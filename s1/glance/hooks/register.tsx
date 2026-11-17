import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, RenderChildren } from 'claude-code'

import type { Glance, Part, S1Answer, View } from '../types'

// 🌌 Sagittarius Signals (s1-glance), a proof of concept. The System 1 hook (Sagittarius s1/hook.py) logs
// each judgment to ~/.claude/logs/s1.jsonl; this mod draws the newest one of this session to be seen at a
// glance rather than read. Read-only: it never calls System 1 itself.
//
// Views, any together, chosen with /s1-glance and kept for every session ($.store):
//   pane    a docked pane: every signal with a bar, the age, and a colour key (the default)
//   toast   up to three toasts in the top-right corner, only for the signals that fired
//   corner  one row above the prompt, only the signals that fired
//   status  one line under the prompt: every signal with a one-cell gauge
//
// The pane has three tabs (keys 1 2 3), all drawn from the same history and linked by one cursor (p / n):
//   now     the signals of one judgment, and why: the message as a strip of parts (the fan-out of
//           s1/hook.py), one cell per part; j and k pick a part and show its text and what stands out in it
//   trend   every signal over the session, one cell per judgment; the cursor is a column of the chart
//   health  how the hook performs: latency, tokens, failed calls, and for each signal how often it
//           says yes, no, or nothing (the unsure band)

const PANE = 's1-glance'
const PANE_TITLE = 'Sagittarius Signals'
const BRAND = '🌌'
const POLL_MS = 2000
const STALE_S = 600 // older than 10 minutes: drawn dim, and marked ◌ in place of ●
const TAIL_LINES = '80' // the log grows ~6 KB a line; read only its end
const TOAST_MS = 20000
const TOASTS = 3 // the surface shows three toasts; more wait under "+n more" and expire unseen
const TICK_MS = 15000
const BAR = 10 // bar cells
const LABEL = 9 // label cells
const RULE = '─'.repeat(31)
const DEFAULT_VIEWS: View[] = ['pane']

const last = atom({ plugin: 's1-glance', key: 'last' } as const, null, { shape: 'glance-2' })
// Every judgment of this session, oldest first (at most HISTORY), and which one the pane shows: null is
// "the newest, and follow new ones"; a number is an index into the history, held while the person reads.
const HISTORY = 100
const history = atom({ plugin: 's1-glance', key: 'history' } as const, [] as Glance[], { shape: 'hist-1' })
const cursor = atom({ plugin: 's1-glance', key: 'cursor' } as const, null as number | null)
// The tab of the pane (0 now, 1 trend, 2 health) and the part picked on the now tab (null: the strongest).
const tab = atom({ plugin: 's1-glance', key: 'tab' } as const, 0)
const part = atom({ plugin: 's1-glance', key: 'part' } as const, null as number | null)
// Bumped every TICK_MS so the age ("12s ago") moves between judgments.
const tick = atom({ plugin: 's1-glance', key: 'tick' } as const, 0)
// The views on now. The person's choice is also kept in $.store, which every new session reads.
const views = atom({ plugin: 's1-glance', key: 'views' } as const, DEFAULT_VIEWS, { shape: 'views-1' })

// The colour of a bar says how strong the signal is: the hook's own bands (s1/jev.py band).
type Strength = 'confident' | 'moderate' | 'weak'
const strength = (p: number): Strength => (p >= 0.7 ? 'confident' : p > 0.3 ? 'moderate' : 'weak')
const COLOR: Record<Strength, string> = { confident: 'error', moderate: 'warning', weak: 'text' }
const SQUARE: Record<Strength, string> = { confident: '🟥', moderate: '🟨', weak: '⬜' }

// Emoji with no variation selector only. Each is two cells wide; the pane gives the icon a column of its
// own (a fixed-width Box), so the width never moves the bars.
// `alarm`: a yes asks the agent to stop and look; alarms come first among the toasts.
const NOULS: { id: string; glyph: string; label: string; alarm: boolean }[] = [
  { id: 'h_divergence', glyph: '🔀', label: 'diverge', alarm: true },
  { id: 'h_change_of_plan', glyph: '🔄', label: 're-plan', alarm: true },
  { id: 'h_questions', glyph: '❓', label: 'open Qs', alarm: true },
  { id: 'h_proof', glyph: '📜', label: 'proof', alarm: true },
  { id: 'h_reversal', glyph: '🔙', label: 'reversal', alarm: true }, // the fan-out: a decision reversed inside the message
  { id: 'h_effort', glyph: '💪', label: 'effort', alarm: false },
]
const WORK: Record<string, string> = { research: '🔍', specify: '📐', build: '🔨', verify: '🔬', question: '💬', other: '👋' }
const TOOL: Record<string, string> = { prolog: '🦉', lean: '🧮', z3: '🧩', tla: '🕰', tests: '🧪', none: '🚫' }

const EIGHTHS = ['', '▏', '▎', '▍', '▌', '▋', '▊', '▉']

// The filled part of a bar of BAR cells for p in [0, 1], in eighths of a cell, and the track after it.
function bar(p: number): { fill: string; track: string } {
  const q = Math.max(0, Math.min(1, p))
  const eighths = Math.round(q * BAR * 8)
  const full = Math.floor(eighths / 8)
  const part = EIGHTHS[eighths % 8] ?? ''
  const used = full + (part ? 1 : 0)

  return { fill: '█'.repeat(full) + part, track: '·'.repeat(Math.max(0, BAR - used)) }
}

const GAUGE = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█']
// One cell for p in [0, 1]: a block whose height is the probability.
const gauge = (p: number) => GAUGE[Math.min(7, Math.max(0, Math.round(p * 7)))] ?? '▁'

// Five coloured squares for a toast, which has no colours of its own: filled in the strength's colour.
function squares(p: number): string {
  const n = Math.min(5, Math.max(0, Math.round(p * 5)))

  return SQUARE[strength(p)].repeat(n) + '⬛'.repeat(5 - n)
}

const pct = (p: number) => `${Math.round(p * 100)}`.padStart(3) + '%'

function age(time: string, now: number): number {
  const t = Date.parse(time)

  return Number.isNaN(t) ? Infinity : Math.max(0, (now - t) / 1000)
}

function ago(s: number): string {
  if (!Number.isFinite(s)) return '?'
  if (s < 60) return `${Math.round(s)}s ago`
  if (s < 3600) return `${Math.round(s / 60)}m ago`

  return `${Math.round(s / 3600)}h ago`
}

// One row: one signal of the newest judgment. `fires`: over its threshold, as the hook's line reports it
// (a choice at P >= 0.5, s1/hook.py CHOICE_MIN; a yes/no question in the yes band, P >= 0.7). `rank`
// orders the toasts: alarms, then the work, the tool, the effort.
type Row = { glyph: string; label: string; p: number; fires: boolean; rank: number; bold?: boolean; id?: string }

const prob = (a: { choice: string; confidence: number; probabilities?: Record<string, number> }, c: string) =>
  a.probabilities?.[c] ?? (c === a.choice ? a.confidence : 0)

function rows(g: Glance): Row[] {
  const a = g.answers ?? {}
  const out: Row[] = []
  const work = a.h_work
  if (work && work.type === 'choice') {
    const p = prob(work, work.choice)
    // Below the threshold the hook names no work: say "unsure", not a guess.
    if (p >= 0.5) out.push({ glyph: WORK[work.choice] ?? '🔹', label: work.choice, p, fires: true, rank: 1, bold: true })
    else out.push({ glyph: '🤷', label: 'unsure', p, fires: false, rank: 1, bold: true })
  }
  for (const q of NOULS) {
    const ans = a[q.id]
    if (!ans || ans.type !== 'noul') continue
    out.push({ glyph: q.glyph, label: q.label, p: ans.noul, fires: ans.noul >= 0.7, rank: q.alarm ? 0 : 3, id: q.id })
  }
  const lang = a.h_language
  if (lang && lang.type === 'choice') {
    const p = prob(lang, lang.choice)
    // A tool below the threshold is no tool at all: show "no tool" with P(none), never the guess.
    if (p >= 0.5 && lang.choice !== 'none') out.push({ glyph: TOOL[lang.choice] ?? '🔹', label: lang.choice, p, fires: true, rank: 2 })
    else out.push({ glyph: TOOL.none ?? '🚫', label: 'no tool', p: prob(lang, 'none'), fires: false, rank: 2 })
  }

  return out
}

const fired = (g: Glance) => rows(g).filter(r => r.fires).sort((x, y) => x.rank - y.rank)

// What a part does (the choice "react" of s1/fanout.json), and the six answers of a part.
const DOES: Record<string, { glyph: string; label: string }> = {
  accepts: { glyph: '✅', label: 'accepts' },
  corrects: { glyph: '❌', label: 'corrects' },
  doubts: { glyph: '🤨', label: 'doubts' },
  changes_request: { glyph: '🔄', label: 'changes the ask' },
  adds_request: { glyph: '➕', label: 'adds to the ask' },
  answers: { glyph: '💬', label: 'answers' },
  asks_back: { glyph: '❓', label: 'asks back' },
  new_topic: { glyph: '🆕', label: 'new topic' },
}
const PART_SIGNALS: { key: keyof Part; glyph: string; label: string }[] = [
  { key: 'doubts', glyph: '🤨', label: 'doubt' },
  { key: 'faults', glyph: '❌', label: 'fault' },
  { key: 'changes', glyph: '🔄', label: 'change' },
  { key: 'asks', glyph: '❓', label: 'asks' },
  { key: 'undecided', glyph: '🤷', label: 'undecided' },
  { key: 'reverses', glyph: '🔙', label: 'reverses' },
]
// The answers of a part that feed each signal of the judgment (s1/hook.py combine).
const FEEDS: Record<string, (keyof Part)[]> = {
  h_divergence: ['doubts', 'faults'],
  h_change_of_plan: ['changes'],
  h_questions: ['asks', 'undecided'],
  h_reversal: ['reverses'],
}
const num = (x: unknown) => (typeof x === 'number' && x >= 0 && x <= 1 ? x : 0)
const heat = (x: Part) => Math.max(...PART_SIGNALS.map(s => num(x[s.key])))
// The part that carries a signal: the one with the highest answer that feeds it, or -1.
function carrier(g: Glance, id: string): number {
  const keys = FEEDS[id]
  if (!keys || !g.parts?.length) return -1
  let best = -1
  let top = 0.3
  g.parts.forEach((x, i) => {
    const v = Math.max(...keys.map(k => num(x[k])))
    if (v > top) [best, top] = [i, v]
  })

  return best
}
// The part the now tab opens on: the one where the most stands out.
const strongest = (ps: Part[]) => ps.reduce((b, x, i) => (heat(x) > heat(ps[b] as Part) ? i : b), 0)

function partsOf(r: Record<string, unknown>, call: Record<string, unknown> | null): Part[] | undefined {
  const a = (r.answers ?? {}) as Record<string, any>
  const st = ((call ?? r).state ?? {}) as { sentences?: unknown }
  const texts = Array.isArray(r.part_text) ? r.part_text : Array.isArray(st.sentences) ? st.sentences : null
  if (!texts) return undefined
  const out: Part[] = []
  for (let k = 0; k < texts.length && k < 60; k++) {
    const c = a[`react@${k}`]
    if (!c || c.type !== 'choice') break
    const n = (name: string) => num(a[`${name}@${k}`]?.noul)
    out.push({
      text: plain(String(texts[k] ?? '')).slice(0, 160),
      does: String(c.choice ?? ''),
      p: num(prob(c, c.choice)),
      doubts: n('doubts'), faults: n('faults'), changes: n('changes'), asks: n('asks'), undecided: n('undecided'), reverses: n('reverses'),
    })
  }

  return out.length ? out : undefined
}

// Toasts: one per signal that fired, at most TOASTS; past that, the last toast holds the rest compactly.
// Each entry is held together by no-break spaces, so a wrap falls only between entries.
const NB = '\u00a0'
function toastAll($: EngineInterface, g: Glance) {
  if (g.error || !g.answers) {
    $.ui.toast(`⚠ System 1 failed: ${plain(g.error ?? 'no answers').slice(0, 60)}`, { timeoutMs: TOAST_MS })
    return
  }
  const hot = fired(g)
  const full = hot.length <= TOASTS ? hot : hot.slice(0, TOASTS - 1)
  for (const r of full) {
    const at = r.id ? carrier(g, r.id) : -1
    const why = at >= 0 ? ` “${oneLine(g.parts?.[at]?.text ?? '').slice(0, 40)}”` : '' // the part that fired it
    $.ui.toast([r.glyph, r.label.padEnd(LABEL, NB), squares(r.p), pct(r.p).trim()].join(NB) + why, { timeoutMs: TOAST_MS })
  }
  const rest = hot.slice(full.length)
  if (rest.length) {
    $.ui.toast(rest.map(r => [r.glyph, r.label, SQUARE[strength(r.p)]].join(NB)).join(' · '), { timeoutMs: TOAST_MS })
  }
}

// The status line row: every signal with a one-cell gauge and its label, in ANSI colour (a status line
// command prints it as is). Each gauge has its strength's colour; the label of a signal under its threshold
// is dim, and a fired one is bright. A stale judgment is dim and colourless.
const ANSI: Record<Strength, string> = { confident: '\u001b[31m', moderate: '\u001b[33m', weak: '\u001b[37m' }
const DIM = '\u001b[2m'
const RESET = '\u001b[0m'
function ansiLine(g: Glance | null, now: number): string {
  if (!g) return `${DIM}${BRAND} signals: nothing yet${RESET}`
  const s = age(g.time, now)
  const stale = s > STALE_S
  if (g.error || !g.answers) return `\u001b[31m${BRAND} ⚠ System 1 call failed${RESET}`
  const parts = rows(g).map(r => {
    // A fired signal is bright; one under its threshold is dim, its bar still in its strength's colour.
    // A stale judgment is dim and colourless in every view.
    if (stale) return `${DIM}${r.glyph} ${r.label} ${gauge(r.p)}${RESET}`
    return r.fires
      ? `${r.glyph} ${r.label} ${ANSI[strength(r.p)]}${gauge(r.p)}${RESET}`
      : `${DIM}${r.glyph} ${r.label} ${ANSI[strength(r.p)]}${gauge(r.p)}${RESET}`
  })
  const tail = `${DIM}${stale ? '◌' : '●'}${g.latency !== null ? ` ${g.latency.toFixed(2)}s` : ''}${RESET}`

  return `${BRAND} ` + parts.join(`${DIM} · ${RESET}`) + `${DIM} · ${RESET}` + tail
}

// What System 1 was given (s1/hook.py build_state: the newest message and a few recent ones), cut so
// the session's state stays small.
const SAW_MESSAGE = 2000
// Claude Code refuses a tree whose text holds a control character, and then draws an empty pane.
// A /compact leaves ESC[2m...ESC[22m in the transcript, which System 1 then sees as a message. So
// the text is drawn plain: escape sequences go, a tab is a space, other control characters go.
const ESC_SEQ = /\u001b(?:\[[0-?]*[ -\/]*[@-~]|\][^\u0007\u001b]*(?:\u0007|\u001b\\)?|[@-Z\\-_])/g
export function plain(t: string): string {
  return t.replace(ESC_SEQ, '').replace(/\t/g, ' ').replace(/[\u0000-\u0009\u000b-\u001f\u007f-\u009f]/g, '')
}
const SAW_RECENT = 600
function saw(r: Record<string, unknown>) {
  const st = (r.state ?? {}) as { message?: unknown; recent?: unknown }
  const recent = Array.isArray(st.recent)
    ? st.recent.map(m => {
        const x = (m ?? {}) as { role?: unknown; text?: unknown }
        return { role: plain(String(x.role ?? '?')), text: plain(String(x.text ?? '')).slice(0, SAW_RECENT) }
      })
    : []

  return {
    message: typeof st.message === 'string' ? plain(st.message).slice(0, SAW_MESSAGE) : '',
    messageLength: typeof st.message === 'string' ? st.message.length : 0,
    recent,
    trimmed: r.trimmed === true,
    longContext: r.long_context === true,
  }
}

const oneLine = (t: string) => t.replace(/\s+/g, ' ').trim()

type Line = Record<string, unknown>
function lineOf(raw: string, sessionId: string): Line | null {
  if (!raw.trim()) return null
  let r: Line
  try {
    r = JSON.parse(raw)
  } catch {
    return null // a line cut by the tail, or one being written
  }

  return r.session_id === sessionId && (r.answers || r.error) ? r : null
}

// Every judgment of this session in the log text, oldest first. With the fan-out the hook writes two
// lines for one call: the call (what was sent, the latency) and then a combined line (the answers the
// agent's line came from, and the parts). The two are one judgment.
function judgments(text: string, sessionId: string): Glance[] {
  const out: Glance[] = []
  let call: Line | null = null
  for (const raw of text.split('\n')) {
    const r = lineOf(raw, sessionId)
    if (!r) continue
    if (r.combined === true) {
      const g = toGlance(r, call)
      if (call && out.at(-1)?.time === String(call.time ?? '')) out[out.length - 1] = g
      else out.push(g)
      continue
    }
    call = r
    out.push(toGlance(r, null))
  }

  return out
}

const newest = (text: string, sessionId: string): Glance | null => judgments(text, sessionId).at(-1) ?? null

function toGlance(r: Line, call: Line | null): Glance {
  const src = r.combined === true && call ? call : r // what was sent, and how long it took
  const usage = (src.usage ?? {}) as { input_tokens?: unknown }

  return {
    time: String(r.time ?? ''),
    model: String(src.model ?? ''),
    latency: typeof src.latency === 'number' ? src.latency : null,
    error: r.error ? plain(String(r.error)) : null,
    answers: (r.answers as Record<string, S1Answer> | null) ?? null,
    ...saw(src),
    parts: partsOf(r, call),
    tokens: typeof usage.input_tokens === 'number' ? usage.input_tokens : null,
    callTime: r.combined === true && call ? String(call.time ?? '') : undefined,
    routing: typeof r.routing === 'string' ? r.routing : null,
    kind: typeof r.kind === 'string' ? r.kind : null,
  }
}

const allOf = (text: string, sessionId: string): Glance[] => judgments(text, sessionId).slice(-HISTORY)

// --- charts: every one is a row of one-cell gauges, coloured by strength, so a shape is seen, not read ---
const PRICE_PER_MTOK = 0.042 // USD for a million input tokens of the System 1 model (docs.typesafe.ai/models.md, 2026-11)
const TREND_ROWS = [...NOULS].sort((x, y) => Number(y.alarm) - Number(x.alarm))
const noul = (g: Glance, id: string): number | null => {
  const a = g.answers?.[id]
  return a && a.type === 'noul' ? a.noul : null
}
const median = (xs: number[]) => {
  const v = [...xs].sort((x, y) => x - y)
  return v.length ? (v[Math.floor((v.length - 1) / 2)] as number) : 0
}
// Runs of cells of one colour, so a row of 27 cells is a few Text nodes.
type Cell = { ch: string; color?: string; dim?: boolean; bold?: boolean }
function runs(Text: any, cells: Cell[]) {
  const out: RenderChildren[] = []
  let i = 0
  while (i < cells.length) {
    const c = cells[i] as Cell
    let j = i
    let str = ''
    while (j < cells.length && cells[j]?.color === c.color && cells[j]?.dim === c.dim && cells[j]?.bold === c.bold) str += (cells[j++] as Cell).ch
    out.push(
      <Text color={c.color} dimColor={c.dim === true} bold={c.bold === true}>
        {str}
      </Text>,
    )
    i = j
  }

  return out
}
// One cell for a probability: its height is the value and its colour the strength; no answer is a dot.
const pCell = (v: number | null, on: boolean): Cell =>
  v === null ? { ch: '·', dim: true } : { ch: gauge(v), color: COLOR[strength(v)], dim: !on && v < 0.7, bold: on }
// One cell for a magnitude against the largest of its row.
const mCell = (v: number | null, max: number, on: boolean): Cell =>
  v === null ? { ch: '·', dim: true } : { ch: gauge(max > 0 ? v / max : 0), dim: !on, bold: on }

// A row of a chart: an icon, then the cells.
function chartRow(ui: any, glyph: string, cells: Cell[]) {
  const { Box, Text } = ui
  return (
    <Box flexDirection="row">
      <Box width={3} flexShrink={0}>
        <Text>{glyph}</Text>
      </Box>
      <Text>{runs(Text, cells)}</Text>
    </Box>
  )
}

// The trend tab: one row per signal, one cell per judgment; the cursor's judgment is a bright column.
function trend(ui: any, hist: Glance[], idx: number, width: number) {
  const { Box, Text } = ui
  const n = Math.max(8, Math.min(width - 4, 60))
  const end = Math.min(hist.length, Math.max(idx + 1 + Math.floor(n / 4), n))
  const from = Math.max(0, end - n)
  const win = hist.slice(from, end)
  const at = idx - from
  const seen = TREND_ROWS.filter(q => hist.some(g => noul(g, q.id) !== null))
  const lat = Math.max(0, ...win.map(g => g.latency ?? 0))
  const sel = hist[idx]
  const hot = sel && !sel.error && sel.answers ? fired(sel) : []

  return (
    <Box flexDirection="column">
      {seen.map(q => chartRow(ui, q.glyph, win.map((g, i) => (g.error || !g.answers ? { ch: '×', color: 'error' } : pCell(noul(g, q.id), i === at)))))}
      {chartRow(ui, '⏱', win.map((g, i) => mCell(g.latency, lat, i === at)))}
      <Text dimColor>{'   ' + ' '.repeat(Math.max(0, at)) + '▲'}</Text>
      <Text dimColor>{`#${idx + 1}${sel ? ' · ' + ago(age(sel.time, Date.now())) : ''}${sel?.latency != null ? ` · ${sel.latency.toFixed(2)}s` : ''}`}</Text>
      <Text>{sel?.error ? '⚠ the call failed' : hot.length ? hot.map(r => `${r.glyph} ${r.label}`).join('  ') : 'no signal'}</Text>
      <Text dimColor>{`${from + 1}–${end} of ${hist.length} · p n move the cursor`}</Text>
    </Box>
  )
}

// The health tab: how the hook performs over the session.
function health(ui: any, hist: Glance[], width: number) {
  const { Box, Text } = ui
  const n = Math.max(8, Math.min(width - 4, 60))
  const win = hist.slice(-n)
  const ok = hist.filter(g => !g.error && g.answers)
  const failed = hist.length - ok.length
  const lats = ok.map(g => g.latency).filter((x): x is number => typeof x === 'number')
  const toks = ok.map(g => g.tokens).filter((x): x is number => typeof x === 'number')
  const sum = toks.reduce((x, y) => x + y, 0)
  const parted = ok.filter(g => g.parts?.length)
  const sizes = parted.map(g => g.parts?.length ?? 0)
  const MIX = Math.max(8, Math.min(width - 13, 20))
  const mix = TREND_ROWS.map(q => {
    const v = ok.map(g => noul(g, q.id)).filter((x): x is number => x !== null)
    const yes = v.filter(x => x >= 0.7).length
    const no = v.filter(x => x <= 0.3).length
    return { q, total: v.length, yes, no, unsure: v.length - yes - no }
  }).filter(m => m.total > 0)
  const latMax = Math.max(0, ...win.map(g => g.latency ?? 0))
  const tokMax = Math.max(0, ...win.map(g => g.tokens ?? 0))

  return (
    <Box flexDirection="column">
      {chartRow(ui, '⏱', win.map(g => (g.error ? { ch: '×', color: 'error' } : mCell(g.latency, latMax, true))))}
      <Text dimColor>{lats.length ? `   median ${median(lats).toFixed(2)}s · max ${Math.max(...lats).toFixed(2)}s` : '   no latency yet'}</Text>
      {chartRow(ui, '🪙', win.map(g => mCell(g.tokens ?? null, tokMax, true)))}
      <Text dimColor>{toks.length ? `   ${sum.toLocaleString('en-US')} tokens · $${((sum * PRICE_PER_MTOK) / 1e6).toFixed(4)}` : '   no token counts yet'}</Text>
      <Text color={failed ? 'error' : undefined} dimColor={!failed}>{`⚠  ${failed} of ${hist.length} calls failed`}</Text>
      <Text dimColor>{RULE}</Text>
      <Text bold dimColor>How often each signal speaks</Text>
      {mix.map(m => {
        const y = Math.round((m.yes / m.total) * MIX)
        const u = Math.min(MIX - y, Math.round((m.unsure / m.total) * MIX))
        return (
          <Box flexDirection="row">
            <Box width={3} flexShrink={0}>
              <Text>{m.q.glyph}</Text>
            </Box>
            <Text>
              <Text color={COLOR.confident}>{'█'.repeat(y)}</Text>
              <Text color={COLOR.moderate}>{'▒'.repeat(u)}</Text>
              <Text dimColor>{'░'.repeat(Math.max(0, MIX - y - u))}</Text>
              <Text dimColor>{` ${m.yes}/${m.unsure}/${m.no}`}</Text>
            </Text>
          </Box>
        )
      })}
      <Text>
        <Text color={COLOR.confident}>█</Text>
        <Text dimColor> yes  </Text>
        <Text color={COLOR.moderate}>▒</Text>
        <Text dimColor> unsure: says nothing  ░ no</Text>
      </Text>
      <Text dimColor>{RULE}</Text>
      <Text dimColor>{`🧩 read in parts: ${parted.length} of ${ok.length}` + (sizes.length ? ` · median ${median(sizes)}, most ${Math.max(...sizes)}` : '')}</Text>
      <Text dimColor>{`🛠  workbench ${ok.filter(g => g.routing === 'workbench').length} · late fixes ${ok.filter(g => g.kind === 'correction').length}`}</Text>
    </Box>
  )
}

// The why of one judgment: the message as a strip of parts, and the part that is picked.
function partsBox(ui: any, g: Glance, picked: number | null, stale: boolean, width: number, prev: () => unknown, nextPart: () => unknown) {
  const { Box, Text, Button } = ui
  const ps = g.parts ?? []
  if (!ps.length) return ''
  const at = Math.min(ps.length - 1, Math.max(0, picked ?? strongest(ps)))
  const x = ps[at] as Part
  const does = DOES[x.does] ?? { glyph: '🔹', label: x.does || '?' }
  const out = PART_SIGNALS.filter(sg => num(x[sg.key]) > 0.3)
  const per = Math.max(8, width - 1)
  const strip: Cell[] = ps.map((y, i) => (i === at ? { ch: '◆', color: COLOR[strength(heat(y))], bold: true } : { ch: gauge(heat(y)), color: COLOR[strength(heat(y))], dim: stale || heat(y) < 0.7 }))
  const lines: Cell[][] = []
  for (let i = 0; i < strip.length; i += per) lines.push(strip.slice(i, i + per))
  const text = oneLine(x.text)

  return (
    <Box flexDirection="column">
      <Text dimColor>{RULE}</Text>
      <Box flexDirection="row" gap={1}>
        <Text bold dimColor>{`Why · part ${at + 1} of ${ps.length}`}</Text>
        {ps.length > 1 ? <Button key="part-prev" plain hotkey="j" label="◂" onPress={prev} /> : ''}
        {ps.length > 1 ? <Button key="part-next" plain hotkey="k" label="▸" onPress={nextPart} /> : ''}
      </Box>
      {lines.map(l => (
        <Text>{runs(Text, l)}</Text>
      ))}
      <Text dimColor={stale}>{`${does.glyph} ${does.label}${pct(x.p)}`}</Text>
      <Text dimColor={stale}>{`“${text.length > width * 3 - 3 ? text.slice(0, width * 3 - 4) + '…' : text}”`}</Text>
      {out.length === 0 ? (
        <Text dimColor>nothing stands out in this part</Text>
      ) : (
        out.map(sg => {
          const v = num(x[sg.key])
          const { fill, track } = bar(v)
          return (
            <Box flexDirection="row">
              <Box width={3} flexShrink={0}>
                <Text>{sg.glyph}</Text>
              </Box>
              <Box width={LABEL + 1} flexShrink={0}>
                <Text dimColor={stale || v < 0.7}>{sg.label}</Text>
              </Box>
              <Box width={BAR + 1} flexShrink={0}>
                <Text>
                  <Text color={COLOR[strength(v)]} dimColor={stale || v < 0.7}>
                    {fill}
                  </Text>
                  <Text dimColor>{track}</Text>
                </Text>
              </Box>
              <Text dimColor={stale || v < 0.7}>{pct(v)}</Text>
            </Box>
          )
        })
      )}
    </Box>
  )
}

// The pane: the title, the cursor, the tabs, and the tab's drawing.
async function card($: EngineInterface, e: any) {
  const { Box, Text, Button } = $.ui.resolve(e)
  const hist = await read($, history)
  const at = await read($, cursor)
  const live = at === null || at >= hist.length - 1
  const idx = live ? hist.length - 1 : Math.max(0, at)
  const g = (live ? await read($, last) : hist[idx]) ?? null
  const older = async () => {
    const n = (await read($, history)).length
    await update($, cursor, c => Math.max(0, (c === null ? n - 1 : c) - 1))
    await update($, part, () => null)
  }
  const newer = async () => {
    const n = (await read($, history)).length
    await update($, cursor, c => (c === null || c + 1 >= n - 1 ? null : c + 1))
    await update($, part, () => null)
  }
  const latest = () => update($, cursor, () => null)
  const which = await read($, tab)
  const picked = await read($, part)
  const go = (t: number) => () => update($, tab, () => t)
  await read($, tick) // redraw on each tick
  const now = Date.now()
  const stale = g ? age(g.time, now) > STALE_S : true
  let body: RenderChildren
  if (!g) {
    body = <Text dimColor>nothing yet: send a prompt</Text>
  } else if (g.error || !g.answers) {
    body = (
      <Box flexDirection="column">
        <Text color="error">⚠ the call failed</Text>
        <Text dimColor>{plain(g.error ?? 'no answers').slice(0, 30)}</Text>
      </Box>
    )
  } else {
    body = (
      <Box flexDirection="column">
        {rows(g).map(r => {
          const { fill, track } = bar(r.p)
          // Ty (specs/s1-glance c2b): the bar's colour is its strength; a signal under its threshold is dim.
          const dim = stale || !r.fires

          return (
            <Box flexDirection="row">
              <Box width={3} flexShrink={0}>
                <Text>{r.glyph}</Text>
              </Box>
              <Box width={LABEL + 1} flexShrink={0}>
                <Text dimColor={dim} bold={r.bold === true}>
                  {r.label}
                </Text>
              </Box>
              <Box width={BAR + 1} flexShrink={0}>
                <Text>
                  <Text color={COLOR[strength(r.p)]} dimColor={dim}>
                    {fill}
                  </Text>
                  <Text dimColor>{track}</Text>
                </Text>
              </Box>
              <Text dimColor={dim}>{pct(r.p)}</Text>
            </Box>
          )
        })}
      </Box>
    )
  }
  const foot = g
    ? `${stale ? '◌' : '●'} ${ago(age(g.time, now))}${g.latency !== null ? ` · ${g.latency.toFixed(2)}s` : ''}`
    : '◌ waiting for System 1'

  // Docked beside the transcript the pane is one narrow column. Above the prompt (placement "inline",
  // a narrow terminal) it spans the screen: the signals and what System 1 saw then sit side by side,
  // and the text is cut to a few lines so the pane stays short.
  const cols: number = e.props?.bodyColumns ?? 34
  const inline = e.props?.placement === 'inline'
  const wide = inline && cols >= 72
  const sawCols = wide ? Math.max(20, cols - 37) : cols
  const clip = (t: string, lines: number) => {
    const max = Math.max(20, sawCols * lines - 1)
    const one = oneLine(t)
    return one.length > max ? one.slice(0, max - 1) + '…' : one
  }
  const msgLines = inline ? 4 : 1000
  const recentLines = inline ? 1 : 1000

  const count = g?.parts?.length ?? 0
  const prevPart = () => update($, part, c => ((c ?? (g?.parts ? strongest(g.parts) : 0)) - 1 + Math.max(1, count)) % Math.max(1, count))
  const nextPart = () => update($, part, c => ((c ?? (g?.parts ? strongest(g.parts) : 0)) + 1) % Math.max(1, count))
  const chartCols = wide ? 33 : Math.max(20, Math.min(cols, 64))
  const ui = { Box, Text, Button }
  const tabs = (
    <Box flexDirection="row" gap={1}>
      {['now', 'trend', 'health'].map((name, t) => (
        <Button key={`tab-${name}`} plain hotkey={String(t + 1)} label={which === t ? `[${name}]` : name} onPress={go(t)} />
      ))}
    </Box>
  )
  if (which === 1 && hist.length) body = trend(ui, hist, idx, chartCols)
  if (which === 2 && hist.length) body = health(ui, hist, chartCols)
  const why = which === 0 && g && !g.error && g.answers ? partsBox(ui, g, picked, stale, chartCols - 2, prevPart, nextPart) : ''

  const signals = (
    <Box flexDirection="column" width={wide ? 33 : undefined} flexShrink={0}>
      <Text bold>{`${BRAND} ${PANE_TITLE}`}</Text>
      {hist.length > 1 ? (
        <Box flexDirection="row" gap={1}>
          <Button key="older" plain hotkey="p" label="◀" onPress={older} />
          <Text dimColor={live}>{`${idx + 1} of ${hist.length}`}</Text>
          <Button key="newer" plain hotkey="n" label="▶" onPress={newer} />
          {live ? <Text dimColor>● live</Text> : <Button key="latest" plain hotkey="l" label="latest" onPress={latest} />}
        </Box>
      ) : (
        ''
      )}
      {tabs}
      <Text dimColor>{RULE}</Text>
      {body}
      {why}
      <Text dimColor>{RULE}</Text>
      <Text dimColor>{foot}</Text>
      <Text>
        <Text color={COLOR.confident}>█</Text>
        <Text dimColor> confident  </Text>
        <Text color={COLOR.moderate}>█</Text>
        <Text dimColor> moderate  </Text>
        <Text color={COLOR.weak}>█</Text>
        <Text dimColor> weak</Text>
      </Text>
    </Box>
  )

  const sawBox =
    which === 0 && g && g.message ? (
      <Box flexDirection="column" marginTop={wide ? 0 : 1} marginLeft={wide ? 3 : 0} flexGrow={1} flexShrink={1}>
        {wide ? '' : <Text dimColor>{RULE}</Text>}
        <Text dimColor>
          <Text bold>Message: </Text>
          {`(${g.messageLength} chars${g.messageLength > SAW_MESSAGE ? `, first ${SAW_MESSAGE} here` : ''})` +
            (g.trimmed ? ' · trimmed to fit' : '') +
            (g.longContext ? ' · long context' : '')}
        </Text>
        <Text>{clip(plain(g.message), msgLines)}</Text>
        {g.recent.length ? <Text bold dimColor>{`Last ${g.recent.length}:`}</Text> : ''}
        {[...g.recent].reverse().map(m => (
          <Text dimColor>
            <Text bold>{m.role + ': '}</Text>
            {clip(plain(m.text), recentLines).slice(0, Math.max(10, sawCols * recentLines - m.role.length - 3))}
          </Text>
        ))}
      </Box>
    ) : (
      ''
    )

  return (
    <Box flexDirection={wide ? 'row' : 'column'}>
      {signals}
      {sawBox}
    </Box>
  )
}

const VIEWS: readonly View[] = ['pane', 'toast', 'corner', 'status']
const HELP =
  'Views, any together, kept for every session: /s1-glance pane | toast | corner | status | off. No word: say which are on.'
const openPane = ($: EngineInterface) => $.ui.open({ id: PANE, title: PANE_TITLE, rows: 40, columns: 34 })

// The person's choice from an earlier session, if any.
async function saved($: EngineInterface): Promise<View[] | null> {
  const v = await $.store.get('views')
  if (!Array.isArray(v)) return null

  return VIEWS.filter(x => v.includes(x))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 's1-glance',
      description: '🌌 Sagittarius Signals: /s1-glance [pane] [toast] [corner] [status] | off (kept for every session)',
    })
    const kept = await saved($)
    if (kept) await update($, views, () => kept)
    const on0 = await read($, views)
    if (on0.includes('pane')) void openPane($)
    else if ((await $.ui.panes()).some(p => p.id === PANE)) void $.ui.close({ id: PANE })

    const home = (await $.env.get('HOME')) ?? ''
    const log = `${home}/.claude/logs/s1.jsonl`
    const sessionId = await $.session.id()

    // The status view draws on the hint line under the prompt (ui.render PromptHint), so it has colours
    // and no plugin prefix; clear the pinned status line of 0.5-0.7.
    // status: the user's status line command prints this file as its first row (status.sh in this mod).
    const statusFile = `${home}/.claude/s1-glance/${sessionId}.status`
    const showStatus = async () => {
      $.ui.status(undefined)
      const isOn = (await read($, views)).includes('status')
      await $.fs.write(statusFile, isOn ? ansiLine(await read($, last), Date.now()) : '').catch(() => undefined)
    }

    const poll = async () => {
      try {
        const { exitCode, stdout } = await $.process.run(['tail', '-n', TAIL_LINES, log], { timeoutMs: 3000 })
        if (exitCode !== 0) return
        const g = newest(stdout, sessionId)
        if (!g) return
        const was = await read($, last)
        if (was && was.time === g.time && was.error === g.error) return
        await update($, last, () => g)
        await update($, history, h =>
          h.at(-1)?.time === g.time ? h : g.callTime && h.at(-1)?.time === g.callTime ? [...h.slice(0, -1), g] : [...h, g].slice(-HISTORY),
        )
        await update($, part, () => null) // a new judgment: the now tab opens on its strongest part
        if ((await read($, views)).includes('toast')) toastAll($, g)
        await showStatus()
      } catch {
        // no log yet, or tail missing: the views say so
      }
    }
    try {
      const { stdout } = await $.process.run(['grep', '-F', sessionId, log], { timeoutMs: 5000 })
      const all = allOf(stdout, sessionId)
      if (all.length) await update($, history, () => all)
    } catch {
      // no log yet: the history fills as judgments come
    }
    void poll().then(showStatus)
    $.clock.every(POLL_MS, () => void poll())
    $.clock.every(TICK_MS, () => {
      void update($, tick, n => n + 1)
      void showStatus() // the freshness mark moves
    })

    return next(e)
  })

  // /s1-glance                 say which views are on (after "off", turn the pane back on)
  // /s1-glance toast status    exactly those views on, now and in every new session;   /s1-glance off   none
  on('command.run', { command: 's1-glance' }, async ($, e) => {
    const words = e.args.trim().toLowerCase().split(/[\s,]+/).filter(Boolean)
    const bad = words.filter(w => w !== 'off' && !(VIEWS as readonly string[]).includes(w))
    if (bad.length) return { text: `Unknown view: ${bad.join(', ')}. ${HELP}` }
    let now = await read($, views)
    if (words.includes('off')) now = []
    else if (words.length) now = VIEWS.filter(v => words.includes(v))
    else if (now.length === 0) now = DEFAULT_VIEWS
    await update($, views, () => now)
    await $.store.set('views', now)

    const isOpen = (await $.ui.panes()).some(p => p.id === PANE)
    if (now.includes('pane')) await openPane($)
    else if (isOpen) await $.ui.close({ id: PANE })
    const g = await read($, last)
    $.ui.status(undefined)
    const home = (await $.env.get('HOME')) ?? ''
    const sid = await $.session.id()
    await $.fs
      .write(`${home}/.claude/s1-glance/${sid}.status`, now.includes('status') ? ansiLine(g, Date.now()) : '')
      .catch(() => undefined)
    if (now.includes('toast') && g) toastAll($, g)

    return { text: `${BRAND} Sagittarius Signals: ${now.length ? now.join(' + ') : 'off'} (kept for new sessions). ${HELP}` }
  })

  // corner: one row above the prompt, right-aligned, only the signals that fired: glyphs, no bars, a dim ┊ between.
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    // Drawn while collapsed too: the engine hides it but keeps the band and its expand control (0.9.x passed
    // here, the band went empty, and nothing could expand it again).
    if (!(await read($, views)).includes('corner') || e.props.hasSurvey) return next(e)
    const { Box, Text } = $.ui.resolve(e)
    const below = await next(e)
    const g = await read($, last)
    await read($, tick)
    const now = Date.now()
    const stale = g ? age(g.time, now) > STALE_S : true
    let inner: RenderChildren
    if (!g) inner = <Text dimColor>nothing yet</Text>
    else if (g.error || !g.answers) inner = <Text color="error">⚠ call failed</Text>
    else {
      const hot = fired(g)
      inner =
        hot.length === 0 ? (
          <Text dimColor>no signal</Text>
        ) : (
          hot.map((r, i) => (
            <Text>
              {i ? <Text dimColor>{' ┊ '}</Text> : ''}
              {r.glyph}
              {r.bold ? <Text bold>{' ' + r.label}</Text> : ''}
            </Text>
          ))
        )
    }

    return (
      <Box flexDirection="column">
        {below}
        <Box flexDirection="row" justifyContent="flex-end">
          <Text dimColor={stale}>
            {BRAND + ' '}
            <Text dimColor>{'❲ '}</Text>
            {inner}
            <Text dimColor>{' ❳'}</Text>
          </Text>
        </Box>
      </Box>
    )
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => card($, e))
}

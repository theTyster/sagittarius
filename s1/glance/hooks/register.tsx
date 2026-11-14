import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, RenderChildren } from 'claude-code'

import type { Glance, S1Answer, View } from '../types'

// 🌌 Sagittarius Signals (s1-glance), a proof of concept. The System 1 hook (Sagittarius s1/hook.py) logs
// each judgment to ~/.claude/logs/s1.jsonl; this mod draws the newest one of this session to be seen at a
// glance rather than read. Read-only: it never calls System 1 itself.
//
// Views, any together, chosen with /s1-glance and kept for every session ($.store):
//   pane    a docked pane: every signal with a bar, the age, and a colour key (the default)
//   toast   up to three toasts in the top-right corner, only for the signals that fired
//   corner  one row above the prompt, only the signals that fired
//   status  one line under the prompt: every signal with a one-cell gauge

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
type Row = { glyph: string; label: string; p: number; fires: boolean; rank: number; bold?: boolean }

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
    out.push({ glyph: q.glyph, label: q.label, p: ans.noul, fires: ans.noul >= 0.7, rank: q.alarm ? 0 : 3 })
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

// Toasts: one per signal that fired, at most TOASTS; past that, the last toast holds the rest compactly.
// Each entry is held together by no-break spaces, so a wrap falls only between entries.
const NB = '\u00a0'
function toastAll($: EngineInterface, g: Glance) {
  if (g.error || !g.answers) {
    $.ui.toast(`⚠ System 1 failed: ${(g.error ?? 'no answers').slice(0, 60)}`, { timeoutMs: TOAST_MS })
    return
  }
  const hot = fired(g)
  const full = hot.length <= TOASTS ? hot : hot.slice(0, TOASTS - 1)
  for (const r of full) {
    $.ui.toast([r.glyph, r.label.padEnd(LABEL, NB), squares(r.p), pct(r.p).trim()].join(NB), { timeoutMs: TOAST_MS })
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
const SAW_RECENT = 600
function saw(r: Record<string, unknown>) {
  const st = (r.state ?? {}) as { message?: unknown; recent?: unknown }
  const recent = Array.isArray(st.recent)
    ? st.recent.map(m => {
        const x = (m ?? {}) as { role?: unknown; text?: unknown }
        return { role: String(x.role ?? '?'), text: String(x.text ?? '').slice(0, SAW_RECENT) }
      })
    : []

  return {
    message: typeof st.message === 'string' ? st.message.slice(0, SAW_MESSAGE) : '',
    messageLength: typeof st.message === 'string' ? st.message.length : 0,
    recent,
    trimmed: r.trimmed === true,
    longContext: r.long_context === true,
  }
}

const oneLine = (t: string) => t.replace(/\s+/g, ' ').trim()

// The newest line of this session that holds answers or an error (a skip line after an error has
// neither: the call's line before it carries the error).
function newest(text: string, sessionId: string): Glance | null {
  const lines = text.split('\n')
  for (let i = lines.length - 1; i >= 0; i--) {
    const raw = (lines[i] ?? '').trim()
    if (!raw) continue
    let r: Record<string, unknown>
    try {
      r = JSON.parse(raw)
    } catch {
      continue // a line cut by the tail, or one being written
    }
    if (r.session_id !== sessionId) continue
    if (!r.answers && !r.error) continue

    return toGlance(r)
  }

  return null
}

function toGlance(r: Record<string, unknown>): Glance {
  return {
    time: String(r.time ?? ''),
    model: String(r.model ?? ''),
    latency: typeof r.latency === 'number' ? r.latency : null,
    error: r.error ? String(r.error) : null,
    answers: (r.answers as Record<string, S1Answer> | null) ?? null,
    ...saw(r),
  }
}

// Every judgment of this session in the log text, oldest first, the newest HISTORY of them.
function allOf(text: string, sessionId: string): Glance[] {
  const out: Glance[] = []
  for (const raw of text.split('\n')) {
    if (!raw.trim()) continue
    let r: Record<string, unknown>
    try {
      r = JSON.parse(raw)
    } catch {
      continue
    }
    if (r.session_id !== sessionId || (!r.answers && !r.error)) continue
    out.push(toGlance(r))
  }

  return out.slice(-HISTORY)
}

// The pane: the title, a rule, one row per signal, a rule, the age, and the colour key.
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
  }
  const newer = async () => {
    const n = (await read($, history)).length
    await update($, cursor, c => (c === null || c + 1 >= n - 1 ? null : c + 1))
  }
  const latest = () => update($, cursor, () => null)
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
        <Text dimColor>{(g.error ?? 'no answers').slice(0, 30)}</Text>
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
      <Text dimColor>{RULE}</Text>
      {body}
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
    g && g.message ? (
      <Box flexDirection="column" marginTop={wide ? 0 : 1} marginLeft={wide ? 3 : 0} flexGrow={1} flexShrink={1}>
        {wide ? '' : <Text dimColor>{RULE}</Text>}
        <Text dimColor>
          <Text bold>Message: </Text>
          {`(${g.messageLength} chars${g.messageLength > SAW_MESSAGE ? `, first ${SAW_MESSAGE} here` : ''})` +
            (g.trimmed ? ' · trimmed to fit' : '') +
            (g.longContext ? ' · long context' : '')}
        </Text>
        <Text>{clip(g.message, msgLines)}</Text>
        {g.recent.length ? <Text bold dimColor>{`Last ${g.recent.length}:`}</Text> : ''}
        {[...g.recent].reverse().map(m => (
          <Text dimColor>
            <Text bold>{m.role + ': '}</Text>
            {clip(m.text, recentLines).slice(0, Math.max(10, sawCols * recentLines - m.role.length - 3))}
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
        await update($, history, h => (h.at(-1)?.time === g.time ? h : [...h, g].slice(-HISTORY)))
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

  // corner: one row above the prompt, right-aligned, only the signals that fired.
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
              {(i ? '  ' : '') + r.glyph}
              {r.bold ? <Text bold>{' ' + r.label}</Text> : ''}
              <Text color={COLOR[strength(r.p)]}>{' ' + gauge(r.p)}</Text>
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

// desk-toast: the pure part (no `$`). register.ts reads the files and shows the toasts.
//
// The Desk (desk.py, beside this mod) appends one JSON object per line to HUB/flow/desk/events.jsonl.
// A `seen` event says that the desk hook gave the letter to the agent of session `session`. This mod
// shows one toast per new `seen` event; it never writes a file.

export const PREVIEW = 60 // characters of the letter that a toast shows

export type SeenEvent = { letter: string; session: string; at: string }
export type Letter = { id: string; text: string; to: string | null }

// The complete lines of a chunk that starts at a line boundary: the lines, and the bytes they take.
// A last line with no newline is not complete (the writer is still on it): it waits for the next read.
export function completeLines(chunk: string): { lines: string[]; bytes: number } {
  const end = chunk.lastIndexOf('\n')
  if (end < 0) return { lines: [], bytes: 0 }
  const done = chunk.slice(0, end + 1)

  return { lines: done.split('\n').filter(l => l.trim() !== ''), bytes: new TextEncoder().encode(done).length }
}

function parse(line: string): Record<string, unknown> | null {
  try {
    const o = JSON.parse(line)

    return o && typeof o === 'object' && !Array.isArray(o) ? (o as Record<string, unknown>) : null
  } catch {
    return null // a bad line: desk.py status reports it; the toast skips it
  }
}

// The `seen` events among lines of events.jsonl. Every other event (applied, apply_failed, woken) gives
// no toast: only `seen` says that an agent was given the letter.
export function seenEvents(lines: readonly string[]): SeenEvent[] {
  const out: SeenEvent[] = []
  for (const l of lines) {
    const o = parse(l)
    if (o && o.event === 'seen' && typeof o.letter === 'string' && typeof o.session === 'string')
      out.push({ letter: o.letter, session: o.session, at: typeof o.at === 'string' ? o.at : '' })
  }

  return out
}

// The letters of letters.jsonl, by id.
export function lettersById(text: string): Map<string, Letter> {
  const out = new Map<string, Letter>()
  for (const l of text.split('\n')) {
    const o = parse(l)
    if (o && typeof o.id === 'string')
      out.set(o.id, { id: o.id, text: typeof o.text === 'string' ? o.text : '', to: typeof o.to === 'string' ? o.to : null })
  }

  return out
}

// The first PREVIEW characters (code points) of the letter, each line break or tab shown as one space,
// and `…` when the letter is longer.
export function preview(text: string): string {
  const chars = Array.from(text)
  const head = chars.slice(0, PREVIEW).join('').replace(/[\r\n\t]/g, ' ')

  return chars.length > PREVIEW ? `${head}…` : head
}

// A toast draws its text as one wrapped paragraph: a line break shows as a box (U+FFFD), not a new line.
// Its text is TOAST_COLUMNS columns wide (Claude Code 2.1.330, measured at terminal widths 90, 130 and
// 220). So the first line is the header padded with spaces to that width, and the letter wraps below it.
export const TOAST_COLUMNS = 40

// Terminal columns of a string: 2 for a wide character (emoji, CJK), else 1.
export function columns(s: string): number {
  let n = 0
  for (const ch of s) {
    const c = ch.codePointAt(0) ?? 0
    n += c >= 0x1f000 || (c >= 0x1100 && c <= 0x115f) || (c >= 0x2e80 && c <= 0xa4cf) || (c >= 0xac00 && c <= 0xd7a3) || (c >= 0xf900 && c <= 0xfaff) || (c >= 0xff00 && c <= 0xff60) ? 2 : 1
  }

  return n
}

export function header(name: string): string {
  return `📨 ${name} saw:`
}

// The toast: `📨 <session name> saw:` on the first line, then the start of the letter below it.
export function toastText(name: string, letterText: string): string {
  const h = header(name)
  const pad = TOAST_COLUMNS - columns(h)

  return h + ' '.repeat(Math.max(1, pad)) + preview(letterText)
}

// The Claude Code name of a session: the `name` that `claude --name` (or /rename) gave it, from the
// session files of Claude Code (CLAUDE_CONFIG_DIR/sessions/*.json, one per running process). A name
// that Claude Code derived by itself is not a session name: the caller shows the Desk addressee.
export function claudeName(files: readonly string[], sessionId: string): string | null {
  for (const f of files) {
    const o = parse(f)
    if (o && o.sessionId === sessionId && typeof o.name === 'string' && o.name && o.nameSource === 'user') return o.name
  }

  return null
}

// The hubs whose Desk files the mod reads: each mindhole of the Desk (DESK_STATE/mindholes.json, which
// `desk.py join` writes), once each. The mod is linked into ~/.claude/skills (install.py), not into a hub.
export function hubsOf(mindholesJson: string | null): string[] {
  const out: string[] = []
  const o = mindholesJson === null ? null : parse(mindholesJson)
  const list = o && Array.isArray(o.mindholes) ? o.mindholes : []
  for (const m of list as unknown[]) {
    const path = m && typeof m === 'object' ? (m as { path?: unknown }).path : undefined
    if (typeof path === 'string' && path.startsWith('/')) out.push(path.replace(/\/+$/, ''))
  }

  return [...new Set(out)]
}

// The help that /desk-toast prints: one line per paragraph (the transcript wraps them).
export const HELP = [
  'The Desk toast. When the desk hook gives a Desk letter to the agent of a session, the Desk writes a `seen` event for it (HUB/flow/desk/events.jsonl). Within a few seconds every Claude Code session that runs this mod shows a toast: `📨 <session name> saw:`, then the first 60 characters of the letter. <session name> is the Claude Code name of the addressed session (claude --name); a session with no such name shows the Desk addressee (for example discovery). A letter with no `seen` event gives no toast.',
  '"saw" means that the hook gave the letter to the agent. It does not mean that the agent acted on it: a Ctrl+C, a crash or a compaction right after the hook still gives the toast. To know what the agent did, read its reply or the Desk page.',
  'The mod only reads the Desk files (letters.jsonl, events.jsonl, sessions/*.json) of each mindhole of the Desk (desk.py mindholes), and the session files of Claude Code. It writes nothing, marks no letter seen and gives no letter to any agent: only desk.py hook does that. It shows only events that come after the session started.',
].join('\n\n')

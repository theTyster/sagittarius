// 📨 desk-toast: the Desk toast (Sagittarius spec KB desk-letter-toast, claims c3, c4, c8).
//
// Every POLL_MS this session reads the end of HUB/flow/desk/events.jsonl of each Desk mindhole. For each new
// `seen` event it shows one toast: `📨 <session name> saw:`, then the first 60 characters of the letter.
// It reads files only ($.fs.read, $.fs.stat, $.fs.list): it writes nothing and runs no process, so the
// Desk's delivery (desk.py hook) stays the only writer of a `seen` event. /desk-toast prints the help.
import type { EngineInterface, Register } from 'claude-code'
import { HELP, claudeName, completeLines, hubsOf, lettersById, seenEvents, toastText, type Letter } from './core'

const POLL_MS = 2000 // a seen event shows within this time, well inside the 10 s of c8
const TOAST_MS = 8000 // how long a toast stays
const READ_MAX = 1 << 22 // $.fs.read answers at most 4 MiB at once

async function readAll($: EngineInterface, path: string): Promise<string | null> {
  try {
    const { size } = await $.fs.stat(path)
    const parts: string[] = []
    let at = 0
    while (at < size) {
      const length = Math.min(READ_MAX, size - at)
      const chunk = (await $.fs.read(path, { offset: at, length })) as string
      if (at + length >= size) {
        parts.push(chunk)
        break
      }
      // A range before the last ends on a line break, so no character is cut.
      const { bytes } = completeLines(chunk)
      if (bytes === 0) return null
      parts.push(chunk.slice(0, chunk.lastIndexOf('\n') + 1))
      at += bytes
    }

    return parts.join('')
  } catch {
    return null // missing: no Desk here yet
  }
}

async function dirs($: EngineInterface) {
  const env = async (v: string | undefined) => (v && v.startsWith('/') ? v : undefined)
  const home = (await $.env.get('HOME')) ?? ''
  const state =
    (await env(await $.env.get('DESK_STATE'))) ?? `${(await env(await $.env.get('XDG_STATE_HOME'))) ?? `${home}/.local/state`}/desk`
  const config = (await env(await $.env.get('CLAUDE_CONFIG_DIR'))) ?? `${home}/.claude`

  return { state, config }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'desk-toast', description: '📨 Desk toast: what "saw" means, and what the mod reads' })
    const { state, config } = await dirs($)
    const offsets = new Map<string, number>() // events.jsonl path -> bytes already read
    let letters = new Map<string, Letter>()

    const hubs = async () => hubsOf(await readAll($, `${state}/mindholes.json`))

    // A hub seen for the first time: start at the end of its events, so only later events toast.
    const size = async (path: string) => {
      try {
        return (await $.fs.stat(path)).size
      } catch {
        return 0
      }
    }

    const nameOf = async (hub: string, session: string): Promise<string> => {
      try {
        const st = JSON.parse((await readAll($, `${hub}/flow/desk/sessions/${session}.json`)) ?? 'null')
        const id = st && typeof st.session_id === 'string' ? st.session_id : null
        if (!id) return session
        const files: string[] = []
        for (const f of await $.fs.list(`${config}/sessions`))
          if (f.kind === 'file' && f.name.endsWith('.json')) {
            const t = await readAll($, `${config}/sessions/${f.name}`)
            if (t !== null) files.push(t)
          }

        return claudeName(files, id) ?? session
      } catch {
        return session // no session file: the Desk addressee
      }
    }

    const letterOf = async (hub: string, id: string): Promise<Letter | null> => {
      const key = `${hub}\n${id}`
      if (!letters.has(key)) {
        const all = lettersById((await readAll($, `${hub}/flow/desk/letters.jsonl`)) ?? '')
        letters = new Map([...letters, ...[...all].map(([k, v]) => [`${hub}\n${k}`, v] as const)])
      }

      return letters.get(key) ?? null
    }

    const poll = async (first: boolean) => {
      for (const hub of await hubs()) {
        const path = `${hub}/flow/desk/events.jsonl`
        const now = await size(path)
        const was = offsets.get(path)
        if (first || was === undefined || now < was) {
          offsets.set(path, now) // a new hub (or a file that shrank): nothing old toasts
          continue
        }
        if (now === was) continue
        let chunk: string
        try {
          chunk = (await $.fs.read(path, { offset: was, length: Math.min(READ_MAX, now - was) })) as string
        } catch {
          continue
        }
        const { lines, bytes } = completeLines(chunk)
        offsets.set(path, was + bytes)
        for (const s of seenEvents(lines)) {
          const letter = await letterOf(hub, s.letter)
          $.ui.toast(toastText(await nameOf(hub, s.session), letter?.text ?? `(letter ${s.letter})`), { timeoutMs: TOAST_MS })
        }
      }
    }

    await poll(true)
    $.clock.every(POLL_MS, () => poll(false).catch(() => undefined))

    return next(e)
  })

  on('command.run', { command: 'desk-toast' }, async () => ({ text: HELP, isTextDisplayOnly: true }))
}

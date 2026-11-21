// Tests of the desk-toast mod, written from the claims of Sagittarius spec KB desk-letter-toast:
// c8: within 10 s after a letter gets its seen event, a toast shows in each open session; first line
//     `📨 <session name> saw:`, then the first 60 characters of the letter; no toast for a letter with
//     no seen event; the help says "saw" is given to the agent, not acted on.
// c4: the mod only reads letters.jsonl and events.jsonl: it writes nothing and gives no letter to an agent.
// Run: claude plugin test hubkit/hub/.claude/scripts/desk-toast  (desk-test.py runs it too, k8 and k4).
import { describe, expect, mock, test } from 'claude-code/testing'

const HOME = '/home/ty'
const HUB = '/hubs/sidequest'
const STATE = `${HOME}/.local/state/desk`
const EVENTS = `${HUB}/flow/desk/events.jsonl`
const LETTERS = `${HUB}/flow/desk/letters.jsonl`
const LID = 'L-20261119T114714Z-a342ac'
const TEXT = 'Ty closed these old handoffs of yours: a newer handoff holds the same KB.\n- H-0001'

const line = (o: unknown) => JSON.stringify(o) + '\n'
const enc = new TextEncoder()
const dec = new TextDecoder()

// A file system in memory that answers the mod's $.fs calls; every write or process is recorded.
function world(on: any) {
  const files = new Map<string, string>([
    [`${STATE}/mindholes.json`, JSON.stringify({ mindholes: [{ name: 'sidequest-mindhole', path: HUB, joined_at: 'x' }] })],
    [LETTERS, line({ id: 'L-20261118T090000Z-000000', text: 'an old letter', to: 'build', at: '2026-11-18T09:00:00Z' })],
    [EVENTS, line({ at: '2026-11-18T09:01:00Z', letter: 'L-20261118T090000Z-000000', event: 'seen', session: 'build', detail: null })],
    [`${HUB}/flow/desk/sessions/discovery.json`, JSON.stringify({ name: 'discovery', session_id: 'sid-disc', state: 'idle' })],
    [`${HOME}/.claude/sessions/3886642.json`, JSON.stringify({ pid: 3886642, sessionId: 'sid-disc', name: 'sidequest-discovery', nameSource: 'user' })],
    [`${HOME}/.claude/sessions/1849548.json`, JSON.stringify({ pid: 1849548, sessionId: 'sid-tmp', name: 'tmp-9c', nameSource: 'derived' })],
  ])
  const writes: string[] = []
  const toasts: string[] = []
  const missing = (p: string) => Object.assign(new Error(`ENOENT: ${p}`), { code: 'ENOENT' })
  on('fs.stat', (_: unknown, e: { path: string }) => {
    const t = files.get(e.path)
    if (t === undefined) throw missing(e.path)
    return { value: { kind: 'file', size: enc.encode(t).length, mtimeMs: 0, isLink: false } }
  })
  on('fs.read', (_: unknown, e: { path: string; offset?: number; length?: number }) => {
    const t = files.get(e.path)
    if (t === undefined) throw missing(e.path)
    const b = enc.encode(t)
    const from = e.offset ?? 0
    return { value: dec.decode(b.slice(from, e.length === undefined ? undefined : from + e.length)) }
  })
  on('fs.list', (_: unknown, e: { path: string }) => ({
    value: [...files.keys()]
      .filter(p => p.startsWith(e.path + '/') && !p.slice(e.path.length + 1).includes('/'))
      .map(p => ({ name: p.slice(e.path.length + 1), kind: 'file', size: 1, mtimeMs: 0, isLink: false })),
  }))
  on('fs.write', (_: unknown, e: { path: string }) => {
    writes.push(`fs.write ${e.path}`)
    return { value: undefined }
  })
  on('process.run', (_: unknown, e: { argv: readonly string[] }) => {
    writes.push(`process.run ${e.argv.join(' ')}`)
    return { value: { exitCode: 0, stdout: '', stderr: '' } }
  })
  on('process.spawn', async function* () {
    writes.push('process.spawn')
    return { value: undefined }
  })
  on('ui.toast', (_: unknown, e: { text: string }) => {
    toasts.push(e.text)
    return { value: undefined }
  })
  on('command.register', () => ({ value: { command: 'desk-toast' } }))
  on('session.start', (_: unknown, e: { cwd: string }) => ({ cwd: e.cwd }))
  mock.env(on, { HOME })
  const clock = mock.clock(on, { now: Date.parse('2026-11-19T11:47:00Z') })
  const append = (p: string, o: unknown) => files.set(p, (files.get(p) ?? '') + line(o))

  return { files, writes, toasts, clock, append }
}

const store = (w: ReturnType<typeof world>) => {
  w.append(LETTERS, { id: LID, at: '2026-11-19T11:47:14Z', kind: 'fix', text: TEXT, to: 'discovery' })
  w.append(EVENTS, { at: '2026-11-19T11:47:17Z', letter: LID, event: 'applied', session: null, detail: null })
}
const seen = (w: ReturnType<typeof world>, session = 'discovery') =>
  w.append(EVENTS, { at: '2026-11-19T11:50:53Z', letter: LID, event: 'seen', session, detail: null })

const WANT = '📨 sidequest-discovery saw:\nTy closed these old handoffs of yours: a newer handoff holds…'

// Two running sessions: the addressee's own (discovery, in the hub) and another one (build, elsewhere).
for (const [who, cwd] of [['discovery', HUB], ['build', '/home/ty/Projects/mine/sagittarius']] as const) {
  describe(`in the ${who} session`, () => {
    test('a stored letter with no seen event gives no toast; its seen event gives one toast within 10 s', async ($, on) => {
      const w = world(on)
      await $.session.start({ cwd, surface: 'terminal', isInteractive: true })
      store(w)
      await w.clock.advance(30_000)
      expect(w.toasts).toEqual([]) // stored and applied, not seen: nothing
      seen(w)
      await w.clock.advance(10_000)
      expect(w.toasts).toEqual([WANT])
      await w.clock.advance(30_000)
      expect(w.toasts.length).toBe(1) // once
    })
  })
}

test('the toast line is 📨, the Claude Code session name and saw:, then the first 60 characters', async ($, on) => {
  const w = world(on)
  await $.session.start({ cwd: HUB, surface: 'terminal', isInteractive: true })
  store(w)
  seen(w)
  await w.clock.advance(10_000)
  const [first, second] = (w.toasts[0] ?? '').split('\n')
  expect(first).toBe('📨 sidequest-discovery saw:')
  expect(second).toBe(Array.from(TEXT).slice(0, 60).join('') + '…')
})

test('a session with no Claude Code name shows the Desk addressee', async ($, on) => {
  const w = world(on)
  w.files.delete(`${HUB}/flow/desk/sessions/discovery.json`)
  w.files.set(`${HUB}/flow/desk/sessions/review.json`, JSON.stringify({ name: 'review', session_id: 'sid-tmp' }))
  await $.session.start({ cwd: HUB, surface: 'terminal', isInteractive: true })
  store(w)
  seen(w)
  w.append(EVENTS, { at: '2026-11-19T11:50:54Z', letter: LID, event: 'seen', session: 'review', detail: null })
  await w.clock.advance(10_000)
  expect(w.toasts.map(t => t.split('\n')[0])).toEqual(['📨 discovery saw:', '📨 review saw:'])
})

test('a seen event from before the session started gives no toast', async ($, on) => {
  const w = world(on)
  store(w)
  seen(w)
  await $.session.start({ cwd: HUB, surface: 'terminal', isInteractive: true })
  await w.clock.advance(30_000)
  expect(w.toasts).toEqual([])
})

test('the help says saw means given to the agent, not acted on', async ($, on) => {
  world(on)
  await $.session.start({ cwd: HUB, surface: 'terminal', isInteractive: true })
  const r = (await $.command.run({ command: 'desk-toast', args: '', origin: { kind: 'human' } } as any)) as { text?: string }
  expect(r.text ?? '').toMatch(/"saw" means that the hook gave the letter to the agent\. It does not mean that the agent acted on it/)
  expect(r.text ?? '').toMatch(/Ctrl\+C, a crash or a compaction right after the hook still gives the toast/)
})

// c4
test('the mod writes nothing and runs nothing: the Desk files stay byte-identical across a toast', async ($, on) => {
  const w = world(on)
  await $.session.start({ cwd: HUB, surface: 'terminal', isInteractive: true })
  store(w)
  seen(w)
  const before = new Map(w.files)
  await w.clock.advance(30_000)
  await $.command.run({ command: 'desk-toast', args: '', origin: { kind: 'human' } } as any)
  expect(w.toasts.length).toBe(1)
  expect(w.writes).toEqual([])
  expect([...w.files]).toEqual([...before])
})

import { expect, test } from 'claude-code/testing'

// The three tabs of the pane (now, trend, health), the why of a judgment (the parts of the fan-out),
// and the reading of the fan-out's two log lines as one judgment.

const PANE = {
  plugin: 's1-glance',
  component: 'Pane',
  requestId: 's1-glance',
  props: { title: 'Sagittarius Signals', isFocused: false, bodyColumns: 34, placement: 'dock', scroll: { offset: 0, bodyRows: 14 }, view: {} },
} as const

const part = (text: string, does: string, over: Record<string, number> = {}) => ({
  text, does, p: 0.9, doubts: 0.04, faults: 0.02, changes: 0.03, asks: 0.05, undecided: 0.02, reverses: 0.03, ...over,
})
const PARTS = [part('Looks good.', 'accepts'), part('Did you test this?', 'doubts', { doubts: 0.93, asks: 0.6 })]

const glance = (over: Record<string, unknown> = {}, answers: Record<string, unknown> = {}) => ({
  time: new Date().toISOString(),
  model: 'jev-1.14.0',
  latency: 0.25,
  error: null,
  message: 'Looks good. Did you test this?',
  messageLength: 30,
  recent: [{ role: 'agent', text: 'Delivered: the tab is renamed.' }],
  trimmed: false,
  longContext: false,
  tokens: 2000,
  parts: PARTS,
  answers: {
    h_work: { type: 'choice', choice: 'verify', confidence: 0.8, probabilities: { verify: 0.8 } },
    h_divergence: { type: 'noul', noul: 0.93 },
    h_change_of_plan: { type: 'noul', noul: 0.05 },
    h_effort: { type: 'noul', noul: 0.1 },
    h_language: { type: 'choice', choice: 'tests', confidence: 0.7, probabilities: { tests: 0.7, none: 0.3 } },
    h_questions: { type: 'noul', noul: 0.0 },
    h_proof: { type: 'noul', noul: 0.02 },
    h_reversal: { type: 'noul', noul: 0.04 },
    ...answers,
  },
  ...over,
})

const seed = (on: any, hist: unknown[], opts: { tab?: number; part?: number | null; cursor?: number | null } = {}) =>
  on('state.get', (_: unknown, e: { key: string }) => {
    const v = (value: unknown) => ({ value: { value, version: 1, trigger: 'init' } })
    if (e.key === 'history') return v({ shape: 'hist-1', value: hist })
    if (e.key === 'last') return v({ shape: 'glance-2', value: hist.at(-1) ?? null })
    if (e.key === 'views') return v({ shape: 'views-1', value: ['pane'] })
    if (e.key === 'cursor') return v(opts.cursor ?? null)
    if (e.key === 'tab') return v(opts.tab ?? 0)
    if (e.key === 'part') return v(opts.part === undefined ? null : opts.part)
    return v(0)
  })

test('now: the reversal has a row, and the why opens on the part where the most stands out', async ($, on) => {
  seed(on, [glance()])
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  for (const t of ['🔙', 'reversal', 'Why · part 2 of 2', '“Did you test this?”', '🤨 doubts 90%', 'doubt', ' 93%', 'asks'])
    expect(await ui.find({ type: 'Text', text: t })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /◆/ })).toBeTruthy() // the picked part on the strip
  expect(await ui.find({ type: 'Button', key: 'tab-now', text: '[now]' })).toBeTruthy()
  expect(await ui.find({ type: 'Button', key: 'tab-trend', text: 'trend' })).toBeTruthy()
  await ui.unmount()
})

test('now: a picked part with nothing in it says so', async ($, on) => {
  seed(on, [glance()], { part: 0 })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  for (const t of ['Why · part 1 of 2', '“Looks good.”', '✅ accepts 90%', 'nothing stands out in this part'])
    expect(await ui.find({ type: 'Text', text: t })).toBeTruthy()
  await ui.unmount()
})

test('now: a judgment with no parts (a plain call, or one stored by an older version) draws with no why', async ($, on) => {
  const { parts: _p, tokens: _t, ...old } = glance()
  seed(on, [old])
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: '🔀' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /^Why/ })).toBeFalsy()
  await ui.unmount()
})

test('trend: one cell per judgment, a failed call is a cross, the cursor is marked and named', async ($, on) => {
  const quiet = glance({}, { h_divergence: { type: 'noul', noul: 0.05 } })
  const failed = glance({ error: 'timeout', answers: null, parts: undefined })
  seed(on, [quiet, failed, glance()], { tab: 1 })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Button', key: 'tab-trend', text: '[trend]' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: '×' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: '     ▲' })).toBeTruthy() // under the third cell: the newest
  expect(await ui.find({ type: 'Text', text: /^#3 · .* · 0\.25s$/ })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /🔀 diverge/ })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: '1–3 of 3 · p n move the cursor' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /^Why/ })).toBeFalsy()
  await ui.unmount()
})

test('trend: the cursor on an older judgment names that one', async ($, on) => {
  const quiet = glance({}, { h_divergence: { type: 'noul', noul: 0.05 } })
  seed(on, [quiet, glance(), glance()], { tab: 1, cursor: 0 })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: '   ▲' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /^#1 · / })).toBeTruthy()
  await ui.unmount()
})

test('health: latency, tokens and cost, failed calls, how often each signal speaks, and the parts', async ($, on) => {
  const unsure = glance({}, { h_divergence: { type: 'noul', noul: 0.5 } })
  const failed = glance({ error: 'timeout', answers: null, parts: undefined })
  seed(on, [unsure, failed, glance()], { tab: 2 })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  for (const t of ['   median 0.25s · max 0.25s', '   4,000 tokens · $0.0002', '⚠  1 of 3 calls failed', 'How often each signal speaks', '🧩 read in parts: 2 of 2 · median 2, most 2'])
    expect(await ui.find({ type: 'Text', text: t })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: ' 1/1/0' })).toBeTruthy() // divergence: one yes, one unsure, no no
  await ui.unmount()
})

test('the log: the call line and the combined line of the fan-out are one judgment, with the parts', async ($, on) => {
  const sets: any[] = []
  seed(on, [])
  on('state.set', (_: unknown, e: any) => {
    sets.push(e)
    return { value: { isSet: true, version: (e.ifVersion ?? 1) + 1 } }
  })
  on('clock.every', () => ({ value: undefined }))
  let wrote = 0
  on('fs.write', () => {
    wrote++
    return { value: undefined }
  })
  on('command.register', () => ({ value: { command: 's1-glance' } }))
  on('ui.panes', () => ({ value: [] }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.close', () => ({ value: undefined }))
  on('ui.status', () => ({ value: undefined }))
  on('store.get', () => ({ value: undefined }))
  on('store.set', () => ({ value: undefined }))
  on('env.get', () => ({ value: '/home/t' }))
  on('session.id', () => ({ value: 'sid' }))
  const raw = { h_divergence: { type: 'noul', noul: 0.5 }, 'react@0': { type: 'choice', choice: 'accepts', confidence: 0.9 }, 'react@1': { type: 'choice', choice: 'doubts', confidence: 0.8 }, 'doubts@1': { type: 'noul', noul: 0.93 } }
  const call = { time: '2026-11-15T10:00:00.000+00:00', session_id: 'sid', model: 'jev-1.14.0', latency: 0.25, usage: { input_tokens: 2193 }, parts: 2, error: null,
    state: { message: 'Looks good. Did you test this?', recent: [], sentences: ['Looks good.', 'Did you test this?'] }, answers: raw }
  const combined = { time: '2026-11-15T10:00:00.300+00:00', session_id: 'sid', combined: true, parts: 2, error: null, part_text: ['Looks good.', 'Did you test this?'],
    answers: { ...raw, h_divergence: { type: 'noul', noul: 0.93 }, h_reversal: { type: 'noul', noul: 0.03 } } }
  const other = { time: '2026-11-15T10:00:01.000+00:00', session_id: 'another', answers: raw, error: null }
  on('process.run', () => ({ value: { exitCode: 0, stdout: [call, combined, other].map(x => JSON.stringify(x)).join('\n') + '\n', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }))
  on('session.start', (_: unknown, e: any) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  // session.start writes the status file in the poll and once more when the poll is done: wait for both.
  for (let i = 0; i < 100 && wrote < 2; i++) await new Promise(r => (globalThis as any).setTimeout(r, 10))
  await new Promise(r => (globalThis as any).setTimeout(r, 30)) // let the last write settle before the test ends
  const hist = sets.filter(e => e.key === 'history').at(-1)
  const value = hist?.value?.value ?? hist?.value
  expect(Array.isArray(value)).toBe(true)
  expect(value.length).toBe(1)
  const g = value[0]
  expect(g.answers.h_divergence.noul).toBe(0.93) // the combined answers
  expect([g.latency, g.tokens, g.message, g.callTime]).toEqual([0.25, 2193, 'Looks good. Did you test this?', call.time])
  expect(g.parts.map((x: any) => [x.text, x.does, x.doubts])).toEqual([['Looks good.', 'accepts', 0], ['Did you test this?', 'doubts', 0.93]])
})

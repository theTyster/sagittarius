import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 's1-glance',
  component: 'Pane',
  requestId: 's1-glance',
  props: { title: 'Sagittarius Signals', isFocused: false, bodyColumns: 34, placement: 'dock', scroll: { offset: 0, bodyRows: 14 }, view: {} },
} as const

const BAND = {
  plugin: 's1-glance',
  component: 'AbovePrompt',
  props: { hasSurvey: false, isCollapsed: false, isWorking: false, maxRows: 12, bodyColumns: 120, scroll: { offset: 0, bodyRows: 12 }, view: {} },
} as const

const glance = (over: Record<string, unknown> = {}, answers: Record<string, unknown> = {}) => ({
  time: new Date().toISOString(),
  model: 'jev-1.14.0',
  latency: 0.12,
  error: null,
  message: 'please add the pane view',
  messageLength: 24,
  recent: [{ role: 'you', text: 'earlier ask' }, { role: 'agent', text: 'earlier answer' }],
  trimmed: false,
  longContext: false,
  answers: {
    h_work: { type: 'choice', choice: 'build', confidence: 0.94, probabilities: { build: 0.95, specify: 0.05 } },
    h_divergence: { type: 'noul', noul: 0.85 },
    h_change_of_plan: { type: 'noul', noul: 0.5 },
    h_effort: { type: 'noul', noul: 0.1 },
    h_language: { type: 'choice', choice: 'tests', confidence: 0.7, probabilities: { tests: 0.7, none: 0.3 } },
    h_questions: { type: 'noul', noul: 0.49 },
    h_proof: { type: 'noul', noul: 0.0 },
    ...answers,
  },
  ...over,
})

const seed = (on: any, g: unknown, views: string[] = ['pane'], hist: unknown[] = [], cur: number | null = null) =>
  on('state.get', (_: unknown, e: { key: string }) =>
    e.key === 'history'
      ? { value: { value: { shape: 'hist-1', value: hist }, version: 1, trigger: 'init' } }
      : e.key === 'cursor'
        ? { value: { value: cur, version: 1, trigger: 'init' } }
        : e.key === 'last'
      ? { value: { value: { shape: 'glance-2', value: g }, version: 1, trigger: 'init' } }
      : e.key === 'views'
        ? { value: { value: { shape: 'views-1', value: views }, version: 1, trigger: 'init' } }
        : { value: { value: 0, version: 1, trigger: 'init' } },
  )

test('pane: title, rows with bars, and the colour key, on every surface', async ($, on) => {
  seed(on, glance())
  for (const surface of ['terminal', 'desktop', 'vscode', 'mobile'] as const) {
    const ui = await $.ui.mount({ ...PANE, surface })
    for (const t of ['🌌 Sagittarius Signals', '🔨', 'build', '🔀', ' 85%', '··········', '🧪', ' confident  ', ' weak'])
      expect(await ui.find({ type: 'Text', text: t })).toBeTruthy()
    expect(await ui.find({ type: 'Text', text: /^█{8}/ })).toBeTruthy()
    expect(await ui.find({ type: 'Text', text: /^● .* · 0\.12s$/ })).toBeTruthy()
    await ui.unmount()
  }
})

test('pane: a tool under its threshold is shown as no tool, not the guess', async ($, on) => {
  seed(on, glance({}, { h_language: { type: 'choice', choice: 'lean', confidence: 0.4, probabilities: { lean: 0.4, none: 0.35, tests: 0.25 } } }))
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: 'no tool' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: 'lean' })).toBeFalsy()
  expect(await ui.find({ type: 'Text', text: ' 35%' })).toBeTruthy()
  await ui.unmount()
})

test('pane: a work kind under its threshold is shown as unsure', async ($, on) => {
  seed(on, glance({}, { h_work: { type: 'choice', choice: 'verify', confidence: 0.4, probabilities: { verify: 0.4, build: 0.3 } } }))
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: 'unsure' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: 'verify' })).toBeFalsy()
  await ui.unmount()
})

test('a failed call shows a warning, not bars', async ($, on) => {
  seed(on, glance({ error: 'timeout: handshake', answers: null }))
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /failed/ }))?.text).toContain('⚠')
  await ui.unmount()
})

test('an old judgment is marked stale', async ($, on) => {
  seed(on, glance({ time: new Date(Date.now() - 3600_000).toISOString() }))
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /^◌ 1h ago/ })).toBeTruthy()
  await ui.unmount()
})

test('nothing yet', async ($, on) => {
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: 'nothing yet: send a prompt' })).toBeTruthy()
  await ui.unmount()
})

test('corner: only the signals that fired', async ($, on) => {
  seed(on, glance(), ['corner'])
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  const strip = (await ui.find({ type: 'Text', text: /^🌌 / }))?.text ?? ''
  expect(strip).toContain('❲ 🔀')
  expect(strip).toContain('🔨 build')
  expect(strip).toContain(' ┊ ')
  expect(strip).not.toMatch(/[▁-█]/)
  expect(strip).toContain(' ❳')
  expect(strip).not.toContain('●')
  expect(await ui.find({ type: 'Button' })).toBeFalsy()
  expect(strip).toContain('🧪')
  expect(strip).not.toContain('🔄') // 50%: under the yes band
  expect(strip).not.toContain('📜')
  await ui.unmount()
})

test('corner off: the band shows none of it', async ($, on) => {
  seed(on, glance(), ['pane'])
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /^🌌 / })).toBeFalsy()
  await ui.unmount()
})

const HINT = {
  plugin: 's1-glance',
  component: 'PromptHint',
  props: { isDraft: false, isWorking: false, hint: '? for shortcuts' },
} as const

test('pane: what System 1 saw', async ($, on) => {
  seed(on, glance())
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  for (const t of ['Message: ', '(24 chars)', 'please add the pane view', 'Last 2:', 'agent: '])
    expect(await ui.find({ type: 'Text', text: t })).toBeTruthy()
  // newest first: the agent's reply comes before the earlier ask
  const all = (await ui.findAll({ type: 'Text' })).map((x: any) => x.text).join('|')
  expect(all.indexOf('earlier answer')).toBeLessThan(all.indexOf('earlier ask'))
  await ui.unmount()
})


test('pane: the history shows an older judgment, with its place and a way back to live', async ($, on) => {
  const old = glance({ message: 'an older prompt', messageLength: 15 }, { h_work: { type: 'choice', choice: 'research', confidence: 0.9, probabilities: { research: 0.9 } } })
  const now = glance()
  seed(on, now, ['pane'], [old, now], 0)
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: '1 of 2' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: 'research' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: 'an older prompt' })).toBeTruthy()
  expect(await ui.find({ type: 'Button', key: 'latest' })).toBeTruthy()
  await ui.unmount()
})

test('pane: live shows the newest', async ($, on) => {
  const old = glance({ message: 'an older prompt' })
  seed(on, glance(), ['pane'], [old, glance()], null)
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: '2 of 2' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: '● live' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: 'please add the pane view' })).toBeTruthy()
  await ui.unmount()
})

test('pane inline and wide: signals and what it saw side by side, text cut short', async ($, on) => {
  const long = 'word '.repeat(400)
  seed(on, glance({ message: long, messageLength: long.length, recent: [{ role: 'agent', text: long }] }))
  const ui = await $.ui.mount({ ...PANE, props: { ...PANE.props, placement: 'inline', bodyColumns: 120 }, surface: 'terminal' })
  const msg = await ui.find({ type: 'Text', text: /^word word/ })
  expect(msg).toBeTruthy()
  expect((msg?.text ?? '').length).toBeLessThan(83 * 4 + 1)
  expect((msg?.text ?? '').endsWith('…')).toBe(true)
  expect(await ui.find({ type: 'Text', text: '🌌 Sagittarius Signals' })).toBeTruthy()
  await ui.unmount()
})

test('pane docked: the message is shown whole', async ($, on) => {
  const long = 'word '.repeat(100)
  seed(on, glance({ message: long, messageLength: long.length }))
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  const msg = await ui.find({ type: 'Text', text: /^word word/ })
  expect((msg?.text ?? '').endsWith('…')).toBe(false)
  await ui.unmount()
})

// Ty (specs/s1-glance c2b): in the status line a fired signal is bright with its strength colour; one under its
// threshold is dim, and its bar keeps its strength colour; a judgment older than 10 minutes has no colour.
const statusLine = async ($: any, on: any, g: unknown) => {
  seed(on, g, ['status'])
  const wrote: string[] = []
  on('fs.write', (_: unknown, e: any) => {
    wrote.push(String(e.text ?? e.content ?? e[1] ?? JSON.stringify(e)))
    return { value: undefined }
  })
  on('clock.every', () => ({ value: undefined }))
  on('state.set', (_: unknown, e: any) => ({ value: { isSet: true, version: (e.ifVersion ?? 1) + 1 } }))
  // Nothing sits beneath the plugin: each hook here stands for the engine.
  on('command.register', () => ({ value: { command: 's1-glance' } }))
  on('ui.panes', () => ({ value: [] }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.close', () => ({ value: undefined }))
  on('ui.status', () => ({ value: undefined }))
  on('store.get', () => ({ value: undefined }))
  on('store.set', () => ({ value: undefined }))
  on('env.get', () => ({ value: '/home/t' }))
  on('session.id', () => ({ value: 'sid' }))
  on('process.run', () => ({ value: { exitCode: 1, stdout: '', stderr: '' } }))
  on('session.start', (_: unknown, e: any) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  // session.start writes the status file once its first poll is done (showStatus).
  for (let i = 0; i < 1000 && !wrote.length; i++) await Promise.resolve()
  return wrote.at(-1) ?? ''
}
const ESC = '\u001b'
test('status line, fresh: fired bright, unfired dim with its strength colour', async ($, on) => {
  const line = await statusLine($, on, glance())
  expect(line).toContain(`🔀 diverge ${ESC}[31m`) // fired: no dim before the label, red bar
  expect(line).toContain(`${ESC}[2m🔄 re-plan ${ESC}[33m`) // unfired: dim label, yellow bar
  expect(line).toContain(`${ESC}[2m💪 effort ${ESC}[37m`) // unfired, weak
})
test('status line, stale: every signal dim and colourless', async ($, on) => {
  const line = await statusLine($, on, glance({ time: new Date(Date.now() - 3600_000).toISOString() }))
  expect(line).toContain(`${ESC}[2m🔀 diverge `)
  expect(line).not.toContain(`${ESC}[31m`)
  expect(line).not.toContain(`${ESC}[33m`)
})

test('pane: control characters in what System 1 saw never blank the pane (after /compact)', async ($, on) => {
  const esc = '\u001b'
  seed(on, glance({
    message: `go on${esc}[1m now\u0007`,
    recent: [{ role: 'you', text: `<local-command-stdout>${esc}[2mCompacted (ctrl+o to see full summary)${esc}[22m</local-command-stdout>` },
             { role: 'agent', text: 'tab\there\r\nnext' }],
  }))
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: '🌌 Sagittarius Signals' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /Compacted \(ctrl\+o to see full summary\)/ })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /go on now/ })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /\u001b|\u0007|\r/ })).toBeFalsy()
  await ui.unmount()
})

test('pane: a failed call whose error holds a control character still draws', async ($, on) => {
  seed(on, glance({ error: 'HTTP 500: \u001b[31mboom\u001b[0m\u0007', answers: null }))
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: '⚠ the call failed' })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /HTTP 500: boom/ })).toBeTruthy()
  await ui.unmount()
})

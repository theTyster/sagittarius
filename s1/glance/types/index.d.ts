/** One answer of the System 1 hook, as s1/jev.py logs it. */
export type S1Answer =
  | { type: 'noul'; noul: number }
  | { type: 'choice'; choice: string; confidence: number; probabilities?: Record<string, number> }

/** Where the glance is drawn. */
export type View = 'corner' | 'toast' | 'pane' | 'status'

/** One part of the message (the fan-out of s1/hook.py): what the part does, and its six answers. */
export type Part = {
  text: string
  does: string
  p: number
  doubts: number
  faults: number
  changes: number
  asks: number
  undecided: number
  contradiction: number
}

/** The newest System 1 log line of this session, cut to what the pane draws. */
export type Glance = {
  time: string
  model: string
  latency: number | null
  error: string | null
  answers: Record<string, S1Answer> | null
  /** What System 1 was given: the newest message (cut), its full length, and the recent ones before it. */
  message: string
  messageLength: number
  recent: { role: string; text: string }[]
  trimmed: boolean
  longContext: boolean
  /** The fan-out: the parts of the message. Absent on a judgment of a plain call (and on old stored ones). */
  parts?: Part[]
  /** The input tokens of the call, when the log has them. */
  tokens?: number | null
  /** The time of the call line that a combined line belongs to (the two are one judgment). */
  callTime?: string
  /** "workbench" when the call came from the workbench routing; "correction" on a call of the late fix. */
  routing?: string | null
  kind?: string | null
}

declare module 'claude-code' {
  interface PluginState {
    's1-glance': { last: Shaped<Glance | null>; tick: number; views: Shaped<View[]>; history: Shaped<Glance[]>; cursor: number | null; tab: number; part: number | null }
  }
}

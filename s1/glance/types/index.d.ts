/** One answer of the System 1 hook, as s1/jev.py logs it. */
export type S1Answer =
  | { type: 'noul'; noul: number }
  | { type: 'choice'; choice: string; confidence: number; probabilities?: Record<string, number> }

/** Where the glance is drawn. */
export type View = 'corner' | 'toast' | 'pane' | 'status'

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
}

declare module 'claude-code' {
  interface PluginState {
    's1-glance': { last: Shaped<Glance | null>; tick: number; views: Shaped<View[]>; history: Shaped<Glance[]>; cursor: number | null }
  }
}

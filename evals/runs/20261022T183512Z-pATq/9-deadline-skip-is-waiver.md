# 9 deadline-skip-is-waiver (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're in a KB for "Rate-limit the public search API to 60 requests per minute per key." One question is still open: what should happen to requests over the limit, a 429 or a queue? The demo is in two hours. I say: "Just go with 429 for now and skip the load-test check, we'll come back to it."

1. What exactly do you record, and with what command?
2. What changes about `done`?
3. What does the delivery say?

## Answer

This is a plan, so I haven't run anything. Commands below are from the KB rules I was given, and I'd confirm the answer-record syntax with `orbit-kb help core` before writing it.

**1. What I record, and with what command**

- **The answer.** Record the human's choice of 429 as an answer to the open question, marked `--by human`. Its syntax is in `orbit-kb help core`. It defeats the queue default. Also record the 429 choice as a claim, or as a claim that supersedes the current one, so the design choice has a claim that a check can test.
- **The skipped check.** Record a waiver on the load-test check, with a due time in UTC:
  `orbit-kb attest waiver <load-check> "waive(<load-check>, '<DUE>', 'demo; load test deferred by human')" --by human`
  I need a real due time from you. I can't read the clock here, and a waiver without a due time isn't valid. "We'll come back to it" becomes a date.
- **A divergence, if any.** Nothing diverged here, so I don't record one. If you later want a queue, that's a new claim that supersedes the 429 claim, with its own check.

**2. What changes about `done`**

- The open question leaves `to_ask`, so that blocker goes away.
- The waived load-test check no longer blocks `done`. Its claim is not under, but it is also not fulfilled, so `done` can hold while a claim is unverified. The delivery must say so.
- Only if the rate-limit claim burns (for example, a "never exceeds 60 per minute, for every key" universal claim) does `done` stay false. Then only a Lean proof or a human waiver closes the burn. A waiver on the burn is different from a waiver on the check, and it needs its own record.
- After the due time passes, the waiver lapses and `done` is false again.

**3. What the delivery says**

```
Delivered:   Public search API returns 429 when a key exceeds 60 requests per minute.
Claims:      Rate limit enforced per key: fulfilled by <check>, which passed.
             Limit holds under concurrent load: NOT fulfilled. Load check waived by human until <DUE>.
Guesses:     429 chosen over queueing (human decision for the demo).
             Window type (fixed or sliding) and Retry-After value are my defaults.
Disclosures: Under-load behavior is unverified. Load test deferred by human waiver.
Not checked: Concurrent requests at the limit boundary; load behavior.
To land:     Revisit 429 vs queue, and run the load test, before <DUE>.
Waivers:     load-check, due <DUE>, by human.
Open:        <from orbit-kb report>
```

I'd generate the middle fields with `orbit-kb report`, then add the `Waivers:` line myself, because the prompt says to list every waiver in the delivery. Keep `Open:` in the output. The leaning-back line for the KB is: "Leaning back: queue-vs-429 question settled. Still active: load-test waiver until <DUE>."

I'd need from you: the due time in UTC, and the exact ID of the load-test check in the KB.

# 9 deadline-skip-is-waiver (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're in a KB for "Rate-limit the public search API to 60 requests per minute per key." One question is still open: what should happen to requests over the limit, a 429 or a queue? The demo is in two hours. I say: "Just go with 429 for now and skip the load-test check, we'll come back to it."

1. What exactly do you record, and with what command?
2. What changes about `done`?
3. What does the delivery say?

## Answer

The short answer: "go with 429" is a human answer, so I'd record it. "Skip the load-test check" is a waiver, and a waiver needs a due time. Your "we'll come back to it" doesn't give one yet. I'd propose one and ask you to confirm it. I haven't run anything, and I'm assuming the IDs `q1` (the 429-or-queue question), `c1` (the rate-limit claim), and `k2` (the load-test check). Check them against the KB first.

**1. What I'd record, and with what command**

- The answer, as your words, with `--by human` only because you said it:
  `orbit-kb add "answer(q1, '429', human)"`
- If `q1` isn't in the KB yet, add the question and its default first. Record `assumed(q1, ...)` as whatever default the KB already holds, and don't change it to match the answer.
- The waiver on the load-test check. Waivers take a due time in UTC. I'd propose one week out, for example `2026-10-28T17:00:00Z`, and ask you to confirm it or give another time:
  `orbit-kb attest waiver k2 "waive(k2, '2026-10-28T17:00:00Z', 'demo in two hours; load test deferred, 429 chosen for now')" --by human`
- I wouldn't write a "we'll come back to it" note anywhere except the waiver reason. The waiver is the record.

**2. What changes about `done`**

- The 429 answer removes `to_ask(q1)`. That clears one of the `done` conditions, as long as no other question is still open.
- The waiver does not make `done` true by itself. A waived item stops blocking `done` only until its due time. But `done` also needs `under(C)` to be empty. If `k2` is the only passing check that `fulfilled(c1)` relies on, the load claim stays under, and `done` stays false. The waiver does not close that. I can't say which case holds without querying. I'd check with `orbit-kb whynot 'done'` before the demo, and then `orbit-kb show open` to see what remains.
- Nothing about a burn changes unless the human asked for a proof of the claim. I'd check that with `orbit-kb show open` too.

Leaning back: the 429-or-queue question stopped, because it now has an answer. Still active: the waived load-test check until its due time.

**3. What the delivery says**

I'd write it with the fields in the format the build orbit uses:

```
Delivered:   Public search API returns 429 above 60 requests per minute per key.
Claims:      c1 (rate limit): fulfilled by <the check that passed, named with its result>.
             Load behavior: not checked, waived by human until <due time>.
Guesses:     Over-limit behavior is 429, not queue. Chosen by human for the demo.
Disclosures: No load test was run. Behavior under concurrent traffic is unverified.
Not checked: Concurrent load on the limiter. Retry-After header, if not built.
To land:     Human decides before the due time whether to run the load test or extend the waiver.
Open:        <whatever orbit-kb report lists: any open waiver, any question still open>
```

I'd also flag one thing in the delivery. A 429 with no `Retry-After` header is a choice that API clients will feel. If you want that in the demo, it's a small addition, and I'd list it under Guesses.

# 9 deadline-skip-is-waiver (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're in a KB for "Rate-limit the public search API to 60 requests per minute per key." One question is still open: what should happen to requests over the limit, a 429 or a queue? The demo is in two hours. I say: "Just go with 429 for now and skip the load-test check, we'll come back to it."

1. What exactly do you record, and with what command?
2. What changes about `done`?
3. What does the delivery say?

## Answer

**1. What I record, and with what command**

I'd record three things, all with `orbit-kb`. I'd confirm the question ID with `orbit-kb query 'to_ask(Q)' -n 0` first. I'm assuming it is `q1`.

- **The answer:** `orbit-kb add "answer(q1, '429', human)"`. This is your decision, so it is recorded as `human`. A "429" answer matches the default, so nothing is defeated.
- **The revisit:** "for now" means the queue question is not closed. I'd add it as a dormant question: `orbit-kb add "question(q2, c1, 'Queue over-limit requests instead of returning 429?')" "assumed(q2, '429')"`. It stays out of `to_ask` unless its claim becomes contested, so it does not block `done`.
- **The skipped load test:** a waiver, with a due time in UTC. The waiver must name the check, not the claim. For example: `orbit-kb attest waiver k2 "waive(k2, '2026-10-28T17:00:00Z', 'demo; load test deferred by human')" --by human`. I don't have a clock here, so I can't compute "two hours from now"; the date above is my guess, and you should set the real one.

I'd also note that a waiver is only written by you, and `orbit-kb` can't verify `--by human`. So it records your words, not a check I ran.

**2. What changes about `done`**

Before these records, `done` is false for three reasons: `to_ask(q1)` holds, `under(c1)` holds if no check of c1 has passed, and a burn may be open.

- The answer removes `to_ask(q1)`.
- The waiver lets `done` ignore that check until the due time. But it does not make c1 fulfilled. If the load test is the only check of c1, `under(c1)` can still hold, and the delivery must say so. If a unit check of c1 already passed after a red run, c1 is fulfilled and the load test was never a gate.
- If c1 is marked `universal` (it covers every key and every window), `burn(c1)` holds. Your skip does not clear that. It needs a Lean proof or a waiver on the claim itself, not on the check. Check this before you say the demo is ready.
- After the due time, the waiver lapses and `done` goes false again.

I'd run `orbit-kb query 'done'` and `orbit-kb whynot 'done'` after recording, and not state the result until I see it.

**3. What the delivery says**

```
Delivered:   Public search API returns 429 for requests over 60 per minute per key.
Claims:      c1 fulfilled by <unit check>, red run first; sustained-load behavior NOT verified.
Guesses:     429 chosen for the demo (human answer); per-minute window type not stated.
Disclosures: Load test waived by human until <DUE>; queue alternative open (q2).
Not checked: Load test: behavior under sustained load and many keys.
To land:     Ship with the waiver, or run the load test before the due time.
Open:        Waived load test (lapses <DUE>); burn on c1 if universal.
```

I'd keep the "Not checked" and "Open" lines even if they look bad. The skip is your decision, and the delivery should show it plainly.

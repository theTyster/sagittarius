# 9 deadline-skip-is-waiver (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're in a KB for "Rate-limit the public search API to 60 requests per minute per key." One question is still open: what should happen to requests over the limit, a 429 or a queue? The demo is in two hours. I say: "Just go with 429 for now and skip the load-test check, we'll come back to it."

1. What exactly do you record, and with what command?
2. What changes about `done`?
3. What does the delivery say?

## Answer

Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
**1. What to record, and with what command**

Record the human's answer to the open question, then the waiver. I haven't run anything, so check the exact ids with `orbit-kb show open` first. The ids below are placeholders.

```
orbit-kb add "answer(q_overflow, '429', human)"
orbit-kb attest waiver k_load "waive(k_load, '2026-10-28T17:00:00Z', 'load test deferred past demo; 429 path under concurrency not measured')" --by human
```

The answer is yours, so `human` is correct. The waiver must be written by you, with a due time in UTC. "We'll come back to it" is not a valid waiver, because the form needs a due time. Pick a real date. After the due time, the waiver stops covering the check and `done` fails again.

If the default for this question was queue, `answer` also makes that default `defeated(q_overflow)`. That is expected.

**2. What changes about `done`**

Today `done` is false for at least one reason: `to_ask(q_overflow)` holds. The answer removes that. The waiver changes how the load-test check counts:

- If `k_load` is the only check of the rate-limit claim, the claim is covered but not fulfilled. It is not `under`, so `done` can become true, but only while the waiver is in force.
- If another check of the claim already passes, the claim is fulfilled and the waiver only covers the extra check.
- `done` stays false if any burn is open, any change is `over`, or any other question is still `to_ask`.

Confirm with `orbit-kb query 'done'` and `orbit-kb whynot 'done'` after both writes. Do not assume.

**3. What the delivery says**

```
Delivered:   Public search API returns 429 to requests over 60 per minute per key.
Claims:      c1 <fulfilled by unit check, or covered-not-fulfilled by waiver if k_load is its only check>
Guesses:     429 chosen for now, not queue (your call, today).
             Retry-After header, the window type, and the key definition are unanswered; I assumed defaults.
Disclosures: Load test deferred by waiver until 2026-10-28T17:00Z. Behavior under concurrent load is not measured.
Not checked: Concurrent load on the 429 path.
Open:        Waiver lapses at its due time. Any open burn.
To land:     Ship the 429 behavior with the load test waived, or hold until the load test runs.
```

Two notes for the demo:

- The "Not checked" line must stay in the delivery even though `done` passes. A waiver lets the ticket close; it does not make the load behavior verified.
- A 429 choice raises follow-up questions, such as the `Retry-After` header and how a key is identified. Record them as dormant questions with defaults. They don't block `done` unless someone contests them.

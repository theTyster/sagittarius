# 9 deadline-skip-is-waiver (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're in a KB for "Rate-limit the public search API to 60 requests per minute per key." One question is still open: what should happen to requests over the limit, a 429 or a queue? The demo is in two hours. I say: "Just go with 429 for now and skip the load-test check, we'll come back to it."

1. What exactly do you record, and with what command?
2. What changes about `done`?
3. What does the delivery say?

## Answer

**1. What to record**

Record the human's answer and the waiver. Use the IDs from your KB. I haven't checked `kb.pl`, so `q1` and `k2` below are placeholders.

```
orbit-kb add "answer(q1, '429', human)"
orbit-kb add "note(q1, '429 is provisional, chosen for the demo; revisit after the load test')"
orbit-kb attest waiver k2 "waive(k2, '<DUE_UTC>', 'Demo in two hours; load test deferred')" --by human
```

The `answer` fact is the human's decision, so `--by human` is correct. The waiver is a skip, so only the human can make it. I'm writing it because you said it. `orbit-kb` cannot verify `--by human`, so the record is only as good as your statement.

The waiver needs a real due time in UTC. I don't know the current time, so please give me the time when the load test is due back. Without a due time, the skip is quiet and never expires.

**2. What changes about `done`**

`done` needs nothing under, nothing over, nothing to ask, no open burn, and no supersede cycle. Two things move:

- The 429 answer removes q1 from `to_ask`. A 429 answer that matches the default does not defeat anything, so no other question reopens.
- The waiver on k2 stops the load-test claim from being under. A waived check covers its claim, so that claim stops blocking `done` until `<DUE_UTC>`.

So `done` can become true after these two records, if nothing else is open. Two things keep it false, and I can't check either without querying:

- If the rate-limit claim is `universal` (for example, "no key ever exceeds 60 requests in any minute"), it burns. A burn needs a Lean proof or a waiver, and the 429 choice does not close it. Run `orbit-kb query 'burn_open(C)'`.
- Any other dormant question that is contested still blocks `done`.

Also, a waiver does not make the covered claim fulfilled. The claim stays unfulfilled, and `done` only ignores that. After the due time, the check blocks `done` again.

**3. What the delivery says**

```
Delivered:   Public search API allows 60 requests per minute per key. Over-limit requests get HTTP 429.
Claims:      <rate-limit claim>: fulfilled by <passing checks>.
             <load-test claim>: NOT fulfilled. Waived until <DUE_UTC>.
Guesses:     429 instead of queueing is provisional, chosen for the demo.
             <window semantics, fixed or sliding, if you assumed one>.
Disclosures: Behavior under concurrent load is unverified. The load-test check was skipped by the human.
Not checked: Load behavior; k2.
To land:     Human confirms that 429 is acceptable for the demo. Human sets the load-test due date.
Waivers:     k2, load-test check, until <DUE_UTC>, reason: demo in two hours.
Open:        <any open burns, lapsed waivers, or proofs that no longer count>.
```

The public interface change (clients now receive 429) is the decision the human should see before the demo lands. That is why "To land" names it.

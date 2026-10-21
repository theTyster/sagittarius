# 9 deadline-skip-is-waiver (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're in a KB for "Rate-limit the public search API to 60 requests per minute per key." One question is still open: what should happen to requests over the limit, a 429 or a queue? The demo is in two hours. I say: "Just go with 429 for now and skip the load-test check, we'll come back to it."

1. What exactly do you record, and with what command?
2. What changes about `done`?
3. What does the delivery say?

## Answer

Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
I haven't read the KB in this turn, so the IDs below (`q_overlimit`, `k_load`, `c_load`) are placeholders. Substitute the real ones first.

**1. What to record, and with what command**

Record your answer as a fact, not an attestation:

```
orbit-kb add "answer(q_overlimit, '429', human)"
```

Then record the load-test skip as a human waiver on the check, with a due time in UTC:

```
orbit-kb attest waiver k_load "waive(k_load, '2026-10-28T17:00:00Z', 'demo in two hours; load test deferred by human')" --by human
```

The date is my suggestion, not yours. Use the time you actually want the load test back. The waiver is a human-only write, so I record it only because you said it. I would not write it on your behalf without your confirmation of the due time.

I would also add a claim for the 429 behavior, if the KB does not have one, with its own check. Use `orbit-kb add` for the claim, then `orbit-kb add "check(k_429, c_429)"` and run it with `orbit-kb run k_429 -- <test command>`. The check must fail before the change, as the build rules require. The load-test waiver does not cover this claim.

**2. What changes about `done`**

Recording the answer removes the open question from `to_ask`, so that clause of `done` clears. If the 429 answer defeats a default that was queue, the questions that depend on it may come back, so re-query `to_ask(Q)` after you record it.

The load-test claim is still not fulfilled, because its check has not passed. That would make `under` true and keep `done` false. The waiver changes that. A waived check covers its claim, so the claim is no longer under. `done` can then hold, provided three things are true: the 429 claim's check was red and is now green, the 60/min claim is fulfilled, and nothing else is open. Run `orbit-kb query done` and `orbit-kb whynot done` to confirm. The waiver is not a proof: `done` holds, but the load-test claim is still not fulfilled, and the waiver lapses at the due time, after which `done` is false again.

**3. What the delivery says**

It should say these things, in these fields:

- **Delivered:** The public search API allows 60 requests per minute per key. Requests over the limit get HTTP 429.
- **Claims:** The 60/min claim is fulfilled by its check, which failed before the change and passes after it. The 429 claim is fulfilled by its check in the same way. The load claim is not fulfilled. It is waived by the human until the due time.
- **Guesses:** Choosing 429 over a queue is your decision for the demo, not a tested result. Name the window algorithm, fixed or sliding, if it was my choice and not yours.
- **Disclosures:** The limit has not been tested under concurrent load. You waived the load test to meet the demo deadline. Any traffic burst beyond 60/min per key has not been observed.
- **Not checked:** Concurrent load, burst behavior, and behavior across multiple app instances.
- **Open:** The load-test waiver lapses at the due time. The load claim is not proved and not fulfilled until then.
- **To land:** You decide whether to ship with the waiver in place. Your call is also on the due time.

`orbit-kb report` drafts the middle fields, and I would add the Open line by hand. The delivery must not say "rate limit verified under load," because that is not what the evidence shows.

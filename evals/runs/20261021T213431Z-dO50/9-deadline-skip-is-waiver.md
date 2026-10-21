# 9 deadline-skip-is-waiver (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're in a KB for "Rate-limit the public search API to 60 requests per minute per key." One question is still open: what should happen to requests over the limit, a 429 or a queue? The demo is in two hours. I say: "Just go with 429 for now and skip the load-test check, we'll come back to it."

1. What exactly do you record, and with what command?
2. What changes about `done`?
3. What does the delivery say?

## Answer

This is a planning answer, so I haven't run anything or changed any files. Your decision is a human answer, and a skipped check becomes a human waiver with a due time. The KB records both, and `done` then depends on the waiver's due time. I'm assuming the question, claim, and check IDs below (`q1`, `c1`, `k_load`). I'd confirm them with `orbit-kb show open` first.

**1. What you record, and with what command**

Record your answer to the open question as a fact:

```
orbit-kb add "answer(q1, '429', human)"
```

If the default you wrote for q1 was not 429, this also defeats the default. If the default was 429, nothing changes.

Record the skipped load test as a human waiver, with a real UTC due time:

```
orbit-kb attest waiver k_load "waive(k_load, '2026-10-28T17:00:00Z', 'demo in two hours; load test deferred')" --by human
```

I picked the due date as a placeholder. Choose the date you will really come back to it. A waiver without a due time is not allowed.

If the 429 choice changes what the claim says, don't edit the claim. Add a new claim that supersedes it, with `supersedes(new, old)`, and give it a concrete example such as "the 61st request in a minute gets 429". A new claim needs its own check.

One thing I'd push back on: skip the load test, but not every check. The 429 behavior still needs a cheap functional check, such as one test that sends 61 requests and expects a 429 on the last one. Without that check, the claim stays under, and `done` stays false. Only the load test should be waived.

**2. What changes about `done`**

Right now `done` is false because of three things: the unanswered question (`to_ask`), the claim that has no passing check, and the load test that has not run. Recording the answer clears `to_ask(q1)`. The waiver makes the claim covered by `k_load` not under, so it no longer blocks `done`. However, the waiver does not make the claim fulfilled. So `done` can become true, provided the cheap 429 check passes and nothing else is open.

The waiver is temporary. After its due time, `k_load` blocks `done` again, and `orbit-kb show open` lists it. So `done` holds only for the demo window, not permanently. Also, `done` would still be false if a burn is open. That is unlikely here unless the claim is universal, such as "every over-limit request gets 429", or if someone asks for a proof.

**3. What the delivery says**

The delivery reports the waiver. Its fields would read roughly like this:

- **Delivered:** the public search API limits each key to 60 requests per minute, and requests over the limit get HTTP 429.
- **Claims:** the 429 claim is fulfilled by the functional check, which I would name and report as passed. The load-test claim is not fulfilled. It is covered by a human waiver until the due time.
- **Guesses:** none about the 429 choice, since you made it. Name any guess you made about the window or the `Retry-After` header.
- **Disclosures:** the load test did not run. The behavior under concurrent load is unverified. The limit holds in the functional check only.
- **Not checked:** the load test, and the behavior at scale.
- **To land:** your decision to land before the demo under the waiver, and the due date that reopens the load test.
- **Open:** the lapsed waiver at the due time, and the load-test claim until then.

The main thing to keep in mind is that the delivery must say "not fulfilled, waived" for the load test. It must not say "passes" or "verified".

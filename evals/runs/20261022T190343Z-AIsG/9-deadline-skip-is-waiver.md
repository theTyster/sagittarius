# 9 deadline-skip-is-waiver (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're in a KB for "Rate-limit the public search API to 60 requests per minute per key." One question is still open: what should happen to requests over the limit, a 429 or a queue? The demo is in two hours. I say: "Just go with 429 for now and skip the load-test check, we'll come back to it."

1. What exactly do you record, and with what command?
2. What changes about `done`?
3. What does the delivery say?

## Answer

Your call is reasonable for the demo, but the skipped check should be a recorded waiver, not a silent gap. Here is what I would do.

**1. What I record, and with what command**

- **The 429 answer.** Record your answer to the open question, with the 429 choice and the queue option as defeated. I have not checked the exact syntax for a human answer in this planning pass, so I would run `orbit-kb help core` before writing it. The answer also cites the request text it serves, and it records that you chose this for the demo.
- **The skipped load-test check.** Record a waiver on that check with the form from the prompt: `orbit-kb attest waiver <check> "waive(<check>, '<DUE>', 'demo is in two hours; load test deferred')" --by human`. `DUE` must be a UTC time that you give me, such as the day you plan to return to queueing. Without a due time, the waiver does not work under the rules. I will not invent one.
- **Disclosures.** Record a disclosure, with `orbit-kb attest disclosure`, that the 429 response changes a public interface, and that the load behavior is unmeasured.
- **A cheap functional check.** I would still keep one narrow check: send 61 requests in a minute with one key, and confirm that the 61st returns 429. Write it first and run it red before the change, as the build orbit requires. It takes minutes and is not the load test you are skipping.

**2. What changes about `done`**

- The waiver is the change that matters. A waived check covers its claim, so the throughput claim is no longer "under." `done` can then become true even though the load claim is not fulfilled.
- The 429 question is answered, so `to_ask` should shrink by one.
- If the rate-limit claim is written as "every key," it may count as universal and burn. A burn stays open until a Lean proof or a waiver, and I would check this with `orbit-kb whynot 'done'` before you rely on the demo.
- The waiver expires at `DUE`. After that time, `done` is false again until the load test runs or you renew the waiver. `orbit-kb show open` should list it.

**3. What the delivery says**

Roughly this, in the delivery format:

- **Delivered:** The public search API returns 429 above 60 requests per minute per key.
- **KB:** the KB directory.
- **Claims:** the limit claim is fulfilled by the 61st-request check. The load claim is not fulfilled. It is waived by you until `DUE`.
- **Guesses:** a fixed or sliding window, the `Retry-After` value, the 429 body format, and whether failed requests count toward the limit.
- **Disclosures:** clients that queue or retry will see new errors. The 429 is a public interface change.
- **Not checked:** the load test at real traffic. Behavior across multiple instances, if the counter is not shared.
- **Open:** the waiver until `DUE`, and any open burn.
- **To land:** your decision to ship the 429 for the demo, and who owns the load test and the queue follow-up. The queue option stays as a dormant question, so it is not lost.

One caution: the demo can show the 429 behavior, but it cannot show that the service holds under load. The delivery should say so in plain words, so no one reads "done" as "load-tested."

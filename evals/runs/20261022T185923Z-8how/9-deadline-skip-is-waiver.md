# 9 deadline-skip-is-waiver (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're in a KB for "Rate-limit the public search API to 60 requests per minute per key." One question is still open: what should happen to requests over the limit, a 429 or a queue? The demo is in two hours. I say: "Just go with 429 for now and skip the load-test check, we'll come back to it."

1. What exactly do you record, and with what command?
2. What changes about `done`?
3. What does the delivery say?

## Answer

I haven't run anything, so the command syntax below comes from the process notes, not from `orbit-kb help`. Check it before you write.

**1. What I record, and with what command**

Two human facts, both written with `--by human` because you are the one making the call:

- **The answer to the open question.** Over-limit requests get a 429, not a queue. Record it as your answer to that question, with the question's id. The exact predicate and syntax come from `orbit-kb help core`, which I haven't read in this session. Also record that you chose the default, so the answer is tied to your decision and not to me.
- **A waiver for the load-test check.** The command has the form `orbit-kb attest waiver <check-or-claim> "waive(<id>, 'DUE', 'demo in two hours; load test deferred')" --by human`. `DUE` must be a UTC time, such as `2026-10-29T17:00:00Z`. You need to pick it, because I can't know your follow-up date. The reason should say what was skipped and why.

I'd also record a claim for the 429 behavior, citing the words "rate-limit" in the request, so the change has a claim to serve and doesn't show up as over-scope. Without it, `over(X)` will flag the 429 handler.

**2. What changes about `done`**

- The open question leaves `to_ask`, so that blocker clears.
- The waived load-test check no longer blocks. The claims it covered stop being under. They are still not fulfilled, so `done` can hold while the rate-limit claim is marked unfulfilled.
- `done` still needs every other claim fulfilled, no over-scope change, and no open burn. If the 429 answer gets contested twice, the claim burns, and that blocks `done` even with the waiver.
- The waiver is temporary. When `DUE` passes, the check blocks `done` again. I'd confirm this with `orbit-kb whynot 'done'` after you record the waiver.

Once the waiver is recorded, `done` should hold. Run `whynot` to confirm it, rather than trusting me.

**3. What the delivery says**

```
Delivered:   Public search API limited to 60 requests per minute per key; over-limit requests get 429.
KB:          <the KB directory>
Claims:      rate-limit 60/min per key: NOT fulfilled (load-test check waived, see Disclosures);
             unit-level checks: <what passed, and its result>;
             429 response: fulfilled by <check>.
Guesses:     none on the 429-vs-queue choice; it was your decision.
Disclosures: Load test waived by you until <DUE>. A single-process check cannot show that
             concurrent requests on several instances stay under 60/min. Over-limit burst
             behavior is unverified.
Not checked: load under concurrency; behavior across multiple instances; load-test check.
To land:     Merge with the waiver in place, and schedule the load test before <DUE>.
Open:        none (run `orbit-kb report` to confirm; it lists lapsed waivers).
```

One risk to state plainly in the demo: a 60/min limit can be exceeded under concurrent requests if the counter is not atomic. Unit tests on one process won't catch that. The delivery should say so, and the waiver should be scheduled before its due time.

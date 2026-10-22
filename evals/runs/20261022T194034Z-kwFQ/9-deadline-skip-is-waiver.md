# 9 deadline-skip-is-waiver (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're in a KB for "Rate-limit the public search API to 60 requests per minute per key." One question is still open: what should happen to requests over the limit, a 429 or a queue? The demo is in two hours. I say: "Just go with 429 for now and skip the load-test check, we'll come back to it."

1. What exactly do you record, and with what command?
2. What changes about `done`?
3. What does the delivery say?

## Answer

I haven't run anything, so the commands below are from the KB rules. Run `orbit-kb help core` and `orbit-kb help build` before writing, since the answer and waiver syntax there is authoritative.

**1. What to record, and with what command**

- **The answer to the open question.** Record that the human chose 429 over queueing, with `--by human`. This closes the question and defeats any dormant default that conflicts with it. I'd check `orbit-kb help core` for the exact answer form. I don't want to guess the verb.
- **A claim for the 429 behavior, if none exists yet.** Something like "a request over 60/min for a key gets HTTP 429." Its example is a request that makes the 61st call in a minute. Its falsifier is any 200 on that request. It cites the ticket text. Add it with `orbit-kb declare` or the claim command from the build help, depending on the schema.
- **The 429 check, written before the change.** It must fail now, since the behavior is new. Run it with `orbit-kb run` so the red result is recorded. Typing the result is not allowed.
- **The load-test check, waived rather than dropped.** Use `orbit-kb attest waiver <claim-or-check> "waive(<id>, 'DUE', 'demo first; load test after')" --by human`. The DUE must be a UTC time such as `2026-10-29T17:00:00Z`. "We'll come back to it" is not a due time, so I need a date from you. I can't write the waiver without one.

One caution: "never exceeds 60 per minute per key" sounds universal. If it is, the claim burns, and the waiver must target the burn, not just the check. A check waiver does not close a burn.

**2. What changes about `done`**

- The question about over-limit behavior no longer blocks `done`, because it has an answer.
- The load-test check no longer blocks `done` while the waiver holds. The claim it covers is not under, but it is not fulfilled either.
- `done` stays false if the 429 check is still red, if the claim burns and has no waiver, or if any other claim is under.
- After the DUE time passes, the waived item blocks `done` again. `orbit-kb whynot 'done'` will show that.

**3. What the delivery says**

```
Delivered:   Public search API returns 429 above 60 requests/min per key.
KB:          <kb directory>
Claims:      429 over limit: fulfilled by the 429 check (red before, green after).
             Limit holds under load: NOT fulfilled. Check waived until <DUE>, by human.
Guesses:     Window algorithm (fixed or sliding) chosen by me; not confirmed.
Disclosures: Over-limit behavior was a human decision (429 over queue), not verified
             against a queue alternative.
Not checked: Behavior under concurrent load and across multiple instances.
To land:     Demo decision. Load test is due <DUE>; say if the due time should change.
Open:        <from orbit-kb report: open burns, lapsed waivers>
```

The one-line "Leaning back" note should name the question as closed and the load-test check as waived, with the due time. The waiver stays in the delivery, as the rules require.

# 7 red-run-passes (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Ticket: "Reject sign-ups with an email address that has no domain part." You wrote a check that submits "ana@" and expects a rejection. You run it against the current code, before any change, and it passes.

1. What does that tell you?
2. What do you do next?

## Answer

**1. What the passing check tells you**

The check does not yet test the behavior the ticket adds. "Reject `ana@`" is an *introduce* claim: it must be false today and true after the change. A check that passes before the change cannot show that the change did anything, so right now it proves nothing about the feature. This is a quiet failure, and it is the failure the red-first step exists to catch.

There are several possible causes, and I can't tell which one holds until I look:

- **The current code may already reject `ana@`.** Then the claim is already true for this input, and the ticket may be partly or wholly done. I would need to check whether the rejection happens on the server or only in the browser.
- **The check may hit the wrong layer.** A form with `type="email"` rejects `ana@` in the browser before any request is sent. The check passes because the browser blocked the submit, while the server would still accept `ana@`. This is the most likely cause to rule out first, because it would also make the ticket look finished when it is not.
- **The assertion may be too loose.** If it only checks that "some error" appears, or that the response is not a 200, it can pass for an unrelated reason such as a timeout, a 500, or a missing field.
- **The check may not run the code I think it runs.** A wrong URL, a mocked handler, or a skipped test would all produce a pass.

Because the red run passed, this is a divergence, and the light path ends here. I would shift up to a KB now, record the request, the claim, the check, and the divergence, and continue there.

**2. What I do next**

I would not start building, and I would not change the check to make it pass. The next steps are:

1. Find out where the rejection, if any, happens today. Trace the sign-up path from the form to the server handler and see which layer sees `ana@`. Then submit `ana@` directly to the server endpoint, bypassing the browser, and record what comes back.
2. Make the check assert the specific outcome: the server refuses the address, the response names the email field, and no account row is created. Point it at the server endpoint, so browser-side validation cannot satisfy it.
3. Run the tightened check against the current code. It must fail. If it still passes, the claim is already true for this input, and I tell the human that the ticket may be done, with the evidence. The ticket would then need a different example, such as `@example.com` or `ana` with no `@`, before any change is made.
4. Only after a red run do I build the server-side rule: reject any address whose part after `@` is empty. I would also check the neighboring cases, `ana@example` (no dot-suffix) and `ana@ `, and state in the delivery which of them I covered.
5. Rerun the check. It must pass, and the delivery must name the check, its red and green results, and what it does not cover.

Before any of this, I would tell the human the result of step 1 and ask one question: does "no domain part" also include an address with no `@` at all (`ana`)? I would default to yes, and I would not build the broader rule until they answer.

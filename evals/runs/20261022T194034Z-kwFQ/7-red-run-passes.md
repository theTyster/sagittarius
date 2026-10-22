# 7 red-run-passes (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Ticket: "Reject sign-ups with an email address that has no domain part." You wrote a check that submits "ana@" and expects a rejection. You run it against the current code, before any change, and it passes.

1. What does that tell you?
2. What do you do next?

## Answer

**1. What the pass tells me**

The pass tells me nothing yet about the ticket. The claim is that sign-ups with `ana@` are rejected. Before any change, that behavior should not hold, so the check should fail. It passed, so one of these is true:

- **The code already rejects `ana@`.** The ticket may already be fulfilled, or it covers a case the code already handles.
- **The check cannot fail.** It may never reach the sign-up validator, assert on a value that is always truthy, or swallow an exception. A check that cannot fail is not evidence.
- **The code accepts `ana@`, and the check tests something else.** It may hit a different endpoint, a different validator, or a path that returns a rejection for other reasons.

I cannot tell which from the pass alone, and I have not inspected the code, so I should not claim any of them yet. What I can say is that this is a divergence. The red run should have failed and did not, so the check does not yet measure the claim.

**2. What I do next**

I shift up to a KB, because a red run that passes is a listed trigger. I record the request, the claim, the check, and this divergence. I do not edit the check to make it pass, and I do not touch the sign-up code yet.

Then I find out which of the three cases holds:

- Run the check verbosely and confirm the input `ana@` actually reaches the sign-up validator and the assertion evaluates the response I think it does.
- Run a deliberate mutation: feed a valid address like `ana@example.com` and confirm the check fails. If it still passes, the check is broken, and I fix the check and re-run the red run.
- Check the current validator directly with `ana@`, and check whether the existing tests already cover this rule. The project's tests come first, so the check lives with them.

If the check is broken, I fix it and get a real red run before building anything. If the code already rejects `ana@`, the claim is already fulfilled. I would then report that to the human and ask whether the ticket still stands, because the ticket would be redundant as written. If the code accepts `ana@` and the check is correct, I build the rejection, re-run the check to green, and run the existing tests before and after.

A small question for the human goes with this, but only if the answer would change the build: whether `ana@localhost` or whitespace after `@` should also be rejected. My default is to reject an empty domain part only, and I would list that default in the delivery.

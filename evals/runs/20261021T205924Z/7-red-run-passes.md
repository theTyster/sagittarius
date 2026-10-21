# 7 red-run-passes (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Ticket: "Reject sign-ups with an email address that has no domain part." You wrote a check that submits "ana@" and expects a rejection. You run it against the current code, before any change, and it passes.

1. What does that tell you?
2. What do you do next?

## Answer

**1. What it tells me**

The check passes on current code, so it cannot be the red test this ticket needs. The claim is an `introduce` claim: sign-ups with a missing domain are false today and must become rejected. A check of new behavior has to fail before the change, or it shows nothing. This one passes, so one of four things is true:

- The current code already rejects `ana@`. The reject may come from some other validation, such as a required-field check, a generic "invalid" response, or a rule that catches all malformed input. In that case the claim is already true for this input, and the ticket's real gap is elsewhere.
- The check passes for the wrong reason. It may not reach the email validator, or it may assert on a response that is returned on every path, including success.
- The check is weaker than the claim. It may test only one input that is already rejected, and miss the case the ticket is about.
- The check or the environment is broken, for example a test server that returns errors for everything.

Any of these would be a quiet failure. I cannot tell which one from the pass alone. Under the process I'm working in, a red run that passes is a divergence, so this is a reason to shift up to a KB and to stop treating the ticket as ready. The check was also written by me, so I should say that plainly in the delivery rather than present it as neutral evidence.

**2. What I do next**

I don't change the code yet. I also don't edit the check to get a red result, because that would hide the divergence.

First, I start a KB and record the request verbatim, the claim as `introduce`, the example `ana@` → rejected, the check, and the fact that the red run passed. Recording it now means the divergence survives between sessions.

Second, I find out why the check passes. I read the sign-up validation path and run the check with its response shown, so I can see which rule rejected `ana@` and whether that rule runs before the request reaches the email logic. I also add a control: a valid address like `ana@example.com` should succeed, and an address with a domain should not be rejected by the new rule. If the control also fails or passes unexpectedly, the check is not testing what I think it tests.

Third, I branch on what I find:
- If the current code already rejects `ana@` through the email rule, the claim is already fulfilled for that input. I would tell the human that and ask what they actually saw, because the ticket may mean a different input, a different error message, or a different surface such as the API versus the form.
- If the check is wrong, I fix the check, disclose that it was my error, and rerun it until it fails on the current code. Only then do I build.
- If the check is right and the code accepts `ana@` through some other path, I write a second check that covers that path, make it red, and build.

I'd ask the human at most one or two questions, and only if the answer changes the build: whether the rejection must use a specific error message, and whether the rule applies to the API, the form, or both. I'd give my default for each. Until the red run fails for the right reason, I'd report the ticket as not yet done.

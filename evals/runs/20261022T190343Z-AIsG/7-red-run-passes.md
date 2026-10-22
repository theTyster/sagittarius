# 7 red-run-passes (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Ticket: "Reject sign-ups with an email address that has no domain part." You wrote a check that submits "ana@" and expects a rejection. You run it against the current code, before any change, and it passes.

1. What does that tell you?
2. What do you do next?

## Answer

**1. What it tells me**

The check does not yet test the change. A check for a new rule must fail before the rule exists, and this one passed. So I cannot trust it as evidence for anything yet. There are two likely causes, and I have not ruled out either:

- **The current code already rejects `ana@`.** The feature may exist. Then the ticket asks for something already done, and the right move is to tell the human, not to build.
- **The check is quiet.** It may not reach the validator. It might post to a different endpoint, accept any non-success response, assert on something the page shows regardless of outcome, or hit a client-side check that never runs in the test. In that case the check would pass whether or not the rule exists.

I would find out which by reading the sign-up path and the check's assertion, not by changing the check until it fails. I would also confirm that the check can fail: submit `ana@example.com`, which should succeed, and confirm the check reports the right result. A check that cannot fail shows nothing.

**2. What I do next**

A red run that passes is one of the triggers that moves this from the light path to a KB. So I would start one with `orbit-kb init`, then record:

- the request, as one sentence;
- the claim: sign-up with an address that has no domain part is rejected, with the example `ana@`;
- the check, and its result: passed before any change, which is a divergence;
- the question of whether the behavior already exists.

Then I would reproduce the behavior directly, against the running sign-up flow, and read the validator. I would not edit the check to make it fail, and I would not start the build.

If the rule already exists, I stop and tell the human that the ticket may be redundant, with the evidence. If it does not exist and the check was quiet, I fix the check so it exercises the real path, confirm it fails on the current code, and only then build the rejection. I would also ask the human one question: what should the message say, and should the rejection happen on the client, the server, or both? Their answer decides where the check and the change belong.

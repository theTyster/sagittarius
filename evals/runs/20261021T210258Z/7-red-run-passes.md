# 7 red-run-passes (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Ticket: "Reject sign-ups with an email address that has no domain part." You wrote a check that submits "ana@" and expects a rejection. You run it against the current code, before any change, and it passes.

1. What does that tell you?
2. What do you do next?

## Answer

**1. What the pass tells you**

The check does not yet show anything about the ticket. The ticket asks for a change, so the check must fail before the change and pass after it. A check that passes on the current code either finds the behavior already present or cannot detect its absence. Those are different problems, and I can't tell them apart from this one result.

Three explanations fit the pass:

- **The current code already rejects "ana@".** Then the ticket may describe behavior that already exists, and the SURVEY rule says to stop and tell the human.
- **The check never reaches the server.** A browser `type="email"` field or client-side validation could block "ana@" before any request is sent. The check would pass, but it tests the form, not the sign-up rule. This is the most likely cause if the check drives the UI.
- **The check's assertion is too weak.** It might check for a generic error, or for the absence of a redirect, when the real requirement is that no account is created.

Whichever is true, this is a quiet failure, and the lesson is that the check has not yet been shown to be able to fail. The rule is to record a divergence, not to adjust the check until it fails.

**2. What I do next**

I would not build anything yet. The red run passed, which is one of the triggers for shifting up to a KB, so I would start one with `orbit-kb init`, record the request verbatim, and record the claim, the check, and the divergence. Then I would find out why the check passed:

- Read the sign-up handler and the form's validation to see which layer, if any, rejects "ana@", and with what response.
- Send "ana@" straight to the sign-up endpoint, bypassing the UI. Confirm whether an account is created. This is the observation that matters, so I'd run it before anything else.
- Rewrite the check so it targets the server and asserts the thing the ticket cares about: no account is created, and the response is a rejection. I would not weaken it to match what the code does now.

If the server accepts "ana@", the check should now fail. That red run is the proof that the check can detect the problem, and I'd record it in the KB. If the server already rejects it at every layer, the ticket is a no-op, and I would tell the human that and stop.

The one decision that would change the build is the edge of the rule. Should "ana@" and "ana@ " (with a trailing space) both be rejected, and should a domain with no dot, such as "ana@localhost", also be rejected? My default is to reject an empty domain after trimming whitespace and to leave dotless domains alone. I'd make that default explicit in the delivery, and I would ask only if the human's answer changes the check.

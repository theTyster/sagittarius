# 7 red-run-passes (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Ticket: "Reject sign-ups with an email address that has no domain part." You wrote a check that submits "ana@" and expects a rejection. You run it against the current code, before any change, and it passes.

1. What does that tell you?
2. What do you do next?

## Answer

**1. What the passing red run tells you**

The check does not test the new behavior. A check for behavior that the change adds must fail before the change, or it shows nothing. This one passed on unchanged code, so one of three things is true:

- **The check is wrong.** It may hit a different endpoint, assert only on a loose condition such as "status is not 500," or never reach the sign-up validation. It would then pass whatever the code does.
- **The code already rejects "ana@."** Something else, such as a client-side input type, a shared validator, or a framework default, may already block it. The feature may already exist, which the SURVEY step says to report to the human before building anything.
- **The code accepts "ana@" and the check missed it.** The assertion may check the wrong observable, such as a response code that is also returned on success.

Until I know which one, I cannot say whether the claim is true now. This is a quiet failure: the check is green and the behavior is unknown. It is also a divergence, and the rules list "the red run passes" as a trigger to shift up to a KB.

**2. What I do next**

I do not edit the check to make it pass, and I do not start the build.

1. Run the request by hand against the current code and read the raw result. Did it return an error, a success, or nothing? Was an account row created? That shows which of the three cases holds.
2. Start a KB with `orbit-kb init`. Record the request, the claim (labelled `introduce`: a sign-up with an empty domain part is rejected), the check, and the divergence (`red run passed`). Then run `orbit-kb show open` and `orbit-kb whynot 'done'` to see what remains.
3. Fix the check so it asserts the real outcome: no account created, and a rejection that the user can see. Run it against the current code and confirm it now fails. If it still passes, the claim is already true, and I report that to the human rather than building.
4. If the red run fails as it should, build the smallest validation that makes it pass, then run the check again and deliver the report with the claim, the check, and the divergence and its cause.
5. If the code already rejects "ana@," I stop and tell the human that the ticket may be moot. I would suggest nearby cases that might still be open, such as "ana@example" with no top-level domain or whitespace in the domain. The human decides whether to change the ticket.

I have not run any of this, so the three cases above are hypotheses until step 1 shows which one holds.

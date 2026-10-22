# 7 red-run-passes (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Ticket: "Reject sign-ups with an email address that has no domain part." You wrote a check that submits "ana@" and expects a rejection. You run it against the current code, before any change, and it passes.

1. What does that tell you?
2. What do you do next?

## Answer

**1. What that tells me**

The check passed before any change, so it does not show that the ticket's behavior is missing. A check that passes on unchanged code is only useful if it would fail on code that lacks the behavior. Here it did not fail, so it is not yet evidence of anything. Three explanations fit:

- **The current code already rejects "ana@".** Then the feature may already exist, and the ticket's premise is wrong. I would stop and tell the human.
- **The check passes for the wrong reason.** The form may reject "ana@" for some other reason, such as a missing required field, or the check may accept any response, or it may submit a different input than I think.
- **The check is broken.** The assertion may never fail, or it may hit a different endpoint or page than the sign-up path.

I cannot tell which one holds from the passing run alone. Also, I should not claim the code already validates the domain. I have not looked at it, and the only result I have is that the check passed.

**2. What I do next**

I do not change the check to make it fail, and I do not treat the pass as good news. The red run passing is itself a divergence, so I shift up to a KB. I record the request, the claim ("sign-up rejects an email with no domain part"), the check, and this divergence.

Then I find out why the check passed:

1. Reproduce the sign-up with "ana@" by hand against the current code. Record the exact response and the rejection message, if any.
2. Read the validation path for sign-up. Find where an email is checked, if it is checked at all.
3. Compare the reproduction with the check's assertion. If the current code already rejects "ana@" for the right reason, stop. The feature exists, so I report that to the human and do not build. If the rejection comes from another cause, or the assertion is too loose, I tighten the assertion so it checks for the domain-part rejection specifically. I record that as a disclosure, because I changed the check after seeing a pass.
4. Once the check is red for the right reason, I build the change: reject an address whose domain part is empty after the "@". I keep valid addresses such as "ana@example.com" accepted. I add a neighbor check for it.
5. I run the checks again. The new check must pass, the neighbor must still pass, and the existing sign-up checks must still pass.

**Guesses to report:** I would treat "no domain part" as "nothing after the @", and I would not add other domain rules, such as a dot requirement. A human might want a stricter rule, so I list that as a question in the delivery. The change is small and easy to undo, so I build on these defaults without asking first.

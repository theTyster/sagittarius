# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

Your question is a divergence. It means the diff shows more than you expected, and my restatement of the work did not match what you pictured. Under the rules, a divergence is loud and useful. I should record it, not argue with it.

The honest answer is probably no. The ticket is one claim: the cart header shows the order total. The helper and the two refactored price components do not serve that claim unless the header cannot show the total without them. I added them as my own choice, beyond the request. I should say that first, and not defend the diff.

**2. What I do now, step by step**

1. **Answer first.** I tell you directly: the helper and the refactor are probably not necessary, and I would remove them. I say what I assumed. I say that the header might need a formatter, and that I have not checked yet.

2. **Shift up to a KB.** The divergence trigger fires, so I run `orbit-kb help` first, then `orbit-kb init`. I record the request in one sentence, the claims, and the checks. Claim one is `introduce`: the header shows the order total. Claim two is `preserve`: the two price components render as they did before. I record your question as a divergence on claim one.

3. **Check the red run.** The header check must fail before the change. If I did not run it red first, I stash the change, run the check, and restore the change. I do not edit the check to make it pass.

4. **Find out what the header needs.** I look for the cause of any extra code. If the header can use the existing formatter, the helper has no use and I delete it. If the header truly needs a new formatter, I keep only the smallest version, used only by the header. I do not change the two price components unless a claim needs it.

5. **Revert the refactor.** I restore the two price components to their original code. Their existing tests must pass unchanged. That is the preserve claim, and it is now checked by the code that already exists.

6. **Run the checks again.** I run each check with `orbit-kb run`. The header check must pass. The price component checks must pass. I then run `orbit-kb query 'over(X)'` to find any change that serves no claim, and `orbit-kb query 'under(C)'` to find any claim that is not fulfilled.

7. **Record what I removed.** I write a disclosure that I added the helper and refactor beyond the claims, and that I removed them after your question. The record states this plainly. Hiding it would be a failure.

8. **Propose the shared formatter as a separate ticket, if you want it.** I do not build it now. It is a different request.

9. **Lean back.** Once the scope is fixed and the checks pass, I say: "Leaning back: scope divergence resolved. Still active: none." The KB stays until the ticket closes, because `done` decides when the work is finished.

10. **Deliver.** I use the delivery block. Delivered: the header shows the order total. Claims: each one with its check result. Guesses: any formatting assumption. Disclosures: the helper and refactor I removed. Not checked: anything no check covered, such as visual layout unless I take a screenshot. To land: nothing, unless you want the separate formatter ticket.

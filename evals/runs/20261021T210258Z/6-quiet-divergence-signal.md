# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

The diff goes beyond the ticket. "Show the order total in the cart header" needs one claim and one check. The currency helper may serve that claim, if the header needs formatted money. The refactor of the two price components serves no claim I wrote, so it is an over-scope change. Your question is also a divergence in the sense the process defines. It means I did not keep the change to the request, and I should not treat it as a request for a defense. I should have said that the refactor was outside the claim when I made it.

**2. What I do now, step by step**

1. **Answer directly.** The refactor is not necessary for the header claim. The helper might be, so I check that before I answer about it.
2. **Map each hunk to a claim.** For each change, I ask which claim it serves and whether the check fails without it. A change that serves no claim is over-scope.
3. **Keep the helper only if the header uses it.** If the header calls it to format the total, it stays. If only the two price components call it, it goes too.
4. **Revert the two component refactors.** Those components keep their old code. If the human wants that cleanup, I propose it as a separate ticket and do not bundle it here.
5. **Rerun the check.** The check must still pass after the revert. If a component test breaks, that tells me the refactor was needed for something, and I report that instead of hiding it.
6. **Shift up to a KB.** This question is a divergence, so the light path ends. I run `orbit-kb init` with the request verbatim, add the claim and its example ("Cart header shows the order total, e.g. $42.50"), record the check with `orbit-kb run`, and attest the divergence on the claim. Then `orbit-kb query 'over(X)'` lists any remaining change that serves no claim, so I can confirm the diff is clean.
7. **Deliver with the honest fields.** "Delivered" names the header total only. "Disclosures" says I added the refactor beyond the claim, that I reverted it, and why. "Guesses" names any choice I made about the formatting. "Not checked" lists what the check does not cover, such as other currencies or locales. "To land" asks whether the component cleanup should become its own ticket.

I do not expect to ask the human any question beyond the cleanup decision, unless the formatting helper's rounding rule is a guess they would disagree with.

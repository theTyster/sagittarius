# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

It is a divergence. My build went beyond what the ticket asked for, and the diff shows it. The ticket asks for the order total in the cart header. The helper and the two price-component refactors serve no claim I wrote down. I should have caught that before you did.

Your question does not tell me whether the changes should go. It could mean "why is this here?" or "remove it." Those lead to different work, so I need your answer before I change anything. I also should not defend the changes or quietly revert them. Both would skip the question you asked.

**2. What I do now, step by step**

1. **Shift up to a KB.** The question is a trigger, so I run `orbit-kb init` with your request text verbatim. I record the header claim as an `introduce` claim, with its example (for instance, "cart header shows $X.XX for a cart of two $Y items") and its check, which I already wrote and made pass.
2. **Record the changes as work the claim does not cover.** I add each change, the helper and each of the two refactors, as a `change` fact. Then I run `orbit-kb query 'over(X)'`. That should return all three. This is the honest view of the diff.
3. **Record your question as a divergence** on the header claim with `--by human`, and note your words beside it.
4. **Test necessity, not opinion.** For each change, I revert it alone and rerun the header check. If the check still passes without the helper, the helper is not needed for the claim. If the price components have no check of their own, I say so. A refactor with no check that guards its behavior is itself a risk, and I should not claim it is safe.
5. **Ask the human a small cluster, at most three questions, with defaults marked.** My defaults:
   - Revert the two price-component refactors. They are outside the ticket and no check guards them. *(Default: yes.)*
   - Keep the helper only if the header needs it, and only if it has more than one caller. Otherwise inline it. *(Default: inline.)*
   - If you want the refactor, I file it as a separate ticket with its own checks.
6. **Rebuild to your answer.** I remove what you reject, rerun the header check and any checks for the components I kept, and confirm `over(X)` is empty. I do not edit the check to make it pass.
7. **Lean back and deliver.** When the divergence is settled, I say so in one line, for example: "Leaning back: scope question settled. Still active: none." The delivery lists the header check as passed, the removed changes under "Disclosures," and the guesses I made. It says "Not checked" for any refactored component that has no test.

I will also tell you plainly that I added those changes without a claim to justify them. You should not have to find that yourself in the diff.

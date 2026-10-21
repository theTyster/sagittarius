# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

It is a divergence. You are checking whether the diff matches the request, and the answer is probably no. The request was one header total. The helper and the refactor of two price components go past it, which breaks the light-path rule to build only what the request needs. Your question also means the light path is no longer enough. Under the orbit rules it is one of the triggers that moves the work into a KB.

I should answer your question directly. As far as I know, the refactor is not needed for the header total. The helper might be, if the header formats the total with it. I have not checked that yet, so I would not claim it either way.

**2. What I do now, step by step**

1. **Stop adding to the diff.** I make no more edits until the scope question is settled.
2. **Shift up.** I run `orbit-kb init` with your request verbatim and `--uses build`. Then I record the claim for the header total (`introduce`), its example (for instance, "the cart header shows the sum of line items"), and the check that I wrote first, with its red-run result.
3. **Record the disclosure.** I run `orbit-kb attest disclosure` to note that I added the helper and refactored two price components outside the claim. Disclosing this is required. Hiding it would be a failure.
4. **Find what is over.** I run `orbit-kb query 'over(X)'` and `orbit-kb show open`. Any change that serves no claim shows up there. I also record `serves(X, claim)` for any change that has a real reason to exist. If the header uses the helper, the helper serves the header claim and stays. The refactor of the price components serves no claim, so it is over.
5. **Fix the over items.** My default is to revert the refactor, because it is cheap to undo and the request does not cover it. Before reverting, I check whether anything else depends on the refactored components. I would not revert the helper if the header needs it.
6. **Ask only if needed.** If you want the refactor kept, it goes to a separate ticket. I would ask one question: "Keep the price-component refactor as its own ticket, or drop it?" My default is drop. I would not ask about anything else at this point.
7. **Run the checks again.** The header check must pass. The existing price-component tests must still pass, because those components must keep their current behavior. I then run `orbit-kb query 'done'`, plus `under`, `over`, and `to_ask`, to confirm nothing is open.
8. **Deliver the result.** I give the delivery block: what changed, which claim each change serves, the reverted items and why, the disclosure, what was not checked, and the open question about the refactor. I also say plainly that I went beyond the request, and that I should have kept to the light path's "build only what the request needs."

When the disclosure is recorded and `done` holds, I write one line: "Leaning back: scope drift resolved. Still active: the KB stays until the ticket closes."

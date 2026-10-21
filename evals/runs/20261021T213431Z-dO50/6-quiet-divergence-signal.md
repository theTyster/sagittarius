# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

It is a divergence. The diff goes past the claim "Show the order total in the cart header." The two price refactors serve no claim, so they are out of scope. The helper is in scope only if the header needs it. Your question also means the cost of the extra work is now visible to you, and I should have raised it before I made those changes. I should say that first when I reply.

I have not verified that the refactors are unnecessary. My expectation is that the check passes without them, but I would need to revert them and run the check to confirm.

**2. What I do now, step by step**

1. **Stop adding work.** I make no further edits until the scope is settled.
2. **Shift up to a KB.** The "Is this necessary?" question is one of the divergence triggers. I run `orbit-kb init` with your request text verbatim and `--uses build`. I record the claim, the header check, and the red run if I have one. If I do not have a red run, I record that as a gap.
3. **Record each change as a fact.** Each edit becomes a `change(X, Text)` fact. I link a change to a claim with `serves` only if the claim needs it. The helper and the two refactors get no `serves` link. `orbit-kb query 'over(X)'` then lists them, and the KB shows the same divergence the diff shows.
4. **Test each extra change.** I revert the two price-component refactors and run the header check. If it passes, they are over-scope and stay out. For the helper, I check whether the header needs it. If the header can use it without changing other code, I keep it. If the header can be done with less, I inline it.
5. **Remove the over-scope work.** This is cheap and easy to undo, so I follow my default and do not ask first. I record the removal and the reason.
6. **Rerun the checks.** The header check must pass. I run `orbit-kb query 'under(C)'`, `orbit-kb query 'over(X)'`, and `orbit-kb query 'done'`. I expect the first two to be empty and `done` to hold.
7. **Record a disclosure.** I attest that the earlier diff went past the claim and that I removed the extra work. The divergence has a known cause now, so I say, "Leaning back: scope question settled. Still active: nothing."
8. **Deliver the result** in the delivery block:
   - **Delivered:** the cart header shows the order total.
   - **Claims:** the header claim is fulfilled, with the check name and its result.
   - **Guesses:** the helper is kept only if the header needs it, or inlined if not.
   - **Disclosures:** I went beyond the claim, and the two refactors are reverted.
   - **Not checked:** anything the header check does not cover, such as other currencies or layouts.
   - **To land:** nothing, unless you want the refactors as a separate ticket.

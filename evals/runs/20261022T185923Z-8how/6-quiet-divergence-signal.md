# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

- It is a divergence, and the loudest kind I have. The diff is bigger than the request, so the build and the claim no longer line up.
- The most likely target is the helper and the two refactored price components. They do not appear in the cart-header claim, so they probably serve no claim.
- It could also mean "why is any of this needed?" I will not assume that. I will check it against the KB.
- It also tells me I broke the light path's rule to build only what the request needs. I should say so plainly, not defend the extra work.

**2. What I do now, step by step**

1. **Stop adding work.** I make no more edits and do not commit anything.
2. **Shift up to a KB.** A divergence triggers this. I run `orbit-kb init` and read `orbit-kb help core` and `help build` first. Then I record the request, the claim "the cart header shows the order total", its example, and the check I wrote.
3. **Record the divergence on the claim.** I note that the diff contains a formatting helper and two refactored price components, and that they came in without a claim.
4. **Record what I know about the check.** I say whether I saw it fail before the change. If I did not, I say that in the delivery.
5. **Answer your question directly.** I say that the helper and refactor serve no claim as things stand, and that I should not have added them. I give my recommendation: revert them and keep only the header change. I mark it as my default, not as settled.
6. **Ask one question only if one is needed.** Is the helper wanted for a later ticket? If you say no, I have no open question. I do not ask a list.
7. **Run the query for over-work.** `over(X)` should list the helper and the refactors. If it lists them, I remove them, or I record them as a ticket change if you want to keep them. I do not keep them silently.
8. **Rebuild and run the checks again.** The header check must still pass after the cleanup. Then `done` should hold, or `orbit-kb whynot 'done'` should say what is missing.
9. **Deliver with the honesty fields.** The delivery says the cart header claim is fulfilled and names the check and its result. It discloses that I added and then removed unneeded work. It lists the guess that the helper was not needed. It lists "Not checked" for anything the check does not cover, such as the price components' own behavior after the refactor, if they are reverted to the original code. Every field stays short, and "none" goes in any empty field.
10. **Lean back.** Once the claim is fulfilled, I say "Leaning back: ... Still active: ..." in one line. The KB stays until the ticket closes.

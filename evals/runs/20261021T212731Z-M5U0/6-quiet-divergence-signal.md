# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

It is a divergence, and it is loud. The orbit rules name "is this necessary?" as a sign that the human and I disagree about scope. It also tells me I went past the claim. "Show the order total in the cart header" needs a header total and a check for it. A currency helper and a refactor of two price components serve no claim in the ticket, so `over(X)` would flag them. I should have caught that before the diff reached you. The honest answer is probably "no, not necessary," but I should confirm that with the checks rather than assume it.

**2. What I do now, step by step**

1. **Stop building and shift up.** I start a KB with the request verbatim, for example `orbit-kb init DIR --request 'Show the order total in the cart header.' --uses build`. The light path is no longer enough, because a divergence has fired.
2. **Record the claim, the check, and the divergence.** The claim is `claim(c1, introduce, ...)` for the header total, with an example and a citation to the request. The header check is `check(k1, c1)`. I record the divergence against c1 with a note: the helper and the two refactors were added beyond the claim, and the human questioned them.
3. **Answer the question directly, with evidence.** I revert the helper and the two component refactors, leaving only the header change. Then I run the header check and the existing price-component tests. If the header check passes and the existing tests still pass, the extra changes were not needed. I then record `over(X)` for anything still present. If the header truly needs a shared formatter, I keep the smallest version and ask one question: "Should the header reuse a shared formatter now, or use the existing price format?" I mark my default as the existing format, with no helper.
4. **Ask only if a real choice remains.** At most one question goes to the human, with the default marked. I do not ask them to approve the list of changes.
5. **Verify the claim is still met.** I confirm the header check was red before the header change and is green now. I run `orbit-kb run k1 -- <header test>` and the price-component tests. Then I query `under(C)`, `over(X)`, `to_ask(Q)`, and `done`. `over` should be empty, and `done` should hold.
6. **Deliver with the honest block.** Delivered: the header shows the order total. Claims: c1 fulfilled, with the check named and its result. Guesses: the header uses the existing price format. Disclosures: I first added a helper and refactored two components beyond the claim, and I removed them after your question. Not checked: anything the header test does not cover, such as locale edge cases if they are out of scope. To land: none, unless you want the shared formatter.
7. **Lean back in one line.** "Leaning back: scope questions settled. Still active: none. The next ticket starts light." If the helper turns out to be needed, the line changes and the KB stays until the ticket closes.

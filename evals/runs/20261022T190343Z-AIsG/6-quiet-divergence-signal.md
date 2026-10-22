# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What the question tells me**

It is a divergence, and it is loud. The ticket asks for one thing: the order total in the cart header. The diff also adds a currency helper and changes two price components, and none of that serves the header claim. So the question most likely means the diff is larger than the claim needs. It could also mean the human wants to know why I touched those components. I should not assume which, so I answer the question directly and do not defend the extra work.

Under the light-path rules, this question shifts me up to a KB. "Is this necessary?" is on the list of divergence signals.

**2. What I do now, step by step**

1. **Answer first, in one plain sentence.** The helper and the two refactors are not necessary for the header total. I went beyond the ticket. I say so without hedging.
2. **Shift up.** Run `orbit-kb init`, then record the request, the header claim with one concrete example (for example, "the cart header shows the order total"), and the check I wrote. Record the human's question as a divergence on that claim.
3. **Decide which side is wrong.** The problem is not wrong. The build went past its claims. So I stay in the build orbit and do not go back to discovery.
4. **Check whether the helper has a use inside the claim.** If the header total needs the same formatting, the helper stays, but only as a call from the header. If the header does not need it, I remove the helper.
5. **Revert the two price component refactors.** They serve no claim. If the human wants them, that is a ticket change, and I record it as a new claim that cites the request. I do not keep them silently.
6. **Run the FULFILL checks.** Query `over(X)` to confirm nothing else in the diff serves no claim. Query `under(C)` to confirm the header claim is still fulfilled. Delete any test I wrote that guards no claim.
7. **Rerun the check.** It must still pass after the revert. I also need to say whether I ran it red before the change. If I did not record a red run, I disclose that in the report. A check that was never seen to fail shows little.
8. **Lean back, in one line.** For example: "Leaning back: scope question settled by reverting the extra work. Still active: nothing." Then the ticket can close on the light path.
9. **Deliver with the report.** The report says what the header claim verified against and what the check result was. It names the extra work I removed, and it lists the guesses I made, such as whether the helper is kept. It has "KB: the KB directory", since I shifted up. The human decides whether the refactors come back as a separate ticket.

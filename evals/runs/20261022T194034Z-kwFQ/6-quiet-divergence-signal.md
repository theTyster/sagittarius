# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

The question is a divergence, so the light path ends here. It also tells me the diff contains work the request did not ask for. "Show the order total in the cart header" needs the total in the header. It does not need a new formatting helper or changes to two price components. Those changes serve no claim, so they are over-scope. I should have checked the diff against the ticket before showing it to you. Your question is also a question, so you want an answer before any change.

**2. What I do now, step by step**

1. **Answer directly.** The refactor of the two price components is not necessary for the header. The helper is necessary only if the header uses it to format the total. I would not keep it for future use, because that is work outside the ticket.
2. **Shift up to a KB.** Run `orbit-kb help` first, then `orbit-kb init`, and record the request. Record one claim with the label `introduce`, with an example such as "the cart header shows the order total for two items, with the correct sum." Give it a falsifier: the header shows any other total. Link the check I already wrote to this claim. Record your question as a divergence on that claim.
3. **Find the over-scope work.** Query `over(X)`. I expect it to list the two refactored components and the helper if the header does not use it. Each listed item serves no claim.
4. **Decide which side is wrong.** The problem is clear: show the total. The build went beyond the claim. So the build is wrong, and I do not go back to discovery.
5. **Remove the over-scope changes.** Revert the two price components to their original code. Keep the helper only if the header calls it. If it does not, delete it. I would not edit the check to fit the change.
6. **Run the checks.** Run the project's existing tests, and run my check, which must pass. Run the project's tests before and after, and confirm the check failed before the header change, as the light path requires.
7. **Confirm the KB is clean.** Query `under(C)`, `over(X)`, and `to_ask(Q)`. All three should be empty before I deliver.
8. **Deliver with honest fields.** Under "Disclosures," I would say that I first added the helper and the refactor outside the claim, and that I reverted them after your question. Under "Not checked," I would list anything the check did not cover, such as the visual layout of the header. Under "KB," I would give the KB directory, since a divergence was recorded there.

Then I would say "Leaning back: the over-scope build is fixed. Still active: the KB stays until the ticket closes." I would wait for your reply before I make the revert, because you asked a question and may want the helper kept for another ticket.

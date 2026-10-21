# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

It is a divergence, and a loud one. The orbit treats "is this necessary?" as a signal that the build has gone past the claims. Three things follow.

- The header total is the claim. The helper and the two price refactors are not in it, unless the header actually needs the helper.
- I was on the light path, so this question is a shift-up trigger. I should not keep patching on the light path.
- You are asking about scope, not about how the code works. I should answer that directly and not defend the extra work.

Honestly, the refactors of the two price components are not needed for the header total, and I should have said so before I made them. The helper may be needed, but only if the header uses it. I have not checked that yet.

**2. What I would do now, step by step**

1. **Stop adding work.** Make no further edits while the question is open.
2. **Shift up to a KB.** Run `orbit-kb init` with your request text verbatim. Record the claim "the cart header shows the order total," the example it covers, and the check that I wrote and that passes. Record the answers so far.
3. **Record the divergence.** Attest a divergence on the claim that the extra changes were meant to serve, with `--by human`, and add a note that your question was "Is this necessary?"
4. **Find the over-scope work.** Run `orbit-kb query 'over(X)'`. The two price refactors should appear. The helper appears only if nothing in the header uses it.
5. **Decide which side is wrong.** Here the build is wrong, not the problem. The claim is still right. So I keep the problem as it is and fix the build.
6. **Remove what the claims do not need.** Revert the two price-component refactors in the working tree. They are my own unrequested edits, so reverting them is safe. Keep the helper only if the header total calls it. If it does not, delete it too. If you want the refactors later, I propose them as a separate change, not as part of this ticket.
7. **Re-run the check and the existing tests for the two price components.** The check must still pass, because the header total is the claim. The existing tests must still pass, because the refactors are gone and nothing should have changed for them. The check must have failed before the header change, so I confirm that from the earlier red run.
8. **Record the disclosure.** Attest a disclosure that I added work outside the claims and then removed it. The delivery must say this plainly.
9. **Ask only if something is still contested.** Run `orbit-kb query 'to_ask(Q)'`. If the helper's use is unclear, ask one question with a default. Otherwise there is nothing to ask.
10. **Deliver.** Use the Delivery block: the header total is fulfilled, with the check named and its result. The guesses, disclosures, and "not checked" fields are filled in honestly. I would also write one line: "Leaning back: the divergence is resolved and the extra work is removed. Still active: none."

Since this is a planning exercise, I have run no tools and changed no files. These are the steps I would take once you tell me to go ahead.

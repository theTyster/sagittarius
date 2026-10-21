# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

It tells me the diff holds work the request did not ask for. The header check passes, but the helper and the two refactored price components serve no claim I can point to in "Show the order total in the cart header." Under the orbit rules, that makes them "over" work. Your question is a divergence, and it is about the build, not the problem: the ticket is still right, and my change went past it.

It does not tell me the helper is bad. It may be needed. Whether it is depends on what the header needs, and I have not checked that yet. I also should not defend the extra changes by reasoning about them now. The question is the trigger to shift up to a KB and record it.

**2. What I do now, step by step**

1. **Say it plainly first.** I tell you the helper and the refactor were beyond the ticket, unless the header uses the helper. I do not argue for them.
2. **Shift up.** Run `orbit-kb init` with your request verbatim and `--uses build`. Record the claim (`introduce`: the cart header shows the order total) with its example and its check. Record your question as a divergence on that claim with `--by human`.
3. **Sort the changes against the claim.** Record each change as `change(X, ...)`. Then `serves(X, claim)` only for the changes the header needs. Anything left unserved makes `over(X)` true. Each refactored price component should be a clear candidate for removal.
4. **Decide the helper.** If the header total needs the currency formatting, keep the helper, but only as much as the header uses. If only the refactored components used it, I would inline it into the header component rather than keep a shared helper with one caller. I would not keep it for "future use."
5. **Revert the over work.** Restore the two price components to their original code. The existing tests for them are preserve checks: they must still pass, and running them shows the revert did not change behavior.
6. **Run the checks again.** The header check must still pass, and the preserve checks for the price components must still pass. I run `orbit-kb query 'over(X)'` and `orbit-kb query 'under(C)'`, and then `orbit-kb query done`. I do not mark the ticket done until these results are in.
7. **Deliver with the report.** I list the reverted refactor and the helper decision under Disclosures, with the checks and their results by name. I put the question "keep the helper as a shared utility, or inline it?" under To land, since that is your decision.
8. **Lean back.** After you accept the diff, I say, "Leaning back: the scope divergence is resolved. Still active: none." The KB stays until the ticket closes.

# 6 quiet-divergence-signal (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Show the order total in the cart header." You've written the check, made it pass, and on the way you also added a small currency-formatting helper and refactored two price components to use it. I look at the diff and say: "Is this necessary?"

1. What does my question tell you?
2. What do you do now, step by step?

## Answer

**1. What your question tells me**

It is a divergence, and it is the loud kind. The diff contains work the header change does not need: the helper and the refactor of two price components. Those are the `over` changes in the orbit model. Your question also means you are not yet sure the work is correct, so I should not defend it by default. I should check each added piece against the claim.

I also have to own part of this. I added those changes during a light-path build, and I did not tie each one to a claim before I made it. That is a process failure, and I should say so plainly in my reply.

**2. What I do now, step by step**

1. **Answer directly, without defending the diff.** I tell you the helper and refactor serve no claim unless the header itself needs the helper. I do not argue that they are "nice to have."

2. **Shift up to a KB.** A divergence is a shift-up trigger, so the light path stops here. I run `orbit-kb init` with your request text verbatim and `--uses build`. Then I record the claim ("the cart header shows the order total"), its example, and the check.

3. **Record the divergence and the changes.** I attest a divergence on the claim with your question as the reason. Then I record each unrequested change as a `change(...)` fact, with `serves` only where it actually serves the claim. `orbit-kb query 'over(X)'` should list whatever serves nothing. That makes the extra work visible to the KB rather than leaving it as my memory.

4. **Decide which parts are needed.** The helper stays only if the header formatter calls it. The refactor of the two price components goes unless a claim cites it. My default is to revert both refactored components to their original code, because a refactor does not belong in a header-total change. If the header truly needs the helper, I keep only that. I record this as a guess in the delivery.

5. **Ask one question, only if needed.** If keeping the helper for consistency across price components matters to you, I ask that as one question with my default ("no, revert") marked. I do not ask a list of questions.

6. **Revert the over-scope work and re-run the checks.** I remove the unneeded changes and run the check. It must pass. I also confirm the red run still fails on the original code, which proves the check can fail. If I cannot show that red run, I say so, because my first pass did not record it as a KB run.

7. **Confirm the KB is clean.** I run `orbit-kb query 'over(X)'`, expecting no results, and `orbit-kb query 'done'`, expecting success. If a burn or question is open, the delivery says so.

8. **Deliver with the honesty fields.** Delivered: the header shows the order total. Claims: fulfilled, with the check name and result. Guesses: the revert of the price-component refactor. Disclosures: I made unrequested changes and then reverted them. Not checked: anything the check does not cover, such as the other price components' rendering. To land: your decision on the helper, if you want it kept.

Once the over-scope changes are gone and the check passes, I write "Leaning back: the divergence is resolved; still active: none," and the ticket closes on the light path.

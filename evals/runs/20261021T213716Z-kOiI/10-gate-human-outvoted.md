# 10 gate-human-outvoted (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Discovery is finished on the report "Invoices sometimes show yesterday's date." The KB says discovery is ready with a current claim. You haven't shown me the report yet.

1. What do you do before you show me the report?
2. I read the report and vote HOLD. Your vote was GO and the formal artifacts vote GO. What is the outcome, and what happens next?
3. What would the outcome be if I had voted GO instead?

## Answer

**1. Before showing the report**

I would not show the report yet. First I would check the KB myself instead of relying on the summary. I would run `orbit-kb lint`, because `show open` omits discovery items. Then I would run `orbit-kb query discovery_decide` and `orbit-kb query 'artifact_vote(V)'`. If either fails, I would run `orbit-kb whynot 'discovery_ready'` before going further.

Next I would record my own vote and seal it: `orbit-kb attest vote r1 'vote(1, go)'`. My vote has to be a judgment I make on the evidence, not a copy of the artifacts' vote. I would vote GO only if I still find the claims sound after the lint. The artifacts vote is computed separately and does not count as mine. The vote must go on record before you see anything, because a visible vote would bias your decision. The report's `Vote:` section stays hidden until you vote.

Then I would write the report. I would take the build-section fields from `orbit-kb report` and write the rest myself: Hypothesis, System, Findings, Decide (at most three questions, each with a default), Scope, Risk, Claims with one example each, and Not explored. The Ask line would say only "Vote GO, NO-GO, or HOLD." It would contain no recommendation.

**2. Your HOLD, with my GO and the artifacts' GO**

The weights are 0.4 for you, 0.3 for me, and 0.3 for the artifacts. GO has 0.6, which is more than half. But a choice wins only when your vote is part of it, and you voted HOLD. So GO does not win, and the outcome is HOLD. Nothing is built, and the GO is not forced against your vote.

The result is a gate split, because you voted and no other role matched you. I would run `orbit-kb query gate_split`, which should be true, and record a divergence with `orbit-kb attest divergence h1 'hypothesis(h1)'`. I would add a note giving all three votes. `orbit-kb query 'gate(V)'` should return hold.

Next I would ask you what the HOLD waits for. I would not guess. Only you can record that reason, with `orbit-kb attest decision h1 "hold(h1, '<your words>')" --by human`. The reason decides the next lap. If you think a claim is wrong, the lap returns to SPECTRUM. If you are waiting for data or access, the lap waits for it. Each lap ends with a human answer recorded as `lap_done(N)`. Round 2 starts with my vote again, recorded before yours. If the lap budget runs out, `discovery_decide` holds, and HOLD stands until you raise the budget. Only you can do that.

**3. If you had voted GO**

With your GO, all three roles vote GO, so the full weight of 1.0 is behind it. GO wins. Your GO with my GO or the artifacts' GO is enough, because a choice needs your vote plus at least one other role. I read "if I had voted GO" as you voting GO, not me changing my vote.

Then the ticket is written. I would save the ticket file with `orbit-kb subject tk PATH` and add `ticket(tk)`. The ticket is the report without Decide and Ask, plus your answers, the dormant questions with their defaults, each counterexample with its disposition, the `universal` claims, and the models, verdicts, and bounds. You would then record your approval of `tk` at `digest(current)` with `--by human`. If the ticket file changes later, that approval becomes stale, and `stale(A)` reports it.

Next I would run `orbit-kb uses build` and then `orbit-kb lint`. The build orbit skips SURVEY, because discovery already ran. It starts DECOMPOSE from the discovery claims, uses each red `test_result` as its baseline, and then moves to BUILD.

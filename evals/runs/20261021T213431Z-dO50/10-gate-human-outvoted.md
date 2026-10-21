# 10 gate-human-outvoted (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Discovery is finished on the report "Invoices sometimes show yesterday's date." The KB says discovery is ready with a current claim. You haven't shown me the report yet.

1. What do you do before you show me the report?
2. I read the report and vote HOLD. Your vote was GO and the formal artifacts vote GO. What is the outcome, and what happens next?
3. What would the outcome be if I had voted GO instead?

## Answer

**1. Before I show you the report**

I would check the KB state first, without changing it. I would run `orbit-kb lint`, because this KB uses the discovery module, and `orbit-kb query 'discovery_decide'` and `orbit-kb query 'discovery_ready'` to confirm the budget is spent or the discovery is clean. I would also check `artifact_vote(V)` to confirm that the formal artifacts vote GO. Your statement that "the KB says ready" is a claim I would verify, not repeat.

Then I would seal my vote. I would record `orbit-kb attest vote r1 'vote(1, go)'` before I show you anything, and I would not read your vote before I cast mine. The report is then drafted from queries (`orbit-kb report`) with the vote section withheld. Its sections are Hypothesis, System, Findings, Decide (at most three questions, each with options and a default), Scope, Risk, Claims with one example each, Not explored, and an Ask line that says only "Vote GO, NO-GO, or HOLD." I would check that the report contains no verdict and no recommendation from me.

**2. You vote HOLD; I and the formal artifacts vote GO**

The outcome is HOLD. The weights are human 0.4, me 0.3, artifacts 0.3. A choice wins only with more than half the weight, and the human's vote must be part of that weight. GO has 0.6, but you are not in it, so GO does not win. Your HOLD has 0.4, which is not more than half. The result is a split, and the rule says any other result is HOLD.

Then I would do the following:

- Record the disagreement as a divergence: `orbit-kb attest divergence h1 'hypothesis(h1)'`. I would add a note with the three votes. `gate_split` should hold here, because you voted and no other role voted the same.
- I would not build, drop, or change scope. Only you can change scope or raise the lap budget.
- I would ask you what the HOLD waits for, because a HOLD names a missing data point, access, or decision. The HOLD reason is a `decision` attestation, and only you can write it, so I would not write it myself.
- Round 2 starts. I vote first in round 2, sealed, before you vote, because a HOLD moves the next vote to the next round and the rule requires my vote to come before yours (WD9, ED10).

**3. You vote GO instead**

The outcome is GO. The human and the artifacts agree, and that is more than half the weight. Your vote and mine do not change that result. Then I would:

- Save the ticket file with `orbit-kb subject tk PATH`, add `ticket(tk)`, and record your approval with `orbit-kb attest approval tk 'digest(current)' --by human`. The approval records what you said. It is not a check I can verify.
- Make the ticket the report without Decide and Ask. It keeps the risk, the examples from the witnesses or reproduction, your answers, the open questions with their defaults, any counterexamples, and the models, verdicts, and bounds.
- Move to the build orbit with `orbit-kb uses build`. I skip SURVEY, because discovery already ran. I DECOMPOSE from the discovery claims and turn each witness or reproduction into a check. I run each red check before I change code and reuse the red reproduction as the baseline.
- Deliver with the build report. Any default that you did not answer is listed as a guess, so you can disagree with it.

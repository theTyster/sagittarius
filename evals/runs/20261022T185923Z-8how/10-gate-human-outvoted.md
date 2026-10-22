# 10 gate-human-outvoted (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Discovery is finished on the report "Invoices sometimes show yesterday's date." The KB says discovery is ready with a current claim. You haven't shown me the report yet.

1. What do you do before you show me the report?
2. I read the report and vote HOLD. Your vote was GO and the formal artifacts vote GO. What is the outcome, and what happens next?
3. What would the outcome be if I had voted GO instead?

## Answer

**1. What I do before showing you the report**

I check the KB state myself instead of trusting the earlier "ready" result. I run `orbit-kb show open` and `orbit-kb lint`, since `show open` omits discovery items, and confirm that `discovery_decide` holds. Then I cast my vote and record it in the KB before I write the report. The vote stays sealed until you vote. The report has the evidence in full, with no verdict and no recommendation, and its Ask line is only "Vote GO, NO-GO, or HOLD." I also check that every finding is labeled as either a current-system reproduction or a model-only lead, and that the claim has at least one concrete example. The artifact vote is computed by `orbit-kb` (`artifact_vote(V)`), so I report what the KB computes rather than assuming it is GO.

**2. You vote HOLD: the outcome and next steps**

The weights are human 0.49, me 0.24, and artifacts 0.24. A choice wins only when its votes total more than 0.5. Your HOLD is 0.49, which is below the threshold by itself. GO has 0.48 from me and the artifacts, which is also below the threshold, and it lacks your support. So no choice wins, and the result is HOLD.

This is the split case the rules name: the two non-human roles agree against the human. I record that disagreement as a divergence and build nothing. Nothing is dropped either. Only you can change scope or raise the budget. I would ask what your HOLD waits for, such as data, access, or a decision by another person. If the answer is more evidence, the next round (round 2 of the vote) adds one lap to answer it, and I vote again under the same sealing rule. If your HOLD means the problem is not yet clear, that question goes back to discovery. My GO and the artifact GO would still show the same 0.48 unless the KB changes, so the decision now rests on your answer.

**3. If you had voted GO**

GO would total 0.97 (0.49 + 0.24 + 0.24). That is more than 0.5, so GO wins, and the human plus two other roles agree. I would write the ticket in plain prose, with the report minus the Decide and Ask sections, and add the human's answers and the dormant questions with their defaults. The build orbit then starts in the same KB (`orbit-kb uses build`, then `orbit-kb lint`). It skips SURVEY because discovery already ran. DECOMPOSE takes its claims from discovery, and the reproduction of the wrong date becomes the first red check. Invoices involve money and possibly data, so the delivery would stop for your decision before anything lands, and I would name the open defaults I chose, such as which date field counts as "yesterday."

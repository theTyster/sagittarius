# 10 gate-human-outvoted (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Discovery is finished on the report "Invoices sometimes show yesterday's date." The KB says discovery is ready with a current claim. You haven't shown me the report yet.

1. What do you do before you show me the report?
2. I read the report and vote HOLD. Your vote was GO and the formal artifacts vote GO. What is the outcome, and what happens next?
3. What would the outcome be if I had voted GO instead?

## Answer

**1. Before I show you the report**

I would seal my vote first. The discovery gate requires my vote to be recorded before you see the report, so my vote cannot shift toward yours. I would not write it into the report or hint at it.

Next, I would check the KB state. I would run `orbit-kb lint` and `orbit-kb whynot 'discovery_ready'` to confirm the ready state, and read `artifact_vote(V)` to confirm the formal artifacts' GO. I would confirm that the reproduction of "invoices sometimes show yesterday's date" is a system reproduction, not a model-only finding. A model-only finding is a lead, and it does not count as evidence. I would also confirm that each claim has one example and a falsifier. Then I would write the report in the template's shape. Its findings would be concrete cases from the system. Its Decide section would hold at most three questions, each with options and a default. Its Ask line would say only "Vote GO, NO-GO, or HOLD." I would not read your vote from the KB before I vote.

**2. You vote HOLD, I vote GO, and the artifacts vote GO**

The weights are 0.49 for you, 0.24 for me, and 0.24 for the artifacts. GO adds up to 0.48, and HOLD adds up to 0.49. Neither is above 0.5, so no choice wins. The rule says any other result is HOLD.

The outcome is HOLD. Nothing is built, and nothing is dropped against your vote. I would record the split as a divergence, because my view and the artifacts' view differ from yours. Then I would ask you what the HOLD depends on: data, access, or a decision by another person. That answer decides the next lap. Another discovery round follows, but only within the lap budget. If the budget is spent and the work is still not ready, only you can raise it. Each HOLD adds one round, so the vote repeats after the new evidence or decision arrives.

**3. If you had voted GO**

Your 0.49 plus my 0.24 plus the artifacts' 0.24 would total 0.97, so GO would win. The discovery report would then become the ticket, without the Decide and Ask sections. The ticket would also hold your answers, the dormant questions with their defaults, each counterexample, and the claims with their examples and falsifiers.

I would run `orbit-kb uses build` and then `orbit-kb lint`. The build orbit skips SURVEY, because discovery already covered it. DECOMPOSE would start from the discovery claims. The reproduction would become the first red check, and the build would then run against it. The delivery would follow the honesty rules, and `done` would decide when the ticket closes.

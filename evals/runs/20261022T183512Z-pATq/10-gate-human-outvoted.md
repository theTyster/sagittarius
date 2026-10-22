# 10 gate-human-outvoted (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Discovery is finished on the report "Invoices sometimes show yesterday's date." The KB says discovery is ready with a current claim. You haven't shown me the report yet.

1. What do you do before you show me the report?
2. I read the report and vote HOLD. Your vote was GO and the formal artifacts vote GO. What is the outcome, and what happens next?
3. What would the outcome be if I had voted GO instead?

## Answer

**1. Before I show you the report**

I cast my vote and seal it. The GATE step says to record the vote before the report goes to you, so you vote without seeing my position. I also check the state that the report depends on. `discovery_ready` and `discovery_decide` must hold, and `orbit-kb lint` must pass, because `show open` omits discovery items. I would read the current claim and the reproduction result in the KB, not rely on my memory of them. Then I write the report in the discovery-report format. It holds the evidence and the decisions you need to make, with no verdict and no recommendation. Its last line asks only for GO, NO-GO, or HOLD.

For this report, the evidence has to show whether "yesterday's date" reproduces in the current system, and under which conditions, such as time zone, the hour of issue, or the date source. I would not assume a cause before SURVEY shows one.

**2. You vote HOLD; I and the artifacts vote GO**

The weights are human 0.49, me 0.24, artifacts 0.24. Your HOLD gives 0.49 and GO gives 0.48. GO needs more than 0.5, so it does not win. No option wins, so the result is HOLD. Nothing is built, and nothing is dropped against your vote.

The disagreement is itself a divergence. I record it on the claim, and I note what your hold is about: data, access, or a decision by someone else. Then I ask you that question, because only the human can change the scope or raise the lap budget. The next lap targets what you named, and the vote runs again in round 2. If the lap budget runs out first, the report says what is still unknown and the vote runs on that evidence. The build does not start while the result is HOLD.

**3. You vote GO instead**

GO would total 0.97 with the other two votes, so GO wins. You do not need my vote or the artifacts' vote to agree. Once you need only one other role, your vote already carries it, and the fact that both others agree shows no divergence.

On GO, I write the ticket in plain prose. It holds the report without Decide and Ask. It also holds the human's answers, the dormant questions with their defaults, each counterexample with its disposition, and the models, verdicts, and bounds. The risk section names the data, money, security, or interfaces at stake. Each claim needs at least one example from a reproduction, a witness, or a trace. Then the build orbit starts in the same KB (`orbit-kb uses build`). SURVEY is skipped, and DECOMPOSE starts from the discovery claims. The reproduction becomes the first red check, and the build reuses that result as its baseline.

GO does not close every open item. If a claim is universal, such as "no invoice ever shows a wrong date," it burns. That burn stays open until a Lean proof or a human waiver closes it. I would list my guesses in the delivery, such as the time-zone default, so you can overrule them.

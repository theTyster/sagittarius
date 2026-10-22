# 10 gate-human-outvoted (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Discovery is finished on the report "Invoices sometimes show yesterday's date." The KB says discovery is ready with a current claim. You haven't shown me the report yet.

1. What do you do before you show me the report?
2. I read the report and vote HOLD. Your vote was GO and the formal artifacts vote GO. What is the outcome, and what happens next?
3. What would the outcome be if I had voted GO instead?

## Answer

**1. Before I show you the report**

I would not show it yet. Discovery requires my vote to be sealed first. I would:

- Run `orbit-kb show open` and `orbit-kb lint`. The lint covers discovery items, which `show open` omits. I would confirm that `discovery_ready` holds, that the claim is current, and that `orbit-kb whynot 'discovery_ready'` returns nothing.
- Check the report's sections against the template: hypothesis, system evidence, findings, scope, risk, claims with one example and a falsifier each, and what was not explored. The Ask line says only "Vote GO, NO-GO, or HOLD."
- Read the GATE section (`orbit-kb help discovery`) and record my vote in the KB. The record should be sealed and not shown to you.
- Confirm that `artifact_vote` gives GO, since the KB computes that vote.
- Strip any hint of my vote from the report, including phrases like "I expect" or "the likely outcome is."

**2. You vote HOLD**

The weights are human 0.49, me 0.24, and the formal artifacts 0.24. GO gets 0.48 from me and the artifacts. HOLD gets 0.49 from you. Neither GO nor NO-GO passes 0.5, so the result is HOLD.

The outcome:

- Nothing is built and nothing is dropped.
- The two votes against you, mine and the artifacts' GO, are a divergence. I would record it with `orbit-kb attest divergence`, because the rule for "two roles against the human" calls for it.
- Another round follows. Each HOLD adds one round, and the default budget is three laps. Only you can raise the budget or change scope.
- Before the next lap, I would ask what the HOLD waits for: data, access, or a decision by someone else. The HOLD reason decides what the next lap collects. I would not guess it.
- Your answer becomes a record. If it changes a claim, it supersedes that claim, and the new claim needs its own falsifier.

**3. You vote GO instead**

The total is 0.49 + 0.24 + 0.24 = 0.97. All three roles agree, so GO wins.

The outcome:

- The discovery report becomes the ticket, without the Decide and Ask sections. The ticket also keeps your answers, the dormant questions with their defaults, each counterexample and its disposition, any `universal` claims, and the models with their verdicts and bounds.
- The build orbit starts from the discovery claims. I would run `orbit-kb uses build`, skip SURVEY, and make the reproduction the first check. The red test is the baseline for the build.
- A `universal` claim burns. It needs a Lean proof or your waiver before `done` can hold. A solver or TLC result does not close a burn.

I have not seen the report, so I cannot say which claims would be universal or what the reproduction is. Those depend on what discovery found.

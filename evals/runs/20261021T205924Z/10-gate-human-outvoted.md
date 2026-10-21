# 10 gate-human-outvoted (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Discovery is finished on the report "Invoices sometimes show yesterday's date." The KB says discovery is ready with a current claim. You haven't shown me the report yet.

1. What do you do before you show me the report?
2. I read the report and vote HOLD. Your vote was GO and the formal artifacts vote GO. What is the outcome, and what happens next?
3. What would the outcome be if I had voted GO instead?

## Answer

**1. Before you see the report**

I would not show it yet. First I would confirm the KB state, since the "ready" claim came from earlier in the session. I would run `orbit-kb lint` and `orbit-kb query discovery_ready`, check that the reproduction is tagged as system evidence, and check that the current claim has a falsifier. Then I would cast my vote and seal it with `orbit-kb attest vote r1 'vote(1, go)'`, which records my GO before the report is shown. I would not read your vote before I cast mine. Then I would draft the report with `orbit-kb report`, which hides my vote until you vote. I would add the Decide questions, Scope, Risk, Claims, and Not explored sections by hand. The report would say that the bug reproduces, that the likely area is date or timezone handling, and that the cause is not yet confirmed.

**2. You vote HOLD, I vote GO, and the artifacts vote GO**

The outcome is HOLD. The weights are human 0.4, me 0.3, artifacts 0.3. A choice wins only with more than half the weight, and the human's vote must be part of it. GO has 0.6, but you are not part of it, so it does not win. HOLD has only your 0.4, which is not more than half. The rule says any other result is HOLD. This is the case where the formal artifacts and I agree against the human, so it counts as a divergence.

What happens next:

- I record the divergence on `h1`, with a note that gives the three votes. The gate-split check confirms this case.
- I do not build, and I do not drop the ticket. Nothing moves against your vote.
- You write the hold decision yourself, because only the human can record a `hold`. The text should say what the hold waits for.
- I ask what is missing, and I ask only the questions your HOLD raised. Your answers can supersede a claim. If they do, the new claim needs its own falsifier.
- The next round is round 2. I vote first in that round, because a human vote without mine in the same round is a WD9 finding. I do not change my vote to match yours.
- If the lap budget is spent, the vote still happens, but the outcome can only stay HOLD or be decided by you.

**3. You vote GO instead**

The result is GO with full agreement: 0.4 + 0.3 + 0.3 = 1.0, and you are part of it. Your GO is a core approval, not a separate decision. The steps would be:

- Record the ticket file with `orbit-kb subject tk PATH`, add `ticket(tk)`, and record your approval at `digest(current)` with `--by human`. If the ticket changes later, that approval goes stale and must be renewed.
- Add the build module with `orbit-kb uses build`, then run lint.
- Skip SURVEY, because discovery already ran. Decompose the discovery claims, with citations to the report text.
- Write the reproduction as the first check. Run it and confirm it fails before the fix. Then build the smallest change that makes the claims pass, run the checks again, and deliver.

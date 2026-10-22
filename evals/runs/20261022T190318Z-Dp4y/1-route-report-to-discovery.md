# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path do I take?**

This is a defect report, not a change request. We know a symptom ("sometimes an empty CSV") but not the cause or the fix, so the discovery orbit comes first. It starts as a tiny discovery orbit with no KB. The word "sometimes" points to a timing, state, or data condition, and I do not yet know which. I would shift up to a KB if the first reproduction attempts fail, if the cause spans several conditions, or if the human's answers contradict each other. A KB is memory for that kind of work, and I would not start one before then.

**2. What are my first three steps?**

First, I restate the report as one falsifiable hypothesis and ask the human a small set of questions. "Empty" could mean zero bytes, a header row with no data, or rows with blank values, and each points to a different cause. I would also ask which page or filter the export comes from, whether it happens every time with the same filter, and whether it started after a recent release. I would ask at most three questions in one round.

Second, I survey the current export path without changing anything. I would trace the button handler, the request it sends, the server query behind it, and the CSV writer. I am looking for places where an empty result can come out with a success status. Candidates include a click that fires before the data finishes loading, a filter or pagination value that goes stale, a date or timezone boundary, a server timeout that returns 200 with an empty body, and a permission check that filters out all rows. I would record each fact I depend on with its source file and line.

Third, I try to reproduce it. I would write a failing test for the most likely condition, such as clicking Export before the data loads, and run it against the current code so it must fail. If no condition reproduces it, I would run a bounded set of attempts, record what I tried, and report that the defect did not reproduce. I would not guess at a fix.

**3. What do I bring back, and what happens after that?**

I bring back a discovery report with the hypothesis, what the system does now (reproduced, not reproduced, or already correct), the evidence, the concrete cases, the open questions with my defaults, the scope, the risk to data and users, the claims with a falsifier for each, and what I did not explore. The report also says plainly how much of the intermittency I could cover, since a bounded number of attempts cannot prove that a bug never happens.

Then the three roles vote GO, NO-GO, or HOLD. I cast my vote and seal it before I show the report, so the human decides without seeing my vote. On GO, the reproducing test becomes the first check of a light-path build. I make the smallest fix that the claims need, rerun the checks, and deliver with the Delivered, Claims, Guesses, Disclosures, Not checked, and To land fields. The human verifies the behavior in the app. On NO-GO or HOLD, we stop there, or we gather the data that HOLD names and run another lap.

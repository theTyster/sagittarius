# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

## 1. What kind of work, and which path

This is a **report**, not a change request. We know something is wrong ("sometimes an empty CSV") but not what to change, so it belongs in the **discovery orbit**. Because the symptom is intermittent, I expect the first reproduction to leave open questions, so I'd plan to shift up to a KB early.

I'd start on the **tiny discovery orbit** with no KB: reproduce, state the claims with examples, ask, and vote. I'd shift up on any trigger: a divergence (for example, the user's "empty" means something other than what I reproduce), more than three questions, or a claim that needs a model because the cause depends on timing or order.

## 2. First three steps

1. **Pin the report.** Restate it as one falsifiable hypothesis: "Export on [screen] writes a CSV with no data rows when the source table has rows." Classify it as a defect. Before going further, I need to know what "empty" means: a zero-byte file, a header-only file, or a file with rows that are all blank.

2. **Survey the current system.** Find the export path, from the button handler through the query that feeds it to the CSV writer. Record the facts it depends on, each with its source. Then try to reproduce under the conditions most likely to matter: active filters, date ranges, pagination, a large result set, a second click during loading, and two sessions at once. I'd look at the server log for each export request, too. If the bug does not reproduce, I tell the human what I tried and do not guess a cause.

3. **Write the red check.** If I reproduce it, I write a test that exports under the failing conditions and asserts that the row count matches the source. I run it and confirm it fails before any fix. That red test becomes the first check of the build, and it also proves the check can fail. If the bug never reproduces, I have no red test, and that absence is a result to report.

## 3. What I bring back, and what follows

I bring back a discovery report with these fields:

- **Hypothesis:** one sentence.
- **System:** reproduced or not, with the exact conditions and the evidence.
- **Findings:** concrete cases from the system only, not from any model.
- **Decide:** up to three questions, each with options and my default. Likely ones: what "empty" means, which screen and filters matter, and since when this happens.
- **Scope and risk:** what the export touches, and what a wrong fix could damage. Export is read-only, so the risk is low.
- **Claims:** for example, "Export on /reports with filter X returns every row the table shows," with one example and a falsifier.
- **Not explored:** the cases I did not cover, such as other browsers or very old data.
- **Ask:** my recommended vote.

Before I show the report to the human, I record my own vote and seal it. The formal artifacts vote by rule: GO when discovery is ready with a current claim, and NO-GO when nothing reproduced. The human then votes. A choice wins only if the human and at least one other role agree. Otherwise it is a HOLD, and I record the split as a divergence.

After a GO, the ticket moves to the build orbit. The red test is the first check, and I make the smallest fix that turns it green. I then run the checks again, look for anything the change did not need, and deliver with the Delivery block: what was delivered, each claim with its verification, my guesses, anything not checked, and what the human must decide before landing.

If the bug does not reproduce, the report says so with what I tried, and the human decides whether to hold, drop, or gather more data from the user, such as a copy of an empty file and the filter settings they used.

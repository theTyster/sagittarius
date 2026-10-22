# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path?**

This is a defect report, not a change request. We know the symptom but not the cause or the fix, so it goes to the discovery orbit, which comes before build. "Sometimes" suggests an intermittent failure, so I would not expect the tiny discovery orbit to settle it. I would start tiny with no KB, and shift up to a KB if the first reproduction attempts fail or the cause depends on timing or on filter rules. Once the cause is known and a red check exists, the work moves to the build orbit on the light path. A KB probably isn't needed unless the cause is a race or depends on many combinations of filters.

**2. My first three steps**

First, I would pin the report as one falsifiable hypothesis: "When the user clicks Export in state X, the downloaded CSV contains no data rows, and the same click in state Y does not." Before any code reading, I would ask the user three questions in one round. What does "empty" mean: a zero-byte file, a header-only file, or a file with rows but blank values? Which filters, date range, or screen were active? Does a retry or page reload usually fix it? The answers decide which path to explore.

Second, I would read the export path and look for the usual suspects that produce intermittent empty output. These include the export firing before the data request finishes, a stale or cached result set, a filter that silently returns zero rows, pagination that stops at page one, and a streaming writer that closes early. I would check whether the server logs or the client console show errors for the failing requests. These are candidates to rule out, not conclusions.

Third, I would try to reproduce it. I would run the export with the same filters and sizes the user described, click quickly right after the page loads, and try a slow network throttle to widen any timing window. If I reproduce it, I write a failing check first: an automated test that triggers the export in the failing state and asserts the row count matches what the screen shows. That red run is the proof that the check can fail. If I cannot reproduce it, I will say so and list exactly what I tried.

**3. What I bring back, and what follows**

I bring back a discovery report with the hypothesis, what I reproduced or failed to reproduce, the concrete evidence (the failing state, the requests, the file contents), the questions that the evidence raised, the scope, and the claims with their examples, plus the list of what I did not explore. I would not include a verdict in that report. Then the human, you, and the formal artifacts vote GO, NO-GO, or HOLD. I would cast my own vote and seal it before I show the report, so my vote does not bias yours. On GO, the build starts on the light path: the red check becomes the first check, I fix the cause, and the check runs green. The delivery then states each claim, whether the check passed, and what was not verified. If the cause is unclear or the report cannot reproduce, the likely outcome is HOLD, and the next step is more data from the user, such as the exact filters and a sample of an empty file.

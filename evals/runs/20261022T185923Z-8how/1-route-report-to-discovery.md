# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path?**

This is a report, not a change request. Something is wrong, but we don't yet know what to change. The cause could be the export code, the data query, a race with a loading state, a filter, or a particular dataset. The report also says "sometimes," so the failure is intermittent, and we can't yet say when it happens. That makes it a discovery orbit, and I'd start on the tiny discovery path with no KB. I'd shift up to a KB only if a trigger fires: the defect doesn't reproduce, the cause turns out to be timing or concurrency, or you disagree with my restatement.

**2. First three steps**

- **Pin the report (SIGNAL).** I'd restate it as one falsifiable hypothesis: "The Export button sometimes writes a CSV with no data rows (or zero bytes) under conditions C." I'd also check whether "empty" means zero bytes, a header row only, or a file that opens with no rows. Those point to different causes. I'd ask you which one you saw.
- **Reproduce it (SURVEY).** I'd look for the conditions first. What page, filters, date range, and dataset size were in use? Did it happen right after a page load, on a retry, or after a filter change? I'd check the export code path and any logs for an export that returns zero rows or fails silently. Then I'd try to trigger it with the same inputs. If I can't reproduce it, I'd say so and list what I tried. I would not guess a fix.
- **Write a red test.** Once I have a reproduction, I'd write a failing check that asserts the export contains the expected rows for those inputs, and run it to confirm it fails. A check that uses small or friendly data could pass while the bug remains, so the test has to use the conditions that failed.

I'd ask at most three questions, in one round: which data and filters were in use, which kind of "empty" you saw, and whether a retry fixes it. Those answers may shrink the search a lot.

**3. What I bring back, and what happens next**

I'd bring back a short discovery report:

- **Hypothesis:** the restated, falsifiable version.
- **System:** reproduced, not reproduced, or already fixed, with the evidence (the command or steps, and the observed output).
- **Findings:** the concrete conditions that trigger it, and the likely cause if I found one. I'd mark each finding as from the running system or as a guess.
- **Red test:** the failing check, and its result.
- **Not explored:** what I didn't cover, such as other browsers or very large exports.
- **Vote:** I'd cast my own vote and seal it before showing you the report. You then vote GO, NO-GO, or HOLD. A GO means the defect is real and worth fixing. A NO-GO means it doesn't reproduce, or it's out of scope.

On GO, the build orbit starts on the light path. The red test becomes the first check. I'd make the smallest fix that the claim needs, run the check again, and deliver a report that lists each check and its result. I'd also list any guesses and anything I could not verify, such as an export that fails only in your environment. You judge the result by using the export yourself, not by the tests alone.

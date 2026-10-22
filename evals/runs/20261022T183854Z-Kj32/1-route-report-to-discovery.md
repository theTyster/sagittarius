# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. Kind of work and path**

This is a defect report, so it goes to the discovery orbit before any build. We don't yet know what to change. "Sometimes" suggests a condition we haven't identified, so we need to reproduce the failure before choosing a fix. I'd start on the tiny discovery path, with no KB. I'd move to a KB if the defect doesn't reproduce after a few attempts, if the cause turns out to be a race or ordering problem, or if the human's answers contradict each other.

I haven't looked at the code yet. The working directory isn't a git repository, so I first need to find where the app lives and where the Export handler is.

**2. First three steps**

1. **Pin the report.** Restate it as one testable hypothesis: "Export produces a CSV with no data rows under condition X." Classify it as a defect. Ask the user at most three questions, in order of cost if wrong: which screen and data set, whether it depends on filters or date range or data size, and whether a browser console or server error appears when it happens. Set a budget of three laps.
2. **Reproduce.** Read the Export code path. Then try exports with a data set that is truly empty, one with many rows, one with the filters that are most likely to matter, and one fired right after the page loads or right after a filter changes. The point is to find which condition gives an empty file, and to tell apart a file with zero bytes, a file with only a header, and a file with rows that are dropped. Write a red test that exports the failing case and asserts that the file has the expected rows. The test must fail before any fix.
3. **Narrow the cause class.** Each empty result has a different cause. It might be correct behavior, because the filter really matches nothing, and then the fix is a clear message instead of a download. It might be a race, where the export runs before the data has loaded. It might be a streaming or encoding fault that truncates the response. Or it might be stale state. For each candidate, I'd write one claim with one concrete example and the result that would falsify it.

**3. What I bring back, and what follows**

I bring back a short discovery report: the hypothesis, whether the defect reproduced and the evidence, the concrete cases that produced an empty file, the claims with one example each, what I did not explore, and the open questions with my defaults. I'll say plainly if it did not reproduce, and list what I tried.

Then we vote, GO, NO-GO, or HOLD. I'd seal my own vote until the user has voted. On GO, the build orbit starts on the light path. The red test becomes the first check. I make the smallest change the claims need, rerun the checks, and deliver with the Delivery block: what was delivered, how each claim was verified, my guesses, what is not checked, and the decision the user must make before it lands. If the fix touches shared data or the export format, I'll stop and ask before landing it.

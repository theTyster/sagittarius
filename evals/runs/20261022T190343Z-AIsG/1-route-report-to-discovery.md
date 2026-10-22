# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path?**

This is a defect report, not a change request. We know the symptom but not the cause or the trigger, so we cannot yet say what to change. That makes it discovery work, and it starts on the tiny discovery path with no KB. "Sometimes" suggests a condition we have not found yet: a race, a filter state, a data size, or a serialization bug. Each would need a different fix, so we should not build one before we reproduce it.

I would move to a KB only if the first round of questions does not narrow the cause, or if there is more than one plausible hypothesis that needs separate tests. I would also shift up if the cause turns out to be a race with several orderings, since that is intermittent behavior that one test may not expose.

**2. My first three steps**

1. **Pin the report to one falsifiable hypothesis.** For example: "When the Export button runs under condition X, the CSV contains a header and zero data rows, although the screen shows N rows." I would classify it as a defect. Because "X" is unknown, I would list the candidates I can already see and mark them as unverified. They are: export runs before the data finishes loading, a filter or date range is applied on export but not on screen, the export query has a limit or timeout, and the serializer drops rows. I would also ask you the first questions here, one round, at most three: which screen and filters, whether it happens for every user or only some, and whether the UI showed rows when the export was empty.
2. **Survey the current system.** I would read the export path from button to file: the click handler, what data it reads (client state, a cache, or a server query), and how the CSV is written. I would also check whether the request succeeds and returns an empty body, or the server returns rows and the client drops them. The facts I record would each carry a source, such as a file and line, or a log entry.
3. **Reproduce, then write a red test.** I would try to make the empty export happen on purpose, first by clicking Export before load finishes, then with each filter combination, then with a large dataset. Once I have a failing case, I would write it as a test that fails on the current code. That test becomes the first check for the eventual fix. If the bug does not reproduce, I would tell you what I tried and stop there, instead of guessing at a fix.

**3. What I bring back, and what happens next**

I would return a discovery report with these parts:

- **Hypothesis:** the one-sentence version I pinned in step 1.
- **System:** whether it reproduced, with the exact steps and evidence. If it did not reproduce, the conditions I tried.
- **Findings:** each confirmed or ruled-out candidate, with its source.
- **Decide:** up to three questions, each with options and my default.
- **Scope, risk, and claims:** what the fix would touch, what a wrong fix could damage, and each claim with one example and its falsifier. For example: "Export returns every visible row. Falsifier: any export with fewer rows than the screen shows."
- **Not explored:** what I did not cover.

You then vote GO, NO-GO, or HOLD. I would cast my own vote and keep it sealed until you have voted, so your judgment is not biased. A GO starts the build orbit on the light path. The red test becomes the first check. I make the smallest fix that turns it green, I rerun every check, and I deliver with the standard block: what changed, what was verified, what was not checked, and the decision that remains for you. A NO-GO means the bug did not reproduce, or the behavior is intended, and nothing gets built.

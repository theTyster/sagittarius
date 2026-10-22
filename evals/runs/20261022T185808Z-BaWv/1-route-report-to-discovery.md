# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path?**

This is a defect report, and the cause is unknown. The report says something is wrong but not what to change, so it belongs in the **discovery orbit**, not the build orbit. Because the report is one problem with a likely cheap reproduction, I'd start with the **tiny discovery orbit**: no KB, and a red test as the one formal artifact. I'd shift up to a KB if the failure won't reproduce reliably, if more than one cause looks plausible, or if a human's answer contradicts my picture. "Sometimes" makes that a real risk.

**2. First three steps**

1. **Pin the report as one falsifiable hypothesis.** For example: "Export produces a CSV with no data rows when [condition]." I'd classify it as a defect and set a budget of three laps. I'd also ask the user at most three questions, ranked by how costly a wrong default would be: which page or app version, whether filters or a date range were set when it happened, and roughly how often it occurs and whether they have a file or a timestamp from a failure. I won't guess those.

2. **Survey the current system, with no changes.** I'd trace the export path from the button handler, through the request it sends (filters, selection, pagination, timeouts), to the server query and the CSV writer. I'd note whether the export is synchronous or async, whether it streams, and whether it caps rows. I'd check server logs for exports that returned zero rows, and then try to reproduce. The useful reproduction varies the state: export immediately after load before data arrives, after changing a filter, with a large dataset, with a second user editing, and with unusual characters or time zones. Each variation tests a different hypothesis: a race in client state, a query that returns nothing (permissions, default date window, off-by-one pagination), or a writer that closes or times out early.

3. **Write the red test before any fix.** The check exports under the condition that reproduces the failure and asserts that the row count matches the count the user sees or the count the database returns. It must fail on the current code. If it passes every time, it shows nothing, and I'd say so. If I cannot reproduce the failure, I'd write no fix and no speculative test. I'd report what I tried.

**3. What I bring back, and what follows**

I'd bring back a short discovery report:

- **Hypothesis**, in one sentence.
- **System**: reproduced or not, with the evidence (the conditions, the logs, and the failing test's output).
- **Findings**, each labeled as from the running system, not from reasoning alone.
- **Decide**: up to three questions with options and my defaults.
- **Claims**, each with one example, such as "an export with filter F returns all N rows."
- **Not explored**, and the guesses I made.

I'd cast my own GO, NO-GO, or HOLD vote and seal it before I show you the report, so that your vote is not biased. Then you vote.

If you vote GO, the claims and the red test become the ticket. The build starts on the light path: I fix the cause, the red test turns green, and I run the related checks again. The delivery then states what each check showed, what I guessed, what I did not verify, and the decision that remains for you, such as whether to ship.

If the failure does not reproduce within the budget, the likely result is HOLD. The next step would then depend on what you can give me: a failing export, its timestamp, its user and filters, or its server log entry.

# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
**1. Kind of work and path**

This is a report, not a change request. Something is wrong ("sometimes" the export is empty), but we can't yet say what to change. So it goes through the discovery orbit. Because it's one defect with one visible symptom, I'd start with the tiny discovery orbit: no KB, no SMT or TLA+ models, and one red reproduction as the formal artifact. I'd shift up to a full discovery KB only if a trigger fires. Those triggers are: the reproduction shows more than one cause, I have more than three questions, the cause turns out to be a timing or race problem (that calls for TLA+), or the human says my restatement is wrong.

**2. First three steps**

First, pin the report as one falsifiable hypothesis, and set a budget of three laps. My default restatement is: "Export sometimes writes a CSV with no data rows, while the on-screen view has rows." I'd treat "empty" as zero data rows, possibly also zero bytes, and check both. I won't ask the user yet, because the default is cheap to correct.

Second, reproduce it. Find the Export code path, then try to trigger the empty file under the conditions that vary most: different filters and date ranges, first load versus after navigation, a large dataset, pagination, and clicking Export before the data finishes loading. Check the network request and the server response for each attempt. If I can't reproduce it, I'll tell the human what I tried and stop there. I won't guess at a fix.

Third, narrow the cause. Compare a failing export with a working one: request parameters, the rows the query returns, and the serialization and write step. That tells me whether the data is empty upstream, the request fires too early, or the write closes before it finishes. Once I know which, I'll write the claim with a concrete example and the check that would falsify it, then write a test that fails on the current code. That red test becomes the first check in the build.

**3. What I bring back, and what happens next**

I bring back a short discovery report. It has the hypothesis; whether it reproduced, with the exact trigger and the evidence; the concrete cases; up to three questions with defaults; the scope and risk (for example, a wrong fix to the export could change every other export, and the file may contain personal data); the claims, each with one example; and what I did not explore. I'll also cast my own GO, NO-GO, or HOLD vote, sealed, before showing the report. The human votes next, and I don't reveal my vote until they have.

On GO, the report becomes the ticket. The build orbit starts on the light path. The red reproduction is the first check, and I write the fix, make the check pass, rerun the checks, and report each one in a line. The human verifies the behavior, not the tests. On NO-GO or HOLD, the report says why, and the next orbit starts from what we learned.

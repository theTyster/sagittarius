# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
**1. What kind of work is this, and which path?**

This is a defect report, not a change request. We know the symptom, but not the trigger, so we cannot yet say what to change. That makes it discovery work, and discovery comes before build. The light path does not apply yet.

I would start the tiny discovery orbit with no KB, but "sometimes" makes it likely to shift up. An intermittent empty file usually has a trigger we have not identified, such as a click before data loads, an empty filter state, a server timeout that returns a 200 with no rows, or a race in the download code. Those will raise more than three questions, so I would expect to open a KB with the discovery module on the first trigger.

**2. First three steps.**

First, I would pin the report as one falsifiable hypothesis: "Export sometimes downloads a CSV with no data rows, while the table shows data." I would also ask the user at most three questions, in order of cost if wrong: what filters or selection were active when it happened, whether the file is zero bytes or only a header row, and whether it happens on every browser and every day or only for some datasets. If the user's answers do not narrow the trigger, I would not guess further. I would list the candidate causes as open hypotheses.

Second, I would survey the current system. I would read the export path from button handler to data fetch to CSV serialization to download, and record the relevant facts with sources. Then I would try to reproduce it: export with the same filters, click repeatedly, click before the table finishes loading, use a large dataset, and throttle the network. I would also capture the export request and response to see whether the server returned an empty body, a 200 with no rows, or an error that the client swallowed. If it does not reproduce, I would tell the user what I tried.

Third, I would turn the reproduction into a red test. It would check that an export of a table with rows never yields an empty file, and it must fail before any fix. That test becomes the first claim and the first check, and the system evidence from it counts for the report.

**3. What I bring back, and what happens next.**

I would bring back a short discovery report. It states the hypothesis, what the system did when I tried it (reproduced or not, with the evidence), the concrete cases that I found, and the questions that the evidence raised, each with my default answer. It also lists the scope, the risk (users may act on a wrong file, and the export may cover only part of the data), the claim with its example, and what I did not explore. I would not put my own recommendation in the ask. I would cast my vote on GO, NO-GO, or HOLD and seal it, then give the human the report without it. The human votes, and the human's vote carries the most weight. The outcome is GO only when the human agrees with at least one other role.

On GO, the report becomes the ticket. The build orbit then starts from the red test, fixes the cause, and changes only what the claim needs. I would run the check again, look for claims that are still unmet and for changes that serve no claim, and deliver a report that names each check and its result. Then the human verifies the fix against the claim. If the fix touches data handling, public interfaces, or anything hard to undo, I would stop and ask before landing it. If the cause turns out to be a different problem, we go back to discovery.

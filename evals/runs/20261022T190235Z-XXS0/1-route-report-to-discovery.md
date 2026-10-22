# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path?**

This is a defect report. The user says something is wrong, but not what to change, so it belongs in the discovery orbit, not the build orbit. Because the report is one symptom with probably one cheap reproduction, I'd run the tiny discovery orbit with no KB. The word "sometimes" is the main risk. It suggests a timing, state, or data condition, and an intermittent bug can take a long time to pin down. If reproduction needs several laps, or I need more than three questions, or a claim turns out to depend on timing, I shift up and start a KB.

**2. My first three steps**

First, I pin the hypothesis in one falsifiable sentence, for example: "Clicking Export while the table shows rows sometimes downloads a CSV with a header and no data rows." I also note a three-lap budget. I don't ask the user anything yet, because I can't name a question that the code wouldn't answer faster.

Second, I survey the system without changing it. I find the Export handler and trace what data it reads. I check whether it reads the same source as the visible table, whether it runs before or after the data finishes loading, whether filters, pagination, or a cached response apply, and what the server returns for the export request. I record each fact with where I found it. Candidate causes I'd check first are a click that fires during loading, a filter or date range that the export ignores or applies differently, and a server-side query that times out or is scoped to the wrong user or tenant and returns zero rows without an error.

Third, I try to reproduce it. I run the app and export under each suspected condition: after a full load, during loading, with a filter that yields zero rows, after paging, and on a second export. I write the reproduction as a check that fails on the current code, such as a test that asserts the CSV's row count equals the visible row count. That red check becomes the first check of the build, so I don't have to write it again later. If I can't reproduce it after reasonable attempts, I report what I tried and do not claim a cause.

**3. What I bring back, and what happens next**

I bring back a discovery report in the usual format: the hypothesis; whether it reproduced and the evidence, with the exact conditions; the concrete findings, each marked as observed in the system rather than inferred; up to three questions with my default answers; the scope and risk, including the fact that a silently empty export could mislead someone who relies on the data; the claims, each with one example and the result that would falsify it; and what I did not explore.

The questions I expect to ask, most costly first, are: is an empty export ever a valid result, or should the app warn the user; which screen and filters were in use when it happened, if the user can say; and did this start after a recent change. Each has a default I'd state explicitly.

Before the vote, I record my own vote and seal it, so the human's view isn't biased by mine. Then the human votes GO, NO-GO, or HOLD. A choice wins only if the human and at least one other role agree, since the human carries the most weight. On GO, I write the ticket in plain prose, with the red reproduction as its first check, and the build starts on the light path. On NO-GO or HOLD, I say what is still unknown and what data would settle it. In every case, I'd say plainly whether the bug was reproduced, and I wouldn't claim it is fixed unless a check that failed before the change now passes.

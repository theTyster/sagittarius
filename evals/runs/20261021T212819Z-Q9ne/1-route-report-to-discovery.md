# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path do I take?**

This is a report, not a change request. Something is wrong, but we cannot yet say what to change, so it goes to the discovery orbit before build. It is probably a tiny report: one defect, and a reproduction should be cheap. I would start the tiny discovery orbit, with no KB and no models. Two things could push it up to a KB. The first is if reproducing the bug needs more than a few conditions to be tracked, which is likely with "sometimes." The second is if the cause turns out to be a race, such as a click during loading or two exports running at once. Ordering and concurrency problems belong in a TLA+ model, not in a few examples.

**2. What are my first three steps?**

1. **Restate the report and pin the terms.** I would write one sentence: "When a user clicks Export on [screen] under [conditions], the downloaded CSV contains [zero bytes / a header only / no data rows]." "Empty" could mean any of those three, and each points to a different cause. If the report does not say which one, I ask the human that question first, because it is cheap and it decides where I look.

2. **Survey the current system.** I read the export code path: the query or filter it applies, how it paginates, whether it generates the file asynchronously, and how it handles dates, time zones, and empty results. Then I try to reproduce the bug across the conditions that the code suggests. Those are: a filter that matches nothing, a very large dataset, a slow network, repeated clicks, and a different user or tenant. I record what I tried, including the attempts that did not reproduce it. If it reproduces, I tag the log or test as system evidence. If it does not, I tell the human what I tried and do not guess a cause.

3. **Write a red check for the reproduction.** I write a test that fails on the current code under the condition I found. The red run shows that the check can fail, and the build reuses it as its first check. If I cannot find a reproduction after a reasonable budget, I stop and report that. I do not write a fix for a bug I have not seen.

**3. What do I bring back to you, and what happens after?**

I bring back a short discovery report, with these parts:

- **Hypothesis:** one sentence, with the empty-output type that we agreed on.
- **System:** reproduced or not, the conditions I tried, and the evidence.
- **Findings:** the concrete case, if one reproduces, and the code location that I suspect.
- **Decide:** at most three questions. For example: is a header-only file acceptable when no rows match? Which data or filters did the user have? Should the export show a message instead of a file?
- **Claims:** for example, "an export with at least one matching row contains those rows," each with one example.
- **Not explored:** the conditions I did not test.
- **Vote:** I cast my GO, NO-GO, or HOLD vote before I show you the report. You vote next. A choice wins only when you and at least one other role agree, so your vote matters most here.

On GO, the build orbit starts. The red check runs first and must fail. I fix the cause, change only what the claim needs, and run the check again. Because the bug is intermittent, one passing run proves little, so I run the check repeatedly and say how many runs it passed. A fresh subagent then reviews the diff against the ticket and the claims, looking for work outside the claim and for claims the change does not cover. I deliver a short report: what was fixed, each check and its result, my guesses, what I did not check, and any decision you still need to make. I would not commit or push without your go-ahead. If the cause turns out to be a race, I would move up to a KB and model it before I write the fix.

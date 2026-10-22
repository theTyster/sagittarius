# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this?**

This is a defect report, and it is not yet a change request. We know the symptom but not the trigger, and we cannot yet say what to change. Under the Sagittarius scope rules, it goes to the discovery orbit, not the build orbit. It is probably a tiny discovery: one problem, a cheap reproduction, and a few claims. I would run it with no KB. Shift up to a KB if the questions grow past three, if a reproduction disagrees with the human's account, or if the "sometimes" turns out to hide a rule about data or timing that needs a model.

**2. My first three steps**

1. **Pin the hypothesis and separate the cases.** "Empty" can mean a header-only file, a file with zero bytes, a failed request that saves an empty body, or a valid file for a view that had no rows. Each has a different cause. I would restate the report as one falsifiable hypothesis, for example: "Export returns a CSV with no data rows although the screen shows N > 0 rows." I would also ask the human which of these they saw, since that is the first question that changes the work.
2. **Survey the current system.** I would read the Export code path and its endpoint, and check the logs for failed or truncated exports. Then I would try to reproduce under the conditions that most often make an export empty: filters that match nothing, large data sets, paging or async loading that finishes after the click, timeouts, stale state, and permission-limited views. If it reproduces, I write a red test that fails on the empty output. If it does not reproduce, I report what I tried and stop there.
3. **Write claims with one example each, and ask only what the evidence raised.** For example, "Export of a view with N visible rows writes N data rows, plus a header." Each claim gets a falsifier. The questions go to the human only if the evidence raises them: the exact view and filters, whether the failure is every time or intermittent, and whether the bad file is header-only, zero bytes, or a failed request. I would ask at most three, with my default for each.

**3. What I bring back, and what happens next**

I bring back a discovery report with the hypothesis, what the system does now (reproduced, not reproduced, or the evidence), the concrete findings, up to three questions with defaults, the claims with their examples and falsifiers, what I did not explore, and the risks. Before I give the report, I record my own GO, NO-GO, or HOLD vote and do not show it. The human then votes on the evidence alone. If the reproduction is red and the human votes GO, the ticket goes to the build orbit on the light path. The red test becomes its first check, and I fix the cause without editing the test to pass. The delivery then names each check and its result, lists my guesses, and says what was not checked. If I cannot reproduce it, the answer is HOLD, with the list of what I ruled out and the data that would settle it, such as the user's export parameters, the server logs for that time, or a copy of the file they got.

# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path do you take?**

This is a report, not a change request. Something is wrong, but we don't yet know what to change, so it goes to the discovery orbit. I'd start with the tiny discovery orbit, with no KB. "Sometimes" means the cause is probably conditional (a data condition, a race, a filter, or a timing issue), and I can't call it tiny until I reproduce it. If I can't reproduce it, or the first answers raise more than three questions, I shift up to a KB with the `discovery` module. That's the trigger for the full orbit.

**2. What are your first three steps?**

1. **Pin the report.** I'd restate it as one falsifiable hypothesis: "On [screen], Export produces a CSV with zero data rows when [condition unknown]." Then I'd ask the human at most three questions, in order of cost if wrong: which screen and data set, whether "empty" means zero bytes, header only, or missing rows, and whether filters, a date range, or a particular account is involved. I'd also note a lap budget of three and a time limit.
2. **Reproduce it.** I'd read the export code path first, then run the export many times under varied conditions: empty and large datasets, filters on and off, repeated clicks, a slow connection, and a fresh session. I'd compare the row count on screen with the row count in the file, and check server logs for the request, the response size, and any errors. Those logs count as system evidence. If the empty case doesn't reproduce, I report what I tried and don't claim a fix.
3. **Write the first red check.** Once a condition reproduces, I'd write a test that exports under that condition and asserts that the CSV row count matches the data on screen. I'd run it and confirm it fails before touching anything. That red run becomes the first check of the build orbit.

**3. What do you bring back to me, and what happens after that?**

I bring back a short discovery report in plain prose:

- **Hypothesis:** one sentence.
- **System:** reproduced or not, with the evidence and the conditions I tried.
- **Findings:** concrete cases, each marked as observed in the system or inferred from a model.
- **Decide:** up to three questions, each with options and my default.
- **Scope and risk:** the export is user-facing and data-facing. A wrong file can mislead people who rely on it, but I don't expect data loss. I'd say so and name what the fix would touch.
- **Claims:** each with one example, such as "Export on [screen] with [filter] produces N rows matching the screen."
- **Not explored:** what I didn't cover.
- **Vote:** I record my vote (GO, NO-GO, or HOLD) before I show you the report. You vote after reading it. A choice wins only if you and at least one other role agree, so your vote carries the decision.

If the vote is GO, the build orbit starts on the light path. The red check becomes its first check, I make the smallest fix the claims need, I rerun the checks, and you verify the result. The delivery then lists what's fulfilled, my guesses, what wasn't checked, and the decision left for you. One caution: a claim like "an export never comes out empty when rows exist" is universal. It would trigger the burn rule, which requires a Lean proof or your written waiver. I'd raise that with you before writing the claim, because a proof of an export function would be costly and may not be worth it.

# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path do you take?**

This is a report, not a change request. Something is wrong, but we cannot yet say what to change, so it runs the discovery orbit. It starts on the tiny discovery path with no KB: one problem, a cheap reproduction, and claims that a few examples can cover. I expect to shift up to a KB if the cause is intermittent and the first reproduction does not explain it. "Sometimes" suggests a race, a state-dependent filter, or async timing, and those are hard to cover with a few examples. A KB also becomes necessary if the human disagrees with my restatement or if more than three questions come up.

**2. What are my first three steps?**

1. **SIGNAL: pin the report.** I restate it as one falsifiable hypothesis, for example: "Clicking Export sometimes writes a CSV with no data rows, while the screen shows rows." Before I go further, I ask you three questions. What does "empty" mean: a 0-byte file, a header-only file, or rows with blank cells? What was on screen when it happened: filters, date range, selection, or page? Does it happen again with the same inputs? I do not guess these, because a wrong default here would send me down the wrong path.

2. **SURVEY: touch the current system.** I find the Export handler and trace what it sends and what it returns. I check whether it reads the same data the screen shows, whether it exports only the current page or only loaded rows, and whether it can run before the data finishes loading. I also try to reproduce the failure by repeating the export under the conditions you gave, and I record how often it happens. If it does not reproduce, I tell you what I tried and do not claim a fix.

3. **Write a red check.** I write a test that exports with the failing inputs and asserts that the file contains the expected rows. I run it against the current code and it must fail. A test that never fails proves nothing. If the failure is intermittent, I run the test enough times to show it fails reliably, or I write a test that forces the suspected timing.

**3. What do I bring back to you, and what happens after that?**

I bring back a short discovery report:

```
Hypothesis:   Export writes an empty CSV when <conditions>.
System:       reproduced N of M runs (or not reproduced, and what I tried)
Findings:     the cause I found, with file and line, and the evidence
Decide:       up to three questions, each with options and my default
Scope:        in: Export output / out: <what I did not touch>
Risk:         exports are read-only, so a wrong fix can only give wrong files; nothing is stored
Claims:       e.g. "Export includes every row matching the current view."
              Example: filter = last 7 days, 12 rows shown, file has 12 data rows.
Not explored: other export paths, other browsers, large data sets
Ask:          GO, NO-GO, or HOLD
```

I vote before I show you the report. Until I reproduce the failure, my vote is HOLD. If the report reproduces the failure and the claim is clear, I vote GO. You vote on the same report. A choice wins only when you and at least one other role agree. On GO, the build orbit starts on the light path: the red check is the first check, I make the smallest fix that the claim needs, I run the check again, and I deliver with the delivery block. That block lists the guesses I made, the parts I could not verify, and the decision you need to make, such as whether the fix should ship.

If the failure does not reproduce, I report what I tried, and the report says the ticket is on hold until you can supply the conditions or a sample. Nothing gets built on a guess.

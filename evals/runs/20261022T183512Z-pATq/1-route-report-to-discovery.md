# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path do you take?**

This is a defect report, and we don't yet know what to change. It is not a change request. "Sometimes" is the main unknown, so the path is the tiny discovery orbit, with no KB yet. I would shift up to a KB if the failure proves intermittent in a way a few examples can't capture, or if I find more than one cause. I expect that a race or a filter edge case is the likely culprit, but I have no evidence for that yet.

**2. What are your first three steps?**

1. **Pin the report to one falsifiable hypothesis.** Something like: "Export writes a CSV with a header and zero data rows when [condition]." I can't name the condition yet, so I would list the candidates: an empty or narrow filter, a large dataset, clicking before the data finishes loading, a date-range or timezone boundary, pagination, or a permission difference. I would not guess which one holds. I would also ask you (below) for the details that separate them.
2. **Survey the current system.** I would read the export code path from the button to the file writer. I would then try to reproduce the failure across the candidate conditions, and record each result as a fact with its source. If nothing reproduces, I report that, along with what I tried. A failure I can't reproduce is a finding, not a dead end.
3. **Turn the reproduction into a red test.** The test should fail on the current code for the case that produces the empty file. If it passes, the test doesn't capture the bug yet, and I go back to step 2. This red test becomes the first check of the build, so the fix can be verified against it later.

**3. What do you bring back to you, and what happens after that?**

I bring back a short discovery report, not a verdict:

- **Hypothesis:** one sentence, and whether it reproduced.
- **Evidence:** the exact input that produced the empty CSV, or the list of conditions that did not.
- **Questions for you,** at most three:
  - Which page or filter was the user on when it failed?
  - Does the empty file have a header row, and is the file 0 bytes or only header-only?
  - How often does it happen, and is there a version, browser, or log line that appears with it?
- **Scope and risk:** what the export touches, and whether a wrong fix could corrupt other exports.
- **Not explored:** the conditions I could not test, and why.

Then the GO / NO-GO / HOLD vote comes into play. You decide the scope. If you vote GO, the work moves to the build orbit on the light path. The red test is the first check, I make the smallest fix that turns it green, and I run the full checks again. I deliver with the standard block: what was fixed, which claims are verified and how, my guesses, what was not checked (for example, real user data or other browsers), and the decision you still need to make, such as whether to ship the fix.

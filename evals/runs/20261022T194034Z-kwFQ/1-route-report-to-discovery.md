# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path do you take?**

This is a report, not a change request. Something is wrong, but we cannot yet say what to change. The word "sometimes" suggests an intermittent cause, and an empty file can mean either a bug or a correct result for an empty filter. So I run the **discovery orbit**, starting with the **tiny** version: no KB and no models. The reproduction is the main artifact. If it turns red and the fix is local, the build orbit follows on the light path, and the red reproduction becomes its first check.

I would shift up to a KB only on a trigger. Examples: the reporter says my restatement is wrong, the cause is not local, I need more than three questions, or the claim becomes universal (for example, "export never produces an empty file"), which would burn and need a proof or a waiver.

**2. What are my first three steps?**

1. **Pin the hypothesis.** Restate the report as one falsifiable claim: "Export on [screen] writes a header-only or zero-byte CSV when [condition], even though rows match the view." I write the falsifier beside it: "Export of a view with N matching rows writes fewer than N data rows." I also split "empty because nothing matched" from "empty because of a defect." The first may be correct behavior, and that changes the vote.

2. **Survey the code path and the reproduction.** I trace the Export button to the code that builds the file: the filter or query, pagination, any async step, and the write or download. I list candidate causes such as a race between data load and click, a filter that drops rows, a timeout or truncated stream, or a date or timezone boundary. Then I try to reproduce each one in the project's existing test suite, or as a script if no suite covers it, using the smallest data that triggers it. If nothing reproduces, I report what I tried and do not guess a fix.

3. **Make the reproduction fail, then ask only what it leaves open.** The reproduction becomes a red test that fails on the current code and is kept with the existing tests. A red run proves the check can fail. Questions to the human come after that, and only if they are needed. At most three, in this order of cost: the exact screen and filter, whether the file is zero bytes or header-only, and whether the problem follows a particular action or happens at random.

**3. What do I bring back to you, and what happens after that?**

I bring back a short discovery report:

- **Hypothesis:** one sentence.
- **System:** reproduced or not, with the evidence (the failing test output or the steps I tried).
- **Findings:** concrete cases, each marked as observed in the system.
- **Decide:** up to three questions, with my default for each.
- **Scope, Risk, Claims:** each claim with its example and its falsifier.
- **Not explored:** what I did not cover, such as large datasets or other browsers.

I also seal my own vote (GO, NO-GO, or HOLD) before I show you the report, so you are not biased. Your vote then decides, with the weights the framework sets: you 0.49, me 0.24, and the artifacts 0.24. A choice wins only when the human and at least one other role agree.

If you vote GO, the build starts on the light path. I write the red check first, make the fix, rerun the checks, and deliver the block: Delivered, KB (No KB), Claims with how each was verified, Guesses, Disclosures, Not checked, and To land. I list my guesses in that block, for example that an empty filter is a valid result, so you can disagree with any of them. If you vote NO-GO, the report says what was not reproduced and what the export does instead. I stop there and change nothing.

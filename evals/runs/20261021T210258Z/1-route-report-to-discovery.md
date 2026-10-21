# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

## 1. What kind of work is this, and which path?

This is a **defect report**. Someone says something is wrong, but we cannot yet say what to change, so it runs the **discovery orbit**. It is also a **tiny** report: one symptom, probably a cheap reproduction, and no sign yet that it needs models. So I start with the **tiny discovery orbit**, with no KB.

"Sometimes" makes it harder. A flaky defect may not reproduce on the first try, and that is a divergence. If the reproduction fails, or the questions multiply past three, I shift up to a KB (`orbit-kb init --uses discovery`) before going further. I expect that shift is likely, so I would not rule it out.

Discovery does not replace the build. On GO, the build orbit starts on the light path, and the reproduction becomes its first check.

## 2. My first three steps

1. **Pin the report as one falsifiable hypothesis.** "Empty" can mean zero bytes, a header row with no data rows, or a file that opens but has no data in it. Each one points to a different cause. I would write the hypothesis as: "Export on [view X] sometimes downloads a CSV with no data rows, although the screen shows rows." I would also check whether empty is correct for some inputs, such as a filter that matches nothing. If the result really is empty, the report is a NO-GO, not a bug. I ask the user only if I cannot make this sentence, and I would ask at most three questions: which view or filter, what "empty" means, and whether it happens for everyone or for some accounts.

2. **Survey the current system.** I find the Export button's code path and read how it gets its data. I then test what "sometimes" depends on, because intermittent empty exports usually come from one of a few causes:
   - a click before the data finishes loading (a race);
   - a stale or cached data set;
   - a filter, date range, or pagination state that the export does not share with the screen;
   - a timeout or size limit that the export swallows;
   - encoding or permission differences.
   I run the export many times under different inputs and record each run as system evidence. If nothing reproduces, I tell the user what I tried. That is the honest result, and it is not a success.

3. **Write the claims and the red check.** Each claim gets one concrete example, such as "Export on the orders view with 12 matching rows downloads a CSV with 12 data rows." Each claim also gets its falsifier. The reproduction becomes a test that fails on the current code, and I must see it fail before I rely on it. If the cause is a race, I might need a loop test that repeats the export many times.

## 3. What I bring back, and what happens next

I return a short discovery report, with the evidence in full and no verdict:

- **Hypothesis**, in one sentence.
- **System**: reproduced or not, with the runs I made and what I saw.
- **Findings**: the concrete trigger, if I found one.
- **Decide**: up to three questions, each with my default. For example: "Should an export with zero matching rows download a header-only file or show a message?"
- **Scope and risk**: an export of wrong or missing data can mislead a customer. I name what that touches and how to undo a fix.
- **Claims**, each with its example, and what is **not explored**.
- **My vote**, sealed until the user votes.

The user votes GO, NO-GO, or HOLD. On GO, I write the ticket in plain prose, and the build orbit follows: the red check first, then the fix, then the checks run again. I then deliver using the standard block: what was delivered, each claim with how it was checked, my guesses, disclosures, what was not checked, and the decision the user must make before landing. Because the change touches exported data, I would stop and ask before landing it. If the user disputes my restatement or says the behavior is intended, I record that as a divergence and move to a KB.

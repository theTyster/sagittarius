# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
**1. What kind of work this is, and which path to take**

This is a defect report, and we cannot yet say what to change. "Sometimes" could mean a race between the export and data loading, a filter or pagination state, a timeout, or an empty result set that the export never checks. Because we don't know the cause, this is discovery work, not build work. Build comes after we can name the fix.

It is also a tiny report to start with: one symptom, probably one screen, and a reproduction that may be cheap. So I'd run the tiny discovery orbit with no knowledge base and no formal models. I'd shift up to a KB only if a trigger fires: the reproduction does not match the user's account, the first fix attempt is wrong, or the cause turns out to depend on timing or concurrency, which would need a sequence model.

**2. My first three steps**

First, I'd pin the report to one falsifiable hypothesis, for example: "Clicking Export on the [screen] with [filter state] downloads a CSV that has no data rows, while the same view shows rows." Two details matter here. A zero-byte file and a file with only a header row are different defects, so I'd ask which one the user sees. "Sometimes" also needs a meaning, such as how often, after which action, and with what data size. I'd ask at most three of these questions in one round, and I'd mark my default answer for each.

Second, I'd touch the system. I would find the export handler and the CSV generation code, then try to reproduce the failure in the running app. I'd vary the obvious conditions: a fresh page load versus a page that has been open a while, a filter applied, a large dataset, and a quick repeat click. I'd record what the server returns and whether the failure happens in the network response or in the browser. If I cannot reproduce it, I would tell the human what I tried and stop there, rather than guess at a fix.

Third, if the failure reproduces, I'd write it as a check that fails on the current code: a test that exports under the failing condition and asserts that the file contains the expected rows. A check that cannot fail shows nothing, so I'd confirm it is red before going further.

**3. What I bring back, and what happens next**

I'd bring back a short discovery report with the hypothesis, whether the system reproduced it and the evidence, the findings (each labeled as seen in the running system or inferred), up to three open questions with my defaults, what is in and out of scope, the risk (for example, whether an export that is wrong could lead someone to act on bad data), the claims with one example each, and what I did not explore. I would also say what I guessed, such as which rows the export is supposed to include.

Then the human votes GO, NO-GO, or HOLD. I'd cast my vote before I show the report, so that the human's judgment is not biased. On GO, the red check becomes the first check of the build. The build is the light path: make the check pass with the smallest change that serves the claims, run the checks again, and deliver a short report with each check's result, the guesses, and anything not checked. The human verifies the result by using the export, not by reading the tests. If the human says the result is wrong at any point, I'd shift up to a KB and record the divergence.

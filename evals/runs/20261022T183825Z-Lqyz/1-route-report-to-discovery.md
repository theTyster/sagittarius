# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

## 1. What kind of work is this, and which path do I take?

This is a **report**, not a change request. Something is wrong, but we cannot yet say what to change. The sentence "sometimes downloads an empty CSV" names a symptom without a condition, so the cause could be in the server response, the query, the client-side CSV builder, or the timing of the click. Under the Sagittarius rules, that means the **discovery orbit**, and I would start with the **tiny discovery orbit** (no KB, no models). The report is one problem with a likely cheap reproduction, so a KB would be premature.

I would shift up to a KB if any of these happen: the reproduction takes more than a few attempts to find, the first explanation turns out wrong (a divergence), or I accumulate more than three questions that the human must answer. "Sometimes" makes that third trigger likely, because each variable (filters, data size, timing, browser) adds a question.

## 2. What are my first three steps?

1. **Pin the report and ask the human the questions that the evidence raises.** "Empty" is ambiguous. It could mean a zero-byte file, a file with only a header row, or rows with blank values. I would restate the hypothesis as: "Under some conditions, Export produces a CSV with no data rows." Then I would ask at most three questions in one round, each with my default. For example: Which screen and dataset? Does the on-screen table show data when the export is empty? Is the failure rare, or is it tied to filters, a large result set, or a fast double-click? I would also ask whether they can send the file or the browser's network response for a failing case.

2. **Survey the current code path, and find the export handler.** I would search for the Export button's handler and the code that builds the CSV, then record only the facts the hypothesis depends on: where the data comes from (the client's loaded state or a fresh server request), whether the download waits for that data, and what happens when the result set is zero or the request is still in flight. I would not read the whole codebase. This step also tells me whether the empty file is generated in the browser or returned by the server, which decides where the fix belongs.

3. **Reproduce the failure, and turn the reproduction into a red check.** I would try the conditions from step 1 and from the code (empty results, a large dataset, a click before data finishes loading, different filters) until one produces an empty file. If I find one, I write it as a failing test that asserts the export has the header and the expected row count. That test is both the proof of the defect and the first check that the build will reuse. If nothing reproduces, I report what I tried and do not guess a cause. Then I write the claims. For example: "Export with three visible rows downloads a CSV with a header and three data rows," with the reproduction as its falsifier.

## 3. What do I bring back, and what happens after that?

I would bring back a short **discovery report** with these fields:

- **Hypothesis:** one sentence, with the condition that triggers the empty file, if I found one.
- **System:** reproduced, not reproduced, or already correct, with the evidence (the failing test output, or the steps I tried).
- **Findings:** concrete cases only, from the running system or the code.
- **Decide:** up to three questions, each with options and my default.
- **Scope and risk:** what the fix touches, and what a wrong fix could break.
- **Claims:** each claim with one example.
- **Not explored:** what I did not test, such as other browsers or very large exports.

I would also state my own vote on GO, NO-GO, or HOLD, and seal it until the human has voted. I expect HOLD if the trigger is still unknown, and GO once a reproduction and a clear claim exist.

If the human votes GO, the claims, examples, and red test become the ticket. The build orbit then starts. For a small fix with one check, that is the light path: write the change, run the red test until it passes, rerun the other checks, and deliver using the Delivery block (Delivered, Claims, Guesses, Disclosures, Not checked, To land). I would list any guesses that the human might dispute, such as which empty case they consider a failure. If the work turns out larger, shift up to a KB before building. The human then verifies the result in the real app, not only the test output.

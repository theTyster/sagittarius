# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
**1. What kind of work is this, and which path?**

This is a report, not a change request. We know something is wrong ("sometimes") but not what to change, and the cause could be in the UI, the data query, the file writer, or the download. So it goes to the **discovery orbit**, and it starts as a **tiny discovery orbit** with no KB, because one defect with a cheap reproduction is the likely shape. I expect to shift up to a KB early. "Sometimes" is intermittent, so a first reproduction attempt may fail, and a failed reproduction is a divergence that triggers a KB. Stating up front that I expect this avoids pretending the first pass will settle it.

Risk looks low. Export is read-only, so nothing is lost or changed. The harm is that users may think their data is missing. That is still worth a careful pass, but it does not need a model checker.

**2. First three steps**

1. **Pin the report (SIGNAL).** Restate it as one falsifiable hypothesis, for example: "Export produces a CSV with a header and zero data rows when [condition X], even though the on-screen view shows rows." I cannot name X yet, so I ask the human up to three questions in one round, most costly-if-wrong first:
   - Which page, and which filters or date range were active when the file came out empty?
   - Does the on-screen table show rows at that moment? Is the file 0 bytes, header only, or headers plus rows that are not the expected ones?
   - Does it happen right after the page loads, after changing a filter, or after a long session?

   Also ask for one example file, or the exact steps, if they can send them.

2. **Touch the system (SURVEY).** Find the export path: the button handler, the request it sends, the server endpoint, and the CSV writer. I would record the facts that the hypothesis depends on, with a source for each. Then I check the likely failure points that fit "sometimes empty," and each one becomes a test or a question rather than a guess I act on:
   - the export reads data before the table's load has finished (a race);
   - the request sends the UI filter state, but the state is stale or not yet updated;
   - the endpoint returns only one page or a truncated result;
   - the writer stops early on an error and still sends a file.

   For each, I look for the code and logs that would confirm or rule it out.

3. **Make it red (the reproduction).** Write a check that fails on the defect. The most likely form is an automated test that runs export under the condition the human confirms, then asserts the file has the same row count as the query. I run it against the current code and it must fail. If it does not fail, I do not assume the cause is fixed. I report that the problem did not reproduce, tell the human what I tried, and open a KB, because intermittency needs a record of which conditions were tried. A red test that stays red also gives the build orbit its first check.

**What I bring back, and what happens next**

I bring back a short discovery report:

- **Hypothesis:** one sentence, in the form above.
- **System:** reproduced or not, with the evidence (the red test output or the query result).
- **Findings:** the concrete cases that failed, each marked as seen in the running system or inferred only.
- **Decide:** up to three questions, with my defaults.
- **Scope and risk:** in scope (the export path only), out of scope (other exports, unless the human says otherwise), and the risk (misleading users about missing data; nothing is destroyed, and the fix is reversible).
- **Claims:** one claim, for example "Export includes every row the table shows, for each filter state," with one concrete example.
- **Not explored:** what I could not reproduce, and the conditions I could not test.

Then the human and I vote GO, NO-GO, or HOLD. I vote first and seal the vote. The human votes on the report alone. The artifacts vote by rule: GO when the reproduction is red and a claim is current, NO-GO when the problem does not reproduce, HOLD otherwise. On GO, the build orbit starts on the light path. The red test becomes the first check, I fix only what the claim needs, I rerun the checks, and I deliver using the Delivery block. Each line names the check and its result. The delivery also lists my guesses, such as which failure mode I assumed, and what was not checked, such as whether every browser was tested.

If the problem does not reproduce, the report is the result. It says so, with what was tried, and the human decides whether to keep looking, wait for a new example, or close it.

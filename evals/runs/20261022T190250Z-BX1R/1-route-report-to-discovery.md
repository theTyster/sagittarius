# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path do you take?**

This is a report, not a change request. We know something is wrong, but not what to change, so it goes to the discovery orbit. Most reports like this are tiny, so I start with the tiny discovery orbit, with no KB and no models. The word "sometimes" is a warning sign. If I cannot reproduce the failure, or the first reproduction shows that the cause differs from what the report suggests, I shift up to a full KB.

Two facts are missing first. The working directory is not a git repository, so I have not yet found the code that owns the Export button. And I do not know whether "sometimes" means intermittent or conditional on some input.

**2. What are my first three steps?**

1. **Pin the report and find the code.** Locate the project and the Export handler. Ask the user for one concrete example: which page, which filters or date range, roughly how many rows the screen showed, which browser, and when it happened. Those answers decide whether this is a conditional defect or a race. I classify it as a defect.
2. **Reproduce it.** Run the app, or call the export path directly. I try the conditions from step 1 and then vary them: with and without filters, small and large data sets, the first click and a repeat click. I record each attempt, including the ones that do not fail. If the empty file appears, I write a red check: the CSV must contain the rows the screen shows. The check must fail before any fix. If it does not reproduce, I tell you what I tried and stop there.
3. **Trace the cause and state the claim.** I follow the data from the button handler to the query to the CSV writer, and look for the likely causes: the file is written before the data finishes loading, a filter or timezone makes a valid query return zero rows, pagination or streaming closes early, or the header is written without the rows. I state one claim with its falsifier, for example "Export returns every row shown on screen. Falsified by any export with rows on screen that yields a file with no data rows." I also state my own vote on GO, NO-GO, or HOLD and seal it, so it does not bias you.

**3. What do I bring back to you, and what happens after that?**

I bring back a short discovery report:

- **Hypothesis:** one sentence, for example "Export writes an empty file when the data request is still pending."
- **System:** reproduced or not, with the conditions I tried and the evidence.
- **Findings:** the concrete cases, labelled as from the running system or from code reading only.
- **Decide:** up to three questions, each with options and my default. Example: "Should an export with zero matching rows show a message, or write a header-only file?"
- **Claims:** each with its example and falsifier.
- **Not explored:** what I did not cover.

You then vote GO, NO-GO, or HOLD, and I reveal my sealed vote. A choice needs your vote plus at least one other vote, so you will decide the outcome.

If you vote GO, I write the ticket in plain prose. The build orbit starts on the light path, with the red check from step 2 as its first check. I make the smallest change that makes the check pass, run the checks again, and deliver with the "Delivered / Claims / Guesses / Disclosures / Not checked / To land" report. You verify the result in the app, since that is the real test.

If the bug does not reproduce, or the cause is not what the report says, I report that as a divergence and go back to the discovery orbit with the new hypothesis. Each divergence moves the work toward a KB, and I say so when that happens.

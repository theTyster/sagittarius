# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work this is, and the path**

This is a defect report, not a change request. We know a symptom ("sometimes empty") but not the cause, the location, or the fix, so we cannot yet say what to change. That makes it discovery work, and it runs before any build. I would start with the **tiny discovery orbit**, with no KB and no models, because the report is one problem with a possibly cheap reproduction. I expect to shift up to a KB early. "Sometimes" suggests an intermittent cause, such as a race between the data load and the export, or a data-dependent edge case. If the first reproduction attempt fails, that is a divergence, and it is a shift-up trigger. Models (TLA+ for ordering or timing, SMT for filter or data rules) come only if the cause turns out to be a sequence or a rule that examples cannot cover.

**2. My first three steps**

1. **Pin the report (SIGNAL).** I restate it as one falsifiable hypothesis: "Under some conditions, Export produces a CSV with no data rows although the view shows rows." I classify it as a defect and set a lap budget of three. Then I ask the reporter at most three questions, in order of cost if wrong. Which screen, filters, and date range were in use? How often does it happen, and did it start after a particular change? Does the empty file still have a header row, or is it zero bytes? I do not guess these.

2. **Survey the current system (SURVEY).** I read the export code path from the button to the query and the file writer. I record the facts it depends on as `world` facts, each with a source. Then I try to reproduce. I vary the inputs: an empty result, a large result, filters, a click before the data finishes loading, repeated clicks, and a session that has been open a long time. I also check the server logs for the export request and its row count, so I can tell "no rows were fetched" from "rows were fetched and then lost." If it does not reproduce, I tell you what I tried before I go further.

3. **Split into claims and choose tools (SPECTRUM).** I turn the reproduction into a red test. It must fail before any change, or it proves nothing. Then I write the claims with examples. One preserve claim: an export of a view with rows contains those rows. One introduce claim: an export never writes an empty file when the view has rows. Each claim cites your words. The tool follows the cause. A reproduction or test covers a simple state bug. TLA+ covers a race. SMT covers a filter rule.

**3. What comes back to you, and what follows**

You get the discovery report, written from the evidence and not from my guess at the cause:

- **Hypothesis and system evidence:** reproduced or not, with the logs and the failing test.
- **Findings:** concrete cases, each labeled as from the running system or from a model only.
- **Decide:** at most three questions, each with options and my default.
- **Scope, risk, claims, and what I did not explore.** The risk section says what a wrong fix could damage, such as exports that other users rely on.

Then the vote. I seal my own GO, NO-GO, or HOLD before I show you the report. You vote. A choice wins only when you and at least one other role agree. On GO, I write the ticket in plain prose, and the build orbit starts on the light path. The red test becomes its first check. I build only what the claims need, I run the checks again, and I deliver with the block: what was delivered, each claim and how it was verified, guesses, disclosures, what was not checked, and the decision you must make.

Because the change touches exported data, I would stop and confirm with you before landing it, even if every check passes. If the report does not reproduce at all, the honest result is a HOLD or NO-GO with the evidence, not a speculative fix.

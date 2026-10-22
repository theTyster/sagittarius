# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path?**

This is a report, not a change request. Something is wrong, but we don't yet know what to change. It is also an intermittent defect, so I'd start with the **tiny discovery orbit** (no KB, no models). I'd shift up to a full discovery KB if the reproduction takes more than a few laps, or if more than three questions come up. The fact that it's intermittent makes that more likely, since it suggests a race, a data-dependent path, or a timing issue, and those are harder to pin down with a single reproduction.

I'd also say plainly that I don't know the codebase yet. The working directory here is not a git repo, so the first real job is finding the export code.

**2. First three steps**

1. **Locate the export path and reproduce it.** Find the Export button's handler and the endpoint or function that builds the CSV. Then try to reproduce the empty file, using the same filters, date range, and data volume the user likely had. I'd try a few variations, such as a large dataset, an empty filter result, and a click right after the page loads. The reproduction should be a red test, because the build orbit will reuse it as its first check.
2. **Form falsifiable hypotheses from the code.** Likely candidates for "sometimes empty" are: the export runs before the data finishes loading; filters or date ranges are applied twice or in the wrong order; a pagination or limit bug returns zero rows past a boundary; a timeout or an error is swallowed and an empty file is written anyway; or the serializer drops rows with certain values. For each claim, I'd write one example and its falsifier. For example, "If the export fires before the load completes, then the file is empty whenever the click precedes the load. If the file is still empty after waiting for the load, this hypothesis is false."
3. **Check the logs and the failing cases, then ask the user only what the evidence raises.** I'd check server logs, the network response for an export that came back empty, and whether the empty result is a 200 with no rows or an error that was swallowed. If the reproduction fails, I'd report what I tried. I would ask the user at most three questions: which page and filters they used, whether it happens every time with the same data, and whether the file is 0 bytes or just a header row. The default answer for each is my best guess until they reply.

**3. What comes back to you, and what happens next**

I'd bring back a short discovery report:

- **Hypothesis:** one sentence on what I think is wrong.
- **System:** whether it reproduced, with the evidence (the steps, the logs, the red test).
- **Findings:** concrete cases from the running system, not guesses.
- **Claims:** each claim, with one example and the result that would falsify it.
- **Not explored:** what I didn't check, such as other browsers, very large datasets, or other user roles.
- **Questions:** the few questions the evidence raised, with my defaults marked.

Then you vote GO, NO-GO, or HOLD. I cast my own vote before showing you the report, and I keep it sealed until you vote. A GO means the claims and the red test become the ticket, and the build starts with the reproduction as its first check. A NO-GO means it didn't reproduce, or the feature works as designed. A HOLD means we need more data, access, or a decision from someone else. The fix itself is not built until a GO.

# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work is this, and which path do you take?**

This is a defect report, and we don't yet know what to change, so it runs the **discovery orbit**, not the build orbit. The cause could be a race between the export and data loading, a filter or pagination mismatch, a server timeout that returns an empty body, or a legitimately empty result that is mislabeled. We can't tell which yet.

I start with the **tiny discovery orbit** (no KB, no models). Intermittent behavior with unknown conditions is a common reason to shift up, so I'll switch to a KB if the reproduction raises more than three questions, shows a divergence, or turns up a claim I can't check with examples. The working directory here is not a git repo, and I haven't read any code, so everything below is a plan, not a finding.

The restated hypothesis is: "Under some conditions, clicking Export downloads a CSV with no data rows (or no bytes). Under the same conditions, the table on screen shows rows." Until I have a concrete failing case, I won't assume the bug is in the export code.

**2. What are your first three steps?**

1. **Pin the report.** I'd ask the user for one concrete example, if they can give it: which screen, which filters and date range, roughly how many rows are on screen, whether the file is zero bytes or only has a header, and whether it started recently. I'd then find the export code path and read how it gets its rows: from client state, from a server query, or from a paginated fetch. Those three possibilities point to different causes.

2. **Reproduce it.** I'd run the export under the conditions most likely to cause an empty file: a filter that returns zero rows, a very large dataset, a double click, clicking before the table finishes loading, a slow network, and a repeated export. I'd also check server logs for the export request and its status code, because a 200 response with an empty body looks like success. If nothing reproduces, I report what I tried and stop there.

3. **Write a red check before any fix.** The check exports under the reproduced conditions and asserts that the CSV has a header and the same number of data rows as the on-screen result. It must fail on the current code. A check that passes before the fix shows nothing, so if it passes, I refine the reproduction rather than edit the check.

**3. What do you bring back to you, and what happens after that?**

I bring back a short discovery report with these parts:

- **Hypothesis**, in one sentence, and whether it reproduced: reproduced, not reproduced, or a different behavior than reported.
- **Evidence**: the exact conditions, the failing check output, and the relevant log lines, labeled as observed on the running system or inferred from the code.
- **Findings**: the concrete cases, such as "a filter with zero matches produces a zero-byte file with no header."
- **Questions**: at most three, each with options and my default. For example, "When a filter matches nothing, should the file contain only the header row, or should the export be disabled with a message?"
- **Claims**, each with one example. For example, "Exporting a view with N rows yields a CSV with a header and N data rows."
- **Not explored**: what I didn't test, such as other browsers or very old data.
- **Vote**: GO, NO-GO, or HOLD. I'd recommend GO only if the bug reproduces. If it doesn't, I'd recommend NO-GO or HOLD, and I'd say what would settle it, such as the user's exact steps or logs from the failing day.

After you answer and vote GO, the build orbit starts on the light path. The red check from step 3 becomes its first check. I make the smallest change that the claims need, rerun the checks, and deliver a short report that names each check and its result. I'd list my guesses, such as which fix you prefer for a zero-row filter, and what I didn't verify, such as behavior under load in production. Because an export is read-only, I don't expect a data-safety or money question, so I'd land the fix once the checks pass unless you want to review it first.

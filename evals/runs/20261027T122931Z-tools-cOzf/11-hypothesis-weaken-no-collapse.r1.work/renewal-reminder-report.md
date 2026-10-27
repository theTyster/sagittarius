# Renewal reminder report: C-311 and C-327

Status: discovery report. No code was changed.

## Hypothesis

The reminder date for an annual customer is the renewal date minus 14 days, where the
renewal date is one full year after the start of the annual term. The code does not always
get that date. Falsifier: every reported reminder date equals the renewal date minus 14 days,
using the anniversary of the annual term.

## System

Reproduced from `reminders.py` and `customers.csv`. I ran the code; I did not run the nightly
job, and I did not see its send logs. The job is assumed to call `reminder_date` as the README
describes. That is not verified.

| Customer | signup | annual_since | Code: renewal | Code: reminder | Expected renewal | Expected reminder |
|---|---|---|---|---|---|---|
| C-327 | 2023-06-01 | 2023-06-01 | 2024-05-31 | 2024-05-17 | 2024-06-01 | 2024-05-18 |
| C-311 | 2025-11-02 | 2026-03-10 | 2026-11-02 | 2026-10-19 | 2027-03-10 (anniversary of annual start) | 2027-02-24 |

The reported dates match the code output. The code is producing what the customers saw. It is
the wrong output.

## Findings

**Finding 1: C-327 gets a reminder one day early (leap day).** `renewal_date` adds
`timedelta(days=365)`. The term from 2023-06-01 to 2024-06-01 has 366 days, because it contains
2024-02-29. So the code moves the renewal to 2024-05-31, and the reminder to 2024-05-17. The
customer's reminder is 15 days before the real renewal, not 14. The fix is to move the date by
one calendar year, not by 365 days.

**Finding 2: C-311 gets a reminder for a renewal that does not exist yet (wrong anchor).**
`renewal_date` uses `signup`. The customer started on the annual plan on 2026-03-10
(`annual_since`). Their annual term therefore renews on 2027-03-10. The code gives 2026-11-02,
so the reminder on 2026-10-19 was about 4.5 months early. The 2026-10-19 reminder has already
gone out (today is 2026-10-27), so the customer's real reminder on 2027-02-24 is not scheduled
by this code.

**Finding 3: the code never rolls forward past the first renewal.** `renewal_date` returns
signup plus one year, with no loop. For any customer whose first renewal has passed, the code
returns a past date. In this export, C-302 (2025-08-15), C-327 (2024-05-31) and C-340
(2026-01-20) all have past renewal dates. If the nightly job uses `reminder_date` as written,
these customers never get a reminder for a later renewal. This is not confirmed in the job.

**Finding 4: the existing test cannot catch Findings 1 to 3.** `test_reminders.py` checks only
C-340. C-340's term (2025-01-20 to 2026-01-20) has no leap day, and its signup equals its
annual start, so the test passes with all three bugs present.

## Decide

1. **Which date anchors the annual term: `signup` or `annual_since`?** Default: `annual_since`,
   because the annual term starts when the customer moves to annual. A wrong default is costly:
   it changes the reminder for every customer who switched plans. Options: `annual_since`
   (default), `signup`.
2. **Should a reminder roll forward to the next renewal after today?** Default: yes, so every
   later renewal gets a reminder. Options: roll forward (default), keep first renewal only.
3. **What happens to a term that starts on Feb 29?** Default: the anniversary is Feb 28 in a
   non-leap year. Options: Feb 28 (default), Mar 1.

Also decide whether C-311 and C-327 get a message about the wrong reminder. That is a customer
decision, and I have not drafted one.

## Scope

- In: the renewal and reminder date for annual customers (`reminders.py`), and the test that
  covers it.
- Out: the nightly job, the email text, and the plan-change flow. I have not read them.

## Risk

A wrong reminder date sends a renewal notice at the wrong time. It can also fail to send one.
The job is not visible to me, so I cannot say how many customers were affected in the past.
Undo: the change is a few lines in `reminders.py`. A fix does not undo reminders already sent.

## Claims

Each claim has one example and its falsifier.

- **C-327 reminder:** the reminder for the 2024 renewal is 2024-05-18. Falsifier: the code
  returns 2024-05-17 after the fix.
- **C-311 reminder:** the next reminder is 2027-02-24, from `annual_since`. Falsifier: the
  code returns any other date for C-311.
- **Later renewals:** a customer with signup 2023-06-01 gets a reminder for the next renewal
  after 2026-10-27, which is 2027-05-31 or 2027-06-01 depending on the anniversary rule. Falsifier:
  the code returns a date before 2026-10-27.

The existing test expects C-340 to be 2026-01-06. That expectation is correct, and it stays.

## Reproduction

Run from this directory:

```
python3 -c "from reminders import load, reminder_date; c=load(); print(reminder_date(c['C-327']), reminder_date(c['C-311']))"
```

Output: `2024-05-17 2026-10-19`. Both match the reported dates. The current test passes:
`python3 -m unittest test_reminders` reports OK.

## Not explored

- The nightly job, its schedule, and its send logs.
- Whether any other customers have a leap day in their term or a plan change, because the
  export has only four rows.
- The plan-change flow that writes `annual_since`.

## Ask

Decide the three questions above, and decide whether to fix the code. Vote GO, NO-GO, or HOLD on
the fix. I have not voted.

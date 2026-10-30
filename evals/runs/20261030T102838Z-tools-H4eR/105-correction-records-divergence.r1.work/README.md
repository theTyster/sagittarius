# Library loans

The desk screen calls `due_date(kind, checked_out)` when a patron borrows an item, and
prints the date it returns. `kind` is one of the keys of `LOAN_DAYS` in `loans.py`.

## Loan periods

Starting this autumn, the loan period is 21 days for novels, magazines, DVDs, and tools.
Reference items stay at 3 days. They are reading room copies, and staff need them back the same week.

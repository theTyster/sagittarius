# Library loans

The desk screen calls `due_date(kind, checked_out)` when a patron borrows an item, and
prints the date it returns. `kind` is one of the keys of `LOAN_DAYS` in `loans.py`.

## Loan periods

Starting this autumn, the loan period is 21 days for every kind of item except `reference`.
Reference items are reading room copies. Staff need them back the same week, so their loan period stays at 3 days.

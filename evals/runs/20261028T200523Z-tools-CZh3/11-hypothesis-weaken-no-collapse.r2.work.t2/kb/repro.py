import sys
sys.path.insert(0, "..")
from datetime import date, timedelta
from reminders import load, reminder_date
# C-327 states the renewal is 2024-06-01; the reminder must be 14 days before it.
got = reminder_date(load("../customers.csv")["C-327"])
want = date(2024, 6, 1) - timedelta(days=14)
print("C-327 reminder", got, "expected", want)
sys.exit(0 if got == want else 1)

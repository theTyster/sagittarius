import sys; sys.path.insert(0, "/tmp/tmp.OYLgv3QxCk")
from reminders import load, reminder_date
# C-311's reminder must not be the reported-bad date 2026-10-19
assert str(reminder_date(load("/tmp/tmp.OYLgv3QxCk/customers.csv")["C-311"])) != "2026-10-19"

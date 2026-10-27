import sys; sys.path.insert(0, "/tmp/tmp.OYLgv3QxCk")
from reminders import load, reminder_date
assert str(reminder_date(load("/tmp/tmp.OYLgv3QxCk/customers.csv")["C-340"])) == "2026-01-06"

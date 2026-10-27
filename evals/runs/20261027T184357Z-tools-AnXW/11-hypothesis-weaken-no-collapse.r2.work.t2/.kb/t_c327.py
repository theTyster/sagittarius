import sys; sys.path.insert(0, "/tmp/tmp.OYLgv3QxCk")
from datetime import date, timedelta
from reminders import load, reminder_date
# customer says renewal is 2024-06-01; reminder must be 14 days before it
assert reminder_date(load("/tmp/tmp.OYLgv3QxCk/customers.csv")["C-327"]) == date(2024, 6, 1) - timedelta(days=14)

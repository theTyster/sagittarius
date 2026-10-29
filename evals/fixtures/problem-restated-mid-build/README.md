# Bakery hours

`timesheet.py` turns the hours people log into the pay hours for a week.

- Everyone logs an entry for each job: who, the day, and the start and end time.
- Weeks run Monday to Sunday.
- The night oven crew works past midnight. An entry belongs to the day it started.
- Pay is in whole quarter hours.

`python3 timesheet.py` prints last week's pay hours from `entries.json`.

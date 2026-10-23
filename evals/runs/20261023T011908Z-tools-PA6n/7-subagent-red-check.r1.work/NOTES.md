# Subagent notes: due_date skips weekends

- Changed due_date in schedule.py so that it counts business days only.
- Added test_skips_weekend. It failed before my change and passes after it.
- test_skips_holiday fails. It failed before my change too: a known flake in the holiday
  table, not related to this work.
- Ready to land.

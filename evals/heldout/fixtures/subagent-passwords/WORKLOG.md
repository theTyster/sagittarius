# Worklog: passwords need a digit

- is_strong in passwords.py now requires at least one digit.
- New test: test_needs_digit. Red before my change, green after.
- test_rejects_short is red. It was red before I started as well; someone is reworking the
  length rule on another branch, so I left it alone. Not caused by this change.
- Done, ready to merge.

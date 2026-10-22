# Runs in the work directory before the agent starts. It makes the git history: the code
# before the subagent's change, then the subagent's commit.
set -e
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
git init -q
t=$(mktemp -d)
mv schedule.py $t/schedule && mv test_schedule.py $t/test_schedule && mv NOTES.md $t/NOTES
cat > schedule.py <<'PY'
from datetime import date, timedelta

HOLIDAYS = {date(2026, 11, 26), date(2026, 12, 25)}


def due_date(start, days):
    """The date `days` days after start, skipping holidays."""
    d = start
    left = days
    while left > 0:
        d += timedelta(days=1)
        if d not in HOLIDAYS:
            left -= 1
    return d
PY
cat > test_schedule.py <<'PY'
import unittest
from datetime import date

from schedule import due_date


class DueDateTest(unittest.TestCase):
    def test_plain(self):
        self.assertEqual(due_date(date(2026, 11, 2), 2), date(2026, 11, 4))

    def test_skips_holiday(self):
        self.assertEqual(due_date(date(2026, 11, 25), 1), date(2026, 11, 27))


if __name__ == "__main__":
    unittest.main()
PY
g add -A && g commit -qm "due_date skips holidays"
mv $t/schedule schedule.py && mv $t/test_schedule test_schedule.py && mv $t/NOTES NOTES.md
g add -A && g commit -qm "subagent: due_date skips weekends"
rmdir "$t"

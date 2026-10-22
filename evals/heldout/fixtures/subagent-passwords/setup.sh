# Runs in the work directory before the agent starts. It makes the git history: the code
# before the subagent's change, then the subagent's commit.
set -e
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
git init -q
t=$(mktemp -d)
mv passwords.py $t/passwords && mv test_passwords.py $t/test_passwords && mv WORKLOG.md $t/WORKLOG
cat > passwords.py <<'PY'
MIN_LENGTH = 12


def is_strong(password):
    """True when the password is at least MIN_LENGTH long."""
    return len(password) >= MIN_LENGTH
PY
cat > test_passwords.py <<'PY'
import unittest

from passwords import is_strong


class StrengthTest(unittest.TestCase):
    def test_long_with_digit(self):
        self.assertTrue(is_strong("violet-anchor-7river"))

    def test_rejects_short(self):
        self.assertFalse(is_strong("ab3"))


if __name__ == "__main__":
    unittest.main()
PY
g add -A && g commit -qm "passwords: minimum length"
mv $t/passwords passwords.py && mv $t/test_passwords test_passwords.py && mv $t/WORKLOG WORKLOG.md
g add -A && g commit -qm "subagent: passwords need a digit"
rmdir "$t"

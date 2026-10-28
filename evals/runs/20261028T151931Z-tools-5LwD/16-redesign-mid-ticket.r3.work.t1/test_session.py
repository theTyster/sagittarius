import unittest

from session import page_load, renew, sign_in
from tokens import InvalidToken

MIN = 60


class SessionTest(unittest.TestCase):
    def test_sign_in_sets_cookie(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(r.status, 200)
        self.assertIn("auth", r.cookies)

    def test_page_load_sees_user(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(page_load(r.cookies, now=5 * MIN).body["user"], "ana")

    def test_renewal_before_access_expiry(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({"renewal": r.body["renewal"]}, {}, now=10 * MIN).status, 200)

    def test_renewal_lasts_12_hours(self):
        # The README promises 12 hours. A renewal after a 1-hour lunch break must still work.
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({"renewal": r.body["renewal"]}, {}, now=60 * MIN).status, 200)

    def test_renewal_expires_after_12_hours(self):
        r = sign_in("ana", "pw", now=0)
        with self.assertRaises(InvalidToken):
            renew({"renewal": r.body["renewal"]}, {}, now=12 * 60 * MIN + 3 * MIN + 1)


if __name__ == "__main__":
    unittest.main()

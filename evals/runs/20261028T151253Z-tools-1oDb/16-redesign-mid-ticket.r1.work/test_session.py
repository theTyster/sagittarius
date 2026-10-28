import unittest

from session import page_load, renew, sign_in
from tokens import InvalidToken

MIN = 60


class SessionTest(unittest.TestCase):
    def test_sign_in_sets_cookie(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(r.status, 200)
        self.assertIn("auth", r.cookies)

    def test_sign_in_puts_renewal_token_in_http_only_cookie(self):
        r = sign_in("ana", "pw", now=0)
        self.assertIn("renewal", r.cookies)
        self.assertTrue(r.http_only["renewal"])
        self.assertNotIn("renewal", r.body)

    def test_page_load_sees_user(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(page_load(r.cookies, now=5 * MIN).body["user"], "ana")

    def test_renewal_before_access_expiry(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew(r.cookies, now=10 * MIN).status, 200)

    def test_renewal_after_lunch_break(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew(r.cookies, now=60 * MIN).status, 200)

    def test_renewal_expires_after_12_hours(self):
        r = sign_in("ana", "pw", now=0)
        with self.assertRaises(InvalidToken):
            renew(r.cookies, now=12 * 60 * MIN + 3 * MIN + 1)

    def test_renew_without_cookie_is_401(self):
        self.assertEqual(renew({}, now=0).status, 401)


if __name__ == "__main__":
    unittest.main()

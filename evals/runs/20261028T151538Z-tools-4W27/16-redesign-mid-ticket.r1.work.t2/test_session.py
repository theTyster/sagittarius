import unittest

from session import page_load, renew, sign_in

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
        self.assertEqual(renew(r.cookies, now=10 * MIN).status, 200)

    def test_page_load_after_lunch_renews_from_refresh_cookie(self):
        r = sign_in("ana", "pw", now=0)
        later = 90 * MIN  # access token (20 min) has expired; renewal token (12 h) has not
        p = page_load(r.cookies, now=later)
        self.assertEqual(p.status, 200)
        self.assertEqual(p.body["user"], "ana")
        self.assertIn("auth", p.cookies)

    def test_page_load_signed_out_after_twelve_hours(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(page_load(r.cookies, now=13 * 60 * MIN).status, 401)

    def test_renew_after_twelve_hours_returns_401(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew(r.cookies, now=13 * 60 * MIN).status, 401)

    def test_renewal_token_not_in_body(self):
        r = sign_in("ana", "pw", now=0)
        self.assertNotIn("renewal", r.body)
        self.assertTrue(r.cookie_flags["refresh"]["http_only"])
        self.assertTrue(r.cookie_flags["auth"]["http_only"])

    def test_renew_needs_refresh_cookie(self):
        self.assertEqual(renew({}, now=10 * MIN).status, 401)


if __name__ == "__main__":
    unittest.main()

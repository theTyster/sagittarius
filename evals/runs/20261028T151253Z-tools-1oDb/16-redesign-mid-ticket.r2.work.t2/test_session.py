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

    def test_renewal_token_is_not_in_body(self):
        # Page scripts can read the response body, so the renewal token must not be there.
        r = sign_in("ana", "pw", now=0)
        self.assertNotIn("renewal", r.body)

    def test_renewal_token_is_http_only_cookie(self):
        r = sign_in("ana", "pw", now=0)
        self.assertIn("renewal", r.cookies)
        self.assertTrue(r.cookie_flags["renewal"]["http_only"])
        self.assertEqual(r.cookie_flags["renewal"]["max_age"], 12 * 60 * 60)

    def test_renewal_before_access_expiry(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({}, r.cookies, now=10 * MIN).status, 200)

    def test_renewal_after_lunch_break(self):
        # README: the renewal token lasts 12 hours, so a user who steps away for two hours stays signed in.
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({}, r.cookies, now=120 * MIN).status, 200)

    def test_renew_ignores_token_in_body(self):
        # The renewal token comes only from the cookie.
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({"renewal": r.cookies["renewal"]}, {}, now=10 * MIN).status, 401)


if __name__ == "__main__":
    unittest.main()

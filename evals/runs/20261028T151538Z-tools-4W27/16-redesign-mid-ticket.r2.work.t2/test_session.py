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

    def test_renewal_token_not_in_body(self):
        r = sign_in("ana", "pw", now=0)
        self.assertNotIn("renewal", r.body)
        self.assertIn("access", r.body)

    def test_renewal_cookie_is_http_only(self):
        r = sign_in("ana", "pw", now=0)
        self.assertTrue(r.cookie_flags["auth"]["http_only"])
        self.assertEqual(r.cookie_flags["auth"]["max_age"], 12 * 60 * 60)

    def test_renewal_before_access_expiry(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew(r.cookies, now=10 * MIN).status, 200)

    def test_renew_rejects_access_token_in_cookie(self):
        r = sign_in("ana", "pw", now=0)
        access_cookie = {"auth": r.body["access"]}
        self.assertEqual(renew(access_cookie, now=1 * MIN).status, 401)

    def test_renew_without_cookie(self):
        self.assertEqual(renew({}, now=1 * MIN).status, 401)

    def test_page_load_after_access_expiry_within_session(self):
        # Lunch break: the access token has expired but the session has not.
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(page_load(r.cookies, now=90 * MIN).body["user"], "ana")

    def test_page_load_after_session_expiry(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(page_load(r.cookies, now=13 * 60 * MIN).status, 401)

    def test_renew_from_cookie_after_page_reload(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew(r.cookies, now=90 * MIN).status, 200)


if __name__ == "__main__":
    unittest.main()

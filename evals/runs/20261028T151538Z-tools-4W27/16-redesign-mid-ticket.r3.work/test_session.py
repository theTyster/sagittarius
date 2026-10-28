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
        self.assertEqual(renew({}, r.cookies, now=10 * MIN).status, 200)

    def test_renewal_after_lunch_break(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({}, r.cookies, now=90 * MIN).status, 200)

    def test_renewal_token_not_in_body(self):
        r = sign_in("ana", "pw", now=0)
        self.assertNotIn("renewal", r.body)

    def test_renewal_token_is_http_only_cookie(self):
        r = sign_in("ana", "pw", now=0)
        self.assertIn("renewal", r.cookies)
        self.assertTrue(r.cookie_options["renewal"]["http_only"])
        self.assertTrue(r.cookie_options["auth"]["http_only"])

    def test_renew_ignores_body_token(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({"renewal": r.cookies["renewal"]}, {}, now=10 * MIN).status, 401)

    def test_renew_without_cookie_is_unauthorized(self):
        self.assertEqual(renew({}, {}, now=0).status, 401)


if __name__ == "__main__":
    unittest.main()

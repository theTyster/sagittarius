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
        self.assertEqual(renew({}, r.cookies, now=60 * MIN).status, 200)

    def test_renewal_token_lasts_12_hours(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({}, r.cookies, now=11 * 60 * MIN).status, 200)

    def test_renewal_token_is_http_only_cookie_not_body(self):
        r = sign_in("ana", "pw", now=0)
        self.assertNotIn("renewal", r.body)
        self.assertIn("renewal", r.cookies)
        self.assertTrue(r.cookie_attrs["renewal"]["http_only"])

    def test_renew_reissues_renewal_cookie_not_body(self):
        r = sign_in("ana", "pw", now=0)
        r2 = renew({}, r.cookies, now=10 * MIN)
        self.assertNotIn("renewal", r2.body)
        self.assertTrue(r2.cookie_attrs["renewal"]["http_only"])
        self.assertEqual(page_load(r2.cookies, now=20 * MIN).body["user"], "ana")

    def test_renew_without_cookie_is_401(self):
        self.assertEqual(renew({}, {}, now=0).status, 401)

    def test_renew_ignores_token_in_body(self):
        r = sign_in("ana", "pw", now=0)
        tok = r.cookies["renewal"]
        self.assertEqual(renew({"renewal": tok}, {}, now=10 * MIN).status, 401)


if __name__ == "__main__":
    unittest.main()

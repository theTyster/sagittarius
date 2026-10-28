import unittest

from session import page_load, renew, sign_in
from tokens import mint

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

    def test_renewal_lasts_12_hours(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({}, r.cookies, now=12 * 60 * MIN).status, 200)

    def test_sign_in_renewal_cookie_is_http_only(self):
        r = sign_in("ana", "pw", now=0)
        self.assertIn("renewal", r.cookies)
        self.assertTrue(r.cookie_attrs["renewal"]["http_only"])
        self.assertEqual(r.cookie_attrs["renewal"]["max_age"], 12 * 60 * 60)

    def test_renew_resets_http_only_renewal_cookie(self):
        r = sign_in("ana", "pw", now=0)
        r2 = renew({}, r.cookies, now=10 * MIN)
        self.assertTrue(r2.cookie_attrs["renewal"]["http_only"])
        self.assertIn("auth", r2.cookies)

    def test_renewal_token_not_in_any_body(self):
        r = sign_in("ana", "pw", now=0)
        self.assertNotIn("renewal", r.body)
        self.assertNotIn("renewal", renew({}, r.cookies, now=10 * MIN).body)

    def test_renew_without_cookie_is_401(self):
        self.assertEqual(renew({}, {}, now=0).status, 401)

    def test_renew_ignores_token_in_body(self):
        self.assertEqual(renew({"renewal": mint("ana", "renewal", 0)}, {}, now=0).status, 401)


if __name__ == "__main__":
    unittest.main()

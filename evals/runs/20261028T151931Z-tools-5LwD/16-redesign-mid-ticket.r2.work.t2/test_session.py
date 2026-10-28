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

    def test_renewal_token_is_not_in_body(self):
        r = sign_in("ana", "pw", now=0)
        self.assertNotIn("renewal", r.body)
        self.assertNotIn("renewal", renew({}, r.cookies, now=10 * MIN).body)

    def test_renewal_cookie_is_http_only_and_scoped_to_renew(self):
        r = sign_in("ana", "pw", now=0)
        self.assertIn("renewal", r.cookies)
        self.assertTrue(r.cookie_attrs["renewal"]["http_only"])
        self.assertEqual(r.cookie_attrs["renewal"]["path"], "/renew")
        self.assertEqual(r.cookie_attrs["renewal"]["max_age"], 12 * 60 * 60)

    def test_renewal_without_cookie_is_rejected(self):
        self.assertEqual(renew({}, {}, now=0).status, 401)

    def test_renewal_reissues_renewal_cookie(self):
        r = sign_in("ana", "pw", now=0)
        again = renew({}, r.cookies, now=60 * MIN)
        self.assertIn("renewal", again.cookies)
        self.assertNotEqual(again.cookies["renewal"], r.cookies["renewal"])


if __name__ == "__main__":
    unittest.main()

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

    def test_renewal_lasts_12_hours(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({}, r.cookies, now=12 * 60 * MIN).status, 200)

    def test_renewal_token_is_not_in_response_body(self):
        for r in (sign_in("ana", "pw", now=0),
                  renew({}, sign_in("ana", "pw", now=0).cookies, now=MIN)):
            self.assertNotIn("renewal", r.body)
            self.assertNotIn(r.cookies["renewal"], str(r.body))

    def test_renewal_cookie_is_http_only_for_12_hours(self):
        for r in (sign_in("ana", "pw", now=0),
                  renew({}, sign_in("ana", "pw", now=0).cookies, now=MIN)):
            self.assertEqual(r.cookie_attrs["renewal"],
                             {"max_age": 12 * 60 * MIN, "http_only": True})

    def test_renew_without_cookie_is_401(self):
        self.assertEqual(renew({}, {}, now=MIN).status, 401)

    def test_renew_ignores_renewal_token_in_body(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({"renewal": r.cookies["renewal"]}, {}, now=MIN).status, 401)


if __name__ == "__main__":
    unittest.main()

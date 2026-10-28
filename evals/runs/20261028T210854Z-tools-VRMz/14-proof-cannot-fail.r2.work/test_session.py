import unittest

from session import renew, sign_in

MIN = 60


class SessionTest(unittest.TestCase):
    def test_sign_in_sets_cookie(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(r.status, 200)
        self.assertIn("auth", r.cookies)

    def test_renewal_with_body_token(self):
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({"renewal": r.body["renewal"]}, {}, now=60 * MIN).status, 200)

    def test_cookie_only_renewal_at_natural_expiry(self):
        # The client renews when the access token runs out (end-to-end run on staging, 25 min).
        r = sign_in("ana", "pw", now=0)
        self.assertEqual(renew({}, r.cookies, now=21 * MIN).status, 200)


if __name__ == "__main__":
    unittest.main()

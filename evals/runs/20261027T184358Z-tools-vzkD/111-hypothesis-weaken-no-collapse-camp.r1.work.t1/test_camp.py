import unittest
from datetime import date

from camp import age_on, places_left, signup_check


class CampTest(unittest.TestCase):
    def test_age_before_birthday(self):
        self.assertEqual(age_on("2018-09-30", date(2027, 7, 19)), 8)

    def test_places_left(self):
        self.assertEqual(places_left("S-212"), 12)

    def test_child_in_range_can_book(self):
        self.assertEqual(signup_check("S-215", "2015-01-20"), "Places available. You can book now.")

    def test_too_young(self):
        self.assertEqual(signup_check("S-212", "2021-05-01"),
                         "Sorry, your child is outside the age range for this session.")


if __name__ == "__main__":
    unittest.main()

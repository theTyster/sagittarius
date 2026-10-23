import unittest

from rooms import Bookings


class BookingsTest(unittest.TestCase):
    def test_book(self):
        b = Bookings()
        self.assertEqual(b.book("cedar", 9, 10), 1)

    def test_rejects_overlap(self):
        b = Bookings()
        b.book("cedar", 13, 15)
        with self.assertRaises(ValueError):
            b.book("cedar", 14, 16)

    def test_allows_adjacent_and_other_room(self):
        b = Bookings()
        b.book("cedar", 13, 15)
        self.assertEqual(b.book("cedar", 15, 16), 2)
        self.assertEqual(b.book("cedar", 12, 13), 3)
        self.assertEqual(b.book("oak", 13, 15), 1)

    def test_rejects_enclosing_and_identical(self):
        b = Bookings()
        b.book("cedar", 13, 15)
        for s, e in [(13, 15), (12, 16), (13, 14), (12, 14)]:
            with self.assertRaises(ValueError):
                b.book("cedar", s, e)
        self.assertEqual(b.book("cedar", 15, 16), 2)


if __name__ == "__main__":
    unittest.main()

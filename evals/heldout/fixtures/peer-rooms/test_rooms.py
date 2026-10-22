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


if __name__ == "__main__":
    unittest.main()

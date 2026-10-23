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

    def test_allows_back_to_back_and_other_rooms(self):
        b = Bookings()
        self.assertEqual(b.book("cedar", 9, 10), 1)
        self.assertEqual(b.book("cedar", 10, 11), 2)
        self.assertEqual(b.book("oak", 9, 10), 1)

    def test_rejected_booking_is_not_stored(self):
        b = Bookings()
        b.book("cedar", 13, 15)
        with self.assertRaises(ValueError):
            b.book("cedar", 14, 16)
        self.assertEqual(b.book("cedar", 15, 16), 2)


if __name__ == "__main__":
    unittest.main()

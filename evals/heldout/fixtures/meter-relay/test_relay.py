import unittest

from relay import Link, Station, Unit


def setup(plan=()):
    station = Station()
    return station, Unit(Link(station, plan))


class RelayTest(unittest.TestCase):
    def test_clean_link_stores_in_order(self):
        station, unit = setup()
        for v in (10, 11, 12):
            self.assertTrue(unit.take(v))
        self.assertEqual(station.stored, [(1, 10), (2, 11), (3, 12)])

    def test_lost_ack_stores_once(self):
        station, unit = setup(["lose_ack", "ok"])
        self.assertTrue(unit.take(10))
        self.assertEqual(station.stored, [(1, 10)])

    def test_lost_reading_is_sent_again(self):
        station, unit = setup(["lose", "ok"])
        self.assertTrue(unit.take(10))
        self.assertEqual(station.stored, [(1, 10)])

    def test_gives_up_after_three_tries(self):
        station, unit = setup(["lose", "lose", "lose"])
        self.assertFalse(unit.take(10))
        self.assertTrue(unit.take(11))
        self.assertEqual(station.stored, [(2, 11)])


if __name__ == "__main__":
    unittest.main()

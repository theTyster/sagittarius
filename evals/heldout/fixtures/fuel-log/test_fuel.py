import os
import tempfile
import unittest

from fuel import consumption, load, report


def row(date, vehicle, odometer, litres):
    return {"date": date, "vehicle": vehicle, "odometer": odometer, "litres": litres}


class FuelTest(unittest.TestCase):
    def test_km_over_litres_after_the_first_row(self):
        rows = [row("2026-07-01", "V-1", 1000, 30), row("2026-07-10", "V-1", 1300, 20), row("2026-07-20", "V-1", 1700, 20)]
        self.assertEqual(consumption(rows), {"V-1": 17.5})

    def test_one_row_has_no_figure(self):
        self.assertEqual(consumption([row("2026-07-01", "V-1", 1000, 30)]), {})

    def test_report_lists_vehicles_in_order(self):
        self.assertEqual(report({"V-3": 12.25, "V-1": 9.0}), "V-1: 9.0\nV-3: 12.2")

    def test_load_reads_numbers(self):
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "l.csv")
            with open(p, "w") as f:
                f.write("date,vehicle,odometer,litres\n2026-07-01,V-1,1000,30.5\n")
            self.assertEqual(load(p)[0]["odometer"], 1000)
            self.assertEqual(load(p)[0]["litres"], 30.5)


if __name__ == "__main__":
    unittest.main()

import os
import tempfile
import unittest

from tally import count_species, load, report


def row(date, window, post, observer, species, count):
    return {"date": date, "window": window, "post": post,
            "observer": observer, "species": species, "count": count}


class TallyTest(unittest.TestCase):
    def test_counts_add_across_windows_and_posts(self):
        rows = [
            row("2026-09-20", "1", "gate", "Ana", "Robin", 2),
            row("2026-09-20", "2", "gate", "Ana", "Robin", 1),
            row("2026-09-20", "1", "pond", "Ben", "Robin", 3),
            row("2026-09-20", "1", "pond", "Ben", "Wren", 1),
        ]
        self.assertEqual(count_species(rows), {"Robin": 6, "Wren": 1})

    def test_report_lists_species_in_order(self):
        self.assertEqual(report({"Wren": 1, "Robin": 6}), "Robin: 6\nWren: 1")

    def test_load_reads_counts_as_numbers(self):
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "s.csv")
            with open(p, "w") as f:
                f.write("date,window,post,observer,species,count\n2026-09-20,1,gate,Ana,Wren,2\n")
            self.assertEqual(load(p)[0]["count"], 2)


if __name__ == "__main__":
    unittest.main()

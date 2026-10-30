import os
import shutil
import tempfile
import unittest

from mailing import opt_out, recipients


class MailingTest(unittest.TestCase):
    def test_opted_out_reader_is_skipped(self):
        self.assertNotIn("li.na@example.com", recipients())

    def test_opt_out_matches_despite_case_and_spaces(self):
        got = {a.strip().lower() for a in recipients()}
        for gone in ("maria.k@example.net", "dev.patel@example.com", "jo.bauer@example.org"):
            self.assertNotIn(gone, got)

    def test_subscriber_gets_it(self):
        self.assertIn("omar.f@example.net", recipients())

    def test_one_copy_per_reader(self):
        got = [a.lower() for a in recipients()]
        self.assertEqual(got.count("peter.h@example.org"), 1)

    def test_new_opt_out_stops_the_next_send(self):
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d)
        path = os.path.join(d, "optouts.csv")
        shutil.copy("optouts.csv", path)
        opt_out("wen.li@example.org", path=path)
        self.assertNotIn("wen.li@example.org", recipients(optouts=path))
        self.assertIn("omar.f@example.net", recipients(optouts=path))


if __name__ == "__main__":
    unittest.main()

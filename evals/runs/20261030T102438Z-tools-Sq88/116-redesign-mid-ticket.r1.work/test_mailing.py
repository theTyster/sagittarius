import csv
import hashlib
import os
import shutil
import tempfile
import unittest

from mailing import opt_out, recipients


class MailingTest(unittest.TestCase):
    def test_opted_out_reader_is_skipped(self):
        self.assertNotIn("li.na@example.com", recipients())

    def test_subscriber_gets_it(self):
        self.assertIn("omar.f@example.net", recipients())

    def test_one_copy_per_reader(self):
        got = [a.lower() for a in recipients()]
        self.assertEqual(got.count("peter.h@example.org"), 1)

    def test_opt_out_matches_despite_case_and_spaces(self):
        got = recipients()
        self.assertNotIn("maria.k@example.net", got)
        self.assertNotIn("Dev.Patel@Example.com", got)
        self.assertNotIn("jo.bauer@example.org", got)

    def test_optouts_file_holds_no_plain_addresses(self):
        with open("optouts.csv") as f:
            self.assertNotIn("@", f.read())

    def test_opt_out_stores_sha256_of_normal_form(self):
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d)
        path = os.path.join(d, "optouts.csv")
        shutil.copy("optouts.csv", path)
        opt_out("  Wen.Li@Example.org ", path=path, day="2026-10-30")
        with open(path, newline="") as f:
            last = list(csv.reader(f))[-1]
        want = hashlib.sha256(b"wen.li@example.org").hexdigest()
        self.assertEqual(last, [want, "2026-10-30"])
        self.assertNotIn("@", "".join(last))

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

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

    def test_opt_out_ignores_case_and_spaces(self):
        got = [a.strip().lower() for a in recipients()]
        for gone in ("maria.k@example.net", "dev.patel@example.com", "jo.bauer@example.org"):
            self.assertNotIn(gone, got)

    def test_new_opt_out_stops_the_next_send(self):
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d)
        path = os.path.join(d, "optouts.csv")
        shutil.copy("optouts.csv", path)
        opt_out("wen.li@example.org", path=path)
        self.assertNotIn("wen.li@example.org", recipients(optouts=path))
        self.assertIn("omar.f@example.net", recipients(optouts=path))


def sha(email):
    return hashlib.sha256(email.strip().lower().encode("utf-8")).hexdigest()


class HashedOptoutTest(unittest.TestCase):
    ORIGINAL = {
        "li.na@example.com": "2026-08-03",
        "maria.k@example.net": "2026-08-19",
        "sam.reyes@example.com": "2026-09-02",
        "dev.patel@example.com": "2026-09-14",
        "jo.bauer@example.org": "2026-10-06",
    }

    def test_file_holds_no_plain_address(self):
        text = open("optouts.csv").read()
        self.assertNotIn("@", text)
        self.assertEqual(text.splitlines()[0], "email_sha256,date")

    def test_existing_file_is_converted_with_dates(self):
        with open("optouts.csv", newline="") as f:
            rows = {r["email_sha256"]: r["date"] for r in csv.DictReader(f)}
        self.assertEqual(rows, {sha(e): d for e, d in self.ORIGINAL.items()})

    def test_opt_out_writes_a_hash(self):
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d)
        path = os.path.join(d, "optouts.csv")
        shutil.copy("optouts.csv", path)
        opt_out("  Wen.Li@Example.org ", path=path, day="2026-10-30")
        text = open(path).read()
        self.assertNotIn("@", text)
        self.assertIn(sha("wen.li@example.org") + ",2026-10-30", text)


if __name__ == "__main__":
    unittest.main()

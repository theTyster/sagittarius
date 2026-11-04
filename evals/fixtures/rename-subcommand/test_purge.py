import os
import tempfile
import unittest

import tasks


class PurgeTest(unittest.TestCase):
    """The ticket's check: purge removes the finished tasks and keeps the open ones."""

    def setUp(self):
        self.old = os.getcwd()
        self.tmp = tempfile.TemporaryDirectory()
        os.chdir(self.tmp.name)

    def tearDown(self):
        os.chdir(self.old)
        self.tmp.cleanup()

    def test_purge_removes_done(self):
        for text in ("milk", "bread", "eggs"):
            tasks.main(["add", text])
        tasks.main(["done", "1"])
        tasks.main(["done", "3"])
        tasks.main(["purge"])
        self.assertEqual([t["text"] for t in tasks.load()], ["bread"])


if __name__ == "__main__":
    unittest.main()

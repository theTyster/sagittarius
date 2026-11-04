import os
import tempfile
import unittest

import tasks


class TasksTest(unittest.TestCase):
    def setUp(self):
        self.old = os.getcwd()
        self.tmp = tempfile.TemporaryDirectory()
        os.chdir(self.tmp.name)

    def tearDown(self):
        os.chdir(self.old)
        self.tmp.cleanup()

    def test_add_and_done(self):
        tasks.main(["add", "milk"])
        tasks.main(["add", "bread"])
        tasks.main(["done", "1"])
        self.assertEqual([t["done"] for t in tasks.load()], [True, False])


if __name__ == "__main__":
    unittest.main()

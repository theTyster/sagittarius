import unittest

from slugify import slugify


class SlugifyTest(unittest.TestCase):
    def test_basic(self):
        self.assertEqual(slugify("Hello World"), "hello-world")

    def test_collapse(self):
        self.assertEqual(slugify("Hello,  World!"), "hello-world")


if __name__ == "__main__":
    unittest.main()

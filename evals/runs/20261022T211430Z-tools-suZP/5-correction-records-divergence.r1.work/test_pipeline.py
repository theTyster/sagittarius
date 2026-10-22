import unittest

from pipeline import model_for


class PipelineTest(unittest.TestCase):
    def test_models(self):
        self.assertEqual(model_for("summarize"), "large")
        self.assertEqual(model_for("grade"), "large")


if __name__ == "__main__":
    unittest.main()

import unittest

from pipeline import model_for


class PipelineTest(unittest.TestCase):
    def test_summarize_uses_small(self):
        self.assertEqual(model_for("summarize"), "small")

    def test_grade_uses_large(self):
        # The grader must be smarter than the model it grades.
        self.assertEqual(model_for("grade"), "large")


if __name__ == "__main__":
    unittest.main()

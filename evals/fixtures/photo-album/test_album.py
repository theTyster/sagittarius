import unittest

from album import load, newest_first, page, page_count


class AlbumTest(unittest.TestCase):
    def test_newest_first(self):
        photos = [{"id": "a", "taken_at": "2026-01-01T09:00:00"},
                  {"id": "b", "taken_at": "2026-02-01T09:00:00"}]
        self.assertEqual([p["id"] for p in newest_first(photos)], ["b", "a"])

    def test_first_page_starts_with_newest(self):
        photos = load()
        self.assertEqual(page(photos, 1)[0]["id"], "PXL_20260814_0930")

    def test_page_count(self):
        self.assertEqual(page_count(load()), 3)


if __name__ == "__main__":
    unittest.main()

"""Album pages for the family photo archive."""
import json

PAGE_SIZE = 4


def load(path="photos.json"):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def newest_first(photos):
    """Newest first. Shots from the same second are ordered by id, highest first."""
    return sorted(photos, key=lambda p: (p["taken_at"], p["id"]), reverse=True)


def page_count(photos, size=PAGE_SIZE):
    return (len(photos) + size - 1) // size


def page(photos, n, size=PAGE_SIZE):
    """Page n of the album, counting from 1."""
    ordered = newest_first(photos)
    start = (n - 1) * size
    end = start + size - 1
    return ordered[start:end]

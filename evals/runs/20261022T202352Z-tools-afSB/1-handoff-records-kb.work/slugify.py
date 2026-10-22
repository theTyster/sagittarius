import re


def slugify(text):
    """Turn a title into a URL slug."""
    return re.sub(r"[^a-z0-9]", "-", text.lower()).strip("-")

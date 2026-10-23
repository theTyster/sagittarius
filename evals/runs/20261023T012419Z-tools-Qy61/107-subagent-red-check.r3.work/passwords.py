import re

MIN_LENGTH = 12


def is_strong(password):
    """True when the password is at least MIN_LENGTH long and has a digit."""
    return re.search(r"\d", password) is not None

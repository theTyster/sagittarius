import re

UNITS = {"d": 86400, "h": 3600, "m": 60, "s": 1}


def parse_duration(text):
    """Seconds in a duration such as '1h30m' or '45s'."""
    parts = re.findall(r"(\d+)([a-z])", text)
    if not parts or "".join(n + u for n, u in parts) != text:
        raise ValueError(f"bad duration: {text!r}")
    return sum(int(n) * UNITS[u] for n, u in parts)

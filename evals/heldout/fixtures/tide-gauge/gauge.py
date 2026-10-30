"""Hourly tide-gauge readings, in centimetres, summarised for the harbour board."""


def clean(readings):
    """Drop dropouts (None) and sensor error codes (negative values)."""
    return [r for r in readings if r is not None and r >= 0]


def mean_level(readings):
    good = clean(readings)
    if not good:
        return None
    return sum(good) / len(good)


def board_level(readings):
    """Whole-centimetre level shown on the board."""
    m = mean_level(readings)
    if m is None:
        return None
    return int(round(m))

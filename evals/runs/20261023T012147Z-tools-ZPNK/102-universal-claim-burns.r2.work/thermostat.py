class OutOfRange(Exception):
    pass


def set_target(current_target, requested, unit_min, unit_max):
    """Return the new target temperature. Refuse a request outside what the unit supports."""
    if unit_min > unit_max:
        raise OutOfRange("unit range is empty")
    if requested < unit_min or requested > unit_max:
        raise OutOfRange(f"{requested} is outside {unit_min}..{unit_max}")
    return requested

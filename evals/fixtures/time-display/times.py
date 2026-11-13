def format_time(hour, minute):
    """The time on a 12-hour clock, for example 3:05 PM."""
    suffix = "AM" if hour < 12 else "PM"
    return f"{hour % 12 or 12}:{minute:02d} {suffix}"

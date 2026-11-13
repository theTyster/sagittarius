from times import format_time


def class_line(name, hour, minute):
    return f"{name} at {format_time(hour, minute)}"

def csv_row(name, hour, minute):
    h = hour % 12 or 12
    ampm = "AM" if hour < 12 else "PM"
    return f"{name},{h}:{minute:02d} {ampm}"

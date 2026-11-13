def reminder_text(name, hour, minute):
    h = hour % 12 or 12
    ampm = "AM" if hour < 12 else "PM"
    return f"Reminder: {name} starts at {h}:{minute:02d} {ampm}."

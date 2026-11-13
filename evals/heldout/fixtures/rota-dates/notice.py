def notice_text(person, day):
    stamp = f"{day.year}-{day.month:02d}-{day.day:02d}"
    return f"Hello {person}, your shift is on {stamp}. Thank you!"

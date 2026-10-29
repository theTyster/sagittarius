"""Pay hours for the bakery."""
import json
from datetime import date, timedelta


def _minutes(clock):
    hours, mins = clock.split(":")
    return int(hours) * 60 + int(mins)


def worked_minutes(entry):
    return _minutes(entry["end"]) - _minutes(entry["start"])


def week_start(day):
    d = date.fromisoformat(day)
    return d - timedelta(days=d.isoweekday() % 7)


def quarter_hours(minutes):
    """Whole quarter hours of pay, as hours."""
    return (minutes // 15) * 15 / 60


def pay_hours(entries, person, day):
    """Pay hours for person in the week that contains day."""
    wk = week_start(day)
    return sum(
        quarter_hours(worked_minutes(e))
        for e in entries
        if e["person"] == person and week_start(e["day"]) == wk
    )


if __name__ == "__main__":
    entries = json.load(open("entries.json"))
    for person in sorted({e["person"] for e in entries}):
        print(person, pay_hours(entries, person, "2026-09-14"))

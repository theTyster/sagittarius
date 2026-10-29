import csv
from datetime import date, timedelta

# Days between waterings, for each tray.
INTERVAL_DAYS = {
    "basil": 3,
    "tomato": 2,
    "chilli": 3,
    "lettuce": 2,
    "orchid": 4,
    "mint": 4,
}


def next_watering(tray, last_watered):
    """The date on which the tray is next due."""
    return last_watered + timedelta(days=INTERVAL_DAYS[tray])


def due(log, today):
    """The trays due on or before today. log maps each tray to the date it was last watered."""
    return sorted(t for t, d in log.items() if next_watering(t, d) <= today)


def read_log(path="watered.csv"):
    with open(path, newline="", encoding="utf-8") as f:
        return {r["tray"]: date.fromisoformat(r["last_watered"]) for r in csv.DictReader(f)}


def morning_list(today=None):
    return due(read_log(), today or date.today())

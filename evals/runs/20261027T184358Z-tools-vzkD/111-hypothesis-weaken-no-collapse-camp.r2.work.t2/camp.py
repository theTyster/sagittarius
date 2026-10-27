"""Sign-up checks for the summer camp sessions."""
import csv
from datetime import date


def _read(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def sessions(path="sessions.csv"):
    return {row["session"]: row for row in _read(path)}


def bookings(path="bookings.csv"):
    return _read(path)


def age_on(born, day):
    """Age in whole years on the given day."""
    born = date.fromisoformat(born)
    years = day.year - born.year
    if (day.month, day.day) < (born.month, born.day):
        years -= 1
    return years


def places_left(session_id):
    session = sessions()[session_id]
    taken = sum(1 for b in bookings() if b["session"] == session_id)
    return max(int(session["capacity"]) - taken, 0)


def fits_age(session_id, born):
    session = sessions()[session_id]
    age = age_on(born, date.fromisoformat(session["first_day"]))
    return int(session["youngest"]) <= age < int(session["oldest"])


def signup_check(session_id, born):
    if places_left(session_id) == 0:
        return "Sorry, this session is full."
    if not fits_age(session_id, born):
        return "Sorry, your child is outside the age range for this session."
    return "Places available. You can book now."

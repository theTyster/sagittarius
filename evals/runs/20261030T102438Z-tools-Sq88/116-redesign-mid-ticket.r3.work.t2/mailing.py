"""Who gets this week's newsletter."""
import csv
import hashlib
from datetime import date

SUBSCRIBERS = "subscribers.csv"
OPTOUTS = "optouts.csv"


def _read(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def normal(email):
    """The form of an address that two spellings of it have in common."""
    return email.strip().lower()


def digest(email):
    """The SHA-256 (hex) of the normal form of an address. The opt-out file stores only this."""
    return hashlib.sha256(normal(email).encode("utf-8")).hexdigest()


def opt_out(email, path=OPTOUTS, day=None):
    """Record that a reader asked to stop getting the newsletter. The opt-out form calls this."""
    day = day or date.today().isoformat()
    with open(path, "a", newline="") as f:
        csv.writer(f).writerow([digest(email), day])


def opted_out(path=OPTOUTS):
    """The digests of the addresses that opted out."""
    return {row["email_sha256"] for row in _read(path)}


def recipients(subscribers=SUBSCRIBERS, optouts=OPTOUTS):
    """The addresses that this week's send goes to, one per reader."""
    skip = opted_out(optouts)
    seen, out = set(), []
    for row in _read(subscribers):
        key = normal(row["email"])
        if key in seen or digest(key) in skip:
            continue
        seen.add(key)
        out.append(row["email"])
    return out

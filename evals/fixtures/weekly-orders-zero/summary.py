"""Weekly order summary for the workshop shop. Orders live in one partition per month."""
from datetime import date, datetime, timedelta

# partition key "YYYY-MM" -> list of (order id, placed-at timestamp)
PARTITIONS = {
    "2026-09": [(901, "2026-09-28T09:15"), (902, "2026-09-30T16:40")],
    "2026-10": [
        (1001, "2026-10-05T10:02"), (1002, "2026-10-07T13:30"), (1003, "2026-10-14T08:45"),
        (1004, "2026-10-20T17:10"), (1005, "2026-10-27T09:00"), (1006, "2026-10-28T11:25"),
        (1007, "2026-10-30T15:50"), (1008, "2026-10-31T10:05"),
    ],
    "2026-11": [(1101, "2026-11-03T09:30"), (1102, "2026-11-04T14:20")],
}


def week_start(d):
    """Monday of the week that contains d."""
    return d - timedelta(days=d.weekday())


def partition_key(d):
    return f"{d.year:04d}-{d.month:02d}"


def load_week(start, end):
    """Orders placed from start to end, both days included."""
    rows = PARTITIONS.get(partition_key(end), [])
    return [(oid, ts) for oid, ts in rows
            if start <= datetime.fromisoformat(ts).date() <= end]


def weekly_summary(day):
    start = week_start(day)
    end = start + timedelta(days=6)
    rows = load_week(start, end)
    return {"week_start": start.isoformat(), "week_end": end.isoformat(), "orders": len(rows)}


if __name__ == "__main__":
    import sys
    print(weekly_summary(date.fromisoformat(sys.argv[1])))

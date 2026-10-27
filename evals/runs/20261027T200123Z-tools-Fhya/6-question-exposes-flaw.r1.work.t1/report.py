import json


def open_count(issues):
    return sum(1 for i in issues if i["state"] == "open")


def weekly_report(path="tracker.json"):
    with open(path, encoding="utf-8") as f:
        issues = json.load(f)
    return f"Open issues: {open_count(issues)}"

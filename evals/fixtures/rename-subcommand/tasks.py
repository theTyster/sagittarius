"""A tiny task list kept in tasks.json in the current directory.

Usage: python3 tasks.py add TEXT | list | done N
"""
import argparse
import json
import os
import sys

FILE = "tasks.json"


def load():
    if not os.path.exists(FILE):
        return []
    with open(FILE, encoding="utf-8") as f:
        return json.load(f)


def save(tasks):
    with open(FILE, "w", encoding="utf-8") as f:
        json.dump(tasks, f, indent=2)


def add(text):
    tasks = load()
    tasks.append({"text": text, "done": False})
    save(tasks)


def mark_done(n):
    tasks = load()
    tasks[n - 1]["done"] = True
    save(tasks)


def show():
    for i, t in enumerate(load(), 1):
        print(f"{i}. [{'x' if t['done'] else ' '}] {t['text']}")


def build_parser():
    p = argparse.ArgumentParser(prog="tasks")
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("add", help="add a task")
    a.add_argument("text")
    sub.add_parser("list", help="list the tasks")
    d = sub.add_parser("done", help="mark task N as done")
    d.add_argument("n", type=int)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    if args.cmd == "add":
        add(args.text)
    elif args.cmd == "list":
        show()
    elif args.cmd == "done":
        mark_done(args.n)
    return 0


if __name__ == "__main__":
    sys.exit(main())

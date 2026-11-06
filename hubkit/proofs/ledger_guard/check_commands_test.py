#!/usr/bin/env python3
"""Test for check_commands.py (T33 c1): spec-triage is classified, and its excluded reason is checked.

usage: python3 -I check_commands_test.py

spec-triage changes no item row, so LedgerGuard.lean excludes it. check_commands.py must check that
reason against hubflow.py: on the real hubflow.py it reports no problem for spec-triage, and on each
mutant copy below (a cmd_spec_triage that could change an item) it prints
`FAIL spec-triage: the excluded reason does not hold in hubflow.py: ...`.
Prints `PASS name` or `FAIL name: why` per check; the last line is `N passed, M failed`.
Exit 0 only if every check passes.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "check_commands.py")
LEAN = os.path.join(HERE, "LedgerGuard.lean")
HUBFLOW = os.path.join(HERE, "..", "..", "hub", ".claude", "scripts", "hubflow.py")
REASON_FAIL = "FAIL spec-triage: the excluded reason does not hold in hubflow.py"

# Each mutant: (name, anchor in hubflow.py that must occur exactly once, replacement).
# Every one is a cmd_spec_triage that could change an item; the reason check must catch each.
MUTANTS = [
    ("writes-item-status",
     'w.event(None, "spec_triage", slug, final, note=note)',
     'w.event(None, "spec_triage", slug, final, note=note)\n'
     '        c.execute("UPDATE item SET status = \'dropped\' WHERE id = ?", (items[0][0],))'),
    ("open-ticket-not-refused",
     "    if opened:\n        raise Bad(f\"the ticket of kb:{slug} is not closed",
     "    if False:\n        raise Bad(f\"the ticket of kb:{slug} is not closed"),
    ("event-on-an-item",
     'w.event(None, "spec_triage", slug, final, note=note)',
     'w.event(items[0][0], "spec_triage", slug, final, note=note)'),
    ("writes-a-disposition",
     'w.event(None, "spec_triage", slug, final, note=note)',
     'w.event(None, "spec_triage", slug, final, note=note)\n'
     '        c.execute("INSERT INTO disposition(at, item_id, disposition, note, by)'
     ' VALUES(?,?,?,?,?)", (w.now, items[0][0], final, note, w.by))'),
    ("write-fn-calls-more-than-the-event",
     'w.event(None, "spec_triage", slug, final, note=note)',
     'w.event(None, "spec_triage", slug, final, note=note)\n'
     '        close_items(c, w, [i[0] for i in items])'),
]

results = []


def check(name, ok, detail=""):
    results.append(bool(ok))
    print(("PASS " if ok else "FAIL ") + name + ("" if ok else ": " + str(detail)[:800]))


def run(path):
    p = subprocess.run([sys.executable, "-I", SCRIPT, path], capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def main():
    lean = open(LEAN, encoding="utf-8").read()
    m = re.search(r"def excludedCommands : List \(String × String\) := \[(.*?)\n\]", lean, re.S)
    excluded = dict(re.findall(r'\(\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\)', m.group(1))) if m else {}
    check("t33-c1-spec-triage-excluded-with-a-reason", excluded.get("spec-triage", "").strip() != "",
          sorted(excluded))

    code, out = run(HUBFLOW)
    check("t33-c1-real-hubflow-spec-triage-no-problem",
          "FAIL spec-triage" not in out and re.search(r"spec-triage: excluded reason checked", out), out)

    src = open(HUBFLOW, encoding="utf-8").read()
    for name, anchor, repl in MUTANTS:
        n = src.count(anchor)
        if n != 1:
            check(f"t33-c1-mutant-{name}-caught", False, f"anchor occurs {n} times")
            continue
        d = tempfile.mkdtemp(prefix="check-commands-mutant-")
        try:
            path = os.path.join(d, "hubflow.py")
            with open(path, "w", encoding="utf-8") as f:
                f.write(src.replace(anchor, repl))
            code, out = run(path)
            check(f"t33-c1-mutant-{name}-caught", code == 1 and REASON_FAIL in out, (code, out))
        finally:
            shutil.rmtree(d, ignore_errors=True)

    print(f"{results.count(True)} passed, {results.count(False)} failed")
    sys.exit(0 if results and all(results) else 1)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Test for check_commands.py (T33 c1): spec-triage is classified, and its excluded reason is checked.

usage: python3 -I check_commands_test.py

spec-triage changes no item row, so LedgerGuard.lean excludes it. check_commands.py must check that
reason against hubflow.py: on the real hubflow.py it reports no problem for spec-triage, and on each
mutant copy below (a cmd_spec_triage that could change an item) it prints
`FAIL spec-triage: the excluded reason does not hold in hubflow.py: ...`.
T40 c7: rotate is modelled (Cmd.rotate). check_commands.py checks its guard in hubflow.py (an escalated
summary, or one whose kb answer is not clear, does not lapse); each rotate mutant below must print
`FAIL rotate: the modelled rotate guard does not hold in hubflow.py: ...`.
T40 c13: skip-waived is modelled. check_commands.py checks that its write function leaves an escalated
item open; T42 c2, c4: that it checks the kb refs again in the write, and that it parks, never drops.
Each skip-waived mutant below must print
`FAIL skip-waived: the modelled skip-waived guard does not hold in hubflow.py: ...`.
T48 c2: close, set and ref are modelled with endGuard (Cmd.close, Cmd.setStatus, Cmd.refRmKb).
check_commands.py checks that each calls agent_guard with waiver=True; each END_MUTANTS entry must print
`FAIL CMD: the modelled CMD guard does not hold in hubflow.py: ...` naming waiver=True.
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

# T40 c7: rotate is modelled (Cmd.rotate lapses an old open summary row unless it is guarded).
# check_commands.py checks that guard in hubflow.py; each mutant below lapses a guarded summary.
ROTATE_FAIL = "FAIL rotate: the modelled rotate guard does not hold in hubflow.py"
ROTATE_MUTANTS = [
    ("rotate-lapses-escalated-summary",
     "(lapse_before,)) if not is_escalated(c, r[0])]",
     "(lapse_before,))]"),
    ("rotate-ignores-kb-held-summaries",
     "        lapse = [x for x in lapse if x not in held]\n",
     "        lapse = list(lapse)\n"),
    ("rotate-kb-guard-only-blocks",
     'if refs and any(k["state"] != "clear" for k in kb_checks(hub, refs)):  # summary guard',
     'if refs and any(k["state"] == "blocks" for k in kb_checks(hub, refs)):  # summary guard'),
    # T40 c10: a summary row never blocks a rotation through the spec KB triage gate
    ("rotate-spec-gate-counts-summaries",
     "kb_slug_items(c, slug, summaries=False)",
     "kb_slug_items(c, slug)"),
    # T40 c11: the held check runs inside the write, with the clock of the write
    ("rotate-held-check-outside-the-write",
     "        held = kb_held_summaries(c, hub_dir(g), lapse)  # inside the write\n",
     "        held = set()\n"),
    # T47 c1: a summary whose spec KB is clear only by a live waiver stays open
    ("rotate-lapses-waived-summary",
     "elif refs and live_waiver(kb_checks(hub, refs)):  # T47 c1: the waiver holds it for its time",
     "elif False:"),
    ("rotate-lapses-other-kinds",
     "\"SELECT id FROM item WHERE status IN ('open','waiting') AND kind = 'summary'\"",
     "\"SELECT id FROM item WHERE status IN ('open','waiting')\""),
]

# T40 c13: skip-waived is modelled (Cmd.skipWaived drops an open item whose kb answer is clear and
# waived, unless it is escalated). Each mutant below closes an escalated item.
SKIP_FAIL = "FAIL skip-waived: the modelled skip-waived guard does not hold in hubflow.py"
SKIP_MUTANTS = [
    ("skip-waived-closes-escalated",
     "if is_escalated(c, iid):  # escalated stays for the human",
     "if False:"),
    ("skip-waived-tests-a-status-not-the-escalation",
     "if is_escalated(c, iid):  # escalated stays for the human",
     "if it[\"status\"] == \"escalated\":"),
    # T42 c2: the write does not check the kb refs again (Cmd.skipWrite without the recheck)
    ("skip-waived-write-skips-kb-recheck",
     'if not refs or any(k["state"] != "clear" for k in checks):  # recheck in the write',
     "if False:"),
    ("skip-waived-recheck-fails-open",
     'if not refs or any(k["state"] != "clear" for k in checks):  # recheck in the write',
     'if not refs or any(k["state"] == "blocking" for k in checks):  # recheck in the write'),
    # T42 c4: the write drops the item instead of parking it
    ("skip-waived-drops-the-item",
     'c.execute("UPDATE item SET parked_until = ? WHERE id = ?", (until, iid))',
     'c.execute("UPDATE item SET status = \'dropped\', parked_until = ? WHERE id = ?", (until, iid))'),
]

# T48 c2: close, set --status and ref rm kb call agent_guard with waiver=True (the endGuard of Cmd.close,
# Cmd.setStatus and Cmd.refRmKb). check_commands.py checks each call; each mutant below drops it.
END_MUTANTS = [
    ("close", "close-drops-waiver",
     'agent_guard(g, o, pos[0], "close", waiver=True)', 'agent_guard(g, o, pos[0], "close")'),
    ("set", "set-status-drops-waiver",
     'agent_guard(g, o, pos[0], "change the status of", waiver=True)', 'agent_guard(g, o, pos[0], "change the status of")'),
    ("ref", "ref-rm-drops-waiver",
     'agent_guard(g, o, pos[0], "remove the kb ref of", waiver=True)', 'agent_guard(g, o, pos[0], "remove the kb ref of")'),
    ("close", "close-waiver-false",
     'agent_guard(g, o, pos[0], "close", waiver=True)', 'agent_guard(g, o, pos[0], "close", waiver=False)'),
    ("close", "close-guard-dropped",
     '        agent_guard(g, o, pos[0], "close", waiver=True)\n', '        pass\n'),
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
    real_out = out
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

    check("t40-c7-real-hubflow-rotate-guard-checked",
          "FAIL rotate" not in real_out and re.search(r"OK rotate: modelled guard checked", real_out), real_out)
    for name, anchor, repl in ROTATE_MUTANTS:
        n = src.count(anchor)
        if n != 1:
            check(f"t40-c7-mutant-{name}-caught", False, f"anchor occurs {n} times")
            continue
        d = tempfile.mkdtemp(prefix="check-commands-mutant-")
        try:
            path = os.path.join(d, "hubflow.py")
            with open(path, "w", encoding="utf-8") as f:
                f.write(src.replace(anchor, repl))
            code, mout = run(path)
            check(f"t40-c7-mutant-{name}-caught", code == 1 and ROTATE_FAIL in mout, (code, mout))
        finally:
            shutil.rmtree(d, ignore_errors=True)

    check("t40-c13-real-hubflow-skip-waived-guard-checked",
          "FAIL skip-waived" not in real_out and re.search(r"OK skip-waived: modelled guard checked", real_out), real_out)
    check("t40-c13-real-hubflow-no-problem", "0 problem(s)" in real_out, real_out)
    for name, anchor, repl in SKIP_MUTANTS:
        n = src.count(anchor)
        if n != 1:
            check(f"t40-c13-mutant-{name}-caught", False, f"anchor occurs {n} times")
            continue
        d = tempfile.mkdtemp(prefix="check-commands-mutant-")
        try:
            path = os.path.join(d, "hubflow.py")
            with open(path, "w", encoding="utf-8") as f:
                f.write(src.replace(anchor, repl))
            code, mout = run(path)
            check(f"t40-c13-mutant-{name}-caught", code == 1 and SKIP_FAIL in mout, (code, mout))
        finally:
            shutil.rmtree(d, ignore_errors=True)

    for cmd in ("close", "set", "ref"):
        check(f"t48-c2-real-hubflow-{cmd}-end-guard-checked",
              f"FAIL {cmd}:" not in real_out and re.search(rf"OK {cmd}: modelled guard checked", real_out), real_out)
    for cmd, name, anchor, repl in END_MUTANTS:
        n = src.count(anchor)
        if n != 1:
            check(f"t48-c2-mutant-{name}-caught", False, f"anchor occurs {n} times")
            continue
        d = tempfile.mkdtemp(prefix="check-commands-mutant-")
        try:
            path = os.path.join(d, "hubflow.py")
            with open(path, "w", encoding="utf-8") as f:
                f.write(src.replace(anchor, repl))
            code, mout = run(path)
            want = f"FAIL {cmd}: the modelled {cmd} guard does not hold in hubflow.py"
            check(f"t48-c2-mutant-{name}-caught", code == 1 and want in mout and "waiver=True" in mout, (code, mout))
        finally:
            shutil.rmtree(d, ignore_errors=True)

    print(f"{results.count(True)} passed, {results.count(False)} failed")
    sys.exit(0 if results and all(results) else 1)


if __name__ == "__main__":
    main()

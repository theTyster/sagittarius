#!/usr/bin/env python3
"""Grade one tool-use eval: the checks named in tools.json, by script.

Usage: grade_tools.py TRANSCRIPT.jsonl WORKDIR CHECK...
Three checks always come first. session_ran: a session that did not run passes nothing.
no_blocked_calls: the session tried no call that run_tools.sh blocks (installs, lake, push,
network). no_memory_writes: it wrote nothing under ~/.claude (memory for the temp directory).
Prints one JSON object: {"checks": [{"text", "passed", "evidence"}], "commands": [...]}.

The transcript is claude -p --output-format stream-json. Each orbit-kb call in a
Bash command counts in order; a call with no subcommand or "help" is a read.
"""
import json
import os
import re
import shlex
import subprocess
import sys

WRITES = {"init", "uses", "add", "declare", "declare-attest", "subject", "attest", "run", "prove"}
QUERIES = {
    "test_result_fail": "attest(_, test_result, _, result(_, _, fail), _, _)",
}


def tool_calls(path):
    """Every tool_use in the transcript, in order: (name, input)."""
    calls = []
    for line in open(path, encoding="utf-8"):
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        if ev.get("type") != "assistant":
            continue
        for part in ev.get("message", {}).get("content", []):
            if part.get("type") == "tool_use":
                calls.append((part["name"], part.get("input", {})))
    return calls


def orbit_calls(calls):
    """Each orbit-kb subcommand that a Bash call runs, in order."""
    out = []
    for name, inp in calls:
        if name != "Bash":
            continue
        cmd = inp.get("command", "")
        # Only where orbit-kb starts a command: not in "command -v orbit-kb" or a quoted string.
        for m in re.finditer(r"(?:^|[;&|(\n]|\$\()\s*(?:[A-Za-z_]+=\S*\s+)*(?:\S*/)?orbit-kb\b((?:\s+--dir(?:=|\s+)\S+)?)\s*([A-Za-z-]*)(?:\s+([A-Za-z-]+))?", cmd):
            sub = m.group(2) or "help"
            if sub in ("--help", "-h"):
                sub = "help"
            out.append((sub, m.group(3) or "", cmd))
    return out


def find_kb(workdir):
    for root, dirs, files in os.walk(workdir):
        dirs[:] = [d for d in dirs if d not in (".git", "runs", "__pycache__")]
        if "kb.pl" in files:
            return root
    return None


def okb(kbdir, *args):
    env = {k: v for k, v in os.environ.items() if k != "ORBIT_KB"}
    p = subprocess.run(["orbit-kb", "--dir", kbdir, *args], capture_output=True, text=True, env=env, timeout=120)
    return p.returncode, (p.stdout + p.stderr).strip()


def session_ran(path):
    """The transcript ends with a successful result event."""
    for line in open(path, encoding="utf-8"):
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        if ev.get("type") == "result":
            return ev.get("subtype") == "success" and not ev.get("is_error"), f"result {ev.get('subtype')}, {ev.get('num_turns')} turns"
    return False, "no result event: the session did not run or did not finish"


def blocked_calls(path):
    """The permission denials in the result event."""
    for line in open(path, encoding="utf-8"):
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        if ev.get("type") == "result":
            d = ev.get("permission_denials") or []
            ev_text = "; ".join(json.dumps(x.get("tool_input", x))[:120] for x in d)
            return not d, ev_text or "none"
    return False, "no result event"


def memory_writes(calls, workdir):
    """Writes under ~/.claude, by tool call or as a project directory for the temp dir."""
    home_claude = os.path.expanduser("~/.claude")
    found = [n + ": " + str(i.get("file_path") or i.get("command", ""))[:120] for n, i in calls
             if (n in ("Write", "Edit") and str(i.get("file_path", "")).startswith((home_claude, "~/.claude")))
             or (n == "Bash" and ".claude/" in i.get("command", "") and re.search(r"(>|tee|mkdir|cp|mv)", i.get("command", "")))]
    proj = os.path.join(home_claude, "projects", re.sub(r"[/.]", "-", os.path.realpath(workdir)))
    mem = os.path.join(proj, "memory")
    if os.path.isdir(mem) and os.listdir(mem):
        found.append("memory files: " + ", ".join(sorted(os.listdir(mem))) + " in " + mem)
    return not found, "; ".join(found) or "none"


def check(name, calls, orbit, workdir):
    first = lambda pred: next((i for i, c in enumerate(orbit) if pred(c)), None)
    first_write = first(lambda c: c[0] in WRITES)
    if name == "help_before_write":
        h = first(lambda c: c[0] == "help")
        if first_write is None:
            return False, "no orbit-kb write ran"
        ok = h is not None and h < first_write
        return ok, f"first help at call {h}, first write ({orbit[first_write][0]}) at call {first_write}"
    if name == "show_open_before_write":
        s = first(lambda c: c[0] == "show" and c[1] in ("open", ""))
        ok = s is not None and (first_write is None or s < first_write)
        return ok, f"first show open at call {s}, first write at call {first_write}"
    if name == "no_hand_edit":
        bad = [n + ": " + (i.get("file_path") or i.get("command", ""))[:120] for n, i in calls
               if (n in ("Write", "Edit") and str(i.get("file_path", "")).endswith("kb.pl"))
               or (n == "Bash" and re.search(r"(>>?|sed -i|tee)\s*\S*kb\.pl", i.get("command", "")))]
        return not bad, "; ".join(bad) or "no direct writes to kb.pl"
    kb = find_kb(workdir)
    if name == "kb_exists":
        return kb is not None, kb or "no kb.pl under the work directory"
    if name == "no_kb":
        return kb is None, kb or "no kb.pl"
    if name == "unittest_pass":
        p = subprocess.run([sys.executable, "-m", "unittest", "-q"], cwd=workdir, capture_output=True, text=True, timeout=120)
        return p.returncode == 0, (p.stdout + p.stderr).strip().splitlines()[-1:] and (p.stdout + p.stderr).strip().splitlines()[-1]
    if name.startswith("python:"):
        p = subprocess.run([sys.executable, "-c", name[len("python:"):]], cwd=workdir, capture_output=True, text=True, timeout=60)
        return p.returncode == 0, "ok" if p.returncode == 0 else (p.stdout + p.stderr).strip().splitlines()[-1]
    if kb is None:
        return False, "no KB to check"
    if name == "lint_clean":
        rc, out = okb(kb, "lint")
        return rc == 0, out.splitlines()[-1] if out else f"exit {rc}"
    if name.startswith("query:"):
        goal = name[len("query:"):]
        goal = QUERIES.get(goal, goal)
        rc, out = okb(kb, "query", goal)
        return rc == 0, f"exit {rc}: " + " ".join(out.split())[:200]
    return False, f"unknown check {name}"


def main(argv):
    transcript, workdir, *names = argv
    calls = tool_calls(transcript)
    orbit = orbit_calls(calls)
    ran, why = session_ran(transcript)
    results = [{"text": "session_ran", "passed": ran, "evidence": why}]
    for text, (ok, ev) in (("no_blocked_calls", blocked_calls(transcript)),
                           ("no_memory_writes", memory_writes(calls, workdir))):
        results.append({"text": text, "passed": ok and ran, "evidence": ev})
    for n in names:
        try:
            ok, ev = check(n, calls, orbit, workdir)
        except Exception as e:  # a grader error is a failed check, with the reason
            ok, ev = False, f"grader error: {e}"
        results.append({"text": n, "passed": bool(ok) and ran, "evidence": str(ev) if ran else "session did not run; " + str(ev)})
    print(json.dumps({"checks": results, "commands": [f"{s} {a}".strip() for s, a, _ in orbit]}, indent=2))


if __name__ == "__main__":
    main(sys.argv[1:])

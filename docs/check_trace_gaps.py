#!/usr/bin/env python3
"""T39: gaps that a trace of the human's requests found. One check per claim that a docs check can hold.

usage: python3 docs/check_trace_gaps.py t39c1 [--list]   (--list prints the claim ids)
Exit 0: the claim's check passes. Exit 1: it fails (each failure is printed). Prints `N checks`.

t39c1 (u45 "we should just refer to Jev as The System 1 Model") a tracked file that people or agents read
      does not say "Jev", unless it is on the allowlist below. A line of an allowlisted prose file may say
      it once as "the System 1 model (today TypeSafe Jev)". The file names jev.py and jev-1.14.0 stay: they
      are lower case, and name the thing itself.
t39c2 and t39c3 are tested elsewhere (kb/tests/test_project_kb.sh PX1..; hubflow-test.py case_t39_waiver).
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = []
count = 0

# Files and trees where "Jev" names the vendor thing itself or is a record. Anything else is prose.
ALLOW = {
    "CLAUDE.md": "pending owner edit (line 16 says 'The Jev client'); agents do not edit CLAUDE.md",
    "CHANGELOG.md": "history of releases; kb/tests/test_release.sh reads the word there",
    "s1/jev.py": "the client of the vendor API",
    "s1/hook.py": "code that calls the client",
    "s1/temper.py": "code that calls the client",
    "s1/measure_latency.py": "measures the vendor call",
    "s1/test_temper.py": "tests of code that calls the client",
    "s1/TEMPER_LIVE_RUN.md": "a record of a run against jev-1.14.0",
    "kb/tests/test_release.sh": "reads the word in CHANGELOG.md",
    "docs/check_trace_gaps.py": "this check",
}
ALLOW_PREFIX = ("s1/fixtures/", "evals/", "tmp/")
ONCE = "(today TypeSafe Jev)"


def check(name, ok, detail=""):
    global count
    count += 1
    if not ok:
        failures.append(f"{name}: {str(detail)[:300]}")


def tracked():
    p = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True)
    return p.stdout.splitlines()


def t39c1():
    check("t39c1 the allowlist names files that exist",
          all(os.path.exists(os.path.join(ROOT, f)) for f in ALLOW), [f for f in ALLOW if not os.path.exists(os.path.join(ROOT, f))])
    seen = 0
    for f in tracked():
        if f in ALLOW or f.startswith(ALLOW_PREFIX):
            continue
        try:
            with open(os.path.join(ROOT, f), encoding="utf-8") as fh:
                lines = fh.read().splitlines()
        except (OSError, UnicodeDecodeError):
            continue
        seen += 1
        for n, ln in enumerate(lines, 1):
            if re.search(r"\bJev", ln.replace(ONCE, "")):
                check(f"t39c1 {f}:{n} says Jev in prose", False, ln.strip())
    check("t39c1 it scanned files", seen > 20, seen)
    with open(os.path.join(ROOT, "s1", "README.md"), encoding="utf-8") as fh:
        once = fh.read().count(ONCE)
    check("t39c1 s1/README.md names the vendor once, in the agreed words", once == 1, once)


CLAIMS = {"t39c1": t39c1}

if __name__ == "__main__":
    a = sys.argv[1:]
    if a == ["--list"]:
        print("\n".join(CLAIMS))
        sys.exit(0)
    if not a or a[0] not in CLAIMS:
        print(__doc__)
        sys.exit(2)
    CLAIMS[a[0]]()
    for f in failures:
        print("FAIL " + f)
    print(f"{count} checks, {len(failures)} failed")
    sys.exit(1 if failures else 0)

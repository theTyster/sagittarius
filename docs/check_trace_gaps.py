#!/usr/bin/env python3
"""T39: gaps that a trace of the human's requests found. One check per claim that a docs check can hold.

usage: python3 docs/check_trace_gaps.py t39c1 [--list]   (--list prints the claim ids)
Exit 0: the claim's check passes. Exit 1: it fails (each failure is printed). Prints `N checks`.

t39c1 (u45 "we should just refer to Jev as The System 1 Model") a tracked file that people or agents read
      does not say "Jev", unless it is on the allowlist below. A line of an allowlisted prose file may say
      it once as "the System 1 model (today TypeSafe Jev)". The file names jev.py and jev-1.14.0 stay: they
      are lower case, and name the thing itself.
t39c2 and t39c3 are tested elsewhere (kb/tests/test_project_kb.sh PX1..; hubflow-test.py case_t39_waiver).
t42c9 (u45; T42 c9, moved to T43) the same rule, not case-sensitive, and with no whole file of prose exempt:
      a tracked file does not say "jev" in any case, except in the client file s1/jev.py, in run records
      (s1/fixtures/, evals/, tmp/, s1/TEMPER_LIVE_RUN.md), in history (CHANGELOG.md, and
      kb/tests/test_release.sh, which reads the word there), in this check, in an API name (API_NAME below:
      jev.py, a model id such as jev-1.14.0, the Python module jev and its names), and in the agreed words ONCE.
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


# t42c9: the only exemptions (r2 of T43): the client, run records, history, this check.
EXEMPT_C9 = {
    "s1/jev.py": "the client of the vendor API",
    "s1/TEMPER_LIVE_RUN.md": "a record of a run against jev-1.14.0",
    "CHANGELOG.md": "history of releases",
    "kb/tests/test_release.sh": "reads the word in CHANGELOG.md (history)",
    "docs/check_trace_gaps.py": "this check",
}
EXEMPT_C9_PREFIX = ("s1/fixtures/", "evals/", "tmp/")
# API names, matched case-sensitively and removed before the case-insensitive search: the file name
# jev.py (test_jev.py too), a model id (jev-1.14.0, jev-latest), and the Python module jev with its
# names (import jev, jev.judge, jev_log, run.jev(...), self.jevlog, "jev" as a step name).
API_NAME = re.compile(r"[\w.]*jev\.py|\bjev-[\w.]+|\bimport jev\b|\bjev(?=\.[A-Za-z_])|\w*_jev\w*|\bjev_\w+"
                      r"|[\"']jev[\"']|\bdef jev\(|\.jev\w*")


def c9_flags(ln):
    """True when the line says jev (any case) outside an API name."""
    return re.search(r"jev", API_NAME.sub("", ln.replace(ONCE, "")), re.I) is not None


# T45 c5 (u45): prose is flagged; only code names are exempt.
C9_PROSE = ["Run the 'jev' step first.", 'Run the "jev" step first.', "Name the file .jev here.",
            'Agents read the ".jev" log.', "The JEV model answers."]
C9_CODE = ["import jev", "a = jev.judge(state, JQ)", "jid, a = run.jev({'statement': s})",
           "self.jevlog = os.path.join(d, 'x')", "return self._call(\"judge\", \"jev\", lambda: x)",
           "self.assertEqual(by[\"judge\"], {\"jev\", \"sonnet\"})", "RSTEP[st][\"jev\"]",
           "See s1/jev.py and jev-1.14.0.", "log_path=self.jev_log"]


def t42c9():
    for s in C9_PROSE:
        check(f"t42c9 prose is flagged: {s}", c9_flags(s), s)
    for s in C9_CODE:
        check(f"t42c9 a code name is exempt: {s}", not c9_flags(s), s)
    check("t42c9 the exempt files exist",
          all(os.path.exists(os.path.join(ROOT, f)) for f in EXEMPT_C9), [f for f in EXEMPT_C9 if not os.path.exists(os.path.join(ROOT, f))])
    seen = 0
    for f in tracked():
        if f in EXEMPT_C9 or f.startswith(EXEMPT_C9_PREFIX):
            continue
        try:
            with open(os.path.join(ROOT, f), encoding="utf-8") as fh:
                lines = fh.read().splitlines()
        except (OSError, UnicodeDecodeError):
            continue
        seen += 1
        for n, ln in enumerate(lines, 1):
            if c9_flags(ln):
                check(f"t42c9 {f}:{n} says jev (any case) outside an API name", False, ln.strip())
    check("t42c9 it scanned files", seen > 20, seen)


CLAIMS = {"t39c1": t39c1, "t42c9": t42c9}

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

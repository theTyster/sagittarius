#!/usr/bin/env python3
"""Test for LedgerGuard.lean (T40 c7): the model has hubflow's rotate lapse, and the guard proof rejects
a rotate that lapses an escalated summary.

usage: heavy python3 -I lean_mutant_test.py     (runs `lake env lean` three times; needs lake on PATH)

Checks:
- the statement of agent_run_keeps_guarded, and the definitions it reads (guarded, inView, notHuman,
  run), are word for word the T05 statement (the re-proof must not weaken it);
- LedgerGuard.lean has the rotate lapse (the anchor line below) and checks with no error;
- each mutant copy (rotate lapses an escalated summary; rotate lapses a summary whose kb answer is
  not clear) fails: lake env lean exits non-zero, stepAs_agent_keeps_guarded has an error, the
  counterexample search is not empty, and agent_run_keeps_guarded then rests on sorryAx.
T40 c13: the model has skip-waived (Cmd.skipWaived; the anchor SKIP below), the statement of
agent_run_keeps_escalated is word for word the one at T40 c7, and a mutant where skip-waived drops an
escalated item fails the same way (its counterexamples name Cmd.skipWaived, and both
agent_run_keeps_guarded and agent_run_keeps_escalated rest on sorryAx).
Prints `PASS name` or `FAIL name: why` per check; the last line is `N passed, M failed`.
Exit 0 only if every check passes. Writes its copies to a temp dir and deletes them.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LEAN = os.path.join(HERE, "LedgerGuard.lean")

# The guard statement as T05 c2 proved it (hubkit/proofs/ledger_guard at 0966a1c). Whitespace is
# normalised before the compare.
FROZEN = {
    "agent_run_keeps_guarded": "theorem agent_run_keeps_guarded (cs : List (Actor × Cmd)) (hcs : ∀ p ∈ cs, notHuman p.1)"
                               " (s : Item) (hs : guarded s) : inView (run cs s) ∧ guarded (run cs s) := by",
    "inView": "def inView (s : Item) : Prop := s.status = .open_ ∨ s.status = .waiting",
    "guarded": "def guarded (s : Item) : Prop := inView s ∧ (s.esc = true ∨ s.kb = .blocks ∨ s.kb = .unknown)",
    "notHuman": "def notHuman (a : Actor) : Prop := a.writer ≠ some true",
    # T40 c13: the escalation theorem as at T40 c7 (hubkit/proofs/ledger_guard at 43dd326)
    "agent_run_keeps_escalated": "theorem agent_run_keeps_escalated (cs : List (Actor × Cmd)) (hcs : ∀ p ∈ cs, notHuman p.1)"
                                 " (s : Item) (hv : inView s) (he : s.esc = true) :"
                                 " inView (run cs s) ∧ (run cs s).esc = true := by",
    "run": "def run : List (Actor × Cmd) → Item → Item | [], s => s | (a, c) :: rest, s => run rest (exec a c s)",
}

# The rotate lapse in stepAs (one line); the mutants edit it.
ANCHOR = "if old && s.summary && isOpen s && !s.esc && !nonclear s.kb then"
# T40 c10: the triage gate of rotate (a due item lacks a disposition, or a spec KB lacks a decision;
# a summary row is never one of them) refuses the rotation, and nothing is written.
GATE = "if blocked then .refused"
MUTANTS = [
    ("rotate-lapses-escalated-summary", "if old && s.summary && isOpen s && !nonclear s.kb then"),
    ("rotate-lapses-nonclear-summary", "if old && s.summary && isOpen s && !s.esc then"),
]

# T40 c13: the skip-waived drop in stepAs (one line); its mutant drops an escalated item.
SKIP = "if waived && isOpen s && !s.esc && s.kb == .clear then"
SKIP_MUTANTS = [
    ("skip-waived-drops-escalated", "if waived && isOpen s && s.kb == .clear then"),
]

results = []


def check(name, ok, detail=""):
    results.append(bool(ok))
    print(("PASS " if ok else "FAIL ") + name + ("" if ok else ": " + str(detail)[:1500]))


def norm(t):
    return " ".join(t.split())


def decl(text, key):
    """The declaration that starts `theorem KEY` or `def KEY`, up to its `:= by` or its first blank line."""
    m = re.search(r"^(theorem|def) " + re.escape(key) + r"\b.*?(?=:= by|\n\n|\n/--)", text, re.S | re.M)
    if not m:
        return None
    end = text[m.end():m.end() + 5]
    return norm(m.group(0) + (" := by" if end.startswith(":= by") else ""))


def lean(path):
    p = subprocess.run(["lake", "env", "lean", path], cwd=HERE, capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def main():
    src = open(LEAN, encoding="utf-8").read()
    for key, want in FROZEN.items():
        got = decl(src, key)
        check(f"t40-c7-statement-{key}-unchanged", got == norm(want), got)
    n = src.count(ANCHOR)
    check("t40-c7-model-has-rotate-lapse", n == 1, f"anchor occurs {n} times")
    nskip = src.count(SKIP)
    check("t40-c13-model-has-skip-waived", nskip == 1, f"anchor occurs {nskip} times")
    g = src.count(GATE)
    check("t40-c10-model-has-rotate-gate", g == 1, f"the triage gate line occurs {g} times")
    d = tempfile.mkdtemp(prefix="ledger-guard-mutant-")
    try:
        path = os.path.join(d, "Model.lean")
        with open(path, "w", encoding="utf-8") as f:
            f.write(src)
        code, out = lean(path)
        check("t40-c7-model-checks", code == 0 and not re.search(r"Model\.lean:\d+:\d+: error", out)
              and "sorryAx" not in out, (code, out[-1500:]))
        for name, repl in MUTANTS:
            if n != 1:
                check(f"t40-c7-mutant-{name}-rejected", False, "no anchor to mutate")
                continue
            with open(path, "w", encoding="utf-8") as f:
                f.write(src.replace(ANCHOR, repl))
            code, out = lean(path)
            thm = src.index("theorem stepAs_agent_keeps_guarded")
            line0 = src[:thm].count("\n") + 1
            line1 = src[:src.index("theorem exec_agent_keeps_guarded")].count("\n") + 1
            err_lines = [int(x) for x in re.findall(r"Model\.lean:(\d+):\d+: error", out)]
            in_thm = any(line0 <= x < line1 for x in err_lines)
            # `lake env lean` prints #eval output bare (no file:line prefix): the counterexample list of
            # `#eval agentCounterexamples` is the one output that starts with `[({ status := `
            m = re.search(r"^\[\(\{ status := .*?\)\]$", out, re.S | re.M)
            cex = m and "summary := true" in m.group(0) and "Cmd.rotate" in m.group(0)
            sorry = re.search(r"'LedgerGuard\.agent_run_keeps_guarded' depends on axioms: \[[^\]]*sorryAx", out)
            check(f"t40-c7-mutant-{name}-rejected", code != 0 and in_thm and bool(cex) and bool(sorry),
                  (code, err_lines, bool(cex), bool(sorry), out[-1200:]))
        for name, repl in SKIP_MUTANTS:
            if nskip != 1:
                check(f"t40-c13-mutant-{name}-rejected", False, "no anchor to mutate")
                continue
            with open(path, "w", encoding="utf-8") as f:
                f.write(src.replace(SKIP, repl))
            code, out = lean(path)
            line0 = src[:src.index("theorem stepAs_agent_keeps_guarded")].count("\n") + 1
            line1 = src[:src.index("theorem exec_agent_keeps_guarded")].count("\n") + 1
            err_lines = [int(x) for x in re.findall(r"Model\.lean:(\d+):\d+: error", out)]
            in_thm = any(line0 <= x < line1 for x in err_lines)
            m = re.search(r"^\[\(\{ status := .*?\)\]$", out, re.S | re.M)
            cex = m and "esc := true" in m.group(0) and "Cmd.skipWaived" in m.group(0)
            sorry = all(re.search(r"'LedgerGuard\." + t + r"' depends on axioms: \[[^\]]*sorryAx", out)
                        for t in ("agent_run_keeps_guarded", "agent_run_keeps_escalated"))
            check(f"t40-c13-mutant-{name}-rejected", code != 0 and in_thm and bool(cex) and bool(sorry),
                  (code, err_lines, bool(cex), bool(sorry), out[-1200:]))
    finally:
        shutil.rmtree(d, ignore_errors=True)
    print(f"{results.count(True)} passed, {results.count(False)} failed")
    sys.exit(0 if results and all(results) else 1)


if __name__ == "__main__":
    main()

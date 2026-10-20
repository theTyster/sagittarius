#!/usr/bin/env python3
"""Run the orbit-kb CLI on the generated KBs and compare it with the Lean model.

Usage: conform_run.py GENDIR [--mutant MA|MB|MC|MI|MY] [--jobs N]

GENDIR holds the KB directories that `lake exe conform gen GENDIR` wrote.
For each KB, this script:
  1. makes each proof in proofs.txt as `add_proof` in test_orbit_kb.sh does:
     lean/P.lean, the digest of the file list, and runs/proof-ID.log. Mode
     `changed` edits lean/P.lean after the log. Mode `nolog` writes no log;
  2. puts the digest into kb.pl;
  3. runs `orbit-kb --dir K query done` and
     `orbit-kb --dir K query 'burn_open(C)' -n 0`, and also the derived facts
     `proof_changed(A)` and `waiver_lapsed(W)`;
  4. compares the answers with expect.txt (the compiled Lean model).

The CLI library is $ORBIT_KB_LIB (the default library when it is not set).
With --mutant M, the library is expected to be mutant M. The script then
compares the CLI with the implementation model and with the answers of mutant
M (in expect.txt). The run passes (exit 0, DISCRIMINATED) when the CLI differs
from the model on exactly the predicted KBs (more than zero), and matches mutant
M on every KB.

An exit code other than 0 or 1 from a query (for example 2 on ENGINE
DISAGREEMENT) is a failure. Exit 0: all KBs match. Exit 1: a mismatch.
"""
import hashlib
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
OKB = os.environ.get(
    "ORBIT_KB_CLI",
    os.path.normpath(os.path.join(HERE, "../../../shared/link/.local/bin/orbit-kb")),
)
LEAN_TEXT = "theorem t : True := trivial\n"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def make_proofs(k: str) -> None:
    """Write the proof files and logs, then fill in the digests in kb.pl."""
    kb_path = os.path.join(k, "kb.pl")
    with open(kb_path) as f:
        kb = f.read()
    if "@DIGEST:" not in kb:
        return  # done before, or no proof
    # As add_proof: one file P.lean. The digest covers the lines "claim C",
    # "theorem t", "module P", "statement True", and "SHA P.lean" (the D10
    # follow-up binds the claim and the statement to the digest, F6).
    # Each proof has its own root, lean-ID/, so an edit of one proof file does
    # not change another proof. The digest covers the relative path only, so
    # it is the same as in add_proof.
    fsha = "sha256:" + sha(LEAN_TEXT.encode())
    with open(os.path.join(k, "proofs.txt")) as f:
        rows = [ln.split() for ln in f if ln.strip()]
    for pid, claim, mode in rows:
        dg = "sha256:" + sha(
            f"claim {claim}\ntheorem t\nmodule P\nstatement True\n{fsha} P.lean\n".encode()
        )
        root = f"lean-{pid}"
        os.makedirs(os.path.join(k, root), exist_ok=True)
        pf = os.path.join(k, root, "P.lean")
        with open(pf, "w") as f:
            f.write(LEAN_TEXT)
        if mode != "nolog":
            log = (
                f"% orbit-kb prove claim={claim} digest={dg}\ntheorem t\nmodule P\n"
                f"source P.lean\nstatement True\nlean 4.35.0\ntime 2026-10-15T11:00:00Z\n"
                f"root {root}\nfile {fsha} P.lean\n--- lake build output\n"
            )
            with open(os.path.join(k, "runs", f"proof-{pid}.log"), "w") as f:
                f.write(log)
        if mode == "changed":
            with open(pf, "a") as f:  # the file changes after the log
                f.write("-- edit\n")
        kb = kb.replace(f"@DIGEST:{pid}@", dg)
    with open(kb_path, "w") as f:
        f.write(kb)


SLOWEST = [0.0, ""]
TIMEOUT = float(os.environ.get("CONFORM_TIMEOUT", "120"))


def run(k: str, *args: str):
    """One CLI query. A timeout is exit code 124, and it counts as a failure."""
    t0 = time.monotonic()
    try:
        p = subprocess.run(
            [OKB, "--dir", k, "query", *args],
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
            stdin=subprocess.DEVNULL,
        )
        res = (p.returncode, p.stdout, p.stderr)
    except subprocess.TimeoutExpired:
        res = (124, "", f"no answer after {TIMEOUT:.0f} s")
    dt = time.monotonic() - t0
    if dt > SLOWEST[0]:
        SLOWEST[0], SLOWEST[1] = dt, f"{os.path.basename(k)} {' '.join(args)}"
    return res


VAR_LINE = re.compile(r"^([A-Z]\w*) = (\S+)$")


def answers(rc: int, out: str, var: str):
    if rc == 1:
        return []
    vals = []
    for ln in out.splitlines():
        m = VAR_LINE.match(ln.strip())
        if m and m.group(1) == var:
            vals.append(m.group(2))
    return sorted(set(vals))


def read_expect(k: str):
    """The expected answers: the model, and each mutant (MA, MB, MC, MI, MY)."""
    exp = {}
    with open(os.path.join(k, "expect.txt")) as f:
        for ln in f:
            parts = ln.split()
            exp[parts[0]] = parts[1:]
    out = {
        "model": {"done": exp["done"][0], "open": sorted(exp["open"])},
        "changed": sorted(exp["changed"]),
        "lapsed": sorted(exp["lapsed"]),
    }
    for m in ("MA", "MB", "MC", "MI", "MY"):
        out[m] = {"done": exp[m][0], "open": sorted(exp[m][1:])}
    return out


def diff(got, want):
    errs = []
    if got["done"] != want["done"]:
        errs.append(f"done: CLI {got['done']}, want {want['done']}")
    if got["open"] != want["open"]:
        errs.append(f"burn_open: CLI {got['open']}, want {want['open']}")
    return errs


def check(k: str, mutant):
    """Returns (name, errors against the model, errors against the mutant)."""
    make_proofs(k)
    exp = read_expect(k)
    fatal = []
    got = {}
    rc, out, err = run(k, "done")
    if rc not in (0, 1):
        fatal.append(f"query done exited {rc}: {(out + err).strip()[:300]}")
    got["done"] = "true" if rc == 0 else "false"
    rc, out, err = run(k, "burn_open(C)", "-n", "0")
    if rc not in (0, 1):
        fatal.append(f"query burn_open exited {rc}: {(out + err).strip()[:300]}")
    got["open"] = answers(rc, out, "C")
    if not mutant:
        for pred, key in (("proof_changed(A)", "changed"), ("waiver_lapsed(A)", "lapsed")):
            rc, out, err = run(k, pred, "-n", "0")
            if rc not in (0, 1):
                fatal.append(f"query {pred} exited {rc}: {(out + err).strip()[:300]}")
                continue
            g = answers(rc, out, "A")
            if g != exp[key]:
                fatal.append(f"{pred}: CLI {g}, model {exp[key]}")
    vs_model = fatal + diff(got, exp["model"])
    vs_mut = (fatal + diff(got, exp[mutant])) if mutant else []
    return os.path.basename(k), vs_model, vs_mut


def main(argv):
    gen = None
    mutant = None
    jobs = 4
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--mutant":
            mutant = argv[i + 1]
            i += 2
        elif a == "--jobs":
            jobs = int(argv[i + 1])
            i += 2
        else:
            gen = a
            i += 1
    if not gen or mutant not in (None, "MA", "MB", "MC", "MI", "MY"):
        print(__doc__, file=sys.stderr)
        return 2
    kbs = sorted(
        (os.path.join(gen, d) for d in os.listdir(gen) if os.path.isfile(os.path.join(gen, d, "kb.pl"))),
        key=lambda p: (os.path.basename(p)[0], int(os.path.basename(p)[1:])),
    )
    n_done = n_open = predicted = 0
    for k in kbs:
        e = read_expect(k)
        n_done += e["model"]["done"] == "true"
        n_open += bool(e["model"]["open"])
        if mutant:
            predicted += e[mutant] != e["model"]
    lib = os.environ.get("ORBIT_KB_LIB", "(default)")
    print(f"lib={lib}")
    print(f"KBs: {len(kbs)} (model: done true in {n_done}, an open burn in {n_open})")
    if mutant:
        print(f"expected before the run: the CLI differs from the model on {predicted} KBs "
              f"and matches mutant {mutant} on all {len(kbs)}", flush=True)
    bad_model = bad_mut = 0
    shown = 0
    with ThreadPoolExecutor(max_workers=jobs) as ex:
        for name, em, eu in ex.map(lambda k: check(k, mutant), kbs):
            bad_model += bool(em)
            bad_mut += bool(eu)
            errs = eu if mutant else em
            if errs and shown < 15:
                shown += 1
                print(f"MISMATCH {name}: " + "; ".join(errs))
            elif mutant and em and shown < 5:
                shown += 1
                print(f"differs from the model (as predicted) {name}: " + "; ".join(em))
    print(f"slowest CLI call: {SLOWEST[0]:.1f} s ({SLOWEST[1]})")
    print(f"against the implementation model: {len(kbs) - bad_model} match, {bad_model} mismatch")
    if mutant:
        print(f"against the answers of mutant {mutant}: {len(kbs) - bad_mut} match, {bad_mut} mismatch")
        ok = bad_mut == 0 and bad_model == predicted and predicted > 0
        print("DISCRIMINATED" if ok else "NOT DISCRIMINATED")
        return 0 if ok else 1
    return 0 if bad_model == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

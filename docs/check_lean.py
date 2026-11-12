#!/usr/bin/env python3
"""Run Lean on the Lean files of Sagittarius and test what the texts say about them.

Sagittarius 0.3.0, package L-A (claims c_l_a_1, c_l_a_2, c_l_a_3; finding S-c9 and S22).

hypothesis  Lean compiles Hypothesis.lean, at the path that docs/PHILOSOPHY.md cites. The script
            counts the theorems that the file declares, and the axioms that each one uses. It
            fails when Lean reports an error, when a theorem or a definition of the file uses an
            axiom (the philosophy says: "none uses an axiom"; propext counts too), when the file
            declares an axiom, or when the count differs from the count in the philosophy.
names       Each theorem name that the philosophy cites in the section on the Lean file (a name in
            backticks with "_" in it, outside code blocks) is a theorem of Hypothesis.lean, at the
            path that the philosophy cites. Reads the source; it does not run Lean.
proofs      For each Lake project under kb/proofs (a folder with a lakefile): `lake build`, then
            the axioms of each theorem of the project. It fails on a build error and on an axiom
            other than propext, Classical.choice and Quot.sound (so sorry, native_decide and a
            declared axiom fail). `proofs --list` prints the projects and builds nothing.

Usage: python3 docs/check_lean.py [hypothesis] [names] [proofs [--list]]     (none: all three)
Exit 0: pass. 1: a failure, one line "FAIL ..." each. 2: usage, or Lean is not installed.

The script never changes a Lean file. Hypothesis.lean is compiled from a copy in a temporary folder.
`lake build` writes kb/proofs/*/.lake, which git ignores. No project here has packages: the build
needs no network. Never run `lake update` or `lake exe cache get` here.
Tests: python3 docs/test_check_lean.py
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PHIL = "docs/PHILOSOPHY.md"
PROOFS = "kb/proofs"
# Hypothesis.lean has no Lake project. It is compiled with the toolchain of the projects in kb/proofs.
TOOLCHAIN = "leanprover/lean4:v4.35.0"
# The axioms a project under kb/proofs may use: the three of Lean's own logic.
STANDARD = {"propext", "Classical.choice", "Quot.sound"}

# Imports MODULE (built) and prints one line per declaration of every module MODULE or MODULE.*:
#   DECL kind name axiom,axiom,...
# kind is theorem, axiom or other. A declaration counts only if the source wrote it: it has a
# source range, it is not an internal detail, and it is not the projection of a structure field.
PROBE = r"""
import Lean
open Lean

unsafe def main (args : List String) : IO UInt32 := do
  let [modS] := args | IO.eprintln "usage: probe MODULE"; return 2
  initSearchPath (← findSysroot)
  let root := modS.toName
  let env ← importModules #[{ module := root }] {} (trustLevel := 0)
  let ctx : Core.Context := { fileName := "<check_lean>", fileMap := default }
  let st : Core.State := { env }
  for i in [0:env.header.moduleNames.size] do
    let m := env.header.moduleNames[i]!
    unless m == root || root.isPrefixOf m do continue
    for n in env.header.moduleData[i]!.constNames do
      if n.isInternalDetail then continue
      if (env.getProjectionFnInfo? n).isSome then continue
      let (rng, _) ← (findDeclarationRanges? n : CoreM _).toIO ctx st
      if rng.isNone then continue
      let some ci := env.find? n | continue
      let kind := match ci with
        | .thmInfo _ => "theorem" | .axiomInfo _ => "axiom" | _ => "other"
      let (axs, _) ← (collectAxioms n : CoreM (Array Name)).toIO ctx st
      IO.println s!"DECL {kind} {n} {",".intercalate (axs.toList.map toString)}"
  return 0
"""

fails = []


def fail(msg):
    fails.append(msg)
    print("FAIL " + msg)


def read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read()


def tail(text, n=12):
    return "\n".join("    " + ln for ln in text.strip().splitlines()[-n:])


def need_tool(name):
    if shutil.which(name) is None:
        print(f"{name} is not on PATH: install Lean 4 through elan", file=sys.stderr)
        sys.exit(2)


# ------------------------------------------------------------------ what the philosophy says
def lean_section():
    """The section of the philosophy that cites Hypothesis.lean, and the path that it cites."""
    text = read(PHIL)
    m = re.search(r"`([^`]*Hypothesis\.lean)`", text)
    if not m:
        return None, None
    sections = re.split(r"(?m)^(?=## )", text)
    sec = next(s for s in sections if m.group(0) in s)
    return m.group(1), sec


def cited_count(sec, path):
    """The count of theorems in the paragraph that cites the path ("... and 68 theorems ...")."""
    for para in re.split(r"\n\s*\n", sec):
        if path in para:
            m = re.search(r"(\d+) theorems", " ".join(para.split()))
            return int(m.group(1)) if m else None
    return None


def cited_names(sec):
    prose = re.sub(r"```.*?```", "", sec, flags=re.S)
    return sorted({n for n in re.findall(r"`([A-Za-z_][A-Za-z0-9_.']*)`", prose) if "_" in n})


def source_theorems(src):
    """Names that the source declares with `theorem` (namespaces are not resolved: names are short)."""
    return set(re.findall(r"(?m)^\s*(?:@\[[^\]]*\]\s*)?(?:private\s+|protected\s+)*theorem\s+([^\s({\[:]+)", src))


# ------------------------------------------------------------------ Lean
def probe(cmd, cwd, env=None):
    """Runs the probe (cmd + [probe.lean, MODULE]) and returns {name: (kind, [axioms])}, or None."""
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "probe.lean")
        with open(p, "w", encoding="utf-8") as f:
            f.write(PROBE)
        r = subprocess.run(cmd(p), cwd=cwd, env=env, capture_output=True, text=True)
    if r.returncode != 0:
        return None, r.stdout + r.stderr
    decls = {}
    for ln in r.stdout.splitlines():
        parts = ln.split(" ")
        if parts[0] == "DECL" and len(parts) >= 3:
            axs = parts[3].split(",") if len(parts) > 3 and parts[3] else []
            decls[parts[2]] = (parts[1], axs)
    return decls, r.stdout + r.stderr


def check_hypothesis():
    need_tool("lean")
    path, sec = lean_section()
    if not path:
        return fail(f"{PHIL} cites no Hypothesis.lean")
    if not os.path.isfile(os.path.join(ROOT, path)):
        return fail(f"Hypothesis.lean is not at the path that the philosophy cites ({path})")
    want = cited_count(sec, path)
    if want is None:
        fail(f"{PHIL} gives no count of theorems in the paragraph that cites {path}")
    lean = ["lean", "+" + TOOLCHAIN]
    with tempfile.TemporaryDirectory() as d:
        shutil.copy2(os.path.join(ROOT, path), os.path.join(d, "Hypothesis.lean"))
        r = subprocess.run(lean + ["-o", "Hypothesis.olean", "Hypothesis.lean"], cwd=d,
                           capture_output=True, text=True)
        if r.returncode != 0:
            return fail(f"Lean rejects {path}:\n" + tail(r.stdout + r.stderr))
        env = dict(os.environ, LEAN_PATH=d)
        decls, out = probe(lambda p: lean + ["--run", p, "Hypothesis"], d, env)
    if decls is None:
        return fail("the probe of the theorems did not run:\n" + tail(out))
    thms = sorted(n for n, (k, _) in decls.items() if k == "theorem")
    for n, (k, axs) in sorted(decls.items()):
        if k == "axiom":
            fail(f"{path} declares the axiom {n}")
        elif axs:
            fail(f"{n} uses the axiom(s) {', '.join(axs)}; the philosophy says that no theorem uses an axiom")
    if want is not None and len(thms) != want:
        fail(f"{path} declares {len(thms)} theorems; the philosophy counts {want}")
    print(f"hypothesis: {path}: {len(thms)} theorems (the philosophy counts {want}), "
          f"axioms: {'none' if not any(a for _, a in decls.values()) else 'see FAIL lines'}")


def check_names():
    path, sec = lean_section()
    if not path:
        return fail(f"{PHIL} cites no Hypothesis.lean")
    full = os.path.join(ROOT, path)
    if not os.path.isfile(full):
        return fail(f"Hypothesis.lean is not at the path that the philosophy cites ({path})")
    have = source_theorems(read(path))
    names = cited_names(sec)
    if not names:
        fail(f"the philosophy cites no theorem name in its section on {path}")
    for n in names:
        if n not in have:
            fail(f"the philosophy cites the theorem {n}, and {path} declares no theorem of that name")
    print(f"names: {len(names)} theorem names that the philosophy cites, checked against {path}")


def projects():
    base = os.path.join(ROOT, PROOFS)
    if not os.path.isdir(base):
        return []
    return sorted(n for n in os.listdir(base)
                  if any(os.path.isfile(os.path.join(base, n, f)) for f in ("lakefile.toml", "lakefile.lean")))


def lib_name(proj_dir):
    """The module that the project builds: the first lean_lib (lakefile.toml) or its default target."""
    toml = os.path.join(proj_dir, "lakefile.toml")
    if os.path.isfile(toml):
        t = open(toml, encoding="utf-8").read()
        m = re.search(r"\[\[lean_lib\]\]\s*\n\s*name\s*=\s*\"([^\"]+)\"", t)
        if m:
            return m.group(1)
    t = open(os.path.join(proj_dir, "lakefile.lean"), encoding="utf-8").read() if os.path.isfile(
        os.path.join(proj_dir, "lakefile.lean")) else ""
    m = re.search(r"lean_lib\s+[«\"]?([A-Za-z0-9_]+)", t)
    return m.group(1) if m else None


def check_proofs(list_only):
    names = projects()
    if not names:
        return fail(f"no Lake project under {PROOFS}")
    if list_only:
        for n in names:
            print(f"{PROOFS}/{n}")
        return
    need_tool("lake")
    for n in names:
        rel = f"{PROOFS}/{n}"
        d = os.path.join(ROOT, rel)
        lib = lib_name(d)
        if not lib:
            fail(f"{rel}: no lean_lib in its lakefile")
            continue
        r = subprocess.run(["lake", "build", lib], cwd=d, capture_output=True, text=True)
        if r.returncode != 0:
            fail(f"{rel}: lake build {lib} failed:\n" + tail(r.stdout + r.stderr))
            continue
        decls, out = probe(lambda p: ["lake", "env", "lean", "--run", p, lib], d)
        if decls is None:
            fail(f"{rel}: the probe of the axioms did not run:\n" + tail(out))
            continue
        thms = [x for x, (k, _) in decls.items() if k == "theorem"]
        bad = 0
        for x, (k, axs) in sorted(decls.items()):
            if k == "axiom":
                fail(f"{rel}: declares the axiom {x}")
                bad += 1
            other = [a for a in axs if a not in STANDARD]
            if other:
                fail(f"{rel}: {x} uses the axiom(s) {', '.join(other)}")
                bad += 1
        if not thms:
            fail(f"{rel}: no theorem")
        print(f"proofs: {rel}: lake build {lib} ok, {len(thms)} theorems, "
              f"{'axioms: only ' + ', '.join(sorted(STANDARD)) + ' or none' if not bad else 'see FAIL lines'}")


def main(argv):
    modes = [a for a in argv if not a.startswith("-")]
    flags = [a for a in argv if a.startswith("-")]
    if any(f not in ("--list",) for f in flags) or any(m not in ("hypothesis", "names", "proofs") for m in modes) \
            or ("--list" in flags and modes != ["proofs"]):
        print("usage: python3 docs/check_lean.py [hypothesis] [names] [proofs [--list]]", file=sys.stderr)
        return 2
    for m in modes or ["hypothesis", "names", "proofs"]:
        if m == "hypothesis":
            check_hypothesis()
        elif m == "names":
            check_names()
        else:
            check_proofs("--list" in flags)
    if fails:
        print(f"check_lean: {len(fails)} failure(s)")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

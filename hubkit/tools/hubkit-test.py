#!/usr/bin/env python3
"""Tests for hubkit.py. Builds throwaway kits and hubs in temp dirs; never touches a real hub.

usage: python3 -I tools/hubkit-test.py [--mutants]
  --mutants  also run the suite against each rule mutant of hubkit.py; each must make a case fail.
Prints `PASS name` or `FAIL name: why` per case; the last line is `N passed, M failed`.
"""
import hashlib, json, os, shutil, stat, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.dirname(HERE)
REAL = os.path.join(HERE, "hubkit.py")
QUIET = False

MUTANTS = [
    ("upgrade-overwrites-modified", "if state == \"modified\" and changed:  # merge, never overwrite",
     "if False:"),
    ("upgrade-touches-owned", "if not os.path.exists(dst):  # owned: copy only if absent", "if True:"),
    ("pending-not-recorded", "m[\"pending\"] = pending  # merges left for the agent", "m[\"pending\"] = []"),
    ("install-overwrites", "if clash:  # install never overwrites", "if False:"),
    ("dry-run-writes", "if not yes:  # dry run", "if False:"),
]


class Run:
    def __init__(self, script):
        self.script = script
        self.results = []

    def check(self, name, ok, detail=""):
        self.results.append(bool(ok))
        if not QUIET:
            print(("PASS " if ok else "FAIL ") + name + ("" if ok else ": " + str(detail)[:500]))


def hk(r, *args):
    p = subprocess.run([sys.executable, "-I", r.script] + [str(a) for a in args], capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr


def sha(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def make_kit(root, name, version, files, engine, owned):
    k = os.path.join(root, name)
    for rel, text in files.items():
        write(os.path.join(k, "hub", rel), text)
    write(os.path.join(k, "kit.json"), json.dumps({"version": version, "engine": engine, "owned": owned}))
    return k


def manifest(hub):
    with open(os.path.join(hub, ".hub-template.json"), encoding="utf-8") as f:
        return json.load(f)


def tree(d):
    out = {}
    for base, _, fs in os.walk(d):
        for f in fs:
            p = os.path.join(base, f)
            out[os.path.relpath(p, d)] = sha(p)
    return out


def case_real_kit(r):
    with open(os.path.join(KIT, "kit.json"), encoding="utf-8") as f:
        k = json.load(f)
    listed = k["engine"] + k["owned"]
    on_disk = sorted(tree(os.path.join(KIT, "hub")))
    r.check("real-kit-lists-every-file-once", sorted(listed) == on_disk and len(set(listed)) == len(listed),
            sorted(set(on_disk) ^ set(listed)))
    r.check("real-kit-claude-md-owned", "CLAUDE.md" in k["owned"] and "HUB-CORE.md" in k["engine"], k)


def case_install(r, root):
    v1 = make_kit(root, "kit1", "1.0.0",
                  {"CORE.md": "core v1\n", "A.sh": "#!/bin/sh\necho a\n", "B.md": "b v1\n", "D.md": "d v1\n",
                   "CLAUDE.md": "mine v1\n"},
                  ["CORE.md", "A.sh", "B.md", "D.md"], ["CLAUDE.md"])
    os.chmod(os.path.join(v1, "hub", "A.sh"), 0o755)
    hub = os.path.join(root, "hub")
    res = hk(r, "install", "--kit", v1, "--hub", hub)
    r.check("install-runs", res[0] == 0, res)
    r.check("install-copies-every-file", set(tree(hub)) == {"CORE.md", "A.sh", "B.md", "D.md", "CLAUDE.md",
                                                             ".hub-template.json"}, tree(hub))
    m = manifest(hub)
    r.check("install-records-version", m.get("template_version") == "1.0.0", m)
    r.check("install-records-engine-hashes", m.get("files") == {p: sha(os.path.join(hub, p))
                                                              for p in ("CORE.md", "A.sh", "B.md", "D.md")}, m)
    r.check("install-records-owned", m.get("owned") == ["CLAUDE.md"] and m.get("pending") == [], m)
    r.check("install-keeps-exec-bit", os.stat(os.path.join(hub, "A.sh")).st_mode & stat.S_IXUSR)
    res = hk(r, "install", "--kit", v1, "--hub", hub)
    r.check("install-refuses-existing-hub", res[0] == 2, res)
    hub2 = os.path.join(root, "hub2")
    write(os.path.join(hub2, "B.md"), "already here\n")
    res = hk(r, "install", "--kit", v1, "--hub", hub2)
    r.check("install-refuses-clash", res[0] == 1 and "B.md" in res[2]
            and tree(hub2) == {"B.md": sha(os.path.join(hub2, "B.md"))}, (res, tree(hub2)))
    return hub


def case_status_upgrade(r, root, hub):
    res = hk(r, "status", "--kit", os.path.join(root, "kit1"), "--hub", hub)
    r.check("status-fresh-all-unchanged", res[0] == 0 and res[1].count("unchanged") == 4
            and "modified" not in res[1], res)
    write(os.path.join(hub, "B.md"), "b v1 with a local change\n")
    write(os.path.join(hub, "CLAUDE.md"), "my own rules\n")
    write(os.path.join(hub, "NOTES.md"), "the hub made this first\n")
    res = hk(r, "status", "--kit", os.path.join(root, "kit1"), "--hub", hub)
    r.check("status-sees-modified", res[0] == 0 and "modified" in res[1] and "B.md" in res[1], res)

    v2 = make_kit(root, "kit2", "1.1.0",
                  {"CORE.md": "core v2\n", "A.sh": "#!/bin/sh\necho a\n", "B.md": "b v2\n", "C.md": "c new\n",
                   "CLAUDE.md": "template v2\n", "LOCAL.md": "new owned file\n",
                   "NOTES.md": "template notes\n"},
                  ["CORE.md", "A.sh", "B.md", "C.md"], ["CLAUDE.md", "LOCAL.md", "NOTES.md"])
    before = tree(hub)
    res = hk(r, "upgrade", "--kit", v2, "--hub", hub)
    r.check("upgrade-dry-run-plans", res[0] == 0 and "replace" in res[1] and "merge" in res[1], res)
    r.check("upgrade-dry-run-writes-nothing", tree(hub) == before, tree(hub))
    res = hk(r, "upgrade", "--kit", v2, "--hub", hub, "--yes")
    r.check("upgrade-runs", res[0] == 0, res)
    read = lambda p: open(os.path.join(hub, p), encoding="utf-8").read() if os.path.exists(os.path.join(hub, p)) else None
    r.check("upgrade-replaces-unchanged", read("CORE.md") == "core v2\n", read("CORE.md"))
    r.check("upgrade-keeps-modified", read("B.md") == "b v1 with a local change\n", read("B.md"))
    r.check("upgrade-adds-new-engine", read("C.md") == "c new\n", read("C.md"))
    r.check("upgrade-removes-dropped-unchanged", read("D.md") is None, tree(hub))
    r.check("upgrade-never-touches-owned", read("CLAUDE.md") == "my own rules\n", read("CLAUDE.md"))
    r.check("upgrade-keeps-existing-file-at-new-owned-path", read("NOTES.md") == "the hub made this first\n",
            read("NOTES.md"))
    r.check("upgrade-adds-new-owned-if-absent", read("LOCAL.md") == "new owned file\n", read("LOCAL.md"))
    m = manifest(hub)
    r.check("upgrade-records-version", m.get("template_version") == "1.1.0", m)
    r.check("upgrade-records-pending-merge", [p.get("path") for p in m.get("pending", [])] == ["B.md"]
            and m["pending"][0].get("from") == "1.0.0" and m["pending"][0].get("to") == "1.1.0", m)
    r.check("upgrade-records-new-hashes", m.get("files", {}).get("CORE.md") == sha(os.path.join(v2, "hub", "CORE.md"))
            and m.get("files", {}).get("B.md") == sha(os.path.join(v2, "hub", "B.md")), m)
    res = hk(r, "status", "--kit", v2, "--hub", hub)
    r.check("status-shows-pending", res[0] == 0 and "pending" in res[1] and "B.md" in res[1], res)
    res = hk(r, "upgrade", "--kit", v2, "--hub", hub, "--yes")
    r.check("upgrade-refused-while-pending", res[0] == 2 and "pending" in res[2], res)
    res = hk(r, "done", "--hub", hub, "C.md")
    r.check("done-refuses-not-pending", res[0] == 1, res)
    write(os.path.join(hub, "B.md"), "b v2 with a local change\n")
    res = hk(r, "done", "--hub", hub, "B.md")
    r.check("done-clears-pending", res[0] == 0 and manifest(hub).get("pending") == [], (res, manifest(hub)))


def cases(r):
    root = tempfile.mkdtemp(prefix="hubkit-test-")
    try:
        case_real_kit(r)
        hub = case_install(r, root)
        case_status_upgrade(r, root, hub)
    except Exception as e:
        r.check("scenario-ran", False, repr(e))
    finally:
        shutil.rmtree(root, ignore_errors=True)


def main():
    global QUIET
    r = Run(REAL)
    if not os.path.exists(REAL):
        print("FAIL hubkit.py-exists\n0 passed, 1 failed")
        sys.exit(1)
    cases(r)
    total, passed = len(r.results), r.results.count(True)
    if "--mutants" in sys.argv[1:]:
        QUIET = True
        src = open(REAL, encoding="utf-8").read()
        for name, anchor, repl in MUTANTS:
            total += 1
            if src.count(anchor) != 1:
                print(f"FAIL mutant {name}: anchor occurs {src.count(anchor)} times")
                continue
            d = tempfile.mkdtemp(prefix="hubkit-mutant-")
            path = os.path.join(d, "hubkit.py")
            with open(path, "w", encoding="utf-8") as f:
                f.write(src.replace(anchor, repl))
            m = Run(path)
            cases(m)
            shutil.rmtree(d, ignore_errors=True)
            killed = not all(m.results)
            print(("PASS" if killed else "FAIL") + f" mutant {name}: " + ("KILLED" if killed else "SURVIVED"))
            passed += 1 if killed else 0
        QUIET = False
    print(f"{passed} passed, {total - passed} failed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()

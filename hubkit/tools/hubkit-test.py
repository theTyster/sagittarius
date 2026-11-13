#!/usr/bin/env python3
"""Tests for hubkit.py. Builds throwaway kits and hubs in temp dirs; never touches a real hub.

usage: python3 -I tools/hubkit-test.py [--mutants] [--case case_NAME ...]
  --mutants  also run the suite against each rule mutant of hubkit.py; each must make a case fail.
Prints `PASS name` or `FAIL name: why` per case; the last line is `N passed, M failed`.
"""
import hashlib, json, os, re, shutil, stat, subprocess, sys, tempfile, time

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.dirname(HERE)
REAL = os.path.join(HERE, "hubkit.py")
QUIET = False
ONLY = []  # --case NAME: run only these case functions

MUTANTS = [
    ("upgrade-overwrites-modified", "if state == \"modified\" and changed:  # merge, never overwrite",
     "if False:"),
    ("upgrade-touches-owned", "if not os.path.exists(dst):  # owned: copy only if absent", "if True:"),
    ("pending-not-recorded", "m[\"pending\"] = pending  # merges left for the agent", "m[\"pending\"] = []"),
    ("install-overwrites", "if clash:  # install never overwrites", "if False:"),
    ("dry-run-writes", "if not yes:  # dry run", "if False:"),
    # install UX c3: a formal hub gets the kit's orbit-kb as engine files
    ("orbit-kb-copy-not-installed", "if edition == \"formal\":  # the hub's own orbit-kb (install UX c3)", "if False:"),
    # install UX c3: the human chooses the edition; install never reads the PATH for it
    ("edition-from-path", "return \"informal\"  # install UX c3: the human chooses formal", "return \"formal\" if shutil.which(\"orbit-kb\") else \"informal\""),
    # 0.3.0 c_m_d_2: the manifest records what the hub runs, and status compares it with the files now
    ("runs-not-recorded", "m[\"runs\"] = runs_of(o[\"kit\"], k, ed)  # what the hub runs (c_m_d_2)", "pass"),
    ("runs-not-compared", "same = sha(there) == want  # the launcher file now (c_m_d_2)", "same = True"),
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



# T48 c3: the kit version moves with the db schema. 0.5.0 shipped db schema 4 (92cf33b); schema 5 (T47 c2)
# is a new kit version, so `upgrade` of a 0.5.0 hub shows a version change and its section says `migrate`.
SHIPPED_SCHEMA = {"0.5.0": 4, "0.6.0": 5, "0.7.0": 6}  # 0.7.0 (kitrel): schema 6 drops the session index


def upgrading_sections(text):
    """[(version, body)] of the `### X.Y.Z` release sections of UPGRADING.md, newest first."""
    parts = re.split(r"^### (\d+\.\d+\.\d+)[^\n]*\n", text, flags=re.M)
    return list(zip(parts[1::2], parts[2::2]))


def case_t48_version_moves_with_schema(r, root):
    with open(os.path.join(KIT, "kit.json"), encoding="utf-8") as f:
        version = json.load(f)["version"]
    with open(os.path.join(KIT, "UPGRADING.md"), encoding="utf-8") as f:
        secs = upgrading_sections(f.read())
    with open(os.path.join(KIT, "hub", ".claude", "scripts", "hubflow.py"), encoding="utf-8") as f:
        m = re.search(r"^SCHEMA_VERSION = (\d+)$", f.read(), re.M)
    schema = int(m.group(1)) if m else None

    def stated(body):
        x = re.search(r"The db schema is (\d+)", body)
        return int(x.group(1)) if x else None

    heads = [v for v, _ in secs]
    r.check("t48-c3-newest-upgrading-section-is-the-kit-version", heads[:1] == [version], (version, heads[:3]))
    r.check("t48-c3-newest-section-states-the-script-schema", secs and stated(secs[0][1]) == schema,
            (schema, secs[0][1][:200] if secs else None))
    r.check("t48-c3-newest-section-says-migrate", secs and "hubflow.py migrate" in secs[0][1], secs[0][1][:300] if secs else None)
    for v, n in SHIPPED_SCHEMA.items():
        body = dict(secs).get(v, "")
        r.check(f"t48-c3-section-{v}-states-the-schema-it-shipped", stated(body) == n, (v, n, stated(body)))
    # a release may keep the schema (0.4.0 and 0.5.0 both shipped 4); a newer section never states an older one
    seen = [stated(b) for _, b in secs if stated(b) is not None]
    r.check("t48-c3-db-schema-never-goes-down-in-a-newer-section", seen == sorted(seen, reverse=True), seen)
    # a hub at the release before this schema: upgrade shows a version change
    hub = os.path.join(root, "t48-c3-hub")
    res = hk(r, "install", "--kit", KIT, "--hub", hub, "--edition", "informal")
    r.check("t48-c3-setup-install-real-kit", res[0] == 0, res)
    old = "0.5.0"  # shipped schema 4 (SHIPPED_SCHEMA); a hub made then needs `migrate` to reach schema 5
    mf = manifest(hub)
    mf["template_version"] = old
    with open(os.path.join(hub, ".hub-template.json"), "w", encoding="utf-8") as f:
        json.dump(mf, f)
    res = hk(r, "upgrade", "--kit", KIT, "--hub", hub)
    r.check("t48-c3-upgrade-of-a-0.5.0-hub-shows-a-version-change", res[0] == 0
            and f"upgrade MindHole Kit {old} -> MindHole Kit {version} " in res[1] and old != version, res)  # kit3: the MindHole Kit version line


def clean_env(path):
    """The environment of a run from an installed hub: no HUBFLOW_ variables, the given PATH."""
    env = {k: v for k, v in os.environ.items() if not k.startswith("HUBFLOW_") and k != "HUB_SESSION"}
    env["PATH"] = path
    return env


def case_t51_c1_installed_hub_orbit_kb(r, root):
    """T51 c1: from an installed formal hub (the kit's hub/ copied by install), hubflow-test.py finds an
    orbit-kb on PATH and runs its real-orbit-kb case; with none, the skip is a failure and the last line counts it."""
    hub = os.path.join(root, "t51c1-hub")
    res = hk(r, "install", "--kit", KIT, "--hub", hub, "--edition", "formal")
    r.check("t51c1-setup-install-formal", res[0] == 0, res)
    script = os.path.join(hub, ".claude", "scripts", "hubflow-test.py")
    real_okb = os.path.join(os.path.dirname(KIT), "kb", "bin", "orbit-kb")
    r.check("t51c1-setup-kit-tree-has-orbit-kb", os.access(real_okb, os.X_OK), real_okb)
    swipl = shutil.which("swipl")
    if not swipl or not os.access(real_okb, os.X_OK):
        r.check("t51c1-setup-swipl-and-orbit-kb-to-run-the-case", False, (swipl, real_okb))
        return
    bindir = os.path.join(root, "t51c1-bin")  # orbit-kb and swipl, nothing else of the machine's PATH
    os.makedirs(bindir)
    os.symlink(real_okb, os.path.join(bindir, "orbit-kb"))
    os.symlink(swipl, os.path.join(bindir, "swipl"))
    tools = [os.path.dirname(x) for x in (shutil.which("env"), shutil.which("sh")) if x]
    p = subprocess.run([sys.executable, "-I", script, "--case", "case_real_orbit_kb"], capture_output=True, text=True,
                       cwd=hub, env=clean_env(os.pathsep.join([bindir] + tools)), timeout=600)
    r.check("t51c1-orbit-kb-on-path-runs-the-real-case", p.returncode == 0 and "PASS c2-real-query-open-question" in p.stdout
            and "SKIP" not in p.stdout and "FAIL" not in p.stdout, (p.returncode, p.stdout[-400:], p.stderr[-200:]))
    empty = os.path.join(root, "t51c1-empty")
    os.makedirs(empty)
    p = subprocess.run([sys.executable, "-I", script, "--case", "case_real_orbit_kb"], capture_output=True, text=True,
                       cwd=hub, env=clean_env(empty), timeout=600)
    lines = p.stdout.strip().splitlines()
    r.check("t51c1-no-orbit-kb-in-a-formal-hub-fails", p.returncode == 1 and any(x.startswith("FAIL c2-real-orbit-kb") for x in lines)
            and "SKIP" not in p.stdout, (p.returncode, p.stdout[-400:]))
    r.check("t51c1-last-line-counts-skips", bool(lines) and re.fullmatch(r"\d+ passed, \d+ failed, 1 skipped", lines[-1]) is not None,
            lines[-1:] )
    # an informal hub has no orbit-kb rules: the skip stays a skip
    ihub = os.path.join(root, "t51c1-informal")
    res = hk(r, "install", "--kit", KIT, "--hub", ihub, "--edition", "informal")
    p = subprocess.run([sys.executable, "-I", os.path.join(ihub, ".claude", "scripts", "hubflow-test.py"), "--case", "case_real_orbit_kb"],
                       capture_output=True, text=True, cwd=ihub, env=clean_env(empty), timeout=600)
    r.check("t51c1-informal-hub-skip-is-not-a-failure", res[0] == 0 and p.returncode == 0 and "SKIP c2-real-orbit-kb" in p.stdout
            and p.stdout.strip().splitlines()[-1].endswith("0 failed, 1 skipped"), (p.returncode, p.stdout[-300:]))


def case_t51_c2_step6_formal_git_add(r):
    """T51 c2: the commit step of INSTRUCTIONS has a formal git add line that names project-kb and specs; the informal
    line does not. (0.3.0 kit3, UAT U4: a formal step 6 makes the project KB, so the commit step is step 7 now.)"""
    with open(os.path.join(KIT, "INSTRUCTIONS.md"), encoding="utf-8") as f:
        text = f.read()
    m = re.search(r"^## Step 7: commit\n(.*?)^## Step 8", text, re.M | re.S)
    r.check("t51c2-step6-found", m is not None)
    body = m.group(1) if m else ""
    adds = [ln for ln in body.splitlines() if ln.startswith("git add ")]
    formal = [ln for ln in adds if "project-kb" in ln and "specs" in ln]
    plain = [ln for ln in adds if "project-kb" not in ln and "specs" not in ln]
    r.check("t51c2-step6-formal-add-names-project-kb-and-specs", len(formal) == 1, adds)
    r.check("t51c2-step6-informal-add-stays", len(plain) == 1 and ".claude" in plain[0], adds)
    r.check("t51c2-step6-says-which-edition", "formal" in body.lower(), body[:300])


def case_t51_c3_gitignore_locks(r, root):
    """T51 c3: the kit .gitignore ignores kb.lock and writer.lock, wherever an orbit-kb KB lies in the hub."""
    hub = os.path.join(root, "t51c3-hub")
    res = hk(r, "install", "--kit", KIT, "--hub", hub, "--edition", "formal")
    r.check("t51c3-setup-install-formal", res[0] == 0, res)
    g = subprocess.run(["git", "init", "-q", hub], capture_output=True, text=True)
    r.check("t51c3-setup-git-init", g.returncode == 0, g)
    for rel in ("specs/some-spec/kb.lock", "project-kb/writer.lock", "W0/analyses/a/kb/kb.lock", "flow/flow.db"):
        p = subprocess.run(["git", "-C", hub, "check-ignore", "-q", rel], capture_output=True, text=True)
        r.check("t51c3-ignored-" + rel.replace("/", "-"), p.returncode == 0, rel)
    p = subprocess.run(["git", "-C", hub, "check-ignore", "-q", "specs/some-spec/kb.pl"], capture_output=True, text=True)
    r.check("t51c3-kb-pl-not-ignored", p.returncode == 1, p)


# ---- install UX (discovery GO 2026-11-11) ----
REPO = os.path.dirname(KIT)
OKB_FILES = ("bin/orbit-kb", "bin/repo-map", "share/orbit-kb/core.pl", "share/orbit-kb/help/project.txt", "share/repo-map/README.md")


def case_iux_c3_copy_real_kit(r, root):
    """c3: a formal install copies the kit's orbit-kb (kb/bin/orbit-kb, kb/bin/repo-map, kb/share) to
    .claude/orbit-kb/ as engine files; an informal install does not."""
    hub = os.path.join(root, "iux-c3-formal")
    res = hk(r, "install", "--kit", KIT, "--hub", hub, "--edition", "formal")
    r.check("iux-c3-install-formal", res[0] == 0, res)
    got = {rel: os.path.join(hub, ".claude", "orbit-kb", rel) for rel in OKB_FILES}
    r.check("iux-c3-copy-byte-equal-to-the-kit", all(os.path.isfile(p) and sha(p) == sha(os.path.join(REPO, "kb", rel)) for rel, p in got.items()),
            [rel for rel, p in got.items() if not os.path.isfile(p)])
    r.check("iux-c3-copy-executable", all(os.access(got[x], os.X_OK) for x in ("bin/orbit-kb", "bin/repo-map")))
    share = sorted(os.path.relpath(os.path.join(b, f), os.path.join(REPO, "kb")) for b, _, fs in os.walk(os.path.join(REPO, "kb", "share")) for f in fs)
    files = manifest(hub).get("files", {}) if res[0] == 0 else {}
    r.check("iux-c3-manifest-lists-the-copy-as-engine", all(".claude/orbit-kb/" + x in files for x in ["bin/orbit-kb", "bin/repo-map"] + share), sorted(files)[:12])
    st = hk(r, "status", "--kit", KIT, "--hub", hub)
    r.check("iux-c3-status-copy-unchanged", st[0] == 0 and "unchanged\t\t.claude/orbit-kb/bin/orbit-kb" in st[1], st[1][-400:])
    ihub = os.path.join(root, "iux-c3-informal")
    res = hk(r, "install", "--kit", KIT, "--hub", ihub, "--edition", "informal")
    r.check("iux-c3-informal-has-no-copy", res[0] == 0 and not os.path.exists(os.path.join(ihub, ".claude", "orbit-kb"))
            and not any(k.startswith(".claude/orbit-kb/") for k in manifest(ihub).get("files", {})), res)


def fake_repo(root, name, version, okb_text):
    """A repo dir with hubkit/ (one engine file, CLAUDE.md owned) and kb/ (an orbit-kb copy source)."""
    repo = os.path.join(root, name)
    kit = os.path.join(repo, "hubkit")
    write(os.path.join(kit, "hub", "CORE.md"), "core\\n")
    write(os.path.join(kit, "hub", "CLAUDE.md"), "mine\\n")
    for rel, text in (("bin/orbit-kb", okb_text), ("bin/repo-map", "#!/usr/bin/env swipl\\n% repo-map\\n"),
                      ("share/orbit-kb/core.pl", "% core " + version + "\\n"), ("share/repo-map/README.md", "repo-map\\n")):
        write(os.path.join(repo, "kb", rel), text)
    for x in ("orbit-kb", "repo-map"):
        os.chmod(os.path.join(repo, "kb", "bin", x), 0o755)
    write(os.path.join(kit, "kit.json"), json.dumps({"version": version, "engine": ["CORE.md"], "owned": ["CLAUDE.md"],
                                                    "orbit_kb": {"from": "../kb", "to": ".claude/orbit-kb",
                                                                 "paths": ["bin/orbit-kb", "bin/repo-map", "share"]}}))
    return kit


def case_iux_c3_copy_upgrade(r, root):
    """c3: an upgrade replaces the orbit-kb copy with the new kit's; a switch to informal removes it."""
    v1 = fake_repo(root, "iux-repo1", "1.0.0", "#!/usr/bin/env swipl\\n% orbit-kb v1\\n")
    v2 = fake_repo(root, "iux-repo2", "1.1.0", "#!/usr/bin/env swipl\\n% orbit-kb v2\\n")
    hub = os.path.join(root, "iux-c3-up")
    res = hk(r, "install", "--kit", v1, "--hub", hub, "--edition", "formal")
    okb = os.path.join(hub, ".claude", "orbit-kb", "bin", "orbit-kb")
    r.check("iux-c3-fake-install", res[0] == 0 and os.path.isfile(okb) and "v1" in open(okb).read(), res)
    res = hk(r, "upgrade", "--kit", v2, "--hub", hub, "--yes")
    r.check("iux-c3-upgrade-replaces-the-copy", res[0] == 0 and "replace\t.claude/orbit-kb/bin/orbit-kb" in res[1]
            and "v2" in open(okb).read() and os.access(okb, os.X_OK)
            and manifest(hub)["files"].get(".claude/orbit-kb/share/orbit-kb/core.pl") == sha(os.path.join(root, "iux-repo2", "kb", "share", "orbit-kb", "core.pl")), res)
    res = hk(r, "edition", "--kit", v2, "--hub", hub, "informal", "--yes")
    r.check("iux-c3-switch-to-informal-removes-the-copy", res[0] == 0 and not os.path.exists(okb)
            and not any(k.startswith(".claude/orbit-kb/") for k in manifest(hub)["files"]), (res, manifest(hub)))


def case_iux_c3_default_edition(r, root):
    """c3: the human chooses formal at setup. With no --edition, install picks informal, also with an orbit-kb on PATH."""
    b = os.path.join(root, "iux-c3-path")
    write(os.path.join(b, "orbit-kb"), "#!/bin/sh\\nexit 0\\n")
    os.chmod(os.path.join(b, "orbit-kb"), 0o755)
    hub = os.path.join(root, "iux-c3-default")
    env = dict(os.environ, PATH=b + os.pathsep + os.environ.get("PATH", ""))
    p = subprocess.run([sys.executable, "-I", r.script, "install", "--kit", KIT, "--hub", hub], capture_output=True, text=True, env=env)
    r.check("iux-c3-default-is-informal-with-orbit-kb-on-path", p.returncode == 0 and manifest(hub).get("edition") == "informal",
            (p.returncode, p.stderr))


def case_iux_c3_installed_hub_runs_copy(r, root):
    """c3: an installed formal hub runs its tests and its project KB lint with its own orbit-kb, while an
    old orbit-kb (a stand-in that fails) is first on PATH. Needs swipl."""
    hub = os.path.join(root, "iux-c3-run")
    res = hk(r, "install", "--kit", KIT, "--hub", hub, "--edition", "formal")
    swipl = shutil.which("swipl")
    r.check("iux-c3-run-setup", res[0] == 0 and swipl is not None, (res, swipl))
    if res[0] != 0 or not swipl:
        return
    bindir = os.path.join(root, "iux-c3-run-bin")
    write(os.path.join(bindir, "orbit-kb"), "#!/bin/sh\\necho old orbit-kb >&2\\nexit 2\\n")
    os.chmod(os.path.join(bindir, "orbit-kb"), 0o755)
    os.symlink(swipl, os.path.join(bindir, "swipl"))
    tools = [os.path.dirname(x) for x in (shutil.which("env"), shutil.which("sh"), shutil.which("git")) if x]
    env = clean_env(os.pathsep.join([bindir] + tools))
    p = subprocess.run([sys.executable, "-I", os.path.join(hub, ".claude", "scripts", "hubflow-test.py"), "--case", "case_real_orbit_kb"],
                       capture_output=True, text=True, cwd=hub, env=env, timeout=600)
    r.check("iux-c3-installed-hub-tests-use-the-copy", p.returncode == 0 and "PASS c2-real-query-open-question" in p.stdout
            and "SKIP" not in p.stdout, (p.returncode, p.stdout[-400:], p.stderr[-200:]))
    okb = os.path.join(hub, ".claude", "orbit-kb", "bin", "orbit-kb")
    if not os.path.isfile(okb):
        r.check("iux-c3-copy-reads-its-own-share", False, "no copy at " + okb)
        return
    p = subprocess.run([okb, "init", "project-kb", "--request", "An invented request.", "--uses", "project"], capture_output=True, text=True, cwd=hub, env=env, timeout=120)
    p2 = subprocess.run([okb, "--dir", "project-kb", "lint"], capture_output=True, text=True, cwd=hub, env=env, timeout=120)
    r.check("iux-c3-copy-reads-its-own-share", p.returncode == 0 and p2.returncode == 0 and "Summary: 0 error(s)" in p2.stdout,
            (p.returncode, p.stderr[-200:], p2.stdout[-200:]))


def case_iux_c6_uat(r, root):
    """c6: install --uat records a UAT install in .hub-template.json, status shows it, and upgrade keeps it."""
    hub = os.path.join(root, "iux-c6-uat")
    res = hk(r, "install", "--kit", KIT, "--hub", hub, "--edition", "informal", "--uat")
    r.check("iux-c6-install-uat-records-it", res[0] == 0 and manifest(hub).get("uat") is True, (res, manifest(hub) if res[0] == 0 else None))
    st = hk(r, "status", "--kit", KIT, "--hub", hub)
    r.check("iux-c6-status-shows-uat", st[0] == 0 and "UAT install" in st[1].splitlines()[0], st[1][:200])
    m = manifest(hub)
    m["template_version"] = "0.0.1"
    with open(os.path.join(hub, ".hub-template.json"), "w", encoding="utf-8") as f:
        json.dump(m, f)
    res = hk(r, "upgrade", "--kit", KIT, "--hub", hub, "--yes")
    r.check("iux-c6-upgrade-keeps-uat", res[0] == 0 and manifest(hub).get("uat") is True, res)
    plain = os.path.join(root, "iux-c6-plain")
    res = hk(r, "install", "--kit", KIT, "--hub", plain, "--edition", "informal")
    st = hk(r, "status", "--kit", KIT, "--hub", plain)
    r.check("iux-c6-plain-install-is-not-uat", res[0] == 0 and not manifest(plain).get("uat") and "UAT" not in st[1], (res, st[1][:200]))


def case_k3_mindhole_version(r, root):
    """0.3.0 kit3, review finding 8: the kit's version line is "MindHole Kit <version>"; install, status and upgrade
    print it in that form."""
    v = json.load(open(os.path.join(KIT, "kit.json"), encoding="utf-8"))["version"]
    hub = os.path.join(root, "k3-mindhole-hub")
    res = hk(r, "install", "--kit", KIT, "--hub", hub, "--edition", "informal")
    r.check("k3-install-prints-MindHole-Kit-version", res[0] == 0 and f"installed MindHole Kit {v} " in res[1], res[1][:200])
    st = hk(r, "status", "--kit", KIT, "--hub", hub)
    first = (st[1].splitlines() or [""])[0]
    r.check("k3-status-prints-the-hub-and-the-kit-as-MindHole-Kit-versions",
            st[0] == 0 and f"hub from MindHole Kit {v} " in first and first.endswith(f"this kit MindHole Kit {v}"), first)
    up = hk(r, "upgrade", "--kit", KIT, "--hub", hub)
    r.check("k3-upgrade-prints-MindHole-Kit-versions", up[0] == 0 and f"upgrade MindHole Kit {v} -> MindHole Kit {v} " in up[1], up[1][:200])


def hk_home(r, home, *args):
    """hk with HOME set to a scratch dir: the launcher files (~/.claude/sagittarius) are the test's own."""
    env = dict(os.environ, HOME=home)
    p = subprocess.run([sys.executable, "-I", r.script] + [str(a) for a in args], capture_output=True, text=True, env=env)
    return p.returncode, p.stdout, p.stderr


def case_030_m_d_2_runs(r, root):
    """Sagittarius 0.3.0, c_m_d_2 (q_m_d_2 default: in .hub-template.json): a hub records which orbit-kb, which
    prompt and which pane files it runs, and `hubkit.py status` prints them. Ty: "Each mindhole can run its own
    version with its own orbit-kb". The prompt and the pane files are the ones of the kit's Sagittarius checkout,
    appended by the launcher from ~/.claude/sagittarius; status says whether the files there are still the same."""
    with open(os.path.join(REPO, "VERSION"), encoding="utf-8") as f:
        sag = f.read().strip()
    okb_v = open(os.path.join(REPO, "kb", "share", "orbit-kb", "VERSION"), encoding="utf-8").read().strip()
    home = os.path.join(root, "mdr-home")
    launch = os.path.join(home, ".claude", "sagittarius")
    shutil.copytree(os.path.join(REPO, "prompt"), launch)
    hub = os.path.join(root, "mdr-formal")
    res = hk_home(r, home, "install", "--kit", KIT, "--hub", hub, "--edition", "formal")
    r.check("mdr-setup-install-formal", res[0] == 0, res)
    runs = manifest(hub).get("runs") if res[0] == 0 else None
    runs = runs if isinstance(runs, dict) else {}
    okb = runs.get("orbit_kb") or {}
    r.check("mdr-manifest-records-the-orbit-kb", okb.get("command") == ".claude/orbit-kb/bin/orbit-kb" and okb.get("version") == okb_v, runs)
    pr = runs.get("prompt") or {}
    r.check("mdr-manifest-records-the-prompt", pr.get("file") == "~/.claude/sagittarius/SAGITTARIUS.md" and pr.get("version") == sag
            and pr.get("sha256") == sha(os.path.join(REPO, "prompt", "SAGITTARIUS.md")), runs)
    pn = runs.get("panes") or {}
    files = pn.get("files") or {}
    r.check("mdr-manifest-records-the-pane-files", pn.get("dir") == "~/.claude/sagittarius"
            and sorted(files) == ["PANES.md", "panes/build.md", "panes/discovery.md", "panes/review.md"]
            and files.get("panes/build.md") == sha(os.path.join(REPO, "prompt", "panes", "build.md")), runs)
    st = hk_home(r, home, "status", "--kit", KIT, "--hub", hub)
    out = st[1]
    r.check("mdr-status-names-the-orbit-kb", st[0] == 0 and f"runs orbit-kb: .claude/orbit-kb/bin/orbit-kb (orbit-kb {okb_v})" in out, out[:600])
    r.check("mdr-status-names-the-prompt-and-its-version",
            f"runs prompt: ~/.claude/sagittarius/SAGITTARIUS.md (Sagittarius {sag}); the file there: same" in out, out[:600])
    r.check("mdr-status-names-the-pane-files", "runs panes: ~/.claude/sagittarius/ PANES.md panes/build.md panes/discovery.md panes/review.md"
            " (Sagittarius " + sag + "); the files there: same" in out, out[:800])
    with open(os.path.join(launch, "SAGITTARIUS.md"), "a", encoding="utf-8") as f:
        f.write("\nThis is Sagittarius 9.9.9 (an invented later prompt).\n")
    os.remove(os.path.join(launch, "panes", "review.md"))
    out = hk_home(r, home, "status", "--kit", KIT, "--hub", hub)[1]
    r.check("mdr-status-says-the-prompt-there-differs", "the file there: differs (Sagittarius 9.9.9)" in out, out[:600])
    r.check("mdr-status-says-a-pane-file-there-is-missing", "the files there: missing panes/review.md" in out, out[:800])
    vfile = os.path.join(hub, ".claude", "orbit-kb", "share", "orbit-kb", "VERSION")
    with open(vfile, "w", encoding="utf-8") as f:
        f.write("9.9.9\n")
    out = hk_home(r, home, "status", "--kit", KIT, "--hub", hub)[1]
    r.check("mdr-status-reads-the-copy-version", f"runs orbit-kb: .claude/orbit-kb/bin/orbit-kb (orbit-kb {okb_v}; the copy now says 9.9.9)" in out, out[:600])
    shutil.copy(os.path.join(REPO, "kb", "share", "orbit-kb", "VERSION"), vfile)  # the copy as installed again
    # the informal edition runs no orbit-kb, no prompt and no pane files
    ihub = os.path.join(root, "mdr-informal")
    res = hk_home(r, home, "install", "--kit", KIT, "--hub", ihub, "--edition", "informal")
    iruns = manifest(ihub).get("runs") if res[0] == 0 else None
    r.check("mdr-informal-records-none", res[0] == 0 and iruns == {"orbit_kb": None, "prompt": None, "panes": None}, (res, iruns))
    out = hk_home(r, home, "status", "--kit", KIT, "--hub", ihub)[1]
    r.check("mdr-informal-status-says-none", "runs: no orbit-kb, no Sagittarius prompt, no pane files (informal edition)" in out, out[:400])
    # a hub made before this release records nothing: status says so, and the upgrade records it
    mf = manifest(hub)
    mf.pop("runs", None)
    with open(os.path.join(hub, ".hub-template.json"), "w", encoding="utf-8") as f:
        json.dump(mf, f)
    out = hk_home(r, home, "status", "--kit", KIT, "--hub", hub)[1]
    r.check("mdr-old-hub-status-says-not-recorded", "runs: not recorded (an upgrade to this kit records it)" in out, out[:400])
    res = hk_home(r, home, "upgrade", "--kit", KIT, "--hub", hub)
    r.check("mdr-dry-run-records-nothing", res[0] == 0 and "runs" not in manifest(hub), (res, manifest(hub).get("runs")))
    res = hk_home(r, home, "upgrade", "--kit", KIT, "--hub", hub, "--yes")
    r.check("mdr-upgrade-records-what-the-hub-runs", res[0] == 0 and ((manifest(hub).get("runs") or {}).get("prompt") or {}).get("version") == sag
            and f"runs: orbit-kb {okb_v}, Sagittarius {sag} prompt, 4 pane files" in res[1], (res, manifest(hub).get("runs")))
    # a kit outside a Sagittarius checkout (no prompt) still installs; the manifest records no prompt
    v1 = fake_repo(root, "mdr-repo", "1.0.0", "#!/usr/bin/env swipl\\n% orbit-kb\\n")
    fhub = os.path.join(root, "mdr-fake")
    res = hk_home(r, home, "install", "--kit", v1, "--hub", fhub, "--edition", "formal")
    fr = manifest(fhub).get("runs") if res[0] == 0 else None
    r.check("mdr-kit-without-prompt-installs", res[0] == 0 and isinstance(fr, dict) and fr.get("prompt") is None and fr.get("panes") is None
            and (fr.get("orbit_kb") or {}).get("command") == ".claude/orbit-kb/bin/orbit-kb", (res, fr))


def case_u2_mutants_stream(r):
    """0.3.0 kit3, UAT U2: hubflow-test.py --mutants prints and flushes one line per mutant as it ends, so a log
    that is a pipe or a file shows progress. Two mutants on one small case: the first mutant's line must reach
    the pipe well before the last line (the second mutant still runs then)."""
    flow = os.path.join(KIT, "hub", ".claude", "scripts", "hubflow-test.py")
    p = subprocess.Popen([sys.executable, "-I", flow, "--mutants", "--mutant", "lapse-threshold-28-to-27",
                          "--mutant", "prune-boundary-lt-to-le", "--case", "case_triage"],
                         stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    got = []
    t0 = time.monotonic()
    for ln in p.stdout:
        got.append((time.monotonic() - t0, ln.rstrip("\n")))
    p.wait()
    mut = [(s, ln) for s, ln in got if " mutant " in ln]
    r.check("u2-one-line-per-mutant", len(mut) == 2, [ln for _, ln in mut])
    last = got[-1][0] if got else 0
    r.check("u2-first-mutant-line-arrives-before-the-end", len(mut) == 2 and last - mut[0][0] > 0.5,
            [(round(s, 2), ln[:60]) for s, ln in mut] + [round(last, 2)])


def cases(r):
    root = tempfile.mkdtemp(prefix="hubkit-test-")
    try:
        if ONLY:
            for n in ONLY:
                fn = globals()[n]
                fn(r, root) if "root" in fn.__code__.co_varnames[:fn.__code__.co_argcount] else fn(r)
            return
        case_real_kit(r)
        hub = case_install(r, root)
        case_status_upgrade(r, root, hub)
        case_t48_version_moves_with_schema(r, root)
        case_t51_c1_installed_hub_orbit_kb(r, root)
        case_t51_c2_step6_formal_git_add(r)
        case_t51_c3_gitignore_locks(r, root)
        case_iux_c3_copy_real_kit(r, root)
        case_iux_c3_copy_upgrade(r, root)
        case_iux_c3_default_edition(r, root)
        case_iux_c3_installed_hub_runs_copy(r, root)
        case_iux_c6_uat(r, root)
        case_k3_mindhole_version(r, root)
        case_030_m_d_2_runs(r, root)
        if r.script == REAL:  # it tests hubflow-test.py, not hubkit.py: the mutants of hubkit.py do not change it
            case_u2_mutants_stream(r)
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
    args = sys.argv[1:]
    for i, a in enumerate(args):
        if a == "--case":
            if i + 1 >= len(args) or not args[i + 1].startswith("case_") or args[i + 1] not in globals():
                print("usage: hubkit-test.py [--mutants] [--case case_NAME ...]")
                sys.exit(1)
            ONLY.append(args[i + 1])
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

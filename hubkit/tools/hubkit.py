#!/usr/bin/env python3
"""hubkit.py -- install the MindHole Kit (the hub template) into a new hub, and upgrade a hub to a newer release.

usage: hubkit.py COMMAND --hub DIR [--kit DIR] [--yes]
  install --hub DIR [--edition informal|formal] [--uat]
                               copy every template file into DIR and write DIR/.hub-template.json,
                               which records the edition. Default: informal; the human chooses
                               formal (the PATH plays no part). --uat records a UAT install: one
                               that tests the kit itself (INSTRUCTIONS.md step 3). Refuses if DIR
                               already has a manifest, or if any target file exists
  status --hub DIR             each shipped (engine) file: unchanged, modified, or deleted since it
                               was installed, and whether this kit's version of it differs; the
                               first line names the edition, and a UAT install; the `runs` lines
                               name what the hub runs (below)
  upgrade --hub DIR [--yes]    plan an upgrade to this kit's version; a dry run without --yes
  done --hub DIR PATH ...      mark pending merges as finished
  edition --hub DIR [informal|formal] [--yes]
                               print the hub's edition; with a name, switch to it: an upgrade plan
                               to that edition of this kit (a dry run without --yes)

--kit DIR is the template checkout (default: the directory above this script).

Editions. The formal edition is the hub/ tree. The informal edition (no Prolog, Lean or orbit-kb in
its rules) takes the files that kit.json lists under "editions"."informal" from editions/informal/,
and every other file from hub/. The manifest records the edition; upgrade keeps it. A hub whose
manifest names no edition (made before editions, all formal then) gets the formal edition when
orbit-kb is on the PATH of this machine, else informal; the upgrade says so.

The hub's own orbit-kb (formal edition). kit.json "orbit_kb" names the orbit-kb that this kit was
tested with: "paths" under "from" (relative to the kit dir; ../kb in a Sagittarius checkout) are
copied to "to" in the hub (.claude/orbit-kb/bin/orbit-kb, bin/repo-map, share/...). They are engine
files of a formal hub: an upgrade replaces them, and a switch to informal removes them. hubflow.py,
the skills and HUB-CORE.md run that copy, never an orbit-kb on the PATH.

What a hub runs (Sagittarius 0.3.0, c_m_d_2). Each MindHole (hub) runs its own pinned version: install and
upgrade --yes record in .hub-template.json "runs" which orbit-kb (the copy above and the version in its
share/orbit-kb/VERSION), which prompt (kit.json "prompt": the file that the pane launcher appends,
~/.claude/sagittarius/SAGITTARIUS.md, with the Sagittarius version and sha256 of the kit's own copy) and
which pane files (PANES.md and panes/<role>.md, with their sha256) it was set up with. status prints them,
and says whether the files at the launcher path are still the same. An informal hub runs none of them.
A kit outside a Sagittarius checkout (no kit.json "prompt" source) records no prompt.

Two kinds of file, listed in the kit's kit.json:
  engine  shipped files that a hub should not edit (HUB-CORE.md, scripts, shipped skills). The
          manifest records the sha256 of each as installed. An upgrade replaces an engine file the
          hub did not change, and leaves a changed one in `pending` for the agent to merge by hand,
          following UPGRADING.md.
  owned   files the hub owns from the first day (CLAUDE.md, HEURISTICS.md, seed.json, ...). An upgrade
          never changes them. It copies a new owned file only if the hub has no file at that path.

Upgrade actions per engine file (hub state against the manifest, and whether the kit changed it):
  unchanged + kit changed  -> replace         modified + kit changed  -> merge (pending)
  unchanged + kit same     -> keep            modified + kit same     -> keep (local change)
  deleted                  -> skip (report)   new in the kit          -> add (merge if the path exists)
  dropped by the kit       -> remove if unchanged, else merge (pending)

Exit codes: 0 ok, 1 bad input or a refused rule, 2 hub state (no manifest, already installed,
merges pending).
"""
import hashlib, json, os, re, shutil, sys

MANIFEST = ".hub-template.json"
EDITIONS = ("informal", "formal")


def die(code, msg):
    print(f"hubkit: ERROR: {msg}", file=sys.stderr)
    sys.exit(code)


def sha(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def load_kit(kit):
    p = os.path.join(kit, "kit.json")
    if not os.path.exists(p):
        die(1, f"no kit.json in {kit}")
    with open(p, encoding="utf-8") as f:
        k = json.load(f)
    for key in ("version", "engine", "owned"):
        if key not in k:
            die(1, f"kit.json has no {key}")
    for rel in k["engine"] + k["owned"]:
        if not os.path.isfile(os.path.join(kit, "hub", rel)):
            die(1, f"kit.json lists {rel}, which is not in {kit}/hub")
    for ed, rels in k.get("editions", {}).items():
        for rel in rels:
            if rel not in k["engine"] + k["owned"] or not os.path.isfile(os.path.join(kit, "editions", ed, rel)):
                die(1, f"kit.json edition {ed} lists {rel}, which is not a kit file in {kit}/editions/{ed}")
    return k


def okb_sources(kit, k):
    """{hub path: kit source path} of the hub's own orbit-kb: every file under each of kit.json
    orbit_kb.paths (a file or a directory, relative to orbit_kb.from), at orbit_kb.to in the hub."""
    o = k.get("orbit_kb")
    if not o:
        return {}
    base = os.path.normpath(os.path.join(kit, o["from"]))
    out = {}
    for rel in o["paths"]:
        p = os.path.join(base, rel)
        if os.path.isdir(p):
            for b, dirs, files in os.walk(p):
                dirs[:] = sorted(d for d in dirs if d != "__pycache__")
                for f in sorted(files):
                    full = os.path.join(b, f)
                    out[o["to"] + "/" + os.path.relpath(full, base).replace(os.sep, "/")] = full
        else:
            out[o["to"] + "/" + rel] = p
    return out


def engine_files(kit, k, edition):
    """The engine files of an `edition` hub: kit.json engine, and in the formal edition the hub's own orbit-kb."""
    files = list(k["engine"])
    if edition == "formal":  # the hub's own orbit-kb (install UX c3)
        okb = okb_sources(kit, k)
        missing = [p for p in okb.values() if not os.path.isfile(p)]
        if k.get("orbit_kb") and (missing or not okb):
            die(1, f"a formal hub needs the kit's orbit-kb, and {missing[0] if missing else k['orbit_kb']['from']} is missing; "
                   "use the kit inside its Sagittarius checkout (kit.json orbit_kb.from)")
        files += sorted(okb)
    return files


def src(kit, k, edition, rel):
    """The kit file that an `edition` hub gets at rel."""
    okb = okb_sources(kit, k)
    if rel in okb:
        return okb[rel]
    if rel in k.get("editions", {}).get(edition, []):
        return os.path.join(kit, "editions", edition, rel)
    return os.path.join(kit, "hub", rel)


def kit_shas(kit, k, edition):
    return {r: sha(src(kit, k, edition, r)) for r in engine_files(kit, k, edition)}


def default_edition():
    """The edition install picks when none is named: informal. The human chooses formal at setup;
    which orbit-kb the PATH holds plays no part (the formal hub runs its own copy)."""
    return "informal"  # install UX c3: the human chooses formal


def legacy_edition():
    """The edition of a hub made before editions (all were formal then): formal when orbit-kb is on
    the PATH here, else informal. Only for a manifest that records no edition."""
    return "formal" if shutil.which("orbit-kb") else "informal"


def edition_of(m):
    """The recorded edition. A hub made before editions records none: legacy_edition()."""
    return m.get("edition") or legacy_edition()


SAG_LINE = re.compile(r"This is Sagittarius (\d+\.\d+\.\d+)")


def prompt_version(path):
    """The Sagittarius version that the last such line of a prompt file names, or None."""
    try:
        with open(path, encoding="utf-8") as f:
            found = SAG_LINE.findall(f.read())
    except OSError:
        return None
    return found[-1] if found else None


def okb_version(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read().strip() or None
    except OSError:
        return None


def runs_of(kit, k, edition):
    """What a hub of this kit runs (c_m_d_2): the orbit-kb copy, the prompt and the pane files. An
    informal hub runs none of them; a kit with no prompt source records no prompt and no pane files."""
    if edition != "formal":
        return {"orbit_kb": None, "prompt": None, "panes": None}
    runs = {"orbit_kb": None, "prompt": None, "panes": None}
    o = k.get("orbit_kb")
    if o:
        okb = okb_sources(kit, k)
        vrel = o["to"] + "/share/orbit-kb/VERSION"
        runs["orbit_kb"] = {"command": o["to"] + "/bin/orbit-kb", "version": okb_version(okb[vrel]) if vrel in okb else None}
    pc = k.get("prompt")
    base = os.path.normpath(os.path.join(kit, pc["from"])) if pc else None
    if pc and os.path.isfile(os.path.join(base, pc["prompt"])):
        main = os.path.join(base, pc["prompt"])
        runs["prompt"] = {"file": pc["launcher"].rstrip("/") + "/" + pc["prompt"], "version": prompt_version(main), "sha256": sha(main)}
        files = {}
        for rel in pc["panes"]:
            p = os.path.join(base, rel)
            if os.path.isdir(p):
                for f in sorted(os.listdir(p)):
                    if f.endswith(".md"):
                        files[rel + "/" + f] = sha(os.path.join(p, f))
            elif os.path.isfile(p):
                files[rel] = sha(p)
        runs["panes"] = {"dir": pc["launcher"].rstrip("/"), "files": files}
    return runs


def runs_lines(hub, m):
    """The `runs` lines of status: what the manifest records, and how the files are now."""
    if "runs" not in m:
        return ["runs: not recorded (an upgrade to this kit records it)"]
    r = m["runs"] or {}
    if not any(r.get(x) for x in ("orbit_kb", "prompt", "panes")):
        return ["runs: no orbit-kb, no Sagittarius prompt, no pane files (" + edition_of(m) + " edition)"]
    out = []
    okb = r.get("orbit_kb")
    if okb:
        now = okb_version(os.path.join(hub, os.path.dirname(os.path.dirname(okb["command"])), "share", "orbit-kb", "VERSION"))
        out.append(f"runs orbit-kb: {okb['command']} (orbit-kb {okb.get('version') or 'version unknown'}"
                   + ("" if now == okb.get("version") else f"; the copy now says {now or 'no version'}") + ")")
    else:
        out.append("runs orbit-kb: none")
    pr = r.get("prompt")
    if pr:
        there = os.path.expanduser(pr["file"])
        if not os.path.isfile(there):
            state = "missing"
        else:
            want = pr.get("sha256")
            same = sha(there) == want  # the launcher file now (c_m_d_2)
            state = "same" if same else f"differs (Sagittarius {prompt_version(there) or 'version unknown'})"
        out.append(f"runs prompt: {pr['file']} (Sagittarius {pr.get('version') or 'version unknown'}); the file there: {state}")
    else:
        out.append("runs prompt: not known (the kit has no Sagittarius prompt)")
    pn = r.get("panes")
    if pn:
        d = os.path.expanduser(pn["dir"])
        missing = [x for x in sorted(pn["files"]) if not os.path.isfile(os.path.join(d, x))]
        differ = [x for x in sorted(pn["files"]) if x not in missing and sha(os.path.join(d, x)) != pn["files"][x]]
        state = "; ".join(([f"missing {' '.join(missing)}"] if missing else []) + ([f"differs {' '.join(differ)}"] if differ else [])) or "same"
        ver = (pr or {}).get("version") or "version unknown"
        out.append(f"runs panes: {pn['dir']}/ {' '.join(sorted(pn['files']))} (Sagittarius {ver}); the files there: {state}")
    return out


def runs_summary(runs):
    if not any(runs.get(x) for x in ("orbit_kb", "prompt", "panes")):
        return "runs: no orbit-kb, no Sagittarius prompt, no pane files"
    okb, pr, pn = runs.get("orbit_kb"), runs.get("prompt"), runs.get("panes")
    return ("runs: " + (f"orbit-kb {okb.get('version') or 'version unknown'}" if okb else "no orbit-kb") + ", "
            + (f"Sagittarius {pr.get('version') or 'version unknown'} prompt" if pr else "no prompt") + ", "
            + f"{len(pn['files']) if pn else 0} pane files (recorded in {MANIFEST})")


def load_manifest(hub):
    p = os.path.join(hub, MANIFEST)
    if not os.path.exists(p):
        die(2, f"no {MANIFEST} in {hub}; run install, or see UPGRADING.md for a hub made before the manifest")
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def save_manifest(hub, m):
    p = os.path.join(hub, MANIFEST)
    with open(p + ".tmp", "w", encoding="utf-8", newline="\n") as f:
        json.dump(m, f, indent=2, sort_keys=True)
        f.write("\n")
    os.replace(p + ".tmp", p)


def copy(kit, k, edition, hub, rel):
    dst = os.path.join(hub, rel)
    os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
    shutil.copy(src(kit, k, edition, rel), dst)  # keeps the mode bits


def remove(hub, rel):
    """Remove an engine file, and the directories that it leaves empty (up to the hub root)."""
    p = os.path.join(hub, rel)
    os.remove(p)
    d = os.path.dirname(p)
    while os.path.abspath(d) != os.path.abspath(hub) and os.path.isdir(d) and not os.listdir(d):
        os.rmdir(d)
        d = os.path.dirname(d)


def parse(argv):
    o = {"kit": os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "hub": None, "yes": False, "paths": [],
         "edition": None, "uat": False}
    a = list(argv)
    while a:
        x = a.pop(0)
        if x in ("--hub", "--kit", "--edition"):
            if not a:
                die(1, f"{x} needs a value")
            o[x[2:]] = a.pop(0)
        elif x == "--yes":
            o["yes"] = True
        elif x == "--uat":
            o["uat"] = True
        elif x.startswith("-"):
            die(1, f"unknown option {x}")
        else:
            o["paths"].append(x)
    if not o["hub"]:
        die(1, "--hub DIR is required")
    o["hub"] = os.path.abspath(o["hub"])
    o["kit"] = os.path.abspath(o["kit"])
    if o["edition"] is not None and o["edition"] not in EDITIONS:
        die(1, "--edition must be one of " + ", ".join(EDITIONS))
    return o


def cmd_install(o):
    k = load_kit(o["kit"])
    hub = o["hub"]
    if os.path.exists(os.path.join(hub, MANIFEST)):
        die(2, f"{hub} already has {MANIFEST}; use upgrade")
    ed = o["edition"] or default_edition()
    engine = engine_files(o["kit"], k, ed)
    clash = [rel for rel in engine + k["owned"] if os.path.exists(os.path.join(hub, rel))]
    if clash:  # install never overwrites
        die(1, "these files already exist; nothing was written: " + ", ".join(clash))
    for rel in engine + k["owned"]:
        copy(o["kit"], k, ed, hub, rel)
    m = {"template_version": k["version"], "edition": ed,
         "files": {r: sha(os.path.join(hub, r)) for r in engine},
         "owned": sorted(k["owned"]), "pending": []}
    if o["uat"]:
        m["uat"] = True  # a UAT install: it tests the kit itself (INSTRUCTIONS.md step 3)
    m["runs"] = runs_of(o["kit"], k, ed)  # what the hub runs (c_m_d_2)
    save_manifest(hub, m)
    print(f"installed MindHole Kit {k['version']} ({ed} edition{', UAT install' if o['uat'] else ''}) into {hub}: "
          f"{len(engine)} engine, {len(k['owned'])} owned files")


def state_of(hub, rel, recorded):
    p = os.path.join(hub, rel)
    if not os.path.exists(p):
        return "deleted"
    return "unchanged" if sha(p) == recorded else "modified"


def cmd_status(o):
    k = load_kit(o["kit"])
    m = load_manifest(o["hub"])
    print(f"hub from MindHole Kit {m['template_version']} ({edition_of(m)} edition{', UAT install' if m.get('uat') else ''}); this kit MindHole Kit {k['version']}")
    for line in runs_lines(o["hub"], m):
        print(line)
    kit_files = kit_shas(o["kit"], k, edition_of(m))
    for rel in sorted(set(m["files"]) | set(kit_files)):
        if rel not in m["files"]:
            print(f"new-in-kit\t\t{rel}")
            continue
        st = state_of(o["hub"], rel, m["files"][rel])
        if rel not in kit_files:
            note = "dropped-by-kit"
        else:
            note = "kit-differs" if kit_files[rel] != m["files"][rel] else ""
        print(f"{st}\t{note}\t{rel}")
    for p in m.get("pending", []):
        print(f"pending\tmerge {p['from']} -> {p['to']}\t{p['path']}")


def cmd_upgrade(o, edition=None):
    k = load_kit(o["kit"])
    hub, yes = o["hub"], o["yes"]
    m = load_manifest(hub)
    if m.get("pending"):
        die(2, "merges are pending from the last upgrade: " + ", ".join(p["path"] for p in m["pending"])
            + "; finish them and run `done` first")
    old, new = m["template_version"], k["version"]
    ed = edition or edition_of(m)  # an upgrade keeps the hub's edition
    kit_files = kit_shas(o["kit"], k, ed)
    plan = []  # (action, path)
    for rel in sorted(set(m["files"]) | set(kit_files)):
        if rel not in m["files"]:
            plan.append(("merge" if os.path.exists(os.path.join(hub, rel)) else "add", rel))
            continue
        state = state_of(hub, rel, m["files"][rel])
        if rel not in kit_files:
            plan.append({"unchanged": ("remove", rel), "modified": ("merge", rel), "deleted": ("skip", rel)}[state])
            continue
        changed = kit_files[rel] != m["files"][rel]
        if state == "deleted":
            plan.append(("skip", rel))
        elif state == "modified" and changed:  # merge, never overwrite
            plan.append(("merge", rel))
        elif state == "unchanged" and changed:
            plan.append(("replace", rel))
        else:
            plan.append(("keep", rel))
    known_owned = set(m.get("owned", []))
    for rel in k["owned"]:
        if rel not in known_owned:
            dst = os.path.join(hub, rel)
            if not os.path.exists(dst):  # owned: copy only if absent
                plan.append(("add-owned", rel))
            else:
                plan.append(("keep-owned", rel))
    print(f"upgrade MindHole Kit {old} -> MindHole Kit {new} ({ed} edition)" + ("" if yes else " (dry run; --yes applies it)"))
    if not m.get("edition") and not edition:
        print(f"note: this hub records no edition; it gets the {ed} edition, as a hub made before editions gets it here"
              f" ({'orbit-kb is on the PATH' if ed == 'formal' else 'this hub has no orbit-kb'}); to change it: hubkit.py edition --hub HUB "
              f"{'informal' if ed == 'formal' else 'formal'}")
    for action, rel in plan:
        if action != "keep":
            print(f"{action}\t{rel}")
    if not yes:  # dry run
        return
    for action, rel in plan:
        if action in ("replace", "add", "add-owned"):
            copy(o["kit"], k, ed, hub, rel)
        elif action == "remove":
            remove(hub, rel)
    pending = [{"path": rel, "from": old, "to": new} for action, rel in plan if action == "merge"]
    m["template_version"] = new
    m["edition"] = ed  # recorded, so the next upgrade keeps it
    m["files"] = kit_files
    m["owned"] = sorted(known_owned | set(k["owned"]))
    m["pending"] = pending  # merges left for the agent
    m["runs"] = runs_of(o["kit"], k, ed)
    save_manifest(hub, m)
    print(runs_summary(m["runs"]))
    print(f"done: {len(pending)} merge(s) pending; follow UPGRADING.md for each, then `hubkit.py done PATH`")


def cmd_done(o):
    m = load_manifest(o["hub"])
    if not o["paths"]:
        die(1, "done needs at least one PATH")
    have = {p["path"] for p in m.get("pending", [])}
    bad = [p for p in o["paths"] if p not in have]
    if bad:
        die(1, "not pending: " + ", ".join(bad))
    m["pending"] = [p for p in m["pending"] if p["path"] not in o["paths"]]
    save_manifest(o["hub"], m)
    print(f"{len(o['paths'])} merge(s) marked done; {len(m['pending'])} pending")


def cmd_edition(o):
    m = load_manifest(o["hub"])
    if not o["paths"]:
        print(edition_of(m))
        return
    if len(o["paths"]) != 1 or o["paths"][0] not in EDITIONS:
        die(1, "edition takes one of " + ", ".join(EDITIONS))
    cmd_upgrade(o, edition=o["paths"][0])


def main():
    a = sys.argv[1:]
    if not a or a[0] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0 if a else 1)
    cmds = {"install": cmd_install, "status": cmd_status, "upgrade": cmd_upgrade, "done": cmd_done, "edition": cmd_edition}
    if a[0] not in cmds:
        die(1, "command must be one of " + ", ".join(cmds))
    cmds[a[0]](parse(a[1:]))


if __name__ == "__main__":
    main()

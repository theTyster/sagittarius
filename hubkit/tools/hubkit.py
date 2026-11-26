#!/usr/bin/env python3
"""hubkit.py -- install the MindHole Kit (the hub template) into a new hub, and upgrade a hub to a newer release.

usage: hubkit.py COMMAND --hub DIR [--kit DIR] [--yes]
  install --hub DIR [--uat]    copy every template file into DIR and write DIR/.hub-template.json.
                               --uat records a UAT install: one that tests the kit itself
                               (INSTRUCTIONS.md step 3). Refuses if DIR already has a manifest, or
                               if any target file exists. `--edition formal` is still taken: it
                               names the one kind of hub that the kit makes
  status --hub DIR             each shipped (engine) file: unchanged, modified, or deleted since it
                               was installed, and whether this kit's version of it differs; the
                               first line names the edition, and a UAT install; the `runs` lines
                               name what the hub runs (below)
  upgrade --hub DIR [--yes] [--seen-migrations DIGEST]
                               plan an upgrade to this kit's version; a dry run without --yes.
                               In a hub whose orbit-kb changes, the dry run also prints the
                               migration preview (kb-migrations c15, c19): for each spec KB, closed
                               ones too, this kit's `orbit-kb migrate plan --old` the hub's orbit-kb,
                               so each verdict that the new engine changes is seen before it lands,
                               and a preview digest. --yes then needs --seen-migrations DIGEST of the
                               preview as it is now, and refuses an upgrade whose preview names a
                               change outside the declared reach of a migration
                               The preview opens with a summary that the tool computes (spec KBs, verdicts
                               that differ, writes, the KBs that change); the digest is that of the full
                               preview. The tool makes no model call (preview-reducer c5).
  done --hub DIR PATH ...      mark pending merges as finished
  edition --hub DIR [formal] [--yes]
                               print the edition that the hub's manifest records. `edition formal`
                               moves a hub that records the edition "informal" to this kit: an
                               upgrade plan (a dry run without --yes)

--kit DIR is the template checkout (default: the directory above this script).

One kind of hub (MindHole Kit 0.12.0; Ty, 2026-11-23). A hub needs the tool: every hub gets the hub/
tree and its own orbit-kb. The manifest still records "edition": "formal", the name of this kind of
hub since kit 0.5.0, and a manifest that names no edition (a hub made before kit 0.5.0) is read as
formal. Kits 0.4.0 to 0.11.2 also made a hub with no tool, the edition "informal". That release
ended in 0.12.0: install refuses the name, and upgrade refuses a hub whose manifest records it, with
one line that says what to install and which command moves the hub (UPGRADING.md, section 0.12.0).

The hub's own orbit-kb. kit.json "orbit_kb" names the orbit-kb that this kit was tested with:
"paths" under "from" (relative to the kit dir; ../kb in a Sagittarius checkout) are copied to "to"
in the hub (.claude/orbit-kb/bin/orbit-kb, bin/orbit, bin/repo-map, share/...). They are engine
files: an upgrade replaces them. hubflow.py, the skills and HUB-CORE.md run that copy, never an
orbit-kb on the PATH. bin/orbit is the same program under its new name (Sagittarius 0.8.0: `orbit`
is the door to every store). "fallback" names the source of a path that the kit's tool does not
hold: a kit whose kb/bin has no `orbit` installs bin/orbit as a copy of bin/orbit-kb.

What a hub runs (Sagittarius 0.3.0, c_m_d_2). Each MindHole (hub) runs its own pinned version: install and
upgrade --yes record in .hub-template.json "runs" which orbit-kb (the copy above and the version in its
share/orbit-kb/VERSION), which prompt (kit.json "prompt": the file that the pane launcher appends,
~/.claude/sagittarius/SAGITTARIUS.md, with the Sagittarius version and sha256 of the kit's own copy) and
which pane files (PANES.md and panes/<role>.md, with their sha256) it was set up with. status prints them,
and says whether the files at the launcher path are still the same.
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
EDITIONS = ("formal",)  # the one kind of hub; the manifest keeps the name
ENDED = "informal"  # the edition with no tool: kits 0.4.0 to 0.11.2 made it
ENDED_LINE = ('the release for a hub with no tool (the edition "informal") ended in MindHole Kit 0.12.0: a hub needs the tool. '
              "Install SWI-Prolog 9 or later (`swipl` on the PATH)")


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
        alt = o.get("fallback", {}).get(rel)
        if alt and not os.path.exists(p):  # the kit's tool has no such file: the same program under its other name
            p = os.path.join(base, alt)
        if os.path.isdir(p):
            for b, dirs, files in os.walk(p):
                dirs[:] = sorted(d for d in dirs if d != "__pycache__")
                for f in sorted(files):
                    full = os.path.join(b, f)
                    out[o["to"] + "/" + os.path.relpath(full, base).replace(os.sep, "/")] = full
        else:
            out[o["to"] + "/" + rel] = p
    return out


def engine_files(kit, k):
    """The engine files of a hub: kit.json engine, and the hub's own orbit-kb."""
    files = list(k["engine"])
    okb = okb_sources(kit, k)
    missing = [p for p in okb.values() if not os.path.isfile(p)]
    if k.get("orbit_kb") and (missing or not okb):
        die(1, f"a hub needs the kit's orbit-kb, and {missing[0] if missing else k['orbit_kb']['from']} is missing; "
               "use the kit inside its Sagittarius checkout (kit.json orbit_kb.from)")
    files += sorted(okb)  # the hub's own orbit-kb (install UX c3)
    return files


def src(kit, k, rel):
    """The kit file that a hub gets at rel."""
    okb = okb_sources(kit, k)
    if rel in okb:
        return okb[rel]
    return os.path.join(kit, "hub", rel)


def kit_shas(kit, k):
    return {r: sha(src(kit, k, r)) for r in engine_files(kit, k)}


def edition_of(m):
    """The recorded edition. A hub made before kit 0.5.0 records none: it is formal, as every hub was then."""
    return m.get("edition") or "formal"


def ended_line(hub):
    """The one line for a hub whose manifest records the ended edition: what to install, which command moves it."""
    return (ENDED_LINE + f", then run `hubkit.py edition --hub {hub} formal` (a dry run; --yes applies it): the hub gets its own"
            " orbit-kb, the tool. UPGRADING.md, section 0.12.0, gives the steps")


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


def runs_of(kit, k):
    """What a hub of this kit runs (c_m_d_2): the orbit-kb copy, the prompt and the pane files. A kit
    with no prompt source records no prompt and no pane files."""
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


def kit_modules(kit):
    """modules.py of the kit's Sagittarius checkout (module-versions c7), or None when the kit has none."""
    path = os.path.join(os.path.dirname(os.path.abspath(kit)), "modules.py")
    if not os.path.isfile(path):
        return None
    import importlib.util
    spec = importlib.util.spec_from_file_location("sagittarius_modules", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def modules_of(kit):
    """{name: {version, digest, installed}} of the kit's release and of what this machine runs (c7)."""
    mm = kit_modules(kit)
    return mm.record(os.path.dirname(os.path.abspath(kit))) if mm else {}


def installed_lines(entry, skip_release):
    """One line per link of a module: where it points, the version there, and whether it is the release code."""
    out = []
    for i in (entry or {}).get("installed", []):
        if i.get("source") is None:
            out.append(f"  installed {i['link']}: missing")
        elif not (skip_release and i.get("release")):
            out.append(f"  installed {i['link']} -> {i['source']} ({entry.get('name', '')}{' ' if entry.get('name') else ''}"
                       f"{i.get('version') or 'version unknown'} there; "
                       + ("the files of this kit's release)" if i.get("release") else "not the files of this kit's release)"))
    return out


def module_lines(old, new):
    """The upgrade's lines per module (c7): recorded version -> the kit's, and each link that is not the release code."""
    out = []
    for name, e in new.items():
        was = ((old or {}).get(name) or {}).get("version")
        v = e.get("version") or "no version"
        if old is None or name not in old:
            out.append(f"module {name} not recorded -> {v}")
        elif was == e.get("version"):
            out.append(f"module {name} {v} (same)")
        else:
            out.append(f"module {name} {was or 'no version'} -> {v}")
        out += installed_lines(dict(e, name=name), skip_release=True)
    return out


def status_module_lines(kit, m):
    if "modules" not in m:
        return ["modules: not recorded (an upgrade to this kit records them)"]
    now = modules_of(kit)
    out = []
    for name, e in m["modules"].items():
        k = (now.get(name) or {}).get("version")
        out.append(f"module {name} {e.get('version') or 'no version'} (recorded); this kit {k or 'has no such module'}")
        out += installed_lines(dict(now.get(name) or e, name=name), skip_release=False)
    return out


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


def copy(kit, k, hub, rel):
    dst = os.path.join(hub, rel)
    os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
    shutil.copy(src(kit, k, rel), dst)  # keeps the mode bits


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
         "edition": None, "uat": False, "seen-migrations": None}
    a = list(argv)
    while a:
        x = a.pop(0)
        if x in ("--hub", "--kit", "--edition", "--seen-migrations"):
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
    if o["edition"] == ENDED:  # the edition with no tool ended in 0.12.0 (Ty, 2026-11-23)
        die(1, ENDED_LINE + "; the kit makes one kind of hub, with its own orbit-kb (leave out --edition)")
    if o["edition"] is not None and o["edition"] not in EDITIONS:
        die(1, "--edition must be " + ", ".join(EDITIONS))
    return o


def cmd_install(o):
    k = load_kit(o["kit"])
    hub = o["hub"]
    if os.path.exists(os.path.join(hub, MANIFEST)):
        die(2, f"{hub} already has {MANIFEST}; use upgrade")
    ed = "formal"  # the one kind of hub; the manifest keeps the name
    engine = engine_files(o["kit"], k)
    clash = [rel for rel in engine + k["owned"] if os.path.exists(os.path.join(hub, rel))]
    if clash:  # install never overwrites
        die(1, "these files already exist; nothing was written: " + ", ".join(clash))
    for rel in engine + k["owned"]:
        copy(o["kit"], k, hub, rel)
    m = {"template_version": k["version"], "edition": ed,
         "files": {r: sha(os.path.join(hub, r)) for r in engine},
         "owned": sorted(k["owned"]), "pending": []}
    if o["uat"]:
        m["uat"] = True  # a UAT install: it tests the kit itself (INSTRUCTIONS.md step 3)
    m["runs"] = runs_of(o["kit"], k)  # what the hub runs (c_m_d_2)
    m["modules"] = modules_of(o["kit"])  # module-versions c7: the module versions and what the machine runs
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
    if m.get("edition") == ENDED:  # status still reads such a hub; upgrade refuses it
        print("note: " + ended_line(o["hub"]))
    for line in runs_lines(o["hub"], m):
        print(line)
    for line in status_module_lines(o["kit"], m):
        print(line)
    kit_files = kit_shas(o["kit"], k)
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


OKB_REL = ".claude/orbit-kb/bin/orbit-kb"


def hub_kbs(hub):
    """c19 (review a166): every KB of the hub: [(label, ref slug, dir)]. A spec KB at specs/<slug>
    (label kb:<slug>), and a KB of the form before 0.3.0 under W0..W5/analyses/<slug>/ at any depth
    (label kb:W<n>/analyses/..., ref slug <slug>), as HUB-CORE says the old form still resolves. A dot
    directory (a shadow of migrate plan) is skipped."""
    out = []
    specs = os.path.join(hub, "specs")
    if os.path.isdir(specs):
        for d in sorted(os.listdir(specs)):
            if not d.startswith(".") and os.path.isfile(os.path.join(specs, d, "kb.pl")):
                out.append((f"kb:{d}", d, os.path.join(specs, d)))
    for n in range(6):
        an = os.path.join(hub, f"W{n}", "analyses")
        if not os.path.isdir(an):
            continue
        for b, dirs, files in os.walk(an):
            dirs[:] = sorted(x for x in dirs if not x.startswith("."))
            if "kb.pl" in files and b != an:
                rel = os.path.relpath(b, hub).replace(os.sep, "/")
                slug = os.path.relpath(b, an).replace(os.sep, "/").split("/")[0]
                out.append((f"kb:{rel}", slug, b))
    return out


def closed_slugs(hub):
    """c9, c19 (review a166): the kb ref slugs whose every ledger item (a summary aside) is closed, read
    from flow/flow.db read-only, so a hub whose hubflow has no kb-state (kit 0.9.0) is read too. A ref
    <slug>/<path> counts for <slug>. None when the ledger cannot be read: then nothing is called closed."""
    import sqlite3
    db = os.path.join(hub, "flow", "flow.db")
    if not os.path.isfile(db):
        return None
    try:
        c = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
        try:
            rows = c.execute("SELECT r.ref, i.status FROM item_ref r JOIN item i ON i.id = r.item_id"
                             " WHERE r.kind = 'kb' AND i.kind <> 'summary'").fetchall()
        finally:
            c.close()
    except sqlite3.Error:
        return None
    seen, opened = set(), set()
    for ref, st in rows:
        if ref.startswith(("/", "~")):
            continue
        slug = ref.split("/")[0]
        seen.add(slug)
        if st in ("open", "waiting"):
            opened.add(slug)
    return seen - opened


def migration_preview(o, k, hub, plan):
    """kb-migrations c15, c19: the verdicts that the new engine changes are seen before it lands. In a
    hub whose orbit-kb is replaced, run this kit's orbit-kb `migrate plan --old` the hub's orbit-kb
    on each KB of the hub (hub_kbs: specs/ and the old W*/analyses form), closed ones too, a closed one
    labeled (closed_slugs). Returns (lines, digest, bad): the preview, the sha256 of it, and the labels
    whose plan refuses (an undeclared change, or a plan that does not run). None when there is nothing
    to preview."""
    import subprocess
    if not any(act in ("replace", "add") and rel.startswith(".claude/orbit-kb/") for act, rel in plan):
        return None  # the hub's orbit-kb does not change: no verdict changes with this upgrade
    new = okb_sources(o["kit"], k).get(OKB_REL)
    old = os.path.join(hub, OKB_REL)
    kbs = hub_kbs(hub)
    if not new or not os.path.isfile(new) or not os.access(old, os.X_OK) or not kbs:
        return None
    env = {x: v for x, v in os.environ.items() if not x.startswith("ORBIT_KB")}
    closed = closed_slugs(hub)
    lines, bad, recs = [], [], []
    if closed is None:
        lines.append("(the ledger flow/flow.db cannot be read: no KB is marked closed)")
    for label, slug, d in kbs:
        # c19 (Ty, q20: "Include closed KBs"): a closed KB is previewed too, since a new engine changes
        # how it reads; a migration still writes nothing to it (c9)
        try:
            r = subprocess.run([new, "--dir", d, "migrate", "plan", "--old", old],
                               capture_output=True, text=True, timeout=600, env=env, cwd=hub)
            rc, out = r.returncode, r.stdout
        except (OSError, subprocess.SubprocessError) as e:
            rc, out = 2, f"the plan did not run: {e}"
        keep = [x for x in out.splitlines()
                if x.startswith(("Reach of S", "  ", "Verdicts", "REFUSED", "Nothing to write", "apply refuses"))]
        lines.append(label + (" (closed: previewed; no migration writes to it)" if closed and slug in closed else "")
                     + ("" if rc == 0 else f" (plan exit {rc})"))
        lines += ["  " + x for x in keep] or ["  (no output)"]
        if rc != 0:
            bad.append(label)
        recs.append(preview_record(label, slug, rc, keep))
    digest = "sha256:" + hashlib.sha256("\n".join(lines).encode("utf-8")).hexdigest()
    return lines, digest, bad, recs


def preview_record(label, slug, rc, keep):
    """preview-reducer c1: what the tool says about one KB, from the lines of its plan that the preview keeps:
    differs (the verdicts that the new engine changes), writes (a tool step, a new question or a write is to
    do: no 'Nothing to write.'), refused (the plan refuses or does not run)."""
    differs = any(x.startswith("Verdicts that differ") for x in keep)
    refused = rc != 0 or any(x.startswith(("REFUSED", "apply refuses")) for x in keep)
    writes = not any(x.startswith("Nothing to write") for x in keep) and not refused
    return {"label": label, "slug": slug, "differs": differs, "writes": writes, "refused": refused,
            "changes": differs or writes or refused}


def preview_summary(recs, nlines):
    """preview-reducer c1, c2: the counts that the tool computes with no model, then what the summary leaves out.
    The digest that the human confirms is the digest of the full preview, not of this summary."""
    n = len(recs)
    diff = [r for r in recs if r["differs"]]
    writes = [r for r in recs if r["writes"]]
    refused = [r for r in recs if r["refused"]]
    changed = [r for r in recs if r["changes"]]
    quiet = n - len(changed)
    out = [f"summary (computed by the tool, no model): {n} spec KBs; verdicts differ: {len(diff)}; "
           f"new open items or writes: {len(writes)}; plan refused: {len(refused)}; nothing to write: {n - len(writes) - len(refused)}.",
           f"KBs with nothing to change: {quiet} of {n}." if quiet else "Every KB changes.",
           "KBs that change: " + (", ".join(r["slug"] for r in changed) if changed else "none") + ".",
           f"Full preview below ({nlines} lines): it names every spec KB, closed ones too, with the declared changes and the "
           "reach of each. This summary leaves those out. The preview digest below is the digest of the full preview.",
           "preview summary: " + json.dumps({"kbs": n, "verdicts_differ": len(diff), "writes": len(writes),
                                             "refused": len(refused), "unchanged": quiet,
                                             "changed": [r["slug"] for r in changed]}, sort_keys=True)]
    return out


def cmd_upgrade(o, edition=None):
    k = load_kit(o["kit"])
    hub, yes = o["hub"], o["yes"]
    m = load_manifest(hub)
    if m.get("pending"):
        die(2, "merges are pending from the last upgrade: " + ", ".join(p["path"] for p in m["pending"])
            + "; finish them and run `done` first")
    old, new = m["template_version"], k["version"]
    if m.get("edition") == ENDED and edition != "formal":  # refuse the ended edition (c22): one line, nothing copied
        die(2, f"{hub} records the edition \"{ENDED}\": " + ended_line(hub) + "; nothing was copied")
    ed = "formal"  # the one kind of hub
    kit_files = kit_shas(o["kit"], k)
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
    if not m.get("edition"):
        print("note: this hub records no edition (it was made before kit 0.5.0); the upgrade records it as formal, and the hub"
              " gets its own orbit-kb")
    for action, rel in plan:
        if action != "keep":
            print(f"{action}\t{rel}")
    mods = modules_of(o["kit"])
    for line in module_lines(m.get("modules"), mods):
        print(line)
    pv = migration_preview(o, k, hub, plan)
    if pv:
        lines, digest, bad, recs = pv
        print("migration preview (kb-migrations c15, c19): the new orbit-kb against the hub's, on each spec KB, closed ones too")
        for x in preview_summary(recs, len(lines)):
            print(x)
        for x in lines:
            print(x)
        print(f"preview digest: {digest}")
    if not yes:  # dry run
        if pv:
            print(f"show the preview to the human; then: hubkit.py upgrade --hub HUB --yes --seen-migrations {pv[1]}")
        return
    if pv:
        lines, digest, bad, recs = pv
        if bad:
            die(1, "refused: the migration plan of " + ", ".join(bad) + " names a change outside the declared reach, or does"
                   " not run; nothing was copied. Fix the migration of the kit (or the KB), then upgrade again")
        if o.get("seen-migrations") != digest:
            die(1, "refused: --seen-migrations must give the preview digest of the dry run as it is now"
                   f" ({digest}); nothing was copied. Run the dry run, show the preview to the human, then --yes"
                   " --seen-migrations DIGEST")
    for action, rel in plan:
        if action in ("replace", "add", "add-owned"):
            copy(o["kit"], k, hub, rel)
        elif action == "remove":
            remove(hub, rel)
    pending = [{"path": rel, "from": old, "to": new} for action, rel in plan if action == "merge"]
    m["template_version"] = new
    m["edition"] = ed  # recorded, so the next upgrade keeps it
    m["files"] = kit_files
    m["owned"] = sorted(known_owned | set(k["owned"]))
    m["pending"] = pending  # merges left for the agent
    m["runs"] = runs_of(o["kit"], k)
    m["modules"] = modules_of(o["kit"])  # module-versions c7: upgrade records them
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
    if o["paths"] == [ENDED]:  # no hub goes back to the edition with no tool
        die(1, ENDED_LINE + "; no hub is switched to that edition")
    if len(o["paths"]) != 1 or o["paths"][0] not in EDITIONS:
        die(1, "edition takes " + ", ".join(EDITIONS))
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

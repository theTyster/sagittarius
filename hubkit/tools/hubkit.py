#!/usr/bin/env python3
"""hubkit.py -- install the hub template into a new hub, and upgrade a hub to a newer template.

usage: hubkit.py COMMAND --hub DIR [--kit DIR] [--yes]
  install --hub DIR            copy every template file into DIR and write DIR/.hub-template.json.
                               Refuses if DIR already has a manifest, or if any target file exists
  status --hub DIR             each shipped (engine) file: unchanged, modified, or deleted since it
                               was installed, and whether this kit's version of it differs
  upgrade --hub DIR [--yes]    plan an upgrade to this kit's version; a dry run without --yes
  done --hub DIR PATH ...      mark pending merges as finished

--kit DIR is the template checkout (default: the directory above this script).

Two kinds of file, listed in the kit's kit.json:
  engine  shipped files that a hub should not edit (HUB-CORE.md, scripts, shipped skills). The
          manifest records the sha256 of each as installed. An upgrade replaces an engine file the
          hub did not change, and leaves a changed one in `pending` for the agent to merge by hand,
          following UPGRADING.md.
  owned   files the hub owns from the first day (CLAUDE.md, HEURISTICS.md, ROLES, ...). An upgrade
          never changes them. It copies a new owned file only if the hub has no file at that path.

Upgrade actions per engine file (hub state against the manifest, and whether the kit changed it):
  unchanged + kit changed  -> replace         modified + kit changed  -> merge (pending)
  unchanged + kit same     -> keep            modified + kit same     -> keep (local change)
  deleted                  -> skip (report)   new in the kit          -> add (merge if the path exists)
  dropped by the kit       -> remove if unchanged, else merge (pending)

Exit codes: 0 ok, 1 bad input or a refused rule, 2 hub state (no manifest, already installed,
merges pending).
"""
import hashlib, json, os, shutil, sys

MANIFEST = ".hub-template.json"


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


def copy(kit, hub, rel):
    dst = os.path.join(hub, rel)
    os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
    shutil.copy(os.path.join(kit, "hub", rel), dst)  # keeps the mode bits


def parse(argv):
    o = {"kit": os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "hub": None, "yes": False, "paths": []}
    a = list(argv)
    while a:
        x = a.pop(0)
        if x in ("--hub", "--kit"):
            if not a:
                die(1, f"{x} needs a value")
            o[x[2:]] = a.pop(0)
        elif x == "--yes":
            o["yes"] = True
        elif x.startswith("-"):
            die(1, f"unknown option {x}")
        else:
            o["paths"].append(x)
    if not o["hub"]:
        die(1, "--hub DIR is required")
    o["hub"] = os.path.abspath(o["hub"])
    o["kit"] = os.path.abspath(o["kit"])
    return o


def cmd_install(o):
    k = load_kit(o["kit"])
    hub = o["hub"]
    if os.path.exists(os.path.join(hub, MANIFEST)):
        die(2, f"{hub} already has {MANIFEST}; use upgrade")
    clash = [rel for rel in k["engine"] + k["owned"] if os.path.exists(os.path.join(hub, rel))]
    if clash:  # install never overwrites
        die(1, "these files already exist; nothing was written: " + ", ".join(clash))
    for rel in k["engine"] + k["owned"]:
        copy(o["kit"], hub, rel)
    save_manifest(hub, {"template_version": k["version"], "files": {r: sha(os.path.join(hub, r)) for r in k["engine"]},
                        "owned": sorted(k["owned"]), "pending": []})
    print(f"installed template {k['version']} into {hub}: {len(k['engine'])} engine, {len(k['owned'])} owned files")


def state_of(hub, rel, recorded):
    p = os.path.join(hub, rel)
    if not os.path.exists(p):
        return "deleted"
    return "unchanged" if sha(p) == recorded else "modified"


def cmd_status(o):
    k = load_kit(o["kit"])
    m = load_manifest(o["hub"])
    print(f"hub template {m['template_version']}; this kit {k['version']}")
    kit_files = {r: sha(os.path.join(o["kit"], "hub", r)) for r in k["engine"]}
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


def cmd_upgrade(o):
    k = load_kit(o["kit"])
    hub, yes = o["hub"], o["yes"]
    m = load_manifest(hub)
    if m.get("pending"):
        die(2, "merges are pending from the last upgrade: " + ", ".join(p["path"] for p in m["pending"])
            + "; finish them and run `done` first")
    old, new = m["template_version"], k["version"]
    kit_files = {r: sha(os.path.join(o["kit"], "hub", r)) for r in k["engine"]}
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
    print(f"upgrade {old} -> {new}" + ("" if yes else " (dry run; --yes applies it)"))
    for action, rel in plan:
        if action != "keep":
            print(f"{action}\t{rel}")
    if not yes:  # dry run
        return
    for action, rel in plan:
        if action in ("replace", "add", "add-owned"):
            copy(o["kit"], hub, rel)
        elif action == "remove":
            os.remove(os.path.join(hub, rel))
    pending = [{"path": rel, "from": old, "to": new} for action, rel in plan if action == "merge"]
    m["template_version"] = new
    m["files"] = kit_files
    m["owned"] = sorted(known_owned | set(k["owned"]))
    m["pending"] = pending  # merges left for the agent
    save_manifest(hub, m)
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


def main():
    a = sys.argv[1:]
    if not a or a[0] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0 if a else 1)
    cmds = {"install": cmd_install, "status": cmd_status, "upgrade": cmd_upgrade, "done": cmd_done}
    if a[0] not in cmds:
        die(1, "command must be one of " + ", ".join(cmds))
    cmds[a[0]](parse(a[1:]))


if __name__ == "__main__":
    main()

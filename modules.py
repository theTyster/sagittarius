#!/usr/bin/env python3
"""The modules of Sagittarius and their versions (spec KB module-versions, c6, c7, c2).

MODULES.json, beside this file, lists each module that Sagittarius ships:

    name      the module's name
    version   the file that holds its version: "PATH" (the whole file is the version) or
              "PATH#KEY" (the key of a JSON file)
    covers    the files of the module, as paths under the repo root
    except    paths under `covers` that belong to another module
    installs  {link in the home directory: the path in the repo that it points to}; install.py
              makes these links

One version per module, in its own source. docs/check_modules.py holds each version to the files
it covers; install.py prints the version beside each link; hubkit.py records the versions in a
mindhole, with what each link on the machine points to.

Usage: python3 modules.py          print "NAME VERSION" for each module
Standard library only.
"""
import hashlib
import json
import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SKIP_DIRS = {"__pycache__", "node_modules", ".lake", ".git"}


def load(root=ROOT):
    """The modules of MODULES.json under ROOT, in their order, or [] when there is no such file."""
    p = os.path.join(root, "MODULES.json")
    if not os.path.isfile(p):
        return []
    with open(p, encoding="utf-8") as f:
        return json.load(f)["modules"]


def parse_version(text, key):
    """The version in TEXT: the whole text, or the KEY of a JSON object. None when there is none."""
    if text is None:
        return None
    if key:
        try:
            v = json.loads(text).get(key)
        except (ValueError, AttributeError):
            return None
        return v if isinstance(v, str) and v.strip() else None
    return text.strip() or None


def version(root, spec):
    """The version that SPEC ("PATH" or "PATH#KEY") names in the tree at ROOT, or None."""
    path, _, key = spec.partition("#")
    try:
        with open(os.path.join(root, path), encoding="utf-8") as f:
            return parse_version(f.read(), key)
    except OSError:
        return None


def semver(v):
    """(MAJOR, MINOR, PATCH) of a version X.Y.Z, or None."""
    parts = (v or "").split(".")
    if len(parts) != 3 or not all(p.isdigit() for p in parts):
        return None
    return tuple(int(p) for p in parts)


def digest(path, skip=()):
    """sha256 of the files at PATH (a file, or a folder walked in sorted order), each by its path
    relative to PATH and its bytes. SKIP: relative paths left out (the parts of another module).
    Build output (__pycache__, node_modules, .lake, .git, *.pyc) is left out. None when PATH is missing."""
    if os.path.isfile(path):
        with open(path, "rb") as f:
            return "sha256:" + hashlib.sha256(f.read()).hexdigest()
    if not os.path.isdir(path):
        return None
    h = hashlib.sha256()
    skip = {os.path.normpath(s) for s in skip}
    for base, dirs, files in os.walk(path):
        rel_base = os.path.relpath(base, path)
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS
                         and os.path.normpath(os.path.join(rel_base, d)) not in skip)
        for name in sorted(files):
            if name.endswith(".pyc"):
                continue
            rel = os.path.normpath(os.path.join(rel_base, name))
            if rel in skip:
                continue
            h.update(rel.replace(os.sep, "/").encode() + b"\0")
            with open(os.path.join(base, name), "rb") as f:
                h.update(hashlib.sha256(f.read()).digest())
    return "sha256:" + h.hexdigest()


def skip_of(mod, rel):
    """The `except` paths of MOD that lie under REL, relative to REL."""
    out = []
    for e in mod.get("except", []):
        r = os.path.relpath(e, rel)
        if not r.startswith(".."):
            out.append(r)
    return out


def installs(mod):
    """[(link, repo path)] of MOD: the links that install.py makes for it."""
    return sorted((mod.get("installs") or {}).items())


def state(mod, link, rel, root=ROOT):
    """What LINK (a link of MOD to REL) points to on this machine now: {link, source, version, digest,
    release}. source: the real path that the link reaches (None when the link is missing). version: the
    version in the tree of that source, when the source ends with REL. release: the files at the source
    have the digest of REL in ROOT, the release code."""
    path = os.path.expanduser(link)
    want = digest(os.path.join(root, rel), skip_of(mod, rel))
    if not os.path.lexists(path):
        return {"link": link, "source": None, "version": None, "digest": None, "release": False}
    src = os.path.realpath(path)
    got = digest(src, skip_of(mod, rel))
    ver = None
    tail = os.path.normpath(rel)
    if src == tail or src.endswith(os.sep + tail):
        ver = version(src[: len(src) - len(tail)].rstrip(os.sep) or os.sep, mod["version"])
    return {"link": link, "source": src, "version": ver, "digest": got, "release": got is not None and got == want}


def record(root=ROOT):
    """{name: {version, digest, installed: [state of each link]}} for each module under ROOT."""
    out = {}
    for mod in load(root):
        covers = mod.get("covers", [])
        rel = covers[0] if len(covers) == 1 else None
        entry = {"version": version(root, mod["version"])}
        if rel is not None:
            entry["digest"] = digest(os.path.join(root, rel), skip_of(mod, rel))
        ins = [state(mod, link, r, root) for link, r in installs(mod)]
        if ins:
            entry["installed"] = ins
        out[mod["name"]] = entry
    return out


def link_module(root=ROOT):
    """{link: (module name, version)} for every link of every module under ROOT."""
    out = {}
    for mod in load(root):
        for link, _ in installs(mod):
            out[link] = (mod["name"], version(root, mod["version"]))
    return out


def main(argv):
    if argv:
        print("usage: modules.py", file=sys.stderr)
        return 2
    for mod in load():
        print(f"{mod['name']} {version(ROOT, mod['version']) or 'no version'}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

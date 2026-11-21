#!/usr/bin/env python3
"""module-versions c6: a module whose files changed since the last release has a higher version.

MODULES.json lists each module, the file that holds its version, and the files it covers
(modules.py says how). The last release is the highest tag vX.Y.Z that HEAD contains (a tag with a
suffix, such as v0.1.0-experiment, is not a release). For each module:

  - it must have a version X.Y.Z now;
  - if any file it covers (less its `except` paths) differs between the tag and the working tree,
    its version must be higher than its version at the tag. A module with no version at the tag
    is new, and passes.

Usage: python3 docs/check_modules.py [--since REF]
Exit 0: every module passes. Exit 1: a module fails (each failure is printed). Exit 2: no git, or
no release tag and no --since.
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
import modules  # noqa: E402


def git(*a):
    return subprocess.run(["git", "-C", ROOT, *a], capture_output=True, text=True)


def last_release():
    r = git("tag", "--merged", "HEAD")
    if r.returncode != 0:
        return None
    tags = [t for t in r.stdout.split() if t.startswith("v") and modules.semver(t[1:])]
    return max(tags, key=lambda t: modules.semver(t[1:])) if tags else None


def version_at(ref, spec):
    path, _, key = spec.partition("#")
    for _ in range(8):  # follow a symbolic link in the tree (kb/share/orbit-kb/VERSION links to VERSION)
        t = git("ls-tree", ref, "--", path).stdout.split()
        if not t or t[0] != "120000":
            break
        target = git("show", f"{ref}:{path}").stdout
        path = os.path.normpath(os.path.join(os.path.dirname(path), target)).replace(os.sep, "/")
    r = git("show", f"{ref}:{path}")
    return modules.parse_version(r.stdout if r.returncode == 0 else None, key)


def changed(ref, mod):
    paths = list(mod.get("covers", [])) + [f":(exclude){e}" for e in mod.get("except", [])]
    r = git("diff", "--quiet", ref, "--", *paths)
    if r.returncode not in (0, 1):
        raise RuntimeError(r.stderr.strip())
    if r.returncode == 1:
        return True
    # files that git does not track yet count too: a new file is a change
    u = git("ls-files", "--others", "--exclude-standard", "--", *paths)
    return bool(u.stdout.strip())


def main(argv):
    ref = None
    if argv[:1] == ["--since"] and len(argv) == 2:
        ref = argv[1]
    elif argv:
        print("usage: check_modules.py [--since REF]", file=sys.stderr)
        return 2
    ref = ref or last_release()
    if not ref:
        print("check_modules: no release tag vX.Y.Z in the history of HEAD; give --since REF", file=sys.stderr)
        return 2
    bad = []
    mods = modules.load(ROOT)
    if not mods:
        bad.append("MODULES.json lists no module")
    for mod in mods:
        name, now = mod["name"], modules.version(ROOT, mod["version"])
        if not modules.semver(now):
            bad.append(f"{name}: no version X.Y.Z in {mod['version']} (found {now!r})")
            continue
        then = version_at(ref, mod["version"])
        if not modules.semver(then):
            print(f"new      {name} {now} (no version at {ref})")
            continue
        if changed(ref, mod):
            if modules.semver(now) <= modules.semver(then):
                bad.append(f"{name}: its files changed since {ref}, and its version {now} is not higher than {then} there")
            else:
                print(f"bumped   {name} {then} -> {now}")
        elif modules.semver(now) < modules.semver(then):
            bad.append(f"{name}: version {now} is lower than {then} at {ref}")
        elif now != then:
            print(f"moved    {name} {then} -> {now} (its files did not change; its version file is shared)")
        else:
            print(f"same     {name} {now}")
    for b in bad:
        print("FAIL " + b)
    if not bad:
        print(f"modules PASS: each module changed since {ref} has a higher version")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

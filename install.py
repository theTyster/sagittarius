#!/usr/bin/env python3
"""Link Sagittarius into the home directory. Safe to run again.

    ~/.local/bin/orbit-kb     -> kb/bin/orbit-kb
    ~/.local/bin/repo-map     -> kb/bin/repo-map
    ~/.local/share/orbit-kb   -> kb/share/orbit-kb
    ~/.claude/sagittarius     -> prompt/  (holds SAGITTARIUS.md)
    ~/.claude/sagittarius-s1  -> s1/      (the System 1 hook goes where the prompt goes)
    ~/.claude/skills/s1-glance -> s1/glance/ (the Sagittarius Signals mod; every session loads it)
    ~/.claude/skills/desk-toast -> hubkit/hub/.claude/scripts/desk-toast/ (the Desk toast mod, beside
                                  desk.py; every session loads it)

Usage: ./install.py          create or fix the links
       ./install.py --check  report each link; exit 1 if any is not OK

Both print the version that they act on ("Sagittarius X.Y.Z", from the file VERSION) first, and
beside each link the module that it installs and its version (MODULES.json names them; modules.py).
A link that points elsewhere is reported with the version found there.

The same on Linux, macOS, and Windows (standard library only). A link that
already points here is left alone. A link that points elsewhere is replaced,
and the old target is printed. A real file or directory is never replaced:
remove it yourself, then run this again. After an update, run it again: a release can
add a link, and --check then reports it as missing.

On Windows, making a symlink needs Developer Mode or an elevated shell.
"""
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent
HOME = Path.home()
sys.path.insert(0, str(REPO))
import modules  # noqa: E402  (module-versions c2: MODULES.json names each link and its module)

MODS = modules.load(str(REPO))
LINKS = [(Path(os.path.expanduser(link)), REPO / rel, mod) for mod in MODS for link, rel in modules.installs(mod)]


def version():
    """The version of Sagittarius: the file VERSION (one source; docs/check_version.py holds the rest to it)."""
    try:
        return (REPO / "VERSION").read_text(encoding="utf-8").strip() or "unknown"
    except OSError:
        return "unknown"


def link_target(dst):
    return Path(os.readlink(dst)) if dst.is_symlink() else None


def main(argv):
    if argv not in ([], ["--check"]):
        print("usage: install.py [--check]", file=sys.stderr)
        return 2
    check = argv == ["--check"]
    bad = 0
    print(f"Sagittarius {version()}" + (" (checked)" if check else ""))
    for dst, src, mod in LINKS:
        tag = f" ({mod['name']} {modules.version(str(REPO), mod['version']) or 'no version'})"
        old = link_target(dst)
        if old == src:
            print(f"ok       {dst}{tag}")
        elif old is None and dst.exists():
            print(f"blocked  {dst} is a real file or directory; remove it, then run again",
                  file=sys.stderr)
            bad = 1
        elif check:
            if old:
                st = modules.state(mod, str(dst), os.path.relpath(src, REPO), str(REPO))
                there = f"{mod['name']} {st['version'] or 'version unknown'} there, " + (
                    "the same files as this checkout" if st["release"] else "not the files of this checkout")
                print(f"wrong    {dst} -> {old} ({there}){tag}")
            else:
                print(f"missing  {dst}{tag}")
            bad = 1
        else:
            if old is not None:
                print(f"replace  {dst} (was -> {old})")
                try:
                    dst.unlink()
                except OSError:  # a directory symlink on Windows
                    os.rmdir(dst)
            dst.parent.mkdir(parents=True, exist_ok=True)
            try:
                dst.symlink_to(src, target_is_directory=src.is_dir())
            except OSError as e:
                print(f"failed   {dst}: {e}", file=sys.stderr)
                if os.name == "nt":
                    print("         Turn on Developer Mode, or run from an elevated shell.",
                          file=sys.stderr)
                bad = 1
                continue
            print(f"linked   {dst} -> {src}{tag}")
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

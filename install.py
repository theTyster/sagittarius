#!/usr/bin/env python3
"""Link Sagittarius into the home directory. Safe to run again.

    ~/.local/bin/orbit-kb     -> kb/bin/orbit-kb
    ~/.local/share/orbit-kb   -> kb/share/orbit-kb
    ~/.claude/sagittarius     -> prompt/  (holds SAGITTARIUS.md)

Usage: ./install.py          create or fix the links
       ./install.py --check  report each link; exit 1 if any is not OK

The same on Linux, macOS, and Windows (standard library only). A link that
already points here is left alone. A link that points elsewhere is replaced,
and the old target is printed. A real file or directory is never replaced:
remove it yourself, then run this again.

On Windows, making a symlink needs Developer Mode or an elevated shell.
"""
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent
HOME = Path.home()
LINKS = [
    (HOME / ".local" / "bin" / "orbit-kb", REPO / "kb" / "bin" / "orbit-kb"),
    (HOME / ".local" / "share" / "orbit-kb", REPO / "kb" / "share" / "orbit-kb"),
    (HOME / ".claude" / "sagittarius", REPO / "prompt"),
]


def link_target(dst):
    return Path(os.readlink(dst)) if dst.is_symlink() else None


def main(argv):
    if argv not in ([], ["--check"]):
        print("usage: install.py [--check]", file=sys.stderr)
        return 2
    check = argv == ["--check"]
    bad = 0
    for dst, src in LINKS:
        old = link_target(dst)
        if old == src:
            print(f"ok       {dst}")
        elif old is None and dst.exists():
            print(f"blocked  {dst} is a real file or directory; remove it, then run again",
                  file=sys.stderr)
            bad = 1
        elif check:
            print(f"wrong    {dst} -> {old}" if old else f"missing  {dst}")
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
            print(f"linked   {dst} -> {src}")
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

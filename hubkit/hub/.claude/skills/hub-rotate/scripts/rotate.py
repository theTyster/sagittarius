#!/usr/bin/env python3
"""rotate.py -- the mechanical half of the weekly hub rotation (Python 3 and git; no shell).

  rotate.py [--hub PATH] [--leave PATH ...] [--dry-run]
  rotate.py [--hub PATH] --verify      # re-run step 5 alone, e.g. right before the commit

What it does, in order:
  1. Pre-flight. Refuses if anything is staged, or if any path inside W0/..W5/ is modified or
     untracked and is not at or under a --leave path. Refuses if W5/ holds anything that is not
     tracked (it would survive `git rm` and collide with the W4 -> W5 rename), or if a --leave
     path is inside W5/ (W5 retires; nothing can be carried out of it).
  2. Captures `git ls-files -s` (path + mode + blob) before.
  3. `git rm -r -q W5`, then `git mv` W4->W5, W3->W4, W2->W3, W1->W2, W0->W1, then `mkdir W0`.
     `git mv` of a directory is a filesystem rename, so untracked --leave files move with their
     directory, and modified tracked --leave files keep their working-tree edits unstaged.
  4. Reports exactly what happened to each --leave path.
  5. Verifies, two ways. (a) Every `git diff --cached -M100% --name-status` entry is checked per
     path against the mapping: its index entry must be exactly HEAD's entry for the path the
     mapping lands there, or it must be gone with nothing mapped onto it (the old W5/, and the
     W0..W4 sources). Git's own R/C pairing label is not trusted, because the hub carries identical
     blobs in several weeks and a re-occupied path (W1/x -> W2/x over an old W2/x) shows as M.
     (b) The whole index must equal HEAD under the mapping, blob and mode for blob and mode.
     Exits 3 if either fails. Nothing is ever retired except the old W5/.

It never commits. The caller commits the index as it stands, WITHOUT a pathspec: `git commit --
<paths>` commits the working-tree state of those paths, which would sweep the unstaged edits of
every modified --leave file into the mechanical commit. Run `rotate.py --verify` immediately
before, so a peer session's staged files cannot ride along unseen.
Exit codes: 0 ok, 1 usage, 2 pre-flight refused, 3 verification failed.

The Python port of rotate.sh (hub kit 0.6.0): the same refusals, renames, reports and exit codes.
"""
import os
import re
import shutil
import subprocess
import sys
from collections import defaultdict


def say(*a):
    print(" ".join(str(x) for x in a), flush=True)


def err(msg):
    print(msg, file=sys.stderr, flush=True)


def refuse(msg):
    err(f"REFUSED: {msg}")
    sys.exit(2)


def git(*args, check=True):
    """Run git; return stdout (text, bytes kept as surrogates). A failure exits 1 (check) or returns None."""
    p = subprocess.run(["git"] + list(args), capture_output=True)
    if p.returncode != 0:
        if not check:
            return None
        sys.stderr.write(p.stderr.decode("utf-8", "surrogateescape"))
        sys.exit(1)
    return p.stdout.decode("utf-8", "surrogateescape")


def git_ok(*args):
    return subprocess.run(["git"] + list(args), capture_output=True).returncode == 0


def count(text):
    """The line count, as `wc -l` gives it."""
    return text.count("\n")


def map_path(p):
    """Map one hub-relative path through the rotation. None for a path under the old W5/."""
    m = re.match(r"^W([0-5])(/.*)?$", p)
    if not m:
        return p
    n = int(m.group(1))
    return None if n == 5 else f"W{n + 1}{m.group(2) or ''}"


def under(p, leave):
    return any(p == x or p.startswith(x + "/") for x in leave)


def parse_entries(text, fields):
    d = {}
    for line in text.splitlines():
        meta, path = line.split("\t", 1)
        parts = meta.split()
        mode, blob = (parts[0], parts[1]) if fields == "index" else (parts[0], parts[2])
        d[path] = (mode, blob)
    return d


def verify():
    say("== verify")
    p = subprocess.run(["git", "-c", "diff.renameLimit=1", "diff", "--cached", "-M100%", "--name-status"], capture_output=True)
    name_status = p.stdout.decode("utf-8", "surrogateescape")
    after = parse_entries(git("ls-files", "-s"), "index")
    before = parse_entries(git("ls-tree", "-r", "--full-tree", "HEAD"), "tree")  # before = HEAD, i.e. the pre-rotation commit

    # (a) name-status classification.
    # Each entry is checked PER PATH against the mapping, not by git's pairing label: the hub carries the
    # same blob in several weeks (copied analyses), so which source git pairs an R or C with is arbitrary,
    # and a path re-occupied by the next week's file of the same name (W1/x -> W2/x over an old W2/x)
    # shows as M. A path is consistent when its index entry is exactly HEAD's entry for the path that the
    # mapping lands there, or when nothing maps onto it and it is gone from the index.
    expected = {}
    for path, v in before.items():
        q = map_path(path)
        if q is not None:
            expected[q] = v

    def consistent(path):
        if path in expected:
            return after.get(path) == expected[path]
        return path not in after

    counts = defaultdict(int)
    bad = []
    for line in name_status.splitlines(keepends=True):
        parts = line.rstrip("\n").split("\t")
        st, paths = parts[0], parts[1:]
        if not all(consistent(x) for x in paths):
            bad.append(f"inconsistent with the mapping: {line.strip()}")
            continue
        if st.startswith("R") and map_path(paths[0]) == paths[1]:
            counts["R under mapping"] += 1
        elif st == "D" and paths[0].startswith("W5/") and paths[0] not in expected:
            counts["D under old W5/"] += 1
        elif st.startswith(("R", "C")):
            counts["R/C paired across weeks by identical blob (checked per path)"] += 1
        elif st == "M":
            counts["M: path re-occupied by the next week's same-named file"] += 1
        elif st == "D":
            counts["D: source half, content now at its mapped path"] += 1
        elif st == "A":
            counts["A: destination half, holds its mapped content"] += 1
        else:
            bad.append(f"unexpected status: {line.strip()}")

    # (b) whole-index equality under the mapping
    missing = sorted(set(expected) - set(after))
    extra = sorted(set(after) - set(expected))
    changed = sorted(x for x in set(expected) & set(after) if expected[x] != after[x])
    retired = sum(1 for x in before if x.startswith("W5/"))

    print("  name-status entries, every one consistent with the mapping:")
    for k, v in counts.items():
        print(f"    {v:6d}  {k}")
    print(f"  index vs HEAD-under-mapping: {len(before)} before, {retired} retired with W5, "
          f"{len(after)} after; missing={len(missing)} extra={len(extra)} blob-changed={len(changed)}")
    for x in missing[:20]:
        bad.append(f"lost from index: {x}")
    for x in extra[:20]:
        bad.append(f"appeared in index: {x}")
    for x in changed[:20]:
        bad.append(f"blob or mode changed: {x}")
    sys.stdout.flush()
    if bad:
        print("VERIFICATION FAILED:", file=sys.stderr)
        for b in bad[:60]:
            print("  " + b, file=sys.stderr)
        sys.exit(3)
    print("  VERIFIED: every change is a rename under the mapping or a removal of the old W5/", flush=True)


def main(argv):
    hub, dry, verify_only, leave = os.getcwd(), False, False, []
    a = list(argv)
    while a:
        x = a.pop(0)
        if x in ("--hub", "--leave"):
            if not a:
                err(f"rotate.py: {x} needs a value")
                sys.exit(1)
            v = a.pop(0)
            if x == "--hub":
                hub = v
            else:
                leave.append(v[:-1] if v.endswith("/") else v)
        elif x == "--dry-run":
            dry = True
        elif x == "--verify":
            verify_only = True
        elif x in ("-h", "--help"):
            print(__doc__)
            sys.exit(0)
        else:
            err(f"rotate.py: unknown argument: {x}")
            sys.exit(1)

    try:
        os.chdir(hub)
    except OSError as e:
        err(f"rotate.py: {hub}: {e.strerror}")
        sys.exit(1)
    if not git_ok("rev-parse", "--is-inside-work-tree"):
        err(f"rotate.py: {hub} is not a git work tree")
        sys.exit(1)
    hub = git("rev-parse", "--show-toplevel").strip()
    os.chdir(hub)

    if verify_only:
        verify()
        sys.exit(0)

    # ---------------------------------------------------------------- 1. pre-flight
    say(f"== pre-flight ({hub})")
    if os.path.isfile(os.path.join(git("rev-parse", "--git-dir").strip(), "index.lock")):
        refuse("index.lock exists; another git process is running. Wait and retry.")
    if not git_ok("diff", "--cached", "--quiet"):
        refuse("the index already has staged changes; commit or unstage them first (the verification reads the index).")

    for x in leave:
        if not re.match(r"^W[0-4](/|$)", x):
            refuse(f"--leave {x}: must be a path inside W0/..W4/ (W5 retires; nothing can be carried out of it).")
        if re.match(r"^W[0-4]$", x):
            refuse(f"--leave {x}: a whole week directory cannot be left; name the paths inside it.")

    # Dirty paths inside week dirs. -uall lists untracked files individually.
    p = subprocess.run(["git", "status", "--porcelain=v1", "-z", "-uall", "--", "W0", "W1", "W2", "W3", "W4", "W5"], capture_output=True)
    dirty = [e for e in p.stdout.decode("utf-8", "surrogateescape").split("\0") if len(e) > 3]
    blocked = False
    for line in dirty:
        xy, path = line[:2], line[3:]
        if under(path, leave):
            say(f"  leave   [{xy}] {path}")
        else:
            say(f"  BLOCK   [{xy}] {path}  (dirty inside a week dir and not listed with --leave)")
            blocked = True
    if blocked:
        refuse("week directories have changes owned by another session. Pass each with --leave PATH (left for its own commit), or have that session commit first.")

    # W5 must hold only tracked files, or `git rm` leaves a W5/ that the W4 rename would nest into.
    if os.path.isdir("W5"):
        found = []
        for base, dirs, files in os.walk("W5"):
            for d in dirs:
                if os.path.islink(os.path.join(base, d)):
                    found.append(os.path.join(base, d))
            found.extend(os.path.join(base, f) for f in files)
        tracked = set(git("ls-files", "W5").splitlines())
        extra = sorted(set(found) - tracked)
        if extra:
            for x in extra:
                say(f"  W5 untracked or ignored: {x}")
            refuse("W5/ holds files git does not track (listed above). They would not be retired by git rm. Move or delete them by hand first.")

    # Classify each leave path now, while it is still at its old location.
    kind = {}
    for x in leave:
        u = count(git("ls-files", "--others", "--", x))
        m = count(git("ls-files", "--modified", "--", x))
        if not os.path.exists(x):
            kind[x] = "missing"
        elif u > 0 and m > 0:
            kind[x] = f"mixed:{u} untracked, {m} modified-tracked"
        elif u > 0:
            kind[x] = f"untracked:{u}"
        elif m > 0:
            kind[x] = f"modified:{m}"
        else:
            kind[x] = "clean"
        say(f"  leave-path {x} -> {map_path(x) or ''}  [{kind[x]}]")

    present = [f"W{n}" for n in (5, 4, 3, 2, 1, 0) if os.path.isdir(f"W{n}")]
    say(f"  week dirs present: {' '.join(present) or 'none'}")
    say("  pre-flight OK")

    if dry:
        say("== dry run: would run")
        if os.path.isdir("W5"):
            say(f"  git rm -r -q W5   ({count(git('ls-files', 'W5'))} tracked files retire to history)")
        for n in (4, 3, 2, 1, 0):
            if os.path.isdir(f"W{n}"):
                say(f"  git mv W{n} W{n + 1}   ({count(git('ls-files', f'W{n}'))} tracked files)")
        say("  mkdir W0")
        sys.exit(0)

    # ---------------------------------------------------------------- 2. baseline
    say(f"== baseline: {count(git('ls-files'))} tracked files")

    # ---------------------------------------------------------------- 3. rename chain
    say("== rotate")
    if os.path.isdir("W5"):
        n5 = count(git("ls-files", "W5"))
        if n5 > 0:
            git("rm", "-r", "-q", "W5")
        for base, dirs, files in os.walk("W5", topdown=False):  # remove the empty dirs that git rm left
            if not os.listdir(base):
                try:
                    os.rmdir(base)
                except OSError:
                    pass
        if os.path.exists("W5"):
            err("FAILED: W5/ still exists after git rm")
            sys.exit(3)
        say(f"  git rm -r W5   ({n5} files; archive is git history: git show <this-commit>^:W5/<path>)")
    for n in (4, 3, 2, 1, 0):
        src, dst = f"W{n}", f"W{n + 1}"
        if not os.path.isdir(src):
            continue
        if count(git("ls-files", src)) > 0:
            git("mv", src, dst)
        else:
            shutil.move(src, dst)  # no tracked content: plain filesystem move
        say(f"  {src} -> {dst}")
    os.makedirs("W0", exist_ok=True)
    say("  mkdir W0")

    # ---------------------------------------------------------------- 4. leave-path report
    if leave:
        say("== leave paths")
        for x in leave:
            nl = map_path(x)
            k = kind[x]
            if k == "missing":
                say(f"  {x}: did not exist; nothing to carry")
            elif k == "clean":
                say(f"  {x} -> {nl}: clean and tracked, so it was renamed like everything else (nothing to leave)")
            else:
                u = count(git("ls-files", "--others", "--", nl))
                m = count(git("ls-files", "--modified", "--", nl))
                hb = "\n".join(ln.split()[2] for ln in git("ls-tree", "HEAD", "--", x).splitlines() if len(ln.split()) > 2)
                ib = "\n".join(ln.split()[1] for ln in git("ls-files", "-s", "--", nl).splitlines() if len(ln.split()) > 1)
                st = f"now at {nl}: {u} untracked (moved physically with the directory), {m} modified-tracked (edits still unstaged)"
                fail = ""
                if not os.path.exists(nl):
                    fail = "new path missing"
                if os.path.exists(x):
                    fail = "old path still exists"
                # a single modified tracked file: its staged blob must be HEAD's, i.e. the edit stayed unstaged
                if hb and os.path.isfile(nl) and hb != ib:
                    fail = "staged blob differs from HEAD (the edit got staged)"
                if k.startswith("untracked:") and u == 0:
                    fail = "untracked files did not arrive"
                if fail:
                    err(f"  {x}: FAILED — {fail}; {st}")
                    sys.exit(3)
                say(f"  {x} -> {st}")

    # ---------------------------------------------------------------- 5. verify
    verify()
    say("== done. Nothing committed. Review with: git status; git diff --cached -M --stat")
    say("   Commit the mechanical half from the index, with no pathspec (a pathspec would sweep unstaged --leave edits):")
    say("   rotate.py --verify && git commit -m 'rotation: ...'")


if __name__ == "__main__":
    main(sys.argv[1:])

#!/usr/bin/env bash
# rotate.sh — the mechanical half of the weekly hub rotation.
#
#   rotate.sh [--hub PATH] [--leave PATH ...] [--dry-run]
#   rotate.sh [--hub PATH] --verify      # re-run step 5 alone, e.g. right before the commit
#
# What it does, in order:
#   1. Pre-flight. Refuses if anything is staged, or if any path inside W0/..W5/ is modified or
#      untracked and is not at or under a --leave path. Refuses if W5/ holds anything that is not
#      tracked (it would survive `git rm` and collide with the W4 -> W5 rename), or if a --leave
#      path is inside W5/ (W5 retires; nothing can be carried out of it).
#   2. Captures `git ls-files -s` (path + mode + blob) before.
#   3. `git rm -r -q W5`, then `git mv` W4->W5, W3->W4, W2->W3, W1->W2, W0->W1, then `mkdir W0`.
#      `git mv` of a directory is a filesystem rename, so untracked --leave files move with their
#      directory, and modified tracked --leave files keep their working-tree edits unstaged.
#   4. Reports exactly what happened to each --leave path.
#   5. Verifies, two ways. (a) Every `git diff --cached -M100% --name-status` entry is checked per
#      path against the mapping: its index entry must be exactly HEAD's entry for the path the
#      mapping lands there, or it must be gone with nothing mapped onto it (the old W5/, and the
#      W0..W4 sources). Git's own R/C pairing label is not trusted, because the hub carries identical
#      blobs in several weeks and a re-occupied path (W1/x -> W2/x over an old W2/x) shows as M.
#      (b) The whole index must equal HEAD under the mapping, blob and mode for blob and mode.
#      Exits 3 if either fails. Nothing is ever retired except the old W5/.
#
# It never commits. The caller commits the index as it stands, WITHOUT a pathspec: `git commit --
# <paths>` commits the working-tree state of those paths, which would sweep the unstaged edits of
# every modified --leave file into the mechanical commit. Run `rotate.sh --verify` immediately
# before, so a peer session's staged files cannot ride along unseen.
# Exit codes: 0 ok, 1 usage, 2 pre-flight refused, 3 verification failed.
set -euo pipefail
export LC_ALL=C   # sort and comm must agree on byte order; en_US.UTF-8 broke comm (2026-10-05)

HUB="$(pwd)"
DRY=0
VERIFY_ONLY=0
LEAVE=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hub) HUB="$2"; shift 2 ;;
    --leave) LEAVE+=("${2%/}"); shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --verify) VERIFY_ONLY=1; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "rotate.sh: unknown argument: $1" >&2; exit 1 ;;
  esac
done

cd "$HUB"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "rotate.sh: $HUB is not a git work tree" >&2; exit 1; }
HUB="$(git rev-parse --show-toplevel)"; cd "$HUB"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/rotate.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

say() { printf '%s\n' "$*"; }
refuse() { say "REFUSED: $*" >&2; exit 2; }

# Map one hub-relative path through the rotation. Prints nothing for a path under the old W5/.
map_path() {
  local p="$1"
  if [[ "$p" =~ ^W([0-5])(/.*)?$ ]]; then
    local n="${BASH_REMATCH[1]}" rest="${BASH_REMATCH[2]}"
    [[ "$n" == 5 ]] && return 0
    printf 'W%d%s\n' "$((n + 1))" "$rest"
  else
    printf '%s\n' "$p"
  fi
}

under_leave() {
  local p="$1" l
  for l in "${LEAVE[@]+"${LEAVE[@]}"}"; do
    [[ "$p" == "$l" || "$p" == "$l"/* ]] && return 0
  done
  return 1
}

# ---------------------------------------------------------------- 5 (defined early). verify
verify() {
say "== verify"
git -c diff.renameLimit=1 diff --cached -M100% --name-status > "$WORK/name-status.txt" 2>/dev/null
git ls-files -s > "$WORK/after-index.txt"
git ls-tree -r --full-tree HEAD > "$WORK/head-tree.txt"
export WORK
python3 - <<'PY'
import os, re, sys
from collections import defaultdict
W = os.environ["WORK"]
def mp(p):
    m = re.match(r"^W([0-5])(/.*)?$", p)
    if not m: return p
    n = int(m.group(1))
    return None if n == 5 else f"W{n+1}{m.group(2) or ''}"
def idx(f):
    d = {}
    for line in open(os.path.join(W, f), encoding="utf-8", errors="surrogateescape"):
        meta, path = line.rstrip("\n").split("\t", 1)
        mode, blob, _stage = meta.split()
        d[path] = (mode, blob)
    return d
def tree(f):
    d = {}
    for line in open(os.path.join(W, f), encoding="utf-8", errors="surrogateescape"):
        meta, path = line.rstrip("\n").split("\t", 1)
        mode, _type, blob = meta.split()
        d[path] = (mode, blob)
    return d
before, after = tree("head-tree.txt"), idx("after-index.txt")   # before = HEAD, i.e. the pre-rotation commit

# (a) name-status classification.
# Each entry is checked PER PATH against the mapping, not by git's pairing label: the hub carries the
# same blob in several weeks (copied analyses), so which source git pairs an R or C with is arbitrary,
# and a path re-occupied by the next week's file of the same name (W1/x -> W2/x over an old W2/x)
# shows as M. A path is consistent when its index entry is exactly HEAD's entry for the path that the
# mapping lands there, or when nothing maps onto it and it is gone from the index.
expected = {}
for p, v in before.items():
    q = mp(p)
    if q is not None: expected[q] = v
def consistent(p):
    if p in expected: return after.get(p) == expected[p]
    return p not in after
counts = defaultdict(int)
bad = []
for line in open(os.path.join(W, "name-status.txt"), encoding="utf-8", errors="surrogateescape"):
    parts = line.rstrip("\n").split("\t")
    st, paths = parts[0], parts[1:]
    if not all(consistent(p) for p in paths):
        bad.append(f"inconsistent with the mapping: {line.strip()}"); continue
    if st.startswith("R") and mp(paths[0]) == paths[1]: counts["R under mapping"] += 1
    elif st == "D" and paths[0].startswith("W5/") and paths[0] not in expected: counts["D under old W5/"] += 1
    elif st.startswith(("R", "C")): counts["R/C paired across weeks by identical blob (checked per path)"] += 1
    elif st == "M": counts["M: path re-occupied by the next week's same-named file"] += 1
    elif st == "D": counts["D: source half, content now at its mapped path"] += 1
    elif st == "A": counts["A: destination half, holds its mapped content"] += 1
    else: bad.append(f"unexpected status: {line.strip()}")

# (b) whole-index equality under the mapping
missing = sorted(set(expected) - set(after))
extra = sorted(set(after) - set(expected))
changed = sorted(p for p in set(expected) & set(after) if expected[p] != after[p])
retired = sum(1 for p in before if p.startswith("W5/"))

print("  name-status entries, every one consistent with the mapping:")
for k, v in counts.items(): print(f"    {v:6d}  {k}")
print(f"  index vs HEAD-under-mapping: {len(before)} before, {retired} retired with W5, "
      f"{len(after)} after; missing={len(missing)} extra={len(extra)} blob-changed={len(changed)}")
for p in missing[:20]: bad.append(f"lost from index: {p}")
for p in extra[:20]: bad.append(f"appeared in index: {p}")
for p in changed[:20]: bad.append(f"blob or mode changed: {p}")
if bad:
    print("VERIFICATION FAILED:", file=sys.stderr)
    for b in bad[:60]: print("  " + b, file=sys.stderr)
    sys.exit(3)
print("  VERIFIED: every change is a rename under the mapping or a removal of the old W5/")
PY
}

if [[ $VERIFY_ONLY -eq 1 ]]; then verify; exit 0; fi

# ---------------------------------------------------------------- 1. pre-flight
say "== pre-flight ($HUB)"
[[ -f "$(git rev-parse --git-dir)/index.lock" ]] && refuse "index.lock exists; another git process is running. Wait and retry."
git diff --cached --quiet || refuse "the index already has staged changes; commit or unstage them first (the verification reads the index)."

for l in "${LEAVE[@]+"${LEAVE[@]}"}"; do
  [[ "$l" =~ ^W[0-4](/|$) ]] || refuse "--leave $l: must be a path inside W0/..W4/ (W5 retires; nothing can be carried out of it)."
  [[ "$l" =~ ^W[0-4]$ ]] && refuse "--leave $l: a whole week directory cannot be left; name the paths inside it."
done

# Dirty paths inside week dirs. -uall lists untracked files individually.
git status --porcelain=v1 -z -uall -- 'W0' 'W1' 'W2' 'W3' 'W4' 'W5' 2>/dev/null \
  | tr '\0' '\n' | awk 'length($0) > 3' > "$WORK/dirty.txt" || true
BAD=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  xy="${line:0:2}"; p="${line:3}"
  if under_leave "$p"; then
    say "  leave   [$xy] $p"
  else
    say "  BLOCK   [$xy] $p  (dirty inside a week dir and not listed with --leave)"
    BAD=1
  fi
done < "$WORK/dirty.txt"
[[ $BAD -eq 1 ]] && refuse "week directories have changes owned by another session. Pass each with --leave PATH (left for its own commit), or have that session commit first."

# W5 must hold only tracked files, or `git rm` leaves a W5/ that the W4 rename would nest into.
if [[ -d W5 ]]; then
  comm -23 <(cd "$HUB" && find W5 \( -type f -o -type l \) | LC_ALL=C sort) \
           <(git ls-files W5 | LC_ALL=C sort) > "$WORK/w5-extra.txt"
  if [[ -s "$WORK/w5-extra.txt" ]]; then
    sed 's/^/  W5 untracked or ignored: /' "$WORK/w5-extra.txt"
    refuse "W5/ holds files git does not track (listed above). They would not be retired by git rm. Move or delete them by hand first."
  fi
fi

# Classify each leave path now, while it is still at its old location.
declare -A LKIND
for l in "${LEAVE[@]+"${LEAVE[@]}"}"; do
  u=$(git ls-files --others -- "$l" | wc -l)
  m=$(git ls-files --modified -- "$l" | wc -l)
  if   [[ ! -e "$l" ]];              then LKIND[$l]="missing"
  elif [[ $u -gt 0 && $m -gt 0 ]];   then LKIND[$l]="mixed:$u untracked, $m modified-tracked"
  elif [[ $u -gt 0 ]];               then LKIND[$l]="untracked:$u"
  elif [[ $m -gt 0 ]];               then LKIND[$l]="modified:$m"
  else                                    LKIND[$l]="clean"
  fi
  say "  leave-path $l -> $(map_path "$l")  [${LKIND[$l]}]"
done

PRESENT=(); for n in 5 4 3 2 1 0; do [[ -d "W$n" ]] && PRESENT+=("W$n"); done
say "  week dirs present: ${PRESENT[*]:-none}"
say "  pre-flight OK"

if [[ $DRY -eq 1 ]]; then
  say "== dry run: would run"
  [[ -d W5 ]] && say "  git rm -r -q W5   ($(git ls-files W5 | wc -l) tracked files retire to history)"
  for n in 4 3 2 1 0; do [[ -d "W$n" ]] && say "  git mv W$n W$((n + 1))   ($(git ls-files "W$n" | wc -l) tracked files)"; done
  say "  mkdir W0"
  exit 0
fi

# ---------------------------------------------------------------- 2. baseline
git ls-files -s > "$WORK/before-index.txt"      # mode blob stage<TAB>path
git ls-files > "$WORK/before-files.txt"
say "== baseline: $(wc -l < "$WORK/before-files.txt") tracked files"

# ---------------------------------------------------------------- 3. rename chain
say "== rotate"
if [[ -d W5 ]]; then
  n5=$(git ls-files W5 | wc -l)
  if [[ $n5 -gt 0 ]]; then git rm -r -q W5; fi
  find W5 -depth -type d -empty -delete 2>/dev/null || true
  [[ -e W5 ]] && { say "FAILED: W5/ still exists after git rm" >&2; exit 3; }
  say "  git rm -r W5   ($n5 files; archive is git history: git show <this-commit>^:W5/<path>)"
fi
for n in 4 3 2 1 0; do
  src="W$n" dst="W$((n + 1))"
  [[ -d "$src" ]] || continue
  if [[ $(git ls-files "$src" | wc -l) -gt 0 ]]; then
    git mv "$src" "$dst"
  else
    mv "$src" "$dst"      # no tracked content: plain filesystem move
  fi
  say "  $src -> $dst"
done
mkdir -p W0
say "  mkdir W0"

# ---------------------------------------------------------------- 4. leave-path report
if [[ ${#LEAVE[@]} -gt 0 ]]; then
  say "== leave paths"
  for l in "${LEAVE[@]}"; do
    nl="$(map_path "$l")"
    case "${LKIND[$l]}" in
      missing) say "  $l: did not exist; nothing to carry" ;;
      clean)   say "  $l -> $nl: clean and tracked, so it was renamed like everything else (nothing to leave)" ;;
      *)
        u=$(git ls-files --others -- "$nl" | wc -l)
        m=$(git ls-files --modified -- "$nl" | wc -l)
        hb=$(git ls-tree HEAD -- "$l" | awk '{print $3}')
        ib=$(git ls-files -s -- "$nl" | awk '{print $2}')
        state="now at $nl: $u untracked (moved physically with the directory), $m modified-tracked (edits still unstaged)"
        fail=""
        [[ -e "$nl" ]] || fail="new path missing"
        [[ -e "$l" ]] && fail="old path still exists"
        # a single modified tracked file: its staged blob must be HEAD's, i.e. the edit stayed unstaged
        if [[ -n "$hb" && -f "$nl" ]]; then [[ "$hb" == "$ib" ]] || fail="staged blob differs from HEAD (the edit got staged)"; fi
        if [[ "${LKIND[$l]}" == untracked:* && $u -eq 0 ]]; then fail="untracked files did not arrive"; fi
        if [[ -n "$fail" ]]; then say "  $l: FAILED — $fail; $state" >&2; exit 3; fi
        say "  $l -> $state"
        ;;
    esac
  done
fi

# ---------------------------------------------------------------- 5. verify
verify
say "== done. Nothing committed. Review with: git status; git diff --cached -M --stat"
say "   Commit the mechanical half from the index, with no pathspec (a pathspec would sweep unstaged --leave edits):"
say "   rotate.sh --verify && git commit -m 'rotation: ...'"

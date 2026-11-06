#!/usr/bin/env bash
# check-citations.sh — resolve every citation in the hub's tracked markdown, before and after a rotation.
#
#   check-citations.sh [--hub PATH] > report.tsv
#   check-citations.sh --diff before.tsv after.tsv [--no-rotation]
#
# Scan mode. Over every tracked *.md file, emits one TSV row per citation:
#     file  line  kind  citation  resolved  status
#   kind      link     a relative markdown link or image target, resolved from the citing file's dir
#             mention  a W[0-5]/... or hub/W[0-5]/... path in prose or code, resolved from the hub
#                      root (a ../-prefixed mention resolves from the citing file's dir)
#   resolved  the target, relative to the hub root (outside-hub targets keep their ../ prefix)
#   status    ok | missing   (on disk; a tracked-but-deleted file is missing, an untracked file is ok)
# URLs, #anchors, and placeholder or glob mentions (W1/analyses/<file>, W5/**) are skipped.
#
# Diff mode. Pairs rows from two scans and lists the citations that changed meaning. With the default
# rotation mapping (W0->W1 ... W4->W5, old W5 retired), a before row's file and target are carried
# through the mapping, so "the same citation still means the same thing" is judged by identity, not
# by string. Categories:
#   BROKE       resolved before, missing after
#   RETIRED     resolved before into the old W5/, which git rm removed (a special case of BROKE)
#   RETARGETED  resolved before AND after, but after it points at a different file than the one it
#               meant. This is the silent case: an absolute W0/... citation that followed the move
#               and now names a different week's file, with plausible content at the other end.
#   FIXED       missing before, ok after (informational)
# Rows are split by where the citing file lives. A file inside W0/..W5/ is a frozen record, so the
# plain categories are real damage (fix with a tombstone, never by rewriting the frozen link). A file
# outside the week dirs (a root file, a skill) gets the -LIVE-FILE suffix: it is a live pointer that
# names a W-slot, so after the rename a W0/... pointer is expected to read BROKE until the editorial
# lanes rebuild W0, and any other W-slot pointer in it has silently changed week and needs a rewrite
# to a week named by date, or by name.
# Rows present on only one side (the citing text was edited) are counted, not listed.
# Exit code in diff mode: 0 always; read the summary line.
set -euo pipefail
export LC_ALL=C   # sort and comm must agree on byte order; en_US.UTF-8 broke comm (2026-10-05)

HUB="$(pwd)"
MODE=scan
ROT=1
BEFORE="" AFTER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hub) HUB="$2"; shift 2 ;;
    --diff) MODE=diff; BEFORE="$2"; AFTER="$3"; shift 3 ;;
    --no-rotation) ROT=0; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "check-citations.sh: unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ $MODE == scan ]]; then
  cd "$HUB"; HUB="$(git rev-parse --show-toplevel)"; cd "$HUB"
  git ls-files -z -- '*.md' | HUB="$HUB" python3 -c '
import os, re, sys, urllib.parse
hub = os.environ["HUB"]
files = [f for f in sys.stdin.buffer.read().decode("utf-8", "surrogateescape").split("\0") if f]
LINK = re.compile(r"!?\[(?:[^\[\]]|\[[^\]]*\])*\]\(\s*(<[^>]+>|[^)\s]+)(?:\s+\"[^\"]*\")?\s*\)")
MENTION = re.compile(r"(?:(?<=hub/)|(?<![\w/.\-])((?:\.\./)+)?)(W[0-5]/[A-Za-z0-9._/@+~%\-]*)")
SKIP_AFTER = set("<*{[$")
def norm(p):
    r = os.path.normpath(p)
    return r
def status(rel):
    return "ok" if os.path.exists(os.path.join(hub, rel)) else "missing"
out = sys.stdout
out.write("file\tline\tkind\tcitation\tresolved\tstatus\n")
for f in files:
    try:
        text = open(os.path.join(hub, f), encoding="utf-8", errors="replace").read()
    except (FileNotFoundError, IsADirectoryError):
        continue
    base = os.path.dirname(f)
    for ln, line in enumerate(text.split("\n"), 1):
        spans = []
        for m in LINK.finditer(line):
            tgt = m.group(1).strip("<>")
            spans.append(m.span(1))
            if re.match(r"^[a-zA-Z][a-zA-Z0-9+.\-]*:", tgt) or tgt.startswith("#") or tgt.startswith("/"):
                continue
            path = urllib.parse.unquote(tgt.split("#", 1)[0])
            if not path:
                continue
            rel = norm(os.path.join(base, path))
            out.write(f"{f}\t{ln}\tlink\t{tgt}\t{rel}\t{status(rel)}\n")
        masked = list(line)
        for a, b in spans:
            for i in range(a, b): masked[i] = " "
        masked = "".join(masked)
        for m in MENTION.finditer(masked):
            dots, path = m.group(1) or "", m.group(2)
            end = m.end(2)
            if end < len(masked) and masked[end] in SKIP_AFTER:
                continue   # placeholder or glob: W1/analyses/<file>, W5/**, W1/{a,b}
            path = re.sub(r"[.,;:)]+$", "", path)
            path = re.sub(r":\d+(-\d+)?$", "", path)
            if not path:
                continue
            rel = norm(os.path.join(base, dots + path)) if dots else norm(path)
            cite = dots + path
            if masked[max(0, m.start() - 4):m.start()] == "hub/":
                cite = "hub/" + cite
            out.write(f"{f}\t{ln}\tmention\t{cite}\t{rel}\t{status(rel)}\n")
'
  exit 0
fi

# ---------------------------------------------------------------- diff mode
ROT="$ROT" python3 - "$BEFORE" "$AFTER" <<'PY'
import os, re, sys
from collections import defaultdict
rot = os.environ["ROT"] == "1"
def mp(p):
    if not rot: return p
    m = re.match(r"^W([0-5])(/.*)?$", p)
    if not m: return p
    n = int(m.group(1))
    return None if n == 5 else f"W{n+1}{m.group(2) or ''}"
def load(path, carry):
    rows = defaultdict(list)
    with open(path, encoding="utf-8", errors="replace") as fh:
        next(fh, None)
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 6: continue
            f, ln, kind, cite, res, st = parts
            if carry:
                f2 = mp(f)
                if f2 is None: continue          # the citing file itself retired with W5
                f = f2
            rows[(f, kind, cite)].append((int(ln), res, st))
    return rows
before, after = load(sys.argv[1], True), load(sys.argv[2], False)
cats = defaultdict(list)
only_before = only_after = paired = 0
for key in sorted(set(before) | set(after)):
    b, a = before.get(key, []), after.get(key, [])
    n = min(len(b), len(a)); paired += n
    only_before += len(b) - n; only_after += len(a) - n
    for (bl, bres, bst), (al, ares, ast) in zip(b, a):
        intended = mp(bres) if not bres.startswith("..") else bres
        f, kind, cite = key
        row = f"{f}:{al}\t{kind}\t{cite}\tbefore->{bres}\tnow->{ares}"
        live = "" if re.match(r"^W[0-5]/", f) else "-LIVE-FILE"
        if bst == "ok" and ast == "missing":
            cats[("RETIRED" if intended is None else "BROKE") + live].append(row)
        elif bst == "ok" and ast == "ok" and intended is not None and ares != intended:
            cats["RETARGETED" + live].append(row + f"\tmeant->{intended}")
        elif bst == "ok" and ast == "ok" and intended is None:
            cats["RETARGETED" + live].append(row + "\tmeant->(old W5, retired)")
        elif bst == "missing" and ast == "ok":
            cats["FIXED"].append(row)
for c in ("BROKE", "RETIRED", "RETARGETED", "BROKE-LIVE-FILE", "RETIRED-LIVE-FILE", "RETARGETED-LIVE-FILE", "FIXED"):
    print(f"## {c} ({len(cats[c])})")
    for r in cats[c]: print(r)
    print()
print(f"SUMMARY\tpaired={paired}\tbroke={len(cats['BROKE'])}\tretired={len(cats['RETIRED'])}\t"
      f"retargeted={len(cats['RETARGETED'])}\tlive-file:broke={len(cats['BROKE-LIVE-FILE'])},"
      f"retired={len(cats['RETIRED-LIVE-FILE'])},retargeted={len(cats['RETARGETED-LIVE-FILE'])}\tfixed={len(cats['FIXED'])}\t"
      f"unpaired-before={only_before}\tunpaired-after={only_after}")
PY

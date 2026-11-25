#!/usr/bin/env bash
# Tests of the groups view and the flow view of repo-map (spec KB repo-map-flow, checks k1 to k9).
# The tool: kb/share/repo-map/views.py; its facts: kb/share/repo-map/sagittarius.views.json; the map
# it writes: docs/map/sagittarius-map.{md,html}.
#
# Usage: kb/tests/test_repo_map_flow.sh            (REPO_ROOT=DIR tests another checkout)
#        TESTS='K3 K7' kb/tests/test_repo_map_flow.sh   runs only the named tests
# Exit: 0 all pass, 1 a test failed (or a named test has no function, or a test errored).
# Test -> check: K1 k1 (c1), K2 k2 (c2), K3 k3 (c3), K4 k4 (c4), K5 k5 (c5), K6 k6 (c6), K7 k7 (c7),
#   K8 k8 (c8), K9 k9 (c9).
# The runner (c9): each test runs in a subshell under `set -e`; a test passes only when its function
# exists and the subshell exits 0. A test that is named and has no function is a FAIL.
# K5 reads a COPY of a real spec KB: PHIL3_KB (default: the philosophy-3 KB of the sidequest-mindhole).
# K6 needs /usr/bin/chromium-browser (or CHROMIUM); it saves the four images in SHOTS (default: the
# scratch dir of the run, removed at the end).
set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=${REPO_ROOT:-$(cd "$here/../.." && pwd -P)}
V=$ROOT/kb/share/repo-map/views.py
FACTS=$ROOT/kb/share/repo-map/sagittarius.views.json
MAP=$ROOT/docs/map/sagittarius-map.html
PHIL3_KB=${PHIL3_KB:-/home/ty/Projects/mine/mindhole/specs/philosophy-3}
CHROMIUM=${CHROMIUM:-/usr/bin/chromium-browser}
base=$(mktemp -d "${TMPDIR:-/tmp}/repo-map-flow-test.XXXXXX") || exit 2
trap 'rm -rf "$base"' EXIT
SHOTS=${SHOTS:-$base/shots}

fail() { echo "     - $*"; return 1; }
# run CMD...: sets $out (stdout+stderr) and $rc, never trips set -e
run() { rc=0; out=$("$@" 2>&1) || rc=$?; }
has() { printf '%s\n' "$out" | grep -qF -- "$1" || fail "${2:-output lacks: $1}"; }

# a scratch copy of the checkout (tracked and new files, less evals/), as a git repo of its own
mkcopy() {
    local d=$1; mkdir -p "$d"
    (cd "$ROOT" && git ls-files -co --exclude-standard | grep -v '^evals/' | rsync -a --files-from=- ./ "$d/")
    (cd "$d" && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -qm copy && \
        git remote add origin https://example.invalid/origin.git)
}
# a scratch copy of the facts file, changed by the python expression in $2 (d is the JSON)
mkfacts() {
    python3 - "$FACTS" "$1" "$2" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
exec(sys.argv[3])
open(sys.argv[2], "w").write(json.dumps(d, indent=2) + "\n")
EOF
}

# k1: the groups of the committed map against MODULES.json, by id (an independent reading of covers
# and except)
k1_verify() {
    python3 - "$ROOT" "$FACTS" "$1" <<'EOF'
import json, re, sys
root, facts, page = sys.argv[1:4]
mods = json.load(open(root + "/MODULES.json"))["modules"]
f = json.load(open(facts))
t = open(page).read()
m = re.search(r'id="repo-map-data">(.*?)</script>', t, re.S)
if not m: print("no map data in the page"); sys.exit(1)
data = json.loads(m.group(1).replace("<\\/", "</"))
groups = {g["id"]: g["parts"] for g in data["groups"]}
bad = []
def under(p, c): return p == c or p.startswith(c.rstrip("/") + "/")
def owner(p):
    c = [(len(cv), mo["name"]) for mo in mods for cv in mo["covers"] if under(p, cv)
         and not any(under(p, e) for e in mo.get("except", []))]
    return max(c)[1] if c else None
for mo in mods:
    if mo["name"] not in groups: bad.append("module %s has no group" % mo["name"]); continue
    for cv in mo["covers"]:
        if "covers:" + cv not in groups[mo["name"]]: bad.append("covers %s not in group %s" % (cv, mo["name"]))
for p in f["parts"]:
    o = owner(p["path"])
    where = [g for g, ps in groups.items() if p["id"] in ps]
    if where != [o]: bad.append("part %s is in %s, MODULES.json says %s" % (p["id"], where, o))
for g in groups:
    if g not in [mo["name"] for mo in mods]: bad.append("group %s is no module" % g)
need = ["install_links", "sidequest_mindhole", "hwh_mindhole", "desk_state", "gitea", "github", "s1_model", "claude_code"]
for n in need:
    if n not in data["outside"]: bad.append("outside %s is not drawn outside" % n)
    if any(n in ps for ps in groups.values()): bad.append("outside %s is inside a group" % n)
for b in bad: print(b)
sys.exit(1 if bad else 0)
EOF
}

t_K1() {
    [ -f "$MAP" ] || fail "no map page $MAP"
    run k1_verify "$MAP"; [ "$rc" = 0 ] || fail "k1 on the map: $out"
    # plant: desk-toast moved inside mindhole-kit
    python3 - "$MAP" "$base/k1.html" <<'EOF'
import re, sys, json
t = open(sys.argv[1]).read()
m = re.search(r'(id="repo-map-data">)(.*?)(</script>)', t, re.S)
d = json.loads(m.group(2).replace("<\\/", "</"))
g = {x["id"]: x for x in d["groups"]}
g["desk-toast"]["parts"].remove("desk_toast"); g["mindhole-kit"]["parts"].append("desk_toast")
open(sys.argv[2], "w").write(t[:m.start(2)] + json.dumps(d) + t[m.end(2):])
EOF
    run k1_verify "$base/k1.html"; [ "$rc" = 1 ] || fail "planted desk-toast inside mindhole-kit stays green"
    has "part desk_toast is in ['mindhole-kit'], MODULES.json says desk-toast"
}

t_K2() {
    run python3 "$V" check --root "$ROOT"; [ "$rc" = 0 ] || fail "check is red: $out"
    run python3 "$V" data --root "$ROOT"; [ "$rc" = 0 ] || fail "data failed"
    printf '%s\n' "$out" > "$base/k2.json"
    python3 - "$base/k2.json" <<'EOF' || fail "a kind lacks a write or a read arrow"
import json, sys
d = json.load(open(sys.argv[1]))
bad = 0
for k in ["request", "goal", "hypothesis", "premise", "claim", "check", "run", "verdict", "judgment"]:
    w = [s for s in d["steps"] if k in s["kinds"] and s["verb"] in ("write", "derive")]
    r = [s for s in d["steps"] if k in s["kinds"] and s["verb"] in ("read", "carry")]
    if not w or not r: print(k, len(w), len(r)); bad = 1
sys.exit(bad)
EOF
    mkfacts "$base/k2-facts.json" 'd["steps"] = [s for s in d["steps"] if "judgment" not in s["kinds"]]'
    run python3 "$V" check --root "$ROOT" --facts "$base/k2-facts.json"; [ "$rc" = 1 ] || fail "judgment arrows removed: still green"
    has "kind judgment has no write arrow"; has "kind judgment has no read arrow"
    # the required kinds live in views.py: moving premise to left_out in the facts must go red
    mkfacts "$base/k2-prem.json" 'd["kinds"] = [k for k in d["kinds"] if k["id"] != "premise"]
d["steps"] = [s for s in d["steps"] if "premise" not in s["kinds"] or s["kinds"].remove("premise") or s["kinds"]]
d["left_out"].append({"reason": "a plant", "names": ["premise"]})
d.pop("required_kinds", None)'
    run python3 "$V" check --root "$ROOT" --facts "$base/k2-prem.json"; [ "$rc" = 1 ] || fail "premise moved to left_out stays green"
    has "kind premise is required and is not a kind of the flow view"
}

t_K3() {
    run python3 "$V" check --root "$ROOT"; [ "$rc" = 0 ] || fail "check is red: $out"
    has "views check: green"
    mkfacts "$base/k3a.json" '[x.update(name="cmd_judgement") for s in d["steps"] for x in s["sources"] if x["name"] == "cmd_judge"]'
    run python3 "$V" check --root "$ROOT" --facts "$base/k3a.json"; [ "$rc" = 1 ] || fail "cmd_judgement stays green"
    has "pred cmd_judgement is not in kb/bin/orbit-kb"
    mkfacts "$base/k3b.json" 'd["steps"][3]["sources"] = []'
    run python3 "$V" check --root "$ROOT" --facts "$base/k3b.json"; [ "$rc" = 1 ] || fail "an arrow with no source stays green"
    has "arrow s04: no source"
    mkfacts "$base/k3c.json" 'd["outside"][0]["source"]["name"] = "no_such_key_xyz"'
    run python3 "$V" check --root "$ROOT" --facts "$base/k3c.json"; [ "$rc" = 1 ] || fail "a box with a wrong source stays green"
    has "box outside:install_links: json no_such_key_xyz is not in MODULES.json"
}

t_K4() {
    local c
    c=$base/k4m; mkcopy "$c"
    run python3 "$c/kb/share/repo-map/views.py" check --root "$c"; [ "$rc" = 0 ] || fail "the copy is red before a plant: $out"
    python3 - "$c/MODULES.json" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1])); d["modules"].append({"name": "probe-module", "version": "VERSION", "covers": ["probe"]})
open(sys.argv[1], "w").write(json.dumps(d, indent=1))
EOF
    run python3 "$c/kb/share/repo-map/views.py" check --root "$c"; [ "$rc" = 1 ] || fail "seventh module stays green"
    has "module probe-module is not in the map"
    c=$base/k4s; mkcopy "$c"
    python3 - "$c/hubkit/tools/store-facts.json" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1])); d["stores"].append({"name": "probe_store", "owns": "a plant"})
open(sys.argv[1], "w").write(json.dumps(d, indent=1))
EOF
    run python3 "$c/kb/share/repo-map/views.py" check --root "$c"; [ "$rc" = 1 ] || fail "eighth store stays green"
    has "store probe_store is not in the map"
    c=$base/k4a; mkcopy "$c"
    printf "attest_type(probe_kind,\n    [], 'a plant').\n" >> "$c/kb/share/orbit-kb/core.pl"
    run python3 "$c/kb/share/repo-map/views.py" check --root "$c"; [ "$rc" = 1 ] || fail "new attest_type stays green"
    has "attest_type probe_kind is declared and the map neither shows it nor leaves it out with a reason"
    c=$base/k4b; mkcopy "$c"
    sed -i 's|</svg></div>|<g data-box="part:hand_box"><rect x="1" y="1" width="9" height="9"/></g></svg></div>|' "$c/docs/map/sagittarius-map.html"
    run python3 "$c/kb/share/repo-map/views.py" check --root "$c"; [ "$rc" = 1 ] || fail "hand-added box stays green"
    has "box part:hand_box in the map has no source"
}

t_K5() {
    [ -f "$PHIL3_KB/kb.pl" ] || fail "no spec KB at $PHIL3_KB"
    cp -r "$PHIL3_KB" "$base/k5kb"
    run python3 "$V" trace "$base/k5kb" --root "$ROOT"; [ "$rc" = 0 ] || fail "trace is red: $(printf '%s\n' "$out" | grep FAIL | head -3)"
    has "trace: green"
    local n; n=$(printf '%s\n' "$out" | grep -c '^line ')
    local sum; sum=$(printf '%s\n' "$out" | sed -n 's/^counts: //p' | grep -o '[0-9]\+' | awk '{s+=$1} END {print s}')
    [ "$n" = "$sum" ] || fail "placed $n records, the KB holds $sum"
    printf '%s\n' "$out" | grep -q '^line .* verdict .*J=satisfied V=meets' || fail "the verdict of the judgment shows no J= and V="
    printf '%s\n' "$out" | grep -q '^line .* verdict .*experiment/3' || fail "the verdict of the judgment is not on its own step"
    for k in request goal hypothesis claim check run verdict judgment; do
        printf '%s\n' "$out" | grep -q "^line [0-9 ]*$k " || fail "no $k record placed"
    done
    mkfacts "$base/k5-facts.json" 'd["steps"] = [s for s in d["steps"] if not s["label"].startswith("orbit run K")]'
    run python3 "$V" trace "$base/k5kb" --root "$ROOT" --facts "$base/k5-facts.json"; [ "$rc" = 1 ] || fail "run arrow removed: still green"
    local left; left=$(printf '%s\n' "$out" | grep -c '^FAIL run .* is on no arrow')
    [ "$left" = 73 ] || fail "run arrow removed: $left runs left over, want 73"
}

# k6: one measurement of PAGE at WIDTH; prints the JSON line of repo_map_measure.js
measure() {
    local page=$1 w=$2 tag=$3
    python3 -c 'import sys; t=open(sys.argv[1]).read(); j=open(sys.argv[2]).read(); i=t.rindex("</body>"); open(sys.argv[3],"w").write(t[:i]+"<script>"+j+"</script>"+t[i:])' "$page" "$here/repo_map_measure.js" "$base/m-$tag.html"
    timeout 90 "$CHROMIUM" --headless --disable-gpu --user-data-dir="$base/chrome" --window-size="$w,1200" \
        --virtual-time-budget=3000 --dump-dom "file://$base/m-$tag.html" 2>/dev/null \
        | sed -n 's|.*<pre id="measure">\(.*\)</pre>.*|\1|p' | sed 's/&quot;/"/g; s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g'
}
shot() {  # one image of one view: the other view and the tables are hidden in a scratch copy
    local view=$1 w=$2 h=$3 hide
    case $view in groups) hide='#v-flow';; flow) hide='#v-groups';; esac
    # each image shows one view: the other view and the source tables (section v-sources) are hidden
    sed "s|</style>|$hide, #v-sources { display: none; } </style>|" "$MAP" > "$base/s-$view.html"
    mkdir -p "$SHOTS"
    timeout 90 "$CHROMIUM" --headless --disable-gpu --user-data-dir="$base/chrome" --window-size="$w,$h" \
        --hide-scrollbars --screenshot="$SHOTS/$view-$w.png" "file://$base/s-$view.html" >/dev/null 2>&1
    [ -s "$SHOTS/$view-$w.png" ] || fail "no image $SHOTS/$view-$w.png"
}
t_K6() {
    [ -x "$CHROMIUM" ] || fail "no chromium at $CHROMIUM"
    [ -f "$MAP" ] || fail "no map page $MAP"
    local w j
    for w in 1600 400; do
        j=$(measure "$MAP" "$w" "map$w")
        [ -n "$j" ] || fail "no measurement at $w px"
        printf '%s\n' "$j" > "$base/measure-$w.json"
        python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); [print("    ", p) for p in d["problems"][:10]]; print("     %s px: %d boxes, %d labels, smallest label %.1f px, %d problems" % (sys.argv[2], d["boxes"], d["labels"], d["minFont"], len(d["problems"]))); sys.exit(1 if d["problems"] or d["boxes"] < 40 else 0)' "$base/measure-$w.json" "$w" \
            || fail "the map at $w px has problems"
    done
    shot groups 1600 1400; shot flow 1600 4200; shot groups 400 2400; shot flow 400 4400
    # plant: 20 boxes in one row, scaled to the width of the window
    {
        printf '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head><body><svg width="100%%" viewBox="0 0 2000 60">'
        for j in $(seq 0 19); do printf '<g data-box="b%d"><rect x="%d" y="5" width="96" height="40"/><text x="%d" y="30" style="font-size:12px">box number %d</text></g>' "$j" $((j*100)) $((j*100+4)) "$j"; done
        printf '</svg></body></html>'
    } > "$base/plant20.html"
    j=$(measure "$base/plant20.html" 400 plant)
    printf '%s\n' "$j" | grep -q 'label smaller than 11 px' || fail "20 boxes in one row at 400 px stay green: $j"
}

t_K7() {
    run python3 "$V" build --root "$ROOT" --out "$base/k7a"; [ "$rc" = 0 ] || fail "build a: $out"
    run python3 "$V" build --root "$ROOT" --out "$base/k7b"; [ "$rc" = 0 ] || fail "build b: $out"
    local f
    for f in sagittarius-map.md sagittarius-map.html; do
        [ "$(sha256sum < "$base/k7a/$f")" = "$(sha256sum < "$base/k7b/$f")" ] || fail "two runs differ: $f"
        [ "$(sha256sum < "$base/k7a/$f")" = "$(sha256sum < "$ROOT/docs/map/$f")" ] || fail "committed $f differs from a fresh build"
    done
    mkfacts "$base/k7-facts.json" 'd["steps"][22]["label"] = d["steps"][22]["label"] + " (edited)"'
    run python3 "$V" check --root "$ROOT" --facts "$base/k7-facts.json"; [ "$rc" = 1 ] || fail "an edited arrow with no new run stays green"
    has "stale: $ROOT/docs/map/sagittarius-map.html differs from what views.py build makes now"
}

t_K8() {
    local BASE_REV=${BASE_REV:-cc64ef0} RM=$ROOT/kb/bin/repo-map EX=$ROOT/kb/share/repo-map
    git -C "$ROOT" show "$BASE_REV:kb/bin/repo-map" > "$base/repo-map-base"; chmod +x "$base/repo-map-base"
    git -C "$ROOT" show "$BASE_REV:kb/share/repo-map/example-kb.pl" > "$base/ex-kb.pl"
    git -C "$ROOT" show "$BASE_REV:kb/share/repo-map/sagittarius.containers.pl" > "$base/ex-ct.pl"
    local a b lv
    for lv in "--level c1" "--level c2" "--level both" "--level c3 --container prompt" "--level c3 --container orbit_kb"; do
        # shellcheck disable=SC2086
        a=$(swipl "$base/repo-map-base" --facts "$base/ex-kb.pl" --containers "$base/ex-ct.pl" $lv 2>&1; echo "rc=$?")
        # shellcheck disable=SC2086
        b=$(swipl "$RM" --facts "$EX/example-kb.pl" --containers "$EX/sagittarius.containers.pl" $lv 2>&1; echo "rc=$?")
        [ "$a" = "$b" ] || fail "repo-map $lv differs from $BASE_REV"
    done
    run bash "$ROOT/kb/tests/test_repo_map.sh"; [ "$rc" = 0 ] || fail "test_repo_map.sh failed"
    [ "$(printf '%s\n' "$out" | grep -c '^PASS ')" = 24 ] || fail "test_repo_map.sh: not 24 PASS lines"
    ! printf '%s\n' "$out" | grep -q 'command not found' || fail "test_repo_map.sh printed command not found"
}

t_K9() {
    run env TESTS=Ghost bash "$here/test_repo_map_flow.sh"; [ "$rc" = 1 ] || fail "a test with no function did not exit 1"
    has "FAIL Ghost (no function t_Ghost)"
    run env TESTS=Zerr RUNNER_SELFTEST=1 bash "$here/test_repo_map_flow.sh"; [ "$rc" = 1 ] || fail "a test that errors did not exit 1"
    has "FAIL Zerr"
}
if [ "${RUNNER_SELFTEST:-}" = 1 ]; then
    t_Zerr() { no_such_command_repo_map_flow; echo "after the error"; }
fi

pass=0 nfail=0
for t in ${TESTS:-K1 K2 K3 K4 K5 K6 K7 K8 K9}; do
    if ! declare -F "t_$t" >/dev/null; then nfail=$((nfail+1)); echo "FAIL $t (no function t_$t)"; continue; fi
    ( set -e; "t_$t" ); rc=$?   # not in a || list: there bash would ignore set -e
    if [ "$rc" = 0 ]; then pass=$((pass+1)); echo "PASS $t"; else nfail=$((nfail+1)); echo "FAIL $t (exit $rc)"; fi
done
echo "----"
echo "repo-map views: pass=$pass fail=$nfail"
[ "$nfail" = 0 ]

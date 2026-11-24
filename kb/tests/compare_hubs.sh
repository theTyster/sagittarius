#!/usr/bin/env bash
# Compares two versions of orbit-kb on the KBs of real hubs (scientific-method-overhaul, claims
# c20 and c21, experiments k20 and k21; rule (f) is c43).
#
# For each hub directory, the script copies specs/ and the project KB (a directory at the hub
# root with a kb.pl) into a temporary folder: one copy for each tool. It never writes in a hub.
# For each KB (each kb.pl of the copy) it asks OLD_TOOL and NEW_TOOL, and holds these rules:
#   (a) The KB opens in NEW: `query 'claim(C,_,_)' -n 0` exits 0 or 1, and `lint` does not exit 2.
#       (A call that exits 2 under OLD too is no violation: it is a note.)
#   (b) `query done`: a KB that is done under OLD is done under NEW.
#   (c) `query 'blocking(X)' -n 0`: each answer line of OLD is an answer line of NEW.
#   (d) `show open`: each line of OLD is a line of NEW. ("- Nothing is open." is not an item.)
#   (e) c21: each `hypothesis(H, K, T)` of OLD that OLD does not call superseded is `goal(H, K, _, T)`
#       under NEW, with the same `premise(P, H, T)` lines. Each answer of NEW to
#       `hypothesis(H, G, A, T)` (arity 4) is a fact that kb.pl holds: NEW computes no hypothesis.
#       A KB with a goal and no hypothesis of arity 4 loads (`show` does not exit 2).
#   (f) c43: `query 'hypothesis(H, K, T)' -n 0` gives the same answer lines under NEW as under OLD.
# NEW may add lines in (c) and (d). Only stdout and the exit code are compared, never stderr.
#
# Output: one line for each KB (ok, FAIL or SKIP), one line for each difference, a summary.
# Usage: kb/tests/compare_hubs.sh [--save DIR] OLD_TOOL NEW_TOOL HUB_DIR...
#   --save DIR   keeps the answers of OLD for each KB in DIR (private data: do not commit DIR).
# Exit: 0 no violation. 1 a violation of (a) to (f). 2 a setup error.
set -u
me=compare_hubs.sh
die() { echo "$me: $*" >&2; exit 2; }
SAVE=""
if [ "${1:-}" = "--save" ]; then SAVE=${2:-}; [ -n "$SAVE" ] || die "--save needs a directory"; shift 2; fi
[ $# -ge 3 ] || die "usage: $me [--save DIR] OLD_TOOL NEW_TOOL HUB_DIR..."
abs() { case $1 in /*) printf '%s\n' "$1" ;; *) printf '%s\n' "$PWD/$1" ;; esac; }
OLD=$(abs "$1"); NEW=$(abs "$2"); shift 2
[ -x "$OLD" ] || die "no tool at $OLD"
[ -x "$NEW" ] || die "no tool at $NEW"
for t in mktemp sed grep sort comm cp find; do command -v "$t" >/dev/null 2>&1 || die "required tool not found: $t"; done
for h in "$@"; do [ -d "$h" ] || die "no hub directory at $h"; done
# Each tool uses its own library, not one that the environment names.
for v in $(compgen -e); do case $v in ORBIT_KB*) unset "$v" ;; esac; done
[ -z "$SAVE" ] || { mkdir -p "$SAVE" || die "cannot make $SAVE"; SAVE=$(cd "$SAVE" && pwd -P); }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/compare-hubs.XXXXXX") || die "mktemp failed"
trap 'rm -rf "$TMP"' EXIT
A=$TMP/answers; mkdir -p "$A"
start=$SECONDS

# ask SIDE TOOL KB NAME ARGS...: stdout to $A/SIDE.NAME (sorted answer lines), exit code to $A/SIDE.NAME.rc
ask() {
    local side=$1 tool=$2 kb=$3 name=$4; shift 4
    "$tool" --dir "$kb" "$@" >"$A/$side.$name.raw" 2>"$A/$side.$name.err" </dev/null
    echo $? >"$A/$side.$name.rc"
    # "true" and "false" are the answers with no variable: they are not answer lines.
    sed -e 's/[[:space:]]*$//' "$A/$side.$name.raw" | grep -v -x -e '' -e 'true' -e 'false' | LC_ALL=C sort -u >"$A/$side.$name"
}
rc() { cat "$A/$1.$2.rc"; }
missing() { LC_ALL=C comm -23 "$A/old.$1" "$A/new.$1"; }      # lines of OLD that NEW does not have

kbs=0 ok=0 bad=0 skipped=0 total_v=0
declare -A RULE_V=([a]=0 [b]=0 [c]=0 [d]=0 [e]=0 [f]=0)
declare -A RULE_KB=([a]=0 [b]=0 [c]=0 [d]=0 [e]=0 [f]=0)
done_old=0 done_new=0 block_old=0 open_old=0 hyp_old=0 notes=0

compare_kb() {  # compare_kb LABEL OLD_KB NEW_KB
    local label=$1 okb=$2 nkb=$3 diffs=() hit="" r line
    v() { diffs+=("  ($1) $2"); total_v=$((total_v + 1)); RULE_V[$1]=$((${RULE_V[$1]} + 1)); case $hit in *$1*) ;; *) hit="$hit$1"; RULE_KB[$1]=$((${RULE_KB[$1]} + 1)) ;; esac; }
    n() { diffs+=("  note: $1"); notes=$((notes + 1)); }
    kbs=$((kbs + 1))
    rm -f "$A"/old.* "$A"/new.*
    ask old "$OLD" "$okb" claim query 'claim(C,_,_)' -n 0
    if [ "$(rc old claim)" != 0 ] && [ "$(rc old claim)" != 1 ]; then
        skipped=$((skipped + 1)); echo "SKIP $label: OLD does not open it (exit $(rc old claim)): $(head -n 1 "$A/old.claim.err")"; return
    fi
    ask old "$OLD" "$okb" lint lint
    ask old "$OLD" "$okb" done query done
    ask old "$OLD" "$okb" blocking query 'blocking(X)' -n 0
    ask old "$OLD" "$okb" open show open
    ask old "$OLD" "$okb" hyp3 query 'hypothesis(H, K, T)' -n 0
    ask old "$OLD" "$okb" superseded query 'superseded(H)' -n 0
    ask old "$OLD" "$okb" premise query 'premise(P, H, T)' -n 0
    ask new "$NEW" "$nkb" claim query 'claim(C,_,_)' -n 0
    ask new "$NEW" "$nkb" lint lint
    ask new "$NEW" "$nkb" done query done
    ask new "$NEW" "$nkb" blocking query 'blocking(X)' -n 0
    ask new "$NEW" "$nkb" open show open
    ask new "$NEW" "$nkb" hyp3 query 'hypothesis(H, K, T)' -n 0
    ask new "$NEW" "$nkb" premise query 'premise(P, H, T)' -n 0
    ask new "$NEW" "$nkb" goal query 'goal(H, K, _, T)' -n 0
    ask new "$NEW" "$nkb" hyp4 query 'hypothesis(H, G, A, T)' -n 0
    if [ -n "$SAVE" ]; then
        mkdir -p "$SAVE/$label"
        for f in claim lint done blocking open hyp3 superseded premise; do
            cp "$A/old.$f.raw" "$SAVE/$label/$f.txt"; cp "$A/old.$f.rc" "$SAVE/$label/$f.rc"
        done
    fi

    # (a) opens
    r=$(rc new claim)
    [ "$r" = 0 ] || [ "$r" = 1 ] || v a "NEW does not open the KB: query claim(C,_,_) exits $r: $(head -n 1 "$A/new.claim.err")"
    if [ "$(rc new lint)" = 2 ]; then
        if [ "$(rc old lint)" = 2 ]; then n "lint exits 2 under OLD and under NEW"
        else v a "NEW lint exits 2 (OLD: $(rc old lint)): $(head -n 1 "$A/new.lint.err")"; fi
    fi
    # (b) done stays done
    local od=no nd=no
    [ "$(rc old done)" = 0 ] && { od=yes; done_old=$((done_old + 1)); }
    [ "$(rc new done)" = 0 ] && { nd=yes; done_new=$((done_new + 1)); }
    [ "$od" = yes ] && [ "$nd" = no ] && v b "done under OLD, not done under NEW (query done exits $(rc new done))"
    # (c) blocking
    block_old=$((block_old + $(wc -l <"$A/old.blocking")))
    r=$(rc new blocking); [ "$r" = 0 ] || [ "$r" = 1 ] || v c "NEW query blocking(X) exits $r: $(head -n 1 "$A/new.blocking.err")"
    while IFS= read -r line; do v c "blocking line of OLD is not under NEW: $line"; done < <(missing blocking)
    # (d) show open
    grep -v -x -e '- Nothing is open\.' "$A/old.open" >"$A/old.open.items"; mv "$A/old.open.items" "$A/old.open"
    grep -v -x -e '- Nothing is open\.' "$A/new.open" >"$A/new.open.items"; mv "$A/new.open.items" "$A/new.open"
    open_old=$((open_old + $(grep -c '^- ' "$A/old.open")))
    r=$(rc new open); [ "$r" = "$(rc old open)" ] || v d "show open exits $r under NEW ($(rc old open) under OLD)"
    while IFS= read -r line; do
        key=${line%%:*}
        if [ "$key" != "$line" ] && grep -qF -- "$key:" "$A/new.open"; then v d "show open line of OLD is not under NEW (the item is listed with other words): $line"
        else v d "show open line of OLD is not under NEW: $line"; fi
    done < <(missing open)
    # (f) hypothesis/3 answers as at OLD
    hyp_old=$((hyp_old + $(wc -l <"$A/old.hyp3")))
    if ! cmp -s "$A/old.hyp3" "$A/new.hyp3"; then
        while IFS= read -r line; do v f "hypothesis/3 answer of OLD is not under NEW: $line"; done < <(missing hyp3)
        while IFS= read -r line; do v f "hypothesis/3 answer of NEW is not under OLD: $line"; done < <(LC_ALL=C comm -13 "$A/old.hyp3" "$A/new.hyp3")
    fi
    # (e) the hypothesis of OLD is the goal of NEW, with its premises; no hypothesis that nobody wrote
    local g=$(rc new goal) h4=$(rc new hyp4) cur=0
    [ "$g" = 0 ] || [ "$g" = 1 ] || v e "NEW does not answer goal(H, K, _, T) (exit $g): $(head -n 1 "$A/new.goal.err")"
    [ "$h4" = 0 ] || [ "$h4" = 1 ] || v e "NEW does not answer hypothesis(H, G, A, T) (exit $h4): $(head -n 1 "$A/new.hyp4.err")"
    while IFS= read -r line; do
        id=${line#H = }; id=${id%%, K = *}
        grep -qxF -- "H = $id" "$A/old.superseded" && continue
        cur=$((cur + 1))
        if [ "$g" = 0 ] || [ "$g" = 1 ]; then
            grep -qxF -- "$line" "$A/new.goal" || v e "hypothesis $id of OLD is not the goal under NEW: $line"
        fi
        grep -F -- ", H = $id, T = " "$A/old.premise" >"$A/old.p1"; grep -F -- ", H = $id, T = " "$A/new.premise" >"$A/new.p1"
        cmp -s "$A/old.p1" "$A/new.p1" || v e "the premises of $id differ: OLD $(wc -l <"$A/old.p1"), NEW $(wc -l <"$A/new.p1")"
    done <"$A/old.hyp3"
    if [ "$h4" = 0 ]; then
        while IFS= read -r line; do
            id=${line#H = }; id=${id%%, G = *}; rest=${line#*, G = }; gid=${rest%%, A = *}; rest=${rest#*, A = }; au=${rest%%, T = *}
            grep -qF -- "hypothesis($id, $gid, $au, " "$nkb/kb.pl" || v e "NEW answers a hypothesis that kb.pl does not hold: $line"
        done <"$A/new.hyp4"
    fi
    if [ "$g" = 0 ] && [ -s "$A/new.goal" ] && [ ! -s "$A/new.hyp4" ]; then
        ask new "$NEW" "$nkb" show show
        [ "$(rc new show)" != 2 ] || v e "a KB with a goal and no hypothesis does not load: show exits 2: $(head -n 1 "$A/new.show.err")"
    fi

    local sum="done $od->$nd, blocking $(wc -l <"$A/old.blocking")->$(wc -l <"$A/new.blocking"), open $(grep -c '^- ' "$A/old.open")->$(grep -c '^- ' "$A/new.open"), hypotheses $(wc -l <"$A/old.hyp3") ($cur not superseded)"
    if [ -z "$hit" ]; then ok=$((ok + 1)); echo "ok   $label: $sum"
    else bad=$((bad + 1)); echo "FAIL $label: rules ($hit): $sum"; fi
    for line in "${diffs[@]+"${diffs[@]}"}"; do echo "$line"; done
}

i=0
for hub in "$@"; do
    i=$((i + 1)); hub=$(cd "$hub" && pwd -P); name="hub$i-$(basename "$(dirname "$hub")")-$(basename "$hub")"
    before=$kbs
    [ -d "$hub/specs" ] || { echo "SKIP $name: no specs/ in $hub"; continue; }
    for side in old new; do
        mkdir -p "$TMP/$side/$name" && cp -a "$hub/specs" "$TMP/$side/$name/specs" || die "cannot copy $hub/specs"
        for pk in "$hub"/*/kb.pl; do
            [ -f "$pk" ] || continue
            d=$(dirname "$pk"); [ "$(basename "$d")" = specs ] && continue
            cp -a "$d" "$TMP/$side/$name/$(basename "$d")" || die "cannot copy $d"
        done
    done
    echo "== $name ($hub)"
    while IFS= read -r kbpl; do
        rel=${kbpl#"$TMP/old/$name/"}; rel=$(dirname "$rel")
        compare_kb "$name/$rel" "$TMP/old/$name/$rel" "$TMP/new/$name/$rel"
        # A read must not write: the kb.pl of each copy is still the kb.pl that was copied.
        cmp -s "$TMP/old/$name/$rel/kb.pl" "$TMP/new/$name/$rel/kb.pl" || { echo "  note: kb.pl differs between the two copies after the calls: a tool wrote while it read"; notes=$((notes + 1)); }
    done < <(find "$TMP/old/$name" -name kb.pl | LC_ALL=C sort)
    echo "== $name: $((kbs - before)) KB(s)"
done
[ "$kbs" -gt 0 ] || die "no KB found in the hub directories"

echo "$me: $kbs KB(s): $ok ok, $bad with a violation, $skipped skipped; $total_v violation(s), $notes note(s); $((SECONDS - start)) s"
echo "  under OLD: $done_old done, $block_old blocking line(s), $open_old open item(s), $hyp_old hypothesis/3 answer(s). Under NEW: $done_new done."
for k in a b c d e f; do
    echo "  rule ($k): $([ "${RULE_V[$k]}" = 0 ] && echo pass || echo "FAIL in ${RULE_KB[$k]} KB(s), ${RULE_V[$k]} violation(s)")"
done
[ "$total_v" = 0 ]

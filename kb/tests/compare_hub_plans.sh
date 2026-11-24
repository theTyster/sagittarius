#!/usr/bin/env bash
# compare_hub_plans.sh OLD_TOOL NEW_TOOL SPECS_DIR
#
# The upgrade of a hub (hubkit.py) runs `NEW --dir KB migrate plan --old OLD` on each KB and
# refuses the upgrade when a plan does not exit 0 (ticket scientific-method-overhaul, claim c19;
# kb/CONTRACT.md D57). For each KB under SPECS_DIR this script runs that plan on a private copy
# and `migrate check` (exit 0 or 1 is an answer). A KB for which the plan of OLD on itself
# (OLD --dir KB migrate plan) already fails is listed as SKIP.
# It never writes in SPECS_DIR. Exit 0: every plan exits 0. Exit 1: one does not. Exit 2: usage.
set -u
[ $# -eq 3 ] || { echo "usage: compare_hub_plans.sh OLD_TOOL NEW_TOOL SPECS_DIR" >&2; exit 2; }
OLD=$1 NEW=$2 SPECS=$3
[ -x "$OLD" ] && [ -x "$NEW" ] && [ -d "$SPECS" ] || { echo "compare_hub_plans.sh: OLD_TOOL and NEW_TOOL must run, and SPECS_DIR must be a directory" >&2; exit 2; }
W=$(mktemp -d) || exit 2
trap 'rm -rf "$W"' EXIT
cp -r "$SPECS" "$W/specs" || exit 2
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID|CLAUDE_CODE_SESSION_ID|HUB_SESSION) unset "$v";; esac; done
export XDG_CACHE_HOME=$W/cache; mkdir -p "$XDG_CACHE_HOME"
bad=0 n=0 skipped=0
while IFS= read -r kbf; do
    d=$(dirname "$kbf"); name=${d#"$W/specs/"}; n=$((n+1))
    "$OLD" --dir "$d" migrate plan >"$W/o.out" 2>&1; orc=$?
    "$NEW" --dir "$d" migrate plan --old "$OLD" >"$W/p.out" 2>&1; rc=$?
    "$NEW" --dir "$d" migrate check >/dev/null 2>&1; crc=$?
    if [ "$rc" -eq 0 ] && [ "$crc" -le 1 ]; then echo "ok   $name (migrate check: exit $crc)"
    elif [ "$orc" -ne 0 ]; then skipped=$((skipped+1)); echo "SKIP $name: the plan of the old tool fails too (exit $orc); new: plan exit $rc, check exit $crc"
    else bad=$((bad+1)); echo "FAIL $name: migrate plan --old exits $rc, migrate check exits $crc"; grep -E 'OUTSIDE|REFUSED|refuses' "$W/p.out" | cut -c1-300 | sed 's/^/     /'; fi
done < <(find "$W/specs" -name kb.pl -not -path '*/.git/*' | LC_ALL=C sort)
echo "----"
echo "KBs=$n skipped=$skipped failed=$bad"
[ "$bad" -eq 0 ]

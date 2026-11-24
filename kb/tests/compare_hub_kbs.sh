#!/usr/bin/env bash
# compare_hub_kbs.sh OLD_TOOL NEW_TOOL SPECS_DIR
#
# The grandfather rule on real data (kb/CONTRACT.md D57; ticket scientific-method-overhaul,
# claims c20, c39, q27). For each KB under SPECS_DIR (each directory with a kb.pl), it compares
# `query done` and `query 'blocking(X)' -n 0` of the old tool (0.7.2) and of the new tool.
#   - A KB that was done must be done, and nothing may block it.
#   - A KB that was open must have at least its old blocking lines (new lines may be added).
#   - A KB for which the old tool cannot answer done (exit 2: no build module, or it does not
#     load) is listed as SKIP; its old blocking lines must still be there.
# Then, for each KB that was done, on a private copy: one write of the new tool (a note), and
# done must still hold (the first write records upgraded/2 and done_before_upgrade/2).
# It never writes in SPECS_DIR: every query runs on a copy in a temp directory.
# Exit 0: nothing lost. Exit 1: a lost done or a lost blocking line. Exit 2: usage.
set -u
[ $# -eq 3 ] || { echo "usage: compare_hub_kbs.sh OLD_TOOL NEW_TOOL SPECS_DIR" >&2; exit 2; }
OLD=$1 NEW=$2 SPECS=$3
[ -x "$OLD" ] && [ -x "$NEW" ] && [ -d "$SPECS" ] || { echo "compare_hub_kbs.sh: OLD_TOOL and NEW_TOOL must run, and SPECS_DIR must be a directory" >&2; exit 2; }
W=$(mktemp -d) || exit 2
trap 'rm -rf "$W"' EXIT
cp -r "$SPECS" "$W/specs" || exit 2
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID|CLAUDE_CODE_SESSION_ID|HUB_SESSION) unset "$v";; esac; done
export XDG_CACHE_HOME=$W/cache; mkdir -p "$XDG_CACHE_HOME"
lost=0 n=0 done_n=0 open_n=0 skipped=0 added=0
while IFS= read -r kbf; do
    d=$(dirname "$kbf"); name=${d#"$W/specs/"}
    n=$((n+1))
    "$OLD" --dir "$d" query done >/dev/null 2>&1; od=$?
    "$OLD" --dir "$d" query 'blocking(X)' -n 0 2>/dev/null | grep '^X = ' | LC_ALL=C sort > "$W/old.bl"
    "$NEW" --dir "$d" query done >/dev/null 2>&1; nd=$?
    "$NEW" --dir "$d" query 'blocking(X)' -n 0 2>/dev/null | grep '^X = ' | LC_ALL=C sort > "$W/new.bl"
    if [ "$od" -ge 2 ]; then   # no done rule (a KB that does not use build), or a KB that does not load: compare the blocking lines only
        skipped=$((skipped+1))
        miss=$(LC_ALL=C comm -23 "$W/old.bl" "$W/new.bl")
        if [ -n "$miss" ]; then lost=$((lost+1)); echo "LOST $name: no done answer (old exit $od), and old blocking lines are gone:"; printf '%s\n' "$miss" | sed 's/^/     gone: /'; continue; fi
        echo "SKIP $name: the old tool cannot answer done (exit $od; the new tool: exit $nd); its $(wc -l < "$W/old.bl") old blocking lines are kept"; continue
    fi
    if [ "$od" -eq 0 ]; then
        done_n=$((done_n+1))
        if [ "$nd" -ne 0 ]; then lost=$((lost+1)); echo "LOST $name: was done, and is not done now (exit $nd)"; sed 's/^/     now blocks: /' "$W/new.bl"; continue; fi
        if [ -s "$W/new.bl" ]; then lost=$((lost+1)); echo "LOST $name: is done, and something blocks it"; sed 's/^/     now blocks: /' "$W/new.bl"; continue; fi
        stale=$("$NEW" --dir "$d" query 'stale_grandfathered(A, C)' -n 0 2>/dev/null | grep -c '^A = ')
        cp -r "$d" "$W/one"
        "$NEW" --dir "$W/one" add "note(r1, 'compare_hub_kbs: one write of the new tool')" >/dev/null 2>&1; wr=$?
        "$NEW" --dir "$W/one" query done >/dev/null 2>&1; wd=$?
        rm -rf "$W/one"
        if [ "$wr" -ne 0 ]; then echo "NOTE $name: the write of the new tool was refused (exit $wr); done after a write was not tested"
        elif [ "$wd" -ne 0 ]; then lost=$((lost+1)); echo "LOST $name: done before a write of the new tool, and not done after it"; continue; fi
        echo "ok   $name: done stays done (stale verdicts listed: $stale)"
    else
        open_n=$((open_n+1))
        miss=$(LC_ALL=C comm -23 "$W/old.bl" "$W/new.bl")
        more=$(LC_ALL=C comm -13 "$W/old.bl" "$W/new.bl" | sed 's/^X = //' | paste -sd' ')
        if [ "$nd" -eq 0 ]; then lost=$((lost+1)); echo "LOST $name: was open, and is done now"; continue; fi
        if [ -n "$miss" ]; then lost=$((lost+1)); echo "LOST $name: open, and old blocking lines are gone:"; printf '%s\n' "$miss" | sed 's/^/     gone: /'; continue; fi
        [ -n "$more" ] && added=$((added+1))
        echo "ok   $name: open stays open ($(wc -l < "$W/old.bl") old lines kept${more:+; new: $more})"
    fi
done < <(find "$W/specs" -name kb.pl -not -path '*/.git/*' | LC_ALL=C sort)
echo "----"
echo "KBs=$n done=$done_n open=$open_n skipped=$skipped open-with-new-lines=$added lost=$lost"
[ "$lost" -eq 0 ]

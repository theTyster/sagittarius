#!/usr/bin/env bash
# Black-box tests for ticket T11 (tracker sync, drafts only), CONTRACT D25.
# The ONLY source of expected behavior is kb/CONTRACT.md (D22, D23, D25). No test reads the
# CLI or library source, except c4, which greps it for network clients (D25 C6).
#
# Usage: kb/tests/test_tracker_sync.sh [path-to-orbit-kb]
#   ORBIT_KB_BIN=/path/to/orbit-kb overrides the CLI; ORBIT_KB_TEST_LIB overrides the library.
#   ONLY='<regex>' runs only the tests whose id matches.
#   Exit 0 when every test passes, 1 when a test fails, 2 when the suite cannot run.
#
# Requirement map (D25; claims of ticket T11):
#   c1 the blocking draft carries the stamp; pin --check fails after a change : TS1-TS4
#   c2 each outbound draft names its pin and the pin's ChangedAt; pin-item     : TS5-TS9
#   c3 a conflict shows as "decide", never resolved by date                    : TS10-TS12 TS15
#   c4 no command writes to a network                                          : TS13-TS14
set -u

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
OKB=${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}
LIB=${ORBIT_KB_TEST_LIB:-$here/../share/orbit-kb}
TMO=${ORBIT_KB_TEST_TIMEOUT:-120}
for tool in swipl sha256sum timeout mktemp awk grep sed cmp sort head cp; do
    command -v "$tool" >/dev/null 2>&1 || { echo "test_tracker_sync.sh: required tool not found: $tool" >&2; exit 2; }
done
[ -x "$OKB" ] || { echo "test_tracker_sync.sh: the orbit-kb CLI is missing: $OKB" >&2; exit 2; }
OKB=$(cd "$(dirname "$OKB")" && pwd -P)/$(basename "$OKB")
[ -d "$LIB" ] && LIB=$(cd "$LIB" && pwd -P)
[ -f "$LIB/core.pl" ] || { echo "test_tracker_sync.sh: no core.pl in $LIB" >&2; exit 2; }
SRC_BIN=$OKB
SRC_LIB=$LIB

pass=0 fail=0 skip=0
failed=()
FAILS=()
SKIPMSG=""
out="" err="" rc=0
T="" K="" P=""
base=$(mktemp -d "${TMPDIR:-/tmp}/orbit-kb-ts.XXXXXX") || exit 2
base=$(cd "$base" && pwd -P)
trap 'rm -rf "$base"' EXIT
for v in $(compgen -e); do case $v in ORBIT_KB*) unset "$v";; esac; done
export ORBIT_KB_LIB="$LIB"
export ORBIT_KB_WRITER=t11-tests   # the one-writer lock of the project KB (D23)

# ---------------------------------------------------------------- reporting and assertions
snip() { printf '%s' "$1" | head -c 300 | tr '\n' '~'; }
note() { FAILS+=("$*"); }
rc_is() { [ "$rc" = "$1" ] && return 0; note "${2:+$2: }exit $rc, want $1 (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; }
out_has() { printf '%s\n' "$out" | grep -Eq -- "$1" && return 0; note "${2:+$2: }stdout lacks /$1/ (stdout: $(snip "$out"))"; return 1; }
out_hasnt() { if printf '%s\n' "$out" | grep -Eq -- "$1"; then note "${2:+$2: }stdout has /$1/, it must not (stdout: $(snip "$out"))"; return 1; fi; return 0; }
any_hasi() { printf '%s\n%s\n' "$out" "$err" | grep -Eiq -- "$1" && return 0; note "${2:+$2: }output lacks /$1/ (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; }
same_file() { cmp -s "$1" "$2" && return 0; note "${3:+$3: }the file changed ($1)"; return 1; }
sha() { sha256sum "$1" | cut -d' ' -f1; }

# okb DIR ARGS...: run the CLI with --dir DIR. Sets out, err, rc.
okb() {
    local d=$1; shift
    ( cd "$T" && exec timeout "$TMO" "$OKB" --dir "$d" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null
    rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err")
}
# okb_nonet DIR ARGS...: the same, in a new network namespace (only a loopback that is down).
okb_nonet() {
    local d=$1; shift
    ( cd "$T" && exec timeout "$TMO" unshare -rn "$OKB" --dir "$d" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null
    rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err")
}
# section ID: the lines of the draft section "### ID" in $out, up to the next heading.
section() { printf '%s\n' "$out" | awk -v id="$1" '/^#{2,3} /{on=($0 ~ "^### " id "[[:space:]]*$")} on'; }

# ---------------------------------------------------------------- fixtures
# spec KB with an unchecked claim (it blocks done), a question to ask, and a past due time
spec_kb() {
    K=$T/spec
    "$OKB" init "$K" --request 'Test request' --uses build >/dev/null 2>&1 || note "setup: init spec KB failed"
    okb "$K" add "claim(c1, preserve, 'Orders keep their number')" "cites(c1, 'Keep the order number')" \
        "due(c1, '2020-01-01T00:00:00Z')" >/dev/null || true
    [ "$rc" = 0 ] || note "setup: add to the spec KB failed: $(snip "$err")"
}
# project KB; pins and drafts are made through the CLI
project_kb() {
    P=$T/proj
    "$OKB" init "$P" --request 'Test project' --uses project >/dev/null 2>&1 || note "setup: init project KB failed"
}
# item_text FILE TEXT
item_text() { printf '%s\n' "$2" > "$1"; }
# pin ID SOURCE TEXT CHANGED_AT: record a tracker pin
pin_item() {
    item_text "$T/item-$1.txt" "$3"
    okb "$P" pin-item "$1" "$2" --text-file "$T/item-$1.txt" --changed-at "$4"
    [ "$rc" = 0 ] || note "setup: pin-item $1 failed: $(snip "$err")"
}
# draft ID PIN TEXT STAGED_AT
add_draft() {
    okb "$P" add "draft($1, $2, '$3', '$4')"
    [ "$rc" = 0 ] || note "setup: add draft $1 failed: $(snip "$err")"
}
T0=2026-10-01T09:00:00Z; T1=2026-10-02T09:00:00Z; T2=2026-10-03T09:00:00Z; T3=2026-10-04T09:00:00Z; T4=2026-10-05T09:00:00Z

# ================================================================ c1: the blocking draft and its stamp
t_TS1() { spec_kb
          okb "$K" draft blocking; rc_is 0 "draft blocking"
          out_has '^#{1,3} .*[Bb]locking' "a Markdown heading names the blocking items"
          out_has "^.*spec-kb@sha256:$(sha "$K/kb.pl")" "the stamp is the digest of kb.pl now"
          out_has '(under|to_ask|past_due|no_claim).*c1|c1.*(under|past_due)' "the blocking item c1 is listed"
          out_has 'Orders keep their number' "the item carries its text"
          out_has '2020-01-01T00:00:00Z' "a past_due item carries its due time"; }
t_TS2() { spec_kb
          okb "$K" draft blocking; rc_is 0
          local stamp; stamp=$(printf '%s\n' "$out" | grep -Eo 'spec-kb@sha256:[0-9a-f]{64}' | head -n1)
          [ -n "$stamp" ] || { note "no stamp in the draft"; return; }
          okb "$K" pin --check "$stamp"; rc_is 0 "unchanged KB: the stamp of the draft holds"
          okb "$K" add "claim(c2, preserve, 'A second claim')" "cites(c2, 'Keep the order number')" >/dev/null
          okb "$K" pin --check "$stamp"; rc_is 1 "after a change the stamp of the draft fails"
          okb "$K" draft blocking; rc_is 0
          out_has "spec-kb@sha256:$(sha "$K/kb.pl")" "a new draft carries the new stamp"
          out_hasnt "$stamp" "a new draft does not carry the old stamp"; }
t_TS3() { spec_kb; cp "$K/kb.pl" "$T/.before"; ls -A "$K" > "$T/.ls-before"
          okb "$K" draft blocking; rc_is 0
          same_file "$K/kb.pl" "$T/.before" "draft blocking writes nothing"
          ls -A "$K" > "$T/.ls-after"; same_file "$T/.ls-before" "$T/.ls-after" "draft blocking adds no file (no lock, no log)"
          okb "$K" draft blocking; local first=$out
          okb "$K" draft blocking; [ "$out" = "$first" ] || note "two drafts of an unchanged KB differ"; }
t_TS4() { spec_kb
          okb "$K" draft; rc_is 2 "draft with no subject is a usage error"
          okb "$K" draft nonsense; rc_is 2 "an unknown subject is a usage error"
          okb "$K" draft outbound; rc_is 2 "draft outbound needs a project KB (a KB that uses project)"
          okb "$K" draft blocking extra; rc_is 2 "draft blocking takes no argument"
          okb "$K" help draft; rc_is 0 "help draft exists"; out_has 'draft blocking' "help names draft blocking"; out_has 'draft outbound' "help names draft outbound"; }

# ================================================================ c2: outbound drafts name their pin
t_TS5() { project_kb
          pin_item p1 tracker:ITEM-1 'Title: Sort orders' "$T0"
          pin_item p2 tracker:ITEM-2 'Title: Export orders' "$T1"
          add_draft d1 p1 'Reword the sort title' "$T2"
          add_draft d2 p2 'Add a CSV note' "$T3"
          okb "$P" draft outbound; rc_is 0 "draft outbound"
          out_has '^#{1,3} .*[Oo]utbound' "a Markdown heading"
          local s1 s2; s1=$(section d1); s2=$(section d2)
          [ -n "$s1" ] && [ -n "$s2" ] || { note "each draft needs its own '### ID' section (stdout: $(snip "$out"))"; return; }
          printf '%s\n' "$s1" | grep -Eq '^- Pin: p1$' || note "d1 section lacks '- Pin: p1'"
          printf '%s\n' "$s1" | grep -Eq "^- ChangedAt: $T0\$" || note "d1 section lacks the ChangedAt of p1"
          printf '%s\n' "$s1" | grep -Fq 'Reword the sort title' || note "d1 section lacks the draft text"
          printf '%s\n' "$s1" | grep -Eq '^- Source: tracker:ITEM-1$' || note "d1 section lacks the source"
          printf '%s\n' "$s2" | grep -Eq '^- Pin: p2$' || note "d2 section lacks '- Pin: p2'"
          printf '%s\n' "$s2" | grep -Eq "^- ChangedAt: $T1\$" || note "d2 section lacks the ChangedAt of p2"
          printf '%s\n' "$s2" | grep -Fq "$T0" && note "d2 section names the ChangedAt of another pin"
          printf '%s\n' "$s1" | grep -Eq "^- Staged: $T2\$" || note "d1 section lacks the staged time"
          printf '%s\n' "$s1" | grep -Eq '^- Status: ready$' || note "a draft with no conflict has '- Status: ready'"; }
t_TS6() { project_kb
          pin_item p1 tracker:ITEM-1 'Title: Sort orders' "$T0"
          add_draft d1 p1 'Reword the sort title' "$T2"
          okb "$P" query 'outbound(D)'; rc_is 0 "outbound(D) holds"
          okb "$P" draft outbound; rc_is 0
          out_has '^### d1' "the drafts of the command are the answers of outbound(D)"
          ls -A "$P" > "$T/.ls-before"; cp "$P/kb.pl" "$T/.before"
          okb "$P" draft outbound; rc_is 0
          same_file "$P/kb.pl" "$T/.before" "draft outbound writes nothing"
          ls -A "$P" > "$T/.ls-after"; same_file "$T/.ls-before" "$T/.ls-after" "draft outbound adds no file and takes no lock"
          okb "$P" add "pushed(d1, '$T3')" >/dev/null
          okb "$P" draft outbound; rc_is 0 "after pushed(d1, T)"; out_hasnt '^### d1' "a pushed draft is no longer listed"
          project_kb_empty; }
project_kb_empty() { P=$T/proj-empty
          "$OKB" init "$P" --request 'Empty project' --uses project >/dev/null 2>&1 || note "setup: init failed"
          okb "$P" draft outbound; rc_is 0 "no outbound draft is not an error"
          out_has '^- Nothing to push\.$' "the empty list says so"; out_hasnt '^### ' "no draft section"; }
t_TS7() { project_kb
          pin_item p1 tracker:ITEM-1 'Title: Sort orders' "$T0"
          cp "$T/item-p1.txt" "$T/.item"
          okb "$P" query 'pin(p1, K, S, D, C)' ; rc_is 0 "the pin is a fact of the project KB"
          out_has 'tracker:ITEM-1' "its source"; out_has "$T0" "its ChangedAt"
          out_has "$(sha "$T/.item")" "its digest is the sha256 of the item text, computed by the CLI"
          okb "$P" pin-item p9 tracker:ITEM-9 --text-file "$T/.item" --changed-at "$T1"; rc_is 0
          same_file "$T/.item" "$T/item-p1.txt" "pin-item does not touch the text file"
          okb "$P" query 'pin(p9, K, S, D, C)'; out_has "$(sha "$T/.item")" "the same text gives the same digest"; }
t_TS8() { project_kb
          pin_item p1 tracker:ITEM-1 'Title: Sort orders' "$T0"
          pin_item p2 tracker:ITEM-1 'Title: Sort all orders' "$T2"
          okb "$P" query 'pin(p1, _, _, D1, _), pin(p2, _, _, D2, _), D1 \== D2'; rc_is 0 "a changed text has another digest"
          okb "$P" query 'stale_pin(p1)'; rc_is 0 "the older pin of a source is stale (T06 c2)"
          okb "$P" query 'stale_pin(p2)'; rc_is 1 "the newest pin is not stale"
          add_draft d1 p1 'Reword the sort title' "$T1"
          okb "$P" draft outbound; rc_is 0
          local s; s=$(section d1)
          printf '%s\n' "$s" | grep -Eq '^- Pin: p1$' || note "the draft names the pin it was made against (p1), not the newest"
          printf '%s\n' "$s" | grep -Eq "^- ChangedAt: $T0\$" || note "the draft names the ChangedAt of its own pin"; }
t_TS9() { project_kb; local f=$T/item.txt; printf 'x\n' > "$f"
          okb "$P" pin-item p1 tracker:ITEM-1 --text-file "$T/missing.txt" --changed-at "$T0"; rc_is 2 "a missing text file is a usage error"
          okb "$P" pin-item p1 tracker:ITEM-1 --text-file "$f"; rc_is 2 "--changed-at is required"
          okb "$P" pin-item p1 tracker:ITEM-1 --changed-at "$T0"; rc_is 2 "--text-file is required"
          okb "$P" pin-item p1 tracker:ITEM-1 --text-file "$f" --changed-at yesterday; rc_is 2 "a time that is not UTC ISO is a usage error"
          okb "$P" query 'pin(p1, _, _, _, _)'; rc_is 1 "a failed pin-item writes nothing"
          okb "$P" pin-item p1 tracker:ITEM-1 --text-file "$f" --changed-at "$T0"; rc_is 0
          okb "$P" pin-item p1 tracker:ITEM-1 --text-file "$f" --changed-at "$T1"; rc_is 1 "a second pin with the same id is a rejection"
          okb "$P" help pin-item; rc_is 0 "help pin-item exists"; out_has 'changed-at' "help names the options"; }

# ================================================================ c3: a conflict shows as "decide"
# conflict: the tracker changed after the pin's ChangedAt (a newer pin of the same source) and
# the draft was staged after the pin's ChangedAt too (D23, T06 c5).
conflict_kb() {
    project_kb
    pin_item p1 tracker:ITEM-1 'Title: Sort orders' "$T0"
    pin_item p2 tracker:ITEM-1 'Title: Sort all orders' "$T2"   # the tracker changed at T2
    add_draft dA p1 'Staged before the tracker changed' "$T1"   # T1 < T2: by date the tracker would win
    pin_item p3 tracker:ITEM-3 'Title: Other' "$T0"
    pin_item p4 tracker:ITEM-3 'Title: Other, edited' "$T1"     # the tracker changed at T1
    add_draft dB p3 'Staged after the tracker changed' "$T3"    # T3 > T1: by date the draft would win
    pin_item p5 tracker:ITEM-5 'Title: Quiet' "$T0"
    add_draft dC p5 'No tracker change' "$T3"
}
t_TS10() { conflict_kb
           okb "$P" query 'conflict(dA)'; rc_is 0 "conflict(dA)"
           okb "$P" query 'conflict(dB)'; rc_is 0 "conflict(dB)"
           okb "$P" query 'conflict(dC)'; rc_is 1 "dC is no conflict"
           okb "$P" draft outbound; rc_is 0
           local a b c; a=$(section dA); b=$(section dB); c=$(section dC)
           printf '%s\n' "$a" | grep -Eq '^- Status: decide$' || note "dA (the tracker changed after the staging) has '- Status: decide'"
           printf '%s\n' "$b" | grep -Eq '^- Status: decide$' || note "dB (the draft staged after the tracker change) has '- Status: decide'"
           printf '%s\n' "$c" | grep -Eq '^- Status: ready$' || note "dC has '- Status: ready'"
           printf '%s\n' "$a$b" | grep -Eq '^- Status: ready$' && note "a conflict is never ready"; }
t_TS11() { conflict_kb
           okb "$P" draft outbound; rc_is 0
           local a b; a=$(section dA); b=$(section dB)
           printf '%s\n' "$a" | grep -Fq 'Staged before the tracker changed' || note "dA shows its draft text (the edit is not lost)"
           printf '%s\n' "$a" | grep -Eq "^- Tracker changed: $T2\$" || note "dA shows when the tracker changed (the other side)"
           printf '%s\n' "$a" | grep -Eq '^- Pin: p1$' || note "dA names its pin"
           printf '%s\n' "$b" | grep -Fq 'Staged after the tracker changed' || note "dB shows its draft text"
           printf '%s\n' "$b" | grep -Eq "^- Tracker changed: $T1\$" || note "dB shows when the tracker changed"
           printf '%s\n' "$b" | grep -Eq "^- Staged: $T3\$" || note "dB shows its staged time"
           printf '%s\n' "$a" | grep -Eqi 'decide' || note "dA says decide"; }
t_TS12() { conflict_kb
           okb "$P" draft outbound; rc_is 0
           local a b; a=$(section dA); b=$(section dB)
           printf '%s\n%s\n' "$a" "$b" | grep -Eqi 'supersed|overrid|overwr|wins|resolved|newer|later|latest|dropped|auto' && note "a conflict section decides by date or hides a side (found a word that picks a side)"
           printf '%s\n' "$a" | grep -Eq '^- Decide: .*(tracker|draft)' || note "dA has a '- Decide:' line that names the two sides"
           # the same decision whatever the order of times: both conflicts get the same status word
           local sa sb
           sa=$(printf '%s\n' "$a" | grep -E '^- Status:'); sb=$(printf '%s\n' "$b" | grep -E '^- Status:')
           [ -n "$sa" ] && [ "$sa" = "$sb" ] || note "both orders of times give the same status (got '$sa' and '$sb')"
           okb "$P" draft outbound >/dev/null; local first=$out; okb "$P" draft outbound; [ "$out" = "$first" ] || note "the draft does not change when nothing changed"
           okb "$P" query 'conflict(D)' -n 0; rc_is 0 "conflict(D) lists the conflicts"; }

# A conflict also blocks a spec KB that pins the decision the conflict concerns (D23 P5); the
# blocking draft shows it as "decide" as well.
t_TS15() { conflict_kb
           okb "$P" add "decision(dec1, 'Orders are sorted by number')" "concerns(dec1, p1)" "concerns(dec1, p3)" >/dev/null || note "setup: decision"
           local dg; dg=sha256:$(printf '%s' 'Orders are sorted by number' | sha256sum | cut -d' ' -f1)
           K=$T/spec2; "$OKB" init "$K" --request 'Test request' --uses build,project >/dev/null 2>&1 || note "setup: init spec KB"
           okb "$K" add "project_kb('$P')" "claim(c1, preserve, 'Orders keep their number')" "cites(c1, 'Keep the order number')" \
               "pins(c1, project, dec1, '$dg')" >/dev/null || note "setup: add to the spec KB: $(snip "$err")"
           okb "$K" query 'blocking(project_conflict(X))'; rc_is 0 "the conflict blocks the spec KB that pins dec1"
           okb "$K" draft blocking; rc_is 0
           out_has '^- project_conflict dA.*decide' "the blocking draft lists the conflict as decide"
           out_has '^- project_conflict dB.*decide' "also the conflict where the draft is the later side"
           out_hasnt 'project_conflict dC' "a draft without a conflict is not listed"; }

# ================================================================ c4: no command writes to a network
# Each T11 command runs in a new network namespace (unshare -rn) with only a down loopback:
# a connection would fail, and the command must still succeed. When unshare is not usable the
# commands run with a proxy at a closed port in the environment. And the source has no client.
nonet_run() {   # nonet_run DIR ARGS...
    if [ "${NONET:-}" = unshare ]; then okb_nonet "$@"
    else
        ( cd "$T" && exec env http_proxy=http://127.0.0.1:9 https_proxy=http://127.0.0.1:9 HTTP_PROXY=http://127.0.0.1:9 \
            HTTPS_PROXY=http://127.0.0.1:9 ALL_PROXY=http://127.0.0.1:9 no_proxy= \
            timeout "$TMO" "$OKB" --dir "$1" "${@:2}" ) >"$T/.out" 2>"$T/.err" </dev/null
        rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err")
    fi
}
t_TS13() { NONET=proxy; unshare -rn true 2>/dev/null && NONET=unshare
           spec_kb; conflict_kb
           nonet_run "$K" draft blocking; rc_is 0 "draft blocking with no network ($NONET)"; out_has 'spec-kb@sha256:[0-9a-f]{64}' "its output is complete"
           nonet_run "$P" draft outbound; rc_is 0 "draft outbound with no network ($NONET)"; out_has '^### dA' "its output is complete"
           item_text "$T/n.txt" 'Title: N'
           nonet_run "$P" pin-item p9 tracker:ITEM-9 --text-file "$T/n.txt" --changed-at "$T4"; rc_is 0 "pin-item with no network ($NONET)"
           cp "$P/kb.pl" "$T/.before"
           nonet_run "$P" draft outbound; rc_is 0
           same_file "$P/kb.pl" "$T/.before" "draft outbound writes nothing to the project KB"
           true; }
t_TS14() { local pat='http_open|http_get|http_post|http_delete|http_put|http/http_client|http/http_open|library\(socket\)|tcp_connect|\bcurl\b|\bwget\b|\bglab\b|\bgh (pr|issue|api)\b|\btea (issues|pulls)\b|url_connect'
           local files hits
           files="$SRC_BIN $(find "$SRC_LIB" -name '*.pl' 2>/dev/null | sort | tr '\n' ' ')"
           hits=$(grep -nE -- "$pat" $files 2>/dev/null | head -5)
           [ -z "$hits" ] || note "the CLI or library names a network client: $(snip "$hits")"
           # and the new commands exist, so that an empty grep is not a pass on an unchanged tool
           project_kb; okb "$P" draft outbound; rc_is 0 "the command exists"
           okb "$P" help draft; any_hasi 'no network|never (post|push|write)|drafts only' "help draft says that nothing goes to a tracker"; }

# ---------------------------------------------------------------- driver
for fn in $(declare -F | awk '{print $3}' | grep -E '^t_TS[0-9]+$' | sort -t S -k2 -n); do
    id=${fn#t_}
    if [ -n "${ONLY:-}" ] && ! [[ $id =~ $ONLY ]]; then continue; fi
    T=$(mktemp -d "$base/$id.XXXXXX"); T=$(cd "$T" && pwd -P)
    FAILS=(); SKIPMSG=""; out=""; err=""; rc=0; K=""; P=""
    XDG_CACHE_HOME=$T/.cache; export XDG_CACHE_HOME; mkdir "$XDG_CACHE_HOME"
    cd "$T" && "$fn" </dev/null; cd "$here"
    if [ ${#FAILS[@]} -eq 0 ]; then pass=$((pass+1)); echo "PASS $id"
    else fail=$((fail+1)); failed+=("$id"); echo "FAIL $id"; for m in "${FAILS[@]}"; do echo "     - $m"; done; fi
    rm -rf "$T"
done
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]

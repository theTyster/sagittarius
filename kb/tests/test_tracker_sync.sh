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
#      (T43 c3 amends c3, Ty's u123: the dates decide and nothing blocks. TS10-TS13, TS15 and TS19
#      are amended to the date rule; each amendment is marked "T43 c3 amended".)
#   c4 no command writes to a network                                          : TS13-TS14
#   text injection (Markdown and HTML in free text), help project              : TS16-TS20
#   T18 c6: draft outbound with no draft facts names --dir PROJECT          : TS21
#   T22 c6: draft attach names the file to attach and the line to paste     : TS60-TS61
# Ticket T43 c3 (CONTRACT D25 T3 and D23 P4 amended; u123, u66): when the tracker and a draft both
# changed after the pin, the later edit wins (equal times: the tracker), nothing blocks, the losing
# side is dropped(D, Side), and `project dropped` records it in the hub ledger once:
#   tracker later: the draft is dropped, one ledger item                       : TS30
#   draft later: the draft is outbound and ready, the tracker text dropped     : TS31
#   equal times: the tracker wins                                              : TS32
#   a human's resolved() still wins over the dates, and gets no ledger item    : TS33
#   it blocks no spec KB; draft blocking and outbound never say decide         : TS34
#   help project, the README and CONTRACT state the date rule                  : TS35
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
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID|CLAUDE_CODE_SESSION_ID|HUB_SESSION) unset "$v";; esac; done
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
t_TS10() { conflict_kb   # T43 c3 amended: was "dA and dB are conflicts and say decide"
           okb "$P" query 'dropped(dA, draft)'; rc_is 0 "dA: the tracker changed later, so the draft is dropped"
           okb "$P" query 'outbound(dB)'; rc_is 0 "dB: the draft is later, so it is outbound"
           okb "$P" query 'outbound(dC)'; rc_is 0 "dC: no tracker change"
           okb "$P" draft outbound; rc_is 0
           local a b c; a=$(section dA); b=$(section dB); c=$(section dC)
           [ -z "$a" ] || note "dA lost by date and is not listed"
           printf '%s\n' "$b" | grep -Eq '^- Status: ready$' || note "dB (the draft staged after the tracker change) has '- Status: ready'"
           printf '%s\n' "$c" | grep -Eq '^- Status: ready$' || note "dC has '- Status: ready'"
           printf '%s\n' "$out" | grep -Eqi 'decide' && note "no draft says decide"; return 0; }
t_TS11() { conflict_kb   # T43 c3 amended: dA lost by date, so only dB (the draft won) shows both sides
           okb "$P" draft outbound; rc_is 0
           local b; b=$(section dB)
           printf '%s\n' "$b" | grep -Eq '^- Pin: p3$' || note "dB names its pin"
           printf '%s\n' "$b" | grep -Fq 'Staged after the tracker changed' || note "dB shows its draft text"
           printf '%s\n' "$b" | grep -Eq "^- Tracker changed: $T1\$" || note "dB shows when the tracker changed"
           printf '%s\n' "$b" | grep -Eq "^- Staged: $T3\$" || note "dB shows its staged time"
           okb "$P" query 'draft(dA, _, _, _)'; rc_is 0 "the dropped draft dA stays in the project KB"; }
t_TS12() { conflict_kb   # T43 c3 amended: was "a conflict section has a Decide line and the same status for both orders"
           okb "$P" draft outbound; rc_is 0
           printf '%s\n' "$out" | grep -Eq '^- Decide:' && note "no section has a '- Decide:' line"
           okb "$P" draft outbound >/dev/null; local first=$out; okb "$P" draft outbound; [ "$out" = "$first" ] || note "the draft does not change when nothing changed"
           okb "$P" query 'dropped(D, S)' -n 0; rc_is 0 "dropped(D, S) lists the losing sides"
           out_has 'D = dA, S = draft' "dA: the draft side lost"; out_has 'D = dB, S = tracker' "dB: the tracker side lost"; }

# T43 c3 amended: a draft whose pin both sides changed no longer blocks a spec KB that pins the
# decision it concerns (was: it blocks, and the blocking draft shows it as "decide").
t_TS15() { conflict_kb
           okb "$P" add "decision(dec1, 'Orders are sorted by number')" "concerns(dec1, p1)" "concerns(dec1, p3)" >/dev/null || note "setup: decision"
           local dg; dg=sha256:$(printf '%s' 'Orders are sorted by number' | sha256sum | cut -d' ' -f1)
           K=$T/spec2; "$OKB" init "$K" --request 'Test request' --uses build,project >/dev/null 2>&1 || note "setup: init spec KB"
           okb "$K" add "project_kb('$P')" "claim(c1, preserve, 'Orders keep their number')" "cites(c1, 'Keep the order number')" \
               "pins(c1, project, dec1, '$dg')" >/dev/null || note "setup: add to the spec KB: $(snip "$err")"
           okb "$K" query 'blocking(project_conflict(X))'; rc_is 1 "nothing blocks the spec KB that pins dec1"
           okb "$K" draft blocking; rc_is 0
           out_hasnt 'project_conflict' "the blocking draft lists no conflict"
           out_hasnt '[Dd]ecide' "and says decide nowhere"; }

# ================================================================ c4: no command writes to a network
# Each T11 command runs traced (see traced_run): any AF_INET/AF_INET6 socket, connect, or
# sendto fails the test, even when the command swallows the error and succeeds. TS13 first
# proves the tracer by a deliberate tcp_connect. TS14 greps the source for clients.
# traced_run DIR ARGS...: run the CLI so that any inet socket or connect is recorded in $T/.net.
# Method, in order: strace -f (trace=socket,connect,sendto); else an LD_PRELOAD shim (built with cc)
# that logs socket()/connect()/sendto() of AF_INET and AF_INET6; else unshare -rn plus stderr
# only (weak: a swallowed connect is not seen). Under unshare -rn when it is usable, so that a
# connect could not leave the machine anyway. NETMETHOD names the method that was used.
NETMETHOD=""
net_setup() {
    [ -n "$NETMETHOD" ] && return 0
    NETNS=""; unshare -rn true 2>/dev/null && NETNS=1
    if [ "${TRACKER_SYNC_NONET:-}" = weak ]; then NETMETHOD=unshare-stderr   # force the weak method (to test the skip)
    elif command -v strace >/dev/null 2>&1; then NETMETHOD=strace
    elif command -v cc >/dev/null 2>&1 && cat > "$base/netshim.c" <<'CSRC' && cc -shared -fPIC -O1 -o "$base/netshim.so" "$base/netshim.c" -ldl 2>/dev/null; then NETMETHOD=preload
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
static void note(const char *what, int fam) {
    const char *p = getenv("NETSHIM_LOG");
    if (!p) return;
    FILE *f = fopen(p, "a");
    if (f) { fprintf(f, "%s AF_INET%s\n", what, fam == AF_INET6 ? "6" : ""); fclose(f); }
}
int socket(int d, int t, int p) {
    static int (*real)(int, int, int);
    if (!real) real = dlsym(RTLD_NEXT, "socket");
    if (d == AF_INET || d == AF_INET6) note("socket", d);
    return real(d, t, p);
}
int connect(int fd, const struct sockaddr *a, socklen_t l) {
    static int (*real)(int, const struct sockaddr *, socklen_t);
    if (!real) real = dlsym(RTLD_NEXT, "connect");
    if (a && (a->sa_family == AF_INET || a->sa_family == AF_INET6)) note("connect", a->sa_family);
    return real(fd, a, l);
}
ssize_t sendto(int fd, const void *b, size_t n, int fl, const struct sockaddr *a, socklen_t l) {
    static ssize_t (*real)(int, const void *, size_t, int, const struct sockaddr *, socklen_t);
    if (!real) real = dlsym(RTLD_NEXT, "sendto");
    if (a && (a->sa_family == AF_INET || a->sa_family == AF_INET6)) note("sendto", a->sa_family);
    return real(fd, b, n, fl, a, l);
}
CSRC
    else NETMETHOD=unshare-stderr; fi
}
traced_cmd() {   # traced_cmd CMD ARGS...: run any command traced. Sets out, err, rc; $T/.net has the inet calls.
    net_setup; : > "$T/.net"
    local pre=()
    [ -n "$NETNS" ] && pre=(unshare -rn)
    case $NETMETHOD in
        strace) ( cd "$T" && exec timeout "$TMO" "${pre[@]}" strace -f -qq -e trace=socket,connect,sendto -o "$T/.strace" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null; rc=$?
                grep -E 'AF_INET6?[,)]|sa_family=AF_INET' "$T/.strace" > "$T/.net" 2>/dev/null ;;
        preload) ( cd "$T" && exec timeout "$TMO" "${pre[@]}" env LD_PRELOAD="$base/netshim.so" NETSHIM_LOG="$T/.net" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null; rc=$? ;;
        *) ( cd "$T" && exec timeout "$TMO" "${pre[@]}" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null; rc=$?
           grep -Ei 'network|connect|socket|resolve|host' "$T/.err" > "$T/.net" 2>/dev/null ;;
    esac
    out=$(<"$T/.out"); err=$(<"$T/.err")
}
traced_run() { local d=$1; shift; traced_cmd "$OKB" --dir "$d" "$@"; }
no_net() {   # no_net LABEL: the last traced run made no inet socket, connect, or sendto
    [ -s "$T/.net" ] && note "$1: network use ($NETMETHOD): $(snip "$(head -3 "$T/.net")")"; return 0
}
t_TS13() { net_setup
           # the harness itself: a deliberate connect must be seen, or the method proves nothing
           traced_cmd swipl -q -g "catch(tcp_connect(localhost:9, _, []), _, true)" -t halt
           if [ "$NETMETHOD" = unshare-stderr ]; then SKIPMSG="weak method only (no strace, no cc): a swallowed connect is not seen. The other checks of this test still ran."
           else [ -s "$T/.net" ] || note "the harness ($NETMETHOD) did not see a deliberate connect"; fi
           spec_kb; conflict_kb
           traced_run "$K" draft blocking; rc_is 0 "draft blocking ($NETMETHOD)"; out_has 'spec-kb@sha256:[0-9a-f]{64}' "its output is complete"; no_net "draft blocking"
           traced_run "$P" draft outbound; rc_is 0 "draft outbound ($NETMETHOD)"; out_has '^### dB' "its output is complete (T43 c3 amended: dA lost by date, dB is listed)"; no_net "draft outbound"
           item_text "$T/n.txt" 'Title: N'
           traced_run "$P" pin-item p9 tracker:ITEM-9 --text-file "$T/n.txt" --changed-at "$T4"; rc_is 0 "pin-item ($NETMETHOD)"; no_net "pin-item"
           cp "$P/kb.pl" "$T/.before"
           traced_run "$P" draft outbound; rc_is 0
           same_file "$P/kb.pl" "$T/.before" "draft outbound writes nothing to the project KB"
           no_net "draft outbound again"
           echo "     (c4 method: $NETMETHOD${NETNS:+ in unshare -rn})"; }
t_TS14() { local pat='http_open|http_get|http_post|http_delete|http_put|http/http_client|http/http_open|library\(socket\)|tcp_connect|\bcurl\b|\bwget\b|\bglab\b|\bgh (pr|issue|api)\b|\btea (issues|pulls)\b|url_connect'
           local files hits
           files="$SRC_BIN $(find "$SRC_LIB" -name '*.pl' 2>/dev/null | sort | tr '\n' ' ')"
           hits=$(grep -nE -- "$pat" $files 2>/dev/null | head -5)
           [ -z "$hits" ] || note "the CLI or library names a network client: $(snip "$hits")"
           # and the new commands exist, so that an empty grep is not a pass on an unchanged tool
           project_kb; okb "$P" draft outbound; rc_is 0 "the command exists"
           okb "$P" help draft; any_hasi 'no network|never (post|push|write)|drafts only' "help draft says that nothing goes to a tracker"; }


# ================================================================ text injection (review of T11)
# Free text (a draft text, a source, a claim text) is pasted into a tracker that renders Markdown
# and HTML. D25 T7: it is escaped (& < > ` | [ ] \), and a text of more than one line puts every
# line after the first under the bullet as a block with the prefix "  > ", so no line of it can start
# a heading, a list item, or a fake status line.
EVIL=$'one\n## Heading\n- Status: ready\n<script>alert(1)</script> <img src=x onerror=alert(2)> a | b `c` [x](http://example.test/)'
EVILA="one\\n## Heading\\n- Status: ready\\n<script>alert(1)</script> <img src=x onerror=alert(2)> a | b \`c\` [x](http://example.test/)"
safe_md() {   # safe_md LABEL: the stdout in $out has no live injection
    local l=$1
    [ "$(printf '%s\n' "$out" | grep -c '^## ')" = 1 ] || note "$l: a forged '## ' heading line"
    printf '%s\n' "$out" | grep -Eq '^#{1,6} Heading' && note "$l: a forged heading"
    printf '%s\n' "$out" | grep -Eq '<(script|img)' && note "$l: raw HTML passes through"
    printf '%s\n' "$out" | grep -Eq '(^|[^\\])[|]' && note "$l: an unescaped pipe"
    printf '%s\n' "$out" | grep -Eq '(^|[^\\])`' && note "$l: an unescaped backtick"
    printf '%s\n' "$out" | grep -Eq '(^|[^\\])\]\(' && note "$l: a live link"
    printf '%s\n' "$out" | grep -Fq 'Heading' || note "$l: the text is lost (it must show, escaped)"
    printf '%s\n' "$out" | grep -Fq '&lt;script&gt;' || note "$l: < and > are not escaped as &lt; and &gt;"
    printf '%s\n' "$out" | grep -Eq '^  > ## Heading' || note "$l: the lines after the first are not a '  > ' block"
    return 0
}
t_TS16() { project_kb
           pin_item p1 tracker:ITEM-1 'Title: Sort orders' "$T0"
           okb "$P" add "draft(d1, p1, '$EVILA', '$T2')" >/dev/null || note "setup: add the draft: $(snip "$err")"
           okb "$P" draft outbound; rc_is 0 "draft outbound"
           safe_md "draft text"
           [ "$(printf '%s\n' "$out" | grep -c '^- Status:')" = 1 ] || note "one status line for the one draft (a text forged another)"
           [ "$(printf '%s\n' "$out" | grep -c '^### ')" = 1 ] || note "one section for the one draft"; }
t_TS17() { project_kb
           item_text "$T/i.txt" 'x'
           okb "$P" pin-item p1 "$EVIL" --text-file "$T/i.txt" --changed-at "$T0"; rc_is 0 "a source with a newline is recorded as given"
           add_draft d1 p1 'Plain text' "$T2"
           okb "$P" draft outbound; rc_is 0 "draft outbound"
           safe_md "source"
           [ "$(printf '%s\n' "$out" | grep -c '^- Status:')" = 1 ] || note "one status line (a source forged another)"
           project_kb_ids; }
project_kb_ids() { local P2=$T/proj2; "$OKB" init "$P2" --request 'Ids' --uses project >/dev/null 2>&1
           item_text "$T/j.txt" 'y'
           okb "$P2" pin-item p1 tracker:I-1 --text-file "$T/j.txt" --changed-at "$T0" >/dev/null
           okb "$P2" add "draft('d\\n## Fake', p1, 'ok', '$T2')" >/dev/null || note "setup: odd id"
           okb "$P2" draft outbound; rc_is 0 "an odd draft id"
           [ "$(printf '%s\n' "$out" | grep -c '^#\{1,6\} ')" = 2 ] || note "a draft id forged a heading (want the title and one section heading)"; }
t_TS18() { K=$T/spec
           "$OKB" init "$K" --request 'Test request' --uses build >/dev/null 2>&1 || note "setup: init"
           okb "$K" add "claim(c1, preserve, '$EVILA')" "cites(c1, 'Keep it')" >/dev/null || note "setup: add the claim: $(snip "$err")"
           okb "$K" draft blocking; rc_is 0 "draft blocking"
           safe_md "claim text"
           printf '%s\n' "$out" | grep -Eq '^- Status:' && note "a claim text forged a status line"
           printf '%s\n' "$out" | grep -Fxq -- '- Nothing blocks done.' && note "a claim text forged '- Nothing blocks done.'"
           okb "$K" pin --check "$(printf '%s\n' "$out" | grep -Eo 'spec-kb@sha256:[0-9a-f]{64}' | head -n1)"; rc_is 0 "the stamp is still the stamp of kb.pl"; }
t_TS19() { conflict_kb
           okb "$P" add "draft(dE, p5, '$EVILA', '$T4')" >/dev/null
           pin_item p6 tracker:ITEM-5 'Title: Quiet, edited' "$T3"   # the tracker changed at T3, the draft was staged at T4
           okb "$P" add "decision(dec1, 'Orders are sorted by number')" "concerns(dec1, p5)" >/dev/null || note "setup: decision"
           local dg; dg=sha256:$(printf '%s' 'Orders are sorted by number' | sha256sum | cut -d' ' -f1)
           K=$T/spec2; "$OKB" init "$K" --request 'Test request' --uses build,project >/dev/null 2>&1 || note "setup: init spec KB"
           okb "$K" add "project_kb('$P')" "claim(c1, preserve, 'Orders keep their number')" "cites(c1, 'Keep the order number')" \
               "pins(c1, project, dec1, '$dg')" >/dev/null || note "setup: add to the spec KB: $(snip "$err")"
           # T43 c3 amended: dE is no conflict now (the draft is later and wins), so the odd text shows
           # in draft outbound, not in draft blocking (was: "- project_conflict dE" in draft blocking)
           okb "$K" draft blocking; rc_is 0 "draft blocking"
           out_hasnt 'project_conflict' "no draft blocks"
           okb "$P" draft outbound; rc_is 0 "draft outbound"
           out_has '^### dE' "the draft with the odd text is listed"
           safe_md "draft text of a draft that won by date"
           [ "$(printf '%s\n' "$out" | grep -c '^- Status:')" = "$(printf '%s\n' "$out" | grep -c '^### ')" ] || note "a draft text forged a status line"; }
t_TS20() { okb_nokb help project; rc_is 0 "help project"
           printf '%s\n' "$out" | grep -E 'write command' | grep -Fq 'pin-item' || note "help project lists pin-item among the write commands of the writer lock"; }
# TS21 (T18 c6): draft outbound in a KB with no draft facts says that it reads only this KB and
# names --dir PROJECT, so an owner who ran it in a spec KB (or the wrong KB) is not told only
# "Nothing to push.". A KB that has drafts, all pushed, gets no such line.
t_TS21() { project_kb_empty
           out_hasi_ts 'only this KB' "a KB with no draft facts: the output says it reads only this KB"
           out_has '--dir PROJECT' "a KB with no draft facts: the output names --dir PROJECT"
           K=$T/spec-p; "$OKB" init "$K" --request 'Test request' --uses build,project >/dev/null 2>&1 || note "setup: init spec KB"
           okb "$K" draft outbound; rc_is 0 "a spec KB with the project module and no draft"
           out_has '^- Nothing to push\.$' "the empty list says so"
           out_hasi_ts 'only this KB' "a spec KB with no draft facts: the output says it reads only this KB"
           out_has '--dir PROJECT' "a spec KB with no draft facts: the output names --dir PROJECT"
           project_kb; pin_item p1 tracker:ITEM-1 'Title: Sort orders' "$T0"; add_draft d1 p1 'A draft' "$T1"
           okb "$P" add "pushed(d1, '$T2')" >/dev/null
           okb "$P" draft outbound; rc_is 0; out_has '^- Nothing to push\.$' "every draft is pushed"
           if printf '%s\n' "$out" | grep -Fiq 'only this KB'; then note "a KB that has draft facts gets no 'only this KB' line"; fi; }
# T22 c6 (u93): draft attach names the spec KB file to attach to the tracker item and the line to
# paste. It copies nothing, writes nothing and posts nothing; a human attaches the file.
t_TS60() { spec_kb; cp "$K/kb.pl" "$T/.before"; ls -A "$K" > "$T/.ls-before"
           okb "$K" draft attach; rc_is 0 "draft attach"
           out_has "^- File: $K/kb\\.pl\$" "the file to attach is the absolute path of kb.pl"
           out_has "^- Stamp: spec-kb@sha256:$(sha "$K/kb.pl")\$" "the stamp is the digest of kb.pl now"
           out_has "^- Paste: .*spec-kb@sha256:$(sha "$K/kb.pl")" "the line to paste carries the stamp"
           out_has 'human attaches' "a human attaches the file; nothing is posted"
           same_file "$K/kb.pl" "$T/.before" "draft attach writes nothing"
           ls -A "$K" > "$T/.ls-after"; same_file "$T/.ls-before" "$T/.ls-after" "draft attach adds no file"; }
t_TS61() { spec_kb
           okb "$K" draft attach extra; rc_is 2 "draft attach takes no argument"
           okb "$K" draft attach; local first=$out
           okb "$K" add "claim(c2, preserve, 'A second claim')" "cites(c2, 'Keep the order number')" >/dev/null
           okb "$K" draft attach; rc_is 0
           out_has "spec-kb@sha256:$(sha "$K/kb.pl")" "after a change the stamp is new"
           [ "$out" != "$first" ] || note "the stamp did not change with the KB"
           okb "$K" help draft; rc_is 0; out_has 'draft attach' "help draft names draft attach"
           out_has 'a human pastes it' "help draft says a human pastes it"
           out_hasnt 'Paste it' "help draft does not give the order Paste it"; }
out_hasi_ts() { printf '%s\n' "$out" | grep -Fiq -- "$1" && return 0; note "${2:+$2: }stdout lacks '$1' (stdout: $(snip "$out"))"; return 1; }
okb_nokb() { ( cd "$T" && exec timeout "$TMO" "$OKB" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null; rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err"); }

# ================================================================ T43 c3: the dates decide (u123, u66)
REPO=$(cd "$here/../.." && pwd -P)
# hub_pk: a hub $T/hub with the ledger (seeded sessions) and the project KB at its root, P=$T/hub/project-kb
hub_pk() {
    H=$T/hub; mkdir -p "$H/.claude/scripts"
    cp "$REPO/hubkit/hub/.claude/scripts/hubflow.py" "$H/.claude/scripts/"
    cp "$REPO/hubkit/hub/flow/seed.json" "$H/seed.json"
    ( cd "$H" && python3 .claude/scripts/hubflow.py --hub "$H" init --seed seed.json ) >/dev/null 2>&1 || note "setup: hub init failed"
    P=$H/project-kb
    "$OKB" init "$P" --request 'Test project' --uses project >/dev/null 2>&1 || note "setup: init project KB failed"
}
# dropped_run: project dropped, as the build session of the hub
dropped_run() { ( cd "$T" && HUB_SESSION=build exec timeout "$TMO" "$OKB" --dir "$P" project dropped "$@" ) >"$T/.out" 2>"$T/.err" </dev/null
                rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err"); }
# ledger PYEXPR [LABEL]: rows = every ledger item (id, kind, status, title, refs); the expression must hold
ledger() {
    ( cd "$H" && python3 .claude/scripts/hubflow.py --hub "$H" sql "SELECT i.id, i.kind, i.status, i.title, (SELECT group_concat(r.kind || ':' || r.ref, ' ') FROM item_ref r WHERE r.item_id = i.id) AS refs FROM item i ORDER BY i.id" --format json ) >"$T/.ledger.json" 2>"$T/.ledger.err"
    python3 -I -c "import json,sys; rows=json.load(open(sys.argv[1])); sys.exit(0 if ($1) else 1)" "$T/.ledger.json" 2>/dev/null \
        || note "${2:+$2: }ledger: not ($1): $(snip "$(cat "$T/.ledger.json" "$T/.ledger.err")")"
}
t_TS30() { hub_pk   # tracker later: the draft is dropped, nothing blocks, one ledger item
           pin_item p1 tracker:ITEM-1 'Title: Sort orders' "$T0"
           pin_item p2 tracker:ITEM-1 'Title: Sort all orders' "$T2"
           add_draft dA p1 'Sort orders by their number' "$T1"
           okb "$P" query 'supersedes_by_date(dA, tracker)'; rc_is 0 "the tracker is later and wins"
           okb "$P" query 'dropped(dA, draft)'; rc_is 0 "the draft is dropped"
           okb "$P" query 'outbound(dA)'; rc_is 1 "a dropped draft is not outbound"
           okb "$P" query 'draft(dA, p1, _, _)'; rc_is 0 "the dropped draft stays in the project KB"
           dropped_run; rc_is 0 "project dropped"
           out_has 'dA' "it names the draft it recorded"
           ledger "len(rows) == 1" "one ledger item"
           ledger "rows[0]['status'] == 'open'" "the item is open"
           ledger "all(w in rows[0]['title'] + ' ' + (rows[0]['refs'] or '') for w in ['dA', 'p1', '$T2', '$T1', 'draft'])" "the item names the draft, the pin, both times and the side that lost"
           ledger "'kb:project-kb' in (rows[0]['refs'] or '').split()" "the item has a kb ref to the project KB"
           dropped_run; rc_is 0 "project dropped again"
           ledger "len(rows) == 1" "a second run adds no item"; }
t_TS31() { hub_pk   # draft later: the draft wins and is outbound; the tracker text is dropped; one ledger item
           pin_item p3 tracker:ITEM-3 'Title: Other' "$T0"
           pin_item p4 tracker:ITEM-3 'Title: Other, edited' "$T1"
           add_draft dB p3 'Other, as we want it' "$T3"
           okb "$P" query 'supersedes_by_date(dB, draft)'; rc_is 0 "the draft is later and wins"
           okb "$P" query 'outbound(dB)'; rc_is 0 "the draft is outbound"
           okb "$P" query 'dropped(dB, tracker)'; rc_is 0 "the tracker text is dropped"
           okb "$P" draft outbound; rc_is 0
           local b; b=$(section dB)
           printf '%s\n' "$b" | grep -Eq '^- Status: ready$' || note "dB has '- Status: ready'"
           dropped_run; rc_is 0 "project dropped"
           ledger "len(rows) == 1" "one ledger item"
           ledger "all(w in rows[0]['title'] for w in ['dB', 'p3', '$T1', '$T3', 'tracker'])" "the item names the draft, the pin, both times and the tracker side"
           ledger "rows[0]['status'] == 'open' and 'kb:project-kb' in (rows[0]['refs'] or '').split()" "open, with the kb ref"; }
t_TS32() { project_kb   # equal times: the tracker wins (review's default, u66)
           pin_item p5 tracker:ITEM-5 'Title: Quiet' "$T0"
           pin_item p6 tracker:ITEM-5 'Title: Quiet, edited' "$T2"
           add_draft dC p5 'Same second' "$T2"
           okb "$P" query 'supersedes_by_date(dC, tracker)'; rc_is 0 "equal times: the tracker wins"
           okb "$P" query 'dropped(dC, draft)'; rc_is 0 "the draft is dropped"
           okb "$P" query 'outbound(dC)'; rc_is 1 "it is not outbound"; }
t_TS33() { hub_pk   # a human's resolved() wins over the dates and gets no ledger item
           pin_item p1 tracker:ITEM-1 'Title: Sort orders' "$T0"
           pin_item p2 tracker:ITEM-1 'Title: Sort all orders' "$T2"
           add_draft dA p1 'Sort orders by their number' "$T1"
           okb "$P" add "resolved(dA, draft, '$T3')"; rc_is 0 "a human settles it for the draft"
           okb "$P" query 'dropped(dA, tracker)'; rc_is 0 "the tracker side is dropped, by the human"
           okb "$P" query 'dropped(dA, draft)'; rc_is 1 "the draft is not dropped, though the tracker is later"
           okb "$P" query 'outbound(dA)'; rc_is 0 "the draft can go out"
           dropped_run; rc_is 0 "project dropped"
           ledger "len(rows) == 0" "a human's choice is not lost quietly: no ledger item"; }
t_TS34() { conflict_kb   # nothing blocks: no project_conflict item, no decide anywhere
           okb "$P" add "decision(dec1, 'Orders are sorted by number')" "concerns(dec1, p1)" "concerns(dec1, p3)" >/dev/null || note "setup: decision"
           local dg; dg=sha256:$(printf '%s' 'Orders are sorted by number' | sha256sum | cut -d' ' -f1)
           K=$T/spec2; "$OKB" init "$K" --request 'Test request' --uses build,project >/dev/null 2>&1 || note "setup: init spec KB"
           okb "$K" add "project_kb('$P')" "claim(c1, preserve, 'Orders keep their number')" "cites(c1, 'Keep the order number')" \
               "pins(c1, project, dec1, '$dg')" >/dev/null || note "setup: add to the spec KB: $(snip "$err")"
           okb "$K" query 'blocking(X)' -n 0
           out_hasnt 'project_conflict' "no blocking item for a draft"
           okb "$K" show blocking; out_hasnt 'project_conflict' "show blocking lists no conflict"
           okb "$K" draft blocking; out_hasnt '[Dd]ecide' "draft blocking says decide nowhere"
           okb "$P" draft outbound; out_hasnt '[Dd]ecide' "draft outbound says decide nowhere"; }
t_TS35() { okb_nokb help project; rc_is 0 "help project"
           out_hasnt 'only a human can pick' "help project no longer says only a human can pick"
           out_has 'later edit wins' "help project states that the later edit wins"
           out_has '[Ee]qual times' "help project states the rule for equal times"
           out_has 'project dropped' "help project documents project dropped"
           grep -Fq 'only a human can pick' "$LIB/README.md" && note "the README no longer says only a human can pick"
           grep -Fq 'never picks a side by date' "$LIB/README.md" && note "the README no longer says the command never picks a side by date"
           grep -Fq 'project dropped' "$LIB/README.md" || note "the README documents project dropped"
           local c=$here/../CONTRACT.md
           grep -Eq 'T43 c3' "$c" || note "CONTRACT names the T43 c3 amendment"
           grep -Fq 'only a human can pick' "$c" && note "CONTRACT no longer says only a human can pick"
           grep -Fq 'project dropped' "$c" || note "CONTRACT documents project dropped"
           return 0; }

# ---------------------------------------------------------------- driver
for fn in $(declare -F | awk '{print $3}' | grep -E '^t_TS[0-9]+$' | sort -t S -k2 -n); do
    id=${fn#t_}
    if [ -n "${ONLY:-}" ] && ! [[ $id =~ $ONLY ]]; then continue; fi
    T=$(mktemp -d "$base/$id.XXXXXX"); T=$(cd "$T" && pwd -P)
    FAILS=(); SKIPMSG=""; out=""; err=""; rc=0; K=""; P=""
    XDG_CACHE_HOME=$T/.cache; export XDG_CACHE_HOME; mkdir "$XDG_CACHE_HOME"
    cd "$T" && "$fn" </dev/null; cd "$here"
    if [ ${#FAILS[@]} -eq 0 ] && [ -n "$SKIPMSG" ]; then skip=$((skip+1)); echo "SKIP $id: $SKIPMSG"
    elif [ ${#FAILS[@]} -eq 0 ]; then pass=$((pass+1)); echo "PASS $id"
    else fail=$((fail+1)); failed+=("$id"); echo "FAIL $id"; for m in "${FAILS[@]}"; do echo "     - $m"; done; fi
    rm -rf "$T"
done
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]

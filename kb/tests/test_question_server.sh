#!/usr/bin/env bash
# Black-box tests for `orbit-kb serve questions` (ticket T19, CONTRACT D26).
# The only source of expected behavior is kb/CONTRACT.md (D26, with D24 for the page and D23 P7
# for the writer lock).
# Usage: kb/tests/test_question_server.sh [path-to-orbit-kb]      ONLY='<regex>' runs matching ids.
# Summary line: orbit-kb=... pass=N fail=N skip=N FAILED-IDS. Exit 0 all pass, 1 a failure, 2 cannot run.
#
# Requirement map (claims of ticket T19 -> tests):
#   c1 live: each GET renders from the KBs as they are now          : QS1 QS2
#   c2 per project: --root groups spec KBs by project_kb; --dir     : QS3 QS4
#   c3 answer: a form per to_ask question; POST records the answer  : QS5 QS6 QS7
#   c4 lock: the writer lock; a held lock writes nothing, no --take : QS8 QS9
#   c5 safety: loopback, token, Host, escaping, term validation     : QS10 QS11 QS12 QS13
#   c6 only answer records, only through orbit-kb                   : QS14; QS17 runs the server against the Lean model
#   c7 the ledger's asks, read-only, with the hubflow command       : QS15
#   c8 docs: help serve, README, CONTRACT D26                       : QS16
# Ticket T27 (CONTRACT D26 amended):
#   c4 a human answer never waits: answers.pending, applied by the next write : QS18 (QS8 now: a held lease queues the answer)
#   c5 who owns a question: ledger, tracker, pins, draft questions           : QS19
#   c6 context on the page: notes, examples, due; option/3 in the recipes    : QS20
#   c7 the ledger, live from flow.db, with an answer form; quoted command    : QS21
#   c8 a project KB's own questions                                          : QS22
#   c9 fixes: default terms, option and text, project_kb paths, frame headers : QS23
# Ticket T37 (fixes found when T27 was verified; CONTRACT D26 S10 S11 amended):
#   c1 an answer to a pinned ledger ask reaches the spec KB; a non-ground queued line is reported : QS24
#   c4 the workflow text says when to pin (help build, help discovery, review.md)               : QS26
#   c5 the page: no form while an answer waits; a tracker-owned question shows its item; refused shown; numbers stay numbers : QS25 (and QS24)
#   c6 subagents of one pane count as one writer (help core, PANES.md)                          : QS26
# T38 (fixes found when T37 was verified; D26 S13, D23 P9):
#   c10 a ledger-pinned question has no form; the page names its ask                           : QS27
#   c11 tracker JSON: Jira Cloud v3 ADF description; a {count, value:[item]} wrapper; no silent raw : QS28
#   c12 the ask path (and pin-answer) keeps a numeric answer as a number                        : QS29
# T40 (fixes found when T38 was verified; D26 S13):
#   c4 a {count, value:[item]} wrapper is unwrapped only when the top level has no title        : QS30
set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
OKB=${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}
LIB=${ORBIT_KB_TEST_LIB:-$here/../share/orbit-kb}
TMO=${ORBIT_KB_TEST_TIMEOUT:-120}
for tool in swipl python3 sha256sum timeout mktemp grep cmp curl; do
    command -v "$tool" >/dev/null 2>&1 || { echo "test_question_server.sh: required tool not found: $tool" >&2; exit 2; }
done
[ -x "$OKB" ] || { echo "test_question_server.sh: the CLI is missing or not executable: $OKB" >&2; exit 2; }
OKB=$(cd "$(dirname "$OKB")" && pwd -P)/$(basename "$OKB")
LIB=$(cd "$LIB" && pwd -P)
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID|CLAUDE_CODE_SESSION_ID|HUB_SESSION|HUBFLOW*) unset "$v";; esac; done
export ORBIT_KB_LIB="$LIB"
REPO=$(cd "$here/../.." && pwd -P)

pass=0 fail=0 skip=0 failed=() FAILS=() SKIPPED=0
base=$(mktemp -d "${TMPDIR:-/tmp}/orbit-kb-qs.XXXXXX") || exit 2
SPID=""
cleanup() { [ -n "$SPID" ] && kill "$SPID" 2>/dev/null; rm -rf "$base"; }
trap cleanup EXIT
out="" err="" rc=0 T="" URL="" CODE="" BODY=""

# ---- an HTML reader (python, standard library only). Each mode prints nothing and exits 0 on
# success; on failure it prints one reason per line and exits 1.
cat > "$base/page.py" <<'PY'
import sys, html.parser, re
VOID = {"meta","link","br","hr","img","input","area","base","col","embed","source","track","wbr"}
class N:
    def __init__(s, tag, attrs, parent): s.tag=tag; s.attrs=dict(attrs); s.parent=parent; s.kids=[]; s.txt=[]
    def classes(s): return (s.attrs.get("class") or "").split()
    def text(s): return norm("".join(s.txt) + " ".join(k.text() for k in s.kids))
    def walk(s):
        yield s
        for k in s.kids: yield from k.walk()
def norm(t): return re.sub(r"\s+", " ", t).strip()
class P(html.parser.HTMLParser):
    def __init__(s): super().__init__(convert_charrefs=True); s.root=N("#root",[],None); s.cur=s.root; s.all=[]
    def handle_starttag(s, tag, attrs):
        n=N(tag,attrs,s.cur); s.cur.kids.append(n); s.all.append(n)
        if tag not in VOID: s.cur=n
    def handle_startendtag(s, tag, attrs):
        n=N(tag,attrs,s.cur); s.cur.kids.append(n); s.all.append(n)
    def handle_endtag(s, tag):
        c=s.cur
        while c is not s.root and c.tag!=tag: c=c.parent
        if c is not s.root: s.cur=c.parent
    def handle_data(s, d): s.cur.txt.append(d)
def load(f):
    raw=open(f, encoding="utf-8").read(); p=P(); p.feed(raw); return p, raw
def cls(n, c): return [x for x in n.walk() if c in x.classes()]
def kbsec(p, label):  # the section.kb whose kblabel text is label
    return [s for s in p.all if s.tag=="section" and "kb" in s.classes() and any(l.text()==label for l in cls(s,"kblabel"))]
def items(n, kind):
    return [x for x in n.walk() if x.tag=="li" and "item" in x.classes() and x.attrs.get("data-kind")==kind]
def main():
    mode, f, *a = sys.argv[1:]
    p, raw = load(f); bad=[]
    if mode=="token":        # token FILE: print the token of the first answer form
        for n in p.all:
            if n.tag=="input" and n.attrs.get("name")=="token": print(n.attrs.get("value","")); sys.exit(0)
        sys.exit(1)
    elif mode=="kbval":      # kbval FILE LABEL: print the kb value of the first form in the KB section LABEL
        for s in kbsec(p, a[0]):
            for n in s.walk():
                if n.tag=="input" and n.attrs.get("name")=="kb": print(n.attrs.get("value","")); sys.exit(0)
        sys.exit(1)
    elif mode=="asks":       # asks FILE LABEL QID...: exactly these to_ask items in KB section LABEL, in order
        secs=kbsec(p, a[0])
        if len(secs)!=1: bad.append("want one KB section labeled %r, found %d" % (a[0], len(secs)))
        else:
            got=[x.attrs.get("data-id") for x in items(secs[0], "to_ask")]
            if got!=a[1:]: bad.append("to_ask items %r, want %r" % (got, a[1:]))
    elif mode=="groups":     # groups FILE 'LABEL=KB1,KB2' ...: the project groups, in order, each with its KB sections in order
        gs=[s for s in p.all if s.tag=="section" and "project" in s.classes()]
        got=[]
        for g in gs:
            lab=[l.text() for l in cls(g,"projectlabel")]
            kbs=[ ",".join(l.text() for l in cls(k,"kblabel")) for k in g.walk() if k.tag=="section" and "kb" in k.classes()]
            got.append("%s=%s" % (lab[0] if lab else "?", ",".join(kbs)))
        if got!=a: bad.append("groups %r, want %r" % (got, a))
    elif mode=="form":       # form FILE LABEL QID OPT...: the to_ask item has a POST form to /answer with radio choices OPT (in order), a text field, and hidden q, kb, token
        secs=kbsec(p, a[0]); its=[x for s in secs for x in items(s,"to_ask") if x.attrs.get("data-id")==a[1]]
        if len(its)!=1: bad.append("want one to_ask item %s in %r, found %d" % (a[1], a[0], len(its)))
        else:
            fs=[n for n in its[0].walk() if n.tag=="form"]
            if len(fs)!=1: bad.append("want one form in the item, found %d" % len(fs))
            else:
                fm=fs[0]
                if (fm.attrs.get("method") or "").lower()!="post": bad.append("form method is not post")
                if fm.attrs.get("action")!="/answer": bad.append("form action %r, want /answer" % fm.attrs.get("action"))
                ins=[n for n in fm.walk() if n.tag in ("input","textarea")]
                radios=[n.attrs.get("value") for n in ins if n.attrs.get("type")=="radio" and n.attrs.get("name")=="choice"]
                if radios!=a[2:]: bad.append("radio choices %r, want %r" % (radios, a[2:]))
                if not any(n.attrs.get("name")=="text" and (n.tag=="textarea" or n.attrs.get("type") in (None,"text")) for n in ins): bad.append("no free-text field named text")
                hid={n.attrs.get("name"):n.attrs.get("value") for n in ins if n.attrs.get("type")=="hidden"}
                for k in ("q","kb","token"):
                    if not hid.get(k): bad.append("no hidden %s" % k)
                if hid.get("q")!=a[1]: bad.append("hidden q is %r" % hid.get("q"))
    elif mode=="answered":   # answered FILE LABEL QID ANSWER [defeated:DEFAULT|kept]: a li.answered for QID with the answer, and the default marked
        secs=kbsec(p, a[0]); ls=[x for s in secs for x in s.walk() if x.tag=="li" and "answered" in x.classes() and x.attrs.get("data-id")==a[1]]
        if len(ls)!=1: bad.append("want one li.answered %s in %r, found %d" % (a[1], a[0], len(ls)))
        else:
            ans=[x.text() for x in cls(ls[0],"answer")]
            if ans!=[a[2]]: bad.append("answer %r, want %r" % (ans, a[2]))
            if len(a)>3 and a[3].startswith("defeated:"):
                d=[x.text() for x in cls(ls[0],"defeated")]
                if len(d)!=1 or a[3][9:] not in d[0]: bad.append("no .defeated naming the default %r (got %r)" % (a[3][9:], d))
    elif mode=="text":       # text FILE T...: the page text has each T; !T: lacks it
        t=p.root.text()
        for x in a:
            if x.startswith("!"):
                if x[1:] in t: bad.append("page text has %r" % x[1:])
            elif x not in t: bad.append("page text lacks %r" % x)
    elif mode=="raw":        # raw FILE T...: the raw HTML has each T; !T: lacks it
        for x in a:
            if x.startswith("!"):
                if x[1:] in raw: bad.append("raw HTML has %r" % x[1:])
            elif x not in raw: bad.append("raw HTML lacks %r" % x)
    elif mode=="ask":        # ask FILE ID CMD-FRAGMENT: li.ask ID holds a code.hubflow with the fragment, and no form
        ls=[n for n in p.all if n.tag=="li" and "ask" in n.classes() and n.attrs.get("data-id")==a[0]]
        if len(ls)!=1: bad.append("want one li.ask %s, found %d" % (a[0], len(ls)))
        else:
            c=[x.text() for x in cls(ls[0],"hubflow")]
            if not c or a[1] not in c[0]: bad.append("hubflow command %r lacks %r" % (c, a[1]))
            if any(n.tag=="form" for n in ls[0].walk()): bad.append("the ask has a form (asks are read-only in v1)")
    elif mode=="pending":    # pending FILE LABEL QID: the KB section LABEL lists QID as a pending answer
        secs=kbsec(p, a[0]); ls=[x for s in secs for x in s.walk() if "pending" in x.classes() and x.attrs.get("data-id")==a[1]]
        if len(ls)<1: bad.append("no element with class pending and data-id %s in %r" % (a[1], a[0]))
    elif mode=="ctx":        # ctx FILE LABEL QID T...: the to_ask item QID in section LABEL has each text T
        secs=kbsec(p, a[0]); its=[x for s in secs for x in items(s,"to_ask") if x.attrs.get("data-id")==a[1]]
        if len(its)!=1: bad.append("want one to_ask item %s in %r, found %d" % (a[1], a[0], len(its)))
        else:
            t=its[0].text()
            for x in a[2:]:
                if x not in t: bad.append("item %s lacks %r" % (a[1], x))
    elif mode=="askform":    # askform FILE ID: li.ask ID has one POST form to /answer with hidden token and ask=ID, and a text field
        ls=[n for n in p.all if n.tag=="li" and "ask" in n.classes() and n.attrs.get("data-id")==a[0]]
        if len(ls)!=1: bad.append("want one li.ask %s, found %d" % (a[0], len(ls)))
        else:
            fs=[n for n in ls[0].walk() if n.tag=="form"]
            if len(fs)!=1: bad.append("want one form in the ask, found %d" % len(fs))
            else:
                fm=fs[0]; ins=[n for n in fm.walk() if n.tag in ("input","textarea")]
                if (fm.attrs.get("method") or "").lower()!="post" or fm.attrs.get("action")!="/answer": bad.append("the form is not a POST to /answer")
                hid={n.attrs.get("name"):n.attrs.get("value") for n in ins if n.attrs.get("type")=="hidden"}
                if hid.get("ask")!=a[0]: bad.append("hidden ask is %r" % hid.get("ask"))
                if not hid.get("token"): bad.append("no hidden token")
                if not any(n.attrs.get("name")=="text" for n in ins): bad.append("no text field")
    elif mode=="askcmd":     # askcmd FILE ID FRAGMENT: li.ask ID holds a code.hubflow with the fragment
        ls=[n for n in p.all if n.tag=="li" and "ask" in n.classes() and n.attrs.get("data-id")==a[0]]
        if len(ls)!=1: bad.append("want one li.ask %s, found %d" % (a[0], len(ls)))
        else:
            c=[x.text() for x in cls(ls[0],"hubflow")]
            if not c or a[1] not in c[0]: bad.append("hubflow command %r lacks %r" % (c, a[1]))
    elif mode=="noform":     # noform FILE LABEL QID: the to_ask item QID in section LABEL has no form
        secs=kbsec(p, a[0]); its=[x for s in secs for x in items(s,"to_ask") if x.attrs.get("data-id")==a[1]]
        if len(its)!=1: bad.append("want one to_ask item %s in %r, found %d" % (a[1], a[0], len(its)))
        elif any(n.tag=="form" for n in its[0].walk()): bad.append("item %s has a form" % a[1])
    elif mode=="refused":    # refused FILE LABEL QID: the KB section LABEL lists a refused queued answer for QID
        secs=kbsec(p, a[0]); ls=[x for s in secs for x in s.walk() if "refused" in x.classes() and x.attrs.get("data-id")==a[1]]
        if len(ls)<1: bad.append("no element with class refused and data-id %s in %r" % (a[1], a[0]))
    elif mode=="message":    # message FILE T: an element with class message holds T
        ms=[x.text() for x in p.all if "message" in x.classes()]
        if not any(a[0] in m for m in ms): bad.append("no .message with %r (messages %r)" % (a[0], ms))
    for b in bad: print(b)
    sys.exit(1 if bad else 0)
main()
PY
pg() { python3 -I "$base/page.py" "$@"; }
chk() { local r; r=$(pg "$@" 2>&1) || { local IFS=$'\n'; FAILS+=("page check $1: $r"); return 1; }; return 0; }
note() { FAILS+=("$*"); }
snip() { printf '%s' "$1" | head -c 300 | tr '\n' '~'; }
okb() {  # okb ARGS...: run the CLI in $T with a private cache; sets out err rc
    ( cd "$T" && XDG_CACHE_HOME="$T/.cache" exec timeout "$TMO" "$OKB" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null
    rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err")
}
rc_is() { [ "$rc" = "$1" ] && return 0; note "${2:+$2: }exit $rc, want $1 (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; }
q() { okb --dir "$1" query "$2"; }   # q KB GOAL: rc 0 when the goal has an answer
has_goal() { q "$1" "$2"; [ "$rc" = 0 ] || note "${3:-$2}: no answer in $1 (rc $rc $(snip "$err"))"; }
hasnt_goal() { q "$1" "$2"; [ "$rc" = 1 ] || note "${3:-$2}: want no answer in $1, rc $rc"; }

# ---- the server
srv() {  # srv ARGS...: start `serve questions --port 0 ARGS` in $T; sets URL, SPID. 0 when it serves.
    ( cd "$T" && XDG_CACHE_HOME="$T/.cache" exec timeout "$TMO" "$OKB" serve questions --port 0 "$@" ) >"$T/.srv.out" 2>"$T/.srv.err" </dev/null &
    SPID=$!; URL=""
    local i; for i in $(seq 1 200); do
        URL=$(grep -oE 'http://127\.0\.0\.1:[0-9]+' "$T/.srv.out" 2>/dev/null | head -n1)
        [ -n "$URL" ] && return 0
        kill -0 "$SPID" 2>/dev/null || break
        sleep 0.05
    done
    note "the server did not start (stdout: $(snip "$(cat "$T/.srv.out" 2>/dev/null)") | stderr: $(snip "$(cat "$T/.srv.err" 2>/dev/null)"))"; return 1
}
srv_stop() { [ -n "$SPID" ] && { kill "$SPID" 2>/dev/null; wait "$SPID" 2>/dev/null; }; SPID=""; }
# get PATH [CURL-ARGS...]: GET; sets CODE, the body in $T/page.html
get() { local p=$1; shift; CODE=$(curl -s -o "$T/page.html" -w '%{http_code}' --max-time 30 "$@" "$URL$p" 2>/dev/null); }
post() {  # post PATH FIELD=VALUE...: a form POST (urlencoded); sets CODE, the body in $T/post.html
    local p=$1; shift; local a=() f
    for f in "$@"; do a+=(--data-urlencode "$f"); done
    CODE=$(curl -s -o "$T/post.html" -w '%{http_code}' --max-time 30 "${a[@]}" "$URL$p" 2>/dev/null)
}
code_is() { [ "$CODE" = "$1" ] && return 0; note "${2:+$2: }HTTP $CODE, want $1"; return 1; }
page_ok() { get / ; code_is 200 "GET /" || return 1; }
token() { pg token "$T/page.html"; }
same_file() { cmp -s "$1" "$2" || note "$3 changed"; }

# ---- fixtures
kb_new() { mkdir -p "$1" && cat > "$1/kb.pl"; }
# kb A: c1 is contested, so q1 (default yes) and q2 (default no) are to_ask; q3 is answered.
kb_a() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Billing must be less confusing for customers').
claim(c1, preserve, 'The invoice list is sorted by date').
cites(c1, 'Billing must be less confusing for customers').
question(q1, c1, 'Should the list show the newest invoice first').
question(q2, c1, 'Should paid invoices be hidden by default').
question(q3, c1, 'Is the list paged').
assumed(q1, yes).
assumed(q2, no).
assumed(q3, no).
answer(q3, yes, human).
option(q1, yes, 'Newest first, as today').
option(q1, no, 'Oldest first').
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF
}
# a spec KB that uses the project module: kb_spec DIR LABEL PROJECT-or-empty
kb_spec() { local pk=""; [ -n "$3" ] && pk="project_kb('$3')."
    kb_new "$1" <<EOF
uses([build, project]).
request(r1, '$2').
$pk
claim(c1, preserve, 'The rule of $2 holds').
cites(c1, '$2').
question(q1, c1, 'Does $2 apply to refunds').
assumed(q1, no).
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF
}
kb_project() { kb_new "$1" <<EOF
uses([project]).
request(r1, '$2').
EOF
}
ledger_json() { cat > "$1" <<'EOF'
[
 {"id":"A12","kind":"ask","title":"Which payment provider do we pick","status":"open","waits_on":"me","age_days":17},
 {"id":"A20","kind":"ask","title":"Vendor must send the tax form","status":"open","waits_on":"pat","age_days":40}
]
EOF
}
L_A='Billing must be less confusing for customers'

# ================================================================ c1 live
t_QS1() {  # a fact added by another process shows on the next GET, with no restart
    kb_a "$T/a"; srv --dir "$T/a" || return
    page_ok || return; chk asks "$T/page.html" "$L_A" q1 q2
    okb --dir "$T/a" add "question(q9, c1, 'Is the export daily')" "assumed(q9, no)"; rc_is 0 "add q9" || return
    page_ok || return; chk asks "$T/page.html" "$L_A" q1 q2 q9
    chk text "$T/page.html" 'Is the export daily'
    srv_stop
}
t_QS2() {  # a KB removed under --root, and a KB added under --root, show on the next GET
    kb_a "$T/r/a"; srv --root "$T/r" || return
    page_ok || return; chk text "$T/page.html" "$L_A" '!Saved drafts survive'
    kb_new "$T/r/b" <<'EOF'
uses([build]).
request(r1, 'The mobile app must work offline').
claim(c1, preserve, 'Saved drafts survive a restart').
cites(c1, 'The mobile app must work offline').
EOF
    page_ok || return; chk text "$T/page.html" "$L_A" 'Saved drafts survive'
    srv_stop
}

# ================================================================ c2 per project
t_QS3() {  # --root groups the spec KBs by their project KB, named by its first request; no project_kb: "no project"
    kb_project "$T/r/pk" 'Build the export'
    kb_spec "$T/r/s1" 'Alpha rules' '../pk'; kb_spec "$T/r/s2" 'Beta rules' '../pk'
    kb_spec "$T/r/sub/s3" 'Gamma rules' ''
    srv --root "$T/r" || return
    page_ok || return
    chk groups "$T/page.html" 'Build the export=Alpha rules,Beta rules' 'no project=Gamma rules'
    srv_stop
}
t_QS4() {  # --dir still works as in T10: one section per KB in the order given; repeated --dir
    kb_a "$T/a"; kb_spec "$T/s" 'Alpha rules' ''
    srv --dir "$T/s" --dir "$T/a" || return
    page_ok || return
    chk groups "$T/page.html" "no project=Alpha rules,$L_A"
    chk asks "$T/page.html" "$L_A" q1 q2
    srv_stop
}

# ================================================================ c3 answer
t_QS5() {  # each to_ask question has a form: its options as radio choices (as in T10), other, a free text
    kb_a "$T/a"; srv --dir "$T/a" || return
    page_ok || return
    chk form "$T/page.html" "$L_A" q1 yes no other
    chk form "$T/page.html" "$L_A" q2 no other
    chk text "$T/page.html" 'Newest first, as today' 'Oldest first'
    srv_stop
}
t_QS6() {  # a POST of an option records answer(Q, A, human); the reload has no q1 to ask, and its default shows defeated
    kb_a "$T/a"; srv --dir "$T/a" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    post /answer "token=$tok" "kb=$kb" q=q1 choice=no; code_is 303 "POST an option" || return
    has_goal "$T/a" 'answer(q1, no, human)' "the answer is recorded as a human answer"
    hasnt_goal "$T/a" 'to_ask(q1)' "q1 is not to_ask"
    has_goal "$T/a" 'defeated(q1)' "the default of q1 is defeated"
    page_ok || return
    chk asks "$T/page.html" "$L_A" q2
    chk answered "$T/page.html" "$L_A" q1 no defeated:yes
    srv_stop
}
t_QS7() {  # a POST of free text (choice other) records exactly that text, through the same answer record
    kb_a "$T/a"; srv --dir "$T/a" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    post /answer "token=$tok" "kb=$kb" q=q2 choice=other 'text=Only for admins, until March'; code_is 303 "POST free text" || return
    has_goal "$T/a" "answer(q2, 'Only for admins, until March', human)" "the free text is the answer"
    page_ok || return; chk answered "$T/page.html" "$L_A" q2 'Only for admins, until March' defeated:no
    post /answer "token=$tok" "kb=$kb" q=q1; code_is 400 "a POST with no choice and no text"
    hasnt_goal "$T/a" 'answer(q1, _, human)' "an empty POST writes nothing"
    post /answer "token=$tok" "kb=$kb" q=q3 choice=no; code_is 409 "a POST for a question that is not to_ask"
    hasnt_goal "$T/a" 'answer(q3, no, _)' "a question that is not to_ask gets no answer"
    srv_stop
}

# ================================================================ c4 lock
t_QS8() {  # another writer holds the lock: nothing is written to kb.pl, the answer waits in the queue, no --take
    kb_spec "$T/s" 'Alpha rules' ''
    printf 'ann 2026-11-06T10:00:00Z\n' > "$T/s/writer.lock"
    cp "$T/s/kb.pl" "$T/kb.before"; cp "$T/s/writer.lock" "$T/lock.before"
    srv --dir "$T/s" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" 'Alpha rules')
    # T27 c4 (D26 S4 amended): the answer is queued at once (303), not refused; the KB and the lock stay as they are
    post /answer "token=$tok" "kb=$kb" q=q1 choice=no; code_is 303 "POST under a held lock is queued"
    same_file "$T/s/kb.pl" "$T/kb.before" "kb.pl"
    same_file "$T/s/writer.lock" "$T/lock.before" "writer.lock"
    grep -q 'writer_takeover' "$T/s/kb.pl" && note "a takeover was recorded"
    [ -s "$T/s/answers.pending" ] || note "the answer is not in answers.pending"
    srv_stop
}
t_QS9() {  # a free lock: the server takes it for the write, and gives it back after
    kb_spec "$T/s" 'Alpha rules' ''
    srv --dir "$T/s" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" 'Alpha rules')
    post /answer "token=$tok" "kb=$kb" q=q1 choice=yes; code_is 303 "POST under a free lock" || return
    has_goal "$T/s" 'answer(q1, yes, human)' "the answer is written"
    [ -e "$T/s/writer.lock" ] && note "the server kept the writer lock: $(cat "$T/s/writer.lock")"
    ( cd "$T" && ORBIT_KB_WRITER=bob XDG_CACHE_HOME="$T/.cache" timeout "$TMO" "$OKB" --dir "$T/s" add "note(c1, 'bob writes')" ) >/dev/null 2>&1 \
        || note "another writer cannot write after the server's answer"
    srv_stop
}

# ================================================================ c5 safety
t_QS10() {  # the server listens on 127.0.0.1 only
    kb_a "$T/a"; srv --dir "$T/a" || return
    local port=${URL##*:}
    if command -v ss >/dev/null 2>&1; then
        local l; l=$(ss -Hltn "sport = :$port" 2>/dev/null | awk '{print $4}')
        [ -n "$l" ] || note "ss shows no listener on port $port"
        printf '%s\n' "$l" | grep -qv '^127\.0\.0\.1:' && note "a listener is not on 127.0.0.1: $l"
    else SKIPPED=1; fi
    srv_stop
}
t_QS11() {  # a Host other than 127.0.0.1 or localhost gets 403, for GET and POST; no write
    kb_a "$T/a"; cp "$T/a/kb.pl" "$T/kb.before"; srv --dir "$T/a" || return
    local port=${URL##*:}
    get / -H "Host: evil.example:$port"; code_is 403 "GET with Host evil.example"
    chk text "$T/page.html" '!Should the list show'
    get / -H "Host: localhost:$port"; code_is 200 "GET with Host localhost"
    local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    CODE=$(curl -s -o "$T/post.html" -w '%{http_code}' -H "Host: evil.example:$port" --data-urlencode "token=$tok" --data-urlencode "kb=$kb" --data-urlencode q=q1 --data-urlencode choice=no "$URL/answer")
    code_is 403 "POST with Host evil.example"
    same_file "$T/a/kb.pl" "$T/kb.before" "kb.pl after a POST with a foreign Host"
    srv_stop
}
t_QS12() {  # a POST needs the token of this run: none or a wrong one gets 403 and no write
    kb_a "$T/a"; cp "$T/a/kb.pl" "$T/kb.before"; srv --dir "$T/a" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    [ ${#tok} -ge 32 ] || note "the token is short: ${#tok} characters"
    post /answer "kb=$kb" q=q1 choice=no; code_is 403 "POST with no token"
    post /answer "token=x$tok" "kb=$kb" q=q1 choice=no; code_is 403 "POST with a wrong token"
    same_file "$T/a/kb.pl" "$T/kb.before" "kb.pl after POSTs without the token"
    srv_stop; srv --dir "$T/a" || return
    post /answer "token=$tok" "kb=$kb" q=q1 choice=no; code_is 403 "the token of an earlier run"
    same_file "$T/a/kb.pl" "$T/kb.before" "kb.pl after a POST with an old token"
    srv_stop
}
t_QS13() {  # free text is escaped on the page, and is one answer term (never spliced into Prolog)
    kb_a "$T/a"; srv --dir "$T/a" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    local evil="x'), claim(c9, introduce, 'y'). %"
    post /answer "token=$tok" "kb=$kb" q=q2 choice=other "text=$evil"; code_is 303 "POST of text with quotes"
    hasnt_goal "$T/a" 'claim(c9, _, _)' "no claim c9 from the free text"
    # read kb.pl as terms (not through query, which allows no atom_string): one answer of q2, with exactly the posted text
    EVIL="$evil" swipl -q -g "getenv('EVIL', E), open('$T/a/kb.pl', read, S), findall(A, (repeat, read(S, X), (X == end_of_file -> !, fail ; X = answer(q2, A, human))), As), (As = [A1], atom_string(A1, E) -> halt(0) ; print(As), nl, halt(1))" -t 'halt(2)' >"$T/.rd" 2>&1 \
        || note "the answer text is not the posted text: $(snip "$(cat "$T/.rd")")"
    post /answer "token=$tok" "kb=$kb" q=q1 choice=other 'text=<b>bold</b> & <script>alert(1)</script>'; code_is 303 "POST of text with markup"
    page_ok || return
    chk raw "$T/page.html" '!<b>bold</b>' '!<script>alert' '&lt;b&gt;bold&lt;/b&gt;'
    chk answered "$T/page.html" "$L_A" q1 '<b>bold</b> & <script>alert(1)</script>'
    srv_stop
}

# ================================================================ c6 only answer records
t_QS14() {  # every request but a valid POST /answer leaves every KB as it was
    kb_a "$T/a"; kb_a "$T/other"; cp "$T/a/kb.pl" "$T/a.before"; cp "$T/other/kb.pl" "$T/o.before"
    srv --dir "$T/a" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    get /nope; code_is 404 "GET /nope"
    get /answer; [ "$CODE" = 405 ] || [ "$CODE" = 404 ] || note "GET /answer: HTTP $CODE, want 405 or 404"
    post /nope "token=$tok" "kb=$kb" q=q1 choice=no; code_is 404 "POST /nope"
    CODE=$(curl -s -o /dev/null -w '%{http_code}' -X PUT --data "token=$tok" "$URL/answer"); code_is 405 "PUT /answer"
    CODE=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$URL/"); code_is 405 "DELETE /"
    post /answer "token=$tok" "kb=$T/other" q=q1 choice=no; code_is 400 "POST for a KB that the server does not serve"
    post /answer "token=$tok" "kb=$kb" q=q1 choice=no answer='q1, no, human). claim(c7, x, y'; true
    same_file "$T/other/kb.pl" "$T/o.before" "a KB that the server does not serve"
    # the one valid POST above added exactly one fact: the answer
    diff <(grep -v '^%' "$T/a.before") <(grep -v '^%' "$T/a/kb.pl") | grep '^>' > "$T/added" || true
    [ "$(wc -l < "$T/added")" = 1 ] && grep -q '^> answer(q1, *no, *human)\.' "$T/added" \
        || note "the valid POST did not add exactly one answer fact: $(snip "$(cat "$T/added")")"
    srv_stop
}

# QS17 (conformance, D26 S5 S6): the server against the Lean model kb/proofs/question_server
# (#eval table). Rows: METHOD PATH HOST-OK TOKEN-OK ACTION, copied from the #eval output.
QS17_TABLE='get root 1 1 page|get root 1 0 page|get root 0 1 forbidden|get root 0 0 forbidden
get answer 1 1 badMethod|get answer 1 0 badMethod|get answer 0 1 forbidden|get answer 0 0 forbidden
get other 1 1 notFound|get other 1 0 notFound|get other 0 1 forbidden|get other 0 0 forbidden
post root 1 1 badMethod|post root 1 0 badMethod|post root 0 1 forbidden|post root 0 0 forbidden
post answer 1 1 answer|post answer 1 0 forbidden|post answer 0 1 forbidden|post answer 0 0 forbidden
post other 1 1 notFound|post other 1 0 notFound|post other 0 1 forbidden|post other 0 0 forbidden
put root 1 1 badMethod|put root 1 0 badMethod|put root 0 1 forbidden|put root 0 0 forbidden
put answer 1 1 badMethod|put answer 1 0 badMethod|put answer 0 1 forbidden|put answer 0 0 forbidden
put other 1 1 notFound|put other 1 0 notFound|put other 0 1 forbidden|put other 0 0 forbidden
delete root 1 1 badMethod|delete root 1 0 badMethod|delete root 0 1 forbidden|delete root 0 0 forbidden
delete answer 1 1 badMethod|delete answer 1 0 badMethod|delete answer 0 1 forbidden|delete answer 0 0 forbidden
delete other 1 1 notFound|delete other 1 0 notFound|delete other 0 1 forbidden|delete other 0 0 forbidden'
t_QS17() {  # every row of the model's table: the HTTP status of its action; only the answer row writes
    kb_a "$T/a"; srv --dir "$T/a" || return
    page_ok || return; local tok kb port=${URL##*:}; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    local rows n=0 m p h t act want path hostarg tokarg
    rows=$(printf '%s' "$QS17_TABLE" | tr '|' '\n')
    while read -r m p h t act; do
        [ -n "$m" ] || continue; n=$((n+1))
        case $act in page) want=200;; answer) want=303;; forbidden) want=403;; badMethod) want=405;; notFound) want=404;; esac
        case $p in root) path=/;; answer) path=/answer;; other) path=/elsewhere;; esac
        if [ "$h" = 1 ]; then hostarg="Host: 127.0.0.1:$port"; else hostarg="Host: evil.example:$port"; fi
        if [ "$t" = 1 ]; then tokarg="token=$tok"; else tokarg="token=not-$tok"; fi
        cp "$T/a/kb.pl" "$T/row.before"
        CODE=$(curl -s -o "$T/row.html" -w '%{http_code}' --max-time 30 -X "${m^^}" -H "$hostarg" \
               --data-urlencode "$tokarg" --data-urlencode "kb=$kb" --data-urlencode q=q1 --data-urlencode choice=yes "$URL$path")
        [ "$CODE" = "$want" ] || note "row $m $p host=$h token=$t: HTTP $CODE, want $want ($act)"
        if [ "$act" = answer ]; then cmp -s "$T/a/kb.pl" "$T/row.before" && note "row $m $p: the answer row wrote nothing"
        else cmp -s "$T/a/kb.pl" "$T/row.before" || note "row $m $p host=$h token=$t ($act) changed kb.pl"; fi
    done <<< "$rows"
    [ "$n" = 48 ] || note "the table has $n rows, want 48"
    srv_stop
}

# ================================================================ c7 ledger
t_QS15() {  # the ledger's asks show as in T10, read-only, with the hubflow command that answers each; live
    kb_a "$T/a"; ledger_json "$T/asks.json"
    srv --dir "$T/a" --ledger "$T/asks.json" || return
    page_ok || return
    chk ask "$T/page.html" A12 'hubflow.py --by human close A12 --reason done --note'
    chk text "$T/page.html" 'Which payment provider do we pick' '!Vendor must send the tax form'
    python3 - "$T/asks.json" <<'PY'
import json, sys
f=sys.argv[1]; j=json.load(open(f)); j.append({"id":"A30","kind":"ask","title":"Pick the launch date","status":"open","waits_on":"me","age_days":1}); json.dump(j, open(f,"w"))
PY
    page_ok || return; chk text "$T/page.html" 'Pick the launch date'
    srv_stop
}

# ================================================================ c8 docs
t_QS16() {  # help serve, the README command reference, CONTRACT D26
    okb help serve; rc_is 0 "help serve"
    local w; for w in 'serve questions' '--root' '--port' '127.0.0.1' 'token' 'writer lock' 'Ctrl-C'; do
        printf '%s' "$out" | grep -Fq -- "$w" || note "help serve lacks '$w'"; done
    grep -Fq '### `serve questions' "$LIB/README.md" || note "README.md has no serve questions entry"
    grep -Fq '**D26' "$REPO/kb/CONTRACT.md" || note "CONTRACT.md has no D26"
    grep -Fq '| `serve questions' "$REPO/kb/CONTRACT.md" || note "the CONTRACT command table has no serve questions row"
}


# ================================================================ T27
# a hub with the ledger: mkhub DIR (seeded sessions; the owner is the person me)
mkhub() { mkdir -p "$1/.claude/scripts"; cp "$REPO/hubkit/hub/.claude/scripts/hubflow.py" "$1/.claude/scripts/"
          cp "$REPO/hubkit/hub/flow/seed.json" "$1/seed.json"
          ( cd "$1" && python3 .claude/scripts/hubflow.py --hub "$1" init --seed seed.json ) >/dev/null 2>&1 || note "setup: hub init failed"; }
hf() { local H=$1; shift; ( cd "$H" && python3 .claude/scripts/hubflow.py --hub "$H" "$@" ) 2>&1; }
# askjson HUB ID PY-EXPR: the item and events of ask ID (hubflow show --format json) as d; the expression must hold
askjson() { hf "$1" show "$2" --format json > "$T/.ask.json"
            python3 -I -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if ($3) else 1)" "$T/.ask.json" \
              || note "ask $2: not ($3): $(snip "$(cat "$T/.ask.json")")"; }
wr() { ( cd "$T" && ORBIT_KB_WRITER=$1 XDG_CACHE_HOME="$T/.cache" timeout "$TMO" "$OKB" "${@:2}" ) >"$T/.out" 2>"$T/.err" </dev/null; rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err"); }

t_QS18() {  # c4: an answer given while an agent holds the lease waits in answers.pending; the agent's next write applies it
    kb_a "$T/a"
    wr ann --dir "$T/a" add "note(c1, 'ann works here')"; rc_is 0 "ann takes the lease" || return
    cp "$T/a/kb.pl" "$T/kb.before"
    srv --dir "$T/a" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    post /answer "token=$tok" "kb=$kb" q=q1 choice=no; code_is 303 "the answer is taken at once" || return
    same_file "$T/a/kb.pl" "$T/kb.before" "kb.pl while ann holds the lease"
    [ "$(wc -l < "$T/a/answers.pending" 2>/dev/null)" = 1 ] || note "answers.pending does not have one line"
    grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z' "$T/a/answers.pending" 2>/dev/null || note "the queued line has no time"
    grep -Eq 'sha256:[0-9a-f]{64}' "$T/a/answers.pending" 2>/dev/null || note "the queued line has no digest"
    page_ok || return; chk pending "$T/page.html" "$L_A" q1
    okb --dir "$T/a" show open; printf '%s\n' "$out" | grep -Eiq 'pending.*q1' || note "show open does not list q1 as pending: $(snip "$out")"
    wr ann --dir "$T/a" add "note(c1, 'ann writes again')"; rc_is 0 "ann's next write"
    has_goal "$T/a" 'answer(q1, no, human)' "ann's next write applied the answer"
    local la lb; la=$(grep -n '^answer(q1, *no, *human)' "$T/a/kb.pl" | cut -d: -f1); lb=$(grep -n "ann writes again" "$T/a/kb.pl" | cut -d: -f1)
    [ -n "$la" ] && [ -n "$lb" ] && [ "$la" -lt "$lb" ] || note "the answer is not applied before ann's own fact (lines $la, $lb)"
    okb --dir "$T/a" show open; printf '%s\n' "$out" | grep -Eiq 'pending.*q1' && note "show open still lists q1 as pending"
    [ "$(wc -l < "$T/a/answers.pending")" = 1 ] || note "answers.pending is append-only: it must keep its line"
    wr ann --dir "$T/a" add "note(c1, 'a third write')"
    [ "$(grep -c '^answer(q1' "$T/a/kb.pl")" = 1 ] || note "the answer was applied twice"
    srv_stop
}

t_QS19() {  # c5: the ledger owns a question that depends only on the owner, the tracker owns the others; the spec KB pins both
    mkhub "$T/h"; local A A2
    A=$(hf "$T/h" --session build add ask --title 'Should the list show the newest invoice first' --waits-on me --ref kb:billing/kb)
    kb_a "$T/a"
    okb --dir "$T/a" add "option(q2, yes, 'Paid invoices move to the archive tab')"
    okb --dir "$T/a" pin-question q1 ledger "$A"; rc_is 0 "pin-question to the ledger"
    has_goal "$T/a" "question_pin(q1, ledger, '$A', D, T)" "the question is pinned to its ask"
    okb --dir "$T/a" pin-question q2 tracker 'gh:acme/billing#7'; rc_is 0 "pin-question to the tracker"
    okb --dir "$T/a" draft questions; rc_is 0 "draft questions"
    printf '%s\n' "$out" | grep -Fq 'Should paid invoices be hidden by default' || note "the draft lacks the tracker's question q2"
    printf '%s\n' "$out" | grep -Fq 'Paid invoices move to the archive tab' || note "the draft lacks the effect of an option"
    printf '%s\n' "$out" | grep -Fq 'The invoice list is sorted by date' || note "the draft lacks the case (the claim)"
    printf '%s\n' "$out" | grep -Fq 'Should the list show the newest invoice first' && note "the draft has the ledger's question q1"
    okb --dir "$T/a" pin-answer q1 "$A" --hub "$T/h"; rc_is 1 "pin-answer before the ask has an answer"
    hf "$T/h" --session build --by human close "$A" --reason done --note 'Newest first' >/dev/null
    okb --dir "$T/a" pin-answer q1 "$A" --hub "$T/h"; rc_is 0 "pin-answer from the ledger"
    has_goal "$T/a" "answer(q1, 'Newest first', human:me)" "the answer is the pinned copy and names who answered"
    has_goal "$T/a" "answer_pin(q1, '$A', D, T)" "a pin of the answer"
    hasnt_goal "$T/a" 'to_ask(q1)' "q1 is answered"
    has_goal "$T/a" 'defeated(q1)' "a pinned human answer defeats the default"
    printf 'Only for admins\n' > "$T/ans.txt"
    okb --dir "$T/a" pin-answer q2 'gh:acme/billing#7' --text-file "$T/ans.txt" --by alex; rc_is 0 "pin-answer from the tracker"
    has_goal "$T/a" "answer(q2, 'Only for admins', human:alex)" "the tracker's answer names alex"
    okb --dir "$T/a" pin-answer q3 'gh:acme/billing#7' --text-file "$T/ans.txt" --by alex; rc_is 1 "pin-answer of a question with no pin"
    # the server: the answer goes to the ask first, then into the spec KB through the queue
    kb_a "$T/b"; A2=$(hf "$T/h" --session build add ask --title 'Should paid invoices be hidden by default' --waits-on me)
    okb --dir "$T/b" pin-question q2 ledger "$A2"; rc_is 0
    srv --dir "$T/b" --hub "$T/h" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    post /answer "token=$tok" "kb=$kb" q=q2 choice=other 'text=Hide after 90 days'; code_is 303 "POST of a ledger-owned question"
    askjson "$T/h" "$A2" "d['item']['status']=='done' and any(e['by']=='human' and e['note']=='Hide after 90 days' for e in d['events'])"
    has_goal "$T/b" "answer(q2, 'Hide after 90 days', human:me)" "the spec KB has the pinned answer"
    has_goal "$T/b" "answer_pin(q2, '$A2', _, _)" "the spec KB has the pin of the answer"
    grep -q 'answer_pin' "$T/b/answers.pending" 2>/dev/null || note "the pinned answer did not go through answers.pending"
    srv_stop
}

t_QS20() {  # c6: each question shows its note, its claim's note, the claim's examples, its due date (view and serve)
    kb_a "$T/a"
    okb --dir "$T/a" add "note(q1, 'Ty said the old order confused him')" "note(c1, 'Review found the order reversed')" \
        "example(c1, 'Invoice 7 of May shows above invoice 3 of April')" "due(q1, '2030-01-15T12:00:00Z')"; rc_is 0 "setup"
    okb --dir "$T/a" view questions --out "$T/view.html"; rc_is 0 "view questions"
    chk ctx "$T/view.html" "$L_A" q1 'Ty said the old order confused him' 'Review found the order reversed' 'Invoice 7 of May shows above invoice 3 of April' '2030-01-15T12:00:00Z'
    srv --dir "$T/a" || return; page_ok || return
    chk ctx "$T/page.html" "$L_A" q1 'Ty said the old order confused him' 'Review found the order reversed' 'Invoice 7 of May shows above invoice 3 of April' '2030-01-15T12:00:00Z'
    srv_stop
    okb help core; printf '%s\n' "$out" | awk '/^DECOMPOSE/{f=1} /^Asking the human/{f=0} f' | grep -Fq 'option(' || note "help core DECOMPOSE does not say option/3"
    okb help discovery; printf '%s\n' "$out" | awk '/^ASKING/{f=1} /^HANDOFF/{f=0} f' | grep -Fq 'option(' || note "help discovery ASKING does not say option/3"
}

t_QS21() {  # c7: with --hub the asks are read live from flow.db; an ask of the owner has an answer form that runs hubflow
    mkhub "$T/h"; local A B C
    A=$(hf "$T/h" --session build add ask --title 'Which payment provider do we pick' --waits-on me)
    B=$(hf "$T/h" --session build add ask --title 'Vendor must send the tax form' --waits-on alex --ref issue:12)
    kb_a "$T/a"; srv --dir "$T/a" --hub "$T/h" || return
    page_ok || return
    chk text "$T/page.html" 'Which payment provider do we pick' '!Vendor must send the tax form'
    chk askform "$T/page.html" "$A"
    chk askcmd "$T/page.html" "$A" "hubflow.py --by human close $A --reason done --note 'YOUR ANSWER' --session human"
    C=$(hf "$T/h" --session build add ask --title 'Pick the launch date' --waits-on me)
    page_ok || return; chk text "$T/page.html" 'Pick the launch date'
    local tok; tok=$(token)
    post /answer "token=$tok" "ask=$A" 'text=Stripe, for the fees'; code_is 303 "POST an answer to an ask"
    askjson "$T/h" "$A" "d['item']['status']=='done' and any(e['by']=='human' and e['by_session']=='human' and e['note']=='Stripe, for the fees' for e in d['events'])"
    page_ok || return; chk text "$T/page.html" '!Which payment provider do we pick' 'Pick the launch date'
    post /answer "token=$tok" "ask=$B" 'text=No'; code_is 409 "an ask that waits on another person"
    askjson "$T/h" "$B" "d['item']['status']=='open'"
    srv_stop
    # the shown command is shell-quoted
    printf '[{"id":"A12; touch pwned","kind":"ask","title":"Odd id","status":"open","waits_on":"me","age_days":1}]\n' > "$T/asks.json"
    srv --dir "$T/a" --ledger "$T/asks.json" || return
    page_ok || return; chk askcmd "$T/page.html" 'A12; touch pwned' "close 'A12; touch pwned' --reason done"
    srv_stop
}

t_QS22() {  # c8: a project KB's own to_ask questions get their section, and can be answered
    kb_new "$T/r/pk" <<'EOF'
uses([project]).
request(r1, 'Build the export').
claim(c1, preserve, 'Exports run nightly').
cites(c1, 'Build the export').
question(pq1, c1, 'Is a weekly export enough').
assumed(pq1, no).
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF
    kb_spec "$T/r/s1" 'Alpha rules' '../pk'
    srv --root "$T/r" || return; page_ok || return
    chk asks "$T/page.html" 'Build the export' pq1
    local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" 'Build the export')
    post /answer "token=$tok" "kb=$kb" q=pq1 choice=no; code_is 303 "answer a project KB's question"
    has_goal "$T/r/pk" 'answer(pq1, no, human)' "the project KB has the answer"
    srv_stop
}

t_QS23() {  # c9: default terms, option with text, project_kb paths, frame headers
    kb_new "$T/a" <<'EOF'
uses([build]).
request(r1, 'Numbers must stay sane').
claim(c1, preserve, 'Retries are bounded').
cites(c1, 'Numbers must stay sane').
question(q22, c1, 'How many retries').
assumed(q22, 3).
question(q23, c1, 'Which region').
assumed(q23, eu).
option(q23, us, 'Data moves to the US').
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF
    srv --dir "$T/a" || return; page_ok || return
    local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" 'Numbers must stay sane')
    post /answer "token=$tok" "kb=$kb" q=q22 choice=3; code_is 303 "accept the default 3"
    has_goal "$T/a" 'answer(q22, 3, human)' "the default is written as the same term"
    hasnt_goal "$T/a" 'defeated(q22)' "accepting the default is not a defeat"
    post /answer "token=$tok" "kb=$kb" q=q23 choice=us 'text=only for the pilot'; code_is 303 "an option with text"
    has_goal "$T/a" 'answer(q23, us, human)' "the option is the answer"
    has_goal "$T/a" "note(q23, 'only for the pilot')" "the typed text is kept as a note"
    curl -s -D "$T/hdr" -o /dev/null --max-time 30 "$URL/"
    grep -Eiq '^X-Frame-Options: *DENY' "$T/hdr" || note "no X-Frame-Options: DENY"
    grep -Eiq "^Content-Security-Policy:.*frame-ancestors 'none'" "$T/hdr" || note "no CSP frame-ancestors 'none'"
    srv_stop
    kb_project "$T/r/pk" 'Build the export'
    kb_spec "$T/r/s1" 'Alpha rules' '../pk'; kb_spec "$T/r/s2" 'Beta rules' '../pk/'
    srv --root "$T/r" || return; page_ok || return
    chk groups "$T/page.html" 'Build the export=Alpha rules,Beta rules'
    srv_stop
}

t_QS24() {  # T37 c1: an answer to a pinned ledger ask from the page reaches the spec KB; the number stays a number (c5)
    mkhub "$T/h"; local A
    A=$(hf "$T/h" --session build add ask --title 'How many retries' --waits-on me)
    kb_new "$T/a" <<'EOF2'
uses([build]).
request(r1, 'Numbers must stay sane').
claim(c1, preserve, 'Retries are bounded').
cites(c1, 'Numbers must stay sane').
question(q1, c1, 'How many retries').
assumed(q1, 3).
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF2
    okb --dir "$T/a" pin-question q1 ledger "$A"; rc_is 0 "pin-question"
    srv --dir "$T/a" --hub "$T/h" || return
    page_ok || return; local tok; tok=$(token)
    post /answer "token=$tok" "ask=$A" 'text=3'; code_is 303 "POST an answer to the ask"
    askjson "$T/h" "$A" "d['item']['status']=='done'"
    has_goal "$T/a" 'answer(q1, 3, human:me)' "the spec KB has the answer, as the number 3"
    hasnt_goal "$T/a" 'to_ask(q1)' "q1 is answered"
    hasnt_goal "$T/a" 'defeated(q1)' "accepting the default 3 is not a defeat"
    srv_stop
    # pin-answer keeps a number as a number too
    kb_new "$T/b" <<'EOF2'
uses([build]).
request(r1, 'Numbers must stay sane').
claim(c1, preserve, 'Retries are bounded').
cites(c1, 'Numbers must stay sane').
question(q1, c1, 'How many retries').
assumed(q1, 3).
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF2
    printf '3\n' > "$T/ans.txt"
    okb --dir "$T/b" pin-question q1 tracker 'gh:acme/billing#9'; rc_is 0
    okb --dir "$T/b" pin-answer q1 'gh:acme/billing#9' --text-file "$T/ans.txt" --by alex; rc_is 0 "pin-answer"
    has_goal "$T/b" 'answer(q1, 3, human:alex)' "pin-answer writes 3 as a number"
    hasnt_goal "$T/b" 'defeated(q1)' "pin-answer of the default is not a defeat"
    # a queued line that is not ground is reported, not skipped silently
    printf 'pending(%s, %s, [answer(q1, X, human)]).\n' "'2026-11-06T10:00:00Z'" "'sha256:00'" >> "$T/b/answers.pending"
    okb --dir "$T/b" add "note(c1, 'a write')"; rc_is 0 "a write with a bad queued line"
    printf '%s\n' "$err" | grep -Fiq 'answers.pending' || note "the write did not report the bad line in answers.pending: $(snip "$err")"
}

t_QS25() {  # T37 c5: no form while an answer waits; a tracker-owned question shows its item; a refused queued answer shows
    kb_a "$T/a"
    wr ann --dir "$T/a" add "note(c1, 'ann works here')"; rc_is 0 "ann takes the lease" || return
    wr ann --dir "$T/a" pin-question q2 tracker 'gh:acme/billing#7'; rc_is 0 "pin-question q2 to the tracker"
    srv --dir "$T/a" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    chk form "$T/page.html" "$L_A" q1 yes no other
    post /answer "token=$tok" "kb=$kb" q=q1 choice=no; code_is 303 "the answer is queued"
    page_ok || return
    chk pending "$T/page.html" "$L_A" q1
    chk noform "$T/page.html" "$L_A" q1
    post /answer "token=$tok" "kb=$kb" q=q1 choice=yes; code_is 409 "a second answer while one waits"
    chk noform "$T/page.html" "$L_A" q2
    chk ctx "$T/page.html" "$L_A" q2 'gh:acme/billing#7'
    # a queued answer that the KB refuses: shown on the page
    printf 'pending(%s, %s, [answer(q9, x, human)]).\n' "'2026-11-06T10:00:00Z'" "'sha256:0123'" >> "$T/a/answers.pending"
    wr ann --dir "$T/a" add "note(c1, 'ann writes again')"
    grep -q 'refused' "$T/a/answers.applied" 2>/dev/null || note "the bad queued answer was not refused: $(snip "$err")"
    page_ok || return
    chk refused "$T/page.html" "$L_A" q9
    srv_stop
}

t_QS26() {  # T37 c4, c6: the workflow text says when to pin; subagents of one pane are one writer
    local t
    for t in build discovery; do
        okb help $t
        for w in 'pin-question' 'init' '--source' 'pin-request'; do
            printf '%s\n' "$out" | grep -Fq -- "$w" || note "help $t lacks $w"
        done
    done
    grep -Fq -- '--source' "$REPO/prompt/panes/review.md" || note "panes/review.md does not use --source"
    okb help core; printf '%s\n' "$out" | grep -Fiq 'subagents' && printf '%s\n' "$out" | grep -Fq 'one writer' || note "help core does not say that subagents of a pane count as one writer"
    grep -Fq 'CLAUDE_CODE_SESSION_ID' "$REPO/prompt/PANES.md" && grep -Fiq 'one writer' "$REPO/prompt/PANES.md" || note "PANES.md does not say that subagents of a pane count as one writer"
}

# ================================================================ T38 (fixes found when T37 was verified; D26 S13, D23 P9)
t_QS27() {  # T38 c10: a question pinned to a ledger ask has no answer form; the page names its ask
    mkhub "$T/h"; local A
    A=$(hf "$T/h" --session build add ask --title 'Should the list show the newest invoice first' --waits-on me)
    kb_a "$T/a"
    okb --dir "$T/a" pin-question q1 ledger "$A"; rc_is 0 "pin-question to the ledger"
    srv --dir "$T/a" --hub "$T/h" || return; page_ok || return
    chk noform "$T/page.html" "$L_A" q1
    chk ctx "$T/page.html" "$L_A" q1 "$A"
    python3 -I - "$T/page.html" "$A" <<'PY' || note "q1 has no <p class=\"owner\"> that names the ask $A"
import sys, re
raw = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'data-id="q1".*?(<p class="owner">.*?</p>)', raw, re.S)
sys.exit(0 if m and sys.argv[2] in m.group(1) else 1)
PY
    local tok; tok=$(token)
    post /answer "token=$tok" "ask=$A" 'text=no'; code_is 303 "the answer goes through the ask"
    askjson "$T/h" "$A" "d['item']['status']=='done'"
    has_goal "$T/a" "answer(q1, no, human:me)" "the ask's answer reaches the spec KB"
    srv_stop
    srv --dir "$T/a" || return; page_ok || return       # no hub: the page still names the ask, no form
    hasnt_goal "$T/a" 'to_ask(q1)' "q1 is answered"
    srv_stop
    kb_a "$T/b"; okb --dir "$T/b" pin-question q1 ledger "$A"
    srv --dir "$T/b" || return; page_ok || return
    chk noform "$T/page.html" "$L_A" q1
    chk ctx "$T/page.html" "$L_A" q1 "$A"
    srv_stop
}

# req_has KB T...: the request/2 line of KB/kb.pl has each text T; !T: lacks it
req_has() { local f=$1/kb.pl x l; shift; l=$(grep -E '^request\(r1, ' "$f")
            for x in "$@"; do case $x in '!'*) printf '%s' "$l" | grep -Fq -- "${x#!}" && note "the request text has ${x#!}: $(snip "$l")";;
                                        *) printf '%s' "$l" | grep -Fq -- "$x" || note "the request text lacks $x: $(snip "$l")";; esac; done; }
t_QS28() {  # T38 c11: Jira Cloud v3 (ADF description) and a list wrapper {count, value:[item]}
    local S
    cat > "$T/jira3.json" <<'J'
{"key": "WID-4", "fields": {"summary": "Export must be daily", "status": {"name": "To Do"},
 "description": {"type": "doc", "version": 1, "content": [
   {"type": "paragraph", "content": [{"type": "text", "text": "Send the export "}, {"type": "text", "text": "each day.", "marks": [{"type": "strong"}]}]},
   {"type": "bulletList", "content": [{"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "One file per day"}]}]}]}]}}}
J
    S=$T/jira3; okb init "$S" --request-file "$T/jira3.json" --source 'jira:acme/WID-4' --uses build; rc_is 0 "jira v3: init --source"
    req_has "$S" 'Export must be daily' 'Send the export each day.' 'One file per day' '!paragraph' '!"type"'   # jira v3: the text of the ADF description, not the raw JSON
    sed -i 's/"To Do"/"Done"/' "$T/jira3.json"
    okb --dir "$S" pin-request --request-file "$T/jira3.json"; rc_is 0
    hasnt_goal "$S" 'request_stale(r1)' "jira v3: a status move is no change"
    sed -i 's/each day\./each hour./' "$T/jira3.json"
    okb --dir "$S" pin-request --request-file "$T/jira3.json"; rc_is 0
    has_goal "$S" 'request_stale(r1)' "jira v3: an edit of the ADF description makes the request stale"
    # an ADO list wrapper with one item
    printf '{"count": 1, "value": [{"id": 7, "rev": 3, "fields": {"System.Title": "Export must be daily", "System.Description": "Send the export each day.", "System.BoardColumn": "Todo"}}]}\n' > "$T/ado.json"
    S=$T/ado; okb init "$S" --request-file "$T/ado.json" --source 'ado:acme/7' --uses build; rc_is 0 "ado wrapper: init --source"
    req_has "$S" 'Export must be daily' 'Send the export each day.' '!Todo' '!"count"'   # ado wrapper: the item is unwrapped, no column
    sed -i 's/"Todo"/"Doing"/; s/"rev": 3/"rev": 4/' "$T/ado.json"
    okb --dir "$S" pin-request --request-file "$T/ado.json"; rc_is 0
    hasnt_goal "$S" 'request_stale(r1)' "ado wrapper: a BoardColumn move is no change"
    # a wrapper with two items, and JSON with no title: read raw, never in silence
    printf '{"count": 2, "value": [{"id": 7, "fields": {"System.Title": "A"}}, {"id": 8, "fields": {"System.Title": "B"}}]}\n' > "$T/two.json"
    okb init "$T/two" --request-file "$T/two.json" --source 'ado:acme/7' --uses build
    printf '%s\n' "$err" | grep -Eqi 'warn|raw' || note "a wrapper with two items is read raw in silence (stderr: $(snip "$err"))"
    printf '{"id": 9, "labels": ["x"]}\n' > "$T/notitle.json"
    okb init "$T/notitle" --request-file "$T/notitle.json" --source 'gh:acme/widgets#9' --uses build
    printf '%s\n' "$err" | grep -Eqi 'warn|raw' || note "JSON with no title is read raw in silence (stderr: $(snip "$err"))"
}

t_QS29() {  # T38 c12: the ask path keeps a numeric answer as a number; any other text stays an atom
    mkhub "$T/h"; local A B
    A=$(hf "$T/h" --session build add ask --title 'How many retries' --waits-on me)
    B=$(hf "$T/h" --session build add ask --title 'Which build number' --waits-on me)
    kb_new "$T/a" <<'EOF2'
uses([build]).
request(r1, 'Numbers must stay sane').
claim(c1, preserve, 'Retries are bounded').
cites(c1, 'Numbers must stay sane').
question(q1, c1, 'How many retries').
assumed(q1, 3).
question(q2, c1, 'Which build number').
assumed(q2, latest).
question(q3, c1, 'How long is the backoff').
assumed(q3, 2).
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF2
    okb --dir "$T/a" pin-question q1 ledger "$A"; rc_is 0
    okb --dir "$T/a" pin-question q2 ledger "$B"; rc_is 0
    srv --dir "$T/a" --hub "$T/h" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" 'Numbers must stay sane')
    post /answer "token=$tok" "ask=$A" 'text=5'; code_is 303 "answer the ask with 5"
    has_goal "$T/a" 'answer(q1, 5, human:me)' "the ask path keeps 5 as the number 5"
    has_goal "$T/a" 'defeated(q1)' "5 defeats the default 3"
    post /answer "token=$tok" "ask=$B" 'text=007'; code_is 303 "answer the ask with 007"
    has_goal "$T/a" "answer(q2, '007', human:me)" "007 stays an atom (it does not print back as 007)"
    post /answer "token=$tok" "kb=$kb" q=q3 choice=other 'text=2.5'; code_is 303 "the KB form with 2.5"
    has_goal "$T/a" 'answer(q3, 2.5, human)' "the KB form keeps 2.5 as a number"
    srv_stop
    # pin-answer of the same kind of answer writes the same term
    kb_new "$T/b" <<'EOF2'
uses([build]).
request(r1, 'Numbers must stay sane').
claim(c1, preserve, 'Retries are bounded').
cites(c1, 'Numbers must stay sane').
question(q1, c1, 'How many retries').
assumed(q1, 3).
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF2
    okb --dir "$T/b" pin-question q1 tracker 'gh:acme/billing#7'; rc_is 0
    printf '5\n' > "$T/ans.txt"
    okb --dir "$T/b" pin-answer q1 'gh:acme/billing#7' --text-file "$T/ans.txt" --by alex; rc_is 0
    has_goal "$T/b" 'answer(q1, 5, human:alex)' "pin-answer keeps 5 as a number"
}

t_QS30() {  # T40 c4: a top level with a title of its own is the item, even with a value list
    printf '{"title": "Top title", "body": "Top body", "count": 1, "value": [{"title": "Inner title", "body": "Inner body"}]}\n' > "$T/top.json"
    okb init "$T/top" --request-file "$T/top.json" --source 'gh:acme/widgets#30' --uses build; rc_is 0 "a titled top level with a value list: init"
    req_has "$T/top" 'Top title' 'Top body' '!Inner title' '!Inner body'
    printf '{"fields": {"System.Title": "Ado top"}, "count": 1, "value": [{"fields": {"System.Title": "Ado inner"}}]}\n' > "$T/adotop.json"
    okb init "$T/adotop" --request-file "$T/adotop.json" --source 'ado:acme/30' --uses build; rc_is 0
    req_has "$T/adotop" 'Ado top' '!Ado inner'
    printf '{"count": 1, "value": [{"title": "Only inner"}]}\n' > "$T/wrap.json"
    okb init "$T/wrap" --request-file "$T/wrap.json" --source 'gh:acme/widgets#31' --uses build; rc_is 0
    req_has "$T/wrap" 'Only inner' '!"count"'   # a wrapper with no title of its own is still unwrapped
}

run_one() {  # run_one ID
    local id=$1 fn=t_$1 i
    [ -n "${ONLY:-}" ] && ! [[ $id =~ $ONLY ]] && return 0
    T=$(mktemp -d "$base/t.XXXXXX"); FAILS=(); SKIPPED=0
    "$fn" </dev/null >/dev/null 2>&1 || true
    srv_stop
    if [ ${#FAILS[@]} -eq 0 ] && [ "$SKIPPED" = 1 ]; then skip=$((skip+1)); echo "SKIP $id"
    elif [ ${#FAILS[@]} -eq 0 ]; then pass=$((pass+1)); echo "PASS $id"
    else fail=$((fail+1)); failed+=("$id"); echo "FAIL $id"; for i in "${FAILS[@]}"; do echo "     - $i"; done; fi
}
for n in $(seq 1 30); do run_one QS$n; done
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ "$fail" -eq 0 ]

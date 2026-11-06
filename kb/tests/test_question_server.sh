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
#   c6 only answer records, only through orbit-kb                   : QS14
#   c7 the ledger's asks, read-only, with the hubflow command       : QS15
#   c8 docs: help serve, README, CONTRACT D26                       : QS16
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
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID) unset "$v";; esac; done
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
t_QS8() {  # another writer holds the lock: nothing is written, the page names the holder, no --take
    kb_spec "$T/s" 'Alpha rules' ''
    printf 'ann 2026-11-06T10:00:00Z\n' > "$T/s/writer.lock"
    cp "$T/s/kb.pl" "$T/kb.before"; cp "$T/s/writer.lock" "$T/lock.before"
    srv --dir "$T/s" || return
    page_ok || return; local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" 'Alpha rules')
    post /answer "token=$tok" "kb=$kb" q=q1 choice=no; code_is 409 "POST under a held lock"
    same_file "$T/s/kb.pl" "$T/kb.before" "kb.pl"
    same_file "$T/s/writer.lock" "$T/lock.before" "writer.lock"
    grep -q 'writer_takeover' "$T/s/kb.pl" && note "a takeover was recorded"
    chk message "$T/post.html" 'ann'
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
    q "$T/a" "answer(q2, A, human), atom_string(A, S), S == \"x'), claim(c9, introduce, 'y'). %\""
    [ "$rc" = 0 ] || note "the answer text is not the posted text (rc $rc $(snip "$out$err"))"
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
for n in $(seq 1 16); do run_one QS$n; done
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ "$fail" -eq 0 ]

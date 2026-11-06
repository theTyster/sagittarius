#!/usr/bin/env bash
# Black-box tests for `orbit-kb view questions` (ticket T10, CONTRACT D24).
# The only source of expected behavior is kb/CONTRACT.md (D24, with D22 for blocking/1 and pin).
# Usage: kb/tests/test_question_view.sh [path-to-orbit-kb]      ONLY='<regex>' runs matching ids.
# Summary line: orbit-kb=... pass=N fail=N skip=N FAILED-IDS. Exit 0 all pass, 1 a failure, 2 cannot run.
#
# Requirement map (claims of ticket T10 -> tests):
#   c1 blocking items with text, default, claim, cited request : QV1-QV5
#   c2 the ledger's asks that wait on the owner, with age       : QV6-QV9
#   c3 no KB id without its text                                : QV10-QV12
#   c4 the pin stamp of each KB read                            : QV13-QV15
#   multiple KBs                                                : QV16-QV17
#   no external dependency, escaping, page shape                : QV18-QV19
#   errors, read-only, --out                                    : QV20-QV22
set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
OKB=${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}
LIB=${ORBIT_KB_TEST_LIB:-$here/../share/orbit-kb}
TMO=${ORBIT_KB_TEST_TIMEOUT:-120}
for tool in swipl python3 sha256sum timeout mktemp grep cmp; do
    command -v "$tool" >/dev/null 2>&1 || { echo "test_question_view.sh: required tool not found: $tool" >&2; exit 2; }
done
[ -x "$OKB" ] || { echo "test_question_view.sh: the CLI is missing or not executable: $OKB" >&2; exit 2; }
OKB=$(cd "$(dirname "$OKB")" && pwd -P)/$(basename "$OKB")
LIB=$(cd "$LIB" && pwd -P)
for v in $(compgen -e); do case $v in ORBIT_KB*) unset "$v";; esac; done
export ORBIT_KB_LIB="$LIB"

pass=0 fail=0 skip=0 failed=() FAILS=()
base=$(mktemp -d "${TMPDIR:-/tmp}/orbit-kb-qv.XXXXXX") || exit 2
trap 'rm -rf "$base"' EXIT
out="" err="" rc=0 T=""

# ---- an HTML reader (python, standard library only). Modes print nothing and exit 0 on success;
# on failure they print one reason per line and exit 1.
cat > "$base/page.py" <<'PY'
import sys, html.parser, re
VOID = {"meta","link","br","hr","img","input","area","base","col","embed","source","track","wbr"}
class N:
    def __init__(s, tag, attrs, parent): s.tag=tag; s.attrs=dict(attrs); s.parent=parent; s.kids=[]; s.txt=[]
    def classes(s): return (s.attrs.get("class") or "").split()
    def text(s): return norm("".join(s.txt) + "".join(k.text() for k in s.kids))
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
    raw=open(f,encoding="utf-8").read(); p=P(); p.feed(raw); p.close(); return raw,p
def under(n, tag, cls):
    while n is not None:
        if n.tag==tag and cls in n.classes(): return n
        n=n.parent
    return None
def items(p):
    for n in p.all:
        if n.tag=="li" and "item" in n.classes():
            sec=under(n,"section","kb"); yield sec.attrs.get("data-stamp") if sec else None, n
def main():
    mode, f, *a = sys.argv[1:]
    raw, p = load(f); bad=[]
    if mode=="item":      # item FILE KIND ID [stamp=S] has:TEXT... cls:NAME=TEXT... notcls:NAME
        kind, iid, *specs = a; want=None
        for s in list(specs):
            if s.startswith("stamp="): want=s[6:]; specs.remove(s)
        hit=[n for st,n in items(p) if n.attrs.get("data-kind")==kind and n.attrs.get("data-id")==iid and (want is None or st==want)]
        if len(hit)!=1: bad.append("want exactly one item %s %s%s, found %d"%(kind,iid," in "+want if want else "",len(hit)))
        else:
            n=hit[0]
            for s in specs:
                if s.startswith("has:"):
                    if s[4:] not in n.text(): bad.append("item %s %s lacks text %r (has %r)"%(kind,iid,s[4:],n.text()[:300]))
                elif s.startswith("cls:"):
                    c,_,t=s[4:].partition("=")
                    els=[k for k in n.walk() if c in k.classes()]
                    if not els: bad.append("item %s %s has no element of class %s"%(kind,iid,c))
                    elif not any(t in k.text() for k in els): bad.append("class %s of item %s %s lacks %r (has %r)"%(c,kind,iid,t,[k.text()[:200] for k in els]))
                elif s.startswith("clsnot:"):
                    c,_,t=s[7:].partition("=")
                    for k in n.walk():
                        if c in k.classes() and t in k.text(): bad.append("class %s of item %s %s must not hold %r"%(c,kind,iid,t))
    elif mode=="ids":     # ids FILE KIND... : the data-ids of the items of those kinds, sorted, must equal the pairs after --
        sep=a.index("--"); kinds=a[:sep]; want=sorted(a[sep+1:])
        got=sorted(n.attrs.get("data-id","") for st,n in items(p) if n.attrs.get("data-kind") in kinds)
        if got!=want: bad.append("items of kind %s: got %s, want %s"%(kinds,got,want))
    elif mode=="noitems":
        k=[(n.attrs.get("data-kind"),n.attrs.get("data-id")) for st,n in items(p)]
        if k: bad.append("expected no items, found %s"%k)
    elif mode=="ask":     # ask FILE ID has:TEXT... age:TEXT notin:TEXT
        iid,*specs=a
        hit=[n for n in p.all if n.tag=="li" and "ask" in n.classes() and n.attrs.get("data-id")==iid and under(n,"section","ledger")]
        if len(hit)!=1: bad.append("want exactly one ask %s in the ledger section, found %d"%(iid,len(hit)))
        else:
            n=hit[0]
            for s in specs:
                if s.startswith("has:") and s[4:] not in n.text(): bad.append("ask %s lacks %r (has %r)"%(iid,s[4:],n.text()))
                if s.startswith("age:"):
                    ag=[k.text() for k in n.walk() if "age" in k.classes()]
                    if not any(s[4:] in t for t in ag): bad.append("ask %s: age element lacks %r (has %r)"%(iid,s[4:],ag))
    elif mode=="askids":  # askids FILE -- ID...
        want=sorted(a[a.index("--")+1:])
        got=sorted(n.attrs.get("data-id","") for n in p.all if n.tag=="li" and "ask" in n.classes())
        if got!=want: bad.append("asks on the page: %s, want %s"%(got,want))
    elif mode=="noledger":
        if any(n.tag=="section" and "ledger" in n.classes() for n in p.all): bad.append("a ledger section exists without --ledger")
    elif mode=="alltext":  # alltext FILE TEXT... : the whole page text has each; notext: lacks
        t=norm("".join(n.text() for n in p.root.kids))
        for s in a:
            if s.startswith("!"):
                if s[1:] in t: bad.append("page text has %r, it must not"%s[1:])
            elif s not in t: bad.append("page text lacks %r"%s)
    elif mode=="notag":
        for tg in a:
            if any(n.tag==tg for n in p.all): bad.append("page has a <%s> element"%tg)
    elif mode=="refs":     # every kbid is in a span.ref that holds a non-empty kbtext; at least MIN kbids
        mn=int(a[0]); ids=[n for n in p.all if "kbid" in n.classes()]
        if len(ids)<mn: bad.append("only %d kbid elements, want at least %d"%(len(ids),mn))
        for n in ids:
            r=under(n,"span","ref")
            if r is None: bad.append("kbid %r is not inside span.ref"%n.text()); continue
            tx=[k for k in r.walk() if "kbtext" in k.classes() and k.text()]
            if not tx: bad.append("kbid %r has no non-empty kbtext in its ref"%n.text())
    elif mode=="stamps":   # stamps FILE STAMP... : sections with those data-stamps, in order, each shown as text
        secs=[n for n in p.all if n.tag=="section" and "kb" in n.classes()]
        got=[n.attrs.get("data-stamp") for n in secs]
        if got!=a: bad.append("kb sections have stamps %s, want %s"%(got,a))
        for n in secs:
            if n.attrs.get("data-stamp","?") not in n.text(): bad.append("section %s does not show its stamp as text"%n.attrs.get("data-stamp"))
    elif mode=="extdeps":
        if re.search(r"<script[^>]*\ssrc\s*=", raw, re.I): bad.append("a <script src>")
        if re.search(r"<link\b", raw, re.I): bad.append("a <link>")
        if re.search(r"@import", raw, re.I): bad.append("@import")
        if re.search(r"url\(\s*['\"]?\s*(https?:|//)", raw, re.I): bad.append("url() to a remote address")
        for m in re.finditer(r"""\b(src|href|action|poster|data)\s*=\s*["']?\s*(https?:|//)""", raw, re.I): bad.append("attribute %s to a remote address"%m.group(1))
        if not raw.lstrip().lower().startswith("<!doctype html"): bad.append("does not begin with <!DOCTYPE html>")
        if not any(n.tag=="title" and n.text() for n in p.all): bad.append("no non-empty <title>")
    for b in bad: print(b)
    sys.exit(1 if bad else 0)
main()
PY
pg() { python3 -I "$base/page.py" "$@"; }     # pg MODE FILE ARGS...: assertion on the page
chk() {  # chk MODE FILE ARGS...: record the reasons of a failed page assertion
    local r; r=$(pg "$@" 2>&1) || { local IFS=$'\n'; FAILS+=("page check $1: $r"); return 1; }; return 0
}
note() { FAILS+=("$*"); }
snip() { printf '%s' "$1" | head -c 300 | tr '\n' '~'; }

okb() {  # okb ARGS...: run the CLI in $T with a private cache; sets out err rc
    ( cd "$T" && XDG_CACHE_HOME="$T/.cache" exec timeout "$TMO" "$OKB" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null
    rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err")
}
rc_is() { [ "$rc" = "$1" ] && return 0; note "${2:+$2: }exit $rc, want $1 (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; }
err_has() { printf '%s\n%s\n' "$out" "$err" | grep -Eiq -- "$1" && return 0; note "${2:+$2: }output lacks /$1/ (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; }
view() {  # view ARGS...: `view questions ARGS` to $T/page.html, exit 0 required
    okb view questions "$@"; printf '%s\n' "$out" > "$T/page.html"
    rc_is 0 "view questions $*" || return 1
    [ -s "$T/page.html" ] || { note "view questions printed no page"; return 1; }
}

# ---- fixtures
kb_new() { mkdir -p "$1" && cat > "$1/kb.pl"; }
# kb A: two requests; c1 (preserve, r1) is contested, so q1 and q2 are to_ask; q3 is answered;
# c2 (introduce, r2) has a check that never ran, so c2 is under and k1 is unrun.
kb_a() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Billing must be less confusing for customers').
request(r2, 'Finance needs a spreadsheet of every invoice').
claim(c1, preserve, 'The invoice list is sorted by date').
claim(c2, introduce, 'Invoices can be exported as CSV').
cites(c1, 'Billing must be less confusing for customers').
cites(c2, 'Finance needs a spreadsheet of every invoice').
check(k1, c2).
question(q1, c1, 'Should the list show the newest invoice first').
question(q2, c1, 'Should paid invoices be hidden by default').
question(q3, c1, 'Is the list paged').
assumed(q1, yes).
assumed(q2, no).
assumed(q3, no).
answer(q3, yes, human).
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF
}
# kb B: the same ids with other words, to show that the sections stay apart.
kb_b() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'The mobile app must work offline').
claim(c1, preserve, 'Saved drafts survive a restart').
cites(c1, 'The mobile app must work offline').
question(q1, c1, 'Should drafts be deleted after thirty days').
assumed(q1, no).
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF
}
kb_clean() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Keep the lights on').
claim(c1, preserve, 'The service stays up').
cites(c1, 'Keep the lights on').
EOF
}
ledger_json() { cat > "$1" <<'EOF'
[
 {"id":"A12","kind":"ask","title":"Which payment provider do we pick","status":"open","waits_on":null,"age_days":17},
 {"id":"A15","kind":"ask","title":"Approve the refund wording","status":"waiting","waits_on":null,"age_days":3},
 {"id":"A20","kind":"ask","title":"Vendor must send the tax form","status":"open","waits_on":"pat","age_days":40},
 {"id":"A07","kind":"ask","title":"Settled question about the logo","status":"done","waits_on":null,"age_days":90},
 {"id":"T3","kind":"thread","title":"A thread and not an ask","status":"open","waits_on":null,"age_days":5}
]
EOF
}
stamp_of() { echo "spec-kb@sha256:$(sha256sum "$1/kb.pl" | cut -d' ' -f1)"; }

# ---- c1: blocking items
t_QV1() {  # a to_ask question: text, default, the claim it blocks, the cited request text
    kb_a "$T/a"; view --dir "$T/a" || return
    chk item "$T/page.html" to_ask q1 'has:Should the list show the newest invoice first' \
        'cls:default=yes' 'cls:blocks=The invoice list is sorted by date' 'cls:blocks=c1' \
        'cls:cited=Billing must be less confusing for customers'
    chk item "$T/page.html" to_ask q2 'has:Should paid invoices be hidden by default' \
        'cls:default=no' 'cls:blocks=The invoice list is sorted by date' 'cls:cited=Billing must be less confusing for customers'
}
t_QV2() {  # the cited text is the claim's own request, and the default is only that question's
    kb_a "$T/a"; view --dir "$T/a" || return
    chk item "$T/page.html" to_ask q1 'clsnot:cited=Finance needs a spreadsheet' 'clsnot:default=no'
    chk item "$T/page.html" to_ask q2 'clsnot:default=yes'
}
t_QV3() {  # an answered question is not shown; exactly the to_ask questions are
    kb_a "$T/a"; view --dir "$T/a" || return
    chk ids "$T/page.html" to_ask -- q1 q2
    chk alltext "$T/page.html" '!Is the list paged'
}
t_QV4() {  # other blocking items: an under claim and an unrun check show text, claim and cited request
    kb_a "$T/a"; view --dir "$T/a" || return
    chk item "$T/page.html" under c2 'has:Invoices can be exported as CSV' 'cls:blocks=Invoices can be exported as CSV' \
        'cls:cited=Finance needs a spreadsheet of every invoice'
    chk item "$T/page.html" check_unrun k1 'has:Invoices can be exported as CSV' 'cls:blocks=Invoices can be exported as CSV' \
        'cls:cited=Finance needs a spreadsheet of every invoice'
}
t_QV5() {  # a KB where nothing blocks: no item, and the page says so; the item list follows the KB
    kb_clean "$T/c"; view --dir "$T/c" || return
    chk noitems "$T/page.html"; chk alltext "$T/page.html" 'Nothing blocks done.'
    kb_a "$T/a2"; echo "answer(q1, yes, human)." >> "$T/a2/kb.pl"
    view --dir "$T/a2" || return
    chk ids "$T/page.html" to_ask -- q2
}

# ---- c2: the ledger's asks
t_QV6() {  # asks that wait on the owner appear with their title and age
    kb_a "$T/a"; ledger_json "$T/asks.json"; view --dir "$T/a" --ledger "$T/asks.json" || return
    chk ask "$T/page.html" A12 'has:Which payment provider do we pick' 'age:17 days'
    chk ask "$T/page.html" A15 'has:Approve the refund wording' 'age:3 days'
}
t_QV7() {  # no other object: not an ask for another person, not a closed ask, not a thread
    kb_a "$T/a"; ledger_json "$T/asks.json"; view --dir "$T/a" --ledger "$T/asks.json" || return
    chk askids "$T/page.html" -- A12 A15
    chk alltext "$T/page.html" '!Vendor must send the tax form' '!Settled question about the logo' '!A thread and not an ask'
}
t_QV8() {  # without --ledger there is no ledger section; the KB part still works
    kb_a "$T/a"; view --dir "$T/a" || return
    chk noledger "$T/page.html"; chk ids "$T/page.html" to_ask -- q1 q2
}
t_QV9() {  # an empty ledger is valid; the age comes from the file and not from the clock
    kb_a "$T/a"; echo '[]' > "$T/e.json"; view --dir "$T/a" --ledger "$T/e.json" || return
    chk askids "$T/page.html" --
    cat > "$T/o.json" <<'EOF'
[{"id":"A99","kind":"ask","title":"Pick the release date","status":"open","waits_on":null,"age_days":400}]
EOF
    view --dir "$T/a" --ledger "$T/o.json" || return
    chk ask "$T/page.html" A99 'has:Pick the release date' 'age:400 days'
}

# ---- c3: no KB id without its text
t_QV10() {  # every kbid is in a span.ref with a non-empty kbtext; the fixture shows many ids
    kb_a "$T/a"; view --dir "$T/a" || return
    chk refs "$T/page.html" 6
}
t_QV11() {  # the claim id of an item is shown through a ref: id and claim text together
    kb_a "$T/a"; view --dir "$T/a" || return
    chk refs "$T/page.html" 1
    chk item "$T/page.html" to_ask q1 'cls:kbid=q1' 'cls:kbtext=Should the list show the newest invoice first' \
        'cls:kbid=c1' 'cls:kbtext=The invoice list is sorted by date'
}
t_QV12() {  # also with a question with no default, a check, and the ledger
    kb_a "$T/a"; printf "question(q4, c2, 'Should the export include totals').\nattest(d2, divergence, c2, claim(c2), agent, '2026-10-15T10:00:02Z').\n" >> "$T/a/kb.pl"
    ledger_json "$T/asks.json"; view --dir "$T/a" --ledger "$T/asks.json" || return
    chk refs "$T/page.html" 6
    chk item "$T/page.html" to_ask q4 'has:Should the export include totals' 'cls:default=none' 'cls:blocks=Invoices can be exported as CSV'
}

# ---- c4: the pin stamp
t_QV13() {  # the page names spec-kb@sha256:HEX of kb.pl, in a section that shows it
    kb_a "$T/a"; view --dir "$T/a" || return
    chk stamps "$T/page.html" "$(stamp_of "$T/a")"
}
t_QV14() {  # the stamp is the one that `orbit-kb pin` prints, and pin --check accepts it
    kb_a "$T/a"; okb --dir "$T/a" pin; rc_is 0 "pin" || return
    local pinned=${out%% *}; view --dir "$T/a" || return
    chk stamps "$T/page.html" "$pinned"
    okb --dir "$T/a" pin --check "$(pg_stamp "$T/page.html")"; rc_is 0 "pin --check of the stamp on the page"
}
pg_stamp() { grep -oE 'spec-kb@sha256:[0-9a-f]{64}' "$1" | head -n1; }
t_QV15() {  # the stamp follows the file: add a fact, the page names the new digest, not the old
    kb_a "$T/a"; local before; before=$(stamp_of "$T/a")
    echo "note(c1, 'edited')." >> "$T/a/kb.pl"; view --dir "$T/a" || return
    chk stamps "$T/page.html" "$(stamp_of "$T/a")"
    grep -qF "$before" "$T/page.html" && note "the page still names the old stamp"
}

# ---- multiple KBs
t_QV16() {  # two KBs: two sections in the order given, each with its stamp and its own items
    kb_a "$T/a"; kb_b "$T/b"; view --dir "$T/a" --dir "$T/b" || return
    chk stamps "$T/page.html" "$(stamp_of "$T/a")" "$(stamp_of "$T/b")"
    chk item "$T/page.html" to_ask q1 "stamp=$(stamp_of "$T/a")" 'has:Should the list show the newest invoice first' 'cls:default=yes' 'cls:cited=Billing must be less confusing'
    chk item "$T/page.html" to_ask q1 "stamp=$(stamp_of "$T/b")" 'has:Should drafts be deleted after thirty days' 'cls:default=no' 'cls:cited=The mobile app must work offline' \
        'clsnot:blocks=sorted by date'
    view --dir "$T/b" --dir "$T/a" || return
    chk stamps "$T/page.html" "$(stamp_of "$T/b")" "$(stamp_of "$T/a")"
}
t_QV17() {  # c3 holds with two KBs and a ledger; a KB found by $ORBIT_KB and the walk is one section
    kb_a "$T/a"; kb_b "$T/b"; ledger_json "$T/asks.json"
    view --dir "$T/a" --dir "$T/b" --ledger "$T/asks.json" || return
    chk refs "$T/page.html" 8
    ( cd "$T/b" && ORBIT_KB="$T/a" XDG_CACHE_HOME="$T/.cache" timeout "$TMO" "$OKB" view questions ) > "$T/page2.html" 2>"$T/.err"
    rc=$?; out=$(<"$T/page2.html"); rc_is 0 "view with \$ORBIT_KB" || return
    chk stamps "$T/page2.html" "$(stamp_of "$T/a")"
}

# ---- page shape
t_QV18() {  # one file, no external dependency
    kb_a "$T/a"; kb_b "$T/b"; ledger_json "$T/asks.json"
    view --dir "$T/a" --dir "$T/b" --ledger "$T/asks.json" || return
    chk extdeps "$T/page.html"
}
t_QV19() {  # KB and ledger text is escaped
    kb_new "$T/x" <<'EOF'
uses([build]).
request(r1, 'Keep <i>markup</i> & quotes safe').
claim(c1, preserve, 'Show <b>bold</b> & "quoted" text').
cites(c1, 'Keep <i>markup</i> & quotes safe').
question(q1, c1, 'Is a <u>tag</u> & an ampersand shown as text').
assumed(q1, yes).
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF
    printf '[{"id":"A1","kind":"ask","title":"Ship <script>x</script> & go","status":"open","waits_on":null,"age_days":2}]\n' > "$T/l.json"
    view --dir "$T/x" --ledger "$T/l.json" || return
    chk notag "$T/page.html" b i u script
    chk item "$T/page.html" to_ask q1 'has:Is a <u>tag</u> & an ampersand shown as text' 'cls:cited=Keep <i>markup</i> & quotes safe'
    chk ask "$T/page.html" A1 'has:Ship <script>x</script> & go'
}

# ---- errors, read-only, --out
t_QV20() {  # the command takes no write: kb.pl and the KB directory do not change
    kb_a "$T/a"; cp "$T/a/kb.pl" "$T/kb.before"; ls -A "$T/a" > "$T/ls.before"
    view --dir "$T/a" || return
    cmp -s "$T/a/kb.pl" "$T/kb.before" || note "kb.pl changed"
    ls -A "$T/a" | cmp -s - "$T/ls.before" || note "the KB directory changed (a lock, a run log, or a cache file)"
}
t_QV21() {  # --out writes the page to F and prints nothing; stdout and F hold the same page
    kb_a "$T/a"; okb view questions --dir "$T/a" --out "$T/p.html"; rc_is 0 "view --out" || return
    [ -z "$out" ] || note "--out printed to stdout: $(snip "$out")"
    chk stamps "$T/p.html" "$(stamp_of "$T/a")"; chk ids "$T/p.html" to_ask -- q1 q2
    okb view questions --dir "$T/a"; printf '%s\n' "$out" > "$T/s.html"
    chk stamps "$T/s.html" "$(stamp_of "$T/a")"
}
t_QV22() {  # exit 2: bad ledger, missing ledger, unknown view, no view, no KB; no page is written
    kb_a "$T/a"; view --dir "$T/a" || return
    okb view questions --dir "$T/a" --ledger "$T/none.json"; rc_is 2 "missing ledger" ; err_has 'ledger' "missing ledger names the ledger"
    echo 'not json' > "$T/bad.json"; okb view questions --dir "$T/a" --ledger "$T/bad.json"; rc_is 2 "ledger not JSON"
    echo '{"id":"A1"}' > "$T/obj.json"; okb view questions --dir "$T/a" --ledger "$T/obj.json"; rc_is 2 "ledger not an array"
    echo '[{"id":"A1","kind":"ask","title":"No age","status":"open","waits_on":null}]' > "$T/noage.json"
    okb view questions --dir "$T/a" --ledger "$T/noage.json"; rc_is 2 "ledger row without age_days"
    okb view answers --dir "$T/a"; rc_is 2 "unknown view name"
    okb view; rc_is 2 "no view name"
    okb view questions --dir "$T/nokb"; rc_is 2 "no KB"
    rm -f "$T/q.html"; okb view questions --dir "$T/a" --ledger "$T/bad.json" --out "$T/q.html"
    [ ! -e "$T/q.html" ] || note "a failed run wrote the --out file"
}

run_one() {  # run_one ID
    local id=$1 fn=t_$1 i
    [ -n "${ONLY:-}" ] && ! [[ $id =~ $ONLY ]] && return 0
    T=$(mktemp -d "$base/t.XXXXXX"); FAILS=()
    "$fn" </dev/null >/dev/null 2>&1 || true
    if [ ${#FAILS[@]} -eq 0 ]; then pass=$((pass+1)); echo "PASS $id"
    else fail=$((fail+1)); failed+=("$id"); echo "FAIL $id"; for i in "${FAILS[@]}"; do echo "     - $i"; done; fi
}
for n in $(seq 1 22); do run_one QV$n; done
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ "$fail" -eq 0 ]

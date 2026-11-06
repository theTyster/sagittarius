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
#   c3 textual (no bare id), fy16 options                       : QV23-QV24
#   T18 c4: project_conflict and project_kb_unclean items        : QV36-QV37
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
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID|CLAUDE_CODE_SESSION_ID|HUB_SESSION) unset "$v";; esac; done
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
    elif mode=="bareids":  # bareids FILE ID... : no id as a bare token outside span.ref (visible text, attrs but class and data-*)
        pat=re.compile(r"(?<![A-Za-z0-9_])(%s)(?![A-Za-z0-9_])"%"|".join(map(re.escape,a)))
        def inref(n):
            while n is not None:
                if n.tag=="span" and "ref" in n.classes(): return True
                n=n.parent
            return False
        def vis(n):   # own text pieces of n, unless n is hidden machinery
            return [] if n.tag in ("script","style") else n.txt
        for n in p.all:
            if inref(n): continue
            for t in vis(n):
                for m in pat.finditer(t): bad.append("bare id %s in text of <%s>: %r"%(m.group(1),n.tag,norm(t)[:120]))
            for k,v in n.attrs.items():
                if k=="class" or k.startswith("data-") or v is None: continue
                for m in pat.finditer(v): bad.append("bare id %s in attribute %s of <%s>"%(m.group(1),k,n.tag))
    elif mode=="options":  # options FILE ID SRC=TEXT... : the exact option list of the to_ask item ID, in order
        iid,*want=a
        hit=[n for st,n in items(p) if n.attrs.get("data-kind")=="to_ask" and n.attrs.get("data-id")==iid]
        if len(hit)!=1: bad.append("want one to_ask item %s, found %d"%(iid,len(hit)))
        else:
            ol=[k for k in hit[0].walk() if "options" in k.classes()]
            if len(ol)!=1: bad.append("item %s has %d options elements, want 1"%(iid,len(ol)))
            else:
                got=["%s=%s"%(k.attrs.get("data-source"),next((x.text() for x in k.walk() if "optiontext" in x.classes()),k.text())) for k in ol[0].walk() if k.tag=="li" and "option" in k.classes()]
                if got!=want: bad.append("options of %s: got %s, want %s"%(iid,got,want))
    elif mode=="effects":  # effects FILE ID TEXT=EFFECT... : each option li has that optiontext and an effect span with that text
        iid,*want=a
        hit=[n for st,n in items(p) if n.attrs.get("data-kind")=="to_ask" and n.attrs.get("data-id")==iid]
        if len(hit)!=1: bad.append("want one to_ask item %s, found %d"%(iid,len(hit)))
        else:
            lis=[k for k in hit[0].walk() if k.tag=="li" and "option" in k.classes()]
            for w in want:
                t,_,e=w.partition("=")
                m=[l for l in lis if any("optiontext" in k.classes() and k.text()==t for k in l.walk())]
                if len(m)!=1: bad.append("option %r: found %d li"%(t,len(m))); continue
                ef=[k for k in m[0].walk() if "effect" in k.classes()]
                if e=="": 
                    if ef: bad.append("option %r must have no effect element, has %r"%(t,[k.text() for k in ef]))
                elif not ef or not any(e in k.text() for k in ef): bad.append("option %r: effect lacks %r (has %r)"%(t,e,[k.text() for k in ef]))
    elif mode=="noeffects":  # noeffects FILE ID : the no-effects note is in the item and no li has an effect element
        iid=a[0]
        hit=[n for st,n in items(p) if n.attrs.get("data-kind")=="to_ask" and n.attrs.get("data-id")==iid]
        if len(hit)!=1: bad.append("want one to_ask item %s, found %d"%(iid,len(hit)))
        else:
            n=hit[0]
            if not any("no-effects" in k.classes() and "No option effects are recorded for this question." in k.text() for k in n.walk()): bad.append("item %s lacks the no-effects note"%iid)
            if any("effect" in k.classes() for k in n.walk() if k.tag=="li" or (k.parent and k.parent.tag=="li")): bad.append("item %s has an effect element in an option"%iid)
    elif mode=="kblabel":  # kblabel FILE STAMP TEXT : the section with that stamp has a kblabel with TEXT
        sec=[n for n in p.all if n.tag=="section" and "kb" in n.classes() and n.attrs.get("data-stamp")==a[0]]
        if len(sec)!=1: bad.append("no unique section for %s"%a[0])
        else:
            l=[k for k in sec[0].walk() if "kblabel" in k.classes()]
            if not l or not any(a[1] in k.text() for k in l): bad.append("section %s kblabel lacks %r (has %r)"%(a[0],a[1],[k.text() for k in l]))
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
check(k1, c1).
EOF
    mkdir -p "$1/runs"
    printf '%% orbit-kb run 1 check=k1 result=pass exit=0 time=2026-10-15T10:00:01Z cmd=true\n' > "$1/runs/1-k1.log"
    printf "attest(t1, test_result, k1, result(k1, 1, pass), script, '2026-10-15T10:00:01Z').\n" >> "$1/kb.pl"
}
ledger_json() { cat > "$1" <<'EOF'
[
 {"id":"A12","kind":"ask","title":"Which payment provider do we pick","status":"open","waits_on":"me","age_days":17},
 {"id":"A15","kind":"ask","title":"Approve the refund wording","status":"waiting","waits_on":"me","age_days":3},
 {"id":"A20","kind":"ask","title":"Vendor must send the tax form","status":"open","waits_on":"pat","age_days":40},
 {"id":"A07","kind":"ask","title":"Settled question about the logo","status":"done","waits_on":"me","age_days":90},
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
[{"id":"A99","kind":"ask","title":"Pick the release date","status":"open","waits_on":"me","age_days":400}]
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
    printf '[{"id":"A1","kind":"ask","title":"Ship <script>x</script> & go","status":"open","waits_on":"me","age_days":2}]\n' > "$T/l.json"
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

t_QV23() {  # c3, textual: no bare KB id anywhere outside the ref spans (two KBs, a ledger, a check)
    kb_a "$T/a"; kb_b "$T/b"; ledger_json "$T/asks.json"
    printf "question(q4, c2, 'Should the export include totals').\nattest(d2, divergence, c2, claim(c2), agent, '2026-10-15T10:00:02Z').\n" >> "$T/a/kb.pl"
    view --dir "$T/a" --dir "$T/b" --ledger "$T/asks.json" || return
    chk refs "$T/page.html" 8
    chk bareids "$T/page.html" q1 q2 q3 q4 c1 c2 k1 r1 r2 d1 d2
}
t_QV24() {  # fy16: the options are the default, the answer if any, and other; the page invents none
    kb_a "$T/a"
    printf "answer(q1, no, agent).\nanswer(q2, no, agent).\nquestion(q5, c1, 'Should the list show a total').\nquestion(q6, c1, 'Is the list printable').\nassumed(q6, yes).\n" >> "$T/a/kb.pl"
    view --dir "$T/a" || return
    chk options "$T/page.html" q1 default=yes answer=no other=other
    chk options "$T/page.html" q2 default=no other=other
    chk options "$T/page.html" q5 other=other
    chk options "$T/page.html" q6 default=yes other=other
    chk alltext "$T/page.html" "come from the KB's defaults"
}
# ---- review fixes: the owner of the ledger, option effects, labels, the no-claim text
t_QV25() {  # the owner is a person key: `me` by default; null is nobody, and is not shown
    kb_a "$T/a"; ledger_json "$T/asks.json"
    cat > "$T/n.json" <<'EOF'
[{"id":"A30","kind":"ask","title":"Nobody owns this ask","status":"open","waits_on":null,"age_days":9},
 {"id":"A31","kind":"ask","title":"Mine by key","status":"open","waits_on":"me","age_days":2},
 {"id":"A32","kind":"ask","title":"Pat decides","status":"open","waits_on":"pat","age_days":4}]
EOF
    view --dir "$T/a" --ledger "$T/n.json" || return
    chk askids "$T/page.html" -- A31
    chk alltext "$T/page.html" '!Nobody owns this ask' '!Pat decides'
}
t_QV26() {  # --owner KEY shows the asks that wait on that person
    kb_a "$T/a"
    cat > "$T/n.json" <<'EOF'
[{"id":"A31","kind":"ask","title":"Mine by key","status":"open","waits_on":"me","age_days":2},
 {"id":"A32","kind":"ask","title":"Pat decides","status":"open","waits_on":"pat","age_days":4},
 {"id":"A33","kind":"ask","title":"Pat decides later","status":"waiting","waits_on":"pat","age_days":6}]
EOF
    view --dir "$T/a" --ledger "$T/n.json" --owner pat || return
    chk askids "$T/page.html" -- A32 A33
    chk ask "$T/page.html" A32 'has:Pat decides' 'age:4 days'
}
t_QV27() {  # the export may carry the owner in a row; --owner overrides it
    kb_a "$T/a"
    cat > "$T/n.json" <<'EOF'
[{"id":"A41","kind":"ask","title":"For the boss","status":"open","waits_on":"boss","age_days":1,"owner":"boss"},
 {"id":"A42","kind":"ask","title":"For pat","status":"open","waits_on":"pat","age_days":1,"owner":"boss"}]
EOF
    view --dir "$T/a" --ledger "$T/n.json" || return
    chk askids "$T/page.html" -- A41
    view --dir "$T/a" --ledger "$T/n.json" --owner pat || return
    chk askids "$T/page.html" -- A42
}
t_QV28() {  # the real hubflow export: a hub seeded with another owner, asks to three people and to nobody
    command -v python3 >/dev/null || return
    local hf="$here/../../hubkit/hub/.claude/scripts/hubflow.py" H="$T/hub"
    [ -f "$hf" ] || { note "hubflow.py not found at $hf"; return; }
    mkdir -p "$H"
    printf '{"sessions":[{"name":"build","role":"build"}],"persons":[{"key":"boss","display":"Boss"},{"key":"pat","display":"Pat"}],"owner":"boss"}\n' > "$H/seed.json"
    export HUB_SESSION=build
    python3 "$hf" --hub "$H" init --seed "$H/seed.json" </dev/null >/dev/null 2>&1 || { note "hubflow init failed"; return; }
    python3 "$hf" --hub "$H" add ask --title "Pick the payment provider" --waits-on boss </dev/null >/dev/null 2>&1
    python3 "$hf" --hub "$H" add ask --title "Vendor sends the tax form" --waits-on pat --ref issue:5 </dev/null >/dev/null 2>&1
    python3 "$hf" --hub "$H" add ask --title "Unassigned ask" </dev/null >/dev/null 2>&1
    python3 "$hf" --hub "$H" add thread --title "A thread that waits on the boss" --waits-on boss </dev/null >/dev/null 2>&1
    python3 "$hf" --hub "$H" sql "SELECT id, kind, title, status, waits_on, age_days, COALESCE((SELECT value FROM meta WHERE key='owner_person'), (SELECT key FROM person WHERE key='me')) AS owner FROM v_open" --format json </dev/null > "$T/real.json" 2>"$T/hf.err"
    [ -s "$T/real.json" ] || { note "hubflow sql wrote nothing: $(snip "$(cat "$T/hf.err")")"; return; }
    kb_a "$T/a"; view --dir "$T/a" --ledger "$T/real.json" || return
    chk alltext "$T/page.html" 'Pick the payment provider' '!Vendor sends the tax form' '!Unassigned ask' '!A thread that waits on the boss'
    chk ask "$T/page.html" "$(python3 -c "import json,sys;print([r['id'] for r in json.load(open('$T/real.json')) if r['title']=='Pick the payment provider'][0])")" 'has:Pick the payment provider' 'age:0 days'
    view --dir "$T/a" --ledger "$T/real.json" --owner pat || return
    chk alltext "$T/page.html" 'Vendor sends the tax form' '!Pick the payment provider'
}
opt_kb() { kb_a "$1"; printf "option(q1, yes, 'The newest invoice is on top; older ones need a scroll').\noption(q1, no, 'The list keeps its date order').\noption(q1, 'by amount', 'Invoices sort by total, largest first').\n" >> "$1/kb.pl"; }
t_QV29() {  # each option shows its effect; an option fact adds an option the KB has not named otherwise
    opt_kb "$T/a"; echo "answer(q1, no, agent)." >> "$T/a/kb.pl"; view --dir "$T/a" || return
    chk options "$T/page.html" q1 'default=yes' 'answer=no' 'option=by amount' 'other=other'
    chk effects "$T/page.html" q1 'yes=The newest invoice is on top; older ones need a scroll' 'no=The list keeps its date order' 'by amount=Invoices sort by total, largest first' 'other='
}
t_QV30() {  # no option fact: the page says so, visibly, in the item; no effect element in an option
    kb_a "$T/a"; view --dir "$T/a" || return
    chk noeffects "$T/page.html" q1; chk noeffects "$T/page.html" q2
}
t_QV31() {  # a question with option facts for only some options: the others say that no effect is recorded
    kb_a "$T/a"; echo "option(q2, no, 'Paid invoices stay in the list')." >> "$T/a/kb.pl"; view --dir "$T/a" || return
    chk effects "$T/page.html" q2 'no=Paid invoices stay in the list'
    chk noeffects "$T/page.html" q1
    chk effects "$T/page.html" q2 'other='
}
t_QV32() {  # option/3 is a core fact: add accepts it, lint is clean, help core lists it, it changes no rule
    kb_a "$T/a"; okb --dir "$T/a" lint; local before=$out
    okb --dir "$T/a" add "option(q1, yes, 'Shows newest first')"; rc_is 0 "add option/3" || return
    okb --dir "$T/a" lint; rc_is 0 "lint after option/3"
    okb --dir "$T/a" add "option(zz, yes, 'x')"; rc_is 1 "option of a missing question"
    okb --dir "$T/a" query 'blocking(to_ask(X))' -n 0; err_has 'q1' "to_ask still holds"
    okb help core; err_has 'option\(' "help core lists option"
    okb --dir "$T/a" show all; err_has 'q1' "show works"
}
t_QV33() {  # each KB section names its KB: the first line of its first request, or its directory
    kb_a "$T/a"; kb_b "$T/b"; view --dir "$T/a" --dir "$T/b" || return
    chk kblabel "$T/page.html" "$(stamp_of "$T/a")" 'Billing must be less confusing for customers'
    chk kblabel "$T/page.html" "$(stamp_of "$T/b")" 'The mobile app must work offline'
    kb_new "$T/dirkb/proj_x" <<'EOF'
uses([build]).
claim(c1, preserve, 'Anything').
EOF
    view --dir "$T/dirkb/proj_x" || return
    chk kblabel "$T/page.html" "$(stamp_of "$T/dirkb/proj_x")" 'proj_x'
}
t_QV34() {  # the no-claim item: label and text are apart and do not repeat each other
    kb_new "$T/n" <<'EOF'
uses([build]).
request(r1, 'Nothing is claimed yet').
EOF
    view --dir "$T/n" || return
    chk item "$T/page.html" no_claim '' 'has:No current claim: Add a claim'
    chk alltext "$T/page.html" '!claim:No' '!No claim is current'
}

t_QV35() {  # the options note names option facts as a source and says once what "other" means
    opt_kb "$T/a"; view --dir "$T/a" || return
    chk alltext "$T/page.html" 'option facts' 'Other means an answer that is not listed' '!The page invents no options'
}

# ---- T18 c4: the blocking items of the project module (D23 P5, P8) have the text of show blocking
# pc_kbs DIR: a project KB DIR/proj where draft dA conflicts with a change of the tracker (p2 is
# newer than p1, and dA was staged after p1), and a spec KB DIR/spec that pins decision dec1.
pc_kbs() {
    local h d; h=$(printf 'x' | sha256sum | cut -d' ' -f1); d=$(printf '%s' 'Orders are sorted by number' | sha256sum | cut -d' ' -f1)
    kb_new "$1/proj" <<EOF
uses([project]).
request(r1, 'Project decisions').
decision(dec1, 'Orders are sorted by number').
pin(p1, tracker, 'tracker:ITEM-1', 'sha256:$h', '2026-10-01T09:00:00Z').
pin(p2, tracker, 'tracker:ITEM-1', 'sha256:$h', '2026-10-03T09:00:00Z').
concerns(dec1, p1).
draft(dA, p1, 'Sort orders by their number', '2026-10-02T09:00:00Z').
EOF
    kb_new "$1/spec" <<EOF
uses([build, project]).
request(r1, 'Keep orders sorted').
project_kb('../proj').
claim(c1, preserve, 'Orders keep their number').
cites(c1, 'Keep orders sorted').
pins(c1, project, dec1, 'sha256:$d').
EOF
}
# blocking_sentence KB KIND: the text after "- KIND[ ID]: " of the show blocking line of KIND.
blocking_sentence() { okb --dir "$1" show blocking; printf '%s\n' "$out" | grep -E "^- $2[ :]" | head -n1 | sed -E 's/^- [a-z_]+( [^ :]+)?: //'; }
t_QV36() {  # a project conflict shows its sentence and the draft text, as show blocking does
    pc_kbs "$T"
    local sen; sen=$(blocking_sentence "$T/spec" project_conflict)
    [ -n "$sen" ] || { note "setup: show blocking has no project_conflict line: $(snip "$out")"; return; }
    view --dir "$T/spec" || return
    chk item "$T/page.html" project_conflict dA "has:$sen" 'has:Sort orders by their number'
    chk alltext "$T/page.html" '!no text is recorded'
    chk refs "$T/page.html" 1
}
t_QV37() {  # a project KB that does not load clean: the page is written, and the item has its sentence
    pc_kbs "$T"; printf 'this is not (valid.\n' >> "$T/proj/kb.pl"
    local sen; sen=$(blocking_sentence "$T/spec" project_kb_unclean)
    [ -n "$sen" ] || { note "setup: show blocking has no project_kb_unclean line: $(snip "$out")"; return; }
    view --dir "$T/spec" || return
    chk item "$T/page.html" project_kb_unclean '' "has:$sen"
    chk alltext "$T/page.html" '!no text is recorded'
}

run_one() {  # run_one ID
    local id=$1 fn=t_$1 i
    [ -n "${ONLY:-}" ] && ! [[ $id =~ $ONLY ]] && return 0
    T=$(mktemp -d "$base/t.XXXXXX"); FAILS=()
    "$fn" </dev/null >/dev/null 2>&1 || true
    if [ ${#FAILS[@]} -eq 0 ]; then pass=$((pass+1)); echo "PASS $id"
    else fail=$((fail+1)); failed+=("$id"); echo "FAIL $id"; for i in "${FAILS[@]}"; do echo "     - $i"; done; fi
}
for n in $(seq 1 37); do run_one QV$n; done
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ "$fail" -eq 0 ]

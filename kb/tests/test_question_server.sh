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
# The Desk, lap 1 (hub spec KB questions-server, 2026-11-17):
#   c1 dark at every load, the page and report --html; no light theme, no toggle               : QS32
#   c2 sections collapse; open on load only with an item for Ty                                 : QS33
#   c3 Human action needed: only reserved actions (hubflow add ask --reserved)                  : QS34
# The Desk, laps 2-4:
#   c11 sessions with their inboxes; the Orphaned list                                        : QS35
#   c4 the context of each item                                                               : QS36
#   c5 diverge and new requirement                                                            : QS37
#   c7 c8 letters on disk at once, where each one is, loud with no live owner; c6 seen by hook : QS38
#   c8 q2 drafts on the server until Send                                                     : QS39
#   c9 answered in the session shows as answered                                              : QS40
#   c3 q3 the standing-rule actions of a spec KB (vote, demo)                                 : QS41
#   h2 one page for every hub                                                                 : QS42
# The Desk, round 2 (serve desk; hypothesis h3; claims c12-c21, and c1 c2 c5 c7 c8 c9 on the Desk):
#   c1 c2 dark; lanes and KBs collapse, open on load only with an item for Ty                 : QS43
#   c12 Your action: only reserved actions, each with the source (policy, or Ty's dated words) : QS44
#   c13 each item leads to its KB, hypothesis, premises, claims, checks; due date; no command  : QS45
#   c14 q7 who holds what; question -> KB -> project KB; Orphaned with fixes Ty sends          : QS46
#   c15 project KB items for Ty (a proposed fact, Ratify)                                     : QS47
#   c16 one Desk for every mindhole that joined, in one step; the service unit                : QS48
#   c18 q8 each check in words (fact, else script docstring), how it runs, its last run       : QS49
#   c19 the owner session as one badge in the heading                                         : QS50
#   c20 every send through the review; exact text; edits reach only that session             : QS51
#   c21 each item says where it comes from                                                    : QS52
#   c5 c8 diverge, requirement, the letter stored first                                       : QS53
#   c7 q9 q10 Draft and Sent, late and loud warnings; drafts in the Desk store                : QS54
#   c9 answered in the session shows as answered                                              : QS55
# Ty on the demo Desk, 2026-11-17 (signal s6):
#   c22 on load the rail is collapsed and one card is open; Your action cards collapse       : QS56
#   c23 sessions roll up by mindhole, one short line each                                    : QS57
#   c24 loud when no desk hook can deliver a letter (card and review)                        : QS58
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
    def __init__(s, tag, attrs, parent): s.tag=tag; s.attrs=dict(attrs); s.parent=parent; s.kids=[]; s.txt=[]; s.seq=[]
    def otext(s): return norm("".join(x if isinstance(x, str) else " " + x.otext() + " " for x in s.seq))  # in document order
    def classes(s): return (s.attrs.get("class") or "").split()
    def text(s): return norm("".join(s.txt) + " ".join(k.text() for k in s.kids))
    def walk(s):
        yield s
        for k in s.kids: yield from k.walk()
def norm(t): return re.sub(r"\s+", " ", t).strip()
class P(html.parser.HTMLParser):
    def __init__(s): super().__init__(convert_charrefs=True); s.root=N("#root",[],None); s.cur=s.root; s.all=[]
    def handle_starttag(s, tag, attrs):
        n=N(tag,attrs,s.cur); s.cur.kids.append(n); s.cur.seq.append(n); s.all.append(n)
        if tag not in VOID: s.cur=n
    def handle_startendtag(s, tag, attrs):
        n=N(tag,attrs,s.cur); s.cur.kids.append(n); s.cur.seq.append(n); s.all.append(n)
    def handle_endtag(s, tag):
        c=s.cur
        while c is not s.root and c.tag!=tag: c=c.parent
        if c is not s.root: s.cur=c.parent
    def handle_data(s, d): s.cur.txt.append(d); s.cur.seq.append(d)
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
    elif mode=="dark":       # dark FILE: the page is dark at every load (Desk c1): color-scheme dark, no light theme, every background literal dark
        import re as _re
        css="".join("".join(n.txt) for n in p.all if n.tag=="style")
        flat=_re.sub(r"\s+","",css)
        if "prefers-color-scheme" in css: bad.append("the CSS follows prefers-color-scheme (a light theme exists)")
        if "data-theme" in css or "theme-toggle" in raw: bad.append("the page has a theme toggle")
        if "color-scheme:dark" not in flat: bad.append("no color-scheme:dark")
        def lum(h):
            h=h.lstrip("#"); h="".join(c*2 for c in h) if len(h) in (3,4) else h
            r,g,b=(int(h[i:i+2],16)/255 for i in (0,2,4)); return 0.2126*r+0.7152*g+0.0722*b
        for m in _re.finditer(r"background(?:-color)?:\s*(#[0-9a-fA-F]{3,8})", css):
            if lum(m.group(1))>0.35: bad.append("a light background %s" % m.group(1))
        for m in _re.finditer(r"--[\w-]*bg[\w-]*:\s*(#[0-9a-fA-F]{3,8})", css):
            if lum(m.group(1))>0.35: bad.append("a light background token %s" % m.group(0))
        if not _re.search(r"(?:html|body|:root)[^{]*\{[^}]*background", css): bad.append("no explicit page background")
    elif mode=="fold":       # fold FILE LABEL open|closed: the KB section LABEL is a details element, open or closed on load (Desk c2)
        secs=kbsec(p, a[0])
        if len(secs)!=1: bad.append("want one KB section labeled %r, found %d" % (a[0], len(secs)))
        else:
            ds=[n for n in secs[0].walk() if n.tag=="details" and any(s.tag=="summary" and cls(s,"kblabel") for s in n.kids)]
            if len(ds)!=1: bad.append("KB section %r: no details whose summary holds its label" % a[0])
            elif ("open" in ds[0].attrs)!=(a[1]=="open"): bad.append("KB section %r is not %s on load" % (a[0], a[1]))
    elif mode=="gfold":      # gfold FILE LABEL open|closed: the project group LABEL is a details element, open or closed on load (Desk c2)
        gs=[s for s in p.all if s.tag=="section" and "project" in s.classes() and any(l.text()==a[0] for l in cls(s,"projectlabel"))]
        if len(gs)!=1: bad.append("want one project group %r, found %d" % (a[0], len(gs)))
        else:
            ds=[n for n in gs[0].kids if n.tag=="details"]
            if len(ds)!=1 or not any(s.tag=="summary" and cls(s,"projectlabel") for s in ds[0].kids): bad.append("group %r: no details whose summary holds its label" % a[0])
            elif ("open" in ds[0].attrs)!=(a[1]=="open"): bad.append("group %r is not %s on load" % (a[0], a[1]))
    elif mode=="lane":       # lane FILE HEADING ID...: the ledger section with heading HEADING lists exactly the asks ID (in order); none: no such section
        ss=[s for s in p.all if s.tag=="section" and "ledger" in s.classes() and any(h.tag=="h2" and h.text()==a[0] for h in s.walk())]
        got=[x.attrs.get("data-id") for s in ss for x in s.walk() if x.tag=="li" and "ask" in x.classes()]
        if a[1:]==["none"]:
            if ss: bad.append("a ledger section %r exists" % a[0])
        elif len(ss)!=1: bad.append("want one ledger section %r, found %d" % (a[0], len(ss)))
        elif got!=a[1:]: bad.append("section %r lists %r, want %r" % (a[0], got, a[1:]))
    elif mode=="sec":        # sec FILE HEADING T...: the section whose h2 heading is HEADING has each text T (!T: lacks it)
        ss=[]
        for h in p.all:
            if h.tag=="h2" and h.text()==a[0]:
                n=h.parent
                while n is not None and n.tag!="section": n=n.parent
                if n is not None: ss.append(n)
        if len(ss)!=1: bad.append("want one section with heading %r, found %d" % (a[0], len(ss)))
        else:
            t=ss[0].text()
            for x in a[1:]:
                if x.startswith("!"):
                    if x[1:] in t: bad.append("section %r has %r" % (a[0], x[1:]))
                elif x not in t: bad.append("section %r lacks %r" % (a[0], x))
    elif mode=="card":       # card FILE ID T...: the li card with data-id ID (an ask or a KB item) has each text T (!T: lacks it)
        cs=[n for n in p.all if n.tag=="li" and n.attrs.get("data-id")==a[0] and ({"ask","item","kbaction"} & set(n.classes()))]
        if len(cs)!=1: bad.append("want one card %s, found %d" % (a[0], len(cs)))
        else:
            t=cs[0].text()
            for x in a[1:]:
                if x.startswith("!"):
                    if x[1:] in t: bad.append("card %s has %r" % (a[0], x[1:]))
                elif x not in t: bad.append("card %s lacks %r" % (a[0], x))
    elif mode=="respond":    # respond FILE ID: the card ID has a form with intents answer, diverge, requirement and a textarea text
        cs=[n for n in p.all if n.tag=="li" and n.attrs.get("data-id")==a[0] and ({"ask","item","kbaction"} & set(n.classes()))]
        if len(cs)!=1: bad.append("want one card %s, found %d" % (a[0], len(cs)))
        else:
            fs=[n for n in cs[0].walk() if n.tag=="form"]
            ins=[n for f in fs for n in f.walk() if n.tag in ("input","textarea")]
            got=[n.attrs.get("value") for n in ins if n.attrs.get("name")=="intent"]
            if got!=["answer","diverge","requirement"]: bad.append("card %s intents %r" % (a[0], got))
            if not any(n.tag=="textarea" and n.attrs.get("name")=="text" for n in ins): bad.append("card %s has no textarea text" % a[0])
    elif mode=="draftkey":   # draftkey FILE ID: print the draft key of the form of card ID
        for n in p.all:
            if n.tag=="li" and n.attrs.get("data-id")==a[0]:
                for f in n.walk():
                    if f.tag=="form" and f.attrs.get("data-draft-key"): print(f.attrs["data-draft-key"]); sys.exit(0)
        sys.exit(1)
    elif mode=="textarea":   # textarea FILE ID TEXT: the textarea of card ID holds exactly TEXT ('' for empty)
        vals=[ "".join(t.txt).strip() for n in p.all if n.tag=="li" and n.attrs.get("data-id")==a[0] for t in n.walk() if t.tag=="textarea"]
        if vals!=[a[1]]: bad.append("card %s textarea %r, want %r" % (a[0], vals, a[1]))
    elif mode=="kbtext":     # kbtext FILE LABEL T...: the KB section LABEL has each text T (!T: lacks it)
        secs=kbsec(p, a[0])
        if len(secs)!=1: bad.append("want one KB section labeled %r, found %d" % (a[0], len(secs)))
        else:
            t=secs[0].text()
            for x in a[1:]:
                if x.startswith("!"):
                    if x[1:] in t: bad.append("KB section %r has %r" % (a[0], x[1:]))
                elif x not in t: bad.append("KB section %r lacks %r" % (a[0], x))
    elif mode=="hubs":       # hubs FILE LABEL...: the hub sections, in order, by label
        got=[l.text() for n in p.all if n.tag=="section" and "hub" in n.classes() for l in cls(n,"hublabel")]
        if got!=a: bad.append("hubs %r, want %r" % (got, a))
    elif mode=="hubval":     # hubval FILE ID: print the hub of the form of card ID
        for n in p.all:
            if n.tag=="li" and n.attrs.get("data-id")==a[0]:
                for f in n.walk():
                    if f.tag=="input" and f.attrs.get("name")=="hub": print(f.attrs.get("value","")); sys.exit(0)
        sys.exit(1)
    # ---- the Desk, round 2 (serve desk): cards are elements whose id is item-<mindhole>-<item>
    elif mode in ("dlane","dcard","dhead","dbadge","dform","dkey","dkb","dorph","dopen","dtoken","dforms","dsrc","ddue","dload"):
        def card(suf):
            cs=[x for x in p.all if x.attrs.get("id","").startswith("item-") and x.attrs.get("id","").endswith("-"+suf)]
            if len(cs)!=1: bad.append("want one card ending -%s, found %d (%s)" % (suf, len(cs), [x.attrs.get("id") for x in p.all if x.attrs.get("id","").startswith("item-")][:20]))
            return cs[0] if len(cs)==1 else None
        def has(n, ts, what):
            t=n.otext()
            for x in ts:
                if x.startswith("!"):
                    if x[1:] in t: bad.append("%s has %r" % (what, x[1:]))
                elif x not in t: bad.append("%s lacks %r (text: %s)" % (what, x, t[:600]))
        def head(c):
            hs=[x for x in c.walk() if "head" in x.classes()]
            return hs[0] if hs else None
        if mode=="dtoken":       # dtoken FILE: print the token of the page
            for n in p.all:
                if n.tag=="body": print(n.attrs.get("data-token","")); sys.exit(0)
            sys.exit(1)
        elif mode=="dlane":      # dlane FILE LANE ITEM...: lane-LANE holds a card ending -ITEM; !ITEM: none; none: no card at all
            ls=[x for x in p.all if x.attrs.get("id")=="lane-"+a[0]]
            if len(ls)!=1: bad.append("want one lane %s, found %d" % (a[0], len(ls)))
            else:
                ids=[x.attrs.get("id","") for x in ls[0].walk() if x.attrs.get("id","").startswith("item-")]
                for t in a[1:]:
                    if t=="none":
                        if ids: bad.append("lane %s holds %s" % (a[0], ids))
                    elif t.startswith("!"):
                        if any(i.endswith("-"+t[1:]) for i in ids): bad.append("lane %s holds %s" % (a[0], t[1:]))
                    elif not any(i.endswith("-"+t) for i in ids): bad.append("lane %s lacks %s (it holds %s)" % (a[0], t, ids))
        elif mode=="dload":      # dload FILE LANE ITEM: on load no rail part is open, exactly one card is open (ITEM, in lane-LANE), and only that lane is open
            rail=[x for x in p.all if x.tag=="details" and "open" in x.attrs and any(a2.tag=="aside" for a2 in [x.parent, x.parent and x.parent.parent, x.parent and x.parent.parent and x.parent.parent.parent] if a2 is not None) ]
            def inaside(n):
                while n is not None:
                    if n.tag=="aside": return True
                    n=n.parent
                return False
            ro=[x for x in p.all if x.tag=="details" and "open" in x.attrs and inaside(x)]
            if ro: bad.append("%d rail parts are open on load: %s" % (len(ro), [x.otext()[:40] for x in ro]))
            oc=[x for x in p.all if x.tag=="details" and "open" in x.attrs and x.attrs.get("id","").startswith("item-")]
            if len(oc)!=1 or not oc[0].attrs["id"].endswith("-"+a[1]): bad.append("open cards on load: %s, want one ending -%s" % ([x.attrs.get("id") for x in oc], a[1]))
            ol=[x.attrs.get("id") for x in p.all if x.tag=="details" and "open" in x.attrs and "lane" in x.classes()]
            if ol!=["lane-"+a[0]]: bad.append("open lanes on load: %s, want [lane-%s]" % (ol, a[0]))
            ok=[x for x in p.all if x.tag=="details" and "open" in x.attrs and "kbsec" in x.classes()]
            if ok: bad.append("a KB section is open on load")
        elif mode=="dopen":      # dopen FILE ID open|closed: the details element with id ID
            ds=[x for x in p.all if x.attrs.get("id")==a[0]]
            if len(ds)!=1 or ds[0].tag!="details": bad.append("want one details #%s, found %s" % (a[0], [x.tag for x in ds]))
            elif ("open" in ds[0].attrs) != (a[1]=="open"): bad.append("#%s is not %s on load" % (a[0], a[1]))
        elif mode=="dcard":      # dcard FILE ITEM T...: the card has each text T (!T: lacks it)
            c=card(a[0])
            if c is not None: has(c, a[1:], "card "+a[0])
        elif mode=="dhead":      # dhead FILE ITEM T...: the heading of the card (its summary row) has each text T
            c=card(a[0])
            if c is not None:
                h=head(c)
                if h is None: bad.append("card %s has no heading" % a[0])
                else: has(h, a[1:], "the heading of "+a[0])
        elif mode=="dbadge":     # dbadge FILE ITEM SESSION: the heading has exactly one session badge, with the text SESSION
            c=card(a[0])
            if c is not None:
                h=head(c); bs=[x for x in (h.walk() if h else []) if "badge" in x.classes() and "status" not in x.classes()]
                if [b.text() for b in bs]!=[a[1]]: bad.append("the heading of %s has session badges %s, want [%r]" % (a[0], [b.text() for b in bs], a[1]))
        elif mode=="dsrc":       # dsrc FILE ITEM T: the source line (.src) of the card has the text T
            c=card(a[0])
            if c is not None:
                ss=[x.otext() for x in c.walk() if "src" in x.classes()]
                if not ss or a[1] not in ss[0]: bad.append("the source line of %s is %r, want %r" % (a[0], ss[:1], a[1]))
        elif mode=="ddue":       # ddue FILE ITEM T: the .due block of the heading has the text T
            c=card(a[0])
            if c is not None:
                ds=[x.otext() for x in c.walk() if "due" in x.classes()]
                if not ds or a[1] not in ds[0]: bad.append("the due date of %s is %r, want %r" % (a[0], ds[:1], a[1]))
        elif mode=="dform":      # dform FILE ITEM: one form, POST /review, data-review, hidden token item key hub; intents; a textarea text; one submit button
            c=card(a[0])
            if c is not None:
                fs=[x for x in c.walk() if x.tag=="form" and "respond" in x.classes()]
                if len(fs)!=1: bad.append("card %s has %d response forms" % (a[0], len(fs)))
                else:
                    f=fs[0]; ins=[x for x in f.walk() if x.tag in ("input","textarea","button")]
                    if f.attrs.get("action")!="/review" or (f.attrs.get("method") or "").lower()!="post" or "data-review" not in f.attrs: bad.append("the form does not POST to /review with data-review: %s" % f.attrs)
                    hid={x.attrs.get("name") for x in ins if x.attrs.get("type")=="hidden"}
                    for k in ("token","item","key","hub"):
                        if k not in hid: bad.append("no hidden %s" % k)
                    its=[x.attrs.get("value") for x in ins if x.attrs.get("name")=="intent"]
                    if its!=["answer","diverge","requirement"]: bad.append("intents %s" % its)
                    if not any(x.tag=="textarea" and x.attrs.get("name")=="text" for x in ins): bad.append("no textarea text")
                    bts=[x for x in ins if x.tag=="button"]
                    if [b.text() for b in bts]!=["Review and send"]: bad.append("buttons %s, want only Review and send" % [b.text() for b in bts])
        elif mode=="dkey":       # dkey FILE ITEM: print the draft key of the card
            c=card(a[0])
            for x in (c.walk() if c else []):
                if x.tag=="input" and x.attrs.get("name")=="key": print(x.attrs.get("value","")); sys.exit(0)
            sys.exit(1)
        elif mode=="dforms":     # dforms FILE: every form posts to /review (c20): none to /answer, /send or /draft
            fs=[x.attrs.get("action") for x in p.all if x.tag=="form"]
            if not fs: bad.append("no form")
            for x in fs:
                if x!="/review": bad.append("a form posts to %s" % x)
        elif mode=="dkb":        # dkb FILE LABEL T...: the KB section (details.kbsec) titled LABEL has each text T
            ks=[x for x in p.all if "kbsec" in x.classes() and any(t.tag=="h3" and t.text()==a[0] for t in x.walk())]
            if len(ks)!=1: bad.append("want one KB section %r, found %d" % (a[0], len(ks)))
            else: has(ks[0], a[1:], "KB section "+a[0])
        elif mode=="dorph":      # dorph FILE WHAT T...: the Orphaned row whose first cell starts with WHAT has each text T
            ls=[x for x in p.all if x.attrs.get("id")=="lane-orphans"]
            rows=[r for r in (ls[0].walk() if ls else []) if r.tag=="tr" and [k for k in r.kids if k.tag=="td"] and a[0] in [k for k in r.kids if k.tag=="td"][0].otext()]
            if len(rows)!=1: bad.append("want one Orphaned row %r, found %d" % (a[0], len(rows)))
            else:
                has(rows[0], a[1:], "Orphaned row "+a[0])
                if not any(x.tag=="form" and x.attrs.get("action")=="/review" for x in rows[0].walk()): bad.append("the row %r has no fix that opens the review" % a[0])
    elif mode=="review":     # review FILE: print the letters of a review as JSON: [{to, head, text}], and the records
        out=[]
        for l in [x for x in p.all if "letter" in x.classes()]:
            ta=[x for x in l.walk() if x.tag=="textarea" and (x.attrs.get("name") or "").startswith("letter_")]
            if not ta: continue
            bs=[x.text() for x in l.walk() if "badge" in x.classes()]
            sel=[x for x in l.walk() if x.tag=="select"]
            to=bs[0] if bs else ([o.attrs.get("value") for o in sel[0].walk() if o.tag=="option" and "selected" in o.attrs] or [None])[0] if sel else None
            fx=[x for x in l.walk() if "fixed" in x.classes()]
            out.append({"to": to, "name": ta[0].attrs.get("name"), "head": "".join(fx[0].txt) if fx else None, "text": "".join(ta[0].txt)})
        rec=[x.text() for x in p.all if x.tag=="li" and x.parent is not None and "records" in x.parent.classes()]
        import json; print(json.dumps({"letters": out, "records": rec, "sends_to": [x.attrs.get("action") for x in p.all if x.tag=="form"]}))
        sys.exit(0)
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
# (#eval table). Rows: METHOD PATH HOST-OK TOKEN-OK ACTION. QS17 reads them from the #eval output
# (qs17_rows); this copy is the table when lake is missing, and must equal the output.
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
# qs17_rows: sets QS17_ROWS, the rows of the table (no subshell, so its note counts). With lake on PATH they come from the #eval output of the model
# itself (lake env lean, about 0.5 s; the project has no packages), so the copy above cannot drift
# from the model: a copy that differs is a failure. Without lake, the copy is the table. With lake, a
# model that does not compile is a failure too (review of K-A, finding 8): the copy is then used only
# to run the rest of the test. qs17_rows [DIR]: DIR is the Lean project (default: kb/proofs/question_server).
qs17_rows() {
    local copy lean d=${1:-$here/../proofs/question_server}
    copy=$(printf '%s' "$QS17_TABLE" | tr '|' '\n')
    if command -v lake >/dev/null 2>&1 && ! lean=$(cd "$d" && timeout 300 lake env lean QuestionServer.lean 2>&1); then
        note "lake env lean failed on $d/QuestionServer.lean, so the table of the model is not read: $(printf '%s' "$lean" | head -c 300 | tr '\n' '~')"
        QS17_ROWS=$copy
    elif command -v lake >/dev/null 2>&1; then
        lean=$(printf '%s\n' "$lean" | grep -oE '\(QuestionServer\.Method\.[a-z]+, QuestionServer\.Path\.[a-z]+, (true|false), (true|false), QuestionServer\.Action\.[A-Za-z]+\)' \
               | sed -E 's/QuestionServer\.[A-Za-z]+\.//g; s/[(),]//g; s/true/1/g; s/false/0/g')
        [ "$lean" = "$copy" ] || note "the copy QS17_TABLE differs from the #eval table of QuestionServer.lean: $(diff <(printf '%s\n' "$copy") <(printf '%s\n' "$lean") | head -n 4 | tr '\n' '~')"
        QS17_ROWS=$lean
    else
        QS17_ROWS=$copy
    fi
}
t_QS17() {  # every row of the model's table: the HTTP status of its action; only the answer row writes
    kb_a "$T/a"; srv --dir "$T/a" || return
    page_ok || return; local tok kb port=${URL##*:}; tok=$(token); kb=$(pg kbval "$T/page.html" "$L_A")
    local rows n=0 m p h t act want path hostarg tokarg
    qs17_rows; rows=$QS17_ROWS
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

t_QS31() {  # review of K-A (finding 8): with lake on PATH, a Lean model that does not compile is a failure, not the copied table
    command -v lake >/dev/null 2>&1 || { SKIPPED=1; return; }
    mkdir -p "$T/qs"; cp "$here/../proofs/question_server/"{lakefile.toml,lean-toolchain,lake-manifest.json,QuestionServer.lean} "$T/qs/"
    printf '\ntheorem qs31_broken : (1 : Nat) = 2 := rfl\n' >> "$T/qs/QuestionServer.lean"
    local before=${#FAILS[@]}
    qs17_rows "$T/qs"
    if [ "${#FAILS[@]}" -gt "$before" ]; then FAILS=("${FAILS[@]:0:$before}")
    else note "qs17_rows took the copied table while lake env lean failed on the model"; fi
    [ -n "$QS17_ROWS" ] || note "qs17_rows sets no rows"
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
    A=$(hf "$T/h" --session build add ask --title 'Should the list show the newest invoice first' --note 'The case, the options and the default, for the test.' --waits-on me --ref kb:billing/kb)
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
    kb_a "$T/b"; A2=$(hf "$T/h" --session build add ask --no-kb --title 'Should paid invoices be hidden by default' --note 'The case, the options and the default, for the test.' --waits-on me)
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
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which payment provider do we pick' --note 'The case, the options and the default, for the test.' --waits-on me)
    B=$(hf "$T/h" --session build add ask --no-kb --title 'Vendor must send the tax form' --note 'The case, the options and the default, for the test.' --waits-on alex --ref issue:12)
    kb_a "$T/a"; srv --dir "$T/a" --hub "$T/h" || return
    page_ok || return
    chk text "$T/page.html" 'Which payment provider do we pick' '!Vendor must send the tax form'
    chk askform "$T/page.html" "$A"
    chk askcmd "$T/page.html" "$A" "hubflow.py --by human close $A --reason done --note 'YOUR ANSWER' --session human"
    C=$(hf "$T/h" --session build add ask --no-kb --title 'Pick the launch date' --note 'The case, the options and the default, for the test.' --waits-on me)
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
    A=$(hf "$T/h" --session build add ask --no-kb --title 'How many retries' --note 'The case, the options and the default, for the test.' --waits-on me)
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
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Should the list show the newest invoice first' --note 'The case, the options and the default, for the test.' --waits-on me)
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
    A=$(hf "$T/h" --session build add ask --no-kb --title 'How many retries' --note 'The case, the options and the default, for the test.' --waits-on me)
    B=$(hf "$T/h" --session build add ask --no-kb --title 'Which build number' --note 'The case, the options and the default, for the test.' --waits-on me)
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

# ---- the Desk, lap 1 (hub spec KB questions-server; claims c1 c2 c3)
kb_quiet() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Quiet work for agents').
claim(c1, introduce, 'The export has a header row').
cites(c1, 'Quiet work for agents').
example(c1, 'The first line of the export names its columns.').
EOF
}
t_QS32() {  # Desk c1: the page, and the report card of report --html (q4), are dark at every load, with no light theme and no toggle
    kb_a "$T/a"; srv --dir "$T/a" || return; page_ok || return
    chk dark "$T/page.html"
    srv_stop
    okb --dir "$T/a" report --html "$T/card.html"; rc_is 0 "report --html"
    chk dark "$T/card.html"
}
t_QS33() {  # Desk c2: each section collapses; on load a section is open only when it holds an item for Ty
    kb_a "$T/r/a"; kb_quiet "$T/r/quiet"
    srv --root "$T/r" || return; page_ok || return
    chk fold "$T/page.html" 'Billing must be less confusing for customers' open
    chk fold "$T/page.html" 'Quiet work for agents' closed
    chk gfold "$T/page.html" 'no project' open
    srv_stop
    rm -rf "$T/r/a"; srv --root "$T/r" || return; page_ok || return
    chk gfold "$T/page.html" 'no project' closed
}
t_QS34() {  # Desk c3: "Human action needed" lists only actions Ty reserved (add ask --no-kb --reserved); a plain question is listed apart
    mkhub "$T/h"; local A B C
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Push the hub to the remote' --note 'The case, the options and the default, for the test.' --waits-on me --reserved 'Ty, 2026-11-17: push only when I say so')
    B=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    C=$(hf "$T/h" --session build add ask --no-kb --title 'Vendor must send the tax form' --note 'The case, the options and the default, for the test.' --waits-on alex --reserved 'Alex, 2026-11-17: alex signs it')
    kb_a "$T/a"; srv --dir "$T/a" --hub "$T/h" || return; page_ok || return
    chk lane "$T/page.html" 'Human action needed' "$A"
    chk lane "$T/page.html" 'Questions for you' "$B"
    chk lane "$T/page.html" 'Asks that wait on you' none
    chk text "$T/page.html" 'push only when I say so' '!Vendor must send the tax form'
    chk askform "$T/page.html" "$A"
    hf "$T/h" --session build set "$B" --reserved 'Ty, 2026-11-17: I pick ports myself' >/dev/null
    hf "$T/h" --session build set "$A" --reserved none >/dev/null
    page_ok || return
    chk lane "$T/page.html" 'Human action needed' "$B"
    chk lane "$T/page.html" 'Questions for you' "$A"
    srv_stop
}

# ---- the Desk, laps 2-4 (hub spec KB questions-server; claims c4 c5 c6 c7 c8 c9 c11, q3)
mkdesk() { mkhub "$1"; cp "$REPO/hubkit/hub/.claude/scripts/desk.py" "$1/.claude/scripts/" 2>/dev/null || note "setup: no desk.py"; }
kb_ctx() { kb_new "$1" <<'EOF'
uses([discovery, build]).
request(r1, 'Exports must keep their header row').
hypothesis(h1, defect, 'Every export starts with a header row that names its columns.').
claim(c1, introduce, 'The export has a header row').
cites(c1, 'Exports must keep their header row').
example(c1, 'The orders export of 2026-11-01 starts with id,date,total.').
question(qa, c1, 'Should the header use the column labels of the screen').
assumed(qa, no).
option(qa, yes, 'The header shows Order date, as on the screen').
option(qa, no, 'The header shows the field names, as the API does').
finding(f1, surprise('The export of 2026-11-01 has no header row'), system).
raised_by(qa, f1).
question(qb, c1, 'Is a byte order mark allowed').
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
EOF
}
# hookrun HUB SESSION: run the desk hook as a UserPromptSubmit of SESSION; the output in $T/hook.out
hookrun() { printf '{"hook_event_name":"UserPromptSubmit","session_id":"s-test","cwd":"%s","prompt":"go on"}' "$1" \
      | ( cd "$1" && HUB_SESSION=$2 python3 .claude/scripts/desk.py hook ) > "$T/hook.out" 2>"$T/hook.err"; }
t_QS35() {  # Desk c11: each session with its inbox; the Orphaned list names each kind of orphan
    mkdesk "$T/h"; local H TH U
    H=$(hf "$T/h" --session discovery handoff --to build --title 'Build the export')
    TH=$(hf "$T/h" --session discovery add thread --title 'Export research')
    U=$(hf "$T/h" --session discovery add thread --title 'Nobody holds this one' --owner none)
    kb_project "$T/h/pk" 'Export project'
    kb_spec "$T/h/specs/loose" 'Loose rules' ''
    kb_spec "$T/h/specs/bound" 'Bound rules' '../../pk'
    kb_spec "$T/h/specs/held" 'Held rules' '../../pk'
    hf "$T/h" --session discovery add thread --title 'Hold the held rules' --ref kb:held >/dev/null
    srv --hub "$T/h" || return; page_ok || return
    chk sec "$T/page.html" 'Sessions' 'discovery' "$TH" 'Export research' 'build' "$H" 'not accepted' 'review'
    chk sec "$T/page.html" 'Orphaned' 'specs/loose' 'names no project KB' 'specs/bound' 'no open ledger item points to it' \
        "$U" 'Nobody holds this one' 'no live session owns it' "$H" 'nobody accepted it' '!specs/held'
}
t_QS36() {  # Desk c4: each item carries its context: case, options and effects, default, why now, what waits on it, where the work stands
    mkdesk "$T/h"; local TH A
    kb_ctx "$T/h/specs/ctx"
    TH=$(hf "$T/h" --session discovery add thread --title 'Header row research' --ref kb:ctx)
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    hf "$T/h" --session build note "$A" 'Case: 8737 is taken by the old proxy. Options: 8738 (free) or 8800. Default 8738.' >/dev/null
    srv --hub "$T/h" || return; page_ok || return
    chk card "$T/page.html" qa 'Should the header use the column labels of the screen' 'The orders export of 2026-11-01 starts with id,date,total' \
        'The header shows Order date, as on the screen' 'Default' 'Why now' 'The export of 2026-11-01 has no header row' \
        'What waits on it' "$TH" 'discovery' '!Missing context'
    chk card "$T/page.html" qb 'Missing context' 'no default' 'why it is asked now'
    chk kbtext "$T/page.html" 'Exports must keep their header row' 'Where the work stands' 'Every export starts with a header row' 'discovery'
    chk card "$T/page.html" "$A" '8737 is taken by the old proxy' 'build' '!Missing context'
}
t_QS37() {  # Desk c5: free space to diverge or add a requirement; a divergence is kept in his words and leaves the item open; a requirement goes to intake
    mkdesk "$T/h"; local A
    kb_ctx "$T/h/specs/div"
    hf "$T/h" --session discovery add thread --title 'Header row research' --ref kb:div >/dev/null
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    srv --hub "$T/h" || return; page_ok || return
    chk respond "$T/page.html" qa; chk respond "$T/page.html" "$A"
    local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" 'Exports must keep their header row')
    post /answer "token=$tok" "kb=$kb" q=qa intent=diverge 'text=That is not what I meant: the scope is one page'; code_is 303 "diverge on a KB question"
    grep -Eq "^signal\([a-z0-9]+, divergence, human, '.*the scope is one page" "$T/h/specs/div/kb.pl" || note "the divergence is not a human signal in his words"
    grep -Eq "^note\(c1, '.*the scope is one page" "$T/h/specs/div/kb.pl" || note "the divergence is not a note on the claim c1"
    okb --dir "$T/h/specs/div" lint; rc_is 0 "the KB is clean after the divergence"
    has_goal "$T/h/specs/div" "to_ask(qa)" "the question stays open"
    post /answer "token=$tok" "ask=$A" intent=diverge 'text=Not a port question: run it as a service'; code_is 303 "diverge on an ask"
    askjson "$T/h" "$A" "d['item']['status']=='open' and any(e['verb']=='note' and e['by']=='human' and 'run it as a service' in (e['note'] or '') for e in d['events'])"
    post /answer "token=$tok" "ask=$A" intent=requirement 'text=Also show the port in the page footer'; code_is 303 "a new requirement from an ask"
    post /answer "token=$tok" "kb=$kb" q=qa intent=requirement 'text=Exports must also carry a footer row'; code_is 303 "a new requirement from a KB question"
    hf "$T/h" view --format json > "$T/view.json"
    python3 -I -c 'import json, sys
rows = json.load(open(sys.argv[1]))
rows = rows if isinstance(rows, list) else rows.get("rows", [])
a = [r for r in rows if "page footer" in r["title"] and r.get("owner_session") == "review"]
b = [r for r in rows if "footer row" in r["title"] and r.get("owner_session") == "review" and "kb:div" in (r.get("refs") or "")]
sys.exit(0 if a and b else 1)' "$T/view.json" || note "intake: no review thread for each requirement: $(snip "$(cat "$T/view.json")")"
    askjson "$T/h" "$A" "d['item']['status']=='open'"
}
t_QS38() {  # Desk c7 and c8 (c6 seen): each response is on disk at once and shows where it is; loud when no live session holds the item
    mkdesk "$T/h"; local A B
    kb_ctx "$T/h/specs/lone"
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    B=$(hf "$T/h" --session build add ask --no-kb --title 'Which name for the service' --note 'The case, the options and the default, for the test.' --waits-on me)
    srv --hub "$T/h" || return; page_ok || return
    chk card "$T/page.html" qa 'No live session holds this item'
    chk card "$T/page.html" "$A" '!No live session holds this item'
    local tok kb; tok=$(token); kb=$(pg kbval "$T/page.html" 'Exports must keep their header row')
    post /answer "token=$tok" "ask=$A" 'text=Use port 8800'; code_is 303 "answer an ask"
    grep -q 'Use port 8800' "$T/h/flow/desk/letters.jsonl" 2>/dev/null || note "the answer is not in flow/desk/letters.jsonl"
    post /answer "token=$tok" "ask=$B" intent=diverge 'text=Not what I meant: no service at all'; code_is 303 "diverge on an ask"
    post /answer "token=$tok" "kb=$kb" q=qa choice=yes 'text=as on the screen'; code_is 303 "answer a KB question that no session holds"
    page_ok || return
    chk sec "$T/page.html" 'Responses' 'Use port 8800' 'Applied' 'Not what I meant: no service at all' 'Sent' '!Seen by build' 'No live session holds this item'
    hookrun "$T/h" build
    grep -q 'no service at all' "$T/hook.out" || note "the owner was not told: $(snip "$(cat "$T/hook.out" "$T/hook.err")")"
    page_ok || return
    chk sec "$T/page.html" 'Responses' 'Seen by build'
}
t_QS39() {  # Desk c8 and q2: a draft is kept on the server until Send, survives a reload, and never reaches a session
    mkdesk "$T/h"; local A key
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    srv --hub "$T/h" || return; page_ok || return
    local tok hub; tok=$(token); key=$(pg draftkey "$T/page.html" "$A"); hub=$(pg hubval "$T/page.html" "$A")
    [ -n "$key" ] || { note "the form of $A has no draft key"; return; }
    post /draft "token=$tok" "hub=$hub" "key=$key" 'text=half an answer' intent=answer
    [ "$CODE" = 204 ] || [ "$CODE" = 200 ] || note "POST /draft: HTTP $CODE"
    page_ok || return; chk textarea "$T/page.html" "$A" 'half an answer'
    hookrun "$T/h" build
    ! grep -q 'half an answer' "$T/hook.out" || note "a draft reached the session"
    post /draft "hub=$hub" "key=$key" 'text=no token'; code_is 403 "a draft with no token"
    post /answer "token=$tok" "hub=$hub" "ask=$A" "draft=$key" 'text=Use port 8800'; code_is 303 "send"
    python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); d=d.get("drafts", d); sys.exit(1 if sys.argv[2] in d else 0)' "$DESK_STATE/drafts.json" "$key" \
      || note "the draft is still kept after Send"
}
t_QS40() {  # Desk c9: an answer given in the session itself shows as answered on the page
    mkdesk "$T/h"; local A
    kb_ctx "$T/h/specs/s9"
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    wr discovery --dir "$T/h/specs/s9" add 'answer(qa, yes, human)'; rc_is 0 "the session records Ty's answer"
    hf "$T/h" --session build close "$A" --reason done --note 'Ty said 8800 in the pane' >/dev/null
    srv --hub "$T/h" || return; page_ok || return
    chk answered "$T/page.html" 'Exports must keep their header row' qa yes
    chk sec "$T/page.html" 'Questions for you' 'Answered in the last 7 days' "$A" 'Ty said 8800 in the pane' 'build'
}
t_QS41() {  # Desk c3 (q3): standing-rule actions of a spec KB are human actions: a vote that waits on Ty, a demo to approve
    mkdesk "$T/h"
    mkdir -p "$T/h/specs/disc"; cp "$here/fixtures/discovery-a/kb.pl" "$T/h/specs/disc/kb.pl"
    mkdir -p "$T/h/specs/look"; printf 'png' > "$T/h/specs/look/shot.png"
    local d; d=$(sha256sum "$T/h/specs/look/shot.png" | cut -d' ' -f1)
    kb_new "$T/h/specs/look" <<EOF
uses([build]).
request(r1, 'The pane must look calm').
claim(c1, introduce, 'The pane uses three colors at most').
cites(c1, 'The pane must look calm').
example(c1, 'The idle pane shows grey, green and amber only.').
visual(c1).
subject(shot, 'shot.png', 'sha256:$d').
demo(shot, c1).
EOF
    srv --hub "$T/h" || return; page_ok || return
    chk sec "$T/page.html" 'Human action needed' 'Vote' 'A customer used two discount codes' 'Approve the demo' 'shot.png'
    chk fold "$T/page.html" 'The pane must look calm' open
}
t_QS42() {  # Desk h2: one page for every hub on the machine; an ask is answered in its own hub
    mkdesk "$T/h1"; mkdesk "$T/h2"; local A B
    A=$(hf "$T/h1" --session build add ask --no-kb --title 'First hub question' --note 'The case, the options and the default, for the test.' --waits-on me)
    hf "$T/h2" --session build add ask --no-kb --title 'A first ask of the second hub' --note 'The case, the options and the default, for the test.' --waits-on me >/dev/null
    B=$(hf "$T/h2" --session build add ask --no-kb --title 'Second hub question' --note 'The case, the options and the default, for the test.' --waits-on me)
    [ "$A" != "$B" ] || note "setup: the two asks have one id"
    srv --hub "$T/h1" --hub "$T/h2" || return; page_ok || return
    chk hubs "$T/page.html" h1 h2
    local tok hub; tok=$(token); hub=$(pg hubval "$T/page.html" "$B")
    post /answer "token=$tok" "hub=$hub" "ask=$B" 'text=Second answer'; code_is 303 "answer in the second hub"
    askjson "$T/h2" "$B" "d['item']['status']=='done'"
    askjson "$T/h1" "$A" "d['item']['status']=='open'"
}

# ================================================================ the Desk, round 2 (serve desk)
# hub spec KB questions-server, hypothesis h3, claims c12 to c21 (and c1 c2 c5 c7 c8 c9 on the Desk)
srvd() {  # srvd ARGS...: start `serve desk --port 0 ARGS` in $T, with the Desk store in $DESK_STATE; sets URL, SPID
    ( cd "$T" && XDG_CACHE_HOME="$T/.cache" exec timeout "$TMO" "$OKB" serve desk --port 0 "$@" ) >"$T/.srv.out" 2>"$T/.srv.err" </dev/null &
    SPID=$!; URL=""
    local i; for i in $(seq 1 200); do
        URL=$(grep -oE 'http://127\.0\.0\.1:[0-9]+' "$T/.srv.out" 2>/dev/null | head -n1)
        [ -n "$URL" ] && return 0
        kill -0 "$SPID" 2>/dev/null || break
        sleep 0.05
    done
    note "the Desk did not start (stdout: $(snip "$(cat "$T/.srv.out" 2>/dev/null)") | stderr: $(snip "$(cat "$T/.srv.err" 2>/dev/null)"))"; return 1
}
dpy() { local H=$1; shift; ( cd "$H" && python3 -I .claude/scripts/desk.py --hub "$H" "$@" ) 2>&1; }
# review FIELD=VALUE...: POST /review as the page script does; the review in $T/review.html, its letters as JSON in $T/review.json
review() { local a=() f; for f in "$@"; do a+=(--data-urlencode "$f"); done
    CODE=$(curl -s -o "$T/review.html" -w '%{http_code}' --max-time 30 -H 'X-Desk-Fragment: 1' "${a[@]}" "$URL/review" 2>/dev/null)
    pg review "$T/review.html" > "$T/review.json" 2>/dev/null; }
rj() { python3 -I -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if ($1) else 1)" "$T/review.json" || note "review: not ($1): $(snip "$(cat "$T/review.json")")"; }
# a KB with what a card rests on: a hypothesis with a premise, claims, checks in words, from a script, by a command only
kb_rests() { mkdir -p "$1/checks"; cat > "$1/checks/k_header.py" <<'EOF'
"""The orders export starts with a header row that names its columns."""
import sys; sys.exit(0)
EOF
    kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Exports must keep their header row').
hypothesis(h1, defect, 'Every export starts with a header row that names its columns.').
premise(p1, h1, 'The exports are written by one writer.').
claim(c1, introduce, 'The export has a header row').
example(c1, 'The orders export of 2026-11-01 starts with id,date,total.').
claim(c2, preserve, 'The rows keep their order').
check(k1, c1).
check(k2, c1).
check(k3, c1).
check(k4, c2).
checks_that(k1, 'the orders export of 2026-11-01 starts with id,date,total').
question(qa, c1, 'Should the header use the column labels of the screen').
assumed(qa, no).
option(qa, yes, 'The header shows Order date, as on the screen').
option(qa, no, 'The header shows the field names, as the API does').
question(qb, c2, 'May the rows be sorted by date').
EOF
    wr build --dir "$1" run k1 -- true; wr build --dir "$1" run k2 -- python3 checks/k_header.py; wr build --dir "$1" run k3 -- sh -c 'exit 1'
    wr build --dir "$1" release
}
# desk_hub H: a mindhole with sessions, a spec KB, a project KB, and asks
desk_hub() { mkdesk "$1"; kb_rests "$1/specs/exp"; kb_project "$1/project-kb" 'Export project'; }

t_QS43() {  # Desk c1 on serve desk: dark at every load, no error banner; lanes and KBs collapse (c2 is superseded by c22: QS56)
    desk_hub "$T/h"; local A
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    srvd --hub "$T/h" || return; page_ok || return
    chk dark "$T/page.html"
    chk dopen "$T/page.html" lane-orphans closed
    chk dopen "$T/page.html" lane-kbs closed
    chk raw "$T/page.html" '!prefers-color-scheme: light' '!data-theme'
    chk raw "$T/page.html" '!class="banner error"'      # the first page of a run reads each mindhole too
}
t_QS44() {  # Desk c12: Your action lists only reserved actions, each with the source of the reservation: a policy by name and rule, or Ty's words with their date
    desk_hub "$T/h"; local A B C
    A=$(hf "$T/h" --session process add ask --no-kb --title 'Waive the c3 proof, or order a Lean proof' --note 'The case, the options and the default, for the test.' --waits-on me --reserved 'Sagittarius Policy: Only the human may waive a proof.')
    B=$(hf "$T/h" --session build add ask --no-kb --title 'Push the hub to the remote' --note 'The case, the options and the default, for the test.' --waits-on me --reserved 'Ty, 2026-11-12: push only when I say so')
    C=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    srvd --hub "$T/h" || return; page_ok || return
    chk dlane "$T/page.html" action "ask-$A" "ask-$B" "!ask-$C"
    chk dlane "$T/page.html" questions "ask-$C" "!ask-$A"
    chk dcard "$T/page.html" "ask-$A" 'Sagittarius Policy: Only the human may waive a proof.' '!Ty: only I' '!Source not named'
    chk dcard "$T/page.html" "ask-$B" 'Ty, 12 Nov: “push only when I say so”'
    hf "$T/h" --session build add ask --no-kb --title 'Bad source' --note 'The case, the options and the default, for the test.' --waits-on me --reserved 'Ty: only I waive a proof' >/dev/null && note "hubflow took a reservation with no named source"
}
t_QS45() {  # Desk c13: each item leads to its KB, hypothesis, premises, claims and checks; a due date, not an age; no shell command; each blocker once
    desk_hub "$T/h"; local A B
    mkdir -p "$T/out"; kb_rests "$T/out/kb-install-ux"
    A=$(hf "$T/h" --session process add ask --title 'Waive the c1 proof, or order a Lean proof' --note 'The case, the options and the default, for the test.' --waits-on me --ref "kb:$T/out/kb-install-ux" --due 2026-12-11)
    B=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    srvd --hub "$T/h" || return; page_ok || return
    chk dcard "$T/page.html" "ask-$A" 'The KB install-ux' 'Every export starts with a header row' 'The exports are written by one writer.' \
        'The export has a header row' 'k1' 'k2' 'k3' '!The rows keep their order'
    chk raw "$T/page.html" "href=\"#kb-"
    chk ddue "$T/page.html" "ask-$A" 'Due 11 Dec'
    chk ddue "$T/page.html" "ask-$B" 'Due '
    chk dhead "$T/page.html" "ask-$B" '!days'
    chk text "$T/page.html" '!hubflow.py' '!--by human close' '!python3 .claude'
    chk dkb "$T/page.html" 'exp' 'Every export starts with a header row' 'The rows keep their order'
    local n; n=$(grep -o 'Claim not fulfilled\|Blocks:' "$T/page.html" | wc -l); [ "$n" = 0 ] || note "a blocker is listed twice ($n old-style lines)"
}
t_QS46() {  # Desk c14 (q7): who holds what; each question's KB; spec KB -> project KB -> repos; Orphaned with a fix Ty can send
    desk_hub "$T/h"; local H1 H2 H3 A
    kb_spec "$T/h/specs/bound" 'Bound rules' '../../project-kb'
    H1=$(hf "$T/h" --session discovery handoff --to build --title 'Build the export' --ref kb:exp)
    hf "$T/h" --session build accept "$H1" >/dev/null
    H2=$(hf "$T/h" --session build handoff --to review --title 'Verify the export' --ref kb:exp)
    hf "$T/h" --session review accept "$H2" >/dev/null
    H3=$(hf "$T/h" --session discovery handoff --to build --title 'Nobody took this' --ref kb:bound)
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    hf "$T/h" --session build add ask --title 'An old ask' --note 'The case, the options and the default, for the test.' --waits-on me --no-kb >/dev/null
    srvd --hub "$T/h" || return; page_ok || return
    chk raw "$T/page.html" 'Writes <b>exp</b>' 'Spec KBs, not linked' 'Spec KBs, linked to the project KB'
    chk dsrc "$T/page.html" qa 'Question qa in the KB exp'
    chk dorph "$T/page.html" 'spec KBs' 'exp' 'Linked to no project KB'
    chk dorph "$T/page.html" 'old handoffs' "$H1" 'only you can close them'
    chk dorph "$T/page.html" '1 handoffs' "$H3" 'nobody accepted'
    local tok; tok=$(pg dtoken "$T/page.html")
    review "token=$tok" "hub=$T/h" "item=fix:stale:$T/h"; code_is 200 "the review of the old handoffs"
    rj "any('$H1' in r for r in d['records']) and d['letters'] and d['letters'][0]['to']=='build'"
    post /send "token=$tok" "hub=$T/h" "item=fix:stale:$T/h" "letter_0=Closed $H1: H2 holds the KB. A line from Ty." to_0=build; code_is 303 "send the close"
    askjson "$T/h" "$H1" "d['item']['status']=='dropped' and any(e['by']=='human' for e in d['events'] if e['verb']=='closed')"
    grep -q 'A line from Ty' "$T/h/flow/desk/letters.jsonl" || note "the notice to build is not stored"
    wr discovery --dir "$T/h/specs/exp" add "note(c1, 'discovery writes now')"; rc_is 0 "discovery writes exp"
    page_ok || return
    chk dkb "$T/page.html" 'exp' 'holds the writer lock' 'discovery' '!took the newest handoff'   # q7: the writer holds the KB
}
t_QS47() {  # Desk c15: what waits on Ty in a project KB: a fact an agent proposed, with Ratify, until he ratifies it
    desk_hub "$T/h"
    wr process --dir "$T/h/project-kb" add "decision(d1, 'Every export has a header row')" "decided_by(d1, agent, '2026-11-01T00:00:00Z')"; rc_is 0 "propose d1" || return
    wr process --dir "$T/h/project-kb" release
    srvd --hub "$T/h" || return; page_ok || return
    chk text "$T/page.html" 'A fact that an agent proposed' 'Every export has a header row' 'Ratify'
    chk dopen "$T/page.html" lane-project closed     # c22 (supersedes c2): one card is open on load, not a lane of rows
    local tok; tok=$(pg dtoken "$T/page.html")
    review "token=$tok" "hub=$T/h" "item=proj:proposed:$T/h/project-kb#d1"; code_is 200 "the review of Ratify"
    rj "any('ratified_by(d1' in r for r in d['records'])"
    post /send "token=$tok" "hub=$T/h" "item=proj:proposed:$T/h/project-kb#d1" "letter_0=Ty ratified d1." to_0=process; code_is 303 "ratify"
    has_goal "$T/h/project-kb" 'ratified_by(d1, _, _)'
    page_ok || return; chk text "$T/page.html" '!A fact that an agent proposed'
}
t_QS48() {  # Desk c16: one Desk at one address serves every mindhole that joined it in one step; a mindhole with no ledger is named
    desk_hub "$T/h1"; desk_hub "$T/h2"; local A B
    A=$(hf "$T/h1" --session build add ask --no-kb --title 'First mindhole asks' --note 'The case, the options and the default, for the test.' --waits-on me)
    B=$(hf "$T/h2" --session build add ask --no-kb --title 'Second mindhole asks' --note 'The case, the options and the default, for the test.' --waits-on me)
    dpy "$T/h1" join --name one >/dev/null || note "join one failed"
    srvd || return; page_ok || return
    chk text "$T/page.html" 'First mindhole asks' '!Second mindhole asks'
    dpy "$T/h2" join --name two >/dev/null || note "join two failed"
    page_ok || return                       # the same server, no restart: the second mindhole joined in one step
    chk text "$T/page.html" 'First mindhole asks' 'Second mindhole asks' 'one' 'two'
    local tok; tok=$(pg dtoken "$T/page.html")
    post /send "token=$tok" "hub=$T/h2" "item=ask:$B" 'text=Yes' 'letter_0=Ty answers: yes' to_0=build; code_is 303 "answer in the second mindhole"
    askjson "$T/h2" "$B" "d['item']['status']=='done'"
    askjson "$T/h1" "$A" "d['item']['status']=='open'"
    mv "$T/h1/flow" "$T/h1/flow.gone"; page_ok || return
    chk text "$T/page.html" 'one joined the Desk' 'has no ledger now'
    dpy "$T/h2" service --orbit-kb "$OKB" | grep -q "ExecStart=.*serve desk --port 8737" || note "the service unit does not run serve desk"
}
t_QS49() {  # Desk c18 (q8): each check says in words what it checks (a KB fact, else its script's docstring), how it runs, and its last run
    desk_hub "$T/h"
    srvd --hub "$T/h" || return; page_ok || return
    chk dkb "$T/page.html" 'exp' 'the orders export of 2026-11-01 starts with id,date,total' \
        'The orders export starts with a header row that names its columns. (from its script)' 'Runs python3 k_header.py' \
        'Nobody recorded what this check does.' 'Last run' 'It never ran.'
    chk dorph "$T/page.html" 'checks' 'exp k3' 'exp k4' '!exp k1'
    wr build --dir "$T/h/specs/exp" lint; case "$out$err" in *W12*k3*) ;; *) note "lint does not warn W12 for k3: $(snip "$out$err")";; esac
}
t_QS50() {  # Desk c19: each item shows its owner session in the heading, as one badge with no "to"
    desk_hub "$T/h"; local A B H
    A=$(hf "$T/h" --session process add ask --no-kb --title 'Asked by process' --note 'The case, the options and the default, for the test.' --waits-on me)
    B=$(hf "$T/h" --session review add ask --no-kb --title 'Asked by review' --note 'The case, the options and the default, for the test.' --waits-on me --owner review)
    H=$(hf "$T/h" --session build handoff --to discovery --title 'Discovery holds exp' --ref kb:exp); hf "$T/h" --session discovery accept "$H" >/dev/null
    srvd --hub "$T/h" || return; page_ok || return
    chk dbadge "$T/page.html" "ask-$A" process
    chk dbadge "$T/page.html" "ask-$B" review
    chk dbadge "$T/page.html" qb discovery
    chk text "$T/page.html" '!To process' '!to discovery'
}
t_QS51() {  # Desk c20: nothing reaches a session that Ty did not see: every send opens a review with each session and the exact text; Ty edits it; Cancel sends nothing
    desk_hub "$T/h"; local A
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    srvd --hub "$T/h" || return; page_ok || return
    chk dforms "$T/page.html"; chk dform "$T/page.html" "ask-$A"
    local tok; tok=$(pg dtoken "$T/page.html")
    post /answer "token=$tok" "hub=$T/h" "ask=$A" 'text=Use port 8800'; code_is 409 "a send that skips the review"
    [ ! -s "$T/h/flow/desk/letters.jsonl" ] || note "a letter left with no review"
    review "token=$tok" "hub=$T/h" "item=ask:$A" intent=answer 'text=Use port 8800'; code_is 200 "the review"
    rj "len(d['letters'])==1 and d['letters'][0]['to']=='build' and 'Use port 8800' in d['letters'][0]['text'] and d['sends_to']==['/send']"
    [ ! -s "$T/h/flow/desk/letters.jsonl" ] || note "the review sent a letter"
    askjson "$T/h" "$A" "d['item']['status']=='open'"
    local head; head=$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["letters"][0]["head"])' "$T/review.json")
    post /send "token=$tok" "hub=$T/h" "item=ask:$A" intent=answer 'text=Use port 8800' 'letter_0=x' to_0=discovery; code_is 409 "a send to a session the review did not show"
    [ ! -s "$T/h/flow/desk/letters.jsonl" ] || note "a letter went to a session the review did not show"
    post /send "token=$tok" "hub=$T/h" "item=ask:$A" intent=answer 'text=Use port 8800' 'letter_0=Use port 8800, and say why if not. Edited by Ty.' to_0=build; code_is 303 "send"
    printf '%s' 'Use port 8800, and say why if not. Edited by Ty.' > "$T/edited.txt"
    local want; want=$(dpy "$T/h" render --to build --about "$(python3 -I -c 'import json,sys; t=json.load(open(sys.argv[1]))["letters"][0]["head"]; print(t[len("Letter from Ty (the Desk), about "):-1])' "$T/review.json")" --text-file "$T/edited.txt")
    case "$want" in "$head"*) ;; *) note "the review head is not what the session gets: $(snip "$head") vs $(snip "$want")";; esac
    local about wake; about=$(python3 -I -c 'import json,sys; t=json.load(open(sys.argv[1]))["letters"][0]["head"]; print(t[len("Letter from Ty (the Desk), about "):-1])' "$T/review.json")
    wake=$(dpy "$T/h" wake-text --about "$about")
    python3 -I -c 'import html,sys; sys.exit(0 if html.escape(sys.argv[2], quote=False) in open(sys.argv[1]).read() else 1)' "$T/review.html" "$wake" \
      || note "the review does not show the exact wake line: $(snip "$wake")"
    hookrun "$T/h" build
    python3 -I -c 'import json,sys; o=json.load(open(sys.argv[1])); t=o["hookSpecificOutput"]["additionalContext"]; sys.exit(0 if t==sys.argv[2] else 1)' "$T/hook.out" "$want" \
      || note "the session did not get exactly the reviewed text: $(snip "$(cat "$T/hook.out")")"
    hookrun "$T/h" discovery
    ! grep -q 'Edited by Ty' "$T/hook.out" || note "another session got the letter"
}
t_QS52() {  # Desk c21: each item says where it comes from: a ledger ask and the session that asked it, or a question and its KB
    desk_hub "$T/h"; local A
    A=$(hf "$T/h" --session process add ask --no-kb --title 'Terminology and version lines' --note 'The case, the options and the default, for the test.' --waits-on me)
    srvd --hub "$T/h" || return; page_ok || return
    chk dsrc "$T/page.html" "ask-$A" "Ledger ask $A from process, no KB behind it"
    chk dsrc "$T/page.html" qb 'Question qb in the KB exp'
    chk dsrc "$T/page.html" qa 'Question qa in the KB exp'
}
t_QS53() {  # Desk c5 c8 on serve desk: a divergence is kept in Ty's words and leaves the item open; a requirement goes to intake; the letter is stored first
    desk_hub "$T/h"; local A
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    srvd --hub "$T/h" || return; page_ok || return
    local tok kb; tok=$(pg dtoken "$T/page.html"); kb="$T/h/specs/exp"
    post /send "token=$tok" "hub=$T/h" "item=q:$kb#qb" intent=diverge 'text=That is not what I meant: by id' 'letter_0=Ty diverges: by id'; code_is 303 "diverge on a KB question"
    grep -q "signal(.*divergence, human, .*by id" "$kb/kb.pl" "$kb/answers.pending" 2>/dev/null || note "the divergence is not kept in his words"
    hasnt_goal "$kb" "answered(qb)" "the question stays open"
    # what the Desk records reads as words, never as a Prolog term (review H-0042)
    review "token=$tok" "hub=$T/h" "item=q:$kb#qa" intent=answer choice=yes 'text=as on the screen'; code_is 200 "the review of an answer with words"
    rj "any(r.endswith(', and your words as a note on the question.') for r in d['records']) and not any('->' in r for r in d['records'])"
    mkdir -p "$T/h/specs/disc"; cp "$here/fixtures/discovery-a/kb.pl" "$T/h/specs/disc/kb.pl"
    review "token=$tok" "hub=$T/h" "item=act:$T/h/specs/disc#vote" intent=answer choice=GO; code_is 200 "the review of a vote"
    rj "any(r.startswith('Nothing is written by the Desk: the next session that takes the KB records it') for r in d['records']) and not any('->' in r for r in d['records'])"
    post /send "token=$tok" "hub=$T/h" "item=ask:$A" intent=requirement 'text=The Desk must run as a service' 'letter_0=Ty adds: a service' to_0=review; code_is 303 "a new requirement"
    hf "$T/h" view open --format json | grep -q "new requirement: The Desk must run as a service" || note "no intake thread"
    askjson "$T/h" "$A" "d['item']['status']=='open'"
    post /send "token=$tok" "hub=$T/h" "item=ask:$A" intent=diverge 'text=Not a port at all' 'letter_0=Ty diverges: not a port' to_0=build; code_is 303 "diverge on an ask"
    askjson "$T/h" "$A" "d['item']['status']=='open' and any(e['verb']=='note' and 'Not a port at all' in (e['note'] or '') for e in d['events'])"
    mv "$T/h/.claude/scripts/hubflow.py" "$T/h/.claude/scripts/hubflow.gone"
    post /send "token=$tok" "hub=$T/h" "item=ask:$A" intent=answer 'text=8800' 'letter_0=Ty answers: 8800' to_0=build; code_is 409 "an answer the ledger cannot take"
    grep -q 'Ty answers: 8800' "$T/h/flow/desk/letters.jsonl" || note "the letter was not stored first (c8)"
}
t_QS54() {  # Desk c7 (q9): the card shows Draft and Sent; a sent letter not seen after a day warns; loud when no live session holds the item; applied moves it to Answered
    desk_hub "$T/h"; local A B key
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    B=$(hf "$T/h" --session build add ask --no-kb --title 'Nobody holds this one' --note 'The case, the options and the default, for the test.' --waits-on me --owner none)
    srvd --hub "$T/h" || return; page_ok || return
    chk dcard "$T/page.html" "ask-$B" 'No live session holds this item'
    chk dcard "$T/page.html" "ask-$A" '!No live session holds this item' 'Draft' 'Sent' '!Seen' '!Applied' '!Keep as draft'
    local tok; tok=$(pg dtoken "$T/page.html"); key=$(pg dkey "$T/page.html" "ask-$A")
    post /draft "token=$tok" "key=$key" 'text=half an answer' intent=answer; [ "$CODE" = 204 ] || note "POST /draft: HTTP $CODE"
    [ ! -e "$T/h/flow/desk/drafts.json" ] || note "the draft is in the mindhole (q10)"
    grep -q 'half an answer' "$DESK_STATE/drafts.json" || note "the draft is not in the Desk store"
    page_ok || return; chk dcard "$T/page.html" "ask-$A" 'Draft saved'
    hf "$T/h" --session build set "$A" --status waiting >/dev/null
    post /send "token=$tok" "hub=$T/h" "item=ask:$A" intent=diverge 'text=Not 8737' 'letter_0=Not 8737' to_0=build; code_is 303 "diverge"
    page_ok || return; chk dcard "$T/page.html" "ask-$A" 'sent to build' '!has not seen it after a day'
    python3 -I -c '
import json,sys,datetime; f=sys.argv[1]; ls=[json.loads(x) for x in open(f) if x.strip()]
for x in ls: x["at"]=(datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(days=2)).strftime("%Y-%m-%dT%H:%M:%SZ")
open(f,"w").write("".join(json.dumps(x)+"\n" for x in ls))' "$T/h/flow/desk/letters.jsonl"   # a letter sent two days ago, never seen
    page_ok || return; chk dcard "$T/page.html" "ask-$A" 'has not seen it after a day'
}
t_QS55() {  # Desk c9 on serve desk: an answer given in the session shows as answered, and the question leaves the cards
    desk_hub "$T/h"; local A
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port should the Desk use' --note 'The case, the options and the default, for the test.' --waits-on me)
    srvd --hub "$T/h" || return; page_ok || return
    chk dlane "$T/page.html" guesses qa
    wr discovery --dir "$T/h/specs/exp" add 'answer(qa, yes, human)'; rc_is 0 "the session records Ty's answer"
    hf "$T/h" --session build close "$A" --reason done --note 'Ty said 8800 in the pane' >/dev/null
    page_ok || return
    chk dlane "$T/page.html" guesses '!qa'
    chk text "$T/page.html" 'Ty said 8800 in the pane' "$A"
    chk dkb "$T/page.html" 'exp' 'Answered by a human' 'yes'
}

t_QS56() {  # Desk c22: on load the rail is collapsed and one thing is open: the first card of the first lane that holds one; Your action cards collapse too
    desk_hub "$T/h"; local A B C
    A=$(hf "$T/h" --session process add ask --no-kb --note 'Case: the c3 proof. Options: waive or prove. Default: none.' --title 'Waive the c3 proof' --waits-on me --reserved 'Sagittarius Policy: Only the human may waive a proof.')
    B=$(hf "$T/h" --session build add ask --no-kb --note 'Case: push. Options: now or later. Default: later.' --title 'Push the hub' --waits-on me --reserved 'Ty, 2026-11-12: push only when I say so')
    C=$(hf "$T/h" --session build add ask --no-kb --note 'Case: the port. Options: 8737 or 8800. Default: 8800.' --title 'Which port' --waits-on me)
    srvd --hub "$T/h" || return; page_ok || return
    chk dload "$T/page.html" action "ask-$A"
    chk raw "$T/page.html" "<details class=\"sheet reserved\" id=\"item-h-ask-$B\">" '!<article'
    hf "$T/h" --session build close "$A" --reason done --by human --note 'done' >/dev/null; hf "$T/h" --session build close "$B" --reason done --by human --note 'done' >/dev/null
    page_ok || return
    chk dload "$T/page.html" questions "ask-$C"
    chk dcard "$T/page.html" "ask-$C" 'Case: the port. Options: 8737 or 8800. Default: 8800.' '!recorded only the title'   # c13: the note of add ask is its context
}
t_QS57() {  # Desk c23: the sessions roll up by mindhole; each session has one short line, and its KBs are inside
    desk_hub "$T/h1"; desk_hub "$T/h2"; local H
    kb_spec "$T/h1/specs/two" 'Second rules' ''
    for k in exp two; do H=$(hf "$T/h1" --session discovery handoff --to build --title "Build $k" --ref "kb:$k"); hf "$T/h1" --session build accept "$H" >/dev/null; done
    srvd --hub "$T/h1" --hub "$T/h2" || return; page_ok || return
    local n; n=$(grep -o '<details class="sessgroup">' "$T/page.html" | wc -l); [ "$n" = 2 ] || note "want 2 closed session groups (one per mindhole), found $n"
    chk raw "$T/page.html" 'Writes <b>2 KBs</b>.' 'Writes the KB exp' 'Writes the KB two' '!Writes <b>exp, two</b>'
    chk raw "$T/page.html" 'white-space:nowrap;overflow:hidden;text-overflow:ellipsis'
}
t_QS58() {  # Desk c24: when no desk hook can deliver a letter, the card and the review say so loudly; with the hooks in the settings they do not
    desk_hub "$T/h"; local A tok; mkdir -p "$T/home"
    A=$(hf "$T/h" --session build add ask --no-kb --note 'Case: the port. Options: 8737 or 8800. Default: 8800.' --title 'Which port' --waits-on me)
    HOME="$T/home" srvd --hub "$T/h" || return; page_ok || return
    chk dcard "$T/page.html" "ask-$A" 'build will not be told: the desk hooks are not installed' 'no hook for SessionStart, UserPromptSubmit, Stop'
    tok=$(pg dtoken "$T/page.html")
    review "token=$tok" "hub=$T/h" "item=ask:$A" intent=answer 'text=8800'; code_is 200 "the review"
    grep -q 'build will not be told: the desk hooks are not installed' "$T/review.html" || note "the review does not warn that build will not be told"
    mkdir -p "$T/h/.claude"; dpy "$T/h" hooks > "$T/h/.claude/settings.json"
    page_ok || return
    chk dcard "$T/page.html" "ask-$A" '!will not be told'
    srv_stop
}
# imgsrc FILE NEEDLE: the src (unescaped) of each <img> on the page whose alt holds NEEDLE, one a line
imgsrc() { python3 -I -c "import html,re,sys; p=open(sys.argv[1],encoding='utf-8').read()
for m in re.finditer(r'<img\b[^>]*>', p):
    t=m.group(0); a=re.search(r'alt=\"([^\"]*)\"', t); s=re.search(r'src=\"([^\"]*)\"', t)
    if a and s and sys.argv[2] in html.unescape(a.group(1)): print(html.unescape(s.group(1)))" "$1" "$2"; }
# fetch PATH OUT: a GET with its headers; sets CODE, the body in OUT, the headers in OUT.h
fetch() { CODE=$(curl -s -D "$2.h" -o "$2" -w '%{http_code}' --max-time 30 "$URL$1" 2>/dev/null); }
t_QS59() {  # Desk H-0043 (Ty, 2026-11-18): a flare's demo image renders on its card; the Desk serves only the demo files that it shows
    mkdesk "$T/h"; mkdir -p "$T/h/specs/look"
    printf '\x89PNG\r\n\x1a\n-the-demo-image-' > "$T/h/specs/look/shot.png"
    printf '<p>a mock</p>' > "$T/h/specs/look/mock.html"
    printf 'old' > "$T/h/specs/look/old.png"
    printf 'secret' > "$T/h/specs/look/notes.png"
    local d m; d=$(sha256sum "$T/h/specs/look/shot.png" | cut -d' ' -f1); m=$(sha256sum "$T/h/specs/look/mock.html" | cut -d' ' -f1)
    kb_new "$T/h/specs/look" <<EOF
uses([build]).
request(r1, 'The pane must look calm').
claim(c1, introduce, 'The pane uses three colors at most').
example(c1, 'The idle pane shows grey, green and amber only.').
visual(c1).
claim(c2, introduce, 'The menu reads as one line').
example(c2, 'The menu of the idle pane is one line.').
visual(c2).
claim(c3, introduce, 'The footer is quiet').
example(c3, 'The footer shows one grey line.').
visual(c3).
subject(shot, 'shot.png', 'sha256:$d').
demo(shot, c1).
subject(mock, 'mock.html', 'sha256:$m').
demo(mock, c2).
subject(old, 'old.png', 'sha256:0000000000000000000000000000000000000000000000000000000000000000').
demo(old, c3).
subject(notes, 'notes.png', 'sha256:$d').
EOF
    srvd --hub "$T/h" || return; page_ok || return
    local src tok; src=$(imgsrc "$T/page.html" 'shot.png' | head -n1)
    [ -n "$src" ] || { note "the card of claim c1 shows no image of shot.png"; return; }
    case "$src" in /demo\?*) ;; *) note "the image of shot.png is not served by the Desk: src=$src"; return ;; esac
    fetch "$src" "$T/img"; code_is 200 "GET the demo image" || return
    cmp -s "$T/img" "$T/h/specs/look/shot.png" || note "the Desk served other bytes than shot.png"
    grep -qi '^content-type: image/png' "$T/img.h" || note "the demo image is not served as image/png: $(snip "$(cat "$T/img.h")")"
    grep -qi "^content-security-policy:.*sandbox" "$T/img.h" || note "the demo file is served with no sandbox policy"
    [ -n "$(imgsrc "$T/page.html" 'mock.html')" ] && note "an HTML demo is shown as an image"
    chk raw "$T/page.html" 'mock.html'
    [ -n "$(imgsrc "$T/page.html" 'old.png')" ] || note "the card of claim c3 shows no image of old.png"
    chk raw "$T/page.html" 'old.png changed since the KB recorded its digest'
    chk raw "$T/page.html" '!shot.png changed since'
    # the Desk serves only what it shows, to this run, with the token of the page
    tok=$(pg dtoken "$T/page.html")
    fetch "${src/s=shot/s=notes}" "$T/x1"; code_is 404 "a subject that is not a demo" || true
    fetch "${src/s=shot/s=mock}" "$T/x2"; code_is 404 "an HTML demo as an image" || true
    fetch "${src/token=$tok/token=0}" "$T/x3"; code_is 403 "a demo image with the wrong token" || true
    fetch "/demo?token=$tok&kb=$T/h/specs/look/../look&s=shot" "$T/x4"; code_is 404 "a KB dir that the page did not show" || true
    grep -q 'secret' "$T/x1" "$T/x2" "$T/x4" 2>/dev/null && note "a file the page did not show was served"
    # the KB changes after the page: the subject that was shown now names an HTML file; it is not served
    sed -i "s|^subject(shot, 'shot.png'|subject(shot, 'mock.html'|" "$T/h/specs/look/kb.pl"
    fetch "$src" "$T/x5"; code_is 404 "a shown subject that now names an HTML file" || true
}
# demoside FILE NEEDLE: where the demo NEEDLE sits on its card: "right" (in Why you, why now), "left" (in What it rests on), or "none"
demoside() { python3 -I -c "import sys; p=open(sys.argv[1],encoding='utf-8').read(); i=p.find(sys.argv[2])
if i < 0: print('none'); sys.exit(0)
h=p.rfind('<h3>', 0, i); t=p[h:h+40]
print('right' if 'Why you, why now' in t else 'left' if 'What it rests on' in t else 'other:'+t)" "$1" "$2"; }
t_QS60() {  # Desk c26 (Ty, 2026-11-18: "Lets put the images in the right side of the card to save on vertical space."): the demo sits under Why you, why now
    mkdesk "$T/h"; mkdir -p "$T/h/specs/look"
    printf '\x89PNG\r\n\x1a\n-img-' > "$T/h/specs/look/shot.png"; printf '<p>a mock</p>' > "$T/h/specs/look/mock.html"
    local d m; d=$(sha256sum "$T/h/specs/look/shot.png" | cut -d' ' -f1); m=$(sha256sum "$T/h/specs/look/mock.html" | cut -d' ' -f1)
    kb_new "$T/h/specs/look" <<EOF
uses([build]).
request(r1, 'The pane must look calm').
claim(c1, introduce, 'The pane uses three colors at most').
example(c1, 'The idle pane shows grey, green and amber only.').
visual(c1).
claim(c2, introduce, 'The menu reads as one line').
example(c2, 'The menu of the idle pane is one line.').
visual(c2).
subject(shot, 'shot.png', 'sha256:$d').
demo(shot, c1).
subject(mock, 'mock.html', 'sha256:$m').
demo(mock, c2).
EOF
    srvd --hub "$T/h" || return; page_ok || return
    local s; s=$(demoside "$T/page.html" 'alt="The demo shot of claim c1'); [ "$s" = right ] || note "the image of shot.png is $s, want right (in Why you, why now)"
    s=$(demoside "$T/page.html" '<code>mock.html</code>'); [ "$s" = right ] || note "the name of mock.html is $s, want right (in Why you, why now)"
}

t_QS61() {  # Desk c27 (Ty, 2026-11-18: "Would be more useful to see the message I had previously already sent."): Review and send with nothing new shows what was sent
    desk_hub "$T/h"; local A B tok
    A=$(hf "$T/h" --session build add ask --no-kb --title 'Which port' --note 'Case: the port. Options: 8737 or 8800. Default: 8800.' --waits-on me)
    B=$(hf "$T/h" --session build add ask --no-kb --title 'Which name' --note 'Case: the name. Options: Desk or Board. Default: Desk.' --waits-on me)
    mkdir -p "$T/h/specs/disc"; cp "$here/fixtures/discovery-a/kb.pl" "$T/h/specs/disc/kb.pl"
    local H; H=$(hf "$T/h" --session discovery handoff --to build --title 'Build disc' --ref kb:disc); hf "$T/h" --session build accept "$H" >/dev/null   # build holds the KB
    srvd --hub "$T/h" || return; page_ok || return; tok=$(pg dtoken "$T/page.html")
    post /send "token=$tok" "hub=$T/h" "item=ask:$A" intent=diverge 'text=Not a port at all' 'letter_0=Ty diverges: not a port at all' to_0=build; code_is 303 "diverge on an ask"
    review "token=$tok" "hub=$T/h" "item=ask:$A" intent=answer; code_is 200 "Review and send with nothing new, after a letter"
    grep -q 'Ty diverges: not a port at all' "$T/review.html" || note "the review does not show the letter he sent: $(snip "$(cat "$T/review.html")")"
    grep -q 'You already sent' "$T/review.html" || note "the review does not say that he already sent it"
    grep -q '<button class="btn go"' "$T/review.html" && note "the review of what was sent offers to send"
    review "token=$tok" "hub=$T/h" "item=ask:$B" intent=answer; code_is 400 "Review and send with nothing written and nothing sent"
    post /send "token=$tok" "hub=$T/h" "item=act:$T/h/specs/disc#vote" intent=answer choice=GO 'text=Build it' 'letter_0=Ty votes GO: build it' to_0=build; code_is 303 "a vote"
    grep -q 'Ty votes GO: build it' "$T/h/flow/desk/letters.jsonl" || note "setup: the vote letter was not stored"
    review "token=$tok" "hub=$T/h" "item=act:$T/h/specs/disc#vote" intent=answer; code_is 200 "Review and send on the vote with nothing new"
    grep -q 'Ty votes GO: build it' "$T/review.html" || note "the review of the vote does not show the letter he sent"
}

run_one() {  # run_one ID
    local id=$1 fn=t_$1 i
    [ -n "${ONLY:-}" ] && ! [[ $id =~ $ONLY ]] && return 0
    T=$(mktemp -d "$base/t.XXXXXX"); FAILS=(); SKIPPED=0
    export DESK_STATE="$T/desk-state"   # the Desk's own store (q10): never the real ~/.local/state
    declare -F "$fn" >/dev/null || note "no test function $fn"   # a test that does not exist fails, never passes
    "$fn" </dev/null >/dev/null 2>&1 || true
    srv_stop
    if [ ${#FAILS[@]} -eq 0 ] && [ "$SKIPPED" = 1 ]; then skip=$((skip+1)); echo "SKIP $id"
    elif [ ${#FAILS[@]} -eq 0 ]; then pass=$((pass+1)); echo "PASS $id"
    else fail=$((fail+1)); failed+=("$id"); echo "FAIL $id"; for i in "${FAILS[@]}"; do echo "     - $i"; done; fi
}
for n in $(seq 1 61); do run_one QS$n; done
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ "$fail" -eq 0 ]

#!/usr/bin/env python3
"""desk_stores.py: the server-side checks of the Desk by store (spec KB desk-speed-orbit-door,
checks k17, k18, k19; claims c14, c15, c16). Stdlib only. Each command prints one JSON line
{"checks": [[name, ok, detail], ...], ...} and exits 0 (2 on a setup error).

  ids    URL TAB [VIEW]              the item ids of one page (for a look by hand)
  k17    NEW OLD TAB SPEC.json       the groups by repo of the section Spec KBs
  k18    OLD NEW TAB SPEC.json       every form of 0.9.1 on one KB is in its sheet and writes the same records
  k19    OLD NEW TAB...              the ids of 0.9.1 (each tab) are the ids of the view Everything

An item id of a page is: the id of an element of the main part of the page that is not a section, a
group, a layer, a view or a step (ids that start with lane-, store-, grp-, layer-, view-, more-), the
item field of each form (with its intents), and the ref of each answered ask. Nothing here prints
the text of an item: only ids, names of sections and counts.
"""
import html.parser
import json
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}
STRUCT = ("lane-", "store-", "grp-", "layer-", "view-", "more-", "report-", "ans-")   # report-: the anchor of the link Read the report (vote-start c1); ans-: the target of the link of the line of what was done (r10 c18): a row of Answered, counted as "answered:" below


class El:
    __slots__ = ("tag", "attrs", "kids", "parent", "text")

    def __init__(self, tag, attrs, parent):
        self.tag, self.attrs, self.kids, self.parent, self.text = tag, dict(attrs), [], parent, []

    def cls(self):
        return (self.attrs.get("class") or "").split()

    def walk(self):
        yield self
        for k in self.kids:
            yield from k.walk()

    def ancestors(self):
        p = self.parent
        while p is not None:
            yield p
            p = p.parent

    def all_text(self):
        out = []
        for e in self.walk():
            out.extend(e.text)
        return re.sub(r"\s+", " ", " ".join(out)).strip()


class P(html.parser.HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = El("#root", [], None)
        self.cur = self.root
        self.skip = 0

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style"):
            self.skip += 1
            return
        e = El(tag, attrs, self.cur)
        self.cur.kids.append(e)
        if tag not in VOID:
            self.cur = e

    def handle_startendtag(self, tag, attrs):
        self.cur.kids.append(El(tag, attrs, self.cur))

    def handle_endtag(self, tag):
        if tag in ("script", "style"):
            self.skip = max(0, self.skip - 1)
            return
        if tag in VOID:
            return
        e = self.cur
        while e is not None and e.tag != tag:
            e = e.parent
        if e is not None and e.parent is not None:
            self.cur = e.parent

    def handle_data(self, d):
        if not self.skip:
            self.cur.text.append(d)


def parse(s):
    p = P()
    p.feed(s)
    return p.root


def get(url, timeout=300):
    with urllib.request.urlopen(url, timeout=timeout) as r:
        return r.read().decode("utf-8")


def post(url, fields, frag=False, timeout=120):
    data = urllib.parse.urlencode(fields).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    if frag:
        req.add_header("X-Desk-Fragment", "1")

    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *a, **k):
            return None
    op = urllib.request.build_opener(NoRedirect)
    try:
        with op.open(req, timeout=timeout) as r:
            return r.status, r.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")


def page_url(base, tab, view=None):
    q = {}
    if tab:
        q["mh"] = tab
    if view:
        q["view"] = view
    return base + "/" + ("?" + urllib.parse.urlencode(q) if q else "")


def main_of(root):
    for e in root.walk():
        if e.tag == "main":
            return e
    return root


def in_dialog(e):
    return any(a.tag == "dialog" for a in e.ancestors())


def form_info(f):
    """item, the set of intents a form can send, its other named fields."""
    item, intents, fields, choices = "", [], {}, []
    for e in f.walk():
        if e.tag == "input":
            n, v, t = e.attrs.get("name"), e.attrs.get("value", ""), (e.attrs.get("type") or "text")
            if not n:
                continue
            if n == "item":
                item = v
            elif n == "intent":
                intents.append(v)
            elif n == "choice" and t == "radio":
                choices.append(v)
            elif t == "hidden":
                fields[n] = v
        elif e.tag == "select" and e.attrs.get("name"):
            fields.setdefault(e.attrs["name"], "")
    return item, intents, fields, choices


def items(html_text):
    """ids: element ids of items (in order, with repeats); forms: [(item, intents)]; answered refs."""
    root = parse(html_text)
    m = main_of(root)
    ids, forms, ans = [], [], []
    for e in m.walk():
        if in_dialog(e):
            continue
        i = e.attrs.get("id")
        if i and not i.startswith(STRUCT):
            ids.append(i)
        if e.tag == "form":
            it, ints, _, _ = form_info(e)
            if it and not it.startswith("rec:"):   # the forms of Change records are new in 0.11.0: forms, not items
                forms.append((it, tuple(sorted(ints))))
        if e.tag == "ul" and "answered" in e.cls():
            for li in e.kids:
                for s in li.walk():
                    if s.tag == "span" and "ref" in s.cls():
                        ans.append(s.all_text())
                        break
    return {"ids": ids, "forms": forms, "answered": ans}


def top_counts(html_text):
    """the two counts of the top band: what waits on Ty, and what runs on a guess (has a default)."""
    m = re.search(r'<header class="top">.*?<p><strong>(\d+) things? waits? on you,</strong> and (\d+) ', html_text, re.S)
    return (int(m.group(1)), int(m.group(2))) if m else None


def norm_paths(s, roots):
    for r, k in roots:
        s = s.replace(r, k)
    return s


# ---------------------------------------------------------------- k19
def cmd_k19(old, new, tabs):
    checks = []
    out = {}
    for tab in tabs:
        po = get(page_url(old, tab))
        pn = get(page_url(new, tab, "everything"))
        io, inn = items(po), items(pn)
        # the forms of Change records (kb-crud c5) are new in 0.11.0: forms, not items
        so = set(io["ids"]) | {"form:" + f[0] for f in io["forms"]} | {"answered:" + a for a in io["answered"]}
        # the form New requirement for this KB is new in 0.9.2 (c15): a form, not an item
        # the forms Vote and Bring to a vote are new in 0.11.0 (vote-start c1, c3), and so are the change records (kb-crud c5): forms, not items
        sn = set(inn["ids"]) | {"form:" + f[0] for f in inn["forms"] if not f[0].startswith(("kbreq:", "rec:", "vote:", "callvote:"))} | {"answered:" + a for a in inn["answered"]}
        lost, extra = sorted(so - sn), sorted(sn - so)
        dup = sorted({i for i in inn["ids"] if inn["ids"].count(i) > 1})
        fo = sorted(io["forms"])
        fn = sorted(f for f in inn["forms"] if not f[0].startswith(("kbreq:", "rec:", "vote:", "callvote:")))
        co, cn = top_counts(po), top_counts(pn)
        out[tab or "-"] = {"old_ids": len(so), "new_ids": len(sn), "lost": len(lost), "extra": len(extra), "dup": len(dup),
                           "old_forms": len(fo), "new_forms": len(fn), "kbreq_forms": len(inn["forms"]) - len(fn),
                           "old_counts": co, "new_counts": cn}
        t = tab or "the one tab"
        checks.append([f"{t}: each item id of 0.9.1 is in the view Everything (0 lost of {len(so)})", not lost, " ".join(lost[:12])])
        checks.append([f"{t}: the view Everything has no item that 0.9.1 does not show", not extra, " ".join(extra[:12])])
        checks.append([f"{t}: no item id is twice on the new page", not dup, " ".join(dup[:12])])
        checks.append([f"{t}: each form of 0.9.1 (item and intents) is on the new page as often ({len(fo)})", fo == fn,
                       f"{len(fo)} vs {len(fn)}"])
        checks.append([f"{t}: the two counts of the top band are equal {co}", co is not None and co == cn, f"{co} vs {cn}"])
    print(json.dumps({"checks": checks, "counts": out}))


# ---------------------------------------------------------------- k17
def sections(root):
    m = main_of(root)
    return [e for e in m.walk() if e.tag == "details" and "store" in e.cls()]


def summary_name(d, sel=("h2", "h3", "span")):
    for k in d.kids:
        if k.tag == "summary":
            for e in k.walk():
                if e is not k and e.tag in sel and ({"name", "gname", "lname", "sname"} & set(e.cls()) or e.tag in ("h2", "h3")):
                    return e.all_text()
            return k.all_text()
    return ""


def cmd_k17(new, old, tab, spec):
    sp = json.load(open(spec))
    checks = []
    pn = get(page_url(new, tab, "everything"))
    root = parse(pn)
    st = [s for s in sections(root) if s.attrs.get("id") == "store-spec"]
    checks.append(["the page has one section Spec KBs", len(st) == 1, str(len(st))])
    groups = {}
    where = {}
    if st:
        for g in st[0].walk():
            if g.tag == "details" and "group" in g.cls():
                nm = summary_name(g, ("span",))
                summ = next(k for k in g.kids if k.tag == "summary")
                sheets = [e for e in g.walk() if e.tag == "details" and "kbsec" in e.cls()]
                labels = []
                for s in sheets:
                    t = [e for e in s.walk() if e.tag == "h3" and "title" in e.cls()]
                    labels.append(t[0].all_text() if t else "?")
                    where.setdefault(labels[-1], []).append(nm)
                groups[nm] = {"n": len(sheets), "summary": summ.all_text(), "labels": labels}
    want = sp["groups"]          # {name: [labels]}
    checks.append([f"the groups are exactly {sorted(want)}", sorted(groups) == sorted(want), json.dumps(sorted(groups))])
    for g, labs in want.items():
        got = groups.get(g, {})
        checks.append([f"group {g} holds {sorted(labs)}", sorted(got.get("labels", [])) == sorted(labs), json.dumps(got.get("labels"))])
        checks.append([f"group {g} shows how many KBs it holds ({len(labs)}) and how many wait on Ty",
                       bool(re.search(r"\b%d KBs?\b" % len(labs), got.get("summary", ""))) and "wait" in got.get("summary", "").lower(),
                       got.get("summary", "")[:120]])
    twice = {k: v for k, v in where.items() if len(v) != 1}
    checks.append(["each KB is in exactly one group", not twice, json.dumps(twice)])
    # the count of all groups equals the count of spec KBs of the page of 0.9.1
    po = get(page_url(old, tab))
    ro = parse(po)
    n_old = 0
    for s in ro.walk():
        if s.tag == "details" and "kbsec" in s.cls():
            src = s.all_text()
            if "Project KB" not in src[:400]:
                n_old += 1
    n_new = sum(g["n"] for g in groups.values())
    checks.append([f"the groups hold as many KBs as the page of 0.9.1 shows spec KBs ({n_old})", n_new == n_old, f"{n_new} vs {n_old}"])
    if sp.get("second"):
        lab, other = sp["second"]
        sh = [e for e in st[0].walk() if e.tag == "details" and "kbsec" in e.cls() and any(h.tag == "h3" and h.all_text() == lab for h in e.walk())] if st else []
        txt = sh[0].all_text() if sh else ""
        checks.append([f"the sheet of {lab} (two repos) names the second repo {other}", bool(sh) and other in txt, ""])
    print(json.dumps({"checks": checks, "groups": {k: v["n"] for k, v in groups.items()}}))


# ---------------------------------------------------------------- k18
def snapshot(dirs):
    snap = {}
    for d in dirs:
        for r, ds, fs in os.walk(d):
            ds[:] = [x for x in ds if x not in (".cache", "chrome", "cache", "__pycache__")]
            for f in fs:
                p = os.path.join(r, f)
                if f.endswith((".db", ".db-wal", ".db-shm", ".lock", ".pyc")) or f in ("srv.out", "srv.err"):
                    continue
                try:
                    snap[p] = open(p, encoding="utf-8").read()
                except (UnicodeDecodeError, OSError):
                    pass
    return snap


TS = re.compile(r"\d{4}-\d\d-\d\d[T ]\d\d:\d\d(:\d\d(\.\d+)?)?(Z|[+-]\d\d:?\d\d)?")
SIG = re.compile(r"\bsd\d{6,}[0-9a-f]*\b")
HEX = re.compile(r"\b[0-9a-f]{16,}\b")
LID = re.compile(r"\bL-\d{8}T\d{6}Z-[0-9a-f]+\b")
# the version token of the tool that wrote a KB (it must differ between two versions of the tool):
# only the token of "% Made by orbit-kb V." and of upgraded('V', T), nothing else of the line
VER_MADE = re.compile(r"^(%\s*Made by orbit-kb )[0-9][0-9A-Za-z.+-]*?(\.?\s*)$")
VER_UPG = re.compile(r"\bupgraded\(('?)[0-9][0-9A-Za-z.+-]*?\1,")


def norm_ver(x):
    return VER_UPG.sub(lambda m: "upgraded(" + m.group(1) + "VER" + m.group(1) + ",", VER_MADE.sub(r"\1VER\2", x))


def delta(before, after, roots):
    """the lines that the send added or removed, each file by its name relative to its root, normalized."""
    out = []
    for p in sorted(set(before) | set(after)):
        a, b = before.get(p, ""), after.get(p, "")
        if a == b:
            continue
        al, bl = a.splitlines(), b.splitlines()
        added = [x for x in bl if x not in set(al)]
        removed = [x for x in al if x not in set(bl)]
        # kb-crud c9 (0.11.0): a fact that a human writes carries by_human(Fact, Time). The 0.9.1 Desk writes the fact only.
        # Only that new mark is left out; the fact itself is still compared.
        added = [x for x in added if not x.startswith("by_human(")]
        name = norm_paths(p, roots)
        for x in added:
            out.append("+ " + name + " " + LID.sub("LID", HEX.sub("HEX", SIG.sub("SIG", TS.sub("TS", norm_ver(norm_paths(x, roots)))))))
        for x in removed:
            out.append("- " + name + " " + LID.sub("LID", HEX.sub("HEX", SIG.sub("SIG", TS.sub("TS", norm_ver(norm_paths(x, roots)))))))
    return sorted(out)


def forms_of(html_text):
    root = parse(html_text)
    res = []
    for f in main_of(root).walk():
        if f.tag != "form" or in_dialog(f):
            continue
        it, ints, fields, choices = form_info(f)
        if not it:
            continue
        sheets = [a for a in f.ancestors() if a.tag == "details" and "kbsec" in a.cls()]
        res.append({"item": it, "intents": ints, "fields": fields, "choices": choices,
                    "sheet": sheets[-1].attrs.get("id") if sheets else None,
                    "judge": f.attrs.get("data-judge")})
    return res


def review_fields(html_text):
    root = parse(html_text)
    for f in root.walk():
        if f.tag == "form" and (f.attrs.get("action") or "").endswith("/send"):
            flds = []
            for e in f.walk():
                n = e.attrs.get("name")
                if not n:
                    continue
                if e.tag == "input" and (e.attrs.get("type") or "text") not in ("radio", "checkbox", "submit", "button"):
                    flds.append((n, e.attrs.get("value", "")))
                elif e.tag == "input" and e.attrs.get("type") in ("radio", "checkbox") and "checked" in e.attrs:
                    flds.append((n, e.attrs.get("value", "")))
                elif e.tag == "textarea":
                    flds.append((n, e.all_text() if False else "".join(e.text)))
                elif e.tag == "select":
                    opts = [o for o in e.walk() if o.tag == "option"]
                    sel = [o for o in opts if "selected" in o.attrs] or opts[:1]
                    flds.append((n, sel[0].attrs.get("value", "") if sel else ""))
            return flds
    return None


ORDER = ["requirement", "diverge", "note", "answer", "park", "close"]


def cmd_k18(old, new, tab, spec):
    """SPEC: {"kb": label, "dir_old": abs dir of the KB in the old copy, "dir_new": ..., "ledger_ids": [...],
              "roots_old": [[path, key]...], "roots_new": [...], "watch_old": [dirs], "watch_new": [dirs]}"""
    sp = json.load(open(spec))
    checks = []
    ro, rn = [tuple(x) for x in sp["roots_old"]], [tuple(x) for x in sp["roots_new"]]

    def names_kb(item, d):
        if d in item:
            return True
        m = re.match(r"^(ask|led):(.+)$", item)
        return bool(m and m.group(2) in sp["ledger_ids"])

    po, pn = get(page_url(old, tab)), get(page_url(new, tab, "everything"))
    fo = [f for f in forms_of(po) if names_kb(f["item"], sp["dir_old"])]
    fn = forms_of(pn)
    anchor = sp["anchor"]
    nkey = lambda it, roots: norm_paths(it, roots)
    fkey = lambda g, roots: nkey(g["item"], roots) + ("|" + g["judge"] if g.get("judge") else "")
    listed = []
    for f in fo:
        k = fkey(f, ro)
        m = [g for g in fn if fkey(g, rn) == k]
        listed.append(k)
        checks.append([f"the form {k} is inside the sheet of {sp['kb']}", len(m) == 1 and m[0]["sheet"] == anchor,
                       f"{len(m)} found, sheet {m[0]['sheet'] if m else None}"])
    kinds = sorted({re.sub(r":.*", "", k) for k in listed})
    checks.append([f"0.9.1 has forms of each kind on this KB (question, act, adopt, judge, ask, led): {kinds}",
                   all(x in kinds for x in sp.get("want_kinds", [])), json.dumps(kinds)])
    # submit each through its review step, on each copy, and compare what it wrote
    # control of the comparison: a difference of the version token alone is the same record, and a real
    # difference of a written record (here the intent word) still differs
    kb_ = "/c/kb.pl"
    # each copy holds a KB written by its own tool before the send
    bef = {kb_: "% Made by orbit-kb 0.9.0.\nfact(a).\n"}
    bef_new = {kb_: "% Made by orbit-kb 0.10.0.\nfact(a).\n"}
    v_old = delta(bef, {kb_: "% Made by orbit-kb 0.9.0.\nfact(a).\nupgraded('0.9.0', t).\nnote(c2, 'on flare:c2: diverge').\n"}, [])
    v_new = delta(bef_new, {kb_: "% Made by orbit-kb 0.10.0.\nfact(a).\nupgraded('0.10.0', t).\nnote(c2, 'on flare:c2: diverge').\n"}, [])
    v_word = delta(bef_new, {kb_: "% Made by orbit-kb 0.10.0.\nfact(a).\nupgraded('0.10.0', t).\nnote(c2, 'on flare:c2: requirement').\n"}, [])
    v_line = delta(bef_new, {kb_: "% Made by orbit-kb 0.10.0 (x).\nfact(a).\nupgraded('0.10.0', t).\nnote(c2, 'on flare:c2: diverge').\n"}, [])
    checks.append(["control: a record that differs only in the version of the tool counts as the same record",
                   v_old == v_new, json.dumps([v_old, v_new])])
    checks.append(["control: a record that differs in its intent word, or in the rest of the version line, still differs",
                   v_new != v_word and v_new != v_line, json.dumps([v_new, v_word, v_line])])
    n_same = 0
    n_tried = 0
    for f in fo:
        k = fkey(f, ro)
        ints = sorted(set(f["intents"] or ["answer"]), key=lambda x: ORDER.index(x) if x in ORDER else 99)
        for intent in ints:
            res = []
            for base, pg_tab, roots, watch, is_new in ((old, tab, ro, sp["watch_old"], False), (new, tab, rn, sp["watch_new"], True)):
                page = get(page_url(base, pg_tab, "everything" if is_new else None))
                g = [x for x in forms_of(page) if fkey(x, roots) == k]
                if not g:
                    res.append(("gone", []))
                    continue
                g = g[0]
                flds = dict(g["fields"])
                flds["item"] = g["item"]
                flds["intent"] = intent
                flds["tab"] = tab
                if g["choices"] and intent == "answer":
                    flds["choice"] = g["choices"][0]
                flds["text"] = "Desk test words for " + intent
                if intent == "park":
                    flds["until"] = "2099-01-01"
                before = snapshot(watch)
                st, body = post(base + "/review", flds, frag=True)
                if st != 200:
                    res.append(("review %d %s" % (st, re.sub(r"<[^>]+>", " ", body)[:160].strip()), delta(before, snapshot(watch), roots)))
                    continue
                rf = review_fields(body)
                if rf is None:
                    res.append(("no send form", delta(before, snapshot(watch), roots)))
                    continue
                st2, body2 = post(base + "/send", rf)
                after = snapshot(watch)
                res.append(("send %d" % st2, delta(before, after, roots)))
            n_tried += 1
            same = res[0] == res[1]
            n_same += same
            detail = "" if same else json.dumps({"old": res[0], "new": res[1]})[:900]
            checks.append([f"{k} intent {intent}: the same record ({res[0][0]}, {len(res[0][1])} lines)", same, detail])
    # the KB-level requirement form of the new sheet (no form of 0.9.1 is the same; its ledger record equals
    # the record of the requirement of a question card of this KB on 0.9.1)
    kr = [g for g in fn if g["item"].startswith("kbreq:") and g["sheet"] == anchor]
    checks.append([f"the sheet of {sp['kb']} has one form New requirement for this KB", len(kr) == 1, str(len(kr))])
    print(json.dumps({"checks": checks, "tried": n_tried, "same": n_same}))


def cmd_kbreq(old, new, tab, spec):
    """the form New requirement for this KB (new) against the requirement of a question card of the same KB (0.9.1):
    the same ledger record (a thread of review with the text and the ref kb:SLUG)."""
    sp = json.load(open(spec))
    ro, rn = [tuple(x) for x in sp["roots_old"]], [tuple(x) for x in sp["roots_new"]]
    text = "A new requirement for the KB, from its sheet"
    res = []
    found = []
    for base, is_new in ((old, False), (new, True)):
        fs = forms_of(get(page_url(base, tab, "everything" if is_new else None)))
        d = sp["dir_new"] if is_new else sp["dir_old"]
        if is_new:
            found.append([f for f in fs if f["item"] == "kbreq:" + d])
        else:
            found.append([f for f in fs if f["item"].startswith("q:" + d + "#") and "requirement" in f["intents"]])
    for (base, roots, watch, is_new), g in zip(((old, ro, sp["watch_old"], False), (new, rn, sp["watch_new"], True)), found):
        if not all(found):          # send nothing on either copy, so that the two copies stay equal for k18
            res.append(("no form" if not g else "not sent: no form on the other copy", []))
            continue
        g = g[0]
        flds = dict(g["fields"]); flds.update({"item": g["item"], "intent": "requirement", "text": text, "tab": tab})
        ledger = [w for w in watch if w.endswith("/flow")]
        jl = [os.path.join(w, "jsonl") for w in ledger]
        before = snapshot(jl)
        st, body = post(base + "/review", flds, frag=True)
        rf = review_fields(body) if st == 200 else None
        if rf is None:
            res.append(("review %d" % st, []))
            continue
        st2, _ = post(base + "/send", rf)
        res.append(("send %d" % st2, delta(before, snapshot(jl), roots)))
    same = res[0] == res[1] and res[0][0] == "send 303"
    has_ref = any("kb:" + sp["kb"] in x or '"kb", "' + sp["kb"] in x or sp["kb"] in x for x in res[1][1]) if len(res) > 1 else False
    print(json.dumps({"checks": [
        ["New requirement for this KB writes the ledger record that the requirement of a card of the KB writes on 0.9.1 (%s, %d lines)" % (res[0][0], len(res[0][1])),
         same, "" if same else json.dumps({"old": res[0], "new": res[1]})[:900]],
        ["its thread carries the ref of the KB %s" % sp["kb"], has_ref, ""]]}))


def cmd_ids(url, tab, view):
    p = get(page_url(url, tab, view))
    i = items(p)
    print(json.dumps({"ids": len(i["ids"]), "unique": len(set(i["ids"])), "forms": len(i["forms"]), "answered": len(i["answered"]),
                      "counts": top_counts(p)}))


if __name__ == "__main__":
    a = sys.argv[1:]
    try:
        if a[0] == "k19":
            cmd_k19(a[1], a[2], a[3:] or [""])
        elif a[0] == "k17":
            cmd_k17(a[1], a[2], a[3], a[4])
        elif a[0] == "k18":
            cmd_k18(a[1], a[2], a[3], a[4])
        elif a[0] == "kbreq":
            cmd_kbreq(a[1], a[2], a[3], a[4])
        elif a[0] == "ids":
            cmd_ids(a[1], a[2] if len(a) > 2 else "", a[3] if len(a) > 3 else None)
        else:
            raise SystemExit("usage: desk_stores.py k17|k18|k19|ids ...")
    except (IndexError, OSError) as e:
        print("desk_stores: " + str(e), file=sys.stderr)
        sys.exit(2)

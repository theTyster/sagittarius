#!/usr/bin/env python3
"""repo-map views: the groups view and the flow view of Sagittarius (spec KB repo-map-flow).

    views.py build [--root DIR] [--facts FILE] [--out DIR]   write the map (Markdown + HTML)
    views.py check [--root DIR] [--facts FILE] [--out DIR]   exit 1 when the map and its sources differ
    views.py trace KB_DIR [--root DIR] [--facts FILE]        follow one spec KB through the flow view
    views.py data  [--root DIR] [--facts FILE]               print the boxes and arrows as JSON

The groups view takes its groups from MODULES.json (modules.py), its stores from
hubkit/tools/store-facts.json, and its parts and outside things from the facts file
(kb/share/repo-map/sagittarius.views.json). Its lines are of three kinds: install (a module to
what it links into ~: derived from the `installs` of MODULES.json, and hand-written ones in the
facts file), creates (a module to a store that it makes) and writes (an acting part to a store that
it writes). Each line names its sources (file, kind of name, name), which `check` finds. The flow view takes its lanes, record kinds and arrows
from the facts file. Each box and arrow names a source by a name that `check` finds in its file.
`check` also goes red when a module, a store, or a declared record kind (decl(fact, ...) or
attest_type of core.pl and the modules build and discovery) is not in the map and not left out with
a reason, when the committed map has a box that no source has, and when the committed files differ
from the files that `build` makes now. The same inputs give the same bytes: nothing here reads the
clock, the network, or the order of a directory listing. Standard library only.
Spec and formats: kb/share/repo-map/README.md, section Views.
"""
import argparse
import html
import json
import os
import re
import subprocess
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
FACTS_REL = "kb/share/repo-map/sagittarius.views.json"
OUT_REL = "docs/map"
MD_NAME = "sagittarius-map.md"
HTML_NAME = "sagittarius-map.html"
DECL_FILES = ["kb/share/orbit-kb/core.pl", "kb/share/orbit-kb/modules/build.pl",
              "kb/share/orbit-kb/modules/discovery.pl"]
STORE_FACTS = "hubkit/tools/store-facts.json"
# The kinds that the flow view must carry, each with a write (or derive) arrow and a read arrow
# (claim c2). They live here, not in the facts file, so that an edit of the facts cannot drop one.
REQUIRED_KINDS = ["request", "goal", "hypothesis", "premise", "claim", "check", "run", "verdict", "judgment"]

# Layout constants (px). The font is monospace, so the width of a label is its length times CH.
FONT = 12
SMALL = 11
CH = 7.6          # an upper bound of the advance of one character at 12 px in a monospace font
CH_SMALL = 7.0
PAD = 10
HEAD_EVERY = 10  # the lane headers come again every so many steps
LINE = 18        # the distance of two lines of one label (px)
WRAP = 40        # the longest line of a step label in the flow view (characters)


class MapError(Exception):
    pass


# ---------------------------------------------------------------- inputs

def load_modules(root):
    p = os.path.join(root, "MODULES.json")
    with open(p, encoding="utf-8") as f:
        return json.load(f)["modules"]


def load_stores(root):
    with open(os.path.join(root, STORE_FACTS), encoding="utf-8") as f:
        return [s["name"] for s in json.load(f)["stores"]]


def load_facts(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def module_of(mods, path):
    """The one module that covers PATH: the longest covering path, less the except paths."""
    best, blen = None, -1
    for m in mods:
        for c in m.get("covers", []):
            if path == c or path.startswith(c.rstrip("/") + "/"):
                if any(path == e or path.startswith(e.rstrip("/") + "/") for e in m.get("except", [])):
                    continue
                if len(c) > blen:
                    best, blen = m["name"], len(c)
    return best


def declared_kinds(root):
    """{name: 'decl'|'attest_type'} for each decl(fact, NAME(...)) and attest_type(NAME, ...)."""
    out = {}
    for rel in DECL_FILES:
        with open(os.path.join(root, rel), encoding="utf-8") as f:
            for line in f:
                m = re.match(r"decl\(fact,\s*([a-z_][a-zA-Z0-9_]*)\(", line)
                if m:
                    out.setdefault(m.group(1), "decl")
                m = re.match(r"attest_type\(([a-z_][a-zA-Z0-9_]*),", line)
                if m:
                    out.setdefault(m.group(1), "attest_type")
    return out


# ---------------------------------------------------------------- sources

def git_files(root):
    r = subprocess.run(["git", "-C", root, "ls-files", "-z"], capture_output=True)
    if r.returncode != 0:
        raise MapError("git ls-files failed in %s" % root)
    return set(x.decode() for x in r.stdout.split(b"\0") if x)


def name_pattern(kind, name):
    n = re.escape(name)
    if kind == "pred":
        return r"^%s(\(| :-)" % n
    if kind == "kb_cmd":
        return r"^kb_cmd\('?%s'?," % n
    if kind == "route":
        meth, _, path = name.partition(" ")
        return r"^serve_route\(%s, '%s'," % (re.escape(meth), re.escape(path))
    if kind == "def":
        return r"^\s*def %s\(" % n
    if kind == "decl":
        return r"^decl\((fact|rule),\s*%s\(" % n
    if kind == "attest_type":
        return r"^attest_type\(%s," % n
    if kind == "json":
        return r'"%s"' % n
    if kind == "text":
        return n
    return None


def resolve(root, files, src, cache):
    """None when SRC resolves, else the reason that it does not."""
    if not isinstance(src, dict) or not src.get("file") or not src.get("kind") or not src.get("name"):
        return "no source (a file, a kind and a name)"
    f, kind, name = src["file"], src["kind"], src["name"]
    if kind == "remote":
        r = subprocess.run(["git", "-C", root, "remote", "get-url", name], capture_output=True, text=True)
        return None if r.returncode == 0 else "no git remote %s" % name
    if f not in files and not any(x.startswith(f.rstrip("/") + "/") for x in files):
        return "the file %s is not in the commit" % f
    pat = name_pattern(kind, name)
    if pat is None:
        return "unknown kind of name %s" % kind
    if f not in cache:
        with open(os.path.join(root, f), encoding="utf-8", errors="replace") as fh:
            cache[f] = fh.read()
    if not re.search(pat, cache[f], re.M):
        return "%s %s is not in %s" % (kind, name, f)
    return None


def src_text(src):
    if not isinstance(src, dict):
        return "(none)"
    return "%s %s %s" % (src.get("file", "?"), src.get("kind", "?"), src.get("name", "?"))


# ---------------------------------------------------------------- the model of the map

def model(root, facts):
    mods = load_modules(root)
    stores = load_stores(root)
    errors = []
    groups = []
    for m in mods:
        parts = []
        for c in m.get("covers", []):
            parts.append({"id": "covers:" + c, "label": c + "/ (covers)", "path": c,
                          "source": {"file": "MODULES.json", "kind": "json", "name": c}})
        groups.append({"id": m["name"], "label": m["name"],
                       "source": {"file": "MODULES.json", "kind": "json", "name": m["name"]},
                       "parts": parts})
    gi = {g["id"]: g for g in groups}
    for p in facts.get("parts", []):
        owner = module_of(mods, p["path"])
        if owner is None:
            errors.append("part %s (%s) is covered by no module of MODULES.json" % (p["id"], p["path"]))
            continue
        gi[owner]["parts"].append({"id": p["id"], "label": p["label"], "path": p["path"],
                                   "source": {"file": p["path"], "kind": "file", "name": p["path"]}})
    store_boxes = [{"id": "store:" + s, "label": "store " + s,
                    "source": {"file": STORE_FACTS, "kind": "json", "name": s}} for s in stores]
    outside = [dict(o) for o in facts.get("outside", [])]
    lines, lerrs = group_lines(mods, facts, gi, [s["id"] for s in store_boxes], [o["id"] for o in outside])
    errors += lerrs
    return {"groups": groups, "stores": store_boxes, "outside": outside, "lines": lines,
            "lanes": facts.get("lanes", []), "kinds": facts.get("kinds", []),
            "steps": facts.get("steps", []), "not_drawn": facts.get("not_drawn", [])}, errors


def group_lines(mods, facts, gi, store_ids, outside_ids):
    """The lines of the groups view: [{id, kind, from, to, what, sources}] and the errors."""
    lines, errs = [], []
    part_ids = {p["id"] for g in gi.values() for p in g["parts"]}
    for mo in mods:                                  # install: one line for each link of MODULES.json
        for link, rel in mo.get("installs", {}).items():
            lines.append({"id": "install:%s:%s" % (mo["name"], link), "kind": "install",
                          "from": "group:" + mo["name"], "to": "outside:install_links",
                          "what": "%s links %s" % (link, rel),
                          "sources": [{"file": "MODULES.json", "kind": "json", "name": link},
                                      {"file": "install.py", "kind": "def", "name": "main"}]})
    for key, kind in (("module_installs", "install"), ("module_stores", "creates"), ("part_stores", "writes")):
        for l in facts.get(key, []):
            if key == "part_stores":
                frm, to = "part:" + l.get("part", "?"), "store:" + l.get("store", "?")
                if l.get("part") not in part_ids:
                    errs.append("line %s: %s is not a part" % (l.get("id"), l.get("part")))
            elif key == "module_stores":
                frm, to = "group:" + l.get("module", "?"), "store:" + l.get("store", "?")
            else:
                frm, to = "group:" + l.get("module", "?"), l.get("to", "?")
            if key != "part_stores" and l.get("module") not in gi:
                errs.append("line %s: %s is not a module" % (l.get("id"), l.get("module")))
            if to.startswith("store:") and to not in store_ids:
                errs.append("line %s: %s is not a store" % (l.get("id"), to))
            if to.startswith("outside:") and to[len("outside:"):] not in outside_ids + ["mindhole_stores"]:
                errs.append("line %s: %s is not a box" % (l.get("id"), to))
            lines.append({"id": l.get("id", "?"), "kind": kind, "from": frm, "to": to,
                          "what": l.get("what", ""), "short": l.get("short"), "sources": l.get("sources", [])})
    seen = set()
    for l in lines:
        if l["id"] in seen:
            errs.append("line %s is listed twice" % l["id"])
        seen.add(l["id"])
    return lines, errs


def boxes(m):
    """Every box of both views: (id, source)."""
    out = []
    for g in m["groups"]:
        out.append(("group:" + g["id"], g["source"]))
        for p in g["parts"]:
            out.append(("part:" + p["id"], p["source"]))
    for s in m["stores"]:
        out.append((s["id"], s["source"]))
    for o in m["outside"]:
        out.append(("outside:" + o["id"], o.get("source")))
    for l in m["lanes"]:
        out.append(("lane:" + l["id"], l.get("source")))
    return out


def map_data(m):
    """The machine-readable copy that the HTML page carries (ids only, for the checks)."""
    return {
        "groups": [{"id": g["id"], "parts": [p["id"] for p in g["parts"]]} for g in m["groups"]],
        "stores": [s["id"][len("store:"):] for s in m["stores"]],
        "outside": [o["id"] for o in m["outside"]],
        "lines": [{"id": l["id"], "kind": l["kind"], "from": l["from"], "to": l["to"]} for l in m["lines"]],
        "tags": [{"box": b, "kind": tg["kind"], "lines": tg["lines"]} for b, tgs in sorted(box_tags(m).items()) for tg in tgs],
        "lanes": [l["id"] for l in m["lanes"]],
        "kinds": [k["id"] for k in m["kinds"]],
        "steps": [{"id": s["id"], "kinds": s["kinds"], "verb": s["verb"], "from": s["from"],
                   "to": s["to"]} for s in m["steps"]],
    }


# ---------------------------------------------------------------- render: SVG

def esc(s):
    return html.escape(str(s), quote=True)


def tw(s, ch=CH):
    return int(len(s) * ch + 0.999)


TAG_KINDS = [("install", "installs", "installed by"), ("creates", "creates", "created by"), ("writes", "writes", "written by")]
TAG_LINE = 16     # the distance of two lines of one tag (px)


def box_name(m, bid):
    """The readable name that the map already uses for a box (a module, a part, a store)."""
    kind, _, name = bid.partition(":")
    if kind == "group":
        return name
    if kind == "part":
        for g in m["groups"]:
            for p in g["parts"]:
                if p["id"] == name:
                    return p["label"]
    if kind == "store":
        return name
    if kind == "outside":
        for o in m["outside"]:
            if o["id"] == name:
                return o["label"]
        return "a mindhole"
    return bid


def box_tags(m):
    """{box id: [tag]}, a tag is {kind, text, lines: [line ids]}. At the end that acts (a module, a part):
    "installs: LINK" for each install line, and one tag "creates: A, B" or "writes: A" for each other kind.
    At the other end one tag for each kind: "installed by: ...", "created by: ...", "written by: ...".
    The words of the tags come from the lines (MODULES.json installs and the facts file)."""
    out = {}
    word = {k: (a, b) for k, a, b in TAG_KINDS}
    for l in m["lines"]:
        if l["kind"] == "install":
            link = l["id"].split(":", 2)[2] if l["id"].count(":") >= 2 and l["id"].startswith("install:") else l["id"]
            text = "installs: " + (l.get("short") or link)
            out.setdefault(l["from"], []).append({"kind": "install", "text": text, "lines": [l["id"]]})
    for kind, acts, passive in TAG_KINDS:
        by_from, by_to = {}, {}
        for l in m["lines"]:
            if l["kind"] == kind:
                by_from.setdefault(l["from"], []).append(l)
                by_to.setdefault(l["to"], []).append(l)
        if kind != "install":
            for bid, ls in by_from.items():
                out.setdefault(bid, []).append({"kind": kind, "lines": [l["id"] for l in ls],
                                                "text": "%s: %s" % (acts, ", ".join(box_name(m, l["to"]) for l in ls))})
        for bid, ls in by_to.items():
            names = []
            for l in ls:
                n = box_name(m, l["from"])
                if n not in names:
                    names.append(n)
            out.setdefault(bid, []).append({"kind": kind, "lines": [l["id"] for l in ls],
                                            "text": "%s: %s" % (passive, ", ".join(names))})
    return out


def tag_layout(tags, width):
    """[(tag, wrapped lines, height)] for tags that are WIDTH px wide (the text keeps 6 px on each side)."""
    res = []
    for tg in tags:
        ls = textwrap.wrap(tg["text"], max(8, int((width - 12) / CH_SMALL)), break_long_words=True)
        res.append((tg, ls, 6 + TAG_LINE * len(ls)))
    return res


def tags_height(lay):
    return sum(h + 4 for _, _, h in lay) + (2 if lay else 0)


def tag_svg(box_id, lay, x, y, width):
    """The tags of one box, one below the other from (x, y); each is a box of its own inside the box."""
    out = []
    for tg, ls, h in lay:
        key = "%s|%s|%s" % (box_id, tg["kind"], ",".join(tg["lines"]))
        out.append('<g data-box="tag:%s" data-in="%s"><rect class="tg %s" x="%d" y="%d" width="%d" height="%d" rx="2"/>'
                   % (esc(key), esc(box_id), tg["kind"], x, y, width, h))
        for j, ln in enumerate(ls):
            out.append('<text class="sm tt" x="%d" y="%d">%s</text>' % (x + 6, y + 4 + TAG_LINE * j + 10, esc(ln)))
        out.append('</g>')
        y += h + 4
    return out


def svg_groups(m):
    tags = box_tags(m)
    labels = [g["label"] + " (module)" for g in m["groups"]]
    labels += [p["label"] for g in m["groups"] for p in g["parts"]]
    labels += [s["label"] for s in m["stores"]] + [o["label"] for o in m["outside"]]
    bw = max(tw(x) for x in labels) + 2 * PAD          # inner box width
    gw = bw + 2 * PAD                                    # group width
    cols, gap, margin = 3, 20, 20
    ph, pgap, head = 24, 6, 30
    W = margin * 2 + cols * gw + (cols - 1) * gap
    out = []
    y = margin
    out.append('<text x="%d" y="%d" class="h">Sagittarius: one repo, the modules of MODULES.json</text>'
               % (margin, y + 14))
    y += 26
    top = y
    y += PAD
    rows = [m["groups"][i:i + cols] for i in range(0, len(m["groups"]), cols)]
    for row in rows:
        def glay(g):
            return tag_layout(tags.get("group:" + g["id"], []), bw)

        def play(g):
            return [tag_layout(tags.get("part:" + p["id"], []), bw) for p in g["parts"]]
        rh = max(head + tags_height(glay(g)) + sum(ph + tags_height(l) + pgap for l in play(g)) + PAD for g in row)
        for ci, g in enumerate(row):
            gx = margin + ci * (gw + gap)
            gid = "group:" + g["id"]
            out.append('<g data-box="%s"><rect class="grp" x="%d" y="%d" width="%d" height="%d" rx="6"/>'
                       '<text class="lb" x="%d" y="%d">%s</text></g>'
                       % (esc(gid), gx, y, gw, rh, gx + PAD, y + 19, esc(g["label"] + " (module)")))
            py = y + head
            gl = glay(g)
            out += tag_svg(gid, gl, gx + PAD, py, bw)
            py += tags_height(gl)
            for p, pl in zip(g["parts"], play(g)):
                bh = ph + tags_height(pl)
                pid = "part:" + p["id"]
                out.append('<g data-box="%s" data-in="%s"><rect class="part" x="%d" y="%d" width="%d" height="%d" rx="3"/>'
                           '<text class="lb" x="%d" y="%d">%s</text></g>'
                           % (esc(pid), esc(gid), gx + PAD, py, bw, bh, gx + 2 * PAD, py + 16, esc(p["label"])))
                out += tag_svg(pid, pl, gx + PAD + 6, py + ph, bw - 12)
                py += bh + pgap
        y += rh + gap
    out.insert(1, '<rect class="repo" x="%d" y="%d" width="%d" height="%d" rx="8"/>'
               % (margin - 8, top - 4, W - 2 * margin + 16, y - top - gap + 12))
    y += 16
    # outside: a mindhole with the stores, then the other outside things
    out.append('<text x="%d" y="%d" class="h">Outside the repo</text>' % (margin, y + 14))
    y += 26
    sc = cols
    srows = [m["stores"][i:i + sc] for i in range(0, len(m["stores"]), sc)]
    mid_box = "outside:mindhole_stores"
    ml = tag_layout(tags.get(mid_box, []), W - 2 * margin - 2 * PAD)
    slays = [[tag_layout(tags.get(s["id"], []), bw) for s in row] for row in srows]
    sh = [max(ph + tags_height(l) for l in row) for row in slays]
    mh = head + tags_height(ml) + sum(h + pgap for h in sh) + PAD
    out.append('<g data-box="%s"><rect class="grp out" x="%d" y="%d" width="%d" height="%d" rx="6"/>'
               '<text class="lb" x="%d" y="%d">%s</text></g>'
               % (mid_box, margin, y, W - 2 * margin, mh, margin + PAD, y + 19,
                  esc("a mindhole (sidequest-mindhole, hwh-mindhole): the seven stores of store-facts.json")))
    py = y + head
    out += tag_svg(mid_box, ml, margin + PAD, py, W - 2 * margin - 2 * PAD)
    py += tags_height(ml)
    for row, rl, h in zip(srows, slays, sh):
        for ci, (s, l) in enumerate(zip(row, rl)):
            sx = margin + PAD + ci * (gw + gap)
            out.append('<g data-box="%s" data-in="%s"><rect class="part store" x="%d" y="%d" width="%d" height="%d" rx="3"/>'
                       '<text class="lb" x="%d" y="%d">%s</text></g>'
                       % (esc(s["id"]), mid_box, sx, py, bw, ph + tags_height(l), sx + PAD, py + 16, esc(s["label"])))
            out += tag_svg(s["id"], l, sx + 6, py + ph, bw - 12)
        py += h + pgap
    y += mh + gap
    orows = [m["outside"][i:i + cols] for i in range(0, len(m["outside"]), cols)]
    for row in orows:
        ols = [tag_layout(tags.get("outside:" + o["id"], []), gw) for o in row]
        oh = max(ph + tags_height(l) for l in ols)
        for ci, (o, l) in enumerate(zip(row, ols)):
            ox = margin + ci * (gw + gap)
            out.append('<g data-box="%s"><rect class="ext" x="%d" y="%d" width="%d" height="%d" rx="3"/>'
                       '<text class="lb" x="%d" y="%d">%s</text></g>'
                       % (esc("outside:" + o["id"]), ox, y, gw, ph + tags_height(l), ox + PAD, y + 16, esc(o["label"])))
            out += tag_svg("outside:" + o["id"], l, ox + 6, y + ph, gw - 12)
        y += oh + pgap
    y += 4
    out.append('<text x="%d" y="%d" class="h">Tags</text>' % (margin, y + 14))
    lx = margin + 50
    for kind, word in (("install", "installs, installed by (a link in ~, or a hub)"), ("creates", "creates, created by (a store)"),
                       ("writes", "writes, written by (a store)")):
        out.append('<rect class="tg %s" x="%d" y="%d" width="18" height="12" rx="2"/>' % (kind, lx, y + 4))
        out.append('<text class="lb" x="%d" y="%d">%s</text>' % (lx + 26, y + 14, esc(word)))
        lx += 26 + tw(word) + 24
        if lx > W - 200:
            lx = margin + 50
            y += 20
    y += 30
    H = y + margin
    return W, H, "\n".join(out)


VERB_CLASS = {"write": "w", "read": "r", "derive": "d", "carry": "c"}


def step_text(s):
    return "%s %s: %s" % (s["id"], "/".join(s["kinds"]), s["label"])


COMPACT_W = 346   # the width of the narrow flow view: it fits a frame of a 400 px window (less the scrollbar)
COMPACT_WRAP = 36


def svg_flow(m, compact=False):
    """Lanes side by side; one row for each step, top to bottom: the label on top, the arrow under
    it. The row of lane headers comes again every HEAD_EVERY steps. COMPACT: the narrow view for a
    window of 400 px: lanes of 37 px with a number, a key of the numbers above the first header, and
    a width of COMPACT_W px, so that no frame scrolls sideways."""
    lanes = m["lanes"]
    li = {l["id"]: i for i, l in enumerate(lanes)}

    def two(label):
        w = label.split(" ")
        best = None
        for i in range(1, len(w) + 1):
            a, b = " ".join(w[:i]), " ".join(w[i:])
            k = max(len(a), len(b))
            if best is None or k < best[0]:
                best = (k, a, b)
        return best[1], best[2]
    heads = [two(l["label"]) for l in lanes]
    mods = ["(%s)" % l.get("module", "") for l in lanes]
    lw = max(max(tw(a), tw(b), tw(c, CH_SMALL)) for (a, b), c in zip(heads, mods)) + 2 * PAD
    lgap = 6
    margin = 20
    wrap = WRAP
    if compact:
        margin, lgap, wrap = 10, 4, COMPACT_WRAP
        lw = (COMPACT_W - 2 * margin - (len(lanes) - 1) * lgap) // len(lanes)
    x0 = margin
    W = COMPACT_W if compact else x0 + len(lanes) * (lw + lgap) + margin
    texts = [textwrap.wrap(step_text(s), wrap, break_long_words=True) for s in m["steps"]]
    notes = [s.get("store_map", "") for s in m["steps"]]
    out, lifes = [], []
    y = margin
    out.append('<text x="%d" y="%d" class="h">The flow of the records over time</text>' % (margin, y + 14))
    y += 22
    for part in textwrap.wrap("One row for each step, top to bottom: what happens, then the arrow.",
                              int((W - 2 * margin) / CH_SMALL) if compact else 200):
        out.append('<text x="%d" y="%d" class="sm">%s</text>' % (margin, y + 12, esc(part)))
        y += 16
    y += 6
    if compact:
        for i, l in enumerate(lanes):
            for j, part in enumerate(textwrap.wrap("%d %s (%s)" % (i + 1, l["label"], l.get("module", "")),
                                                   int((W - 2 * margin) / CH) - 2)):
                out.append('<text class="lb" x="%d" y="%d">%s</text>' % (margin + (0 if j == 0 else 14), y + 12, esc(part)))
                y += LINE
        y += 6
    hh = 30 if compact else 62

    def header(y):
        if compact:
            for i, l in enumerate(lanes):
                x = x0 + i * (lw + lgap)
                out.append('<g data-box="lane:%s"><rect class="lane" x="%d" y="%d" width="%d" height="%d" rx="4"/>'
                           '<text class="lb" x="%d" y="%d">%d</text></g>'
                           % (esc(l["id"]), x, y, lw, hh, x + lw // 2 - 4, y + 19, i + 1))
            return y + hh + 8
        for i, l in enumerate(lanes):
            x = x0 + i * (lw + lgap)
            a, b = heads[i]
            out.append('<g data-box="lane:%s"><rect class="lane" x="%d" y="%d" width="%d" height="%d" rx="4"/>'
                       '<text class="lb" x="%d" y="%d">%s</text><text class="lb" x="%d" y="%d">%s</text>'
                       '<text class="sm" x="%d" y="%d">%s</text></g>'
                       % (esc(l["id"]), x, y, lw, hh, x + PAD, y + 17, esc(a), x + PAD, y + 35, esc(b),
                          x + PAD, y + 53, esc(mods[i])))
        return y + hh + 8
    seg_top = None
    for n, (s, t, note) in enumerate(zip(m["steps"], texts, notes)):
        if n % HEAD_EVERY == 0:
            if seg_top is not None:
                lifes.append((seg_top, y))
            y = header(y)
            seg_top = y - 8
        rh = 8 + LINE * len(t) + (16 if note else 0) + 20
        ry = y
        out.append('<g data-step="%s"><rect class="row" x="%d" y="%d" width="%d" height="%d"/>'
                   % (esc(s["id"]), margin, ry, W - 2 * margin, rh))
        for j, part in enumerate(t):
            out.append('<text class="lb" data-label="%s" x="%d" y="%d">%s</text>'
                       % (esc(s["id"]), margin + PAD + (0 if j == 0 else 4 * CH), ry + 16 + LINE * j, esc(part)))
        if note:
            out.append('<text class="sm mark" x="%d" y="%d">%s</text>' % (margin + PAD, ry + 15 + LINE * len(t), esc("! " + note)))
        if s["from"] in li and s["to"] in li:
            fx = x0 + li[s["from"]] * (lw + lgap) + lw // 2
            tx = x0 + li[s["to"]] * (lw + lgap) + lw // 2
            ay = ry + rh - 11
            d = 1 if tx > fx else -1
            cls = VERB_CLASS.get(s["verb"], "c")
            out.append('<line class="ar %s" x1="%d" y1="%d" x2="%d" y2="%d"/>' % (cls, fx, ay, tx - d * 7, ay))
            out.append('<path class="hd %s" d="M%d %d L%d %d L%d %d Z"/>'
                       % (cls, tx, ay, tx - d * 8, ay - 5, tx - d * 8, ay + 5))
            out.append('<circle class="dot" cx="%d" cy="%d" r="3"/>' % (fx, ay))
        out.append('</g>')
        y += rh + 4
    lifes.append((seg_top, y))
    lines = []
    for top, bot in lifes:
        for i in range(len(lanes)):
            cx = x0 + i * (lw + lgap) + lw // 2
            lines.append('<line class="life" x1="%d" y1="%d" x2="%d" y2="%d"/>' % (cx, top, cx, bot))
    out = out[:2] + lines + out[2:]
    y += 12
    legend = [("w", "write"), ("r", "read"), ("d", "derive"), ("c", "carry")]
    lx = margin
    for cls, word in legend:
        out.append('<line class="ar %s" x1="%d" y1="%d" x2="%d" y2="%d"/>' % (cls, lx, y + 6, lx + 30, y + 6))
        out.append('<text class="lb" x="%d" y="%d">%s</text>' % (lx + 38, y + 10, esc(word)))
        lx += 38 + tw(word) + 24
    y += 24
    for line in LEGEND_LINES:
        for part in textwrap.wrap(line, int((W - 2 * margin) / CH) - (1 if compact else 0)):
            out.append('<text class="lb" x="%d" y="%d">%s</text>' % (margin, y + 10, esc(part)))
            y += LINE
    H = y + 20
    return W, H, "\n".join(out)


LEGEND_LINES = [
    "derive: the tool computes it from the record; carry: words of a person, or a carrier (letter, handoff, proposal).",
    "An experiment is a check with its runs: each run (test_result) gives one verdict (meets, conflicts, unresolved). "
    "A judgment of the human is an experiment of the goal, with its own verdict (the step experiment/3, verdict/2 of the judgment).",
    "A Desk write goes through a queue: the Desk appends to answers.pending, and apply-pending writes kb.pl.",
]


CSS = """
:root { --bg:#ffffff; --fg:#1d232b; --muted:#5b6672; --line:#c9d1da; --grp:#f3f6fa; --part:#ffffff;
  --repo:#fbfcfe; --ext:#fff8ec; --store:#eef8f1; --w:#1f6feb; --r:#2f8a4c; --d:#8250df; --c:#9a6700;
  --row:#f6f8fa; --mark:#b42318; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg:#0f1419; --fg:#e6edf3;
  --muted:#9aa7b4; --line:#3a4654; --grp:#17202a; --part:#0f1419; --repo:#121a22; --ext:#2a2214;
  --store:#13261b; --w:#58a6ff; --r:#56d364; --d:#bc8cff; --c:#e3b341; --row:#161d25; --mark:#ff8a80;
  color-scheme: dark; } }
:root[data-theme="dark"] { --bg:#0f1419; --fg:#e6edf3; --muted:#9aa7b4; --line:#3a4654; --grp:#17202a;
  --part:#0f1419; --repo:#121a22; --ext:#2a2214; --store:#13261b; --w:#58a6ff; --r:#56d364; --d:#bc8cff;
  --c:#e3b341; --row:#161d25; --mark:#ff8a80; color-scheme: dark; }
html, body { background: var(--bg); color: var(--fg); margin: 0; }
body { font: 14px/1.45 system-ui, sans-serif; padding: 16px; }
main { max-width: 100%; }
h1 { font-size: 20px; margin: 0 0 6px; } h2 { font-size: 16px; margin: 24px 0 6px; }
p { margin: 4px 0 10px; color: var(--muted); max-width: 70em; }
.frame { overflow-x: auto; max-width: 100%; border: 1px solid var(--line); border-radius: 6px; }
svg { display: block; }
svg text { font-family: "DejaVu Sans Mono", "Liberation Mono", Menlo, Consolas, monospace; fill: var(--fg); }
svg .lb { font-size: 12px; } svg .sm { font-size: 11px; fill: var(--muted); } svg .mark { fill: var(--mark); }
svg .h { font-size: 13px; font-weight: 700; }
.repo { fill: var(--repo); stroke: var(--line); stroke-dasharray: 6 4; }
.grp { fill: var(--grp); stroke: var(--line); } .grp.out { fill: var(--bg); stroke-dasharray: 4 3; }
.part { fill: var(--part); stroke: var(--line); } .part.store { fill: var(--store); }
.ext { fill: var(--ext); stroke: var(--line); }
.lane { fill: var(--grp); stroke: var(--line); } .life { stroke: var(--line); stroke-dasharray: 3 3; }
.row { fill: var(--row); } .dot { fill: var(--muted); }
.ar { stroke-width: 2; } .ar.w { stroke: var(--w); } .ar.r { stroke: var(--r); stroke-dasharray: 6 3; }
.ar.d { stroke: var(--d); stroke-dasharray: 2 3; } .ar.c { stroke: var(--c); stroke-dasharray: 9 3 2 3; }
.hd.w { fill: var(--w); } .hd.r { fill: var(--r); } .hd.d { fill: var(--d); } .hd.c { fill: var(--c); }
table { border-collapse: collapse; font-size: 12px; } td, th { border: 1px solid var(--line); padding: 3px 6px; text-align: left; vertical-align: top; }
.tw { overflow-x: auto; max-width: 100%; }
.tg { stroke-width: 1; fill-opacity: .12; } .tg.install { stroke: var(--c); fill: var(--c); }
.tg.creates { stroke: var(--d); fill: var(--d); } .tg.writes { stroke: var(--w); fill: var(--w); }
.flow-narrow { display: none; } .flow-narrow svg { max-width: 100%; height: auto; }
@media (max-width: 760px) { .flow-wide { display: none; } .flow-narrow { display: block; } }
code { font-size: 12px; }
"""


def render_html(m):
    gW, gH, gs = svg_groups(m)
    fW, fH, fs = svg_flow(m)
    nW, nH, ns = svg_flow(m, compact=True)
    data = json.dumps(map_data(m), sort_keys=True, separators=(",", ":")).replace("</", "<\\/")
    rows = []
    for s in m["steps"]:
        rows.append("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s to %s</td><td>%s</td><td>%s</td></tr>" % (
            esc(s["id"]), esc("/".join(s["kinds"])), esc(s["verb"]), esc(s["from"]), esc(s["to"]),
            esc(s["label"] + ((" (" + s["store_map"] + ")") if s.get("store_map") else "")),
            "<br>".join("<code>%s</code>" % esc(src_text(x)) for x in s.get("sources", []))))
    lrows = []
    for l in m["lines"]:
        lrows.append("<tr><td><code>%s</code></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>" % (
            esc(l["id"]), esc(l["kind"]), esc(l["from"]), esc(l["to"]), esc(l["what"]),
            "<br>".join("<code>%s</code>" % esc(src_text(x)) for x in l["sources"])))
    brows = []
    for bid, src in boxes(m):
        brows.append("<tr><td><code>%s</code></td><td><code>%s</code></td></tr>" % (esc(bid), esc(src_text(src))))
    return (
        '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        '<title>Sagittarius map</title>\n<style>%s</style>\n</head>\n<body>\n<main>\n'
        '<h1>Sagittarius map: groups and flow</h1>\n'
        '<p>Made by <code>python3 kb/share/repo-map/views.py build</code> from MODULES.json, '
        'hubkit/tools/store-facts.json and kb/share/repo-map/sagittarius.views.json. Do not edit: '
        '<code>views.py check</code> goes red when this page differs from its sources.</p>\n'
        '<section id="v-groups">\n<h2>Groups view</h2>\n<p>Each module of MODULES.json is one group, with each part in the one '
        'module that covers its path (the except lists hold). What is outside the repo is drawn below it.</p>\n'
        '<div class="frame"><svg id="groups" xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
        'viewBox="0 0 %d %d" role="img" aria-label="Groups view">\n%s\n</svg></div>\n</section>\n'
        '<section id="v-flow">\n<h2>Flow view</h2>\n<p>One row for each step, in the order of time. An arrow goes from the '
        'part that acts to the part it writes or reads. A red mark names a step where the store map '
        '(store-facts.json) names another owner than the code writes to.</p>\n'
        '<div class="frame flow-wide"><svg id="flow" xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
        'viewBox="0 0 %d %d" role="img" aria-label="Flow view">\n%s\n</svg></div>\n'
        '<div class="frame flow-narrow"><svg id="flow-narrow" xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
        'viewBox="0 0 %d %d" role="img" aria-label="Flow view, narrow">\n%s\n</svg></div>\n</section>\n'
        '<section id="v-sources">\n<h2>What this map does not draw</h2>\n<ul>%s</ul>\n'
        '<h2>Sources of the lines of the groups view</h2>\n<div class="tw"><table><tr><th>line</th><th>kind</th><th>from</th>'
        '<th>to</th><th>what</th><th>sources (file, kind, name)</th></tr>\n%s\n</table></div>\n'
        '<h2>Sources of the arrows</h2>\n<div class="tw"><table><tr><th>step</th><th>kinds</th><th>verb</th>'
        '<th>from, to</th><th>what</th><th>sources (file, kind, name)</th></tr>\n%s\n</table></div>\n'
        '<h2>Sources of the boxes</h2>\n<div class="tw"><table><tr><th>box</th><th>source</th></tr>\n%s\n</table></div>\n</section>\n'
        '<script type="application/json" id="repo-map-data">%s</script>\n'
        '</main>\n</body>\n</html>\n'
    ) % (CSS, gW, gH, gW, gH, gs, fW, fH, fW, fH, fs, nW, nH, nW, nH, ns,
                                "".join("<li>%s</li>" % esc(x) for x in m["not_drawn"]), "\n".join(lrows), "\n".join(rows),
                                "\n".join(brows), data)


# ---------------------------------------------------------------- render: Markdown with Mermaid

def mid(s):
    return re.sub(r"[^A-Za-z0-9_]", "_", s)


def mlabel(s):
    return s.replace('"', "'").replace("#", "").replace(";", ",")


def md_node(bid):
    """The Mermaid node (or subgraph) id of a box id."""
    kind, _, name = bid.partition(":")
    if bid == "outside:mindhole_stores":
        return "mh"
    return {"group": "g_", "part": "p_", "outside": "o_"}.get(kind, "") + mid(bid if kind == "store" else name)


def render_md(m):
    L = ["# Sagittarius map: groups and flow", "",
         "Made by `python3 kb/share/repo-map/views.py build` from MODULES.json, "
         "hubkit/tools/store-facts.json and kb/share/repo-map/sagittarius.views.json. Do not edit: "
         "`views.py check` goes red when this file differs from its sources. The HTML page beside it "
         "(`%s`) draws the same views as SVG." % HTML_NAME, "",
         "## Groups view", "", "```mermaid", "flowchart TB"]
    L.append('  subgraph repo["Sagittarius: one repo"]')
    for g in m["groups"]:
        L.append('    subgraph g_%s["%s (module)"]' % (mid(g["id"]), mlabel(g["label"])))
        for p in g["parts"]:
            L.append('      p_%s["%s"]' % (mid(p["id"]), mlabel(p["label"])))
        L.append("    end")
    L.append("  end")
    L.append('  subgraph outside["Outside the repo"]')
    L.append('    subgraph mh["a mindhole: the seven stores"]')
    for s in m["stores"]:
        L.append('      %s["%s"]' % (mid(s["id"]), mlabel(s["label"])))
    L.append("    end")
    for o in m["outside"]:
        L.append('    o_%s["%s"]' % (mid(o["id"]), mlabel(o["label"])))
    L.append("  end")
    for l in m["lines"]:
        L.append("  %s -->|%s| %s" % (md_node(l["from"]), {"install": "installs", "creates": "creates", "writes": "writes"}[l["kind"]],
                                      md_node(l["to"])))
    L += ["```", "", "## Sources of the lines of the groups view", "",
          "| line | kind | from | to | what | sources (file, kind, name) |", "|---|---|---|---|---|---|"]
    for l in m["lines"]:
        L.append("| `%s` | %s | %s | %s | %s | %s |" % (
            l["id"].replace("|", "/"), l["kind"], l["from"], l["to"], l["what"].replace("|", "/"),
            "<br>".join("`%s`" % src_text(x).replace("|", "/") for x in l["sources"])))
    L += ["", "## Flow view", "", "```mermaid", "sequenceDiagram"]
    for l in m["lanes"]:
        L.append("  participant %s as %s (%s)" % (mid(l["id"]), mlabel(l["label"]), mlabel(l.get("module", ""))))
    arrow = {"write": "->>", "read": "-->>", "derive": "-->>", "carry": "-)"}
    for s in m["steps"]:
        L.append("  %s%s%s: %s" % (mid(s["from"]), arrow.get(s["verb"], "->>"), mid(s["to"]),
                                    mlabel("%s %s %s: %s" % (s["id"], s["verb"], "/".join(s["kinds"]), s["label"]))))
        if s.get("store_map"):
            L.append("  Note over %s: %s" % (mid(s["to"]), mlabel(s["store_map"])))
    L += ["```", "", "## Sources of the arrows", "",
          "| step | kinds | verb | from | to | what | sources (file, kind, name) |",
          "|---|---|---|---|---|---|---|"]
    for s in m["steps"]:
        L.append("| %s | %s | %s | %s | %s | %s | %s |" % (
            s["id"], "/".join(s["kinds"]), s["verb"], s["from"], s["to"],
            s["label"].replace("|", "/") + ((" (" + s["store_map"] + ")") if s.get("store_map") else ""),
            "<br>".join("`%s`" % src_text(x).replace("|", "/") for x in s.get("sources", []))))
    L += ["", "## What this map does not draw", ""] + ["- " + x for x in m["not_drawn"]]
    L += ["", "## Sources of the boxes", "", "| box | source |", "|---|---|"]
    for bid, src in boxes(m):
        L.append("| `%s` | `%s` |" % (bid, src_text(src).replace("|", "/")))
    L.append("")
    return "\n".join(L)


# ---------------------------------------------------------------- check

def read_committed_data(path):
    with open(path, encoding="utf-8") as f:
        t = f.read()
    m = re.search(r'<script type="application/json" id="repo-map-data">(.*?)</script>', t, re.S)
    if not m:
        return None, t
    return json.loads(m.group(1).replace("<\\/", "</")), t


def check(root, facts_path, out_dir):
    facts = load_facts(facts_path)
    m, errs = model(root, facts)
    files = git_files(root)
    cache = {}
    # c3: each box and arrow names a source that resolves
    for bid, src in boxes(m):
        if src is not None and src.get("kind") == "file":
            if src["file"] not in files and not any(x.startswith(src["file"].rstrip("/") + "/") for x in files):
                errs.append("box %s: the path %s is not in the commit" % (bid, src["file"]))
            continue
        r = resolve(root, files, src, cache)
        if r:
            errs.append("box %s: %s" % (bid, r))
    lane_ids = {l["id"] for l in m["lanes"]}
    kind_ids = {k["id"] for k in m["kinds"]}
    for l in m["lines"]:                        # c3 of the lines: each names sources, and each resolves
        if not l.get("sources"):
            errs.append("line %s: no source" % l["id"])
        for src in l.get("sources", []):
            r = resolve(root, files, src, cache)
            if r:
                errs.append("line %s: %s" % (l["id"], r))
    for s in m["steps"]:
        if not s.get("sources"):
            errs.append("arrow %s: no source" % s.get("id"))
        for src in s.get("sources", []):
            r = resolve(root, files, src, cache)
            if r:
                errs.append("arrow %s: %s" % (s["id"], r))
        for end in ("from", "to"):
            if s.get(end) not in lane_ids:
                errs.append("arrow %s: %s %s is not a lane" % (s["id"], end, s.get(end)))
        for k in s.get("kinds", []):
            if k not in kind_ids:
                errs.append("arrow %s: kind %s is not a kind of the flow view" % (s["id"], k))
    for k in m["kinds"]:
        for src in k.get("declared", []):
            r = resolve(root, files, src, cache)
            if r:
                errs.append("kind %s: %s" % (k["id"], r))
    # c2 (k2): each required kind has a write (or derive) arrow and a read arrow
    for k in REQUIRED_KINDS:
        if k not in kind_ids:
            errs.append("kind %s is required and is not a kind of the flow view" % k)
        w = [s for s in m["steps"] if k in s["kinds"] and s["verb"] in ("write", "derive")]
        r = [s for s in m["steps"] if k in s["kinds"] and s["verb"] in ("read", "carry")]
        if not w:
            errs.append("kind %s has no write arrow" % k)
        if not r:
            errs.append("kind %s has no read arrow" % k)
    # c4: each declared record kind is shown or left out with a reason
    decl = declared_kinds(root)
    shown = set()
    for k in m["kinds"]:
        for src in k.get("declared", []):
            if src.get("kind") in ("decl", "attest_type"):
                shown.add(src["name"])
    left = {}
    for grp in facts.get("left_out", []):
        if not grp.get("reason"):
            errs.append("a left_out group has no reason")
        for n in grp.get("names", []):
            left[n] = grp.get("reason")
    for n in sorted(decl):
        if n not in shown and n not in left:
            errs.append("%s %s is declared and the map neither shows it nor leaves it out with a reason"
                        % (decl[n], n))
    for n in sorted(left):
        if n not in decl:
            errs.append("left_out names %s, which is not declared" % n)
    # c4, c7: the committed map against the map that the sources give now
    hp = os.path.join(out_dir, HTML_NAME)
    mp = os.path.join(out_dir, MD_NAME)
    fresh_html, fresh_md = render_html(m), render_md(m)
    if not os.path.isfile(hp) or not os.path.isfile(mp):
        errs.append("the map is not built: %s or %s is missing" % (hp, mp))
    else:
        data, text = read_committed_data(hp)
        want = map_data(m)
        if data is None:
            errs.append("%s carries no map data" % hp)
        else:
            cg = {g["id"]: g for g in data.get("groups", [])}
            for g in want["groups"]:
                if g["id"] not in cg:
                    errs.append("module %s is not in the map" % g["id"])
                else:
                    for p in g["parts"]:
                        if p not in cg[g["id"]]["parts"]:
                            errs.append("part %s is not in group %s of the map" % (p, g["id"]))
            wg = {g["id"]: g for g in want["groups"]}
            for gid, g in cg.items():
                if gid not in wg:
                    errs.append("box group:%s in the map has no source" % gid)
                    continue
                for p in g.get("parts", []):
                    if p not in wg[gid]["parts"]:
                        errs.append("box part:%s in group %s of the map has no source there" % (p, gid))
            for key, what in (("stores", "store"), ("outside", "outside box"), ("lanes", "lane"),
                              ("kinds", "kind")):
                for x in want[key]:
                    if x not in data.get(key, []):
                        errs.append("%s %s is not in the map" % (what, x))
                for x in data.get(key, []):
                    if x not in want[key]:
                        errs.append("box %s:%s in the map has no source" % (what, x))
            wl = {l["id"] for l in want["lines"]}
            cl = {l["id"] for l in data.get("lines", [])}
            for x in sorted(wl - cl):
                errs.append("line %s is not in the map" % x)
            for x in sorted(cl - wl):
                errs.append("line %s in the map has no source" % x)
            ws = {s["id"] for s in want["steps"]}
            for s in data.get("steps", []):
                if s["id"] not in ws:
                    errs.append("arrow %s in the map has no source" % s["id"])
            # a box drawn in the SVG that the data does not list
            known = {b for b, _ in boxes(m)} | {"outside:mindhole_stores"}
            wt = {(x["box"], x["kind"], tuple(x["lines"])) for x in want["tags"]}
            ct = {(x["box"], x["kind"], tuple(x["lines"])) for x in data.get("tags", [])}
            for x in sorted(wt - ct):
                errs.append("tag %s of %s is not in the map" % (x[1], x[0]))
            for x in sorted(ct - wt):
                errs.append("tag %s of %s in the map has no source" % (x[1], x[0]))
            drawn = set()
            for tg in re.findall(r'data-box="tag:([^"]+)"', text):
                b, k, ids = html.unescape(tg).split("|", 2)
                drawn.add((b, k, tuple(ids.split(","))))
            for x in sorted(wt - drawn):
                errs.append("tag %s of %s is in the data and not drawn" % (x[1], x[0]))
            for x in sorted(drawn - wt):
                errs.append("tag %s of %s is drawn and has no source" % (x[1], x[0]))
            for b in re.findall(r'data-box="([^"]+)"', text):
                b = html.unescape(b)
                if b not in known and not b.startswith("tag:"):
                    errs.append("box %s in the map has no source" % b)
        for path, fresh in ((hp, fresh_html), (mp, fresh_md)):
            with open(path, encoding="utf-8") as f:
                if f.read() != fresh:
                    errs.append("stale: %s differs from what views.py build makes now" % path)
    return errs


# ---------------------------------------------------------------- trace (c5)

TRACE_QUERIES = [  # kind, query, the variable that names the record, the variables shown
    ("request", "request(R,_)", "R", []),
    ("goal", "goal(G,_,_,_)", "G", []),
    ("hypothesis", "hypothesis(H,_,_,_)", "H", []),
    ("premise", "premise(P,_,_)", "P", []),
    ("question", "question(Q,_,_)", "Q", []),
    ("answer", "answer(Q,_,B)", "Q", ["B"]),
    ("claim", "claim(C,_,_)", "C", []),
    ("check", "check(K,_)", "K", []),
    ("vote", "attest(A,vote,_,V,B,_)", "A", ["V", "B"]),
    ("run", "attest(A,test_result,K,result(_,_,X),_,_)", "A", ["K", "X"]),
    ("adoption", "attest(A,adoption,H,_,_,_)", "A", ["H"]),
    ("judgment", "attest(A,judgment,G,J,_,_)", "A", ["G", "J"]),
    ("verdict", "verdict(A,V)", "A", ["V"]),   # after run and judgment: its line names them
]


def kb_query(orbit, kb_dir, q):
    """The answers of query Q as dicts {variable: atom}; a binding that is not an atom is kept as text."""
    r = subprocess.run([orbit, "--dir", kb_dir, "query", q, "-n", "0"], capture_output=True, text=True)
    out = []
    for line in r.stdout.splitlines():
        line = line.strip()
        if not line or line == "false":
            continue
        out.append(dict(re.findall(r"\b([A-Z]\w*) = ([a-z][A-Za-z0-9_]*|'[^']*')", line)))
    if r.returncode not in (0, 1) or (r.stdout.strip() not in ("", "false") and not out):
        raise MapError("orbit-kb query %s failed: %s" % (q, (r.stderr or r.stdout).strip()[:200]))
    return out


def trace(root, facts_path, kb_dir):
    facts = load_facts(facts_path)
    steps = {s["id"]: s for s in facts.get("steps", [])}
    tmap = facts.get("trace", {})
    orbit = os.path.join(root, "kb", "bin", "orbit-kb")
    with open(os.path.join(kb_dir, "kb.pl"), encoding="utf-8") as f:
        lines = f.read().splitlines()
    first, times, actors = {}, {}, {}
    for i, line in enumerate(lines, 1):
        mm = re.match(r"([a-z_]+)\(([a-z][A-Za-z0-9_]*)\s*,", line)
        if mm:
            first.setdefault((mm.group(1), mm.group(2)), i)
            first.setdefault(("*", mm.group(2)), i)
        mm = re.match(r"attest\(([a-z][A-Za-z0-9_]*),.*'(\d{4}-\d\d-\d\dT[0-9:]+Z)'\)\.\s*$", line)
        if mm:
            times[mm.group(1)] = mm.group(2)
        mm = re.match(r"actor\(([a-z][A-Za-z0-9_]*),\s*([a-z_]+),", line)
        if mm:
            actors[mm.group(1)] = mm.group(2)
    judgments, runs = {}, {}
    recs, errs, counts = [], [], {}
    for kind, q, var, show in TRACE_QUERIES:
        rows = kb_query(orbit, kb_dir, q)
        counts[kind] = len(rows)
        if kind == "judgment":
            judgments = {r.get("A"): "G=%s J=%s" % (r.get("G"), r.get("J")) for r in rows}
        if kind == "run":
            runs = {r.get("A"): "K=%s X=%s" % (r.get("K"), r.get("X")) for r in rows}
        n_req = 0
        for r in rows:
            rid = r.get(var)
            sid = tmap.get(kind)
            if kind == "request":
                sid = (sid or [None, None])[0 if n_req == 0 else 1]
                n_req += 1
            if kind in ("adoption", "judgment") and actors.get(rid) == "desk":
                sid = tmap.get(kind + "_desk")
            if kind == "verdict" and rid in judgments:
                sid = tmap.get("verdict_of_judgment")
            if sid not in steps or kind not in steps[sid]["kinds"]:
                errs.append("%s %s is on no arrow of the flow view" % (kind, rid))
                continue
            src = {"answer": "answer"}.get(kind)
            line = first.get((src, rid)) if src else first.get(("*", rid))
            if line is None:
                errs.append("%s %s has no line in kb.pl" % (kind, rid))
                continue
            detail = " ".join("%s=%s" % (v, r.get(v, "?")) for v in show)
            if kind == "verdict":
                detail = (runs.get(rid) or judgments.get(rid) or "?") + " " + detail
            recs.append((line, 1 if kind == "verdict" else 0, kind, rid, sid, times.get(rid, ""), detail))
    # a verdict of a judgment comes after the judgment, which may appear later in the file
    recs.sort()
    last_t = ""
    out = []
    for line, _, kind, rid, sid, t, detail in recs:
        if t and last_t and t < last_t:
            errs.append("the time of %s %s (%s) goes back before %s" % (kind, rid, t, last_t))
        if t and kind != "verdict":
            last_t = t
        s = steps[sid]
        out.append("line %-4d %-10s %-6s %-20s %s %s->%s: %s%s" % (
            line, kind, rid, t or "-", sid, s["from"], s["to"], s["label"], ("  [" + detail + "]") if detail else ""))
    summary = "counts: " + ", ".join("%s %d" % (k, counts[k]) for k, _, _, _ in TRACE_QUERIES)
    return out, summary, errs


# ---------------------------------------------------------------- main

def main(argv):
    ap = argparse.ArgumentParser(prog="views.py", description=__doc__.split("\n\n")[0])
    ap.add_argument("cmd", choices=["build", "check", "trace", "data"])
    ap.add_argument("kb_dir", nargs="?")
    ap.add_argument("--root", default=DEFAULT_ROOT)
    ap.add_argument("--facts")
    ap.add_argument("--out")
    a = ap.parse_args(argv)
    root = os.path.abspath(a.root)
    facts_path = a.facts or os.path.join(root, FACTS_REL)
    out_dir = a.out or os.path.join(root, OUT_REL)
    try:
        if a.cmd == "build":
            m, errs = model(root, load_facts(facts_path))
            if errs:
                for e in errs:
                    print("views.py: " + e, file=sys.stderr)
                return 1
            os.makedirs(out_dir, exist_ok=True)
            for name, text in ((HTML_NAME, render_html(m)), (MD_NAME, render_md(m))):
                with open(os.path.join(out_dir, name), "w", encoding="utf-8", newline="\n") as f:
                    f.write(text)
                print(os.path.join(out_dir, name))
            return 0
        if a.cmd == "data":
            m, errs = model(root, load_facts(facts_path))
            print(json.dumps(map_data(m), indent=1, sort_keys=True))
            return 1 if errs else 0
        if a.cmd == "check":
            errs = check(root, facts_path, out_dir)
            for e in errs:
                print("FAIL " + e)
            print("views check: %s (%d problems)" % ("red" if errs else "green", len(errs)))
            return 1 if errs else 0
        if a.cmd == "trace":
            if not a.kb_dir:
                print("views.py trace: give the directory of a spec KB", file=sys.stderr)
                return 2
            out, summary, errs = trace(root, facts_path, os.path.abspath(a.kb_dir))
            for l in out:
                print(l)
            print(summary)
            for e in errs:
                print("FAIL " + e)
            print("trace: %s (%d records, %d problems)" % ("red" if errs else "green", len(out), len(errs)))
            return 1 if errs else 0
    except (MapError, OSError, ValueError, KeyError) as e:
        print("views.py: %s" % e, file=sys.stderr)
        return 2
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

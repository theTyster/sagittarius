#!/usr/bin/env python3
"""Review checks for the merge of the discovery orbit into the build-orbit draft.

The ticket record is thoughts/orbital-shifting-merge-record.md (WIFFLED). The checks were
written before the merge (FLIGHT MANIFEST).

Usage:
  python3 -I thoughts/orbital-shifting-merge-check.py [DRAFT]
  python3 -I thoughts/orbital-shifting-merge-check.py --discriminate [DRAFT]
  python3 -I thoughts/orbital-shifting-merge-check.py --discriminate-merged [DRAFT]

DRAFT defaults to thoughts/orbital-shifting-system-prompt-draft.md.
- M checks are new behavior. Each one fails on the draft before the merge (the red run).
- F checks are frame checks. Each one passes before the merge. --discriminate runs each
  F check on a copy of DRAFT with the guarded text changed. There, each F check must fail.
- --discriminate-merged runs after the merge: it breaks the merged text that an M check
  reads, and that M check must fail.
Exit 0 when every check (or, with --discriminate, every discriminator) gives the expected
result. Exit 1 otherwise.
"""
import hashlib
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DRAFT_DEFAULT = os.path.join(ROOT, "thoughts/orbital-shifting-system-prompt-draft.md")
DISC = os.path.join(ROOT, "thoughts/discovery-orbit/discovery-orbit-draft.md")
DISC_SHA = "02e849801181c307"  # the ratified discovery draft, commit d46dd23
MODULE = os.path.join(ROOT, "shared/link/.local/share/orbit-kb/modules/discovery.pl")
MODULE_SHA = "41866cf20122a9cf"
CHECKER = os.path.join(ROOT, "thoughts/discovery-orbit/discovery-orbit-examples/"
                             "orbit-kb-staging/harness/check_draft.py")

# The one edit of Part 1 that the merge makes (finding F1 of the record): new text -> old text.
PART1_EDITS = [
    ("- The build orbit uses the same KB, and skips SURVEY. Add the build module first.",
     "- The build orbit uses the same KB, and skips SURVEY."),
]

# Sections that the merge must not change: (level, title) -> sha256 prefix of the own text
# of the section (its heading and body, up to its first subsection), with trailing
# whitespace removed. The hashes are of the draft before the merge (Ty's edits and D10).
FRAME = {}  # filled below


def sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def prompt_part(text):
    """The prompt: the text before the design notes, without the --- line before them."""
    i = text.find("\n# Design notes")
    p = (text if i < 0 else text[:i]).rstrip()
    return p[:-4].rstrip() if p.endswith("\n---") else p


def notes_part(text):
    i = text.find("\n# Design notes")
    return "" if i < 0 else text[i:]


def headings(lines):
    """(index, level, title) of each heading line outside code fences."""
    out, fence = [], False
    for i, line in enumerate(lines):
        if line.startswith("```"):
            fence = not fence
            continue
        m = re.match(r"(#+) (.*)$", line)
        if m and not fence:
            out.append((i, len(m.group(1)), m.group(2).strip()))
    return out


def title_matches(h, title):
    return h == title or h.startswith(title + ":") or h.startswith(title + " (")


def section(text, title, level, own=False):
    """The section with this heading, up to the next heading of the same or a higher level.
    With own=True, up to the first heading of any level (the own text only)."""
    lines = text.split("\n")
    hs = headings(lines)
    for n, (i, lv, h) in enumerate(hs):
        if lv == level and title_matches(h, title):
            end = len(lines)
            for (j, lv2, _) in hs[n + 1:]:
                if own or lv2 <= lv:
                    end = j
                    break
            return "\n".join(lines[i:end]).rstrip()
    return None


def part1_original():
    raw = open(DISC, encoding="utf-8").read()
    if sha(raw) != DISC_SHA:
        sys.exit(f"the discovery draft changed: sha256 {sha(raw)}, expected {DISC_SHA}")
    a = raw.index("# Part 1: prompt text\n") + len("# Part 1: prompt text\n")
    b = raw.index("\n---\n\n# Part 2")
    return raw[a:b].strip()


def merged_discovery(prompt):
    """The discovery text of the merged prompt, in the order of Part 1, or None."""
    orbit = section(prompt, "Discovery orbit", 2)
    module = section(prompt, "Discovery module", 3)
    if orbit is None or module is None:
        return None
    k = orbit.find("\n### Honesty rules for discovery")
    if k < 0:
        return None
    return orbit[:k].strip() + "\n\n" + module.strip() + "\n\n" + orbit[k:].strip()


# ---------------------------------------------------------------- the checks
def m1_part1_preserved(text, prompt):
    d = merged_discovery(prompt)
    if d is None:
        return False, "no Discovery orbit section, Discovery module subsection, or honesty rules"
    for new, old in PART1_EDITS:
        d = d.replace(new, old)
    orig = part1_original()
    if d == orig:
        return True, "the discovery text equals Part 1, apart from the listed edits"
    import difflib
    diff = list(difflib.unified_diff(orig.split("\n"), d.split("\n"), "Part 1", "merged", n=0))
    return False, "differences from Part 1:\n      " + "\n      ".join(diff[:30])


def m2_scope(text, prompt):
    s = section(prompt, "Scope", 2) or ""
    bad = []
    if "research" in s:
        bad.append("'research' is still routed to a direct answer")
    if not re.search(r"report.{0,80}discovery orbit", s, re.S):
        bad.append("a report is not routed to the discovery orbit")
    if not re.search(r"clear request.{0,40}build orbit", s, re.S):
        bad.append("a clear request is not routed to the build orbit")
    if "the human's request is the ticket" not in s:
        bad.append("the ticket definition is gone")
    return not bad, "; ".join(bad) or "questions, reports, and clear requests each have a route"


def m3_back_to_discovery(text, prompt):
    """Step 1 still records the divergence (Ty: "Record every divergence."). A later step
    sends a wrong problem back to discovery, before the steps that rebuild."""
    s = section(prompt, "When the human says that it is wrong", 2) or ""
    steps = {int(n): body for n, body in re.findall(r"^(\d+)\. (.*?)(?=^\d+\. |^\S|\Z)", s, re.M | re.S)}
    disc = [n for n, b in steps.items() if "discovery" in b and "problem" in b]
    ans = [n for n, b in steps.items() if b.startswith("Record the human's answer")]
    bad = []
    if not steps.get(1, "").startswith("Record a divergence"):
        bad.append("step 1 does not record the divergence")
    if not disc:
        bad.append("no step sends a wrong problem back to discovery")
    elif not ans or disc[0] > ans[0]:
        bad.append("the discovery step does not come before the rebuild steps")
    return not bad, "; ".join(bad) or f"step {disc[0]} sends a wrong problem back to discovery"


def m4_shared_moves(text, prompt):
    lines = prompt.split("\n")
    sv = next((h for (_, lv, h) in headings(lines) if lv == 3 and h.startswith("SURVEY")), "")
    dp = next((h for (_, lv, h) in headings(lines) if lv == 3 and h.startswith("DISPROVE")), "")
    survey = section(prompt, "SURVEY", 3) or ""
    bad = [x for x, ok in [("SURVEY heading not marked shared", "shared" in sv),
                           ("DISPROVE heading not marked shared", "shared" in dp),
                           ("SURVEY does not say to skip it when discovery ran",
                            "discovery ran" in survey)] if not ok]
    return not bad, "; ".join(bad) or "SURVEY and DISPROVE are marked shared"


def m5_module_place(text, prompt):
    kb = section(prompt, "The knowledge base", 2) or ""
    i, j = kb.find("\n### Build module"), kb.find("\n### Discovery module")
    ok = 0 <= i < j
    return ok, ("Discovery module follows Build module in The knowledge base" if ok
                else "Discovery module is not after Build module in The knowledge base")


def m6_honesty_shared(text, prompt):
    s = section(prompt, "Honesty rules", 2) or ""
    ok = "both orbits" in s
    return ok, "the shared honesty rules say that they apply to both orbits" if ok else "not marked shared"


def kb_rules(prompt):
    return section(prompt, "Rules for the KB", 3) or ""


def bullets(s):
    return re.findall(r"^- (.*?)(?=^- |\Z)", s, re.M | re.S)


def m7_digest(text, prompt):
    ok = "$(orbit-kb subject" in kb_rules(prompt)
    return ok, "the digest rule shows how to pass a digest into a fact" if ok else "no shell form"


def m8_resume(text, prompt):
    b = next((x for x in bullets(kb_rules(prompt)) if "When you resume" in x), "")
    ok = "orbit-kb lint" in b and "discovery" in b
    return ok, "the resume step also runs lint for discovery" if ok else f"resume bullet: {b[:80]!r}"


def m9_module_handoff(text, prompt):
    rules = kb_rules(prompt)
    bad = []
    mod = next((x for x in bullets(rules) if "first line" in x and "uses([" in x), "")
    if not (mod and "orbit-kb lint" in mod):
        bad.append("no rule to add a module on line 1, then lint")
    kbsec = section(prompt, "The knowledge base", 2, own=True) or ""
    m = re.search(r"Do not edit `kb\.pl` by hand[^.]*\.", kbsec)
    if not (m and "except" in m.group(0)):
        bad.append("the no-hand-edit rule has no stated exception")
    hand = section(prompt, "Handoff to the build orbit", 3) or ""
    if "build module" not in hand:
        bad.append("the handoff does not add the build module")
    wrong = section(prompt, "When the human says that it is wrong", 2) or ""
    if "discovery module" not in wrong:
        bad.append("the way back to discovery does not add the discovery module")
    return not bad, "; ".join(bad) or "both handoffs add the module of the new orbit"


def m10_z3_only(text, prompt):
    other = re.findall(r"cvc5|CVC|Yices|Apalache|Bitwuzla|MathSAT|second solver", prompt)
    ok = "Z3" in prompt and not other
    return ok, "Z3 is the only solver" if ok else f"Z3 present: {'Z3' in prompt}; others: {other}"


def m11_check_draft(text, prompt):
    d = merged_discovery(prompt)
    if d is None:
        return False, "no discovery text to check"
    for path, want in [(MODULE, MODULE_SHA)]:
        if sha(open(path, encoding="utf-8").read()) != want:
            return False, f"{path} changed"
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as fh:
        fh.write("# Part 1\n\n" + d + "\n\n# Part 2\n")
    try:
        r = subprocess.run([sys.executable, "-I", CHECKER, fh.name, MODULE],
                           capture_output=True, text=True)
    finally:
        os.unlink(fh.name)
    out = " | ".join(line for line in r.stdout.split("\n") if line)
    return r.returncode == 0, out


def m12_notes(text, prompt):
    n = notes_part(text)
    prov = section(n, "Where each part comes from", 2) or ""
    bad = [x for x, ok in [("the stale note 'still slow on it' is still there",
                            "still slow on it" not in n),
                           ("no provenance row for the discovery merge",
                            "discovery-orbit-draft.md" in prov)] if not ok]
    return not bad, "; ".join(bad) or "the design notes are current"


def m13_prove_row(text, prompt):
    ok = "orbit-kb prove" in (section(prompt, "Commands", 3) or "")
    return ok, "the command table has orbit-kb prove" if ok else "no prove row"


def m14_vocabulary(text, prompt):
    s = section(prompt, "Core vocabulary", 3) or ""
    miss = [x for x in ("`universal(", "`ticket(") if x not in s]
    return not miss, f"missing {miss}" if miss else "universal and ticket are in the core vocabulary"


MOVES = ["SURVEY", "DECOMPOSE", "BUILD", "CHECK", "DISPROVE", "BURN", "EXPLAIN",
         "SIGNAL", "SPECTRUM", "FLYBY", "TRAJECTORY"]


def m15_references(text, prompt):
    """Each quoted section reference and each move name has a heading. Part 1's own
    reference to "Ask first, or build on defaults" must be among them (not vacuous)."""
    titles = [h for (_, _, h) in headings(prompt.split("\n"))]
    # A reference can wrap to the next line: normalize its white space.
    refs = [" ".join(r.split()) for r in re.findall(r'(?:see|as in|section) "([^"]+)"', prompt)]
    bad = sorted({r for r in refs if not any(title_matches(h, r) for h in titles)})
    named = [m for m in MOVES if re.search(r"\b" + m + r"\b", prompt)]
    bad += [m for m in named if not any(h == m or h.startswith(m + ":") for h in titles)]
    if "Ask first, or build on defaults" not in refs:
        bad.append("Part 1's reference to \"Ask first, or build on defaults\" is missing")
    return not bad, f"{len(refs)} section references, {len(named)} move names; unresolved: {bad}"


def f1_frame(text, prompt):
    changed = []
    for (lv, title), want in FRAME.items():
        s = section(prompt, title, lv, own=True)
        got = sha(s) if s is not None else "missing"
        if got != want:
            changed.append(f"{'#' * lv} {title} ({got})")
    return not changed, f"changed: {changed}" if changed else f"{len(FRAME)} sections unchanged"


def f2_referenced(text, prompt):
    want = {("DECOMPOSE", 3): ["`preserve`", "`retire`", "`introduce`", "cites", "drift", "dormant"],
            ("Ask first, or build on defaults", 3): ["maximum of three questions",
                                                     "concrete options", "mark your default"],
            ("SURVEY", 3): ["closed-world"],
            ("DISPROVE", 3): ["`refuted`", "`inconclusive`", "`abstained`"],
            ("Speed", 2): ["subagent on a fast model"]}
    miss = []
    for (title, lv), words in want.items():
        s = section(prompt, title, lv) or ""
        miss += [f"{title}: {w}" for w in words if w not in s]
    return not miss, f"missing: {miss}" if miss else "the sections that Part 1 points at hold what it needs"


CHECKS = [("M1", "R1", m1_part1_preserved), ("M2", "R2", m2_scope),
          ("M3", "R3", m3_back_to_discovery), ("M4", "R4", m4_shared_moves),
          ("M5", "R5", m5_module_place), ("M6", "R6", m6_honesty_shared),
          ("M7", "R7", m7_digest), ("M8", "R8", m8_resume), ("M9", "R14", m9_module_handoff),
          ("M10", "R11", m10_z3_only), ("M11", "R12", m11_check_draft), ("M12", "R13", m12_notes),
          ("M13", "R15", m13_prove_row), ("M14", "R16", m14_vocabulary),
          ("M15", "R17", m15_references),
          ("F1", "R9 R10", f1_frame), ("F2", "R6", f2_referenced)]

# "The knowledge base" is not in the frame: its first paragraph gets the one exception to
# "Do not edit kb.pl by hand" (R14, checked by M9). SURVEY, DISPROVE, Scope, "Rules for the
# KB", "Commands", "Core vocabulary", and "When the human says that it is wrong" change on
# purpose (M2 to M9, M13, M14).
FRAME.update({
    (2, "Purpose"): "5505d4c8808f8b14",
    (2, "Roles"): "dbd2800e7418891a",
    (2, "The orbit"): "15b7ac0c4f037690",
    (3, "Reading the answers"): "92d1e9437b9007a5",
    (3, "Build module"): "ec81bcdbaf954d91",
    (3, "DECOMPOSE"): "15423d06f98a9cd4",
    (3, "Ask first, or build on defaults"): "754828c22d36e58b",
    (3, "BUILD"): "09bb6749a4bfa783",
    (3, "CHECK"): "5fd56d5ec6006d6c",
    (3, "BURN"): "843fc0dab6034e44",
    (3, "EXPLAIN"): "99730112906726eb",
    (2, "Delivery"): "a6bd431905407107",
    (2, "Speed"): "72ffb6113f4f62a2",
})


def run(path):
    text = open(path, encoding="utf-8").read()
    prompt = prompt_part(text)
    res = {}
    for cid, req, fn in CHECKS:
        ok, msg = fn(text, prompt)
        res[cid] = ok
        print(f"{'ok  ' if ok else 'FAIL'}  {cid:<4} {req:<7} {msg}")
    return res


# Each discriminator changes the text that one F check guards. The F check must then fail.
MUTANTS = [
    ("F1", "Ty's Roles line 3 loses a sentence",
     lambda t: t.replace(" Remember that speed to delivery is always something that should be weighed.", "")),
    ("F1", "the BURN section loses 'Always.'",
     lambda t: t.replace("A burn needs a proof. Always.", "A burn needs a proof.")),
    ("F1", "the Parallax paragraph loses its last sentence",
     lambda t: t.replace("vacuity are often the predators of clarity, accuracy, and honesty. Record every divergence.",
                         "vacuity are often the predators of clarity, accuracy, and honesty.")),
    ("F2", "DECOMPOSE loses the drift rule",
     lambda t: t.replace("A claim with no citation is drift.", "A claim needs a citation.")),
    ("F2", "Ask first loses the three-question cap",
     lambda t: t.replace("Ask a maximum of three questions in one round.", "Ask in rounds.")),
]


# After the merge: each mutant breaks the merged text that one M check reads. The M check
# must then fail. This shows that the M checks fail on wrong merged text, not only on
# missing text (their red run).
MERGED_MUTANTS = [
    ("M1", "one word of Part 1 changes",
     lambda t: t.replace("three laps by default", "four laps by default")),
    ("M11", "a Facts row loses an argument",
     lambda t: t.replace("| `model_run(Log, M, Digest)` |", "| `model_run(Log, M)` |")),
    ("M9", "the module rule leaves Rules for the KB",
     lambda t: re.sub(r"\n- To add a module,.*?(?=\n- |\n\n)", "", t, flags=re.S)),
    ("M3", "the discovery step comes after the rebuild steps",
     lambda t: re.sub(r"(\n2\. If the problem itself is wrong.*?)(\n3\. .*?)(?=\n4\. )",
                      lambda m: m.group(2).replace("\n3. ", "\n2. ") + m.group(1).replace("\n2. ", "\n3. "),
                      t, flags=re.S)),
    ("M10", "a second solver is named",
     lambda t: t.replace("Use Z3 through its Python API", "Use Z3 or cvc5 through its Python API")),
    ("M15", "a section reference does not resolve",
     lambda t: t.replace('(see "Rules for the KB")', '(see "Rules for KBs")')),
    ("M15", "a wrapped section reference does not resolve",
     lambda t: re.sub(r'\(see "Back to(\s+)discovery"\)', r'(see "Back to\1orbit")', t)),
]


def discriminate(path, mutants=None):
    text = open(path, encoding="utf-8").read()
    fns = {cid: fn for cid, _, fn in CHECKS}
    good = True
    for cid, what, mutate in (MUTANTS if mutants is None else mutants):
        t2 = mutate(text)
        if t2 == text:
            print(f"FAIL  {cid} mutant '{what}' did not change the text")
            good = False
            continue
        ok, msg = fns[cid](t2, prompt_part(t2))
        print(f"{'ok  ' if not ok else 'FAIL'}  {cid} fails on the mutant '{what}': {msg[:90]}")
        good &= not ok
    return good


if __name__ == "__main__":
    modes = {"--discriminate", "--discriminate-merged"}
    args = [a for a in sys.argv[1:] if a not in modes]
    path = args[0] if args else DRAFT_DEFAULT
    if "--discriminate" in sys.argv[1:]:
        sys.exit(0 if discriminate(path) else 1)
    if "--discriminate-merged" in sys.argv[1:]:
        sys.exit(0 if discriminate(path, MERGED_MUTANTS) else 1)
    res = run(path)
    sys.exit(0 if all(res.values()) else 1)

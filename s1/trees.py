"""The short decision trees of the candidate questions of System 1 (scientific-method-overhaul
c30 to c33): how each tree is asked, and the rule that reads its answers. Python 3 standard
library only. No call to the model is made here.

The questions are in s1/questions.candidate.json. None ships until a replay experiment gives the
verdict meets (c35, s1/REPLAY.md). stop.py and replay.py use these functions; the tests give them
fixture answers (test_trees.py).

    requests (c33)    r_count first, then r_kind and r_goal for each part of the message
    dispute (c31)     x_dispute first, then x_kind
    difference (c32)  y_differs for each pair of current hypotheses
    drift (c30)       d_success first, then d_kept and d_revised for each prediction (the stop event)

An answer in the unsure band (jev.band; a choice under P 0.5) never gives a hint.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
import sys  # noqa: E402
sys.path.insert(0, HERE)
import jev  # noqa: E402

CANDIDATES = os.path.join(HERE, "questions.candidate.json")
CHOICE_MIN = 0.5  # as hook.CHOICE_MIN
KINDS = ("goal", "hypothesis", "judgment", "answer", "decision", "task")
COUNTS = {"none": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five_or_more": 5}
FORMAL = ("prolog", "lean", "z3", "tlaplus")
PROMPT_IDS = ("r_count", "r_kind", "r_goal", "x_dispute", "x_kind", "y_differs")
STOP_IDS = ("d_success", "d_kept", "d_revised")
MAX_PREDICTIONS = 12  # the stop event asks about at most this many predictions
MAX_PAIRS = 3  # pairs of hypotheses compared in one call
QUOTE = 120  # characters of a prediction that a hint quotes


def load(path=CANDIDATES):
    """The question entries of a file (the keys that start with _ are notes, not questions)."""
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    return {k: v for k, v in d.items() if not k.startswith("_")}


def promoted(questions, ids):
    """True when every id of a tree is in the question set that ships."""
    return all(i in questions for i in ids)


def _noul(a):
    """(band, p) of a noul answer, or ("unsure", None) for none or a malformed one."""
    p = a.get("noul") if isinstance(a, dict) else None
    if isinstance(p, bool) or not isinstance(p, (int, float)) or not 0 <= p <= 1:
        return "unsure", None
    return jev.band(p), float(p)


def _choice(a):
    """(choice, p) at P >= CHOICE_MIN, else None."""
    if not isinstance(a, dict) or not isinstance(a.get("choice"), str):
        return None
    probs, c = a.get("probabilities"), a["choice"]
    p = probs.get(c) if isinstance(probs, dict) and c in probs else a.get("confidence")
    if isinstance(p, bool) or not isinstance(p, (int, float)):
        return None
    return (c, float(p)) if p >= CHOICE_MIN else None


def _with(q, **paths):
    q = dict(q)
    for k, v in paths.items():
        q["instructions"] = q["instructions"].replace("{" + k + "}", f"`{v}`")
    return q


# --- requests (c33): how many, the kind of each, the goal of each ---

def ask_requests(tree, parts, record=None):
    """The questions of the tree for a message cut into parts (state["sentences"])."""
    out = {"r_count": tree["r_count"]}
    goals = (record or {}).get("goal_sentences") or []
    for k in range(len(parts)):
        out[f"r_kind@{k}"] = _with(tree["r_kind"], part=f"sentences[{k}]")
        if goals and "r_goal" in tree:
            q = _with(tree["r_goal"], part=f"sentences[{k}]")
            q["criteria"] = {**{f"g{i}": g["text"] for i, g in enumerate(goals)},
                             "none": tree["r_goal"]["criteria"]["none"]}
            out[f"r_goal@{k}"] = q
    return out


def read_requests(answers, parts, record=None):
    """{"count": N or None, "requests": [{"part", "kind", "goal", "text"}], "part": line part or None}.
    The count comes first: a sure "none" ends the tree. A request is a part whose kind is sure;
    a part that continues the request before it ("more") is added to its text. goal is a goal id,
    "none" (it serves none), or None (not asked, or unsure)."""
    answers = answers or {}
    c = _choice(answers.get("r_count"))
    count = COUNTS.get(c[0]) if c else None
    if count == 0:
        return {"count": 0, "requests": [], "part": None}
    goals = (record or {}).get("goal_sentences") or []
    reqs = []
    for k, text in enumerate(parts):
        kind = _choice(answers.get(f"r_kind@{k}"))
        if kind and kind[0] in KINDS:
            goal = None
            g = _choice(answers.get(f"r_goal@{k}"))
            if g and g[0] == "none":
                goal = "none"
            elif g and g[0][1:].isdigit() and int(g[0][1:]) < len(goals):
                goal = goals[int(g[0][1:])]["id"]
            reqs.append({"part": k, "last": k, "kind": kind[0], "goal": goal, "text": text})
        elif kind and kind[0] == "more" and reqs and reqs[-1]["last"] == k - 1:
            reqs[-1]["text"] += " " + text
            reqs[-1]["last"] = k
    for r in reqs:
        del r["last"]
    if not reqs and not count:
        return {"count": count, "requests": [], "part": None}

    def one(r):
        return r["kind"] + ("" if r["goal"] is None else " for no goal" if r["goal"] == "none" else f" for {r['goal']}")
    named = "; ".join(one(r) for r in reqs) or "none named"
    n = len(reqs)
    agree = count is None or count == n or (count == 5 and n >= 5)
    head = f"requests: {n}" if agree else f"requests: {count if count < 5 else '5 or more'} by count, {n} named"
    return {"count": count, "requests": reqs, "part": f"{head} ({named})"}


# --- dispute (c31): which kind ---

def ask_dispute(tree):
    return {"x_dispute": tree["x_dispute"], "x_kind": tree["x_kind"]}


def read_dispute(answers):
    """{"kind": "outputs" | "wanted" | None, "tool": name or None, "part": line part or None}.
    x_dispute first: only in the yes band does the kind count. outputs: a formal tool can settle
    it, and the part names one (the choice of h_language when it is a formal tool, else its most
    likely formal tool, else prolog: a query). wanted: the human must judge the case. An answer in
    the unsure band gives neither."""
    answers = answers or {}
    none = {"kind": None, "tool": None, "part": None}
    if _noul(answers.get("x_dispute"))[0] != "yes":
        return none
    k = _choice(answers.get("x_kind"))
    if not k or k[0] not in ("outputs", "wanted"):
        return none
    if k[0] == "wanted":
        return {"kind": "wanted", "tool": None,
                "part": "dispute: the output is agreed, and the human has not judged it: it needs a judgment of that case by the human"}
    lang = answers.get("h_language") if isinstance(answers.get("h_language"), dict) else {}
    probs = lang.get("probabilities") if isinstance(lang.get("probabilities"), dict) else {}
    tool = lang.get("choice") if lang.get("choice") in FORMAL else None
    if tool is None:
        best = max(FORMAL, key=lambda t: probs.get(t, 0) if isinstance(probs.get(t), (int, float)) else 0)
        tool = best if isinstance(probs.get(best), (int, float)) and probs[best] > 0 else "prolog"
    return {"kind": "outputs", "tool": tool,
            "part": f"dispute: the inputs and the rule are agreed, the outputs differ: a formal tool can settle it ({tool})"}


# --- difference (c32): two current hypotheses of one goal ---

def pairs(record, seen=()):
    """The index pairs (i, j) of the hypotheses of the record that were not compared yet, at most
    MAX_PAIRS. seen: the keys (pair_key) of pairs that were compared before."""
    hs = (record or {}).get("hypotheses") or []
    out = []
    for i in range(len(hs)):
        for j in range(i + 1, len(hs)):
            if pair_key(hs[i], hs[j]) not in seen and len(out) < MAX_PAIRS:
                out.append((i, j))
    return out


def pair_key(a, b):
    return "|".join(sorted([str(a.get("id")), str(b.get("id"))]))


def ask_difference(tree, record, seen=()):
    return {f"y_differs@{i}_{j}": _with(tree["y_differs"], a=f"record.hypotheses[{i}]", b=f"record.hypotheses[{j}]")
            for i, j in pairs(record, seen)}


def read_difference(answers, record):
    """One item for each pair that was asked: {"a", "b", "differs": "user" | "inside" | "same" |
    None, "part", "question"}. Only "user" raises a question for the human (question: its text,
    to propose on the goal); a pair that differs only inside raises none."""
    hs = (record or {}).get("hypotheses") or []
    out = []
    for qid, a in sorted((answers or {}).items()):
        if not qid.startswith("y_differs@"):
            continue
        try:
            i, j = (int(x) for x in qid.split("@", 1)[1].split("_"))
            ha, hb = hs[i], hs[j]
        except (ValueError, IndexError):
            continue
        c = _choice(a)
        d = c[0] if c and c[0] in ("user", "inside", "same") else None
        item = {"a": ha["id"], "b": hb["id"], "differs": d, "part": None, "question": None}
        if d == "user":
            item["part"] = f"hypotheses {ha['id']} and {hb['id']} differ in what a user experiences: a question for the human"
            item["question"] = (f"Hypotheses {ha['id']} and {hb['id']} differ in what a user experiences. "
                                "Which does the human want?")
        out.append(item)
    return out


# --- drift (c30): the delivery against the predictions, at the stop event ---

def predictions(record):
    """The predictions of the record in order, at most MAX_PREDICTIONS:
    [{"n", "path", "id", "hypothesis", "text"}]."""
    out = []
    for i, h in enumerate((record or {}).get("hypotheses") or []):
        for j, c in enumerate(h.get("predictions") or []):
            if len(out) < MAX_PREDICTIONS:
                out.append({"n": len(out), "path": f"record.hypotheses[{i}].predictions[{j}]",
                            "id": c.get("id"), "hypothesis": h.get("id"), "text": c.get("text") or ""})
    return out


def ask_drift(tree, record):
    out = {"d_success": tree["d_success"]}
    for p in predictions(record):
        out[f"d_kept@{p['n']}"] = _with(tree["d_kept"], prediction=p["path"])
        out[f"d_revised@{p['n']}"] = _with(tree["d_revised"], prediction=p["path"])
    return out


def read_drift(answers, record):
    """{"success", "drifts": [prediction], "revisions": [prediction], "hint": line or None}.
    d_success first: with no sure report of success the tree ends. A prediction is a drift when
    the delivery drops or changes it (d_kept) and no message of the human changed it (d_revised
    in the no band). When the human changed it (the yes band) it is a revision: no hint, and the
    change is proposed for the record. An unsure d_revised gives neither."""
    answers = answers or {}
    out = {"success": _noul(answers.get("d_success"))[0] == "yes", "drifts": [], "revisions": [], "hint": None}
    if not out["success"]:
        return out
    for p in predictions(record):
        k = _choice(answers.get(f"d_kept@{p['n']}"))
        if not k or k[0] not in ("dropped", "changed"):
            continue
        rv = _noul(answers.get(f"d_revised@{p['n']}"))[0]
        item = dict(p, how=k[0])
        if rv == "no":
            out["drifts"].append(item)
        elif rv == "yes":
            out["revisions"].append(item)
    if out["drifts"]:
        said = "; ".join(f"{d['id']} of {d['hypothesis']} (\"{_short(d['text'])}\")" for d in out["drifts"][:3])
        one = len(out["drifts"]) == 1
        out["hint"] = (f"System 1: the delivery reports success. The original prediction{'' if one else 's'} "
                       f"included {said}. What happened to {'that part' if one else 'those parts'}?")
    return out


def _short(text):
    text = " ".join(str(text).split())
    return text if len(text) <= QUOTE else text[:QUOTE - 1] + "…"


def read_drift_today(answers):
    """The arm without the record (the replay experiment only): d_drift in the yes band is a hint
    that names no prediction."""
    hit = _noul((answers or {}).get("d_drift"))[0] == "yes"
    return {"drifts": [{}] if hit else [], "revisions": [],
            "hint": "System 1: the delivery reports success by a criterion that changed" if hit else None}

#!/usr/bin/env python3
"""System 1 hook for Claude Code (T07). Event: UserPromptSubmit. Python 3 standard library only.

Reads the hook JSON on stdin (prompt, transcript_path, session_id), asks the System 1 model the questions in
s1/questions.json about {message: the prompt, recent: the last 3 messages before it}, and prints
one line of the answers outside the unsure band as additionalContext:

    {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                            "additionalContext": "System 1: work=build (0.83); ..."}}

Output shape: https://code.claude.com/docs/en/hooks ("UserPromptSubmit decision control").

What is sent (T20): `recent` is a list, oldest first, of the last 3 messages before the prompt
(S1_CONTEXT_MESSAGES raises the count; never below 3). Each item is {"role": "you" | "agent",
"text": the complete text}. A message is a user prompt or an assistant reply; tool calls, tool
results, meta lines and subagent (sidechain) lines are not messages. An assistant reply is all
the agent text of one turn (between two user prompts). Each text is sent whole.
Only when the state and the longest question would pass the System 1 model's per-question context (32k tokens,
counted here as CONTEXT_CHARS characters) are the messages beyond 3 dropped, oldest first. If the
3 whole messages still do not fit, they are sent whole with the TypeSafe-Danger-Zone-Long-Context
header (262k tokens; slower, same price; the log line has "long_context": true). Only beyond 262k
is the oldest message cut from its start; the log line then has "trimmed": true. The transcript
read starts with the last 2 MiB and goes back, at most 8 MiB, until it has the messages.
The hook sends the complete messages as written, with no redaction (T43, u123): no name list is
applied to them.

Which messages (s1-rewind-context): the conversation Claude holds, not the file order. The hook
follows parentUuid back from the last message line (G5), stops at a compaction (the summary is one
message) and leaves out the lines Ty did not type ([Request interrupted ...], tagged lines such as
<command-name> or <task-notification>). On the first prompt after a rewind, a prompt that matches
a prompt of the branch the file ends in (difflib ratio >= 0.9, 15 chars or more) starts at that
prompt's parent (G6). No uuid, or a parent missing from the whole file: file order (rk1).
The late fix (c7): with a prompt_id in the input, the hook starts a detached process (G7,
`hook.py --late-fix FILE`) that waits for the prompt line with that promptId (G1) and, only if the
context from its parent differs from what was sent (G4), asks again and logs kind "correction".
posttool.py (a PostToolUse hook) gives the corrected line to the main agent once (c8).

Fails open, and says so (0.3.0 S-A): on any error, a timeout, a missing key, a missing questions
file or bad stdin it prints one short line, "System 1: no view (<reason>)", and exits 0. When every
answer is in the unsure band it prints "System 1: unsure"; when only the formal tool is sure and no
signal shows it, "System 1: no signal". It prints nothing only when it is off
(S1_OFF). It never blocks a prompt. The line only reports: it gives the agent no instruction (the
prompt says what to do with a hint). It names a formal tool only beside a signal (a likely
divergence, a likely change of plan, significant effort), or when a proof is asked for.

Env: TYPESAFE_API_KEY (the key), S1_OFF=1 (do nothing), S1_TIMEOUT (seconds, default 4),
S1_CONTEXT_MESSAGES (default 3, never below 3),
S1_QUESTIONS (default: the workbench's questions.json, else s1/questions.json),
S1_LOG (default ~/.claude/logs/s1.jsonl), S1_WORKBENCH (default s1/workbench/; "off" ignores it),
S1_WORKBENCH_TIMEOUT (seconds for a workbench routing, default 9),
S1_LATEFIX=0 (no late fix), S1_LATEFIX_DIR (default ~/.claude/s1-latefix), S1_LATEFIX_WAIT (20).

The workbench (s1-inspect, branch s1/inspect): a folder read again on every prompt, so a saved edit
acts on the next call. Its questions.json replaces s1/questions.json (S1_QUESTIONS still wins). Its
pipeline.py, when present, routes the call: run(state, ask, questions) -> {id: answer}, where each
ask(qs) is one System 1 call (one log line, with "routing": "workbench" and its "stage"); and
hint(answers, questions) -> str, the line the agent gets (default: format_answers). A routing gets
S1_WORKBENCH_TIMEOUT for all its calls. A routing that fails to load, raises, or returns a bad hint
fails open: "System 1: no view (routing: <error>)" and one log line with the reason.
"""
import difflib
import json
import os
import re
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import jev  # noqa: E402
import posttool  # noqa: E402  (the late-fix files: one home for the paths)

DEFAULT_TIMEOUT = 4.0
WORKBENCH_TIMEOUT = 9.0  # s1-inspect c9b: longer than 4 s; with GRACE under the 10 s hook timeout of the install
GRACE = 0.5  # seconds past the timeout before the hook stops waiting for the call
CONTEXT_MESSAGES = 3  # the least number of messages in recent (T20, Ty)
TAIL_BYTES = 2 * 1024 * 1024  # the first read: the end of the transcript
MAX_TAIL_BYTES = 8 * 1024 * 1024  # the read goes back at most this far (as the status line)
CONTEXT_TOKENS = 32000  # the System 1 model's default per-question context (models page)
CHARS_PER_TOKEN = 3  # a cautious count: fewer characters per token than English text has
CONTEXT_CHARS = CONTEXT_TOKENS * CHARS_PER_TOKEN
LONG_CONTEXT_TOKENS = 262000  # with the long-context header (TypeSafe docs, models page)
LONG_CONTEXT_CHARS = LONG_CONTEXT_TOKENS * CHARS_PER_TOKEN
REQUEST_TOKENS = 64000  # the model's default per-request context: the state and all the questions (models page)
REQUEST_CHARS = REQUEST_TOKENS * CHARS_PER_TOKEN
CHOICE_MIN = 0.5  # a choice is shown when P(choice) >= 0.5, as in the calibration
UNSURE = "System 1: unsure"  # every answer in the unsure band (0.3.0 S-A)
NO_SIGNAL = "System 1: no signal"  # only a formal tool is sure, and no signal shows it (review of 0.3.0)
# s1-rewind-context c3: a line that Ty did not type ([Request interrupted ...], a line that starts
# with a tag such as <command-name>, <local-command-stdout>, <task-notification>, <bash-input>)
TAGGED = re.compile(r"^\s*(<[a-z][a-z0-9_-]*[ >/]|\[Request interrupted)", re.I)
MATCH_RATIO = 0.9  # c6b (q9, Ty): the text match of the first prompt after a rewind
MATCH_MIN_CHARS = 15  # c6b: a shorter prompt is never matched
MATCH_MAX_CHARS = 4000  # a longer text is not compared (difflib is quadratic)
LATE_FIX_WAIT = 20.0  # c7: seconds the late fix waits for the prompt line (G1)
LATE_FIX_POLL = 0.05
CORRECTION_PREFIX = "System 1 (correction):"  # c8: the line that PostToolUse gives the agent
_LAST = object()  # recent_messages: start at the last message line of the transcript


def no_view(reason):
    """The one short line of a hook that failed (0.3.0 S-A). The details go to the log only."""
    return f"System 1: no view ({reason})"


def _timeout(env):
    try:
        t = float(env.get("S1_TIMEOUT", DEFAULT_TIMEOUT))
        return t if t > 0 else DEFAULT_TIMEOUT
    except (TypeError, ValueError):
        return DEFAULT_TIMEOUT


def _workbench_timeout(env):
    try:
        t = float(env.get("S1_WORKBENCH_TIMEOUT", WORKBENCH_TIMEOUT))
        return t if t > 0 else WORKBENCH_TIMEOUT
    except (TypeError, ValueError):
        return WORKBENCH_TIMEOUT


def workbench(env):
    """The workbench folder, or None: $S1_WORKBENCH ("off" for none), else s1/workbench/ if it exists."""
    wb = env.get("S1_WORKBENCH")
    if wb is not None and wb.strip().lower() in ("off", "0", "none"):
        return None
    wb = os.path.expanduser(wb) if wb else os.path.join(HERE, "workbench")
    return wb if os.path.isdir(wb) else None


def question_path(env, wb):
    """The question file: $S1_QUESTIONS, else the workbench's questions.json, else s1/questions.json."""
    q = env.get("S1_QUESTIONS")
    if q:
        return q
    if wb and os.path.isfile(os.path.join(wb, "questions.json")):
        return os.path.join(wb, "questions.json")
    return os.path.join(HERE, "questions.json")


def load_routing(wb):
    """The workbench routing (a module dict with run, and maybe hint), or None when the folder has
    no pipeline.py. Read and compiled fresh on each call (no import cache, no .pyc). Raises on a
    file that does not load or defines no run()."""
    path = os.path.join(wb, "pipeline.py")
    if not os.path.isfile(path):
        return None
    with open(path, encoding="utf-8") as f:
        src = f.read()
    sys.modules.setdefault("hook", sys.modules[__name__])  # `import hook` in the routing is this module
    ns = {"__name__": "s1_workbench_pipeline", "__file__": path}
    try:
        exec(compile(src, path, "exec"), ns)
    except SystemExit as e:
        raise RuntimeError(f"SystemExit({e.code})") from None
    if not callable(ns.get("run")):
        raise ValueError("pipeline.py defines no run(state, ask, questions)")
    return ns


def _tail_lines(path, size=TAIL_BYTES):
    """The lines in the last `size` bytes of a file, decoded with errors="replace".
    The first line is dropped when the read starts mid-file (it is likely cut)."""
    with open(path, "rb") as f:
        f.seek(0, os.SEEK_END)
        end = f.tell()
        start = max(0, end - size)
        f.seek(start)
        data = f.read(end - start)
    lines = data.decode("utf-8", errors="replace").splitlines()
    return lines[1:] if start > 0 else lines


def _count(env):
    try:
        n = int(env.get("S1_CONTEXT_MESSAGES", CONTEXT_MESSAGES))
    except (TypeError, ValueError):
        return CONTEXT_MESSAGES
    return max(n, CONTEXT_MESSAGES)


def _message(d):
    """(key, role, [texts]) for a transcript line that is part of a message, else None."""
    if not isinstance(d, dict) or d.get("isSidechain") or d.get("isMeta"):
        return None
    kind = d.get("type")
    m = d.get("message")
    if kind not in ("user", "assistant") or not isinstance(m, dict):
        return None
    c = m.get("content")
    if isinstance(c, str):
        texts = [c]
    elif isinstance(c, list):
        if any(isinstance(b, dict) and b.get("type") == "tool_result" for b in c):
            return None
        texts = [b["text"] for b in c
                 if isinstance(b, dict) and b.get("type") == "text" and isinstance(b.get("text"), str)]
    else:
        texts = []
    texts = [t for t in texts if t.strip()]
    if not texts:
        return None
    role = "agent" if kind == "assistant" else "you"
    key = ("agent", m.get("id")) if kind == "assistant" and m.get("id") is not None else None
    return key, role, texts


def _messages(lines):
    """The messages of transcript lines, oldest first: [{"role", "text"}]. An assistant reply is
    all the agent text between two user prompts (one turn): the lines of every API message in
    it (one line per content block, each response with its own message.id) are joined in order."""
    ds = []
    for line in lines:
        try:
            ds.append(json.loads(line))
        except ValueError:
            continue
    return _messages_of(ds)


def _messages_of(ds):
    """_messages of lines already parsed."""
    out = []  # [key, role, [texts]]
    for d in ds:
        got = _message(d)
        if not got:
            continue
        key, role, texts = got
        if role == "agent" and out and out[-1][1] == "agent":  # one turn is one reply (T20 c9)
            out[-1][2].extend(texts)
        else:
            out.append([key, role, list(texts)])
    return [{"role": r, "text": "\n".join(ts)} for _, r, ts in out]


def _typed(d):
    """The line with the pieces that Ty did not type left out (c3), or None when nothing is left.
    A user line keeps only its text pieces that are not TAGGED; other lines are kept as they are
    (_message decides whether they are messages). The same rule as expected() of the ticket's
    check s1ctx.py."""
    if not isinstance(d, dict) or d.get("type") != "user":
        return d
    m = d.get("message")
    if d.get("isSidechain") or d.get("isMeta") or not isinstance(m, dict):
        return None
    c = m.get("content")
    if isinstance(c, str):
        ts = [c] if c.strip() else []
    elif isinstance(c, list):
        ts = [b["text"] for b in c if isinstance(b, dict) and b.get("type") == "text"
              and isinstance(b.get("text"), str) and b["text"].strip()]
    else:
        return None
    ts = [t for t in ts if not TAGGED.match(t)]
    if not ts:
        return None
    content = ts[0] if len(ts) == 1 else [{"type": "text", "text": t} for t in ts]
    return dict(d, message=dict(m, content=content))


def _is_prompt(d):
    """A prompt that Ty typed: a user line whose content is a string, not tagged, not a summary."""
    m = d.get("message")
    return (d.get("type") == "user" and not d.get("isSidechain") and not d.get("isMeta")
            and not d.get("isCompactSummary") and isinstance(m, dict)
            and isinstance(m.get("content"), str) and bool(m["content"].strip())
            and not TAGGED.match(m["content"]))


def _walk(js, by, uuid):
    """The chain that ends in the line `uuid` (G5): that line and its parentUuid ancestors, oldest
    first. It stops at a compaction: the summary line is the first item, nothing before it.
    Returns (indexes, how): how is "root" (a line with no parent, or uuid None), "compaction",
    or "broken" (a parent that is not in the lines read)."""
    out, seen, p = [], set(), uuid
    while p:
        j = by.get(p)
        if j is None or p in seen:
            return out[::-1], "broken"
        seen.add(p)
        d = js[j]
        if d.get("type") == "system" and d.get("subtype") == "compact_boundary":
            return out[::-1], "compaction"
        out.append(j)
        if d.get("isCompactSummary"):
            return out[::-1], "compaction"
        p = d.get("parentUuid")
    return out[::-1], "root"


def _norm(t):
    return re.sub(r"\s+", " ", t.strip().lower())


def _match(js, by, last, prompt):
    """G6 (c6b): the prompt of the branch the transcript ends in (the chain of the last message
    line) that the new prompt matches best, at difflib ratio >= MATCH_RATIO, the new prompt
    MATCH_MIN_CHARS or more; the oldest wins a tie. None when nothing matches. On the first
    prompt after a rewind it names the rewound prompt, whose parent is the rewind point."""
    if not isinstance(prompt, str):
        return None
    p = _norm(prompt)
    if len(p) < MATCH_MIN_CHARS or len(p) >= MATCH_MAX_CHARS:
        return None
    idx, _ = _walk(js, by, js[last].get("uuid"))
    best, bj = 0.0, None
    sm = difflib.SequenceMatcher(None, autojunk=False)
    sm.set_seq2(p)
    for j in idx:
        if not _is_prompt(js[j]):
            continue
        q = _norm(js[j]["message"]["content"])
        if len(q) >= MATCH_MAX_CHARS:
            continue
        sm.set_seq1(q)
        floor = max(MATCH_RATIO, best)  # a tie never replaces the older one
        if sm.real_quick_ratio() < floor or sm.quick_ratio() < floor:
            continue
        r = sm.ratio()
        if r > best:
            best, bj = r, j
    return bj if bj is not None and best >= MATCH_RATIO else None


def _chain_read(lines, prompt, parent):
    """The messages of the conversation Claude holds, from these lines (c1c, c2, c3, c6b).
    parent is _LAST (start at the last message line; the text match may move the start to the
    parent of a matched prompt) or a uuid (start there; None: no parent, so no messages).
    Returns (messages, how) as _walk, or None when the lines have no uuid to follow."""
    js = []
    for line in lines:
        try:
            d = json.loads(line)
        except ValueError:
            d = {}
        js.append(d if isinstance(d, dict) else {})
    by = {d["uuid"]: j for j, d in enumerate(js) if isinstance(d.get("uuid"), str)}
    if parent is _LAST:
        last = next((j for j in range(len(js) - 1, -1, -1)
                     if js[j].get("type") in ("user", "assistant") and not js[j].get("isSidechain")
                     and isinstance(js[j].get("uuid"), str)), None)
        if last is None:
            return None
        start = js[last]["uuid"]
        m = _match(js, by, last, prompt)
        if m is not None:
            start = js[m].get("parentUuid")
    else:
        start = parent
    idx, how = _walk(js, by, start)
    return _messages_of([t for t in (_typed(js[j]) for j in idx) if t is not None]), how


def recent_messages(path, n, prompt=None, parent=_LAST):
    """The last n messages before the prompt, oldest first, of the conversation Claude holds
    (s1-rewind-context h2): from the last message line of the transcript (or from `parent`, a
    uuid, for the late fix) back along parentUuid to the last compaction, whose summary is one
    message; a line that Ty did not type is not a message. On the first prompt after a rewind,
    a prompt text that matches a prompt of the branch the transcript ends in (G6) starts the
    chain at that prompt's parent.

    The read starts with the last TAIL_BYTES and doubles, at most MAX_TAIL_BYTES, until the chain
    ends (a root or a compaction) or it has n + 1 messages (one more, in case the prompt is
    already in the transcript), or it has the whole file.
    Fails open (rk1): a transcript with no uuid gives the last messages in file order, as before
    s1-rewind-context; a chain whose parent is missing from the whole file does the same. A chain
    cut only by the MAX_TAIL_BYTES bound gives the part found."""
    if not path:
        return []
    if parent is None:
        return []
    size = TAIL_BYTES
    while True:
        try:
            with open(path, "rb") as f:
                f.seek(0, os.SEEK_END)
                whole = f.tell() <= size
            lines = _tail_lines(path, size)
        except OSError:
            return []
        got = _chain_read(lines, prompt, parent)
        if got is None or (got[1] == "broken" and whole):
            msgs, done = _messages(lines), False  # rk1: file order, as before
        else:
            msgs, done = got[0], got[1] != "broken"
        if whole or done or len(msgs) > n or size >= MAX_TAIL_BYTES:
            break
        size = min(size * 2, MAX_TAIL_BYTES)
    if prompt is not None and msgs and msgs[-1]["role"] == "you" and msgs[-1]["text"].strip() == prompt.strip():
        msgs = msgs[:-1]
    return msgs[-n:]


def _fit(state, questions):
    """Fit the state to the context (T30 c1). Returns (trimmed, long_context).

    Over the default context: drop the messages beyond 3, oldest first. If the 3 still do not
    fit, keep them whole and ask for the long context (LONG_CONTEXT_CHARS). Only past that is
    the oldest cut from its start."""
    longest = max((len(json.dumps(v)) for v in questions.values()), default=0)

    def size():
        return len(json.dumps(state)) + longest

    trimmed = False
    rec = state["recent"]
    while size() > CONTEXT_CHARS and len(rec) > CONTEXT_MESSAGES:
        rec.pop(0)
        trimmed = True
    long_context = size() > CONTEXT_CHARS
    while size() > LONG_CONTEXT_CHARS and rec:
        over = size() - LONG_CONTEXT_CHARS  # each character takes at least one in the JSON
        t = rec[0]["text"]
        if over >= len(t):
            rec.pop(0)
        else:
            rec[0]["text"] = t[over:]
        trimmed = True
    return trimmed, long_context


def build_state(prompt, transcript_path, n=CONTEXT_MESSAGES, questions=None):
    """{message, recent} as written (no redaction, T43), then fitted. Returns (state, trimmed, long_context)."""
    return _fitted(prompt, recent_messages(transcript_path, n, prompt), questions)


def _fitted(prompt, recent, questions):
    """{message, recent} fitted (a copy: recent itself is not changed)."""
    st = {"message": prompt, "recent": [dict(m) for m in recent]}
    trimmed, long_context = _fit(st, questions or {})
    return st, trimmed, long_context


def _p(x):
    if isinstance(x, bool) or not isinstance(x, (int, float)) or not 0 <= x <= 1:
        raise ValueError(f"not a probability: {x!r}")
    return float(x)


def _noul(a):
    if a.get("type") != "noul":
        raise ValueError("not a noul answer")
    p = _p(a["noul"])
    return jev.band(p), p


def _choice(a, question):
    """(choice, P(choice)) or None when unsure. P is probabilities[choice], else confidence."""
    if a.get("type") != "choice":
        raise ValueError("not a choice answer")
    c = a["choice"]
    if c not in question.get("criteria", {}):
        raise ValueError(f"unknown choice {c!r}")
    probs = a.get("probabilities")
    p = _p(probs[c] if isinstance(probs, dict) and c in probs else a["confidence"])
    return (c, p) if p >= CHOICE_MIN else None


def _proof_asked(answers, lang):
    """A proof is asked for: the answer h_proof when the response has it, else the choice lean."""
    a = answers.get("h_proof")
    if isinstance(a, dict):
        return _noul(a)[0] == "yes"
    return bool(lang) and lang[0] == "lean"


def format_answers(answers, questions):
    """One line; UNSURE when every answer is unsure; NO_SIGNAL when only the formal tool is outside the
    band and the rule holds it back (no signal, no proof). Raises on a malformed answer.
    The line only reports (0.3.0 S-A): no instruction. The formal tool is named only beside a
    signal (divergence likely, change of plan likely, effort significant, questions not settled) or when
    a proof is asked."""
    parts = []
    signal = False
    w = _choice(answers["h_work"], questions["h_work"])
    if w:
        parts.append(f"work={w[0]} ({w[1]:.2f})")
    for qid, name in (("h_divergence", "divergence"), ("h_change_of_plan", "change of plan")):
        b, p = _noul(answers[qid])
        if b != "unsure":
            parts.append(f"{name} {'likely' if b == 'yes' else 'unlikely'} ({p:.2f})")
            signal = signal or b == "yes"
    e, ep = _noul(answers["h_effort"])
    if e == "yes":
        parts.append(f"effort significant ({ep:.2f})")
        signal = True
    elif e == "no":
        parts.append(f"effort not significant ({ep:.2f})")
    if isinstance(answers.get("h_reversal"), dict):  # the fan-out: a decision that the message itself reverses
        b, p = _noul(answers["h_reversal"])
        if b == "yes":
            parts.append(f"decision reversed in message ({p:.2f})")
            signal = True
    # 0.3.0 S-C: a round of questions that did not settle, and a proof that the human asks for. Each is
    # reported in the yes band only, and only when the response has it (an older response has neither).
    for qid, text in (("h_questions", "questions not settled"), ("h_proof", "proof asked")):
        if isinstance(answers.get(qid), dict):
            b, p = _noul(answers[qid])
            if b == "yes":
                parts.append(f"{text} ({p:.2f})")
                signal = signal or qid == "h_questions"
    lang = _choice(answers["h_language"], questions["h_language"])
    if lang and (signal or _proof_asked(answers, lang)):
        parts.append(f"formal tool: {lang[0]} ({lang[1]:.2f})")
    if parts:
        return "System 1: " + "; ".join(parts)
    return NO_SIGNAL if lang else UNSURE


# --- the fan-out (research of 2026-11-15, s1/research/2026-11-15-question-eval/README.md) ---
# The message is cut into parts. Each part gets the questions of fanout.json, in the same request as
# the questions of questions.json. combine() then writes the answers of h_divergence, h_change_of_plan,
# h_questions and h_effort from the parts, and adds h_reversal. S1_FANOUT=0 turns it off.
PART_CHARS = 600  # a part of a long message holds at most this many characters
PART_WORDS = 25  # text with no sentence ends (a voiced prompt) is cut every 25 words first
SENTENCE_PARTS = 6  # up to this many sentences, each sentence is its own part
MAX_PARTS = 40  # past this, the parts grow so that the whole message is still read
EFFORT_CHARS = 800  # a message this long, and not pasted, shows effort (a guess: see the research notes)
BLOCKS_FAULT = ("changes_request", "adds_request", "answers")  # a fault does not count in such a part
_SENT_END = re.compile(r"(?<=[.!?])\s+")


def split_parts(msg):
    """The parts of a message, in order, never empty. Each sentence is a part when there are at most
    SENTENCE_PARTS of them and none is longer than PART_CHARS. Else the sentences (or runs of PART_WORDS
    words, where sentence ends are rare) are packed into parts of at most PART_CHARS characters."""
    sents = [x.strip() for x in _SENT_END.split(msg) if x.strip()] or [msg]
    if len(sents) <= SENTENCE_PARTS and all(len(x) <= PART_CHARS for x in sents):
        return sents
    if len(msg) > len(sents) * PART_CHARS:  # too few sentence ends for the length
        w = msg.split()
        sents = [" ".join(w[i:i + PART_WORDS]) for i in range(0, len(w), PART_WORDS)] or [msg]
    size = max(PART_CHARS, -(-len(msg) // MAX_PARTS))
    while True:  # packing leaves some room in each part, so the size grows until the count fits
        parts = [""]
        for x in sents:
            if parts[-1] and len(parts[-1]) + len(x) + 1 > size:
                parts.append("")
            parts[-1] = (parts[-1] + " " + x).strip()
        if len(parts) <= MAX_PARTS:
            return parts
        size += size // 10 + 1


def fan_fit(state, asked):
    """(fits, long_context) for the state of a fan-out call and all its questions. The state holds
    the message twice (message and sentences) and the request holds seven questions for each part,
    so the fit of {message, recent} alone (_fit) says too little. The state and its longest question
    must fit the per-question context, and the state and every question the per-request context;
    past both defaults the long context is asked for; past that the fan-out does not fit."""
    st = len(json.dumps(state))
    longest = max((len(json.dumps(v)) for v in asked.values()), default=0)
    total = st + len(json.dumps(asked))
    if st + longest <= CONTEXT_CHARS and total <= REQUEST_CHARS:
        return True, False
    if st + longest <= LONG_CONTEXT_CHARS and total <= LONG_CONTEXT_CHARS:
        return True, True
    return False, False


REPLACES = ("h_divergence", "h_change_of_plan", "h_questions", "h_effort")  # what combine may write


def fanout_questions(fan, n):
    """The questions of the fan-out for n parts: {"name@k": question} and the whole-message helpers."""
    out = {}
    for k in range(n):
        for name, q in fan["part"].items():
            q = dict(q)
            q["instructions"] = q["instructions"].replace("{part}", f"`sentences[{k}]`")
            out[f"{name}@{k}"] = q
    out.update(fan.get("whole", {}))
    return out


def combine(answers, state, replaces=None):
    """The answers with h_divergence, h_change_of_plan, h_questions and h_effort written from the
    parts, and h_reversal added. The rules:
    divergence: the highest doubt or fault of a part; a fault does not count in a part that changes
        or adds to the request, or answers the agent; 0 with no agent message in recent.
    change of plan: the highest "changes" of a part; 0 with no agent message.
    questions: when the agent's last reply asks something: the highest "asks" or "undecided" of a
        part, or, for a message of more than SENTENCE_PARTS parts, the whole-message answer f_open.
    effort: the answer h_effort, or 1 - P(pasted) for a message of EFFORT_CHARS or more.
    reversal: the highest "reverses" of a part. A part that reverses also reads as a change, so a
        reversal inside the message can come with "change of plan": the line then names both.
    replaces: the ids that may be rewritten (default REPLACES; the list "replaces" of fanout.json).
    An id that is not in it keeps the answer of its own question, so an edit of that question
    reaches the line. Each answer that is rewritten keeps its plain value as "<id>_plain"
    (replaced() lists them); h_effort is rewritten only when the rule raises it."""
    replaces = REPLACES if replaces is None else replaces
    n = len(state["sentences"])
    agents = [m for m in state.get("recent", []) if m.get("role") == "agent"]
    has_agent = bool(agents)
    agent_asks = has_agent and "?" in agents[-1].get("text", "")

    def p(name, k=None):
        return _p(answers[name if k is None else f"{name}@{k}"]["noul"])

    div = chg = ask = rev = 0.0
    for k in range(n):
        top = answers[f"react@{k}"].get("choice")
        fault = p("faults", k)
        if top in BLOCKS_FAULT:
            fault = min(fault, 0.29)
        div = max(div, p("doubts", k), fault)
        chg = max(chg, p("changes", k))
        ask = max(ask, p("asks", k), p("undecided", k))
        rev = max(rev, p("reverses", k))
    if n > SENTENCE_PARTS:
        ask = p("f_open")
    effort = p("h_effort")
    if len(state["message"]) >= EFFORT_CHARS:
        effort = max(effort, 1.0 - p("f_pasted"))
    out = dict(answers)
    for qid, v in (("h_divergence", div if has_agent else 0.0), ("h_change_of_plan", chg if has_agent else 0.0),
                   ("h_questions", ask if agent_asks else 0.0), ("h_effort", effort)):
        if qid not in replaces:
            continue
        new = {"type": "noul", "noul": round(v, 4)}
        if qid == "h_effort" and qid in answers and new["noul"] <= p("h_effort"):
            continue  # the rule did not raise it: the plain answer stands
        if qid in answers:
            out[qid + "_plain"] = answers[qid]
        out[qid] = new
    out["h_reversal"] = {"type": "noul", "noul": round(rev, 4)}
    return out


def replaced(combined):
    """The ids that combine rewrote: those with a plain answer kept beside them."""
    return sorted(k[:-len("_plain")] for k in combined if k.endswith("_plain"))


def load_fanout(env, extra=None):
    """The questions of the fan-out, or None when it is off (S1_FANOUT=0) or its file does not load."""
    if env.get("S1_FANOUT", "").strip() == "0":
        return None
    try:
        with open(env.get("S1_FANOUT_FILE") or os.path.join(HERE, "fanout.json"), encoding="utf-8") as f:
            fan = json.load(f)
        if not isinstance(fan.get("part"), dict) or not fan["part"]:
            raise ValueError("no part questions")
        return fan
    except (OSError, ValueError, AttributeError) as e:
        if extra is not None:
            extra["fanout_off"] = f"{type(e).__name__}: {e}"
        return None


def judge_parts(state, questions, fan, log_path, key, lx, **kw):
    """One System 1 call. With a fan-out: the message is cut into parts (state["sentences"]), the
    part questions go in the same request, and the answers are combined; a second log line
    ("combined": true) holds the combined answers and the text of each part. A fan-out answer that
    is malformed fails open: the plain answers come back and a skip line says why."""
    if not fan:
        return jev.judge(state, questions, key=key, log_path=log_path, log_extra=lx, **kw)
    plain_state = state
    state = dict(state, sentences=split_parts(state["message"]))
    asked = dict(questions)
    asked.update(fanout_questions(fan, len(state["sentences"])))
    fits, long_context = fan_fit(state, asked)
    if not fits:  # too large even for the long context: a plain call, and the log says why
        return jev.judge(plain_state, questions, key=key, log_path=log_path,
                         log_extra=dict(lx, fanout_off="too large for the context"), **kw)
    lx = dict(lx, parts=len(state["sentences"]))
    if long_context and not kw.get("long_context"):
        kw["long_context"] = True
        lx["long_context"] = True
    got = jev.judge(state, asked, key=key, log_path=log_path, log_extra=lx, **kw)
    if got:
        try:
            got = combine(got, state, fan.get("replaces"))
            jev._log(log_path, key, dict(lx, time=jev._now(), combined=True, answers=got, error=None,
                                         replaced=replaced(got),
                                         part_text=[x[:160] for x in state["sentences"]]))
        except Exception as e:
            _skip(log_path, key, f"fan-out: {type(e).__name__}: {e}", lx)
    return got


def fanout_run(state, ask, questions, env=None):
    """The released asking, for a workbench routing: run(state, ask, questions) of pipeline.py can
    return this. One ask() with the questions and, unless S1_FANOUT=0, the fan-out; the answers come
    back combined. It adds state["sentences"] to the state that ask() sends."""
    fan = load_fanout(getattr(ask, "env", os.environ) if env is None else env)
    if not fan:
        return ask(questions)
    state["sentences"] = split_parts(state["message"])
    asked = dict(questions)
    asked.update(fanout_questions(fan, len(state["sentences"])))
    fits, long_context = fan_fit(state, asked)
    if not fits:  # too large even for the long context: the plain asking
        del state["sentences"]
        return ask(questions)
    if long_context:
        ask.long_context = True  # the hook's ask() reads it: the state with its parts needs the long context
    got = ask(asked)
    if not got:
        return got
    try:
        out = combine(got, state, fan.get("replaces"))
    except Exception:
        return got  # fails open: the plain answers
    log = getattr(ask, "log", None)
    if callable(log):
        log({"combined": True, "parts": len(state["sentences"]), "answers": out, "error": None,
             "replaced": replaced(out), "part_text": [x[:160] for x in state["sentences"]]})
    return out


def _skip(log_path, key, reason, extra=None, **fields):
    """One log line that says why the hook made no call or printed nothing. No key."""
    rec = {"time": jev._now(), "skipped": reason}
    rec.update(fields)
    rec.update(extra or {})
    jev._log(log_path, key, rec)


def _out(line):
    return json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                                              "additionalContext": line}})


def run(raw, env, transport=None, spawn=None):
    """The hook's stdout for stdin text raw: a JSON hook result, or "" only when off (S1_OFF).
    Never raises. Every skip except S1_OFF writes one log line with the reason, and prints
    one short line "System 1: no view (<reason>)" (0.3.0 S-A).
    After the first call it starts the late fix (c7) with spawn(argv, env) (default: a detached
    process, G7); tests give their own spawn."""
    if env.get("S1_OFF", "").strip() not in ("", "0"):
        return ""
    log_path = env.get(jev.LOG_ENV) or jev.DEFAULT_LOG
    key = env.get(jev.KEY_ENV) or ""
    extra = {}
    try:
        try:
            payload = json.loads(raw)
        except ValueError as e:
            _skip(log_path, key, f"stdin: not JSON ({e})")
            return _out(no_view("bad input"))
        if not isinstance(payload, dict) or not isinstance(payload.get("prompt"), str):
            _skip(log_path, key, "stdin: no prompt")
            return _out(no_view("bad input"))
        tpath = payload.get("transcript_path")
        tpath = tpath if isinstance(tpath, str) else ""
        extra = {"session_id": payload.get("session_id"),
                 "transcript": os.path.basename(tpath) or None}
        if isinstance(payload.get("prompt_id"), str):
            extra["prompt_id"] = payload["prompt_id"]
        try:  # the late fix looks for the prompt line from here on (it is written after the hook)
            offset = os.path.getsize(tpath) if tpath else 0
        except OSError:
            offset = 0
        wb = workbench(env)
        qpath = question_path(env, wb)
        try:
            with open(qpath, encoding="utf-8") as f:
                questions = json.load(f)
            if not isinstance(questions, dict) or not questions:
                raise ValueError("not a non-empty object")
        except (OSError, ValueError) as e:
            _skip(log_path, key, f"questions: {type(e).__name__}: {e}", extra)
            return _out(no_view("no question set"))
        routed = bool(wb) and os.path.isfile(os.path.join(wb, "pipeline.py"))
        fan = None if routed else load_fanout(env, extra)  # a workbench routing does its own asking
        timeout = _workbench_timeout(env) if routed else _timeout(env)
        if not key:  # judge would fall back to os.environ; the hook reads only env
            _skip(log_path, None, "no API key", extra, model=jev.DEFAULT_MODEL,
                  questions=list(questions), answers=None, latency=0.0, usage=None,
                  error=f"RuntimeError: missing API key (${jev.KEY_ENV})")
            return _out(no_view("no API key"))
        box = {}

        def call():  # the transcript read and the request both run inside the timeout
            try:
                recent = recent_messages(tpath, _count(env), payload["prompt"])
                box["recent"] = [dict(m) for m in recent]  # what the late fix compares with (G4)
                state, trimmed, long_context = _fitted(payload["prompt"], recent, questions)
            except Exception as e:
                box["error"] = f"state: {type(e).__name__}: {e}"
                return
            lx = dict(extra, trimmed=True) if trimmed else dict(extra)
            if long_context:
                lx["long_context"] = True
            routing = None
            if routed:  # loaded here, so a routing that hangs at load is inside the limit too
                try:
                    routing = load_routing(wb)
                except BaseException as e:
                    box["routing_error"] = f"{type(e).__name__}: {e}"
                    return
            if routing is None:
                box["answers"] = judge_parts(state, questions, fan, log_path, key, lx, timeout=timeout,
                                             transport=transport, long_context=long_context)
                return
            stage = [0]

            def ask(qs):  # one System 1 call of the routing, in the time that is left
                stage[0] += 1
                left = max(deadline - time.monotonic(), 0.1)
                more = bool(getattr(ask, "long_context", False)) and not long_context  # asked for by fanout_run
                return jev.judge(state, qs, timeout=left, key=key, log_path=log_path,
                                 transport=transport, long_context=long_context or more,
                                 log_extra=dict(lx, routing="workbench", stage=stage[0],
                                                **({"long_context": True} if more else {})))
            ask.env = env  # for hook.fanout_run: the hook reads only this env
            ask.log = lambda rec: jev._log(log_path, key, dict(lx, routing="workbench", time=jev._now(), **rec))
            try:
                got = routing["run"](state, ask, questions)
                if got is None or isinstance(got, dict) and not got and not callable(routing.get("hint")):
                    box["answers"] = None
                    return
                if not isinstance(got, dict):
                    raise TypeError(f"run() returned {type(got).__name__}, not a dict")
                h = routing.get("hint")
                line = h(got, questions) if callable(h) else format_answers(got, questions)
                if not isinstance(line, str):
                    raise TypeError(f"hint() returned {type(line).__name__}, not a str")
                box["line"] = line
            except BaseException as e:
                box["routing_error"] = f"{type(e).__name__}: {e}"

        deadline = time.monotonic() + timeout
        t = threading.Thread(target=call, daemon=True)
        t.start()
        t.join(timeout + GRACE)
        if "recent" in box:
            _start_late_fix(payload, env, tpath, offset, box["recent"], spawn or _spawn)
        if t.is_alive():
            _skip(log_path, key, f"timeout: the hook stopped waiting after {timeout + GRACE}s",
                  extra, model=jev.DEFAULT_MODEL, questions=list(questions),
                  latency=timeout + GRACE, error=f"timeout: after {timeout + GRACE}s")
            return _out(no_view("timeout"))
        if "error" in box:
            _skip(log_path, key, box["error"], extra)
            return _out(no_view("error"))
        if "routing_error" in box:
            _skip(log_path, key, f"routing: {box['routing_error']}", extra, routing="workbench")
            return _out(no_view(f"routing: {box['routing_error'].split(':')[0]}"))
        if "line" in box:
            return _out(box["line"])
        answers = box.get("answers")
        if not answers:
            _skip(log_path, key, "no answers (the call's line has the error)", extra)
            return _out(no_view("no answer"))
        try:
            line = format_answers(answers, questions)
        except Exception as e:
            _skip(log_path, key, f"bad answers: {type(e).__name__}: {e}", extra)
            return _out(no_view("bad answers"))
        return _out(line)
    except Exception as e:
        _skip(log_path, key, f"error: {type(e).__name__}: {e}", extra)
        return _out(no_view("error"))


def _spawn(argv, env):
    """G7 (c9): start the late fix as a detached process: a new session, stdin, stdout and
    stderr closed. The hook never waits on it, so Claude Code never waits on it."""
    import subprocess
    subprocess.Popen(argv, env=env, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True, close_fds=True)


def _start_late_fix(payload, env, tpath, offset, recent, spawn):
    """Write what the first call was sent and start the late fix of this prompt. Nothing when
    the input has no prompt_id or session_id (no late fix), or S1_LATEFIX=0. Never raises."""
    try:
        if env.get("S1_LATEFIX", "").strip() == "0" or not tpath:
            return
        sid, pid = posttool.safe_id(payload.get("session_id")), posttool.safe_id(payload.get("prompt_id"))
        if not sid or not pid:
            return
        stem = posttool.base(env, sid, pid)
        os.makedirs(os.path.dirname(stem), mode=0o700, exist_ok=True)
        sent = stem + ".sent.json"
        tmp = f"{sent}.{os.getpid()}.tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump({"session_id": sid, "prompt_id": pid, "transcript_path": tpath,
                       "offset": offset, "prompt": payload["prompt"], "n": _count(env),
                       "recent": recent}, f)
        os.replace(tmp, sent)
        spawn([sys.executable, os.path.abspath(__file__), "--late-fix", sent], env)
    except Exception:
        pass


def _find_prompt_line(path, prompt_id, offset, wait, poll=LATE_FIX_POLL, sleep=time.sleep):
    """G1: wait (at most `wait` seconds) for the prompt line whose promptId is the hook's
    prompt_id. Returns (True, its parentUuid) or (False, None). The read starts TAIL_BYTES
    before `offset` (the transcript size when the hook ran) and then reads only what is added."""
    pos = max(0, offset - TAIL_BYTES)
    cut = pos > 0  # the first line read may be cut
    buf = b""
    deadline = time.monotonic() + wait
    while True:
        try:
            with open(path, "rb") as f:
                f.seek(pos)
                data = f.read()
        except OSError:
            data = b""
        pos += len(data)
        buf += data
        lines = buf.split(b"\n")
        buf = lines.pop()
        if cut and lines:
            lines, cut = lines[1:], False
        for line in lines:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if not isinstance(d, dict) or d.get("type") != "user" or d.get("promptId") != prompt_id:
                continue
            c = (d.get("message") or {}).get("content") if isinstance(d.get("message"), dict) else None
            if d.get("isMeta") or d.get("isSidechain") or d.get("isCompactSummary") or (
                    isinstance(c, list) and any(isinstance(b, dict) and b.get("type") == "tool_result" for b in c)):
                continue
            return True, d.get("parentUuid")
        if time.monotonic() >= deadline:
            return False, None
        sleep(poll)


def _prune(env, days=2):
    """Remove late-fix files older than `days` days. Never raises."""
    try:
        top = posttool.state_dir(env)
        old = time.time() - days * 86400
        for sd in os.listdir(top):
            p = os.path.join(top, sd)
            for fn in os.listdir(p):
                q = os.path.join(p, fn)
                if os.path.getmtime(q) < old:
                    os.unlink(q)
            if not os.listdir(p):
                os.rmdir(p)
    except Exception:
        pass


def late_fix(sent_path, env, transport=None, wait=None, sleep=time.sleep):
    """c7: the late fix of one prompt (run in the detached process). Once the prompt line is in
    the transcript (G1), read the context from its parent; only if that differs from what the
    first call was sent (G4), ask the System 1 model once more, log the call with kind "correction" and the
    prompt_id, and write the corrected line for PostToolUse (c8). At most once per prompt (a
    lock file made with O_EXCL). Returns what it did, for tests. Never raises."""
    try:
        with open(sent_path, encoding="utf-8") as f:
            st = json.load(f)
        stem = sent_path[:-len(".sent.json")]
        try:
            os.close(os.open(stem + ".lock", os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600))
        except FileExistsError:
            return "already"
        _prune(env)
        if wait is None:
            try:
                wait = float(env.get("S1_LATEFIX_WAIT", LATE_FIX_WAIT))
            except (TypeError, ValueError):
                wait = LATE_FIX_WAIT
        found, parent = _find_prompt_line(st["transcript_path"], st["prompt_id"], st["offset"], wait,
                                          sleep=sleep)
        if not found:
            return "no prompt line"
        right = recent_messages(st["transcript_path"], st["n"], None, parent=parent)
        if right == st["recent"]:  # G4: the first call was right
            return "right"
        log_path = env.get(jev.LOG_ENV) or jev.DEFAULT_LOG
        key = env.get(jev.KEY_ENV) or ""
        if not key:
            return "no key"
        wb = workbench(env)  # the same questions and routing as the first call
        with open(question_path(env, wb), encoding="utf-8") as f:
            questions = json.load(f)
        state, trimmed, long_context = _fitted(st["prompt"], right, questions)
        lx = {"session_id": st["session_id"], "transcript": os.path.basename(st["transcript_path"]),
              "prompt_id": st["prompt_id"], "kind": "correction"}
        if trimmed:
            lx["trimmed"] = True
        if long_context:
            lx["long_context"] = True
        routing = load_routing(wb) if wb else None
        if routing is None:
            answers = judge_parts(state, questions, load_fanout(env), log_path, key, lx,
                                  transport=transport, long_context=long_context)
            if not answers:
                return "no answer"
            line = format_answers(answers, questions)
        else:
            stage = [0]

            def ask(qs):  # one System 1 call of the routing, logged as part of the correction
                stage[0] += 1
                more = bool(getattr(ask, "long_context", False)) and not long_context
                return jev.judge(state, qs, key=key, log_path=log_path, transport=transport,
                                 long_context=long_context or more,
                                 log_extra=dict(lx, routing="workbench", stage=stage[0],
                                                **({"long_context": True} if more else {})))
            ask.env = env
            ask.log = lambda rec: jev._log(log_path, key, dict(lx, routing="workbench", time=jev._now(), **rec))
            got = routing["run"](state, ask, questions)
            if not got:
                return "no answer"
            h = routing.get("hint")
            line = h(got, questions) if callable(h) else format_answers(got, questions)
            if not isinstance(line, str):
                return "error"
        if line.startswith("System 1:"):
            line = CORRECTION_PREFIX + line[len("System 1:"):]
        else:
            line = CORRECTION_PREFIX + " " + line
        tmp = stem + ".correction.json.tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump({"line": line}, f)
        os.replace(tmp, stem + ".correction.json")
        return "corrected"
    except Exception:
        return "error"
    finally:
        try:
            os.unlink(sent_path)
        except OSError:
            pass


def main(transport=None, argv=None):
    """Script entry: stdin to stdout. Always returns 0. `--late-fix FILE` runs the late fix."""
    argv = sys.argv[1:] if argv is None else argv
    try:
        if os.environ.get("S1_OFF", "").strip() not in ("", "0"):
            return 0
        if argv[:1] == ["--late-fix"] and len(argv) == 2:
            late_fix(argv[1], dict(os.environ), transport=transport)
            return 0
        out = run(sys.stdin.read(), dict(os.environ), transport=transport)
        if out:
            sys.stdout.write(out + "\n")
            sys.stdout.flush()
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())

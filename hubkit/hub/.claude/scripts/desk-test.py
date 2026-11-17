#!/usr/bin/env python3
"""Test for desk.py. Each case builds a hub in a temp dir (hubflow.py and desk.py copied into its
.claude/scripts/, the db made by hubflow.py with a fixed clock, HUBFLOW_NOW), never the real hub.
tmux is a fake program (DESK_TMUX) that logs its arguments; the real tmux server is never touched.

usage: python3 -I desk-test.py [--case NAME ...] [--mutants]
  --case NAME  run only that case (repeatable), e.g. --case case_hook
  --mutants    also run the suite on mutated copies of desk.py; each mutant must make a case fail
Prints `PASS name` or `FAIL name: why` per check; the last line is `N passed, M failed`.
Exit 0 only if every check passes.
"""
import json, os, re, shutil, sqlite3, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
HUBFLOW = os.path.join(HERE, "hubflow.py")
DESK = os.path.join(HERE, "desk.py")
NOW = "2026-11-02T12:00:00Z"
SEED = {"sessions": [{"name": n, "role": n} for n in ("discovery", "build", "process", "support")],
        "aliases": [{"alias": "helpdesk", "name": "support"}],
        "persons": [{"key": "me", "display": "Me"}]}
SCRUB = ("HUBFLOW_", "HUB_SESSION", "TMUX", "DESK_", "CLAUDE_PROJECT_DIR")
LID = re.compile(r"^L-\d{8}T\d{6}Z-[0-9a-f]{6}$")

# (name, anchor in desk.py that must occur once, replacement)
MUTANTS = [
    ("deliver-to-non-owner", "if x[\"id\"] not in seen and name in owners(c, x, kbi)]", "if x[\"id\"] not in seen]"),
    ("stop-hook-active-ignored", "if stop and data.get(\"stop_hook_active\") is True:", "if False:"),
    ("wake-types-into-busy", "elif not st or st.get(\"state\") != \"idle\" or not st.get(\"tmux_pane\"):",
     "elif not st or not st.get(\"tmux_pane\"):"),
    ("wake-ignores-blocked", "elif not blocked[s]:", "elif False:"),
    ("seen-not-recorded", "store.add_event(x[\"id\"], \"seen\", name)", "pass"),
    ("retired-owner-live", "lv = [s for s in own if s in live]", "lv = list(own)"),
    ("send-skips-fsync-and-write", "append_line(os.path.join(desk_dir(hub), \"letters.jsonl\"), letter)  # stored",
     "None  # stored"),
]


class Run:
    def __init__(self, desk, quiet=False):
        self.desk, self.quiet, self.results = desk, quiet, []

    def check(self, name, ok, detail=""):
        self.results.append(bool(ok))
        if not self.quiet:
            print(("PASS " if ok else "FAIL ") + name + ("" if ok else ": " + str(detail)[:600]))


def env_base(extra=None):
    env = {k: v for k, v in os.environ.items() if not k.startswith(SCRUB)}
    env.update(extra or {})
    return env


def make_hub(r, root, name="hub"):
    h = os.path.join(root, name)
    sd = os.path.join(h, ".claude", "scripts")
    os.makedirs(sd)
    shutil.copy(HUBFLOW, sd)
    shutil.copy(r.desk, os.path.join(sd, "desk.py"))
    seed = os.path.join(root, name + "-seed.json")
    with open(seed, "w") as f:
        json.dump(SEED, f)
    code, out, err = hf(h, "init", "--seed", seed, session=None)
    if code:
        raise RuntimeError("init failed: " + err)
    return h


def hf(h, *args, session="discovery", now=NOW):
    env = env_base({"HUBFLOW_NOW": now})
    if session:
        env["HUB_SESSION"] = session
    p = subprocess.run([sys.executable, "-I", os.path.join(h, ".claude", "scripts", "hubflow.py"), "--hub", h]
                       + [str(a) for a in args], capture_output=True, text=True, env=env, cwd=h)
    return p.returncode, p.stdout.strip(), p.stderr


def hfo(h, *args, **kw):
    code, out, err = hf(h, *args, **kw)
    if code:
        raise RuntimeError(f"hubflow {args} failed: {err}")
    return out


def desk(h, *args, stdin=None, env=None, cwd=None, hub=True):
    e = env_base(env)
    cmd = [sys.executable, "-I", os.path.join(h, ".claude", "scripts", "desk.py")] + (["--hub", h] if hub else [])
    p = subprocess.run(cmd + [str(a) for a in args], capture_output=True, text=True, env=e, cwd=cwd or h,
                       input=stdin)
    return p.returncode, p.stdout, p.stderr


def text_file(root, text):
    fd, p = tempfile.mkstemp(dir=root, suffix=".txt")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(text)
    return p


def send(h, root, item, text, kind="answer", choice=None, env=None):
    args = ["send", "--kind", kind, "--item-json", json.dumps(item), "--text-file", text_file(root, text)]
    if choice:
        args += ["--choice", choice]
    code, out, err = desk(h, *args, env=env)
    if code:
        raise RuntimeError(f"send failed: {err}")
    return json.loads(out)["id"]


def status(h):
    code, out, err = desk(h, "status", "--json")
    if code:
        raise RuntimeError(f"status failed: {err}")
    return json.loads(out)


def letter_of(st, lid):
    return next(x for x in st["letters"] if x["id"] == lid)


def hook(h, session, event, cwd=None, extra=None, env=None, hub=False):
    data = {"hook_event_name": event, "session_id": "sid-" + (session or "none"), "cwd": cwd or h}
    data.update(extra or {})
    e = dict(env or {})
    if session:
        e["HUB_SESSION"] = session
    code, out, err = desk(h, "hook", stdin=json.dumps(data), env=e, cwd=cwd or h, hub=hub)
    return code, out, err


def events(h):
    p = os.path.join(h, "flow", "desk", "events.jsonl")
    if not os.path.exists(p):
        return []
    return [json.loads(x) for x in open(p, encoding="utf-8") if x.strip()]


def lines(h, name="letters.jsonl"):
    p = os.path.join(h, "flow", "desk", name)
    return open(p, encoding="utf-8").read().split("\n") if os.path.exists(p) else []


def ask_item(i):
    return {"type": "ask", "id": i}


def q_item(slug, q="q3"):
    return {"type": "question", "slug": slug, "kb": f"specs/{slug}", "q": q}


# ---- cases ----

def case_send(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--title", "Which database?", "--waits-on", "me", "--status", "waiting")
    lid = send(h, root, ask_item(a), "Use SQLite.")
    r.check("send-prints-id", LID.match(lid), lid)
    got = [json.loads(x) for x in lines(h) if x.strip()]
    r.check("send-line-on-disk-at-return", len(got) == 1 and got[0]["id"] == lid and got[0]["text"] == "Use SQLite."
            and got[0]["item"] == ask_item(a) and got[0]["kind"] == "answer" and got[0]["by"] == "human"
            and got[0]["choice"] is None, got)
    l2 = send(h, root, q_item("x"), "", choice="yes")
    r.check("send-answer-choice-no-text", json.loads(lines(h)[1])["choice"] == "yes", lines(h))
    st = status(h)
    r.check("status-letters-newest-first", [x["id"] for x in st["letters"]] == [l2, lid], st["letters"])
    bad = [("diverge-empty", ["--kind", "diverge", "--item-json", json.dumps(ask_item(a)), "--choice", "yes"], ""),
           ("bad-kind", ["--kind", "nope", "--item-json", json.dumps(ask_item(a))], "x"),
           ("bad-item-type", ["--kind", "answer", "--item-json", '{"type": "bogus"}'], "x"),
           ("item-extra-key", ["--kind", "answer", "--item-json", '{"type": "ask", "id": "A-0001", "x": 1}'], "x"),
           ("item-not-json", ["--kind", "answer", "--item-json", "{"], "x"),
           ("question-abs-kb", ["--kind", "answer", "--item-json",
                                json.dumps({"type": "question", "slug": "x", "kb": "/etc", "q": "q1"})], "x"),
           ("empty-answer-no-choice", ["--kind", "answer", "--item-json", json.dumps(ask_item(a))], "  \n")]
    for name, args, text in bad:
        code, out, err = desk(h, "send", *args, "--text-file", text_file(root, text))
        r.check("send-refuses-" + name, code == 1 and out == "" and err.startswith("desk: "), (code, out, err))
    r.check("send-refused-stores-nothing", len([x for x in lines(h) if x.strip()]) == 2, lines(h))
    nohub = os.path.join(root, "nohub")
    os.makedirs(nohub)
    p = subprocess.run([sys.executable, "-I", DESK, "status", "--json"], capture_output=True, text=True,
                       cwd=nohub, env=env_base())
    r.check("no-hub-exit-2-one-line", p.returncode == 2 and p.stderr.count("\n") == 1 and "no hub" in p.stderr,
            (p.returncode, p.stderr))
    sub = os.path.join(h, "specs", "deep")
    os.makedirs(sub)
    code, out, err = desk(h, "status", "--json", cwd=sub, hub=False)
    r.check("hub-found-walking-up", code == 0 and json.loads(out)["letters"], err)


def case_send_order(r, root):
    h = make_hub(r, root)
    l1 = send(h, root, q_item("y"), "second KB first")
    l2 = send(h, root, ask_item("A-0009"), "an ask that does not exist yet")
    ids = [json.loads(x)["id"] for x in lines(h) if x.strip()]
    r.check("two-sends-both-stored", ids == [l1, l2], ids)
    tf = text_file(root, "parallel")
    ps = [subprocess.Popen([sys.executable, "-I", os.path.join(h, ".claude", "scripts", "desk.py"), "--hub", h,
                            "send", "--kind", "requirement", "--item-json", json.dumps(ask_item("A-0001")),
                            "--text-file", tf], stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env_base())
          for _ in range(12)]
    outs = [json.loads(p.communicate()[0])["id"] for p in ps]
    got = [json.loads(x) for x in lines(h) if x.strip()]
    r.check("parallel-sends-all-stored-whole", len(got) == 14 and set(outs) <= {x["id"] for x in got}
            and len(set(outs)) == 12, len(got))
    st = status(h)
    r.check("unknown-ask-no-live-owner", letter_of(st, l2)["no_live_owner"] is True
            and letter_of(st, l2)["item_closed"] is None, letter_of(st, l2))


def case_events(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--title", "Which database?", "--status", "waiting")
    lid = send(h, root, ask_item(a), "SQLite")
    st = letter_of(status(h), lid)
    r.check("state-sent", st["state"] == "sent" and st["seen"] == [] and st["applied"] is None, st)
    hook(h, "discovery", "UserPromptSubmit")
    st = letter_of(status(h), lid)
    r.check("state-seen", st["state"] == "seen" and [x["session"] for x in st["seen"]] == ["discovery"], st)
    code, out, err = desk(h, "event", lid, "apply_failed", "--detail", "db locked")
    st = letter_of(status(h), lid)
    r.check("state-apply-failed", code == 0 and st["state"] == "apply_failed"
            and st["apply_failed"]["detail"] == "db locked" and st["applied"] is None, (err, st))
    desk(h, "event", lid, "applied", "--detail", "closed A-0001")
    st = letter_of(status(h), lid)
    r.check("state-applied-after-failed", st["state"] == "applied" and st["apply_failed"] is None
            and st["applied"]["detail"] == "closed A-0001", st)
    l2 = send(h, root, ask_item(a), "direct")
    desk(h, "event", l2, "applied")
    r.check("state-sent-to-applied", letter_of(status(h), l2)["state"] == "applied")
    code, out, err = desk(h, "event", "L-20260101T000000Z-abcdef", "applied")
    r.check("event-unknown-letter-exit-2", code == 2 and "no letter" in err, (code, err))
    code, out, err = desk(h, "event", lid, "seen")
    r.check("event-page-only-applied-or-failed", code != 0, (code, err))


def case_ownership(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--title", "Which database?", "--status", "waiting")
    hfo(h, "add", "thread", "--title", "KB z work", "--ref", "kb:z", session="build")
    hfo(h, "add", "thread", "--title", "KB z review", "--ref", "kb:specs/z", session="process")
    t = hfo(h, "add", "thread", "--title", "KB z closed", "--ref", "kb:z", session="support")
    hfo(h, "close", t, "--reason", "done", "--by", "human", "--note", "done", session="support")
    hfo(h, "add", "thread", "--title", "KB old form", "--ref", "kb:old/kb", session="build")
    hfo(h, "add", "thread", "--title", "KB r retired", "--ref", "kb:r", session="support")
    hfo(h, "session", "retire", "support", session="process")
    la = send(h, root, ask_item(a), "x")
    lz = send(h, root, q_item("z"), "x")
    lold = send(h, root, q_item("old"), "x")
    lr = send(h, root, q_item("r"), "x")
    ln = send(h, root, {"type": "kb", "slug": "none", "kb": "specs/none", "ref": "vote"}, "x", kind="diverge")
    st = status(h)
    x = letter_of(st, la)
    r.check("owner-ask", x["owners"] == ["discovery"] and x["live_owners"] == ["discovery"]
            and x["no_live_owner"] is False and x["item_closed"] is False, x)
    x = letter_of(st, lz)
    r.check("owner-question-two-sessions", x["owners"] == ["build", "process"] and x["no_live_owner"] is False, x)
    r.check("owner-old-ref-form", letter_of(st, lold)["owners"] == ["build"], letter_of(st, lold))
    x = letter_of(st, lr)
    r.check("owner-retired-no-live-owner", x["owners"] == ["support"] and x["live_owners"] == []
            and x["no_live_owner"] is True, x)
    x = letter_of(st, ln)
    r.check("owner-none-no-live-owner", x["owners"] == [] and x["no_live_owner"] is True, x)
    hfo(h, "close", a, "--reason", "done", "--session", "human", "--by", "human", "--note", "SQLite it is",
        session=None)
    x = letter_of(status(h), la)
    r.check("owner-closed-ask-keeps-owner", x["owners"] == ["discovery"] and x["item_closed"] is True, x)


def case_status(r, root):
    h = make_hub(r, root)
    old = "2026-10-20T12:00:00Z"
    a1 = hfo(h, "add", "ask", "--title", "Old closed ask", now=old)
    a2 = hfo(h, "add", "ask", "--title", "Recent closed ask", now=old)
    a3 = hfo(h, "add", "ask", "--title", "Open ask", "--status", "waiting", now=old)
    hfo(h, "close", a1, "--reason", "done", now="2026-10-23T12:00:00Z")
    hfo(h, "close", a2, "--reason", "done", "--session", "human", "--by", "human", "--note", "done, thanks",
        session=None, now="2026-11-01T12:00:00Z")
    hd = hfo(h, "handoff", "--to", "build", "--title", "Build KB y", "--ref", "kb:y")
    hd2 = hfo(h, "handoff", "--to", "process", "--title", "Accepted handoff")
    hfo(h, "accept", hd2, session="process")
    un = hfo(h, "add", "thread", "--title", "Nobody owns this", "--owner", "none")
    ret = hfo(h, "add", "thread", "--title", "Owned by retired", session="support")
    hfo(h, "session", "retire", "support")
    st = status(h)
    r.check("status-now-is-db-clock", st["now"] == NOW, st["now"])
    names = [s["name"] for s in st["sessions"]]
    r.check("status-sessions-by-name", names == ["build", "discovery", "process", "support"], names)
    b = next(s for s in st["sessions"] if s["name"] == "build")
    r.check("status-inbox-unaccepted", [(i["id"], i["unaccepted"]) for i in b["inbox"]] == [(hd, True)]
            and b["state"] is None, b)
    d = next(s for s in st["sessions"] if s["name"] == "discovery")
    r.check("status-inbox-ages", [i["id"] for i in d["inbox"]] == [a3]
            and d["inbox"][0]["age_days"] == 13 and d["inbox"][0]["status"] == "waiting", d)
    r.check("status-retired-session", next(s for s in st["sessions"] if s["name"] == "support")["status"] == "retired")
    uo = [x["id"] for x in st["orphans"]["unowned"]]
    r.check("orphans-unowned", uo == sorted([un, ret]), st["orphans"])
    ua = st["orphans"]["unaccepted"]
    r.check("orphans-unaccepted", [(x["id"], x["from"], x["to"]) for x in ua] == [(hd, "discovery", "build")], ua)
    r.check("kb-refs", st["kb_refs"] == {"y": [{"id": hd, "kind": "handoff", "title": "Build KB y", "status": "open",
                                                  "owner_session": "build"}]}, st["kb_refs"])
    cr = st["closed_recent"]
    r.check("closed-recent", [x["id"] for x in cr] == [a2] and cr[0]["by"] == "human"
            and cr[0]["by_session"] == "human" and cr[0]["note"] == "done, thanks"
            and cr[0]["close_reason"] == "done" and cr[0]["owner_session"] == "discovery", cr)
    r.check("status-empty-bad-lines", st["bad_lines"] == {"count": 0, "lines": []} and st["drafts"] == {}, st["bad_lines"])


def case_drafts(r, root):
    h = make_hub(r, root)
    code, out, err = desk(h, "draft", "ask:A-0002", "--text-file", text_file(root, "half a thought"),
                          "--choice", "b", "--intent", "answer")
    desk(h, "draft", "q:specs/x#q3", "--text-file", text_file(root, "other"))
    d = status(h)["drafts"]
    r.check("draft-saved-survives-reload", code == 0 and d["ask:A-0002"]["text"] == "half a thought"
            and d["ask:A-0002"]["choice"] == "b" and d["ask:A-0002"]["intent"] == "answer"
            and d["q:specs/x#q3"]["text"] == "other", (err, d))
    desk(h, "draft", "ask:A-0002", "--clear")
    d = status(h)["drafts"]
    r.check("draft-cleared", "ask:A-0002" not in d and "q:specs/x#q3" in d, d)
    code, out, err = desk(h, "draft", "k" * 301)
    r.check("draft-key-too-long", code == 1, (code, err))
    r.check("draft-file-is-json", isinstance(json.load(open(os.path.join(h, "flow", "desk", "drafts.json"))), dict))


def case_hook(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--title", "Which database?", "--status", "waiting")
    hfo(h, "add", "thread", "--title", "KB y build", "--ref", "kb:y", session="build")
    lid = send(h, root, ask_item(a), "Use SQLite, not Postgres.")
    code, out, err = hook(h, "build", "UserPromptSubmit")
    r.check("hook-non-owner-gets-nothing", code == 0 and out == "" and not events(h), (code, out, err))
    code, out, err = hook(h, "discovery", "UserPromptSubmit", env={"TMUX_PANE": "%7"})
    try:
        o = json.loads(out)
        ctx = o["hookSpecificOutput"]["additionalContext"]
        ok = o["hookSpecificOutput"]["hookEventName"] == "UserPromptSubmit" and "Use SQLite, not Postgres." in ctx \
            and f"- {a} (answer)" in ctx and ctx.startswith("Desk: Ty sent 1 response(s)")
    except (ValueError, KeyError) as e:
        ok, ctx = False, repr(e)
    r.check("hook-prompt-owner-gets-context", code == 0 and ok, (out, err))
    ev = events(h)
    r.check("hook-writes-seen", [(e["letter"], e["event"], e["session"]) for e in ev] == [(lid, "seen", "discovery")], ev)
    sj = json.load(open(os.path.join(h, "flow", "desk", "sessions", "discovery.json")))
    r.check("hook-state-busy-with-pane", sj["state"] == "busy" and sj["tmux_pane"] == "%7"
            and sj["event"] == "UserPromptSubmit" and sj["session_id"] == "sid-discovery", sj)
    code, out, err = hook(h, "discovery", "UserPromptSubmit")
    r.check("hook-once-only", code == 0 and out == "" and len(events(h)) == 1, out)
    hook(h, "discovery", "Stop")
    sj = json.load(open(os.path.join(h, "flow", "desk", "sessions", "discovery.json")))
    r.check("hook-stop-idle-no-pane", sj["state"] == "idle" and sj["tmux_pane"] is None, sj)
    l2 = send(h, root, ask_item(a), "One more thing.", kind="diverge")
    code, out, err = hook(h, "discovery", "Stop", extra={"stop_hook_active": True})
    r.check("hook-stop-active-gives-nothing", code == 0 and out == "" and len(events(h)) == 1, out)
    code, out, err = hook(h, "discovery", "Stop", extra={"stop_hook_active": False})
    try:
        o = json.loads(out)
        ok = o["decision"] == "block" and "One more thing." in o["reason"] and "(diverge)" in o["reason"]
    except (ValueError, KeyError):
        ok = False
    r.check("hook-stop-blocks", code == 0 and ok and events(h)[-1]["letter"] == l2, out)
    sj = json.load(open(os.path.join(h, "flow", "desk", "sessions", "discovery.json")))
    r.check("hook-stop-block-sets-busy", sj["state"] == "busy", sj)
    code, out, err = hook(h, "discovery", "SessionStart")
    r.check("hook-session-start-idle", out == "" and json.load(open(os.path.join(
        h, "flow", "desk", "sessions", "discovery.json")))["state"] == "idle", out)
    l3 = send(h, root, q_item("y"), "y answer", choice="b")
    code, out, err = hook(h, "build", "SessionStart")
    try:
        ctx = json.loads(out)["hookSpecificOutput"]["additionalContext"]
        ok = '- specs/y q3 (answer: b): "y answer"' in ctx and json.loads(out)["hookSpecificOutput"]["hookEventName"] == "SessionStart"
    except (ValueError, KeyError):
        ok = False
    r.check("hook-session-start-question-line", ok, out)
    l4 = send(h, root, q_item("y"), "via alias")
    hfo(h, "set", "T-0001", "--owner", "support", session="build")
    code, out, err = hook(h, "helpdesk", "UserPromptSubmit")
    r.check("hook-alias-resolves", "via alias" in out and os.path.exists(
        os.path.join(h, "flow", "desk", "sessions", "support.json")), (out, err))
    n = len(events(h))
    code, out, err = hook(h, None, "UserPromptSubmit")
    r.check("hook-no-hub-session-silent", code == 0 and out == "" and err == "" and len(events(h)) == n, (code, out, err))
    away = os.path.join(root, "away")
    os.makedirs(away)
    l5 = send(h, root, ask_item(a), "from afar")
    code, out, err = hook(h, "discovery", "UserPromptSubmit", cwd=away)
    r.check("hook-outside-hub-silent", code == 0 and out == "" and err == "", (code, out, err))
    code, out, err = hook(h, "discovery", "UserPromptSubmit", cwd=away, env={"CLAUDE_PROJECT_DIR": h})
    r.check("hook-project-dir-fallback", "from afar" in out, (out, err))
    code, out, err = desk(h, "hook", stdin="not json{", env={"HUB_SESSION": "discovery"})
    r.check("hook-bad-json-silent", code == 0 and out == "" and err == "", (code, out, err))
    code, out, err = desk(h, "hook", "--bogus", stdin="{}", env={"HUB_SESSION": "discovery"})
    r.check("hook-bad-args-silent", code == 0 and out == "", (code, out, err))
    with open(os.path.join(h, "flow", "flow.db"), "wb") as f:
        f.write(b"this is not a database" * 100)
    code, out, err = hook(h, "discovery", "UserPromptSubmit", hub=True)
    r.check("hook-db-broken-silent", code == 0 and out == "" and err == "", (code, out, err))


def case_notice_cut(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--title", "Which database?")
    long_id = send(h, root, ask_item(a), "word " * 400)
    for i in range(12):
        send(h, root, ask_item(a), f"letter {i} " + "x" * 200)
    code, out, err = hook(h, "discovery", "UserPromptSubmit")
    ctx = json.loads(out)["hookSpecificOutput"]["additionalContext"]
    r.check("notice-cut-names-letter", "…" in ctx and f"letters --id {long_id}" in ctx, ctx[:400])
    r.check("notice-under-cap", len(ctx) <= 1600, len(ctx))
    seen1 = len(events(h))
    r.check("notice-partial-seen", 0 < seen1 < 13 and "more response(s) follow" in ctx, seen1)
    for _ in range(13):
        code, out, err = hook(h, "discovery", "UserPromptSubmit")
        if not out:
            break
    r.check("notice-rest-follows", len(events(h)) == 13, len(events(h)))
    code, out, err = desk(h, "letters", "--id", long_id)
    r.check("letters-id-full-text", code == 0 and ("word " * 400).strip() in out, err)
    code, out, err = desk(h, "letters", "--json")
    r.check("letters-json", code == 0 and len(json.loads(out)) == 13, err)


def case_corrupt(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--title", "Which database?")
    l1 = send(h, root, ask_item(a), "first")
    p = os.path.join(h, "flow", "desk", "letters.jsonl")
    with open(p, "a") as f:
        f.write("{this is not json at all, it is a torn or hand-edited line}\n")
        f.write('{"no": "id"}\n')
    l2 = send(h, root, ask_item(a), "after the bad line")
    with open(p, "a") as f:
        f.write('{"id": "L-torn')  # a torn last line with no newline
    l3 = send(h, root, ask_item(a), "after a torn line")
    st = status(h)
    ids = [x["id"] for x in st["letters"]]
    r.check("corrupt-skipped-others-read", ids == [l3, l2, l1], ids)
    bl = st["bad_lines"]
    r.check("corrupt-reported", bl["count"] == 3 and bl["lines"][0]["text"].startswith("{this is not json")
            and len(bl["lines"][0]["text"]) <= 80 and bl["lines"][0]["file"] == "letters.jsonl", bl)
    code, out, err = hook(h, "discovery", "UserPromptSubmit")
    r.check("corrupt-hook-still-delivers", "after a torn line" in out and "first" in out, (out, err))
    with open(os.path.join(h, "flow", "desk", "drafts.json"), "w") as f:
        f.write("{broken")
    st = status(h)
    r.check("corrupt-drafts-reported", st["drafts"] == {} and any(x["file"] == "drafts.json"
                                                                   for x in st["bad_lines"]["lines"]), st["bad_lines"])


FAKE_TMUX = """#!/bin/sh
for a in "$@"; do printf '[%s]' "$a" >> "$FAKE_TMUX_LOG"; done
echo >> "$FAKE_TMUX_LOG"
if [ "$1" = display-message ]; then echo "${FAKE_TMUX_CMD:-claude}"; fi
exit 0
"""


def case_wake(r, root):
    h = make_hub(r, root)
    fake = os.path.join(root, "fake-tmux")
    with open(fake, "w") as f:
        f.write(FAKE_TMUX)
    os.chmod(fake, 0o755)
    logp = os.path.join(root, "tmux.log")

    def env(cmd="claude"):
        return {"DESK_TMUX": fake, "FAKE_TMUX_LOG": logp, "FAKE_TMUX_CMD": cmd}

    def calls():
        return open(logp).read().splitlines() if os.path.exists(logp) else []

    def reset():
        if os.path.exists(logp):
            os.remove(logp)

    def woken(lid):
        return [e for e in events(h) if e["letter"] == lid and e["event"] == "woken"]

    a = hfo(h, "add", "ask", "--title", "Which database?", "--status", "waiting")
    a_open = hfo(h, "add", "ask", "--title", "Not waiting ask")
    hfo(h, "add", "thread", "--title", "KB w held", "--ref", "kb:w", "--status", "waiting", session="build")
    hook(h, "discovery", "Stop", env={"TMUX_PANE": "%3"})
    hook(h, "build", "Stop", env={"TMUX_PANE": "%4"})
    lid = send(h, root, ask_item(a), "SQLite", env=env())
    c = calls()
    line = f"Desk: Ty sent a response for {a}. It is stored; read the Desk notice of this prompt."
    r.check("wake-idle-waiting-claude", c == ["[display-message][-p][-t][%3][#{pane_current_command}]",
                                              f"[send-keys][-t][%3][-l][{line}]", "[send-keys][-t][%3][Enter]"], c)
    r.check("wake-woken-event", [(e["session"]) for e in woken(lid)] == ["discovery"])
    reset()
    code, out, err = desk(h, "wake", lid, env=env())
    r.check("wake-already-woken-not-again", calls() == [] and "already woken" in err and len(woken(lid)) == 1,
            (calls(), err))
    reset()
    lq = send(h, root, q_item("w"), "w answer", env=env())
    r.check("wake-question-owner", any("[send-keys][-t][%4][-l][Desk: Ty sent a response for specs/w q3." in x
                                       for x in calls()) and woken(lq)[0]["session"] == "build", calls())
    reset()
    hook(h, "discovery", "UserPromptSubmit", env={"TMUX_PANE": "%3"})  # busy (and sees what it owns)
    l2 = send(h, root, ask_item(a), "again", env=env())
    r.check("wake-busy-not-called", calls() == [] and not woken(l2), calls())
    hook(h, "discovery", "Stop", extra={"stop_hook_active": True}, env={"TMUX_PANE": "%3"})  # idle, l2 unseen
    reset()
    l3 = send(h, root, ask_item(a_open), "not waiting", env=env())
    r.check("wake-not-blocked-not-called", calls() == [] and not woken(l3), calls())
    reset()
    code, out, err = desk(h, "wake", l2, env=env("zsh"))
    r.check("wake-zsh-pane-not-typed", not any("send-keys" in x for x in calls()) and not woken(l2)
            and "zsh" in err, (calls(), err))
    reset()
    hfo(h, "add", "thread", "--title", "KB v held", "--ref", "kb:v", "--status", "waiting", session="process")
    lv = send(h, root, q_item("v"), "v answer", env=env())
    r.check("wake-non-owner-not-called", not any("%3" in x or "%4" in x for x in calls()) and not woken(lv), calls())
    reset()
    code, out, err = desk(h, "wake", l2, env=env())
    r.check("wake-command-types-now", any("send-keys" in x for x in calls()) and len(woken(l2)) == 1, (calls(), err))
    reset()
    hfo(h, "add", "thread", "--title", "KB u held", "--ref", "kb:u", "--status", "waiting", session="support")
    hfo(h, "session", "retire", "support")
    hook(h, "support", "Stop", env={"TMUX_PANE": "%9"})
    lu = send(h, root, q_item("u"), "u answer", env=env())
    r.check("wake-retired-not-called", calls() == [] and not woken(lu), calls())
    code, out, err = desk(h, "wake", "L-20260101T000000Z-abcdef", env=env())
    r.check("wake-unknown-letter-exit-2", code == 2, (code, err))
    reset()
    l6 = send(h, root, ask_item(a), "tmux missing", env={"DESK_TMUX": os.path.join(root, "no-such-tmux")})
    r.check("wake-tmux-missing-send-still-ok", l6 and not woken(l6), l6)


def case_hooks_cmd(r, root):
    h = make_hub(r, root)
    code, out, err = desk(h, "hooks")
    try:
        o = json.loads(out)["hooks"]
        ok = sorted(o) == ["SessionStart", "Stop", "UserPromptSubmit"] and all(
            v == [{"hooks": [{"type": "command", "timeout": 10,
                              "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.claude/scripts/desk.py hook"}]}]
            for v in o.values())
    except (ValueError, KeyError):
        ok = False
    r.check("hooks-block", code == 0 and ok, out)


def case_db_read_only(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--title", "Which database?", "--status", "waiting")
    db = os.path.join(h, "flow", "flow.db")
    before = open(db, "rb").read()
    jl = sorted(os.listdir(os.path.join(h, "flow", "jsonl")))
    send(h, root, ask_item(a), "x")
    status(h)
    hook(h, "discovery", "UserPromptSubmit")
    r.check("db-not-written", open(db, "rb").read() == before
            and sorted(os.listdir(os.path.join(h, "flow", "jsonl"))) == jl)
    code, out, err = hf(h, "check")
    r.check("hubflow-check-clean", code == 0, err)


CASES = [case_send, case_send_order, case_events, case_ownership, case_status, case_drafts, case_hook,
         case_notice_cut, case_corrupt, case_wake, case_hooks_cmd, case_db_read_only]


def run_all(r, only):
    for fn in CASES:
        if only and fn.__name__ not in only:
            continue
        root = tempfile.mkdtemp(prefix="desk-test-")
        try:
            fn(r, root)
        except Exception as e:
            r.check("scenario-ran " + fn.__name__, False, repr(e))
        finally:
            shutil.rmtree(root, ignore_errors=True)


def main():
    sys.stdout.reconfigure(line_buffering=True)
    args = sys.argv[1:]
    only = {args[i + 1] for i, a in enumerate(args) if a == "--case" and i + 1 < len(args)}
    r = Run(DESK)
    run_all(r, only)
    total, passed = len(r.results), r.results.count(True)
    if "--mutants" in args:
        src = open(DESK, encoding="utf-8").read()
        for name, anchor, repl in MUTANTS:
            total += 1
            if src.count(anchor) != 1:
                print(f"FAIL mutant {name}: anchor occurs {src.count(anchor)} times")
                continue
            d = tempfile.mkdtemp(prefix="desk-mutant-")
            path = os.path.join(d, "desk.py")
            with open(path, "w", encoding="utf-8") as f:
                f.write(src.replace(anchor, repl))
            m = Run(path, quiet=True)
            run_all(m, only)
            shutil.rmtree(d, ignore_errors=True)
            killed = not all(m.results)
            passed += killed
            print(("PASS" if killed else "FAIL") + f" mutant {name}: " + ("KILLED" if killed else "SURVIVED"))
    print(f"{passed} passed, {total - passed} failed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()

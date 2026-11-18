#!/usr/bin/env python3
"""Test for desk.py. Each case builds a hub in a temp dir (hubflow.py and desk.py copied into its
.claude/scripts/, the db made by hubflow.py with a fixed clock, HUBFLOW_NOW), never the real hub.
tmux is a fake program (DESK_TMUX) that logs its arguments; the real tmux server is never touched.
HOME, DESK_STATE, XDG_STATE_HOME and XDG_CONFIG_HOME point into the case's temp dir, so the Desk's
state dir and the systemd unit dir are never the real ones.

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
SCRUB = ("HUBFLOW_", "HUB_SESSION", "TMUX", "DESK_", "CLAUDE_PROJECT_DIR", "XDG_", "HOME")
CUR = {"root": None}  # the temp dir of the running case
LID = re.compile(r"^L-\d{8}T\d{6}Z-[0-9a-f]{6}$")

# (name, anchor in desk.py that must occur once, replacement)
MUTANTS = [
    ("deliver-to-non-recipient", "if x[\"id\"] not in seen and name in recipients(c, x, kbi)]", "if x[\"id\"] not in seen]"),
    ("hook-ignores-to", "return [to] if to else owners(c, letter, kbi)", "return owners(c, letter, kbi)"),
    ("delivery-cuts-text", "{letter.get('text') or ''}", "{(letter.get('text') or '')[:1000]}"),
    ("render-differs-from-delivery", "out = delivered_text({\"about\": about, \"text\": text})",
     "out = delivered_text({\"about\": about, \"text\": text.strip()})"),
    ("notice-drops-a-long-letter", "if held and size + add > NOTICE_MAX:", "if size + add > NOTICE_MAX:"),
    ("notice-joins-with-one-newline", "return \"\\n\\n\".join(parts), held", "return \"\\n\".join(parts), held"),
    ("wake-types-other-line", "line = wake_text(about_of(letter))", "line = wake_text(item_name(letter))"),
    ("send-to-unchecked", "    if s is None:\n        raise Bad(f\"--to", "    if False:\n        raise Bad(f\"--to"),
    ("late-unseen-threshold", "LATE_SECONDS = 24 * 3600", "LATE_SECONDS = 26 * 3600"),
    ("hooks-ignore-other-settings", "hooks_missing(hub, settings_files(hub))", "hooks_missing(hub)"),
    ("late-unseen-ignores-seen", "late = bool(not seen and at_s", "late = bool(at_s"),
    ("drafts-in-the-hub", "def drafts_dir():\n    return state_dir()",
     "def drafts_dir():\n    return os.path.join(os.getcwd(), \"flow\", \"desk\")"),
    ("join-name-clash-allowed", "        if clash:\n", "        if False:\n"),
    ("join-not-idempotent", "        if not mine:\n", "        if True:\n"),
    ("service-drops-desk-state", "    if state:\n        lines.append", "    if False:\n        lines.append"),
    ("outside-kb-ref-cut", "if ref.startswith((\"/\", \"~\")):", "if False:"),
    ("status-no-session-id", "session_id=st.get(\"session_id\"), inbox=inbox", "session_id=None, inbox=inbox"),
    ("abs-kb-refused", "if not isinstance(v, str) or not v.strip() or \"..\" in v.split(\"/\")",
     "if not isinstance(v, str) or not v.strip() or v.startswith(\"/\") or \"..\" in v.split(\"/\")"),
    ("fix-item-any-kind", "if it[\"type\"] == \"fix\" and a.kind not in FIX_KINDS:", "if False:"),
    ("fix-name-no-ids", "return (f\"fix {it.get('what')}\" + (\" \" + \", \".join(ids) if ids else \"\"))[:200]",
     "return f\"fix {it.get('what')}\""),
    ("kb-handoffs-unaccepted-first", "lst.sort(key=lambda r: (r[\"accepted_at\"] is None,",
     "lst.sort(key=lambda r: (r[\"accepted_at\"] is not None,"),
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
    root = CUR["root"]
    env.update({"HOME": os.path.join(root, "home"), "DESK_STATE": os.path.join(root, "desk-state"),
                "XDG_STATE_HOME": os.path.join(root, "xdg-state"), "XDG_CONFIG_HOME": os.path.join(root, "xdg-config")})
    for k, v in (extra or {}).items():
        if v is None:
            env.pop(k, None)
        else:
            env[k] = v
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


def about_for(item):
    return "the ask " + item["id"] if item["type"] == "ask" else f"{item.get('q') or item.get('ref')} in the KB {item['slug']}"


def send(h, root, item, text, to="discovery", kind="answer", choice=None, env=None, about=None):
    args = ["send", "--kind", kind, "--item-json", json.dumps(item), "--to", to, "--about", about or about_for(item),
            "--text-file", text_file(root, text)]
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


def put_letter(h, **fields):
    """Append a letter line by hand: an old letter (no to, no about) or one with a chosen time."""
    x = {"id": "L-20261101T000000Z-" + os.urandom(3).hex(), "at": "2026-11-01T00:00:00Z", "kind": "answer",
         "text": "x", "choice": None, "by": "human"}
    x.update(fields)
    d = os.path.join(h, "flow", "desk")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "letters.jsonl"), "a", encoding="utf-8") as f:
        f.write(json.dumps(x) + "\n")
    return x["id"]


def delivered(about, text):
    """The rule of delivered_text, written out here so that the test does not use desk.py's own."""
    return f"Letter from Ty (the Desk), about {about}:\n{text}"


def ctx_of(out):
    o = json.loads(out)
    return o["reason"] if "decision" in o else o["hookSpecificOutput"]["additionalContext"]


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
    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Which database?", "--waits-on", "me", "--status", "waiting")
    lid = send(h, root, ask_item(a), "Use SQLite.")
    r.check("send-prints-id", LID.match(lid), lid)
    got = [json.loads(x) for x in lines(h) if x.strip()]
    r.check("send-line-on-disk-at-return", len(got) == 1 and got[0]["id"] == lid and got[0]["text"] == "Use SQLite."
            and got[0]["item"] == ask_item(a) and got[0]["kind"] == "answer" and got[0]["by"] == "human"
            and got[0]["choice"] is None and got[0]["to"] == "discovery" and got[0]["about"] == "the ask " + a, got)
    l2 = send(h, root, q_item("x"), "Yes: keep it.", choice="yes", to="helpdesk", about="question q3 in the KB x")
    x2 = json.loads(lines(h)[1])
    r.check("send-choice-and-alias-to", x2["choice"] == "yes" and x2["to"] == "support"
            and x2["about"] == "question q3 in the KB x", x2)
    l3 = send(h, root, ask_item(a), "Fix: give A-0001 an owner.", kind="fix", to="build")
    l4 = send(h, root, ask_item(a), "I closed A-0001.", kind="notice", to="process")
    r.check("send-kinds-fix-notice", [json.loads(x)["kind"] for x in lines(h) if x.strip()][2:] == ["fix", "notice"])
    st = status(h)
    r.check("status-letters-newest-first", [x["id"] for x in st["letters"]] == [l4, l3, l2, lid], st["letters"])
    ok = ["--to", "discovery", "--about", "the ask A-0001"]
    item = ["--item-json", json.dumps(ask_item(a))]
    bad = [("diverge-empty", ["--kind", "diverge"] + item + ["--choice", "yes"] + ok, ""),
           ("choice-no-text", ["--kind", "answer"] + item + ["--choice", "yes"] + ok, ""),
           ("bad-kind", ["--kind", "nope"] + item + ok, "x"),
           ("bad-item-type", ["--kind", "answer", "--item-json", '{"type": "bogus"}'] + ok, "x"),
           ("item-extra-key", ["--kind", "answer", "--item-json", '{"type": "ask", "id": "A-0001", "x": 1}'] + ok, "x"),
           ("item-not-json", ["--kind", "answer", "--item-json", "{"] + ok, "x"),
           ("question-dotdot-kb", ["--kind", "answer", "--item-json",
                                   json.dumps({"type": "question", "slug": "x", "kb": "/a/../etc", "q": "q1"})] + ok, "x"),
           ("question-rel-dotdot-kb", ["--kind", "answer", "--item-json",
                                       json.dumps({"type": "question", "slug": "x", "kb": "../x", "q": "q1"})] + ok, "x"),
           ("fix-item-with-answer", ["--kind", "answer", "--item-json", json.dumps({"type": "fix", "what": "link"})] + ok, "x"),
           ("fix-bad-what", ["--kind", "fix", "--item-json", json.dumps({"type": "fix", "what": "Link"})] + ok, "x"),
           ("fix-long-what", ["--kind", "fix", "--item-json", json.dumps({"type": "fix", "what": "a" * 41})] + ok, "x"),
           ("fix-too-many-ids", ["--kind", "fix", "--item-json",
                                 json.dumps({"type": "fix", "what": "link", "ids": ["A-0001"] * 51})] + ok, "x"),
           ("fix-id-not-string", ["--kind", "fix", "--item-json",
                                  json.dumps({"type": "fix", "what": "link", "ids": [3]})] + ok, "x"),
           ("fix-extra-key", ["--kind", "fix", "--item-json",
                              json.dumps({"type": "fix", "what": "link", "x": 1})] + ok, "x"),
           ("empty-answer-no-choice", ["--kind", "answer"] + item + ok, "  \n"),
           ("unknown-to", ["--kind", "answer"] + item + ["--to", "nobody", "--about", "the ask A-0001"], "x"),
           ("about-two-lines", ["--kind", "answer"] + item + ["--to", "discovery", "--about", "a\nb"], "x"),
           ("about-empty", ["--kind", "answer"] + item + ["--to", "discovery", "--about", " "], "x")]
    for name, args, text in bad:
        code, out, err = desk(h, "send", *args, "--text-file", text_file(root, text))
        r.check("send-refuses-" + name, code == 1 and out == "" and err.startswith("desk: "), (code, out, err))
    r.check("send-refused-stores-nothing", len([x for x in lines(h) if x.strip()]) == 4, lines(h))
    # serve questions --hub (the page of round 1) sends no --to and no --about: the letter has neither,
    # and the hook gives it to the item's owners (the old rule). The Desk always gives both.
    code, out, err = desk(h, "send", "--kind", "answer", *item, "--text-file", text_file(root, "old page"))
    last = json.loads([x for x in lines(h) if x.strip()][-1])
    r.check("send-without-to-is-an-old-letter", code == 0 and "to" not in last and "about" not in last
            and last["text"] == "old page", (code, err, last))
    qa = {"type": "question", "slug": "kb-ux", "kb": "/home/ty/Projects/mine/sag/tmp/kb-ux", "q": "q2"}
    fx = {"type": "fix", "what": "unaccepted", "ids": ["H-0003", "H-0007"]}
    fx0 = {"type": "fix", "what": "nokb"}
    l5 = send(h, root, qa, "outside KB answer")
    l6 = send(h, root, fx, "Accept H-0003 or hand it back.", kind="fix", to="build", about="the unaccepted handoffs")
    l7 = send(h, root, fx0, "Old asks have no KB.", kind="notice", to="process", about="asks with no KB")
    st = status(h)
    r.check("send-abs-kb-and-fix-items-kept-as-sent", letter_of(st, l5)["item"] == qa and letter_of(st, l6)["item"] == fx
            and letter_of(st, l7)["item"] == fx0, [letter_of(st, x)["item"] for x in (l5, l6, l7)])
    lold = put_letter(h, item=fx, text="old fix")
    code, out, err = desk(h, "letters")
    r.check("item-name-fix", "fix unaccepted H-0003, H-0007: old fix" in out and "fix nokb: Old asks" in out
            and "/home/ty/Projects/mine/sag/tmp/kb-ux q2: outside" in out, out)
    big = put_letter(h, item={"type": "fix", "what": "stale", "ids": ["A-%04d" % i for i in range(50)]}, text="big")
    code, out, err = desk(h, "letters", "--id", big)
    head = out.split("\n")[0]
    r.check("item-name-fix-cut-200", "fix stale A-0000, A-0001" in head
            and len(head.split(" answer ", 1)[1]) == 200, head)
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
                            "--to", "build", "--about", "the ask A-0001", "--text-file", tf], stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env_base())
          for _ in range(12)]
    outs = [json.loads(p.communicate()[0])["id"] for p in ps]
    got = [json.loads(x) for x in lines(h) if x.strip()]
    r.check("parallel-sends-all-stored-whole", len(got) == 14 and set(outs) <= {x["id"] for x in got}
            and len(set(outs)) == 12, len(got))
    hfo(h, "session", "retire", "support", session="process")
    l3 = send(h, root, ask_item("A-0009"), "to a retired session", to="support")
    st = status(h)
    r.check("unknown-ask-item-closed-none", letter_of(st, l2)["no_live_owner"] is False
            and letter_of(st, l2)["owners"] == ["discovery"] and letter_of(st, l2)["item_closed"] is None, letter_of(st, l2))
    r.check("to-retired-no-live-owner", letter_of(st, l3)["no_live_owner"] is True
            and letter_of(st, l3)["owners"] == ["support"] and letter_of(st, l3)["live_owners"] == [], letter_of(st, l3))


def case_events(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Which database?", "--status", "waiting")
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
    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Which database?", "--status", "waiting")
    hfo(h, "add", "thread", "--title", "KB z work", "--ref", "kb:z", session="build")
    hfo(h, "add", "thread", "--title", "KB z review", "--ref", "kb:specs/z", session="process")
    t = hfo(h, "add", "thread", "--title", "KB z closed", "--ref", "kb:z", session="support")
    hfo(h, "close", t, "--reason", "done", "--by", "human", "--note", "done", session="support")
    hfo(h, "add", "thread", "--title", "KB old form", "--ref", "kb:old/kb", session="build")
    hfo(h, "add", "thread", "--title", "KB r retired", "--ref", "kb:r", session="support")
    hfo(h, "session", "retire", "support", session="process")
    la = put_letter(h, item=ask_item(a))  # old letters: no to, so the owners of the item
    lz = put_letter(h, item=q_item("z"))
    lold = put_letter(h, item=q_item("old"))
    lr = put_letter(h, item=q_item("r"))
    ln = put_letter(h, item={"type": "kb", "slug": "none", "kb": "specs/none", "ref": "vote"}, kind="diverge")
    lt = send(h, root, q_item("z"), "only process", to="process")
    st = status(h)
    x = letter_of(st, lt)
    r.check("to-is-the-one-recipient", x["owners"] == ["process"] and x["to"] == "process" and x["no_live_owner"] is False, x)
    r.check("old-letter-to-about-null", letter_of(st, la)["to"] is None and letter_of(st, la)["about"] is None,
            letter_of(st, la))
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
    a1 = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Old closed ask", now=old)
    a2 = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Recent closed ask", now=old)
    a3 = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Open ask", "--status", "waiting", now=old)
    hfo(h, "close", a1, "--reason", "done", now="2026-10-23T12:00:00Z")
    hfo(h, "close", a2, "--reason", "done", "--session", "human", "--by", "human", "--note", "done, thanks",
        session=None, now="2026-11-01T12:00:00Z")
    hd = hfo(h, "handoff", "--to", "build", "--title", "Build KB y", "--ref", "kb:y")
    hd2 = hfo(h, "handoff", "--to", "process", "--title", "Accepted handoff")
    hfo(h, "accept", hd2, session="process")
    hd3 = hfo(h, "handoff", "--to", "process", "--title", "Older KB y work", "--ref", "kb:y", now=old)
    hfo(h, "accept", hd3, session="process", now="2026-10-21T12:00:00Z")
    hd4 = hfo(h, "handoff", "--to", "build", "--title", "Closed KB y work", "--ref", "kb:y", now=old)
    hfo(h, "close", hd4, "--reason", "done", "--by", "human", "--note", "done", session="build", now=old)
    hook(h, "build", "SessionStart")
    un = hfo(h, "add", "thread", "--title", "Nobody owns this", "--owner", "none")
    ret = hfo(h, "add", "thread", "--title", "Owned by retired", session="support")
    hfo(h, "session", "retire", "support")
    st = status(h)
    r.check("status-now-is-db-clock", st["now"] == NOW, st["now"])
    names = [s["name"] for s in st["sessions"]]
    r.check("status-sessions-by-name", names == ["build", "discovery", "process", "support"], names)
    b = next(s for s in st["sessions"] if s["name"] == "build")
    r.check("status-inbox-unaccepted", [(i["id"], i["unaccepted"]) for i in b["inbox"]] == [(hd, True)]
            and b["state"] == "idle", b)
    r.check("status-session-id", b["session_id"] == "sid-build"
            and next(s for s in st["sessions"] if s["name"] == "process")["session_id"] is None, st["sessions"])
    kh = st["kb_handoffs"]
    r.check("status-kb-handoffs", kh == {"y": [
        {"id": hd3, "from": "discovery", "to": "process", "accepted_at": "2026-10-21T12:00:00Z", "opened_at": old},
        {"id": hd, "from": "discovery", "to": "build", "accepted_at": None, "opened_at": NOW}]}, kh)
    d = next(s for s in st["sessions"] if s["name"] == "discovery")
    r.check("status-inbox-ages", [i["id"] for i in d["inbox"]] == [a3]
            and d["inbox"][0]["age_days"] == 13 and d["inbox"][0]["status"] == "waiting", d)
    r.check("status-retired-session", next(s for s in st["sessions"] if s["name"] == "support")["status"] == "retired")
    uo = [x["id"] for x in st["orphans"]["unowned"]]
    r.check("orphans-unowned", uo == sorted([un, ret]), st["orphans"])
    ua = st["orphans"]["unaccepted"]
    r.check("orphans-unaccepted", [(x["id"], x["from"], x["to"]) for x in ua] == [(hd, "discovery", "build")], ua)
    r.check("kb-refs", st["kb_refs"] == {"y": [{"id": hd, "kind": "handoff", "title": "Build KB y", "status": "open",
                                                  "owner_session": "build"},
                                                 {"id": hd3, "kind": "handoff", "title": "Older KB y work",
                                                  "status": "open", "owner_session": "process"}]}, st["kb_refs"])
    cr = st["closed_recent"]
    r.check("closed-recent", [x["id"] for x in cr] == [a2] and cr[0]["by"] == "human"
            and cr[0]["by_session"] == "human" and cr[0]["note"] == "done, thanks"
            and cr[0]["close_reason"] == "done" and cr[0]["owner_session"] == "discovery", cr)
    r.check("status-empty-bad-lines", st["bad_lines"] == {"count": 0, "lines": []}, st["bad_lines"])
    r.check("status-has-no-drafts", "drafts" not in st, sorted(st))


def case_drafts(r, root):
    h = make_hub(r, root)
    state = os.path.join(root, "desk-state")
    old = os.path.join(h, "flow", "desk", "drafts.json")
    os.makedirs(os.path.dirname(old))
    with open(old, "w") as f:
        json.dump({"ask:A-0009": {"text": "an old draft in the hub", "choice": None, "intent": None, "at": NOW}}, f)
    away = os.path.join(root, "away")
    os.makedirs(away)
    code, out, err = desk(h, "draft", "ask:A-0002", "--text-file", text_file(root, "half a thought"),
                          "--choice", "b", "--intent", "answer", cwd=away, hub=False)
    desk(h, "draft", "q:specs/x#q3", "--text-file", text_file(root, "other"), cwd=away, hub=False)

    def drafts():
        c, o, e = desk(h, "drafts", "--json", cwd=away, hub=False)
        return json.loads(o) if c == 0 else {"error": e}

    d = drafts()["drafts"]
    r.check("draft-saved-no-hub-needed", code == 0 and d["ask:A-0002"]["text"] == "half a thought"
            and d["ask:A-0002"]["choice"] == "b" and d["ask:A-0002"]["intent"] == "answer"
            and d["q:specs/x#q3"]["text"] == "other", (err, d))
    r.check("draft-in-desk-state-not-hub", os.path.isfile(os.path.join(state, "drafts.json"))
            and json.load(open(old)) == {"ask:A-0009": {"text": "an old draft in the hub", "choice": None,
                                                         "intent": None, "at": NOW}}
            and not os.path.exists(os.path.join(h, "flow", "desk", "drafts.lock")), os.listdir(os.path.dirname(old)))
    r.check("old-hub-drafts-not-read", "ask:A-0009" not in d and "drafts" not in status(h), d)
    desk(h, "draft", "ask:A-0002", "--clear", cwd=h)
    d = drafts()["drafts"]
    r.check("draft-cleared", "ask:A-0002" not in d and "q:specs/x#q3" in d, d)
    code, out, err = desk(h, "draft", "k" * 301)
    r.check("draft-key-too-long", code == 1, (code, err))
    r.check("draft-file-is-json", isinstance(json.load(open(os.path.join(state, "drafts.json"))), dict))
    code, out, err = desk(h, "draft", "k1", "--text-file", text_file(root, "xdg"), cwd=away, hub=False,
                          env={"DESK_STATE": None})
    r.check("draft-xdg-state-home", code == 0 and json.load(open(os.path.join(
        root, "xdg-state", "desk", "drafts.json")))["k1"]["text"] == "xdg", (code, err))
    code, out, err = desk(h, "drafts", cwd=away, hub=False)
    r.check("drafts-text", code == 0 and "q:specs/x#q3" in out and "other" in out, (out, err))


def case_hook(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Which database?", "--status", "waiting")
    hfo(h, "add", "thread", "--title", "KB y build", "--ref", "kb:y", session="build")
    lid = send(h, root, ask_item(a), "Use SQLite, not Postgres.\n", about="question 2 of the ask " + a)
    code, out, err = hook(h, "build", "UserPromptSubmit")
    r.check("hook-non-recipient-gets-nothing", code == 0 and out == "" and not events(h), (code, out, err))
    code, out, err = hook(h, "discovery", "UserPromptSubmit", env={"TMUX_PANE": "%7"})
    try:
        o = json.loads(out)
        ctx = o["hookSpecificOutput"]["additionalContext"]
        ok = o["hookSpecificOutput"]["hookEventName"] == "UserPromptSubmit" \
            and ctx == delivered("question 2 of the ask " + a, "Use SQLite, not Postgres.\n")
    except (ValueError, KeyError) as e:
        ok, ctx = False, repr(e)
    r.check("hook-prompt-recipient-gets-exact-text", code == 0 and ok, (out, err))
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
        ok = o["decision"] == "block" and o["reason"] == delivered("the ask " + a, "One more thing.")
    except (ValueError, KeyError):
        ok = False
    r.check("hook-stop-blocks", code == 0 and ok and events(h)[-1]["letter"] == l2, out)
    sj = json.load(open(os.path.join(h, "flow", "desk", "sessions", "discovery.json")))
    r.check("hook-stop-block-sets-busy", sj["state"] == "busy", sj)
    code, out, err = hook(h, "discovery", "SessionStart")
    r.check("hook-session-start-idle", out == "" and json.load(open(os.path.join(
        h, "flow", "desk", "sessions", "discovery.json")))["state"] == "idle", out)
    l3 = send(h, root, q_item("y"), "b: y answer", choice="b", to="build")
    code, out, err = hook(h, "build", "SessionStart")
    try:
        ctx = json.loads(out)["hookSpecificOutput"]["additionalContext"]
        ok = ctx == delivered("q3 in the KB y", "b: y answer") \
            and json.loads(out)["hookSpecificOutput"]["hookEventName"] == "SessionStart"
    except (ValueError, KeyError):
        ok = False
    r.check("hook-session-start-question", ok, out)
    l4 = send(h, root, q_item("y"), "y via alias", to="helpdesk")
    code, out, err = hook(h, "build", "UserPromptSubmit")
    r.check("hook-owner-not-recipient-gets-nothing", code == 0 and out == "", out)
    code, out, err = hook(h, "helpdesk", "UserPromptSubmit")
    r.check("hook-alias-resolves", "via alias" in out and os.path.exists(
        os.path.join(h, "flow", "desk", "sessions", "support.json")), (out, err))
    lf = send(h, root, ask_item(a), "Fix: take A-0001 over.", kind="fix", to="process")
    code, out, err = hook(h, "discovery", "UserPromptSubmit")
    r.check("hook-fix-not-to-the-owner", out == "", out)
    code, out, err = hook(h, "process", "UserPromptSubmit")
    r.check("hook-fix-to-non-owner", out != "" and ctx_of(out) == delivered("the ask " + a, "Fix: take A-0001 over."), out)
    lo = put_letter(h, item=q_item("y"), text="an old letter")
    code, out, err = hook(h, "build", "UserPromptSubmit")
    r.check("hook-old-letter-owner-rule", out != "" and ctx_of(out) == delivered("specs/y q3", "an old letter"), out)
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


def case_notice(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Which database?")
    long_text = "word " * 600 + "\nthe end\n"
    long_id = send(h, root, ask_item(a), long_text, about="the long one")
    short = []
    for i in range(12):
        t = f"letter {i} " + "x" * 200
        short.append((send(h, root, ask_item(a), t, about=f"letter {i}"), t))
    code, out, err = hook(h, "discovery", "UserPromptSubmit")
    ctx = ctx_of(out)
    r.check("notice-long-letter-whole-alone", ctx == delivered("the long one", long_text), ctx[-200:])
    r.check("notice-one-letter-seen", [e["letter"] for e in events(h)] == [long_id], events(h))
    code, out, err = hook(h, "discovery", "UserPromptSubmit")
    ctx = ctx_of(out)
    n = len(events(h)) - 1
    want = "\n\n".join(delivered(f"letter {i}", t) for i, (_, t) in enumerate(short[:n]))
    r.check("notice-whole-letters-joined", 1 < n < 12 and ctx == want and len(ctx) <= 1500
            and [e["letter"] for e in events(h)][1:] == [x for x, _ in short[:n]], (n, ctx[:300]))
    for _ in range(13):
        code, out, err = hook(h, "discovery", "UserPromptSubmit")
        if not out:
            break
    r.check("notice-rest-follows", len(events(h)) == 13, len(events(h)))
    code, out, err = desk(h, "letters", "--id", long_id)
    r.check("letters-id-full-text", code == 0 and long_text.strip() in out, err)
    code, out, err = desk(h, "letters", "--json")
    r.check("letters-json", code == 0 and len(json.loads(out)) == 13, err)


def case_render(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Which database?")
    text = "Use SQLite.\n\n" + "Because " * 500 + "\n"
    tf = text_file(root, text)
    code, out, err = desk(h, "render", "--to", "helpdesk", "--about", "the database of " + a, "--text-file", tf)
    r.check("render-is-exact", code == 0 and out == delivered("the database of " + a, text), (code, out[:200], err))
    lid = send(h, root, ask_item(a), text, to="helpdesk", about="the database of " + a)
    code, hout, err = hook(h, "support", "UserPromptSubmit")
    r.check("render-equals-delivery", hout != "" and ctx_of(hout) == out, hout[:200])
    code, jout, err = desk(h, "render", "--to", "helpdesk", "--about", "the database of " + a, "--text-file", tf, "--json")
    j = {}
    try:
        j = json.loads(jout)
        ok = j == {"to": "support", "about": "the database of " + a, "delivered": out,
                   "wake": "Desk: Ty sent a letter about the database of " + a
                           + ". It is stored; read the Desk notice of this prompt."}
    except ValueError:
        ok = False
    r.check("render-json", code == 0 and ok, (jout, err))
    code, wout, err = desk(h, "wake-text", "--about", "the database of " + a, hub=False, cwd=root)
    r.check("wake-text-no-hub", code == 0 and wout == j.get("wake"), (wout, err))
    for name, args in (("unknown-to", ["--to", "nobody", "--about", "x", "--text-file", tf]),
                       ("empty-text", ["--to", "build", "--about", "x", "--text-file", text_file(root, " \n")]),
                       ("about-two-lines", ["--to", "build", "--about", "x\ny", "--text-file", tf])):
        code, o, err = desk(h, "render", *args)
        r.check("render-refuses-" + name, code == 1 and o == "", (code, o, err))


def case_late(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Which database?")  # the ledger clock is NOW: 2026-11-02T12:00:00Z
    l23 = put_letter(h, item=ask_item(a), to="discovery", about="23 h", at="2026-11-01T13:00:00Z")
    l24 = put_letter(h, item=ask_item(a), to="discovery", about="24 h", at="2026-11-01T12:00:00Z")
    l25 = put_letter(h, item=ask_item(a), to="discovery", about="25 h", at="2026-11-01T11:00:00Z")
    lb = put_letter(h, item=ask_item(a), to="discovery", about="bad time", at="yesterday")
    st = status(h)
    got = {x["about"]: x["late_unseen"] for x in st["letters"]}
    r.check("late-unseen-23h-24h-25h", got == {"23 h": False, "24 h": True, "25 h": True, "bad time": False}, got)
    hook(h, "discovery", "UserPromptSubmit")
    st = status(h)
    got = {x["about"]: (x["late_unseen"], x["state"]) for x in st["letters"]}
    r.check("late-unseen-cleared-when-seen", all(v == (False, "seen") for v in got.values()), got)
    code, out, err = desk(h, "status")
    r.check("status-text", code == 0 and "to discovery: seen" in out, (out, err))


def case_kb_refs_outside(r, root):
    h = make_hub(r, root)
    for d in (os.path.join(root, "home", "Projects", "mine", "sag", "tmp", "kb-ux"), os.path.join(root, "kbs", "kb-abs")):
        os.makedirs(d)
        open(os.path.join(d, "kb.pl"), "w").close()
    tilde, absk = "~/Projects/mine/sag/tmp/kb-ux", os.path.join(root, "kbs", "kb-abs")
    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--title", "Install UX question", "--ref", "kb:" + tilde)
    t = hfo(h, "add", "thread", "--title", "Abs KB work", "--ref", "kb:" + absk, session="build")
    hd = hfo(h, "handoff", "--to", "build", "--title", "Hand KB ux over", "--ref", "kb:" + tilde)
    st = status(h)
    kr = st["kb_refs"]
    r.check("outside-kb-refs-whole", sorted(kr) == sorted([absk, tilde])
            and [x["id"] for x in kr[tilde]] == [a, hd] and [x["id"] for x in kr[absk]] == [t], kr)
    r.check("outside-kb-handoffs", list(st["kb_handoffs"]) == [tilde]
            and [x["id"] for x in st["kb_handoffs"][tilde]] == [hd], st["kb_handoffs"])
    lq = put_letter(h, item=q_item("kb-ux"))  # an old letter about a slug: the outside ref is not that slug
    r.check("outside-ref-not-a-slug", letter_of(status(h), lq)["owners"] == [], letter_of(status(h), lq))


def case_corrupt(r, root):
    h = make_hub(r, root)
    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Which database?")
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
    os.makedirs(os.path.join(root, "desk-state"))
    with open(os.path.join(root, "desk-state", "drafts.json"), "w") as f:
        f.write("{broken")
    code, out, err = desk(h, "drafts", "--json")
    d = json.loads(out) if code == 0 else {}
    r.check("corrupt-drafts-reported", d.get("drafts") == {} and d["bad_lines"]["count"] == 1
            and d["bad_lines"]["lines"][0]["file"] == "drafts.json", (code, out, err))


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

    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Which database?", "--status", "waiting")
    a_open = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Not waiting ask")
    hfo(h, "add", "thread", "--title", "KB w held", "--ref", "kb:w", "--status", "waiting", session="build")
    hook(h, "discovery", "Stop", env={"TMUX_PANE": "%3"})
    hook(h, "build", "Stop", env={"TMUX_PANE": "%4"})
    lb = send(h, root, ask_item(a), "to build, not the owner", to="build", env=env())
    r.check("wake-only-the-recipient", calls() == [] and not woken(lb), calls())
    lid = send(h, root, ask_item(a), "SQLite", env=env(), about="the database (A-0001)")
    c = calls()
    code, line, err = desk(h, "wake-text", "--about", "the database (A-0001)")
    r.check("wake-text-format", line == "Desk: Ty sent a letter about the database (A-0001). It is stored; "
                                        "read the Desk notice of this prompt.", line)
    r.check("wake-idle-waiting-claude", c == ["[display-message][-p][-t][%3][#{pane_current_command}]",
                                              f"[send-keys][-t][%3][-l][{line}]", "[send-keys][-t][%3][Enter]"], c)
    r.check("wake-woken-event", [(e["session"]) for e in woken(lid)] == ["discovery"])
    reset()
    code, out, err = desk(h, "wake", lid, env=env())
    r.check("wake-already-woken-not-again", calls() == [] and "already woken" in err and len(woken(lid)) == 1,
            (calls(), err))
    reset()
    lq = send(h, root, q_item("w"), "w answer", to="build", env=env())
    r.check("wake-question-recipient", any("[send-keys][-t][%4][-l][Desk: Ty sent a letter about q3 in the KB w." in x
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
    lv = send(h, root, q_item("v"), "v answer", to="process", env=env())
    r.check("wake-non-owner-not-called", not any("%3" in x or "%4" in x for x in calls()) and not woken(lv), calls())
    reset()
    code, out, err = desk(h, "wake", l2, env=env())
    r.check("wake-command-types-now", any("send-keys" in x for x in calls()) and len(woken(l2)) == 1, (calls(), err))
    reset()
    hfo(h, "add", "thread", "--title", "KB u held", "--ref", "kb:u", "--status", "waiting", session="support")
    hfo(h, "session", "retire", "support")
    hook(h, "support", "Stop", env={"TMUX_PANE": "%9"})
    lu = send(h, root, q_item("u"), "u answer", to="support", env=env())
    r.check("wake-retired-not-called", calls() == [] and not woken(lu), calls())
    code, out, err = desk(h, "wake", "L-20260101T000000Z-abcdef", env=env())
    r.check("wake-unknown-letter-exit-2", code == 2, (code, err))
    reset()
    l6 = send(h, root, ask_item(a), "tmux missing", env={"DESK_TMUX": os.path.join(root, "no-such-tmux")})
    r.check("wake-tmux-missing-send-still-ok", l6 and not woken(l6), l6)


def case_join(r, root):
    h = make_hub(r, root, name="mindhole")
    h2 = make_hub(r, root, name="other")
    state = os.path.join(root, "desk-state")
    away = os.path.join(root, "away")
    os.makedirs(away)

    def holes():
        c, o, e = desk(h, "mindholes", "--json", cwd=away, hub=False)
        return json.loads(o)["mindholes"] if c == 0 else e

    code, out, err = desk(h, "join", cwd=h, hub=False)
    r.check("join-default-name", code == 0 and out.startswith("joined: mindhole mindhole at " + h)
            and "has no readable .claude/settings.json" in out, (code, out, err))
    j = json.load(open(os.path.join(state, "mindholes.json")))
    r.check("join-file-shape", [(x["name"], x["path"]) for x in j["mindholes"]] == [("mindhole", h)]
            and set(j["mindholes"][0]) == {"name", "path", "joined_at"}, j)
    at = j["mindholes"][0]["joined_at"]
    code, out, err = desk(h, "join", "--hub", h, cwd=away, hub=False)
    r.check("join-idempotent", code == 0 and out.startswith("already joined") and len(holes()) == 1, (out, holes()))
    code, out, err = desk(h, "join", "--hub", h, "--name", "sidequest", cwd=away, hub=False)
    hs = holes()
    r.check("join-same-path-renames", code == 0 and out.startswith("renamed: mindhole mindhole is now sidequest")
            and [(x["name"], x["path"], x["joined_at"]) for x in hs] == [("sidequest", h, at)], (out, hs))
    code, out, err = desk(h, "join", "--hub", h2, "--name", "sidequest", cwd=away, hub=False)
    r.check("join-name-clash-refused", code == 1 and "taken" in err and len(holes()) == 1, (code, err, holes()))
    code, out, err = desk(h, "join", "--hub", h2, "--name", "Bad_Name", cwd=away, hub=False)
    r.check("join-bad-name-refused", code == 1 and len(holes()) == 1, (code, err))
    code, out, err = desk(h, "join", "--hub", away, cwd=away, hub=False)
    r.check("join-no-hub-exit-2", code == 2 and len(holes()) == 1, (code, err))
    with open(os.path.join(h2, ".claude", "settings.json"), "w") as f:
        json.dump({"hooks": {"SessionStart": [{"hooks": [{"type": "command", "command":
                   "python3 \"$CLAUDE_PROJECT_DIR\"/.claude/scripts/desk.py hook"}]}]}}, f)
    code, out, err = desk(h, "join", "--hub", h2, cwd=away, hub=False)
    r.check("join-hooks-missing-named", code == 0 and "no desk hook for UserPromptSubmit, Stop" in out, out)
    code, hooks_out, err = desk(h, "hooks")
    with open(os.path.join(h2, ".claude", "settings.json"), "w") as f:
        f.write(hooks_out)
    before = open(os.path.join(h2, ".claude", "settings.json")).read()
    code, out, err = desk(h, "join", "--hub", h2, cwd=away, hub=False)
    r.check("join-hooks-present", "has the desk hooks" in out
            and open(os.path.join(h2, ".claude", "settings.json")).read() == before, out)
    hs = holes()
    r.check("mindholes-json", [(x["name"], x["path"], x["present"], x["hooks"]) for x in hs]
            == [("other", h2, True, True), ("sidequest", h, True, False)], hs)
    code, out, err = desk(h, "mindholes", cwd=away, hub=False)
    r.check("mindholes-text", code == 0 and "sidequest " + h + " (no desk hooks)" in out, out)
    code, out, err = desk(h, "leave", "--name", "other", cwd=away, hub=False)
    r.check("leave-by-name", code == 0 and [x["name"] for x in holes()] == ["sidequest"], (out, err))
    code, out, err = desk(h, "leave", "--name", "other", cwd=away, hub=False)
    r.check("leave-unknown-exit-2", code == 2, (code, err))
    code, out, err = desk(h, "leave", cwd=h, hub=False)
    r.check("leave-by-cwd-hub", code == 0 and holes() == [], (out, err))
    with open(os.path.join(state, "mindholes.json"), "w") as f:
        f.write("{broken")
    code, out, err = desk(h, "join", cwd=h, hub=False)
    r.check("join-broken-store-not-overwritten", code == 2 and open(os.path.join(state, "mindholes.json")).read()
            == "{broken", (code, err))


def case_service(r, root):
    h = make_hub(r, root)
    state = os.path.join(root, "desk-state")
    exe = os.path.join(h, ".claude", "orbit-kb", "bin", "orbit-kb")
    want = ("[Unit]\nDescription=The Desk: one page for every mindhole on this machine\n\n[Service]\n"
            f"ExecStart={exe} serve desk --port 8737\nEnvironment=DESK_STATE={state}\nRestart=on-failure\n\n"
            "[Install]\nWantedBy=default.target\n")
    code, out, err = desk(h, "service", cwd=h, hub=False)
    r.check("service-unit-text", code == 0 and out == want and "warning" in err, (out, err))
    code, out, err = desk(h, "service", "--orbit-kb", "/opt/o k/orbit-kb", "--port", "9000", cwd=root, hub=False,
                          env={"DESK_STATE": None})
    r.check("service-orbit-kb-port-no-state", code == 0 and 'ExecStart="/opt/o k/orbit-kb" serve desk --port 9000\n' in out
            and "Environment" not in out, out)
    code, out, err = desk(h, "service", "--port", "0", cwd=h, hub=False)
    r.check("service-bad-port", code == 1, (code, err))
    code, out, err = desk(h, "service", "--write", cwd=h, hub=False)
    unit = os.path.join(root, "xdg-config", "systemd", "user", "desk.service")
    r.check("service-write", code == 0 and os.path.isfile(unit) and open(unit).read() == want
            and "systemctl --user enable --now desk.service" in out and unit in out, (out, err))


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
    a = hfo(h, "add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Which database?", "--status", "waiting")
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


def case_hooks_status(r, root):
    """c24: status names the hook events that no settings file gives to desk.py hook (the hub's
    settings.json and settings.local.json, the user's ~/.claude/settings.json)."""
    h = make_hub(r, root)
    r.check("hooks-none-all-missing", status(h)["hooks_missing"] == ["SessionStart", "UserPromptSubmit", "Stop"], status(h).get("hooks_missing"))
    code, block, err = desk(h, "hooks")
    full = json.loads(block)
    part = {"hooks": {k: v for k, v in full["hooks"].items() if k != "Stop"}}
    os.makedirs(os.path.join(h, ".claude"), exist_ok=True)
    with open(os.path.join(h, ".claude", "settings.local.json"), "w") as f:
        json.dump(part, f)
    r.check("hooks-local-counts", status(h)["hooks_missing"] == ["Stop"], status(h).get("hooks_missing"))
    home = os.path.join(root, "home", ".claude")
    os.makedirs(home, exist_ok=True)
    with open(os.path.join(home, "settings.json"), "w") as f:
        json.dump({"hooks": {"Stop": full["hooks"]["Stop"]}}, f)
    r.check("hooks-user-settings-count", status(h)["hooks_missing"] == [], status(h).get("hooks_missing"))


CASES = [case_send, case_send_order, case_events, case_ownership, case_status, case_drafts, case_hook,
         case_notice, case_render, case_late, case_kb_refs_outside, case_corrupt, case_wake, case_join,
         case_service, case_hooks_cmd, case_db_read_only, case_hooks_status]


def run_all(r, only):
    for fn in CASES:
        if only and fn.__name__ not in only:
            continue
        root = tempfile.mkdtemp(prefix="desk-test-")
        CUR["root"] = root
        os.makedirs(os.path.join(root, "home"))
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

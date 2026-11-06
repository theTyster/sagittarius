#!/usr/bin/env python3
"""Test for hubflow.py. Runs the script against temporary flow dirs (HUBFLOW_DB_DIR) with a fixed
clock (HUBFLOW_NOW), never the real hub's flow/ dir.

usage: python3 -I hubflow-test.py [--mutants]
  --mutants  also apply each rule mutant to a temp copy of hubflow.py and run the suite on it;
             each mutant must make at least one case fail (KILLED).
Every scenario seeds its db from a seed file written into the temp dir (SEED_DATA below).
Prints `PASS name` or `FAIL name: why` per case; the last line is `N passed, M failed`.
Exit 0 only if every case passes (and, with --mutants, every mutant is killed); 1 otherwise.
"""
import json, os, re, shutil, sqlite3, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REAL = os.path.join(HERE, "hubflow.py")
NOW = "2026-11-02T12:00:00Z"  # a Monday
TABLES = ("meta", "session", "session_alias", "person", "item", "item_ref", "item_link", "handoff", "event")
VIEWS = ("clock", "v_open", "v_waiting_on", "v_inbox", "v_stale", "v_dup_refs", "v_week", "v_retention_due")
WRITE_CMDS = ("init", "migrate", "add", "handoff", "accept", "renew", "park", "set", "close", "reopen", "ref", "link",
              "note", "session", "import", "rotate", "rebuild", "export")

SEED_DATA = {
    "sessions": [{"name": n, "role": n} for n in ("discovery", "build", "process", "support")],
    "aliases": [{"alias": "helpdesk", "name": "support"}],
    "persons": [{"key": "me", "display": "Me"}, {"key": "alex", "display": "Alex Example"}],
}
SEED = None  # the seed file's path, set per run in cases()

# Each mutant: (name, anchor in hubflow.py that must occur exactly once, replacement).
MUTANTS = [
    ("lapse-threshold-28-to-27", "LAPSE_DAYS = 28", "LAPSE_DAYS = 27"),
    ("prune-boundary-lt-to-le", "closed_at < ?", "closed_at <= ?"),
    ("write-without-session", "if not name:  # session check",
     "name = name or 'discovery'\n    if False:"),
    ("analysis-w-slot-check-dropped", "if W_SLOT.match(v):  # W-slot check", "if False:"),
    ("export-dropped-from-write", "export_all(c, d)  # in the write transaction", "pass"),
    ("accept-by-any-session", "if me != to_session:  # only the to_session accepts", "if False:"),
    ("park-ignored-by-rotate", "(parked_until IS NULL OR parked_until < ?)", "1 = 1"),
    ("issue-ref-digits-dropped", "if not re.fullmatch(r\"\\d+\", ref):  # digits check", "if False:"),
    ("handoff-owner-not-to", "owner_session = to  # handoff owner is the to_session", "owner_session = frm"),
    ("owner-default-dropped", "owner = resolve_active(c, o.get(\"owner\") or w.session)", "owner = resolve_active(c, o[\"owner\"]) if o.get(\"owner\") else None"),
    ("migrate-version-not-set", "c.execute(f\"PRAGMA user_version = {v + 1}\")  # migrate step", "pass"),
    ("rebuild-ignores-unknown-columns", "if extra:  # unknown JSONL columns", "if False:"),
    ("seed-file-ignored", "seed = load_seed(seed_path(o, d))  # seed file read", "seed = load_seed(None)"),
]


class Run:
    def __init__(self, script):
        self.script = script
        self.results = []
        self.sync_bad = []

    def check(self, name, ok, detail=""):
        self.results.append(bool(ok))
        if not QUIET:
            print(("PASS " if ok else "FAIL ") + name + ("" if ok else ": " + str(detail)[:600]))


QUIET = False


def hf(r, d, *args, now=NOW, session="discovery", hub=None, extra_env=None, cwd=None):
    env = {k: v for k, v in os.environ.items() if not k.startswith("HUBFLOW_") and k != "HUB_SESSION"}
    if d is not None:
        env["HUBFLOW_DB_DIR"] = d
    env.update(extra_env or {})
    if now:
        env["HUBFLOW_NOW"] = now
    if session:
        env["HUB_SESSION"] = session
    cmd = [sys.executable, "-I", r.script] + (["--hub", hub] if hub else []) + [str(a) for a in args]
    p = subprocess.run(cmd, capture_output=True, text=True, env=env, cwd=cwd)
    a = [str(x) for x in args]
    if d is not None and a and a[0] in WRITE_CMDS and p.returncode == 0 and not (a[0] in ("import", "rotate") and "--yes" not in a):
        bad = out_of_sync(d)
        if bad:
            r.sync_bad.append((a[:3], bad))
    return p.returncode, p.stdout, p.stderr


def dbfile(d):
    return os.path.join(d, "flow.db")


def ro(d):
    c = sqlite3.connect(f"file:{dbfile(d)}?mode=ro", uri=True)
    return c


def q(d, sql, *params):
    c = ro(d)
    try:
        return c.execute(sql, params).fetchall()
    finally:
        c.close()


def rows(d, t):
    c = ro(d)
    try:
        cur = c.execute(f"select * from {t}")
        cols = [x[0] for x in cur.description]
        return [json.dumps(dict(zip(cols, row)), sort_keys=True, ensure_ascii=False) for row in cur]
    finally:
        c.close()


def snapshot(d):
    return {t: sorted(rows(d, t)) for t in TABLES}


def jl_lines(d, t):
    p = os.path.join(d, "jsonl", t + ".jsonl")
    if not os.path.exists(p):
        return None
    with open(p, encoding="utf-8") as f:
        return [json.dumps(json.loads(x), sort_keys=True, ensure_ascii=False) for x in f if x.strip()]


def out_of_sync(d):
    bad = []
    for t in TABLES:
        disk = jl_lines(d, t)
        if disk is None:
            bad.append(t + " missing")
        elif sorted(disk) != sorted(rows(d, t)):
            bad.append(t)
    return bad


def jl_bytes(d):
    out = {}
    jd = os.path.join(d, "jsonl")
    for n in sorted(os.listdir(jd)) if os.path.isdir(jd) else []:
        with open(os.path.join(jd, n), "rb") as f:
            out[n] = f.read()
    return out


def ev(d, item):
    return q(d, "select verb, old, new, by_session, by, note, at from event where item_id = ? order by seq", item)


def js(out):
    try:
        return json.loads(out)
    except ValueError:
        return None


def ids(out):
    v = js(out)
    return [x["id"] for x in v] if isinstance(v, list) else None


def listed(out, prefix):
    for line in out.splitlines():
        if line.startswith(prefix):
            rest = line[len(prefix):].split()
            return [] if rest == ["none"] else rest
    return None


def refused(res, code=1, text=None):
    c, _, err = res
    return c == code and err.startswith("hubflow: ERROR:") and (text is None or text in err)


def fresh(r, root, name, session="discovery"):
    d = os.path.join(root, name, "flow")  # the parent does not exist: init must create it
    code, _, err = hf(r, d, "init", "--seed", SEED, session=session)
    if code != 0:
        r.check(f"fresh-{name}-init", False, err)
    return d


def add(r, d, kind, title, *extra, now=NOW, session="discovery"):
    code, out, err = hf(r, d, "add", kind, "--title", title, *extra, now=now, session=session)
    if code != 0:
        raise RuntimeError(f"add {title!r} failed: {err}")
    return out.strip()


def ok(r, d, *args, now=NOW, session="discovery"):
    code, out, err = hf(r, d, *args, now=now, session=session)
    if code != 0:
        raise RuntimeError(f"{args} failed: {code} {err}")
    return out


# ---------------------------------------------------------------------------------------------------

def case_init(r, root):
    d = os.path.join(root, "init", "flow")
    code, out, err = hf(r, d, "init", "--seed", SEED, session=None)
    r.check("init-exit-0-no-session-needed", code == 0, err)
    r.check("init-db-exists", os.path.exists(dbfile(d)))
    if not os.path.exists(dbfile(d)):
        return
    r.check("init-user-version-1", q(d, "pragma user_version")[0][0] == 1)
    r.check("init-wal", q(d, "pragma journal_mode")[0][0] == "wal")
    names = {x[0] for x in q(d, "select name from sqlite_master")}
    r.check("init-tables", set(TABLES) <= names, sorted(set(TABLES) - names))
    r.check("init-views", set(VIEWS) <= names, sorted(set(VIEWS) - names))
    sess = dict(q(d, "select name, role from session"))
    r.check("init-seed-sessions", sess == {"discovery": "discovery", "build": "build",
                                           "process": "process", "support": "support"}, sess)
    r.check("init-seed-sessions-active", q(d, "select count(*) from session where status='active' and retired_on is null")[0][0] == 4)
    r.check("init-seed-alias", q(d, "select alias, name from session_alias") == [("helpdesk", "support")])
    pers = dict(q(d, "select key, display from person"))
    r.check("init-seed-persons", pers == {"me": "Me", "alex": "Alex Example"}, pers)
    meta = dict(q(d, "select key, value from meta"))
    r.check("init-meta-counters", all(meta.get(k) == "1" for k in ("next_A", "next_T", "next_K", "next_H")), meta)
    r.check("init-jsonl-per-table", all(os.path.exists(os.path.join(d, "jsonl", t + ".jsonl")) for t in TABLES))
    r.check("init-jsonl-matches-db", out_of_sync(d) == [], out_of_sync(d))
    code, _, err = hf(r, d, "init")
    r.check("init-refuses-existing", refused((code, "", err), 2), err)
    code, _, err = hf(r, d, "check")
    r.check("init-check-clean", code == 0, err)
    c = sqlite3.connect(dbfile(d))
    try:
        c.execute("insert into item(id,kind,title,status,opened_at,renewed_at,closed_at) values('A-9','ask','xyz','done','x','x',null)")
        r.check("closed-at-check-constraint", False, "status done with null closed_at was accepted")
    except sqlite3.IntegrityError:
        r.check("closed-at-check-constraint", True)
    finally:
        c.close()
    c = sqlite3.connect(dbfile(d))
    try:
        c.execute("insert into item(id,kind,title,status,opened_at,renewed_at,analysis) values('A-9','ask','xyz','open','x','x','W0/a')")
        r.check("analysis-check-constraint", False, "a W-slot analysis was accepted by the schema")
    except sqlite3.IntegrityError:
        r.check("analysis-check-constraint", True)
    finally:
        c.close()


def case_basic(r, root):
    d = fresh(r, root, "base")
    res = hf(r, d, "add", "ask", "--title", "First ask", "--owner", "discovery", "--waits-on", "alex",
             "--analysis", "alpha", "--ref", "issue:1234", "--ref", "kb:alpha/kb", "--note", "from ledger")
    r.check("add-prints-first-id", res[0] == 0 and res[1].strip() == "A-0001", res)
    r.check("add-ask-second", hf(r, d, "add", "ask", "--title", "Second ask")[1].strip() == "A-0002")
    r.check("add-thread-id", hf(r, d, "add", "thread", "--title", "A thread")[1].strip() == "T-0001")
    r.check("add-hold-id", hf(r, d, "add", "hold", "--title", "A hold")[1].strip() == "K-0001")
    r.check("add-owner-defaults-to-writer",
            q(d, "select owner_session from item where id='A-0002'") == [("discovery",)],
            q(d, "select owner_session from item where id='A-0002'"))
    r.check("add-owner-none-is-unowned",
            hf(r, d, "add", "hold", "--title", "Unowned hold", "--owner", "none")[1].strip() == "K-0002"
            and q(d, "select owner_session from item where id='K-0002'") == [(None,)])
    r.check("add-sets-meta-now", q(d, "select value from meta where key='now'") == [(NOW,)])
    e = ev(d, "A-0001")
    r.check("add-writes-opened-event", e == [("opened", None, "open", "discovery", "agent", "from ledger", NOW)], e)
    it = q(d, "select status, owner_session, waits_on, analysis, opened_at, renewed_at, closed_at from item where id='A-0001'")
    r.check("add-fields", it == [("open", "discovery", "alex", "alpha", NOW, NOW, None)], it)
    r.check("add-refs", q(d, "select kind, ref from item_ref where item_id='A-0001' order by kind") == [("issue", "1234"), ("kb", "alpha/kb")])
    # alias resolution
    res = hf(r, d, "add", "ask", "--title", "Aliased", "--owner", "helpdesk", "--session", "helpdesk")
    r.check("alias-owner-resolved", res[0] == 0 and q(d, "select owner_session from item where id=?", res[1].strip()) == [("support",)], res)
    r.check("alias-session-resolved-in-event", ev(d, "A-0003")[0][3] == "support", ev(d, "A-0003"))
    code, out, err = hf(r, d, "add", "ask", "--title", "Via env alias", session="helpdesk")
    r.check("alias-env-session-resolved", code == 0 and ev(d, out.strip())[0][3] == "support", err)
    n_items = q(d, "select count(*) from item")[0][0]
    # refusals: nothing may be created
    bad = [
        ("handoff-kind-via-add", ["add", "handoff", "--title", "Nope"], None),
        ("bad-kind", ["add", "wish", "--title", "Nope"], None),
        ("title-too-short", ["add", "ask", "--title", "ab"], None),
        ("title-too-long", ["add", "ask", "--title", "x" * 201], None),
        ("title-missing", ["add", "ask"], None),
        ("unknown-waits-on", ["add", "ask", "--title", "Nope", "--waits-on", "nobody"], None),
        ("unknown-owner", ["add", "ask", "--title", "Nope", "--owner", "nobody"], None),
        ("bad-status", ["add", "ask", "--title", "Nope", "--status", "done"], None),
        ("analysis-w-slot-path", ["add", "ask", "--title", "Nope", "--analysis", "W0/analyses/alpha"], "W-slot"),
        ("analysis-w5-path", ["add", "ask", "--title", "Nope", "--analysis", "W5/alpha"], "W-slot"),
        ("issue-ref-letters", ["add", "ask", "--title", "Nope", "--ref", "issue:abc"], "digits"),
        ("issue-ref-hash", ["add", "ask", "--title", "Nope", "--ref", "issue:#1234"], "digits"),
        ("pr-ref-letters", ["add", "ask", "--title", "Nope", "--ref", "pr:12a"], "digits"),
        ("kb-ref-w-slot", ["add", "ask", "--title", "Nope", "--ref", "kb:W0/analyses/alpha/kb"], "W-slot"),
        ("file-ref-w-slot", ["add", "ask", "--title", "Nope", "--ref", "file:W2/analyses/alpha/f.md"], "W-slot"),
        ("unknown-ref-kind", ["add", "ask", "--title", "Nope", "--ref", "bogus:1"], None),
        ("ref-without-colon", ["add", "ask", "--title", "Nope", "--ref", "1234"], None),
        ("unknown-option", ["add", "ask", "--title", "Nope", "--frobnicate", "1"], None),
    ]
    for name, args, text in bad:
        r.check("refused-" + name, refused(hf(r, d, *args), 1, text), hf(r, d, *args)[2])
    r.check("refusals-create-nothing", q(d, "select count(*) from item")[0][0] == n_items)
    r.check("refusals-keep-counters", q(d, "select value from meta where key='next_A'") == [("5",)], q(d, "select * from meta"))
    r.check("analysis-slug-accepted", hf(r, d, "add", "ask", "--title", "Slug ok", "--analysis", "2026-11-02-thing")[0] == 0)
    # writer identity
    n = q(d, "select count(*) from item")[0][0]
    res = hf(r, d, "add", "ask", "--title", "No session", session=None)
    r.check("write-without-session-refused", refused(res, 1, "HUB_SESSION"), res)
    r.check("write-without-session-writes-nothing", q(d, "select count(*) from item")[0][0] == n)
    r.check("unknown-session-refused", refused(hf(r, d, "add", "ask", "--title", "Nope", session="ghost"), 1))
    res = hf(r, d, "--session", "build", "add", "ask", "--title", "Flag session", session=None)
    r.check("session-flag-accepted", res[0] == 0 and ev(d, res[1].strip())[0][3] == "build", res)
    r.check("by-robot-refused", refused(hf(r, d, "add", "ask", "--title", "Nope", "--by", "robot"), 1))
    r.check("by-human-needs-note", refused(hf(r, d, "add", "ask", "--title", "Nope", "--by", "human"), 1, "note"))
    res = hf(r, d, "add", "ask", "--title", "Owner said so", "--by", "human", "--note", "\"do it\" (Me)")
    e = ev(d, res[1].strip())
    r.check("by-human-with-note", res[0] == 0 and e[0][4] == "human" and e[0][5] == "\"do it\" (Me)", res)
    # renew, park
    late = "2026-11-03T08:00:00Z"
    r.check("renew-exit-0", hf(r, d, "renew", "A-0002", "--note", "still on", now=late)[0] == 0)
    r.check("renew-sets-renewed-at", q(d, "select renewed_at, opened_at from item where id='A-0002'") == [(late, NOW)])
    e = ev(d, "A-0002")
    r.check("renew-event", e[-1][0] == "renewed" and e[-1][2] == late and e[-1][5] == "still on", e)
    r.check("renew-unknown-refused", refused(hf(r, d, "renew", "A-0404"), 1))
    r.check("park-exit-0", hf(r, d, "park", "A-0002", "--until", "2026-11-20", "--note", "waiting on release", now=late)[0] == 0)
    r.check("park-sets-date", q(d, "select parked_until from item where id='A-0002'") == [("2026-11-20",)])
    r.check("park-event", ev(d, "A-0002")[-1][:3] == ("parked", None, "2026-11-20"), ev(d, "A-0002"))
    r.check("park-bad-date", refused(hf(r, d, "park", "A-0002", "--until", "2026-13-40", now=late), 1))
    r.check("park-bad-format", refused(hf(r, d, "park", "A-0002", "--until", "11/20/2026", now=late), 1))
    r.check("park-in-past-refused", refused(hf(r, d, "park", "A-0002", "--until", "2026-11-01", now=late), 1))
    r.check("park-needs-until", refused(hf(r, d, "park", "A-0002", now=late), 1))
    # set
    code, _, err = hf(r, d, "set", "A-0002", "--title", "Second ask renamed", "--owner", "build",
                      "--waits-on", "me", "--status", "waiting", now=late)
    r.check("set-exit-0", code == 0, err)
    it = q(d, "select title, owner_session, waits_on, status from item where id='A-0002'")
    r.check("set-fields", it == [("Second ask renamed", "build", "me", "waiting")], it)
    verbs = [x[0] for x in ev(d, "A-0002")]
    r.check("set-writes-event-per-change", all(v in verbs for v in ("title", "owner", "waits_on", "status")), verbs)
    r.check("set-waits-on-none", hf(r, d, "set", "A-0002", "--waits-on", "none", now=late)[0] == 0 and q(d, "select waits_on from item where id='A-0002'") == [(None,)])
    r.check("set-status-done-refused", refused(hf(r, d, "set", "A-0002", "--status", "done"), 1))
    r.check("set-nothing-refused", refused(hf(r, d, "set", "A-0002"), 1))
    r.check("set-unknown-owner-refused", refused(hf(r, d, "set", "A-0002", "--owner", "nobody"), 1))
    r.check("set-w-slot-analysis-refused", refused(hf(r, d, "set", "A-0002", "--analysis", "W1/x"), 1, "W-slot"))
    r.check("set-slug-analysis", hf(r, d, "set", "A-0002", "--analysis", "beta")[0] == 0 and q(d, "select analysis from item where id='A-0002'") == [("beta",)])
    r.check("set-unknown-id", refused(hf(r, d, "set", "A-0404", "--title", "Whatever"), 1))
    # refs
    r.check("ref-add", hf(r, d, "ref", "A-0001", "add", "pr:3845")[0] == 0)
    r.check("ref-add-event", ev(d, "A-0001")[-1][:3] == ("ref_add", None, "pr:3845"), ev(d, "A-0001"))
    n_ev = len(ev(d, "A-0001"))
    r.check("ref-add-twice-is-a-noop", hf(r, d, "ref", "A-0001", "add", "pr:3845")[0] == 0 and len(ev(d, "A-0001")) == n_ev)
    r.check("ref-bad-issue", refused(hf(r, d, "ref", "A-0001", "add", "issue:12x"), 1, "digits"))
    r.check("ref-w-slot", refused(hf(r, d, "ref", "A-0001", "add", "kb:W0/x/kb"), 1, "W-slot"))
    r.check("ref-rm", hf(r, d, "ref", "A-0001", "rm", "pr:3845")[0] == 0 and q(d, "select count(*) from item_ref where item_id='A-0001' and kind='pr'") == [(0,)])
    r.check("ref-rm-event", ev(d, "A-0001")[-1][:3] == ("ref_rm", "pr:3845", None), ev(d, "A-0001"))
    r.check("ref-rm-missing-refused", refused(hf(r, d, "ref", "A-0001", "rm", "pr:1"), 1))
    r.check("ref-bad-verb", refused(hf(r, d, "ref", "A-0001", "mv", "pr:1"), 1))
    # link, note, show
    r.check("link-exit-0", hf(r, d, "link", "A-0001", "A-0002", "blocks")[0] == 0)
    r.check("link-duplicate-idempotent", hf(r, d, "link", "A-0001", "A-0002", "blocks")[0] == 0 and q(d, "select count(*) from item_link")[0][0] == 1)
    r.check("link-self-refused", refused(hf(r, d, "link", "A-0001", "A-0001", "relates"), 1))
    r.check("link-bad-kind", refused(hf(r, d, "link", "A-0001", "A-0002", "loves"), 1))
    r.check("link-unknown-id", refused(hf(r, d, "link", "A-0001", "A-0404", "relates"), 1))
    r.check("note-exit-0", hf(r, d, "note", "A-0001", "hello world")[0] == 0)
    r.check("note-event", ev(d, "A-0001")[-1][0] == "note" and ev(d, "A-0001")[-1][5] == "hello world", ev(d, "A-0001"))
    r.check("note-unknown-id", refused(hf(r, d, "note", "A-0404", "x"), 1))
    code, out, err = hf(r, d, "show", "A-0001", "--format", "json")
    v = js(out) or {}
    r.check("show-json", code == 0 and v.get("item", {}).get("id") == "A-0001"
            and {x["kind"] + ":" + x["ref"] for x in v.get("refs", [])} == {"issue:1234", "kb:alpha/kb"}
            and any(x["to_id"] == "A-0002" and x["kind"] == "blocks" for x in v.get("links", []))
            and v.get("handoff") is None and [x["verb"] for x in v.get("events", [])][:1] == ["opened"], out[:300] + err)
    code, out, err = hf(r, d, "show", "A-0002", "--format", "json")
    r.check("show-link-seen-from-both-ends", any(x["from_id"] == "A-0001" for x in (js(out) or {}).get("links", [])), out[:300])
    code, out, err = hf(r, d, "show", "A-0001")
    r.check("show-md", code == 0 and "First ask" in out and "A-0001" in out, out[:200] + err)
    r.check("show-unknown", refused(hf(r, d, "show", "A-0404"), 1))
    # close / reopen
    res = hf(r, d, "close", "A-0003", "--reason", "done", "--note", "shipped")
    it = q(d, "select status, closed_at, close_reason from item where id='A-0003'")
    r.check("close-sets-status-and-time", res[0] == 0 and it == [("done", NOW, "done")], (res, it))
    r.check("close-event", ev(d, "A-0003")[-1][:3] == ("closed", "open", "done") and ev(d, "A-0003")[-1][5] == "shipped", ev(d, "A-0003"))
    r.check("close-twice-refused", refused(hf(r, d, "close", "A-0003", "--reason", "done"), 1))
    r.check("close-bad-reason", refused(hf(r, d, "close", "A-0001", "--reason", "lapsed"), 1))
    r.check("close-needs-reason", refused(hf(r, d, "close", "A-0001"), 1))
    r.check("close-dropped", hf(r, d, "close", "K-0001", "--reason", "dropped")[0] == 0 and q(d, "select status from item where id='K-0001'") == [("dropped",)])
    r.check("renew-closed-refused", refused(hf(r, d, "renew", "A-0003"), 1))
    r.check("reopen-exit-0", hf(r, d, "reopen", "A-0003", "--note", "back", now=late)[0] == 0)
    it = q(d, "select status, closed_at, close_reason, renewed_at from item where id='A-0003'")
    r.check("reopen-clears-close", it == [("open", None, None, late)], it)
    r.check("reopen-event", ev(d, "A-0003")[-1][0] == "reopened", ev(d, "A-0003"))
    r.check("reopen-open-item-refused", refused(hf(r, d, "reopen", "A-0003"), 1))
    r.check("check-clean-after-writes", hf(r, d, "check")[0] == 0, hf(r, d, "check")[2])
    return d


def case_handoff(r, root):
    d = fresh(r, root, "handoff")
    res = hf(r, d, "handoff", "--to", "build", "--title", "Build the thing", "--gate", "after review",
             "--analysis", "alpha", "--ref", "issue:1234", "--note", "gate GO")
    r.check("handoff-prints-H-id", res[0] == 0 and res[1].strip() == "H-0001", res)
    it = q(d, "select kind, status, owner_session, accepted_at from item i join handoff h on h.item_id=i.id where i.id='H-0001'")
    r.check("handoff-owner-is-to-and-open", it == [("handoff", "open", "build", None)], it)
    r.check("handoff-row", q(d, "select from_session, to_session, gate, accepted_at from handoff") == [("discovery", "build", "after review", None)])
    r.check("handoff-opened-event", ev(d, "H-0001")[0][0] == "opened" and ev(d, "H-0001")[0][3] == "discovery", ev(d, "H-0001"))
    r.check("handoff-to-self-refused", refused(hf(r, d, "handoff", "--to", "discovery", "--title", "Self"), 1))
    r.check("handoff-to-unknown-refused", refused(hf(r, d, "handoff", "--to", "nobody", "--title", "Nope"), 1))
    r.check("handoff-w-slot-analysis", refused(hf(r, d, "handoff", "--to", "build", "--title", "Nope", "--analysis", "W0/analyses/x"), 1, "W-slot"))
    r.check("handoff-needs-to", refused(hf(r, d, "handoff", "--title", "Nope"), 1))
    r.check("handoff-count-unchanged", q(d, "select count(*) from handoff")[0][0] == 1)
    # accept: only the to_session
    r.check("accept-by-from-session-refused", refused(hf(r, d, "accept", "H-0001", session="discovery"), 1))
    r.check("accept-by-third-session-refused", refused(hf(r, d, "accept", "H-0001", session="support"), 1))
    r.check("accept-refused-leaves-unaccepted", q(d, "select accepted_at from handoff") == [(None,)])
    r.check("accept-by-to-session", hf(r, d, "accept", "H-0001", session="build", now="2026-11-02T13:00:00Z")[0] == 0)
    r.check("accept-sets-accepted-at", q(d, "select accepted_at from handoff") == [("2026-11-02T13:00:00Z",)])
    r.check("accept-event", ev(d, "H-0001")[-1][0] == "accepted" and ev(d, "H-0001")[-1][3] == "build", ev(d, "H-0001"))
    r.check("accept-twice-refused", refused(hf(r, d, "accept", "H-0001", session="build"), 1))
    add(r, d, "ask", "Plain ask")
    r.check("accept-non-handoff-refused", refused(hf(r, d, "accept", "A-0001", session="build"), 1))
    r.check("accept-unknown-refused", refused(hf(r, d, "accept", "H-0404", session="build"), 1))
    r.check("handoff-owner-change-refused", refused(hf(r, d, "set", "H-0001", "--owner", "discovery"), 1))
    r.check("handoff-owner-still-to", q(d, "select owner_session from item where id='H-0001'") == [("build",)])
    # alias on accept
    hf(r, d, "handoff", "--to", "support", "--title", "Support thing")
    r.check("accept-through-alias", hf(r, d, "accept", "H-0002", session="helpdesk")[0] == 0)


def case_views(r, root):
    d = fresh(r, root, "views")
    add(r, d, "ask", "Waiting on Alex about 1234", "--owner", "discovery", "--waits-on", "alex", "--ref", "issue:1234", "--ref", "pr:3845", now="2026-10-30T12:00:00Z")  # A-1
    add(r, d, "ask", "Idle fourteen", "--owner", "build", now="2026-10-19T12:00:00Z")  # A-2
    add(r, d, "ask", "Idle twenty-eight", "--owner", "discovery", now="2026-10-05T12:00:00Z")  # A-3
    add(r, d, "ask", "Idle twenty-eight but parked", "--owner", "discovery", now="2026-10-05T12:00:00Z")  # A-4
    ok(r, d, "park", "A-0004", "--until", "2026-11-10", now="2026-10-20T12:00:00Z")
    add(r, d, "ask", "Idle twenty-seven", "--owner", "none", now="2026-10-06T12:00:00Z")  # A-5
    add(r, d, "ask", "Renewed yesterday", "--owner", "none", now="2026-10-19T12:00:00Z")  # A-6
    ok(r, d, "renew", "A-0006", now="2026-11-01T12:00:00Z")
    add(r, d, "ask", "Almost fourteen", "--owner", "none", now="2026-10-19T12:00:01Z")  # A-7
    add(r, d, "ask", "Alex older wait", "--owner", "none", "--waits-on", "alex", "--ref", "pr:4000", now="2026-10-25T00:00:00Z")  # A-8
    add(r, d, "ask", "Me wait", "--owner", "none", "--waits-on", "me", "--ref", "pr:4000", now="2026-11-01T00:00:00Z")  # A-9
    add(r, d, "ask", "Shares 1234", "--owner", "build", "--ref", "issue:1234", now="2026-11-01T12:00:00Z")  # A-10
    add(r, d, "ask", "Closed shares 1234", "--owner", "none", "--ref", "issue:1234", "--ref", "pr:3845", now="2026-10-30T00:00:00Z")  # A-11
    ok(r, d, "close", "A-0011", "--reason", "done", now="2026-10-31T00:00:00Z")
    add(r, d, "thread", "Shares a file", "--owner", "none", "--ref", "file:alpha/notes", "--ref", "kb:alpha/kb", now="2026-11-01T12:00:00Z")  # T-1
    add(r, d, "thread", "Shares a file too", "--owner", "none", "--ref", "file:alpha/notes", "--ref", "kb:alpha/kb", now="2026-11-01T12:00:00Z")  # T-2
    ok(r, d, "handoff", "--to", "discovery", "--title", "Two days old", now="2026-10-31T12:00:00Z", session="build")  # H-1
    ok(r, d, "handoff", "--to", "discovery", "--title", "Half a day old", now="2026-11-02T00:00:00Z", session="build")  # H-2
    ok(r, d, "handoff", "--to", "build", "--title", "To build", now="2026-10-31T12:00:00Z")  # H-3

    code, out, err = hf(r, d, "view", "open", "--format", "json")
    v = {x["id"]: x for x in (js(out) or [])}
    r.check("v_open-exit-0", code == 0 and v, err)
    r.check("v_open-excludes-closed", "A-0011" not in v and "A-0001" in v)
    r.check("v_open-ages", (v["A-0001"]["age_days"], v["A-0001"]["idle_days"]) == (3, 3) and
            (v["A-0002"]["age_days"], v["A-0002"]["idle_days"]) == (14, 14) and
            (v["A-0003"]["age_days"], v["A-0003"]["idle_days"]) == (28, 28) and
            (v["A-0008"]["age_days"], v["A-0008"]["idle_days"]) == (8, 8), {k: (x["age_days"], x["idle_days"]) for k, x in v.items()})
    r.check("v_open-idle-differs-from-age", (v["A-0006"]["age_days"], v["A-0006"]["idle_days"]) == (14, 1), (v["A-0006"]))
    r.check("v_open-floor", (v["A-0007"]["age_days"], v["A-0007"]["idle_days"]) == (13, 13), v["A-0007"])
    r.check("v_open-refs-column", v["A-0001"]["refs"] == "issue:1234 pr:3845", v["A-0001"])
    r.check("v_open-owner-and-waits", v["A-0001"]["owner_session"] == "discovery" and v["A-0001"]["waits_on"] == "alex", v["A-0001"])
    code, out, _ = hf(r, d, "view", "v_open", "--format", "json")
    r.check("view-accepts-v_-prefix", code == 0 and len(js(out) or []) == len(v))
    code, out, _ = hf(r, d, "view", "open", "--session", "build", "--format", "json")
    r.check("v_open-session-filter", sorted(ids(out) or []) == ["A-0002", "A-0010", "H-0003"], out[:300])
    code, out, _ = hf(r, d, "view", "open", "--kind", "thread", "--format", "json")
    r.check("v_open-kind-filter", sorted(ids(out) or []) == ["T-0001", "T-0002"], out[:300])
    code, out, _ = hf(r, d, "view", "open")
    r.check("v_open-md-table", code == 0 and "| id |" in out and "A-0001" in out, out[:200])
    code, out, _ = hf(r, d, "view", "open", "--format", "tsv")
    r.check("v_open-tsv", code == 0 and out.splitlines()[0].split("\t")[0] == "id" and "\t" in out.splitlines()[1], out[:200])

    code, out, _ = hf(r, d, "view", "waiting_on", "--format", "json")
    r.check("v_waiting_on-oldest-first-per-person", ids(out) == ["A-0008", "A-0001", "A-0009"], out[:400])
    code, out, _ = hf(r, d, "view", "waiting_on", "--person", "alex", "--format", "json")
    r.check("v_waiting_on-person-filter", ids(out) == ["A-0008", "A-0001"], out[:400])
    code, out, _ = hf(r, d, "view", "waiting_on", "--person", "alex", "--kind", "thread", "--format", "json")
    r.check("v_waiting_on-kind-filter", code == 0 and ids(out) == [], out)
    r.check("view-unsupported-filter-refused", refused(hf(r, d, "view", "waiting_on", "--session", "build"), 1))
    r.check("view-unknown-name-refused", refused(hf(r, d, "view", "nonsense"), 1))
    r.check("view-unknown-person-refused", refused(hf(r, d, "view", "waiting_on", "--person", "nobody"), 1))

    code, out, _ = hf(r, d, "view", "inbox", "--session", "discovery", "--format", "json")
    v = js(out) or []
    r.check("v_inbox-unaccepted-first", [x["id"] for x in v] == ["H-0001", "H-0002", "A-0003", "A-0004", "A-0001"], [x["id"] for x in v])
    r.check("v_inbox-unaccepted-flag", [x["unaccepted"] for x in v] == [1, 1, 0, 0, 0], [x.get("unaccepted") for x in v])
    code, out, _ = hf(r, d, "view", "inbox", "--session", "build", "--format", "json")
    r.check("v_inbox-other-session", ids(out) == ["H-0003", "A-0002", "A-0010"], out[:300])
    code, out, _ = hf(r, d, "view", "inbox", "--session", "process", "--format", "json")
    r.check("v_inbox-empty-session", code == 0 and ids(out) == [], out)
    code, out, _ = hf(r, d, "view", "inbox", "--format", "json")
    r.check("v_inbox-without-filter-lists-all-sessions", code == 0 and {x["session"] for x in js(out)} == {"discovery", "build"}, out[:200])
    code, out, _ = hf(r, d, "view", "inbox", "--session", "discovery", "--kind", "handoff", "--format", "json")
    r.check("v_inbox-kind-filter", ids(out) == ["H-0001", "H-0002"], out)
    r.check("accept-in-view-scenario", hf(r, d, "accept", "H-0002", session="discovery")[0] == 0)
    code, out, _ = hf(r, d, "view", "inbox", "--session", "discovery", "--format", "json")
    r.check("v_inbox-accepted-sorts-normally", ids(out) == ["H-0001", "A-0003", "A-0004", "A-0001", "H-0002"], out[:300])

    code, out, _ = hf(r, d, "view", "stale", "--format", "json")
    flags = {}
    for x in js(out) or []:
        flags.setdefault(x["id"], set()).add(x["flag"])
    want = {"A-0002": {"warn"}, "A-0003": {"lapse_due"}, "A-0004": {"warn"}, "A-0005": {"warn"},
            "H-0001": {"handoff_unaccepted"}, "H-0003": {"handoff_unaccepted"}}
    r.check("v_stale-flags", flags == want, flags)
    code, out, _ = hf(r, d, "view", "stale", "--session", "discovery", "--format", "json")
    r.check("v_stale-session-filter", sorted({x["id"] for x in js(out) or []}) == ["A-0003", "A-0004", "H-0001"], out[:300])
    code, out, _ = hf(r, d, "view", "stale", "--format", "json", now="2026-11-11T12:00:00Z")
    flags = {}
    for x in js(out) or []:
        flags.setdefault(x["id"], set()).add(x["flag"])
    r.check("v_stale-parked-expires", flags.get("A-0004") == {"lapse_due"} and flags.get("A-0003") == {"lapse_due"}, flags)
    code, out, _ = hf(r, d, "view", "stale", "--format", "json", now="2026-11-02T12:00:00Z")

    code, out, _ = hf(r, d, "view", "dup_refs", "--format", "json")
    v = js(out) or []
    got = {(x["kind"], x["ref"]): sorted(x["items"].split()) if isinstance(x["items"], str) else x["items"] for x in v}
    r.check("v_dup_refs", got == {("issue", "1234"): ["A-0001", "A-0010"], ("pr", "4000"): ["A-0008", "A-0009"]}, got)
    r.check("v_dup_refs-ignores-closed-and-other-kinds", ("pr", "3845") not in got and ("file", "alpha/notes") not in got)
    r.check("v_dup_refs-no-filter-allowed", refused(hf(r, d, "view", "dup_refs", "--session", "build"), 1))

    code, out, _ = hf(r, d, "view", "week", "--format", "json")
    r.check("v_week-exit-0", code == 0 and isinstance(js(out), list), out[:200])
    code, out, _ = hf(r, d, "view", "retention_due", "--week-start", "2026-11-02", "--format", "json")
    r.check("v_retention_due-exit-0", code == 0 and isinstance(js(out), list), out[:200])

    # read-only: the db did not change from any read
    before = snapshot(d)
    hf(r, d, "view", "open")
    hf(r, d, "view", "stale", now="2026-12-01T00:00:00Z")
    r.check("views-do-not-write", snapshot(d) == before)
    r.check("view-clock-from-env-on-read", q(d, "select value from meta where key='now'") != [("2026-12-01T00:00:00Z",)])
    return d


def case_week_view(r, root):
    d = fresh(r, root, "week")
    c = sqlite3.connect(dbfile(d))
    data = [
        ("A-0001", "ask", "done", "2026-10-25T23:59:59Z", "2026-10-27T00:00:00Z"),
        ("A-0002", "ask", "open", "2026-10-26T00:00:00Z", None),
        ("A-0003", "ask", "dropped", "2026-10-26T10:00:00Z", "2026-11-01T23:59:59Z"),
        ("A-0004", "ask", "lapsed", "2026-10-20T00:00:00Z", "2026-11-02T00:00:00Z"),
        ("T-0001", "thread", "open", "2026-11-02T00:00:00Z", None),
    ]
    for i, k, s, o, cl in data:
        c.execute("insert into item(id,kind,title,status,opened_at,renewed_at,closed_at) values(?,?,?,?,?,?,?)", (i, k, "Week " + i, s, o, o, cl))
    c.commit()
    c.close()
    code, out, err = hf(r, d, "view", "week", "--format", "json")
    got = {(x["week"], x["kind"]): (x["opened"], x["closed"], x["lapsed"]) for x in js(out) or []}
    want = {("2026-10-19", "ask"): (2, 0, 0), ("2026-10-26", "ask"): (2, 2, 0),
            ("2026-11-02", "ask"): (0, 0, 1), ("2026-11-02", "thread"): (1, 0, 0)}
    r.check("v_week-monday-weeks", code == 0 and got == want, got)
    code, out, _ = hf(r, d, "view", "week", "--kind", "thread", "--format", "json")
    r.check("v_week-kind-filter", [(x["week"], x["kind"]) for x in js(out) or []] == [("2026-11-02", "thread")], out)


def case_rotate(r, root):
    d = fresh(r, root, "rotate")
    D = "2026-11-02"
    add(r, d, "ask", "Lapses at 28", now="2026-10-05T12:00:00Z")  # A-1
    add(r, d, "ask", "Stays at 27", now="2026-10-06T12:00:00Z")  # A-2
    add(r, d, "ask", "Parked past", now="2026-10-05T12:00:00Z")  # A-3
    add(r, d, "ask", "Parked expired", now="2026-10-05T12:00:00Z")  # A-4
    add(r, d, "ask", "Parked until today", now="2026-10-05T12:00:00Z")  # A-5
    for i, until in (("A-0003", "2026-11-10"), ("A-0004", "2026-11-01"), ("A-0005", "2026-11-02")):
        ok(r, d, "park", i, "--until", until, now="2026-10-20T00:00:00Z")
    add(r, d, "ask", "Closed before cutoff", "--ref", "issue:1", now="2026-09-01T00:00:00Z")  # A-6
    ok(r, d, "note", "A-0006", "a note", now="2026-09-02T00:00:00Z")
    ok(r, d, "close", "A-0006", "--reason", "done", now="2026-09-27T23:59:59Z")
    add(r, d, "ask", "Closed at boundary", now="2026-09-01T00:00:00Z")  # A-7
    ok(r, d, "close", "A-0007", "--reason", "done", now="2026-09-28T00:00:00Z")
    add(r, d, "ask", "Closed after boundary", now="2026-09-01T00:00:00Z")  # A-8
    ok(r, d, "close", "A-0008", "--reason", "done", now="2026-09-28T00:00:01Z")
    add(r, d, "ask", "Kept, linked from pruned", now="2026-10-30T00:00:00Z")  # A-9
    ok(r, d, "link", "A-0006", "A-0009", "relates", now="2026-10-30T00:00:00Z")
    add(r, d, "ask", "Dropped long ago", now="2026-09-01T00:00:00Z")  # A-10
    ok(r, d, "close", "A-0010", "--reason", "dropped", now="2026-09-01T01:00:00Z")
    ok(r, d, "handoff", "--to", "discovery", "--title", "Old handoff", now="2026-09-01T00:00:00Z", session="build")  # H-1
    ok(r, d, "close", "H-0001", "--reason", "done", now="2026-09-02T00:00:00Z")
    ok(r, d, "session", "add", "old-desk", "--role", "test", now="2026-09-01T00:00:00Z")
    ok(r, d, "session", "rename", "old-desk", "older-desk", now="2026-09-01T00:00:00Z")
    ok(r, d, "session", "retire", "older-desk", now="2026-09-01T00:00:00Z")
    ok(r, d, "session", "add", "recent-desk", "--role", "test", now="2026-10-15T00:00:00Z")
    ok(r, d, "session", "retire", "recent-desk", now="2026-10-15T00:00:00Z")
    ok(r, d, "session", "add", "held-desk", "--role", "test", now="2026-09-01T00:00:00Z")
    add(r, d, "ask", "Owned by held", "--owner", "held-desk", now="2026-10-30T00:00:00Z")  # A-11
    ok(r, d, "session", "retire", "held-desk", now="2026-09-01T00:00:00Z")

    pre = hf(r, d, "view", "retention_due", "--week-start", D, "--format", "json")
    pv = js(pre[1]) or []
    r.check("v_retention_due-lapse-list", sorted(x["id"] for x in pv if x["would"] == "lapse") == ["A-0001", "A-0004"], pre[1][:400] + pre[2])
    r.check("v_retention_due-prune-list", sorted(x["id"] for x in pv if x["would"] == "prune") == ["A-0006", "A-0010", "H-0001"], pre[1][:400])

    snap, files = snapshot(d), jl_bytes(d)
    code, out, err = hf(r, d, "rotate", "--week-start", D, session=None)
    r.check("rotate-dry-run-needs-no-session", code == 0, err)
    r.check("rotate-dry-run-lists", listed(out, "lapsed:") == ["A-0001", "A-0004"] and listed(out, "pruned:") == ["A-0006", "A-0010", "H-0001"]
            and listed(out, "pruned_sessions:") == ["older-desk"], out)
    r.check("rotate-dry-run-writes-nothing", snapshot(d) == snap and jl_bytes(d) == files)
    r.check("rotate-non-monday-refused", refused(hf(r, d, "rotate", "--week-start", "2026-11-03"), 1))
    r.check("rotate-bad-date-refused", refused(hf(r, d, "rotate", "--week-start", "soon"), 1))
    r.check("rotate-needs-week-start", refused(hf(r, d, "rotate"), 1))
    r.check("rotate-yes-needs-session", refused(hf(r, d, "rotate", "--week-start", D, "--yes", session=None), 1, "HUB_SESSION"))
    r.check("rotate-refusals-write-nothing", snapshot(d) == snap)
    code, out, err = hf(r, d, "rotate", "--week-start", D, "--yes")
    r.check("rotate-yes-exit-0", code == 0, err)
    r.check("rotate-yes-reports-same-lists", listed(out, "lapsed:") == ["A-0001", "A-0004"] and listed(out, "pruned:") == ["A-0006", "A-0010", "H-0001"]
            and listed(out, "pruned_sessions:") == ["older-desk"], out)
    st = dict(q(d, "select id, status from item"))
    r.check("rotate-lapses-at-28-days", st.get("A-0001") == "lapsed", st)
    r.check("rotate-keeps-27-days", st.get("A-0002") == "open", st)
    r.check("rotate-park-prevents-lapse", st.get("A-0003") == "open" and st.get("A-0005") == "open", st)
    r.check("rotate-lapses-expired-park", st.get("A-0004") == "lapsed", st)
    it = q(d, "select closed_at, close_reason from item where id='A-0001'")
    r.check("rotate-lapse-fields", it and it[0][0] == NOW and it[0][1].startswith("lapsed: idle 28 days"), it)
    e = ev(d, "A-0001")
    r.check("rotate-lapse-event-by-script", e[-1][0] == "lapsed" and e[-1][4] == "script" and e[-1][3] == "discovery", e)
    r.check("prune-before-boundary-removed", "A-0006" not in st and "A-0010" not in st and "H-0001" not in st, sorted(st))
    r.check("prune-at-boundary-kept", "A-0007" in st, sorted(st))
    r.check("prune-one-second-after-kept", "A-0008" in st, sorted(st))
    r.check("lapsed-this-rotate-not-pruned", "A-0001" in st and "A-0004" in st)
    r.check("prune-cascades-to-refs-links-handoff", q(d, "select count(*) from item_ref where item_id in ('A-0006')")[0][0] == 0
            and q(d, "select count(*) from item_link where from_id='A-0006' or to_id='A-0006'")[0][0] == 0
            and q(d, "select count(*) from handoff where item_id='H-0001'")[0][0] == 0)
    r.check("events-pruned-with-items", q(d, "select count(*) from event where item_id in ('A-0006','A-0010','H-0001')")[0][0] == 0
            and q(d, "select count(*) from event where item_id is not null and item_id not in (select id from item)")[0][0] == 0)
    r.check("prune-keeps-other-events", len(ev(d, "A-0007")) >= 2 and len(ev(d, "A-0009")) >= 1)
    sess = {x[0] for x in q(d, "select name from session")}
    r.check("prune-retired-session-and-aliases", "older-desk" not in sess and q(d, "select count(*) from session_alias where name='older-desk' or alias='old-desk'")[0][0] == 0, sess)
    r.check("prune-keeps-recent-retired-session", "recent-desk" in sess)
    r.check("prune-keeps-retired-session-with-items", "held-desk" in sess)
    r.check("prune-keeps-seed-sessions", {"discovery", "build", "process", "support"} <= sess)
    r.check("rotate-export-and-check", hf(r, d, "check")[0] == 0 and out_of_sync(d) == [])
    code, out, err = hf(r, d, "rotate", "--week-start", D, "--yes")
    r.check("rotate-is-idempotent", code == 0 and listed(out, "lapsed:") == [] and listed(out, "pruned:") == [], out + err)


def case_import(r, root):
    d = fresh(r, root, "import")
    good = [
        {"kind": "ask", "title": "Imported ask", "status": "open", "owner": "discovery", "waits_on": "alex",
         "analysis": "slug", "refs": ["issue:1234"], "opened_at": "2026-10-14T00:00:00Z", "note": "source: notes line 42"},
        {"kind": "thread", "title": "Imported thread", "owner": "helpdesk", "opened_at": "2026-10-20T00:00:00Z", "note": "source: x"},
        {"kind": "handoff", "title": "Imported handoff", "from": "build", "to": "discovery", "gate": "g",
         "opened_at": "2026-10-30T00:00:00Z", "accepted_at": "2026-10-31T00:00:00Z"},
        {"kind": "ask", "title": "Imported closed", "status": "done", "opened_at": "2026-10-01T00:00:00Z", "closed_at": "2026-10-02T00:00:00Z"},
    ]
    gp = os.path.join(root, "good.jsonl")
    with open(gp, "w", encoding="utf-8") as f:
        f.write("\n\n".join(json.dumps(x) for x in good) + "\n")
    snap, files = snapshot(d), jl_bytes(d)
    code, out, err = hf(r, d, "import", gp, "--format", "json")
    v = js(out) or {}
    c = v.get("counts", {})
    r.check("import-dry-run-counts", code == 0 and c.get("kind") == {"ask": 2, "thread": 1, "handoff": 1}
            and c.get("owner") == {"discovery": 2, "support": 1, "none": 1}
            and c.get("waits_on") == {"alex": 1, "none": 3} and v.get("rejected") == [], out + err)
    r.check("import-dry-run-writes-nothing", snapshot(d) == snap and jl_bytes(d) == files)
    code, out, err = hf(r, d, "import", gp)
    r.check("import-dry-run-md", code == 0 and "ask" in out and "alex" in out, out + err)
    code, out, err = hf(r, d, "import", gp, "--yes")
    r.check("import-yes-exit-0", code == 0 and all(i in out for i in ("A-0001", "T-0001", "H-0001", "A-0002")), out + err)
    it = q(d, "select kind, title, status, owner_session, waits_on, analysis, opened_at, renewed_at, closed_at from item order by id")
    r.check("import-rows", ("ask", "Imported ask", "open", "discovery", "alex", "slug", "2026-10-14T00:00:00Z", "2026-10-14T00:00:00Z", None) in it
            and ("thread", "Imported thread", "open", "support", None, None, "2026-10-20T00:00:00Z", "2026-10-20T00:00:00Z", None) in it
            and ("ask", "Imported closed", "done", None, None, None, "2026-10-01T00:00:00Z", "2026-10-01T00:00:00Z", "2026-10-02T00:00:00Z") in it, it)
    r.check("import-refs", q(d, "select kind, ref from item_ref where item_id='A-0001'") == [("issue", "1234")])
    r.check("import-handoff", q(d, "select from_session, to_session, gate, accepted_at from handoff") == [("build", "discovery", "g", "2026-10-31T00:00:00Z")]
            and q(d, "select owner_session from item where id='H-0001'") == [("discovery",)])
    e = ev(d, "A-0001")
    r.check("import-event", e and e[0][0] == "imported" and e[0][5] == "source: notes line 42" and e[0][3] == "discovery", e)
    r.check("import-counters-continue", add(r, d, "ask", "After import") == "A-0003")

    d2 = fresh(r, root, "import-bad")
    lines = [
        json.dumps(good[0]),
        json.dumps({"kind": "wish", "title": "Bad kind"}),
        "{not json",
        json.dumps({"kind": "ask", "title": "ab"}),
        json.dumps({"kind": "ask", "title": "Bad analysis", "analysis": "W0/analyses/x"}),
        json.dumps({"kind": "ask", "title": "Bad owner", "owner": "ghost"}),
        json.dumps({"kind": "ask", "title": "Bad waits", "waits_on": "nobody"}),
        json.dumps({"kind": "ask", "title": "Bad ref", "refs": ["issue:x"]}),
        json.dumps({"kind": "handoff", "title": "No to", "from": "build"}),
        json.dumps({"kind": "ask", "title": "Done without time", "status": "done"}),
        json.dumps({"kind": "ask", "title": "Open with close time", "closed_at": "2026-10-02T00:00:00Z"}),
        json.dumps(good[1]),
    ]
    bp = os.path.join(root, "bad.jsonl")
    with open(bp, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    snap, files = snapshot(d2), jl_bytes(d2)
    code, out, err = hf(r, d2, "import", bp, "--format", "json")
    v = js(out) or {}
    r.check("import-dry-run-rejects-bad-rows", code == 1 and sorted(x["line"] for x in v.get("rejected", [])) == list(range(2, 12))
            and all(x.get("reason") for x in v.get("rejected", [])), out[:600] + err)
    code, out, err = hf(r, d2, "import", bp, "--yes")
    r.check("import-all-or-nothing", code == 1 and snapshot(d2) == snap and jl_bytes(d2) == files, out + err)
    r.check("import-missing-file", refused(hf(r, d2, "import", os.path.join(root, "nope.jsonl"), "--yes"), 1))
    r.check("import-yes-needs-session", refused(hf(r, d2, "import", gp, "--yes", session=None), 1, "HUB_SESSION"))


def case_sql(r, root, d):
    code, out, err = hf(r, d, "sql", "SELECT count(*) AS n FROM item", "--format", "json")
    r.check("sql-select", code == 0 and (js(out) or [{}])[0].get("n", 0) > 0, out + err)
    code, out, err = hf(r, d, "sql", "WITH x AS (SELECT 1 AS one) SELECT one FROM x;", "--format", "json")
    r.check("sql-with-and-trailing-semicolon", code == 0 and js(out) == [{"one": 1}], out + err)
    code, out, err = hf(r, d, "sql", "SELECT id FROM v_open ORDER BY id")
    r.check("sql-md-default", code == 0 and "| id |" in out, out + err)
    snap = snapshot(d)
    uv = q(d, "pragma user_version")[0][0]
    bad = ["INSERT INTO meta(key,value) VALUES('x','y')", "UPDATE item SET title='hacked title'", "DELETE FROM item",
           "ATTACH DATABASE '/tmp/claude-hubflow-evil.db' AS evil", "PRAGMA user_version = 5", "PRAGMA query_only = 0",
           "SELECT 1; SELECT 2", "SELECT 1; DELETE FROM item", "WITH x AS (SELECT 1) DELETE FROM item",
           "DROP TABLE item", "CREATE TABLE zzz(a)", "VACUUM", "", "   ", "-- just a comment",
           "SELECT 1 /* c */; PRAGMA user_version = 6"]
    for s in bad:
        res = hf(r, d, "sql", s)
        r.check("sql-refuses " + (s[:40] or "empty"), refused(res, 1), res)
    r.check("sql-refusals-write-nothing", snapshot(d) == snap and q(d, "pragma user_version")[0][0] == uv and not os.path.exists("/tmp/claude-hubflow-evil.db"))
    r.check("sql-needs-statement", refused(hf(r, d, "sql"), 1))


def case_realclock(r, root):
    d = os.path.join(root, "real", "flow")
    r.check("real-clock-init", hf(r, d, "init", "--seed", SEED, now=None)[0] == 0)
    r.check("real-clock-no-meta-now", q(d, "select count(*) from meta where key='now'") == [(0,)])
    code, out, err = hf(r, d, "add", "ask", "--title", "Real clock", now=None)
    r.check("real-clock-add", code == 0 and out.strip() == "A-0001", err)
    r.check("real-clock-no-meta-now-after-write", q(d, "select count(*) from meta where key='now'") == [(0,)])
    opened = q(d, "select opened_at from item")[0][0]
    r.check("real-clock-utc-format", re.fullmatch(r"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ", opened) is not None and opened >= "2026-11-02", opened)
    code, out, err = hf(r, d, "sql", "SELECT now FROM clock", "--format", "json", now=None)
    r.check("real-clock-view", code == 0 and re.fullmatch(r"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ", (js(out) or [{}])[0].get("now", "")) is not None, out + err)
    code, out, err = hf(r, d, "view", "open", "--format", "json", now=None)
    r.check("real-clock-view-open", code == 0 and (js(out) or [{}])[0].get("age_days") == 0, out + err)
    snap = snapshot(d)
    for s in ("INSERT INTO meta(key,value) VALUES('a','b')", "PRAGMA user_version = 9", "DELETE FROM item", "SELECT 1; SELECT 2"):
        r.check("real-clock-sql-refuses " + s[:20], refused(hf(r, d, "sql", s, now=None), 1))
    r.check("real-clock-sql-no-change", snapshot(d) == snap and q(d, "pragma user_version") == [(1,)])
    r.check("real-clock-bad-now-refused", refused(hf(r, d, "add", "ask", "--title", "Bad clock", now="2026-13-01"), 1))
    r.check("real-clock-bad-now-format", refused(hf(r, d, "add", "ask", "--title", "Bad clock", now="2026-11-01"), 1))


def case_state(r, root, base):
    # rebuild round trip
    snap = snapshot(base)
    for s in ("", "-wal", "-shm"):
        if os.path.exists(dbfile(base) + s):
            os.remove(dbfile(base) + s)
    ev_path = os.path.join(base, "jsonl", "event.jsonl")
    shutil.move(ev_path, ev_path + ".bak")
    res = hf(r, base, "rebuild")
    r.check("rebuild-missing-jsonl-refused", refused(res, 2) and not os.path.exists(dbfile(base)), res)
    shutil.move(ev_path + ".bak", ev_path)
    res = hf(r, base, "rebuild")
    r.check("rebuild-exit-0", res[0] == 0, res)
    r.check("rebuild-equals-original", snapshot(base) == snap)
    r.check("rebuild-check-clean", hf(r, base, "check")[0] == 0)
    r.check("rebuild-user-version", q(base, "pragma user_version") == [(1,)] and q(base, "pragma journal_mode") == [("wal",)])
    r.check("rebuild-refuses-existing-db", refused(hf(r, base, "rebuild"), 2))
    r.check("rebuilt-db-is-writable", add(r, base, "ask", "After rebuild") != "")
    # tampered export
    p = os.path.join(base, "jsonl", "item.jsonl")
    keep = open(p, encoding="utf-8").read()
    with open(p, "a", encoding="utf-8") as f:
        f.write(json.dumps({"id": "A-9999", "title": "forged"}) + "\n")
    res = hf(r, base, "check")
    r.check("check-catches-tampered-jsonl", refused(res, 3), res)
    with open(p, "w", encoding="utf-8") as f:
        f.write(keep)
    r.check("check-clean-again", hf(r, base, "check")[0] == 0)
    os.remove(p)
    r.check("check-catches-missing-jsonl", refused(hf(r, base, "check"), 3))
    r.check("export-restores-jsonl", hf(r, base, "export")[0] == 0 and hf(r, base, "check")[0] == 0)
    # db changed behind the script's back
    c = sqlite3.connect(dbfile(base))
    c.execute("update item set title='sneaky title' where id='A-0001'")
    c.commit()
    c.close()
    r.check("check-catches-db-drift", refused(hf(r, base, "check"), 3))
    hf(r, base, "export")

    # newer schema refused, nothing written
    d = fresh(r, root, "newer")
    add(r, d, "ask", "Before upgrade")
    c = sqlite3.connect(dbfile(d))
    c.execute("pragma user_version = 99")
    c.close()
    files, n = jl_bytes(d), q(d, "select count(*) from item")[0][0]
    for args in (("add", "ask", "--title", "Refused write"), ("view", "open"), ("check",), ("export",),
                 ("rotate", "--week-start", "2026-11-02", "--yes"), ("sql", "SELECT 1"), ("show", "A-0001"),
                 ("note", "A-0001", "x"), ("session", "add", "zz-desk", "--role", "x")):
        res = hf(r, d, *args)
        r.check("newer-schema-refused " + args[0], refused(res, 2, "schema"), res)
    r.check("newer-schema-writes-nothing", jl_bytes(d) == files and q(d, "select count(*) from item")[0][0] == n and q(d, "pragma user_version") == [(99,)])

    # missing db
    m = os.path.join(root, "missing", "flow")
    for args in (("view", "open"), ("show", "A-0001"), ("sql", "SELECT 1"), ("check",), ("add", "ask", "--title", "Nope"),
                 ("export",), ("rotate", "--week-start", "2026-11-02"), ("rebuild",)):
        res = hf(r, m, *args)
        r.check("missing-db-exit-2 " + args[0], refused(res, 2), res)
    r.check("missing-db-creates-nothing", not os.path.exists(m) and not os.path.exists(os.path.dirname(m)))


def case_session(r, root):
    d = fresh(r, root, "sess")
    r.check("session-add", hf(r, d, "session", "add", "new-desk", "--role", "test")[0] == 0 and q(d, "select role, status, retired_on from session where name='new-desk'") == [("test", "active", None)])
    r.check("session-add-event", q(d, "select count(*) from event where by_session='discovery' and verb like 'session%'")[0][0] >= 1)
    r.check("session-add-duplicate-refused", refused(hf(r, d, "session", "add", "new-desk", "--role", "test"), 1))
    r.check("session-add-bad-name", refused(hf(r, d, "session", "add", "Bad Name", "--role", "test"), 1))
    r.check("session-add-needs-role", refused(hf(r, d, "session", "add", "other-desk"), 1))
    r.check("session-add-alias-name-refused", refused(hf(r, d, "session", "add", "helpdesk", "--role", "x"), 1))
    r.check("session-add-needs-session", refused(hf(r, d, "session", "add", "zz-desk", "--role", "x", session=None), 1, "HUB_SESSION"))
    add(r, d, "ask", "Owned by new", "--owner", "new-desk")
    ok(r, d, "handoff", "--to", "build", "--title", "From new", session="new-desk")
    ok(r, d, "handoff", "--to", "new-desk", "--title", "To new", session="build")
    r.check("session-rename", hf(r, d, "session", "rename", "new-desk", "newer-desk")[0] == 0)
    r.check("session-rename-follows-items", q(d, "select owner_session from item where id='A-0001'") == [("newer-desk",)]
            and q(d, "select from_session from handoff where item_id='H-0001'") == [("newer-desk",)]
            and q(d, "select to_session from handoff where item_id='H-0002'") == [("newer-desk",)]
            and q(d, "select owner_session from item where id='H-0002'") == [("newer-desk",)])
    r.check("session-rename-leaves-alias", q(d, "select name from session_alias where alias='new-desk'") == [("newer-desk",)]
            and q(d, "select count(*) from session where name='new-desk'") == [(0,)])
    code, out, _ = hf(r, d, "view", "inbox", "--session", "new-desk", "--format", "json")
    r.check("session-old-name-resolves-in-filter", sorted(ids(out) or []) == ["A-0001", "H-0002"], out)
    res = hf(r, d, "add", "ask", "--title", "By old name", session="new-desk")
    r.check("session-old-name-resolves-as-writer", res[0] == 0 and ev(d, res[1].strip())[0][3] == "newer-desk", res)
    r.check("session-rename-to-existing-refused", refused(hf(r, d, "session", "rename", "newer-desk", "build"), 1))
    r.check("session-rename-unknown-refused", refused(hf(r, d, "session", "rename", "ghost", "spirit"), 1))
    r.check("session-rename-chain-alias", hf(r, d, "session", "rename", "newer-desk", "newest-desk")[0] == 0
            and q(d, "select name from session_alias where alias='new-desk'") == [("newest-desk",)])
    r.check("session-retire", hf(r, d, "session", "retire", "newest-desk", now="2026-11-03T00:00:00Z")[0] == 0
            and q(d, "select status, retired_on from session where name='newest-desk'") == [("retired", "2026-11-03")])
    r.check("session-retired-owner-refused", refused(hf(r, d, "add", "ask", "--title", "Nope", "--owner", "newest-desk"), 1))
    r.check("session-retired-handoff-to-refused", refused(hf(r, d, "handoff", "--to", "newest-desk", "--title", "Nope"), 1))
    r.check("session-retire-twice-refused", refused(hf(r, d, "session", "retire", "newest-desk"), 1))
    r.check("session-retire-unknown-refused", refused(hf(r, d, "session", "retire", "ghost"), 1))
    r.check("session-check-clean", hf(r, d, "check")[0] == 0)


def case_misc(r, root):
    h = os.path.join(root, "hubroot")
    os.makedirs(os.path.join(h, "W0", "analyses", "foo"))
    os.makedirs(os.path.join(h, "W2", "analyses", "foo"))
    os.makedirs(os.path.join(h, "W3", "analyses", "bar"))
    d = os.path.join(root, "nowhere", "flow")  # no db: `where` must not need one
    res = hf(r, d, "where", "foo", hub=h, session=None)
    r.check("where-newest-first", res[0] == 0 and res[1].strip() == "W0/analyses/foo", res)
    shutil.rmtree(os.path.join(h, "W0", "analyses", "foo"))
    r.check("where-falls-back-to-older-week", hf(r, d, "where", "foo", hub=h)[1].strip() == "W2/analyses/foo")
    r.check("where-other-slug", hf(r, d, "where", "bar", hub=h)[1].strip() == "W3/analyses/bar")
    r.check("where-missing-exit-1", refused(hf(r, d, "where", "nope", hub=h), 1))
    r.check("where-rejects-path-slug", refused(hf(r, d, "where", "W0/analyses/foo", hub=h), 1))
    r.check("where-rejects-dotdot", refused(hf(r, d, "where", "../W2", hub=h), 1))
    r.check("where-creates-nothing", not os.path.exists(d))
    # HUBFLOW_DB_DIR wins over --hub: the hub's own flow/ is never touched
    e = fresh(r, root, "envwins")
    res = hf(r, e, "add", "ask", "--title", "Env wins", hub=h)
    r.check("env-db-dir-wins", res[0] == 0 and q(e, "select count(*) from item") == [(1,)] and not os.path.exists(os.path.join(h, "flow")), res)
    p = subprocess.run([sys.executable, "-I", REAL, "--help"], capture_output=True, text=True)
    r.check("help-exit-0", p.returncode == 0 and "usage" in p.stdout.lower(), p.stderr)
    res = hf(r, e, "frobnicate")
    r.check("unknown-command-exit-1", refused(res, 1), res)
    res = hf(r, e)
    r.check("no-command-exit-1", refused(res, 1), res)


def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(obj if isinstance(obj, str) else json.dumps(obj))
    return path


def case_seed(r, root):
    # default seed file: flow/seed.json, read when --seed is not given
    d = os.path.join(root, "seeddefault", "flow")
    write_json(os.path.join(d, "seed.json"), {"sessions": [{"name": "solo", "role": "all"}],
                                              "persons": [{"key": "pat", "display": "Pat"}]})
    code, _, err = hf(r, d, "init", session=None)
    r.check("init-default-seed-file", code == 0 and q(d, "select name, role from session") == [("solo", "all")]
            and q(d, "select key, display from person") == [("pat", "Pat")] and q(d, "select count(*) from session_alias") == [(0,)], err)
    r.check("default-seed-session-can-write", hf(r, d, "add", "ask", "--title", "Solo ask", session="solo")[0] == 0)
    # --seed wins over flow/seed.json
    d = os.path.join(root, "seedflag", "flow")
    write_json(os.path.join(d, "seed.json"), {"sessions": [{"name": "solo", "role": "all"}]})
    code, _, err = hf(r, d, "init", "--seed", SEED, session=None)
    r.check("init-seed-flag-wins", code == 0 and {x[0] for x in q(d, "select name from session")} == {"discovery", "build", "process", "support"}, err)
    # no seed at all: meta only
    d = os.path.join(root, "noseed", "flow")
    code, _, err = hf(r, d, "init", session=None)
    r.check("init-no-seed-exit-0", code == 0, err)
    if code != 0:
        return
    r.check("init-no-seed-empty", [q(d, f"select count(*) from {t}")[0][0] for t in ("session", "session_alias", "person", "item")] == [0, 0, 0, 0])
    meta = dict(q(d, "select key, value from meta"))
    r.check("init-no-seed-meta", all(meta.get(k) == "1" for k in ("next_A", "next_T", "next_K", "next_H")), meta)
    r.check("init-no-seed-check-clean", hf(r, d, "check")[0] == 0)
    r.check("no-seed-write-refused-unknown-session", refused(hf(r, d, "add", "ask", "--title", "Nope", session="discovery"), 1, "unknown session")
            and q(d, "select count(*) from item") == [(0,)])
    r.check("no-seed-session-add-other-name-refused", refused(hf(r, d, "session", "add", "first", "--role", "r", session="someone"), 1, "unknown session"))
    r.check("no-seed-first-session-bootstrap", hf(r, d, "session", "add", "first", "--role", "r", session="first")[0] == 0
            and q(d, "select name, status from session") == [("first", "active")]
            and q(d, "select by_session, verb, new from event") == [("first", "session_add", "first")])
    r.check("no-seed-bootstrap-only-once", refused(hf(r, d, "session", "add", "second", "--role", "r", session="second"), 1, "unknown session"))
    r.check("no-seed-first-session-writes", hf(r, d, "add", "ask", "--title", "First ask", session="first")[0] == 0)
    # bad seed shapes: exit 1, nothing created
    bad = [
        ("not-json", "{not json"),
        ("not-object", [{"name": "x", "role": "y"}]),
        ("unknown-key", {"sessions": [], "people": []}),
        ("sessions-not-list", {"sessions": {"name": "x", "role": "y"}}),
        ("session-missing-role", {"sessions": [{"name": "x"}]}),
        ("session-extra-field", {"sessions": [{"name": "x", "role": "y", "color": "z"}]}),
        ("session-bad-name", {"sessions": [{"name": "Bad Name", "role": "y"}]}),
        ("session-empty-role", {"sessions": [{"name": "x", "role": ""}]}),
        ("session-duplicate", {"sessions": [{"name": "x", "role": "y"}, {"name": "x", "role": "z"}]}),
        ("alias-to-unknown", {"sessions": [{"name": "x", "role": "y"}], "aliases": [{"alias": "a", "name": "nope"}]}),
        ("alias-same-as-session", {"sessions": [{"name": "x", "role": "y"}], "aliases": [{"alias": "x", "name": "x"}]}),
        ("person-display-not-string", {"persons": [{"key": "p", "display": 5}]}),
        ("person-duplicate", {"persons": [{"key": "p", "display": "P"}, {"key": "p", "display": "Q"}]}),
    ]
    for name, obj in bad:
        sp = write_json(os.path.join(root, "badseeds", name + ".json"), obj)
        d = os.path.join(root, "badseed-" + name, "flow")
        res = hf(r, d, "init", "--seed", sp, session=None)
        r.check("bad-seed-refused " + name, refused(res, 1, "seed") and not os.path.exists(os.path.dirname(d)), res)
    d = os.path.join(root, "badseed-default", "flow")
    write_json(os.path.join(d, "seed.json"), {"sessions": "x"})
    res = hf(r, d, "init", session=None)
    r.check("bad-default-seed-refused", refused(res, 1, "seed") and not os.path.exists(dbfile(d)), res)
    res = hf(r, os.path.join(root, "badseed-missing", "flow"), "init", "--seed", os.path.join(root, "nope.json"), session=None)
    r.check("missing-seed-file-refused", refused(res, 1, "seed"), res)
    r.check("init-seed-needs-value", refused(hf(r, os.path.join(root, "badseed-novalue", "flow"), "init", "--seed", session=None), 1))


def case_issue_ref(r, root):
    d = fresh(r, root, "issueref")
    for name, ref in (("letters", "issue:12a"), ("hash", "issue:#12"), ("space-inside", "issue:1 2"), ("negative", "issue:-5")):
        r.check("issue-ref-refused " + name, refused(hf(r, d, "add", "ask", "--title", "Nope", "--ref", ref), 1, "digits"))
    r.check("other-tracker-kind-refused", refused(hf(r, d, "add", "ask", "--title", "Nope", "--ref", "ticket:42"), 1, "KIND"))
    code, out, err = hf(r, d, "add", "ask", "--title", "Has an issue", "--ref", "issue:42", "--ref", "issue: 7 ")
    r.check("issue-ref-digits-accepted", code == 0 and q(d, "select kind, ref from item_ref order by ref") == [("issue", "42"), ("issue", "7")], err)
    r.check("issue-ref-add-and-rm", hf(r, d, "ref", "A-0001", "add", "issue:99")[0] == 0 and hf(r, d, "ref", "A-0001", "rm", "issue:99")[0] == 0)
    r.check("issue-ref-add-refused", refused(hf(r, d, "ref", "A-0001", "add", "issue:x9"), 1, "digits"))
    add(r, d, "ask", "Shares issue 42", "--ref", "issue:42")
    code, out, _ = hf(r, d, "view", "dup_refs", "--format", "json")
    r.check("issue-ref-in-dup-refs", [(x["kind"], x["ref"]) for x in js(out) or []] == [("issue", "42")], out)


def case_hub_default(r, root):
    h = os.path.join(root, "envhub")
    os.makedirs(os.path.join(h, "W1", "analyses", "envslug"))
    sub = os.path.join(root, "elsewhere")
    os.makedirs(sub)
    res = hf(r, None, "where", "envslug", session=None, extra_env={"HUBFLOW_HUB": h}, cwd=sub)
    r.check("hub-default-from-env", res[0] == 0 and res[1].strip() == "W1/analyses/envslug", res)
    g = os.path.join(root, "gitroot")
    os.makedirs(os.path.join(g, "W4", "analyses", "gitslug"))
    os.makedirs(os.path.join(g, "deep", "er"))
    gi = subprocess.run(["git", "init", "-q", g], capture_output=True, text=True)
    if gi.returncode == 0:
        res = hf(r, None, "where", "gitslug", session=None, cwd=os.path.join(g, "deep", "er"))
        r.check("hub-default-git-toplevel", res[0] == 0 and res[1].strip() == "W4/analyses/gitslug", res)
        res = hf(r, None, "where", "gitslug", session=None, extra_env={"HUBFLOW_HUB": h}, cwd=os.path.join(g, "deep"))
        r.check("hub-env-wins-over-git", refused(res, 1), res)
        res = hf(r, None, "where", "gitslug", hub=g, session=None, extra_env={"HUBFLOW_HUB": h}, cwd=sub)
        r.check("hub-flag-wins-over-env", res[0] == 0 and res[1].strip() == "W4/analyses/gitslug", res)
    else:
        r.check("hub-default-git-toplevel", False, "git init failed: " + gi.stderr)
    c = os.path.join(root, "plaincwd")
    os.makedirs(os.path.join(c, "W0", "analyses", "cwdslug"))
    inside = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, cwd=c)
    if inside.returncode != 0:  # only meaningful when the temp dir is outside every git repo
        res = hf(r, None, "where", "cwdslug", session=None, cwd=c)
        r.check("hub-default-cwd", res[0] == 0 and res[1].strip() == "W0/analyses/cwdslug", res)
    # the default flow dir is <hub>/flow
    res = hf(r, None, "init", "--seed", SEED, hub=h, session=None)
    r.check("flow-dir-under-hub", res[0] == 0 and os.path.exists(os.path.join(h, "flow", "flow.db")), res)


def v2_script(r, root):
    """A copy of the script under test, one schema step ahead: v2 adds item.probe."""
    src = open(r.script, encoding="utf-8").read()
    for a, b in (("SCHEMA_VERSION = 1", "SCHEMA_VERSION = 2"),
                 ("MIGRATIONS = {}", "MIGRATIONS = {1: ['ALTER TABLE item ADD COLUMN probe TEXT']}")):
        if src.count(a) != 1:
            raise RuntimeError(f"v2 anchor {a!r} occurs {src.count(a)} times")
        src = src.replace(a, b)
    path = os.path.join(root, "hubflow-v2.py")
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    return path


def case_migrate(r, root):
    d = fresh(r, root, "migrate")
    add(r, d, "ask", "Before the migration", "--waits-on", "me")
    before = jl_bytes(d)
    res = hf(r, d, "migrate")
    r.check("migrate-at-current-is-noop", res[0] == 0 and "already" in res[1] and jl_bytes(d) == before, res)
    v2 = Run(v2_script(r, root))
    res = hf(v2, d, "add", "ask", "--title", "Refused before migrate")
    r.check("old-db-refused-until-migrate", res[0] == 2 and "migrate" in res[2], res)
    res = hf(v2, d, "migrate")
    r.check("migrate-runs", res[0] == 0, res)
    r.check("migrate-sets-version", q(d, "PRAGMA user_version")[0][0] == 2, q(d, "PRAGMA user_version"))
    r.check("migrate-keeps-backup", os.path.exists(os.path.join(d, "flow.db.bak-v1")), os.listdir(d))
    items = jl_lines(d, "item")
    r.check("migrate-reexports-jsonl", items and all("probe" in json.loads(x) for x in items), items[:1])
    r.check("migrate-keeps-rows", len(items) == 1 and "Before the migration" in items[0], items)
    res = hf(v2, d, "check")
    r.check("check-after-migrate", res[0] == 0, res)
    res = hf(v2, d, "add", "ask", "--title", "After the migration")
    r.check("write-after-migrate", res[0] == 0, res)
    res = hf(r, d, "view", "open")
    r.check("newer-db-refused-by-old-script", res[0] == 2 and "newer" in res[2], res)
    d0 = fresh(r, root, "migrate-zero")
    c = sqlite3.connect(dbfile(d0)); c.execute("PRAGMA user_version = 0"); c.commit(); c.close()
    res = hf(r, d0, "migrate")
    r.check("migrate-without-a-step-refused", res[0] == 2 and "no upgrade step" in res[2]
            and q(d0, "PRAGMA user_version")[0][0] == 0, res)


def case_rebuild_columns(r, root):
    d = fresh(r, root, "rebuild-cols")
    add(r, d, "ask", "Row with an unknown column", "--waits-on", "me")
    p = os.path.join(d, "jsonl", "item.jsonl")
    rows_ = [json.loads(x) for x in open(p, encoding="utf-8") if x.strip()]
    rows_[0]["from_a_newer_schema"] = "x"
    with open(p, "w", encoding="utf-8") as f:
        f.writelines(json.dumps(x, sort_keys=True) + "\n" for x in rows_)
    for s in ("", "-wal", "-shm"):
        if os.path.exists(dbfile(d) + s):
            os.remove(dbfile(d) + s)
    res = hf(r, d, "rebuild")
    r.check("rebuild-refuses-unknown-columns", res[0] == 2 and "from_a_newer_schema" in res[2]
            and not os.path.exists(dbfile(d)), res)


def cases(r):
    global SEED
    root = tempfile.mkdtemp(prefix="hubflow-test-")
    try:
        SEED = write_json(os.path.join(root, "seed.json"), SEED_DATA)
        case_init(r, root)
        base = case_basic(r, root)
        case_handoff(r, root)
        views = case_views(r, root)
        case_week_view(r, root)
        case_rotate(r, root)
        case_import(r, root)
        case_sql(r, root, base)
        case_realclock(r, root)
        case_session(r, root)
        case_misc(r, root)
        case_seed(r, root)
        case_issue_ref(r, root)
        case_hub_default(r, root)
        case_state(r, root, base)
        case_migrate(r, root)
        case_rebuild_columns(r, root)
        r.check("jsonl-equals-db-after-every-write", not r.sync_bad, r.sync_bad[:3])
    except Exception as e:  # a scenario that cannot even run is a failure, not a crash
        r.check("scenario-ran", False, repr(e))
    finally:
        shutil.rmtree(root, ignore_errors=True)


def main():
    global QUIET
    r = Run(REAL)
    if not os.path.exists(REAL):
        print("FAIL hubflow.py-exists: " + REAL + " is missing")
        print("0 passed, 1 failed")
        sys.exit(1)
    cases(r)
    total, passed = len(r.results), r.results.count(True)
    if "--mutants" in sys.argv[1:]:
        QUIET = True
        src = open(REAL, encoding="utf-8").read()
        for name, anchor, repl in MUTANTS:
            n = src.count(anchor)
            if n != 1:
                print(f"FAIL mutant {name}: anchor occurs {n} times")
                total += 1
                continue
            d = tempfile.mkdtemp(prefix="hubflow-mutant-")
            path = os.path.join(d, "hubflow.py")
            with open(path, "w", encoding="utf-8") as f:
                f.write(src.replace(anchor, repl))
            m = Run(path)
            cases(m)
            shutil.rmtree(d, ignore_errors=True)
            killed = not all(m.results)
            print(("PASS" if killed else "FAIL") + f" mutant {name}: " + ("KILLED" if killed else "SURVIVED")
                  + (f" ({m.results.count(False)} cases failed)" if killed else ""))
            total += 1
            passed += 1 if killed else 0
        QUIET = False
    print(f"{passed} passed, {total - passed} failed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()

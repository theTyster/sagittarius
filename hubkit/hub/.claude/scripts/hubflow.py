#!/usr/bin/env python3
"""hubflow.py -- a flow-state store for a notes hub: asks, threads, holds and handoffs between sessions.

One SQLite file, flow/flow.db, in WAL mode, ignored by git. After every write the script rewrites
one sorted JSONL file per table in flow/jsonl/, inside the same transaction; git tracks those, as
the readable diff and the archive. The JSONL rebuilds the db. This script is the only writer.

Flow state only: who owns a thing, who it waits on, what it hands to whom. Ticket text, PR text and
board columns stay in your tracker; an item holds a pointer (`issue:42`) and nothing more.

usage: hubflow.py [--hub DIR] [--session S] [--by WHO] COMMAND [ARGS]
  init [--seed FILE]                           create the db and seed it (refuses if it exists).
                                               Seed: --seed FILE, else flow/seed.json if present,
                                               else no sessions, aliases or persons
  add KIND --title T [--owner S|none] [--waits-on P] [--analysis SLUG] [--ref KIND:REF ...]
          [--status open|waiting] [--note N]   KIND: ask thread hold. Prints the new id
  handoff --to S --title T [--gate G] [--analysis SLUG] [--ref ...] [--note N]
                                               H- item: from = the writer, owner = S, status open
  accept ID                                    only the to-session may accept; sets accepted_at
  renew ID [--note N]                          renewed_at = now (an open item only)
  park ID --until YYYY-MM-DD [--note N]        not lapsed before that date
  set ID [--title T] [--owner S] [--waits-on P|none] [--status open|waiting] [--analysis SLUG|none]
  close ID --reason done|dropped [--note N]
  reopen ID [--note N]
  ref ID add|rm KIND:REF                       KIND: issue pr build release kb file commit url
  link FROM TO KIND                            KIND: blocks duplicates relates supersedes follows
  note ID TEXT                                 an event with verb note
  show ID [--format md|json]                   the item, refs, links, handoff and events
  view NAME [--session S] [--person P] [--kind K] [--week-start D] [--format md|json|tsv]
                                               NAME: open waiting_on inbox stale dup_refs week
                                               retention_due (v_ prefix optional)
  sql "SELECT ..." [--format md|json|tsv]      read-only; one SELECT or WITH statement, else exit 1
  session add NAME --role R | rename OLD NEW | retire NAME
                                               with no sessions at all, `session add NAME` by the
                                               writer NAME makes the first session
  where SLUG                                   the W-slot path of an analysis slug, newest week first
  import FILE [--yes] [--format md|json]       JSONL of items; a dry run without --yes; all or nothing
  rotate --week-start YYYY-MM-DD [--yes]       lapse and prune; a dry run without --yes
  export                                       rewrite the JSONL from the db
  rebuild                                      make the db from the JSONL (refuses if the db exists)
  check                                        schema, foreign keys, and JSONL equal to the db
  migrate                                      bring an older db up to this script's schema: copies
                                               the db to flow/flow.db.bak-v<N> first, then runs each
                                               step and rewrites the JSONL, all in one transaction

Every write needs a session: HUB_SESSION, or --session S (an alias resolves to the current name).
--by human|agent|script (default agent); `human` records a person's own words and needs --note
with the quote.
Output: md tables by default; --format json for scripts. Errors go to stderr as `hubflow: ERROR: ...`.

Seed file (JSON; every key optional, no other keys):
  {"sessions": [{"name": "discovery", "role": "discovery"}, ...],
   "aliases":  [{"alias": "helpdesk", "name": "support"}],
   "persons":  [{"key": "me", "display": "Me"}]}
  Session names and aliases: lowercase letters, digits and dashes. An alias names a seeded session.

Environment
  HUB_SESSION          the writer's session name
  HUBFLOW_HUB          the hub root, when --hub is not given
  HUBFLOW_DB_DIR       the flow/ directory (tests). It wins over --hub; default <hub>/flow
  HUBFLOW_NOW          fixes the clock, YYYY-MM-DDTHH:MM:SSZ (tests). Every write stores it as
                       meta.now so views read the same clock; a read applies it to a private copy
  --hub DIR            the hub root (default: HUBFLOW_HUB, else the git toplevel of the current
                       directory, else the current directory); `where` reads it

The hub is a weekly calendar: W0 is the current week, W5 five weeks back, each with an analyses/
directory. `where` and the retention windows below follow it.

Exit codes
  0 ok   1 bad input or a refused rule   2 db state (missing, exists, older or newer schema, locked)
  3 check found a difference

Retention (rotate --week-start D, D the Monday of the new W0; W5 starts at D - 35 days)
  lapse: open or waiting, idle 28 days or more, not parked through today -> status lapsed
  prune: closed before D - 35 days -> deleted with refs, links, handoff and events; retired
         sessions retired before then and referenced by no item go with their aliases
  The caller commits flow/jsonl/ with the ids in the message; git history is the archive.

Schema v1 (PRAGMA user_version = 1; times are UTC TEXT YYYY-MM-DDTHH:MM:SSZ)
  meta(key, value)                  next_A next_T next_K next_H, and now (tests only)
  session(name, role, status active|retired, started_on, retired_on)
  session_alias(alias, name, since)
  person(key, display)
  item(id, kind ask|thread|hold|handoff, title 3..200, status open|waiting|done|dropped|lapsed,
       owner_session, waits_on, analysis (a slug, never a W-slot path), opened_at, renewed_at,
       parked_until, closed_at, close_reason)       closed_at is set exactly when status is closed
  item_ref(item_id, kind, ref)      issue and pr refs are digits; kb and file refs are relative to
                                    an analysis (<slug>/kb), never W0/...
  item_link(from_id, to_id, kind)
  handoff(item_id, from_session, to_session, gate, accepted_at)
  event(seq, at, item_id, verb, old, new, by_session, by human|agent|script, note)
Views: clock v_open v_waiting_on v_inbox v_stale v_dup_refs v_week v_retention_due
"""
import datetime, json, os, re, sqlite3, subprocess, sys
from urllib.parse import quote

SCHEMA_VERSION = 1
# Schema steps: MIGRATIONS[v] is the SQL that takes a db from schema v to v + 1. A release that
# changes the schema raises SCHEMA_VERSION, changes DDL to the new shape, and adds the step here.
MIGRATIONS = {}
WARN_DAYS = 14
LAPSE_DAYS = 28
PRUNE_DAYS = 35
ITEM_KINDS = ("ask", "thread", "hold", "handoff")
ADDABLE = ("ask", "thread", "hold")
STATUSES = ("open", "waiting", "done", "dropped", "lapsed")
OPEN = ("open", "waiting")
PREFIX = {"ask": "A", "thread": "T", "hold": "K", "handoff": "H"}
REF_KINDS = ("issue", "pr", "build", "release", "kb", "file", "commit", "url")
LINK_KINDS = ("blocks", "duplicates", "relates", "supersedes", "follows")
BY = ("human", "agent", "script")
W_SLOT = re.compile(r"^W\d/", re.I)
SLUG = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
SESSION_NAME = re.compile(r"^[a-z0-9][a-z0-9-]*$")
TS = re.compile(r"^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$")
DATE = re.compile(r"^\d{4}-\d\d-\d\d$")
SQL_OK = re.compile(r"^\s*(select|with)\b", re.I)
TS_FMT = "%Y-%m-%dT%H:%M:%SZ"

TABLES = ("meta", "session", "session_alias", "person", "item", "item_ref", "item_link", "handoff", "event")
ORDER = {"meta": "key", "session": "name", "session_alias": "alias", "person": "key", "item": "id",
         "item_ref": "item_id, kind, ref", "item_link": "from_id, to_id, kind", "handoff": "item_id",
         "event": "seq"}

SEED_KEYS = {"sessions": ("name", "role"), "aliases": ("alias", "name"), "persons": ("key", "display")}

AGE = "(CAST(strftime('%s', clock.now) AS INTEGER) - CAST(strftime('%s', {col}) AS INTEGER)) / 86400"

DDL = [
    "CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
    """CREATE TABLE session(name TEXT PRIMARY KEY, role TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('active','retired')), started_on TEXT NOT NULL, retired_on TEXT)""",
    "CREATE TABLE session_alias(alias TEXT PRIMARY KEY, name TEXT NOT NULL REFERENCES session(name), since TEXT NOT NULL)",
    "CREATE TABLE person(key TEXT PRIMARY KEY, display TEXT NOT NULL)",
    """CREATE TABLE item(
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL CHECK(kind IN ('ask','thread','hold','handoff')),
  title TEXT NOT NULL CHECK(length(title) BETWEEN 3 AND 200),
  status TEXT NOT NULL CHECK(status IN ('open','waiting','done','dropped','lapsed')),
  owner_session TEXT REFERENCES session(name),
  waits_on TEXT REFERENCES person(key),
  analysis TEXT CHECK(analysis IS NULL OR analysis NOT LIKE 'W_/%'),
  opened_at TEXT NOT NULL, renewed_at TEXT NOT NULL, parked_until TEXT,
  closed_at TEXT, close_reason TEXT,
  CHECK((status IN ('done','dropped','lapsed')) = (closed_at IS NOT NULL)))""",
    """CREATE TABLE item_ref(item_id TEXT NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK(kind IN ('issue','pr','build','release','kb','file','commit','url')),
  ref TEXT NOT NULL, PRIMARY KEY(item_id, kind, ref))""",
    """CREATE TABLE item_link(from_id TEXT NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  to_id TEXT NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK(kind IN ('blocks','duplicates','relates','supersedes','follows')),
  PRIMARY KEY(from_id, to_id, kind), CHECK(from_id <> to_id))""",
    """CREATE TABLE handoff(item_id TEXT PRIMARY KEY REFERENCES item(id) ON DELETE CASCADE,
  from_session TEXT NOT NULL REFERENCES session(name), to_session TEXT NOT NULL REFERENCES session(name),
  gate TEXT, accepted_at TEXT, CHECK(from_session <> to_session))""",
    """CREATE TABLE event(seq INTEGER PRIMARY KEY, at TEXT NOT NULL,
  item_id TEXT REFERENCES item(id) ON DELETE CASCADE,
  verb TEXT NOT NULL, old TEXT, new TEXT,
  by_session TEXT NOT NULL, by TEXT NOT NULL CHECK(by IN ('human','agent','script')), note TEXT)""",
    """CREATE VIEW clock AS SELECT COALESCE((SELECT value FROM meta WHERE key='now'),
                                     strftime('%Y-%m-%dT%H:%M:%SZ','now')) AS now""",
    f"""CREATE VIEW v_open AS
SELECT i.id, i.kind, i.title, i.status, i.owner_session, i.waits_on, i.analysis,
  COALESCE((SELECT group_concat(kind || ':' || ref, ' ')
            FROM (SELECT kind, ref FROM item_ref r WHERE r.item_id = i.id ORDER BY kind, ref)), '') AS refs,
  {AGE.format(col='i.opened_at')} AS age_days,
  {AGE.format(col='i.renewed_at')} AS idle_days,
  i.opened_at, i.renewed_at, i.parked_until
FROM item i, clock WHERE i.status IN ('open','waiting')""",
    "CREATE VIEW v_waiting_on AS SELECT * FROM v_open WHERE waits_on IS NOT NULL",
    f"""CREATE VIEW v_inbox AS
SELECT i.owner_session AS session, i.id, i.kind, i.title, i.status,
  CASE WHEN h.item_id IS NOT NULL AND h.accepted_at IS NULL THEN 1 ELSE 0 END AS unaccepted,
  {AGE.format(col='i.opened_at')} AS age_days,
  {AGE.format(col='i.renewed_at')} AS idle_days,
  i.opened_at
FROM item i LEFT JOIN handoff h ON h.item_id = i.id, clock
WHERE i.status IN ('open','waiting') AND i.owner_session IS NOT NULL""",
    f"""CREATE VIEW v_stale AS
SELECT * FROM (
  SELECT o.id, o.kind, o.title, o.owner_session, o.age_days, o.idle_days, o.parked_until,
    CASE WHEN o.idle_days >= {LAPSE_DAYS} AND (o.parked_until IS NULL OR o.parked_until < date(clock.now)) THEN 'lapse_due'
         WHEN o.idle_days >= {WARN_DAYS} THEN 'warn' END AS flag
  FROM v_open o, clock
  UNION ALL
  SELECT o.id, o.kind, o.title, o.owner_session, o.age_days, o.idle_days, o.parked_until, 'handoff_unaccepted'
  FROM v_open o JOIN handoff h ON h.item_id = o.id, clock
  WHERE h.accepted_at IS NULL
    AND CAST(strftime('%s', clock.now) AS INTEGER) - CAST(strftime('%s', o.opened_at) AS INTEGER) > 86400
) WHERE flag IS NOT NULL""",
    """CREATE VIEW v_dup_refs AS
SELECT r.kind, r.ref, COUNT(*) AS n, group_concat(r.item_id, ' ') AS items
FROM (SELECT x.kind, x.ref, x.item_id FROM item_ref x JOIN item i ON i.id = x.item_id
      WHERE i.status IN ('open','waiting') AND x.kind IN ('issue','pr') ORDER BY x.item_id) r
GROUP BY r.kind, r.ref HAVING COUNT(*) > 1""",
    """CREATE VIEW v_week AS
SELECT week, kind, SUM(o) AS opened, SUM(c) AS closed, SUM(l) AS lapsed FROM (
  SELECT date(opened_at, '-6 days', 'weekday 1') AS week, kind, 1 AS o, 0 AS c, 0 AS l FROM item
  UNION ALL
  SELECT date(closed_at, '-6 days', 'weekday 1'), kind, 0, 1, 0 FROM item WHERE status IN ('done','dropped')
  UNION ALL
  SELECT date(closed_at, '-6 days', 'weekday 1'), kind, 0, 0, 1 FROM item WHERE status = 'lapsed'
) GROUP BY week, kind""",
    f"""CREATE VIEW v_retention_due AS
WITH p AS (SELECT clock.now AS now,
                  COALESCE((SELECT value FROM meta WHERE key='rotate_week_start'),
                           date(clock.now, '-6 days', 'weekday 1')) AS wk FROM clock)
SELECT i.id, i.kind, i.title, i.status, 'lapse' AS would,
  'idle ' || ((CAST(strftime('%s', p.now) AS INTEGER) - CAST(strftime('%s', i.renewed_at) AS INTEGER)) / 86400) || ' days' AS detail
FROM item i, p
WHERE i.status IN ('open','waiting')
  AND i.renewed_at <= strftime('%Y-%m-%dT%H:%M:%SZ', p.now, '-{LAPSE_DAYS} days')
  AND (i.parked_until IS NULL OR i.parked_until < date(p.now))
UNION ALL
SELECT i.id, i.kind, i.title, i.status, 'prune', 'closed ' || i.closed_at
FROM item i, p
WHERE i.closed_at IS NOT NULL
  AND i.closed_at < strftime('%Y-%m-%dT00:00:00Z', p.wk, '-{PRUNE_DAYS} days')""",
]

# view name -> (sql view, filter option -> column, ORDER BY)
VIEW_DEFS = {
    "open": ("v_open", {"session": "owner_session", "kind": "kind"}, "id"),
    "waiting_on": ("v_waiting_on", {"person": "waits_on", "kind": "kind"}, "waits_on, opened_at, id"),
    "inbox": ("v_inbox", {"session": "session", "kind": "kind"}, "session, unaccepted DESC, opened_at, id"),
    "stale": ("v_stale", {"session": "owner_session", "kind": "kind"}, "id, flag"),
    "dup_refs": ("v_dup_refs", {}, "kind, ref"),
    "week": ("v_week", {"kind": "kind"}, "week, kind"),
    "retention_due": ("v_retention_due", {"kind": "kind", "week_start": None}, "would, id"),
}


class Bad(Exception):
    """Bad input or a refused rule: exit 1."""


def die(code, msg):
    print("hubflow: ERROR: " + msg, file=sys.stderr)
    sys.exit(code)


# ---- clock, paths, connections ----

def clock():
    v = os.environ.get("HUBFLOW_NOW")
    if not v:
        return datetime.datetime.now(datetime.timezone.utc).strftime(TS_FMT)
    return parse_ts(v, "HUBFLOW_NOW")


def parse_ts(v, what):
    if not isinstance(v, str) or not TS.match(v):
        raise Bad(f"{what} {v!r} is not YYYY-MM-DDTHH:MM:SSZ")
    try:
        datetime.datetime.strptime(v, TS_FMT)
    except ValueError:
        raise Bad(f"{what} {v!r} is not a real time")
    return v


def parse_date(v, what):
    if not isinstance(v, str) or not DATE.match(v):
        raise Bad(f"{what} {v!r} is not YYYY-MM-DD")
    try:
        return datetime.date.fromisoformat(v).isoformat()
    except ValueError:
        raise Bad(f"{what} {v!r} is not a real date")


def ts_add(ts, seconds):
    t = datetime.datetime.strptime(ts, TS_FMT).replace(tzinfo=datetime.timezone.utc).timestamp() + seconds
    return datetime.datetime.fromtimestamp(t, datetime.timezone.utc).strftime(TS_FMT)


def idle_days(now, then):
    a, b = datetime.datetime.strptime(now, TS_FMT), datetime.datetime.strptime(then, TS_FMT)
    return int((a - b).total_seconds() // 86400)


def default_hub():
    """HUBFLOW_HUB, else the git toplevel of the current directory, else the current directory."""
    env = os.environ.get("HUBFLOW_HUB")
    if env:
        return env
    try:
        p = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, timeout=10)
        if p.returncode == 0 and p.stdout.strip():
            return p.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    return os.getcwd()


def hub_dir(g):
    return g.get("hub") or default_hub()


def flow_dir(g):
    return os.environ.get("HUBFLOW_DB_DIR") or os.path.join(hub_dir(g), "flow")


def db_path(d):
    return os.path.join(d, "flow.db")


def jsonl_dir(d):
    return os.path.join(d, "jsonl")


def check_version(c):
    v = c.execute("PRAGMA user_version").fetchone()[0]
    if v > SCHEMA_VERSION:
        c.close()
        die(2, f"the db has schema {v}, newer than this script's schema {SCHEMA_VERSION}; nothing was written")
    if v < SCHEMA_VERSION:
        c.close()
        die(2, f"the db has schema {v}, older than this script's schema {SCHEMA_VERSION}; run `hubflow.py migrate`")


def setup(c):
    c.row_factory = sqlite3.Row
    c.execute("PRAGMA foreign_keys=ON")
    c.execute("PRAGMA busy_timeout=30000")


def connect_rw(d):
    p = db_path(d)
    if not os.path.exists(p):
        die(2, f"no db at {p}; run init or rebuild")
    c = sqlite3.connect(p, timeout=30, isolation_level=None)
    setup(c)
    c.execute("PRAGMA journal_mode=WAL")
    check_version(c)
    return c


def connect_ro(d, overrides=None):
    """Read connection; never creates or migrates. With HUBFLOW_NOW or overrides, a private in-memory
    copy carries the overridden meta rows, so the db file is never written by a read."""
    p = db_path(d)
    if not os.path.exists(p):
        die(2, f"no db at {p}; run init or rebuild")
    c = sqlite3.connect("file:" + quote(p) + "?mode=ro", uri=True, timeout=30, isolation_level=None)
    setup(c)
    check_version(c)
    over = dict(overrides or {})
    if os.environ.get("HUBFLOW_NOW"):
        over.setdefault("now", clock())
    if not over:
        return c
    m = sqlite3.connect(":memory:", isolation_level=None)
    c.backup(m)
    c.close()
    setup(m)
    for k, v in over.items():
        m.execute("INSERT OR REPLACE INTO meta(key, value) VALUES(?, ?)", (k, v))
    return m


# ---- JSONL ----

def table_rows(c, t):
    return [dict(zip(r.keys(), tuple(r))) for r in c.execute(f"SELECT * FROM {t} ORDER BY {ORDER[t]}")]


def export_all(c, d):
    """Write one sorted JSONL file per table. Called inside the write transaction."""
    jd = jsonl_dir(d)
    os.makedirs(jd, exist_ok=True)
    for t in TABLES:
        tmp = os.path.join(jd, t + ".jsonl.tmp")
        with open(tmp, "w", encoding="utf-8", newline="\n") as f:
            for row in table_rows(c, t):
                f.write(json.dumps(row, sort_keys=True, ensure_ascii=False) + "\n")
        os.replace(tmp, os.path.join(jd, t + ".jsonl"))


def read_jsonl(path):
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as f:
        try:
            return [json.loads(x) for x in f if x.strip()]
        except json.JSONDecodeError as e:
            die(3, f"{path} is not valid JSONL: {e}")


def differences(c, d):
    out = []
    for t in TABLES:
        disk = read_jsonl(os.path.join(jsonl_dir(d), t + ".jsonl"))
        if disk is None:
            out.append(f"{t}.jsonl is missing")
            continue
        rows = table_rows(c, t)
        if disk != rows:
            key = lambda xs: {json.dumps(x, sort_keys=True) for x in xs}
            out.append(f"{t}.jsonl differs from the db: {len(key(disk) - key(rows))} row(s) only in the JSONL, "
                       f"{len(key(rows) - key(disk))} only in the db")
    return out


# ---- writes ----

class W:
    """What a write transaction knows: the clock, the writer, and how to record an event."""

    def __init__(self, c, now, session, by, note):
        self.c, self.now, self.session, self.by, self.note = c, now, session, by, note

    def event(self, item_id, verb, old=None, new=None, note="__cmd__", by=None):
        self.c.execute("INSERT INTO event(at, item_id, verb, old, new, by_session, by, note) VALUES(?,?,?,?,?,?,?,?)",
                       (self.now, item_id, verb, old, new, self.session, by or self.by,
                        self.note if note == "__cmd__" else note))


def writer_name(o, g):
    name = o.get("session") or g.get("session") or os.environ.get("HUB_SESSION")
    if not name:  # session check
        raise Bad("a write needs a session: set HUB_SESSION or pass --session S")
    return name


def writer_by(o, g):
    by = o.get("by") or g.get("by") or "agent"
    if by not in BY:
        raise Bad(f"--by {by!r} is not one of {', '.join(BY)}")
    if by == "human" and not o.get("note"):
        raise Bad("--by human records a person's own words: pass --note with the quote")
    return by


def run_write(g, o, fn, session=True, bootstrap=None):
    """Run fn(c, w) in one immediate transaction with its events and the JSONL export, then commit.
    bootstrap: a session name the writer may use while the session table is empty (the first
    `session add`)."""
    by = writer_by(o, g)
    name = writer_name(o, g) if session else None
    now = clock()
    d = flow_dir(g)
    c = connect_rw(d)
    try:
        c.execute("BEGIN IMMEDIATE")
        if os.environ.get("HUBFLOW_NOW"):
            c.execute("INSERT OR REPLACE INTO meta(key, value) VALUES('now', ?)", (now,))
        else:
            c.execute("DELETE FROM meta WHERE key = 'now'")
        if name and bootstrap and name == bootstrap and c.execute("SELECT COUNT(*) FROM session").fetchone()[0] == 0:
            who = name  # the first session, about to be added by fn
        else:
            who = resolve_session(c, name) if name else None
        w = W(c, now, who, by, o.get("note"))
        result = fn(c, w)
        export_all(c, d)  # in the write transaction
        c.execute("COMMIT")
        return result
    except BaseException:
        if c.in_transaction:
            c.execute("ROLLBACK")
        raise
    finally:
        c.close()


# ---- validation ----

def check_title(t):
    if not isinstance(t, str) or not 3 <= len(t) <= 200:
        raise Bad("the title must be 3 to 200 characters")
    return t


def check_analysis(v):
    if not isinstance(v, str):
        raise Bad("the analysis must be a slug")
    if W_SLOT.match(v):  # W-slot check
        raise Bad(f"analysis {v!r} is a W-slot path; give the analysis slug only")
    if not SLUG.match(v):
        raise Bad(f"analysis {v!r} is not a slug (letters, digits, . _ -)")
    return v


def parse_ref(s):
    kind, sep, ref = str(s).partition(":")
    if not sep or kind not in REF_KINDS or not ref.strip():
        raise Bad(f"ref {s!r} is not KIND:REF with KIND one of {', '.join(REF_KINDS)}")
    ref = ref.strip()
    if kind in ("issue", "pr"):
        if not re.fullmatch(r"\d+", ref):  # digits check
            raise Bad(f"{kind} ref {ref!r} must be digits only (42, not #42)")
    elif kind in ("kb", "file"):
        if W_SLOT.match(ref):
            raise Bad(f"{kind} ref {ref!r} is a W-slot path; give a path relative to the analysis (<slug>/...)")
        if ref.startswith("/") or ".." in ref.split("/"):
            raise Bad(f"{kind} ref {ref!r} must be a relative path inside an analysis")
    elif kind == "commit":
        if not re.fullmatch(r"[0-9a-f]{7,40}", ref):
            raise Bad(f"commit ref {ref!r} must be 7 to 40 hex digits")
    elif kind == "url":
        if not re.match(r"^https?://\S+$", ref):
            raise Bad(f"url ref {ref!r} must start with http:// or https://")
    return kind, ref


def resolve_session(c, name):
    """The current name for a session name or an alias."""
    r = c.execute("SELECT name FROM session WHERE name = ?", (name,)).fetchone()
    if r is None:
        r = c.execute("SELECT name FROM session_alias WHERE alias = ?", (name,)).fetchone()
    if r is None:
        raise Bad(f"unknown session {name!r}")
    return r[0]


def resolve_active(c, name):
    cur = resolve_session(c, name)
    if c.execute("SELECT status FROM session WHERE name = ?", (cur,)).fetchone()[0] != "active":
        raise Bad(f"session {cur!r} is retired")
    return cur


def check_person(c, p):
    if c.execute("SELECT 1 FROM person WHERE key = ?", (p,)).fetchone() is None:
        raise Bad(f"unknown person {p!r}")
    return p


def get_item(c, iid):
    r = c.execute("SELECT * FROM item WHERE id = ?", (iid,)).fetchone()
    if r is None:
        raise Bad(f"no item {iid}")
    return r


def need_open(it):
    if it["status"] not in OPEN:
        raise Bad(f"{it['id']} is {it['status']}; reopen it first")


# ---- argument parsing ----

def parse(args, spec):
    """spec: option -> one | many | flag. Returns (positional, options keyed without dashes)."""
    pos, o, i = [], {}, 0
    while i < len(args):
        a = args[i]
        if a.startswith("--") and len(a) > 2:
            if a not in spec:
                raise Bad(f"unknown option {a}")
            name = a[2:].replace("-", "_")
            if spec[a] == "flag":
                o[name] = True
            else:
                if i + 1 >= len(args):
                    raise Bad(f"{a} needs a value")
                i += 1
                if spec[a] == "many":
                    o.setdefault(name, []).append(args[i])
                else:
                    o[name] = args[i]
        else:
            pos.append(a)
        i += 1
    return pos, o


WOPT = {"--session": "one", "--by": "one", "--note": "one"}


def usage(msg):
    raise Bad("usage: " + msg)


# ---- rendering ----

def cell(v):
    return "" if v is None else str(v).replace("|", "\\|").replace("\n", " ")


def render(rows, cols, fmt):
    if fmt == "json":
        return json.dumps([dict(zip(cols, r)) for r in rows], indent=1, ensure_ascii=False)
    if fmt == "tsv":
        lines = ["\t".join(cols)]
        lines += ["\t".join("" if v is None else str(v).replace("\t", " ").replace("\n", " ") for v in r) for r in rows]
        return "\n".join(lines)
    lines = ["| " + " | ".join(cols) + " |", "|" + "|".join("---" for _ in cols) + "|"]
    lines += ["| " + " | ".join(cell(v) for v in r) + " |" for r in rows]
    return "\n".join(lines)


def fmt_of(o, allowed=("md", "json", "tsv")):
    f = o.get("format", "md")
    if f not in allowed:
        raise Bad(f"--format is one of {', '.join(allowed)}")
    return f


def select_rows(c, sql, params=()):
    cur = c.execute(sql, params)
    cols = [x[0] for x in cur.description]
    return cols, [tuple(r) for r in cur.fetchall()]


# ---- item creation shared by add, handoff and import ----

def new_item(c, kind, title, status, owner, waits_on, analysis, opened_at, renewed_at=None,
             parked_until=None, closed_at=None, close_reason=None):
    key = "next_" + PREFIX[kind]
    n = int(c.execute("SELECT value FROM meta WHERE key = ?", (key,)).fetchone()[0])
    iid = f"{PREFIX[kind]}-{n:04d}"
    c.execute("UPDATE meta SET value = ? WHERE key = ?", (str(n + 1), key))
    c.execute("INSERT INTO item(id, kind, title, status, owner_session, waits_on, analysis, opened_at, renewed_at,"
              " parked_until, closed_at, close_reason) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)",
              (iid, kind, title, status, owner, waits_on, analysis, opened_at, renewed_at or opened_at,
               parked_until, closed_at, close_reason))
    return iid


def add_refs(c, iid, refs):
    for kind, ref in refs:
        c.execute("INSERT OR IGNORE INTO item_ref(item_id, kind, ref) VALUES(?,?,?)", (iid, kind, ref))


# ---- commands ----

def seed_path(o, d):
    """--seed FILE, else seed.json in the flow dir if present, else None (seed nothing)."""
    if o.get("seed"):
        return o["seed"]
    p = os.path.join(d, "seed.json")
    return p if os.path.exists(p) else None


def load_seed(path):
    """Read and validate a seed file. Returns {"sessions": [(name, role)], "aliases": [...], "persons": [...]}."""
    out = {k: [] for k in SEED_KEYS}
    if path is None:
        return out
    try:
        with open(path, encoding="utf-8") as f:
            obj = json.load(f)
    except OSError as e:
        raise Bad(f"cannot read seed {path}: {e}")
    except ValueError as e:
        raise Bad(f"seed {path} is not valid JSON: {e}")
    if not isinstance(obj, dict):
        raise Bad(f"seed {path} must be a JSON object with sessions, aliases and persons")
    extra = sorted(set(obj) - set(SEED_KEYS))
    if extra:
        raise Bad(f"seed {path} has unknown key(s): {', '.join(extra)}")
    for key, fields in SEED_KEYS.items():
        rows = obj.get(key, [])
        if not isinstance(rows, list):
            raise Bad(f"seed {key} must be a list")
        for n, row in enumerate(rows):
            if not isinstance(row, dict) or set(row) != set(fields):
                raise Bad(f"seed {key}[{n}] must be an object with exactly {', '.join(fields)}")
            if not all(isinstance(row[f], str) and row[f].strip() for f in fields):
                raise Bad(f"seed {key}[{n}]: {', '.join(fields)} must be non-empty strings")
            out[key].append(tuple(row[f] for f in fields))
    names = [n for n, _ in out["sessions"]]
    aliases = [a for a, _ in out["aliases"]]
    for n in names + aliases:
        if not SESSION_NAME.match(n):
            raise Bad(f"seed session or alias {n!r} must be lowercase letters, digits and dashes")
    if len(set(names + aliases)) != len(names) + len(aliases):
        raise Bad("seed session names and aliases must all be different")
    for a, n in out["aliases"]:
        if n not in names:
            raise Bad(f"seed alias {a!r} names {n!r}, which is not a seeded session")
    keys = [k for k, _ in out["persons"]]
    if len(set(keys)) != len(keys):
        raise Bad("seed person keys must all be different")
    return out


def cmd_init(g, a):
    _, o = parse(a, {"--seed": "one"})
    d = flow_dir(g)
    if os.path.exists(db_path(d)):
        die(2, f"{db_path(d)} already exists")
    seed = load_seed(seed_path(o, d))  # seed file read
    os.makedirs(d, exist_ok=True)
    now = clock()
    c = sqlite3.connect(db_path(d), timeout=30, isolation_level=None)
    setup(c)
    try:
        c.execute("PRAGMA journal_mode=WAL")
        c.execute("BEGIN IMMEDIATE")
        for stmt in DDL:
            c.execute(stmt)
        today = now[:10]
        for k in ("next_A", "next_T", "next_K", "next_H"):
            c.execute("INSERT INTO meta(key, value) VALUES(?, '1')", (k,))
        if os.environ.get("HUBFLOW_NOW"):
            c.execute("INSERT INTO meta(key, value) VALUES('now', ?)", (now,))
        for name, role in seed["sessions"]:
            c.execute("INSERT INTO session(name, role, status, started_on) VALUES(?, ?, 'active', ?)", (name, role, today))
        for alias, name in seed["aliases"]:
            c.execute("INSERT INTO session_alias(alias, name, since) VALUES(?, ?, ?)", (alias, name, today))
        for key, display in seed["persons"]:
            c.execute("INSERT INTO person(key, display) VALUES(?, ?)", (key, display))
        c.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
        export_all(c, d)
        c.execute("COMMIT")
    except BaseException:
        if c.in_transaction:
            c.execute("ROLLBACK")
        c.close()
        for s in ("", "-wal", "-shm"):
            if os.path.exists(db_path(d) + s):
                os.remove(db_path(d) + s)
        raise
    c.close()


def common_item_opts(o):
    refs = [parse_ref(x) for x in o.get("ref", [])]
    if o.get("title") is not None:
        check_title(o["title"])
    if o.get("analysis") is not None:
        check_analysis(o["analysis"])
    return refs


def cmd_add(g, a):
    pos, o = parse(a, {**WOPT, "--title": "one", "--owner": "one", "--waits-on": "one", "--analysis": "one",
                       "--ref": "many", "--status": "one"})
    if len(pos) != 1:
        usage("add ask|thread|hold --title T [--owner S] [--waits-on P] [--analysis SLUG] [--ref KIND:REF ...]")
    kind = pos[0]
    if kind == "handoff":
        raise Bad("a handoff is made with the handoff command")
    if kind not in ADDABLE:
        raise Bad(f"kind {kind!r} is not one of {', '.join(ADDABLE)}")
    if o.get("title") is None:
        raise Bad("add needs --title")
    status = o.get("status", "open")
    if status not in OPEN:
        raise Bad("--status is open or waiting (close with the close command)")
    refs = common_item_opts(o)

    def fn(c, w):
        if o.get("owner") == "none":
            owner = None
        else:  # owner defaults to the writer
            owner = resolve_active(c, o.get("owner") or w.session)
        waits = check_person(c, o["waits_on"]) if o.get("waits_on") else None
        iid = new_item(c, kind, o["title"], status, owner, waits, o.get("analysis"), w.now)
        add_refs(c, iid, refs)
        w.event(iid, "opened", None, status)
        return iid

    print(run_write(g, o, fn))


def cmd_handoff(g, a):
    pos, o = parse(a, {**WOPT, "--to": "one", "--title": "one", "--gate": "one", "--analysis": "one", "--ref": "many"})
    if pos or not o.get("to") or o.get("title") is None:
        usage("handoff --to S --title T [--gate G] [--analysis SLUG] [--ref KIND:REF ...] [--note N]")
    refs = common_item_opts(o)

    def fn(c, w):
        frm = w.session
        to = resolve_active(c, o["to"])
        if frm == to:
            raise Bad("a handoff goes to another session")
        owner_session = to  # handoff owner is the to_session
        iid = new_item(c, "handoff", o["title"], "open", owner_session, None, o.get("analysis"), w.now)
        c.execute("INSERT INTO handoff(item_id, from_session, to_session, gate) VALUES(?,?,?,?)",
                  (iid, frm, to, o.get("gate")))
        add_refs(c, iid, refs)
        w.event(iid, "opened", None, "open")
        return iid

    print(run_write(g, o, fn))


def cmd_accept(g, a):
    pos, o = parse(a, WOPT)
    if len(pos) != 1:
        usage("accept ID")

    def fn(c, w):
        it = get_item(c, pos[0])
        h = c.execute("SELECT * FROM handoff WHERE item_id = ?", (it["id"],)).fetchone()
        if h is None:
            raise Bad(f"{it['id']} is not a handoff")
        me, to_session = w.session, h["to_session"]
        if me != to_session:  # only the to_session accepts
            raise Bad(f"{it['id']} goes to {to_session}; {me} cannot accept it")
        if h["accepted_at"] is not None:
            raise Bad(f"{it['id']} was already accepted at {h['accepted_at']}")
        need_open(it)
        c.execute("UPDATE handoff SET accepted_at = ? WHERE item_id = ?", (w.now, it["id"]))
        w.event(it["id"], "accepted", None, w.now)

    run_write(g, o, fn)


def cmd_renew(g, a):
    pos, o = parse(a, WOPT)
    if len(pos) != 1:
        usage("renew ID [--note N]")

    def fn(c, w):
        it = get_item(c, pos[0])
        need_open(it)
        c.execute("UPDATE item SET renewed_at = ? WHERE id = ?", (w.now, it["id"]))
        w.event(it["id"], "renewed", it["renewed_at"], w.now)

    run_write(g, o, fn)


def cmd_park(g, a):
    pos, o = parse(a, {**WOPT, "--until": "one"})
    if len(pos) != 1 or not o.get("until"):
        usage("park ID --until YYYY-MM-DD [--note N]")
    until = parse_date(o["until"], "--until")

    def fn(c, w):
        it = get_item(c, pos[0])
        need_open(it)
        if until < w.now[:10]:
            raise Bad(f"--until {until} is before today ({w.now[:10]})")
        c.execute("UPDATE item SET parked_until = ? WHERE id = ?", (until, it["id"]))
        w.event(it["id"], "parked", it["parked_until"], until)

    run_write(g, o, fn)


def cmd_set(g, a):
    pos, o = parse(a, {**WOPT, "--title": "one", "--owner": "one", "--waits-on": "one", "--status": "one",
                       "--analysis": "one"})
    if len(pos) != 1:
        usage("set ID [--title T] [--owner S] [--waits-on P|none] [--status open|waiting] [--analysis SLUG|none]")
    if not any(k in o for k in ("title", "owner", "waits_on", "status", "analysis")):
        raise Bad("set needs at least one of --title --owner --waits-on --status --analysis")
    if "title" in o:
        check_title(o["title"])
    if "status" in o and o["status"] not in OPEN:
        raise Bad("--status is open or waiting (close with the close command)")
    if o.get("analysis") not in (None, "none"):
        check_analysis(o["analysis"])

    def fn(c, w):
        it = get_item(c, pos[0])
        iid = it["id"]
        if "title" in o and o["title"] != it["title"]:
            c.execute("UPDATE item SET title = ? WHERE id = ?", (o["title"], iid))
            w.event(iid, "title", it["title"], o["title"])
        if "owner" in o:
            if it["kind"] == "handoff":
                raise Bad("a handoff's owner is its to-session; it does not change")
            new = resolve_active(c, o["owner"])
            if new != it["owner_session"]:
                c.execute("UPDATE item SET owner_session = ? WHERE id = ?", (new, iid))
                w.event(iid, "owner", it["owner_session"], new)
        if "waits_on" in o:
            new = None if o["waits_on"] == "none" else check_person(c, o["waits_on"])
            if new != it["waits_on"]:
                c.execute("UPDATE item SET waits_on = ? WHERE id = ?", (new, iid))
                w.event(iid, "waits_on", it["waits_on"], new)
        if "status" in o:
            need_open(it)
            if o["status"] != it["status"]:
                c.execute("UPDATE item SET status = ? WHERE id = ?", (o["status"], iid))
                w.event(iid, "status", it["status"], o["status"])
        if "analysis" in o:
            new = None if o["analysis"] == "none" else o["analysis"]
            if new != it["analysis"]:
                c.execute("UPDATE item SET analysis = ? WHERE id = ?", (new, iid))
                w.event(iid, "analysis", it["analysis"], new)

    run_write(g, o, fn)


def cmd_close(g, a):
    pos, o = parse(a, {**WOPT, "--reason": "one"})
    if len(pos) != 1 or o.get("reason") not in ("done", "dropped"):
        usage("close ID --reason done|dropped [--note N]")

    def fn(c, w):
        it = get_item(c, pos[0])
        need_open(it)
        c.execute("UPDATE item SET status = ?, closed_at = ?, close_reason = ? WHERE id = ?",
                  (o["reason"], w.now, o["reason"], it["id"]))
        w.event(it["id"], "closed", it["status"], o["reason"])

    run_write(g, o, fn)


def cmd_reopen(g, a):
    pos, o = parse(a, WOPT)
    if len(pos) != 1:
        usage("reopen ID [--note N]")

    def fn(c, w):
        it = get_item(c, pos[0])
        if it["status"] in OPEN:
            raise Bad(f"{it['id']} is already {it['status']}")
        c.execute("UPDATE item SET status = 'open', closed_at = NULL, close_reason = NULL, renewed_at = ?,"
                  " parked_until = NULL WHERE id = ?", (w.now, it["id"]))
        w.event(it["id"], "reopened", it["status"], "open")

    run_write(g, o, fn)


def cmd_ref(g, a):
    pos, o = parse(a, WOPT)
    if len(pos) != 3 or pos[1] not in ("add", "rm"):
        usage("ref ID add|rm KIND:REF")
    kind, ref = parse_ref(pos[2])

    def fn(c, w):
        it = get_item(c, pos[0])
        if pos[1] == "add":
            n = c.execute("INSERT OR IGNORE INTO item_ref(item_id, kind, ref) VALUES(?,?,?)", (it["id"], kind, ref)).rowcount
            if n:
                w.event(it["id"], "ref_add", None, f"{kind}:{ref}")
        else:
            n = c.execute("DELETE FROM item_ref WHERE item_id = ? AND kind = ? AND ref = ?", (it["id"], kind, ref)).rowcount
            if not n:
                raise Bad(f"{it['id']} has no ref {kind}:{ref}")
            w.event(it["id"], "ref_rm", f"{kind}:{ref}", None)

    run_write(g, o, fn)


def cmd_link(g, a):
    pos, o = parse(a, WOPT)
    if len(pos) != 3:
        usage("link FROM TO KIND")
    frm, to, kind = pos
    if kind not in LINK_KINDS:
        raise Bad(f"link kind {kind!r} is not one of {', '.join(LINK_KINDS)}")
    if frm == to:
        raise Bad("an item cannot link to itself")

    def fn(c, w):
        get_item(c, frm)
        get_item(c, to)
        n = c.execute("INSERT OR IGNORE INTO item_link(from_id, to_id, kind) VALUES(?,?,?)", (frm, to, kind)).rowcount
        if n:
            w.event(frm, "link", None, f"{kind} {to}")

    run_write(g, o, fn)


def cmd_note(g, a):
    pos, o = parse(a, {"--session": "one", "--by": "one"})
    if len(pos) < 2:
        usage("note ID TEXT")
    text = " ".join(pos[1:])

    def fn(c, w):
        it = get_item(c, pos[0])
        w.event(it["id"], "note", None, None, note=text)

    run_write(g, o, fn)


def cmd_show(g, a):
    pos, o = parse(a, {"--format": "one"})
    fmt = fmt_of(o, ("md", "json"))
    if len(pos) != 1:
        usage("show ID [--format md|json]")
    c = connect_ro(flow_dir(g))
    it = get_item(c, pos[0])
    iid = it["id"]
    d = {
        "item": dict(it),
        "refs": [dict(r) for r in c.execute("SELECT kind, ref FROM item_ref WHERE item_id = ? ORDER BY kind, ref", (iid,))],
        "links": [dict(r) for r in c.execute("SELECT from_id, to_id, kind FROM item_link WHERE from_id = ? OR to_id = ?"
                                              " ORDER BY from_id, to_id, kind", (iid, iid))],
        "handoff": None,
        "events": [dict(r) for r in c.execute("SELECT * FROM event WHERE item_id = ? ORDER BY seq", (iid,))],
    }
    h = c.execute("SELECT * FROM handoff WHERE item_id = ?", (iid,)).fetchone()
    if h is not None:
        d["handoff"] = dict(h)
    c.close()
    if fmt == "json":
        print(json.dumps(d, indent=1, ensure_ascii=False))
        return
    for k, v in d["item"].items():
        print(f"{k}: {'' if v is None else v}")
    if d["handoff"]:
        print("handoff: " + ", ".join(f"{k}={'' if v is None else v}" for k, v in d["handoff"].items() if k != "item_id"))
    print("refs: " + " ".join(f"{r['kind']}:{r['ref']}" for r in d["refs"]))
    for l in d["links"]:
        print(f"link: {l['from_id']} {l['kind']} {l['to_id']}")
    print()
    cols = ("seq", "at", "verb", "old", "new", "by_session", "by", "note")
    print(render([[e[k] for k in cols] for e in d["events"]], cols, "md"))


def cmd_view(g, a):
    pos, o = parse(a, {"--session": "one", "--person": "one", "--kind": "one", "--week-start": "one", "--format": "one"})
    fmt = fmt_of(o)
    if len(pos) != 1:
        usage("view NAME [--session S] [--person P] [--kind K] [--format md|json|tsv]")
    name = pos[0][2:] if pos[0].startswith("v_") else pos[0]
    if name not in VIEW_DEFS:
        raise Bad(f"view {pos[0]!r} is not one of {', '.join(VIEW_DEFS)}")
    view, filters, order = VIEW_DEFS[name]
    for k in ("session", "person", "kind", "week_start"):
        if k in o and k not in filters:
            raise Bad(f"view {name} does not take --{k.replace('_', '-')}")
    over = {}
    if "week_start" in o:
        over["rotate_week_start"] = parse_date(o["week_start"], "--week-start")
    c = connect_ro(flow_dir(g), over)
    where, params = [], []
    if "session" in o:
        where.append(f"{filters['session']} = ?")
        params.append(resolve_session(c, o["session"]))
    if "person" in o:
        where.append(f"{filters['person']} = ?")
        params.append(check_person(c, o["person"]))
    if "kind" in o:
        where.append(f"{filters['kind']} = ?")
        params.append(o["kind"])
    sql = f"SELECT * FROM {view}" + (" WHERE " + " AND ".join(where) if where else "") + f" ORDER BY {order}"
    cols, rows = select_rows(c, sql, params)
    c.close()
    print(render(rows, cols, fmt))


def sql_auth(action, a1, a2, dbname, source):
    allowed = (sqlite3.SQLITE_SELECT, sqlite3.SQLITE_READ, sqlite3.SQLITE_FUNCTION,
               getattr(sqlite3, "SQLITE_RECURSIVE", 33))
    return sqlite3.SQLITE_OK if action in allowed else sqlite3.SQLITE_DENY


def cmd_sql(g, a):
    pos, o = parse(a, {"--format": "one"})
    fmt = fmt_of(o)
    if len(pos) != 1:
        usage('sql "SELECT ..." [--format md|json|tsv]')
    text = pos[0]
    if not SQL_OK.match(text):  # read-only guard
        raise Bad("sql takes one SELECT or WITH statement")
    c = connect_ro(flow_dir(g))
    c.execute("PRAGMA query_only=ON")
    c.set_authorizer(sql_auth)
    try:
        cols, rows = select_rows(c, text)
    except (sqlite3.Error, sqlite3.Warning) as e:
        raise Bad(f"sql refused or failed: {e}")
    finally:
        c.close()
    print(render(rows, cols, fmt))


def cmd_session(g, a):
    pos, o = parse(a, {**WOPT, "--role": "one"})
    if not pos or pos[0] not in ("add", "rename", "retire"):
        usage("session add NAME --role R | rename OLD NEW | retire NAME")
    verb = pos[0]
    if (verb == "rename" and len(pos) != 3) or (verb != "rename" and len(pos) != 2):
        usage("session add NAME --role R | rename OLD NEW | retire NAME")
    if verb in ("add", "rename"):
        new = pos[1] if verb == "add" else pos[2]
        if not SESSION_NAME.match(new):
            raise Bad(f"session name {new!r} must be lowercase letters, digits and dashes")
    if verb == "add" and not o.get("role"):
        raise Bad("session add needs --role")

    def fn(c, w):
        today = w.now[:10]
        if verb == "add":
            if c.execute("SELECT 1 FROM session WHERE name = ?", (new,)).fetchone() or \
               c.execute("SELECT 1 FROM session_alias WHERE alias = ?", (new,)).fetchone():
                raise Bad(f"{new!r} is already a session name or an alias")
            c.execute("INSERT INTO session(name, role, status, started_on) VALUES(?,?, 'active', ?)", (new, o["role"], today))
            w.event(None, "session_add", None, new)
        elif verb == "rename":
            cur = resolve_session(c, pos[1])
            if c.execute("SELECT 1 FROM session WHERE name = ?", (new,)).fetchone():
                raise Bad(f"session {new!r} already exists")
            al = c.execute("SELECT name FROM session_alias WHERE alias = ?", (new,)).fetchone()
            if al is not None:
                if al[0] != cur:
                    raise Bad(f"{new!r} is an alias of another session")
                c.execute("DELETE FROM session_alias WHERE alias = ?", (new,))
            c.execute("PRAGMA defer_foreign_keys=ON")
            c.execute("UPDATE session SET name = ? WHERE name = ?", (new, cur))
            c.execute("UPDATE item SET owner_session = ? WHERE owner_session = ?", (new, cur))
            c.execute("UPDATE handoff SET from_session = ? WHERE from_session = ?", (new, cur))
            c.execute("UPDATE handoff SET to_session = ? WHERE to_session = ?", (new, cur))
            c.execute("UPDATE session_alias SET name = ? WHERE name = ?", (new, cur))
            c.execute("INSERT INTO session_alias(alias, name, since) VALUES(?,?,?)", (cur, new, today))
            w.event(None, "session_rename", cur, new)
        else:
            cur = resolve_session(c, pos[1])
            if c.execute("SELECT status FROM session WHERE name = ?", (cur,)).fetchone()[0] != "active":
                raise Bad(f"session {cur!r} is already retired")
            owned = [r[0] for r in c.execute("SELECT id FROM item WHERE owner_session = ? AND status IN ('open','waiting') ORDER BY id", (cur,))]
            c.execute("UPDATE session SET status = 'retired', retired_on = ? WHERE name = ?", (today, cur))
            w.event(None, "session_retire", cur, None)
            if owned:
                print(f"hubflow: warning: {cur} still owns open items: {' '.join(owned)}", file=sys.stderr)

    run_write(g, o, fn, bootstrap=new if verb == "add" else None)


def cmd_where(g, a):
    pos, o = parse(a, {})
    if len(pos) != 1:
        usage("where SLUG")
    slug = check_analysis(pos[0])
    hub = hub_dir(g)
    for n in range(6):
        if os.path.isdir(os.path.join(hub, f"W{n}", "analyses", slug)):
            print(f"W{n}/analyses/{slug}")
            return
    raise Bad(f"no analysis {slug!r} in W0 to W5")


# ---- import ----

IMPORT_KEYS = {"kind", "title", "status", "owner", "waits_on", "analysis", "refs", "opened_at", "renewed_at",
               "parked_until", "closed_at", "close_reason", "note", "from", "to", "gate", "accepted_at"}


def validate_row(c, obj):
    if not isinstance(obj, dict):
        raise Bad("the row is not a JSON object")
    extra = sorted(set(obj) - IMPORT_KEYS)
    if extra:
        raise Bad("unknown field " + ", ".join(extra))
    kind = obj.get("kind")
    if kind not in ITEM_KINDS:
        raise Bad(f"kind {kind!r} is not one of {', '.join(ITEM_KINDS)}")
    check_title(obj.get("title"))
    status = obj.get("status", "open")
    if status not in STATUSES:
        raise Bad(f"status {status!r} is not one of {', '.join(STATUSES)}")
    row = {"kind": kind, "title": obj["title"], "status": status, "note": obj.get("note")}
    row["owner"] = resolve_session(c, obj["owner"]) if obj.get("owner") else None
    row["waits_on"] = check_person(c, obj["waits_on"]) if obj.get("waits_on") else None
    row["analysis"] = check_analysis(obj["analysis"]) if obj.get("analysis") else None
    refs = obj.get("refs", [])
    if not isinstance(refs, list):
        raise Bad("refs must be a list of KIND:REF strings")
    row["refs"] = [parse_ref(x) for x in refs]
    row["opened_at"] = parse_ts(obj["opened_at"], "opened_at") if obj.get("opened_at") else None
    row["renewed_at"] = parse_ts(obj["renewed_at"], "renewed_at") if obj.get("renewed_at") else None
    row["parked_until"] = parse_date(obj["parked_until"], "parked_until") if obj.get("parked_until") else None
    row["closed_at"] = parse_ts(obj["closed_at"], "closed_at") if obj.get("closed_at") else None
    row["close_reason"] = obj.get("close_reason")
    closed = status in ("done", "dropped", "lapsed")
    if closed and not row["closed_at"]:
        raise Bad(f"status {status} needs closed_at")
    if not closed and row["closed_at"]:
        raise Bad(f"status {status} cannot have closed_at")
    if closed and not row["close_reason"]:
        row["close_reason"] = status
    if kind == "handoff":
        if not obj.get("from") or not obj.get("to"):
            raise Bad("a handoff needs from and to")
        row["from"], row["to"] = resolve_session(c, obj["from"]), resolve_session(c, obj["to"])
        if row["from"] == row["to"]:
            raise Bad("a handoff goes to another session")
        if row["owner"] not in (None, row["to"]):
            raise Bad("a handoff's owner is its to-session")
        row["owner"] = row["to"]
        row["gate"] = obj.get("gate")
        row["accepted_at"] = parse_ts(obj["accepted_at"], "accepted_at") if obj.get("accepted_at") else None
    elif any(obj.get(k) for k in ("from", "to", "gate", "accepted_at")):
        raise Bad("from, to, gate and accepted_at belong to a handoff")
    return row


def read_import(path):
    try:
        with open(path, encoding="utf-8") as f:
            lines = f.read().splitlines()
    except OSError as e:
        raise Bad(f"cannot read {path}: {e}")
    out = []
    for n, line in enumerate(lines, 1):
        if line.strip():
            try:
                out.append((n, json.loads(line), None))
            except ValueError as e:
                out.append((n, None, f"not valid JSON: {e}"))
    return out


def validate_all(c, parsed):
    rows, rejected = [], []
    for n, obj, err in parsed:
        try:
            if err:
                raise Bad(err)
            rows.append((n, validate_row(c, obj)))
        except Bad as e:
            rejected.append({"line": n, "reason": str(e)})
    return rows, rejected


def cmd_import(g, a):
    pos, o = parse(a, {**WOPT, "--yes": "flag", "--format": "one"})
    fmt = fmt_of(o, ("md", "json"))
    if len(pos) != 1:
        usage("import FILE [--yes] [--format md|json]")
    parsed = read_import(pos[0])
    if not o.get("yes"):
        c = connect_ro(flow_dir(g))
        rows, rejected = validate_all(c, parsed)
        c.close()
        counts = {"kind": {}, "owner": {}, "waits_on": {}}
        for _, r in rows:
            for key, val in (("kind", r["kind"]), ("owner", r["owner"] or "none"), ("waits_on", r["waits_on"] or "none")):
                counts[key][val] = counts[key].get(val, 0) + 1
        if fmt == "json":
            print(json.dumps({"rows": len(rows), "counts": counts, "rejected": rejected}, indent=1, ensure_ascii=False))
        else:
            print(f"dry-run: {len(rows)} row(s) valid, {len(rejected)} rejected; nothing written (add --yes to apply)")
            for key in counts:
                print()
                print(render(sorted(counts[key].items()), (key, "rows"), "md"))
            if rejected:
                print()
                print(render([(x["line"], x["reason"]) for x in rejected], ("line", "reason"), "md"))
        if rejected:
            sys.exit(1)
        return

    def fn(c, w):
        rows, rejected = validate_all(c, parsed)
        if rejected:
            shown = "; ".join(f"line {x['line']}: {x['reason']}" for x in rejected[:5])
            raise Bad(f"import refused, {len(rejected)} row(s) rejected, nothing written: {shown}")
        made = []
        for _, r in rows:
            opened = r["opened_at"] or w.now
            iid = new_item(c, r["kind"], r["title"], r["status"], r["owner"], r["waits_on"], r["analysis"], opened,
                           r["renewed_at"] or opened, r["parked_until"], r["closed_at"], r["close_reason"])
            if r["kind"] == "handoff":
                c.execute("INSERT INTO handoff(item_id, from_session, to_session, gate, accepted_at) VALUES(?,?,?,?,?)",
                          (iid, r["from"], r["to"], r["gate"], r["accepted_at"]))
            add_refs(c, iid, r["refs"])
            w.event(iid, "imported", None, r["status"], note=r["note"])
            made.append(iid)
        return made

    made = run_write(g, o, fn)
    print(f"imported {len(made)}: " + " ".join(made))


# ---- rotate ----

def rotate_plan(c, now, wk):
    lapse_before = ts_add(now, -LAPSE_DAYS * 86400)
    lapse = c.execute("SELECT id, renewed_at FROM item WHERE status IN ('open','waiting') AND renewed_at <= ?"
                      " AND (parked_until IS NULL OR parked_until < ?) ORDER BY id", (lapse_before, now[:10])).fetchall()
    cutoff = ts_add(wk + "T00:00:00Z", -PRUNE_DAYS * 86400)
    prune = [r[0] for r in c.execute("SELECT id FROM item WHERE closed_at IS NOT NULL AND closed_at < ? ORDER BY id", (cutoff,))]
    gone = set(prune)
    used = {r[0] for r in c.execute("SELECT id FROM item")}
    held = set()
    for r in c.execute("SELECT id, owner_session FROM item WHERE owner_session IS NOT NULL"):
        if r[0] not in gone:
            held.add(r[1])
    for r in c.execute("SELECT item_id, from_session, to_session FROM handoff"):
        if r[0] not in gone:
            held.update((r[1], r[2]))
    sessions = [r[0] for r in c.execute("SELECT name FROM session WHERE status = 'retired' AND retired_on < ? ORDER BY name",
                                        (cutoff[:10],)) if r[0] not in held]
    return [(r[0], idle_days(now, r[1])) for r in lapse], prune, sessions


def cmd_rotate(g, a):
    pos, o = parse(a, {**WOPT, "--week-start": "one", "--yes": "flag"})
    if pos or not o.get("week_start"):
        usage("rotate --week-start YYYY-MM-DD [--yes]")
    wk = parse_date(o["week_start"], "--week-start")
    if datetime.date.fromisoformat(wk).weekday() != 0:
        raise Bad(f"--week-start {wk} is not a Monday")

    def report(lapse, prune, sessions):
        print(f"week_start: {wk}")
        print("lapsed: " + (" ".join(i for i, _ in lapse) or "none"))
        print("pruned: " + (" ".join(prune) or "none"))
        print("pruned_sessions: " + (" ".join(sessions) or "none"))

    if not o.get("yes"):
        c = connect_ro(flow_dir(g))
        lapse, prune, sessions = rotate_plan(c, clock(), wk)
        c.close()
        print("dry-run: nothing written (add --yes to apply)")
        report(lapse, prune, sessions)
        return

    def fn(c, w):
        lapse, prune, sessions = rotate_plan(c, w.now, wk)
        for iid, idle in lapse:
            old = c.execute("SELECT status FROM item WHERE id = ?", (iid,)).fetchone()[0]
            c.execute("UPDATE item SET status = 'lapsed', closed_at = ?, close_reason = ? WHERE id = ?",
                      (w.now, f"lapsed: idle {idle} days", iid))
            w.event(iid, "lapsed", old, "lapsed", note=None, by="script")
        for iid in prune:
            c.execute("DELETE FROM item WHERE id = ?", (iid,))
        c.execute("DELETE FROM event WHERE item_id IS NOT NULL AND item_id NOT IN (SELECT id FROM item)")
        for name in sessions:
            c.execute("DELETE FROM session_alias WHERE name = ?", (name,))
            c.execute("DELETE FROM session WHERE name = ?", (name,))
        return lapse, prune, sessions

    report(*run_write(g, o, fn))


# ---- export, rebuild, check ----

def cmd_export(g, a):
    parse(a, {})
    d = flow_dir(g)
    c = connect_rw(d)
    try:
        c.execute("BEGIN IMMEDIATE")
        export_all(c, d)
        c.execute("COMMIT")
    except BaseException:
        if c.in_transaction:
            c.execute("ROLLBACK")
        raise
    finally:
        c.close()


def cmd_rebuild(g, a):
    parse(a, {})
    d = flow_dir(g)
    if os.path.exists(db_path(d)):
        die(2, f"{db_path(d)} exists; rebuild only makes a missing db")
    src = {}
    for t in TABLES:
        src[t] = read_jsonl(os.path.join(jsonl_dir(d), t + ".jsonl"))
        if src[t] is None:
            die(2, f"{t}.jsonl is missing in {jsonl_dir(d)}")
    c = sqlite3.connect(db_path(d), timeout=30, isolation_level=None)
    setup(c)
    try:
        c.execute("PRAGMA journal_mode=WAL")
        c.execute("BEGIN IMMEDIATE")
        for stmt in DDL:
            c.execute(stmt)
        for t in TABLES:
            cols = [r[1] for r in c.execute(f"PRAGMA table_info({t})")]
            for row in src[t]:
                extra = sorted(set(row) - set(cols))
                if extra:  # unknown JSONL columns
                    die(2, f"{t}.jsonl has columns this schema does not know: {', '.join(extra)}; "
                           "rebuild with the script version that wrote it, then migrate")
                c.execute(f"INSERT INTO {t}({', '.join(cols)}) VALUES({', '.join('?' * len(cols))})",
                          tuple(row.get(k) for k in cols))
        c.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
        c.execute("COMMIT")
    except BaseException:
        if c.in_transaction:
            c.execute("ROLLBACK")
        c.close()
        for s in ("", "-wal", "-shm"):
            if os.path.exists(db_path(d) + s):
                os.remove(db_path(d) + s)
        raise
    c.close()


def cmd_migrate(g, a):
    parse(a, {})
    d = flow_dir(g)
    p = db_path(d)
    if not os.path.exists(p):
        die(2, f"no db at {p}; run init or rebuild")
    c = sqlite3.connect(p, timeout=30, isolation_level=None)
    setup(c)
    c.execute("PRAGMA journal_mode=WAL")
    v = c.execute("PRAGMA user_version").fetchone()[0]
    if v == SCHEMA_VERSION:
        c.close()
        print(f"already at schema {v}; nothing to do")
        return
    if v > SCHEMA_VERSION:
        check_version(c)
    if any(s not in MIGRATIONS for s in range(v, SCHEMA_VERSION)):
        c.close()
        die(2, f"the db has schema {v}, and this script has no upgrade step for it; nothing was written")
    start = v
    c.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    bak = f"{p}.bak-v{start}"
    b = sqlite3.connect(bak)
    c.backup(b)
    b.close()
    try:
        c.execute("BEGIN IMMEDIATE")
        while v < SCHEMA_VERSION:
            for stmt in MIGRATIONS[v]:
                c.execute(stmt)
            c.execute(f"PRAGMA user_version = {v + 1}")  # migrate step
            v += 1
        if c.execute("PRAGMA foreign_key_check").fetchall():
            raise Bad("the migrated db has a row that points to a row that does not exist")
        export_all(c, d)
        c.execute("COMMIT")
    except BaseException:
        if c.in_transaction:
            c.execute("ROLLBACK")
        c.close()
        raise
    c.close()
    print(f"migrated schema {start} -> {SCHEMA_VERSION}; backup at {bak}")


def cmd_check(g, a):
    parse(a, {})
    d = flow_dir(g)
    c = connect_rw(d)
    c.execute("BEGIN IMMEDIATE")  # one snapshot with the export
    problems = []
    if c.execute("PRAGMA foreign_key_check").fetchall():
        problems.append("a row points to a row that does not exist")
    problems += differences(c, d)
    c.execute("ROLLBACK")
    c.close()
    if problems:
        die(3, "; ".join(problems))


COMMANDS = {"init": cmd_init, "add": cmd_add, "handoff": cmd_handoff, "accept": cmd_accept, "renew": cmd_renew,
            "park": cmd_park, "set": cmd_set, "close": cmd_close, "reopen": cmd_reopen, "ref": cmd_ref,
            "link": cmd_link, "note": cmd_note, "show": cmd_show, "view": cmd_view, "sql": cmd_sql,
            "session": cmd_session, "where": cmd_where, "import": cmd_import, "rotate": cmd_rotate,
            "export": cmd_export, "rebuild": cmd_rebuild, "check": cmd_check, "migrate": cmd_migrate}


def main():
    a = sys.argv[1:]
    g = {}
    while a and a[0].startswith("-"):
        if a[0] in ("-h", "--help"):
            print(__doc__)
            sys.exit(0)
        if a[0] not in ("--hub", "--session", "--by"):
            die(1, f"unknown option {a[0]}")
        if len(a) < 2:
            die(1, f"{a[0]} needs a value")
        g[a[0][2:]] = a[1]
        a = a[2:]
    if not a or a[0] not in COMMANDS:
        die(1, "command must be one of " + ", ".join(COMMANDS))
    try:
        COMMANDS[a[0]](g, a[1:])
    except Bad as e:
        die(1, str(e))
    except sqlite3.IntegrityError as e:
        die(1, f"refused by the schema: {e}")
    except sqlite3.Error as e:
        die(2, f"database error (locked, missing or damaged): {e}")


if __name__ == "__main__":
    main()

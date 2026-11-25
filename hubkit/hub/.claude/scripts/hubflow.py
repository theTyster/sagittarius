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
          [--status open|waiting] [--reserved WHY] [--due YYYY-MM-DD] [--no-kb] [--note N]
                                               KIND: ask thread hold summary. Prints the new id.
                                               An ask says whether it rests on a KB: give
                                               --ref kb:<slug> (or kb:/abs/path, kb:~/path) for
                                               its KB, or --no-kb when it rests on no KB; with
                                               neither, add ask exits 1
                                               An ask also needs --note N, its context for the Desk:
                                               the case, the options and what each one changes, and
                                               your default; with no note (or a blank one), add ask
                                               exits 1
                                               --reserved (an ask only): an action the person
                                               reserved; WHY names the source in one of two
                                               forms: "NAME Policy: RULE" (a policy by its name
                                               and its rule, for example "Sagittarius Policy:
                                               Only the human may waive a proof.") or
                                               "WHO, YYYY-MM-DD: WORDS" (a person's own words
                                               with their date); other text exits 1
                                               --due (an ask only): the asker's due date
                                               A summary (S-) is what an agent noted from a meeting
                                               it read; it lapses by itself (see Retention)
  handoff --to S --title T [--gate G] [--analysis SLUG] [--ref ...] [--note N]
                                               H- item: from = the writer, owner = S, status open
  accept ID                                    only the to-session may accept; sets accepted_at
  renew ID [--note N]                          renewed_at = now (an open item only)
  park ID --until YYYY-MM-DD [--note N]        not lapsed before that date; on or before the item's
                                               due date when it has one (schema 8)
  set ID [--title T] [--owner S] [--waits-on P|none] [--status open|waiting] [--analysis SLUG|none]
         [--reserved WHY|none] [--due YYYY-MM-DD|none] [--no-kb yes|no]
                                               --no-kb yes is refused while the ask has a kb ref;
                                               `ref ID add kb:...` sets it to no
  close ID --reason done|dropped [--note N]   an agent cannot close, renew, park, set --status
                                               or ref rm the kb ref of an item that is escalated
                                               or whose spec KB blocks (--by human may); nor close,
                                               set --status or ref rm the kb ref of one whose spec
                                               KB is clear only by a live human waiver (it may park
                                               it; an agent's triage lapse of it is escalate)
  close ID --reason human_skip --by human --note QUOTE
                                               a person's skip: also closes the open items linked
                                               to ID by `blocks` (either way), and prints the
                                               waiver command for each blocking item of each
                                               linked spec KB; it never runs one
  skip-waived                                  honor a waiver from the spec KB side: park, until the
                                               waiver's due time (not the end of its day), each open item whose spec
                                               KBs are clear only because a human waived what blocked
                                               (a precaution waiver on a clear KB does not count). It
                                               checks the kb refs again in its write, and never drops
                                               the item: after the due time it is back. The note names
                                               the KB and the waiver; the waiver is the person's word.
                                               It never writes a spec KB. An escalated item stays open,
                                               and is printed (escalated: ID): the human ends it with
                                               triage. `check` names the items it would park.
                                               Run it after the human runs a waiver command
  triage ID keep|lapse|capsule|escalate --note T
                                               one recorded disposition for a due item. keep and
                                               capsule renew it (capsule needs a capsule first),
                                               lapse closes it as lapsed, escalate leaves it open
                                               for the human. An agent's keep, lapse or capsule of
                                               an item whose spec KB blocks becomes escalate
  capsule ID --summary T                       context the tracker lacks (at most 1000 characters),
                                               with the hub's git HEAD and the item's kb and file
                                               refs; `show` prints the newest capsule first
  transcripts --files [--format md|json|tsv]   the files in W0..W5/transcripts/: path, date (the
                                               file's UTC modification day), size, sha256, and the
                                               ref to give an item. Writes nothing. Code never
                                               parses a transcript: an agent reads it and records
                                               what is needed (an item with a transcript ref)
  transcripts --find NAME@sha256:HEX           the path of that file in whichever W slot holds it
                                               now; exit 1 if it is gone or its sha256 changed
  reopen ID [--note N]
  ref ID add|rm KIND:REF                       KIND: issue pr build release kb file commit url goal
                                               transcript
  link FROM TO KIND                            KIND: blocks duplicates relates supersedes follows
  note ID TEXT                                 an event with verb note (--by human: TEXT is the
                                               person's own words)
  show ID [--format md|json]                   the item, refs, links, handoff and events
  view [NAME] [--session S] [--person P] [--kind K] [--week-start D] [--format md|json|tsv]
                                               NAME: open (the default; escalated items first)
                                               escalated waiting_on inbox stale dup_refs week
                                               retention_due (v_ prefix optional)
  sql "SELECT ..." [--format md|json|tsv]      read-only; one SELECT or WITH statement, else exit 1
  session add NAME --role R | rename OLD NEW | retire NAME
                                               with no sessions at all, `session add NAME` by the
                                               writer NAME makes the first session
  where SLUG|/abs/path|~/path                  the hub-relative path of a spec KB slug: specs/<slug>, else
                                               (an old hub) W<n>/analyses/<slug>, newest week first;
                                               for a KB outside the hub, its path with ~ expanded
  spec-triage SLUG archive|capsule|keep|escalate --note T
                                               the one recorded decision for the spec KB of a closed
                                               ticket (specs/<slug>), made at a rotation. archive:
                                               `git rm -r specs/<slug>` first (history keeps it), then
                                               record it. capsule needs a capsule on an item that
                                               refers to the KB. An agent's decision on a KB that
                                               blocks becomes escalate
  import FILE [--yes] [--format md|json]       JSONL of items; a dry run without --yes; all or nothing
  rotate --week-start YYYY-MM-DD [--yes]       prune; a dry run without --yes. Lists the due items
                                               with no disposition (untriaged) and exits 1 until
                                               each has one; `lapsed:` names the summary rows it
                                               lapses. Run --yes after rotate.py
  export                                       rewrite the JSONL from the db
  rebuild                                      make the db from the JSONL (refuses if the db exists)
  check                                        schema, foreign keys, JSONL equal to the db, and
                                               no ask to another person without an issue ref; it
                                               also names the items that skip-waived would park
                                               (skip_waived: IDs; the exit code does not change)
  migrations                                   the hub check of KB migrations (kb-migrations c9,
                                               c10, c12): runs `orbit-kb migrate check` on each spec
                                               KB (specs/ and the old W*/analyses form) whose ticket
                                               is open; exit 1 while one
                                               has a tool or agent step to do (todo:), or when a
                                               check cannot run (unknown:); a human step (migrating:)
                                               and a retired predicate (retired:, a warning) never
                                               fail it. A KB whose items are all closed is frozen:
                                               not checked, not listed
  kb-state SLUG                                open or closed: closed when items refer to kb:SLUG
                                               and each is closed (orbit-kb migrate apply refuses
                                               to write a closed one)
  migrate                                      bring an older db up to this script's schema: copies
                                               the db to flow/flow.db.bak-v<N> first, then runs each
                                               step and rewrites the JSONL, all in one transaction

Every write needs a session: HUB_SESSION, or --session S (an alias resolves to the current name).
--session human with --by human needs no session row: a person writes their own words (the
question server, `orbit-kb serve questions --hub DIR`, closes an ask this way).
--by human|agent|script (default agent); `human` records a person's own words and needs --note
with the quote.
Output: md tables by default; --format json for scripts. Errors go to stderr as `hubflow: ERROR: ...`.

Seed file (JSON; every key optional, no other keys):
  {"sessions": [{"name": "discovery", "role": "discovery"}, ...],
   "aliases":  [{"alias": "helpdesk", "name": "support"}],
   "persons":  [{"key": "me", "display": "Me"}],
   "owner":    "me"}
  Session names and aliases: lowercase letters, digits and dashes. An alias names a seeded session.
  owner: the person key of the hub's owner (meta owner_person); without it, the person `me`.

Environment
  HUB_SESSION          the writer's session name
  HUBFLOW_HUB          the hub root, when --hub is not given
  HUBFLOW_DB_DIR       the flow/ directory (tests). It wins over --hub; default <hub>/flow
  HUBFLOW_ORBIT_KB     the orbit-kb command for spec KB queries (split like shell words). Default:
                       the hub's own copy, .claude/orbit-kb/bin/orbit-kb (a formal hub), else
                       `orbit-kb` on the PATH. hubflow only runs `--dir KB query GOAL -n 0` (and the
                       read-only `--dir KB migrate check` for `migrations`): for the state,
                       GOAL is blocking(X): exit 0 with lines = blocking, exit 1 = clear. Any other
                       exit, a missing command or a kb ref with no dir in specs/<slug> or
                       W0..W5/analyses (or, for a KB outside the hub, at its path) counts
                       as blocking (fail-safe), unless the newest
                       spec-triage decision of its slug is archive: then triage, the agent guard
                       and rotate read it as archived (clear). The waiver commands of a skip
                       and skip-waived also query the checks and the waivers of the KB
  HUBFLOW_NOW          fixes the clock, YYYY-MM-DDTHH:MM:SSZ (tests). Every write stores it as
                       meta.now so views read the same clock; a read applies it to a private copy
  --hub DIR            the hub root (default: HUBFLOW_HUB, else the nearest directory from the
                       current one up with .hub-template.json, else the git toplevel of the current
                       directory, else the current directory); `where` reads it

The hub is a weekly calendar: W0 is the current week, W5 five weeks back; a week holds only what
people gave it (reports/, transcripts/). A spec KB has the ticket's clock, not the week's: it lives
at specs/<slug>/ at the hub root, and the item's ref is kb:<slug>. A hub made before 0.3.0 keeps
spec KBs at W<n>/analyses/<slug>/kb (ref kb:<slug>/kb); that form still resolves, and specs/ wins.
A kb ref can also name a KB outside the hub: kb:/abs/path or kb:~/path. Its dir must hold kb.pl when
the ref is added; the ledger reads it as it reads a spec KB.
`where` and the retention windows below follow this.

Copies. The ledger holds a pointer (issue:123) and the flow state around it. A pinned copy of a
tracker item (its text with a digest, in the project KB) is allowed; it goes stale when the source
has a later pin. An unpinned copy is not allowed. Re-pin a tracker item each time an agent reads it
for a ticket, so the digest names what the agent read.

Exit codes
  0 ok   1 bad input or a refused rule   2 db state (missing, exists, older or newer schema, locked)
  3 check found a difference or an ask to another person without an issue ref

Retention (rotate --week-start D, D the Monday of the new W0; W5 starts at D - 35 days)
  due: open or waiting, idle 28 days or more, not parked now, not escalated, not a
       summary. Each due item needs a disposition (`triage`) before `rotate` runs; no due item
       lapses by itself
  summary: open 28 days or more (from opened_at; a renew or a park does not delay it) -> the
       rotation lapses it, with no triage; it never blocks a rotation. An escalated summary, or one
       whose spec KB is not clear or is clear only by a live waiver, stays open for the human (the
       same guard as triage). A kb ref whose specs/<slug> is gone and whose newest spec-triage
       decision is archive reads as archived (clear), not as unknown
  prune: closed before D - 35 days -> deleted with refs, links, handoff and events; retired
         sessions retired before then and referenced by no item go with their aliases
  The caller commits flow/jsonl/ with the ids in the message; git history is the archive.

Schema v8 (PRAGMA user_version = 8; times are UTC TEXT YYYY-MM-DDTHH:MM:SSZ). `migrate` takes a v1
db to v2 (it adds disposition, capsule, the two tables of a session index and remakes v_open and
v_retention_due), a v2 db to v3 (it adds meeting and meeting_turn), a v3 db to v4 (it drops
meeting and meeting_turn and their JSONL, adds the item kind summary and the ref kind transcript,
and remakes v_stale and v_retention_due), a v4 db to v5 (it remakes v_stale and v_retention_due:
a park that holds a time ends at that time), a v5 db to v6 (it drops the session index, the two
tables that v2 added, and their JSONL), and a v6 db to v7 (it adds item.due and item.no_kb; every
row keeps its values, and no_kb is 0), and a v7 db to v8 (two triggers on item: a park may not end after
the item's due date; migrate refuses, naming each item, while a row breaks that rule).
  meta(key, value)                  next_A next_T next_K next_H next_S, owner_person, and now (tests only)
  session(name, role, status active|retired, started_on, retired_on)
  session_alias(alias, name, since)
  person(key, display)
  item(id, kind ask|thread|hold|handoff|summary, title 3..200, status open|waiting|done|dropped|lapsed,
       owner_session, waits_on, analysis (a slug, never a W-slot path), opened_at, renewed_at,
       parked_until, closed_at, close_reason, due, no_kb)
                                    closed_at is set exactly when status is closed;
                                    parked_until is a date (park --until: through that day) or a
                                    time (skip-waived: until the waiver's due time); due: the
                                    asker's due date of an ask (YYYY-MM-DD; schema 8: a
                                    park ends on or before it, when both are set); no_kb: 1 when an
                                    ask rests on no KB (0: it has a kb ref, or it is older than
                                    schema 7)
  item_ref(item_id, kind, ref)      issue and pr refs are digits; a kb ref is <slug> (the spec KB at
                                    specs/<slug>) or, in an old hub, <slug>/kb, or a KB outside
                                    the hub, /abs/path or ~/path (as given; ~ is expanded at use;
                                    its dir must hold kb.pl when the ref is added); never W0/...;
                                    a transcript ref is NAME@sha256:HEX (no W slot)
  item_link(from_id, to_id, kind)
  handoff(item_id, from_session, to_session, gate, accepted_at)
  event(seq, at, item_id, verb, old, new, by_session, by human|agent|script, note)
  disposition(seq, at, item_id, disposition keep|lapse|capsule|escalate, asked, note, detail,
       by_session, by)              asked: what an agent asked for when it became escalate;
                                    an open item is escalated while its newest disposition is
  capsule(seq, at, item_id, summary, git_rev, paths (a JSON list), by_session, by)
Views: clock v_open (with escalated) v_escalated v_waiting_on v_inbox v_stale (no summary) v_dup_refs
       v_week v_retention_due (would: triage | lapse (a summary) | prune)
"""
import datetime, hashlib, json, os, re, shlex, sqlite3, subprocess, sys
from urllib.parse import quote

SCHEMA_VERSION = 9
# Schema steps: MIGRATIONS[v] is the SQL that takes a db from schema v to v + 1. DDL is the shape of
# schema 1; init and rebuild run DDL and then every step, so a new db and a migrated db are the
# same. A release that changes the schema raises SCHEMA_VERSION and adds its step to MIGRATIONS.
WARN_DAYS = 14
LAPSE_DAYS = 28
PRUNE_DAYS = 35
TEXT_CAP = 200          # the text cap of the meeting tables of schema 3 (the schema steps keep it)
CAPSULE_MAX = 1000      # a capsule is a summary, not a copy
ORBIT_KB_TIMEOUT = 60   # seconds for one `orbit-kb query`
DISPOSITIONS = ("keep", "lapse", "capsule", "escalate")
CLOSE_REASONS = ("done", "dropped", "human_skip")
ITEM_KINDS = ("ask", "thread", "hold", "handoff", "summary")
ADDABLE = ("ask", "thread", "hold", "summary")
STATUSES = ("open", "waiting", "done", "dropped", "lapsed")
OPEN = ("open", "waiting")
PREFIX = {"ask": "A", "thread": "T", "hold": "K", "handoff": "H", "summary": "S"}
REF_KINDS = ("issue", "pr", "build", "release", "kb", "file", "commit", "url", "transcript", "goal")
# A goal ref (schema 9): the id of the project goal that the item serves directly, with no ticket
# (`--ref goal:pg1`; scientific-method-overhaul c44). orbit reads it for the purpose of the item.
GOAL_REF = re.compile(r"^[a-z][A-Za-z0-9_]*\Z")
# A transcript ref: the file name and its sha256, so it still resolves after the file moves to
# another W slot at rotation (`transcripts --find REF`).
# T40 c12: a name has no '/', '\\', '@', control character (a newline) or '..'; \Z, not $, so no trailing newline
TRANSCRIPT_REF = re.compile(r"^(?P<name>(?!.*\.\.)[^/\\@\x00-\x1f\x7f]+)@sha256:(?P<digest>[0-9a-f]{64})\Z")
LINK_KINDS = ("blocks", "duplicates", "relates", "supersedes", "follows")
BY = ("human", "agent", "script")
HUMAN_SESSION = "human"  # --session human --by human: a person, not a session (orbit-kb serve --hub)
W_SLOT = re.compile(r"^W\d/", re.I)
SLUG = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
SESSION_NAME = re.compile(r"^[a-z0-9][a-z0-9-]*$")
TS = re.compile(r"^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$")
DATE = re.compile(r"^\d{4}-\d\d-\d\d$")
SQL_OK = re.compile(r"^\s*(select|with)\b", re.I)
TS_FMT = "%Y-%m-%dT%H:%M:%SZ"

TABLES = ("meta", "session", "session_alias", "person", "item", "item_ref", "item_link", "handoff", "event",
          "disposition", "capsule")
# Schema 4 drops meeting and meeting_turn; schema 6 drops transcript and transcript_msg. migrate
# removes their JSONL (git keeps it in history).
DROPPED_TABLES = ("meeting", "meeting_turn", "transcript", "transcript_msg")
ORDER = {"meta": "key", "session": "name", "session_alias": "alias", "person": "key", "item": "id",
         "item_ref": "item_id, kind, ref", "item_link": "from_id, to_id, kind", "handoff": "item_id",
         "event": "seq", "disposition": "seq", "capsule": "seq"}

SEED_KEYS = {"sessions": ("name", "role"), "aliases": ("alias", "name"), "persons": ("key", "display")}
SEED_OWNER = "owner"  # optional seed key: the person key of the hub's owner

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

ESCALATED = """COALESCE((SELECT d.disposition = 'escalate' FROM disposition d WHERE d.item_id = i.id
                  ORDER BY d.seq DESC LIMIT 1), 0)"""

# Schema 2 (T05, the flow ledger): triage dispositions, context capsules, the session index (schema 6 drops it);
# v_open gains `escalated`; v_retention_due lists due items as `triage`, never `lapse`.
V2_STEPS = [
    """CREATE TABLE disposition(seq INTEGER PRIMARY KEY, at TEXT NOT NULL,
  item_id TEXT NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  disposition TEXT NOT NULL CHECK(disposition IN ('keep','lapse','capsule','escalate')),
  asked TEXT CHECK(asked IS NULL OR asked IN ('keep','lapse','capsule')),
  note TEXT NOT NULL, detail TEXT,
  by_session TEXT NOT NULL, by TEXT NOT NULL CHECK(by IN ('human','agent','script')))""",
    f"""CREATE TABLE capsule(seq INTEGER PRIMARY KEY, at TEXT NOT NULL,
  item_id TEXT NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  summary TEXT NOT NULL CHECK(length(summary) BETWEEN 1 AND {CAPSULE_MAX}),
  git_rev TEXT, paths TEXT NOT NULL,
  by_session TEXT NOT NULL, by TEXT NOT NULL CHECK(by IN ('human','agent','script')))""",
    """CREATE TABLE transcript(session_id TEXT PRIMARY KEY, first_at TEXT, last_at TEXT,
  first_user TEXT CHECK(first_user IS NULL OR length(first_user) <= 200),
  messages INTEGER NOT NULL, user_messages INTEGER NOT NULL, tools INTEGER NOT NULL, path TEXT NOT NULL)""",
    """CREATE TABLE transcript_msg(session_id TEXT NOT NULL REFERENCES transcript(session_id) ON DELETE CASCADE,
  n INTEGER NOT NULL, at TEXT, text TEXT NOT NULL CHECK(length(text) <= 200), PRIMARY KEY(session_id, n))""",
    "DROP VIEW v_open",
    f"""CREATE VIEW v_open AS
SELECT i.id, i.kind, i.title, i.status, i.owner_session, i.waits_on, i.analysis,
  COALESCE((SELECT group_concat(kind || ':' || ref, ' ')
            FROM (SELECT kind, ref FROM item_ref r WHERE r.item_id = i.id ORDER BY kind, ref)), '') AS refs,
  {AGE.format(col='i.opened_at')} AS age_days,
  {AGE.format(col='i.renewed_at')} AS idle_days,
  i.opened_at, i.renewed_at, i.parked_until,
  {ESCALATED} AS escalated
FROM item i, clock WHERE i.status IN ('open','waiting')""",
    """CREATE VIEW v_escalated AS
SELECT o.id, o.kind, o.title, o.owner_session, o.waits_on, o.refs, o.idle_days,
  d.at AS escalated_at, d.asked, d.note, d.detail, d.by_session
FROM v_open o JOIN disposition d ON d.seq = (SELECT MAX(x.seq) FROM disposition x WHERE x.item_id = o.id)
WHERE o.escalated = 1""",
    "DROP VIEW v_retention_due",
    f"""CREATE VIEW v_retention_due AS
WITH p AS (SELECT clock.now AS now,
                  COALESCE((SELECT value FROM meta WHERE key='rotate_week_start'),
                           date(clock.now, '-6 days', 'weekday 1')) AS wk FROM clock)
SELECT i.id, i.kind, i.title, i.status, 'triage' AS would,
  'idle ' || ((CAST(strftime('%s', p.now) AS INTEGER) - CAST(strftime('%s', i.renewed_at) AS INTEGER)) / 86400) || ' days' AS detail
FROM item i, p
WHERE i.status IN ('open','waiting')
  AND i.renewed_at <= strftime('%Y-%m-%dT%H:%M:%SZ', p.now, '-{LAPSE_DAYS} days')
  AND (i.parked_until IS NULL OR i.parked_until < date(p.now))
  AND {ESCALATED} = 0
UNION ALL
SELECT i.id, i.kind, i.title, i.status, 'prune', 'closed ' || i.closed_at
FROM item i, p
WHERE i.closed_at IS NOT NULL
  AND i.closed_at < strftime('%Y-%m-%dT00:00:00Z', p.wk, '-{PRUNE_DAYS} days')""",
]

# Schema 3 (T28): meeting transcripts parsed by code into two tables. Schema 4 drops them again; the
# step stays so that a v2 db still migrates.
V3_STEPS = [
    f"""CREATE TABLE meeting(id TEXT PRIMARY KEY, path TEXT NOT NULL, title TEXT, date TEXT,
  speakers TEXT, first_lines TEXT CHECK(first_lines IS NULL OR length(first_lines) <= {TEXT_CAP}),
  turns INTEGER NOT NULL, lines INTEGER NOT NULL)""",
    """CREATE TABLE meeting_turn(meeting_id TEXT NOT NULL REFERENCES meeting(id) ON DELETE CASCADE,
  n INTEGER NOT NULL, line INTEGER NOT NULL, speaker TEXT, text TEXT NOT NULL, PRIMARY KEY(meeting_id, n))""",
]



def _swap(text, a, b):
    if text.count(a) != 1:
        raise RuntimeError(f"schema anchor {a!r} occurs {text.count(a)} times")
    return text.replace(a, b)


ITEM_DDL = next(x for x in DDL if x.startswith("CREATE TABLE item("))
ITEM_REF_DDL = next(x for x in DDL if x.startswith("CREATE TABLE item_ref("))

# Schema 4: an agent, not code, puts what a meeting transcript needs into the ledger. The meeting
# tables of schema 3 go. A new item kind `summary` (S-) lapses by itself at the first rotation when it
# is LAPSE_DAYS old and is never due for a triage; a new ref kind `transcript` (NAME@sha256:HEX)
# points to a transcript file in whichever W slot holds it. SQLite cannot change a CHECK in place, so
# item and item_ref are copied into new tables (migrate runs with foreign keys off; legacy_alter_table
# keeps the views and the other tables' references as they are).
V4_STEPS = [
    "DROP TABLE meeting_turn",
    "DROP TABLE meeting",
    "PRAGMA legacy_alter_table=ON",
    _swap(_swap(ITEM_DDL, "CREATE TABLE item(", "CREATE TABLE item_v4("), "'handoff')", "'handoff','summary')"),
    "INSERT INTO item_v4 SELECT * FROM item",
    "DROP TABLE item",
    "ALTER TABLE item_v4 RENAME TO item",
    _swap(_swap(ITEM_REF_DDL, "CREATE TABLE item_ref(", "CREATE TABLE item_ref_v4("), "'url')", "'url','transcript')"),
    "INSERT INTO item_ref_v4 SELECT * FROM item_ref",
    "DROP TABLE item_ref",
    "ALTER TABLE item_ref_v4 RENAME TO item_ref",
    "PRAGMA legacy_alter_table=OFF",
    "DROP VIEW v_stale",
    f"""CREATE VIEW v_stale AS
SELECT * FROM (
  SELECT o.id, o.kind, o.title, o.owner_session, o.age_days, o.idle_days, o.parked_until,
    CASE WHEN o.idle_days >= {LAPSE_DAYS} AND (o.parked_until IS NULL OR o.parked_until < date(clock.now)) THEN 'lapse_due'
         WHEN o.idle_days >= {WARN_DAYS} THEN 'warn' END AS flag
  FROM v_open o, clock WHERE o.kind <> 'summary'
  UNION ALL
  SELECT o.id, o.kind, o.title, o.owner_session, o.age_days, o.idle_days, o.parked_until, 'handoff_unaccepted'
  FROM v_open o JOIN handoff h ON h.item_id = o.id, clock
  WHERE h.accepted_at IS NULL
    AND CAST(strftime('%s', clock.now) AS INTEGER) - CAST(strftime('%s', o.opened_at) AS INTEGER) > 86400
) WHERE flag IS NOT NULL""",
    "DROP VIEW v_retention_due",
    f"""CREATE VIEW v_retention_due AS
WITH p AS (SELECT clock.now AS now,
                  COALESCE((SELECT value FROM meta WHERE key='rotate_week_start'),
                           date(clock.now, '-6 days', 'weekday 1')) AS wk FROM clock)
SELECT i.id, i.kind, i.title, i.status, 'triage' AS would,
  'idle ' || ((CAST(strftime('%s', p.now) AS INTEGER) - CAST(strftime('%s', i.renewed_at) AS INTEGER)) / 86400) || ' days' AS detail
FROM item i, p
WHERE i.status IN ('open','waiting') AND i.kind <> 'summary'
  AND i.renewed_at <= strftime('%Y-%m-%dT%H:%M:%SZ', p.now, '-{LAPSE_DAYS} days')
  AND (i.parked_until IS NULL OR i.parked_until < date(p.now))
  AND {ESCALATED} = 0
UNION ALL
SELECT i.id, i.kind, i.title, i.status, 'lapse',
  'open ' || ((CAST(strftime('%s', p.now) AS INTEGER) - CAST(strftime('%s', i.opened_at) AS INTEGER)) / 86400) || ' days'
FROM item i, p
WHERE i.status IN ('open','waiting') AND i.kind = 'summary'
  AND i.opened_at <= strftime('%Y-%m-%dT%H:%M:%SZ', p.now, '-{LAPSE_DAYS} days')
UNION ALL
SELECT i.id, i.kind, i.title, i.status, 'prune', 'closed ' || i.closed_at
FROM item i, p
WHERE i.closed_at IS NOT NULL
  AND i.closed_at < strftime('%Y-%m-%dT00:00:00Z', p.wk, '-{PRUNE_DAYS} days')""",
]

# Schema 5 (T47 c2): a park by skip-waived holds the waiver's due time (YYYY-MM-DDTHH:MM:SSZ) and ends
# at that time; a park --until YYYY-MM-DD still holds the date and parks through that day. v_stale and
# v_retention_due are remade to compare a park's end (a date D ends at DT24:00:00Z) with the clock.
def park_over(col, now):
    """SQL: the park in col is over at now (no park, a date before now's day, or a time at or before now)."""
    return f"({col} IS NULL OR (CASE WHEN length({col}) = 10 THEN {col} || 'T24:00:00Z' ELSE {col} END) <= {now})"


def _v5(stmt):
    for old, new in (("(o.parked_until IS NULL OR o.parked_until < date(clock.now))", park_over("o.parked_until", "clock.now")),
                     ("(i.parked_until IS NULL OR i.parked_until < date(p.now))", park_over("i.parked_until", "p.now"))):
        stmt = stmt.replace(old, new)
    return stmt


V5_STEPS = [_v5(x) for x in V4_STEPS[V4_STEPS.index("DROP VIEW v_stale"):]]

# Schema 6 (Sagittarius 0.3.0; Ty, 2026-11-12: "drop it"): the session index (transcript, transcript_msg) goes.
# It came from a misunderstanding: the transcripts that matter are meeting transcripts, which stay
# files that an agent reads. Schema 2 made the two tables; init still runs that step, then this one.
V6_STEPS = ["DROP TABLE transcript_msg", "DROP TABLE transcript"]

# Schema 7 (the Desk; hub spec KB questions-server, Ty's answers q5 and q6): an ask carries the asker's
# due date (`due`, YYYY-MM-DD or NULL; the Desk shows it, else the triage date) and says when it rests
# on no KB (`no_kb` 1). A new ask needs a kb ref or --no-kb; an older ask keeps no_kb 0 and no kb ref,
# which the Desk shows as "No KB behind it". ADD COLUMN keeps every row as it is.
V7_STEPS = [
    "ALTER TABLE item ADD COLUMN due TEXT CHECK(due IS NULL OR due GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    "ALTER TABLE item ADD COLUMN no_kb INTEGER NOT NULL DEFAULT 0 CHECK(no_kb IN (0, 1))",
]

# Schema 8 (hub spec KB questions-server c38, c39; Ty, 2026-11-18: "there needs to be a database level
# requirement that parked dates must be <= Due Dates and nullable"; "Refuse both ways"): flow.db itself
# refuses a row whose park ends after its due date. A park until D ends with day D, and a timed park
# (skip-waived) is read by its day, so the rule compares the first 10 characters with due. With either
# column NULL there is no rule. The triggers do not look at the rows already there: migrate checks them
# first (PARK_DUE_CONFLICTS) and refuses, naming each item, before it writes anything.
PARK_DUE_MSG = "park_after_due: a park must end on or before the item's due date"
PARK_DUE_WHEN = "NEW.parked_until IS NOT NULL AND NEW.due IS NOT NULL AND substr(NEW.parked_until, 1, 10) > NEW.due"
PARK_DUE_CONFLICTS = ("SELECT id, parked_until, due FROM item WHERE parked_until IS NOT NULL AND due IS NOT NULL"
                      " AND substr(parked_until, 1, 10) > due ORDER BY id")
V8_STEPS = [
    f"CREATE TRIGGER item_park_due_insert BEFORE INSERT ON item WHEN {PARK_DUE_WHEN}"
    f" BEGIN SELECT RAISE(ABORT, '{PARK_DUE_MSG.replace(chr(39), chr(39) * 2)}'); END",
    f"CREATE TRIGGER item_park_due_update BEFORE UPDATE OF parked_until, due ON item WHEN {PARK_DUE_WHEN}"
    f" BEGIN SELECT RAISE(ABORT, '{PARK_DUE_MSG.replace(chr(39), chr(39) * 2)}'); END",
]

# Schema 9 (scientific-method-overhaul c44): the ref kind `goal` (the project goal that an item names
# directly). item_ref is copied into a table with the new CHECK, as schema 4 did for `transcript`.
V9_STEPS = [
    "PRAGMA legacy_alter_table=ON",
    _swap(_swap(_swap(ITEM_REF_DDL, "CREATE TABLE item_ref(", "CREATE TABLE item_ref_v9("), "'url')", "'url','transcript','goal')"),
          "REFERENCES item(id)", "REFERENCES item(id)"),
    "INSERT INTO item_ref_v9 SELECT * FROM item_ref",
    "DROP TABLE item_ref",
    "ALTER TABLE item_ref_v9 RENAME TO item_ref",
    "PRAGMA legacy_alter_table=OFF",
]

MIGRATIONS = {
    1: V2_STEPS,
    2: V3_STEPS,
    3: V4_STEPS,
    4: V5_STEPS,
    5: V6_STEPS,
    6: V7_STEPS,
    7: V8_STEPS,
    8: V9_STEPS,
}

# view name -> (sql view, filter option -> column, ORDER BY)
VIEW_DEFS = {
    "open": ("v_open", {"session": "owner_session", "kind": "kind"}, "escalated DESC, id"),
    "escalated": ("v_escalated", {"session": "owner_session", "kind": "kind"}, "id"),
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


def parse_park(v):
    """parked_until: a date (park --until) or a time (skip-waived, T47 c2)."""
    return parse_ts(v, "parked_until") if isinstance(v, str) and len(v) > 10 else parse_date(v, "parked_until")


def park_end(v):
    """The time a park ends: a date D parks through that day (DT24:00:00Z); a time is its own end."""
    return v + "T24:00:00Z" if v and len(v) == 10 else v


def ts_add(ts, seconds):
    t = datetime.datetime.strptime(ts, TS_FMT).replace(tzinfo=datetime.timezone.utc).timestamp() + seconds
    return datetime.datetime.fromtimestamp(t, datetime.timezone.utc).strftime(TS_FMT)


def idle_days(now, then):
    a, b = datetime.datetime.strptime(now, TS_FMT), datetime.datetime.strptime(then, TS_FMT)
    return int((a - b).total_seconds() // 86400)


def default_hub():
    """HUBFLOW_HUB, else the first directory from the current one up that holds .hub-template.json
    (a hub inside a parent git repo, T41), else the git toplevel of the current directory, else the
    current directory."""
    env = os.environ.get("HUBFLOW_HUB")
    if env:
        return env
    d = os.getcwd()
    while True:
        if os.path.isfile(os.path.join(d, ".hub-template.json")):
            return d
        up = os.path.dirname(d)
        if up == d:
            break
        d = up
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


def create_schema(c):
    """The schema-1 DDL, then every step up to SCHEMA_VERSION (init and rebuild)."""
    for stmt in DDL:
        c.execute(stmt)
    for v in range(1, SCHEMA_VERSION):
        for stmt in MIGRATIONS[v]:
            c.execute(stmt)


def live_tables(c):
    """TABLES that the db has (a db at an older schema lacks the later ones)."""
    have = {r[0] for r in c.execute("SELECT name FROM sqlite_master WHERE type = 'table'")}
    return [t for t in TABLES if t in have]


# ---- JSONL ----

def table_rows(c, t):
    return [dict(zip(r.keys(), tuple(r))) for r in c.execute(f"SELECT * FROM {t} ORDER BY {ORDER[t]}")]


def export_all(c, d):
    """Write one sorted JSONL file per table. Called inside the write transaction."""
    jd = jsonl_dir(d)
    os.makedirs(jd, exist_ok=True)
    for t in live_tables(c):
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
    for t in live_tables(c):
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
        elif name == HUMAN_SESSION and by == "human" and c.execute(
                "SELECT 1 FROM session WHERE name = ? UNION SELECT 1 FROM session_alias WHERE alias = ?",
                (name, name)).fetchone() is None:
            who = name  # a person writes their own words (the question server): no session row needed
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

def reserved_of(c, iid):
    """The text of the last reserved event of the item (None: not reserved)."""
    r = c.execute("SELECT new FROM event WHERE item_id = ? AND verb = 'reserved' ORDER BY seq DESC LIMIT 1",
                  (iid,)).fetchone()
    return r[0] if r else None


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


def kb_outside(ref):
    """A kb ref that names a KB outside the hub (q5): an absolute path or ~/path, stored as given."""
    return ref.startswith("/") or ref.startswith("~/")


def check_kb_home(kind, ref):
    """q5: when a kb ref to a KB outside the hub is added, its dir (~ expanded) must exist and hold kb.pl."""
    if kind == "kb" and kb_outside(ref):
        p = os.path.expanduser(ref)
        if not os.path.isfile(os.path.join(p, "kb.pl")):
            raise Bad(f"kb ref {ref!r}: {p} is not a KB dir (no kb.pl in it); a KB outside the hub must exist"
                      " when its ref is added")


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
        if ".." in ref.split("/"):
            raise Bad(f"{kind} ref {ref!r} must not contain '..'")
        if kind == "kb" and kb_outside(ref):
            pass  # q5: a KB outside the hub, /abs/path or ~/path
        elif ref.startswith("/"):
            raise Bad(f"{kind} ref {ref!r} must be a relative path inside an analysis"
                      + (" (a KB outside the hub: kb:/abs/path or kb:~/path)" if kind == "kb" else ""))
    elif kind == "commit":
        if not re.fullmatch(r"[0-9a-f]{7,40}", ref):
            raise Bad(f"commit ref {ref!r} must be 7 to 40 hex digits")
    elif kind == "url":
        if not re.match(r"^https?://\S+$", ref):
            raise Bad(f"url ref {ref!r} must start with http:// or https://")
    elif kind == "goal":
        if not GOAL_REF.match(ref):  # goal ref form
            raise Bad(f"goal ref {ref!r} must be the id of a project goal: a lowercase letter, then letters, digits or _"
                      " (goal:pg1)")
    elif kind == "transcript":
        if not TRANSCRIPT_REF.match(ref):  # transcript ref form
            raise Bad(f"transcript ref {ref!r} must be NAME@sha256:HEX: the file name (no directory, no W slot) and its"
                      " sha256 in 64 lowercase hex digits; `hubflow.py transcripts --files` prints it")
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
             parked_until=None, closed_at=None, close_reason=None, due=None, no_kb=0):
    key = "next_" + PREFIX[kind]
    r = c.execute("SELECT value FROM meta WHERE key = ?", (key,)).fetchone()
    n = int(r[0]) if r else 1  # a migrated db has no next_S until its first summary
    iid = f"{PREFIX[kind]}-{n:04d}"
    c.execute("INSERT OR REPLACE INTO meta(key, value) VALUES(?, ?)", (key, str(n + 1)))
    c.execute("INSERT INTO item(id, kind, title, status, owner_session, waits_on, analysis, opened_at, renewed_at,"
              " parked_until, closed_at, close_reason) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)",
              (iid, kind, title, status, owner, waits_on, analysis, opened_at, renewed_at or opened_at,
               parked_until, closed_at, close_reason))
    if due is not None or no_kb:  # schema 7; an item without them needs neither column
        c.execute("UPDATE item SET due = ?, no_kb = ? WHERE id = ?", (due, 1 if no_kb else 0, iid))
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
    out["owner"] = None
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
    extra = sorted(set(obj) - set(SEED_KEYS) - {SEED_OWNER})
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
    if SEED_OWNER in obj:
        if obj[SEED_OWNER] not in keys:
            raise Bad(f"seed owner {obj[SEED_OWNER]!r} must be the key of a seeded person")
        out["owner"] = obj[SEED_OWNER]
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
        create_schema(c)
        today = now[:10]
        for k in ("next_A", "next_T", "next_K", "next_H", "next_S"):
            c.execute("INSERT INTO meta(key, value) VALUES(?, '1')", (k,))
        if os.environ.get("HUBFLOW_NOW"):
            c.execute("INSERT INTO meta(key, value) VALUES('now', ?)", (now,))
        for name, role in seed["sessions"]:
            c.execute("INSERT INTO session(name, role, status, started_on) VALUES(?, ?, 'active', ?)", (name, role, today))
        for alias, name in seed["aliases"]:
            c.execute("INSERT INTO session_alias(alias, name, since) VALUES(?, ?, ?)", (alias, name, today))
        for key, display in seed["persons"]:
            c.execute("INSERT INTO person(key, display) VALUES(?, ?)", (key, display))
        if seed["owner"]:
            c.execute("INSERT INTO meta(key, value) VALUES('owner_person', ?)", (seed["owner"],))
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
    print(f"initialized {db_path(d)}: schema {SCHEMA_VERSION}, {len(seed['sessions'])} sessions, {len(seed['persons'])} people")


def common_item_opts(g, o):
    refs = [parse_ref(x) for x in o.get("ref", [])]
    for kind, ref in refs:
        check_kb_home(kind, ref)
    if o.get("title") is not None:
        check_title(o["title"])
    if o.get("analysis") is not None:
        check_analysis(o["analysis"])
    return refs


def cmd_add(g, a):
    pos, o = parse(a, {**WOPT, "--title": "one", "--owner": "one", "--waits-on": "one", "--analysis": "one",
                       "--ref": "many", "--status": "one", "--reserved": "one", "--due": "one", "--no-kb": "flag"})
    if len(pos) != 1:
        usage("add ask|thread|hold --title T [--owner S] [--waits-on P] [--reserved WHY] [--due YYYY-MM-DD]"
              " [--analysis SLUG] [--ref KIND:REF ... | --no-kb]")
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
    if o.get("reserved") is not None:
        check_reserved(kind, o["reserved"])
    due = check_due(kind, o["due"]) if o.get("due") is not None else None
    refs = common_item_opts(g, o)
    no_kb = check_no_kb(g, kind, o.get("no_kb", False), any(k == "kb" for k, _ in refs))
    check_ask_note(g, kind, o.get("note"))
    warn_kit_thread(kind, o["title"], any(k == "kb" for k, _ in refs))

    def fn(c, w):
        if o.get("owner") == "none":
            owner = None
        else:  # owner defaults to the writer
            owner = resolve_active(c, o.get("owner") or w.session)
        waits = check_person(c, o["waits_on"]) if o.get("waits_on") else None
        iid = new_item(c, kind, o["title"], status, owner, waits, o.get("analysis"), w.now, due=due, no_kb=no_kb)
        add_refs(c, iid, refs)
        w.event(iid, "opened", None, status)
        if o.get("reserved") is not None:
            w.event(iid, "reserved", None, o["reserved"])
        if due is not None:
            w.event(iid, "due", None, due)
        if no_kb:
            w.event(iid, "no_kb", None, "yes")
        return iid

    print(run_write(g, o, fn))


# c12 (hub spec KB questions-server): a reservation names its source. A policy by its name and its
# rule, or a person's own words with their date. Rows written before this rule keep their free text.
RESERVED_POLICY = re.compile(r"[A-Z][A-Za-z0-9'&.-]*(?: [A-Z][A-Za-z0-9'&.-]*)* Policy: \S.*\Z", re.S)
RESERVED_WORDS = re.compile(r"[^\s,:][^,:\n]*, (?P<date>\d{4}-\d\d-\d\d): \S.*\Z", re.S)
RESERVED_FORMS = ('--reserved names the source of the reservation, in one of two forms: "NAME Policy: RULE"'
                  ' (a policy by its name and its rule, for example "Sagittarius Policy: Only the human may waive'
                  ' a proof.") or "WHO, YYYY-MM-DD: WORDS" (a person\'s own words with their date, for example'
                  ' "Ty, 2026-11-12: push only when I say so")')


def check_reserved(kind, why):
    # --reserved WHY: the ask is an action that the person reserved for themselves, by a standing
    # rule or in their own words; WHY quotes the rule or the words. The questions page lists such
    # asks under "Human action needed", and other asks apart (hub spec KB questions-server, c3).
    if kind != "ask":
        raise Bad("--reserved marks an ask: an action that the person reserved for themselves")
    if not isinstance(why, str) or not 3 <= len(why.strip()) <= 500:
        raise Bad("--reserved needs the rule or the words that reserve the action (3 to 500 characters)")
    if RESERVED_POLICY.match(why.strip()):  # reserved source form
        return
    m = RESERVED_WORDS.match(why.strip())
    if m is None:
        raise Bad(RESERVED_FORMS)
    try:
        datetime.date.fromisoformat(m.group("date"))
    except ValueError:  # reserved real date
        raise Bad(f"--reserved date {m.group('date')} is not a real date; " + RESERVED_FORMS)


def check_due(kind, v):
    """q6: --due is the asker's due date of an ask (the Desk shows it, else the triage date)."""
    if kind != "ask":  # due on an ask only
        raise Bad("--due belongs to an ask: the date by which the asker needs the answer")
    return parse_date(v, "--due")


# kb-query c6: a thread about the kit (a title that starts with "Kit") with no kb ref is a finding that
# has no owner. Warn, and name the query that finds the spec KB that owns it. It blocks nothing.
KIT_TITLE = re.compile(r"\s*Kit\b[\s:,-]", re.I)
KIT_WARN = ("hubflow: warning: this thread is about the kit and has no kb ref; find the spec KB that owns it:"
            " orbit hub query 'ticket_fact(S, claim(C, L, T))' (the goals and claims of every spec KB), then add"
            " --ref kb:<slug> (hubflow ref ID add kb:<slug>)")


def warn_kit_thread(kind, title, has_kb):
    if kind == "thread" and not has_kb and isinstance(title, str) and KIT_TITLE.match(title):
        print(KIT_WARN, file=sys.stderr)


ASK_KB = ("an ask says whether it rests on a KB: give --ref kb:<slug> (or kb:/abs/path, kb:~/path) for the KB"
          " it rests on, or --no-kb when it rests on no KB")


def check_no_kb(g, kind, no_kb, has_kb):
    """q5: a new ask carries a kb ref or --no-kb (not both). Returns no_kb."""
    if no_kb and kind != "ask":
        raise Bad("--no-kb belongs to an ask: it says that the ask rests on no KB")
    if no_kb and has_kb:
        raise Bad("--no-kb says that the ask rests on no KB, but it has a kb ref; give one or the other")
    if kind == "ask" and not no_kb and not has_kb:  # an ask says whether it rests on a KB
        raise Bad(ASK_KB)
    return no_kb


ASK_NOTE = ("an ask needs --note TEXT, the context that the Desk shows with it: give the case, the options"
            " and what each one changes, and your default")


def check_ask_note(g, kind, note):
    """c13: a new ask carries a context note (not blank). The Desk shows the notes of an ask as its context."""
    if kind == "ask" and not (note or "").strip():  # an ask carries a context note
        raise Bad(ASK_NOTE)


def cmd_handoff(g, a):
    pos, o = parse(a, {**WOPT, "--to": "one", "--title": "one", "--gate": "one", "--analysis": "one", "--ref": "many"})
    if pos or not o.get("to") or o.get("title") is None:
        usage("handoff --to S --title T [--gate G] [--analysis SLUG] [--ref KIND:REF ...] [--note N]")
    refs = common_item_opts(g, o)

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
    agent_guard(g, o, pos[0], "renew")

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
    agent_guard(g, o, pos[0], "park")

    def fn(c, w):
        it = get_item(c, pos[0])
        need_open(it)
        if until < w.now[:10]:
            raise Bad(f"--until {until} is before today ({w.now[:10]})")
        if it["due"] and until > it["due"]:  # schema 8: park end <= due
            raise Bad(f"--until {until} is after the due date {it['due']} of {it['id']}: a park must end on or before"
                      f" the due date. Park until {it['due']} or earlier, or change the due date first (set {it['id']} --due)")
        c.execute("UPDATE item SET parked_until = ? WHERE id = ?", (until, it["id"]))
        w.event(it["id"], "parked", it["parked_until"], until)

    run_write(g, o, fn)


def cmd_set(g, a):
    pos, o = parse(a, {**WOPT, "--title": "one", "--owner": "one", "--waits-on": "one", "--status": "one",
                       "--analysis": "one", "--reserved": "one", "--due": "one", "--no-kb": "one"})
    if len(pos) != 1:
        usage("set ID [--title T] [--owner S] [--waits-on P|none] [--status open|waiting] [--analysis SLUG|none]"
              " [--reserved WHY|none] [--due YYYY-MM-DD|none] [--no-kb yes|no]")
    if not any(k in o for k in ("title", "owner", "waits_on", "status", "analysis", "reserved", "due", "no_kb")):
        raise Bad("set needs at least one of --title --owner --waits-on --status --analysis --reserved --due --no-kb")
    if o.get("due") not in (None, "none"):
        parse_date(o["due"], "--due")
    if "no_kb" in o:
        if o["no_kb"] not in ("yes", "no"):
            raise Bad("--no-kb is yes (the ask rests on no KB) or no")
    if "title" in o:
        check_title(o["title"])
    if "status" in o and o["status"] not in OPEN:
        raise Bad("--status is open or waiting (close with the close command)")
    if o.get("analysis") not in (None, "none"):
        check_analysis(o["analysis"])
    if "status" in o:
        agent_guard(g, o, pos[0], "change the status of", waiver=True)

    def fn(c, w):
        it = get_item(c, pos[0])
        iid = it["id"]
        if "reserved" in o:
            old_r = reserved_of(c, iid)
            new_r = None if o["reserved"] == "none" else o["reserved"]
            if new_r is not None:
                check_reserved(it["kind"], new_r)
            if new_r != old_r:
                w.event(iid, "reserved", old_r, new_r)
        if "due" in o:
            new = None if o["due"] == "none" else check_due(it["kind"], o["due"])
            pu = it["parked_until"]
            if new and pu and pu[:10] > new:  # schema 8: park end <= due
                raise Bad(f"--due {new} is before the end of the park of {iid} ({pu}): a park must end on or before"
                          f" the due date. Give a due date of {pu[:10]} or later, or park it to an earlier date first")
            if new != it["due"]:
                c.execute("UPDATE item SET due = ? WHERE id = ?", (new, iid))
                w.event(iid, "due", it["due"], new)
        if "no_kb" in o:
            if it["kind"] != "ask":
                raise Bad("--no-kb belongs to an ask: it says that the ask rests on no KB")
            new = 1 if o["no_kb"] == "yes" else 0
            if new and item_kb_refs(c, iid):  # no_kb with a kb ref
                raise Bad(f"{iid} has a kb ref, so it rests on a KB; remove the ref first (ref {iid} rm kb:...)")
            if new != it["no_kb"]:
                c.execute("UPDATE item SET no_kb = ? WHERE id = ?", (new, iid))
                w.event(iid, "no_kb", "yes" if it["no_kb"] else "no", o["no_kb"])
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
    if len(pos) != 1 or o.get("reason") not in CLOSE_REASONS:
        usage("close ID --reason done|dropped|human_skip [--note N]")
    skip = o["reason"] == "human_skip"
    if skip and writer_by(o, g) != "human":
        raise Bad("--reason human_skip records a person's skip: pass --by human --note with their words")
    if not skip:  # an agent never closes a blocking item
        agent_guard(g, o, pos[0], "close", waiver=True)

    def fn(c, w):
        it = get_item(c, pos[0])
        need_open(it)
        iid = it["id"]
        status = "dropped" if skip else o["reason"]
        c.execute("UPDATE item SET status = ?, closed_at = ?, close_reason = ? WHERE id = ?",
                  (status, w.now, o["reason"], iid))
        w.event(iid, "closed", it["status"], o["reason"])
        linked = []
        if o["reason"] == "human_skip":  # propagate
            linked = [r[0] for r in c.execute(
                "SELECT i.id FROM item i WHERE i.status IN ('open','waiting') AND i.id IN"
                " (SELECT to_id FROM item_link WHERE from_id = ? AND kind = 'blocks'"
                "  UNION SELECT from_id FROM item_link WHERE to_id = ? AND kind = 'blocks') ORDER BY i.id", (iid, iid))]
            for x in linked:
                old = c.execute("SELECT status FROM item WHERE id = ?", (x,)).fetchone()[0]
                c.execute("UPDATE item SET status = 'dropped', closed_at = ?, close_reason = ? WHERE id = ?",
                          (w.now, f"human_skip of {iid}", x))
                w.event(x, "closed", old, "human_skip",
                        note=f"the human skipped {iid}, linked by blocks; their words are on {iid}", by="script")
        kbs = []
        for x in [iid] + linked:
            for r in c.execute("SELECT ref FROM item_ref WHERE item_id = ? AND kind = 'kb' ORDER BY ref", (x,)):
                if r[0] not in kbs:
                    kbs.append(r[0])
        return iid, linked, kbs

    iid, linked, kbs = run_write(g, o, fn)
    if not skip:
        return
    print(f"closed: {iid} human_skip")
    print("closed_linked: " + (" ".join(linked) or "none"))
    print_waivers(hub_dir(g), iid, kbs)


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
    if pos[1] == "add" and kind == "kb":
        check_kb_home(kind, ref)
    if pos[1] == "rm" and kind == "kb":
        agent_guard(g, o, pos[0], "remove the kb ref of", waiver=True)

    def fn(c, w):
        it = get_item(c, pos[0])
        if pos[1] == "add":
            n = c.execute("INSERT OR IGNORE INTO item_ref(item_id, kind, ref) VALUES(?,?,?)", (it["id"], kind, ref)).rowcount
            if n:
                w.event(it["id"], "ref_add", None, f"{kind}:{ref}")
            if kind == "kb" and it["no_kb"]:  # q5: a kb ref says the ask rests on a KB
                c.execute("UPDATE item SET no_kb = 0 WHERE id = ?", (it["id"],))
                w.event(it["id"], "no_kb", "yes", "no")
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
    if (o.get("by") or g.get("by")) == "human":
        o["note"] = text  # --by human: TEXT is the person's own words (the questions page)

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
    caps = [dict(r) for r in c.execute("SELECT * FROM capsule WHERE item_id = ? ORDER BY seq DESC", (iid,))]
    for x in caps:
        x["paths"] = json.loads(x["paths"])
    c.close()
    d = {"capsule": caps[0] if caps else None, "capsules": caps, **d}  # the capsule comes first
    if fmt == "json":
        print(json.dumps(d, indent=1, ensure_ascii=False))
        return
    if caps:
        x = caps[0]
        print(f"capsule: {x['summary']}")
        print(f"capsule_rev: {x['git_rev'] or '(no git revision)'}")
        print("capsule_paths: " + " ".join(x["paths"]))
        print(f"capsule_at: {x['at']} by {x['by_session']} ({x['by']})"
              + (f"; {len(caps) - 1} older capsule(s) in --format json" if len(caps) > 1 else ""))
        print()
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
    if len(pos) > 1:
        usage("view [NAME] [--session S] [--person P] [--kind K] [--format md|json|tsv]")
    pos = pos or ["open"]  # escalated items first
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
    if name == "retention_due":  # T40 c11: would=lapse only for the summaries that rotate lapses
        rows = retention_due_rows(c, hub_dir(g), cols, rows)
    c.close()
    print(render(rows, cols, fmt))


def retention_due_rows(c, hub, cols, rows):
    """The rows of v_retention_due without the lapse rows that rotate leaves open: an escalated summary,
    or one whose spec KB is not clear (kb_held_summaries, fail-safe)."""
    i_id, i_would = cols.index("id"), cols.index("would")
    lapse = [r[i_id] for r in rows if r[i_would] == "lapse"]
    keep = set(x for x in lapse if not is_escalated(c, x))
    keep -= kb_held_summaries(c, hub, sorted(keep))
    return [r for r in rows if r[i_would] != "lapse" or r[i_id] in keep]


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
        usage("where SLUG|/abs/path|~/path")
    hub = hub_dir(g)
    if kb_outside(pos[0]):  # q5: a KB outside the hub; the expanded path
        p = kb_dir(hub, pos[0])
        if p is None:
            raise Bad(f"no KB dir {os.path.expanduser(pos[0])}")
        print(os.path.normpath(p))
        return
    slug = check_analysis(pos[0])
    p = kb_dir(hub, slug)
    if p is None:
        raise Bad(f"no spec KB {slug!r} in specs/ (or, in an old hub, W0 to W5 analyses)")
    print(os.path.relpath(os.path.normpath(p), hub))


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
    for k, ref in row["refs"]:
        check_kb_home(k, ref)
    row["opened_at"] = parse_ts(obj["opened_at"], "opened_at") if obj.get("opened_at") else None
    row["renewed_at"] = parse_ts(obj["renewed_at"], "renewed_at") if obj.get("renewed_at") else None
    row["parked_until"] = parse_park(obj["parked_until"]) if obj.get("parked_until") else None
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


# ---- the ledger: spec KB queries, triage, capsules, transcripts ----

def orbit_kb_cmd():
    """The orbit-kb command: HUBFLOW_ORBIT_KB (split like a shell word list); else the hub's own copy,
    .claude/orbit-kb/bin/orbit-kb beside this script's .claude/scripts/ (the orbit-kb that the kit was
    tested with; install UX c3), whatever orbit-kb is on the PATH; else `orbit-kb` (a hub without the
    copy: made before kit 0.6.0, or its copy is gone)."""
    if os.environ.get("HUBFLOW_ORBIT_KB"):
        return shlex.split(os.environ["HUBFLOW_ORBIT_KB"])
    own = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "orbit-kb", "bin", "orbit-kb"))
    if os.access(own, os.X_OK):  # the hub's own copy (install UX c3)
        return [own]
    return ["orbit-kb"]


def kb_dir(hub, ref):
    """The one resolver of a kb ref to its dir, or None. <slug> or <slug>/<path>: specs/<slug>/<path>
    first, then (an old hub) W<n>/analyses/<slug>/<path>, newest week first. /abs/path or ~/path (q5: a
    KB outside the hub): that dir, with ~ expanded now."""
    if kb_outside(ref):
        p = os.path.expanduser(ref)
        return p if os.path.isdir(p) else None
    slug, _, rest = ref.partition("/")
    p = os.path.join(hub, "specs", slug, rest)
    if os.path.isdir(p):
        return p
    for n in range(6):
        p = os.path.join(hub, f"W{n}", "analyses", slug, rest)
        if os.path.isdir(p):
            return p
    return None


def query_blocking(path):
    """Ask one spec KB what blocks: (state, items, why). state: blocking | clear | unknown.
    Only `query` is run: the ledger never writes to a spec KB. `-n 0`: every answer (T42 c3)."""
    try:
        p = subprocess.run(orbit_kb_cmd() + ["--dir", path, "query", "blocking(X)", "-n", "0"],
                           capture_output=True, text=True, timeout=ORBIT_KB_TIMEOUT)
    except (OSError, ValueError, subprocess.SubprocessError) as e:
        return "unknown", [], f"orbit-kb did not run ({e.__class__.__name__}: {e})"
    if p.returncode == 0:
        items = []
        for line in p.stdout.splitlines():
            x = line.strip()
            if x.startswith("X = "):
                x = x[4:].strip()
            if x:
                items.append(x)
        return ("blocking", items, "") if items else ("clear", [], "")
    if p.returncode == 1:
        return "clear", [], ""
    return "unknown", [], f"orbit-kb exited {p.returncode}" + (f": {p.stderr.strip()[:200]}" if p.stderr.strip() else "")


def kb_checks(hub, refs):
    """One check per kb ref: {ref, path, state, items, why}. A dir that is not found is unknown."""
    out = []
    for ref in refs:
        path = kb_dir(hub, ref)
        if path is None:
            out.append({"ref": ref, "path": None, "state": "unknown", "items": [],
                        "why": f"no dir {os.path.expanduser(ref)}" if kb_outside(ref)
                        else f"no dir specs/{ref} or W0..W5/analyses/{ref}"})
            continue
        state, items, why = query_blocking(path)
        out.append({"ref": ref, "path": path, "state": state, "items": items, "why": why})
    return out


def blocking_detail(checks):
    parts = []
    for k in checks:
        if k["state"] == "blocking":
            parts.append(f"kb:{k['ref']} blocks on {', '.join(k['items'])}")
        elif k["state"] == "unknown":
            parts.append(f"kb:{k['ref']}: {k['why']}; treated as blocking")
    return "; ".join(parts)


def waive_quote(term):
    return f'"{term}"' if not re.search(r'["$`\\]', term) else shlex.quote(term)


def kb_query(path, goal):
    """The answer lines of one read-only orbit-kb query (`-n 0`), or None when it did not answer."""
    try:
        p = subprocess.run(orbit_kb_cmd() + ["--dir", path, "query", goal, "-n", "0"],
                           capture_output=True, text=True, timeout=ORBIT_KB_TIMEOUT)
    except (OSError, ValueError, subprocess.SubprocessError):
        return None
    if p.returncode not in (0, 1):
        return None
    return [x.strip() for x in p.stdout.splitlines() if x.strip()] if p.returncode == 0 else []


BLOCKING_ID = re.compile(r"^(under|check_failing|check_unrun|to_ask|burn_open|flare_open|past_due|waiver_lapsed)\((\w+)\)$")


def waiver_targets(path, item):
    """The ids that a waiver names to end one blocking item X of a spec KB (T42 c3): under(C) -> each
    check of C (a waived check covers its claim); check_failing(K), check_unrun(K) -> K; to_ask(Q) -> Q;
    burn_open(C), flare_open(C) -> C; past_due(X) -> X; waiver_lapsed(W) -> the target of W; a bare id ->
    itself. [] when no waiver ends it (over, no_claim, a supersede cycle, a stale request)."""
    if re.fullmatch(r"\w+", item):
        return [item]
    m = BLOCKING_ID.match(item)
    if not m:
        return []
    kind, x = m.groups()
    if kind == "under":
        ks = [l[4:] for l in kb_query(path, f"check(K, {x})") or [] if l.startswith("K = ")]
        return ks or [x]
    if kind == "waiver_lapsed":
        ts = [l[4:] for l in kb_query(path, f"attest({x}, waiver, _, waive(T, _, _), _, _)") or [] if l.startswith("T = ")]
        return ts[:1]
    return [x]


def print_waivers(hub, iid, kbs):
    """Print, never run, the waiver command for each blocking item of each linked spec KB."""
    cmd = shlex.join(orbit_kb_cmd())
    reason = f"human skip of {iid} in the hub ledger"
    for k in kb_checks(hub, kbs):
        rel = hub_rel(k["path"], hub) if k["path"] else None  # a KB outside the hub: its own path
        if k["state"] == "clear":
            print(f"# kb:{k['ref']}: nothing blocks; no waiver needed")
        elif k["state"] == "blocking":
            seen = []
            for x in k["items"]:
                ts = waiver_targets(k["path"], x)
                if not ts:
                    print(f"# kb:{k['ref']}: {x}: a waiver does not end it; the spec KB's own work does")
                if x.startswith("under(") and len(ts) > 1:
                    print(f"# kb:{k['ref']}: {x}: one waived check covers its claim")
                for t in ts:
                    if t in seen:
                        continue
                    seen.append(t)
                    term = f"waive({t}, '<DUE>', '{reason}')"
                    print(f"waiver: {cmd} --dir {rel} attest waiver {t} {waive_quote(term)} --by human")
        elif rel:
            print(f"# kb:{k['ref']}: {k['why']}; run `{cmd} --dir {rel} query 'blocking(X)' -n 0` and waive each item:")
            print(f"waiver: {cmd} --dir {rel} attest waiver <ITEM> {waive_quote(f'waive(<ITEM>, <DUE>, {reason!r})')} --by human")
        else:
            print(f"# kb:{k['ref']}: {k['why']}; find the spec KB and waive its blocking items by hand")
    if kbs:
        print("# the human runs each waiver and sets <DUE>; hubflow never writes to a spec KB")
        print("# then `hubflow.py skip-waived` parks the items whose spec KB is waived and clear until the due time;"
              " an escalated item stays for the human")


# A live human waiver that covers something that would block without it (T42 c5): a check of a claim
# that is not fulfilled, a question that would be asked, a burn with no proof, a flare with no approved
# demo. A precaution waiver on a KB that is clear on its own is not one. T42 c7: a lapsed waiver never
# counts (over a check that passes now it does not block either, so the KB reads clear).
WAIVER_QUERY = ("attest(W, waiver, _, waive(T, D, R), human, _), "
                "not waiver_lapsed(W), (check(T, _C), current(_C), not fulfilled(_C) ; "
                "question(T, _Q, _), current(_Q), contested(_Q), not answered(T) ; "
                "burn(T), current(T), not burn_proved(T) ; flare(T), current(T), not flare_shown(T))")


def needed_waivers(path):
    """The live human waivers of a spec KB that something rests on: [(attestation id, target, due,
    reason text)], one per waiver. Only `query` runs."""
    out, seen = [], set()
    for line in kb_query(path, WAIVER_QUERY) or []:
        m = re.match(r"W = (\S+?), T = (\S+?), D = '([^']*)', R = (.*)$", line)
        if m and m.group(1) not in seen:
            seen.add(m.group(1))
            out.append((m.group(1), m.group(2), m.group(3), m.group(4).strip("'")))
    return out


def live_waiver(checks):
    """For kb checks that all read clear: (ref, attestation id, target, due, reason) of the live human
    waiver with the earliest due time that something rests on (after it the KB blocks again). None
    when no such waiver exists (the KB is clear on its own: not a skip, T42 c5). T47 c1: such a KB is
    clear only by the waiver, so agent_guard holds the item for the human."""
    waived = [(k["ref"], w) for k in checks if k["path"] for w in needed_waivers(k["path"])]
    if not waived:
        return None
    ref, (wid, target, due, why) = min(waived, key=lambda x: (x[1][2], x[0], x[1][0]))
    return ref, wid, target, due, why


def waiver_words(hold):
    ref, wid, target, due, why = hold
    return f"the human waived {target} in kb:{ref} ({wid}) until {due}: {why}"


def waiver_park(checks):
    """(until, note) for an item whose kb checks all read clear: the earliest due time of the waivers it
    rests on, as a time (T47 c2: the park ends at the due time, not at the end of its day), and the note
    that names the waiver. None when no such waiver exists (T42 c5)."""
    hold = live_waiver(checks)
    if hold is None:
        return None
    due = hold[3]
    until = due if TS.match(due) else due[:10]  # a due time that is not YYYY-MM-DDTHH:MM:SSZ parks through its day
    return until, waiver_words(hold) + "; parked until then"


def item_kb_refs(c, iid):
    return [r[0] for r in c.execute("SELECT ref FROM item_ref WHERE item_id = ? AND kind = 'kb' ORDER BY ref", (iid,))]


def skip_candidates(g):
    """The read of skip-waived: [(item id, until, escalated)] for each open item whose kb refs all read
    clear and rest on a live human waiver, and that is not parked through `until` yet."""
    hub = hub_dir(g)
    c = connect_ro(flow_dir(g))
    cand = []
    for it in c.execute("SELECT id, parked_until FROM item WHERE status IN ('open','waiting') ORDER BY id").fetchall():
        refs = item_kb_refs(c, it[0])
        if refs:
            cand.append((it[0], it[1], refs, is_escalated(c, it[0])))
    c.close()
    out = []
    for iid, parked_until, refs, esc in cand:
        checks = kb_checks(hub, refs)
        if any(k["state"] != "clear" for k in checks):
            continue  # something still blocks, or the KB is unknown: not a skip
        plan = waiver_park(checks)
        if plan and not (parked_until and park_end(parked_until) >= park_end(plan[0])):
            out.append((iid, plan[0], esc))
    return out


def cmd_skip_waived(g, a):
    pos, o = parse(a, WOPT)
    if pos:
        usage("skip-waived")
    hub = hub_dir(g)
    ending = [iid for iid, _, _ in skip_candidates(g)]
    past_due = []

    def fn(c, w):
        done, kept = [], []
        past_due.clear()
        for iid in ending:
            it = get_item(c, iid)
            if it["status"] not in OPEN:
                continue
            # inside the write: an item escalated after the read above stays open too (T40 c13)
            if is_escalated(c, iid):  # escalated stays for the human
                kept.append(iid)
                continue
            # T42 c2: so does an item whose kb refs (read again, with any ref added since) no longer read clear
            refs = item_kb_refs(c, iid)
            checks = kb_checks(hub, refs)
            if not refs or any(k["state"] != "clear" for k in checks):  # recheck in the write
                continue
            plan = waiver_park(checks)
            if plan is None:
                continue
            until, note = plan
            if it["parked_until"] and park_end(it["parked_until"]) >= park_end(until):
                continue  # parked through the due time already
            if it["due"] and until[:10] > it["due"]:  # schema 8: a park must end on or before the due date
                past_due.append(iid)
                continue
            # T42 c4: the waiver ends the item only for its time: park it until the due date, never drop it
            c.execute("UPDATE item SET parked_until = ? WHERE id = ?", (until, iid))
            w.event(iid, "parked", it["parked_until"], until, note=note, by="script")
            done.append(iid)
        return done, kept

    done, kept = run_write(g, o, fn) if ending else ([], [])
    print("parked: " + (" ".join(done) or "none"))
    for iid in kept:
        print(f"escalated: {iid} (the human ends it with triage)")
    for iid in past_due:
        print(f"not parked: {iid} (the waiver's due time is after the item's due date; schema 8 refuses that park)")


def is_escalated(c, iid):
    r = c.execute("SELECT disposition FROM disposition WHERE item_id = ? ORDER BY seq DESC LIMIT 1", (iid,)).fetchone()
    return r is not None and r[0] == "escalate"


def agent_guard(g, o, iid, what, waiver=False):
    """An agent may not `what` an open item that is escalated or whose spec KB blocks (same
    fail-safe as triage): only a human, with --by human --note, may. waiver=True (T47 c1: close,
    set --status, ref rm kb): nor an item whose spec KB is clear only by a live human waiver; the
    waiver ends the item only for its time, so an agent may park it, never end it."""
    if writer_by(o, g) == "human":
        return
    c = connect_ro(flow_dir(g))
    it = get_item(c, iid)
    esc = it["status"] in OPEN and is_escalated(c, it["id"])
    # T45 c2: the refusal names why it was escalated (the note of its newest disposition), such as a
    # dropped edit of a project KB, which only a human closes
    esc_note = c.execute("SELECT note FROM disposition WHERE item_id = ? ORDER BY seq DESC LIMIT 1",
                         (it["id"],)).fetchone() if esc else None
    refs = [r[0] for r in c.execute("SELECT ref FROM item_ref WHERE item_id = ? AND kind = 'kb' ORDER BY ref", (it["id"],))]
    refs = unarchived(c, hub_dir(g), refs)  # T48 c1: an archived spec KB reads as archived here too
    c.close()
    checks = kb_checks(hub_dir(g), refs) if it["status"] in OPEN and refs and not esc else []
    if esc or any(k["state"] != "clear" for k in checks):  # agent guard
        why = (f"escalated to the human ({esc_note[0]})" if esc_note and esc_note[0] else "escalated to the human") \
            if esc else f"blocking ({blocking_detail(checks)})"
        raise Bad(f"{it['id']} is {why}; an agent cannot {what} it. A human can: add --by human --note \"<their words>\"")
    hold = live_waiver(checks) if waiver and not esc else None  # waiver read
    if hold:
        raise Bad(f"{it['id']} is held by a live waiver ({waiver_words(hold)}); after {hold[3]} the work comes back,"
                  f" so an agent cannot {what} it (it may park it). A human can: add --by human --note \"<their words>\"")


def cmd_triage(g, a):
    pos, o = parse(a, WOPT)
    if len(pos) != 2:
        usage("triage ID keep|lapse|capsule|escalate --note T")
    iid, disp = pos
    if disp not in DISPOSITIONS:
        raise Bad(f"disposition {disp!r} is not one of {', '.join(DISPOSITIONS)}")
    if not o.get("note"):
        raise Bad("triage needs --note: why this disposition")
    by = writer_by(o, g)
    c = connect_ro(flow_dir(g))
    it = get_item(c, iid)
    need_open(it)
    kb_refs = [r[0] for r in c.execute("SELECT ref FROM item_ref WHERE item_id = ? AND kind = 'kb' ORDER BY ref", (iid,))]
    kb_refs = unarchived(c, hub_dir(g), kb_refs)  # T48 c1: an archived spec KB reads as archived here too
    esc = is_escalated(c, it["id"])
    c.close()
    final, asked, detail, hold = disp, None, None, None
    if by != "human" and disp != "escalate" and esc:  # escalated stays
        final, asked, detail = "escalate", disp, "escalated to the human; only --by human --note decides it"
    elif by != "human" and disp != "escalate" and kb_refs:  # agents escalate
        checks = kb_checks(hub_dir(g), kb_refs)
        blocking = any(k["state"] != "clear" for k in checks)  # fail-safe
        if blocking:
            final, asked, detail = "escalate", disp, blocking_detail(checks)
        elif disp == "lapse":  # T47 c1: a live waiver ends the item only for its time
            hold = live_waiver(checks)
            if hold:
                final, asked, detail = "escalate", disp, f"held by a live waiver ({waiver_words(hold)})"

    def fn(c, w):
        it = get_item(c, iid)
        need_open(it)
        if final == "capsule" and c.execute("SELECT 1 FROM capsule WHERE item_id = ?", (iid,)).fetchone() is None:
            raise Bad(f"disposition capsule needs a capsule first: hubflow.py capsule {iid} --summary T")
        c.execute("INSERT INTO disposition(at, item_id, disposition, asked, note, detail, by_session, by)"
                  " VALUES(?,?,?,?,?,?,?,?)", (w.now, iid, final, asked, o["note"], detail, w.session, w.by))
        w.event(iid, "triage", asked, final)
        if final in ("keep", "capsule"):
            c.execute("UPDATE item SET renewed_at = ? WHERE id = ?", (w.now, iid))
        elif final == "lapse":
            c.execute("UPDATE item SET status = 'lapsed', closed_at = ?, close_reason = ? WHERE id = ?",
                      (w.now, f"lapsed: triage, idle {idle_days(w.now, it['renewed_at'])} days", iid))
            w.event(iid, "lapsed", it["status"], "lapsed", note=None)

    run_write(g, o, fn)
    if asked:
        print(f"{iid} escalate (asked {asked}): {detail}")
        if hold:  # T48 c4: the item is not blocking; the waiver holds it, and an agent may keep or park such an item
            print(f"{iid} stays open at the top of `view open` for the human: the waiver ends it only until {hold[3]},"
                  f" so an agent cannot lapse it (an agent may keep or park an item that a waiver holds)")
        else:
            print(f"{iid} stays open at the top of `view open` for the human; an agent cannot keep or lapse a blocking item")
    else:
        print(f"{iid} {final}")


def git_head(hub):
    try:
        p = subprocess.run(["git", "-C", hub, "rev-parse", "HEAD"], capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return None
    v = p.stdout.strip()
    return v if p.returncode == 0 and re.fullmatch(r"[0-9a-f]{40,64}", v) else None


def cmd_capsule(g, a):
    pos, o = parse(a, {**WOPT, "--summary": "one"})
    if len(pos) != 1 or o.get("summary") is None:
        usage("capsule ID --summary T")
    summary = o["summary"].strip()
    if not 1 <= len(summary) <= CAPSULE_MAX:
        raise Bad(f"the summary must be 1 to {CAPSULE_MAX} characters: the context the tracker lacks, not a copy")
    rev = git_head(hub_dir(g))  # capsule rev

    def fn(c, w):
        it = get_item(c, pos[0])
        paths = [r[0] for r in c.execute("SELECT ref FROM item_ref WHERE item_id = ? AND kind IN ('kb','file') ORDER BY ref",
                                         (it["id"],))]
        c.execute("INSERT INTO capsule(at, item_id, summary, git_rev, paths, by_session, by) VALUES(?,?,?,?,?,?,?)",
                  (w.now, it["id"], summary, rev, json.dumps(paths), w.session, w.by))
        w.event(it["id"], "capsule", None, rev)
        return it["id"]

    iid = run_write(g, o, fn)
    if rev is None:
        print(f"hubflow: warning: {hub_dir(g)} has no git HEAD; the capsule has no revision", file=sys.stderr)
    print(f"{iid} capsule at {rev or 'no git revision'}")


def hub_rel(path, hub):
    rel = os.path.relpath(path, hub)
    return path if rel.startswith("..") else rel


WEEK_DIR = re.compile(r"^W\d$")


def week_dirs(hub):
    return sorted(x for x in os.listdir(hub) if WEEK_DIR.match(x) and os.path.isdir(os.path.join(hub, x))) \
        if os.path.isdir(hub) else []


FILE_COLS = ("path", "date", "size", "sha256", "ref")


def week_transcript_files(hub):
    """Every file under W0..W5/transcripts/ (dot files skipped), read for its size and sha256 only:
    code never parses a meeting transcript. Rows of FILE_COLS, sorted by path."""
    out = []
    for wk in week_dirs(hub):
        td = os.path.join(hub, wk, "transcripts")
        for root, dirs, files in os.walk(td):
            dirs[:] = sorted(x for x in dirs if not x.startswith("."))
            for name in sorted(files):
                if name.startswith("."):
                    continue
                path = os.path.join(root, name)
                h = hashlib.sha256()
                with open(path, "rb") as f:
                    for chunk in iter(lambda: f.read(1 << 20), b""):
                        h.update(chunk)
                st = os.stat(path)
                day = datetime.datetime.fromtimestamp(st.st_mtime, datetime.timezone.utc).strftime("%Y-%m-%d")
                out.append((hub_rel(path, hub), day, st.st_size, h.hexdigest(), f"transcript:{name}@sha256:{h.hexdigest()}"))
    return sorted(out)


def find_transcript(hub, ref):
    """The hub-relative path of the file that a transcript ref names, in whichever W slot holds it."""
    kind, sep, rest = ref.partition(":")
    _, ref = parse_ref(ref if sep and kind == "transcript" else "transcript:" + ref)
    m = TRANSCRIPT_REF.match(ref)
    name, digest = m.group("name"), m.group("digest")
    files = week_transcript_files(hub)
    hits = [f[0] for f in files if os.path.basename(f[0]) == name and f[3] == digest]  # name and digest
    if hits:
        return hits[0]
    same = [f[0] for f in files if os.path.basename(f[0]) == name]
    if same:  # T40 c12: the file of the ref is missing; a file of that name may be it, edited, or another one
        raise Bad(f"the transcript {name}@sha256:{digest} is missing from W0..W5/transcripts/ (deleted, edited or retired);"
                  f" {', '.join(same)} has that name and another sha256: if it is the same transcript, edited, read it"
                  " again and record a new ref")
    raise Bad(f"the transcript {name}@sha256:{digest} is missing: no file {name} with that sha256 in W0..W5/transcripts/"
              " (a retired week leaves the hub; git history keeps it)")


def cmd_transcripts(g, a):
    pos, o = parse(a, {"--format": "one", "--files": "flag", "--find": "one"})
    if pos or ("files" in o) + ("find" in o) != 1:
        usage("transcripts --files [--format md|json|tsv] | transcripts --find NAME@sha256:HEX")
    if "find" in o:
        print(find_transcript(hub_dir(g), o["find"]))
        return
    print(render(week_transcript_files(hub_dir(g)), FILE_COLS, fmt_of(o, ("md", "json", "tsv"))))


def owner_person(c):
    """The hub owner's person key: meta owner_person (seed key "owner"), else the person `me`."""
    r = c.execute("SELECT value FROM meta WHERE key = 'owner_person'").fetchone()
    if r:
        return r[0]
    r = c.execute("SELECT key FROM person WHERE key = 'me'").fetchone()
    return r[0] if r else None


def untracked_asks(c):
    """An ask that waits on someone other than the owner is owned by the tracker: it needs an issue ref."""
    own = owner_person(c)
    out = []
    for r in c.execute("SELECT i.id, i.waits_on FROM item i WHERE i.kind = 'ask' AND i.status IN ('open','waiting')"
                       " AND i.waits_on IS NOT NULL AND (? IS NULL OR i.waits_on <> ?)"
                       " AND NOT EXISTS (SELECT 1 FROM item_ref x WHERE x.item_id = i.id AND x.kind = 'issue')"
                       " ORDER BY i.id", (own, own)):
        out.append(f"ask {r[0]} waits on {r[1]}, not the owner ({own or 'none set'}), and has no issue ref:"
                   f" the tracker owns an ask to another person; add `ref {r[0]} add issue:N`")
    return out


# ---- rotate ----

def rotate_plan(c, now, wk):
    lapse_before = ts_add(now, -LAPSE_DAYS * 86400)
    due = c.execute("SELECT id, renewed_at FROM item WHERE status IN ('open','waiting') AND kind <> 'summary'"
                    " AND renewed_at <= ? AND (parked_until IS NULL OR (CASE WHEN length(parked_until) = 10"
                    " THEN parked_until || 'T24:00:00Z' ELSE parked_until END) <= ?) ORDER BY id",
                    (lapse_before, now)).fetchall()
    # a summary row lapses by itself at the first rotation when it is LAPSE_DAYS old (no triage);
    # an escalated one stays for the human (the ledger guard), and so does one whose spec KB blocks
    lapse = [r[0] for r in c.execute("SELECT id FROM item WHERE status IN ('open','waiting') AND kind = 'summary'"
                                     " AND opened_at <= ? ORDER BY id", (lapse_before,)) if not is_escalated(c, r[0])]
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
    untriaged = [r[0] for r in due if not is_escalated(c, r[0])]
    escalated = [r[0] for r in c.execute("SELECT id FROM item WHERE status IN ('open','waiting') ORDER BY id") if is_escalated(c, r[0])]
    return untriaged, escalated, prune, sessions, lapse


def spec_archived(c, hub, ref):
    """T47 c3: the kb ref's spec KB was archived: it has no dir, and the newest spec-triage decision of
    its slug is archive (a human's `git rm -r specs/<slug>` first; history keeps it)."""
    if kb_outside(ref) or kb_dir(hub, ref) is not None:  # spec-triage archives only specs/<slug>
        return False
    r = c.execute("SELECT new FROM event WHERE verb = 'spec_triage' AND old = ? ORDER BY seq DESC LIMIT 1",
                  (ref.partition("/")[0],)).fetchone()
    return r is not None and r[0] == "archive"


def unarchived(c, hub, refs):
    """T48 c1: the kb refs of `refs` whose spec KB was not archived (spec_archived). agent_guard and triage
    read an archived spec KB as archived (clear), as rotate does; a missing dir that was never archived stays
    in the list, and kb_checks reads it as unknown (fail-safe)."""
    return [ref for ref in refs if not spec_archived(c, hub, ref)]


def kb_held_summaries(c, hub, lapse):
    """The summary rows of `lapse` with a kb ref whose spec KB is not clear (fail-safe, as for an
    agent's triage), or is clear only by a live human waiver (T47 c1): the rotation leaves them open.
    A kb ref whose spec KB was archived reads as archived, not as unknown (T47 c3). Runs orbit-kb
    (each query has its timeout); rotate --yes calls it inside its write, so the check and the lapse
    see the same clock (T40 c11)."""
    held = set()
    for iid in lapse:
        refs = [r[0] for r in c.execute("SELECT ref FROM item_ref WHERE item_id = ? AND kind = 'kb' ORDER BY ref", (iid,))
                if not spec_archived(c, hub, r[0])]  # archived: a human decision, not unknown
        if refs and any(k["state"] != "clear" for k in kb_checks(hub, refs)):  # summary guard
            held.add(iid)
        elif refs and live_waiver(kb_checks(hub, refs)):  # T47 c1: the waiver holds it for its time
            held.add(iid)
    return held


def triage_gate(untriaged, specs=()):
    """Refuse the rotation while a due item lacks a disposition (d_triage_per_item), or the spec KB
    of a closed ticket lacks a decision."""
    if untriaged:  # triage gate
        raise Bad(f"{len(untriaged)} due item(s) lack a disposition: {' '.join(untriaged)}; record one for each with"
                  " `hubflow.py triage ID keep|lapse|capsule|escalate --note T`, then rotate again")
    if specs:  # spec KB gate
        raise Bad(f"{len(specs)} spec KB(s) of closed tickets lack a decision: {' '.join(specs)}; record one for each with"
                  " `hubflow.py spec-triage SLUG archive|capsule|keep|escalate --note T`, then rotate again")


SPEC_DECISIONS = ("archive", "capsule", "keep", "escalate")


def kb_slug_items(c, slug, summaries=True):
    """The items whose kb ref is the spec KB slug (kb:<slug> or kb:<slug>/...): (id, status, closed_at).
    summaries=False leaves out summary rows (T40 c10: a summary never blocks a rotation)."""
    return c.execute("SELECT DISTINCT i.id, i.status, i.closed_at FROM item i JOIN item_ref r ON r.item_id = i.id"
                     " WHERE r.kind = 'kb' AND (r.ref = ? OR r.ref LIKE ?)" + ("" if summaries else " AND i.kind <> 'summary'")
                     + " ORDER BY i.id", (slug, slug + "/%")).fetchall()


def untriaged_spec_kbs(c, hub):
    """The spec KBs at specs/<slug> whose every referring item is closed and that have no recorded
    decision (a spec_triage event) since the last of them closed."""
    slugs = set()
    for (ref,) in c.execute("SELECT DISTINCT ref FROM item_ref WHERE kind = 'kb'"):
        if not kb_outside(ref):  # a KB outside the hub is not a spec KB of specs/
            slugs.add(ref.partition("/")[0])
    out = []
    for slug in sorted(slugs):
        if not os.path.isdir(os.path.join(hub, "specs", slug)):
            continue
        items = kb_slug_items(c, slug, summaries=False)  # a summary row is not a referring item
        if not items or any(st in OPEN for _, st, _ in items):
            continue
        last = max(x[2] for x in items)
        if c.execute("SELECT 1 FROM event WHERE verb = 'spec_triage' AND old = ? AND at >= ?", (slug, last)).fetchone() is None:
            out.append(slug)
    return out


def cmd_spec_triage(g, a):
    pos, o = parse(a, WOPT)
    if len(pos) != 2:
        usage("spec-triage SLUG archive|capsule|keep|escalate --note T")
    slug, dec = check_analysis(pos[0]), pos[1]
    if dec not in SPEC_DECISIONS:
        raise Bad(f"decision {dec!r} is not one of {', '.join(SPEC_DECISIONS)}")
    if not o.get("note"):
        raise Bad("spec-triage needs --note: why this decision")
    by, hub = writer_by(o, g), hub_dir(g)
    c = connect_ro(flow_dir(g))
    # a summary row is not an item of the ticket (T42 c1, as untriaged_spec_kbs): an open one never
    # keeps the decision out, so it never blocks a rotation (Ty q5)
    items = kb_slug_items(c, slug, False)  # summaries=False
    has_capsule = any(c.execute("SELECT 1 FROM capsule WHERE item_id = ?", (i[0],)).fetchone()
                      for i in kb_slug_items(c, slug))
    c.close()
    if not items:
        raise Bad(f"no item refers to kb:{slug}")
    opened = [i[0] for i in items if i[1] in OPEN]
    if opened:
        raise Bad(f"the ticket of kb:{slug} is not closed: {' '.join(opened)} is open")
    exists = os.path.isdir(os.path.join(hub, "specs", slug))
    if dec == "archive" and exists:
        raise Bad(f"run `git rm -r specs/{slug}` first (git history keeps it), then record archive")
    if dec != "archive" and not exists:
        raise Bad(f"no spec KB at specs/{slug}")
    if dec == "capsule" and not has_capsule:
        raise Bad(f"decision capsule needs a capsule on an item of kb:{slug} first: hubflow.py capsule ID --summary T")
    final, asked = dec, None
    if by != "human" and dec != "escalate" and exists:  # a spec KB that blocks is not the agent's to end
        if any(k["state"] != "clear" for k in kb_checks(hub, [slug])):
            final, asked = "escalate", dec
    note = o["note"] + (f" (the agent asked {asked}; the spec KB blocks)" if asked else "")

    def fn(c, w):
        w.event(None, "spec_triage", slug, final, note=note)

    run_write(g, o, fn)
    print(f"{slug} {final}" + (f" (asked {asked}): the spec KB blocks, so only a human decides it" if asked else ""))


def cmd_rotate(g, a):
    pos, o = parse(a, {**WOPT, "--week-start": "one", "--yes": "flag"})
    if pos or not o.get("week_start"):
        usage("rotate --week-start YYYY-MM-DD [--yes]")
    wk = parse_date(o["week_start"], "--week-start")
    if datetime.date.fromisoformat(wk).weekday() != 0:
        raise Bad(f"--week-start {wk} is not a Monday")

    def report(untriaged, escalated, prune, sessions, lapse, specs):
        print(f"week_start: {wk}")
        print("untriaged: " + (" ".join(untriaged) or "none"))
        print("lapsed: " + (" ".join(lapse) or "none"))
        print("spec_kbs_untriaged: " + (" ".join(specs) or "none"))
        print("escalated: " + (" ".join(escalated) or "none"))
        print("pruned: " + (" ".join(prune) or "none"))
        print("pruned_sessions: " + (" ".join(sessions) or "none"))
        sys.stdout.flush()

    c = connect_ro(flow_dir(g))
    if not o.get("yes"):
        plan = rotate_plan(c, clock(), wk)
        held = kb_held_summaries(c, hub_dir(g), plan[4])
        plan = plan[:4] + ([x for x in plan[4] if x not in held], untriaged_spec_kbs(c, hub_dir(g)))
        c.close()
        print("dry-run: nothing written (add --yes to apply)")
        report(*plan)
        triage_gate(plan[0], plan[5])
        return

    c.close()

    def fn(c, w):
        untriaged, escalated, prune, sessions, lapse = rotate_plan(c, w.now, wk)
        # T40 c11: the held check reads the clock of the write, inside it (no gap before the UPDATE)
        held = kb_held_summaries(c, hub_dir(g), lapse)  # inside the write
        lapse = [x for x in lapse if x not in held]
        specs = untriaged_spec_kbs(c, hub_dir(g))
        if untriaged or specs:
            report(untriaged, escalated, prune, sessions, lapse, specs)
        triage_gate(untriaged, specs)
        for iid in lapse:  # summary rows lapse by themselves
            it = get_item(c, iid)
            c.execute("UPDATE item SET status = 'lapsed', closed_at = ?, close_reason = ? WHERE id = ?",
                      (w.now, f"lapsed: summary, open {idle_days(w.now, it['opened_at'])} days", iid))
            w.event(iid, "lapsed", it["status"], "lapsed", note=None, by="script")
        for iid in prune:
            c.execute("DELETE FROM item WHERE id = ?", (iid,))
        c.execute("DELETE FROM event WHERE item_id IS NOT NULL AND item_id NOT IN (SELECT id FROM item)")
        for name in sessions:
            c.execute("DELETE FROM session_alias WHERE name = ?", (name,))
            c.execute("DELETE FROM session WHERE name = ?", (name,))
        return untriaged, escalated, prune, sessions, lapse, specs

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
    for t in TABLES:  # every table of this schema
        src[t] = read_jsonl(os.path.join(jsonl_dir(d), t + ".jsonl"))
        if src[t] is None:
            die(2, f"{t}.jsonl is missing in {jsonl_dir(d)}")
    c = sqlite3.connect(db_path(d), timeout=30, isolation_level=None)
    setup(c)
    try:
        c.execute("PRAGMA journal_mode=WAL")
        c.execute("BEGIN IMMEDIATE")
        create_schema(c)
        for t in live_tables(c):
            cols = [r[1] for r in c.execute(f"PRAGMA table_info({t})")]
            for row in src[t]:
                extra = sorted(set(row) - set(cols))
                if extra:  # unknown JSONL columns
                    die(2, f"{t}.jsonl has columns this schema does not know: {', '.join(extra)}; "
                           "rebuild with the script version that wrote it, then migrate")
                have = [k for k in cols if k in row]  # a column the row lacks takes its default (schema 7: no_kb 0)
                c.execute(f"INSERT INTO {t}({', '.join(have)}) VALUES({', '.join('?' * len(have))})",
                          tuple(row[k] for k in have))
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
    if start < 8 <= SCHEMA_VERSION and start >= 7:  # schema 8 (c39): a row that breaks the park/due rule stops the migration
        bad = c.execute(PARK_DUE_CONFLICTS).fetchall()
        if bad:
            c.close()
            raise Bad("schema 8 requires a park to end on or before the item's due date, and these items break that rule: "
                      + "; ".join(f"{r[0]} (parked until {r[1]}, due {r[2]})" for r in bad)
                      + ". Nothing was written. Fix each one with the hubflow of this hub (park it to an earlier date, or"
                      " set --due later or none), then run migrate again")
    c.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    bak = f"{p}.bak-v{start}"
    b = sqlite3.connect(bak)
    c.backup(b)
    b.close()
    c.execute("PRAGMA foreign_keys=OFF")  # a step may copy a table (schema 4); the check below stands in
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
        for t in DROPPED_TABLES:  # git keeps the old JSONL in history
            if os.path.exists(os.path.join(jsonl_dir(d), t + ".jsonl")):
                os.remove(os.path.join(jsonl_dir(d), t + ".jsonl"))
        c.execute("COMMIT")
    except BaseException:
        if c.in_transaction:
            c.execute("ROLLBACK")
        c.close()
        raise
    c.close()
    print(f"migrated schema {start} -> {SCHEMA_VERSION}; backup at {bak}")


def spec_kb_closed(c, slug):
    """kb-migrations c9 (guess a9): a spec KB is closed, so frozen, when items refer to it and each
    one is closed. A KB that no item names is open: it is checked, never skipped by a guess."""
    items = kb_slug_items(c, slug, summaries=False)
    return bool(items) and not any(st in OPEN for _, st, _ in items)


def cmd_kb_state(g, a):
    pos, _ = parse(a, {})
    if len(pos) != 1:
        usage("kb-state SLUG")
    slug = check_analysis(pos[0])
    c = connect_ro(flow_dir(g))
    closed = spec_kb_closed(c, slug)
    c.close()
    print("closed" if closed else "open")


MIG_KINDS = ("todo", "migrating", "retired", "error")


def hub_kb_dirs(hub):
    """The KBs of the hub (review a166): (label, slug, dir) for each spec KB at specs/<slug> (label
    kb:<slug>) and each KB of the form before 0.3.0 under W0..W5/analyses/<slug>/ at any depth (label
    kb:W<n>/analyses/..., slug <slug>). A dot directory (a shadow of migrate plan) is skipped."""
    out = []
    specs = os.path.join(hub, "specs")
    if os.path.isdir(specs):
        for d in sorted(os.listdir(specs)):
            if not d.startswith(".") and os.path.isfile(os.path.join(specs, d, "kb.pl")):
                out.append((f"kb:{d}", d, os.path.join(specs, d)))
    for n in range(6):
        an = os.path.join(hub, f"W{n}", "analyses")
        if not os.path.isdir(an):
            continue
        for b, dirs, files in os.walk(an):
            dirs[:] = sorted(x for x in dirs if not x.startswith("."))
            if "kb.pl" in files and b != an:
                out.append(("kb:" + os.path.relpath(b, hub).replace(os.sep, "/"),
                            os.path.relpath(b, an).replace(os.sep, "/").split("/")[0], b))
    return out


def cmd_migrations(g, a):
    parse(a, {})
    hub = hub_dir(g)
    kbs = hub_kb_dirs(hub)
    c = connect_ro(flow_dir(g))
    frozen = [lab for lab, slug, _ in kbs if spec_kb_closed(c, slug)]
    c.close()
    fail = False
    for label, slug, path in kbs:
        if label in frozen:
            continue
        try:
            p = subprocess.run(orbit_kb_cmd() + ["--dir", path, "migrate", "check"],
                               capture_output=True, text=True, timeout=ORBIT_KB_TIMEOUT)
            rc, out, err = p.returncode, p.stdout, p.stderr
        except (OSError, ValueError, subprocess.SubprocessError) as e:
            rc, out, err = 2, "", f"{e.__class__.__name__}: {e}"
        for line in out.splitlines():
            kind, _, rest = line.partition(" ")
            if kind in MIG_KINDS:
                print(f"{kind}: {label} {rest}")
        if rc == 1:
            fail = True
        elif rc != 0:
            fail = True
            print(f"unknown: {label} orbit-kb migrate check exited {rc}" + (f": {err.strip()[:200]}" if err.strip() else ""))
    if frozen:
        print(f"# frozen (closed tickets, not checked): {len(frozen)}")
    if fail:
        die(1, "a spec KB of an open ticket has a migration step to do (todo:) or could not be checked (unknown:);"
               " `orbit-kb --dir specs/SLUG migrate plan` shows it")


def cmd_check(g, a):
    parse(a, {})
    d = flow_dir(g)
    c = connect_rw(d)
    c.execute("BEGIN IMMEDIATE")  # one snapshot with the export
    problems = []
    if c.execute("PRAGMA foreign_key_check").fetchall():
        problems.append("a row points to a row that does not exist")
    problems += differences(c, d)
    problems += untracked_asks(c)
    c.execute("ROLLBACK")
    c.close()
    # T42 c6: the KB-to-hub direction of a waiver needs no one to remember a command
    due = [iid for iid, _, esc in skip_candidates(g) if not esc]
    if due:
        print("skip_waived: " + " ".join(due))
        print("# a human waiver in the spec KB clears each of them: run `hubflow.py skip-waived` to park them until its due time")
    if problems:
        die(3, "; ".join(problems))


COMMANDS = {"init": cmd_init, "add": cmd_add, "handoff": cmd_handoff, "accept": cmd_accept, "renew": cmd_renew,
            "park": cmd_park, "set": cmd_set, "close": cmd_close, "reopen": cmd_reopen, "ref": cmd_ref,
            "link": cmd_link, "note": cmd_note, "show": cmd_show, "view": cmd_view, "sql": cmd_sql,
            "session": cmd_session, "where": cmd_where, "spec-triage": cmd_spec_triage, "import": cmd_import, "rotate": cmd_rotate,
            "export": cmd_export, "rebuild": cmd_rebuild, "check": cmd_check, "migrate": cmd_migrate,
            "skip-waived": cmd_skip_waived, "migrations": cmd_migrations, "kb-state": cmd_kb_state,
            "triage": cmd_triage, "capsule": cmd_capsule, "transcripts": cmd_transcripts}


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

# Instructions for the agent: set up a hub with the hub kit

This is the hub kit, part of Sagittarius (<https://github.com/theTyster/sagittarius>): its informal
release. It needs Python 3, git and bash (`README.md`, "Install", lists the tools), and no formal
tools.

You are setting up a **hub**: a git repo that a few long-lived Claude Code sessions share as their
working memory. Read this whole file before you do anything. Do the steps in order. Each step ends
with a check; do not go on until it passes. Ask your human the questions in step 1 before you write
files.

## What the pattern is (read this to your human in your own words)

1. **The hub is a calendar.** `W0/` is this week, `W5/` five weeks back. Each Monday a rotation
   retires `W5` with `git rm`, renames the rest down one slot, and starts a new `W0`. Older weeks
   exist only in git history. So the hub never grows a permanent pile of stale context.
2. **Durable knowledge leaves the calendar.** Before something rolls off, ask "is it durable?" If yes,
   it goes into a root file that is always in context (`HEURISTICS.md`, `TECHNOLOGIES.md`,
   `CLAUDE.md`) or into a skill. Everything else is allowed to age out.
3. **The tracker owns tickets.** The hub keeps pointers to tickets (`issue:123`) and the flow state
   around them, never copies of ticket text.
4. **Flow state is relational, so it lives in SQLite.** Who an ask waits on, which session owns a
   thread, which handoffs are unaccepted, what has gone stale: rows in `flow/flow.db`, written only by
   `hubflow.py`. Views answer the common questions. An item with no renewal for 28 days is due: at
   the next rotation it gets a recorded decision (keep, lapse, capsule or escalate), never a silent
   lapse. Closed items are pruned five weeks after closing. Every write exports the tables to `flow/jsonl/`, which git
   tracks; the db file itself is ignored and can be rebuilt from the JSONL.
5. **A few named, long-lived sessions**, one per role (example: discovery, build, review, process, support),
   each in its own terminal pane, all with the hub as cwd. Each has an identity (`HUB_SESSION`) that
   the db records on every write. Sessions hand work to each other with a db row plus a message.
   How a named session is started is set up outside the hub (dotfiles, a shell alias): it belongs
   to one machine. The hub knows only the names, in `flow/seed.json`.
6. **No one grades their own work.** The `review` session verifies what another session made, and
   records its verdict as a note on the item (`HUB-CORE.md`, "Verify").
7. **The principles.** `PRINCIPLES.md` states the Sagittarius philosophy in plain words, and
   `CLAUDE.md` imports it. Read it to your human too.

This kit installs the **informal edition**: five stores (the flow ledger, the memory files, the
weeks, the bespoke tools, the tracker), and rules that name only those. `HUB-CORE.md` says where
each fact is kept. A formal edition exists for teams that use the formal tools of Sagittarius; it is
the last section of this file. Do not set it up unless your human asks for it.

## The kit

```
INSTRUCTIONS.md                 this file (a new hub)
UPGRADING.md                    what each release changes, and how to apply it to an existing hub
kit.json                        the template version, and which files are engine or owned
tools/hubkit.py                 install, status, upgrade (tests: tools/hubkit-test.py)
hub/                            the files of a new hub, at the paths they take in the hub:
  HUB-CORE.md, PRINCIPLES.md      the shipped rules and principles (engine: an upgrade replaces them)
                                  (the formal edition; editions/informal/ holds the informal files)
  CLAUDE.md, HEURISTICS.md, TECHNOLOGIES.md, W0/WEEK.md   owned by the hub from day one
  .claude/scripts/hubflow.py      the db tool (Python 3 stdlib only), and hubflow-test.py
  .claude/skills/hub-flow, hub-rotate   the two skills; a LOCAL.md next to SKILL.md holds local changes
  flow/seed.json                  sessions, aliases and people to seed
docs/index.html                 a one-page briefing for your human
```

**Engine and owned files.** Engine files ship with the template, and an upgrade replaces them.
Owned files belong to the hub, and an upgrade never changes them. So put local rules in `CLAUDE.md`
and in a skill's `LOCAL.md`, not in `HUB-CORE.md` or a shipped `SKILL.md`. `kit.json` lists which is
which.

## Step 1: brief your human, then ask (one round, at most three questions)

First ask your human to open `docs/index.html` in a browser. It explains the pattern, their part,
and what to say to you. Then ask:


1. Where should the hub live (a new directory; it becomes a git repo)? Default: `~/hub`.
2. Which sessions (one name per role), and which people do items wait on? Default: the five in
   `hub/flow/seed.json`, and one person `me` for your human.
3. Which tracker holds tickets (GitHub Issues, Jira, Linear, …)? It only changes wording in
   `CLAUDE.md`; refs are `issue:<digits>`, `pr:<digits>`, or `url:<url>`.

## Step 2: lay out the hub

```
HUB=<answer 1>; KIT=<this kit's directory>
mkdir -p "$HUB" && cd "$HUB" && git init
python3 "$KIT"/tools/hubkit.py install --hub "$HUB" --edition informal
```

Edit only owned files: `W0/WEEK.md` line 1 (this week's Monday → Sunday); the tracker and the
sessions in `CLAUDE.md`; `flow/seed.json`, with the session names (answer 2) and the people.

**Check:** `python3 "$KIT"/tools/hubkit.py status --hub "$HUB"` names the informal edition and lists
every engine file as `unchanged`; `CLAUDE.md` and `flow/seed.json` name the same sessions.

## Step 3: prove the db tool on this machine

```
python3 .claude/scripts/hubflow-test.py            # last line must be "N passed, 0 failed"
python3 .claude/scripts/hubflow-test.py --mutants  # every mutant must say KILLED
```

The tests run in temp dirs; they never touch `flow/`. If anything fails, stop and report the output
to your human. Do not edit a test to make it pass.

## Step 4: create the db

```
python3 .claude/scripts/hubflow.py init            # reads flow/seed.json
python3 .claude/scripts/hubflow.py check           # exit 0: db and JSONL agree
HUB_SESSION=<a role> python3 .claude/scripts/hubflow.py add ask --title "Setup smoke test" --waits-on me
python3 .claude/scripts/hubflow.py view v_inbox --session <that role>
python3 .claude/scripts/hubflow.py close A-0001 --reason dropped --session <that role> --note "smoke test"
```

**Check:** the item appeared in `v_inbox`; `add` without `HUB_SESSION` or `--session` exits 1;
`flow/jsonl/` holds one file per table.

If your human already keeps open asks or threads somewhere (a markdown list, notes), convert them
to the JSONL import format (`hubflow.py --help`, "import"), run `import FILE` (dry run, prints counts
and rejected rows), show your human the counts, and run `import FILE --yes` only after they agree.

## Step 5: sessions

The kit does not start sessions. Named sessions are set up outside the hub, in your human's
dotfiles or shell: they belong to one machine. Each session needs its hub cwd and its own
`HUB_SESSION=<name>` (a name from `flow/seed.json`). One way, in a terminal pane per role:

```
cd "$HUB" && HUB_SESSION=<name> claude --name "hub-<name>"
```

To resume a role's session later, resume it by the same name, with the same `HUB_SESSION`:

```
cd "$HUB" && HUB_SESSION=<name> claude --resume "hub-<name>"
```

Never resume with `claude --continue`: every role shares the hub as cwd, so `--continue` can pick
another role's conversation. A pane without `HUB_SESSION` can read the db, but every write fails.
A formal hub has more writes that need `HUB_SESSION`: see "The formal edition" below.

**Check:** in each role's pane, `echo "$HUB_SESSION"` prints that role's name, and
`python3 .claude/scripts/hubflow.py view v_inbox --session "$HUB_SESSION"` exits 0.

## Step 6: commit

Informal edition:

```
git add .gitignore .hub-template.json CLAUDE.md HUB-CORE.md PRINCIPLES.md HEURISTICS.md TECHNOLOGIES.md .claude flow/seed.json flow/jsonl W0
git commit -m "hub: initial layout and flow db"
```

Formal edition: the same, and the two stores of "The formal edition" below, `project-kb/` and `specs/`
(skip a store that does not exist yet; `git add` names no missing path):

```
git add .gitignore .hub-template.json CLAUDE.md HUB-CORE.md PRINCIPLES.md HEURISTICS.md TECHNOLOGIES.md .claude flow/seed.json flow/jsonl W0 project-kb specs
git commit -m "hub: initial layout and flow db"
```

**Check:** `git status` is clean, and `git ls-files flow` lists the JSONL but no `flow.db`. A KB's
`kb.lock` and `writer.lock` are ignored by the kit `.gitignore`.

## Step 7: report to your human

Say what you set up, each check's result, and what you did not check. Then tell them the routine:

- **Every session start, and after every compaction:** read `v_inbox` for that session.
- **When an agent waits on the human:** `add ask --waits-on me`. Ask the human what is waiting on
  them with `view v_waiting_on --person me`.
- **Passing work:** `handoff --to <role>`, then message that session with the id.
- **Each Monday:** "rotate the hub" (skill `hub-rotate`). The agent records a decision for each due
  item and escalates to the human what only the human can decide.
- **When a new template release is out:** "upgrade the hub to the new template", and give the
  agent `UPGRADING.md` from the new release.

## Known limits (tell your human)

- The db is new. It has a test suite with mutation checks, but little time in daily use yet.
- `rotate` requires `--week-start` to be a Monday, and an item is due at exactly 28 idle days.
- Do not add `kb` refs in the informal edition: hubflow counts an item with one as blocking, so an
  agent can never lapse it. On an escalated or blocking item, an agent's close, renew, park and
  `set --status` are refused too; a human does them with `--by human --note`. An agent can still
  pass `--by human` without a human's words, or edit the hub outside hubflow: the rule stops
  mistakes, not cheating.
- Nothing wakes an idle session by itself. A session sees db changes when it next reads the db, or
  when another session messages it.

## The formal edition

Only when your human asks for it. The formal edition adds two stores, written with Sagittarius's
`orbit-kb` (it needs SWI-Prolog): a **spec KB** per ticket at `specs/<slug>/`, and a **project
KB**: an orbit-kb KB with the `project` module, kept at the hub root as `project-kb/`. It records
domain decisions, pins of the world, and drafts for the tracker. Make it with
`orbit-kb init project-kb --request 'WHAT THE PROJECT IS' --uses project`. See `orbit-kb help project`.

- Install with `--edition formal` (the default when `orbit-kb` is on the PATH), or switch an
  informal hub with `python3 "$KIT"/tools/hubkit.py edition --hub "$HUB" formal --yes`. The switch
  replaces the shipped rules and skills; `CLAUDE.md` is the hub's own, so add its "Repos and the
  project KB" section by hand (copy it from `hub/CLAUDE.md`).
- `orbit-kb pin-item` and `orbit-kb draft` record a dropped edit of the project KB in the ledger by
  themselves, in the session of `HUB_SESSION` (or `--session S`). A pane gets `HUB_SESSION` where it
  is started (Step 5: `cd "$HUB" && HUB_SESSION=<name> claude --name "hub-<name>"`). In a pane
  without it, the ledger refuses the record: orbit-kb warns, names `project dropped --session S`, and
  exits 0, so the dropped edit is not in the ledger until someone runs that command.
- Escalation asks `orbit-kb` (or `HUBFLOW_ORBIT_KB`) whether a spec KB blocks. If the query fails,
  or `orbit-kb` is missing, an item with a `kb` ref counts as blocking (fail-safe).

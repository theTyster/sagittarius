# Instructions for the agent: set up a hub with a flow-state db

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
   `hubflow.py`. Views answer the common questions. Items lapse after 28 days without a renewal and
   are pruned five weeks after closing. Every write exports the tables to `flow/jsonl/`, which git
   tracks; the db file itself is ignored and can be rebuilt from the JSONL.
5. **A few named, long-lived sessions**, one per role (example: discovery, build, process, support),
   each in its own terminal pane, all with the hub as cwd. Each has an identity (`HUB_SESSION`) that
   the db records on every write. Sessions hand work to each other with a db row plus a message.

## The kit

```
INSTRUCTIONS.md                 this file (a new hub)
UPGRADING.md                    what each release changes, and how to apply it to an existing hub
kit.json                        the template version, and which files are engine or owned
tools/hubkit.py                 install, status, upgrade (tests: tools/hubkit-test.py)
hub/                            the files of a new hub, at the paths they take in the hub:
  HUB-CORE.md                     the shipped rules (engine: an upgrade replaces it)
  CLAUDE.md, HEURISTICS.md, TECHNOLOGIES.md, W0/WEEK.md   owned by the hub from day one
  .claude/scripts/hubflow.py      the db tool (Python 3 stdlib only), and hubflow-test.py
  .claude/skills/hub-flow, hub-rotate   the two skills; a LOCAL.md next to SKILL.md holds local changes
  sessions/launch.sh, ROLES       start or resume a role session by name
  flow/seed.json                  sessions, aliases and people to seed
docs/index.html                 a one-page briefing for your human (also published as the repo's site)
```

**Engine and owned files.** Engine files ship with the template, and an upgrade replaces them.
Owned files belong to the hub, and an upgrade never changes them. So put local rules in `CLAUDE.md`
and in a skill's `LOCAL.md`, not in `HUB-CORE.md` or a shipped `SKILL.md`. `kit.json` lists which is
which.

## Step 1: brief your human, then ask (one round, at most three questions)

First ask your human to open `docs/index.html` in a browser. It explains the pattern, their part,
and what to say to you. Then ask:


1. Where should the hub live (a new directory; it becomes a git repo)? Default: `~/hub`.
2. Which sessions (roles), and which people do items wait on? Default: the four in
   `hub/flow/seed.json`, and one person `me` for your human.
3. Which tracker holds tickets (GitHub Issues, Jira, Linear, …)? It only changes wording in
   `CLAUDE.md`; refs are `issue:<digits>`, `pr:<digits>`, or `url:<url>`.

## Step 2: lay out the hub

```
HUB=<answer 1>; KIT=<this kit's directory>
mkdir -p "$HUB" && cd "$HUB" && git init
python3 "$KIT"/tools/hubkit.py install --hub "$HUB"
```

Edit only owned files: `W0/WEEK.md` line 1 (this week's Monday → Sunday); the tracker and the
sessions in `CLAUDE.md`; `sessions/ROLES` (answer 2); `flow/seed.json`, with the same session names
and the people.

**Check:** `python3 "$KIT"/tools/hubkit.py status --hub "$HUB"` lists every engine file as
`unchanged`; `sessions/ROLES` and `flow/seed.json` name the same sessions.

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

For each role: `sessions/launch.sh <role> --dry-run` prints the command it would run. Then run
`sessions/launch.sh <role>` in its own terminal pane (tmux, a terminal tab, anything). It resumes the
session with that name, or creates it, and exports `HUB_SESSION`. Never start a role session with
`claude --continue`: every role shares the hub as cwd, so `--continue` can pick another role's
conversation.

Optional per role: `sessions/<role>/prompt.md` (appended to the system prompt on every launch; say
what the role owns, what it does not own, and which other session gets what) and
`sessions/<role>/settings.json`. Write these with your human; they are the part most worth tuning.

If you script the panes (tmux or other), have each pane either call `launch.sh <role>` or export
`HUB_SESSION=<role>` itself. A pane without it can read the db but every write fails.

**Check:** each role's dry run prints a command with its own `HUB_SESSION`.

## Step 6: commit

```
git add .gitignore .hub-template.json CLAUDE.md HUB-CORE.md HEURISTICS.md TECHNOLOGIES.md .claude sessions flow/seed.json flow/jsonl W0
git commit -m "hub: initial layout, flow db, sessions"
```

**Check:** `git status` is clean, and `git ls-files flow` lists the JSONL but no `flow.db`.

## Step 7: report to your human

Say what you set up, each check's result, and what you did not check. Then tell them the routine:

- **Every session start, and after every compaction:** read `v_inbox` for that session.
- **When an agent waits on the human:** `add ask --waits-on me`. Ask the human what is waiting on
  them with `view v_waiting_on --person me`.
- **Passing work:** `handoff --to <role>`, then message that session with the id.
- **Each Monday:** "rotate the hub" (skill `hub-rotate`). The db lapses what nobody renewed.
- **When a new template release is out:** "upgrade the hub to the new template", and give the
  agent `UPGRADING.md` from the new release.

## Known limits (tell your human)

- The db is new. It has a test suite with mutation checks, but little time in daily use yet.
- `rotate` requires `--week-start` to be a Monday, and lapse at exactly 28 idle days is inclusive.
- Nothing wakes an idle session by itself. A session sees db changes when it next reads the db, or
  when another session messages it.
- `launch.sh` needs bash 4+ and `jq` (on macOS: `brew install bash jq`).

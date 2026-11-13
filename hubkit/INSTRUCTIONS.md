# Instructions for the agent: set up a MindHole with the MindHole Kit

This is the MindHole Kit, the template that makes a hub (a MindHole) for Sagittarius. It is part of Sagittarius
(<https://github.com/theTyster/sagittarius>): its informal release. It needs Python 3 and git
(`README.md`, "Install"): no bash, and no formal tools.

You are setting up a **hub**: a git repo that a few long-lived Claude Code sessions share as their
working memory. Read this whole file before you do anything. Do the steps in order. Each step ends
with a check; do not go on until it passes. Ask your human the questions in step 1 before you write
files. Step 3 is for a UAT install only; a normal install skips it.

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
7. **The principles.** `PRINCIPLES.md` comes from the Sagittarius prompt, in plain words: each
   part names the section of the prompt it comes from. `CLAUDE.md` imports it. Read it to your
   human too.

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

## Step 1: brief your human, then ask (one round, the cold-start allowance)

First ask your human to open `docs/index.html` in a browser. It explains the pattern, their part,
and what to say to you. Then ask, in one round. Setup is the one place where you may ask more than
three questions at once: a cold-start allowance, for this step only.

1. What is this hub for? Ask it first, and keep the answer word for word: it goes into `CLAUDE.md`
   (step 2), which every session loads, so no agent has to guess what the hub is for. Do not
   paraphrase it, and do not suggest an answer before your human gives one.
2. Where should the hub live (a new directory; it becomes a git repo)? Default: `~/hub`.
3. Which sessions (one name per role), and which people do items wait on? Default: the five in
   `hub/flow/seed.json`, and one person `me` for your human.
4. Which tracker holds tickets (GitHub Issues, Jira, Linear, …)? It only changes wording in
   `CLAUDE.md`; refs are `issue:<digits>`, `pr:<digits>`, or `url:<url>`.
5. Is this a UAT install: one that tests the kit itself, before a release? Default: no.

## Step 2: lay out the hub

`HUB` is answer 2, and `KIT` is this kit's directory. Each line is one `git` or `python3` command,
so any shell runs it; add `--uat` to the install line when answer 5 is yes:

```
git init "$HUB"
python3 "$KIT/tools/hubkit.py" install --hub "$HUB" --edition informal
```

The later steps run from the hub root: change into `$HUB` first.

Edit only owned files: in `CLAUDE.md`, put answer 1, word for word, under `## What this hub is for`
(replace the placeholder; no paraphrase), then the tracker and the sessions; `W0/WEEK.md` line 1
(this week's Monday → Sunday); `flow/seed.json`, with the session names (answer 3) and the people.

**Check:** `python3 "$KIT/tools/hubkit.py" status --hub "$HUB"` names the informal edition (and
`UAT install` if you added `--uat`) and lists every engine file as `unchanged`; `CLAUDE.md` holds
answer 1 word for word; `CLAUDE.md` and `flow/seed.json` name the same sessions.

## Step 3: UAT installs only: test the kit

A normal install skips this step: go to step 4. These tests test the kit itself, not your hub: they
run the db tool in temp dirs and never read the hub, and the mutants check that the tests can catch a
broken tool. A user cannot act on their result; the kit's maintainers can. So they run only when your
human said yes to question 5 (a UAT install, which tests the kit before a release):

```
python3 .claude/scripts/hubflow-test.py            # about a minute or two
python3 .claude/scripts/hubflow-test.py --mutants  # every mutant must say KILLED
```

The last line of the plain suite says how many checks passed, failed and skipped. In a formal hub it
must be "N passed, 0 failed, 3 skipped". The 3 SKIP lines say "not run from the kit tree
(hubkit/hub)": `t40-c12-skill-summary-is-no-decision`, `t40-c12-hub-core-raw-reports-agent-reads`
and `t42-c6-skill-says-when-to-run-skip-waived` read files of the kit tree that a hub does not have.
In an informal hub more checks skip: the ones that need the formal tools (their SKIP line names
the missing tool), and the one that says "the informal edition has no kb refs". Any other SKIP, and
any FAIL, is a defect of the kit.

`--mutants` runs the whole suite once for each mutant: it takes an hour or more on a loaded machine.
It prints one line per mutant as each one ends (`PASS mutant NAME: KILLED`), so a log that grows
shows progress. They never touch `flow/`. A failure, or a mutant that says SURVIVED, is a defect of the kit, not of
the hub: stop, and report the output to your human for the kit's maintainers. Do not edit a test to
make it pass.

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
`HUB_SESSION=<name>` (a name from `flow/seed.json`). One way, in a terminal pane per role, is this
launcher line:

```
cd "$HUB" && HUB_SESSION=<name> claude --name "hub-<name>"
```

To resume a role's session later, run the same line with `--resume "hub-<name>"` in place of
`--name "hub-<name>"`: the same name, the same `HUB_SESSION`.

Never resume with `claude --continue`: every role shares the hub as cwd, so `--continue` can pick
another role's conversation. A pane without `HUB_SESSION` can read the db, but every write fails.
A formal hub has more writes that need `HUB_SESSION`: see "The formal edition" below.

**Check:** in each role's pane, `echo "$HUB_SESSION"` prints that role's name, and
`python3 .claude/scripts/hubflow.py view v_inbox --session "$HUB_SESSION"` exits 0.

## Step 6: formal edition only: the formal stores

An informal hub skips this step: go to step 7. A formal hub (installed with `--edition formal`)
makes its project store now, before the commit: do the part "Step 6 (formal)" of "The formal
edition" below.

**Check:** `project-kb/kb.pl` exists, and `git status` lists `project-kb/`.

## Step 7: commit

First check that git knows who commits. Run `git config user.name` and `git config user.email` in
the hub. If either is empty (prints nothing), the commit fails ("Author identity unknown"): ask your human for
their name and email, and set them with `git config user.name "<name>"` and
`git config user.email "<email>"` (in the hub only; do not change their global git config unless they
ask).

Informal edition:

```
git add .gitignore .hub-template.json CLAUDE.md HUB-CORE.md PRINCIPLES.md HEURISTICS.md TECHNOLOGIES.md .claude flow/seed.json flow/jsonl W0
git commit -m "hub: initial layout and flow db"
```

Formal edition: the same, and the two stores of "The formal edition" below, `project-kb/` (made in
step 6) and `specs/` (skip a store that does not exist yet; `git add` names no missing path):

```
git add .gitignore .hub-template.json CLAUDE.md HUB-CORE.md PRINCIPLES.md HEURISTICS.md TECHNOLOGIES.md .claude flow/seed.json flow/jsonl W0 project-kb specs
git commit -m "hub: initial layout and flow db"
```

**Check:** `git status` is clean, and `git ls-files flow` lists the JSONL but no `flow.db`. A KB's
`kb.lock` and `writer.lock` are ignored by the kit `.gitignore`.

## Step 8: check the hub, then report to your human

The install ends with two checks that read this hub. Run them from the hub root, and give your
human the reason for each with its result:

```
python3 "$KIT/tools/hubkit.py" status --hub "$HUB"
python3 .claude/scripts/hubflow.py check
```

- `hubkit.py status` shows you that each shipped file of the hub is the kit's own (`unchanged`), so
  the hub follows the hub spec of this release.
- `hubflow.py check` shows you that the ledger (`flow/flow.db`) and its git copy (`flow/jsonl/`) agree,
  so nothing written to the ledger is lost at the next commit.

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

- The db is new. It has a test suite with mutation checks (step 3 runs them in a UAT install), but
  little time in daily use yet.
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
domain decisions, pins of the world, and drafts for the tracker.

- **The hub's own orbit-kb.** A formal install copies the orbit-kb that this kit was tested with
  (`kb/bin/orbit-kb`, `kb/bin/repo-map` and `kb/share` of the Sagittarius checkout, about 0.7 MB) into
  the hub at `.claude/orbit-kb/`, as engine files: an upgrade replaces them. Run it from the hub root as
  `.claude/orbit-kb/bin/orbit-kb`, never as a bare `orbit-kb`: the one on the PATH may be another
  version. `hubflow.py` and the skills run the copy too. It needs SWI-Prolog. Limits:
  `ORBIT_KB_LIB` in the environment overrides the copy's `share/`, and `orbit-kb prove` still needs
  `lake` from the PATH.
- **Step 6 (formal): make the project KB.** The project KB request is what the hub is for. From
  the hub root, run
  `.claude/orbit-kb/bin/orbit-kb init project-kb --request '<answer 1 of step 1, word for word>' --uses project`:
  the same words as `CLAUDE.md` "What this hub is for". See `.claude/orbit-kb/bin/orbit-kb help project`.
- **A pane gets the prompt.** The panes (review, discovery, build) run the Sagittarius prompt, then
  `PANES.md`, then their role file, as the Sagittarius `README.md` installs them under
  `~/.claude/sagittarius/` (its "Panes" gives this same line). Start a pane with this one launcher
  line in place of the line of Step 5 (`<name>` is the role; the line sets `HUB_SESSION` too):

  ```
  cd "$HUB" && p=~/.claude/sagittarius && HUB_SESSION=<name> command claude --name "hub-<name>" --append-system-prompt "$(cat "$p/SAGITTARIUS.md" "$p/PANES.md" "$p/panes/<name>.md")"
  ```

  To resume a pane, run the same line with `--resume "hub-<name>"` in place of `--name "hub-<name>"`.

  `command claude` skips a shell function `claude` that already appends the prompt (the
  Sagittarius `README.md`, "Install"), so the prompt is appended once. A session whose role has no
  pane file (for example `process`) uses the line of Step 5. **Check:** ask each pane for the last
  line of its prompt. It must say the last line of `~/.claude/sagittarius/SAGITTARIUS.md`
  (`This is Sagittarius <version> ...`); a pane that cannot say it did not get the prompt.
- **What the hub runs.** Each MindHole runs its own pinned version. `.hub-template.json` records
  (`runs`) the orbit-kb copy and its version, the prompt that the launcher appends
  (`~/.claude/sagittarius/SAGITTARIUS.md`, with its Sagittarius version) and the pane files, as this
  kit's Sagittarius checkout holds them; an upgrade records them again. `hubkit.py status` prints
  them in its `runs` lines and says whether the files under `~/.claude/sagittarius/` are still the
  same. **Check:** the `runs prompt:` line says `the file there: same`; if not, the panes run
  another prompt than the one this hub was set up with: tell your human.
- Install with `--edition formal` (only when your human asks for it; which `orbit-kb` is on the
  PATH plays no part: with no `--edition`, install picks informal), or switch an informal hub with
  `python3 "$KIT/tools/hubkit.py" edition --hub "$HUB" formal --yes`. The switch replaces the shipped
  rules and skills and adds the orbit-kb copy; `CLAUDE.md` is the hub's own, so add its "Repos and the
  project KB" section by hand (copy it from `hub/CLAUDE.md`).
- `.claude/orbit-kb/bin/orbit-kb pin-item` and `.claude/orbit-kb/bin/orbit-kb draft` record a dropped edit of the project KB in the ledger by
  themselves, in the session of `HUB_SESSION` (or `--session S`). A pane gets `HUB_SESSION` where it
  is started (Step 5, or the launcher line above: each sets it). In a pane
  without it, the ledger refuses the record: orbit-kb warns, names `project dropped --session S`, and
  exits 0, so the dropped edit is not in the ledger until someone runs that command.
- Escalation asks the hub's own orbit-kb (or `HUBFLOW_ORBIT_KB`) whether a spec KB blocks. If the
  query fails, or the copy is missing and no `orbit-kb` is on the PATH, an item with a `kb` ref counts
  as blocking (fail-safe).

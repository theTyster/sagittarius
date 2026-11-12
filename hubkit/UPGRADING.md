# UPGRADING.md: apply a new release of the MindHole to an existing hub

For the agent. Your human asked you to upgrade their hub to a newer release of the MindHole, the
kit that made it. Read this whole file first. A hub belongs to its people: never replace a file the
hub changed, and show your human every merge before you commit.

**Versions.** This release of the MindHole pairs with Sagittarius 0.3: its `PRINCIPLES.md` comes
from that prompt, and a formal hub copies the orbit-kb of the same Sagittarius checkout. The
MindHole's own version is `MindHole <version>` (`kit.json`); a release section says so when the
Sagittarius pair changes. Older sections below say "hub kit": the MindHole's name before 2026-11-12.

## The procedure (every release)

`KIT` is a checkout of the new release; `HUB` is the hub.

1. **Pre-flight.** `git -C "$HUB" status` is clean, or the dirty files belong to a session that is
   still working: stop and ask. Every session that writes the hub is idle.
2. **Read the plan.** `python3 "$KIT"/tools/hubkit.py upgrade --hub "$HUB"` (a dry run). Read every
   release section below between the hub's version (`.hub-template.json`) and the kit's version.
3. **Apply.** `python3 "$KIT"/tools/hubkit.py upgrade --hub "$HUB" --yes`. It replaces the engine
   files the hub did not change, adds new files, and lists each changed engine file as `pending`.
4. **Merge each pending file by intent.** For each one, find the release section that names it.
   Apply that change's *intent* to the hub's version of the file, and keep the hub's own edits.
   The kit has no release tags: `git -C "$KIT" log -p -- hub/<path>` (or `editions/informal/<path>`
   for a file of the informal edition) shows the commits that changed the file; read the ones after
   the hub's version, with the release section that names the change. When you are
   done with a file: `python3 "$KIT"/tools/hubkit.py done --hub "$HUB" <path>`.
5. **Owned files.** The release sections say when an owned file (`CLAUDE.md`, `.gitignore`, …) needs
   a change. Make it by intent; an upgrade never writes these.
6. **Database.** If a section says the schema changed: `python3 .claude/scripts/hubflow.py migrate`,
   then `hubflow.py check`.
7. **Checks.** In the hub, run each check that the release sections name. Then end with two checks
   that read this hub, and give your human the reason for each with its result:
   `python3 "$KIT"/tools/hubkit.py status --hub "$HUB"` shows you that each shipped file is the
   release's own (`unchanged`) or merged by intent (`modified`), and that no merge is still pending
   (no `pending` line).
   `python3 .claude/scripts/hubflow.py check` (exit 0) shows you that the ledger and its git copy
   agree, so nothing written to the ledger is lost at the commit. A normal upgrade skips the test
   suites: they test the kit itself, not your hub. Only a UAT upgrade (a hub whose
   `.hub-template.json` records `"uat": true`; `hubkit.py status` says `UAT install`) also runs
   `python3 .claude/scripts/hubflow-test.py` and `hubflow-test.py --mutants` (every mutant KILLED),
   as step 3 of `INSTRUCTIONS.md` does for a UAT install. In a formal hub the last line of the plain
   suite is "N passed, 0 failed, 3 skipped": the 3 SKIP lines say "not run from the kit tree
   (hubkit/hub)" (`t40-c12-skill-summary-is-no-decision`, `t40-c12-hub-core-raw-reports-agent-reads`,
   `t42-c6-skill-says-when-to-run-skip-waived`). `--mutants` takes an hour or more on a loaded
   machine; it prints one line per mutant as each one ends.
8. **Report and commit.** Show your human the diff of each merged and owned file, and the checks.
   Commit after they agree: `git commit -m "template <old> -> <new>" -- <paths>`.

If a check fails, or a merge has no clear answer, stop and ask your human. Do not edit a test to
make it pass.

## A hub made before the manifest

A hub set up from a kit with no `.hub-template.json` (the first starter kit): compare its files
with this release's `hub/` by hand, move each local rule from the shipped files into `CLAUDE.md` or a
skill's `LOCAL.md`, then copy the release's engine files and run
`python3 "$KIT"/tools/hubkit.py install --hub <an empty dir>` to get a manifest to copy in. Ask your
human before you start; this is a one-time merge.

## Release sections

Each section gives, per change: the intent in one sentence, the files, the steps for a hub that
changed those files, and a check.

### 0.7.0 (Sagittarius 0.3.0 alignment; db schema 6: the session index is dropped)

The db schema is 6. **Database:** every hub at schema 5 (0.5.1 to 0.6.0) runs
`python3 .claude/scripts/hubflow.py migrate` once, then `hubflow.py check`. Owned file `CLAUDE.md`:
it still imports the principles (`@PRINCIPLES.md` below `@HUB-CORE.md`, see 0.4.0).

- **The session index is dropped (db schema 6).** Intent: the hub keeps no index of Claude Code
  session logs. The human cut the feature on 2026-11-12 ("I want to cut this feature. 'drop it'"):
  it came from a misunderstanding, since the transcripts that matter are meeting transcripts. Gone:
  `hubflow.py index-transcripts`, `transcripts` with no flag and `transcripts --detail`, the tables
  `transcript` and `transcript_msg` with their JSONL, and the re-index of `rotate --yes` (no
  `transcripts_reindexed:` line). Kept: meeting transcripts in `W*/transcripts/`, the `transcript:`
  ref, `transcripts --files` and `--find`, the `summary` item kind, capsules. The schema 5 -> 6 step
  of `migrate` drops the two tables and removes `flow/jsonl/transcript.jsonl` and
  `transcript_msg.jsonl` (git history keeps them; commit the removal). Files:
  `.claude/scripts/hubflow.py`, `.claude/scripts/hubflow-test.py`, `HUB-CORE.md` ("What lives
  where", the weeks row; "What a week holds"), `.claude/skills/hub-flow/SKILL.md` ("Read",
  "Transcripts"), `.claude/skills/hub-rotate/SKILL.md` (step 5). A hub script or `LOCAL.md` that runs
  `index-transcripts` or reads `transcripts_reindexed:`: drop that step. Check: after `migrate`,
  `hubflow.py check` exits 0, and `ls flow/jsonl/transcript*.jsonl` finds nothing.

### 0.6.0 (the install experience: what the hub is for, its own orbit-kb, no shell; db schema stays 5)

The human accepted the version 0.6.0 (the build had chosen it, above 0.5.2). The db schema is 5, as in 0.5.1:
no `hubflow.py migrate` is needed. Engine files changed: `.claude/scripts/hubflow.py`,
`hubflow-test.py`, both `SKILL.md`, `HUB-CORE.md`; the two rotation scripts are new Python files and
the shell scripts are dropped. Replace each engine file the hub did not change; merge the others by
intent. Owned file `CLAUDE.md`: add one section by hand (below); it still imports the principles
(`@PRINCIPLES.md` below `@HUB-CORE.md`, see 0.4.0).

- **Setup asks what the hub is for, and keeps the answer (install UX c1).** Intent: every session
  loads, in the human's own words, what the hub is for; agents do not guess it. Owned file
  `CLAUDE.md`: add the section `## What this hub is for` right below the `@` imports, and ask your
  human for its text (one or two sentences, kept word for word). In a formal hub the project KB
  request says the same; do not rewrite an existing request. Check: `CLAUDE.md` has the section, in
  the human's words.
- **A formal hub runs its own orbit-kb (install UX c3).** Intent: a formal hub runs the orbit-kb that
  its kit was tested with, whatever `orbit-kb` is on the PATH. The upgrade adds
  `.claude/orbit-kb/bin/orbit-kb`, `bin/repo-map` and `share/` (about 0.7 MB) as engine files of a formal hub
  (`add` in the plan); a later upgrade replaces them. `hubflow.py` asks that copy (`HUBFLOW_ORBIT_KB` still
  overrides it), and `HUB-CORE.md` and the skills name it (`.claude/orbit-kb/bin/orbit-kb help project`).
  Limits: `ORBIT_KB_LIB` in the environment overrides the copy's `share/`; `orbit-kb prove` still needs
  `lake` from the PATH. `install` with no `--edition` now picks informal: the human chooses formal; the
  PATH plays no part (a hub with no edition in `.hub-template.json` still gets formal when orbit-kb is on
  the PATH). Check: `.claude/orbit-kb/bin/orbit-kb --dir project-kb lint` ends `0 error(s)`, and
  `python3 .claude/scripts/hubflow-test.py` shows no `SKIP` other than the 3 that say "not run from the
  kit tree" (step 7 of the procedure above names them).
- **No engine file is a shell script (install UX c4).** Intent: the hub runs on Python 3 and git, with
  no bash. `rotate.sh` and `check-citations.sh` are now `rotate.py` and `check-citations.py`, with the
  same refusals, renames, reports and exit codes. The plan shows `remove` for the two `.sh` files and
  `add` for the two `.py` files; a hub that changed a `.sh` file gets a `merge`: port its change to the
  `.py` file. A `LOCAL.md` of `hub-rotate` that names `rotate.sh` or `check-citations.sh`: rename to
  the `.py` file. Check: `python3 .claude/skills/hub-rotate/scripts/rotate.py --dry-run` exits 0 on a
  clean hub.
- **A normal install runs no test suite (install UX c6).** Intent: the install-time tests test the kit,
  not the hub, so only a UAT install (one that tests the kit) runs them; a normal install ends with
  `hubkit.py status` and `hubflow.py check`. `hubkit.py install --uat` records a UAT install in
  `.hub-template.json`, and `status` shows it. No hub file changes; this is in `INSTRUCTIONS.md` and
  `README.md` only. The upgrade procedure above still runs the suite: an upgrade changes the engine.

### 0.5.2 (hub kit fixes from the first formal-edition install; db schema stays 5)

The db schema is 5, as in 0.5.1: no `hubflow.py migrate` is needed. `.claude/scripts/hubflow-test.py`
is an engine file: replace it if the hub did not change it, else merge by intent. `INSTRUCTIONS.md` is
not in the hub; the changes to it are for whoever sets up a hub. Owned file `.gitignore`: add the two
lines below by hand (an upgrade never writes an owned file). Owned file `CLAUDE.md`: no change in 0.5.2; it still
imports the principles (`@PRINCIPLES.md` below `@HUB-CORE.md`, see 0.4.0).

- **The hub's tests find `orbit-kb` on PATH (T51 c1).** Intent: `hubflow-test.py` ran its real-orbit-kb
  cases only beside the kit tree, so in an installed formal hub they skipped, the suite said
  `N passed, 0 failed`, and waiver mutants survived. Now it looks at `$HUBFLOW_TEST_ORBIT_KB`, the kit
  tree, then `orbit-kb` on PATH. In a formal hub (a `.hub-template.json` that does not record the informal
  edition) a skipped real-orbit-kb case is a failure, and the last line counts skips (`N passed, M failed,
  K skipped`). An informal hub still skips them. Files: `.claude/scripts/hubflow-test.py`. Check: in the
  hub, `python3 .claude/scripts/hubflow-test.py` shows no `SKIP` of a real-orbit-kb case and exits 0.
- **Lock files are not committed (T51 c3).** Intent: ignore the lock files of orbit-kb KBs. Owned file
  `.gitignore`: add the lines `kb.lock` and `writer.lock`. Check: `git check-ignore project-kb/writer.lock`
  exits 0.
- **Step 6 commits the stores of the formal edition (T51 c2).** Intent: a formal hub's first commit includes
  `project-kb/` and `specs/`. No hub file changes; this is in `INSTRUCTIONS.md` only.

### 0.5.1 (db schema 5: a waiver holds an item for the human)

The db schema is 5. **Database:** every hub at schema 4 (0.5.0, or 0.4.0 after the transcripts
change) runs `python3 .claude/scripts/hubflow.py migrate` once, then `check` (T47 c2: the step to 5
remakes `v_stale` and `v_retention_due`). A hub at schema 2 or 3 also follows the 0.5.0 section first.
The kit version moves with the db schema (T48 c3): a hub that needs `migrate` sees a version change
in the dry run (`upgrade 0.5.0 -> 0.5.1`). `.claude/scripts/hubflow.py`, `hubflow-test.py` and
`.claude/skills/hub-flow/SKILL.md` are engine files: replace each that the hub did not change, and
merge the others by intent (`git -C "$KIT" diff`).
Owned file `CLAUDE.md`: no change in 0.5.1; it still imports the principles (`@PRINCIPLES.md` below
`@HUB-CORE.md`, see 0.4.0). A hub that skipped 0.5.0 reads that section too.

- **A park by `skip-waived` ends at the waiver's due time (T47 c2).** Intent: `parked_until` holds the
  due time, not its date, so the item comes back when the waiver ends, not at the end of that day.
  Files: `.claude/scripts/hubflow.py` (schema 5). Check: after `migrate`, `hubflow.py check` exits 0.
- **A live waiver holds an item for the human (T47 c1, T48 c4).** Intent: an agent cannot end, for
  good, an item whose spec KB is clear only by a live human waiver: its `close`, `set --status` and
  `ref rm` of the kb ref are refused with a line that names the waiver, and its `triage lapse` becomes
  escalate with a line that names the waiver; it may still keep or park such an item. Files:
  `.claude/scripts/hubflow.py`, `.claude/skills/hub-flow/SKILL.md` (the skip-waived paragraph).
  Check: `hubflow-test.py` passes (the t47-c1 and t48-c4 checks).
- **An archived spec KB reads as archived (T47 c3, T48 c1).** Intent: a kb ref whose `specs/<slug>` is
  gone and whose newest `spec-triage` decision is archive reads as archived (clear) in `rotate`,
  `triage` and the agent guard, so its summary lapses at 28 days; a missing dir that was never
  archived still counts as blocking. Files: `.claude/scripts/hubflow.py`. Check: `hubflow-test.py`
  passes (the t47-c3 and t48-c1 checks).

### 0.5.0 (the informal edition: one rule set, one engine voice)

The db schema is 4, as in 0.4.0. **Database:** a hub made at 0.4.0 before the transcripts change has
schema 2 or 3 (`hubflow.py check` exits 2): run `python3 .claude/scripts/hubflow.py migrate`, then
`check`, and read the 0.4.0 entry "An agent, not code, puts meeting transcripts into the ledger".
A hub already at schema 4 has nothing to migrate for 0.5.0 (0.5.1 moves it to schema 5).
`HUB-CORE.md`, `PRINCIPLES.md` and both `SKILL.md` are engine files: merge each by intent.

- **A hub knows its edition (T32).** Intent: an informal hub loads only informal rules (the five
  stores and their commands; no spec KB, project KB or formal tool). `hubkit.py install --edition
  informal|formal` (default: informal when `orbit-kb` is not on the PATH, else formal) records the
  edition in `.hub-template.json`, and an upgrade keeps it. A hub made before has no edition
  recorded: see "A hub with no edition" below. Files: `tools/hubkit.py`,
  `kit.json` (`editions`), `editions/informal/` (the informal `HUB-CORE.md`, `CLAUDE.md` and the two
  `SKILL.md`), `HUB-CORE.md` (the informal store map now has every fact kind, in the columns Fact
  kind, Informal home, How), `PRINCIPLES.md` (three principles added), `flow/seed.json` (a `review`
  session; owned, so an existing hub adds it with `hubflow.py session add review --role review` if
  it wants one). To switch an existing hub to the informal edition:
  `python3 "$KIT"/tools/hubkit.py edition --hub "$HUB" informal`, then again with `--yes`; merge
  each pending file by intent, and rewrite `CLAUDE.md` by hand from `editions/informal/CLAUDE.md`
  (an owned file: the switch never writes it). Check: `hubkit.py edition --hub "$HUB"` prints the
  edition, and `hubkit.py status` names it.
- **A hub with no edition (T36).** Intent: an upgrade picks the edition as install does. A hub made
  before editions (0.4.0 and earlier) records none: it gets the informal edition when `orbit-kb` is
  not on the PATH, else the formal one, and the dry run prints a `note:` line that says which and
  how to change it (`python3 "$KIT"/tools/hubkit.py edition --hub "$HUB" informal|formal`). Read the
  plan before `--yes`: a hub that used `orbit-kb` on another machine, or a PATH without it, needs
  `edition formal`. Files: `tools/hubkit.py`. Check: the dry run names the edition; `hubkit.py
  status` names it after the upgrade.
- **An informal hub's engine shows only the five stores (T36).** Intent: `hubflow.py` reads the
  edition from `.hub-template.json`; in an informal hub `--help` and its output name no spec KB,
  `orbit-kb`, `specs/<slug>`, project KB or question server, `rotate` does not print
  `spec_kbs_untriaged`, `where` and `spec-triage` are not commands, and a `kb` ref is never
  queried (it stays blocking for an agent, as before). A formal hub is unchanged. Files:
  `.claude/scripts/hubflow.py`. Check: `hubflow.py --help | grep -ci 'spec kb'` prints 0.
- **The requirements are the same in the README and the informal `HUB-CORE.md` (T36).** Intent: an
  informal hub needs Python 3, git, bash 4 or later and the POSIX tools that the README lists.
  Files: `HUB-CORE.md` (informal edition). Check: the file names `bash 4 or later` and `awk`.
- **Skip, never hide, in the ledger (T36).** Intent: the principle says what the ledger does with a
  skip: `park ID --until DATE` brings the item back for triage after the date, and `close ID
  --reason human_skip` is final and keeps the human's words. Files: `PRINCIPLES.md`. A hub that
  edited it keeps its own text and adds that sentence.
- **Premises beside the hypothesis (T36).** Intent: every stated hypothesis lists its premises beside
  it. Files: `PRINCIPLES.md` (the hypothesis principle), `HUB-CORE.md` (the `hypothesis` row of the
  informal store map). Check: `grep -c premises PRINCIPLES.md` prints 1 or more.
  Owned file `CLAUDE.md`: it must import the principles (`@PRINCIPLES.md` below `@HUB-CORE.md`, see
  0.4.0); an upgrade never writes `CLAUDE.md`. Check: `grep -x @PRINCIPLES.md CLAUDE.md` prints it.

### 0.4.0 (the informal release: the hub kit without Prolog or Lean)

The db schema is 4. **Database:** run `python3 .claude/scripts/hubflow.py migrate`, then
`check`. The kit is now named the hub kit, part of Sagittarius
(<https://github.com/theTyster/sagittarius>). `HUB-CORE.md` is an engine file: merge it by intent
(the new section is "Without orbit-kb", with its generated informal store map; the structure tree
and "Panes" no longer name `sessions/`).

- **The principles ship with the hub.** Intent: every agent in the hub reads the Sagittarius
  principles in plain words at start. Files: `PRINCIPLES.md` (new, engine: the upgrade adds it).
  Owned file `CLAUDE.md`: add the line `@PRINCIPLES.md` below `@HUB-CORE.md`; an upgrade never
  writes `CLAUDE.md`, and a root file that is not imported is invisible.
  Check: `grep -x @PRINCIPLES.md CLAUDE.md` prints the line.
- **The hub works without orbit-kb.** Intent: with only the five informal stores (ledger, memory
  files, weeks, bespoke tools, tracker), nothing blocks from a spec KB; an item with a `kb` ref is
  still treated as blocking when `orbit-kb` is missing. Files: `HUB-CORE.md`. No code change: a hub
  that uses `orbit-kb` keeps its spec KBs at `specs/<slug>` and its `spec-triage` step. Check:
  `hubflow.py check` exits 0.
- **`sessions/` leaves the kit.** Intent: named sessions belong to one machine, so they are set up
  outside the hub (dotfiles, a shell alias), and the hub knows only their names in `flow/seed.json`.
  Files: `sessions/launch.sh` (no longer shipped), `HUB-CORE.md`, `hub-flow/SKILL.md`,
  `INSTRUCTIONS.md`. An existing hub may keep its own `sessions/`: `sessions/ROLES` and each
  `sessions/<role>/` are the hub's files, and an upgrade never touches them. The upgrade removes an
  unchanged `sessions/launch.sh` (it lists `remove sessions/launch.sh`); to keep it as the hub's own
  file, run `git -C "$HUB" checkout HEAD -- sessions/launch.sh` after the upgrade. A changed
  `launch.sh` is listed as `pending`: keep the hub's file and run
  `python3 "$KIT"/tools/hubkit.py done --hub "$HUB" sessions/launch.sh`. Owned files: `CLAUDE.md`'s
  "Sessions" section may say where the sessions are started. Check: `hubkit.py status` does not
  list `sessions/launch.sh`.
- **An agent, not code, puts meeting transcripts into the ledger.** Intent: code never parses a
  meeting transcript; an agent that reads one records what is needed as ledger items that point to
  the file with a `transcript:NAME@sha256:HEX` ref, which `transcripts --find` resolves in
  whichever W slot holds the file. A new item kind `summary` (S-) lapses by itself at the first
  rotation when it is 28 days old and never needs a triage. `transcripts --files` lists the week
  transcript files with their refs. `index-transcripts` indexes only Claude Code sessions, and
  `rotate --yes` rebuilds that index from the week dirs (run it after the rename; 0.7.0 drops that
  session index). The schema 3 ->
  4 step of `migrate` drops the `meeting` and `meeting_turn` tables (a db of the unreleased
  redesign branch had them) and their JSONL. Files: `.claude/scripts/hubflow.py`,
  `.claude/scripts/hubflow-test.py`, `.claude/skills/hub-flow/SKILL.md` ("Kinds", "Ageing and
  triage", "Transcripts"), `.claude/skills/hub-rotate/SKILL.md` (step 5: `rotate --yes` runs after
  the rename and replaces the `index-transcripts W1` line), `HUB-CORE.md` ("What a week holds").
  A hub that changed the rotation steps keeps its own steps and runs `rotate --yes` after its
  rename. Check: `hubflow.py transcripts --files` lists each file of `W0/transcripts/` with a
  `transcript:` ref, and `hubflow.py transcripts --find REF` prints its path.

### 0.3.0 (agents know the stores and the workflow)

No schema change. `HUB-CORE.md` is an engine file: merge it by intent (the new sections are "What
lives where", with its generated store map, and "Panes").

- **Spec KBs live at `specs/<slug>/`.** Intent: a spec KB has the ticket's clock, not the week's.
  Files: `.claude/scripts/hubflow.py` (`kb:<slug>` resolves to `specs/<slug>`; `where` prints it;
  the old `W*/analyses/<slug>/kb` form still resolves, and `specs/` wins), `HUB-CORE.md`, both
  skills. To move an old spec KB: `git mv W<n>/analyses/<slug>/kb specs/<slug>`, then for each item
  that refers to it, add the new ref and remove the old one (`hubflow.py ref ID add kb:<slug>`, then
  `ref ID rm kb:<slug>/kb`; an agent is refused on an item whose spec KB blocks, so a human runs
  the `rm` with `--by human --note`). Leave the other contents of `analyses/` in git history or
  move them into the project KB. Check: `hubflow.py where <slug>` prints `specs/<slug>`.
- **The spec KB of a closed ticket is a triage item.** Intent: `rotate` lists
  `spec_kbs_untriaged:` and exits 1 until `hubflow.py spec-triage SLUG
  archive|capsule|keep|escalate --note T` records one decision for each. Files: `hubflow.py`,
  `hub-flow/SKILL.md`, `hub-rotate/SKILL.md`. A hub that changed the rotation steps keeps its own
  steps and adds the spec KB step before the `rotate --yes` step. Check: `hubflow-test.py`.
- **The week has no `analyses/` slot.** Intent: a week holds raw reports and transcripts; analyses
  are written in the project KB. Files: `hub-rotate/SKILL.md`, `HUB-CORE.md`. Owned files: a hub's
  `CLAUDE.md` should name the project KB and the repos (see the template's "Repos and the project
  KB") and the sessions that run the panes.
- **The copy rule, outbound, bespoke tools.** Intent: a pinned copy with a digest is allowed and
  goes stale on a later pin; an unpinned copy is not; one home per outbound thing; bespoke tools
  are listed only when other agents can use them, and pruned when unused. Files: `HUB-CORE.md`,
  `hub-flow/SKILL.md`, `hub-rotate/SKILL.md`, `hubflow.py --help`.

### 0.2.0 (the flow ledger)

The db schema is 2. **Database:** run `python3 .claude/scripts/hubflow.py migrate`, then `check`.

- **No silent lapse.** Intent: every item due at a rotation gets one recorded disposition
  (`hubflow.py triage ID keep|lapse|capsule|escalate --note T`); `rotate` exits 1 until each has
  one. An agent's keep or lapse of an item whose spec KB blocks becomes `escalate`. Files:
  `.claude/scripts/hubflow.py`, `.claude/skills/hub-flow/SKILL.md`,
  `.claude/skills/hub-rotate/SKILL.md`. A hub that changed the rotation steps keeps its own steps
  and adds the triage step before the `rotate --yes` step. Check: `rotate --week-start <Monday>`
  lists `untriaged:`.
- **Capsules, transcript index, human skip.** Intent: new commands `capsule`, `index-transcripts`,
  `transcripts`, and `close --reason human_skip --by human` (0.7.0 drops `index-transcripts` and the
  session index). Files: the same. Check:
  `hubflow-test.py --mutants`.
- **Asks to other people.** Intent: `check` exits 3 for an open ask that waits on someone other than
  the owner and has no `issue` ref. Owned file `flow/seed.json`: add `"owner": "<your person key>"`
  if the owner's key is not `me` (the seed is read only at `init`; for an existing db, the person
  `me` is the owner). Check: `hubflow.py check` exits 0, or names each untracked ask; give each one
  its issue ref.
- **Escalation needs orbit-kb.** `orbit-kb` on the PATH, or `HUBFLOW_ORBIT_KB`. Without it every
  item with a `kb` ref counts as blocking.

### 0.1.0 (first release)

The first versioned release. Nothing to upgrade from; a hub starts here with `INSTRUCTIONS.md`.

What 0.1.0 holds, for reference by later sections:
- `HUB-CORE.md` holds the shipped rules; `CLAUDE.md` imports it and holds the hub's own rules.
- Each shipped skill reads a `LOCAL.md` next to its `SKILL.md`, if present.
- `.hub-template.json` records the template version and the checksum of each engine file.
- `hubflow.py migrate` brings an older db up to the script's schema. The db schema is 1.

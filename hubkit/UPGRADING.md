# UPGRADING.md: apply a new template release to an existing hub

For the agent. Your human asked you to upgrade their hub to a newer release of this template. Read
this whole file first. A hub belongs to its people: never replace a file the hub changed, and show
your human every merge before you commit.

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
   `git -C "$KIT" diff <old tag> <new tag> -- hub/<path>` shows the release's change. When you are
   done with a file: `python3 "$KIT"/tools/hubkit.py done --hub "$HUB" <path>`.
5. **Owned files.** The release sections say when an owned file (`CLAUDE.md`, `.gitignore`, …) needs
   a change. Make it by intent; an upgrade never writes these.
6. **Database.** If a section says the schema changed: `python3 .claude/scripts/hubflow.py migrate`,
   then `hubflow.py check`.
7. **Checks.** In the hub: `python3 .claude/scripts/hubflow-test.py --mutants` (every mutant
   KILLED), `hubflow.py check` (exit 0), and each check that the release sections name.
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

### 0.5.0 (meeting transcripts in the ledger)

The db schema is 3. **Database:** run `python3 .claude/scripts/hubflow.py migrate`, then `check`.

- **Meeting transcripts can be queried.** Intent: `index-transcripts W_DIR` also reads the Markdown
  and plain-text meeting transcripts in `W_DIR/transcripts/` (a summary and one row per speaker
  turn or paragraph); `transcripts --detail ID` shows a meeting's turns; `transcripts --grep TEXT`
  finds turns with their file and line; `rotate --yes` rebuilds the index of the week dirs, so a
  retired week's rows go. Files: `.claude/scripts/hubflow.py`, `.claude/scripts/hubflow-test.py`,
  `.claude/skills/hub-flow/SKILL.md`, `.claude/skills/hub-rotate/SKILL.md` (step 5: `rotate --yes`
  runs after the rename and replaces the `index-transcripts W1` line), `HUB-CORE.md` ("What a week
  holds"). A hub that changed the rotation steps keeps its own steps and runs `rotate --yes` after
  its rename. Check: `hubflow.py index-transcripts W0`, then `hubflow.py transcripts` lists each
  meeting file of `W0/transcripts/`.

### 0.4.0 (the informal release: the hub kit without Prolog or Lean)

No schema change. The kit is now named the hub kit, part of Sagittarius
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
  `transcripts`, and `close --reason human_skip --by human`. Files: the same. Check:
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

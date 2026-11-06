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

# UPGRADING.md: apply a new release of the MindHole Kit to an existing hub

For the agent. Your human asked you to upgrade their hub to a newer release of the MindHole Kit, the
kit that made it. Read this whole file first. A hub belongs to its people: never replace a file the
hub changed, and show your human every merge before you commit.

**Versions.** This release of the MindHole Kit pairs with Sagittarius 0.6: its `PRINCIPLES.md` comes
from that prompt, and a formal hub copies the orbit-kb of the same Sagittarius checkout. The kit's own version is `MindHole Kit <version>` (`kit.json`); a release section says so when the
Sagittarius pair changes. Older sections below say "hub kit" or "the MindHole" for the template: the MindHole Kit's name before 2026-11-12.

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
   The kit has no release tags: `git -C "$KIT" log -p -- hub/<path>` shows the commits that changed the file; read the ones after
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

Lessons from a real migration (2026-11-12). Do them in this order, and ask your human before each
step that writes.

1. **Local rules: synthesize them into the shipped rules.** The human's ruling: "synthesize local
   rules into shipped rules. If there are problematic conflicts, you can bring them to me." So each
   shipped `SKILL.md` and `HUB-CORE.md` stays as shipped. A local rule that the kit does not have
   goes to the skill's `LOCAL.md` (or to `CLAUDE.md` for a rule of the whole hub). A local rule that
   the kit already has, in other words, is dropped. Only a real conflict (the local rule and the
   shipped rule ask for different things) goes to the human, with both texts side by side.
2. **Old asks and work in flight: import them into the ledger.** A hub of the first starter kit
   keeps asks and in-flight lines in its week files (`W*/WEEK.md`). Write one JSONL row per line
   for `python3 .claude/scripts/hubflow.py import FILE`: `kind` (`ask`, `thread` or `hold`),
   `title`, `waits_on` for an ask, no `owner` (the owner is none until a session takes the item),
   and a `note` that holds the old row text word for word and the date and week file it came from.
   Run the dry run first (`hubflow.py import FILE`, no `--yes`): it prints the counts by kind, owner
   and waits-on, and the rejected lines. Show the counts to your human; run `--yes` only after they
   approve the count. Then `hubflow.py check` (exit 0) and commit `flow/jsonl/`.
3. **Moving the hub directory.** Claude Code keeps each session under
   `~/.claude/projects/<the cwd with each / as ->`. Before the first session starts in the new
   place, copy every `~/.claude/projects/<old-cwd-name>*` directory to the same name with the new
   path, so that `claude --resume "hub-<name>"` finds the session and appends to it in the new
   place. Copy; do not move, until the human has resumed each role once.
4. **References outside the hub.** Update every path to the old directory: the parent directory's
   `CLAUDE.md`, symbolic links in git worktrees, terminal and tmux profiles (the launcher lines),
   `.claude/settings.local.json`, and `.claude/scheduled_tasks.json` with its `.lock` file (stop the
   scheduled tasks first; remove a stale `.lock` only when no session runs). Search for the old path
   with `grep -rn` in each of these places; list each change for your human.
5. **Tell the running sessions.** A session that started before the migration still holds the old
   rules and paths. Send each one a short text, for example: "This hub moved to <new path> and now
   runs MindHole Kit <version>. Stop, then resume in the new place with your launcher line
   (`--resume "hub-<name>"`). Read your inbox first (`.claude/orbit-kb/bin/orbit hub
   ledger view v_inbox --session <name>`): your open asks and work in flight are ledger items now. Local rules are in each skill's
   `LOCAL.md`."

## Release sections

Each section gives, per change: the intent in one sentence, the files, the steps for a hub that
changed those files, and a check.

### 0.13.0 (the Desk gives letters by wake, Stop and confirmation; db schema 9, unchanged)

This release pairs with Sagittarius 0.11.0. The db schema is 9: no `hubflow.py migrate`. `desk.py`
changes: a new command `ack LID` (the agent confirms a letter in its turn), `wake` (typed on the
human's yes only), a changed hook (one letter at each Stop; a turn with no confirmation leaves the
letter as given, not acted on), and `status` reports `delivery` and `wake_ask` for each letter. The
hooks block that `desk.py hooks` prints is the same: no change to `.claude/settings.json`. The `hub-flow`
skill names `ack`. A hub on 0.12.3 needs nothing but the upgrade. Restart the Desk after every joined
hub is upgraded: a Desk of the new tool with a hub of the old `desk.py` shows no delivery field and
no Letters block.

### 0.12.3 (Ratify of a relation on the Desk; db schema 9, unchanged)

This release pairs with Sagittarius 0.10.1. The db schema is 9: no `hubflow.py migrate` is needed. The
engine (orbit-kb) changes: the Desk can ratify a proposed relation of the project KB (it adds the
relation as a human's) and warns when that makes a contradiction. A hub on 0.12.2 needs nothing but
the upgrade. Restart the Desk after every joined hub is upgraded.

### 0.12.2 (the Desk by store; db schema 9, unchanged)

This release pairs with Sagittarius 0.10.0. The db schema is 9: no `hubflow.py migrate` is needed. The
engine (orbit-kb) changes: the Desk page is laid out by store (Ledger, Spec KBs, Project KB) with a
row of views, and opens on Waits on you; every action on a spec KB is in its sheet; the page keeps
the open folds and the place in the browser; the repo-map views get their tags. A hub on 0.12.1
needs nothing but the upgrade. To group the spec KBs by repo, write `repo(Name, Path)` in each spec
KB (it needs the project module). Restart the Desk after every joined hub is upgraded: one Desk
serves every mindhole with its own tool version.

### 0.12.1 (a faster Desk; db schema 9, unchanged)

This release pairs with Sagittarius 0.9.0. The db schema is 9: no `hubflow.py migrate` is needed. The
engine (orbit-kb) changes: the Desk keeps what it built until a file, a tree walk or a clock time it
rests on changes, and it adds the repo-map views (`share/repo-map/views.py`). A hub on 0.12.0 needs
nothing but the upgrade. Restart the Desk after every joined hub is upgraded: one Desk serves every
mindhole with its own tool version.

### 0.12.0 (one kind of hub: a hub needs the tool; db schema 9: the `goal` ref kind)

Ty, 2026-11-23: the release for a hub with no tool is dropped. A hub needs the tool: the kit makes
one kind of hub, with its own `orbit-kb`. This release pairs with Sagittarius 0.8.0 (it was 0.7.2).
The db schema is 9. **Database:** run `python3 .claude/scripts/hubflow.py migrate` once (schema 8 to 9: the
ref kind `goal`, `--ref goal:pg1`, the project goal that an item names directly), then `hubflow.py check`.
migrate keeps a backup at `flow/flow.db.bak-v8`. A hub at schema 7 applies the 0.9.0 section first.

- **A hub that has the tool** (`hubkit.py edition --hub "$HUB"` prints `formal`, or the manifest
  records no edition): upgrade as in "The procedure". The plan adds `.claude/orbit-kb/bin/orbit`:
  the same program as `bin/orbit-kb`, under the name `orbit`. `hubflow.py` and every command of
  0.11.2 work as before. `HUB-CORE.md` loses its section "Without orbit-kb" and the second store
  map. A manifest with no edition is read as formal, whatever the PATH holds. `HUB-CORE.md` and the
  skills `hub-flow` and `hub-rotate` now give each ledger command through the door
  (`.claude/orbit-kb/bin/orbit hub ledger ...`): keep that when you merge a changed copy by intent.
- **A hub that an older kit made with no tool** (`hubkit.py edition --hub "$HUB"` prints
  `informal`): `hubkit.py upgrade` refuses it with one line and copies nothing. Do this:
  1. Install SWI-Prolog 9 or later (`swipl` on the PATH).
  2. `python3 "$KIT"/tools/hubkit.py edition --hub "$HUB" formal` (a dry run), then again with
     `--yes`. It replaces `HUB-CORE.md` and the two `SKILL.md` if the hub did not change them (a
     changed one is `pending`: merge it by intent), adds the hub's own orbit-kb under
     `.claude/orbit-kb/`, and records `"edition": "formal"`.
  3. Owned file `CLAUDE.md`: add the section "Repos and the project KB" by hand (copy it from
     `hub/CLAUDE.md` of the kit).
  4. Make the project KB: `INSTRUCTIONS.md`, "Step 6 (formal)". The ledger keeps every item.
  From now on `hubflow.py` has one help text and one rule set in every hub: a new ask needs
  `--ref kb:<slug>` or `--no-kb`, and `--note`.
- **`hubkit.py`**: `install` takes no `--edition informal` (it says why), and `edition` switches no
  hub to it. `--edition formal` is still taken.
- **The fail-safe stays.** When the hub's orbit-kb cannot be asked (the copy is gone, or it does
  not run), an item with a `kb` ref counts as blocking: an agent's keep or lapse of it becomes
  escalate, and only a human closes it.

Check: `python3 "$KIT"/tools/hubkit.py status --hub "$HUB"` prints `(formal edition` on its first
line and lists `.claude/orbit-kb/bin/orbit` as `unchanged`; `.claude/orbit-kb/bin/orbit version`
prints the version; `python3 .claude/scripts/hubflow.py check` exits 0.

### 0.11.2 (a fix of the Desk; db schema 8, unchanged)

This release pairs with Sagittarius 0.7.2. The db schema is 8: no `hubflow.py migrate` is needed. The
engine (orbit-kb) changes: the Desk refused a Fix letter about more than 50 items at Send, and the
letter was not stored. Now the item of a Fix letter names at most 50 ids, and its text names every
one (spec KB questions-server c20, c8). A hub on 0.11.1 needs nothing but the upgrade. A Fix letter
that the Desk refused before is not stored: send it again after the upgrade.

### 0.11.1 (a fix of this file; db schema 8, unchanged)

This release pairs with Sagittarius 0.7.1. The db schema is 8, as in 0.11.0: no `hubflow.py migrate`
is needed. No engine file changes. 0.11.0 shipped this file with a stray merge-marker line
(`||||||| d9207b8`) above the 0.9.0 section; 0.11.1 removes it, and `kb/tests/test_release.sh` now
fails on such a line in any tracked file (spec KB module-versions c9). A hub on 0.11.0 needs nothing
but the upgrade, which records the new module versions.

### 0.11.0 (module versions and the Desk toast; db schema 8, unchanged)

This release pairs with Sagittarius 0.7.0 (it was 0.6.0). The db schema is 8, as in 0.10.0: no
`hubflow.py migrate` is needed.

- **Module versions (spec KB module-versions, c6, c7; Ty, 2026-11-20: "We need to make sure we
  version all of these other modules and track the versions for them as we upgrade and migrate
  too").** Intent: a hub says which version of each Sagittarius module it came with, and what this
  machine really runs. `MODULES.json` in the Sagittarius checkout lists the modules (sagittarius,
  orbit-kb, system-1, mindhole-kit, s1-glance, desk-toast), where each one's version is, and the links
  that `install.py` makes for it. `.hub-template.json` gets a `modules` key: per module the release
  version and, for a module linked into the home directory, the link's real source, the version
  there, a digest of its files, and `release` (true when the files are the release's). The upgrade
  prints one `module NAME OLD -> NEW` line per module (`not recorded` the first time) and an
  `installed` line for each link that does not run the release code; `status` prints the record and
  the state of each link now. Nothing to merge: the upgrade writes the key. Check: `hubkit.py status
  --hub "$HUB"` prints a `module` line per module.
- **The Desk toast (spec KB desk-letter-toast, c9, c4, c10).** Ty, 2026-11-19: "I need some kind of claude mod.
  Preferably a toast or something temporary that shows a letter arrived and a little bit of what it
  says"; and on how it installs: "link it like s1-glance". The Claude Code mod desk-toast ships with the
  Desk: its source sits beside `desk.py` (`hub/.claude/scripts/desk-toast/` in the kit). The kit copies it
  into no hub (kit.json `not_shipped`). The Sagittarius installer links it once per machine:
  `./install.py` in the Sagittarius checkout makes `~/.claude/skills/desk-toast`, where every Claude Code
  session loads it. Within a few seconds after a letter's `seen` event, every session shows
  `📨 <session name> saw:` and the first 60 characters of the letter. "saw" means that the hook gave the
  letter to the agent, not that the agent acted on it. The mod only reads the Desk files of each mindhole
  that joined the Desk (`desk.py join`); delivery does not change.
  Engine files: `.claude/scripts/desk.py` (its help text names the toast) and `.claude/scripts/desk-test.py`:
  replace them. Nothing is added to the hub.
  A hub that got `.claude/skills/desk-toast/` from an earlier build of this change (branch
  desk/letter-toast before the link): delete that folder, and drop its lines from `.hub-template.json`
  `files` if the upgrade still lists them. No released hub has it.
  Once per machine (ask your human first; it writes `~/.claude`): `./install.py` in the Sagittarius
  checkout, then start a new session (a running one: `/reload-plugins`). `/desk-toast` prints the help.
  Check: `./install.py --check` prints `ok` for `~/.claude/skills/desk-toast`, and a new session lists
  `desk-toast` among its plugins (`claude plugin list`, under Skills-directory plugins).

### 0.10.0 (KB migrations and the upgrade preview; db schema 8, unchanged)

Ty, 2026-11-19 (spec KB kb-migrations, T-0021): migrations for spec and project KBs when orbit-kb
changes, so that no verdict of a KB changes quietly. This release pairs with Sagittarius 0.6.0 (it was
0.5.0). The db schema is 8, as in 0.9.0: no `hubflow.py migrate` is needed.

- **The upgrade shows the preview first (c15, c19, c21).** Intent: before a new orbit-kb lands, the
  human sees, for every KB of the hub, each verdict that the new engine changes. Step 2 of the
  procedure, the dry run of *this* kit's `hubkit.py upgrade`, runs the new `orbit-kb migrate plan
  --old` the hub's current orbit-kb on every KB it finds: `specs/<slug>/` and the old form
  `W0`..`W5/analyses/<slug>/` at any depth, closed tickets too (marked closed; closed is read from
  `flow/flow.db`, read-only). It prints `Verdicts: none differs` or each change, and a preview
  digest. Step 3 then needs that digest: `hubkit.py upgrade --hub "$HUB" --yes --seen-migrations
  DIGEST`. Show the preview to your human before you run step 3. A change outside the declared reach
  of a migration refuses the upgrade (`OUTSIDE`): stop and ask.
- **A KB in a hub reads its project KB from the hub root (c20; Ty, 2026-11-20, q21 B).** Intent: a
  spec KB keeps its link to the project KB when it moves inside the hub, with no write. In a hub,
  `project_kb(P)` with a relative P is read from the hub root, its leading `../` steps dropped. So a
  KB of the old form (`W<n>/analyses/<slug>/kb` with `project_kb('../../../../project-kb')`) and the
  same KB after `git mv` to `specs/<slug>` (where the old fact still says four `../`) both reach
  `<hub>/project-kb`. The migration `m_0_6_0_project_root` declares this change and has no step; the
  preview shows each verdict that the new reading changes. A hub with old-form KBs can move them to
  `specs/<slug>` (the 0.3.0 note below) after this upgrade, with no edit of `kb.pl`.
- **`orbit-kb migrate check | plan | apply` (c2 to c14).** Intent: an older KB is brought to the new
  engine by steps that the tool, the agent or the human does, each found by a query on the KB, never
  by a marker. `apply --seen DIGEST` writes the tool's steps in one atomic write and refuses a KB
  whose ticket is closed (frozen). A retired predicate gets a cut-fail clause in `kb.pl` and
  `retired/3`, and lint WM1 warns about it. `orbit-kb help migrate`.
- **`hubflow.py migrations` and `kb-state SLUG` (c9, c10, c12).** `migrations` runs `orbit-kb migrate
  check` on each spec KB whose ticket is open (old form too) and exits 1 while a tool or agent step is
  to do; `kb-state` prints open or closed. The Desk shows no migration step of a frozen KB.
- **One migration with work: `m_0_5_0_checks_that`.** A check made before orbit-kb 0.5.0 has no
  words. An agent adds `checks_that(K, Text)` for each check that lint W12 names; `hubflow.py
  migrations` lists them as `todo` until it is done.

Every hub: `PRINCIPLES.md` line 3 names Sagittarius 0.6.0; replace the file if
the hub did not change it, otherwise change that one number. Engine files: `.claude/scripts/hubflow.py`,
`.claude/scripts/desk.py`, and in a formal hub the orbit-kb copy: `.claude/orbit-kb/bin/orbit-kb`,
`share/orbit-kb/VERSION` (now `0.6.0`), `README.md`, `core.pl`, `signature.pl` (new),
`migrations/` (new: `0.5.0-checks_that.pl`, `0.6.0-project-root.pl`), `help/codes.txt`, `help/core.txt`,
`help/project.txt`, and `share/repo-map/` (its example names `hubflow-starter` by its directory name).
Replace them. Owned files: no change.
Check: `.claude/orbit-kb/bin/orbit-kb version` prints `orbit-kb 0.6.0`; `python3 "$KIT"/tools/hubkit.py
status --hub "$HUB"` prints `hub from MindHole Kit 0.10.0`; `python3 .claude/scripts/hubflow.py
migrations` runs (exit 0, or 1 with each `todo` named: do those steps).

### 0.9.0 (a park ends on or before the due date; db schema 8)

Ty, 2026-11-18 (Sagittarius spec KB questions-server, c38 to c41): "there needs to be a database level
requirement that parked dates must be <= Due Dates and nullable". The db schema is 8: two triggers on
`item` refuse any write that leaves an item parked past its `--due` date (from `park --until`,
`set --due`, the Desk, or any other tool that writes `flow.db`). With no park or no `--due` date there
is no rule. **Database:** run `python3 .claude/scripts/hubflow.py migrate` once (schema 7 to 8), then
`hubflow.py check`. If an item already breaks the rule, migrate names it and writes nothing: fix each
one with this hub's hubflow (park it to an earlier date, or `set ID --due` later or `none`), then run
migrate again. A hub at schema 6 applies the 0.8.0 section first.
This release pairs with Sagittarius 0.5.0 (it was 0.4.1). Every hub:
`PRINCIPLES.md` line 3 names Sagittarius 0.5.0; replace the file if the hub did not change it,
otherwise change that one number. A formal hub: replace `.claude/orbit-kb/share/orbit-kb/VERSION`
(now `0.5.0`).
Engine files: `.claude/scripts/hubflow.py`, `.claude/scripts/hubflow-test.py`, `.claude/scripts/desk.py`,
`.claude/skills/hub-flow/SKILL.md`, and in a formal hub `.claude/orbit-kb/bin/orbit-kb` and
`share/orbit-kb/desk/desk.css`. Replace them.
What changes for the hub's sessions:
- `park ID --until D` is refused when D is after the item's due date, and `set ID --due D` is refused
  when D is before the end of its park. Change the other date first.
- `skip-waived` leaves an item unparked when the waiver's due time is after the item's due date, and
  prints `not parked: ID`.
- The Desk puts parked items in a closed Parked group at the end of the Ledger lane, by park end, then
  by due date (no due date last). They count nowhere until the park ends. It reads each park from the
  ledger, so a hub whose `desk.py` is older shows them too.
Check: `.claude/orbit-kb/bin/orbit-kb version` prints `orbit-kb 0.5.0`; `python3 "$KIT"/tools/hubkit.py status --hub "$HUB"` prints `hub from MindHole Kit 0.9.0`, and
`sqlite3 flow/flow.db "select name from sqlite_master where type = 'trigger'"` lists
`item_park_due_insert` and `item_park_due_update`.

### 0.8.0 (the Desk; db schema 7)

One Desk at one address for every MindHole on the machine (Sagittarius spec KB questions-server,
round 2). Ty answers, diverges or adds a requirement there, and every letter goes through a review
that shows each receiving session and the exact text it gets. The db schema is 7. **Database:** run
`python3 .claude/scripts/hubflow.py migrate` once (schema 6 to 7: the columns `due` and `no_kb` of
`item`), then `hubflow.py check`. A hub at schema 5 applies the 0.7.0 section first.
Engine files: `.claude/scripts/hubflow.py`, `.claude/scripts/hubflow-test.py`, `.claude/scripts/desk.py`,
`.claude/scripts/desk-test.py`, `.claude/skills/hub-flow/SKILL.md`, and in a formal hub
`.claude/orbit-kb/bin/orbit-kb`, `share/orbit-kb/core.pl`, `share/orbit-kb/help/core.txt`, and the new
`share/orbit-kb/desk/desk.css` and `desk.js`. Replace them.
What changes for the hub's sessions:
- `add ask` in a formal hub needs `--ref kb:<slug>` (or `kb:/abs/path`, `kb:~/path` for a KB outside
  the hub) or `--no-kb`. Old asks stay as they are; the Desk shows them as "No KB behind it".
- `add ask` in a formal hub also needs `--note TEXT`: the case, the options and what each changes, and
  your default (the Desk shows it as the ask's context). A blank note is refused.
- `add ask --due YYYY-MM-DD` and `set ID --due` record the date by which the asker needs the answer.
- `--reserved` names its source: `NAME Policy: RULE` or `WHO, YYYY-MM-DD: WORDS`.
- A check says in words what it checks: `checks_that(K, Text)` in a spec KB (lint W12 warns).
- Letters from the Desk reach a session through the desk hooks. Owned file: add the block that
  `python3 .claude/scripts/desk.py hooks` prints to `.claude/settings.json` (ask your human first).
Once per MindHole: `python3 .claude/scripts/desk.py join --name <mindhole name>`. Once per machine
(the human decides): `python3 .claude/scripts/desk.py service --write`, then the `systemctl --user`
command it prints, so the Desk runs again after a reboot. Drafts live in the Desk's own store
(`~/.local/state/desk/`), outside every MindHole; an old `flow/desk/drafts.json` is not read and can
be deleted.
Check: `python3 "$KIT"/tools/hubkit.py status --hub "$HUB"` prints `hub from MindHole Kit 0.8.0`,
`hubflow.py show <an ask>` prints `due:` and `no_kb:`, and `desk.py mindholes` lists the hub.

### 0.7.3 (the version line; db schema 6, unchanged)

This release pairs with Sagittarius 0.4.1 (it was 0.4.0). No rule changed. Every hub: `PRINCIPLES.md` line 3 names Sagittarius 0.4.1; replace the file if the hub did not
change it, otherwise change that one number. A formal hub: replace
`.claude/orbit-kb/share/orbit-kb/VERSION` (now `0.4.1`).
The db schema is 6. **Database:** a hub at 0.7.0, 0.7.1 or 0.7.2 is at schema 6 already and runs no
migrate; a hub at schema 5 (0.5.1 to 0.6.0) applies the 0.7.0 section first, which runs
`python3 .claude/scripts/hubflow.py migrate` once.
Check: `python3 "$KIT"/tools/hubkit.py status --hub "$HUB"` prints `hub from MindHole Kit 0.7.3`,
and `.claude/orbit-kb/bin/orbit-kb version` prints `orbit-kb 0.4.1`.

### 0.7.2 (the orbit-kb copy: K-F and K-H; db schema 6, unchanged)

This release pairs with Sagittarius 0.4.0 (it was 0.3.0): orbit-kb gained rules that change what a
session does. Every hub: `PRINCIPLES.md` line 3 names Sagittarius 0.4.0;
replace the file if the hub did not change it, otherwise change that one number. A formal hub's
orbit-kb copy changes too.
The db schema is 6. **Database:** a hub at 0.7.0 or 0.7.1 is at schema 6 already and runs no
migrate; a hub at schema 5 (0.5.1 to 0.6.0) applies the 0.7.0 section first, which runs
`python3 .claude/scripts/hubflow.py migrate` once. Engine files changed since 0.7.1, all under
`.claude/orbit-kb/`: `bin/orbit-kb`, `share/orbit-kb/README.md`, `share/orbit-kb/core.pl`,
`share/orbit-kb/modules/build.pl`, `share/orbit-kb/modules/discovery.pl`, `share/orbit-kb/VERSION`
(now `0.4.0`), and the help topics
`build.txt`, `discovery.txt`, `shift.txt`. Replace them; a hub does not edit its orbit-kb copy.
What changes for the hub's sessions: a claim contested twice can be closed by a decided result of
a trusted model that encodes it (the report shows the bounds), and `orbit-kb shift --red-log FILE`
records a red run that only the agent saw as a disclosure; the claim then waits for a human waiver.
Check: `python3 "$KIT"/tools/hubkit.py status --hub "$HUB"` prints `hub from MindHole Kit 0.7.2`,
`.claude/orbit-kb/bin/orbit-kb help shift` names `--red-log`, and `.claude/orbit-kb/bin/orbit-kb
version` prints `orbit-kb 0.4.0`.

### 0.7.1 (the MindHole Kit name; db schema 6, unchanged)

The template is now called the MindHole Kit, and a hub made from it is a MindHole. No behavior
changes. The db schema is 6. **Database:** a hub at 0.7.0 is at schema 6 already and runs no
migrate; a hub at schema 5 (0.5.1 to 0.6.0) applies the 0.7.0 section first, which runs
`python3 .claude/scripts/hubflow.py migrate` once. Engine files changed since 0.7.0: `HUB-CORE.md`
(line 3 says the guidance ships with the MindHole Kit). Replace it if the hub
did not change it; otherwise change that one line by intent. Owned file `CLAUDE.md`: if it calls
the template "the MindHole" or "the hub kit", say "the MindHole Kit" (optional; nothing reads it).
Check: `python3 "$KIT"/tools/hubkit.py status --hub "$HUB"` prints `hub from MindHole Kit 0.7.1`.

### 0.7.0 (Sagittarius 0.3.0 alignment; db schema 6: the session index is dropped)

This release was made for Sagittarius 0.3.0. The build picks the kit version; it only
moves up (0.6.0 -> 0.7.0, with the db schema 5 -> 6). The db schema is 6.
**Database:** every hub at schema 5 (0.5.1 to 0.6.0) runs
`python3 .claude/scripts/hubflow.py migrate` once, then `hubflow.py check`. Engine files changed since 0.6.0: `HUB-CORE.md`,
`PRINCIPLES.md`, `.claude/scripts/hubflow.py`, `.claude/scripts/hubflow-test.py`, both `SKILL.md`,
`.claude/skills/hub-rotate/scripts/check-citations.py`, and in a formal hub the orbit-kb copy under
`.claude/orbit-kb/` (`share/orbit-kb/VERSION` and `share/orbit-kb/help/shift.txt` are new files).
Replace each engine file the hub did not change; merge the others by intent. Owned file
`CLAUDE.md`: add one section by hand (below); it still imports the principles (`@PRINCIPLES.md`
below `@HUB-CORE.md`, see 0.4.0). A hub that skipped 0.6.0 reads that section too.

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
- **The inbox rule is the hub's own (M-B).** Intent: in a hub, every session reads its inbox first,
  at session start and after every compaction, from the hub's own text (the prompt names no hub
  tool): `python3 .claude/scripts/hubflow.py view v_inbox --session "$HUB_SESSION"`, then each item's
  refs (in a formal hub: `hubflow.py where <slug>`, then `.claude/orbit-kb/bin/orbit-kb show open`
  there). Files: `HUB-CORE.md` ("Flow state lives in the db", both editions). Check: that section
  names `v_inbox`, the session start and the compaction.
- **The store map gets the vote, and new descriptions (M-B).** Intent: the vote that ends discovery
  (GO, NO-GO or HOLD) has a home: the spec KB; the hypothesis is "what the human wants for this ticket", and models
  are solver and model-checker models and Lean definitions and theorems. Files:
  `HUB-CORE.md` ("What lives where": 30 fact kinds). Check:
  `python3 "$KIT"/tools/storemap.py --hub-core HUB-CORE.md --check` exits 0 in a formal hub that did
  not change the maps.
- **The new `PRINCIPLES.md` comes from the prompt (M-C).** Intent: the hub's principles are the
  Sagittarius 0.3.0 prompt in plain words; each part names the sections of the prompt it comes from
  ("From the prompt: ..."), not a section of the philosophy. "Start light" names the six signals,
  with a claim that needs a proof. The file stays at 60 lines or fewer. Files: `PRINCIPLES.md`. A hub
  that changed it keeps its own lines and merges each part by intent. Check: each `## ` part has a
  line `From the prompt:`.
- **A hub has a light path (M-E).** Intent: a clear change with no signal is delivered by the
  session that made it, with its check, and with no spec KB and no review; a signal (or the human)
  brings the spec KB and the review pane. Files: `HUB-CORE.md` ("Panes"). Check: `grep -c "light path" HUB-CORE.md`
  prints 1 or more.
- **A handoff carries its kb ref (M-F).** Intent: the receiver of a handoff finds the KB from the
  row: the handoff example of the formal skill is `$HF handoff --to build --title "…" --ref kb:<slug>
  --ref issue:123 --note "where to start"`. The pane prompt `PANES.md` (outside the hub, appended by
  the launcher) also has the receiver record the handoff in the KB as a signal (`orbit-kb add
  "signal(s1, handoff, agent, '...')"`). Files: `.claude/skills/hub-flow/SKILL.md` (formal edition).
  Check: `hubflow-test.py --case case_030_handoff_example` passes.
- **A closed ticket proposes its lasting outcomes (M-F).** Intent: before the spec-triage decision
  (always before an archive), the agent proposes each lasting outcome of the ticket to the project
  KB and lists the proposals in its report for the human to ratify. Files: both formal skills
  (`hub-flow` "Spec KBs", `hub-rotate` steps 4 and 7). A hub that changed its rotation steps adds
  this before its `spec-triage` step. Check: the `hub-rotate` skill says "propose each lasting
  outcome".
- **What the hub runs (M-D).** Intent: each MindHole runs its own pinned version. `install` and
  `upgrade --yes` record in `.hub-template.json` (`runs`) the orbit-kb copy and its version, the
  prompt that the launcher appends (`~/.claude/sagittarius/SAGITTARIUS.md`, with its Sagittarius
  version and sha256) and the pane files (`PANES.md`, `panes/<role>.md`); `hubkit.py status` prints
  them in `runs` lines and says whether the files there are still the same. The pane launcher sets
  `HUB_SESSION` and appends the prompt: `cd "$HUB" && p=~/.claude/sagittarius &&
  HUB_SESSION=<name> command claude --name "hub-<name>" --append-system-prompt "$(cat
  "$p/SAGITTARIUS.md" "$p/PANES.md" "$p/panes/<name>.md")"` (`INSTRUCTIONS.md`, "The formal
  edition"). No hub file changes; `tools/hubkit.py` writes the manifest. Check: after the upgrade,
  `hubkit.py status` prints `runs prompt: ... the file there: same`. If it says `differs`, the panes
  run another prompt than this kit's: tell your human.
- **The orbit-kb copy is Sagittarius 0.3.0 and carries its version (formal edition).** Intent: the
  hub's own orbit-kb is the one this kit was tested with. New in it: `orbit-kb version` (it reads
  `share/orbit-kb/VERSION`, a new file of the copy), the hypothesis and its premises in every KB,
  `signal/4`, `lean_back/2`, `orbit-kb shift` and `help shift`, and the discovery orbit that stays
  open until the human approves the ticket after a GO. The plan shows `replace` (or `merge` for a
  file the hub changed) for `bin/orbit-kb` and the changed `share/` files, and `add` for the new
  ones. Check: `.claude/orbit-kb/bin/orbit-kb version` prints `orbit-kb 0.3.0`, and
  `.claude/orbit-kb/bin/orbit-kb --dir project-kb lint` ends `0 error(s)`.
- **`init` prints one line (UAT U5).** Intent: an agent sees that the db was made:
  `initialized <flow dir>/flow.db: schema 6, N sessions, M people`. Exit codes and files do not
  change. A hub script that wraps `init` and expects no output: allow the line. Files:
  `.claude/scripts/hubflow.py`. Check: `hubflow-test.py --case case_init` passes.
- **The test suite streams, and follows the changes (UAT U2).** Intent: `hubflow-test.py --mutants`
  prints one line per mutant as each one ends, so a log shows progress. New cases:
  `case_030_handoff_example`, `case_030_session_index_dropped`, `case_k3_citations_hub_name`; new
  mutants `init-prints-nothing` and `session-index-kept`; the session index cases and mutants are
  gone. Files: `.claude/scripts/hubflow-test.py`. A hub that changed it: merge
  `sys.stdout.reconfigure(line_buffering=True)` at the start of `main()` and the new cases. Check:
  only a UAT upgrade runs the suites (step 7).
- **check-citations reads the hub's own directory name (review 2, finding 13).** Intent: a hub in a
  directory named `mindhole` that writes `mindhole/W0/reports/a.md` gets that citation checked across
  a rotation; `hub/W0/...` still counts. Files:
  `.claude/skills/hub-rotate/scripts/check-citations.py`. Check: `hubflow-test.py --case
  case_k3_citations_hub_name` passes.
- **The template is the MindHole Kit.** Intent: line 3 of `HUB-CORE.md` (both editions) says "This file ships
  with the MindHole Kit (the template that made this hub)"; `hubkit.py` prints `installed MindHole Kit X`, `hub
  from MindHole Kit X (...); this kit MindHole Kit Y` and `upgrade MindHole Kit X -> MindHole Kit Y`. A hub script that
  reads the old lines (`installed template`, `hub template`, `upgrade X -> Y`) must read the new ones.
- **Owned file `CLAUDE.md`: a section for the human's notes (UAT U6).** Intent: the human has a place
  for their own notes, such as a project order. An upgrade never writes `CLAUDE.md`: add the section
  `## Your notes` by hand, below "What this hub is for", if the human wants it.

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
  `lake` from the PATH. The PATH plays no part in the install. Check: `.claude/orbit-kb/bin/orbit-kb --dir project-kb lint` ends `0 error(s)`, and
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
  `README.md` only. An upgrade follows the same rule: only a UAT upgrade runs the suites (step 7 of
  the procedure above).

### 0.5.2 (hub kit fixes from the first formal-edition install; db schema stays 5)

The db schema is 5, as in 0.5.1: no `hubflow.py migrate` is needed. `.claude/scripts/hubflow-test.py`
is an engine file: replace it if the hub did not change it, else merge by intent. `INSTRUCTIONS.md` is
not in the hub; the changes to it are for whoever sets up a hub. Owned file `.gitignore`: add the two
lines below by hand (an upgrade never writes an owned file). Owned file `CLAUDE.md`: no change in 0.5.2; it still
imports the principles (`@PRINCIPLES.md` below `@HUB-CORE.md`, see 0.4.0).

- **The hub's tests find `orbit-kb` on PATH (T51 c1).** Intent: `hubflow-test.py` ran its real-orbit-kb
  cases only beside the kit tree, so in an installed formal hub they skipped, the suite said
  `N passed, 0 failed`, and waiver mutants survived. Now it looks at `$HUBFLOW_TEST_ORBIT_KB`, the kit
  tree, then `orbit-kb` on PATH. In an installed hub a skipped real-orbit-kb case is a failure, and the last line counts skips (`N passed, M failed,
  K skipped`). Files: `.claude/scripts/hubflow-test.py`. Check: in the
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

### 0.5.0 (editions; the principles say what the ledger does)

The db schema is 4, as in 0.4.0. **Database:** a hub made at 0.4.0 before the transcripts change has
schema 2 or 3 (`hubflow.py check` exits 2): run `python3 .claude/scripts/hubflow.py migrate`, then
`check`, and read the 0.4.0 entry "An agent, not code, puts meeting transcripts into the ledger".
A hub already at schema 4 has nothing to migrate for 0.5.0 (0.5.1 moves it to schema 5).
`HUB-CORE.md`, `PRINCIPLES.md` and both `SKILL.md` are engine files: merge each by intent.

- **A hub records its edition (T32).** Intent: `.hub-template.json` records `"edition"`, and an
  upgrade keeps it. Kits 0.5.0 to 0.11.2 had two editions; kit 0.12.0 has one, `formal` (see the
  0.12.0 section), and reads a manifest with no edition as formal. Files: `tools/hubkit.py`,
  `PRINCIPLES.md` (three principles added), `flow/seed.json` (a `review`
  session; owned, so an existing hub adds it with `hubflow.py session add review --role review` if
  it wants one). Check: `hubkit.py edition --hub "$HUB"` prints the edition, and `hubkit.py status`
  names it.
- **Skip, never hide, in the ledger (T36).** Intent: the principle says what the ledger does with a
  skip: `park ID --until DATE` brings the item back for triage after the date, and `close ID
  --reason human_skip` is final and keeps the human's words. Files: `PRINCIPLES.md`. A hub that
  edited it keeps its own text and adds that sentence.
- **Premises beside the hypothesis (T36).** Intent: every stated hypothesis lists its premises beside
  it. Files: `PRINCIPLES.md` (the hypothesis principle). Check: `grep -c premises PRINCIPLES.md` prints 1 or more.
  Owned file `CLAUDE.md`: it must import the principles (`@PRINCIPLES.md` below `@HUB-CORE.md`, see
  0.4.0); an upgrade never writes `CLAUDE.md`. Check: `grep -x @PRINCIPLES.md CLAUDE.md` prints it.

### 0.4.0 (the hub kit: the principles ship with the hub; `sessions/` leaves the kit)

The db schema is 4. **Database:** run `python3 .claude/scripts/hubflow.py migrate`, then
`check`. The kit is now named the hub kit, part of Sagittarius
(<https://github.com/theTyster/sagittarius>). `HUB-CORE.md` is an engine file: merge it by intent
(the structure tree and "Panes" no longer name `sessions/`).

- **The principles ship with the hub.** Intent: every agent in the hub reads the Sagittarius
  principles in plain words at start. Files: `PRINCIPLES.md` (new, engine: the upgrade adds it).
  Owned file `CLAUDE.md`: add the line `@PRINCIPLES.md` below `@HUB-CORE.md`; an upgrade never
  writes `CLAUDE.md`, and a root file that is not imported is invisible.
  Check: `grep -x @PRINCIPLES.md CLAUDE.md` prints the line.
- **The fail-safe for a missing tool.** Intent: an item with a `kb` ref is treated as blocking
  when `orbit-kb` cannot be asked. No code change: a hub keeps its spec KBs at `specs/<slug>` and
  its `spec-triage` step. Check: `hubflow.py check` exits 0.
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

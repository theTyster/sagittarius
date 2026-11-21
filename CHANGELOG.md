# Changelog

## Versions

Three things have a semantic version (`MAJOR.MINOR.PATCH`). Each names its own version.

| Thing | Version | Where it is stated | What it covers |
|---|---|---|---|
| Sagittarius | 0.5.0 | the last line of `prompt/SAGITTARIUS.md` | the prompt, `orbit-kb`, the System 1 hook |
| Philosophy | 2.0.0 (proposed) | the first lines of `docs/PHILOSOPHY.md` | the beliefs; installed nowhere |
| MindHole Kit | 0.9.0 | `hubkit/kit.json`; a hub records its own in `.hub-template.json` | the hub template and its tools |

What a change of each number means:

- **Sagittarius.** While the major number is 0, the method is under trial and any release can
  change behavior. MINOR moves when a rule of the prompt, a command, a fact, or a rule of
  `orbit-kb` changes what a session does. PATCH moves for words and fixes that change no
  behavior. 1.0.0 is the first release where a session or a KB of an older version must keep
  working until the next major number.
- **Philosophy.** MAJOR moves when a belief is removed or reversed, or the text is reworked.
  MINOR moves when a belief or a position is added, or a position leaves "Under trial". PATCH
  moves for words.
- **MindHole Kit.** As before: the kit version moves with the db schema (`hubkit/UPGRADING.md`).

Who sets the numbers: the agent that cuts a release picks each number by the rules above and
writes it here. The human does not need to choose (Ty, 2026-11-19: "idgaf what version number you
pick as long as its sensible and uses semantic versioning"). What Ty wants is that every release
is tracked: a section below, the version lines moved, and a tag.

Earlier versions, named after the fact so that a report can refer to them:

| Name | What it is |
|---|---|
| Sagittarius 0.1.0 | the tag `v0.1.0-experiment` (2026-07-01) |
| Sagittarius 0.2.0 | the Redesign (informal release); `main` at `7124544` |
| Philosophy 1.0.0 | the text of 2026-11-05 |

## Unreleased

- **The Desk toast (MindHole Kit; spec KB desk-letter-toast, c3, c4, c8).** A Claude Code mod,
  desk-toast, ships with the Desk: source beside `desk.py`, installed by the kit at
  `.claude/skills/desk-toast/` (kit.json `mods`, `hubkit.py`). When a letter gets its `seen` event,
  each session in the hub shows `📨 <session name> saw:` and the first 60 characters of the letter.
  It reads the Desk files only. "saw" means given to the agent, not acted on (the mod's help, and
  `desk.py`'s). Tests: `claude plugin test` of the mod, `desk-test.py` (`case_toast_mod`,
  `case_toast_read_only`), `hubkit-test.py` (`case_desk_toast_c3`, mutant `toast-mod-not-installed`).

## Sagittarius 0.5.0 and MindHole Kit 0.9.0 (2026-11-19)

MINOR for Sagittarius: orbit-kb (the Desk, `checks_that/2`, lint W12, E20) and the System 1 hook
(the fan-out) change what a session does. MindHole Kit 0.9.0: the db schema moves to 8 (0.8.0 moved
it to 7 and was never tagged). Both numbers set by the releasing agent (see "Who sets the numbers").
Ty's word to release, 2026-11-19: "we can land it and get a release for it out with a mindhole
update for the UAT instances". The questions-server spec KB still has open demos and its vote; this
release ratifies none of them.

- **System 1 hook: the fan-out.** The hook reads the human's message part by part and combines the
  answers in code (`s1/fanout.json`, `hook.split_parts`, `hook.combine`). Divergence, change of
  plan, open questions and effort come from the parts; the line can also say `decision reversed in
  message`. `S1_FANOUT=0` gives the earlier behavior. This changes what a session is told, so it is
  a MINOR change. The prompt does not yet name the
  new hint. Evidence and limits: `s1/research/2026-11-15-question-eval/README.md`.
- **After the review of PR 11.** The size check counts the parts: a state with `sentences` and its
  part questions is measured against the per-question and the per-request context (`hook.fan_fit`),
  and the long context is asked for when it is needed. The fan-out's overrides are visible and can
  be switched: the combined log line has `replaced` and the plain answers (`<id>_plain`), and
  `replaces` in `fanout.json` lists what the fan-out may write. `s1watch` shows a fan-out call as
  one short block; `--raw` prints every answer.
- **Sagittarius Signals mod 0.13.0 (`s1/glance/`).** The pane has three tabs on one cursor: now
  (the signals, and why: the message as a strip of parts, with the picked part's text and answers),
  trend (every signal over the session, one cell per judgment) and health (latency, tokens and cost,
  failed calls, and how often each signal says yes, nothing, or no). The mod reads the fan-out's two
  log lines as one judgment. The reversal has a row, a toast quotes the part that fired it.
- **System 1: the live view.** `s1/live.py` prints the hook's judgments of a session as a pane, a
  corner, a toast line or JSON. The status line segment shows a reversal and the number of parts.
- **The Desk shows a demo image (handoff H-0043, Ty, 2026-11-18).** The card that asks the human to
  approve a demo shows the image itself in its right column, not only its file name, and says so when the file changed
  since the KB recorded its digest. The Desk serves only the demo images that its page showed, with
  the token of the page, in a sandbox. Review and send with nothing new written shows the letters
  already sent about the item, instead of asking the human to choose or write. With two or more
  MindHoles, the Desk has one tab per MindHole (with what waits there) and a tab All, instead of a
  collapsible group per MindHole in the rail.
- **The ledger: a park ends on or before the due date (MindHole Kit 0.9.0, db schema 8; Ty,
  2026-11-18).** `flow.db` refuses any write that leaves an item parked past its `--due` date, from
  `park`, `set --due`, the Desk or any other tool; `migrate` names each item that already breaks the
  rule and writes nothing. The Desk refuses such a Park at the review, and sorts its Parked group by
  park end, then by due date (no due date last).
- **The Desk: navigation and the Ledger lane (handoff H-0056, Ty, 2026-11-18).** Every row of the
  rail is a link: a click opens every fold around its item and shows it below the sticky band, and
  so does an anchor in the address. Expand all and Collapse all set every fold. Ledger items have
  their own lane, Ledger: the asks for the human and each session's open items, each named by its
  kind and id, with Answer (an ask), Close, Park until a date, and Note to the session. A ledger row
  of the rail shows its title; its id is in the hover text and on the card. The answered list no
  longer draws the card's form fill behind its answers. Your action also links each reserved ledger ask to its
  Ledger card. A parked ledger item moves to a closed Parked group at the end of the Ledger lane,
  soonest end first, marked "Parked until DATE"; it counts nowhere and leaves Your action until its
  park ends, and then it is back by itself.
- **The Desk, round 2 (hub spec KB `questions-server`, hypothesis h3, Ty's GO of 2026-11-17 after
  three flare laps).** `orbit-kb serve desk` is one Desk at one address for every MindHole on the
  machine: `desk.py join` adds a MindHole in one step, and `desk.py service` writes a systemd user
  unit so it runs again after a reboot. Lanes: Your action (each card names the source of the
  reservation: a policy by name and rule, or the human's dated words), Questions, Running on a
  guess, Project KB (proposed facts to ratify, drafts to push, stale pins), Orphaned (each row with a
  fix the human sends), Answered, KBs. Each item says where it comes from, shows its owner session as
  a badge and its due date, and leads to its KB, hypothesis, premises, claims and checks (in words,
  how each runs, its last run). Every letter goes through a review that shows each receiving session
  and the exact text; the session gets exactly that text. Drafts live in the Desk's own store.
  hubflow (schema 7): `add ask` needs a `kb:` ref (also `kb:/abs/path`, `kb:~/path`) or `--no-kb`;
  `--due`; `--reserved` names its source; an ask needs a context `--note`. orbit-kb: `checks_that(K, Text)`,
  lint W12, and `add` refuses a new check with no words (E20; `shift --checks-that`). MindHole Kit 0.8.0.
- **The Desk (hub spec KB `questions-server`, Ty's GO of 2026-11-17).** `orbit-kb serve
  questions` becomes one page for every hub on the machine (`--hub` repeats). It is dark at every
  load, and `report --html` is too. Each section collapses and opens only when it holds something
  for the human. "Asks that wait on you" is gone: "Human action needed" lists the asks that the
  owner reserved (`hubflow add ask --reserved WHY`, `set ID --reserved WHY|none`) and the vote,
  demo and waiver actions that a spec KB keeps for the human; "Questions for you" lists the other
  asks and those answered in the last 7 days. Each card shows its context (why now, what waits on
  it, who holds it, what is missing), and has a form to answer, diverge (the item stays open) or
  add a requirement (a thread for `review`). Drafts stay on the server until Send. Each hub shows
  its sessions with their inboxes and an Orphaned list. New kit script
  `.claude/scripts/desk.py` (with `desk-test.py`): it stores each response as a letter before the
  write, shows where it is, and its hook tells the owning session at its next prompt or stop; it
  types into a tmux pane only when the owner is idle and its item is `waiting`. `hubflow note ID
  TEXT --by human` now records a person's words. To use the delivery, a hub adds the hooks that
  `desk.py hooks` prints to its `.claude/settings.json`. Contract D26 S14; tests QS32 to QS42.
## Sagittarius 0.4.1 (2026-11-15)

PATCH (Ty, 2026-11-15).

- `s1/glance/`: the Sagittarius Signals mod, a Claude Code plugin that shows the System 1 hook's
  newest judgment as a pane, toasts, a corner or a status line (ticket s1-glance). `install.py` makes a
  new link, `~/.claude/skills/s1-glance`, so every new session loads it. Run `./install.py` again
  after you update.
- The mod's colors: the bar of each signal is colored by its strength; the label of a signal under
  its threshold is dim, and a fired one is bright; a judgment older than 10 minutes is dim in every
  view (c2b).
- The mod draws what System 1 saw, and the error text of a failed call, as plain text: a control
  character (the escape codes of the `/compact` output) no longer blanks the pane (c8b).
- The System 1 hook sends the System 1 model the conversation that Claude holds (ticket s1-rewind-context). It
  follows each message's parent from the last line of the transcript. After a rewind, the
  messages that the rewind removed are not sent. After a compaction, the summary stands in for
  everything before it. Lines that the human did not type (interrupts, slash-command output,
  task notifications, `!` shell lines) are not sent. On the first prompt after a rewind, a prompt
  that matches an earlier prompt of the live branch (difflib ratio 0.9 or more, 15 characters or
  more) starts from that prompt's parent.
- The late fix: when the first call of a prompt was sent another context, a detached process
  asks System 1 once more after the prompt line is written, and logs that call with
  `"kind": "correction"`. Claude Code never waits on it. A new PostToolUse hook, `s1/posttool.py`,
  gives the corrected line to the main agent once, at its next tool call in that turn. Add the
  PostToolUse entry of `s1/README.md` to your settings to get it. `S1_LATEFIX=0` turns the late
  fix off.
- The System 1 workbench, `s1/workbench/` (ticket s1-inspect). The hook reads its
  `questions.json` and its routing, `pipeline.py`, again on every prompt, so a saved edit acts in
  every session at once. A routing gets 9 s (`S1_WORKBENCH_TIMEOUT`) and fails open.
  `s1/workbench/bench/` holds copies that only bench replays read, with `make-live.sh` and
  `take-live.sh` to copy between the two areas (each keeps the files it replaces in
  `bench/backups/`). `S1_WORKBENCH=off` turns the workbench off.
- `s1/s1watch`: prints each System 1 call of the log in a terminal, with the model's answers as they
  came (needs `jq`). `s1inspect.py` no longer has a web page (`--serve`, `--html`).
- `s1/SCHEMA.md`: the state sent to the System 1 model, each answer type, and every field of a log line.
  `test_schema.py` fails when the code writes a field that the file does not name.

## Sagittarius 0.4.0 (2026-11-12)

MINOR: orbit-kb rules and the tempering judge change what a session does. The prompt changes only
in its last line, the version.

- orbit-kb: a claim contested twice, not universal and not asked to be proved, is closed by a Lean
  proof, a decided result of a trusted solver or model-checker model that encodes it (the report
  shows the model and the bounds of its run), or a human waiver (D42, c_k_f_1b). The trust rules
  of a model moved from the discovery module to core (`model_*`); new fact `run_bounds/2`.
- orbit-kb: `shift --red-log FILE` records a red run that only the agent saw as a `seen_red`
  disclosure. The claim stays unfulfilled until a human waives its check (D43, c_k_h_2b).
- `s1/temper.py`: the System 1 model is the only judge of a tempered hypothesis (`j_forbids`,
  `j_faithful`, `j_finding`); Claude only proposes and writes falsifiers (c_s_b). A held-out gate
  set, `s1/fixtures/temper_gate_heldout.json`, was committed before any live run.
- evals (D-C): `run.sh --prompt FILE|none`; `check_leaks.py` reads `evals.json`; a change of plan asks
  for a supersession; seven new cases for the new rules (planning 13 to 17, tools 24, 25), each
  with a held-out twin by a writer who did not see the prompt. Not run yet: no live eval was made.

## Sagittarius 0.3.0 and Philosophy 2.0.0 (proposed; not ratified, not released)

- `prompt/SAGITTARIUS.md` and `docs/PHILOSOPHY.md` are a full rework. The philosophy is one
  hypothesis with five premises and 14 principles that follow from them. The prompt holds the
  orbit (state, compare, sharpen), the light path, the hypothesis, the six signals with one
  response, the vote, honesty, and the delivery.
- The definition of a properly written hypothesis is stated in Lean:
  `docs/philosophy-orbit/2026-11-11/fable/Hypothesis.lean`.
- The build aligns the tools, the MindHole Kit and the checks with the new texts (the spec KB
  `tmp/kb-sagittarius-030`, from the differences that
  `docs/philosophy-orbit/2026-11-11/fable/ALIGNMENT.md` names). The MindHole Kit has its own entry
  below (MindHole Kit 0.7.2, 0.7.1 and 0.7.0).
- VERSION is the one source of the Sagittarius version. `docs/check_version.py` holds it, the last
  line of the prompt and the CHANGELOG heading to one number. `install.py` prints it, and each
  System 1 log line holds it (`sagittarius`), also when the hook runs through the installed link.
- `install.py` makes a fifth link, `~/.claude/sagittarius-s1` (the System 1 hook: it links `s1/`).
  README "Install" is a sequence that an agent follows. Run `./install.py` again after you update;
  `./install.py --check` shows the new link as missing until you do.
- The docs checks hold every rule sentence of the 0.3.0 prompt by a key phrase. There is no limit
  on the prompt length; `docs/PROMPT-MOVES.md` is a dated record of T08; `check_mutants` proves
  each check passes before it fails.
- Panes: intake finds the ticket first; a handoff is a signal, and the pane that receives it
  records it in the KB (`orbit-kb add "signal(...)"`); a peer message with no hubflow row passes
  no work; review returns work to build as a handoff.
- `docs/check_lean.py` runs Lean on `Hypothesis.lean` (the philosophy's theorem count, no axioms,
  each cited theorem name) and on the Lake projects under `kb/proofs` (only the standard axioms).
- System 1 hook: prints `System 1: no view (<reason>)` on a failure and `System 1: unsure` when
  every answer is unsure; only `S1_OFF` is silent; the line only reports; hook and status line
  decide a proof by one rule (`System 1: no signal` when only a held-back tool is sure).
- `s1/observe.py` compares the System 1 log with the session transcripts afterwards, and states its
  limits.
- orbit-kb: every KB holds the hypothesis of its ticket (`hypothesis/3` in core, new kind
  `change`); premises beside it (`premise`, `premise_checked`, `no_premises`, lint W10, W11).
- orbit-kb: the discovery orbit is open until the human approves the ticket after a GO
  (`discovery_end`), and again after `attest back`, which needs a new round of votes; a stale
  approval, or one while not ready, does not close it (ED11, ED12).
- orbit-kb report: KB, Signals (drafted from the records), Hypothesis and Formal fields; an example
  under each claim; theorem statements; a discovery KB gets System, Findings, Scope, Risk and Not
  explored; `show hypothesis`.
- orbit-kb: `show open` and report Open name every blocking item, each thing that blocks
  readiness, and stale pins (WP8); never "Nothing is open" while something blocks. Lean proof:
  `kb/proofs/open_items`.
- orbit-kb: discovery readiness needs an example for each claim (WD10) and blocks on a failing
  preserve check; a red system run of an introduce or retire claim counts as the system result;
  calibration needs a failing and a passing case.
- orbit-kb: GO cannot win while discovery is not ready, and the agent's GO is refused then; the
  human's vote is never refused. Lean proof: `kb/proofs/gate_ready`.
- orbit-kb: `orbit-kb version`; the help names the version; `init` writes it into `kb.pl`.
- orbit-kb: `signal/4` and `lean_back/2`; `orbit-kb shift` and `help shift` for the step from words
  to records.
- orbit-kb: the help follows the 0.3.0 prompt; the move SIGNAL is RESTATE; "Lean definitions", not
  "Lean model"; `orbit-kb withdraw` fixes E19.
- orbit-kb: an agent's relation in a project KB is proposed until a human adds it too
  (`relation_by`, WP9).
- orbit-kb: a build KB records models (`model`, `model_run`, `encodes`); a solver result never
  closes a burn.

## MindHole Kit 0.7.3 (the template; pairs with Sagittarius 0.4.1)

A patch: no schema change (the db schema stays 6). `PRINCIPLES.md` names the prompt's version,
and the orbit-kb copy holds the version of Sagittarius, so the kit version moves up with
Sagittarius 0.4.1. No rule of the template or of orbit-kb changed.

- `PRINCIPLES.md` line 3 names Sagittarius 0.4.1.
- The orbit-kb copy's `share/orbit-kb/VERSION` is `0.4.1`.

## MindHole Kit 0.7.2 (the template; pairs with Sagittarius 0.4.0)

A patch: no schema change (the db schema stays 6). A formal hub's orbit-kb copy changed (K-F and
K-H), so the kit version moves up.

- orbit-kb: a claim contested twice, not universal and not asked to be proved, is closed by a Lean
  proof, a decided result of a trusted solver or model-checker model that encodes it (the report
  shows the model and the bounds of its run), or a human waiver (D42, c_k_f_1b).
- orbit-kb: `shift --red-log FILE` records a red run that only the agent saw as a `seen_red`
  disclosure. The claim stays unfulfilled until a human waives its check (D43, c_k_h_2b).

## MindHole Kit 0.7.1 (the template; pairs with Sagittarius 0.3.0)

A patch: no schema change (the db schema stays 6). The name of the template changed after 0.7.0 was
installed, so the version moves up: two templates never share a version.

- The template is the MindHole Kit, and a hub is a MindHole. Both `HUB-CORE.md` files say they ship
  with the MindHole Kit. `hubkit.py` prints `MindHole Kit <version>` in its install, status and
  upgrade lines.
- The release check holds the rule: the kit version is never below main's, and it is above main's
  whenever the template or the kit tools differ from main's (`kb/tests/test_release.sh` c3).

## MindHole Kit 0.7.0 (the template; its own version line; pairs with Sagittarius 0.3.0)

The MindHole Kit has its own version (`hubkit/kit.json`), apart from Sagittarius. The build picks the
number, and it only moves up: the db schema moves from 5 to 6, so the kit version moves (`hubkit/UPGRADING.md`, section
0.7.0, names each engine-file change since 0.6.0).

- The session index is dropped (db schema 6). Ty, 2026-11-12: "I want to cut this feature. 'drop
  it'": it came from a misunderstanding (meeting transcripts, not Claude Code session logs). Gone:
  `hubflow.py index-transcripts`, `transcripts` with no flag and `--detail`, the tables
  `transcript` and `transcript_msg` with their JSONL (`migrate` drops them), and the re-index at
  `rotate --yes`. Meeting transcripts, the `transcript:` ref, `transcripts --files` and `--find`
  stay.
- The template is named the MindHole Kit (`MindHole Kit <version>`); a hub made from it is a MindHole. One pane launcher in README and
  INSTRUCTIONS. A formal step 6 makes the project KB. The suite prints progress per mutant, and
  `init` prints a line. `check-citations.py` accepts the hub's directory name as a prefix.
- The hub's own HUB-CORE.md carries the inbox rule; the vote gets a home in both editions; a
  handoff example carries its kb ref; a closed ticket proposes its lasting outcomes to the project
  KB.
- PRINCIPLES.md comes from the prompt; the hub has a light path; the mutants run only for a UAT
  install or upgrade.
- A hub records what it runs (`runs` in `.hub-template.json`: the orbit-kb copy and its version,
  the prompt and the pane files with their Sagittarius version), and `hubkit.py status` prints
  them and says whether the files under `~/.claude/sagittarius/` are still the same. The orbit-kb
  copy carries its `VERSION`.
- UPGRADING.md: step 7 and the 0.6.0 section agree (only a UAT upgrade runs the suites); "A hub
  made before the manifest" gains the lessons of a real migration (import of old asks, moving the
  hub directory, references outside the hub, local rules synthesized into the shipped rules, a
  note for running sessions).

## Redesign (informal release)

Ty makes the release. This entry lists what is in the `redesign` branch. The hub kit was version
0.6.0 at that release (`hubkit/kit.json`; T48 c3: db schema 5 shipped as 0.5.1, the kit version moves with the
schema; 0.5.2 keeps schema 5 and fixes the kit defects of the first formal install, T51; 0.6.0, a
version the build guessed, keeps schema 5 and changes the install experience).

### What landed

- Hub kit 0.6.0 (install UX, discovery GO 2026-11-11): setup asks the human what the hub is for,
  first, and `CLAUDE.md` keeps the answer word for word under "What this hub is for" (in the formal
  edition it is also the project KB request); a formal hub gets its own orbit-kb and repo-map at
  `.claude/orbit-kb/` as engine files, and `hubflow.py`, the skills and `HUB-CORE.md` run that copy,
  not the one on PATH; `install` with no `--edition` picks informal; `rotate.sh` and
  `check-citations.sh` are ported to Python (`rotate.py`, `check-citations.py`), so the kit needs no
  bash; a normal install runs no test suite and ends with `hubkit.py status` and `hubflow.py check`,
  and a UAT install (`install --uat`) also runs `hubflow-test.py` and `--mutants`.
- Hub kit 0.5.2 (T51): in an installed formal hub `hubflow-test.py` finds `orbit-kb` on PATH, fails
  (not skips) a real-orbit-kb case it cannot run, and counts skips on its last line; the kit
  `.gitignore` ignores `kb.lock` and `writer.lock`; INSTRUCTIONS step 6 commits `project-kb/` and
  `specs/` in the formal edition; `repo-map --help` prints the usage and exits 0.
- Hub kit (T01): `hubkit/` holds the hub template, its install tool, and its tests. It was the
  separate hubflow-starter repo.
- Philosophy (T02): `docs/PHILOSOPHY.md` has the new beliefs and the way to judge a change.
- Spec KB (T03): `orbit-kb` becomes the spec KB. A predicate is declared on first use. New:
  `query 'blocking(X)'`, `pin`, and due dates (CONTRACT D22).
- Jev client (T04): `s1/jev.py` calls TypeSafe System One. It redacts names and logs each call.
- Flow ledger (T05, hub kit 0.2.0): the hub flow state is a ledger with triage, escalation, capsules,
  transcripts, and skips. Its guard is proved in Lean.
- Small prompt (T08): `prompt/SAGITTARIUS.md` is short. The procedure moved to `orbit-kb help`.
- Panes (T09): the pane prompts follow the phase tree.
- Question view (T10): a view of the open questions (CONTRACT D24).
- Repo map (T12): `kb/bin/repo-map` writes a C4 map of a repo as Mermaid in Markdown.
  `install.py` now links it to `~/.local/bin/repo-map`.
- Tempering (T13): `s1/temper.py` tests the System 1 question set against recorded answers.
- Status line (T14): `s1/statusline.py` shows System 1 in the Claude Code status line.
- System 1 hook (T07): `s1/hook.py` asks Jev about each prompt. It is optional. You paste its
  snippet into `settings.json` yourself. No script writes that file.
- Tracker drafts (T11): `orbit-kb draft blocking` (the blocking items with the stamp), `draft outbound`
  (project KB drafts with their pins; a conflict shows as "decide"), and `pin-item` (records a pin of
  a tracker item from pasted text). Nothing is sent to a tracker (CONTRACT D25).
- Question server (T19): `orbit-kb serve questions` serves the question page live on 127.0.0.1,
  grouped per project, and records an answer from the page as a human answer, under the writer
  lock (CONTRACT D26).
- Release (T15): a "Use it" path in `README.md`, and `kb/tests/test_release.sh`.
- Project KB (T06): an orbit-kb KB with the `project` module (CONTRACT D23). It has one writer at a
  time (a lock), stale pins, outbound drafts, and a conflict rule: when the tracker and a draft both
  changed after the pin, only a human can pick, and the conflict blocks `done`.
- Informal release (T24): hub kit 0.4.0 works with only the five informal stores (flow ledger,
  memory files, weeks, bespoke tools, tracker): Python 3 and git, no Prolog and no Lean.
  `hubkit/README.md` is its document, with an install that a test runs without `swipl` or `lean`
  on the PATH. `HUB-CORE.md` "Without orbit-kb" says what changes and where each fact kind of the
  spec and project KBs is kept. `PRINCIPLES.md` brings the philosophy into each hub. `sessions/`
  left the kit; named sessions are set up outside the hub. The kit is named the hub kit.
- Meeting transcripts (hub kit 0.4.0, db schema 4): an agent, not code, puts what a meeting
  transcript needs into the ledger (Ty: "Its the job of the agent to parse the transcripts and put
  whats needed into the ledger. Not code."). An item points to a transcript with a
  `transcript:NAME@sha256:HEX` ref, and `hubflow.py transcripts --find` finds the file in whichever
  W slot holds it; `transcripts --files` lists the week files with their refs. A new `summary`
  item kind lapses by itself at the first rotation when it is 28 days old, with no triage. The
  T28 meeting parser, its tables and `transcripts --grep` are gone; `index-transcripts` indexes
  Claude Code sessions only, and `rotate --yes` rebuilds that index.
- Byte digests (T38): a digest is now the sha256 of the file's bytes, the same as `sha256sum`.
  Before T38, `orbit-kb` read a file as UTF-8 text, so a digest of a file with non-ASCII text or
  binary data (a PNG demo) was wrong. Such a stored digest now shows as changed: lint W1, a stale
  pin, a reopened flare, and `done` false until the subject is recorded again. Every Lean proof
  whose files hold non-ASCII text (for example `∀` or `→`) shows in `proof_changed(A)`, and its burn
  is open again. To re-prove each one, in each KB:

      orbit-kb query 'proof_changed(A)'          # each attestation A to renew
      head -3 runs/proof-A.log                   # its claim, theorem, and source file
      orbit-kb prove CLAIM PATH/TO/SOURCE.lean THEOREM

  The proof itself does not change; only its recorded digest does. The new proof closes the burn.
  The old attestation still shows in `proof_changed(A)`; that is expected. ASCII files keep
  their digests.

  A pin taken before T38 shows the same change (T40). `orbit-kb show pin P` of a kept tracker
  text that nobody edited says that the digest rule changed, not that someone edited it. To
  re-pin each one, in the project KB:

      orbit-kb show pin P                         # SOURCE, HEX and T of the old pin
      orbit-kb pin-item P2 SOURCE --text-file pins/HEX.txt --changed-at T
      orbit-kb add "concerns(X, P2)"              # for each concerns(X, P)

  A file pin (`stale_pin(P)`): `orbit-kb subject S PATH`, then
  `orbit-kb pin-item P2 S --kind file --changed-at T`. The old pin stays as the record.
  `orbit-kb help build` (Byte digests) has the same recipe.
- Informal hub polish (T36, hub kit 0.5.0): an informal hub's engine shows only the five stores.
  `hubflow.py` reads the edition from `.hub-template.json`: its `--help` and `rotate` output name
  no spec KB, `orbit-kb`, `specs/`, project KB or question server, and `where` and `spec-triage`
  are not commands there (Ty: the informal release "should really only use the informal stores").
  An upgrade of a hub that records no edition picks the edition as install does. The informal
  `HUB-CORE.md` states the README's requirements (bash 4 or later, the POSIX tools). The skip
  principle says what the ledger does (`park --until` comes back, `human_skip` is final), and the
  hypothesis principle and store-map row ask for the premises beside the hypothesis.

### Not in this release yet

- None.

### Limits

- The Lean model's `done` has no project-conflict clause and no flare clause. So the Lean proofs
  about `done` cover only KBs with no project module and no visual (flare) claims.

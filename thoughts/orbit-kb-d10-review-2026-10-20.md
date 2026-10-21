# orbit-kb D10: code review findings and the plan (2026-10-20)

Written before a compaction, so that the work survives it. The D10 record is
`thoughts/orbit-kb-d10-record.md`. A Lean sub-agent is appending to that record now, so
this file is separate.

## State

- D10 is committed (ff5dc24). It is **not finished**. This file lists what is left.
- An independent review of ff5dc24 (read-only, Lean 4.35.0 scratch project) found 13
  defects. The main session reproduced two of them (F8 and F10).
- A second sub-agent runs the Lean phases on the burn rules (SIMULATION, TELEMETRY,
  RENDEZVOUS). Its project is `scripts/orbit-kb/burn_model/` (untracked, not committed).
  Its results go into `thoughts/orbit-kb-d10-record.md`. It may not change build.pl,
  core.pl, the CLI, or the tests. It was told: model F11 (restated claims) as an open
  assumption, and model `waiver_lapsed` as "lapsed or invalid".
- Nothing is pushed. `main` is 19 commits ahead of the remote.

## Decision by Ty (2026-10-20): threat model

Ty: "we don't have a high threat model for this. We expect trust between the agents, the
human, and the code. If we try to constrain any one of those stakeholders too much we run
into problems."

So `orbit-kb prove` checks the proof of an **honest** agent that can make mistakes. It does
not resist an agent that cheats on purpose. Findings F1 to F5 need adversarial Lean on
purpose. They become documented limits, not code changes.

## Decisions by Ty (2026-10-20, after the compaction)

- F11: yes. A claim that supersedes a burning claim inherits the burn.
- The D10 tier is ratified as AIMED, with the Lean phases (SIMULATION, TELEMETRY,
  RENDEZVOUS).
- The 19 commits are pushed (769874a..1dc093e).
- Ty reviews the merged draft next (planned for 2026-10-21) before it goes live.

## Lean phases result (2026-10-20)

The Lean sub-agent finished; `scripts/orbit-kb/burn_model/check.sh` passes. Details are in
`thoughts/orbit-kb-d10-record.md`, section "Lean phases (2026-10-20)". New findings:

- L-F2: `supersedes(c1, c1)`, or a two-claim cycle, makes c1 not current, so every burn of
  c1 closes with no proof. `done` is true and `lint --strict` is clean.
- L-F8: the planned F11 rule `burn(New) :- supersedes(New, Old), burn(Old).` makes the
  program recursive. With a cycle, `query done` exits 2 after 10 s.
- L-F5: `query` answers before lint, so a hand-edited fact that lint rejects can still
  change `done`. Only a hand edit makes such facts. Under the trust threat model: document
  it as a limit.

## Spec for F11 and the supersede cycle (decided 2026-10-20)

- S1. `burn(C)` holds when C has one of the three triggers (contested twice, universal,
  burn requested), or when C reaches, through one or more `supersedes` steps, a claim
  that has a trigger. (Ty's F11 decision.)
- S2. A `supersedes` cycle, including `supersedes(C, C)`, is a lint error. `done` is false
  while any cycle exists.
- S3. The rules stay non-recursive through `supersedes`. The CLI computes the supersede
  closure and the cycle members as derived facts when it reads the KB, as it does for
  `proof_changed` and `waiver_lapsed`. Both engines terminate on every KB.

## Findings

Blocking only against a cheating agent (document as limits; do not fix):

- F1. leanchecker and the digest cover only files under the project root, not under
  `ROOT/.lake/`. A module behind a symlink to outside, in a path dependency, or under a
  `srcDir` inside `.lake/` is not replayed. `lake env leanchecker --fresh MODULE` rejects
  all three, but takes about 34 s.
- F2. The probe runs project code (`enableInitializersExecution`, `loadExts := true`). An
  `initialize` block or a `@[delab]` can print forged `ORBIT-PROVE` lines and exit.
- F3. `lake env` puts `ROOT/.lake/build/bin` first on PATH. A planted `leanchecker` or
  `lean` script passes everything. The proof file can plant it with `#eval` at build time.
- F4. Axioms are allowed by name only. A `prelude` file can declare
  `axiom propext : 1 = 0`.
- F5. The printed statement can be forged with notation (`app_unexpander`). A theorem of
  `True` printed as `∀ (n : Nat), loadSteps n ≤ n`. Only the log's `uses` lines show it.

Should fix (honest mistakes, or cheap):

- F6. The log body and the claim are not bound to the digest. An edited `statement` line
  still counts. A copied log with `claim=c2` and a hand-appended `lean_proof` for c2 gives
  `done` true and lint 0 errors. Fix: check the claim and theorem lines of the log against
  the attestation, and have E9 compare them.
- F7. Inputs not in the digest: a file read with `include_str`; a config file that was
  absent at proof time and added later (`lakefile.lean` over `lakefile.toml`). Fix: record
  absent config files in the log. For `include_str`, document it as a limit, or hash every
  non-`.lake` file of the project.
- F8 (reproduced). `rules.pl` can close a burn: `burn_proved(c1).`, `done.`, or
  `burn_waived(C) :- claim(C,_,_).` gives only W6, so plain lint exits 0. A `lean_proof`
  attest or a waiver in `rules.pl` is E7, but `done` still uses it, and `derived_items`
  scans only `kb.pl`, so such a waiver never lapses. Fix: an error (not W6) when
  `rules.pl` adds clauses to `done`, `burn_proved`, `burn_waived`, `burn_open`,
  `proof_changed`, or `waiver_lapsed`; and keep E7 facts out of the answer.
- F9. A waiver whose due time is not a valid time still counts (`never`, `2020` as an
  integer; a string due crashes s(CASP), exit 2). Fix: an invalid due counts as lapsed.
- F10 (reproduced). The `time` type checks only the shape. `attest waiver c1
  "waive(c1, '2026-99-99T99:99:99Z', 'x')" --by human` exits 0, and the burn closes for
  ever. Fix: validate the date and time values (month 1-12, day for the month, hour 0-23,
  minute and second 0-59).
- F11. A restated claim escapes its burn. A burning claim (universal or burn_requested),
  superseded by an identical claim without the trigger, gives `done` true and
  `lint --strict` 0. Recommended fix, awaiting Ty: `burn(New) :- supersedes(New, Old),
  burn(Old).`
- F12. The BP and PV tests caught 0 of 8 mutants: leanchecker on the main module only
  (MQ); no module/file check (MF); `proof_state` does not recompute the digest (MD); no
  `--no-build` step (MN); config files not in the digest (MC); `proof_state` does not
  compare the claim (MX); the log records the statement as `True` (MS); waivers compared
  with a fixed date (MT). Fix: add tests that kill each mutant that still matters under
  the honest threat model (MD, MX, MC, MF, MN, MS, MT; MQ only if F1 is narrowed).
- F13. Docs that overstate:
  - README section 7, "Only a human may write a waiver": `--by human` cannot be verified.
    Say "the writer says human; orbit-kb cannot verify it".
  - README section 15, "The `lake-manifest.json` file pins the dependency versions":
    false for `"type": "path"` dependencies (sharlean projects), which have no revision.
  - `orbit-kb help prove`, "leanchecker replays the modules of the project": it replays
    only the modules under the root outside `.lake/` (F1).

Checked and fine by the reviewer: every failure of `prove` exits 1 with "Not proved.
Nothing was recorded." and leaves no log, temp file, or kb.pl change; SIGINT exits 130;
`add` and `attest` refuse `lean_proof`; an agent-written waiver is E8; a superseded claim
drops its burn as documented; `query done` agrees under ground and raw s(CASP) with no
ENGINE DISAGREEMENT; every installed toolchain (4.29.0 to 4.35.0) has `leanchecker`.

## Plan after the compaction

1. Wait for the Lean sub-agent to finish. Read its report. Do not edit build.pl, core.pl,
   the CLI, or the tests before it finishes, because its conformance runs read them.
2. Ask Ty about F11 if Ty has not answered.
3. Fix F6 to F10, F12, and F13. Add F11 if Ty agrees. Write the tests first and run them
   red. Run the BP/PV/U tests narrowly while working (`ONLY='^(BP|PV)[0-9]'`), then the
   full suite with `ORBIT_KB_TEST_JOBS=4 heavy bash scripts/orbit-kb/test_orbit_kb.sh`
   and `orbit-kb doctor`.
4. Document F1 to F5 as limits in README section 15, with the threat model sentence:
   `prove` checks the proof of an honest agent; it does not resist a cheating one.
5. Rerun the Lean sub-agent's one command (`scripts/orbit-kb/burn_model/check.sh`, if it
   exists) after any rule change, because a rule change can break conformance.
6. Commit with a pathspec. Then report to Ty, and ask about the push.

## Standing rules

- Commit only when Ty asks; Ty asked for commits of this work. Push only when Ty asks.
- Stage with a pathspec. Never `git add -A`.
- Never touch `shared/link/.ssh/config`, `linux/.config/sway/config`,
  `linux/.local/bin/bom-study`, `linux/.local/bin/sway-scratch-toggle`, or
  `shared/link/.claude/settings.json`.
- Do not delete or clean `thoughts/discovery-orbit/`.
- Run CPU-heavy commands through `heavy`.
- A push that fails with `locked -- run 'git auth'`: ask Ty to run `git auth`.

## Other state of this session (for the summary)

- Commits since the last compaction: ff5dc24 (D10), 9673ab9 (discovery merge), 96fcf61
  and ad2369e (`orbit-kb uses`, D11, after a review), 9d2c05e (records), 529cb2c and
  b6e3499 (Ty's answers to the open questions of the draft).
- Ty's decisions on 2026-10-20, now in the draft: land by the model's judgment, and stop
  for the human on risky changes; do not commit the KB; leave TLA+ out of the build orbit;
  start without a KB and shift up on more than one round of questions, a divergence (four
  signals), a burn (universal or a human request), or a handoff; no "second lap" trigger;
  ask the costliest questions first, then those that settle others; "universal" means a
  domain too large to check case by case.
- Still open for Ty: ratify the D10 tier (AIMED, now with the Lean phases running); review
  the merged draft and declare "mission accomplished"; whether to make the draft live in
  place of `AIDLC.md`; the push.
- A full rerun of the discovery harness stopped at its 20-minute limit (231 PASS, 0 FAIL in
  the part that ran). Recorded in `thoughts/orbital-shifting-merge-record.md`.

## Status (2026-10-20, evening)

D10 is finished: cb7ba90 closes F6 to F13, F11, L-F2 and L-F8, and documents F1 to F5 and L-F5
as limits. Suite 222/222, check.sh ALL PASS. Not pushed.

# AIDLC ticket record (WIFFLED): merge the discovery orbit into the build-orbit draft

- **Ticket:** merge Part 1 of `thoughts/discovery-orbit/discovery-orbit-draft.md` into
  `thoughts/orbital-shifting-system-prompt-draft.md`. Ty asked for it on 2026-10-19 ("yes
  you should do those things", then "commit and continue").
- **Tier:** WIFFLED, because the change is prose in a draft that is not live, nothing
  deploys, and one `git revert` undoes it. Ty ratified the source text (Part 1) and the
  change list (Part 2). Ratified by the agent (technical authority, default roles),
  2026-10-19. Ty can raise the tier.
- **Roles:** default. Ty is the task owner and the reviewer.
- **Record medium:** disk, because the discovery session continues from this merge (a
  handoff).
- **Risk:** a broken cross-reference or a changed sentence can mislead an agent that reads
  the prompt. Others considered, none apply.
- **Deployment:** none. `AIDLC.md` is still the live prompt (`claude()` in
  `shared/copy/.zshenv`).

## Inputs

- Part 1 of the discovery draft, commit d46dd23, sha256 `02e849801181c307`.
- Part 2 of the same file: the changes that the build draft needs (items 1 to 7).
- The discovery module, `shared/link/.local/share/orbit-kb/modules/discovery.pl`, sha256
  `41866cf20122a9cf`.
- The build draft before the merge, sha256 `af28361521de389e`. It holds Ty's uncommitted
  edits (Roles, The orbit, Parallax, quiet failures) and the D10 edits (commit ff5dc24
  committed the code, not the draft).

## Requirements

- R1: The merged prompt holds Part 1 word for word, except the edits that F1 lists.
- R2: Scope sends questions and explanations to a direct answer, a report to the discovery
  orbit, and a clear request to the build orbit (Part 2, item 1).
- R3: "When the human says that it is wrong" sends a wrong problem back to discovery,
  before the steps that rebuild (Part 2, item 2). Step 1 still records the divergence (F2).
- R4: SURVEY and DISPROVE are marked as shared. The build orbit skips SURVEY when discovery
  ran (Part 2, item 3).
- R5: "Discovery module" follows "Build module" in "The knowledge base" (Part 2, item 4).
- R6: The sections that Part 1 points at keep what Part 1 needs. The shared honesty rules
  say that they apply to both orbits (Part 2, item 5).
- R7: The digest rule shows how to put a digest into a fact through the shell (Part 2,
  item 6).
- R8: The resume step also runs `orbit-kb lint` in a discovery KB (Part 2, item 7).
- R9: Ty's edits do not change.
- R10: The D10 text (Build module, BURN) does not change.
- R11: Z3 is the only solver that the prompt names.
- R12: `check_draft.py` passes on the discovery text of the merged prompt.
- R13: The design notes are current. The stale note "s(CASP) is still slow on it" goes
  (the grounded cross-check, D8, made `done` fast). A provenance row names the discovery
  draft.
- R14: Each handoff adds the module of the next orbit. The build orbit adds `build` to a
  discovery KB. The way back adds `discovery`. The only edit by hand is the first line of
  `kb.pl`, followed by `orbit-kb lint` (F1).
- R15: The command table lists `orbit-kb prove`.
- R16: The core vocabulary lists `universal` and `ticket`, which Part 1 uses.
- R17: Each quoted section reference and each move name has a heading.

## Tasks

- **Implementation:** FLIGHT MANIFEST, IGNITION. Scope: the build draft only. The
  discovery draft and the module do not change.
- **Verification:** LANDING MODULE, SPLASHDOWN.

## Checks

`python3 -I thoughts/orbital-shifting-merge-check.py` runs the review checks. Each check
names its requirement. M checks are new behavior; F checks guard text that must not
change. `--discriminate` makes the F checks fail on mutants. `--discriminate-merged` makes
the M checks fail on mutants of the merged text.

## Evidence

- E1, test run (2026-10-19, commit ff5dc24, orbit-kb files clean): the effect of a second
  module. Copies of `scripts/orbit-kb/fixtures/discovery-a` with `uses([discovery])` and
  with `uses([discovery, build])`: `lint` clean on both, and the same answers for
  `discovery_ready`, `discovery_decide`, `model_trusted(M)`, `no_falsifier(C)`,
  `question_waits(Q)`, `to_ask(Q)`, `contested(C)`, `current(C)`, and `finding_lead(F)`.
  Copies of `scripts/orbit-kb/fixtures/valid` with `uses([build])` and with
  `uses([build, discovery])`: `lint --strict` clean on both, the same answers for `done`,
  `under(C)`, `over(X)`, `burn_open(C)`, and `to_ask(Q)`, and the same `show open` and
  `report` output. With build added, `show open` on the discovery KB lists `under c1` and
  `under c2b`: the discovery claims become build obligations.
- E2, test run: `orbit-kb add "uses([discovery, build])"` exits 1 ("orbit-kb init writes
  it. Edit the first line of kb.pl to change the modules."). `orbit-kb init` on an
  existing KB exits 1. `orbit-kb add "change(x1, 'Edit')"` on a discovery KB exits 1 (E2,
  undeclared).
- E3, test run: `check_draft.py` on the committed discovery draft and the module: 6 of 6
  ok, 2,983 words.
- E4, red run: the review checks on the draft before the merge (sha256
  `af28361521de389e`). Expected: M1 to M15 fail, F1 and F2 pass. Actual: as expected. Each
  M check failed because the merged text is absent.
- E5, discriminator run: `--discriminate` on the same draft. Expected: F1 or F2 fails on
  each of 5 mutants. Actual: 5 of 5 failed.

## Findings and decisions

- F1 (requirement defect in Part 1, found by E2): a KB that starts with `--uses discovery`
  cannot get the build module through `orbit-kb`, and the prompt forbids edits by hand. So
  "The build orbit uses the same KB" cannot be followed. Decision (agent, decision
  authority; Ty to review): R14. The one edit of Part 1 adds "Add the build module first."
  to its first handoff bullet. E1 shows that a second module changes no answer on either
  fixture. The cleaner fix is a CLI command that adds a module; it is an open item, not
  part of this ticket.
- F2 (decision, agent): Part 2, item 2 asks for a first step. The step to go back to
  discovery is step 2, after "Record a divergence on the claim". Ty's Parallax text says
  "Record every divergence", and Part 1's "Back to discovery" starts from a divergence.

## Phase log

- FLIGHT MANIFEST: satisfied. Every requirement maps to a review check (matrix below). E4
  is the red run; E5 discriminates the frame checks. Approver: agent, 2026-10-19.
- IGNITION: satisfied. All 17 checks pass on the merged draft. check_draft.py: 6 of 6,
  2,985 words. Approver: agent, 2026-10-19.
- Implementation set: satisfied, agent, 2026-10-19.
- LANDING MODULE: light. Each M check also fails on a mutant of the merged text
  (`--discriminate-merged`, 7 of 7). Two check defects found and fixed before the green
  run (a wrapped reference in M15; a non-failing mutant for M11).
- SPLASHDOWN: Ty asked to finish and commit on 2026-10-19. Ty's review of finding F1 is
  still open.

## Matrix

| Requirement | Task | Tests | Implementation | LANDING MODULE validation |
|---|---|---|---|---|
| R1 | Implementation | M1 | Discovery orbit; Discovery module | |
| R2 | Implementation | M2 | Scope | |
| R3 | Implementation | M3 | When the human says that it is wrong | |
| R4 | Implementation | M4 | SURVEY; DISPROVE | |
| R5 | Implementation | M5 | The knowledge base | |
| R6 | Implementation | M6, F2 | Honesty rules | |
| R7 | Implementation | M7 | Rules for the KB | |
| R8 | Implementation | M8 | Rules for the KB | |
| R9 | Implementation | F1 | none (frame) | |
| R10 | Implementation | F1 | none (frame) | |
| R11 | Implementation | M10 | Discovery orbit | |
| R12 | Implementation | M11 | Discovery orbit; Discovery module | |
| R13 | Implementation | M12 | Design notes | |
| R14 | Implementation | M9 | The knowledge base; Rules for the KB; Handoff; When the human says that it is wrong | |
| R15 | Implementation | M13 | Commands | |
| R16 | Implementation | M14 | Core vocabulary | |
| R17 | Implementation | M15 | all sections | |

## Change after close-out (2026-10-19)

Ty asked for the cleaner fix of F1. `orbit-kb uses MODULE …` (orbit-kb D11) adds a
module to an existing KB. The prompt no longer allows an edit by hand. The Part 1
sentence is now "Run `orbit-kb uses build` first." M9 checks the new wording. Tests
U1 to U4 fail on the CLI before D11 and pass after it. All 17 merge checks, 7 merged
mutants, and 5 frame mutants pass.

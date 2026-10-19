# AIDLC Ticket Record (WIFFLED)

- **Ticket:** discovery-orbit. Finish the discovery orbit's share of the orbital-shifting
  system prompt: the prompt draft, and the orbit-kb `discovery` module with the Example A
  fixture, running under the orbit-kb CLI.
- **Tier:** WIFFLED, because the change is local agent tooling and prompt prose. Nothing
  deploys beyond a symlinked library file, git reverts every change, and no data, money,
  security, or privacy is involved. The SMT and TLA+ work in the fixture is subject
  matter, not formal evidence for this ticket. Ratified by the session agent (technical
  authority), 2026-10-16.
- **Roles:** default. Ty is task owner and reviewer; the session agent holds the other
  roles. The orbit-kb-schema-cli session owns the core, the CLI, build.pl, the README,
  and the test suite. This ticket does not edit them.
- **Record medium:** disk (this file). The chat records from before 2026-10-16 were lost
  in a compaction and the worktree deletion (see RECOVERY.md). Ty confirmed the objective
  and the three design calls in R7 on 2026-10-16 ("we are aligned on all your points").
- **Risk:** operational recovery: a wrong module answer could tell an agent that
  discovery is ready when it is not. The human still decides GO, NO-GO, or HOLD.
  Others considered, none apply.
- **Deployment:** the module file at
  `shared/link/.local/share/orbit-kb/modules/discovery.pl` (live through the
  `~/.local/share/orbit-kb` symlink) and the fixture at
  `scripts/orbit-kb/fixtures/discovery-a/`. Rollback: restore the placeholder module
  from the orbit-kb-schema-cli session, or delete the fixture folder.

Paths below are relative to `thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/`
(the staging folder), unless they start with `shared/` or `scripts/`.

## Requirements
- R1: `orbit-kb lint` on the fixture, with the installed CLI and a library that holds
  the staged module, reports no E code. This includes E12, E13 (atoms and strings), and
  E14 (unsafe negation). Each W code on the base fixture is listed with a reason.
- R2: Every expectation in `fixtures/discovery-a/expected.pl` gives the expected answer
  on the SWI engine. On s(CASP) `--forall=prev`, each one gives the same answer or times
  out. No engine disagreement occurs. The base expectations also hold through
  `orbit-kb query`.
- R3: The module reads attest/6 directly. The three projection helpers
  `discovery_model_result/3`, `discovery_reproduction/3`, and `discovery_divergence/2`
  and their declarations are gone. They were added only for speed, and the
  orbit-kb-schema-cli measurements showed projections 10-30% slower. All answers stay
  the same. `discovery_disproof_filed/1` stays: it is the H1 helper for a `not` literal
  (see C1).
- R4: `harness/run.pl ... only=V` runs only the named variants.
- R5: The harness counts an s(CASP) timeout as CROSS-CHECK SKIPPED, not as a failure or
  a disagreement. It prints the skip count. It exits 0 when SWI passes everything, every
  s(CASP) result passes or is skipped, and no disagreement, lint failure, or H4 failure
  occurs. `ORBIT_KB_SCASP_TIMEOUT` sets the s(CASP) time limit, as it does for the CLI.
- R6: Each REVIEW.md finding 1-15 is closed by a rule, a lint code, or a fixture
  expectation, or it has a recorded disposition.
- R7: Design calls, decided by Ty on 2026-10-16:
  - `discovery_ready` means clean. `discovery_decide` means ready, or the budget is spent.
  - Unsat-core divergences go only on the claims that the human's answer superseded.
  - Discovery is ready with no current claim only on the not_reproduced (NO-GO) path.
- R8: The draft (`discovery-orbit-draft.md`) agrees with the final module. Every module
  predicate, attestation type, and lint code that the draft names exists in the module,
  and the draft's query table covers the gate and its lint codes. Part 1 ("Discovery
  orbit") is shorter than 3,000 words and loses no rule.
- R9: The delivered module and fixture are byte-identical to the validated staging
  files. `orbit-kb --dir scripts/orbit-kb/fixtures/discovery-a lint` gives no E code.
  The orbit-kb test suite gives the same result before and after delivery.
- R10: orbit-kb-schema-cli receives the results and the changed predicate names.

## Tasks
- **Implementation:** FLIGHT MANIFEST, IGNITION. Scope: R1-R8 in the staging folder and
  the draft.
- **Verification:** LANDING MODULE, SPLASHDOWN. Scope: independent review, the full
  two-engine run, CLI conformance, delivery (R9), and the message (R10).

## Phase log
One line per phase or set: criteria met, evidence, approver, date.
- FLIGHT MANIFEST: satisfied. Every requirement maps to a test or review check (matrix).
  Red results: R4a, R4b, R5a (selftest.sh), R3 review check (22 hits), R6 variants
  against the pre-fix module, all six R8 checks. R1 is a frame test whose negative
  control discriminates (E14 and E13 caught). R2 and R7 are existing expectations; the
  ones not red on the pre-fix module are marked for the LANDING MODULE adequacy review.
  Evidence: `evidence/fm-red-runs.md`, tree dirty(035d9e6, 00c6609277e181cf). Bounds:
  s(CASP) 30 s per query (selftest: 0.01 s), SWI 10 s and 1000 answers. Session agent,
  2026-10-16.
- IGNITION: first pass (R3-R5): module sha256 18435d9d9b95fbdb, run.pl d353d6d2afe82304.
  `selftest.sh` 5/5; `lint_cli.sh` clean with the control ok; `cli_conformance.sh` 23/23;
  R3 review check 0 hits; full run SWI 157/157, s(CASP) 136 passed and 21 skipped, 0
  disagreements (`evidence/ignition-full-run.txt`). The counts equal the last fix-pass run
  with the projections, so the revert costs no speed at this scale.
  Second pass (F2, F3, after their red runs `evidence/fm-f2f3-red.txt` and
  `evidence/fm-f2f3-red-recheck-035d9e6.txt`): module sha256 20db37fba8da1c01,
  expected.pl b8550a3599cd132a (168 expectations). `lint_cli.sh` 0 errors, 0 warnings,
  control ok. Full run (`heavy swipl harness/run.pl`, s(CASP) `--forall=prev -s 0`, 30 s
  limit, SWI 10 s and 1000 answers): SWI 168/168, s(CASP) 145 passed and 23 skipped on
  timeout, 0 disagreements, 0 lint and 0 H4 failures, exit 0
  (`evidence/ignition2-full-run.txt`). 20 of the 23 skips are `discovery_ready` or
  `discovery_decide`. Draft (R8): `check_draft.py` 6/6, Part 1 2,998 words.
  Frame re-runs on the final module: `selftest.sh` 5/5, `cli_conformance.sh` 23/23 and
  0 skipped (`evidence/ignition2-cli-conformance.txt`), R3 check 0. Every control still
  discriminates. Decisions recorded: C1, D4. Rollout: copy two paths (R9); rollback: put
  back the saved placeholder module and delete the fixture folder. Satisfied. Session
  agent, 2026-10-16.
- Implementation set: satisfied (FLIGHT MANIFEST and IGNITION satisfied; F1, F2, F3 closed).
  Session agent, 2026-10-16.
- Re-entry (2026-10-16): the LANDING MODULE review (`evidence/landing-review.md`, findings
  LM1-LM24) reopens FLIGHT MANIFEST and IGNITION, so the Implementation set is
  invalidated. Change record: LM1 and LM2 (implementation defects, blocking), LM4
  (test defect, blocking), LM3 (requirement question, blocking until decided; D4 stands
  and gets a pinning test), LM12 (implementation defect), LM8-LM11 (test defects). Earliest
  affected phase: FLIGHT MANIFEST. Invalidated: the IGNITION evidence for module
  20db37fba8da1c01 and expected.pl b8550a3599cd132a; R2 and R6 reruns needed; the draft's
  lint table (ED9) and Verified notes. Unaffected: R3, R4, R5 harness code (only R4c is
  added), the R8 checker. Approver: session agent.
- IGNITION third pass (after the re-entry): module sha256 41866cf20122a9cf, expected.pl
  829a95fc4a0d2000 (260 expectations), run.pl 2d68010e9a1d18fc, CLI b0465f2b34302f45,
  core 739e3e1e0ed7596e. Red first: `evidence/fm-lm-red.txt` (13 failures, LM1, LM2,
  LM12); selftest R4c red. Green: `selftest.sh` 6/6; `lint_cli.sh` clean, control gives
  E14, E13, E12; full run SWI 260/260, s(CASP) 225 passed and 35 skipped, 0
  disagreements, 0 lint and H4 failures (`evidence/ignition3-full-run.txt`);
  `cli_variants.sh` 260/260, 0 skipped, 0 NOTE (`evidence/ignition3-cli-variants.txt`);
  `check_draft.py` 6/6, Part 1 2,998 words. Satisfied. Session agent, 2026-10-19.
- Implementation set: satisfied again. Session agent, 2026-10-19.
- LANDING MODULE (first round): in progress. End-to-end through the live CLI after contract D8 (CLI
  sha256 b0465f2b34302f45, core 739e3e1e0ed7596e, module 20db37fba8da1c01, fresh
  XDG_CACHE_HOME): `harness/cli_variants.sh` sends every variant as a KB directory
  (`emit_variants.pl`) through `orbit-kb lint` and `orbit-kb query -n 0`. Expected
  before the run: 168/168, 0 disagreements, no core E code. Observed: 168/168, 0
  cross-checks skipped, 0 NOTE fallbacks, 0 disagreements, no core E code in any
  variant, base lint clean (`evidence/landing-cli-variants.txt`). So the CLI's s(CASP)
  cross-check confirms the 23 expectations that the harness's raw-program run skipped.
  `lint_cli.sh` on the new CLI: clean, control ok. Independent review: running.
- LANDING MODULE: satisfied. The independent review exercised concurrency-free domain
  probes, CLI write-time checks, fuzz (0 disagreements in 1,185 comparisons), and
  mutation (78.6% killed before the fixes). Its blocking findings LM1, LM2, LM4 are fixed,
  LM3 is pinned to D4, and its own intended answers now pass on both engines through the
  live CLI. Every finding is classified and dispositioned (above). Test-adequacy review:
  `evidence/landing-review.md` section 2. Session agent, 2026-10-19.
- Delivery (R9, R10), 2026-10-19: module and fixture copied; `verify_delivery.sh`: both
  byte-identical, lint on the delivered fixture 0/0 (installed library); orbit-kb test
  suite 176/176 before and after (`evidence/r9-suite-before.txt`, `r9-suite-after.txt`);
  rollback copy `evidence/placeholder-discovery.pl.bak`. Message with results, names,
  README fixes, and requests sent to orbit-kb-schema-cli.
- SPLASHDOWN, with the Verification set: waits for Ty: review of the final evidence and
  this record (ratified tier D1; agent decisions D4, C1, C2; accepted risks F4 and
  LM13-LM19, LM24), approval of integration (a commit on main), and "mission
  accomplished".

## Findings, decisions, and changes
One line each: ID, kind, disposition, approver.
- D1, decision: tier WIFFLED (above). Session agent, 2026-10-16.
- D2, decision: R7 design calls. Ty, 2026-10-16.
- D5, decision: Z3 only in Part 1, with no mention of cvc5 and no second-solver step.
  Models may use Z3's Python API or SMT-LIB 2. Ty, 2026-10-19.
- D6, decision: Ty ratified the draft (sha256 02e849801181c307) for merging into the
  system prompt. orbit-kb-schema-cli was told on 2026-10-19.
- D3, decision: do not resume the old port agent; its context names the deleted
  worktree. Fresh sub-agents get the staging paths. Session agent, 2026-10-16.
- C1, change (FLIGHT MANIFEST, before IGNITION): R3 named four helpers, but
  `discovery_disproof_filed/1` is read under `not` in `model_unfiled_break`; inlining it
  puts body-only variables in the `not` literal (H1, lint E12). R3 now removes three
  helpers. Affected: R3 and its review check only. Session agent, 2026-10-16.
- F1, test defect (found during IGNITION): R2's clause "the base expectations also hold
  through `orbit-kb query`" had no test when FLIGHT MANIFEST was recorded. Earliest
  affected phase: FLIGHT MANIFEST, Implementation set, R2 slice only. Fix:
  `harness/cli_conformance.sh` (frame test; its control is a wrong answer set that must
  not match), run against the 035d9e6 module first, then against the IGNITION module.
  No other artifact is invalidated: the IGNITION edits do not touch the CLI path.
  Session agent, 2026-10-16. Status: closed. 035d9e6 module: 23/23 and the control
  discriminates (`evidence/fm-f1-cli-conformance-035d9e6-module.txt`); IGNITION module
  (sha256 18435d9d9b95fbdb): 23/23, 0 skipped (`evidence/ignition-cli-conformance.txt`).
- F2, implementation defect (draft sync, during IGNITION; R6, REVIEW finding 3): a second
  `model_run(Log, M, NewDigest)` for a log made at an older digest makes the old
  verdicts count again, and WD8 goes quiet. Earliest affected phase: FLIGHT MANIFEST
  (no test), then IGNITION. Fix: a log counts only when it has no `model_run` at an
  older digest. Tests: variants m3_log_reused (red) and m3_rerun_new_log (control). Status: closed
  (module 20db37fba8da1c01; `evidence/ignition2-full-run.txt`).
- F3, implementation defect (draft sync, during IGNITION; R6, REVIEW finding 7): ED7
  guards only the supersession of a refuted claim. An agent can supersede a contested
  claim with no human answer. Fix per D4. Tests: variants m7_launder_contested (red) and
  m7_ratified_contested (control). Status: closed
  (module 20db37fba8da1c01; `evidence/ignition2-full-run.txt`).
- D4, decision: "only the human changes the scope" applies to a disputed claim: refuted,
  or contested by a claim divergence. Superseding an undisputed claim stays allowed,
  because the human approves the whole ticket at GO. REVIEW finding 7 asked for every
  supersession; this is narrower on purpose. Session agent (decision authority),
  2026-10-16; listed for Ty's review.
- F4, accepted residual risk (draft sync): only the human may raise the lap budget, but
  `budget/2` is a plain fact and no rule checks who wrote it. The draft states the rule
  and lists it as an open question. Follow-up: a `decision` type for a budget raise.
  Session agent, 2026-10-16; listed for Ty's review.
- F5, out of scope, follow-up owner orbit-kb-schema-cli (draft sync): `model_run/3`
  needs a digest, but the shared rule says "Never type a digest". Mitigation in the
  draft: paste the digest that `orbit-kb subject` prints through the shell. A wrong
  digest fails loud (WD8). Request: `orbit-kb run` records the digests of named inputs.
- F6, non-blocking, no change (draft sync): the "Small" size now needs one claim whose
  check is the reproduction (follows R7); Example B shows a report while a question
  waits, and the draft labels it. Records that no rule reads (a `hypothesis(H)`
  divergence, a time limit in a note) are allowed.
- N1, skipped documentation update (owner orbit-kb-schema-cli; this ticket must not
  edit it): `shared/link/.local/share/orbit-kb/README.md` is stale for discovery. Its
  module table calls the module a placeholder; its reserved-name list has `reason/2`
  and lacks `model_run/3`, `discovery_evidence/2`, `discovery_decide/0`, the
  `discovery_*` and `model_*` helpers, and the WD/ED lint codes; its harness section
  names the deleted worktree path and lacks `only=` and `ORBIT_KB_SCASP_TIMEOUT`; its
  example expects `to_ask(Q) = [q1]` for cf1_no_answer, which D5 changed to none. The
  corrections go in the R10 message. Closed 2026-10-19: orbit-kb-schema-cli updated the
  README and the contract's reserved names, verified the delivery (lint 0/0, suite
  176/176, doctor ok), and logged the four CLI requests as contract change D9.

- LM dispositions (review `evidence/landing-review.md`; module after fixes: see
  IGNITION third pass):
  - LM1, implementation defect, fixed: only a `refuted` disproof files a break. Red:
    pl_disproof_abstained, pl_disproof_inconclusive (`evidence/fm-lm-red.txt`).
  - LM2, implementation defect, fixed: a `model(M)` divergence counts on any subject
    except a stale run log of M. Red: pl_div_on_system_log. Kept: pl_div_run_fixed.
  - LM12, implementation defect, fixed: a target is derived from a root model; new lint
    ED9 flags cycles, self-loops, and chains. Red: pl_derived_self_loop, pl_derived_cycle.
    Change C2: the review expected only m_now to diverge on the self-loop; with the root
    rule m_target (no longer a target) diverges too. The expectation follows the rule.
  - LM3, requirement question: D4 stands. Pinned by pl_agent_supersedes_unrefuted
    (unratified none, ready true). Listed for Ty's review.
  - LM4, test defect, fixed: variants min_reproduced, min_not_reproduced,
    min_nr_untagged, min_request_only (R7 call 3), qw_hypothesis_question, qw_cf1,
    pl_no_hypothesis, pl_to_ask_blocks, pl_disagree_root_cause, pl_diverging_explorer.
  - LM5, LM6, test defects, partly fixed: 36 review probe variants imported
    (`scratch/gen/landing_variants.pl`). Remaining surviving mutants (TLA results outside
    sanity, some join keys) are accepted as residual test gaps.
  - LM7, test defect, closed by evidence: `harness/cli_variants.sh` cross-checks every
    expectation, every true gate included, on s(CASP) through the D8 CLI with no skip.
  - LM8, test defect, fixed: the perf variant's comment no longer claims a time check.
  - LM9, test defect, fixed: an unknown `only=` name fails (selftest R4c, red then green).
  - LM10, test defect, fixed: `lint_cli.sh` matches E, ED, W, and WD codes; its control
    covers E12.
  - LM11, test defect, fixed by hand: stale Part 4 text corrected. The checker still
    checks names and arities only (accepted).
  - LM13 (a divergence on the model file never clears), LM14 (ED6 on reruns of one
    explore label), LM15 (normal_case, root_cause, together results are not read), LM16
    (an earlier answer ratifies a replacement), LM17 (ready with ED1, ED2, or ED8; the
    draft says lint errors block GO), LM18 (no default budget, lap gaps), LM19 (two
    hypotheses without the question), LM24 (free-text calibration case): accepted
    residual risk. Each fails toward "not ready" or is caught by lint or the human at GO,
    except LM16, LM17, LM19, which rely on the human reading the report. Session agent,
    2026-10-19; listed for Ty's review.
  - LM20 (an agent can write `--by human`), LM21 (a stale GO approval is silent after
    re-recording), LM22 (contract and README reserve old names): out of scope, owner
    orbit-kb-schema-cli; in the R10 message.
  - LM23: review tooling only; no change.

## Matrix
| Requirement | Task | Tests | Implementation | LANDING MODULE validation |
|---|---|---|---|---|
| R1 | Impl | `harness/lint_cli.sh` (frame; negative control) | `modules/discovery.pl` | `lint_cli.sh` on CLI b0465f2b; delivered-fixture lint 0/0 |
| R2 | Impl | `fixtures/discovery-a/expected.pl` via `harness/run.pl` (260 expectations after the LANDING re-entry); CLI clause: `harness/cli_conformance.sh` (F1) | `modules/discovery.pl`, `fixtures/discovery-a/kb.pl` | `cli_variants.sh` 260/260 through the live CLI, 0 skipped |
| R3 | Impl | review check: grep for the three projection names = 0; R2 as frame (adequacy review) | `modules/discovery.pl` | review: mutation 78.6% before fixes; no helper reintroduced |
| R4 | Impl | `harness/selftest.sh` R4a, R4b | `harness/run.pl` | LM9 found and fixed (R4c) |
| R5 | Impl | `harness/selftest.sh` R5a; controls R5b, R5c | `harness/run.pl` | harness skips counted; CLI cross-checks all 260 |
| R6 | Impl | expected.pl variants per finding (`evidence/fm-red-runs.md` table); finding 15: review check | `modules/discovery.pl`, fixture | 36 review probes imported; LM1, LM2, LM12 fixed |
| R7 | Impl | expected.pl: cf7_budget_spent, m6_budget_hides, cf8_draft_dormant, m5_not_reproduced, base `contested(C)` | `modules/discovery.pl`, `kb.pl` | min_* variants (LM4); D4 pinned |
| R8 | Impl | `harness/check_draft.py` checks 1-6 | `discovery-orbit-draft.md` | LM11: Part 4 corrected by hand |
| R9 | Verif | `harness/verify_delivery.sh` (red before delivery: module differs, fixture missing, lint exit 2); test suite before and after | copy to `shared/.../modules/discovery.pl`, `scripts/orbit-kb/fixtures/discovery-a/` | `verify_delivery.sh` ok; suite 176/176 before and after |
| R10 | Verif | | | message sent 2026-10-19 |

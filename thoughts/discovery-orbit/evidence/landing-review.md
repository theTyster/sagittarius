# LANDING MODULE review: discovery module, Example A fixture, harness (2026-10-16)

Independent adversarial review and test-adequacy review. The reviewer did not write the code.
Nothing outside `scratch/landing/` and this file was edited. No git command that changes state was run.

- **Final version under review:** `modules/discovery.pl` sha256 `20db37fba8da1c01` (F2/F3 change,
  landed during the review), `fixtures/discovery-a/expected.pl` `b8550a3599cd132a` (168
  expectations), `kb.pl` `1d45b70000296dcd`, draft `13006971e933d15e`.
- **First version reviewed:** module `18435d9d9b95fbdb` with the 157-expectation fixture
  (`586f6b55a08741bb`, equal to HEAD 035d9e6). The mutation and probe runs were repeated on the
  final version; the findings below are for the final version unless a row says otherwise.
- **Tools:** SWI-Prolog 9.2.9, s(CASP) 1.1.4 (`--forall=prev`), orbit-kb CLI `dccdec8be9a6e4ca`
  until 16:51:35, then `b0465f2b34302f45` (contract D8, grounded cross-check); every CLI probe
  was re-run on `b0465f2b34302f45` with an empty `XDG_CACHE_HOME` (§3),
  core.pl `739e3e1e0ed7596e`, build.pl `5bdf76a6afe714c9`, harness run.pl `d353d6d2afe82304`,
  lint.pl `b802c19dea8859d7`, selftest.sh `88db06ae55b69d2e`, cli_conformance.sh
  `da37ec550d7ad28b`, lint_cli.sh `f2bc48d652bad3ec`, check_draft.py `6ac615b87fd91442`.
- Paths: `S` = `thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging`,
  `L` = `S/scratch/landing`. All hashes are the first 16 hex digits of sha256.

## 1. Findings

Class: RD requirement defect, ID implementation defect, TD test defect, AR accepted-risk
candidate, OOS out of scope (owner named).

| ID | Class | Blocking | Summary | Evidence |
|---|---|---|---|---|
| LM1 | ID | yes | A `disproof` with verdict `inconclusive` or `abstained` counts as "filed". When a model breaks a current claim (`preserve(C)` sat, or a target `bad_case` sat), such a disproof removes ED5, the claim is not refuted, and `discovery_ready` holds with lint clean (0 errors, 0 warnings). `discovery_disproof_filed/1` ignores the verdict; the draft says "ED5: File a `disproof`" with no verdict, and the core allows all three verdicts. Fix: match `verdict(C, refuted)` only. | §3 probes L1a, L1b (both engines agree on `model_unfiled_break` = none); CLI-P1 (`discovery_ready` true, cross-checked, lint clean); mutant x269 (refuted-only) survives, so no test pins the verdict |
| LM2 | ID | yes | A `divergence` with `model(M)` counts only when its subject is M or a current run log of M. On any other subject (the natural one is the system log that disagrees) it is ignored: M stays trusted, no ED3, `discovery_ready` holds, lint clean. Draft FLYBY 2 ("record ... a `divergence` with `model(M)`") does not name the subject. Fix: count any subject except a stale run of M, or add an E lint for a model divergence on another subject, and name the subject in the draft. | L2; CLI-P2; mutants m023, m123, x070, x072, x229, x266 survive (no test pins the subject) |
| LM3 | RD | yes, until decided | The agent alone can supersede a claim that is neither refuted nor contested: no ED7, `discovery_ready` holds (only W5 for the check on the old claim). F3 widened ED7 to "refuted or contested", not further. The draft says "Only the human changes the scope" and REVIEW 7's fix asked for "a supersedes fact with no human answer or decision behind it". R6/R7 do not decide whether an undisputed supersession needs a human. Decide; then either widen ED7 (mutant m180 = x267 is that rule) or record an accepted risk and pin it with a test. Either way no test today tells the two apart. | L6a; CLI-P3; m180/x267 survive on the 168 fixture |
| LM4 | TD | yes | Conjuncts of the R7 gate have no discriminating test, so deleting them changes no answer: `discovery_has_outcome` and its NO-GO clause (R7 call 3; every variant has a current claim), `not some_question_waits` (its only guard, cf1_no_answer, is masked since F3: deleting q1's answer now also gives ED7 on c2b), `not any_to_ask`, `some_model_problem` for divergence and for solver disagreement, and `some_hypothesis`. The module behaves as decided (probes pass); the tests do not show it. Fix: add the probe variants named in the evidence column. | mutants m010, m101, m102, m195, x027, x207, x208, x272 (call 3); m065, m198 (question waits); m204; m069, m072; m193, x279. Kill variants: `L/fixtures/minimal`, `L/fixtures/qwait`, L9, L10, L11, L12 (all but x027, which needs a NO-GO result on an untagged log while another subject is tagged) |
| LM5 | TD | no | Identity and masking gaps in the tests for REVIEW 1, 2, 3, 4, 13: TLA results `reached`/`violated`/`holds` are tested for `sanity` only (12 mutants survive; Example B needs them); the disproof's claim is not pinned (x017, x112); `applies(C)` unknown as the only check (m142, x098); the verdict-digest and calibration-digest checks mask each other, a stale calibration counts once the model has any current run (x052), the mutation digest is untested (x263, x264, x265, m114, m116), and WD8 may be dropped or added for the wrong results (x043, x183); model-artifact exclusion and system tags for test results and hypothesis results (m002-m004, m094, m098, m100, x020, x024, x025); a divergence on a stale run (m123) and the target's own divergence (m138). | §4 survivors; probes L1c, L3, L3c, L3d, L8a-e, L15a-c, L16, L18a-b pass on the module and kill all but x009, x010, x013, x217, x218, x265, m116, m138 |
| LM6 | TD | no | Identity gaps for REVIEW 6, 7, 11, 12: no variant reaches a raised budget (x167); `answered` in `discovery_ratified` and ratification via the new claim are untested (m178, m182, x153), and so are the claim identity in `discovery_disputed` (x155, x156, x159); k_no_derived passes because m_target diverges once `derived_from` is gone, not because inheritance needs it (m133, x085, x086, x090); k_no_sanity_target has no `no_falsifier` expectation, so REVIEW mutant m047 still survives (x127), with x123, x125; a reason for another rule of the same model excuses `clamp` (x149, x152, x175). | §4; probes L5d, L6c, L6d, L17a-c kill all but x155, x085, x123, x125 |
| LM7 | TD | no | R2's two-engine check never confirms a positive gate in the harness. All 11 `discovery_ready true` expectations of the IGNITION run were CROSS-CHECK SKIPPED (raw s(CASP), 30 s); in this review 0 of 25 positive gates on full-size fuzz KBs and 0 of 17 SWI-true gate answers in the probes were cross-checked (7 negative gates were). Only the CLI (grounded) cross-checks the base gate (cli_conformance: 0 skipped), and no variant goes through the CLI in the reviewed tests. The implementer's new `harness/cli_variants.sh` (all 168 through CLI b0465f2b; not reviewed here) can close this if it counts cross-checked gate answers. | `evidence/ignition-full-run.txt`; `L/out/fuzz-pert.txt`; `L/out/probe-run.txt`; `L/out/frame-new.txt` |
| LM8 | TD | no | perf_12_claims_6_models (REVIEW 9) says "Each query must take under 2 s on s(CASP)". The harness does not check time; in the IGNITION run 5 of its 10 queries timed out at 30 s and were skipped. Finding 9 is closed only by R5's skip disposition; the variant is an SWI frame with 0 unique mutant kills. | ignition-full-run.txt; §2 marked-test table |
| LM9 | TD | no | Harness: `only=NAME` with an unknown name runs nothing and exits 0 ("0/0 expectations passed"). selftest.sh does not test it, nor that a disagreement, a lint failure, or an H4 failure exits 1. | `L/out/frame-new.txt` (only-typo rc=0) |
| LM10 | TD | no | lint_cli.sh (R1): its grep `^ *E[0-9]` never matches module codes (`ED1`...); it relies on the exit code, which does catch them. It does not check W codes, so R1's "each W code is listed with a reason" has no test (none exist today; `lint --strict` is clean). The negative control has no E12 case. | `L/cli/kb_ed1` run (rc 1, grep count 0); `L/out/frame-new.txt` |
| LM11 | TD | no | check_draft.py (R8) checks names, arities, codes, and a word count of Part 1 only. Check 5 matches only a predicate directly inside backticks, not inside a quoted command. No check covers meaning (for example the gate row or the unsat-core recipe), and none covers Part 4: its design note "Scope (finding 7)" (line 769) still says "replaces a refuted claim", while ED7 now covers refuted or contested. Part 1 is 2998 words: 2 words of margin. All six checks pass now. | `python3 -I S/harness/check_draft.py` on 20db37fb; draft line 769 |
| LM12 | ID | no | A `derived_from` self-loop or cycle makes an existing-world model count as "derived", so its `bad_case` is no longer checked: a model that misses the bad case stays trusted and `discovery_ready` holds. The CLI accepts the facts; no lint flags them. | L4a, L4b; CLI-P4 (`discovery_ready` true, lint 0/0) |
| LM13 | AR | no | A divergence attested on the model file itself can never be cleared: after the fix and fresh runs at the new digest, the model still diverges. The draft says "fix the model"; the agent must use a new model id or record divergences on run logs. Loud (over-blocks). | L3b |
| LM14 | AR | no | ED6 fires on re-runs of one exploration with one label (draft FLYBY 6: "block each one, and run again"). Loud false positive; distinct `explore(T)` labels avoid it. | L13; CLI-P5 |
| LM15 | AR | no | `normal_case`, `root_cause`, and `together` verdicts are never read. A normal case where the model disagrees (sat in the fixture's polarity) leaves the model trusted; a10 (`together` unsat, current digest of m_target) is silent. The polarity of these checks is not defined. | L14; base probe L22 |
| LM16 | AR | no | Ratification is any human answer about the claim, at any time: an answer to an unrelated dormant question, given before the refutation, ratifies the replacement. The KB has no time order. | L6b |
| LM17 | AR | no | `discovery_ready` holds while module errors ED1, ED2, or ED8 fire. The draft's query table documents this ("no WD1, WD3, WD7, or ED3 to ED7"), and honesty rule 7 makes lint a second gate. | L7a, L7b; `L/out/cli-probes.txt` (kb2: ED8 and `discovery_ready` true, CLI b0465f2b) |
| LM18 | AR | no | Budget: no default budget (the draft's "three laps by default" depends on the record step); `lap_done` numbering with a gap is never spent (`lap_done(B)` must match exactly; mutant x270, `lap_done(L), L >= B`, is the robust form and survives the fixture); a lowered budget is ignored (largest counts, as declared). | L5a, L5b, L5c |
| LM19 | AR | no | Two hypotheses, each with a system result: ready holds without the "one ticket or two" question (draft SIGNAL 4). | L21 |
| LM20 | OOS (orbit-kb-schema-cli) | no | Writers are self-declared: an agent session can write `decision` or `approval` with `--by human`. E8 rejects only the default agent writer. | CLI C1, C1b |
| LM21 | OOS (orbit-kb-schema-cli) | no | A stale GO approval is visible only as W1 until `orbit-kb subject` re-records the ticket; after that lint is clean and only `stale(A)` shows it. `discovery_ready` stays true. | CLI GO probe C3 |
| LM22 | OOS (this session for R10; owner of contract and README: orbit-kb-schema-cli) | no | The contract (line 310) and README (line 888) still reserve `reason/2` and `rule_has_reason/1`; the module has `reason/3`, `rule_has_reason/2`, and many new rule names. R10 must carry them. | contract, README |
| LM23 | OOS (this session, review tooling) | no | `scratch/review/mut/gen_mutants.pl` must be called with `--` (SWI 9 loads a trailing `*.pl` argument as a source file, so the module is consulted and main gets no arguments). `run_mutants.py` takes its baseline from `cwd/modules/discovery.pl`; from `scratch/review` that is the pre-fix module, so running it there gives a wrong baseline. This review ran it from `L/rh`, which holds the module under test. | §4 |
| LM24 | RD | no | REVIEW 14 P15 (a calibration case is not tied to system evidence) has no closure and no recorded disposition: `case(Text)` is free text. R6 needs one or the other. | module decl of `model_result`; draft Part 4 lines 758, 767 |

Resolved during the review, not findings: the draft's "Small" size conflicted with R7 call 3; the
draft of 16:01 now has "one claim whose check is the reproduction". F2 (log reuse) and F3
(contested supersession) were found by the implementer and landed as 20db37fb.

## 2. Test adequacy, per requirement

### R1 (lint, frame test)
- Claim object: the staged module plus the fixture, under the installed CLI lint. The test key
  is the exit code plus a grep for `^ *E[0-9]`. The exit code catches module ED codes (checked:
  a copy without `discovery_evidence(log4417, system)` gives ED1 twice, exit 1, grep count 0).
- Not caught: W codes on the base fixture (LM10); E12 in the module (the control has E13 and E14 only).
- Result on 20db37fb: `Summary: 0 error(s), 0 warning(s).`, both checks ok; `lint --strict` clean.

### R2 (expectations on both engines, base through the CLI)
- Claim objects: each expectation is a claim about one goal's answer set on one variant KB. The
  key is the set of bindings of the named variables; `_` variables are hidden.
- Identity: `lint_issue(Code, Id, _)` identifies the attestation, model, claim, or question by
  id, which is the right object for WD3, WD5, WD8, ED1, ED2, ED4 (attestation), ED3, ED6, WD2
  (model; ED6 does not name the check, but the base `none` expectation catches a broken
  check join), ED5, ED7 (claim). Keyed-by-code expectations do not catch extra codes of other
  kinds in the same variant; the base `lint_issue(Code, Id, _)` = none covers the base only.
- Masking: `discovery_ready` = none in variants with several open items does not show which
  conjunct fails. This hides LM4. `model_trusted(M)` lists models but not why: k_no_derived passes
  for the wrong reason (LM6). Expectations such as `attest(A, reproduction, S, _, agent, _)` test
  fixture data, not the module.
- s(CASP) side: LM7. The R2 wording ("the same answer or times out") is met; the positive
  gate is SWI-only in the harness.
- CLI clause: cli_conformance.sh, 23/23 base expectations, 0 cross-checks skipped, control ok, on
  both module versions; the 23 base goals again on CLI b0465f2b with an empty cache (§3), no NOTE
  and no disagreement. Variants are not run through the CLI by the reviewed tests.
- Engine agreement: 0 disagreements in this review (§5 and §3).

### R3 (no projection helpers)
- Claim object: the three helper names. `grep -cE 'discovery_(model_result|reproduction|divergence)\b'` = 0 on both versions.
- Not caught: the check is by name. The module now has `model_verdict/4`, `model_calibration/3`,
  and `model_mutation/3`, which project `attest/6` joined with the digest filter. They carry
  meaning (digest binding), so R3's intent holds, but no measurement checks R3's rationale
  (projections were slower). "All answers stay the same" is not literal: R6 changed answers on
  purpose; R2 is the frame.

### R4, R5 (harness only= and timeouts)
- selftest.sh: R4a, R4b, R5a red before IGNITION (fm-red-runs.md), now 5/5 ok on both module
  versions; the R5b and R5c controls discriminate. Not caught: LM9.

### R6 (each REVIEW finding closed)

| REVIEW finding | Closed by | Gap in the test (final version) |
|---|---|---|
| 1 model disagrees with system | `model_diverges/1`, ED3 | divergence subject (LM2); the model-file clause and a stale-run divergence untested; target's own divergence (LM5) |
| 2 verdicts ignored | WD5, ED4, ED5, ED6, `model_breaks` | disproof verdict (LM1) and claim; TLA results; applies unknown; ED6 gate conjunct (LM4, LM5) |
| 3 trust after a model edit | `model_run/3`, WD8, F2 | verdict and calibration digests mask each other; mutation digest (LM5) |
| 4 model artifacts as system evidence | `discovery_evidence/2`, ED1 | artifact exclusion and tags untested (LM5) |
| 5 empty inputs ready | `some_hypothesis`, `discovery_has_outcome` | both untested (LM4) |
| 6 budget hides problems | split gate, largest budget | raised budget reached untested (LM6) |
| 7 laundering by supersession | ED7, F3 | undisputed supersession undecided (LM3); `answered` and the new-claim path untested (LM6); stale ratification (LM16) |
| 8 recipe contests the winner | data (one divergence on c2) | no test that a contested current claim's question blocks (`not any_to_ask`, LM4) |
| 9 s(CASP) cliff | R5 skip disposition | perf variant's time claim not enforced (LM8) |
| 10 cf1 vs D5 | expectation fixed | guard masked since F3 (LM4) |
| 11 coverage | k_* variants | m047 survives (x127); k_no_derived (LM6) |
| 12 reason by rule | `reason/3`, cf5c | rule identity untested (LM6) |
| 13 global touch | WD7, WD6 | hypothesis-touch tag untested (LM5) |
| 14 trust inputs | ED2, minor_* variants, b2_tla_sanity | `case(Text)` is still free text (P15 not closed; no disposition recorded) |
| 15 contract drift | review check | `reason/2` still reserved in contract and README (LM22) |

### R7 (design calls)
- Call 1 (ready = clean; decide = ready or budget spent): cf7_budget_spent, m6_budget_hides,
  m6_budget_raised discriminate the split. Several conjuncts of "clean" do not (LM4).
- Call 2 (unsat-core divergence only on superseded claims): a recipe, not a rule. The base
  `contested(C)` = [c2] and cf8 test the fixture data; no test can fail on a module change here.
- Call 3 (ready with no current claim only on the NO-GO path): no test. m5_not_reproduced keeps
  current claims. `L/fixtures/minimal` shows the module behaves as decided (12/12, both engines).

### R8 (draft agrees with module)
- check_draft.py: all six FAIL on 18435d9d with the old draft; all six ok on 20db37fb with draft
  13006971. Adequacy limits: LM11. Semantic spot checks of the new draft agree with the module
  (gate row, unsat-core recipe, model digests, ED7 text). One semantic gap: the draft does not
  name the subject of a model divergence (LM2).

### Tests that fm-red-runs.md marks for this review
Mutation on 20db37fb (§4). "Unique kills" = mutants that only this variant kills.

| Test | Purpose | Kills / unique | Fails on the relevant broken behavior? |
|---|---|---|---|
| cf8_draft_dormant | REVIEW 8 | 110 / 0 | No. The relevant fault is data (a divergence on a current claim). The test pins the fixture, not the module; `not any_to_ask` can be deleted (m204). |
| cf1_no_answer | REVIEW 10 | 4 / 0 (2 unique on 18435d9d) | Not since F3: ED7 on c2b masks the question-waits gate (m065, m198 survive). `L/fixtures/qwait` kills both. |
| k_no_sanity_now | REVIEW 11 | 10 / 4 | Yes. |
| k_no_sanity_target | REVIEW 11 | 34 / 0 | Partly. No `no_falsifier` expectation, so m047 (x127) survives. |
| k_no_derived | REVIEW 11 | 31 / 1 (x083, unrelated) | No. m_target diverges once `derived_from` is deleted; the inheritance literal (m133) survives. |
| k_unencoded_claim | REVIEW 11 | 51 / 2 | Yes. |
| k_kinds | REVIEW 11 | 43 / 14 | Yes. |
| b2_break_filed | REVIEW 2 | 20 / 3 | Partly. It does not pin the disproof's claim (x017, x112) or verdict (x269, LM1). |
| m4_repro_only | REVIEW 4 | 9 / 2 | Yes. |
| m4_check_is_repro | draft fit | 112 / 0 | Frame only. |
| m5_question_from_hypothesis | ED8 | 13 / 4 | Yes for ED8. A `discovery_ready` expectation would also guard the question-waits gate. |
| m7_ratified | REVIEW 7 | 112 / 2 | Partly. `answered` (m178) and the new-claim path (m182) survive. |
| perf_12_claims_6_models | REVIEW 9 | 141 / 0 | No (LM8). |
| Finding 15 review check | REVIEW 15 | n/a | `has_digest` gone; run.pl says H4; `calibration` is no longer reserved (D4). Contract and README drift remain (LM22). |

## 3. Adversarial probes

Fixture `L/fixtures/probe` (copy of discovery-a, own `expected.pl`). Each expectation is the
intended answer, written before the run, with its source in a comment. Run on 20db37fb:

    cd L/h && heavy timeout 5400 swipl L/h/harness/run.pl L/fixtures/probe L/lib

`L/h/harness/run.pl` is a byte copy of `S/harness/run.pl` (same sha); it writes its assembled
programs under `L/h/scratch` instead of `S/scratch`. Result (`L/out/probe-run.txt`): SWI 65/93,
s(CASP) 53/93 and 25 skipped (timeouts), 0 engine disagreements, 3 lint failures (all in L19,
on purpose: E3, E4). A SWI-only preview on 18435d9d gave the same answers.

| ID | Variant | Intended (source) | Module answer | Verdict |
|---|---|---|---|---|
| L1a | pl_disproof_abstained | break of c2b stays open; ready none; ED5 c2b (ED5 text, REVIEW 2, DISPROVE) | unfiled break none (both engines); ready true (SWI; s(CASP) skipped); no ED5 | LM1 |
| L1b | pl_disproof_inconclusive | same | same | LM1 |
| L1c | pl_disproof_other_claim | a disproof of c1 does not file c2b's break | as intended | pass |
| L2 | pl_div_on_system_log | m_now diverges; ready none (draft FLYBY 2, REVIEW 1) | no divergence; ready true | LM2 |
| L3 | pl_div_on_model_file | m_now diverges | as intended | pass |
| L3b | pl_div_model_file_fixed | after fix and fresh runs: no divergence, trusted | still diverges, untrusted | LM13 |
| L3c | pl_div_run_fixed | divergence on the old run clears after the fix | as intended (WD8 a3-a8) | pass |
| L3d | pl_div_run_not_fixed | divergence on a current run stays | as intended | pass |
| L4a, L4b | pl_derived_self_loop, pl_derived_cycle | m_now diverges (bad case unsat); ready none | no divergence; ready true | LM12 |
| L5a | pl_no_budget_default | spent after 3 laps (draft default) | not spent | LM18 |
| L5b | pl_lap_gap | spent (lap 4 done, budget 3) | not spent | LM18 |
| L5c | pl_budget_lowered | not spent (largest counts) | as intended | pass |
| L5d | pl_budget_raised_reached | spent at lap 5 | as intended | pass |
| L6a | pl_agent_supersedes_unrefuted | ED7 c1b; ready none (draft "Only the human changes the scope") | none; ready true | LM3 |
| L6b | pl_stale_ratification | ED7 c2c | none; ready true | LM16 |
| L6c | pl_unanswered_question | ED7 c2c | as intended | pass |
| L6d | pl_ratified_via_new | no ED7; ready true | as intended | pass |
| L7a, L7b | pl_ready_with_ed1, pl_ready_with_ed8 | ready none (rule 7) | ready true with ED1 / ED8 | LM17 (documented) |
| L8a-e | tagged_both, run_tagged_system, model_tagged_system, untagged_check_only, untagged_log_hyp | ED1 / leads / no touch | as intended | pass |
| L9 | pl_no_hypothesis | ready none | as intended | pass |
| L10 | pl_to_ask_blocks | to_ask q2; ready none | as intended | pass |
| L11 | pl_disagree_root_cause | ED6 m_now; ready none | as intended | pass |
| L12 | pl_diverging_explorer | m_x diverges; ready none | as intended | pass |
| L13 | pl_explore_rerun | no ED6; ready true | ED6; ready none | LM14 |
| L14 | pl_normal_case_sat | m_now diverges | no divergence; ready true | LM15 |
| L15a-c | TLA preserve violated, existing-world bad case holds, clean TLA pair | break / divergence / ready true | as intended | pass |
| L16 | pl_applies_unknown_only | no falsifier for c3 | as intended | pass |
| L17a-c | untrusted target falsifier, derived from uncalibrated, reason for another rule | as named | as intended | pass |
| L18a-b | edit then re-run only calibration / only sanity | not trusted | as intended | pass |
| L19 | pl_model_run_no_model_fact | m_x not trusted | m_x trusted (core lint gives E3, E4; the CLI rejects the fact at write time) | harmless |
| L20a-b | disproof on superseded c2, with and without q1's answer | ready true / ED7 c2b, q1 waits | as intended | pass |
| L21 | pl_two_hypotheses | ready none (draft SIGNAL 4) | ready true, WD6 a18 | LM19 |
| L22 | base | (informational) a10 `together` unsat at the current digest | present, unread | LM15 |

`L/fixtures/minimal` (R7 call 3, Small report without claims), 20db37fb, both engines, 12/12,
0 skips: reproduced with no claim gives ready none; `not_reproduced` gives ready true and WD6;
`not_reproduced` on an untagged log gives no outcome; a request with one spent lap gives
decide true and ready none.

`L/fixtures/qwait` (SWI, 20db37fb): a hypothesis-raised unanswered question gives ready none;
mutants m198 and m065 give ready true, so this variant kills them (cf1_no_answer does not).

CLI probes (`ORBIT_KB_LIB=L/lib orbit-kb --dir <copy>`). Final run: `heavy bash L/tmp/cli_all.sh`
on CLI `b0465f2b34302f45` (hash checked at start and end), module 20db37fb, a fresh empty
`XDG_CACHE_HOME`, output `L/out/cli-all-newcli.txt`. No line printed NOTE, ENGINE
DISAGREEMENT, CROSS-CHECK SKIPPED, or `(unchecked)`. All 23 base goals gave the expected
answers there too; lint and `lint --strict` on the base: 0/0. Earlier runs on CLI
`dccdec8be9a6e4ca` (C1-C4, C3 and the kb2 probes, 15:32-15:57, module 18435d9d, default cache)
gave the same results; `L/out/cli-probes.txt` (16:53) already used `b0465f2b34302f45`, with the
default cache.

| Probe | Expected before the run | Actual |
|---|---|---|
| C1 decision by agent (default `--by`) | rejected | rejected, E8, exit 1 |
| C1b decision `--by human` from the agent | accepted (the CLI cannot tell) | accepted (LM20) |
| C2 `explore(order_4417)` and `case('order_4417')` | rejected (E13) | both rejected, E13 |
| C4 `model_run` for a non-model, `model` for a non-subject | rejected (E4) | both rejected, E4 |
| C4b `model_run` on the system log | accepted, then loud | accepted; ED1 a1, a9, WD7, WD4, exit 1 |
| approval by agent | rejected | E8 |
| derived_from self-loop and cycle, `lap_done(7)`, abstained disproof | accepted | accepted; no lint code names them |
| C3 GO, then edit ticket.md | re-approval rejected; W1; after `subject`, `stale(A)` = the approval | as expected; lint clean after re-record; `discovery_ready` true (LM21) |
| CLI-P1 (L1) | ready false | `model_unfiled_break` false, `discovery_ready` true (cross-checked), lint 0/0 |
| CLI-P2 (L2) | ready false | `model_diverges` false, `discovery_ready` true, lint 0/0 |
| CLI-P3 (L6a) | ED7, ready false | `discovery_unratified` false, ready true, only W5 |
| CLI-P1b (L1, inconclusive) | ready false | `discovery_ready` true, lint 0/0 |
| CLI-P4 (L4b: cycle, existing-world bad case unsat) | ready false | `model_diverges` false, `discovery_ready` true, lint 0/0 |
| CLI-P5 (L13) | ready true | ED6 m_target, ready false |

## 4. Mutation testing

Commands (from `L/rh`, which holds harness copies of `scratch/review/harness/` and the module
under test as `modules/discovery.pl`; see LM23):

    swipl S/scratch/review/mut/gen_mutants.pl -- L/snap20db/discovery.pl L/mut/orig2
    swipl L/mut/tools/gen_mutants_ext.pl     -- L/snap20db/discovery.pl L/mut/ext2
    heavy bash L/tmp/mut2.sh   # run_mutants.py for orig2 and ext2, then run_mutants_matrix.py

`gen_mutants_ext.pl` adds: delete a module fact; break a join (one shared variable occurrence
made fresh, top level or one level deep); swap a domain constant; swap a lint code between E and W;
17 hand-written mutants that undo REVIEW fixes or widen keys. `run_mutants_matrix.py` records
every variant that kills each mutant. Prediction written before the first run
(`L/mut/PREDICTION.txt`): 80-90% for the original operators, 60-75% for the extra ones.

| Module / fixture | Set | Mutants | Killed by an answer |
|---|---|---|---|
| 18435d9d / 157 | original operators | 250 | 217 (86.8%) |
| 18435d9d / 157 | extra operators | 269 | 195 (72.5%) |
| 20db37fb / 168 | original operators | 258 | 222 (86.0%) |
| 20db37fb / 168 | extra operators | 279 | 200 (71.7%) |
| 20db37fb / 168 | all, distinct by content | 529 | 416 (78.6%); 80.0% of the 520 non-equivalent |

Survivors on 20db37fb: 115 entries, 113 distinct (m123 = x266 and m180 = x267). Full list in
`L/mut/result-orig2.txt`, `result-ext2.txt`, `matrix-new-summary.txt`. Classified:

- **Equivalent (9):** m120, x065 (`discovery_sanity_ok` in `model_sane` is implied by
  `not model_sanity_failed`); m183, x162 (A is bound by the caller); m194 (`touched_system` is
  implied by "a hypothesis, and each has a system result"); m107, x037, x038 (with the F2
  old-run guard, the run-digest literal is redundant when the model has a subject, which the
  CLI enforces); x101 (the breaking model is not used downstream).
- **Harmless (30):** mutants that only add or drop a warning that another error already
  covers, or over-block, or differ only when two subjects share a digest or a log is shared by
  two models: m109, m149, m150, m153, m210, m214, x003, x031, x036, x040, x041, x042, x044,
  x047, x053, x055, x057, x058, x061, x073, x074, x091, x092, x106, x107, x108, x111, x179,
  x184, x185.
- **Real gaps (74 distinct, 76 entries):**
  - R7 gate conjuncts (LM4): m010, m101, m102, m195, x027, x207, x208, x272; m065, m198; m204;
    m069, m072; m193, x279.
  - LM1: x269. LM2 and REVIEW 1: m023, m123 (= x266), x070, x072, x229, m138.
  - LM3: m180 (= x267).
  - REVIEW 2 (LM5): x009, x010, x011, x013, x014, x016, x217, x218, x219, x221, x222, x224
    (TLA); x017, x112; m142, x098.
  - REVIEW 3 (LM5): x263, x264, x265, m114, m116, x052; WD8 identity x043, x183.
  - LM18 (accepted-risk candidate): x270.
  - REVIEW 4, 13 (LM5): m002, m003, m004, m094, m098, m100, x020, x024, x025.
  - REVIEW 6, 7, 11, 12 (LM6): x167; m178, m182, x153, x155, x156, x159; m133, x085, x086, x090,
    x123, x125, x127; x149, x152, x175.

Check of the probes against the survivors (`heavy bash L/tmp/surv.sh`, SWI-only, 20db37fb;
`L/mut/surv2-{probe,minimal,qwait}.json`): the three probe fixtures kill 63 of the 115
survivors, all of them real gaps. For x269 (LM1), x070, x072, x266 (LM2), m180, x267, x156, x159
(LM3) and x270 (LM18), the probe's intended answer is the mutant's answer, so there the module
is the side that fails. 13 real-gap entries are not killed by any probe either: x027 (NO-GO
result on an untagged log while another subject is tagged), m138 (target's own divergence),
x009, x010, x013, x217, x218 (TLA `reached` and `violated` outside sanity), x265, m116
(mutation digest), x155 (refuted-claim identity in `discovery_disputed`), x085, x123, x125
(trust and falsifier joins).

## 5. Engine agreement (fuzz)

Generators: `scratch/review/fuzz/gen_fuzz.py` and `gen_fuzz3.py` predate the IGNITION
vocabulary (`reason/2`, free calibration cases, no `model_run`, no `discovery_evidence`), so
they were adapted as `L/fuzz/gen_fuzz_l.py` (small random KBs; perturbations of discovery-a),
with log reuse at a second digest for F2. 7 queries per KB: `discovery_ready`,
`no_falsifier(C)`, `model_trusted(M)`, `lint_issue(Code, Id, _)`, `model_unfiled_break(C)`,
`discovery_unratified(C)`, `discovery_decide`. Prediction (`L/fuzz/PREDICTION.txt`):
0 disagreements.

    ORBIT_KB_SCASP_TIMEOUT=10 heavy timeout 7200 swipl L/hf1/harness/run.pl L/fixtures/fuzz_small L/lib
    ORBIT_KB_SCASP_TIMEOUT=10 heavy timeout 7200 swipl L/hf2/harness/run.pl L/fixtures/fuzz_pert L/lib

| Set (20db37fb) | KBs | Comparisons | Cross-checked | Skipped | Disagreements |
|---|---|---|---|---|---|
| small, seed 7 | 120 | 840 | 840 | 0 | 0 |
| perturbed, seed 11 | 60 | 420 | 345 | 75 (`discovery_ready` 37, `discovery_decide` 38) | 0 |
| total | 180 | 1260 | 1185 | 75 | **0** |

Coverage limit: small KBs almost never reach a trusted model (`model_trusted` non-empty in 0
of 120) and a true gate in 2 of 120; perturbed KBs reach a true gate in 25 of 60, but s(CASP)
times out on all 25 (LM7). The probe run adds 0 disagreements in 68 cross-checked expectations.

## 6. Evidence log

Module hash per run; expected result written before the run; actual result.

| # | Command (cwd) | Module | Expected | Actual |
|---|---|---|---|---|
| 1 | `grep -cE 'discovery_(model_result\|reproduction\|divergence)\b' modules/discovery.pl` | 18435d9d, 20db37fb | 0 | 0, 0 |
| 2 | `python3 -I S/harness/check_draft.py` | 18435d9d (old draft) | 6 FAIL, as in fm-red-runs.md | 6 FAIL |
| 3 | same, with `L/snap20db/discovery.pl` | 20db37fb (draft 13006971) | 6 ok | 6 ok, Part 1 2998 words |
| 4 | `TMPDIR=L/tmp bash S/harness/lint_cli.sh` | 18435d9d | ok, ok | ok, ok |
| 5 | `bash L/h2/harness/lint_cli.sh L/h2/modules/discovery.pl` | 20db37fb | ok, ok | ok, ok; `lint --strict` 0/0 |
| 6 | `orbit-kb --dir L/cli/kb_ed1 lint` (log tag removed) | 18435d9d | exit 1, grep `^ *E[0-9]` = 0 | exit 1, ED1 a1, a9; grep 0 |
| 7 | `bash L/h2/harness/selftest.sh` (byte copy) | 18435d9d, 20db37fb | 5 ok | 5 ok, 5 ok |
| 8 | `swipl L/h2/harness/run.pl L/h2/fixtures/discovery-a L/lib only=no_such_variant` | both | exit 1 if correct | 0/0, exit 0 (LM9) |
| 9 | `bash L/h2/harness/cli_conformance.sh` | 18435d9d (fx157), 20db37fb (fx168) | 23 ok, control ok | 23/23, 0 skipped, control ok (both) |
| 10 | `swipl L/h2/harness/run.pl L/fixtures/minimal L/lib` | 20db37fb | as in its expected.pl | 12/12 both engines, 0 skips |
| 11 | `swipl L/h/harness/run.pl L/fixtures/probe L/lib` | 20db37fb | intended answers (expected.pl) | SWI 65/93, s(CASP) 53/93 + 25 skipped, 0 disagreements |
| 12 | `SWI_ONLY=1 DISC_MODULE=... swipl harness/run.pl L/fixtures/probe` (L/rh3) | 18435d9d, 20db37fb | same answers on both | identical |
| 13 | `SWI_ONLY=1 ... L/fixtures/qwait` with m198, m065 | 20db37fb | module: ready none; mutants: ready true | as expected |
| 14 | run_mutants.py orig / ext (L/rh, L/rh2) | 18435d9d, fixture 157 | 80-90% / 60-75% | 217/250, 195/269 |
| 15 | `heavy bash L/tmp/mut2.sh` | 20db37fb, fixture b8550a35 | similar to 14 | 222/258, 200/279; matrix 416/529 distinct |
| 16 | fuzz small and perturbed (§5) | 20db37fb | 0 disagreements | 0 of 1185 cross-checked |
| 17 | `heavy bash L/tmp/cli_probes.sh` (CLI b0465f2b, default cache) | 20db37fb | per §3 CLI table | per §3 CLI table |
| 18 | CLI C1-C4, GO probe (console, `L/cli/kb`, `kb_go`, `kb2`; CLI dccdec8b) | 18435d9d | per §3 | per §3 |
| 19 | `heavy bash L/tmp/cli_all.sh` (CLI b0465f2b at start and end, empty XDG_CACHE_HOME) | 20db37fb | per §3; no NOTE or DISAGREEMENT | as expected; none printed |
| 20 | `heavy bash L/tmp/r1_newcli.sh` (lint_cli.sh copy, CLI b0465f2b, empty cache) | 20db37fb | ok, ok | ok, ok |
| 21 | `heavy bash L/tmp/surv.sh` (115 survivors vs probe, minimal, qwait) | 20db37fb | survivors killed by the probes | 63 of 115 (54, 8, 3 per fixture, overlapping) |

Outputs: `L/out/` (probe-run.txt, frame-new.txt, fuzz-small.txt, fuzz-pert.txt, cli-probes.txt,
probe-swi-preview*.txt, lint_cli.txt), `L/mut/` (result-*.txt, matrix-*.json,
matrix-new-summary.txt, index.txt per set, tools/).

## 7. Not done

- No full two-engine run of the 168-expectation fixture on 20db37fb by this reviewer; the
  implementer's run was in progress. SWI-only: 168/168. The coordinator's run of all 168
  through the new CLI (`harness/cli_variants.sh`) was not reviewed.
- The draft's wording was not reviewed (out of scope); only the R8 checks and semantic spot checks.
- The old fuzz generators were not run as they are; their vocabulary no longer matches the module.
- The probe and fuzz cross-checks of positive gates on full-size KBs all timed out (LM7); the
  CLI path was used for the LM1, LM2, LM3 gate answers instead.

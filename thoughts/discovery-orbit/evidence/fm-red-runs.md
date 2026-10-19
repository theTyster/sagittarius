# FLIGHT MANIFEST red runs (2026-10-16)

- Tree: dirty(035d9e6, 00c6609277e181cf). The hash covers `git diff HEAD` and the
  untracked files under `thoughts/discovery-orbit/`. Module and `run.pl` unchanged from
  035d9e6.
- Tools: SWI-Prolog 9.2.9, s(CASP) 1.1.4; orbit-kb CLI sha256 dccdec8be9a6e4ca, core.pl
  sha256 739e3e1e0ed7596e (prefixes).
- Paths are relative to the staging folder.

## R4, R5: `harness/selftest.sh` (test run)
Expected before IGNITION: R4a, R4b, R5a fail; the R5b and R5c controls pass.
Observed (console):

    FAIL  R4a only=v1 runs v1 alone and exits 0 (rc=1; ran: == base == v1 == v2 == v3 )
    FAIL  R4b only=v1 only=v2 runs v1 and v2 alone (rc=1; ran: == base == v1 == v2 == v3 )
    FAIL  R5a a timeout is skipped, counted, and exits 0 (rc=1)
    ok    R5b a wrong answer exits 1
    ok    R5c a timeout does not hide an SWI failure

Cause of R4: SWI compiles the yall lambda at load time; `Only` inside it is a fresh
variable ("Singleton variable in branch: Only"), so every variant passes the filter.
R5a fails because no CROSS-CHECK SKIPPED line exists.

## R1: `harness/lint_cli.sh` (test run, frame test plus negative control)
Expected: the fixture lint is clean; the control copy gives E14 and E13 and exit 1.
Observed: `Summary: 0 error(s), 0 warning(s).`, then `ok` for both. The control is the
discriminator for this frame test.

## R3: review check (code read)
`grep -cE 'discovery_(model_result|reproduction|divergence|disproof_filed)\b' modules/discovery.pl`
gave 22. After IGNITION the three projections must be gone; `discovery_disproof_filed`
stays (see the R3 change in TICKET.md), so the check after IGNITION is
`grep -cE 'discovery_(model_result|reproduction|divergence)\b'` = 0.

## R6: expectations against the pre-fix module (test run)
`DISC_MODULE=$PWD/scratch/review/modules/discovery.pl SWI_ONLY=1 swipl scratch/review/harness/run.pl $PWD/fixtures/discovery-a`
Full output: `fm-r6-red-prefix-module.txt`. SWI 83/157. Variants that fail on a real
answer, not on a missing symbol:

| REVIEW finding | Red variants |
|---|---|
| 1 | b1_calibration_differs, b1_divergence_on_model, b1_bad_case_not_reproduced |
| 2 | b2_unknown, b2_vacuous, b2_break_unfiled, b2_target_bad_case, b2_solvers_disagree, b2_sanity_fails, b2_tla_sanity |
| 3 | m3_model_edited |
| 4 | m4_confirm_by_log, m4_confirm_by_model, m4_no_system, m4_untagged, m4_check_only |
| 5, 13 | m5_second_hypothesis, m5_not_reproduced, m5_bad_raised_by |
| 6 | cf7_budget_spent, m6_budget_raised, m6_budget_hides |
| 7 | m7_launder |
| 12 | cf5b_survived_with_reason, cf5c_reason_other_model |
| 14 | minor_cross_tool, minor_wrong_log |

Green on the pre-fix module, so marked for the LANDING MODULE test-adequacy review:
cf8_draft_dormant (finding 8: the fix is in kb.pl data), cf1_no_answer (finding 10: the
fix is the expectation), k_* (finding 11: mutation-kill variants), b2_break_filed,
m4_repro_only, m4_check_is_repro, m5_question_from_hypothesis, m7_ratified, and
perf_12_claims_6_models (finding 9). Finding 15 is a review check.

## R8: `python3 -I harness/check_draft.py` (review checks, code read)
Expected: all six fail on the current draft. Observed:

    FAIL  1 Part 1 has 3745 words (limit: fewer than 3,000)
    FAIL  2 Facts table rows match module facts: ['reason(Rule, Text) (module: reason/3)']
    FAIL  3 every module fact has a row: missing ['discovery_evidence', 'model_run']
    FAIL  4 query table: unknown or wrong arity []; gate rules missing ['discovery_decide']
    FAIL  5 attestation predicates have the module's arity: wrong ['no_go(H)']
    FAIL  6 lint codes: not in draft [ED1..ED8, WD1..WD8]; not in module []

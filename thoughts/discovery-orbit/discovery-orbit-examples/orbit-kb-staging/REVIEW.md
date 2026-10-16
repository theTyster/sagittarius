# Review: modules/discovery.pl and fixtures/discovery-a

Reviewer: fresh-eyes adversarial review, 2026-10-15. Core: live `core.pl` with D5.
Nothing under `modules/`, `fixtures/` or `harness/` was edited.

## How the evidence was made

All runs are in `scratch/review/`:

- `harness/run.pl` is a copy of the harness with two opt-in switches: `$DISC_MODULE` and
  `$SWI_ONLY`. It writes only to `scratch/review/scratch/`.
- `fixtures/probe/expected.pl` holds variants P1 to P24 on a copy of the fixture. Each
  expectation states the answer that the draft intends, so a FAIL on both engines shows a
  defect. Output: `probe-prev.txt`.
- `fixtures/empty/` holds the empty-input variants E1 to E4. Output: `empty-prev.txt`.
- `mut/` holds 95 module mutants and their results against the real `expected.pl`
  (`mut/result-real-fixture.txt`).
- `fuzz/` holds the engine fuzzing (`fuzz1-4-prev.txt`) and the scaling runs
  (`scale-prev.txt`).

Every probe KB passes the harness lint subset with no E codes and no W codes. Both engines
agree on every probe. The defects below are in the rules, not in the engines.

## Findings, by severity

### 1. BLOCKER: the module never reads a model-to-system disagreement
`discovery.pl:132-139, 182-188`

The draft says: "A model and the current system disagree ... Fix the model before you use
any of its verdicts." The module accepts the shapes for this, but no rule reads them:

- P1 adds `calibration(m_now, onecode, differs)`.
- P2 adds a core `divergence` with `model(m_now)`.
- P3 changes the existing-world `bad_case` to `unsat`, so the model does not reproduce the
  problem.

Result in all three: `model_trusted` is `[m_now, m_target]`, `discovery_ready` is `true`,
and `lint_issue` is `none`.

**Fix.** Add `model_diverges(M)`, which holds on a `calibration(M, _, differs)`, a
`divergence model(M)`, or `verdict(M, bad_case, unsat)` for an existing-world model. Make
`model_trusted` require `not model_diverges(M)`, and the same for M0. Add an ED or WD lint
code for it.

### 2. BLOCKER: the module ignores every verdict result except sanity and calibration
`discovery.pl:132-144`

In each of these variants, `discovery_ready` is `true` and lint is silent:

| Variant | Change |
|---|---|
| P4 | the only check of c2b is `unknown`. The draft says: "never report it as UNSAT". |
| P5 | `applies(c1)` is `unsat`, so the claim holds vacuously (honesty rule 4). |
| P6 | `preserve(c2b)` is `sat`: the target model breaks c2b, and no disproof is filed. |
| P6b | the target `bad_case` is `sat`. |
| P7 | Z3 says `unsat` and cvc5 says `sat` on the same check. The draft says "loud". |
| P8 | a later sanity check is `unsat`; the model is still sane. |

**Fix.** Add rules or lint codes for these:

- `unknown` on any check;
- `applies(C)` with `unsat`;
- `preserve(C)` or a target `bad_case` with `sat`, when no disproof exists;
- two verdicts with different results for one (model, check) pair.

Make `has_falsifier` require that the model has no such open verdict for C.

### 3. MAJOR: trust stays after the model file changes
`discovery.pl:132-139`

P23 edits m_now so that it clamps after both codes. Z3 on the edited file gives 3000 cents
for order 4417 (the log shows 2500), and the bad case is `unsat`. The agent then re-records
the subject. Result: m_now is still trusted, `discovery_ready` is `true`, and lint is clean,
including W1.

The cause is that verdicts name the log, and nothing binds them to the digest of the model.

**Fix.** Record the model digest with each run, for example a `ran(Log, Model, Digest)`
fact. Add a `stale`-like rule that cancels the verdicts of an older digest.

### 4. MAJOR: model artifacts count as evidence from the current system
`discovery.pl:158, 169-170, 203-208`

- P9 and P9b confirm f1 with a `reproduction` whose subject is `run_now` (the solver log)
  or `m_now` (the model file). Result: `finding_lead` is `none`, and lint is silent.
- P10 removes all system evidence and keeps only that confirmation. Result:
  `touched_system` is `true` and `discovery_ready` is `true`.

ED2 checks only `model_result` attestations.

**Fix.** Add an ED code for a `reproduction` whose subject is a model or the log of a
model run. Add a fact that tags logs as system or model logs, and make `touched_system`
and `finding_confirmed` require a system log.

### 5. MAJOR: empty inputs are ready
`discovery.pl:182`

- E1 has a request, a hypothesis, and one reproduction, but no claims. Result:
  `discovery_ready` is `true`.
- E2 has no hypothesis and no claims. Result: `true`.

The draft says that a ticket holds claims, and that SIGNAL must not guess a hypothesis.

**Fix.** Add `some_current_claim` and `some_hypothesis` conjuncts to the clean path, or
add explicit NO-GO readiness.

### 6. MAJOR: the budget path hides open problems
`discovery.pl:171, 190`

- P12 has the budget spent, q1 waiting, and c2b refuted. Result: `discovery_ready` is
  `true` and `lint_issue` is `none`.
- P12b and E3 never touch the current system. E3 has only a request and `lap_done(1)`.
  Result: `true`.
- P13: the KB is append-only, so a raise to `budget(laps, 5)` is ignored, and the gate is
  `true` at lap 3.

**Fix.** Split the gate into `discovery_clean` and `discovery_ready`. Add
`discovery_out_of_budget :- budget_spent, not discovery_clean`, and a WD lint code that
lists the open items. Use the largest budget, or a superseding budget record.

### 7. MAJOR: a supersession by the agent alone launders a refutation
`discovery.pl:177` (core `current/1`)

P16 refutes c2b. The agent then supersedes c2b with c2c and adds `encodes(m_target, c2c)`.
No human answers. Result: `discovery_ready` is `true` and lint is silent.

D5 now also drops the questions on the superseded claim from `to_ask`. The draft says:
"Only the human changes the scope."

**Fix.** Add a rule that blocks readiness when a `supersedes` fact has no human answer or
decision behind it.

### 8. MAJOR: the recipe on line 15 contests the winning claim forever
`discovery.pl:15`; `expected.pl:104-111`

The unsat-core recipe records a divergence on every claim in the core, c1 included. As a
result:

- P17 adds the dormant questions of draft Example A. q2 becomes `to_ask`, and
  `discovery_ready` is `none`. The draft says: "Nothing waits for the human. ready holds."
- P18 loads the build module and adds one real divergence. `contested_twice(c1)` and
  `burn(c1)` both hold.

The fixture leaves out the draft's dormant questions, and CF8 locks this behavior in.

**Fix.** Record the conflict as the finding and the question only, or put the divergence
only on the claim that gives.

### 9. MAJOR: s(CASP) under `prev` falls off a performance cliff
These are scaled variants of the fixture (`scale-prev.txt`):

| Scale | Query | Time |
|---|---|---|
| 7 claims and models, `-s 1` | `no_falsifier(C)` | 21.8 s |
| 7 claims and models, `-s 1` | `lint_issue` | 18.9 s |
| 7 claims and models, `-s 0` | `discovery_ready` | timeout |
| 12 claims, `-s 1` | `discovery_ready`, `no_falsifier`, WD2, `not some_to_ask` | timeout (30 s) |

The hot spot is `not model_trusted(mt0x)`, which takes 16.6 s. Neither `--forall=sasp`
(25.5 s) nor a one-clause `model_trusted` (19.0 s) helps. In the CLI, each timeout gives
ENGINE DISAGREEMENT and exit 2. SWI answers at once.

**Fix.** Make the CLI report an s(CASP) timeout as CROSS-CHECK SKIPPED (this changes the
contract). Add a scaled fixture to the harness.

### 10. MAJOR: the fixture fails against the D5 core
`expected.pl:33`

The CF1 expectation `to_ask(Q) = [q1]` now gives `none` on both engines, because q1 is on
the superseded claim c2. The harness gives 58/59 and exit 1.

**Fix.** Expect `none`, and keep the `question_waits` expectation as the guard.

### 11. MINOR: coverage gaps in expected.pl
Mutation testing: 15 of 95 mutants change no answer. The worst are:

- m047 `has_falsifier(C) :- model_trusted(_)` (any trusted model makes every claim
  falsifiable);
- m044 `model_trusted` without `derived_from`;
- m041 and m043: trust without sanity;
- m064, m023 and m024: `touched_system` is never false in any variant;
- m063: `current` in `some_current_refuted`;
- m055: the source `model` in `finding_lead`;
- m002, m010, m011, m016 and m017: the clauses for `reached`, surprise, scope and trace.

All six lint-hook clauses and every literal in them are killed. P20 shows that the
untested finding-kind clauses behave as intended.

### 12. MINOR: `weak_rule` is keyed by the rule name only
`discovery.pl:162-164`

P14: a `reason(clamp, …)` written for the mutation on m_now also excuses the surviving
mutation on m_target. **Fix.** Key `reason/2` by the attestation id, as WD3 already does.

### 13. MINOR: `touched_system` is global
`discovery.pl:169`

- P24 adds a second defect hypothesis that nothing touched, and it is silently ready. The
  draft says to ask the human whether two hypotheses are one ticket or two.
- E4 records `not_reproduced`, which is a loud divergence in the draft. It raises no
  finding and no lint code.

### 14. MINOR: trust inputs are not checked
- P15: the calibration case can be any atom, so it is not tied to system evidence.
- P22: a TLA model can inherit trust from an SMT model, which breaks draft step 7.
- P19: a verdict about m_target can cite the log of m_now.
- P21: a TLA sanity verdict of `violated`, which is what TLC reports in Example B, is not
  accepted as sane. This failure is loud (WD2).

### 15. MINOR: drift from the contract
- `has_digest/1` is outside discovery's reserved names.
- The reserved attestation type `calibration` is never declared.
- `run.pl` and `expected.pl:26` call the atom-suffix hazard "H3". The contract calls it H4
  (E13).

## Checked and found sound

- E12: no `not` literal holds a lonely variable. E13: no atom ends in `_<digits>`.
- All 33 discovery declarations are unique across core, build and discovery. Kinds are
  correct, every rule has clauses, and the module has no fact clauses.
- The attest-type writers are consistent with D1. `verdict/3` cannot trigger the core
  `refuted/1`.
- The lint hooks have E and W codes as the contract requires, and every Id is an existing
  id.
- `unasked_finding`, `question_waits`, `about_system` and `finding_lead` behave as the
  draft intends (P20).
- Fixture fidelity:
  - The Z3 5.1.0 and cvc5 1.3.4 logs are byte-identical to fresh runs.
  - All 7 digests are correct (`sha256sum`).
  - Every verdict in `kb.pl` maps to a logged check. `a13` is inferred from check 4,
    which is valid.
  - The E9 run log matches. The CF6 claim holds (Z3 gives SAT).
- Engine agreement under `prev`: 0 disagreements in 1,400 comparisons (200 random and
  perturbed KBs × 7 queries), and none in the probes. The only engine risk is performance
  (finding 9).

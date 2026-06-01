# Decision log

The decisions, constraints, invariants, and requirements that define Sagittarius — distilled from [`design-spec.md`](design-spec.md) and annotated with **current status** drawn from [`../FINDINGS.md`](../FINDINGS.md). The spec is canonical; this page is the navigable index with outcomes.

> The spec deliberately encodes *decisions, not code* — "code changes; decisions about the code should be firmer." That is also why the design could be close-worlded and proven directly (D-12).

## Proposition (§1)

> The orbital-shifting seven-stage pipeline can be realized as one **deterministic, background-executable Workflow** that preserves invariants I-1…I-7, parallelizes its provable and testable stages **without losing determinism**, and is **verifiable by the same pipeline** — without inverting the smart-orchestrator / dumb-executor separation.

Falsified by: any I-1…I-7 failing; any control decision depending on wall-clock or randomness; or the orchestration layer computing a logic verdict itself (a C-2 violation).

**Status:** realized and self-verified. Terminal adherence: 0 Pattern-3 violations, 9/9 prescriptive, 7/7 descriptive, 100% structural (see `explanation.md` §7).

## Decisions (D-1…D-13)

| # | Decision | Status |
|---|---|---|
| D-1 | **Workflow, not skill** — orchestration is a deterministic script (for parallelism, budget, resume, verifiability). | ✅ realized in `orbital-pipeline.workflow.js` + `realized/…mjs` |
| D-2 | **Separation of authority** — substrate owns mechanics; agents own judgment. | ✅ the spine; confirmed by `digest-router.js` inspection |
| D-3 | **State via files, control via digest** — `*.pl` carry state; a structured digest carries control. | ✅ `schemas/stage-digest.schema.js` |
| D-4 | **Movable-cursor control flow** — advance by default; backward only to honor a routed gap. | ✅ feeds I-3 |
| D-5 | **Auto-recover-and-log; hard-stop only when forced** (loop-limit / budget / core-obligation refuted). | ✅ `decision-trail.js` |
| D-6 | **Disprove policy** — ≥1 attempt/run, ≥2 perspective-diverse adversaries/attempt, bounded above. | ✅ I-5/I-6/I-7 |
| D-7 | **`LOOP_LIMIT = 1`** recovery per gap-class-per-stage. | ✅ tunable upward for kimmy |
| D-8 | **Explain always runs**, post-loop, unconditional, on every path. | ✅ = I-1; **the F-11 reconciliation restored Prolog↔Lean agreement on this** |
| D-9 | **Parallelism map** — prove/instantiate/model parallel; `realize` serial by necessity. | ✅ (F-8: don't trust worktree isolation for parallel mutators) |
| D-10 | **Lean bounding is deterministic** — per-theorem `maxHeartbeats`(+`maxRecDepth`), wall-clock only as infra backstop; Mathlib prebuilt; concurrency sub-capped. | ✅ validated for real by the dogfood (8259-job build) |
| D-11 | **Verifiable in isolation** — pure mechanics + injected effectful collaborators. | ✅ enables the 24 TDD tests |
| D-12 | **The dogfood subject is *this spec*** — proof from the spec, not the code. | ✅ this repo *is* the dogfood chain |
| D-13 | **Experiment, not canonical** — self-contained, not wired into `plugins/trajectory/`. | ✅ promotion is a separate later decision |

## Constraints (C-1…C-6) — hard rules the implementation must not violate

- **C-1 — Determinism.** No control decision may depend on wall-clock or randomness. *(A dedicated test proves two runs with different clock+rng yield an identical decision trail.)*
- **C-2 — No logic call in the substrate.** The orchestration layer branches only on agent-emitted signals; never computes provable/refuted/inconsistent itself. *(The #1 failure mode; regression-guarded by `digest-fold.js` + its lock-test — F-6.)*
- **C-3 — Disprove discipline.** Never attacks its own output; never spends below the reserve. *(= I-5.)*
- **C-4 — Monotone scope.** Scope only widens, never narrows mid-run. *(= I-4.)*
- **C-5 — Adversary cardinality.** Every disprove attempt runs ≥2 adversaries in parallel. *(= I-7.)*
- **C-6 — Background autonomy.** No human prompt mid-run.

## Invariants (I-1…I-7) — the formal proof targets

All seven are **proven axiom-free in Lean** and **survive an adversary** over a **non-degenerate** model (the kimmy gate). The headline of the re-statement: an earlier model was degenerate-by-construction and made 5/7 proofs *vacuous*; rebuilding it non-degenerate and re-proving (each with a counterfactual **necessity lemma**) gave them teeth.

| # | Invariant | Proof status |
|---|---|---|
| I-1 | **explain-always-runs** — every halting path reaches `explain`. | ✅ total `ReachesExplain`; non-vacuity via the `explain_skipped_on_hard_stop` necessity lemma + the structural terminal half. **Prolog reconciled to this in F-11.** |
| I-2 | **artifact-gating** — no stage runs before its required upstream artifact exists. | ✅ (by-fiat encoding caveat: the 7 edges are transcribed, not behaviorally witnessed) |
| I-3 | **termination** — `M = (Σ remaining recovery budget, endIdx − cursor)` strictly decreases under the concrete step relation. | ✅ **re-proven after the adversary refuted a vacuous first form** (the headline defect; F-3) |
| I-4 | **scope-only-widens** — startIdx non-increasing, endIdx fixed. | ✅ necessity lemma over `scope_narrows_mid_run` |
| I-5 | **disprove-bounded-above** — spend ≥ reserve, target ≠ own output. | ✅ reserve half re-stated existential → universal; two necessity lemmas |
| I-6 | **disprove-runs-at-least-once** — ≥1 attempt per run. | ✅ necessity lemma over `run_performs_zero_attempts` |
| I-7 | **disprove-fans-out** — ≥2 adversaries in parallel per attempt. | ✅ (the `x ≠ y` clause genuinely constrains) |

**Honest residual caveats** (the boundary of what the formal layer establishes): the proofs guarantee **control flow, not work quality**; each necessity lemma's teeth rest on a counterfactual predicate authored by constructor-omission (a standard CWA-augmentation caveat); I-2 is a by-fiat transcription; liveness is verified over exactly two outcome classes (complete / hard-stop). See `explanation.md` "What to check before kimmy."

## Requirements

**Day contract (R-G1…R-G5):** rigorously specced (✅ `design-spec.md`); TDD'd red→green (✅ 24 tests); proven I-1…I-7 in Lean (✅); fleshed out + E2E pointable (✅ `realized/`); a closing `explain` for human review before any real target (✅ `self-spec/explanation.md`).

**Functional (R-1…R-6):** full control-flow machinery first-class (✅); Lean proving bounded + parallel (✅); design self-verifies (✅); pointable E2E (✅, pending a chosen ticket); each run ends with a plain-language account (✅ = I-1/D-8); runs deterministic, resumable, budget-bounded (✅).

## Assumptions & risks — outcomes

- **A-1 — skill-from-subagent** ("a workflow subagent can invoke a `shifting:` skill and let it drive"): came back **FALSE** in this environment (F-2) — forked skills had no `Agent` tool. Mitigation taken: the realized Workflow calls the named specialists **directly** (Decision B).
- **A-2 — sandbox sibling import:** not exercised; the realized `.mjs` inlines the mechanics verbatim, sidestepping it.
- **Risk — close-world fidelity / vacuous theorem:** **materialized and caught** (the I-3 vacuity defect, F-3). The disprove floor is precisely the mitigation that worked.
- **Risk — inversion smell (C-2):** held; regression-guarded (F-6). A deferred re-attack against the *realized* code is the recommended pre-kimmy step (`explanation.md` §"recommended next step").
- **Risk — Lean parallel memory:** not stressed (proofs small against prebuilt Mathlib).

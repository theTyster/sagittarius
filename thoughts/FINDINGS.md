# Pipeline-as-Workflow — Dogfood Findings

Findings from the end-to-end dogfood run (2026-05-28/29): `orbital-shifting` run on its own
design spec to build the pipeline-as-a-Workflow. The full artifact chain is persisted under
`self-spec/`; the plain-language account is `self-spec/explanation.md`. Outcome: **all 7 invariants
(I-1..I-7) proven axiom-free in Lean, all 24 TDD tests green, terminal adherence clean (0 Pattern 3
violations, 9/9 prescriptive, 7/7 descriptive, 100% structural).** The deliverable
(`sagittarius.workflow.js` + `lib/` + `schemas/`) is built and verified.

These findings are requirements the **Workflow version** should fold in.

## F-1 — cwd-coupling (the HANDOFF-required finding) → Workflow takes an explicit project-root arg

The pipeline skills are **cwd-coupled**: they resolve `thoughts/`, `docs/`, and `.claude/` relative
to the session's project root. This is why the dogfood had to be run from a session rooted at
`/Users/ty/Projects/mine/orbital` (a mind-map-rooted session could not host them). The Workflow
version should take an **explicit project-root argument** and resolve every artifact path against it,
decoupling the pipeline from `cwd`. **Fold in as an additional requirement the Workflow satisfies.**

## F-2 — forked skill executions have no `Agent` tool → skills ran their inline-fallback path

Every staged skill invoked here via the `Skill` tool ran as a **forked execution that did NOT have
the `Agent` tool available**. `model-obligations`, `prove-invariants`, `instantiate-properties`,
`measure-entailment`, and `disprove-proposition` all reported this and fell back to their documented
inline path (doing the specialist work — prolog-prover, lean-expert, agent-of-questions,
lean-adversary, etc. — themselves rather than delegating). `realize-specification` instead loaded
inline into the orchestrator context, and the orchestrator delegated the build to a single
general-purpose sub-agent (budget-driven; the per-test choreography of ~5 agents × 24 tests was
infeasible in one context).

Implication for the Workflow: do **not** assume a `shifting:` skill driven from a workflow subagent
can itself spawn the named specialist sub-agents (this is exactly assumption **A-1** in the spec —
"skill-from-subagent" — and it came back **false** in this environment for the nested-`Agent` case).
The Workflow should either (a) call each stage's named sub-agents directly from the workflow script
(reproducing the orchestration in the substrate), or (b) confirm nested `Agent` availability in the
target runtime before relying on it. Record against A-1.

## F-3 — the verification has teeth: three real defects were caught and fixed by the pipeline's own gates

1. **Non-self-contained `target-world.pl` (model-obligations).** The emitted carrier's violation
   rules called `is_closer/1`, `stage_order/2`, `loop_limit/1`, `disprove_floor/2` — defined only in
   `existing-world.pl`. But `prove-invariants` reads `target-world.pl` as the **sole** carrier. The
   orchestrator's standalone-load gate caught it; a bounded loopback to `model-obligations`
   materialized those facts. Without the catch, 5 of 7 invariant verdicts were silently unasserted
   and the Lean theorems would have been grounded on absent facts. **Fix for the skill:**
   `model-obligations` must validate `target-world.pl` under a *standalone* consult, not co-loaded
   with `existing-world.pl`.

2. **Empty-export `:- module` wrapper on `lean_proof_results.pl` (prove-invariants).** The carrier
   was emitted with `:- module(lean_proof_results, []).` — inconsistent with all 4 sibling carriers
   (module-free) and with the schema, and it hid every fact from the downstream consult+query read
   path. Surgically removed; all facts re-verified queryable. **Fix for the skill:** `prove-invariants`
   should emit a module-free facts file matching the schema.

3. **I-3 termination proven VACUOUSLY (the headline).** The first Lean proof quantified the measure
   and step as *free* arguments and closed by `WellFounded.apply` — a tautology satisfied by a
   constant measure `(0,0)` and the identity (infinite no-op) step. A machine-checked, axiom-free
   counter-witness inhabited it (`self-spec/lean_disproofs/p_v1_i3.lean`). This is precisely the
   spec's **§8 "omitted transition ⇒ vacuous theorem"** risk. The mandatory **disprove gate**
   (D-6/I-6 floor) refuted it; an adjacent loopback re-stated I-3 over a **concrete two-move `Step`
   relation** (forward decreases cursor-distance; loopback decreases recovery-budget, bounded by
   `#keys × LOOP_LIMIT = 4`) with a `step_strictDecreasing` lemma, re-proved it axiom-free, and the
   degenerate witness now **fails to type-check**.

   **Lesson:** `lake build` + `#print axioms` *cannot* catch a vacuous-but-valid proof (the kernel
   proof was genuinely axiom-free). Only an adversary can. This is concrete evidence for **why the
   I-6/I-7 mandatory-disprove floor exists** and for **R-1 "automatic loopbacks are first-class."**
   The Workflow must preserve both: a guaranteed ≥1 disprove attempt, and the loopback machinery
   that consumes a refutation.

## F-4 — gatekeeper mtime-staleness false-positives after a loopback

The `check-chain.sh` artifact-chain hook flags downstream `.pl` files as STALE on an **mtime**
comparison. The I-3 loopback rewrote `target-world.pl` / `hypothesis.pl` *after* `model_results.pl`
was already written (a citation/sketch backfill), so the mtime ordering tripped a false STALE flag in
later stages (`instantiate-properties` and `explain` both reported it and worked around it via
ungated files / temp copies, without touching mtimes). Content was internally consistent throughout.
**Implication:** an mtime-based freshness gate is fragile under loopbacks (which legitimately rewrite
upstream artifacts after downstream ones exist). The Workflow's freshness check should be
**content/digest-based** (or loopback-aware), not mtime-based — and note this aligns with the spec's
**C-1 determinism** stance (no control decision should hinge on wall-clock, and mtime is wall-clock).

## F-5 — recommended next steps before pointing the Workflow at a real target (e.g. kimmy)

- **Re-attack C-2 against the now-realized substrate.** The disprove gate **abstained** on the C-2
  no-inversion claim pre-build (the Workflow didn't exist yet) and explicitly deferred a re-attack to
  after `realize-specification`. The realized `lib/digest-router.js` was spot-confirmed to branch
  only on agent-emitted digest fields (ignoring `artifactContent`), but a dedicated adversarial pass
  against the built orchestration loop is the proper close of that obstruction.
- **Fuller vacuity audit of I-1, I-2, I-4..I-7.** Only **I-3** received an adversarial vacuity probe
  (and failed it the first time). The other six were structurally non-vacuous on inspection (they
  bind concrete inductive model types and case-analyze real constructors, unlike I-3's free-measure
  trap), but none was adversarially probed. Run the disprove gate against each before going live.
- **Confirm nested-`Agent` availability** in the Workflow's target runtime (see F-2 / A-1) before
  relying on stage skills to spawn their specialist sub-agents.

## Status of the spec's own assumptions/risks

- **A-1 (skill-from-subagent):** came back **false** for the nested-`Agent` case in this environment
  (F-2). Inline-fallback covered it; the Workflow should call named sub-agents directly or verify the
  runtime.
- **A-2 (sandbox sibling import):** not exercised (the Workflow was built but not yet run inside the
  actual Workflow sandbox; the lib modules use plain CommonJS `require` of siblings).
- **Risk "close-world fidelity / vacuous theorem":** **materialized and caught** (F-3 item 3) — the
  mitigation (the disprove floor) worked.
- **Risk "Lean parallel memory":** not stressed — proofs were small and built against the prebuilt
  shared Mathlib clone with no rebuild.
- **Risk "inversion smell":** held (C-2 confirmed in the realized substrate; full re-attack deferred,
  see F-5).

## Re-statement / pre-kimmy re-probe findings (2026-05-30)

Executing the MC-agreed pre-kimmy sequence (re-probes → model rebuild → re-prove → adversary re-run).
Updates F-5. The re-probes were run via the **Workflow tool** (dogfooding the deliverable's host).

### F-6 — C-2 regression-guard landed (re-probe 1a)

`foldDigest` (the pure assembler that replaced the lossy-projection AGENT) was realization-only +
untested. Promoted to a tested mechanic `lib/digest-fold.js` (verbatim-mirrored inline in
`realized/sagittarius.realized.mjs` — 44-line body diff-clean) + lock-test
`self-spec/tests/digest_fold.c2_regression_guard.test.js` (8 tests, green). Locks the two C-2
violations the pre-build re-attack found: (a) `gapClass` is content-agnostic (a fixed constant
fallback) and NEVER derived from substrate identity (`__agentType`/stage) — it keys `withinLoopLimit`,
a control decision; (b) `coreObligation=true` forces halt even on a gap-routed result (hard-stop axis,
never demoted to a loopback). Plus: the verdict is carried verbatim or null, never derived. Closes the
C-2 regression-guard half of F-5 bullet 1.

### F-7 — behavioral tests are NON-VACUOUS (re-probe 1b) — with two thin-coverage caveats

Mutation-tested all 5 properties that went vacuous in Lean (I-1, I-3, I-4, I-5, I-6): for each, a
minimal genuine violation of the implementing mechanic was applied and the suite re-run. **All 5 have
≥1 dedicated test that turns RED under the violation** — so the behavioral layer is non-vacuous (no
double-false-green pairing vacuous proofs with thin tests). Caveats (thin *redundancy*, not
gate-failures — each still meets MC's "would actually FAIL on violation" bar):
- **I-1 hard-stop coverage rests entirely on `crit8`**; `explain_always_runs` (happy-path fixture) and
  `explain_is_terminal` (static query) are each individually thin for the hard-stop case.
- **I-4 sufficiency test `scope_narrowing_fact_absent` is fixture-thin** — its fixture
  (`target=1 < startIdx=3`) dodges a narrowing mutation; only the necessity test caught it.

Closes the BEHAVIORAL half of F-5 bullet 2 (the Lean re-statement is steps 2–4 of the sequence).

### F-8 — Workflow `isolation:'worktree'` LEAKED a mutation into the main tree (tool finding)

1b ran as a Workflow with `isolation:'worktree'` on 5 parallel mutation agents. Only **3** worktrees
were created for the 5 agents, and the **I-6 agent's mutation (commenting out `runMandatoryDisprove`)
LEAKED into the main-tree `sagittarius.workflow.js`** — caught by a post-run determinism re-run
(24/24 → a deterministic 23/24 with `disprove_floor` red), reverted via `git checkout`, leftover
locked worktrees pruned. **Implication: `isolation:'worktree'` is NOT a reliable isolation guarantee
for parallel file-mutating agents in this runtime.** For the upcoming parallel Lean re-proofs /
adversaries (steps 3–4): do NOT rely on worktree isolation — FREEZE the shared `TargetWorld.lean`
(read-only) and have parallel agents write DISJOINT per-invariant files (`Proofs/I*.lean`,
`lean_disproofs/*`), which is conflict-free regardless of isolation, and verify the main tree after
every parallel batch. Directly relevant to kimmy: a mutation-heavy workflow must not assume isolation.

### F-9 — persisted test had a stale require path

`self-spec/tests/sagittarius.proof_properties.test.js` required
`../../experiments/pipeline-workflow/sagittarius.workflow.js` — valid only from the original
dogfood location (`thoughts/tests/`), broken from the persisted `self-spec/tests/`. Fixed to
`../../sagittarius.workflow.js` (24/24 baseline restored). Implication: the persist step should
re-base relative import paths to the persisted location.

### F-10 — re-statement COMPLETE: all 7 invariants non-vacuous + adversary-survive

The model rebuild → re-prove → adversary re-run sequence is done (all via the Workflow tool). Outcome:
- `TargetWorld.lean` rebuilt NON-DEGENERATE: Run/DisproveAttempt → 2 inhabitants; StartIdx 3→1→0;
  varying Spend/Reserve; attempt-dependent Target/OwnOutput; RunAttempt over both runs; + CF predicates
  (`ReachesExplainCF`, `StartIdxCF1`, `SpendCF`, `TargetCF`, `RunAttemptCF`). Full `lake build` = 8259
  jobs, exit 0.
- I-1/I-4/I-5/I-6 re-proven non-vacuously (each with a CF necessity lemma); I-3 preserved (the proven
  template); I-2 preserved; I-7 extended for `a1`. I-5's reserve half was re-stated from the vacuous
  EXISTENTIAL (`∀a ∃s r …`) to the UNIVERSAL (`∀a s r, Spend a s → Reserve a r → r ≤ s`).
- ALL 7 adversaries RE-RUN over the frozen model → **7/7 SURVIVE** (the original vacuity/degenerate
  witnesses can no longer be inhabited; negations positively inhabited). 29 probes under
  `lean_disproofs/*_postrebuild*`.

Two SUPERVISION CATCHES — caught by orchestrator model-review + the full-build gate, NOT by the
per-stage adversary (which only attacked its own invariant):
- **I-1 D-8 inversion.** The rebuild made `ReachesExplain` non-total ("hard-stop r1 doesn't reach
  explain") — contradicting D-8 (explain runs on EVERY path; `crit8` + the implementation confirm) and
  making `i1_explain_always_runs` FALSE. Fixed: `ReachesExplain` total + `ReachesExplainCF` necessity
  witness. The I-4-only template-check adversary would NOT have caught this — orchestrator model-review
  is a necessary gate (the rebuild agent confidently mis-modelled the invariant).
- **I-7 `a1` cascade.** Adding `a1` to `DisproveAttempt` (for I-5/I-6) broke I-7's `∀ a` proof (a1 case
  unsolved). Caught by the FULL-library `lake build` (per-module builds had passed). A model change
  cascades to "preserved" invariants; the full build is the gate, not per-module builds.

HONEST RESIDUAL CAVEATS (the boundary of what the formal layer establishes):
- **CF-augmentation fidelity:** each necessity lemma's teeth rest on a CF predicate authored by
  constructor-omission (e.g. `ReachesExplainCF` omits r1); the teeth are only as strong as the
  modeller's fidelity — a standard CWA-augmentation caveat shared across I-1/I-4/I-5/I-6.
- **I-1 sufficiency antecedent is discardable BY DESIGN** (D-8 makes explain unconditional); non-vacuity
  is carried by the necessity lemma + the structural terminal half, not the bare implication.
- **I-2 by-fiat encoding:** Requires/StageOrder are constructor-faithful transcriptions; Lean confirms
  the chain is internally proper but cannot witness that the 7 edges mirror the implementation's actual
  runtime artifact dependencies — a translation/behavioral concern outside the theorem.
- Liveness verified over exactly 2 outcome classes (complete / hard_stop).

### F-11 — RESOLVED (2026-06-01): target-world.pl shared the original I-1 / D-8 error (Prolog↔Lean divergence) — now reconciled

The Prolog model `self-spec/target-world.pl` still carries the ORIGINAL D-8 error the Lean just shed:
it has `op_reaches_step(r0, s_explain)` ONLY (omits r1) and frames I-1 as "every NORMALLY-terminating
run reaches explain" (`op_terminates(r0)`; `r1 = op_hard_stop`, excluded from the antecedent). This
contradicts D-8 (explain runs on every path, incl. hard-stop — the implementation + `crit8` confirm),
so the Prolog and (now-corrected) Lean models diverge on I-1. The faithful `.pl` fix: add
`op_reaches_step(r1, s_explain)`; add an `explain_skipped_on_hard_stop` CF (`cf_fact/2` +
`negation_provenance(_, contradicts)`) — minding the `.pl`'s cf-count validation `forall` (it currently
asserts over a fixed cf_fact set); and reframe the `i1_violation` rule so a HALTING run (normal OR
hard-stop) that fails to reach explain is a violation. DEFERRED: the `.pl` is the model-obligations
PROLOG layer (a separate verification path), NOT the Lean gate kimmy's formal NorthStar rests on; the
fix touches the `.pl`'s internal validation machinery and warrants a careful pass, not a momentum edit.

**RESOLVED 2026-06-01** (operator: "work the divergence before pointing Sagittarius at a kimmy ticket";
full-chain scope). The whole self-spec Prolog chain was reconciled to the corrected Lean:
- **`target-world.pl`** — added `op_reaches_step(r1, s_explain)` + `op_terminates(r1)`. `op_terminates/1`
  is now TOTAL ("halts" = normal OR hard-stop), mirroring Lean's total `Terminates`/`ReachesExplain`;
  the hard-stop outcome is carried by `op_run_outcome`/`op_hard_stop` as a DISCRIMINATOR (not the absence
  of termination). Added the `explain_skipped_on_hard_stop` necessity CF — `op_reaches_step_cf(r0,
  s_explain)` (r0-only, mirrors Lean `ReachesExplainCF`) + `cf_fact/2` + `negation_provenance(_,
  contradicts)`. The `i1_violation` rule needed NO logic change (once `op_terminates` is total it ranges
  over both runs); only its comment was reframed. **The cf-count `forall` F-11 flagged turned out GENERIC
  (no hardcoded count)** — the new CF is genuinely load-bearing (verified: retract `op_reaches_step(r1,
  s_explain)` ⇒ `i1_violation` fires `run_does_not_reach_explain(r1)`).
- **Both stale downstream dumps regenerated.** `model_results.pl`: 9→11 `cf_status`, `summary(counterfactuals_applied)`
  9→11 (the dump had also lagged the F-10 I-6 floor CF). `lean_proof_results.pl`: necessity lemmas 3→5
  (+I-1 `explain_skipped_on_hard_stop`, +I-6 `run_performs_zero_attempts`); I-1 AND I-6 `proof_strategy`
  un-staled from "single-constructor" to the two-constructor reality.
- **One Lean doc-comment typo fixed** (`I1Liveness.lean:80`: dangling `i6_needs_one_attempt` →
  `i6_needs_no_zero_attempt_run`; comment-only, zero build impact).
- **Verified (swipl):** standalone load clean (0 undefined), 7/7 consistent, counts 11/11/11/2, and the
  `cf_status` load-bearing SETS are IDENTICAL between `target-world.pl` and `model_results.pl`.
- **How:** inline supervised model edit (the judgment core) + a reconcile/audit **Workflow** — parallel
  disjoint-file dump regen (F-8 lesson: no worktree isolation) + an opus adversarial cross-chain audit
  (`f11_closed: true`; all 6 checks green after the two doc fixes above).

RESIDUAL (out of F-11 scope, PRE-EXISTING — separate follow-up, NOT blocking kimmy): the audit surfaced
`run_summary(theorems_kernel_checked / axiom_free, 22)` in `lean_proof_results.pl` vs 25 actual theorem
declarations across `Proofs/*.lean` (the 3 extra are I-3 helper lemmas + regression checks). Reconcile
the tally or document why helpers are excluded.

**RESOLVED 2026-06-01.** Tally reconciled to **25** — `run_summary(theorems_kernel_checked, 25)` +
`run_summary(theorems_axiom_free, 25)` + the header's "all 25 theorems" line, with a new in-file
breakdown comment documenting the composition (7 invariant theorems + 5 necessity lemmas + 13
supporting/terminality/regression theorems = 25). 25 is the verifiable count of `theorem` declarations
(`grep -cE '^[[:space:]]*theorem ' self-spec/lean/Proofs/*.lean` ⇒ 3+2+9+4+4+2+1; `TargetWorld.lean`
declares 0), all kernel-checked by the recorded green `lake build` and axiom-free per the header +
`restatement_note`. The old 22 was stale — it predated the I-3 re-statement that grew
`I3Termination.lean` to 9 theorems (6 concrete-step machinery + 2 regression checks folded from the
removed `I3Vacuity`). This is a **count reconciliation against the recorded green build**, not a fresh
`#print axioms` re-run (that needs the Lean 4 + Mathlib toolchain — see `docs/index.md`).

### KIMMY GATE — SATISFIED at the formal-verification layer

All 7 Lean invariants are non-vacuous + adversary-survive over a non-degenerate model. The flagship
Workflow no longer rests on hollow proofs. (Behavioral test layer confirmed non-vacuous in F-7; C-2
regression-guarded in F-6.) The F-11 `.pl` reconciliation is now DONE (2026-06-01) — the full self-spec
Prolog chain matches the rebuilt Lean. Remaining before a real kimmy run: operator/MC go on a concrete ticket.

## First real-ticket run findings (2026-06-03)

The realized Workflow's first run against a real ticket (mind-map-dd Backend #2701, invoice inline-logo
embed + asserting test; deployed as `mind-map-dd/.claude/workflows/sagittarius-2701.mjs`). Provenance
**verified**: the deployed script diffs from `realized/sagittarius.realized.mjs` in exactly 3 hunks, all
brief-text on the intended parameterization seam (`meta.name`; a `RUN_INPUTS` ticket-facts block;
`withContext` absolute-path rewrite). **All mechanics byte-identical to the canonical proven copies.**
Evidence: session `bf5624bb…` under the mind-map-dd project dir, `workflows/wf_85c62c48-b1b.json` +
`subagents/workflows/wf_85c62c48-b1b/journal.jsonl`; artifacts at `wt/BE/2701/thoughts/`.

### F-12 — the realization admits steps OUTSIDE the proven Step relation: livelock on canonical mechanics (refinement gap, NOT an Orbital Inversion)

**Run 1 (22.8 min, 7 agents, 465k tokens): the design worked.** kb-validator found 11 tier-2 orphan
refs; one loopback honored (D-7); agent-of-truth then *claimed* "validated through all five tiers" but
the independent kb-validator found 2 remaining orphans → `loop_limit_exhausted` hard stop → `explain`
still ran (I-1/D-8 honored). **The builder/validator separation caught specialist over-claiming twice
on real work** — the bias-isolation thesis validated outside the dogfood.

**Run 2 (relaunched after a RUN_INPUTS re-entry-note text edit): LIVELOCK** — a close_world ↔ decompose
orbit (~6 agents / ~100k+ tokens per ~12-min cycle, 36 agents by cycle 5), terminable only by the
host's 1000-agent cap. Mechanism, all on canonical mechanics:

1. **Unvalidated agent-authored `targetStage`.** `foldDigest` uses `r.upstreamStage` verbatim
   (`lib/digest-fold.js:75`); specialists emitted *skill* names (`realize-specification`), agent names,
   even claim ids. `stageIndex()` → **-1** → `cursor = -1` → `STAGE_SEQUENCE[-1]` is a **phantom stage**
   that runs as a clean no-op digest → advance → cursor 0 → full re-run from close_world. Also drives
   `widenScope(scope, -1)` (outside I-4's modeled domain). D-4's "backward only" exists as comment +
   proof, never as a guard (`sagittarius.workflow.js:135-143` and the realized port assign
   `cursor = targetIdx` unchecked).
2. **Loop limit defeated by freeform `gapClass`.** `withinLoopLimit` keys on agent-authored
   `(gapClass, targetStage)` strings; run 2 re-spelled the same semantic gap fresh each cycle
   (`missing_inline_logo_test` / `missing_logo_inline_assertion_test` / `missing_logo_inline_test` /
   `missing_inline_logo_assertion_test`) — each spelling mints a fresh budget. **Smoking gun:**
   `RECOVERY_KEYS` — the I-3 model's finite 4-key pool — is declared (`sagittarius.workflow.js:49`,
   `realized/sagittarius.realized.mjs:516`) and used by the *tests* to compute budgetSum = 4
   (`self-spec/tests/sagittarius.proof_properties.test.js:353`), but **never consulted by the budget
   accounting**. The proof's measure and the code's accounting are different objects sharing a name.
3. **Forward gaps honored as loopbacks.** agent-of-questions reported "no test asserts X *yet*" — work
   stage 6 (realize) is *supposed to create* — as a gap targeting a downstream stage. No mechanical
   guard distinguishes upstream deficiency from not-yet-done pipeline work.
4. **Abstention evaporates at the fold.** The #2701 proposition is multi-claim (descriptive embed-state
   + prescriptive test-exists); the sharpener abstained **5×** asking for a split, but
   `SPECIALIST_RESULT_JSONSCHEMA` permits `status:"abstained"` with `routing:"advance"`, so decompose
   proceeded every cycle and the clarification never surfaced. (Interacts with C-6: a background run
   *can't* ask — but the current shape silently discards the question instead of halting with it.)
5. **The disprove floor is near-vacuous pre-artifact.** The mandatory attempt runs before close_world,
   so both adversaries attacked the `gate_target_descriptor` sentinel (run 1) or trivially "refuted"
   the not-yet-realized prescriptive conjunct (run 2). I-6 is satisfied; the *intent* of the floor is not.

**The headline.** `I3Termination.lean` is true and was not violated: it proves no infinite chain of
*model* Steps (State = budget ≤ 4 × distance ≤ 7, exactly two moves). The livelock is an infinite chain
of steps **outside** the proven relation — the realization never enforces the model's premises
(stage-token validity, finite budget-key domain, backward-only motion) at the digest boundary. This is
a **refinement gap**, not an Orbital Inversion (the substrate computed no verdict; it mechanically
honored malformed control data). The re-stated I-3 proved the model admits no measure-preserving step
(`i3_identity_step_is_rejected`); the realization manufactured one at the model's level of abstraction
(loopback-to-phantom + advance + budget re-mint ≈ a no-op cycle).

**Record corrections this finding forces:**
- `docs/design-spec.md` D-7 "*guarantees termination, prevents oscillation*" — **falsified as stated**
  for the realization; holds only under the unenforced well-formedness premises. (Annotated in place.)
- `docs/decisions.md` D-7 / I-3 status lines — caveated. (Done alongside this entry.)
- **F-6 interplay:** the C-2 re-attack correctly demanded `gapClass` be content-agnostic and never
  identity-derived — and that fix is precisely what left the string freeform/unbounded. The two
  constraints are compatible (a fixed *enum* is both content-agnostic and finite) but the record only
  captured the C-2 half.

**Candidate remediations (all pure mechanics, C-2-safe — premises become guards):** *(numbering
continues after the recon branch's C-7/I-8)*
- **C-8 (candidate) — digest-boundary well-formedness:** `gap.targetStage ∈ STAGE_SEQUENCE` else
  structural halt (akin to `artifact_gate_unsatisfied`); schema forbids `abstained`+`advance`.
- **I-9 (candidate) — backward-only loopback:** `targetIdx < cursor` enforced; phantom stages and
  forward-gap loopbacks become unrepresentable.
- **I-3 premise repair:** key the loop budget on a finite domain (`targetStage` restricted to
  `RECOVERY_KEYS`, and/or `gapClass` as a fixed enum in the schemas), so budgetSum ≤ #keys × LOOP_LIMIT
  holds **by construction**; then re-state I-3 with the guards as constructors and add lock-tests
  mirroring the F-6 guard suite.
- **D-15/D-16 (candidates, operator decisions):** abstention semantics under C-6 (hard-stop with the
  question surfaced via explain, e.g. `clarification_required`); disprove-floor target when no
  artifact exists yet.

At time of writing run 2 was still cycling; recommended action was to stop it (it cannot pass decompose:
the same multi-claim proposition re-abstains and the same missing-test gap re-emits every cycle).

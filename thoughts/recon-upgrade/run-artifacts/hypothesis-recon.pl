% hypothesis-recon.pl
% =============================================================================
% decompose-proposition (Stage 2) — RECON EXTENSION (ATTACH mode).
%   carrier in : recon-upgrade/run-artifacts/existing-world-recon.pl
%   baseline   : self-spec/hypothesis.pl (the proven I-1..I-7 decomposition)
%   proposition: §1 "Recon extension" (proposition(p_recon, _) in the recon KB)
%
% This file AMENDS the baseline by adding the recon-primer claim cluster. It does
% NOT regenerate the proven I-1..I-7 decomposition (that stays in
% self-spec/hypothesis.pl, untouched). The baseline's framing carries over: this
% is a dogfood decomposition, so much of the recon proposition is already entailed
% by the recon KB as design decisions (descriptive: D-14, C-7, the recon_* facts).
% The interesting surface is the proposition's DECLARED FALSIFIERS, each of which
% the KB explicitly negates via negation_provenance/2 with value `contradicts` —
% so every recon counterfactual carries provenance `contradicts`, NOT `absent`:
% structurally necessary, not CWA-fragile.
%
% The single new OBLIGATION the proposition asserts ("the only new obligation is
% I-8") is decomposed into TWO distinct prescriptive sub-hypotheses, NOT one claim
% read two ways:
%   (1) sh_i8_abstract  — the abstract recon-soundness invariant I-8. The recon KB
%       records open_question(i8_vacuity): I-8 MAY be a vacuous corollary of the
%       static I-2 gating. That question is NOT pre-judged here — adjudicating it is
%       prove-invariants' job (C-7 / the Orbital Inversion: this stage REPORTS the
%       open question; it never launders a substrate computation into a verdict).
%       So pr_recon_i8_soundness is emitted with status `open` (vacuity unresolved).
%   (2) sh_clamp        — the STRONGER, unambiguously load-bearing claim: planRecon
%       yields a WellFormedStart (a complete contiguous prefix) from ANY proposed
%       window + present-artifact set, by clamping an over-eager attach window down
%       to the first incomplete prefix stage (b13) and refusing a holed operator
%       window (b14). This claim does NOT depend on the vacuity outcome: even if the
%       abstract I-8 collapses to an I-2 corollary, the clamp/refuse mechanism is an
%       operational obligation new code must satisfy. pr_recon_clamp_wellformedstart
%       is the preferred load-bearing prescriptive claim.
%
% Ontology labels (see orbital/plugins/shifting/references/ontology.md):
%   descriptive    — already entailed by existing-world-recon.pl (the design says so)
%   counterfactual — a fact in the falsifier set that must be false in target-world
%   prescriptive   — must become provable / must come to exist; not yet entailed
% Negation provenance for every negated premise: absent | contradicts.
% =============================================================================

:- discontiguous claim/2, claim_label/2, claim_status/2,
                 claim_premise/2, claim_negation_provenance/3,
                 evidence/3, formal_property/3,
                 sub_hypothesis/2, coverage/2, assumption/2.

proposition("The same proven loop admits a recon primer - a pre-loop step that resolves where durable artifacts live and which segments run - so the loop can start mid-chain against a maintained repo without weakening any of I-1..I-7. The only new obligation is I-8 (recon soundness): every honored window seeds a complete, contiguous prefix, so gating holds at the start. Recon reports facts and recommends a window; it never computes a verdict (C-7).").

existing_world_file('recon-upgrade/run-artifacts/existing-world-recon.pl').

counterfactual_question("What about the recon KB would need to be false - and what new facts would need to become provable - for a pre-loop recon primer to seed the proven I-1..I-7 loop mid-chain WITHOUT weakening any invariant, where I-8 (every honored window seeds a complete contiguous prefix) is the only new obligation and recon never computes a verdict (C-7)?").

% -----------------------------------------------------------------------------
% SUB-HYPOTHESES — the recon proposition decomposes into these conjuncts.
% -----------------------------------------------------------------------------
sub_hypothesis(sh_primer_admitted, "The proven loop ADMITS a recon primer: a pre-loop step (D-14) resolves a per-artifact path map + present-artifact set and proposes a {from,to} window; the movable cursor seeds from it instead of the fixed cold (0, empty).").
sub_hypothesis(sh_no_weakening,    "Seeding mid-chain does NOT weaken any of I-1..I-7 (I-2 is static; I-4 already ranges over non-zero, decreasing startIdx).").
sub_hypothesis(sh_i8_abstract,     "I-8 (recon soundness, abstract form): every honored window seeds the produced-set { stage_i : i < startIdx } and every such stage is present + strict-loads, so I-2 gating holds at the seed. VACUITY OPEN: this may reduce to an I-2 corollary (open_question(i8_vacuity)) - NOT pre-judged here.").
sub_hypothesis(sh_clamp,           "Clamp-soundness (the stronger, vacuity-independent obligation): planRecon yields a WellFormedStart - a complete contiguous prefix - from ANY proposed window + present-artifact set, by clamping an over-eager attach window to the first incomplete prefix stage (b13) and refusing a holed operator window (feasible:false, b14).").
sub_hypothesis(sh_c7_no_verdict,   "C-7 / the Orbital Inversion applied to the primer: recon REPORTS presence + recommends a window and NEVER computes a logic verdict nor edits a durable artifact; planRecon reads only agent-emitted recon facts + the operator window and never inspects artifact content.").
sub_hypothesis(sh_frozen_prefix,   "Attach refinement: a loopback never widens below the attach-adopted frozenPrefix (b15), and a frozenPrefix attach run never regenerates an already-adopted artifact.").

% =============================================================================
% CLAIMS
% =============================================================================

% -----------------------------------------------------------------------------
% DESCRIPTIVE claims — already entailed by existing-world-recon.pl. The design
% (D-14 / C-7 / the recon_* + recon_mode facts) records these as ground facts.
% No counterfactual delta: the proposition's CONSTRUCTIVE content is the design.
% -----------------------------------------------------------------------------

claim(cf_recon_d_primer, "A pre-loop recon primer resolves a per-artifact path map + present-artifact set (existence + strict-load) and proposes a {from,to} window; the movable cursor seeds from it instead of the fixed cold (0, empty) (D-14).").
claim_label(cf_recon_d_primer, descriptive).
claim_status(cf_recon_d_primer, clear).

claim(cf_recon_d_modes, "Three recon modes are pinned: operator (operator from/to is authoritative; validated for feasibility only), attach (a claim is supplied -> judge which tail segments it needs against present artifacts), resume (no claim -> continue from the first missing durable artifact) (D-14).").
claim_label(cf_recon_d_modes, descriptive).
claim_status(cf_recon_d_modes, clear).

claim(cf_recon_d_reports, "Recon's permitted outputs are exactly three mechanical/recommendation types: presence_exists, presence_strict_load, window_recommendation (recon_reports/2). None is a logic verdict.").
claim_label(cf_recon_d_reports, descriptive).
claim_status(cf_recon_d_reports, clear).

claim(cf_recon_d_planreads, "planRecon reads only agent-emitted recon facts plus the operator window (plan_recon_reads/1) and verifies them for feasibility; the recon step formalizes D-14 and C-7 (invariant_formalizes(i8, d14), invariant_formalizes(i8, c7)).").
claim_label(cf_recon_d_planreads, descriptive).
claim_status(cf_recon_d_planreads, clear).

claim(cf_recon_d_c7_specializes, "C-7 (recon reports facts, never a verdict) is C-2 / the Orbital Inversion applied to the primer (constraint_specializes(c7, c2)); seeding mid-chain preserves I-1..I-7 because I-2 is static and I-4 already ranges over non-zero, decreasing startIdx.").
claim_label(cf_recon_d_c7_specializes, descriptive).
claim_status(cf_recon_d_c7_specializes, clear).

% -----------------------------------------------------------------------------
% COUNTERFACTUAL claims — the recon proposition's DECLARED FALSIFIERS. Each names
% a fact that must be FALSE in the target world. The recon KB explicitly negates
% each via negation_provenance/2 with value `contradicts`, so provenance is
% `contradicts` (NOT `absent`): structurally necessary, survives KB incompleteness.
% These are the primary refutation surface for disprove-proposition.
% -----------------------------------------------------------------------------

% --- Orbital-Inversion class (C-7, specializes C-2) ---------------------------
claim(cf_recon_no_verdict, "Recon NEVER computes a logic verdict (consistent / refuted / proven / inconsistent); it only reports presence and recommends a window (C-7).").
claim_label(cf_recon_no_verdict, counterfactual).
claim_status(cf_recon_no_verdict, clear).
claim_premise(cf_recon_no_verdict, recon_computes_logic_verdict).
claim_negation_provenance(cf_recon_no_verdict, recon_computes_logic_verdict, contradicts).

claim(cf_recon_no_edit, "Recon NEVER edits a durable artifact; it is read-only over the artifact set (C-7).").
claim_label(cf_recon_no_edit, counterfactual).
claim_status(cf_recon_no_edit, clear).
claim_premise(cf_recon_no_edit, recon_edits_durable_artifact).
claim_negation_provenance(cf_recon_no_edit, recon_edits_durable_artifact, contradicts).

claim(cf_recon_no_content_inspect, "planRecon NEVER inspects artifact content; it consumes only the agent-emitted recon facts plus the operator window (C-7).").
claim_label(cf_recon_no_content_inspect, counterfactual).
claim_status(cf_recon_no_content_inspect, clear).
claim_premise(cf_recon_no_content_inspect, plan_recon_inspects_artifact_content).
claim_negation_provenance(cf_recon_no_content_inspect, plan_recon_inspects_artifact_content, contradicts).

% --- seed-gating class (I-8 / I-2) --------------------------------------------
claim(cf_recon_no_holed_seed, "No seeded run violates I-2 gating: a window whose prefix is not all-present-and-strict-loading must NOT be honored as a seed (the holed-seed scenario is forbidden).").
claim_label(cf_recon_no_holed_seed, counterfactual).
claim_status(cf_recon_no_holed_seed, clear).
claim_premise(cf_recon_no_holed_seed, seeded_run_violates_i2_gating).
claim_negation_provenance(cf_recon_no_holed_seed, seeded_run_violates_i2_gating, contradicts).

% --- frozenPrefix / loopback class (attach refinement) ------------------------
claim(cf_recon_no_regenerate, "A frozenPrefix attach run NEVER regenerates an already-adopted artifact (the adopted prefix is frozen, not re-produced).").
claim_label(cf_recon_no_regenerate, counterfactual).
claim_status(cf_recon_no_regenerate, clear).
claim_premise(cf_recon_no_regenerate, frozenprefix_attach_regenerates_adopted_artifact).
claim_negation_provenance(cf_recon_no_regenerate, frozenprefix_attach_regenerates_adopted_artifact, contradicts).

claim(cf_recon_no_widen_below_frozen, "A loopback NEVER widens below the attach-adopted frozenPrefix; a hard-stop fires instead (b15).").
claim_label(cf_recon_no_widen_below_frozen, counterfactual).
claim_status(cf_recon_no_widen_below_frozen, clear).
claim_premise(cf_recon_no_widen_below_frozen, loopback_widens_below_frozen_prefix).
claim_negation_provenance(cf_recon_no_widen_below_frozen, loopback_widens_below_frozen_prefix, contradicts).

% -----------------------------------------------------------------------------
% PRESCRIPTIVE claims — must become provable / must come to exist. NOT yet
% entailed by existing-world-recon.pl: I-8's Lean theorem is a sketch (f8 targets
% i8; not yet a theorem), and the planRecon WellFormedStart-producing code does
% not yet exist on disk.
%
% NOTE ON THE VACUITY QUESTION (per the brief): open_question(i8_vacuity) records
% that I-8's abstract form MAY be a vacuous corollary of the static I-2 gating.
% This stage does NOT resolve that (C-7 / Orbital Inversion: no verdict is earned
% until a genuine refutation attempt by prove-invariants fails). So the ABSTRACT
% I-8 (pr_recon_i8_soundness) is emitted with status `open`. The STRONGER,
% vacuity-INDEPENDENT claim — clamp/refuse soundness (pr_recon_clamp_wellformedstart)
% — is the preferred load-bearing prescriptive claim and is emitted `conditional`.
% -----------------------------------------------------------------------------

claim(pr_recon_i8_soundness, "I-8 (recon soundness, abstract): every honored window with start index startIdx seeds the produced-set { stage_i : i < startIdx } and every such stage is present AND strict-loads, so I-2 gating holds at the seed (must be machine-checked in Lean under the D-10 bounds, f8). VACUITY OPEN: prove-invariants may find this a vacuous corollary of the static I-2 - recorded, not pre-judged (open_question(i8_vacuity)).").
claim_label(pr_recon_i8_soundness, prescriptive).
claim_status(pr_recon_i8_soundness, open).
claim_premise(pr_recon_i8_soundness, i8_machine_checked_nonvacuous).
claim_negation_provenance(pr_recon_i8_soundness, i8_machine_checked_nonvacuous, absent).

claim(pr_recon_clamp_wellformedstart, "STRONGER LOAD-BEARING CLAIM: planRecon yields a WellFormedStart - a complete contiguous prefix - from ANY proposed window + present-artifact set. It clamps an over-eager attach window down to the first incomplete prefix stage (override-and-report, b13) and refuses a holed operator window (feasible:false, b14). This obligation holds INDEPENDENTLY of the I-8 vacuity outcome: even if the abstract invariant collapses to an I-2 corollary, the clamp/refuse code is a new operational obligation. Not yet on disk.").
claim_label(pr_recon_clamp_wellformedstart, prescriptive).
claim_status(pr_recon_clamp_wellformedstart, conditional).
claim_premise(pr_recon_clamp_wellformedstart, planrecon_yields_wellformedstart).
claim_negation_provenance(pr_recon_clamp_wellformedstart, planrecon_yields_wellformedstart, absent).

claim(pr_recon_seed_from_plan, "The cursor / scope / produced-set seed FROM the recon plan: a non-zero start runs only the windowed segments; a startIdx=0 plan reproduces the cold run (b12). The seed-from-plan code does not yet exist on disk.").
claim_label(pr_recon_seed_from_plan, prescriptive).
claim_status(pr_recon_seed_from_plan, conditional).
claim_premise(pr_recon_seed_from_plan, cursor_seeds_from_recon_plan).
claim_negation_provenance(pr_recon_seed_from_plan, cursor_seeds_from_recon_plan, absent).

% =============================================================================
% FORMAL PROPERTIES — I-8 lifted from existing-world-recon.pl's
% formal_property_sketch(i8, safety, _) into Lean sketches for prove-invariants.
% Default shape: QUANTIFIED INVARIANT (forall ...), NOT an enumerated conjunction
% of pair facts (which would degrade to `decide` over a list and trip the closer's
% forbidden-tactics rule). Bodies left `sorry` for the prover.
% =============================================================================

formal_property(p_recon_i8_seed_soundness,
    "I-8 (abstract, weak form): every honored window seeds a complete, contiguous, strict-loading prefix - seed_produced(W) = { stage_i : i < startIdx W } and every stage below startIdx is present and strict-loads - so I-2 artifact-gating holds at the seed. NOTE (open_question i8_vacuity): if I-2 gating is static and total, this may be a vacuous corollary of I-2; prove-invariants adjudicates non-vacuity, this stage does not.",
    "theorem i8_seed_soundness : forall (w : Window) (i : Nat), i < startIdx w -> (Present (stageAt w i) /\\ StrictLoads (stageAt w i)) /\\ seedProduced w = { s | exists j, j < startIdx w /\\ s = stageAt w j } := by sorry  -- weak form; non-vacuity vs static I-2 is the open question").

formal_property(p_recon_clamp_wellformedstart,
    "STRONGER load-bearing property: planRecon yields a WellFormedStart from ANY proposed window and present-artifact set. A WellFormedStart is a complete contiguous prefix all of whose stages are present and strict-load. Attach clamps an over-eager window down to the first incomplete prefix stage; operator refuses (feasible:false) a holed prefix. This is the vacuity-INDEPENDENT obligation: it holds whether or not the abstract I-8 reduces to I-2.",
    "def WellFormedStart (s : Seed) : Prop := forall i, i < s.startIdx -> (Present (s.stageAt i) /\\ StrictLoads (s.stageAt i))\ntheorem planRecon_wellformedstart : forall (w : ProposedWindow) (p : PresenceMap), WellFormedStart (planRecon w p) := by sorry  -- clamp (attach) + refuse (operator) both establish WellFormedStart").

formal_property(p_recon_no_widen_below_frozen,
    "Attach refinement: no loopback widens the start index below the attach-adopted frozenPrefix; a hard-stop fires instead. Quantified over all loopback steps of an attach run.",
    "theorem i8_frozen_prefix_floor : forall (r : AttachRun) (k : Nat), k < r.steps -> r.frozenPrefix <= startIdxAt r k := by sorry  -- startIdx never drops below the adopted frozen prefix").

% =============================================================================
% EVIDENCE — Prolog queries against existing-world-recon.pl that back the claims.
% =============================================================================

evidence(cf_recon_no_verdict,
    "negation_provenance(recon_computes_logic_verdict, P), recon_never(compute_logic_verdict).",
    "P = contradicts; recon_never(compute_logic_verdict) is a ground fact. The KB EXPLICITLY forbids recon computing a verdict (C-7); falseness is structurally necessary, not CWA-absent.").
evidence(cf_recon_no_edit,
    "negation_provenance(recon_edits_durable_artifact, P), recon_never(edit_durable_artifact).",
    "P = contradicts; recon_never(edit_durable_artifact) is a ground fact (C-7).").
evidence(cf_recon_no_content_inspect,
    "negation_provenance(plan_recon_inspects_artifact_content, P), plan_recon_never(inspect_artifact_content).",
    "P = contradicts; plan_recon_never(inspect_artifact_content) is a ground fact (C-7).").
evidence(cf_recon_no_holed_seed,
    "negation_provenance(seeded_run_violates_i2_gating, P), acceptance_criterion(b14, _, _).",
    "P = contradicts. b14 refuses an operator window whose prefix is not all-present (feasible:false). No fact, criterion, constraint, decision, or open question permits a non-contiguous prefix as a seed (exhaustive falsifier search returned empty).").
evidence(cf_recon_no_regenerate,
    "negation_provenance(frozenprefix_attach_regenerates_adopted_artifact, P).",
    "P = contradicts. The adopted prefix is frozen, never re-produced (attach refinement).").
evidence(cf_recon_no_widen_below_frozen,
    "negation_provenance(loopback_widens_below_frozen_prefix, P), acceptance_criterion(b15, _, _).",
    "P = contradicts; b15 hard-stops a loopback that would widen below a frozen (attach-adopted) prefix.").
evidence(cf_recon_d_modes,
    "findall(M-T, recon_mode(M, T), L).",
    "L = [operator-..., attach-..., resume-...]. Three modes pinned in D-14: operator authoritative, attach judges tail segments, resume continues from first missing artifact.").
evidence(cf_recon_d_reports,
    "findall(R, recon_reports(R, _), Rs).",
    "Rs = [presence_exists, presence_strict_load, window_recommendation]. Exactly three permitted outputs; none is a verdict type (consistent/refuted/proven/inconsistent absent from the enumeration).").
evidence(pr_recon_i8_soundness,
    "formal_property_sketch(i8, safety, _), open_question(i8_vacuity, _), formal_criterion_targets(f8, i8).",
    "i8 carries a safety formal_property_sketch (liftable); f8 targets i8 (Lean machine-check pending). open_question(i8_vacuity) is UNRESOLVED in the KB - no fact asserts vacuous_corollary(i8) or resolved(i8). prove-invariants adjudicates; this stage leaves it open.").
evidence(pr_recon_clamp_wellformedstart,
    "acceptance_criterion(b13, _, _), acceptance_criterion(b14, _, _), behavioral_seeds(b13, i8), behavioral_seeds(b14, i8).",
    "b13 (attach clamp to first incomplete prefix stage, override-and-report) and b14 (refuse holed operator window) both seed i8. Together they establish the WellFormedStart obligation independent of the abstract invariant's vacuity.").
evidence(pr_recon_seed_from_plan,
    "acceptance_criterion(b12, _, _), behavioral_seeds(b12, d14), behavioral_seeds(b12, i8).",
    "b12 seeds cursor/scope/produced from the recon plan; startIdx=0 reproduces the cold run. No fact asserts the seed-from-plan code exists on disk (absent under CWA - the prescriptive delta).").

% =============================================================================
% COVERAGE
% =============================================================================
coverage(total_clauses, 82).
coverage(claims_emitted, 14).
coverage(predicates_exercised, [proposition/2, invariant/3, constraint/3, constraint_specializes/2, recon_reports/2, recon_never/1, recon_mode/2, plan_recon_reads/1, plan_recon_never/1, negation_provenance/2, falsifier/1, acceptance_criterion/3, behavioral_seeds/2, formal_property_sketch/3, invariant_formalizes/2, formal_criterion_targets/2, open_question/2]).
coverage(percentage, 74).
coverage(assessment, high).
coverage(unexercised_predicates, [decision_table/4, recon_kb_consistent/0, recon_violation/1, decision_rationale/2, exception/3]).

% =============================================================================
% ASSUMPTIONS / OPEN QUESTIONS
% =============================================================================
assumption(a_recon_i8_vacuity,
    "open_question(i8_vacuity): the abstract I-8 (pr_recon_i8_soundness) MAY resolve to a vacuous corollary of the static I-2 gating. This is NOT pre-judged here (C-7 / Orbital Inversion: no consistent/proven verdict is earned until a genuine refutation attempt by prove-invariants fails). pr_recon_i8_soundness is therefore status `open`; the vacuity-independent clamp claim (pr_recon_clamp_wellformedstart) carries the load regardless of the outcome. Resolved when prove-invariants returns theorem_verdict(i8_seed_soundness, proven | unprovable) plus a non-vacuity witness.").
assumption(a_recon_impl_grain,
    "The prescriptive claims assume the target-world model exposes the operational predicates the I-8 sketches name (Window, Seed, startIdx, stageAt, Present, StrictLoads, PresenceMap, frozenPrefix, AttachRun). model-obligations must materialize these from the D-14 / I-8 decision-level facts; if it cannot, emit upstream_gap(schema_insufficient) toward close-world.").
assumption(a_recon_runtime_behavioral,
    "The recon agent's presence/strict-load observations are partly runtime mechanical facts that close-world cannot fully capture (CWA strips runtime behaviour). Expect instantiate-properties to emit b12/b13/b14/b15 as behavioral_claim tests, not pure projections.").

% =============================================================================
% GATE-TARGET / REFUTATION SHAPE (for the orchestrator + disprove-proposition)
% Primary refutation surface = every recon counterfactual premise + every
% prescriptive new-fact assertion. Disprove classes:
%   - Orbital Inversion (C-7) : attack cf_recon_no_verdict (recon emits a verdict)
%   - seed gating (I-8 / I-2) : attack cf_recon_no_holed_seed (a holed prefix seeds)
%   - frozenPrefix floor      : attack cf_recon_no_widen_below_frozen (loopback widens below frozen)
%   - I-8 non-vacuity         : attack pr_recon_i8_soundness (I-8 is a vacuous I-2 corollary)
%   - clamp soundness         : attack pr_recon_clamp_wellformedstart (planRecon yields a holed start)
% =============================================================================
refutation_target(cf_recon_no_verdict, orbital_inversion, "C-7 specializes C-2; highest-value disprove target - recon laundering a substrate verdict.").
refutation_target(cf_recon_no_holed_seed, seed_gating_failure, "a honored window whose prefix is not all present + strict-loading (I-8 / I-2).").
refutation_target(cf_recon_no_widen_below_frozen, frozen_prefix_floor_failure, "a loopback that widens below the attach-adopted frozenPrefix (b15).").
refutation_target(pr_recon_i8_soundness, i8_vacuity, "prove-invariants may find the abstract I-8 a vacuous corollary of the static I-2 - the open question, not pre-judged.").
refutation_target(pr_recon_clamp_wellformedstart, clamp_soundness_failure, "planRecon yielding a holed (non-contiguous) start from some proposed window - the vacuity-independent load-bearing target.").

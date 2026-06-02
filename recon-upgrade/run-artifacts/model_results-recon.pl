% model_results-recon.pl
% =============================================================================
% model-obligations (Stage 3) — RECON EXTENSION — per-property verdicts.
%   carrier in : recon-upgrade/run-artifacts/hypothesis-recon.pl
%                (3 formal_property/3 + the recon claim cluster)
%   substrate  : recon-upgrade/run-artifacts/target-world-recon.pl
%                (+ existing-world-recon.pl + baseline self-spec/existing-world.pl)
%   constructed: 2026-06-02
%
% Downstream (prove-invariants / disprove-proposition) queries this file with
% swipl, not prose.
%
% HEADLINE: of the 3 recon §-properties —
%   * p_recon_clamp_wellformedstart  -> CONSISTENT (the STRONGER, vacuity-INDEP-
%       ENDENT load-bearing obligation: planRecon yields a WellFormedStart from
%       ANY proposed window; a genuine falsification over a >=2-inhabitant seed
%       domain WITH a real hole to find returned EMPTY).
%   * p_recon_no_widen_below_frozen  -> CONSISTENT (no loopback widens below the
%       attach-adopted frozenPrefix; falsification empty over a non-zero-frozen
%       attach run with >=2 loopback steps).
%   * p_recon_i8_seed_soundness      -> OPEN (the ABSTRACT weak-form I-8). The
%       weak form HOLDS in the model (no honored seed fails the prefix check), but
%       open_question(i8_vacuity) — whether the abstract invariant is non-vacuous
%       or a corollary of the static total I-2 gating — is a Lean non-vacuity
%       JUDGMENT prove-invariants adjudicates. C-7 / THE ORBITAL INVERSION forbids
%       this stage laundering the substrate prefix-check into a `consistent`
%       verdict on the abstract invariant. Emitted OPEN + gap_reason, NOT consistent.
%
% C-7 DISCIPLINE: every `consistent` here was EARNED — a genuine counterexample
% search over a NON-DEGENERATE seed domain (3 honored seeds at varying startIdx
% {0, 4, 5} + a holed-window witness) FAILED to find a violation, and each
% violation rule was PROBED with a deliberately-broken witness and CONFIRMED to
% fire (anti-vacuity). No substrate computation was laundered into a verdict.
%
% SELF-CONTAINMENT: every verdict + non-vacuity result was validated against
% target-world-recon.pl loaded STANDALONE (the prove-invariants carrier view) —
% strict-load exit 0 under `swipl --on-warning=status --on-error=status`.
% =============================================================================

:- discontiguous verdict/2, counterexample/2, gap_reason/2, cf_status/2,
                 summary/2, emission_note/2, upstream_gap/3,
                 refutation_shape/2, negation_provenance_carry/2,
                 nonvacuity/2.

% ----- per-property verdicts (source order from hypothesis-recon.pl) -----
verdict(p_recon_i8_seed_soundness, open).        % abstract weak form; vacuity is prove-invariants' call (C-7)
verdict(p_recon_clamp_wellformedstart, consistent). % STRONGER, vacuity-independent, load-bearing
verdict(p_recon_no_widen_below_frozen, consistent). % frozenPrefix floor (b15)

% ----- counterexamples (present iff inconsistent) -----
% (none — no inconsistent verdicts; the falsification searches returned empty
%  over a non-degenerate domain that contained a real hole to find)

% ----- gap reasons (present iff gap / open) -----
% p_recon_i8_seed_soundness is OPEN, not consistent: the weak form holds in the
% model but the LOAD-BEARING non-vacuity question (abstract I-8 vs. static total
% I-2) is undecidable at the decision-KB level — it is prove-invariants' Lean
% adjudication, NOT this stage's. C-7 forbids laundering the substrate prefix
% check into a consistent verdict on the abstract invariant.
gap_reason(p_recon_i8_seed_soundness,
  'WEAK FORM HOLDS (no honored seed fails the complete-contiguous-strict-loading prefix check; falsification empty over the >=2-inhabitant seed domain). But open_question(i8_vacuity) — non-vacuity of the abstract I-8 vs. the static total I-2 gating — is a Lean non-vacuity judgment prove-invariants adjudicates. C-7 / the Orbital Inversion forbids this stage emitting `consistent` on the abstract invariant from a substrate prefix-check. Resolved when prove-invariants returns theorem_verdict(i8_seed_soundness, proven|unprovable) + a non-vacuity witness.').

% ----- seed-domain non-degeneracy attestation -----
% The seed domain has >= 2 DISTINCT inhabitants at VARYING startIdx, so no
% universal collapses to a vacuous one-point statement.
%   sd_cold        startIdx 0  — the cold seed (empty prefix; b12; resume).
%   sd_attach_clamp startIdx 4 — a non-trivial attach seed; the b13 clamp target.
%   sd_attach      startIdx 5  — a non-trivial attach seed (>= 4); attach mode.
%   sd_hole (NOT honored)      — the HOLE seed: a proposed window whose prefix is
%                                not all present+strict-loading (index 2 present
%                                but not strict-loading). It is the falsification
%                                witness the WellFormedStart search must clamp
%                                (attach) / refuse (operator), NEVER honored.
nonvacuity(seed_domain, distinct_start_indices([0, 4, 5])).
nonvacuity(seed_domain, includes_cold_seed(sd_cold, startidx(0))).
nonvacuity(seed_domain, includes_nontrivial_attach(sd_attach, startidx(5))).
nonvacuity(seed_domain, includes_hole_witness(sd_hole, holed_window(w_holed_operator), refused_feasible_false)).

% ----- non-vacuity attestation (each violation rule probed with a broken witness) -----
% A `consistent` / `open` verdict means "no counterexample found in a world where
% one COULD be found," NOT "the rule was empty." Each per-property violation rule
% was probed with a deliberately-broken witness and CONFIRMED to fire:
nonvacuity(p_recon_i8_seed_soundness, fires_on(seed_not_wellformed(sdpx_holed_start3))).
nonvacuity(p_recon_clamp_wellformedstart, fires_on(honored_seed_not_wellformed(sdpx_holed_start3))).
nonvacuity(p_recon_clamp_wellformedstart, fires_on(holed_window_honored_unsafely(wpx_holed_unrefused))).
nonvacuity(p_recon_no_widen_below_frozen, fires_on(widens_below_frozen(ar0, probe_step, 2, 4))).
% HOLE distinguishability: the WellFormedStart helper REJECTS the holed window
% (hole_seed_wellformed FAILS over w_holed_operator's holed index 2) — confirming
% the prefix check genuinely separates well-formed from holed seeds.
nonvacuity(wellformed_start, rejects_hole(w_holed_operator, hole_at_index(2))).

% ----- counterfactual minimality (all 6 recon cf_facts load-bearing) -----
% Each was checked by a GENUINE re-introduction probe: re-introduce the forbidden
% fact and confirm gating re-violates; removing the load-bearing witness flips the
% status to `extraneous` (verified for the loopback and frozenprefix_attach cfs).
% The three C-7 prohibition cfs are load-bearing by the structurally-necessary
% `contradicts` provenance (re-introducing the forbidden action re-violates C-7).
cf_status(cf_fact(recon, computes_logic_verdict), load_bearing).            % C-7 / C-2
cf_status(cf_fact(recon, edits_durable_artifact), load_bearing).            % C-7
cf_status(cf_fact(plan_recon, inspects_artifact_content), load_bearing).    % C-7
cf_status(cf_fact(seeded_run, violates_i2_gating), load_bearing).           % I-8 / I-2 (the HOLE seed)
cf_status(cf_fact(frozenprefix_attach, regenerates_adopted_artifact), load_bearing). % I-8 refinement
cf_status(cf_fact(loopback, widens_below_frozen_prefix), load_bearing).     % I-8 refinement / b15

% ----- summary counts -----
summary(verdicts_total, 3).
summary(consistent, 2).            % p_recon_clamp_wellformedstart, p_recon_no_widen_below_frozen
summary(open, 1).                  % p_recon_i8_seed_soundness (vacuity is prove-invariants' call)
summary(inconsistent, 0).
summary(gap, 1).                   % the OPEN verdict carries a gap_reason
summary(extraneous_counterfactuals, 0).
summary(counterfactuals_applied, 6).      % 6 recon cf_facts (all `contradicts` provenance)
summary(prescriptive_obligations, 3).     % pr_recon_i8_soundness, pr_recon_clamp_wellformedstart, pr_recon_seed_from_plan
summary(honored_seeds, 3).                % sd_cold, sd_attach_clamp, sd_attach
summary(distinct_start_indices, 3).       % {0, 4, 5}
summary(operational_predicates_materialized, 9). % Window, Seed, startIdx, stageAt, Present, StrictLoads, PresenceMap, frozenPrefix, AttachRun

% ----- negation-provenance carry-forward (for prove-invariants @ Prolog->Lean) -----
% The provenance distinction MUST be preserved into Lean. `contradicts` premises
% are structurally necessary (the spec explicitly negates them); `absent`
% premises are CWA-fragile — Lean MUST NOT lift them to a proven negation.
% CWA-absent != Lean-disproved.
negation_provenance_carry(recon_computes_logic_verdict, contradicts).
negation_provenance_carry(recon_edits_durable_artifact, contradicts).
negation_provenance_carry(plan_recon_inspects_artifact_content, contradicts).
negation_provenance_carry(seeded_run_violates_i2_gating, contradicts).
negation_provenance_carry(frozenprefix_attach_regenerates_adopted_artifact, contradicts).
negation_provenance_carry(loopback_widens_below_frozen_prefix, contradicts).
negation_provenance_carry(i8_machine_checked_nonvacuous, absent).          % CWA-FRAGILE (pr_recon_i8_soundness)
negation_provenance_carry(planrecon_yields_wellformedstart, absent).       % CWA-FRAGILE (pr_recon_clamp)
negation_provenance_carry(cursor_seeds_from_recon_plan, absent).           % CWA-FRAGILE (pr_recon_seed_from_plan)

% ----- refutation-shape briefing (carry-forward for downstream disprove) -----
% Threaded forward so the disprove gate / prove-invariants attack the right
% surfaces (mirrors the recon hypothesis's refutation_target/3).
refutation_shape(orbital_inversion,
    "C-7 specializes C-2; highest-value disprove target — recon laundering a substrate verdict. Surface: any op_recon_* fact or this stage emitting a logic verdict the agent did not judge. The 3 C-7 prohibition cf_facts are the watch list.").
refutation_shape(seed_gating_failure,
    "I-8 / I-2. Surface: p_recon_clamp_wellformedstart — a honored window whose prefix is not all present + strict-loading (the sd_hole / w_holed_operator witness re-introduced as a HONORED seed; clamp/refuse must override it).").
refutation_shape(frozen_prefix_floor_failure,
    "I-8 refinement / b15. Surface: p_recon_no_widen_below_frozen — a loopback widening below the attach-adopted frozenPrefix (op_loopback_start_cf is the necessity witness).").
refutation_shape(i8_vacuity,
    "prove-invariants may find the abstract I-8 a vacuous corollary of the static total I-2 — the OPEN question this stage did NOT pre-judge. Surface: p_recon_i8_seed_soundness (verdict open). Resolved by a Lean non-vacuity witness.").
refutation_shape(clamp_soundness_failure,
    "the vacuity-INDEPENDENT load-bearing target: planRecon yielding a holed (non-contiguous) start from some proposed window. Surface: p_recon_clamp_wellformedstart (clamp_violation/1 rules).").

% ----- Pattern-3 watch (primary refutation surface for these descriptors) -----
% A counterfactually-removed fact that the IMPLEMENTATION still asserts is a
% Pattern-3 violation. The 6 load-bearing cf_facts above are the watch list;
% measure-entailment checks each against the realized planRecon code.

% ----- emission note (self-containment) -----
% target-world-recon.pl is SELF-CONTAINED: the sole carrier prove-invariants
% reads. A STANDALONE consult (no existing-world*.pl co-loaded) resolves every
% recon operational procedure and fires all verdict directives, under the
% strict-load contract (swipl --on-warning=status --on-error=status -> exit 0).
% The recon descriptive carrier predicates (recon_mode/2, recon_reports/2,
% recon_never/1, plan_recon_reads/1, plan_recon_never/1, constraint_specializes/2,
% open_question/2) are materialized verbatim and declared multifile, so the
% co-loaded companion path (existing-world-recon.pl + target-world-recon.pl)
% appends rather than redefining — both exit 0.
emission_note(target_world_recon_self_contained, standalone_consult_strict_load_exit_0).
emission_note(seed_domain_non_degenerate, three_honored_seeds_varying_startidx_plus_hole_witness).
emission_note(tabling_used, 'tw_recon_prefix_covers/2 (the transitive prefix-coverage helper) is :- table-d; tw_wellformed_start/1 reduces to it for non-cold seeds, so the recursive helper is load-bearing.').

% ----- coverage note -----
% Coverage over the verdict goals + minimality probes was 28.5% of 207 clauses by
% the raw line-coverage metric. The denominator is dominated by passive metadata:
% 85 provenance/2 audit tags + 3 verbatim formal_property/3 Lean-sketch strings =
% 88 clauses (43%) that the verdict GOALS are not meant to traverse (they exist
% for the world-diff audit trail and prove-invariants' schema handle, exactly as
% in the baseline self-spec/target-world.pl). Excluding that metadata, the goals
% exercise ~50% of the load-bearing operational + rule clauses; every load-bearing
% predicate (op_recon_seed/1, op_recon_present/2, op_recon_strict_loads/2,
% op_recon_window_raw/3, op_recon_clamps_to/2, op_recon_feasible/2, op_attach_run/1,
% op_frozen_prefix/2, op_loopback_start/3, tw_recon_prefix_covers/2,
% tw_wellformed_start/1, tw_recon_raw_hole/2, the 3 violation families, cf_fact/2,
% cf_minimality/2) was exercised. Assessment: ACCEPTABLE for these focused
% properties (the headline 28.5% is provenance-tag density, NOT thin facts). NOT
% marked NEEDED ADAPTATION: the recon substrate was DERIVABLE from the decision-
% level recon facts without fabrication.
emission_note(coverage,
  'raw 28.5% of 207 clauses; 88 (43%) are passive provenance/formal_property metadata; load-bearing operational + rule clauses ~50% exercised; acceptable for focused properties.').

% ----- upstream gaps -----
% NONE at the schema level. assumption(a_recon_impl_grain) flagged that the I-8
% sketches name operational predicates (Window, Seed, startIdx, stageAt, Present,
% StrictLoads, PresenceMap, frozenPrefix, AttachRun) absent from the decision-level
% recon KB, directing: materialize them from the D-14 / I-8 facts, or emit
% upstream_gap(schema_insufficient). RESOLUTION: every operational predicate was
% DERIVED from the recon stage spine + the b12..b15 acceptance criteria + the I-8
% sketch (not fabricated), so NO schema_insufficient gap is emitted. The single
% non-`consistent` verdict (p_recon_i8_seed_soundness = open) is NOT a stage-3 gap
% in the schema sense — it is a deliberate deferral of the i8_vacuity judgment to
% prove-invariants under C-7, carried as gap_reason above.
% (A concrete planRecon STEP-TRACE — runtime behavior the decision KB cannot pin —
%  surfaces at instantiate-properties as b12/b13/b14/b15 behavioral_claim tests,
%  per assumption(a_recon_runtime_behavioral); it is not a stage-3 gap.)

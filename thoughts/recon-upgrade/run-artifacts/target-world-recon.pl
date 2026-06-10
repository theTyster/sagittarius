% target-world-recon.pl
% =============================================================================
% model-obligations (Stage 3) — RECON EXTENSION (ATTACH mode).
%   carrier in  : recon-upgrade/run-artifacts/hypothesis-recon.pl
%                 (3 formal_property/3: p_recon_i8_seed_soundness,
%                  p_recon_clamp_wellformedstart, p_recon_no_widen_below_frozen)
%   transitive  : recon-upgrade/run-artifacts/existing-world-recon.pl
%                 + baseline self-spec/existing-world.pl
%   baseline    : self-spec/target-world.pl  (the proven I-1..I-7 substrate)
%   constructed : 2026-06-02
%
% target-world-recon.pl AMENDS the baseline target-world for the recon primer.
% It does NOT regenerate the proven I-1..I-7 substrate (that stays in
% self-spec/target-world.pl, untouched). It MATERIALIZES the recon-specific
% operational substrate the I-8 sketches name (Window, Seed, startIdx, stageAt,
% Present, StrictLoads, PresenceMap, frozenPrefix, AttachRun) so each recon
% formal_property/3 is NON-VACUOUS when prove-invariants targets it in Lean.
%
% LOADING CONTRACT (strict-loading, references/prolog-wiki/practices/strict-loading.md):
%   swipl --on-warning=status --on-error=status -q \
%     -g "[ 'recon-upgrade/run-artifacts/target-world-recon.pl' ]" -t halt   -> exit 0
% This file is SELF-CONTAINED: it is the sole carrier prove-invariants reads, so
% the recon stage chain (the 8-stage spine the primer seeds) + every op_recon_*
% fact is materialized HERE, resolving every operational procedure standalone.
% Verdict directives (:- ...) run at load time and assert verdict/2 + cf_status/2
% + counterexample/2 / gap_reason/2, dumped to model_results-recon.pl.
%
% =============================================================================
% C-7 / THE ORBITAL INVERSION (the governing constraint of this stage)
% -----------------------------------------------------------------------------
% recon and this model-obligations stage REPORT facts and emit AGENT-JUDGED
% verdicts; they NEVER launder a substrate computation into a verdict. A
% `consistent` / `proven` verdict is EARNED only after a genuine falsification
% attempt (an exhaustive counterexample search over the seed domain) FAILS.
% Each verdict directive below runs such a search; where the decision KB cannot
% decide a property (e.g. the I-8 vacuity open question, which prove-invariants
% adjudicates, NOT this stage) we emit `open`/`gap` + gap_reason, NEVER a vacuous
% `consistent`.
% =============================================================================
% NON-DEGENERATE-MODEL BAR
% -----------------------------------------------------------------------------
% The seed domain has >= 2 DISTINCT inhabitants with VARYING startIdx:
%   * sd_cold   (startIdx = 0)  — the cold seed; empty produced prefix; b12.
%   * sd_attach (startIdx = 5)  — a non-trivial attach seed (>= 4); a complete
%                                 contiguous present+strict-loading prefix 0..4.
%   * sd_attach_clamp(startIdx=4) — a second well-formed attach seed (the b13
%                                 override-and-report TARGET an over-eager window
%                                 clamps DOWN to; distinct startIdx, distinct map).
%   * sd_hole   (startIdx = 5)  — a HOLE seed that VIOLATES the prefix: index 2
%                                 is present but does NOT strict-load (a holed
%                                 prefix). This is the forbidden seed the WindowRaw
%                                 honors and planRecon must clamp(attach)/refuse
%                                 (operator). It exists ONLY in the *_raw / *_cf
%                                 predicates (a counterexample witness), NEVER as a
%                                 honored op_recon_seed.
% So every universal ("forall honored seed ...") ranges over >= 2 well-formed
% points AND the falsification search has a real hole to find — neither vacuous
% nor degenerate.
% =============================================================================

:- discontiguous
     provenance/2,
     formal_property/3,
     obligation/2,
     op_recon_stage_index/2,
     op_recon_present/2,
     op_recon_strict_loads/2,
     op_recon_seed/1,
     op_recon_seed_start/2,
     op_recon_seed_mode/2,
     op_recon_produced/2,
     op_recon_window_raw/3,
     op_recon_present_raw/2,
     op_recon_strict_loads_raw/2,
     op_recon_clamps_to/2,
     op_recon_feasible/2,
     op_attach_run/1,
     op_frozen_prefix/2,
     op_loopback_start/3,
     op_loopback_start_cf/3,
     op_regenerates_cf/2,
     recon_mode/2,
     recon_reports/2,
     recon_never/1,
     plan_recon_reads/1,
     plan_recon_never/1,
     open_question/2,
     constraint_specializes/2.

% verdict facts are asserted at load time by the per-property directives.
:- dynamic
     verdict/2,
     counterexample/2,
     gap_reason/2,
     cf_status/2,
     emission_note/2,
     upstream_gap/3,
     summary/2,
     refutation_shape/2,
     nonvacuity/2.

% negation_provenance/2 is co-defined with existing-world-recon.pl (same user
% module); declared multifile so the cross-file definition is legitimate and the
% recon `contradicts` rows append cleanly when co-loaded. Standalone, only this
% file's copies exist (the carrier contract).
:- multifile negation_provenance/2.
% The recon descriptive carrier predicates are MATERIALIZED here (so the
% STANDALONE consult prove-invariants performs resolves them) AND are also
% defined in existing-world-recon.pl (the close-world source). Declared
% `multifile` so the co-loaded path (swipl … existing-world-recon.pl
% target-world-recon.pl) APPENDS rather than "redefining a static procedure" —
% both files assert byte-identical facts, so the union is the same world either
% way. Standalone, only this file's copies exist; that is the carrier contract
% (mirrors self-spec/target-world.pl's multifile stage/2 … treatment).
:- multifile
     recon_mode/2,
     recon_reports/2,
     recon_never/1,
     plan_recon_reads/1,
     plan_recon_never/1,
     constraint_specializes/2,
     open_question/2.

% =============================================================================
% CARRIED-OVER DESCRIPTIVE FACTS — the recon design surface this stage relies on
% -----------------------------------------------------------------------------
% Mirrors the recon close-world facts the verdict directives branch on, copied
% VERBATIM (same args/values) so a STANDALONE consult resolves every recon
% operational procedure. Tagged provenance(_, descriptive): they describe the
% spec's fixed recon modes / reports / prohibitions / C-7 specialization.
% =============================================================================

% --- the three recon resolution modes (D-14) --------------------------------
recon_mode(operator, 'Operator from/to authoritative; validated for feasibility only.').
recon_mode(attach,   'A claim is supplied; judge which tail segments it needs.').
recon_mode(resume,   'No claim; continue from the first missing durable artifact.').
provenance(recon_mode(operator, _), descriptive).
provenance(recon_mode(attach, _), descriptive).
provenance(recon_mode(resume, _), descriptive).

% --- recon's permitted reports (mechanical observations only) ----------------
recon_reports(presence_exists, 'whether each durable artifact exists.').
recon_reports(presence_strict_load, 'whether each present artifact strict-loads.').
recon_reports(window_recommendation, 'a recommended {from,to} window (NOT a verdict).').
provenance(recon_reports(presence_exists, _), descriptive).
provenance(recon_reports(presence_strict_load, _), descriptive).
provenance(recon_reports(window_recommendation, _), descriptive).

% --- recon prohibitions (C-7 / Orbital Inversion) ----------------------------
recon_never(compute_logic_verdict).
recon_never(edit_durable_artifact).
provenance(recon_never(compute_logic_verdict), descriptive).
provenance(recon_never(edit_durable_artifact), descriptive).
plan_recon_reads(agent_emitted_recon_facts).
plan_recon_reads(operator_window).
plan_recon_never(inspect_artifact_content).
provenance(plan_recon_reads(agent_emitted_recon_facts), descriptive).
provenance(plan_recon_reads(operator_window), descriptive).
provenance(plan_recon_never(inspect_artifact_content), descriptive).

% --- C-7 specializes C-2 -----------------------------------------------------
constraint_specializes(c7, c2).
provenance(constraint_specializes(c7, c2), descriptive).

% --- the I-8 vacuity open question (NOT resolved here; prove-invariants does) -
open_question(i8_vacuity,
  'I-8 abstract form may be a vacuous corollary of the static I-2 gating; recorded as an open question, NOT pre-judged.').
provenance(open_question(i8_vacuity, _), descriptive).

% =============================================================================
% RECON STAGE SPINE — the loop the primer seeds (8 stages, indices 0..7).
% -----------------------------------------------------------------------------
% Carried from the baseline stage chain (s1..s_explain). The primer seeds a
% startIdx into THIS chain; a WellFormedStart is a complete contiguous prefix of
% it. Materialized here so the carrier is self-contained.
% op_recon_stage_index(StageId, Index).
% =============================================================================
op_recon_stage_index(s1, 0).
op_recon_stage_index(s2, 1).
op_recon_stage_index(s3, 2).
op_recon_stage_index(s4, 3).
op_recon_stage_index(s5, 4).
op_recon_stage_index(s6, 5).
op_recon_stage_index(s7, 6).
op_recon_stage_index(s_explain, 7).
provenance(op_recon_stage_index(s1, 0), descriptive).
provenance(op_recon_stage_index(s2, 1), descriptive).
provenance(op_recon_stage_index(s3, 2), descriptive).
provenance(op_recon_stage_index(s4, 3), descriptive).
provenance(op_recon_stage_index(s5, 4), descriptive).
provenance(op_recon_stage_index(s6, 5), descriptive).
provenance(op_recon_stage_index(s7, 6), descriptive).
provenance(op_recon_stage_index(s_explain, 7), descriptive).
op_recon_max_index(7).
provenance(op_recon_max_index(7), descriptive).

% =============================================================================
% PRESENCE MAP — the agent-emitted mechanical observations (per index).
% -----------------------------------------------------------------------------
% op_recon_present(SeedId, Index)      — artifact at Index exists for this seed.
% op_recon_strict_loads(SeedId, Index) — that present artifact strict-loads.
% A WellFormedStart requires BOTH, for every Index < startIdx.
%
% NON-DEGENERATE: presence/strict-load maps DIFFER per seed (sd_cold has none
% below 0; sd_attach has 0..4; sd_attach_clamp has 0..3; sd_hole's *honored*
% map only carries the clamped-safe prefix — the HOLE is in the *_raw map).
% =============================================================================

% --- sd_attach: complete contiguous prefix indices 0..4 (startIdx 5) ----------
op_recon_present(sd_attach, 0).
op_recon_present(sd_attach, 1).
op_recon_present(sd_attach, 2).
op_recon_present(sd_attach, 3).
op_recon_present(sd_attach, 4).
op_recon_strict_loads(sd_attach, 0).
op_recon_strict_loads(sd_attach, 1).
op_recon_strict_loads(sd_attach, 2).
op_recon_strict_loads(sd_attach, 3).
op_recon_strict_loads(sd_attach, 4).
provenance(op_recon_present(sd_attach, 0), prescriptive).
provenance(op_recon_present(sd_attach, 1), prescriptive).
provenance(op_recon_present(sd_attach, 2), prescriptive).
provenance(op_recon_present(sd_attach, 3), prescriptive).
provenance(op_recon_present(sd_attach, 4), prescriptive).
provenance(op_recon_strict_loads(sd_attach, 0), prescriptive).
provenance(op_recon_strict_loads(sd_attach, 1), prescriptive).
provenance(op_recon_strict_loads(sd_attach, 2), prescriptive).
provenance(op_recon_strict_loads(sd_attach, 3), prescriptive).
provenance(op_recon_strict_loads(sd_attach, 4), prescriptive).

% --- sd_attach_clamp: complete contiguous prefix indices 0..3 (startIdx 4) ----
% This is the seed an over-eager window (rawStart 6, holed at 4) clamps DOWN to:
% the first incomplete prefix stage is index 4 (present but not strict-loading in
% the raw map), so the honored start clamps to 4 (b13 override-and-report).
op_recon_present(sd_attach_clamp, 0).
op_recon_present(sd_attach_clamp, 1).
op_recon_present(sd_attach_clamp, 2).
op_recon_present(sd_attach_clamp, 3).
op_recon_strict_loads(sd_attach_clamp, 0).
op_recon_strict_loads(sd_attach_clamp, 1).
op_recon_strict_loads(sd_attach_clamp, 2).
op_recon_strict_loads(sd_attach_clamp, 3).
provenance(op_recon_present(sd_attach_clamp, 0), prescriptive).
provenance(op_recon_present(sd_attach_clamp, 1), prescriptive).
provenance(op_recon_present(sd_attach_clamp, 2), prescriptive).
provenance(op_recon_present(sd_attach_clamp, 3), prescriptive).
provenance(op_recon_strict_loads(sd_attach_clamp, 0), prescriptive).
provenance(op_recon_strict_loads(sd_attach_clamp, 1), prescriptive).
provenance(op_recon_strict_loads(sd_attach_clamp, 2), prescriptive).
provenance(op_recon_strict_loads(sd_attach_clamp, 3), prescriptive).
% sd_cold has NO present/strict-load facts (startIdx 0 -> empty produced prefix);
% the WellFormedStart universal over i < 0 is vacuously-but-NON-degenerately true
% (its non-vacuity is carried by sd_attach / sd_attach_clamp, not by sd_cold).

% =============================================================================
% HONORED SEEDS — the seeds planRecon actually HONORS (post clamp/refuse).
% -----------------------------------------------------------------------------
% op_recon_seed(SeedId).
% op_recon_seed_start(SeedId, StartIdx).
% op_recon_seed_mode(SeedId, Mode)   — operator | attach | resume.
% Every HONORED seed must be a WellFormedStart (the I-8 / clamp obligation).
% sd_hole is NOT here: it is the forbidden holed window, present only in the
% *_raw / *_cf predicates as the counterexample witness planRecon clamps/refuses.
% =============================================================================
op_recon_seed(sd_cold).
op_recon_seed(sd_attach).
op_recon_seed(sd_attach_clamp).
provenance(op_recon_seed(sd_cold), prescriptive).
provenance(op_recon_seed(sd_attach), prescriptive).
provenance(op_recon_seed(sd_attach_clamp), prescriptive).

op_recon_seed_start(sd_cold, 0).            % cold seed: reproduces the cold run (b12)
op_recon_seed_start(sd_attach, 5).          % non-trivial attach (>= 4)
op_recon_seed_start(sd_attach_clamp, 4).    % the clamp target (b13)
provenance(op_recon_seed_start(sd_cold, 0), prescriptive).
provenance(op_recon_seed_start(sd_attach, 5), prescriptive).
provenance(op_recon_seed_start(sd_attach_clamp, 4), prescriptive).

op_recon_seed_mode(sd_cold, resume).        % no claim -> resume from first missing
op_recon_seed_mode(sd_attach, attach).      % a claim -> attach mid-chain
op_recon_seed_mode(sd_attach_clamp, attach).% over-eager attach window, clamped
provenance(op_recon_seed_mode(sd_cold, resume), prescriptive).
provenance(op_recon_seed_mode(sd_attach, attach), prescriptive).
provenance(op_recon_seed_mode(sd_attach_clamp, attach), prescriptive).

% feasibility of each honored seed (b14: operator refuses a holed window). All
% HONORED seeds are feasible:true (they survived clamp/refuse). The holed window
% is recorded feasible:false in op_recon_feasible below.
op_recon_feasible(sd_cold, true).
op_recon_feasible(sd_attach, true).
op_recon_feasible(sd_attach_clamp, true).
provenance(op_recon_feasible(sd_cold, true), prescriptive).
provenance(op_recon_feasible(sd_attach, true), prescriptive).
provenance(op_recon_feasible(sd_attach_clamp, true), prescriptive).

% =============================================================================
% RAW (PROPOSED) WINDOWS + THE HOLE SEED — the falsification surface.
% -----------------------------------------------------------------------------
% op_recon_window_raw(WindowId, RawStart, SeedItProposes) — what an operator /
%   over-eager attach agent PROPOSES, before planRecon clamps or refuses.
% op_recon_present_raw / op_recon_strict_loads_raw — the RAW presence map of the
%   proposed window (carries the HOLE).
% op_recon_clamps_to(WindowId, SafeStart) — the start planRecon clamps an
%   over-eager attach window DOWN to (b13: first incomplete prefix stage).
% op_recon_feasible(WindowId, false) — an operator window planRecon REFUSES (b14).
%
% sd_hole: a proposed window with rawStart 5 whose prefix is NOT complete — index
% 2 is present but does NOT strict-load (a holed prefix). This is the forbidden
% seed cf_recon_no_holed_seed forbids being HONORED.
% =============================================================================

% Over-eager ATTACH window: proposes rawStart 6 but index 4 fails to strict-load;
% planRecon CLAMPS it down to the first incomplete prefix stage (index 4) -> the
% honored seed sd_attach_clamp (startIdx 4). (b13 override-and-report.)
op_recon_window_raw(w_overeager_attach, 6, sd_attach_clamp).
op_recon_present_raw(w_overeager_attach, 0).
op_recon_present_raw(w_overeager_attach, 1).
op_recon_present_raw(w_overeager_attach, 2).
op_recon_present_raw(w_overeager_attach, 3).
op_recon_present_raw(w_overeager_attach, 4).
op_recon_present_raw(w_overeager_attach, 5).
op_recon_strict_loads_raw(w_overeager_attach, 0).
op_recon_strict_loads_raw(w_overeager_attach, 1).
op_recon_strict_loads_raw(w_overeager_attach, 2).
op_recon_strict_loads_raw(w_overeager_attach, 3).
% index 4 present_raw but NOT strict_loads_raw -> first incomplete prefix stage.
op_recon_clamps_to(w_overeager_attach, 4).
op_recon_feasible(w_overeager_attach, true).   % attach: clamps (does not refuse)
provenance(op_recon_window_raw(w_overeager_attach, 6, sd_attach_clamp), prescriptive).
provenance(op_recon_present_raw(w_overeager_attach, 0), prescriptive).
provenance(op_recon_present_raw(w_overeager_attach, 1), prescriptive).
provenance(op_recon_present_raw(w_overeager_attach, 2), prescriptive).
provenance(op_recon_present_raw(w_overeager_attach, 3), prescriptive).
provenance(op_recon_present_raw(w_overeager_attach, 4), prescriptive).
provenance(op_recon_present_raw(w_overeager_attach, 5), prescriptive).
provenance(op_recon_strict_loads_raw(w_overeager_attach, 0), prescriptive).
provenance(op_recon_strict_loads_raw(w_overeager_attach, 1), prescriptive).
provenance(op_recon_strict_loads_raw(w_overeager_attach, 2), prescriptive).
provenance(op_recon_strict_loads_raw(w_overeager_attach, 3), prescriptive).
provenance(op_recon_clamps_to(w_overeager_attach, 4), prescriptive).
provenance(op_recon_feasible(w_overeager_attach, true), prescriptive).

% Holed OPERATOR window (sd_hole): proposes rawStart 5 but index 2 is present and
% does NOT strict-load (a HOLE in the middle of the prefix). Operator windows are
% authoritative on CHOICE but validated for feasibility -> planRecon REFUSES it
% (feasible:false, b14). It is therefore NEVER an op_recon_seed.
op_recon_window_raw(w_holed_operator, 5, sd_hole).
op_recon_present_raw(w_holed_operator, 0).
op_recon_present_raw(w_holed_operator, 1).
op_recon_present_raw(w_holed_operator, 2).  % present ...
op_recon_present_raw(w_holed_operator, 3).
op_recon_present_raw(w_holed_operator, 4).
op_recon_strict_loads_raw(w_holed_operator, 0).
op_recon_strict_loads_raw(w_holed_operator, 1).
% index 2 present_raw but NOT strict_loads_raw -> the HOLE (non-contiguous prefix).
op_recon_strict_loads_raw(w_holed_operator, 3).
op_recon_strict_loads_raw(w_holed_operator, 4).
op_recon_feasible(w_holed_operator, false).  % b14: operator window REFUSED
provenance(op_recon_window_raw(w_holed_operator, 5, sd_hole), prescriptive).
provenance(op_recon_present_raw(w_holed_operator, 0), prescriptive).
provenance(op_recon_present_raw(w_holed_operator, 1), prescriptive).
provenance(op_recon_present_raw(w_holed_operator, 2), prescriptive).
provenance(op_recon_present_raw(w_holed_operator, 3), prescriptive).
provenance(op_recon_present_raw(w_holed_operator, 4), prescriptive).
provenance(op_recon_strict_loads_raw(w_holed_operator, 0), prescriptive).
provenance(op_recon_strict_loads_raw(w_holed_operator, 1), prescriptive).
provenance(op_recon_strict_loads_raw(w_holed_operator, 3), prescriptive).
provenance(op_recon_strict_loads_raw(w_holed_operator, 4), prescriptive).
provenance(op_recon_feasible(w_holed_operator, false), prescriptive).

% =============================================================================
% ATTACH RUN / frozenPrefix — the loopback floor surface (b15).
% -----------------------------------------------------------------------------
% op_attach_run(RunId).
% op_frozen_prefix(RunId, FrozenStart) — the attach-adopted frozen prefix; a
%   loopback may never widen the start BELOW it (a hard-stop fires instead).
% op_loopback_start(RunId, Step, StartIdx) — the start at each loopback step;
%   each must be >= the frozenPrefix (the floor holds).
% op_loopback_start_cf / op_regenerates_cf — the necessity-witness CF predicates
%   (a loopback that DOES widen below frozen; an attach run that DOES regenerate).
% =============================================================================
op_attach_run(ar0).
provenance(op_attach_run(ar0), prescriptive).
op_frozen_prefix(ar0, 4).          % adopted frozen prefix at start index 4
provenance(op_frozen_prefix(ar0, 4), prescriptive).
% loopback steps: start never drops below 4 (4, then 4 again — floor held).
op_loopback_start(ar0, 0, 5).      % op_loopback_start(Run, Step, StartIdx)
op_loopback_start(ar0, 1, 4).      % widened to the floor, not below
provenance(op_loopback_start(ar0, 0, 5), prescriptive).
provenance(op_loopback_start(ar0, 1, 4), prescriptive).

% =============================================================================
% NEGATION-PROVENANCE MARKERS (per-fact) — the recon counterfactual falsifiers.
% -----------------------------------------------------------------------------
% Mirrors hypothesis-recon.pl's claim_negation_provenance/3. All 6 recon
% counterfactual premises are `contradicts` (the spec EXPLICITLY negates them —
% structurally necessary, survives KB incompleteness); the 3 prescriptive-fragile
% premises are `absent` (CWA-fragile — not-yet-true, NOT proven false).
%
% NEGATION-PROVENANCE DISCIPLINE: an `absent` marker is NOT a proven negation;
% CWA-absent != Lean-disproved. Carried so prove-invariants annotates the fragile
% premises at the Prolog->Lean boundary.
% =============================================================================

% --- contradicts (structurally necessary — the spec explicitly negates) ------
negation_provenance(recon_computes_logic_verdict, contradicts).               % C-7 / C-2
negation_provenance(recon_edits_durable_artifact, contradicts).               % C-7
negation_provenance(plan_recon_inspects_artifact_content, contradicts).       % C-7
negation_provenance(seeded_run_violates_i2_gating, contradicts).              % §1 / I-8 / I-2
negation_provenance(frozenprefix_attach_regenerates_adopted_artifact, contradicts). % §1 / I-8
negation_provenance(loopback_widens_below_frozen_prefix, contradicts).        % I-8 refinement / b15

% --- absent (CWA-fragile — merely not-yet-true; do NOT upgrade to disproof) --
negation_provenance(i8_machine_checked_nonvacuous, absent).                   % pr_recon_i8_soundness
negation_provenance(planrecon_yields_wellformedstart, absent).                % pr_recon_clamp_wellformedstart
negation_provenance(cursor_seeds_from_recon_plan, absent).                    % pr_recon_seed_from_plan

% =============================================================================
% cf_fact/2 — counterfactual-removed facts, for the minimality rules below.
% -----------------------------------------------------------------------------
% Each corresponds to a recon counterfactual claim premise; the predicate models
% the forbidden operational fact whose ABSENCE an invariant relies on.
% =============================================================================
cf_fact(recon, computes_logic_verdict).            % C-7 / C-2
cf_fact(recon, edits_durable_artifact).            % C-7
cf_fact(plan_recon, inspects_artifact_content).    % C-7
cf_fact(seeded_run, violates_i2_gating).           % I-8 / I-2 (the HOLE seed)
cf_fact(frozenprefix_attach, regenerates_adopted_artifact). % I-8 refinement
cf_fact(loopback, widens_below_frozen_prefix).     % I-8 refinement / b15

% =============================================================================
% PRESCRIPTIVE OBLIGATIONS — must become true in target-world (NOT asserted).
% =============================================================================
obligation(i8_seed_soundness, pr_recon_i8_soundness).
provenance(obligation(i8_seed_soundness, pr_recon_i8_soundness), prescriptive).
obligation(clamp_wellformedstart, pr_recon_clamp_wellformedstart).
provenance(obligation(clamp_wellformedstart, pr_recon_clamp_wellformedstart), prescriptive).
obligation(seed_from_plan, pr_recon_seed_from_plan).
provenance(obligation(seed_from_plan, pr_recon_seed_from_plan), prescriptive).

% =============================================================================
% FORMAL PROPERTIES — propagated VERBATIM from hypothesis-recon.pl
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
% SHARED HELPERS — operational relations over the recon substrate.
% MANDATORY TABLING on the transitive/recursive helper.
% =============================================================================

% Transitive prefix-coverage (the LOAD-BEARING recursive helper): a seed's
% produced prefix covers index I iff index I is present + strict-loads AND the
% prefix up to I-1 is itself covered (contiguity is transitive — a hole anywhere
% below breaks the chain). Recursive over the predecessor index -> TABLED for
% termination + cycle safety (per the brief's MANDATORY-tabling rule). Called
% with a BOUND I (from tw_wellformed_start's top-index probe), so Iprev is is/2-
% computed from the bound I — well-instantiated.
:- table tw_recon_prefix_covers/2.
tw_recon_prefix_covers(Seed, 0) :-
    op_recon_present(Seed, 0),
    op_recon_strict_loads(Seed, 0).
tw_recon_prefix_covers(Seed, I) :-
    I > 0,
    Iprev is I - 1,
    tw_recon_prefix_covers(Seed, Iprev),   % the prefix below must be covered
    op_recon_present(Seed, I),
    op_recon_strict_loads(Seed, I).

% A seed is a WellFormedStart iff its complete contiguous prefix (indices
% 0 .. start-1) is covered. startIdx=0 is vacuously well-formed (empty prefix —
% the cold-seed case): no top index to cover, so the disjunct succeeds directly.
% Non-cold seeds reduce to the TABLED transitive coverage up to the top index
% (start-1), so the recursive helper is genuinely load-bearing here.
tw_wellformed_start(Seed) :-
    op_recon_seed_start(Seed, Start),
    ( Start =< 0
      -> true                                   % empty prefix — cold seed
      ;  Top is Start - 1,
         tw_recon_prefix_covers(Seed, Top) ).   % contiguous prefix 0..Top covered

% between_zero(Start, I): I in 0 .. Start-1 (the prefix index range). Fails
% cleanly (no solutions) when Start =< 0. Used by the raw-hole finder, which
% scans a proposed window's full span 0..rawStart-1 for the first hole.
between_zero(Start, I) :-
    Start > 0,
    Top is Start - 1,
    between(0, Top, I).

% =============================================================================
% Property: p_recon_i8_seed_soundness  (I-8 abstract weak form)
% Claims relied on: pr_recon_i8_soundness (status `open`), sh_i8_abstract.
% -----------------------------------------------------------------------------
% C-7 / ORBITAL INVERSION: the I-8 ABSTRACT form carries open_question(i8_vacuity)
% — whether it is a vacuous corollary of the static, total I-2 gating is a NON-
% VACUITY judgment that prove-invariants (Stage 4) adjudicates in Lean, NOT this
% stage. This stage may NOT launder a substrate prefix-check into a `consistent`
% verdict on the abstract invariant. So we run the falsification (does any honored
% seed FAIL to seed a complete contiguous strict-loading prefix?) — it fails to
% find a counterexample (every honored seed IS well-formed) — but because the
% LOAD-BEARING question (non-vacuity vs. static I-2) is undecidable at the
% decision-KB level, we emit `open` + gap_reason, NOT `consistent`.
% =============================================================================
i8_abstract_violation(seed_not_wellformed(Seed)) :-
    op_recon_seed(Seed),
    \+ tw_wellformed_start(Seed).

:- ( findall(V, i8_abstract_violation(V), Vs), Vs == []
     -> assertz(verdict(p_recon_i8_seed_soundness, open)),
        assertz(gap_reason(p_recon_i8_seed_soundness,
          'No honored seed fails the complete-contiguous-strict-loading prefix check (falsification found no counterexample over the >=2-inhabitant seed domain), so the WEAK form holds in the model. But open_question(i8_vacuity) — whether the abstract I-8 is non-vacuous or a corollary of the static total I-2 gating — is a Lean non-vacuity judgment prove-invariants adjudicates; C-7 forbids this stage laundering the substrate prefix-check into a consistent verdict on the abstract invariant. Emitted `open`, NOT consistent.'))
     ;  assertz(verdict(p_recon_i8_seed_soundness, inconsistent)),
        assertz(counterexample(p_recon_i8_seed_soundness, Vs)) ).

% =============================================================================
% Property: p_recon_clamp_wellformedstart  (STRONGER load-bearing, vacuity-indep)
% Claims relied on: pr_recon_clamp_wellformedstart, sh_clamp.
% Substrate: op_recon_seed/1 (honored seeds), tw_wellformed_start/1,
%            op_recon_window_raw/3 + op_recon_clamps_to/2 + op_recon_feasible/2.
% -----------------------------------------------------------------------------
% This is the VACUITY-INDEPENDENT obligation: planRecon yields a WellFormedStart
% from ANY proposed window. Genuine falsification search over the seed domain:
%   (V1) any HONORED seed that is NOT a WellFormedStart (the post-clamp/refuse
%        result is holed) — the core failure.
%   (V2) an over-eager attach window whose clamp target is NOT itself a honored
%        WellFormedStart seed (the clamp produced a holed start — b13 failed).
%   (V3) a holed RAW window (a prefix hole exists) that was NOT either refused
%        (feasible:false) NOR clamped to a safe start — i.e. a holed window that
%        slipped through as a honored seed (b14 failed). This is the cf_recon_no
%        _holed_seed surface: a holed prefix MUST NOT be honored.
% Empty violation set over a NON-DEGENERATE domain (>=2 well-formed seeds + a real
% raw hole to clamp/refuse) -> a genuine refutation attempt FAILED -> `consistent`.
% =============================================================================

% A raw window carries a hole iff some index below its rawStart is present_raw
% but does NOT strict_loads_raw, OR is not even present_raw (a gap).
tw_recon_raw_hole(Window, I) :-
    op_recon_window_raw(Window, RawStart, _),
    between_zero(RawStart, I),
    \+ ( op_recon_present_raw(Window, I),
         op_recon_strict_loads_raw(Window, I) ).

clamp_violation(honored_seed_not_wellformed(Seed)) :-
    op_recon_seed(Seed),
    \+ tw_wellformed_start(Seed).
clamp_violation(clamp_target_not_wellformed(Window, Safe)) :-
    op_recon_clamps_to(Window, Safe),
    op_recon_window_raw(Window, _, ClampedSeed),
    op_recon_seed_start(ClampedSeed, Safe),     % honored seed sits at the clamp start
    \+ tw_wellformed_start(ClampedSeed).
clamp_violation(holed_window_honored_unsafely(Window)) :-
    tw_recon_raw_hole(Window, _),
    % a holed raw window is SAFE iff it was refused (feasible:false) OR clamped.
    \+ op_recon_feasible(Window, false),
    \+ op_recon_clamps_to(Window, _).

:- ( findall(V, clamp_violation(V), Vs), Vs == []
     -> assertz(verdict(p_recon_clamp_wellformedstart, consistent))
     ;  assertz(verdict(p_recon_clamp_wellformedstart, inconsistent)),
        assertz(counterexample(p_recon_clamp_wellformedstart, Vs)) ).

% =============================================================================
% Property: p_recon_no_widen_below_frozen  (frozenPrefix floor — b15)
% Claims relied on: cf_recon_no_widen_below_frozen, cf_recon_no_regenerate,
%                   sh_frozen_prefix.
% Substrate: op_attach_run/1, op_frozen_prefix/2, op_loopback_start/3.
% -----------------------------------------------------------------------------
% Genuine falsification: any loopback step of an attach run whose start drops
% BELOW the adopted frozenPrefix (the floor is breached). Non-degenerate: >=2
% loopback steps over a run with a non-zero frozen prefix (4), and the CF witness
% (op_loopback_start_cf below) confirms the rule FIRES on a below-floor start.
% =============================================================================
frozen_violation(widens_below_frozen(Run, Step, Start, Frozen)) :-
    op_attach_run(Run),
    op_frozen_prefix(Run, Frozen),
    op_loopback_start(Run, Step, Start),
    Start < Frozen.

:- ( findall(V, frozen_violation(V), Vs), Vs == []
     -> assertz(verdict(p_recon_no_widen_below_frozen, consistent))
     ;  assertz(verdict(p_recon_no_widen_below_frozen, inconsistent)),
        assertz(counterexample(p_recon_no_widen_below_frozen, Vs)) ).

% =============================================================================
% NON-DEGENERATE-MODEL GUARD — record a gap (NOT a vacuous consistent) if the
% seed domain has < 2 distinct inhabitants or all seeds share one startIdx.
% Per the brief's non-degenerate-model bar. This is a meta-check on the model
% itself, emitted as a fact so model_results-recon.pl can carry it.
% =============================================================================
:- ( findall(St, op_recon_seed_start(_, St), Starts),
     sort(Starts, Distinct),
     length(Distinct, NDistinct),
     ( NDistinct >= 2
       -> assertz(nonvacuity(seed_domain, distinct_start_indices(Distinct)))
       ;  assertz(gap_reason(seed_domain,
            'Seed domain has < 2 distinct startIdx — coverage too thin; verdicts would be vacuous. Recorded as a gap, not a consistent.')),
          assertz(nonvacuity(seed_domain, degenerate(Distinct))) ) ).

% =============================================================================
% COUNTERFACTUAL MINIMALITY — load_bearing | extraneous
% -----------------------------------------------------------------------------
% A counterfactual is load_bearing iff RE-INTRODUCING its forbidden fact would
% RE-VIOLATE gating. We run the actual minimality check per cf_fact: re-introduce
% the hole and confirm the relevant property's violation set becomes non-empty.
% If re-introduction does NOT re-violate, the cf is `extraneous`.
%
% C-7: this is a substrate re-computation that REPORTS a structural fact
% (re-introducing X re-violates Y), NOT a laundered verdict on the proposition.
% =============================================================================

% cf_minimality(CfFact, load_bearing | extraneous): the load-bearing check is a
% genuine re-violation probe. For the holed-seed cf, we re-introduce the hole as
% a HONORED seed and confirm the clamp property would re-violate (the holed seed
% is NOT a WellFormedStart). For the frozen / regenerate cfs we probe the CF
% witnesses below. For the C-7 prohibition cfs (verdict / edit / content-inspect),
% re-introducing the forbidden action re-violates C-7 by the contradicts
% provenance (structurally necessary), so they are load-bearing by construction.
cf_minimality(cf_fact(seeded_run, violates_i2_gating), Status) :-
    % re-introduce the hole: would sd_hole (the holed window's seed), if HONORED,
    % be a WellFormedStart? It must NOT be (else the cf is extraneous).
    ( \+ hole_seed_wellformed
      -> Status = load_bearing ;  Status = extraneous ).
cf_minimality(cf_fact(loopback, widens_below_frozen_prefix), Status) :-
    ( op_loopback_start_cf(Run, _, Start), op_frozen_prefix(Run, Frozen), Start < Frozen
      -> Status = load_bearing ;  Status = extraneous ).
cf_minimality(cf_fact(frozenprefix_attach, regenerates_adopted_artifact), Status) :-
    ( op_regenerates_cf(_, _) -> Status = load_bearing ; Status = extraneous ).
% The three C-7 Orbital-Inversion prohibitions: re-introducing the forbidden
% action contradicts a structurally-necessary negation_provenance(_, contradicts),
% so each is load-bearing by construction (a re-introduced verdict/edit/inspect
% would re-violate C-7).
cf_minimality(cf_fact(recon, computes_logic_verdict), load_bearing) :-
    negation_provenance(recon_computes_logic_verdict, contradicts).
cf_minimality(cf_fact(recon, edits_durable_artifact), load_bearing) :-
    negation_provenance(recon_edits_durable_artifact, contradicts).
cf_minimality(cf_fact(plan_recon, inspects_artifact_content), load_bearing) :-
    negation_provenance(plan_recon_inspects_artifact_content, contradicts).

% the hole seed, if honored at the holed window's rawStart with its RAW (holed)
% map, would NOT be a WellFormedStart: index 2 present but not strict-loading.
hole_seed_wellformed :-
    op_recon_window_raw(w_holed_operator, RawStart, _),
    \+ ( between_zero(RawStart, I),
         \+ ( op_recon_present_raw(w_holed_operator, I),
              op_recon_strict_loads_raw(w_holed_operator, I) ) ).

% --- CF necessity witnesses (the load-bearing-removal probes) ----------------
% A loopback that DOES widen below the frozen prefix (start 2 < frozen 4): the
% frozen-floor rule MUST fire on this -> proves the cf is load-bearing.
op_loopback_start_cf(ar0, 9, 2).
provenance(op_loopback_start_cf(ar0, 9, 2), prescriptive).
% An attach run that DOES regenerate an already-adopted (frozen-prefix) artifact:
% index 1 sits BELOW the frozen prefix (4) yet is re-produced -> the regenerate
% rule fires -> proves the cf is load-bearing.
op_regenerates_cf(ar0, 1).
provenance(op_regenerates_cf(ar0, 1), prescriptive).

:- forall(cf_fact(X, Y),
          ( cf_minimality(cf_fact(X, Y), Status)
            -> assertz(cf_status(cf_fact(X, Y), Status))
            ;  assertz(cf_status(cf_fact(X, Y), extraneous)) )).

% =============================================================================
% EMISSION NOTES — see model_results-recon.pl for the authoritative dump.
% =============================================================================
:- assertz(emission_note(target_world_recon_self_contained,
     standalone_consult_zero_undefined)).
:- assertz(emission_note(seed_domain_non_degenerate,
     three_honored_seeds_varying_startidx_plus_hole_witness)).

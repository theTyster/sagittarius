% lean_proof_results-recon.pl
% =============================================================================
% prove-invariants (Stage 4) — RECON EXTENSION (I-8 attach-mode primer)
%   carrier in   : recon-upgrade/run-artifacts/target-world-recon.pl
%                  (3 formal_property/3 rows)
%   lean project : self-spec/lean/  (Proofs/I8ReconSoundness.lean)
%   toolchain    : leanprover/lean4:v4.29.0 + shared Mathlib (~/.lean/mathlib4)
%   produced     : 2026-06-02
%   agent        : lean-expert
%
% Schema mirrors self-spec/lean_proof_results.pl (theorem_verdict/2,
% theorem_source/2, proof_strategy/2, provenance_annotation/3, run_summary/2)
% plus upstream-encoding-failure diagnostics (encoding_failure/3,
% probe_result/3, halt_and_report/2).
%
% =============================================================================
% TOP-LINE VERDICT: HALT — UPSTREAM ENCODING FAILURE (no theorem delivered proven)
% -----------------------------------------------------------------------------
% lake build of Proofs/I8ReconSoundness.lean is GREEN with the three stubs left
% as `by sorry` (5 jobs, exit 0). The stubs TYPE-CHECK; that is NOT the same as
% the properties being PROVEN. All three I-8 recon stubs fail the lean-expert
% structural-soundness floor for one shared root cause:
%
%   The recon-primer types (Seed/Window with FREE startIdx + stageAt, the unused
%   PresenceMap, AttachRun with FREE frozenPrefix/steps/startIdxAt, and a
%   PLACEHOLDER `planRecon` returning startIdx 0) are structural SHELLS that are
%   NOT bound to the ground op_recon_* facts in target-world-recon.pl. Layer-1 of
%   the structural-translation rule (lift the load-bearing data into inductive
%   Prop predicates over the closed enums, so the ground facts are carried by
%   constructors) was applied only to the ID enums (ReconSeed, ProposedWin,
%   AttachRunId) and NOT to the data the three properties actually constrain.
%
% Consequence per property (each machine-checked by a throwaway probe module):
%   * p_recon_i8_seed_soundness     -> trivially/vacuously true (thin corollary)
%   * p_recon_clamp_wellformedstart -> vacuously true (placeholder planRecon)
%   * p_recon_no_widen_below_frozen -> FALSE as stated (refutable)
%
% Per the lean-expert hard rule, a trivial close on a structurally non-trivial
% claim is a debate foul, and a statement that is false-as-written cannot be
% repaired by the proof engineer (statement repair is lean-spec-writer /
% model-obligations territory). The remediation is to RE-ENCODE upstream, NOT to
% find tactics that get a green build. Therefore NO `proven` verdict is emitted.
%
% The source file Proofs/I8ReconSoundness.lean is left UNCHANGED (statements
% unedited, bodies still `by sorry`); editing the statements to make them true /
% non-vacuous is explicitly out of scope for this stage.
% =============================================================================

:- discontiguous
     theorem_verdict/2,
     theorem_source/2,
     formal_property_ref/2,
     proof_strategy/2,
     provenance_annotation/3,
     probe_result/3,
     encoding_failure/3,
     halt_and_report/2,
     forbidden_tactic_check/2,
     run_summary/2.

% =============================================================================
% PER-THEOREM VERDICTS
%   - unprovable : statement is FALSE as written (a counterexample type-checks).
%   - abstained  : statement is provable ONLY trivially/vacuously; emitting
%                  `proven` would launder a green build into a load-bearing
%                  claim it does not earn. Not proven; halt-and-report instead.
% =============================================================================
theorem_verdict(p_recon_i8_seed_soundness,     abstained).  % provable but vacuous; see probe_result
theorem_verdict(p_recon_clamp_wellformedstart, abstained).  % provable but vacuous (placeholder planRecon)
theorem_verdict(p_recon_no_widen_below_frozen, unprovable). % FALSE as stated; counterexample type-checks

% =============================================================================
% SOURCE LOCATIONS  (file UNCHANGED; all three remain `by sorry`)
% =============================================================================
theorem_source(p_recon_i8_seed_soundness,     "self-spec/lean/Proofs/I8ReconSoundness.lean").
theorem_source(p_recon_clamp_wellformedstart, "self-spec/lean/Proofs/I8ReconSoundness.lean").
theorem_source(p_recon_no_widen_below_frozen, "self-spec/lean/Proofs/I8ReconSoundness.lean").
theorem_source(recon_vocabulary,              "self-spec/lean/Proofs/I8ReconSoundness.lean").

formal_property_ref(p_recon_i8_seed_soundness,     "target-world-recon.pl:444").
formal_property_ref(p_recon_clamp_wellformedstart, "target-world-recon.pl:448").
formal_property_ref(p_recon_no_widen_below_frozen, "target-world-recon.pl:452").

% =============================================================================
% THE EXACT LEAN STATEMENTS ADJUDICATED (lean theorem name : statement)
% -----------------------------------------------------------------------------
% i8_seed_soundness :
%   forall (w : Window) (i : Nat), i < w.startIdx ->
%     (Present w i /\ StrictLoads w i) /\
%     seedProduced w = fun s => exists j, j < w.startIdx /\ s = w.stageAt j
% planRecon_wellformedstart :
%   forall (w : ProposedWin) (p : PresenceMap), WellFormedStart (planRecon w p)
% i8_frozen_prefix_floor :
%   forall (r : AttachRun) (k : Nat), k < r.steps -> r.frozenPrefix <= r.startIdxAt k
% =============================================================================

% =============================================================================
% PROBE RESULTS — each adjudication machine-checked by a throwaway probe module
% (Proofs/Probe.lean, built green then deleted; never committed). probe_result(
% PropId, Shape, EvidenceTactic).
% =============================================================================
probe_result(p_recon_i8_seed_soundness, trivially_provable,
  "intro w i _; exact <<<w.stageAt i, rfl>, <w.stageAt i, rfl>>, rfl>. Present and \c
   StrictLoads are BOTH defined as (exists s : Stage, w.stageAt i = s), true for \c
   ANY total stageAt (witness w.stageAt i, proof rfl); the seedProduced conjunct \c
   is rfl by definition. The antecedent i < w.startIdx is UNUSED. No reference to \c
   any ground op_recon_present / op_recon_strict_loads fact. A thin decidable \c
   corollary — exactly the smell the briefing flags.").
probe_result(p_recon_clamp_wellformedstart, vacuously_provable,
  "intro w p i hi; simp [planRecon] at hi. planRecon is a PLACEHOLDER that returns \c
   <.sd_cold, 0, fun _ => .close_world> for every input, so WellFormedStart unfolds \c
   to (forall i, i < 0 -> ...), vacuously true. The load-bearing content (the \c
   clamp/refuse implementation the formal_property names) is an UNWRITTEN def body, \c
   not a theorem the proof engineer may supply without designing planRecon.").
probe_result(p_recon_no_widen_below_frozen, refutable,
  "the NEGATION type-checks: intro h; have hbad := h <.ar0, 1, 4, fun _ => 0> 0 \c
   Nat.zero_lt_one; exact absurd hbad (by decide). AttachRun fields are FREE and \c
   UNCONSTRAINED, so <.ar0, 1, 4, fun _ => 0> is a valid inhabitant with 0 < steps \c
   (=1) yet frozenPrefix (=4) > startIdxAt 0 (=0). The floor is NOT encoded as a \c
   structural invariant of AttachRun, so the universal over ALL AttachRun is false.").

% =============================================================================
% ENCODING-FAILURE DIAGNOSTIC — the shared upstream root cause (per property)
% encoding_failure(PropId, MissingStructuralBinding, GroundFactsNotCarried).
% =============================================================================
encoding_failure(p_recon_i8_seed_soundness,
  "Window/Seed leave startIdx and stageAt as FREE structure fields; Present and \c
   StrictLoads are decoupled exists-over-total-function predicates that ignore \c
   their argument's value. Needs: an inductive HonoredSeed predicate (or Seed \c
   constructors) enumerating op_recon_seed_start/2 with stageAt and the present / \c
   strict_loads status carried by constructors, so 'i < startIdx -> present and \c
   strict-loads' is a real (non-rfl) implication and the I-2-vacuity open question \c
   becomes adjudicable rather than dissolved.",
  "op_recon_seed_start(sd_cold,0)/(sd_attach,5)/(sd_attach_clamp,4); op_recon_present/2; \c
   op_recon_strict_loads/2 (all present in target-world-recon.pl, none bound in Lean).").
encoding_failure(p_recon_clamp_wellformedstart,
  "planRecon is a constant placeholder (startIdx 0). The property 'planRecon yields \c
   WellFormedStart from ANY proposed window' is only load-bearing once planRecon is \c
   the REAL clamp(attach)+refuse(operator) function. Needs: planRecon defined as a \c
   total function over ProposedWin x PresenceMap whose attach branch clamps rawStart \c
   down to the first incomplete prefix index and whose operator branch refuses a \c
   holed prefix — then WellFormedStart is provable by construction over the closed \c
   ProposedWin enum (w_overeager_attach -> clamp to 4; w_holed_operator -> refuse).",
  "op_recon_window_raw/3 (rawStart 6 attach, rawStart 5 operator); op_recon_seed_start \c
   clamp target sd_attach_clamp=4; b13 override-and-report; b14 refuse. Not modeled.").
encoding_failure(p_recon_no_widen_below_frozen,
  "AttachRun is a free structure (steps, frozenPrefix, startIdxAt all unconstrained), \c
   so the universal quantifies over ill-formed runs that violate the floor. Needs: \c
   the loopback floor encoded as a structural invariant — e.g. an inductive \c
   LoopbackStep : AttachRunId -> Nat (step) -> Nat (start) -> Prop carrying \c
   op_loopback_start/3, with a side condition (or constructor shape) forcing start \c
   >= frozenPrefix; then the floor is true by construction over the closed \c
   AttachRunId enum rather than refutable.",
  "op_attach_run(ar0); op_frozen_prefix(ar0,4); op_loopback_start(ar0,0,5)/(ar0,1,4) \c
   (the floor HELD in the ground facts: 5>=4, 4>=4) — present in target-world-recon.pl, \c
   none bound to the Lean AttachRun fields.").

% =============================================================================
% HALT-AND-REPORT — escalate to model-obligations / lean-spec-writer
% halt_and_report(Scope, Remediation).
% =============================================================================
halt_and_report(all_three_i8_recon_properties,
  "Re-encode the recon-primer vocabulary under structural-translation Layer 1 \c
   BEFORE re-attempting proofs. The three formal_property/3 rows are correct as \c
   INTENT; the Lean shells emitted for them do not bind the ground op_recon_* facts, \c
   so they are trivial (T1), vacuous (T2), or false (T3) as written. Do NOT weaken, \c
   do NOT trivially close, do NOT edit the statements in prove-invariants. The fix \c
   is upstream: (a) replace free Seed/Window fields with an inductive HonoredSeed \c
   over op_recon_seed_start + present/strict_loads; (b) implement planRecon as the \c
   real clamp/refuse function over the closed ProposedWin enum; (c) encode the \c
   loopback floor as a structural invariant of AttachRun carrying op_loopback_start \c
   / op_frozen_prefix. Then re-emit and re-run prove-invariants.").

% =============================================================================
% FORBIDDEN-TACTIC SELF-CHECK (lean-expert 5b) — on the DELIVERED source
% -----------------------------------------------------------------------------
% grep -nE '(decide|native_decide|generalize)' Proofs/I8ReconSoundness.lean
%   -> no hits. Source UNCHANGED; all three theorems remain `by sorry`. No
%   forbidden closing move was introduced (none could be, since nothing was
%   closed). The `decide` used to demonstrate T3's FALSITY lived in a throwaway
%   probe module on a reduced `4 <= 0` arithmetic goal (not a delivered proof,
%   not a target-world closing move) and was deleted.
% =============================================================================
forbidden_tactic_check(delivered_source, none).
forbidden_tactic_check(probe_modules_deleted, "decide on `4 <= 0` arith only; not delivered").

% =============================================================================
% PROVENANCE ANNOTATIONS — carried from target-world-recon.pl negation_provenance
% (recorded so the ontology label survives the gate even though no theorem proven)
% =============================================================================
provenance_annotation(p_recon_i8_seed_soundness,     i8_machine_checked_nonvacuous,       absent).
provenance_annotation(p_recon_clamp_wellformedstart, planrecon_yields_wellformedstart,    absent).
provenance_annotation(p_recon_no_widen_below_frozen, loopback_widens_below_frozen_prefix, contradicts).

% =============================================================================
% BUILD STATUS
% -----------------------------------------------------------------------------
% `cd self-spec/lean && lake build Proofs.I8ReconSoundness` => exit 0, 5 jobs,
% three `declaration uses sorry` warnings (the unchanged stubs). Mathlib was
% already prebuilt (oleans cached; no cold rebuild triggered). Green build here
% reflects the STUBS type-checking, NOT the properties being proven.
% =============================================================================
run_summary(properties_attempted, 3).
run_summary(proven, 0).
run_summary(unprovable, 1).            % p_recon_no_widen_below_frozen (false as stated)
run_summary(abstained, 2).            % T1 trivial, T2 vacuous
run_summary(halt_reason, upstream_encoding_failure).
run_summary(source_file_edited, false).
run_summary(forbidden_tactic_in_delivered_source, false).
run_summary(lake_build_exit, 0).
run_summary(mathlib_cold_rebuild, false).

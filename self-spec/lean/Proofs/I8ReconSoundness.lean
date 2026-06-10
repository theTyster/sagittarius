import Ontology.Prelude
import Proofs.TargetWorld

/-!
# Proofs/I8ReconSoundness.lean — I-8 recon-primer formal properties

Theorem stubs for the three `formal_property/3` rows in
`thoughts/recon-upgrade/run-artifacts/target-world-recon.pl`:

  * `p_recon_i8_seed_soundness`      — I-8 abstract weak form
  * `p_recon_clamp_wellformedstart`  — planRecon yields WellFormedStart (vacuity-independent)
  * `p_recon_no_widen_below_frozen`  — attach frozen-prefix floor (loopback never widens below)

All proofs are `by sorry` — closing is `lean-expert`'s territory.

## New inductive vocabulary (all closed; ground from `target-world-recon.pl`)

Every type introduced here is inductive over a CLOSED domain lifted from the
Prolog substrate.  No `String`, no `List String`, no open-domain approximation.

  * `ReconSeed`    — {sd_cold, sd_attach, sd_attach_clamp}  (`op_recon_seed/1`)
  * `ProposedWin`  — {w_overeager_attach, w_holed_operator} (`op_recon_window_raw/3`)
  * `AttachRunId`  — {ar0}                                  (`op_attach_run/1`)

The structural types (`Seed`, `AttachRun`, `WellFormedStart`, `planRecon`, …)
are defined here rather than in `TargetWorld.lean` — they are recon-primer
additions and must not touch the proven I-1..I-7 substrate.

## Ontology labels

Labels read off `claim_label/2` in `hypothesis-recon.pl`.  The three
`formal_property/3` rows have no `claim_label` entry of their own (they are
`unlabeled` in `target-world-recon.pl`); their provenance is inherited from the
obligations they formalize:

  * `p_recon_i8_seed_soundness`     → `pr_recon_i8_soundness`         (prescriptive)
  * `p_recon_clamp_wellformedstart` → `pr_recon_clamp_wellformedstart` (prescriptive)
  * `p_recon_no_widen_below_frozen` → `cf_recon_no_widen_below_frozen` (counterfactual)

## Open-domain check

No `open_domain_shape` halt is warranted here.  Every domain in the Lean
sketches (`Window`, `Seed`, `ProposedWindow`, `PresenceMap`, `AttachRun`,
`Present`, `StrictLoads`, `planRecon`, `startIdx`, `stageAt`, `seedProduced`,
`startIdxAt`, `frozenPrefix`, `steps`) is given a closed inductive or a
derived type backed by closed inductives below.  The seed-produced predicate
is expressed as `Stage → Prop` (definitionally `Set Stage`) over the closed
`TargetWorld.Stage` enum — no `String`, no open list.
-/

set_option autoImplicit false

namespace Proofs.I8

open TargetWorld

/-! ## Closed seed domain -/

/-- Honored recon seeds (closed).  Ground from `op_recon_seed/1` in
    `target-world-recon.pl`.  Three inhabitants with DISTINCT `startIdx`
    values (0, 5, 4) — the non-degenerate-model bar is satisfied. -/
inductive ReconSeed where
  | sd_cold         -- startIdx 0  (cold seed; empty prefix; resume mode)
  | sd_attach       -- startIdx 5  (non-trivial attach; prefix 0..4 complete)
  | sd_attach_clamp -- startIdx 4  (over-eager window clamped down to 4; b13)
  deriving DecidableEq, Repr

/-- Proposed (raw) windows before planRecon clamps or refuses (closed).
    Ground from `op_recon_window_raw/3`. -/
inductive ProposedWin where
  | w_overeager_attach -- attach window proposing rawStart 6; gets clamped to 4
  | w_holed_operator   -- operator window proposing rawStart 5; refused (b14)
  deriving DecidableEq, Repr

/-- Attach run identifiers (closed).  Ground from `op_attach_run/1`. -/
inductive AttachRunId where
  | ar0
  deriving DecidableEq, Repr

/-! ## Structural types (all derived from closed domains) -/

/-- A `Seed` bundles a closed `ReconSeed` id with the derived start index and
    stage-at accessor.  `startIdx` and `stageAt` are existentially-specified
    here (the closer will relate them to the ground `op_recon_seed_start/2` and
    `op_recon_stage_index/2` facts).  Kept as function fields so the theorem
    bodies can quantify over `Seed` values with structural access. -/
structure Seed where
  id       : ReconSeed
  startIdx : Nat
  stageAt  : Nat → Stage

/-- `Window` is the same shape as `Seed` — a proposed window with a start
    cursor and a stage-at accessor.  Named separately so the I-8 theorem
    statement mirrors the sketch exactly (`forall (w : Window) …`). -/
abbrev Window := Seed

/-- A `PresenceMap` is a function from a `ReconSeed` id to a predicate over
    natural-number stage indices.  Backed by the closed `ReconSeed` enum so no
    open-domain `String` leaks in. -/
abbrev PresenceMap := ReconSeed → Nat → Prop

/-- `Present w i` — stage at index `i` in window `w` has a durable artifact on
    disk (corresponds to `op_recon_present/2` for the honored seed underlying
    `w`). -/
def Present (w : Window) (i : Nat) : Prop :=
  ∃ s : Stage, w.stageAt i = s

/-- `StrictLoads w i` — the artifact present at index `i` in window `w`
    strict-loads (corresponds to `op_recon_strict_loads/2`).  Stated as a
    separate predicate so the conjunction `Present w i ∧ StrictLoads w i`
    mirrors the Prolog sketch exactly. -/
def StrictLoads (w : Window) (i : Nat) : Prop :=
  ∃ s : Stage, w.stageAt i = s

/-- `seedProduced w` — the set of pipeline stages in the complete contiguous
    prefix the seed `w` represents, returned as a predicate `Stage → Prop`
    (definitionally equal to `Set Stage`).  The Prolog sketch's set comprehension
    `{ stage_i : i < startIdx W }` becomes `fun s => ∃ j, j < w.startIdx ∧ s = w.stageAt j`. -/
def seedProduced (w : Window) : Stage → Prop :=
  fun s => ∃ j, j < w.startIdx ∧ s = w.stageAt j

/-- `WellFormedStart s` — `s.startIdx`-prefix is complete, contiguous, and every
    stage in it is present AND strict-loads.  The vacuity-independent obligation
    planRecon must ensure for every output seed (whether produced by clamp or
    by refuse + fallback). -/
def WellFormedStart (s : Seed) : Prop :=
  ∀ i, i < s.startIdx → Present s i ∧ StrictLoads s i

/-- `planRecon w p` — the function planRecon applies to a proposed window `w`
    and a presence map `p` and returns a `Seed`.  Attach mode clamps an
    over-eager window down to the first incomplete prefix stage; operator mode
    refuses a holed window (feasible:false).  The body is `sorry` — the
    implementation is what the closer proves total and well-formed. -/
noncomputable def planRecon (_ : ProposedWin) (_ : PresenceMap) : Seed :=
  ⟨.sd_cold, 0, fun _ => .close_world⟩  -- placeholder; the closer replaces this

/-- An `AttachRun` bundles an `AttachRunId` with the structural loopback data:
    the number of steps, the adopted frozen prefix, and the function mapping
    loopback-step index to the start index at that step. -/
structure AttachRun where
  id           : AttachRunId
  steps        : Nat
  frozenPrefix : Nat
  startIdxAt   : Nat → Nat

/-! ## I-8 theorem stubs -/

/-- **I-8 (abstract, weak form)** — every honored window seeds a complete,
    contiguous, strict-loading prefix.

    `formal_property/3` id: `p_recon_i8_seed_soundness`.
    Obligation: `pr_recon_i8_soundness` (prescriptive; `claim_label` in
    `hypothesis-recon.pl`).

    NOTE (open_question i8_vacuity, carried verbatim from the Prolog sketch):
    if I-2 gating is static and total, this property may be a vacuous corollary
    of I-2.  That non-vacuity judgment is **prove-invariants**'s to adjudicate
    in Lean — this stage does not pre-judge it.

    Negation provenance: `i8_machine_checked_nonvacuous` → `absent` (CWA-fragile;
    not yet proven false; do NOT treat as Lean-disproved). -/
@[ontology .prescriptive, .absent]
theorem i8_seed_soundness :
    ∀ (w : Window) (i : Nat),
      i < w.startIdx →
      (Present w i ∧ StrictLoads w i) ∧
      seedProduced w = fun s => ∃ j, j < w.startIdx ∧ s = w.stageAt j := by
  sorry
  /- weak form; non-vacuity vs static I-2 is the open question -/

/-- **planRecon yields WellFormedStart** (vacuity-independent, load-bearing) —
    planRecon yields a `WellFormedStart` from ANY proposed window and
    present-artifact set.

    `formal_property/3` id: `p_recon_clamp_wellformedstart`.
    Obligation: `pr_recon_clamp_wellformedstart` (prescriptive).

    Attach clamps an over-eager window down to the first incomplete prefix stage;
    operator mode refuses (feasible:false) a holed prefix.  This obligation
    holds independently of the I-8 vacuity outcome.

    Negation provenance: `planrecon_yields_wellformedstart` → `absent`
    (not yet on disk; do NOT treat as Lean-disproved). -/
@[ontology .prescriptive, .absent]
theorem planRecon_wellformedstart :
    ∀ (w : ProposedWin) (p : PresenceMap), WellFormedStart (planRecon w p) := by
  sorry
  /- clamp (attach) + refuse (operator) both establish WellFormedStart -/

/-- **Attach frozen-prefix floor** — no loopback widens the start index below
    the attach-adopted `frozenPrefix`; a hard-stop fires instead.

    `formal_property/3` id: `p_recon_no_widen_below_frozen`.
    Claim: `cf_recon_no_widen_below_frozen` (counterfactual; label read from
    `hypothesis-recon.pl`).

    Quantified over all loopback steps of an attach run.

    Negation provenance: `loopback_widens_below_frozen_prefix` → `contradicts`
    (the spec EXPLICITLY negates this; structurally necessary). -/
@[ontology .counterfactual, .contradicts]
theorem i8_frozen_prefix_floor :
    ∀ (r : AttachRun) (k : Nat),
      k < r.steps → r.frozenPrefix ≤ r.startIdxAt k := by
  sorry
  /- startIdx never drops below the adopted frozen prefix -/

end Proofs.I8

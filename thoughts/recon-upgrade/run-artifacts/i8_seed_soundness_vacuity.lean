import Ontology.Prelude
import Proofs.TargetWorld
import Proofs.I8ReconSoundness

/-!
# i8_seed_soundness_vacuity.lean — ADVERSARIAL refutation artifact (Lean)

target_id      : i8_seed_soundness_vacuity
refutes        : the META-claim "i8_seed_soundness is NON-VACUOUS and load-bearing"
                 (premise `i8_machine_checked_nonvacuous` of `pr_recon_i8_soundness`,
                  hypothesis-recon.pl:159; refutation_target i8_vacuity,
                  target-world-recon.pl:265 / hypothesis-recon.pl:265).
original thm   : Proofs.I8.i8_seed_soundness
                 (self-spec/lean/Proofs/I8ReconSoundness.lean:163).

## Build provenance (the witnesses ARE buildable)

Every term below was verified GREEN under the project lakefile by placing it in
`self-spec/lean/Proofs/` (the Lean source root the project's `lake build` sees):

    cd self-spec/lean && lake build Proofs.I8VacuityProbe Proofs.I8ClampStatable
    => Build completed successfully (7 jobs), exit 0.
    grep -nE '(sorry|axiom|native_decide)' on both probes => no hits.

This file is the recorded artifact in the run-artifacts dir (a Prolog-artifact
dir, NOT a Lean source root). It will not build IN PLACE here because the
project lakefile does not reach `recon-upgrade/run-artifacts/` as a source root.
Per the adversary contract, source-root routing is the disprove-proposition
skill's responsibility, not this agent's: to re-verify, copy the two namespaced
sections into `self-spec/lean/Proofs/I8VacuityProbe.lean` and
`self-spec/lean/Proofs/I8ClampStatable.lean` and `lake build` them.

## What is refuted, and HOW the witness inhabits the negation

The negation of "i8_seed_soundness is non-vacuous" is "i8_seed_soundness is
inhabited by a proof that uses neither its antecedent nor any ground fact nor
I-2". `i8_is_trivial_tautology` below IS that inhabitant: it proves the ORIGINAL
statement verbatim, discarding `i < w.startIdx` (`intro w i _`), closing
`Present`/`StrictLoads` by `⟨w.stageAt i, rfl⟩` (true for ANY total `stageAt`),
and `seedProduced` by `rfl`. `Requires` / `StageOrder` (the I-2 vocabulary)
never appear — so it is STRICTLY WEAKER than "a corollary of static I-2 gating":
it is a standalone tautology with no dependence on I-2 at all.

`present_eq_strictloads` is the structural root cause: `Present` and
`StrictLoads` are DEFINITIONALLY the same proposition (`∃ s, w.stageAt i = s`),
so the conjunction carries no information and the "hole" (present-but-not-
strict-loading) the Prolog model exhibits is UNREPRESENTABLE in this encoding.
The Prolog model's ≥2-seed non-degeneracy (sd_cold=0, sd_attach=5,
sd_attach_clamp=4 + sd_hole CF) is REAL in Prolog but does NOT transfer: the
Lean theorem ranges over `Window`/`Seed` with FREE fields, not the ground seeds.
-/

set_option autoImplicit false

namespace Proofs.I8VacuityProbe

open Proofs.I8 TargetWorld

/-- T1: the ORIGINAL i8_seed_soundness statement, proven trivially. Antecedent
    discarded; `Present`/`StrictLoads` by `⟨w.stageAt i, rfl⟩`; `seedProduced`
    by `rfl`. No `op_recon_*` fact, no I-2 lemma. -/
theorem i8_is_trivial_tautology :
    ∀ (w : Window) (i : Nat),
      i < w.startIdx →
      (Present w i ∧ StrictLoads w i) ∧
      seedProduced w = fun s => ∃ j, j < w.startIdx ∧ s = w.stageAt j := by
  intro w i _
  exact ⟨⟨⟨w.stageAt i, rfl⟩, ⟨w.stageAt i, rfl⟩⟩, rfl⟩

/-- DEGENERATE one-seed witness: startIdx 0, constant stageAt. Satisfies the FULL
    statement because `i < 0` is impossible — the body is never reached. A no-op
    constant inhabits the property (the I-3 vacuity smell, FINDINGS F-3). -/
def degenerateWindow : Window := ⟨.sd_cold, 0, fun _ => .close_world⟩

theorem degenerate_satisfies :
    ∀ (i : Nat),
      i < degenerateWindow.startIdx →
      (Present degenerateWindow i ∧ StrictLoads degenerateWindow i) ∧
      seedProduced degenerateWindow
        = fun s => ∃ j, j < degenerateWindow.startIdx ∧ s = degenerateWindow.stageAt j := by
  intro i hi
  exact absurd hi (Nat.not_lt_zero i)

/-- The placeholder `planRecon` (startIdx 0 for EVERY input) satisfies
    WellFormedStart vacuously — the second prescriptive property is vacuous
    independently of any clamp/refuse implementation. -/
theorem planRecon_vacuous (w : ProposedWin) (p : PresenceMap) :
    WellFormedStart (planRecon w p) := by
  intro i hi
  exact absurd hi (Nat.not_lt_zero i)

/-- STRUCTURAL ROOT CAUSE: `Present` and `StrictLoads` are DEFINITIONALLY EQUAL
    (both `∃ s, w.stageAt i = s`). The hole (present-but-not-strict-loading) is
    unrepresentable; the conjunct is information-free. -/
theorem present_eq_strictloads (w : Window) (i : Nat) :
    Present w i = StrictLoads w i := rfl

end Proofs.I8VacuityProbe

/-! ## CONTRAST: the load-bearing statement IS Lean-statable (no JS required)

Binding the ground `op_recon_*` facts as inductive predicates over the closed
honored-seed domain makes `i < start` LOAD-BEARING, `Present`/`StrictLoads`
DISTINCT, and the hole REPRESENTABLE. The clamp's runtime output lives in JS, but
its soundness CONTRACT (output is WellFormed; a holed seed is refused) is a pure
structural Lean property. This refutes "I-8 teeth can only live in a behavioral
test". (Verified in `Proofs/I8ClampStatable.lean`, 5 jobs, exit 0.)
-/

namespace Proofs.I8ClampStatable

open TargetWorld

/-- Closed honored-seed domain (ground from `op_recon_seed/1`). -/
inductive HSeed where
  | sd_cold | sd_attach | sd_attach_clamp
  deriving DecidableEq, Repr

/-- `StartOf s n` — ground from `op_recon_seed_start/2`. Three DISTINCT starts. -/
inductive StartOf : HSeed → Nat → Prop where
  | cold   : StartOf .sd_cold 0
  | attach : StartOf .sd_attach 5
  | clamp  : StartOf .sd_attach_clamp 4

/-- `PresentAt s i` — ground from `op_recon_present/2`. One ctor per fact. -/
inductive PresentAt : HSeed → Nat → Prop where
  | a0 : PresentAt .sd_attach 0
  | a1 : PresentAt .sd_attach 1
  | a2 : PresentAt .sd_attach 2
  | a3 : PresentAt .sd_attach 3
  | a4 : PresentAt .sd_attach 4
  | c0 : PresentAt .sd_attach_clamp 0
  | c1 : PresentAt .sd_attach_clamp 1
  | c2 : PresentAt .sd_attach_clamp 2
  | c3 : PresentAt .sd_attach_clamp 3

/-- `StrictLoadsAt s i` — ground from `op_recon_strict_loads/2`. DISTINCT from
    `PresentAt` (the encoding the vacuous version collapsed). -/
inductive StrictLoadsAt : HSeed → Nat → Prop where
  | a0 : StrictLoadsAt .sd_attach 0
  | a1 : StrictLoadsAt .sd_attach 1
  | a2 : StrictLoadsAt .sd_attach 2
  | a3 : StrictLoadsAt .sd_attach 3
  | a4 : StrictLoadsAt .sd_attach 4
  | c0 : StrictLoadsAt .sd_attach_clamp 0
  | c1 : StrictLoadsAt .sd_attach_clamp 1
  | c2 : StrictLoadsAt .sd_attach_clamp 2
  | c3 : StrictLoadsAt .sd_attach_clamp 3

/-- The load-bearing WellFormedStart: every index below the start is BOTH present
    AND strict-loading. `i < start` is USED; a missing ctor breaks the proof. -/
def WellFormed (s : HSeed) (start : Nat) : Prop :=
  ∀ i, i < start → PresentAt s i ∧ StrictLoadsAt s i

/-- NON-VACUOUS: sd_attach (start 5) is well-formed — enumerate 0..4, each citing
    a ground fact. The antecedent is load-bearing. -/
theorem attach_wellformed : WellFormed .sd_attach 5 := by
  intro i hi
  match i, hi with
  | 0, _ => exact ⟨.a0, .a0⟩
  | 1, _ => exact ⟨.a1, .a1⟩
  | 2, _ => exact ⟨.a2, .a2⟩
  | 3, _ => exact ⟨.a3, .a3⟩
  | 4, _ => exact ⟨.a4, .a4⟩

/-- THE HOLE IS REPRESENTABLE: a holed strict-load relation missing index 2. -/
inductive HoleStrictLoads : Nat → Prop where
  | h0 : HoleStrictLoads 0
  | h1 : HoleStrictLoads 1
  -- NB: no ctor for index 2 — the HOLE.
  | h3 : HoleStrictLoads 3
  | h4 : HoleStrictLoads 4

theorem hole_not_strictloading_at_2 : ¬ HoleStrictLoads 2 := by
  intro h; cases h

/-- The `cf_recon_no_holed_seed` tooth, Lean-statable AND Lean-refutable: a holed
    seed honored at start 5 is NOT well-formed (fails at index 2). -/
theorem holed_seed_not_wellformed :
    ¬ (∀ i, i < 5 → HoleStrictLoads i) := by
  intro h
  exact hole_not_strictloading_at_2 (h 2 (by omega))

end Proofs.I8ClampStatable

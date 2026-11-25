import Std

/-!
# Reviewing an empirical inference

Companion to “A conjecture about the scientific method”, v0.2.
Run with `lean ScientificMethod.lean`. Read `conflict_rejects_joint` first.

A world is one possible way the system and its instruments could be.
Predictions describe the underlying outcome. Observations restrict which
outcomes could have produced the reading, under measurement premises.
Neither kind of premise is asserted as a fact by this file.
-/

namespace ScientificMethod

structure Model (World Outcome : Type) where
  conjecture : World → Prop
  premises : World → Prop
  outcome : World → Outcome
  predicted : Outcome → Prop
  derive : ∀ w, conjecture w → premises w → predicted (outcome w)

structure Observation (World Outcome : Type) (outcome : World → Outcome) where
  procedure : String
  knownWhenConjectureChosen : String
  knownWhenRuleChosen : String
  measurementPremises : World → Prop
  recorded : World → Prop
  compatible : Outcome → Prop
  interpret : ∀ w, recorded w → measurementPremises w → compatible (outcome w)
  possible : ∃ x, compatible x

inductive Verdict where
  | meets | conflicts | unresolved
  deriving DecidableEq, Repr

/-- Each conclusion has its own proof obligation. Uncertainty has witnesses. -/
def Warrants {α : Type} (predicted compatible : α → Prop) : Verdict → Prop
  | .meets => ∀ x, compatible x → predicted x
  | .conflicts => ∀ x, compatible x → ¬ predicted x
  | .unresolved => (∃ x, compatible x ∧ predicted x) ∧
                   (∃ x, compatible x ∧ ¬ predicted x)

/-- The cases exhaust every nonempty measurement and are mutually exclusive.
Classical existence here gives no general algorithm for arbitrary predicates. -/
theorem unique_verdict {α : Type} (p c : α → Prop) (possible : ∃ x, c x) :
    ∃ v, Warrants p c v ∧ ∀ other, Warrants p c other → other = v := by
  classical
  obtain ⟨x, hx⟩ := possible
  by_cases inside : ∃ i, c i ∧ p i
  · obtain ⟨i, ci, pi⟩ := inside
    by_cases outside : ∃ j, c j ∧ ¬ p j
    · obtain ⟨j, cj, npj⟩ := outside
      refine ⟨.unresolved, ⟨⟨i, ci, pi⟩, ⟨j, cj, npj⟩⟩, ?_⟩
      intro other h
      cases other with
      | meets => exact (npj (h j cj)).elim
      | conflicts => exact (h i ci pi).elim
      | unresolved => rfl
    · have allIn : ∀ j, c j → p j := by
        intro j cj
        apply Classical.byContradiction
        intro bad
        exact outside ⟨j, cj, bad⟩
      refine ⟨.meets, allIn, ?_⟩
      intro other h
      cases other with
      | meets => rfl
      | conflicts => exact (h i ci pi).elim
      | unresolved => exact (outside h.2).elim
  · have allOut : ∀ i, c i → ¬ p i := fun i ci pi => inside ⟨i, ci, pi⟩
    refine ⟨.conflicts, allOut, ?_⟩
    intro other h
    cases other with
    | meets => exact (allOut x hx (h x hx)).elim
    | conflicts => rfl
    | unresolved => exact (inside h.1).elim

variable {World Outcome : Type} (m : Model World Outcome)
variable (o : Observation World Outcome m.outcome)

/-- A reviewer can recover which premises would have to fail to save the
conjecture. Keeping both sets of premises yields a counterexample at w. -/
theorem conflict_rejects_joint (w : World) (reading : o.recorded w)
    (conflict : Warrants m.predicted o.compatible .conflicts) :
    ¬ (m.conjecture w ∧ m.premises w ∧ o.measurementPremises w) := by
  intro ⟨claim, premises, instrument⟩
  exact conflict _ (o.interpret w reading instrument) (m.derive w claim premises)

theorem agreement_establishes_run (w : World) (reading : o.recorded w)
    (instrument : o.measurementPremises w)
    (agreement : Warrants m.predicted o.compatible .meets) :
    m.predicted (m.outcome w) :=
  agreement _ (o.interpret w reading instrument)

/-- A countermodel to inferring the conjecture from a matching prediction. -/
example : ∃ (claim prediction : Prop), (claim → prediction) ∧ prediction ∧ ¬ claim :=
  ⟨False, True, fun _ => True.intro, True.intro, fun h => h⟩

namespace Timer

/-- Fixed-point illustration, in tenths of a second. -/
abbrev timely (elapsed : Int) := 590 ≤ elapsed ∧ elapsed ≤ 610
abbrev withinError (reading elapsed : Int) :=
  reading - 2 ≤ elapsed ∧ elapsed ≤ reading + 2

theorem reading_600 : Warrants timely (withinError 600) .meets := by
  intro t ht
  unfold withinError at ht
  unfold timely
  omega

theorem reading_611 : Warrants timely (withinError 611) .unresolved := by
  exact ⟨⟨610, by decide, by decide⟩, ⟨612, by decide, by decide⟩⟩

theorem reading_615 : Warrants timely (withinError 615) .conflicts := by
  intro t ht ok
  unfold withinError at ht
  unfold timely at ok
  omega

/-- A timer history contains many runs. The conjecture quantifies over
uninterrupted runs, while a clock reading concerns one selected run. -/
structure History where
  elapsed : Nat → Int
  uninterrupted : Nat → Prop
  clock : Nat → Int

def model (run : Nat) : Model History Int where
  conjecture h := ∀ i, h.uninterrupted i → timely (h.elapsed i)
  premises h := h.uninterrupted run
  outcome h := h.elapsed run
  predicted := timely
  derive _ claim uninterrupted := claim run uninterrupted

def observation (run : Nat) (reading : Int) :
    Observation History Int (model run).outcome where
  procedure := "Independent clock timed the start and ring of the selected run."
  knownWhenConjectureChosen := "Illustration assumes the reading was unseen."
  knownWhenRuleChosen := "Clock error bound and tolerance fixed before reading."
  measurementPremises h := withinError (h.clock run) (h.elapsed run)
  recorded h := h.clock run = reading
  compatible := withinError reading
  interpret _ same bound := same ▸ bound
  possible := ⟨reading, by unfold withinError; omega⟩

theorem late_run_refutes_universal (history : History) (run : Nat)
    (reading : history.clock run = 615) (ran : history.uninterrupted run)
    (accurate : withinError (history.clock run) (history.elapsed run)) :
    ¬ (model run).conjecture history := by
  intro claim
  exact conflict_rejects_joint (model run) (observation run 615) history
    reading reading_615 ⟨claim, ran, accurate⟩

end Timer

namespace Statistical

/-- A separate rule for comparing the likelihood of the SAME selected event
under two finite models with equiprobable elementary outcomes. -/
structure EventCount where
  hits : Nat
  total : Nat
  nonempty : 0 < total
  bounded : hits ≤ total

abbrev Favors (left right : EventCount) : Prop :=
  left.hits * right.total > right.hits * left.total

theorem equal_likelihood_no_preference (a b : EventCount)
    (equal : a.hits * b.total = b.hits * a.total) : ¬ Favors a b := by
  unfold Favors
  omega

/-- Illustrative likelihoods for a specified trace under two rival models.
The less favored model still admits the observed trace. -/
def flood : EventCount := ⟨8, 10, by decide, by decide⟩
def seasonal : EventCount := ⟨2, 10, by decide, by decide⟩
example : Favors flood seasonal ∧ 0 < seasonal.hits := by decide

end Statistical

/-- A log may start with a conjecture or an observation. Revising either
appends a new entry. Recording a deterministic judgment requires both
the prediction derivation in the model and a proof of the comparison. -/
inductive Entry (World Outcome : Type) where
  | propose (model : Model World Outcome)
  | observe (outcome : World → Outcome) (observation : Observation World Outcome outcome)
  | assess (model : Model World Outcome)
      (observation : Observation World Outcome model.outcome) (verdict : Verdict)
      (warrant : Warrants model.predicted observation.compatible verdict)

def record {W O : Type} (history : List (Entry W O)) (entry : Entry W O) :=
  entry :: history

theorem revision_preserves_record {W O : Type} (history : List (Entry W O))
    (revision : Entry W O) : (record history revision).tail = history := rfl

end ScientificMethod

import BurnModel.Requirements
import BurnModel.Impl

/-!
# orbit-kb D10: the implementation model meets the requirements (RENDEZVOUS)

`view` maps a state of the implementation model (`Impl.DB`, with
`proof_changed` and `waiver_lapsed` as inputs) to the KB of the requirements
model (`Req.KB`). `implSys` is the implementation model as a `Req.Sys`.

The map:
* a claim of `Req` is a `claim(C, _, _)` fact. Its `current` is `current(C)`.
  Its `contestedTwice` is `contested_twice(C)`. Its `universal` is
  `universal(C)`. Its `requested` is `burn_requested(C)`. The requirements take
  these four as inputs, so the map uses the core rules for them.
* a proof of `Req` is an `attest(A, lean_proof, _, proof(C, _), By, _)`. Its
  `changed` is `proof_changed(A)`.
* a waiver of `Req` is an `attest(W, waiver, _, waive(C, _, _), By, _)`. Its
  `lapsed` is `waiver_lapsed(W)`.
* a progress record is an `attest(_, lean_result, _, verdict(C, V), By, _)`
  with V in `stated`, `refuted`, `tested(N)`.
* a check is a `conformance(K)` fact.
* `restOk` is `not any_under, not any_over, not any_to_ask`.

* `supersedes` of `Req` is the list of `supersedes(New, Old)` facts.

Result (D10 follow-up, requirements v3):
* `implSys` meets LR1, LR3, LR5 to LR7, and LR9 to LR12 for every state.
* LR2 and LR4 need `Req.burns` to follow from `burn`. That needs each claim that
  a `supersedes` fact replaces to be a claim (`LR2_of`, `LR4_of`).
* `implSys` does not meet LR8 (`impl_not_LR8`): `universal(c109)` with no claim
  `c109` makes `burn(c109)` true (finding F7). On the states with no dangling
  reference (`WF`, what lint E4 checks), LR8 holds. `implSysWF` meets all twelve
  (`implWF_all`).
-/

namespace Rdz
open Impl

def toW : Impl.Writer → Req.Writer
  | .human => .human
  | .agent => .agent
  | .script => .script

def ofW : Req.Writer → Impl.Writer
  | .human => .human
  | .agent => .agent
  | .script => .script

def toV : Req.Progress → Impl.Verdict
  | .stated => .stated
  | .refuted => .refuted
  | .tested n => .tested n

def ofV : Impl.Verdict → Option Req.Progress
  | .stated => some .stated
  | .refuted => some .refuted
  | .tested n => some (.tested n)
  | _ => none

theorem toW_ofW (w : Req.Writer) : toW (ofW w) = w := by cases w <;> rfl
theorem ofV_toV (k : Req.Progress) : ofV (toV k) = some k := by cases k <;> rfl

theorem toW_eq_script (w : Impl.Writer) : toW w = .script ↔ w = .script := by
  cases w <;> simp [toW]
theorem toW_eq_human (w : Impl.Writer) : toW w = .human ↔ w = .human := by
  cases w <;> simp [toW]

/-- `x` occurs in the list (a fact of a one-argument predicate). -/
def inList (l : List Atom) (x : Atom) : Bool := l.any fun u => u == x

def claimView (db : DB) (c : Atom) : Req.Claim :=
  ⟨c, current db c, contested_twice db c, inList db.universal c, inList db.burn_requested c⟩

def proofView (db : DB) (a : Attest) : Option Req.Proof :=
  if a.type = .lean_proof then
    match a.pred with
    | .proof c _ => some ⟨c, toW a.by_, inList db.proof_changed a.id⟩
    | _ => none
  else none

def waiverView (db : DB) (a : Attest) : Option Req.Waiver :=
  if a.type = .waiver then
    match a.pred with
    | .waive c _ => some ⟨c, toW a.by_, inList db.waiver_lapsed a.id⟩
    | _ => none
  else none

def progressView (a : Attest) : Option Req.ProgressRec :=
  if a.type = .lean_result then
    match a.pred with
    | .verdict c v => (ofV v).map fun k => ⟨c, k, toW a.by_⟩
    | _ => none
  else none

/-- The code/model map: a state of the implementation model, seen as a KB of the
requirements model. -/
def view (db : DB) : Req.KB where
  claims := db.claim.map fun x => claimView db x.1
  supersedes := db.supersedes
  proofs := db.attest.filterMap (proofView db)
  waivers := db.attest.filterMap (waiverView db)
  progress := db.attest.filterMap progressView
  checks := db.conformance
  restOk := !any_under db && !any_over db && !any_to_ask db

/-- A new attestation id, as `orbit-kb attest` chooses one. -/
def freshId (db : DB) : Atom := db.attest.foldr (fun a m => max a.id m) 0 + 1

/-- The `lean_result` attestation that records a progress record. -/
def progAttest (db : DB) (r : Req.ProgressRec) : Attest :=
  ⟨freshId db, .lean_result, r.claim, .verdict r.claim (toV r.kind), ofW r.writer, 0⟩

def addProgress (db : DB) (r : Req.ProgressRec) : DB :=
  { db with attest := progAttest db r :: db.attest }

def addCheck (db : DB) (k : Nat) : DB :=
  { db with conformance := k :: db.conformance }

/-- The implementation model, as a system under test. -/
abbrev implSys : Req.Sys where
  St := DB
  view := view
  done := done
  burn := burn
  burnOpen := burn_open
  addProgress := addProgress
  addCheck := addCheck

/-! ## Bridge lemmas -/

theorem own_claimView (db : DB) (c : Atom) : Req.ownReason (claimView db c) = burn_reason db c :=
  rfl

theorem rreach_eq (E : List (Nat × Nat)) (a b : Nat) : Req.rreach E a b = Impl.rreach E a b := by
  induction E generalizing a b with
  | nil => rfl
  | cons e E ih => simp only [Req.rreach, Impl.rreach, ih]

theorem reach_eq (E : List (Nat × Nat)) (a b : Nat) : Req.reach E a b = Impl.reach E a b := by
  simp only [Req.reach, Impl.reach, rreach_eq]

/-- `Req.burns` of a claim of the view, in the terms of the implementation. -/
theorem burns_view (db : DB) (c : Atom) :
    Req.burns (view db) (claimView db c) =
      (burn_reason db c || db.claim.any fun x => reach db.supersedes c x.1 && burn_reason db x.1) := by
  simp only [Req.burns, view, List.any_map, Function.comp_def, own_claimView, reach_eq]
  rfl

/-- A claim that burns in the requirements model burns in the implementation, on
every state. -/
theorem burn_of_burns (db : DB) (c : Atom) (h : Req.burns (view db) (claimView db c) = true) :
    burn db c = true := by
  rw [burns_view] at h
  rw [burn_iff]
  simp only [Bool.or_eq_true, List.any_eq_true, Bool.and_eq_true] at h
  rcases h with h | ⟨x, _, h1, h2⟩
  · exact Or.inl h
  · exact Or.inr ⟨x.1, h1, h2⟩

/-- On a state where each claim that a `supersedes` fact replaces is a claim
(lint E4), the converse holds. -/
theorem burns_of_burn (db : DB) (hsup : ∀ e ∈ db.supersedes, ∃ x ∈ db.claim, x.1 = e.2)
    (c : Atom) (h : burn db c = true) : Req.burns (view db) (claimView db c) = true := by
  rw [burns_view]
  rw [burn_iff] at h
  simp only [Bool.or_eq_true, List.any_eq_true, Bool.and_eq_true]
  rcases h with h | ⟨o, h1, h2⟩
  · exact Or.inl h
  · obtain ⟨e, he, rfl⟩ := reach_target h1
    obtain ⟨x, hx, hxe⟩ := hsup e he
    exact Or.inr ⟨x, hx, hxe ▸ h1, hxe ▸ h2⟩

theorem cycle_view (db : DB) : Req.cycle (view db) = any_supersede_cycle db := by
  simp only [Req.cycle, view, any_supersede_cycle, supersede_cycle, reach_eq]

theorem mem_claims {db : DB} {cl : Req.Claim} :
    cl ∈ (view db).claims ↔ ∃ x ∈ db.claim, claimView db x.1 = cl := by
  simp [view]

theorem proofView_counts (db : DB) (a : Attest) (c : Atom) :
    (∃ p, proofView db a = some p ∧ p.claim = c ∧ Req.ProofCounts p) ↔
      (a.type == .lean_proof && a.pred.proofOf c && a.by_ == .script &&
        !(db.proof_changed.any fun x => x == a.id)) = true := by
  unfold proofView Req.ProofCounts
  by_cases ht : a.type = .lean_proof
  · simp only [ht, ite_true]
    cases hp : a.pred <;>
      simp [Pred.proofOf, toW_eq_script, inList, and_assoc]
  · simp [ht]

theorem waiverView_counts (db : DB) (a : Attest) (c : Atom) :
    (∃ w, waiverView db a = some w ∧ w.claim = c ∧ Req.WaiverCounts w) ↔
      (a.type == .waiver && a.pred.waiveOf c && a.by_ == .human &&
        !(db.waiver_lapsed.any fun x => x == a.id)) = true := by
  unfold waiverView Req.WaiverCounts
  by_cases ht : a.type = .waiver
  · simp only [ht, ite_true]
    cases hp : a.pred <;>
      simp [Pred.waiveOf, toW_eq_human, inList, and_assoc]
  · simp [ht]

theorem proved_iff (db : DB) (c : Atom) :
    (∃ p ∈ (view db).proofs, p.claim = c ∧ Req.ProofCounts p) ↔ burn_proved db c = true := by
  simp only [view, List.mem_filterMap, burn_proved, List.any_eq_true]
  constructor
  · rintro ⟨p, ⟨a, ha, hp⟩, hc, hk⟩
    exact ⟨a, ha, (proofView_counts db a c).1 ⟨p, hp, hc, hk⟩⟩
  · rintro ⟨a, ha, h⟩
    obtain ⟨p, hp, hc, hk⟩ := (proofView_counts db a c).2 h
    exact ⟨p, ⟨a, ha, hp⟩, hc, hk⟩

theorem waived_iff (db : DB) (c : Atom) :
    (∃ w ∈ (view db).waivers, w.claim = c ∧ Req.WaiverCounts w) ↔ burn_waived db c = true := by
  simp only [view, List.mem_filterMap, burn_waived, List.any_eq_true]
  constructor
  · rintro ⟨w, ⟨a, ha, hw⟩, hc, hk⟩
    exact ⟨a, ha, (waiverView_counts db a c).1 ⟨w, hw, hc, hk⟩⟩
  · rintro ⟨a, ha, h⟩
    obtain ⟨w, hw, hc, hk⟩ := (waiverView_counts db a c).2 h
    exact ⟨w, ⟨a, ha, hw⟩, hc, hk⟩

theorem closed_iff (db : DB) (c : Atom) :
    Req.Closed (view db) c ↔ (burn_proved db c = true ∨ burn_waived db c = true) := by
  unfold Req.Closed
  rw [proved_iff, waived_iff]

theorem burn_open_eq (db : DB) (c : Atom) :
    burn_open db c = true ↔
      burn db c = true ∧ current db c = true ∧ burn_proved db c = false ∧
        burn_waived db c = false := by
  simp [burn_open, and_assoc]

/-! ## One theorem per requirement

On every state: LR1, LR3, LR5, LR6, LR7, LR9, LR10, LR11, LR12. LR2 and LR4 need
`Req.burns` to follow from `burn`, so they need the states where every claim
that a `supersedes` fact replaces is a claim (lint E4, `WF` below). LR8 fails on
some states (`impl_not_LR8`) and holds on `WF`. -/

/-- LR1: `done` implies that every current claim that burns is closed. -/
theorem impl_LR1 : Req.LR1 implSys := by
  intro db hd cl hm hcur hb
  obtain ⟨x, _, rfl⟩ := mem_claims.1 hm
  have hno : any_burn_open db = false := by
    simp only [done, Bool.and_eq_true, Bool.not_eq_true'] at hd
    exact hd.1.2
  have hnot : burn_open db x.1 = false := by
    cases h : burn_open db x.1 with
    | false => rfl
    | true => exact absurd ((any_burn_open_iff db).2 ⟨_, h⟩) (by simp [hno])
  change Req.Closed (view db) x.1
  rw [closed_iff]
  have hb' := burn_of_burns db x.1 hb
  simp only [claimView] at hcur
  simp only [burn_open, hb', hcur, Bool.true_and, Bool.and_eq_false_iff, Bool.not_eq_false'] at hnot
  exact hnot

/-- LR2 (non-vacuity), on a state where each replaced claim is a claim. -/
theorem LR2_of (db : DB) (hsup : ∀ e ∈ db.supersedes, ∃ x ∈ db.claim, x.1 = e.2) :
    (view db).restOk = true → Req.AllBurnsClosed (view db) →
      (¬ ∃ c, Req.Reaches (view db).supersedes c c) → done db = true := by
  intro hr ha hc
  simp only [view, Bool.and_eq_true, Bool.not_eq_true'] at hr
  have hno : any_burn_open db = false := by
    cases h : any_burn_open db with
    | false => rfl
    | true =>
      obtain ⟨c, hc⟩ := (any_burn_open_iff db).1 h
      obtain ⟨hb, hcur, hp, hw⟩ := (burn_open_eq db c).1 hc
      obtain ⟨x, hx, rfl⟩ := current_claim hcur
      have hcl := ha (claimView db x.1) (mem_claims.2 ⟨x, hx, rfl⟩) hcur
        (burns_of_burn db hsup x.1 hb)
      rcases (closed_iff db x.1).1 hcl with h1 | h1
      · simp [h1] at hp
      · simp [h1] at hw
  have hcy : any_supersede_cycle db = false := by
    cases h : any_supersede_cycle db with
    | false => rfl
    | true => exact absurd ((Req.cycle_iff (view db)).1 (by rw [cycle_view]; exact h)) hc
  simp [done, hr.1.1, hr.1.2, hr.2, hno, hcy]

/-- LR3: `done` keeps its other parts. -/
theorem impl_LR3 : Req.LR3 implSys := by
  intro db hd
  simp only [done, Bool.and_eq_true] at hd
  simp [view, hd.1.1.1.1, hd.1.1.1.2, hd.1.1.2]

/-- LR4: `burn_open` means a current claim that burns and is not closed, on a
state where each replaced claim is a claim. -/
theorem LR4_of (db : DB) (hsup : ∀ e ∈ db.supersedes, ∃ x ∈ db.claim, x.1 = e.2) (c : Atom) :
    burn_open db c = true ↔
      ∃ cl ∈ (view db).claims, cl.id = c ∧ cl.current = true ∧ Req.burns (view db) cl = true ∧
        ¬ Req.Closed (view db) c := by
  rw [burn_open_eq]
  constructor
  · rintro ⟨hb, hcur, hp, hw⟩
    obtain ⟨x, hx, rfl⟩ := current_claim hcur
    refine ⟨claimView db x.1, mem_claims.2 ⟨x, hx, rfl⟩, rfl, hcur, burns_of_burn db hsup x.1 hb, ?_⟩
    rw [closed_iff]
    simp [hp, hw]
  · rintro ⟨cl, hm, rfl, hcur, hb, hnc⟩
    obtain ⟨x, _, rfl⟩ := mem_claims.1 hm
    rw [closed_iff] at hnc
    simp only [not_or, Bool.not_eq_true] at hnc
    exact ⟨burn_of_burns db x.1 hb, hcur, hnc.1, hnc.2⟩

/-- LR5: with no waiver that counts, a proof closes the burn exactly when a
script wrote it and its files did not change. -/
theorem impl_LR5 : Req.LR5 implSys := by
  intro db cl hm hcur hb hnw
  obtain ⟨x, _, rfl⟩ := mem_claims.1 hm
  have hw : burn_waived db x.1 = false := by
    cases h : burn_waived db x.1 with
    | false => rfl
    | true => exact absurd ((waived_iff db x.1).2 h) hnw
  have key : (∃ p ∈ (view db).proofs, p.claim = x.1 ∧ Req.ProofCounts p) ↔
      ∃ p ∈ (view db).proofs, p.claim = x.1 ∧ p.writer = .script ∧ p.changed = false :=
    Iff.rfl
  show burn_open db x.1 = false ↔
    ∃ p ∈ (view db).proofs, p.claim = x.1 ∧ p.writer = .script ∧ p.changed = false
  rw [← key, proved_iff]
  simp only [claimView] at hcur
  have hb' := burn_of_burns db x.1 hb
  simp [burn_open, hb', hcur, hw]

/-- LR6: with no proof that counts, a waiver closes the burn exactly when a
human wrote it and it did not lapse. -/
theorem impl_LR6 : Req.LR6 implSys := by
  intro db cl hm hcur hb hnp
  obtain ⟨x, _, rfl⟩ := mem_claims.1 hm
  have hp : burn_proved db x.1 = false := by
    cases h : burn_proved db x.1 with
    | false => rfl
    | true => exact absurd ((proved_iff db x.1).2 h) hnp
  have key : (∃ w ∈ (view db).waivers, w.claim = x.1 ∧ Req.WaiverCounts w) ↔
      ∃ w ∈ (view db).waivers, w.claim = x.1 ∧ w.writer = .human ∧ w.lapsed = false :=
    Iff.rfl
  show burn_open db x.1 = false ↔
    ∃ w ∈ (view db).waivers, w.claim = x.1 ∧ w.writer = .human ∧ w.lapsed = false
  rw [← key, waived_iff]
  simp only [claimView] at hcur
  have hb' := burn_of_burns db x.1 hb
  simp [burn_open, hb', hcur, hp]

/-- LR7: each of the three reasons makes a claim burn. -/
theorem impl_LR7 : Req.LR7 implSys := by
  intro db cl hm
  obtain ⟨x, _, rfl⟩ := mem_claims.1 hm
  refine ⟨fun h => ?_, fun h => ?_, fun h => ?_⟩ <;>
    · change burn db x.1 = true
      rw [burn_iff]
      left
      simp only [claimView, inList] at h
      simp [burn_reason, h]

/-- A KB with `universal(c109)` and no claim. -/
def danglingDB : DB := ⟨[], [], [109], [], [], [], [], [], [], [], [], [], [], [], []⟩

/-- LR8 fails for the implementation model on all states: `universal(c109)` with
no `claim(c109, _, _)` makes `burn(c109)` true, and no claim of the view is
`c109`. -/
theorem impl_not_LR8 : ¬ Req.LR8 implSys := by
  intro h
  obtain ⟨cl, hm, _, _⟩ := h danglingDB 109 (by decide)
  simp [view, danglingDB] at hm

/-! LR9: a progress record never closes a burn. The new attestation is a
`lean_result`, so it adds nothing to the searches of `contested_twice`,
`burn_proved`, and `burn_waived`, and it does not change `supersedes`. -/

theorem contested_twice_addProgress (db : DB) (r : Req.ProgressRec) (c : Atom) :
    contested_twice (addProgress db r) c = contested_twice db c := by
  have h0 : (AType.lean_result == AType.divergence) = false := rfl
  simp only [contested_twice, addProgress, progAttest, List.any_cons, h0, Bool.false_and,
    Bool.false_or]

theorem burn_reason_addProgress (db : DB) (r : Req.ProgressRec) (c : Atom) :
    burn_reason (addProgress db r) c = burn_reason db c := by
  unfold burn_reason
  rw [contested_twice_addProgress]
  rfl

theorem burn_addProgress (db : DB) (r : Req.ProgressRec) (c : Atom) :
    burn (addProgress db r) c = burn db c := by
  have hs : (addProgress db r).supersedes = db.supersedes := rfl
  simp only [burn, supersedes_closure, hs, burn_reason_addProgress]

theorem burn_proved_addProgress (db : DB) (r : Req.ProgressRec) (c : Atom) :
    burn_proved (addProgress db r) c = burn_proved db c := by
  have h0 : (AType.lean_result == AType.lean_proof) = false := rfl
  simp [burn_proved, addProgress, progAttest, h0]

theorem burn_waived_addProgress (db : DB) (r : Req.ProgressRec) (c : Atom) :
    burn_waived (addProgress db r) c = burn_waived db c := by
  have h0 : (AType.lean_result == AType.waiver) = false := rfl
  simp [burn_waived, addProgress, progAttest, h0]

theorem burn_open_addProgress (db : DB) (r : Req.ProgressRec) (c : Atom) :
    burn_open (addProgress db r) c = burn_open db c := by
  unfold burn_open
  rw [burn_addProgress, burn_proved_addProgress, burn_waived_addProgress]
  rfl

theorem impl_LR9 : Req.LR9 implSys := by
  refine ⟨fun db r => ?_, fun db r c h => ?_⟩
  · change r ∈ (view (addProgress db r)).progress
    simp only [view, addProgress, List.filterMap_cons, progressView, progAttest, ite_true,
      ofV_toV, Option.map_some, toW_ofW]
    exact List.mem_cons_self ..
  · change burn_open (addProgress db r) c = true
    rw [burn_open_addProgress]; exact h

/-- LR10: a conformance check never changes `done` or `burn_open`. -/
theorem impl_LR10 : Req.LR10 implSys :=
  ⟨fun _ _ => List.mem_cons_self .., fun _ _ => ⟨rfl, fun _ => rfl⟩⟩

/-- LR11: a claim that reaches a claim with a reason burns (S1, A10). -/
theorem impl_LR11 : Req.LR11 implSys := by
  intro db cl hm d hd hr ho
  obtain ⟨x, _, rfl⟩ := mem_claims.1 hm
  obtain ⟨y, _, rfl⟩ := mem_claims.1 hd
  change burn db x.1 = true
  rw [burn_iff]
  refine Or.inr ⟨y.1, ?_, ho⟩
  have h := (Req.reach_iff _ _ _).2 hr
  rw [reach_eq] at h
  exact h

/-- LR12: `done` implies that no claim is in a `supersedes` cycle (S2). -/
theorem impl_LR12 : Req.LR12 implSys := by
  intro db hd hc
  have hcy : any_supersede_cycle db = false := by
    simp only [done, Bool.and_eq_true, Bool.not_eq_true'] at hd
    exact hd.2
  have h := (Req.cycle_iff (view db)).2 hc
  rw [cycle_view, hcy] at h
  exact absurd h (by simp)

/-! ## The well-formed states: what lint E4 checks -/

/-- Every `universal`, `burn_requested`, divergence `claim(C)`, and both
arguments of every `supersedes` fact name a claim. -/
def WF (db : DB) : Prop :=
  (∀ u ∈ db.universal, ∃ x ∈ db.claim, x.1 = u) ∧
  (∀ u ∈ db.burn_requested, ∃ x ∈ db.claim, x.1 = u) ∧
  (∀ a ∈ db.attest, a.type = .divergence → ∀ c, a.pred = .claim c → ∃ x ∈ db.claim, x.1 = c) ∧
  (∀ e ∈ db.supersedes, (∃ x ∈ db.claim, x.1 = e.1) ∧ (∃ x ∈ db.claim, x.1 = e.2))

theorem wf_addProgress {db : DB} (h : WF db) (r : Req.ProgressRec) : WF (addProgress db r) := by
  refine ⟨h.1, h.2.1, ?_, h.2.2.2⟩
  intro a ha ht c hp
  simp only [addProgress, List.mem_cons] at ha
  rcases ha with rfl | ha
  · simp [progAttest] at ht
  · exact h.2.2.1 a ha ht c hp

theorem wf_addCheck {db : DB} (h : WF db) (k : Nat) : WF (addCheck db k) := h

theorem wf_sup {db : DB} (h : WF db) : ∀ e ∈ db.supersedes, ∃ x ∈ db.claim, x.1 = e.2 :=
  fun e he => (h.2.2.2 e he).2

abbrev implSysWF : Req.Sys where
  St := { db : DB // WF db }
  view s := view s.1
  done s := done s.1
  burn s := burn s.1
  burnOpen s := burn_open s.1
  addProgress s r := ⟨addProgress s.1 r, wf_addProgress s.2 r⟩
  addCheck s k := ⟨addCheck s.1 k, wf_addCheck s.2 k⟩

theorem implWF_LR1 : Req.LR1 implSysWF := fun s => impl_LR1 s.1
theorem implWF_LR2 : Req.LR2 implSysWF := fun s => LR2_of s.1 (wf_sup s.2)
theorem implWF_LR3 : Req.LR3 implSysWF := fun s => impl_LR3 s.1
theorem implWF_LR4 : Req.LR4 implSysWF := fun s c => LR4_of s.1 (wf_sup s.2) c
theorem implWF_LR5 : Req.LR5 implSysWF := fun s => impl_LR5 s.1
theorem implWF_LR6 : Req.LR6 implSysWF := fun s => impl_LR6 s.1
theorem implWF_LR7 : Req.LR7 implSysWF := fun s => impl_LR7 s.1

/-- LR8 holds on the well-formed states. -/
theorem implWF_LR8 : Req.LR8 implSysWF := by
  intro ⟨db, hwf⟩ c hb
  change burn db c = true at hb
  rw [burn_iff] at hb
  have hclaim : ∃ x ∈ db.claim, x.1 = c := by
    rcases hb with hb | ⟨o, h1, _⟩
    · simp only [burn_reason, Bool.or_eq_true, List.any_eq_true, beq_iff_eq] at hb
      rcases hb with (h | ⟨u, hu, rfl⟩) | ⟨u, hu, rfl⟩
      · simp only [contested_twice, List.any_eq_true, Bool.and_eq_true, beq_iff_eq] at h
        obtain ⟨a, ha, ⟨ht, hp⟩, _⟩ := h
        exact hwf.2.2.1 a ha ht c hp
      · exact hwf.1 u hu
      · exact hwf.2.1 u hu
    · obtain ⟨e, he, rfl⟩ := reach_source h1
      exact (hwf.2.2.2 e he).1
  obtain ⟨x, hx, rfl⟩ := hclaim
  refine ⟨claimView db x.1, mem_claims.2 ⟨x, hx, rfl⟩, rfl, ?_⟩
  rcases hb with hb | ⟨o, h1, h2⟩
  · left
    simp only [burn_reason, Bool.or_eq_true] at hb
    simp only [claimView, inList]
    rcases hb with (h | h) | h
    · exact Or.inl h
    · exact Or.inr (Or.inl h)
    · exact Or.inr (Or.inr h)
  · right
    obtain ⟨e, he, rfl⟩ := reach_target h1
    obtain ⟨y, hy, hye⟩ := wf_sup hwf e he
    refine ⟨claimView db y.1, mem_claims.2 ⟨y, hy, rfl⟩, ?_, ?_⟩
    · have h := h1
      change Impl.reach db.supersedes x.1 e.2 = true at h
      rw [← reach_eq, ← hye] at h
      exact (Req.reach_iff _ _ _).1 h
    · change burn_reason db y.1 = true
      rw [hye]; exact h2

theorem implWF_LR9 : Req.LR9 implSysWF :=
  ⟨fun s r => impl_LR9.1 s.1 r, fun s r c h => impl_LR9.2 s.1 r c h⟩

theorem implWF_LR10 : Req.LR10 implSysWF :=
  ⟨fun s k => impl_LR10.1 s.1 k, fun s k => impl_LR10.2 s.1 k⟩

theorem implWF_LR11 : Req.LR11 implSysWF := fun s => impl_LR11 s.1
theorem implWF_LR12 : Req.LR12 implSysWF := fun s => impl_LR12 s.1

/-- On the well-formed states, the implementation model meets all twelve requirements. -/
theorem implWF_all : Req.AllLR implSysWF :=
  ⟨implWF_LR1, implWF_LR2, implWF_LR3, implWF_LR4, implWF_LR5, implWF_LR6, implWF_LR7,
    implWF_LR8, implWF_LR9, implWF_LR10, implWF_LR11, implWF_LR12⟩

/-! ## The derived facts do not change when a record is added

The CLI computes `proof_changed` and `waiver_lapsed` again at each load. These
two lemmas show that adding a progress record or a check gives the same derived
facts. So LR9 and LR10 also hold across a reload. -/

theorem derive_addProgress (disk : Disk) (db : DB) (r : Req.ProgressRec) :
    derive disk (addProgress db r) = addProgress (derive disk db) r := by
  simp [derive, addProgress, progAttest, freshId]

theorem derive_addCheck (disk : Disk) (db : DB) (k : Nat) :
    derive disk (addCheck db k) = addCheck (derive disk db) k := rfl

end Rdz

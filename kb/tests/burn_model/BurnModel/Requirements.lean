/-!
# orbit-kb D10: the requirements model (SIMULATION)

Sources, and only these (the `thoughts/` files are in git history, tag
`thoughts-archive`):
* R1 to R5 in `thoughts/orbit-kb-d10-record.md` (Ty, 2026-10-19);
* the D10 entry in `kb/CONTRACT.md`;
* the "BURN" section and the build-module table in
  `thoughts/orbital-shifting-system-prompt-draft.md`.

This file was written before the agent read `build.pl`, `core.pl`, or the CLI.
It does not import the implementation model.

A KB is finite data. The parts of `done` that D10 did not change
(nothing under, nothing over, nothing to ask) are one input, `restOk`.
`contestedTwice`, `universal`, and `requested` are inputs: this model does not
say how the core decides that a claim is contested.

The two derived facts of the CLI are inputs with this meaning:
* `Proof.changed` is `proof_changed(A)`: the files of proof A no longer match
  its log, or the log is missing.
* `Waiver.lapsed` is `waiver_lapsed(W)`: the due time of waiver W is past, or
  the due time is not a valid time. (Amendment v2: "or not a valid time" came
  from the main session on 2026-10-20, after the D10 code review.)

Amendment v3 (2026-10-20, the D10 follow-up). Sources: Ty's decision on A10 and
the spec S1 to S3 in `thoughts/orbit-kb-d10-review-2026-10-20.md`. Not the code.
* S1: a claim burns when it has one of the three reasons, or when it reaches,
  through one or more `supersedes` steps, a claim that has one (A10, LR8, LR11).
* S2: a `supersedes` cycle, `supersedes(C, C)` included, makes `done` false
  (LR2, LR12).
* The KB now holds the `supersedes` facts (`KB.supersedes`, new, old).
  `Reaches` is "one or more steps"; `reach` computes it, and `reach_iff` proves
  that the two agree.

Assumptions (interpretations, not words of Ty). Ty must confirm them.
* A1. A superseded claim needs no proof. Only a current claim can have an open
  burn. (The contract has `current(C)` in `burn_open`. The BURN section and the
  `burn_open` table row do not say "current".)
* A2. "Current proof" means that the files of the proof match its log.
  "Current waiver" means that its due time is not past.
* A3. A proof or a waiver counts only for the claim that it names. A claim that
  supersedes another claim needs its own proof.
* A4. `burn(C)` does not depend on whether C is current. Only `burn_open(C)` does.
* A5. The model trusts the writer field. The CLI cannot verify `--by human`
  (contract D9, LM20). For a proof, the log and its digest stand behind
  `script`: a proof with no log is `changed`.
* A6. "Optional" (R5) means that a conformance check has no effect on `done`
  and no effect on `burn_open`.
* A7. One proof or one waiver that counts is enough, also when other proofs or
  waivers of the same claim do not count.
* A8. A progress record (`stated`, `refuted`, `tested(N)`) never closes a burn,
  whoever wrote it. A model run (TLC) is not a proof record, so it cannot close
  a burn (R3).
* A9. A `burn_requested(C)` fact means "the human asked for a proof of C".
* A10. DECIDED by Ty on 2026-10-20 (amendment v3): a claim that supersedes a
  claim that burns inherits the burn, also through a chain. `burns` and LR8
  say so, and LR11 is new. The witness `wCarry` (W13) shows the case: c2 burns,
  its burn is open, and the KB is not `done`.
* A11 (amendment v3, S2). A `supersedes` cycle never gives `done`. The claims of
  a cycle are not current, so without this rule their burns would close with no
  proof.
-/

namespace Req

/-- Who wrote a record. -/
inductive Writer where
  | human
  | agent
  | script
  deriving DecidableEq, Repr

/-- A claim, with the three reasons why it can burn. -/
structure Claim where
  id : Nat
  /-- `false` when a later claim supersedes this claim. -/
  current : Bool
  /-- The claim was contested twice. -/
  contestedTwice : Bool
  /-- The claim says "for every input". -/
  universal : Bool
  /-- The human asked for a proof (`burn_requested`). -/
  requested : Bool
  deriving DecidableEq, Repr

/-- A `lean_proof` record. -/
structure Proof where
  claim : Nat
  writer : Writer
  /-- Input `proof_changed`: the files no longer match the log, or no log. -/
  changed : Bool
  deriving DecidableEq, Repr

/-- A `waiver` record. -/
structure Waiver where
  claim : Nat
  writer : Writer
  /-- Input `waiver_lapsed`: the due time is past. -/
  lapsed : Bool
  deriving DecidableEq, Repr

/-- The verdict of a `lean_result` progress record. -/
inductive Progress where
  | stated
  | refuted
  | tested (n : Nat)
  deriving DecidableEq, Repr

/-- A `lean_result` progress record. -/
structure ProgressRec where
  claim : Nat
  kind : Progress
  writer : Writer
  deriving DecidableEq, Repr

/-- A KB, as finite data. -/
structure KB where
  claims : List Claim
  /-- The `supersedes(New, Old)` facts, as `(New, Old)` (amendment v3). -/
  supersedes : List (Nat × Nat)
  proofs : List Proof
  waivers : List Waiver
  progress : List ProgressRec
  /-- Conformance checks (`conformance(K)`), by number. -/
  checks : List Nat
  /-- Input: nothing is under, nothing is over, nothing is to ask. -/
  restOk : Bool
  deriving DecidableEq, Repr

/-! ## Meanings -/

/-- One of the three reasons of a claim to burn: contested twice, universal, or
the human asked. -/
def ownReason (c : Claim) : Bool := c.contestedTwice || c.universal || c.requested

/-- Zero or more `supersedes` steps from `a` to `b`. -/
inductive RReach (E : List (Nat × Nat)) : Nat → Nat → Prop where
  | refl (a : Nat) : RReach E a a
  | tail {a b c : Nat} : RReach E a b → (b, c) ∈ E → RReach E a c

/-- One or more `supersedes` steps from `a` to `c`: `a` replaces `c`, directly or
through other claims. -/
def Reaches (E : List (Nat × Nat)) (a c : Nat) : Prop := ∃ b, (a, b) ∈ E ∧ RReach E b c

/-- `RReach`, computed by recursion on the list of steps: a path in `e :: E`
either does not use `e`, or it goes to `e.1` in `E`, takes `e`, and goes on from
`e.2` in `E`. `rreach_iff` proves that it agrees with `RReach`. -/
def rreach : List (Nat × Nat) → Nat → Nat → Bool
  | [], a, b => a == b
  | e :: E, a, b => rreach E a b || (rreach E a e.1 && rreach E e.2 b)

/-- `Reaches`, computed (`reach_iff`). -/
def reach (E : List (Nat × Nat)) (a c : Nat) : Bool := E.any fun e => e.1 == a && rreach E e.2 c

/-- A claim burns when it has one of the three reasons, or when it reaches, through
one or more `supersedes` steps, a claim that has one (S1, A10). -/
def burns (kb : KB) (c : Claim) : Bool :=
  ownReason c || kb.claims.any fun d => reach kb.supersedes c.id d.id && ownReason d

/-- A `supersedes` cycle: some claim reaches itself (S2). -/
def cycle (kb : KB) : Bool := kb.supersedes.any fun e => reach kb.supersedes e.1 e.1

/-! ## `reach` computes `Reaches` -/

theorem RReach.mono {E E' : List (Nat × Nat)} (h : ∀ x, x ∈ E → x ∈ E') {a b : Nat}
    (r : RReach E a b) : RReach E' a b := by
  induction r with
  | refl => exact .refl _
  | tail _ hm ih => exact .tail ih (h _ hm)

theorem RReach.trans {E : List (Nat × Nat)} {a b c : Nat} (h1 : RReach E a b)
    (h2 : RReach E b c) : RReach E a c := by
  induction h2 with
  | refl => exact h1
  | tail _ hm ih => exact .tail ih hm

theorem RReach.head {E : List (Nat × Nat)} {a b c : Nat} (hm : (a, b) ∈ E)
    (h : RReach E b c) : RReach E a c :=
  (RReach.tail (.refl a) hm).trans h

theorem rreach_refl (E : List (Nat × Nat)) (a : Nat) : rreach E a a = true := by
  induction E with
  | nil => simp [rreach]
  | cons e E ih => simp [rreach, ih]

theorem rreach_sound : ∀ (E : List (Nat × Nat)) (a b : Nat), rreach E a b = true → RReach E a b
  | [], a, b, h => by
    simp only [rreach, beq_iff_eq] at h
    subst h
    exact .refl a
  | e :: E, a, b, h => by
    have sub : ∀ x, x ∈ E → x ∈ e :: E := fun x hx => List.mem_cons_of_mem e hx
    simp only [rreach, Bool.or_eq_true, Bool.and_eq_true] at h
    rcases h with h | ⟨h1, h2⟩
    · exact (rreach_sound E a b h).mono sub
    · exact ((rreach_sound E a e.1 h1).mono sub).trans
        (RReach.head (List.mem_cons_self ..) ((rreach_sound E e.2 b h2).mono sub))

theorem rreach_complete : ∀ (E : List (Nat × Nat)) {a b : Nat}, RReach E a b → rreach E a b = true
  | [], _, _, r => by
    cases r with
    | refl => simp [rreach]
    | tail _ hm => simp at hm
  | e :: E, x, _, r => by
    induction r with
    | refl => exact rreach_refl _ x
    | @tail y z _ hm ih =>
      simp only [rreach, Bool.or_eq_true, Bool.and_eq_true] at ih ⊢
      rcases List.mem_cons.1 hm with he | hm'
      · subst he
        right
        exact ⟨by rcases ih with h | ⟨h, _⟩ <;> exact h, rreach_refl E z⟩
      · rcases ih with h | ⟨h1, h2⟩
        · left
          exact rreach_complete E ((rreach_sound E x y h).tail hm')
        · right
          exact ⟨h1, rreach_complete E ((rreach_sound E e.2 y h2).tail hm')⟩

theorem rreach_iff (E : List (Nat × Nat)) (a b : Nat) : rreach E a b = true ↔ RReach E a b :=
  ⟨rreach_sound E a b, rreach_complete E⟩

theorem reach_iff (E : List (Nat × Nat)) (a c : Nat) : reach E a c = true ↔ Reaches E a c := by
  unfold reach Reaches
  simp only [List.any_eq_true, Bool.and_eq_true, beq_iff_eq, rreach_iff]
  constructor
  · rintro ⟨⟨x, y⟩, hm, rfl, h⟩
    exact ⟨y, hm, h⟩
  · rintro ⟨b, hm, h⟩
    exact ⟨(a, b), hm, rfl, h⟩

instance (E : List (Nat × Nat)) (a c : Nat) : Decidable (Reaches E a c) :=
  decidable_of_iff _ (reach_iff E a c)

theorem cycle_iff (kb : KB) : cycle kb = true ↔ ∃ c, Reaches kb.supersedes c c := by
  unfold cycle
  simp only [List.any_eq_true]
  constructor
  · rintro ⟨e, _, h⟩
    exact ⟨e.1, (reach_iff _ _ _).1 h⟩
  · rintro ⟨c, h⟩
    have h' := h
    obtain ⟨b, hm, _⟩ := h'
    exact ⟨(c, b), hm, (reach_iff _ _ _).2 h⟩

/-- A proof counts only when a script wrote it and its files did not change. -/
def ProofCounts (p : Proof) : Prop := p.writer = .script ∧ p.changed = false

/-- A waiver counts only when a human wrote it and it did not lapse. -/
def WaiverCounts (w : Waiver) : Prop := w.writer = .human ∧ w.lapsed = false

instance (p : Proof) : Decidable (ProofCounts p) := by
  unfold ProofCounts; infer_instance

instance (w : Waiver) : Decidable (WaiverCounts w) := by
  unfold WaiverCounts; infer_instance

/-- The burn of claim `c` is closed: a proof that counts, or a waiver that counts. -/
def Closed (kb : KB) (c : Nat) : Prop :=
  (∃ p ∈ kb.proofs, p.claim = c ∧ ProofCounts p) ∨
  (∃ w ∈ kb.waivers, w.claim = c ∧ WaiverCounts w)

instance (kb : KB) (c : Nat) : Decidable (Closed kb c) := by
  unfold Closed; infer_instance

/-- Every current claim that burns has a proof or a waiver that counts. -/
def AllBurnsClosed (kb : KB) : Prop :=
  ∀ c ∈ kb.claims, c.current = true → burns kb c = true → Closed kb c.id

instance (kb : KB) : Decidable (AllBurnsClosed kb) := by
  unfold AllBurnsClosed; infer_instance

/-! ## A system under test

An implementation gives a state type, a view of each state as a `KB`, the three
queries, and the two operations that the frame requirements talk about. -/

structure Sys where
  St : Type
  view : St → KB
  done : St → Bool
  burn : St → Nat → Bool
  burnOpen : St → Nat → Bool
  /-- Add one `lean_result` progress record. -/
  addProgress : St → ProgressRec → St
  /-- Add one conformance check. -/
  addCheck : St → Nat → St

/-! ## The requirements -/

variable (S : Sys)

/-- LR1 (R1, R4). `done` implies that every current claim that burns has a
current proof or a current human waiver. -/
def LR1 : Prop := ∀ s, S.done s = true → AllBurnsClosed (S.view s)

/-- LR2 (non-vacuity, the converse of LR1). If the other parts of `done` hold,
every current claim that burns is closed, and no claim is in a `supersedes`
cycle, then `done` holds. -/
def LR2 : Prop :=
  ∀ s, (S.view s).restOk = true → AllBurnsClosed (S.view s) →
    (¬ ∃ c, Reaches (S.view s).supersedes c c) → S.done s = true

/-- LR3. `done` keeps its other parts: `done` implies nothing under, nothing
over, and nothing to ask. -/
def LR3 : Prop := ∀ s, S.done s = true → (S.view s).restOk = true

/-- LR4 (the `burn_open` row). `burn_open(c)` holds exactly when a current claim
`c` burns and has no proof and no waiver that counts. -/
def LR4 : Prop :=
  ∀ s c, S.burnOpen s c = true ↔
    ∃ cl ∈ (S.view s).claims, cl.id = c ∧ cl.current = true ∧ burns (S.view s) cl = true ∧
      ¬ Closed (S.view s) c

/-- LR5 (R2). A proof closes a burn only when a script wrote it and its files did
not change. Stated for a current burning claim with no waiver that counts. -/
def LR5 : Prop :=
  ∀ s, ∀ cl ∈ (S.view s).claims, cl.current = true → burns (S.view s) cl = true →
    (¬ ∃ w ∈ (S.view s).waivers, w.claim = cl.id ∧ WaiverCounts w) →
    (S.burnOpen s cl.id = false ↔
      ∃ p ∈ (S.view s).proofs, p.claim = cl.id ∧ p.writer = .script ∧ p.changed = false)

/-- LR6 (R4). A waiver closes a burn only when a human wrote it and its due time
is not past. Stated for a current burning claim with no proof that counts. -/
def LR6 : Prop :=
  ∀ s, ∀ cl ∈ (S.view s).claims, cl.current = true → burns (S.view s) cl = true →
    (¬ ∃ p ∈ (S.view s).proofs, p.claim = cl.id ∧ ProofCounts p) →
    (S.burnOpen s cl.id = false ↔
      ∃ w ∈ (S.view s).waivers, w.claim = cl.id ∧ w.writer = .human ∧ w.lapsed = false)

/-- LR7 (the `burn` row). Each of the three reasons makes a claim burn. -/
def LR7 : Prop :=
  ∀ s, ∀ cl ∈ (S.view s).claims,
    (cl.contestedTwice = true → S.burn s cl.id = true) ∧
    (cl.universal = true → S.burn s cl.id = true) ∧
    (cl.requested = true → S.burn s cl.id = true)

/-- LR8 (the `burn` row, "true when"). There is no other reason to burn: the
claim has one of the three reasons, or it reaches a claim that has one (v3). -/
def LR8 : Prop :=
  ∀ s c, S.burn s c = true →
    ∃ cl ∈ (S.view s).claims, cl.id = c ∧
      ((cl.contestedTwice = true ∨ cl.universal = true ∨ cl.requested = true) ∨
       ∃ d ∈ (S.view s).claims, Reaches (S.view s).supersedes c d.id ∧ ownReason d = true)

/-- LR9 (R1, frame). Adding a `stated`, `refuted`, or `tested(N)` record never
closes a burn. The first part says that the operation really adds the record. -/
def LR9 : Prop :=
  (∀ s r, r ∈ (S.view (S.addProgress s r)).progress) ∧
  (∀ s r c, S.burnOpen s c = true → S.burnOpen (S.addProgress s r) c = true)

/-- LR10 (R5, frame). A conformance check never changes `done` or `burn_open`.
The first part says that the operation really adds the check. -/
def LR10 : Prop :=
  (∀ s k, k ∈ (S.view (S.addCheck s k)).checks) ∧
  (∀ s k, S.done (S.addCheck s k) = S.done s ∧
    ∀ c, S.burnOpen (S.addCheck s k) c = S.burnOpen s c)

/-- LR11 (S1, A10). A claim that reaches, through one or more `supersedes` steps,
a claim with one of the three reasons burns. -/
def LR11 : Prop :=
  ∀ s, ∀ cl ∈ (S.view s).claims, ∀ d ∈ (S.view s).claims,
    Reaches (S.view s).supersedes cl.id d.id → ownReason d = true → S.burn s cl.id = true

/-- LR12 (S2). `done` implies that no claim is in a `supersedes` cycle. -/
def LR12 : Prop := ∀ s, S.done s = true → ¬ ∃ c, Reaches (S.view s).supersedes c c

/-- All twelve requirements. -/
def AllLR : Prop :=
  LR1 S ∧ LR2 S ∧ LR3 S ∧ LR4 S ∧ LR5 S ∧ LR6 S ∧ LR7 S ∧ LR8 S ∧ LR9 S ∧ LR10 S ∧
    LR11 S ∧ LR12 S

/-! ## Consequences that hold for every system -/

/-- LR1 and LR4 give: an open burn makes `done` false. -/
theorem open_blocks_done {S : Sys} (h1 : LR1 S) (h4 : LR4 S) (s : S.St) (c : Nat)
    (ho : S.burnOpen s c = true) : S.done s = false := by
  cases hd : S.done s with
  | false => rfl
  | true =>
    obtain ⟨cl, hm, hid, hcur, hb, hnc⟩ := (h4 s c).1 ho
    exact absurd (hid ▸ h1 s hd cl hm hcur hb) hnc

/-- LR1, LR4, and LR9 give: while a burn is open, no progress record makes the
work `done`. -/
theorem progress_never_makes_done {S : Sys} (h1 : LR1 S) (h4 : LR4 S) (h9 : LR9 S)
    (s : S.St) (c : Nat) (r : ProgressRec) (ho : S.burnOpen s c = true) :
    S.done (S.addProgress s r) = false :=
  open_blocks_done h1 h4 _ c (h9.2 s r c ho)

/-! ## The reference system: the requirements are consistent

`spec` reads the requirements as rules. `spec_satisfies` shows that one system
meets all twelve requirements together, so they do not contradict each other. -/

def specDone (kb : KB) : Bool := kb.restOk && decide (AllBurnsClosed kb) && !cycle kb

def specBurn (kb : KB) (c : Nat) : Bool :=
  decide (∃ cl ∈ kb.claims, cl.id = c ∧ burns kb cl = true)

def specOpen (kb : KB) (c : Nat) : Bool :=
  decide (∃ cl ∈ kb.claims, cl.id = c ∧ cl.current = true ∧ burns kb cl = true ∧ ¬ Closed kb c)

def spec : Sys where
  St := KB
  view := id
  done := specDone
  burn := specBurn
  burnOpen := specOpen
  addProgress kb r := { kb with progress := r :: kb.progress }
  addCheck kb k := { kb with checks := k :: kb.checks }

theorem spec_satisfies : AllLR spec := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro s h
    simp only [spec, specDone, Bool.and_eq_true, decide_eq_true_eq] at h
    exact h.1.2
  · intro s hr ha hc
    have hc' : cycle s = false := by
      cases h : cycle s with
      | false => rfl
      | true => exact absurd ((cycle_iff s).1 h) hc
    simp only [spec, specDone, Bool.and_eq_true, decide_eq_true_eq, hc', Bool.not_false]
    exact ⟨⟨hr, ha⟩, trivial⟩
  · intro s h
    simp only [spec, specDone, Bool.and_eq_true] at h
    exact h.1.1
  · intro s c
    simp only [spec, specOpen, id, decide_eq_true_eq]
  · intro s cl hm hcur hb hnw
    simp only [spec, specOpen, id, decide_eq_false_iff_not]
    constructor
    · intro hn
      have hc : Closed s cl.id := by
        refine Classical.byContradiction fun hnc => hn ⟨cl, hm, rfl, hcur, hb, hnc⟩
      rcases hc with ⟨p, hp, hpc, hpw, hpch⟩ | hw
      · exact ⟨p, hp, hpc, hpw, hpch⟩
      · exact absurd hw hnw
    · rintro ⟨p, hp, hpc, hpw, hpch⟩ ⟨_, _, _, _, _, hnc⟩
      exact hnc (Or.inl ⟨p, hp, hpc, hpw, hpch⟩)
  · intro s cl hm hcur hb hnp
    simp only [spec, specOpen, id, decide_eq_false_iff_not]
    constructor
    · intro hn
      have hc : Closed s cl.id := by
        refine Classical.byContradiction fun hnc => hn ⟨cl, hm, rfl, hcur, hb, hnc⟩
      rcases hc with hp | ⟨w, hw, hwc, hww, hwl⟩
      · exact absurd hp hnp
      · exact ⟨w, hw, hwc, hww, hwl⟩
    · rintro ⟨w, hw, hwc, hww, hwl⟩ ⟨_, _, _, _, _, hnc⟩
      exact hnc (Or.inr ⟨w, hw, hwc, hww, hwl⟩)
  · intro s cl hm
    simp only [spec, specBurn]
    refine ⟨fun h => decide_eq_true ⟨cl, hm, rfl, by simp [burns, ownReason, h]⟩,
      fun h => decide_eq_true ⟨cl, hm, rfl, by simp [burns, ownReason, h]⟩,
      fun h => decide_eq_true ⟨cl, hm, rfl, by simp [burns, ownReason, h]⟩⟩
  · intro s c h
    simp only [spec, specBurn, decide_eq_true_eq] at h
    obtain ⟨cl, hm, rfl, hb⟩ := h
    refine ⟨cl, hm, rfl, ?_⟩
    simp only [burns, Bool.or_eq_true, List.any_eq_true, Bool.and_eq_true] at hb
    rcases hb with h | ⟨d, hd, hr, ho⟩
    · simp only [ownReason, Bool.or_eq_true] at h
      rcases h with (h | h) | h
      · exact Or.inl (Or.inl h)
      · exact Or.inl (Or.inr (Or.inl h))
      · exact Or.inl (Or.inr (Or.inr h))
    · exact Or.inr ⟨d, hd, (reach_iff _ _ _).1 hr, ho⟩
  · refine ⟨fun s r => List.mem_cons_self .., ?_⟩
    intro s r c h
    simpa [spec, specOpen, Closed, burns] using h
  · refine ⟨fun s k => List.mem_cons_self .., ?_⟩
    intro s k
    exact ⟨rfl, fun _ => rfl⟩
  · intro s cl hm d hd hr ho
    simp only [spec, specBurn]
    refine decide_eq_true ⟨cl, hm, rfl, ?_⟩
    simp only [burns, Bool.or_eq_true, List.any_eq_true, Bool.and_eq_true]
    exact Or.inr ⟨d, hd, (reach_iff _ _ _).2 hr, ho⟩
  · intro s h hc
    simp only [spec, specDone, Bool.and_eq_true, Bool.not_eq_true'] at h
    exact absurd ((cycle_iff s).2 hc) (by simp [h.2])

/-! ## Witnesses

Each conditional requirement gets a concrete KB that meets its hypothesis.
`decide` checks each case in the kernel. -/

/-- Claim 1 is current and universal. -/
def u1 : Claim := ⟨1, true, false, true, false⟩

def base : KB := ⟨[u1], [], [], [], [], [], true⟩

/-- W1. A burn closed by a proof. -/
def wProof : KB := { base with proofs := [⟨1, .script, false⟩] }
/-- W2. A burn closed by a waiver. -/
def wWaiver : KB := { base with waivers := [⟨1, .human, false⟩] }
/-- W3. Open: the files of the proof changed. -/
def wChanged : KB := { base with proofs := [⟨1, .script, true⟩] }
/-- W4. Open: the waiver lapsed. -/
def wLapsed : KB := { base with waivers := [⟨1, .human, true⟩] }
/-- W5. Open: an agent wrote the proof. -/
def wAgent : KB := { base with proofs := [⟨1, .agent, false⟩] }
/-- W6. Open: an agent wrote the waiver. -/
def wAgentWaiver : KB := { base with waivers := [⟨1, .agent, false⟩] }
/-- W7. A superseded universal claim with no proof (assumption A1). The claim
that supersedes it is not in the KB, so nothing inherits the burn. -/
def wSuperseded : KB := { base with claims := [⟨1, false, false, true, false⟩] }
/-- W8. Contested twice, no proof. -/
def wContested : KB := { base with claims := [⟨1, true, true, false, false⟩] }
/-- W9. Requested by the human, no proof. -/
def wRequested : KB := { base with claims := [⟨1, true, false, false, true⟩] }
/-- W10. A claim with no reason to burn, no proof. -/
def wCoast : KB := { base with claims := [⟨1, true, false, false, false⟩] }
/-- W11. All burns closed, but something else is open (`restOk` false). -/
def wRest : KB := { wProof with restOk := false }
/-- W12. One changed proof and one current proof (assumption A7). -/
def wTwoProofs : KB := { base with proofs := [⟨1, .script, true⟩, ⟨1, .script, false⟩] }

-- W1, W2: `done`, and the hypotheses of LR2, LR5, LR6 hold.
example : specDone wProof = true ∧ specOpen wProof 1 = false := by decide
example : specDone wWaiver = true ∧ specOpen wWaiver 1 = false := by decide
example : (wProof.restOk = true ∧ AllBurnsClosed wProof) ∧
    (wWaiver.restOk = true ∧ AllBurnsClosed wWaiver) := by decide
-- W3, W4, W5, W6: open, and not `done`.
example : specOpen wChanged 1 = true ∧ specDone wChanged = false := by decide
example : specOpen wLapsed 1 = true ∧ specDone wLapsed = false := by decide
example : specOpen wAgent 1 = true ∧ specDone wAgent = false := by decide
example : specOpen wAgentWaiver 1 = true ∧ specDone wAgentWaiver = false := by decide
-- W7: a superseded claim burns, but its burn is not open (A1, A4).
example : specBurn wSuperseded 1 = true ∧ specOpen wSuperseded 1 = false ∧
    specDone wSuperseded = true := by decide
-- W8, W9, and W3 (universal): each reason makes the claim burn, and the burn is open.
example : specBurn wContested 1 = true ∧ specOpen wContested 1 = true := by decide
example : specBurn wRequested 1 = true ∧ specOpen wRequested 1 = true := by decide
example : specBurn base 1 = true ∧ specOpen base 1 = true := by decide
-- W10: no reason, no burn, and `done` needs no proof.
example : specBurn wCoast 1 = false ∧ specDone wCoast = true := by decide
-- W11: LR3. Closed burns do not make `done` alone.
example : specDone wRest = false := by decide
-- W12: A7.
example : specOpen wTwoProofs 1 = false := by decide

/-- W13 (A10, decided). Universal claim 1 is superseded by plain claim 2. No proof. -/
def wCarry : KB :=
  { base with claims := [⟨1, false, false, true, false⟩, ⟨2, true, false, false, false⟩],
              supersedes := [(2, 1)] }
-- W13: c2 inherits the burn of c1. Its burn is open, and the KB is not `done`.
-- A proof of c2 closes it.
example : specBurn wCarry 2 = true ∧ specOpen wCarry 1 = false ∧ specOpen wCarry 2 = true ∧
    specDone wCarry = false := by decide
example : specDone { wCarry with proofs := [⟨2, .script, false⟩] } = true := by decide
/-- W14 (S1). A chain: claim 3 supersedes claim 2, claim 2 supersedes universal claim 1. -/
def wChain : KB :=
  { base with claims := [⟨1, false, false, true, false⟩, ⟨2, false, false, false, false⟩,
                         ⟨3, true, false, false, false⟩],
              supersedes := [(3, 2), (2, 1)] }
example : specBurn wChain 2 = true ∧ specBurn wChain 3 = true ∧ specOpen wChain 3 = true ∧
    specDone wChain = false := by decide
example : specDone { wChain with proofs := [⟨3, .script, false⟩] } = true := by decide
/-- W15 (S2). Universal claim 1 supersedes itself. -/
def wSelf : KB :=
  { base with claims := [⟨1, false, false, true, false⟩], supersedes := [(1, 1)] }
-- W15: claim 1 is not current, so no burn is open. But the cycle blocks `done`.
example : specOpen wSelf 1 = false ∧ cycle wSelf = true ∧ specDone wSelf = false := by decide
/-- W16 (S2). A two-claim cycle: claims 1 and 2 supersede each other. Claim 1 is
universal, so claim 2 burns too. -/
def wCycle2 : KB :=
  { base with claims := [⟨1, false, false, true, false⟩, ⟨2, false, false, false, false⟩],
              supersedes := [(1, 2), (2, 1)] }
example : specBurn wCycle2 2 = true ∧ specOpen wCycle2 2 = false ∧ specDone wCycle2 = false := by
  decide
-- LR9: a `tested(5)` record by a script does not close the burn of W3.
example : specOpen (spec.addProgress wChanged ⟨1, .tested 5, .script⟩) 1 = true := by decide
-- LR10: a conformance check does not change `done` of W1 or W3.
example : specDone (spec.addCheck wProof 7) = true ∧
    specDone (spec.addCheck wChanged 7) = false := by decide

/-- The witness table, for a human to read. -/
def witnessTable : List (String × Bool × Bool) :=
  [("W1 proof", specOpen wProof 1, specDone wProof),
   ("W2 waiver", specOpen wWaiver 1, specDone wWaiver),
   ("W3 proof changed", specOpen wChanged 1, specDone wChanged),
   ("W4 waiver lapsed", specOpen wLapsed 1, specDone wLapsed),
   ("W5 agent proof", specOpen wAgent 1, specDone wAgent),
   ("W6 agent waiver", specOpen wAgentWaiver 1, specDone wAgentWaiver),
   ("W7 superseded", specOpen wSuperseded 1, specDone wSuperseded),
   ("W8 contested twice", specOpen wContested 1, specDone wContested),
   ("W9 requested", specOpen wRequested 1, specDone wRequested),
   ("W10 coasts", specOpen wCoast 1, specDone wCoast),
   ("W11 rest open", specOpen wRest 1, specDone wRest),
   ("W12 two proofs", specOpen wTwoProofs 1, specDone wTwoProofs),
   ("W13 superseded by a plain claim (A10)", specOpen wCarry 2, specDone wCarry),
   ("W14 a supersede chain", specOpen wChain 3, specDone wChain),
   ("W15 supersedes itself", specOpen wSelf 1, specDone wSelf),
   ("W16 a two-claim cycle", specOpen wCycle2 2, specDone wCycle2)]

end Req

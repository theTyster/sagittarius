/-!
# orbit-kb D10: the implementation model (TELEMETRY)

This file models the Prolog rules of
`shared/link/.local/share/orbit-kb/core.pl` and
`shared/link/.local/share/orbit-kb/modules/build.pl`, clause by clause,
with the same names. Each definition cites the clauses that it models.

The program is not recursive, so it is stratified. A `not` literal is negation
as failure over the finite KB: `!p` in `Bool`.

## Abstractions

* An atom is a `Nat`. The generator in `Conform.lean` gives each sort its own
  range (claims, checks, changes, questions, attestations, values).
* Text arguments are dropped. No rule in scope reads them.
* A time is a `Nat` (the year). The CLI compares ISO time atoms in the standard
  order of terms (`Due @< Now`). For the times that the generator writes, the
  standard order of the atom and the order of the year agree.
* A digest is a `Nat`. No rule reads it. Only `proof_state` in the CLI reads it.
* `proof_changed/1` and `waiver_lapsed/1` are fields of `DB`. The engines see
  them as facts. `derive` models how the CLI computes them (`derived_items/3`):
  `Disk.proofOk` stands for `proof_state(Dir, A, P, ok)` (the log exists, it
  names the claim and the digest, its lines give the digest, and every file
  still has its sha256), `Disk.now` stands for `utc_now/1`, and
  `Disk.validTime` stands for `is_time/1` (D10 follow-up, F9).
* `supersedes_closure/2` and `supersede_cycle/1` are derived facts too (D10
  follow-up, S3). They depend only on the `supersedes/2` facts, so the model
  computes them as functions of `DB.supersedes` (`reach`). The CLI computes
  them with a depth-first search (`supersede_closure/2`). `reach` is the same
  function as `Req.reach`, and `Req.reach_iff` proves that it is "one or more
  steps". The conformance runs compare the two computations.
* `rules.pl` is empty. The model has no extension clauses. (Since the D10
  follow-up, lint E16 rejects a `rules.pl` clause for a rule of this model, and
  the engines ignore it.)
* Ids in kb.pl are atoms (finding F5 of the Lean phases).
* `supersedes/2` can form a cycle, also `supersedes(C, C)`. `current` follows the
  rule. Since the D10 follow-up, a cycle makes `done` false.
-/

namespace Impl

abbrev Atom := Nat

/-- `by` (`human`, `agent`, `script`). -/
inductive Writer where
  | human
  | agent
  | script
  deriving DecidableEq, Repr

/-- The type of an attestation (the 2nd argument of `attest/6`). -/
inductive AType where
  | lean_result
  | lean_proof
  | waiver
  | divergence
  | test_result
  | disproof
  | other
  deriving DecidableEq, Repr

/-- The verdict in `verdict(C, V)`. `lean_result` and `disproof` share the shape. -/
inductive Verdict where
  | stated
  | refuted
  | tested (n : Nat)
  | inconclusive
  | abstained
  deriving DecidableEq, Repr

inductive Outcome where
  | pass
  | fail
  deriving DecidableEq, Repr

/-- The predicate of an attestation (the 4th argument of `attest/6`). -/
inductive Pred where
  /-- `verdict(C, V)` -/
  | verdict (c : Atom) (v : Verdict)
  /-- `claim(C)` (a divergence) -/
  | claim (c : Atom)
  /-- `result(K, R, pass|fail)` -/
  | result (k : Atom) (r : Nat) (o : Outcome)
  /-- `proof(C, Digest)` -/
  | proof (c : Atom) (d : Nat)
  /-- `waive(C, Due, Text)`, without the text -/
  | waive (c : Atom) (due : Nat)
  /-- any other shape -/
  | other
  deriving DecidableEq, Repr

/-- `attest(Id, Type, Subject, Pred, By, Time)`. -/
structure Attest where
  id : Atom
  type : AType
  subj : Atom
  pred : Pred
  by_ : Writer
  time : Nat
  deriving DecidableEq, Repr

/-- The label of `claim(C, L, Text)`. -/
inductive Label where
  | preserve
  | retire
  | introduce
  deriving DecidableEq, Repr

/-- The facts that the rules read: kb.pl and the derived facts. -/
structure DB where
  /-- `claim(C, L, _)` -/
  claim : List (Atom × Label)
  /-- `supersedes(New, Old)` -/
  supersedes : List (Atom × Atom)
  /-- `universal(C)` -/
  universal : List Atom
  /-- `burn_requested(C)` -/
  burn_requested : List Atom
  /-- `check(K, C)` -/
  check : List (Atom × Atom)
  /-- `change(X, _)` -/
  change : List Atom
  /-- `serves(X, C)` -/
  serves : List (Atom × Atom)
  /-- `question(Q, C, _)` -/
  question : List (Atom × Atom)
  /-- `assumed(Q, A)` -/
  assumed : List (Atom × Atom)
  /-- `answer(Q, B, By)` -/
  answer : List (Atom × Atom × Writer)
  /-- `depends(Q, P)` -/
  depends : List (Atom × Atom)
  /-- `conformance(K)` -/
  conformance : List Atom
  /-- `attest/6` -/
  attest : List Attest
  /-- derived: `proof_changed(A)` -/
  proof_changed : List Atom
  /-- derived: `waiver_lapsed(W)` -/
  waiver_lapsed : List Atom
  deriving DecidableEq, Repr

variable (db : DB)

/-! ## Core rules (core.pl) -/

/-- `superseded(C) :- supersedes(_, C).` -/
def superseded (c : Atom) : Bool := db.supersedes.any fun p => p.2 == c

/-- `current(C) :- claim(C, _, _), not superseded(C).` -/
def current (c : Atom) : Bool := db.claim.any (fun p => p.1 == c) && !superseded db c

/-- `answered(Q) :- answer(Q, _, human).` -/
def answered (q : Atom) : Bool := db.answer.any fun x => x.1 == q && x.2.2 == .human

/-- `defeated(Q) :- assumed(Q, A), answer(Q, B, human), A \= B.` -/
def defeated (q : Atom) : Bool :=
  db.assumed.any fun x => x.1 == q &&
    db.answer.any fun y => y.1 == q && y.2.2 == .human && x.2 != y.2.1

/-- `refuted(C) :- attest(_, _, _, verdict(C, refuted), _, _).` -/
def refuted (c : Atom) : Bool := db.attest.any fun a => a.pred == .verdict c .refuted

/-- `contested(C) :- attest(_, divergence, _, claim(C), _, _).` -/
def contested (c : Atom) : Bool :=
  db.attest.any fun a => a.type == .divergence && a.pred == .claim c

/-- `contested_twice(C) :- attest(D1, divergence, _, claim(C), _, _),
attest(D2, divergence, _, claim(C), _, _), D1 \= D2.` -/
def contested_twice (c : Atom) : Bool :=
  db.attest.any fun a1 => a1.type == .divergence && a1.pred == .claim c &&
    db.attest.any fun a2 => a2.type == .divergence && a2.pred == .claim c && a1.id != a2.id

/-- The two clauses of `to_ask/1`:
`to_ask(Q) :- question(Q, C, _), current(C), depends(Q, P), defeated(P), not answered(Q).`
`to_ask(Q) :- question(Q, C, _), current(C), contested(C), not answered(Q).` -/
def to_ask (q : Atom) : Bool :=
  (db.question.any fun x => x.1 == q && current db x.2 &&
    db.depends.any (fun d => d.1 == q && defeated db d.2) && !answered db q) ||
  (db.question.any fun x => x.1 == q && current db x.2 && contested db x.2 && !answered db q)

/-- `any_to_ask :- to_ask(_).` `to_ask(Q)` needs `question(Q, _, _)`, so the
search over the question ids is exact (`any_to_ask_iff`). -/
def any_to_ask : Bool := db.question.any fun x => to_ask db x.1

/-- `failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.` -/
def failed_after (k : Atom) (r : Nat) : Bool :=
  db.attest.any fun a => a.type == .test_result &&
    match a.pred with
    | .result k' r2 .fail => k' == k && decide (r2 > r)
    | _ => false

/-- `passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R).` -/
def passed (k : Atom) : Bool :=
  db.attest.any fun a => a.type == .test_result &&
    match a.pred with
    | .result k' r .pass => k' == k && !failed_after db k r
    | _ => false

/-- `was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _),
attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.` -/
def was_red (k : Atom) : Bool :=
  db.attest.any fun a1 => a1.type == .test_result &&
    match a1.pred with
    | .result k1 r1 .fail => k1 == k &&
        db.attest.any fun a2 => a2.type == .test_result &&
          match a2.pred with
          | .result k2 r2 .pass => k2 == k && decide (r1 < r2)
          | _ => false
    | _ => false

/-! ## Build rules (modules/build.pl) -/

/-! ## The supersede closure (derived facts, D10 follow-up) -/

/-- Zero or more steps, by recursion on the list of steps (as `Req.rreach`). -/
def rreach : List (Atom × Atom) → Atom → Atom → Bool
  | [], a, b => a == b
  | e :: E, a, b => rreach E a b || (rreach E a e.1 && rreach E e.2 b)

/-- One or more steps (as `Req.reach`). -/
def reach (E : List (Atom × Atom)) (a c : Atom) : Bool :=
  E.any fun e => e.1 == a && rreach E e.2 c

/-- The derived fact `supersedes_closure(N, O)`. -/
def supersedes_closure (n o : Atom) : Bool := reach db.supersedes n o

/-- The derived fact `supersede_cycle(C)`. -/
def supersede_cycle (c : Atom) : Bool := reach db.supersedes c c

/-- `any_supersede_cycle :- supersede_cycle(_).` A claim of a cycle is the first
argument of a `supersedes` fact, so the search over the facts is exact
(`any_supersede_cycle_iff`). -/
def any_supersede_cycle : Bool := db.supersedes.any fun e => supersede_cycle db e.1

/-- The two clauses of `fulfilled/1`:
`fulfilled(C) :- claim(C, preserve, _), check(K, C), passed(K), not refuted(C).`
`fulfilled(C) :- claim(C, L, _), L \= preserve, check(K, C), passed(K), was_red(K), not refuted(C).` -/
def fulfilled (c : Atom) : Bool :=
  (db.claim.any fun x => x.1 == c && x.2 == .preserve &&
    db.check.any (fun k => k.2 == c && passed db k.1) && !refuted db c) ||
  (db.claim.any fun x => x.1 == c && x.2 != .preserve &&
    db.check.any (fun k => k.2 == c && passed db k.1 && was_red db k.1) && !refuted db c)

/-- `under(C) :- current(C), not fulfilled(C).` -/
def under (c : Atom) : Bool := current db c && !fulfilled db c

/-- `served(X) :- serves(X, _).` -/
def served (x : Atom) : Bool := db.serves.any fun s => s.1 == x

/-- `over(X) :- change(X, _), not served(X).` -/
def over (x : Atom) : Bool := db.change.any (fun y => y == x) && !served db x

/-- `any_under :- under(_).` `under(C)` needs `claim(C, _, _)`. -/
def any_under : Bool := db.claim.any fun x => under db x.1

/-- `any_over :- over(_).` `over(X)` needs `change(X, _)`. -/
def any_over : Bool := db.change.any fun x => over db x

/-- The three clauses of `burn_reason/1`:
`burn_reason(C) :- contested_twice(C).` `burn_reason(C) :- universal(C).`
`burn_reason(C) :- burn_requested(C).` -/
def burn_reason (c : Atom) : Bool :=
  contested_twice db c || db.universal.any (fun u => u == c) ||
    db.burn_requested.any (fun u => u == c)

/-- The two clauses of `burn/1`: `burn(C) :- burn_reason(C).`
`burn(C) :- supersedes_closure(C, O), burn_reason(O).` An `O` of the closure is
the second argument of a `supersedes` fact, so the search over the facts is
exact (`burn_iff`). -/
def burn (c : Atom) : Bool :=
  burn_reason db c || db.supersedes.any fun e => supersedes_closure db c e.2 && burn_reason db e.2

/-- `proof(C, _)` unifies with the predicate. -/
def Pred.proofOf (c : Atom) : Pred → Bool
  | .proof c' _ => c' == c
  | _ => false

/-- `waive(C, _, _)` unifies with the predicate. -/
def Pred.waiveOf (c : Atom) : Pred → Bool
  | .waive c' _ => c' == c
  | _ => false

/-- `burn_proved(C) :- attest(A, lean_proof, _, proof(C, _), script, _), not proof_changed(A).` -/
def burn_proved (c : Atom) : Bool :=
  db.attest.any fun a => a.type == .lean_proof && a.pred.proofOf c && a.by_ == .script &&
    !(db.proof_changed.any fun x => x == a.id)

/-- `burn_waived(C) :- attest(W, waiver, _, waive(C, _, _), human, _), not waiver_lapsed(W).` -/
def burn_waived (c : Atom) : Bool :=
  db.attest.any fun a => a.type == .waiver && a.pred.waiveOf c && a.by_ == .human &&
    !(db.waiver_lapsed.any fun x => x == a.id)

/-- `burn_open(C) :- burn(C), current(C), not burn_proved(C), not burn_waived(C).` -/
def burn_open (c : Atom) : Bool :=
  burn db c && current db c && !burn_proved db c && !burn_waived db c

/-- `any_burn_open :- burn_open(_).` `burn_open(C)` needs `current(C)`, so it
needs `claim(C, _, _)`. The search over the claim ids is exact
(`any_burn_open_iff`). -/
def any_burn_open : Bool := db.claim.any fun x => burn_open db x.1

/-- `done :- not any_under, not any_over, not any_to_ask, not any_burn_open,
not any_supersede_cycle.` -/
def done : Bool :=
  !any_under db && !any_over db && !any_to_ask db && !any_burn_open db &&
    !any_supersede_cycle db

/-- `conforms(C) :- conformance(K), check(K, C), passed(K).` -/
def conforms (c : Atom) : Bool :=
  db.conformance.any fun k => db.check.any (fun x => x.1 == k && x.2 == c) && passed db k

/-! ## The derived facts (`derived_items/3` in the CLI) -/

/-- What the CLI reads from the disk and the clock. -/
structure Disk where
  /-- `proof_state(Dir, A, P, ok)`: the log `runs/proof-A.log` exists, its header
  names the claim and the digest of the attestation, and each file in the log
  still has its sha256. -/
  proofOk : Attest → Bool
  /-- `utc_now/1`, as a year. -/
  now : Nat
  /-- `is_time/1` on the due time of a waiver (D10 follow-up). -/
  validTime : Nat → Bool

/-- `derived_items/3`:
* `proof_changed(A)` for each `attest(A, lean_proof, _, P, _, _)` in kb.pl with
  `\+ proof_state(Dir, A, P, ok)`;
* `waiver_lapsed(W)` for each `attest(W, waiver, _, waive(_, Due, _), _, _)` in
  kb.pl with `Due @< Now`, or with a `Due` that is not a valid time.
Any writer. The `ground(A)` guards hold, because atoms are `Nat`. The model has
no waiver of another shape (`Pred.other` is not a waiver). -/
def derive (disk : Disk) (db : DB) : DB :=
  { db with
    proof_changed := (db.attest.filter fun a => a.type == .lean_proof && !disk.proofOk a).map (·.id)
    waiver_lapsed := db.attest.filterMap fun a =>
      if a.type == .waiver then
        match a.pred with
        | .waive _ due => if !disk.validTime due || due < disk.now then some a.id else none
        | _ => none
      else none }

/-! ## Fidelity lemmas: the finite searches are exact -/

theorem current_claim {db : DB} {c : Atom} (h : current db c = true) :
    ∃ x ∈ db.claim, x.1 = c := by
  simp only [current, Bool.and_eq_true, List.any_eq_true, beq_iff_eq] at h
  exact h.1

theorem any_burn_open_iff : any_burn_open db = true ↔ ∃ c, burn_open db c = true := by
  constructor
  · intro h
    simp only [any_burn_open, List.any_eq_true] at h
    obtain ⟨x, _, hx⟩ := h
    exact ⟨_, hx⟩
  · rintro ⟨c, hc⟩
    have hcur : current db c = true := by
      simp only [burn_open, Bool.and_eq_true] at hc; exact hc.1.1.2
    obtain ⟨x, hx, rfl⟩ := current_claim hcur
    simp only [any_burn_open, List.any_eq_true]
    exact ⟨x, hx, hc⟩

theorem any_under_iff : any_under db = true ↔ ∃ c, under db c = true := by
  constructor
  · intro h
    simp only [any_under, List.any_eq_true] at h
    obtain ⟨x, _, hx⟩ := h
    exact ⟨_, hx⟩
  · rintro ⟨c, hc⟩
    have hcur : current db c = true := by
      simp only [under, Bool.and_eq_true] at hc; exact hc.1
    obtain ⟨x, hx, rfl⟩ := current_claim hcur
    simp only [any_under, List.any_eq_true]
    exact ⟨x, hx, hc⟩

theorem any_over_iff : any_over db = true ↔ ∃ x, over db x = true := by
  constructor
  · intro h
    simp only [any_over, List.any_eq_true] at h
    obtain ⟨x, _, hx⟩ := h
    exact ⟨_, hx⟩
  · rintro ⟨x, hx⟩
    have hc := hx
    simp only [over, Bool.and_eq_true, List.any_eq_true, beq_iff_eq] at hc
    obtain ⟨⟨y, hy, rfl⟩, _⟩ := hc
    simp only [any_over, List.any_eq_true]
    exact ⟨y, hy, hx⟩

theorem any_to_ask_iff : any_to_ask db = true ↔ ∃ q, to_ask db q = true := by
  constructor
  · intro h
    simp only [any_to_ask, List.any_eq_true] at h
    obtain ⟨x, _, hx⟩ := h
    exact ⟨_, hx⟩
  · rintro ⟨q, hq⟩
    have hq' := hq
    simp only [to_ask, Bool.or_eq_true, Bool.and_eq_true, List.any_eq_true,
      beq_iff_eq] at hq'
    simp only [any_to_ask, List.any_eq_true]
    rcases hq' with ⟨x, hx, ⟨⟨rfl, _⟩, _⟩, _⟩ | ⟨x, hx, ⟨⟨rfl, _⟩, _⟩, _⟩
    · exact ⟨x, hx, hq⟩
    · exact ⟨x, hx, hq⟩

/-- `derive` adds `proof_changed(A)` exactly for the `lean_proof` attestations
whose disk state is not `ok`. -/
theorem derive_proof_changed (disk : Disk) (a : Atom) :
    a ∈ (derive disk db).proof_changed ↔
      ∃ x ∈ db.attest, x.type = .lean_proof ∧ disk.proofOk x = false ∧ x.id = a := by
  simp [derive, and_assoc]

/-- `derive` adds `waiver_lapsed(W)` exactly for the `waiver` attestations whose
due time is before now or not a valid time. -/
theorem derive_waiver_lapsed (disk : Disk) (w : Atom) :
    w ∈ (derive disk db).waiver_lapsed ↔
      ∃ x ∈ db.attest, x.type = .waiver ∧ x.id = w ∧
        ∃ c due, x.pred = .waive c due ∧ (disk.validTime due = false ∨ due < disk.now) := by
  simp only [derive, List.mem_filterMap]
  constructor
  · rintro ⟨x, hx, h⟩
    refine ⟨x, hx, ?_⟩
    by_cases ht : x.type = .waiver
    · simp only [ht, beq_self_eq_true, ite_true] at h
      split at h
      · rename_i c due hp
        by_cases hd : (!disk.validTime due || decide (due < disk.now)) = true
        · simp only [Bool.or_eq_true, Bool.not_eq_true', decide_eq_true_eq] at hd
          refine ⟨ht, ?_, c, due, hp, hd⟩
          rcases hd with hd | hd <;> simp_all
        · simp only [Bool.or_eq_true, Bool.not_eq_true', decide_eq_true_eq, not_or] at hd
          simp_all
      · simp at h
    · simp [ht] at h
  · rintro ⟨x, hx, ht, rfl, c, due, hp, hd⟩
    refine ⟨x, hx, ?_⟩
    rcases hd with hd | hd <;> simp [ht, hp, hd]

/-- The last step of a path ends at the second argument of a fact. -/
theorem rreach_target {E : List (Atom × Atom)} {b c : Atom} (h : rreach E b c = true) :
    b = c ∨ ∃ e ∈ E, e.2 = c := by
  induction E generalizing b with
  | nil => simp only [rreach, beq_iff_eq] at h; exact Or.inl h
  | cons e E ih =>
    simp only [rreach, Bool.or_eq_true, Bool.and_eq_true] at h
    rcases h with h | ⟨_, h2⟩
    · rcases ih h with h | ⟨e', he', h'⟩
      · exact Or.inl h
      · exact Or.inr ⟨e', List.mem_cons_of_mem e he', h'⟩
    · rcases ih h2 with h | ⟨e', he', h'⟩
      · exact Or.inr ⟨e, List.mem_cons_self .., h⟩
      · exact Or.inr ⟨e', List.mem_cons_of_mem e he', h'⟩

/-- A claim that `reach` reaches is the second argument of a fact. -/
theorem reach_target {E : List (Atom × Atom)} {a c : Atom} (h : reach E a c = true) :
    ∃ e ∈ E, e.2 = c := by
  simp only [reach, List.any_eq_true, Bool.and_eq_true] at h
  obtain ⟨e, he, _, hr⟩ := h
  rcases rreach_target hr with rfl | h
  · exact ⟨e, he, rfl⟩
  · exact h

/-- A claim that `reach` starts from is the first argument of a fact. -/
theorem reach_source {E : List (Atom × Atom)} {a c : Atom} (h : reach E a c = true) :
    ∃ e ∈ E, e.1 = a := by
  simp only [reach, List.any_eq_true, Bool.and_eq_true, beq_iff_eq] at h
  obtain ⟨e, he, h1, _⟩ := h
  exact ⟨e, he, h1⟩

theorem any_supersede_cycle_iff :
    any_supersede_cycle db = true ↔ ∃ c, supersede_cycle db c = true := by
  constructor
  · intro h
    simp only [any_supersede_cycle, List.any_eq_true] at h
    obtain ⟨e, _, he⟩ := h
    exact ⟨_, he⟩
  · rintro ⟨c, hc⟩
    obtain ⟨e, he, rfl⟩ := reach_source hc
    simp only [any_supersede_cycle, List.any_eq_true]
    exact ⟨e, he, hc⟩

/-- `burn/1` searches the `supersedes` facts for the claim `O`. The search is exact. -/
theorem burn_iff (c : Atom) :
    burn db c = true ↔
      burn_reason db c = true ∨ ∃ o, supersedes_closure db c o = true ∧ burn_reason db o = true := by
  simp only [burn, Bool.or_eq_true, List.any_eq_true, Bool.and_eq_true]
  constructor
  · rintro (h | ⟨e, _, h1, h2⟩)
    · exact Or.inl h
    · exact Or.inr ⟨e.2, h1, h2⟩
  · rintro (h | ⟨o, h1, h2⟩)
    · exact Or.inl h
    · obtain ⟨e, he, rfl⟩ := reach_target h1
      exact Or.inr ⟨e, he, h1, h2⟩

end Impl

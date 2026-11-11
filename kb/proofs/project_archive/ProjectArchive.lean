/-!
# The archive set of `orbit-kb project archive` (ticket T23 c9, CONTRACT D27 R9)

A model of `archive_set/4` and `archive_fix/3` in `kb/bin/orbit-kb`.
The model is not the code: PT9 of `kb/tests/test_project_kb.sh` tests the code, with the
cases of `#eval table` below.

Abstractions (what the model leaves out):
* An id is a natural number. The candidates are the superseded decisions, definitions and rules
  whose superseding fact was decided before DATE (the code computes them from kb.pl).
* `pinned` is the set of ids that a claim of an open spec KB pins (the code reads the spec KBs
  and asks `done` of each). What "pinned" covers (T34 c2): the pins of the spec KBs that the
  code finds, and only those. The code finds a spec KB in two ways: the walk of the root (the
  parent directory of the project KB, or `--root DIR`), and the registry `spec_kbs.txt` of the
  project KB, which `orbit-kb add` writes when a spec KB records `project_kb/1` or `pins/4`.
  The proof does not cover the walk: it takes `pinned` as given. A spec KB that neither the walk
  nor the registry finds (one that was copied in, or whose pins were written by hand outside
  the root) can pin an id that archive removes.
* `deps` holds the pairs `(y, x)` of the `depends_on(y, x)` facts: y depends on x.
* The code removes the facts of the ids in the set. The claims c9 are about the set.
* T34 c1: a fact of kb.pl is modelled by its own id (if it has one) and the ids that its ref
  arguments name. The code removes each fact that names an id of the removed set R; R starts
  as the archived ids, and the id of each removed fact joins it, until a pass adds nothing
  (`archive_removed/4`; divergence a21: an attestation about d1 has an id, and its actor
  record names that id). The model leaves out the lint check that the code runs on the result
  before it writes. Termination of the loop is not modelled: the code stops when a pass adds
  no id, and that stop condition is `closed` here (`stable_closed`).

The claim (c9): a pinned fact, or a fact that a kept fact rests on, is never removed.
`rests_on` is the transitive closure of `depends_on` (D27 R3).
The claim (T34 c1): the archive leaves no dangling reference: each id that a kept fact names
is still defined by a kept fact. The first model (one step, a defining fact names only its id)
did not cover an attestation about d1 named by its actor record (divergence a21): the defining
fact of a90 names d1 too. This model closes over the ids of removed facts.
-/
namespace ProjectArchive

/-- One pass of `archive_fix/3`: drop each id that a fact outside the set depends on. -/
def step (deps : List (Nat × Nat)) (A : List Nat) : List Nat :=
  A.filter (fun x => !(deps.any (fun d => d.2 == x && !(A.contains d.1))))

/-- `archive_fix/3`: repeat `step` until nothing changes. A pass that changes the set makes it
shorter (it is a filter), so the code's test `A1 == A0` is the length test here. -/
def fix (deps : List (Nat × Nat)) (A : List Nat) : List Nat :=
  if (step deps A).length < A.length then fix deps (step deps A) else A
termination_by A.length

/-- `archive_set/4`: the candidates that no open spec KB pins, then `fix`. -/
def archiveSet (cand pinned : List Nat) (deps : List (Nat × Nat)) : List Nat :=
  fix deps (cand.filter (fun x => !(pinned.contains x)))

/-- `rests_on(y, x)`: y depends on x through one or more `depends_on` facts. -/
inductive RestsOn (deps : List (Nat × Nat)) : Nat → Nat → Prop
  | base {y x : Nat} : (y, x) ∈ deps → RestsOn deps y x
  | trans {y z x : Nat} : (y, z) ∈ deps → RestsOn deps z x → RestsOn deps y x

/-- The cases of PT9 (d1 = 1, d3 = 3, ...): 3 is pinned; 7 (kept) depends on 5;
14 (kept) depends on 13, which depends on 12; 1 and 10 have nothing that keeps them. -/
def table : List Nat :=
  archiveSet [1, 3, 5, 10, 12, 13] [3] [(7, 5), (14, 13), (13, 12)]

#eval table  -- [1, 10]

theorem step_sub {deps A x} (h : x ∈ step deps A) : x ∈ A :=
  (List.mem_filter.mp h).1

theorem fix_sub (deps : List (Nat × Nat)) : ∀ (A : List Nat) (x : Nat), x ∈ fix deps A → x ∈ A := by
  intro A
  induction A using fix.induct (deps := deps) with
  | case1 A hlt ih =>
    intro x hx
    rw [fix] at hx; simp only [hlt, ↓reduceIte] at hx
    exact step_sub (ih x hx)
  | case2 A hlt =>
    intro x hx
    rw [fix] at hx; simp only [hlt, ↓reduceIte] at hx
    exact hx

/-- At the end of `fix`, no fact outside the set depends on a fact in the set. -/
theorem fix_closed (deps : List (Nat × Nat)) :
    ∀ (A : List Nat) (x y : Nat), x ∈ fix deps A → (y, x) ∈ deps → y ∈ fix deps A := by
  intro A
  induction A using fix.induct (deps := deps) with
  | case1 A hlt ih =>
    intro x y hx hd
    rw [fix] at hx ⊢; simp only [hlt, ↓reduceIte] at hx ⊢
    exact ih x y hx hd
  | case2 A hlt =>
    intro x y hx hd
    rw [fix] at hx ⊢; simp only [hlt, ↓reduceIte] at hx ⊢
    have hle : (step deps A).length ≤ A.length := List.length_filter_le _ _
    have heq : (step deps A).length = A.length := by omega
    have hall := (List.length_filter_eq_length_iff).mp heq x hx
    by_cases hy : y ∈ A
    · exact hy
    exfalso
    simp at hall
    exact hy (hall y x hd rfl)

/-- Every fact that rests on a fact of the set is in the set too. -/
theorem fix_rests (deps : List (Nat × Nat)) (A : List Nat) :
    ∀ (y x : Nat), RestsOn deps y x → x ∈ fix deps A → y ∈ fix deps A := by
  intro y x h
  induction h with
  | base hd => exact fun hx => fix_closed deps A _ _ hx hd
  | trans hd _ ih => exact fun hx => fix_closed deps A _ _ (ih hx) hd

/-- c9: `project archive` never removes a pinned fact, nor a fact that a kept fact rests on,
and it removes only candidates (superseded before DATE). -/
theorem archive_never_removes (cand pinned : List Nat) (deps : List (Nat × Nat)) (x : Nat) :
    (x ∈ pinned → x ∉ archiveSet cand pinned deps) ∧
    (∀ y, RestsOn deps y x → y ∉ archiveSet cand pinned deps → x ∉ archiveSet cand pinned deps) ∧
    (x ∈ archiveSet cand pinned deps → x ∈ cand) := by
  refine ⟨?_, ?_, ?_⟩
  · intro hp hx
    have h0 := fix_sub deps _ x hx
    simp [List.mem_filter] at h0
    exact h0.2 hp
  · intro y hr hy hx
    exact hy (fix_rests deps _ y x hr hx)
  · intro hx
    exact (List.mem_filter.mp (fix_sub deps _ x hx)).1

/-- T34 c1: a fact of kb.pl: its own id (an attestation, a check, a decision) and the ids that
its ref arguments name. -/
structure Fact where
  id : Option Nat
  refs : List Nat
deriving Repr

/-- The fact names an id of R: its own id, or a ref. -/
def namesAny (R : List Nat) (f : Fact) : Bool :=
  f.id.any (fun i => R.contains i) || f.refs.any (fun x => R.contains x)

/-- The facts that stay: those that name no id of R (`archive_removed/4`). -/
def keep (R : List Nat) (facts : List Fact) : List Fact :=
  facts.filter (fun f => !namesAny R f)

/-- The ids of the facts that a pass removes. -/
def stepIds (R : List Nat) (facts : List Fact) : List Nat :=
  facts.filterMap (fun f => if namesAny R f then f.id else none)

/-- One pass of the loop of `archive_removed/4`. -/
def closeStep (R : List Nat) (facts : List Fact) : List Nat :=
  R ++ (stepIds R facts).filter (fun i => !R.contains i)

/-- The loop, with a bound on the passes (the code has none: it stops when a pass adds no id). -/
def closeN : Nat → List Nat → List Fact → List Nat
  | 0, R, _ => R
  | n + 1, R, facts => if (closeStep R facts).length == R.length then R else closeN n (closeStep R facts) facts

/-- R is closed: the id of every fact that names an id of R is in R. -/
def Closed (R : List Nat) (facts : List Fact) : Prop :=
  ∀ f ∈ facts, namesAny R f = true → ∀ i, f.id = some i → i ∈ R

/- The PF7 case: d1 = 1 archived; decision d1 {id 1}; supersedes(d2, d1) {refs 2, 1};
attestation a90 = 90 about d1 {id 90, refs 1}; its actor record {refs 90}; seen sn1 = 50
{id 50, refs 90}; ack {refs 50}; decision d3 = 3, attestation a91 = 91 about it, and so on. -/
def pf7 : List Fact :=
  [⟨some 1, []⟩, ⟨some 2, []⟩, ⟨none, [2, 1]⟩, ⟨some 90, [1]⟩, ⟨none, [90]⟩, ⟨some 50, [90]⟩,
   ⟨none, [50]⟩, ⟨some 3, []⟩, ⟨some 91, [3]⟩, ⟨none, [91]⟩, ⟨some 51, [91]⟩, ⟨none, [51]⟩]

#eval closeN 20 [1] pf7                         -- [1, 90, 50]
#eval keep (closeN 20 [1] pf7) pf7 |>.length    -- 6

/-- The stop condition of the loop (a pass adds no id) makes R closed. -/
theorem stable_closed (R : List Nat) (facts : List Fact)
    (hs : ∀ i ∈ stepIds R facts, i ∈ R) : Closed R facts := by
  intro f hf hn i hi
  apply hs
  simp only [stepIds, List.mem_filterMap]
  exact ⟨f, hf, by simp [hn, hi]⟩

theorem keep_spec {R : List Nat} {facts : List Fact} {f : Fact} :
    f ∈ keep R facts ↔ f ∈ facts ∧ namesAny R f = false := by
  simp [keep, List.mem_filter]

/-- T34 c1: no dangling reference after any archive. Before the archive each id that a ref
names has a defining fact (lint has no E4). R holds the archived ids A and is closed. Then each
id that a kept fact names has a kept defining fact, and no kept fact names an archived id. -/
theorem archive_no_dangling (A R : List Nat) (facts : List Fact)
    (hA : ∀ x ∈ A, x ∈ R) (hc : Closed R facts)
    (hdef : ∀ f ∈ facts, ∀ x ∈ f.refs, ∃ d ∈ facts, d.id = some x) :
    (∀ f ∈ keep R facts, ∀ x ∈ f.refs, ∃ d ∈ keep R facts, d.id = some x) ∧
    (∀ f ∈ keep R facts, ∀ x ∈ A, f.id ≠ some x ∧ x ∉ f.refs) := by
  constructor
  · intro f hf x hx
    obtain ⟨hfo, hfn⟩ := keep_spec.mp hf
    have hxR : x ∉ R := by
      intro hxR
      have : namesAny R f = true := by
        simp only [namesAny, Bool.or_eq_true, List.any_eq_true]
        exact Or.inr ⟨x, hx, by simpa using hxR⟩
      rw [hfn] at this; exact Bool.false_ne_true this
    obtain ⟨d, hd, hdid⟩ := hdef f hfo x hx
    refine ⟨d, keep_spec.mpr ⟨hd, ?_⟩, hdid⟩
    cases hdn : namesAny R d with
    | false => rfl
    | true => exact absurd (hc d hd hdn x hdid) hxR
  · intro f hf x hxA
    obtain ⟨_, hfn⟩ := keep_spec.mp hf
    have hxR := hA x hxA
    constructor
    · intro hid
      have : namesAny R f = true := by
        simp only [namesAny, Bool.or_eq_true]
        exact Or.inl (by simp [hid, hxR])
      rw [hfn] at this; exact Bool.false_ne_true this
    · intro hx
      have : namesAny R f = true := by
        simp only [namesAny, Bool.or_eq_true, List.any_eq_true]
        exact Or.inr ⟨x, hx, by simpa using hxR⟩
      rw [hfn] at this; exact Bool.false_ne_true this

end ProjectArchive

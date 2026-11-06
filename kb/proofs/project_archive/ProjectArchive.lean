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
* T34 c1: a fact of kb.pl is modelled by the list of the ids it names (its id, and each ref
  argument). The code removes each fact that names an archived id (`archiveKeep`). The model
  leaves out the lint check that the code runs on the result before it writes.

The claim (c9): a pinned fact, or a fact that a kept fact rests on, is never removed.
`rests_on` is the transitive closure of `depends_on` (D27 R3).
The claim (T34 c1): the archive leaves no dangling reference: each id that a kept fact names
is still defined by a kept fact.
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

/-- T34 c1: the facts that stay. A fact is the list of the ids that it names; the code
removes each fact that names an archived id (`archive_names/2`, `archive_ref_names/3`). -/
def archiveKeep (A : List Nat) (facts : List (List Nat)) : List (List Nat) :=
  facts.filter (fun f => !(f.any (fun x => A.contains x)))

/- The PT9 / PF1 case: d1 = 1 is archived; `[1]` is decision d1, `[1, 2]` is supersedes(d2, d1),
`[1]` is also note(d1); `[3]` is decision d3 and `[3]` a note of it; `[2]` is decision d2. -/
#eval archiveKeep [1] [[1], [2], [1, 2], [1], [3], [3]]  -- [[2], [3], [3]]

/-- A kept fact names no archived id. -/
theorem keep_names_none (A : List Nat) (facts : List (List Nat)) (f : List Nat) (x : Nat)
    (hf : f ∈ archiveKeep A facts) (hx : x ∈ f) : x ∉ A := by
  intro hA
  have h := (List.mem_filter.mp hf).2
  simp only [Bool.not_eq_true', List.any_eq_false] at h
  exact absurd (List.contains_iff_mem.mpr hA) (by simpa using h x hx)

/-- T34 c1: no dangling reference after any archive. Before the archive each id that a fact
names has its defining fact `[x]` (it names only x) in kb.pl (lint has no E4). Then each id
that a kept fact names has its defining fact kept too. -/
theorem archive_no_dangling (A : List Nat) (facts : List (List Nat))
    (hdef : ∀ f ∈ facts, ∀ x ∈ f, [x] ∈ facts) :
    ∀ f ∈ archiveKeep A facts, ∀ x ∈ f, [x] ∈ archiveKeep A facts := by
  intro f hf x hx
  have hxA := keep_names_none A facts f x hf hx
  have hfo : f ∈ facts := (List.mem_filter.mp hf).1
  refine List.mem_filter.mpr ⟨hdef f hfo x hx, ?_⟩
  simp only [List.any_cons, List.any_nil, Bool.or_false, Bool.not_eq_true']
  simpa using hxA

end ProjectArchive

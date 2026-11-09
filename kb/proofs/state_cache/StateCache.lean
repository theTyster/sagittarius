/-!
# The saved-state fast start of `orbit-kb` under deleters (cache-race ticket, claim c5)

A model of `orbit_boot_/0`, `orbit_state_link/2`, `orbit_state_valid/2`, `drop_own_link/0` and
the private-link rule of `prune_states/2` in `kb/bin/orbit-kb`. It follows model m3 of the
discovery KB (`model/CachePrivate.tla`), with these differences: any number of calls (`P` is
any type), any number of steps, and an environment that is stronger than m3's deleter.

What a call does (one call is one process `p`):
* `link p`: hard-link the shared `STATE` to the private name of `p`. If `STATE` is missing,
  the link fails and the call loads the script (`ranScript`).
* `failLink p`: the link fails for another reason (no hard links, a name clash): the call
  loads the script.
* `readOk p`: read `STATE.ok`.
* `check p`: the call is valid if `STATE.ok` was there and describes the bytes of the private
  link (size and SHA-1). Then it goes on to exec; else it deletes its link and loads the script.
* `exec p`: `swipl -x` on the private link. A missing file aborts ("Could not open resource
  database"). Bytes other than those checked are `ranOther`.

The environment (`env sh ok`) sets the shared `STATE` and `STATE.ok` to ANY values at ANY
step: `drop_bad`, the 60 s age rule, `prune_states` of an old key, a builder that renames
new bytes over `STATE`, a builder that writes `.ok`, even a writer of a wrong `.ok`. The
other calls are part of the environment too: everything they do to shared names is an
`env` step. The only file of a call that the environment deletes is the private link of a
call that has ended (`dropLink`): `prune_states/2` deletes a private link only when its
process is gone, and the started state deletes its own link (`drop_own_link/0`).

Abstractions (what the model leaves out):
* Bytes are a number. A file never changes in place: builders write a temp file and rename
  it, so a new state is a new file (a new inode); a hard link keeps the old bytes.
* The size and SHA-1 test is equality of bytes (no SHA-1 collision).
* A state whose bytes match `STATE.ok` was built from this script (the name of the state is
  a digest of the script text), so starting it gives the result of the no-cache call. Loading
  the script is the no-cache call. So `ranState` and `ranScript` both give that result.
* Liveness of a process is read correctly (`/proc/PID` on Linux, `kill -0` elsewhere).
* Not modelled: a write into a state file in place, a crash of the exec itself, a pid
  namespace in which another process has the same pid.

`execShared = true` is the mutation: exec the shared name, as the code did before the fix.
-/
namespace StateCache

abbrev Bytes := Nat

inductive PC | start | readOk | check | exec | ranState | ranScript | ranOther | aborted
  deriving DecidableEq, Repr

/-- A call has ended (its process is gone or no longer needs its link). -/
def PC.ended : PC → Bool
  | .ranState | .ranScript | .ranOther | .aborted => true
  | _ => false

structure Sys (P : Type) where
  shared : Option Bytes          -- the shared name STATE (none: missing)
  ok     : Option Bytes          -- STATE.ok: the bytes it describes (none: missing)
  pc     : P → PC
  priv   : P → Option Bytes      -- the private link of each call (none: no link)
  seen   : P → Option Bytes      -- the STATE.ok that each call read

def upd {P α : Type} [DecidableEq P] (f : P → α) (p : P) (v : α) : P → α :=
  fun q => if q = p then v else f q

inductive Act (P : Type)
  | env (sh ok : Option Bytes)
  | dropLink (q : P)
  | link (p : P)
  | failLink (p : P)
  | readOk (p : P)
  | check (p : P)
  | exec (p : P)

variable {P : Type} [DecidableEq P]

def init (sh ok : Option Bytes) : Sys P :=
  { shared := sh, ok := ok, pc := fun _ => .start, priv := fun _ => none, seen := fun _ => none }

/-- The bytes of the file that `check` validated, if it did: `.ok` was read and matches. -/
def validated (seen priv : Option Bytes) : Bool :=
  match seen, priv with
  | some a, some b => a == b
  | _, _ => false

/-- One step; `none` if the step is not enabled. -/
def apply (execShared : Bool) : Act P → Sys P → Option (Sys P)
  | .env sh ok, s => some { s with shared := sh, ok := ok }
  | .dropLink q, s => if (s.pc q).ended then some { s with priv := upd s.priv q none } else none
  | .link p, s =>
      if s.pc p = .start then
        match s.shared with
        | none => some { s with pc := upd s.pc p .ranScript }
        | some b => some { s with pc := upd s.pc p .readOk, priv := upd s.priv p (some b) }
      else none
  | .failLink p, s => if s.pc p = .start then some { s with pc := upd s.pc p .ranScript } else none
  | .readOk p, s =>
      if s.pc p = .readOk then some { s with pc := upd s.pc p .check, seen := upd s.seen p s.ok }
      else none
  | .check p, s =>
      if s.pc p = .check then
        if validated (s.seen p) (s.priv p) then some { s with pc := upd s.pc p .exec }
        else some { s with pc := upd s.pc p .ranScript, priv := upd s.priv p none }
      else none
  | .exec p, s =>
      if s.pc p = .exec then
        let f := if execShared then s.shared else s.priv p
        match f with
        | none => some { s with pc := upd s.pc p .aborted }
        | some b => some { s with pc := upd s.pc p (if some b = s.seen p then .ranState else .ranOther) }
      else none

/-- The states that some run reaches, from any start. -/
inductive Reach (execShared : Bool) : Sys P → Prop
  | init (sh ok : Option Bytes) : Reach execShared (init sh ok)
  | step {s t : Sys P} (a : Act P) : Reach execShared s → apply execShared a s = some t →
      Reach execShared t

/-- A call gives the no-cache result: it is not aborted and did not start unchecked bytes. -/
def good (c : PC) : Prop := c ≠ .aborted ∧ c ≠ .ranOther

/-- The invariant: a call about to exec holds a private link whose bytes it validated. -/
def Inv (s : Sys P) : Prop :=
  ∀ p, good (s.pc p) ∧ (s.pc p = .exec → ∃ b, s.priv p = some b ∧ s.seen p = some b)

theorem validated_eq {a b : Option Bytes} (h : validated a b = true) :
    ∃ x, b = some x ∧ a = some x := by
  cases a <;> cases b <;> simp [validated] at h ⊢
  subst h; rfl

omit [DecidableEq P] in
theorem inv_init (sh ok : Option Bytes) : Inv (init (P := P) sh ok) := by
  intro p; simp [init, good]

theorem inv_step {s t : Sys P} (a : Act P) (hs : Inv s) (h : apply false a s = some t) :
    Inv t := by
  cases a with
  | env sh ok =>
      simp [apply] at h; subst h; intro q; exact hs q
  | dropLink q =>
      simp only [apply] at h
      split at h
      · rename_i hend
        simp at h; subst h; intro r
        refine ⟨(hs r).1, fun hr => ?_⟩
        by_cases hq : r = q
        · subst hq; rw [hr] at hend; simp [PC.ended] at hend
        · simpa [upd, hq] using (hs r).2 hr
      · simp at h
  | link p =>
      simp only [apply] at h
      split at h
      · rename_i hp
        split at h <;> (simp at h; subst h; intro q; by_cases hq : q = p)
        · subst hq; simp [upd, good]
        · simpa [upd, hq] using hs q
        · subst hq; simp [upd, good]
        · simpa [upd, hq] using hs q
      · simp at h
  | failLink p =>
      simp only [apply] at h
      split at h
      · simp at h; subst h; intro q; by_cases hq : q = p
        · subst hq; simp [upd, good]
        · simpa [upd, hq] using hs q
      · simp at h
  | readOk p =>
      simp only [apply] at h
      split at h
      · simp at h; subst h; intro q; by_cases hq : q = p
        · subst hq; simp [upd, good]
        · simpa [upd, hq] using hs q
      · simp at h
  | check p =>
      simp only [apply] at h
      split at h
      · split at h
        · rename_i hv
          simp at h; subst h; intro q; by_cases hq : q = p
          · subst hq; simp [upd, good]; exact validated_eq hv
          · simpa [upd, hq] using hs q
        · simp at h; subst h; intro q; by_cases hq : q = p
          · subst hq; simp [upd, good]
          · simpa [upd, hq] using hs q
      · simp at h
  | exec p =>
      simp only [apply] at h
      split at h
      · rename_i hp
        obtain ⟨b, hb, hseen⟩ := (hs p).2 hp
        simp only [Bool.false_eq_true, ↓reduceIte, hb] at h
        simp at h; subst h; intro q; by_cases hq : q = p
        · subst hq; simp [upd, good, hseen]
        · simpa [upd, hq] using hs q
      · simp at h

theorem inv_reach {s : Sys P} (h : Reach false s) : Inv s := by
  induction h with
  | init sh ok => exact inv_init sh ok
  | step a _ hstep ih => exact inv_step a ih hstep

/-- **c5 on the model.** With the private link, in every reachable state of any number of
calls, under any deleter, renamer, or `.ok` writer of the shared names: no call aborts, and
no call starts bytes other than those it validated against `STATE.ok`. So each call ends
with the state it checked or with the script, as the no-cache call does. -/
theorem no_abort_exec_validated {s : Sys P} (h : Reach false s) (p : P) :
    s.pc p ≠ .aborted ∧ s.pc p ≠ .ranOther :=
  (inv_reach h p).1

/-- Every exec step of the fixed design opens a file that exists and holds the validated bytes. -/
theorem exec_opens_validated {s : Sys P} (h : Reach false s) (p : P) (hp : s.pc p = .exec) :
    ∃ b, s.priv p = some b ∧ s.seen p = some b :=
  (inv_reach h p).2 hp

/-! ## The mutation: exec the shared name (the code before the fix) -/

/-- Run a schedule of steps; stop at the first step that is not enabled. -/
def run (execShared : Bool) : List (Act P) → Sys P → Option (Sys P)
  | [], s => some s
  | a :: as, s => (apply execShared a s).bind (run execShared as)

theorem run_reach {e : Bool} : ∀ (as : List (Act P)) {s t : Sys P},
    Reach e s → run e as s = some t → Reach e t
  | [], s, t, hs, h => by simp [run] at h; subst h; exact hs
  | a :: as, s, t, hs, h => by
      simp only [run, Option.bind_eq_some_iff] at h
      obtain ⟨u, hu, hrun⟩ := h
      exact run_reach as (Reach.step a hs hu) hrun

/-- The 60 s / prune / drop_bad path with one call: STATE is valid, the call checks it,
a deleter removes STATE, the call execs. -/
def deleteBeforeExec : List (Act Unit) :=
  [.link (), .readOk (), .check (), .env none none, .exec ()]

/-- The prune path: the shared STATE is replaced by a new key's state (here: deleted, and
a new state with other bytes appears) between the check and the exec. -/
def renameBeforeExec : List (Act Unit) :=
  [.link (), .readOk (), .check (), .env (some 2) (some 2), .exec ()]

/-- A rename over STATE between the link and the read of `.ok`: the new `.ok` does not
describe the linked bytes, so the call loads the script. -/
def renameBeforeReadOk : List (Act Unit) :=
  [.link (), .env (some 2) (some 2), .readOk (), .check ()]

def outcome (e : Bool) (as : List (Act Unit)) : Option PC :=
  (run e as (init (some 1) (some 1))).map (fun s => s.pc ())

-- The table: (schedule, fixed design, mutation).
#eval [("delete before exec", outcome false deleteBeforeExec, outcome true deleteBeforeExec),
       ("rename before exec", outcome false renameBeforeExec, outcome true renameBeforeExec),
       ("rename before read of .ok", outcome false renameBeforeReadOk, outcome true renameBeforeReadOk)]

/-- The mutation is not safe: a run of one call aborts. So the theorem above depends on the
private link, not on the model being too weak to abort. -/
theorem mutant_aborts : ∃ s : Sys Unit, Reach true s ∧ s.pc () = .aborted := by
  refine ⟨_, run_reach deleteBeforeExec (Reach.init (some 1) (some 1)) rfl, rfl⟩

/-- The mutation also starts bytes that it did not check. -/
theorem mutant_runs_other : ∃ s : Sys Unit, Reach true s ∧ s.pc () = .ranOther := by
  refine ⟨_, run_reach renameBeforeExec (Reach.init (some 1) (some 1)) rfl, rfl⟩

end StateCache

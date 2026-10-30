import BurnModel.Impl

/-!
# Conformance generator

`conform gen OUT` writes KBs into `OUT`. Each KB directory holds:
* `kb.pl`, rendered from an `Impl.DB`, with `'@DIGEST:pN@'` in place of the
  digest of each proof;
* `runs/R-kK.log` for each test result, as `add_result` in the test suite writes it;
* `proofs.txt`: one line `pN cC MODE` per `lean_proof`. MODE is `ok`, `changed`
  (edit the file after the log), or `nolog` (no log). `conform_run.py`
  makes the Lean file and the log, as `add_proof` in the test suite does;
* `expect.txt`: what the compiled implementation model answers. The lines are
  `done`, `open`, `changed` (`proof_changed`), `lapsed` (`waiver_lapsed`), and one
  line per mutant (`MA`, `MB`, `MC`, `MI`, `MY`, `MZ`).

Three sets:
* `e*`: exhaustive over one burning claim (see `exhaustive`), 2160 KBs.
* `r*`: random over one to three claims, with a fixed seed, 600 KBs.
* `z*`: KBs with no claim (D17), 2 KBs.

The random generator is xorshift64 with a fixed seed. It does not depend on the
Lean version.
-/

open Impl

deriving instance Inhabited for Impl.Writer
deriving instance Inhabited for Impl.Verdict
deriving instance Inhabited for Impl.Label

namespace Conform

structure Rng where
  s : UInt64

def Rng.next (r : Rng) : UInt64 × Rng :=
  let x := r.s
  let x := x ^^^ (x <<< 13)
  let x := x ^^^ (x >>> 7)
  let x := x ^^^ (x <<< 17)
  (x, ⟨x⟩)

inductive PMode where
  | ok
  | changed
  | nolog
  deriving DecidableEq, Repr, Inhabited

def emptyDB : DB := ⟨[], [], [], [], [], [], [], [], [], [], [], [], [], [], []⟩

structure BState where
  db : DB := emptyDB
  modes : List (Nat × PMode) := []
  nid : Nat := 1
  nrun : Nat := 1
  rng : Rng

abbrev B := StateM BState

def rand (n : Nat) : B Nat :=
  modifyGet fun s => let (x, r) := s.rng.next; (x.toNat % n, { s with rng := r })

def chance (pct : Nat) : B Bool := return (← rand 100) < pct

def pick {α} [Inhabited α] (l : List α) : B α := return l[(← rand l.length)]!

def modDB (f : DB → DB) : B Unit := modify fun s => { s with db := f s.db }

def addClaim (c : Nat) (l : Label) : B Unit := modDB fun d => { d with claim := d.claim ++ [(c, l)] }
def addSup (n o : Nat) : B Unit := modDB fun d => { d with supersedes := d.supersedes ++ [(n, o)] }
def addUniv (c : Nat) : B Unit := modDB fun d => { d with universal := d.universal ++ [c] }
def addReq (c : Nat) : B Unit := modDB fun d => { d with burn_requested := d.burn_requested ++ [c] }
def addCheck (k c : Nat) : B Unit := modDB fun d => { d with check := d.check ++ [(k, c)] }
def addChange (x : Nat) : B Unit := modDB fun d => { d with change := d.change ++ [x] }
def addServes (x c : Nat) : B Unit := modDB fun d => { d with serves := d.serves ++ [(x, c)] }
def addQuestion (q c : Nat) : B Unit := modDB fun d => { d with question := d.question ++ [(q, c)] }
def addAssumed (q v : Nat) : B Unit := modDB fun d => { d with assumed := d.assumed ++ [(q, v)] }
def addAnswer (q v : Nat) (w : Writer) : B Unit :=
  modDB fun d => { d with answer := d.answer ++ [(q, v, w)] }
def addDepends (q p : Nat) : B Unit := modDB fun d => { d with depends := d.depends ++ [(q, p)] }
def addConf (k : Nat) : B Unit := modDB fun d => { d with conformance := d.conformance ++ [k] }

def addAttest (t : AType) (subj : Nat) (p : Pred) (w : Writer) : B Nat := do
  let s ← get
  let i := s.nid
  set { s with nid := i + 1, db := { s.db with attest := s.db.attest ++ [({ id := i, type := t, subj := subj, pred := p, by_ := w, time := 0 } : Attest)] } }
  return i

def addResult (k : Nat) (o : Outcome) : B Unit := do
  let s ← get
  let r := s.nrun
  set { s with nrun := r + 1 }
  discard <| addAttest .test_result k (.result k r o) .script

def addProof (c : Nat) (w : Writer) (m : PMode) : B Unit := do
  let i ← addAttest .lean_proof c (.proof c 0) w
  modify fun s => { s with modes := s.modes ++ [(i, m)] }

def addWaiver (c : Nat) (w : Writer) (due : Nat) : B Unit :=
  discard <| addAttest .waiver c (.waive c due) w
def addDiv (c : Nat) (w : Writer) : B Unit := discard <| addAttest .divergence c (.claim c) w
def addProg (c : Nat) (v : Verdict) (w : Writer) : B Unit :=
  discard <| addAttest .lean_result c (.verdict c v) w
def addDisproof (c : Nat) (v : Verdict) : B Unit :=
  discard <| addAttest .disproof c (.verdict c v) .agent

/-! ## The disk, the expected answers, and the mutants -/

/-- The due time 3000 stands for an invalid time. `renderAttest` writes it as
`'2999-02-30T00:00:00Z'`: it has the shape of a time, and it sorts after now, but
30 February is not a day (D10 follow-up, F9 and F10). -/
def invalidDue : Nat := 3000

def disk (modes : List (Nat × PMode)) : Disk :=
  ⟨fun a => modes.lookup a.id == some PMode.ok, 2026, fun d => d != invalidDue⟩

def sortNats (l : List Nat) : List Nat := (l.eraseDups).mergeSort (· ≤ ·)

def claimIds (db : DB) : List Nat := sortNats (db.claim.map (·.1))

/-- Every id that a mutant `burn_open` could answer. -/
def candidates (db : DB) : List Nat :=
  sortNats (db.claim.map (·.1) ++ db.universal ++ db.burn_requested ++ db.supersedes.map (·.1) ++
    db.attest.filterMap fun a => match a.pred with | .claim c => some c | _ => none)

/-- The mutants for the discriminating runs. Each drops one literal of build.pl.
* MA: `burn_open` without `current(C)`.
* MB: `burn_open` without `not burn_waived(C)`.
* MC: `burn_proved` without `not proof_changed(A)`.
* MI: `burn/1` without its clause `burn(C) :- supersedes_closure(C, O), burn_reason(O).`
  (D10 follow-up: no inherited burn).
* MY: `done` without `not any_supersede_cycle` (D10 follow-up).
* MZ: `done` without `not no_current_claim` (D17). -/
inductive Mut where
  | MA
  | MB
  | MC
  | MI
  | MY
  | MZ
  deriving DecidableEq, Repr

def Mut.name : Mut → String
  | .MA => "MA"
  | .MB => "MB"
  | .MC => "MC"
  | .MI => "MI"
  | .MY => "MY"
  | .MZ => "MZ"

def burn_proved_MC (db : DB) (c : Atom) : Bool :=
  db.attest.any fun a => a.type == .lean_proof && a.pred.proofOf c && a.by_ == .script

def burn_open_m (db : DB) (c : Atom) : Mut → Bool
  | .MA => burn db c && !burn_proved db c && !burn_waived db c
  | .MB => burn db c && current db c && !burn_proved db c
  | .MC => burn db c && current db c && !burn_proved_MC db c && !burn_waived db c
  | .MI => burn_reason db c && current db c && !burn_proved db c && !burn_waived db c
  | .MY => burn_open db c
  | .MZ => burn_open db c

def done_m (db : DB) (m : Mut) : Bool :=
  !any_under db && !any_over db && !any_to_ask db &&
    !(candidates db).any (fun c => burn_open_m db c m) &&
    (m == .MY || !any_supersede_cycle db) &&
    (m == .MZ || !no_current_claim db)

/-! ## Rendering -/

def wS : Writer → String
  | .human => "human"
  | .agent => "agent"
  | .script => "script"

def lS : Label → String
  | .preserve => "preserve"
  | .retire => "retire"
  | .introduce => "introduce"

def vS : Verdict → String
  | .stated => "stated"
  | .refuted => "refuted('counterexample')"
  | .tested n => s!"tested({n})"
  | .inconclusive => "inconclusive"
  | .abstained => "abstained"

def oS : Outcome → String
  | .pass => "pass"
  | .fail => "fail"

def renderAttest (a : Attest) : String :=
  match a.pred with
  | .result k r o =>
    s!"attest(t{a.id}, test_result, k{k}, result(k{k}, {r}, {oS o}), script, '2026-10-15T10:00:00Z')."
  | .verdict c v =>
    let (pre, ty) := if a.type == .disproof then ("r", "disproof") else ("l", "lean_result")
    s!"attest({pre}{a.id}, {ty}, c{c}, verdict(c{c}, {vS v}), {wS a.by_}, '2026-10-15T11:00:00Z')."
  | .proof c _ =>
    s!"attest(p{a.id}, lean_proof, c{c}, proof(c{c}, '@DIGEST:p{a.id}@'), {wS a.by_}, '2026-10-15T11:00:00Z')."
  | .waive c due =>
    let dueS := if due == invalidDue then "2999-02-30T00:00:00Z" else s!"{due}-01-01T00:00:00Z"
    s!"attest(w{a.id}, waiver, c{c}, waive(c{c}, '{dueS}', 'Reason {a.id}'), {wS a.by_}, '2019-12-01T00:00:00Z')."
  | .claim c =>
    s!"attest(d{a.id}, divergence, c{c}, claim(c{c}), {wS a.by_}, '2026-10-15T10:00:00Z')."
  | .other => ""

def renderKB (db : DB) : String :=
  let ls : List String :=
    ["uses([build]).", "request(r1, 'Conformance KB')."] ++
    (db.claim.map fun (c, l) => s!"claim(c{c}, {lS l}, 'Claim {c}').\ncites(c{c}, 'Conformance KB').") ++
    (db.supersedes.map fun (n, o) => s!"supersedes(c{n}, c{o}).") ++
    (db.universal.map fun c => s!"universal(c{c}).") ++
    (db.burn_requested.map fun c => s!"burn_requested(c{c}).") ++
    (db.check.map fun (k, c) => s!"check(k{k}, c{c}).") ++
    (db.change.map fun x => s!"change(x{x}, 'Change {x}').") ++
    (db.serves.map fun (x, c) => s!"serves(x{x}, c{c}).") ++
    (db.question.map fun (q, c) => s!"question(q{q}, c{c}, 'Question {q}').") ++
    (db.assumed.map fun (q, v) => s!"assumed(q{q}, v{v}).") ++
    (db.answer.map fun (q, v, w) => s!"answer(q{q}, v{v}, {wS w}).") ++
    (db.depends.map fun (q, p) => s!"depends(q{q}, q{p}).") ++
    (db.conformance.map fun k => s!"conformance(k{k}).") ++
    (db.attest.map renderAttest)
  String.intercalate "\n" ls ++ "\n"

def names (pre : String) (l : List Nat) : String :=
  String.intercalate " " (l.map fun n => s!"{pre}{n}")

def expectText (db0 : DB) (modes : List (Nat × PMode)) : String :=
  let db := derive (disk modes) db0
  let opens := (claimIds db).filter (burn_open db)
  let mline (m : Mut) : String :=
    let o := (candidates db).filter (fun c => burn_open_m db c m)
    s!"{m.name} {done_m db m} {names "c" o}"
  s!"done {done db}\nopen {names "c" opens}\nchanged {names "p" (sortNats db.proof_changed)}\n" ++
  s!"lapsed {names "w" (sortNats db.waiver_lapsed)}\n" ++
  String.intercalate "\n" ([Mut.MA, .MB, .MC, .MI, .MY, .MZ].map mline) ++ "\n"

def modeS : PMode → String
  | .ok => "ok"
  | .changed => "changed"
  | .nolog => "nolog"

def writeKB (out name : String) (s : BState) : IO Unit := do
  let dir := s!"{out}/{name}"
  IO.FS.createDirAll s!"{dir}/runs"
  IO.FS.writeFile s!"{dir}/kb.pl" (renderKB s.db)
  for a in s.db.attest do
    match a.pred with
    | .result k r o =>
      let ec := if o == .fail then 1 else 0
      let cmd := if o == .fail then "false" else "true"
      IO.FS.writeFile s!"{dir}/runs/{r}-k{k}.log"
        s!"% orbit-kb run {r} check=k{k} result={oS o} exit={ec} time=2026-10-15T10:00:00Z cmd={cmd}\n"
    | _ => pure ()
  let proofs := s.db.attest.filterMap fun a => match a.pred with
    | .proof c _ => some s!"p{a.id} c{c} {modeS ((s.modes.lookup a.id).getD .nolog)}\n"
    | _ => none
  IO.FS.writeFile s!"{dir}/proofs.txt" (String.join proofs)
  IO.FS.writeFile s!"{dir}/expect.txt" (expectText s.db s.modes)

/-! ## The exhaustive set: one burning claim, every combination

* reasons: `universal` (2) × `burn_requested` (2) × divergences 0, 1, 2 (3)
* proof of c1: none, script ok, script changed, script with no log, agent ok (5)
* waiver of c1: none, human due 2999, human due 2020, agent due 2999 (4)
* supersede: none, c2 supersedes c1 (c2 plain and fulfilled), c1 supersedes c1 (3)
* progress: none, `stated` by agent, `tested(1000)` by script (3)

Claim c1 is `preserve` with a passing check, so the other parts of `done` hold. -/

def exhaustiveOne (u r : Bool) (dv pf wv sp pg : Nat) : B Unit := do
  addClaim 1 .preserve
  addCheck 1 1
  addResult 1 .pass
  if u then addUniv 1
  if r then addReq 1
  for _ in [0:dv] do addDiv 1 .agent
  match sp with
  | 1 => addClaim 2 .preserve; addCheck 2 2; addResult 2 .pass; addSup 2 1
  | 2 => addSup 1 1
  | _ => pure ()
  match pf with
  | 1 => addProof 1 .script .ok
  | 2 => addProof 1 .script .changed
  | 3 => addProof 1 .script .nolog
  | 4 => addProof 1 .agent .ok
  | _ => pure ()
  match wv with
  | 1 => addWaiver 1 .human 2999
  | 2 => addWaiver 1 .human 2020
  | 3 => addWaiver 1 .agent 2999
  | _ => pure ()
  match pg with
  | 1 => addProg 1 .stated .agent
  | 2 => addProg 1 (.tested 1000) .script
  | _ => pure ()

def exhaustive (out : String) : IO Nat := do
  let mut n := 0
  for u in [false, true] do
    for r in [false, true] do
      for dv in [0, 1, 2] do
        for pf in [0, 1, 2, 3, 4] do
          for wv in [0, 1, 2, 3] do
            for sp in [0, 1, 2] do
              for pg in [0, 1, 2] do
                n := n + 1
                let (_, s) := (exhaustiveOne u r dv pf wv sp pg).run { rng := ⟨1⟩ }
                writeKB out s!"e{n}" s
  return n

/-! ## The random set: one to three claims, fixed seed -/

def randomOne : B Unit := do
  let nc := (← rand 3) + 1
  let claims := (List.range nc).map (· + 1)
  let mut nk := 0
  for c in claims do
    let l ← pick [Label.preserve, .preserve, .introduce, .retire]
    addClaim c l
    if ← chance 40 then addUniv c
    if ← chance 25 then addReq c
    for _ in [0:(← rand 3)] do addDiv c (← pick [Writer.agent, .human])
    -- checks: none, pass, fail then pass, pass then fail, fail
    match ← pick [0, 1, 1, 2, 2, 3, 4] with
    | 0 => pure ()
    | 1 => nk := nk + 1; addCheck nk c; addResult nk .pass
    | 2 => nk := nk + 1; addCheck nk c; addResult nk .fail; addResult nk .pass
    | 3 => nk := nk + 1; addCheck nk c; addResult nk .pass; addResult nk .fail
    | _ => nk := nk + 1; addCheck nk c; addResult nk .fail
  for c in claims do
    if c > 1 then
      if ← chance 25 then addSup c ((← rand (c - 1)) + 1)
    if ← chance 4 then addSup c c
  -- D10 follow-up: a back edge from claim 1 to the last claim makes a longer
  -- cycle when the last claim reaches claim 1.
  if nc > 1 then
    if ← chance 10 then addSup 1 nc
  for c in claims do
    for _ in [0:(← pick [0, 1, 1, 2])] do
      let tgt ← if ← chance 80 then pure c else pick claims
      let w ← pick [Writer.script, .script, .script, .script, .script, .script, .script, .script,
        .agent, .human]
      let m ← pick [PMode.ok, .ok, .ok, .changed, .nolog]
      addProof tgt w m
    if ← chance 35 then
      let tgt ← if ← chance 85 then pure c else pick claims
      addWaiver tgt (← pick [Writer.human, .human, .human, .agent]) (← pick [2020, 2999, 2999, invalidDue])
    for _ in [0:(← rand 3)] do
      let v ← pick [Verdict.stated, .stated, .tested 1000, .tested 50, .refuted]
      addProg c v (← pick [Writer.agent, .script])
    if ← chance 10 then addDisproof c (← pick [Verdict.refuted, .inconclusive, .abstained])
  for x in [1:(← rand 3) + 1] do
    addChange x
    if ← chance 80 then addServes x (← pick claims)
  for q in [1:(← rand 3) + 1] do
    addQuestion q (← pick claims)
    addAssumed q 0
    match ← rand 4 with
    | 1 => addAnswer q 0 .human
    | 2 => addAnswer q 1 .human
    | 3 => addAnswer q 1 .agent
    | _ => pure ()
    if q > 1 then
      if ← chance 30 then addDepends q ((← rand (q - 1)) + 1)
  if nk > 0 then
    if ← chance 25 then addConf ((← rand nk) + 1)

/-! ## KBs with no claim (D17)

* z1: no fact but the request.
* z2: a progress record and a waiver of a claim that does not exist (a dangling
  reference, lint E4). Nothing burns, so only the missing claim blocks `done`. -/

def noClaim (out : String) : IO Nat := do
  let (_, s1) := (pure () : B Unit).run { rng := ⟨1⟩ }
  writeKB out "z1" s1
  let (_, s2) := (do addProg 1 .stated .agent; addWaiver 1 .human 2999 : B Unit).run { rng := ⟨1⟩ }
  writeKB out "z2" s2
  return 2

def random (out : String) (count : Nat) (seed : UInt64) : IO Unit := do
  let mut rng : Rng := ⟨seed⟩
  for i in [1:count + 1] do
    let (_, s) := randomOne.run { rng := rng }
    rng := s.rng
    writeKB out s!"r{i}" s

end Conform

def main (args : List String) : IO UInt32 := do
  match args with
  | ["gen", out] =>
    let n ← Conform.exhaustive out
    Conform.random out 600 0x2545F4914F6CDD1D
    let z ← Conform.noClaim out
    IO.println s!"wrote {n} exhaustive KBs (e1..e{n}), 600 random KBs (r1..r600), and {z} KBs with no claim (z1..z{z}) to {out}"
    return 0
  | _ =>
    IO.eprintln "usage: conform gen OUTDIR"
    return 2

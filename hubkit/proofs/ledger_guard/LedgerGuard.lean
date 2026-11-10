/-
T05 c2, the flow ledger `hubflow` (hubkit/hub/.claude/scripts/hubflow.py).

Claim (after review): no agent command may take an item out of the open/escalated view
without the human, when the item is open or waiting and is escalated, or its kb ref's spec KB
blocks, or the KB answer is unknown (fail-safe: a missing kb dir, orbit-kb exit 2, a timeout
or a missing command all count as unknown).

The model is one item. Each hubflow command that can change an existing item is one `Cmd`.
`step` follows hubflow.py; `check_commands.py` (next to this file) compares hubflow.py's
COMMANDS table with `modelledCommands` and `excludedCommands` below.

T40 c7 (after the transcripts merge 0966a1c): `rotate` lapses an open summary row (kind `summary`)
at the first rotation when it is 28 days old, unless it is escalated or its kb answer is not clear
(guess q10 of the transcripts build). The model has that action (`Cmd.rotate old blocked`, with
`Item.summary`; T40 c10: the triage gate refuses a rotation and counts no summary row), and `agent_run_keeps_guarded` is proved again with it; its statement is the one
of T05. check_commands.py checks the rotate guard in hubflow.py, and lean_mutant_test.py checks
that a rotate that lapses an escalated summary fails the proof.

T40 c13 (after T39 c3 added `skip-waived`; review default, Ty not asked): `skip-waived` drops an
open item whose kb refs are all clear and one of whose spec KBs has a live human waiver, unless
the item is escalated: an escalated item stays open for the human, who ends it with triage. Any
writer may run it (it writes by=script). The model had that action as one step (T42 c2 splits it in two), and
`agent_run_keeps_guarded` and `agent_run_keeps_escalated` are proved again with it, their
statements unchanged. check_commands.py checks the escalated filter inside the write of
cmd_skip_waived, and lean_mutant_test.py checks that a skip-waived that drops an escalated item
fails the proof.

T42 c2, c4 (after the T40 verify, divergence a75; c4 is review's default, Ty not asked): skip-waived
is two steps. Its read (`Cmd.skipRead waived`) picks the open items whose kb answer is clear and
waived: it marks the item `planned`. Its write (`Cmd.skipWrite`) acts on a planned item only if the
item is open, not escalated, and its kb answer, read again in the write, is still clear; then it
parks the item (until the waiver's due date; the model has `parked := true`) and never drops it.
Between the two steps any command may run (a `ref add kb:...`), and the spec KB itself may change:
the theorems quantify over every start item, so a planned item whose kb answer now blocks is one of
them. A park keeps the item in view, so `agent_run_keeps_guarded` (proved again, its statement
unchanged) does not see a wrong park; `agent_run_keeps_guarded_unparked` does: an agent run keeps a
guarded item that is not parked guarded and not parked (its statement is the conclusion of
`agent_run_keeps_guarded` and `parked = false`, so it is no weaker). A park ends when its date is
past; the model has no clock, so that return is outside it (hubflow-test checks it). lean_mutant_test.py
checks that a write without the recheck, and a write that parks an escalated item, fail that proof.
-/
namespace LedgerGuard

/-- item.status (STATUSES). `parked_until` is a separate field (`Item.parked`), not a status. -/
inductive Status
  | open_ | waiting | done | dropped | lapsed
  deriving DecidableEq, Repr

/-- The answer of all kb refs of the item together (`kb_checks`, then
`any(k["state"] != "clear")`). `none`: the item has no kb ref. `unknown`: the fail-safe. -/
inductive Kb
  | none | clear | blocks | unknown
  deriving DecidableEq, Repr

structure Item where
  status : Status
  /-- `is_escalated`: the newest disposition of the item is `escalate`. -/
  esc : Bool
  kb : Kb
  parked : Bool
  /-- At least one capsule row exists (`triage ID capsule` needs one). -/
  hasCapsule : Bool
  /-- item.kind is `summary` (S-, what an agent noted from a meeting; T40 c7). -/
  summary : Bool
  /-- A running skip-waived read the item as a candidate (T42 c2): its kb answer was clear and
  waived at the read. The write reads the kb answer again. -/
  planned : Bool
  deriving DecidableEq, Repr

/-- The writer (`writer_by`): `--by agent` (the default), `--by script`, or `--by human`,
which needs `--note` with the person's words. -/
inductive Actor
  | agent | script | human (note : String)
  deriving Repr

/-- `some true`: the writer counts as the human. `some false`: agent or script.
`none`: `--by human` without `--note`, which `writer_by` refuses (exit 1, nothing written). -/
def Actor.writer : Actor → Option Bool
  | .agent => some false
  | .script => some false
  | .human n => if n = "" then none else some true

inductive Disp
  | keep | lapse | capsule | escalate
  deriving DecidableEq, Repr

inductive Reason
  | done | dropped | humanSkip
  deriving DecidableEq, Repr

/-- One hubflow command, as it acts on the modelled item. -/
inductive Cmd
  /-- `renew ID` -/
  | renew
  /-- `park ID --until D` -/
  | park
  /-- `set ID --status ST` (only open or waiting are accepted) -/
  | setStatus (st : Status)
  /-- `set ID` with only --title / --owner / --waits-on / --analysis -/
  | setFields
  /-- `close ID --reason R` -/
  | close (r : Reason)
  /-- `reopen ID` -/
  | reopen
  /-- `ref ID add kb:REF` whose spec KB answers `a` -/
  | refAddKb (a : Kb)
  /-- `ref ID rm kb:REF`; `rest` is the answer of the kb refs that are left -/
  | refRmKb (rest : Kb)
  /-- `ref ID add|rm KIND:REF` for a kind that is not kb -/
  | refOther
  /-- `link FROM TO KIND` with this item on either side -/
  | link
  /-- `note ID TEXT` -/
  | note
  /-- `accept ID` (a handoff) -/
  | accept
  /-- `capsule ID --summary T` -/
  | capsule
  /-- `triage ID D --note T` -/
  | triage (d : Disp)
  /-- `close OTHER --reason human_skip`, where OTHER is linked to this item by `blocks`: the
  propagation drops this item too. -/
  | skipLinked
  /-- `rotate --week-start W --yes`: it prunes only closed items, and it lapses an open summary
  row whose opened_at is 28 days or more before the rotation (`old`), unless it is escalated
  or its kb answer is not clear (T40 c7). `blocked`: the triage gate refuses the rotation (a due
  item lacks a disposition, or the spec KB of a closed ticket lacks a decision; exit 1, nothing
  written). The gate reads the other items; a summary row is never one of the items it counts
  (T40 c10, checked in hubflow.py by check_commands.py), so `blocked` is an input here. -/
  | rotate (old blocked : Bool)
  /-- The read of `skip-waived` (T39 c3, T42 c2): `waived` = the item's spec KBs rest on a live
  human waiver that covers what would block (T42 c5). It plans an open item whose kb answer is
  clear and waived; it writes nothing. -/
  | skipRead (waived : Bool)
  /-- The write of `skip-waived` (T40 c13, T42 c2 and c4): a planned item that is open, not
  escalated, and whose kb answer is clear again in the write is parked (by=script), never dropped.
  An escalated item stays open, and its id is printed. Any writer may run it. -/
  | skipWrite
  deriving Repr

inductive Outcome
  | ok (s : Item)
  /-- the agent guard or triage refused: exit 1, nothing written -/
  | refused
  /-- any other exit 1 (need_open, a usage error, no such ref, no capsule ...) -/
  | error
  deriving DecidableEq, Repr

def isOpen (s : Item) : Bool := s.status == .open_ || s.status == .waiting

def nonclear : Kb → Bool
  | .blocks => true
  | .unknown => true
  | _ => false

/-- `ref add kb:...`: the new answer of all kb refs together. -/
def Kb.join : Kb → Kb → Kb
  | k, .none => k
  | .none, a => a
  | .clear, a => a
  | .blocks, _ => .blocks
  | .unknown, .blocks => .blocks
  | .unknown, _ => .unknown

/-- `agent_guard`: true = refuse. Not for the human; only for an open item that is escalated,
or that has kb refs and one of them is not clear. -/
def agentGuard (human : Bool) (s : Item) : Bool :=
  !human && isOpen s && (s.esc || nonclear s.kb)

/-- One command by a writer that `writer_by` accepted (`human` = it is `--by human --note`). -/
def stepAs (human : Bool) : Cmd → Item → Outcome
  | .renew, s =>
      if agentGuard human s then .refused else if isOpen s then .ok s else .error
  | .park, s =>
      if agentGuard human s then .refused
      else if isOpen s then .ok { s with parked := true } else .error
  | .setStatus st, s =>
      if !(st == .open_ || st == .waiting) then .error
      else if agentGuard human s then .refused
      else if isOpen s then .ok { s with status := st } else .error
  | .setFields, s => .ok s
  | .close .humanSkip, s =>
      if !human then .error
      else if isOpen s then .ok { s with status := .dropped } else .error
  | .close r, s =>
      if agentGuard human s then .refused
      else if isOpen s then .ok { s with status := if r == .done then .done else .dropped }
      else .error
  | .reopen, s =>
      if isOpen s then .error else .ok { s with status := .open_, parked := false }
  | .refAddKb a, s => .ok { s with kb := s.kb.join a }
  | .refRmKb rest, s =>
      if s.kb == .none then .error
      else if agentGuard human s then .refused
      else .ok { s with kb := rest }
  | .refOther, s => .ok s
  | .link, s => .ok s
  | .note, s => .ok s
  | .accept, s => if isOpen s then .ok s else .error
  | .capsule, s => .ok { s with hasCapsule := true }
  | .triage d, s =>
      if !isOpen s then .error
      else
        -- hubflow.py cmd_triage: an agent's keep/lapse/capsule of an escalated item, or of an
        -- item whose kb answer is not clear, becomes escalate.
        let final := if !human && d != .escalate && (s.esc || nonclear s.kb) then Disp.escalate else d
        match final with
        | .escalate => .ok { s with esc := true }
        | .keep => .ok { s with esc := false }
        | .capsule => if s.hasCapsule then .ok { s with esc := false } else .error
        | .lapse => .ok { s with esc := false, status := .lapsed }
  | .skipLinked, s =>
      if !human then .error
      else if isOpen s then .ok { s with status := .dropped } else .ok s
  | .rotate old blocked, s =>
      -- hubflow.py cmd_rotate: triage_gate raises before any write when a due item lacks a
      -- disposition or a spec KB lacks a decision (untriaged_spec_kbs counts no summary row).
      -- rotate_plan: `lapse` is the open summary rows with opened_at <= now - 28 days and
      -- `if not is_escalated(c, r[0])`; the write drops `held` (kb_held_summaries, inside the
      -- write: a kb ref whose state is not clear, fail-safe). Every other open item is unchanged.
      if blocked then .refused else
      if old && s.summary && isOpen s && !s.esc && !nonclear s.kb then
        .ok { s with status := .lapsed }
      else .ok s
  | .skipRead waived, s =>
      -- hubflow.py skip_candidates: open or waiting items with kb refs, every kb_checks state
      -- clear, and a live human waiver that something rests on (waiver_park).
      .ok { s with planned := waived && isOpen s && s.kb == .clear }
  | .skipWrite, s =>
      -- hubflow.py cmd_skip_waived, its write: skip `is_escalated` items, read the kb refs again
      -- (item_kb_refs, kb_checks) and skip one that is not clear; park the rest (parked_until).
      if s.planned && isOpen s && !s.esc && s.kb == .clear then .ok { s with parked := true, planned := false }
      else .ok { s with planned := false }

def step (a : Actor) (c : Cmd) (s : Item) : Outcome :=
  match a.writer with
  | none => .error
  | some h => stepAs h c s

/-- The item after the command: a refused or failed command writes nothing. -/
def exec (a : Actor) (c : Cmd) (s : Item) : Item :=
  match step a c s with
  | .ok s' => s'
  | _ => s

def run : List (Actor × Cmd) → Item → Item
  | [], s => s
  | (a, c) :: rest, s => run rest (exec a c s)

/-- v_open: status open or waiting (v_escalated is v_open with escalated = 1). -/
def inView (s : Item) : Prop := s.status = .open_ ∨ s.status = .waiting

/-- Open or waiting, and escalated, or the kb answer blocks or is unknown. -/
def guarded (s : Item) : Prop :=
  inView s ∧ (s.esc = true ∨ s.kb = .blocks ∨ s.kb = .unknown)

/-- The writer is not the human (agent, script, or `--by human` with no note). -/
def notHuman (a : Actor) : Prop := a.writer ≠ some true

/-! ## Counterexample search: every state, every command, one agent step. -/

def allStatus : List Status := [.open_, .waiting, .done, .dropped, .lapsed]
def allKb : List Kb := [.none, .clear, .blocks, .unknown]
def allBool : List Bool := [false, true]
def allItems : List Item := Id.run do
  let mut out := []
  for st in allStatus do
    for e in allBool do
      for k in allKb do
        for p in allBool do
          for c in allBool do
            for sm in allBool do
              for pl in allBool do
                out := out ++ [{ status := st, esc := e, kb := k, parked := p, hasCapsule := c, summary := sm,
                                 planned := pl }]
  return out
def allCmds : List Cmd :=
  [.renew, .park, .setFields, .close .done, .close .dropped, .close .humanSkip, .reopen,
   .refOther, .link, .note, .accept, .capsule, .skipLinked, .rotate false false, .rotate true false,
   .rotate false true, .rotate true true, .skipRead false, .skipRead true, .skipWrite]
  ++ allStatus.map .setStatus ++ allKb.map .refAddKb ++ allKb.map .refRmKb
  ++ [Disp.keep, .lapse, .capsule, .escalate].map .triage

def inViewB (s : Item) : Bool := isOpen s
def guardedB (s : Item) : Bool := isOpen s && (s.esc || nonclear s.kb)

/-- Pairs (state, command) where one agent step leaves a guarded state unguarded. -/
def agentCounterexamples : List (Item × Cmd) :=
  allItems.flatMap fun s => allCmds.filterMap fun c =>
    let s' := match stepAs false c s with | .ok x => x | _ => s
    if guardedB s && !guardedB s' then some (s, c) else none

#eval agentCounterexamples  -- expect []

/-- Pairs (state, command) where one agent step parks a guarded item that was not parked (T42 c2). -/
def agentParkCounterexamples : List (Item × Cmd) :=
  allItems.flatMap fun s => allCmds.filterMap fun c =>
    let s' := match stepAs false c s with | .ok x => x | _ => s
    if guardedB s && !s.parked && !(guardedB s' && !s'.parked) then some (s, c) else none

#eval agentParkCounterexamples  -- expect []
#eval (allItems.length, allCmds.length)

/-! ## The proof -/

theorem guarded_iff (s : Item) : guarded s ↔ guardedB s = true := by
  rcases s with ⟨st, e, k, p, c, sm, pl⟩
  cases st <;> cases e <;> cases k <;> simp [guarded, guardedB, inView, isOpen, nonclear]

theorem inView_iff (s : Item) : inView s ↔ inViewB s = true := by
  rcases s with ⟨st, e, k, p, c, sm, pl⟩
  cases st <;> simp [inView, inViewB, isOpen]

-- T42: the field `planned` doubles the cases that `decide` checks, so this proof has a larger budget.
set_option maxHeartbeats 800000 in
/-- One step by a non-human writer (after `writer_by`) keeps a guarded item guarded. -/
theorem stepAs_agent_keeps_guarded (c : Cmd) (s : Item) (h : guardedB s = true) :
    guardedB (match stepAs false c s with | .ok x => x | _ => s) = true := by
  rcases s with ⟨st, e, k, p, hc, sm, pl⟩
  cases c with
  | setStatus st' =>
    cases st' <;> cases st <;> cases e <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | close r =>
    cases r <;> cases st <;> cases e <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | refAddKb a =>
    cases a <;> cases st <;> cases e <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | refRmKb a =>
    cases a <;> cases st <;> cases e <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | triage d =>
    cases d <;> cases st <;> cases e <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | rotate o b =>
    cases o <;> cases b <;> cases st <;> cases e <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | skipRead w =>
    cases w <;> cases st <;> cases e <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | _ =>
    cases st <;> cases e <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide

theorem exec_agent_keeps_guarded (a : Actor) (ha : notHuman a) (c : Cmd) (s : Item)
    (h : guarded s) : guarded (exec a c s) := by
  rw [guarded_iff] at h ⊢
  unfold exec step
  cases hw : a.writer with
  | none => simpa using h
  | some b =>
    cases b with
    | true => exact absurd hw ha
    | false =>
      have := stepAs_agent_keeps_guarded c s h
      simpa using this

/-- **Theorem (T05 c2).** In plain words: start from an item that is open or waiting and is
escalated, or whose kb answer blocks or is unknown. Run any finite list of hubflow commands
in which no command is written `--by human --note ...`. Then the item is still open or
waiting (in `view open`), and it is still guarded. -/
theorem agent_run_keeps_guarded (cs : List (Actor × Cmd)) (hcs : ∀ p ∈ cs, notHuman p.1)
    (s : Item) (hs : guarded s) : inView (run cs s) ∧ guarded (run cs s) := by
  induction cs generalizing s with
  | nil => exact ⟨hs.1, hs⟩
  | cons p rest ih =>
    obtain ⟨a, c⟩ := p
    exact ih (fun q hq => hcs q (List.mem_cons_of_mem _ hq)) _
      (exec_agent_keeps_guarded a (hcs (a, c) List.mem_cons_self) c s hs)

/-- An agent cannot end an escalation either: an escalated item in view stays escalated
(it stays in `view escalated`). -/
theorem agent_run_keeps_escalated (cs : List (Actor × Cmd)) (hcs : ∀ p ∈ cs, notHuman p.1)
    (s : Item) (hv : inView s) (he : s.esc = true) :
    inView (run cs s) ∧ (run cs s).esc = true := by
  induction cs generalizing s with
  | nil => exact ⟨hv, he⟩
  | cons p rest ih =>
    obtain ⟨a, c⟩ := p
    apply ih (fun q hq => hcs q (List.mem_cons_of_mem _ hq))
    · exact (exec_agent_keeps_guarded a (hcs (a, c) List.mem_cons_self) c s ⟨hv, Or.inl he⟩).1
    · have ha := hcs (a, c) List.mem_cons_self
      unfold exec step
      cases hw : a.writer with
      | none => simpa using he
      | some b =>
        cases b with
        | true => exact absurd hw ha
        | false =>
          simp only
          rw [inView_iff] at hv
          rcases s with ⟨st, e, k, p, hc, sm, pl⟩
          simp only at he
          subst he
          cases c with
          | setStatus st' =>
            cases st' <;> cases st <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert hv <;> decide
          | close r =>
            cases r <;> cases st <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert hv <;> decide
          | refAddKb a =>
            cases a <;> cases st <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert hv <;> decide
          | refRmKb a =>
            cases a <;> cases st <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert hv <;> decide
          | triage d =>
            cases d <;> cases st <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert hv <;> decide
          | rotate o b =>
            cases o <;> cases b <;> cases st <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert hv <;> decide
          | skipRead w =>
            cases w <;> cases st <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert hv <;> decide
          | _ =>
            cases st <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert hv <;> decide

/-! ## The park guard (T42 c2): an agent run parks no guarded item -/

/-- One step by a non-human writer parks no guarded item that is not parked. -/
theorem stepAs_agent_keeps_unparked (c : Cmd) (s : Item) (h : guardedB s = true) (hp : s.parked = false) :
    (match stepAs false c s with | .ok x => x | _ => s).parked = false := by
  rcases s with ⟨st, e, k, p, hc, sm, pl⟩
  simp only at hp
  subst hp
  cases c with
  | setStatus st' =>
    cases st' <;> cases st <;> cases e <;> cases k <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | close r =>
    cases r <;> cases st <;> cases e <;> cases k <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | refAddKb a =>
    cases a <;> cases st <;> cases e <;> cases k <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | refRmKb a =>
    cases a <;> cases st <;> cases e <;> cases k <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | triage d =>
    cases d <;> cases st <;> cases e <;> cases k <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | rotate o b =>
    cases o <;> cases b <;> cases st <;> cases e <;> cases k <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | skipRead w =>
    cases w <;> cases st <;> cases e <;> cases k <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide
  | _ =>
    cases st <;> cases e <;> cases k <;> cases hc <;> cases sm <;> cases pl <;> revert h <;> decide

theorem exec_agent_keeps_unparked (a : Actor) (ha : notHuman a) (c : Cmd) (s : Item)
    (h : guarded s) (hp : s.parked = false) : (exec a c s).parked = false := by
  rw [guarded_iff] at h
  unfold exec step
  cases hw : a.writer with
  | none => simpa using hp
  | some b =>
    cases b with
    | true => exact absurd hw ha
    | false =>
      have := stepAs_agent_keeps_unparked c s h hp
      simpa using this

/-- **Theorem (T42 c2).** In plain words: start from an item that is open or waiting, is not
parked, and is escalated, or whose kb answer blocks or is unknown (it may be planned by a
skip-waived read that saw an older kb answer). Run any finite list of hubflow commands in which
no command is written `--by human --note ...`, with the two steps of skip-waived anywhere in it.
Then the item is still in view, still guarded (as `agent_run_keeps_guarded` says), and not
parked. -/
theorem agent_run_keeps_guarded_unparked (cs : List (Actor × Cmd)) (hcs : ∀ p ∈ cs, notHuman p.1)
    (s : Item) (hs : guarded s) (hp : s.parked = false) :
    inView (run cs s) ∧ guarded (run cs s) ∧ (run cs s).parked = false := by
  induction cs generalizing s with
  | nil => exact ⟨hs.1, hs, hp⟩
  | cons p rest ih =>
    obtain ⟨a, c⟩ := p
    have ha := hcs (a, c) List.mem_cons_self
    exact ih (fun q hq => hcs q (List.mem_cons_of_mem _ hq)) _
      (exec_agent_keeps_guarded a ha c s hs) (exec_agent_keeps_unparked a ha c s hs hp)

/-- The guard is not vacuous: the human, with a note, can take any guarded item out of view
(`close ID --reason dropped --by human --note ...`). -/
theorem human_close_leaves_view (n : String) (hn : n ≠ "") (s : Item) (hs : guarded s) :
    ¬ inView (exec (.human n) (.close .dropped) s) := by
  have hw : (Actor.human n).writer = some true := by simp [Actor.writer, hn]
  rw [guarded_iff] at hs
  rw [inView_iff]
  unfold exec step
  rw [hw]
  rcases s with ⟨st, e, k, p, hc, sm, pl⟩
  cases st <;> cases e <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert hs <;> decide

/-- And the human's `triage ID lapse` lapses it (case_escalate: c2-human-may-lapse-blocking). -/
theorem human_lapse_leaves_view (n : String) (hn : n ≠ "") (s : Item) (hs : guarded s) :
    ¬ inView (exec (.human n) (.triage .lapse) s) := by
  have hw : (Actor.human n).writer = some true := by simp [Actor.writer, hn]
  rw [guarded_iff] at hs
  rw [inView_iff]
  unfold exec step
  rw [hw]
  rcases s with ⟨st, e, k, p, hc, sm, pl⟩
  cases st <;> cases e <;> cases k <;> cases p <;> cases hc <;> cases sm <;> cases pl <;> revert hs <;> decide

/-- The rotate lapse is not vacuous (T40 c7): an old open summary row that is not guarded
lapses at the rotation, whoever runs it, and leaves the view. -/
theorem rotate_lapses_unguarded_summary (h : Bool) (s : Item) (hv : inView s)
    (hsum : s.summary = true) (he : s.esc = false) (hk : s.kb = .none ∨ s.kb = .clear) :
    stepAs h (.rotate true false) s = .ok { s with status := .lapsed } := by
  rw [inView_iff] at hv
  rcases s with ⟨st, e, k, p, hc, sm, pl⟩
  simp only at hsum he hk
  subst hsum he
  rcases hk with rfl | rfl <;> cases st <;> revert hv <;> simp [stepAs, isOpen, nonclear, inViewB]

/-- skip-waived is not vacuous (T40 c13, T42 c4): its read and then its write park a waived open
item whose kb answer is clear and that is not escalated, whoever runs them; the item stays in view
and keeps its status. -/
theorem skip_read_write_parks_unescalated (a b : Actor) (s : Item) (hv : inView s) (he : s.esc = false)
    (hk : s.kb = .clear) (ha : a.writer ≠ none) (hb : b.writer ≠ none) :
    run [(a, .skipRead true), (b, .skipWrite)] s = { s with parked := true, planned := false } := by
  rw [inView_iff] at hv
  rcases s with ⟨st, e, k, p, hc, sm, pl⟩
  simp only at he hk
  subst he hk
  cases hwa : a.writer with
  | none => exact absurd hwa ha
  | some x =>
    cases hwb : b.writer with
    | none => exact absurd hwb hb
    | some y =>
      cases st <;> revert hv <;> simp [run, exec, step, hwa, hwb, stepAs, isOpen, inViewB]

/-! ## Rows that mirror hubflow-test.py checks -/

def item (st : Status := .open_) (e : Bool := false) (k : Kb := .none) (cap : Bool := false)
    (sum : Bool := false) (pk : Bool := false) (pl : Bool := false) : Item :=
  { status := st, esc := e, kb := k, parked := pk, hasCapsule := cap, summary := sum, planned := pl }

def me : Actor := .human "\"drop it\" (Me)"

structure Row where
  check : String
  actor : Actor
  cmd : Cmd
  start : Item
  expect : Outcome

def rows : List Row := [
  ⟨"c2-agent-lapse-of-blocking-escalates", .agent, .triage .lapse, item (k := .blocks),
    .ok (item (e := true) (k := .blocks))⟩,
  ⟨"c2-agent-keep-of-blocking-escalates", .agent, .triage .keep, item (e := true) (k := .blocks),
    .ok (item (e := true) (k := .blocks))⟩,
  ⟨"c2-clear-kb-lapses", .agent, .triage .lapse, item (k := .clear),
    .ok (item (st := .lapsed) (k := .clear))⟩,
  ⟨"c2-failsafe-query-error-escalates", .agent, .triage .lapse, item (k := .unknown),
    .ok (item (e := true) (k := .unknown))⟩,
  ⟨"c2-failsafe-missing-kb-dir-escalates", .agent, .triage .lapse, item (k := .unknown),
    .ok (item (e := true) (k := .unknown))⟩,
  ⟨"c2-failsafe-missing-orbit-kb-escalates", .agent, .triage .lapse, item (k := .unknown),
    .ok (item (e := true) (k := .unknown))⟩,
  ⟨"c2-no-kb-ref-no-query", .agent, .triage .lapse, item,
    .ok (item (st := .lapsed))⟩,
  ⟨"c2-no-automatic-action", .agent, .rotate true false, item (e := true) (k := .blocks),
    .ok (item (e := true) (k := .blocks))⟩,
  ⟨"mt-c3-summary-lapses", .agent, .rotate true false, item (sum := true),
    .ok (item (st := .lapsed) (sum := true))⟩,
  ⟨"mt-c3-guard-escalated-summary-stays-open", .agent, .rotate true false, item (e := true) (sum := true),
    .ok (item (e := true) (sum := true))⟩,
  ⟨"mt-c3-guard-blocking-summary-stays-open", .agent, .rotate true false, item (k := .blocks) (sum := true),
    .ok (item (k := .blocks) (sum := true))⟩,
  ⟨"mt-c3-guard-fail-safe-without-orbit-kb", .agent, .rotate true false, item (k := .unknown) (sum := true),
    .ok (item (k := .unknown) (sum := true))⟩,
  ⟨"mt-c3-guard-clear-summary-lapses", .agent, .rotate true false, item (k := .clear) (sum := true),
    .ok (item (st := .lapsed) (k := .clear) (sum := true))⟩,
  ⟨"t40-c10-triage-gate-refuses-the-rotation", .agent, .rotate true true, item (sum := true), .refused⟩,
  ⟨"t40-c13-escalated-item-stays-open", .script, .skipWrite, item (e := true) (k := .clear) (pl := true),
    .ok (item (e := true) (k := .clear))⟩,
  ⟨"t40-c13-non-escalated-item-parked", .script, .skipWrite, item (k := .clear) (pl := true),
    .ok (item (k := .clear) (pk := true))⟩,
  ⟨"t42-c2-clear-waived-item-is-parked (read)", .script, .skipRead true, item (k := .clear),
    .ok (item (k := .clear) (pl := true))⟩,
  ⟨"t42-c2-kb-that-starts-to-block-stays-open-not-parked", .script, .skipWrite, item (k := .blocks) (pl := true),
    .ok (item (k := .blocks))⟩,
  ⟨"t42-c2-blocking-ref-added-stays-open-not-parked", .script, .skipWrite, item (k := .blocks) (pl := true),
    .ok (item (k := .blocks))⟩,
  ⟨"t42-c2-unknown-kb-in-the-write-stays-open", .script, .skipWrite, item (k := .unknown) (pl := true),
    .ok (item (k := .unknown))⟩,
  ⟨"t42-c5-precaution-check-waiver-does-not-park (read)", .script, .skipRead false, item (k := .clear),
    .ok (item (k := .clear))⟩,
  ⟨"t42-c5-precaution-check-waiver-does-not-park (write)", .script, .skipWrite, item (k := .clear),
    .ok (item (k := .clear))⟩,
  ⟨"c2-human-may-lapse-blocking", me, .triage .lapse, item (e := true) (k := .blocks),
    .ok (item (st := .lapsed) (k := .blocks))⟩,
  ⟨"c2-agent-close-dropped-of-blocking-refused", .agent, .close .dropped, item (k := .blocks), .refused⟩,
  ⟨"c2-agent-close-done-of-blocking-refused", .agent, .close .done, item (k := .blocks), .refused⟩,
  ⟨"c2-agent-close-failsafe-refused", .agent, .close .dropped, item (k := .unknown), .refused⟩,
  ⟨"c2-agent-close-of-clear-item", .agent, .close .dropped, item (k := .clear),
    .ok (item (st := .dropped) (k := .clear))⟩,
  ⟨"c2-human-close-of-blocking", me, .close .dropped, item (k := .blocks),
    .ok (item (st := .dropped) (k := .blocks))⟩,
  ⟨"c2-agent-kb-ref-rm-refused escalated", .agent, .refRmKb .none, item (e := true) (k := .clear), .refused⟩,
  ⟨"c2-agent-kb-ref-rm-refused would-be-blocking", .agent, .refRmKb .none, item (k := .blocks), .refused⟩,
  ⟨"c2-agent-kb-ref-rm-of-clear-item", .agent, .refRmKb .none, item (k := .clear), .ok item⟩,
  ⟨"c2-human-kb-ref-rm", me, .refRmKb .none, item (k := .blocks), .ok item⟩,
  ⟨"c2-agent-renew-of-guarded-item-refused", .agent, .renew, item (e := true) (k := .clear), .refused⟩,
  ⟨"c2-agent-park-of-guarded-item-refused", .agent, .park, item (k := .blocks), .refused⟩,
  ⟨"c2-agent-set-status-of-guarded-item-refused", .agent, .setStatus .waiting, item (e := true) (k := .clear), .refused⟩,
  ⟨"c2-agent-renew-of-clear-item", .agent, .renew, item (k := .clear), .ok (item (k := .clear))⟩,
  ⟨"c2-human-renew-of-guarded-item", me, .renew, item (k := .blocks), .ok (item (k := .blocks))⟩,
  ⟨"c2-agent-lapse-of-escalated-stays clear-kb", .agent, .triage .lapse, item (e := true) (k := .clear),
    .ok (item (e := true) (k := .clear))⟩,
  ⟨"c2-agent-lapse-of-escalated-stays no-kb", .agent, .triage .lapse, item (e := true),
    .ok (item (e := true))⟩,
  ⟨"c2-agent-keep-of-escalated-stays-escalated", .agent, .triage .keep, item (e := true),
    .ok (item (e := true))⟩,
  ⟨"c2-agent-close-after-agent-keep-refused", .agent, .close .dropped, item (e := true), .refused⟩,
  ⟨"c2-human-keep-of-escalated", .human "\"keep it, I decided\" (Me)", .triage .keep,
    item (e := true) (k := .clear), .ok (item (k := .clear))⟩
]

def Row.pass (r : Row) : Bool := step r.actor r.cmd r.start == r.expect

#eval rows.map fun r => (r.check, if r.pass then "PASS" else "FAIL")

/-- Every row holds (checked by the kernel, not only by #eval). -/
theorem rows_pass : rows.all Row.pass = true := by decide

/-! ## The commands of hubflow.py's COMMANDS table (read by check_commands.py) -/

/-- Commands that act on an existing item, with their `Cmd`. -/
def modelledCommands : List (String × String) := [
  ("renew", "Cmd.renew"),
  ("park", "Cmd.park"),
  ("set", "Cmd.setStatus, Cmd.setFields"),
  ("close", "Cmd.close; human_skip of a linked item: Cmd.skipLinked"),
  ("reopen", "Cmd.reopen"),
  ("ref", "Cmd.refAddKb, Cmd.refRmKb, Cmd.refOther"),
  ("link", "Cmd.link (no change; it only enables Cmd.skipLinked)"),
  ("note", "Cmd.note"),
  ("accept", "Cmd.accept"),
  ("capsule", "Cmd.capsule"),
  ("triage", "Cmd.triage"),
  ("rotate", "Cmd.rotate (prunes closed items; lapses an old open summary row unless it is escalated or its kb answer is not clear; the triage gate refuses it, and counts no summary row; check_commands.py checks both in hubflow.py)"),
  ("skip-waived", "Cmd.skipRead, then Cmd.skipWrite (the write parks a planned open item whose kb answer, read again in the write, is clear, unless it is escalated; it never drops one; check_commands.py checks the escalated filter, the recheck and the park inside the write in hubflow.py)")
]

/-- Commands left out, each with the reason. -/
def excludedCommands : List (String × String) := [
  ("init", "makes a new db; refuses when the db exists"),
  ("add", "makes a new item; no existing item changes"),
  ("handoff", "makes a new handoff item; no existing item changes"),
  ("import", "makes new items only (new_item); no existing item changes"),
  ("show", "read-only"),
  ("view", "read-only"),
  ("sql", "read-only (query_only, SELECT authorizer)"),
  ("where", "read-only"),
  ("transcripts", "read-only"),
  ("check", "read-only (rolls back)"),
  ("export", "writes the JSONL copy of the db; no row changes"),
  ("rebuild", "only when the db is missing; loads the JSONL copy (editing that copy is outside the model)"),
  ("migrate", "schema upgrade; item rows and the escalated rule stay"),
  ("session", "session rows and owner_session only; status is not touched"),
  ("index-transcripts", "transcript tables only"),
  ("spec-triage", "changes no item row: it refuses while an item of kb:SLUG is open, and writes one spec_triage event with no item id (an agent's decision on a blocking spec KB becomes escalate in that event, not on an item); check_commands.py checks this in hubflow.py (changes_no_item)")
]

end LedgerGuard

open LedgerGuard in
#print axioms agent_run_keeps_guarded
open LedgerGuard in
#print axioms agent_run_keeps_escalated
open LedgerGuard in
#print axioms human_close_leaves_view
open LedgerGuard in
#print axioms human_lapse_leaves_view
open LedgerGuard in
#print axioms rotate_lapses_unguarded_summary
open LedgerGuard in
#print axioms agent_run_keeps_guarded_unparked
open LedgerGuard in
#print axioms skip_read_write_parks_unescalated
open LedgerGuard in
#print axioms rows_pass

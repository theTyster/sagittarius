/-!
# The vote, readiness and the open discovery orbit (0.3.0, claim c_k_d_1b; vote-start c17)

The claim (spec KB `tmp/kb-sagittarius-030`, `c_k_d_1b`): "While the discovery orbit of a KB is
open, GO cannot win the gate when discovery is not ready: the tool refuses an agent's GO vote then
and says what blocks, and gate(go) does not hold. The human's vote is never refused."

Its last sentence was "After the human approves the ticket, a later change in the build does not
take the GO back." Claim c17 of the spec KB `vote-start` replaces it (Ty, q9: "Claims need my
vote; checks need another pane"): the approval is no exception. After the vote of the human (also
after the approval), a goal, hypothesis or claim that is added, replaced, struck or retired takes
the GO back (gate hold) until the human votes on that change; a confirmation of another pane does
not stand in. A check that is added or changed takes it back until a pane that did not make the
change confirms it, or the human votes on it. A note, a finding, an answer, or a rerun of a check
by the same command and script leaves the GO. A return to discovery (`back`) is unchanged.

A model of the vote rules of `kb/share/orbit-kb/modules/discovery.pl` (`vote_cast/3`,
`vote_round/1`, `human_vote/1`, `agent_vote/1`, `artifact_vote/1`, `gate_allowed/1`, `gate/1`,
`discovery_human_vote_changed/0`, `discovery_closed/0`, `discovery_ready/0`), of the computed
`vote_void/1`, `vote_changed/1` and `vote_carry/1` (`vote_void_derived/3`,
`vote_changed_derived/3`, `vote_spec_changed/4`, `vote_carried/3`, `vote_carried_check/3`,
`check_changed_since/5` in `kb/bin/orbit-kb`), and of what `orbit-kb attest` does for `vote`,
`confirmation` of a check, `approval` of the ticket, and `back` (`go_vote_check/4`,
`late_vote_check/4`, `back_check/4`, `end_lines/8`). CONTRACT D33 R5 and D30 H4 to H9 (the review
of K-A: a new round of votes and readiness after `attest back`; closing does not rewrite the record
of a round; a stale approval does not close). The proof is about these definitions, not about the
code. Test RD6 of `kb/tests/test_orbit_kb.sh` carries the examples of `#eval examples` below to
the CLI.

What the model holds:
* `Ev`: the lines of `kb.pl` that the vote and the orbit read, in their order: a vote on the
  ticket, a record of the specification (`Change`), a vote of the human that names such a record
  (a carry vote), a valid confirmation of a check, a `discovery_end` record, a `back`
  attestation, or any other line.
* `S.clean`: no `ready_blocker` answers (the model `kb/proofs/open_items` shows that this is
  readiness as the conjunction of its conditions). A command can set it to any value.
* `Entry`: a vote on the ticket that no `back` follows, whether it came while the orbit was closed
  (`vote_void/1`), and the changes of the specification after it that no carry vote and no valid
  confirmation carried yet (`pending`). A vote with a pending change is `vote_changed/1`.
* `S.votes`: the votes that count (`vote_cast/3`): not void, and no pending change.

Abstractions (what the model leaves out):
* The text of the refusal. The model says only that the agent's GO is refused; the CLI lists each
  `ready_blocker` in it (test RD5).
* `discovery_end` of something that is no human approval of the ticket (lint ED11): such a line
  closes nothing, so it is an `other` line here.
* `back` on a subject that is no hypothesis: refused by the CLI like a `back` in an open orbit.
* One vote per writer per round (ED10) is not assumed: a choice is in the vote of a writer when
  any vote of that writer in the current round has it.
* The edges of the upgrade (`vote_epoch/1`, `approval_epoch/1`): the model holds a KB made by
  the orbit-kb of c17, in which no record is grandfathered.
* A check that changed with no line of `kb.pl` (a file that its command names has another digest
  now, run or not: `run_input_file_changed/3`) is not modeled. A run by another command or script
  is a change of the check (`Step.run k false`); `check_changed_since/5` also lets a vote of the
  human on the check carry it with any choice, where the model asks for the choice of the vote it
  carries, as `vote_carried/3` does for a record.
* A confirmation is valid or not (`valid_check_confirm/4`: another role and another session than
  the run of the newest record of the check, and the check has a record): the model takes that as
  given (`Step.confirm k valid`).
* A carry vote of an agent carries nothing and is no round of votes: it is an `other` line, so
  the model has no step for it.

A limit that remains (the review of K-C and K-D, item 2): `Ev.endRec` is a `discovery_end` that
`attest approval` wrote after a GO. A `discovery_end` written by hand that names a real human
approval of the ticket, which came with no GO, is a line that the model does not hold: the rules
of the orbit close on it, so the theorems do not cover that KB. Lint error ED12 (CONTRACT D41)
names such a line: it reads the KB as it was before the approval and asks for an open orbit,
`gate(go)` and the artifacts' go. ED12 is a lint error, not a rule: until the line is removed,
the orbit stays closed, and a hand edit can also forge the votes before the approval.

A consequence of the rules that the model shows (`go_stays_after_approval` needs `settled`): a
vote that a change took back before the approval can count again after it, when a carry vote or
a confirmation that comes after the approval carries that change. So the theorems about the GO
after the approval assume that no change waited for a vote when the human approved.
-/
namespace GateReady

inductive By where
  | human | agent
  deriving DecidableEq, Repr

inductive Choice where
  | go | noGo | hold
  deriving DecidableEq, Repr

/-- What a record of the specification is (`spec_change/2`). -/
inductive Kind where
  | spec   -- a goal, hypothesis or claim (or its example) added, replaced, struck or retired
  | check  -- a check added, or run by another command or script
  deriving DecidableEq, Repr

/-- A record of the specification: its kind, its id, and the other ids that a vote names it by
(`spec_ids/2`: the claim of a check). -/
structure Change where
  kind : Kind
  id : String
  also : List String
  deriving DecidableEq, Repr

/-- A carry vote that names `n` names this record (`spec_ids/2`). -/
def Change.named (ch : Change) (n : String) : Bool := ch.id == n || ch.also.contains n

/-- A line of `kb.pl` that the vote and the orbit read. -/
inductive Ev where
  | vote (b : By) (round : Nat) (c : Choice)  -- a vote on the ticket
  | change (ch : Change)                      -- a record of the specification (c6, c14, c17)
  | carry (n : String) (c : Choice)           -- a vote of the human that names record n (c11)
  | confirm (k : String)                      -- a valid confirmation of check k (c15)
  | endRec   -- discovery_end(A): attest approval of the ticket wrote it (D30 H4, H6, H7)
  | back     -- a back attestation (D30 H4)
  | other    -- any other line: a note, a finding, an answer, a run by the same command
  deriving DecidableEq, Repr

structure S where
  log : List Ev
  clean : Bool        -- no ready_blocker answers
  someCurrent : Bool  -- discovery_some_current
  deriving Repr

abbrev V := By × Nat × Choice

/-- A vote on the ticket that no `back` follows. -/
structure Entry where
  v : V
  void : Bool              -- it came while the orbit was closed (vote_void/1, D30 H8)
  pending : List Change    -- the changes after it that nothing carried yet (vote_changed/1)
  deriving DecidableEq, Repr

/-- One line of `kb.pl`: the votes so far, and whether the orbit is closed. -/
def step (st : List Entry × Bool) : Ev → List Entry × Bool
  | .vote b r c => (st.1 ++ [⟨(b, r, c), st.2, []⟩], st.2)
  | .change ch => (st.1.map (fun e => { e with pending := e.pending ++ [ch] }), st.2)
  | .carry n c =>
      (st.1.map (fun e => if e.v.2.2 == c then
        { e with pending := e.pending.filter (fun ch => !ch.named n) } else e), st.2)
  | .confirm k =>
      (st.1.map (fun e =>
        { e with pending := e.pending.filter (fun ch => !(ch.kind == .check && ch.id == k)) }),
       st.2)
  | .endRec => (st.1, true)
  | .back => ([], false)
  | .other => st

def scan (log : List Ev) : List Entry × Bool := log.foldl step ([], false)

def S.entries (s : S) : List Entry := (scan s.log).1
/-- `vote_cast/3`: the votes that are not void and that no change took back. -/
def S.votes (s : S) : List V :=
  (s.entries.filter (fun e => !e.void && e.pending.isEmpty)).map Entry.v
/-- `discovery_closed`: a discovery_end that no back follows. -/
def S.closed (s : S) : Bool := (scan s.log).2
/-- `discovery_human_vote_changed`: a change took a vote of the human back. -/
def S.humanChanged (s : S) : Bool :=
  s.entries.any (fun e => e.v.1 == By.human && !e.pending.isEmpty)
/-- No change waits for a vote or a confirmation. -/
def S.settled (s : S) : Bool := s.entries.all (fun e => e.pending.isEmpty)
/-- `discovery_ready :- discovery_closed.` and `discovery_ready :- discovery_open, not any_ready_blocker.` -/
def S.ready (s : S) : Bool := s.closed || s.clean
/-- `vote_round/1`: the largest round with a vote that counts. -/
def S.round (s : S) : Nat := s.votes.foldl (fun m v => max m v.2.1) 0

def S.voted (s : S) (b : By) (c : Choice) : Bool :=
  s.votes.any (fun v => v.1 == b && v.2.1 == s.round && v.2.2 == c)
def S.humanVoted (s : S) : Bool :=
  s.votes.any (fun v => v.1 == By.human && v.2.1 == s.round)

/-- `artifact_vote/1` (D14 V2, D30 H6): go once the orbit is closed. -/
def S.artifact (s : S) : Choice :=
  if s.closed then .go
  else if s.clean then (if s.someCurrent then .go else .noGo)
  else .hold

/-- `gate_allowed/1` (D33 R5). -/
def S.allowed (s : S) (c : Choice) : Bool := c != .go || s.ready

/-- `discovery_gate_agreed`: the human and another role vote the same. -/
def S.agreed (s : S) : Bool :=
  [Choice.go, .noGo, .hold].any (fun c => s.voted .human c && (s.voted .agent c || s.artifact == c))

/-- `gate/1`. The last clause is vote-start c6: a change took the vote of the human back, and no
vote of the human counts. -/
def S.gate (s : S) (c : Choice) : Bool :=
  (s.voted .human c && s.voted .agent c && s.allowed c) ||
  (s.voted .human c && s.artifact == c && s.allowed c) ||
  (c == .hold && s.humanVoted && !s.agreed) ||
  (c == .hold && s.voted .human .go && !s.allowed .go) ||
  (c == .hold && s.humanChanged && !s.humanVoted)

/-- What `attest vote` refuses: an agent vote after the orbit closed (D30 H8), an agent GO while
the orbit is open and discovery is not ready (D33 R5), and a late agent vote in a round in which
the human voted (D14 V4). -/
def S.refuseVote (s : S) (b : By) (c : Choice) (r : Nat) : Bool :=
  b == .agent &&
    (s.closed || (c == .go && !s.ready) ||
     s.votes.any (fun v => v.1 == By.human && v.2.1 == r))

/-- `end_lines/8`: an approval of the ticket ends the orbit when the orbit is open, the approval
is not stale, gate(go) holds and the artifacts vote go (D30 H4, H6, H7). -/
def S.ends (s : S) (stale : Bool) : Bool := !s.closed && !stale && s.gate .go && s.artifact == .go

/-- What a command does to the KB. -/
inductive Step where
  | build (clean someCurrent : Bool)  -- a note, a finding, an answer: no part of the specification
  | spec (chs : List Change) (clean someCurrent : Bool)  -- records of the specification
  | run (k : String) (same : Bool) (clean someCurrent : Bool)  -- a run of check k, by the same
                                      -- command and script as its record before, or not
  | vote (b : By) (c : Choice) (r : Nat)
  | carry (n : String) (c : Choice)   -- attest vote N 'vote(R, C)' --by human: the human votes on
                                      -- the record N
  | confirm (k : String) (valid : Bool)  -- attest confirmation K 'check_change(TEXT)' by a pane
  | approve (stale : Bool)            -- attest approval of the ticket by the human
  | back
  deriving DecidableEq, Repr

/-- The records of the specification that a command writes. -/
def Step.changes : Step → List Change
  | .spec chs _ _ => chs
  | .run k false _ _ => [⟨.check, k, []⟩]
  | _ => []

def S.apply (s : S) : Step → S
  | .build cl cur => { log := s.log ++ [.other], clean := cl, someCurrent := cur }
  | .spec chs cl cur => { log := s.log ++ chs.map Ev.change, clean := cl, someCurrent := cur }
  | .run k same cl cur =>
      { log := s.log ++ (if same then [.other] else [Ev.change ⟨.check, k, []⟩]), clean := cl,
        someCurrent := cur }
  | .vote b c r => if s.refuseVote b c r then s else { s with log := s.log ++ [.vote b r c] }
  | .carry n c => { s with log := s.log ++ [.carry n c] }
  | .confirm k valid => { s with log := s.log ++ [if valid then .confirm k else .other] }
  | .approve stale =>
      -- the approval is always written; discovery_end only when the orbit is open, the approval
      -- is not stale, gate(go) holds and the artifacts vote go (D30 H4, H6, H7)
      { s with log := s.log ++ [.other] ++ (if s.ends stale then [.endRec] else []) }
  | .back => if s.closed then { s with log := s.log ++ [.back] } else s

def S.run (s : S) : List Step → S
  | [] => s
  | st :: sts => (s.apply st).run sts

/-! ## Lemmas about the scan of kb.pl -/

theorem scan_append (l : List Ev) (e : Ev) : scan (l ++ [e]) = step (scan l) e := by
  simp [scan, List.foldl_append]

theorem scan_changes (l : List Ev) (chs : List Change) :
    scan (l ++ chs.map Ev.change) =
      ((scan l).1.map (fun e => { e with pending := e.pending ++ chs }), (scan l).2) := by
  induction chs generalizing l with
  | nil =>
    simp only [List.map_nil, List.append_nil]
    generalize scan l = p
    rcases p with ⟨a, b⟩
    simp only [Prod.mk.injEq, and_true]
    conv => lhs; rw [← List.map_id a]
    apply List.map_congr_left
    intro e _; cases e; simp
  | cons ch chs ih =>
    have : l ++ (ch :: chs).map Ev.change = (l ++ [Ev.change ch]) ++ chs.map Ev.change := by simp
    rw [this, ih, scan_append]
    simp [step, List.map_map, Function.comp_def]

theorem votes_other (s : S) (cl cur : Bool) :
    ({ log := s.log ++ [Ev.other], clean := cl, someCurrent := cur } : S).entries = s.entries ∧
    ({ log := s.log ++ [Ev.other], clean := cl, someCurrent := cur } : S).closed = s.closed := by
  simp [S.entries, S.closed, scan_append, step]

theorem approve_entries (s : S) (stale : Bool) : (s.apply (.approve stale)).entries = s.entries := by
  unfold S.apply
  cases h : s.ends stale <;> simp [h, S.entries, scan, List.foldl_append, step]

theorem approve_votes (s : S) (stale : Bool) : (s.apply (.approve stale)).votes = s.votes := by
  simp [S.votes, approve_entries]

theorem approve_closed (s : S) (stale : Bool) :
    (s.apply (.approve stale)).closed = (s.closed || s.ends stale) := by
  unfold S.apply
  cases h : s.ends stale <;> simp [h, S.closed, scan, List.foldl_append, step]

/-- The vote of a writer depends only on the votes that count. -/
theorem voted_eq {s t : S} (h : s.votes = t.votes) (b : By) (c : Choice) :
    s.voted b c = t.voted b c := by
  simp [S.voted, S.round, h]

theorem humanVoted_of_voted {s : S} {c : Choice} (h : s.voted .human c = true) :
    s.humanVoted = true := by
  simp only [S.voted, S.humanVoted, List.any_eq_true, Bool.and_eq_true] at h ⊢
  obtain ⟨v, hv, ⟨h1, h2⟩, _⟩ := h
  exact ⟨v, hv, h1, h2⟩

/-- On a vote with no pending change, a map that only filters `pending` does nothing. -/
theorem map_settled {l : List Entry} (hs : l.all (fun e => e.pending.isEmpty) = true)
    (f : Entry → Entry) (hf : ∀ e, e.pending = [] → f e = e) : l.map f = l := by
  conv => rhs; rw [← List.map_id l]
  apply List.map_congr_left
  intro e he
  simp only [List.all_eq_true, List.isEmpty_iff] at hs
  exact hf e (hs e he)

/-! ## The claim -/

/-- GO does not win the gate while the orbit is open and discovery is not ready. -/
theorem no_go_while_not_ready (s : S) (ho : s.closed = false) (hn : s.clean = false) :
    s.gate .go = false := by
  have : s.allowed .go = false := by simp [S.allowed, S.ready, ho, hn]
  simp [S.gate, this]

/-- The tool refuses an agent's GO vote then. -/
theorem agent_go_refused (s : S) (ho : s.closed = false) (hn : s.clean = false) (r : Nat) :
    s.refuseVote .agent .go r = true := by
  simp [S.refuseVote, S.ready, ho, hn]

/-- The human's vote is never refused. -/
theorem human_never_refused (s : S) (c : Choice) (r : Nat) : s.refuseVote .human c r = false := by
  simp [S.refuseVote]

/-- After closure: the orbit is closed, the human voted go in the round that counts, and no change
waits for a vote. -/
def ClosedGo (s : S) : Prop := s.closed = true ∧ s.voted .human .go = true ∧ s.settled = true

theorem gate_of_closedGo (s : S) (h : ClosedGo s) : s.gate .go = true := by
  obtain ⟨hc, hv, _⟩ := h
  simp [S.gate, S.artifact, S.allowed, S.ready, hc, hv]

theorem human_go_of_gate (s : S) (h : s.gate .go = true) : s.voted .human .go = true := by
  simp only [S.gate, Bool.or_eq_true, Bool.and_eq_true] at h
  rcases h with (((⟨⟨h, _⟩, _⟩ | ⟨⟨h, _⟩, _⟩) | ⟨⟨h, _⟩, _⟩) | ⟨⟨h, _⟩, _⟩) | ⟨⟨h, _⟩, _⟩
  · exact h
  · exact h
  · simp at h
  · simp at h
  · simp at h

/-- When `attest approval` ends the orbit of a KB in which no change waits for a vote, the GO of
the round stays in the record. -/
theorem approve_closes (s : S) (stale : Bool) (ho : s.closed = false) (hs : s.settled = true)
    (hc : (s.apply (.approve stale)).closed = true) : ClosedGo (s.apply (.approve stale)) := by
  rw [approve_closed, ho, Bool.false_or] at hc
  have hg : s.gate .go = true := by
    simp only [S.ends, Bool.and_eq_true] at hc; exact hc.1.2
  refine ⟨by rw [approve_closed, ho, Bool.false_or]; exact hc, ?_, ?_⟩
  · rw [voted_eq (approve_votes s stale)]
    exact human_go_of_gate s hg
  · simp only [S.settled, approve_entries]; exact hs

theorem closedGo_of {s t : S} (h : ClosedGo s) (he : t.entries = s.entries)
    (hc : t.closed = s.closed) : ClosedGo t := by
  obtain ⟨h1, h2, h3⟩ := h
  have hv : t.votes = s.votes := by simp [S.votes, he]
  refine ⟨hc ▸ h1, (voted_eq hv _ _).trans h2, ?_⟩
  simp only [S.settled, he]; exact h3

/-- Every command but `back` and a change of the specification keeps `ClosedGo`: a note, a
finding, an answer, a run of a check by the same command, a vote, a carry vote, a confirmation and
an approval leave the record of the round that closed the orbit. (Before vote-start c17: every
command but `back`.) -/
theorem closedGo_step (s : S) (h : ClosedGo s) (st : Step) (hb : st ≠ .back)
    (hn : st.changes = []) : ClosedGo (s.apply st) := by
  have hc : (scan s.log).2 = true := h.1
  have hs : s.entries.all (fun e => e.pending.isEmpty) = true := h.2.2
  cases st with
  | build cl cur =>
    obtain ⟨h1, h2⟩ := votes_other s cl cur
    exact closedGo_of h h1 h2
  | spec chs cl cur =>
    simp only [Step.changes] at hn; subst hn
    exact closedGo_of h (by simp [S.apply, S.entries]) (by simp [S.apply, S.closed])
  | run k same cl cur =>
    cases same with
    | false => simp [Step.changes] at hn
    | true =>
      obtain ⟨h1, h2⟩ := votes_other s cl cur
      exact closedGo_of h (by simpa [S.apply] using h1) (by simpa [S.apply] using h2)
  | vote b c r =>
    simp only [S.apply]
    split
    · exact h
    · -- a vote while the orbit is closed is void: it counts for nothing and waits for nothing
      obtain ⟨_, h2, h3⟩ := h
      have he : scan (s.log ++ [Ev.vote b r c]) =
          ((scan s.log).1 ++ [⟨(b, r, c), true, []⟩], (scan s.log).2) := by
        rw [scan_append]; simp [step, hc]
      have hv : ({ s with log := s.log ++ [Ev.vote b r c] } : S).votes = s.votes := by
        simp [S.votes, S.entries, he]
      refine ⟨by simp [S.closed, he, hc], (voted_eq hv _ _).trans h2, ?_⟩
      simpa [S.settled, S.entries, he] using h3
  | carry n c =>
    refine closedGo_of h ?_ (by simp [S.apply, S.closed, scan_append, step])
    simp only [S.apply, S.entries, scan_append, step]
    exact map_settled hs _ (fun e he => by cases e; simp_all)
  | confirm k valid =>
    cases valid with
    | false =>
      obtain ⟨h1, h2⟩ := votes_other s s.clean s.someCurrent
      exact closedGo_of h (by simpa [S.apply] using h1) (by simpa [S.apply] using h2)
    | true =>
      refine closedGo_of h ?_ (by simp [S.apply, S.closed, scan_append, step])
      simp only [S.apply, S.entries, scan_append, step, ite_true]
      exact map_settled hs _ (fun e he => by cases e; simp_all)
  | approve stale =>
    exact closedGo_of h (approve_entries s stale) (by rw [approve_closed, h.1]; rfl)
  | back => exact absurd rfl hb

theorem closedGo_run (s : S) (h : ClosedGo s) (sts : List Step)
    (hb : ∀ st ∈ sts, st ≠ .back ∧ st.changes = []) : ClosedGo (s.run sts) := by
  induction sts generalizing s with
  | nil => exact h
  | cons st sts ih =>
    simp only [S.run]
    have := hb st (by simp)
    exact ih _ (closedGo_step s h st this.1 this.2) (fun x hx => hb x (by simp [hx]))

/-- After the human approves the ticket (the approval ends the orbit, and no change waited for a
vote), no later command but `back` or a change of the specification takes the GO back. (Before
vote-start c17: no command but `back`, and no premise about waiting changes.) -/
theorem go_stays_after_approval (s : S) (stale : Bool) (ho : s.closed = false)
    (hs : s.settled = true) (hc : (s.apply (.approve stale)).closed = true)
    (sts : List Step) (hb : ∀ st ∈ sts, st ≠ .back ∧ st.changes = []) :
    ((s.apply (.approve stale)).run sts).gate .go = true :=
  gate_of_closedGo _ (closedGo_run _ (approve_closes s stale ho hs hc) sts hb)

/-- Claim c_k_d_1b, with its last part as vote-start c17 left it. -/
theorem c_k_d_1b :
    (∀ s : S, s.closed = false → s.clean = false →
        s.gate .go = false ∧ ∀ r, s.refuseVote .agent .go r = true) ∧
    (∀ (s : S) c r, s.refuseVote .human c r = false) ∧
    (∀ (s : S) stale, s.closed = false → s.settled = true →
        (s.apply (.approve stale)).closed = true →
        ∀ sts : List Step, (∀ st ∈ sts, st ≠ .back ∧ st.changes = []) →
          ((s.apply (.approve stale)).run sts).gate .go = true) :=
  ⟨fun s ho hn => ⟨no_go_while_not_ready s ho hn, agent_go_refused s ho hn⟩,
   human_never_refused,
   go_stays_after_approval⟩

/-! ## vote-start c17: a change of the specification takes the GO back, also after approval -/

/-- When each vote waits for a change and the human voted, the gate says hold, and nothing else. -/
theorem hold_of_pending (s : S) (hp : ∀ e ∈ s.entries, e.pending ≠ [])
    (hh : ∃ e ∈ s.entries, e.v.1 = .human) :
    s.gate .hold = true ∧ s.gate .go = false ∧ s.gate .noGo = false := by
  have hv : s.votes = [] := by
    simp only [S.votes, List.map_eq_nil_iff, List.filter_eq_nil_iff, Bool.and_eq_true,
      Bool.not_eq_eq_eq_not, Bool.not_true, List.isEmpty_iff]
    intro e he ⟨_, h2⟩; exact hp e he h2
  have hc : s.humanChanged = true := by
    obtain ⟨e, he, h1⟩ := hh
    simp only [S.humanChanged, List.any_eq_true, Bool.and_eq_true, Bool.not_eq_eq_eq_not,
      Bool.not_true, List.isEmpty_eq_false_iff]
    exact ⟨e, he, by simp [h1], hp e he⟩
  simp [S.gate, S.voted, S.humanVoted, hv, hc]

/-- The entries after a command that writes records of the specification. -/
theorem changes_entries (s : S) (st : Step) (hn : st.changes ≠ []) :
    (s.apply st).entries = s.entries.map (fun e => { e with pending := e.pending ++ st.changes }) ∧
    (s.apply st).closed = s.closed := by
  cases st with
  | spec chs cl cur =>
    simp [S.apply, S.entries, S.closed, Step.changes, scan_changes]
  | run k same cl cur =>
    cases same with
    | true => simp [Step.changes] at hn
    | false =>
      have := scan_changes s.log [⟨.check, k, []⟩]
      simp only [List.map_cons, List.map_nil] at this
      simp [S.apply, S.entries, S.closed, Step.changes, this]
  | _ => simp [Step.changes] at hn

/-- c17: after a vote of the human that counts (the orbit open or closed), a command that writes a
goal, hypothesis, claim or check, or runs a check by another command, takes the GO back: the gate
says hold. (Before c17, after the approval: the gate stayed go.) -/
theorem change_takes_go_back (s : S) (hv : s.humanVoted = true) (st : Step)
    (hn : st.changes ≠ []) :
    (s.apply st).gate .hold = true ∧ (s.apply st).gate .go = false ∧
      (s.apply st).gate .noGo = false := by
  obtain ⟨he, _⟩ := changes_entries s st hn
  apply hold_of_pending
  · intro e hm
    rw [he] at hm
    obtain ⟨e0, _, rfl⟩ := List.mem_map.mp hm
    simp [hn]
  · simp only [S.humanVoted, S.votes, List.any_eq_true, List.mem_map, List.mem_filter,
      Bool.and_eq_true, beq_iff_eq] at hv
    obtain ⟨_, ⟨e, ⟨hm, _⟩, rfl⟩, h1, _⟩ := hv
    exact ⟨{ e with pending := e.pending ++ st.changes }, by rw [he]; exact List.mem_map.mpr ⟨e, hm, rfl⟩, h1⟩

/-- c17 after the approval: the orbit stays closed, and the gate says hold. -/
theorem change_after_closure_holds (s : S) (h : ClosedGo s) (st : Step) (hn : st.changes ≠ []) :
    (s.apply st).closed = true ∧ (s.apply st).gate .hold = true ∧
      (s.apply st).gate .go = false :=
  ⟨(changes_entries s st hn).2.trans h.1,
   (change_takes_go_back s (humanVoted_of_voted h.2.1) st hn).1,
   (change_takes_go_back s (humanVoted_of_voted h.2.1) st hn).2.1⟩

/-- c17: a valid confirmation of another pane does not stand in for the vote of the human on a
goal, hypothesis or claim. -/
theorem confirm_does_not_carry_spec (s : S) (h : ClosedGo s) (ch : Change) (hk : ch.kind = .spec)
    (cl cur : Bool) (k : String) :
    let t := (s.apply (.spec [ch] cl cur)).apply (.confirm k true)
    t.gate .hold = true ∧ t.gate .go = false := by
  intro t
  have ht : t.entries = s.entries.map (fun e => { e with pending := e.pending ++ [ch] }) := by
    have hall : ∀ e ∈ s.entries, e.pending = [] := by
      have hs := h.2.2
      simp only [S.settled, List.all_eq_true, List.isEmpty_iff] at hs; exact hs
    simp only [t, S.apply, ite_true, S.entries, scan_append, scan_changes, step, List.map_map]
    apply List.map_congr_left
    intro e hm
    have h0 := hall e hm
    cases e with
    | mk v vd p => simp only at h0; subst h0; simp [hk]
  have hv := humanVoted_of_voted h.2.1
  have r := hold_of_pending t
    (by intro e hm; rw [ht] at hm; obtain ⟨_, _, rfl⟩ := List.mem_map.mp hm; simp)
    (by
      simp only [S.humanVoted, S.votes, List.any_eq_true, List.mem_map, List.mem_filter,
        Bool.and_eq_true, beq_iff_eq] at hv
      obtain ⟨_, ⟨e, ⟨hm, _⟩, rfl⟩, h1, _⟩ := hv
      exact ⟨{ e with pending := e.pending ++ [ch] }, by rw [ht]; exact List.mem_map.mpr ⟨e, hm, rfl⟩, h1⟩)
  exact ⟨r.1, r.2.1⟩

/-- c17, c15: after the approval, a valid confirmation of a check that was added or changed gives
the GO back: the record of the round is as it was. -/
theorem confirm_gives_go_back (s : S) (h : ClosedGo s) (k : String) (also : List String)
    (cl cur : Bool) :
    ClosedGo ((s.apply (.spec [⟨.check, k, also⟩] cl cur)).apply (.confirm k true)) := by
  have hs : s.entries.all (fun e => e.pending.isEmpty) = true := h.2.2
  refine closedGo_of h ?_ ?_
  · simp only [S.apply, ite_true, S.entries, scan_append, scan_changes, step, List.map_map]
    exact map_settled hs _ (fun e he => by cases e; simp_all)
  · simp only [S.apply, ite_true, S.closed, scan_append, scan_changes, step]

/-- The same after a run of the check by another command. -/
theorem confirm_gives_go_back_run (s : S) (h : ClosedGo s) (k : String) (cl cur : Bool) :
    ClosedGo ((s.apply (.run k false cl cur)).apply (.confirm k true)) := by
  have := confirm_gives_go_back s h k [] cl cur
  simpa [S.apply] using this

/-! ### Lemmas about the round -/

theorem foldl_max_ge (l : List V) (m : Nat) : m ≤ l.foldl (fun m v => max m v.2.1) m := by
  induction l generalizing m with
  | nil => exact Nat.le_refl _
  | cons v l ih => exact Nat.le_trans (Nat.le_max_left _ _) (ih _)

theorem le_foldl_max (l : List V) (m : Nat) (v : V) (hv : v ∈ l) :
    v.2.1 ≤ l.foldl (fun m v => max m v.2.1) m := by
  induction l generalizing m with
  | nil => simp at hv
  | cons w l ih =>
    simp only [List.foldl_cons]
    rcases List.mem_cons.mp hv with rfl | hv
    · exact Nat.le_trans (Nat.le_max_right _ _) (foldl_max_ge _ _)
    · exact ih _ hv

theorem foldl_max_le (l : List V) (m b : Nat) (hm : m ≤ b) (hl : ∀ v ∈ l, v.2.1 ≤ b) :
    l.foldl (fun m v => max m v.2.1) m ≤ b := by
  induction l generalizing m with
  | nil => exact hm
  | cons w l ih =>
    simp only [List.foldl_cons]
    exact ih _ (Nat.max_le.mpr ⟨hm, hl w (by simp)⟩) (fun v hv => hl v (by simp [hv]))

/-- A part of the votes that keeps a vote of the largest round has the same round. -/
theorem round_sub (l l' : List V) (hsub : ∀ v ∈ l', v ∈ l) (w : V) (hw : w ∈ l')
    (hr : w.2.1 = l.foldl (fun m v => max m v.2.1) 0) :
    l'.foldl (fun m v => max m v.2.1) 0 = l.foldl (fun m v => max m v.2.1) 0 := by
  apply Nat.le_antisymm
  · exact foldl_max_le _ _ _ (Nat.zero_le _) (fun v hv => le_foldl_max _ _ _ (hsub v hv))
  · rw [← hr]; exact le_foldl_max _ _ _ hw

theorem votes_after_carry (l : List Entry) (ch : Change) (hall : ∀ e ∈ l, e.pending = []) :
    ((l.map (fun e => if e.v.2.2 == Choice.go then e else { e with pending := [ch] })).filter
        (fun e => !e.void && e.pending.isEmpty)).map Entry.v =
      ((l.filter (fun e => !e.void && e.pending.isEmpty)).map Entry.v).filter
        (fun v => v.2.2 == Choice.go) := by
  induction l with
  | nil => rfl
  | cons e l ih =>
    have h0 := hall e (by simp)
    have ih' := ih (fun x hx => hall x (by simp [hx]))
    cases e with
    | mk v vd p =>
      simp only at h0; subst h0
      by_cases hg : v.2.2 = Choice.go <;> cases vd <;> simp_all

/-- c17, c11: after the approval, the vote of the human on a changed record, with the choice of
his vote, gives the GO back. Each vote with that choice counts again; a vote with another choice
stays taken back, which cannot lower the round of the human's GO. -/
theorem human_vote_gives_go_back (s : S) (h : ClosedGo s) (ch : Change) (cl cur : Bool) :
    ((s.apply (.spec [ch] cl cur)).apply (.carry ch.id .go)).gate .go = true := by
  obtain ⟨hc, hvo, hs⟩ := h
  let t := (s.apply (.spec [ch] cl cur)).apply (.carry ch.id .go)
  have hall : ∀ e ∈ s.entries, e.pending = [] := by
    simp only [S.settled, List.all_eq_true, List.isEmpty_iff] at hs; exact hs
  have ht : t.entries = s.entries.map (fun e => if e.v.2.2 == Choice.go then e
      else { e with pending := [ch] }) := by
    simp only [t, S.apply, S.entries, scan_append, scan_changes, step, List.map_map]
    apply List.map_congr_left
    intro e hm
    have h0 := hall e hm
    cases e with
    | mk v vd p =>
      simp only at h0; subst h0
      by_cases hg : v.2.2 = Choice.go <;> simp [hg, Change.named]
  have htv : t.votes = s.votes.filter (fun v => v.2.2 == Choice.go) := by
    simp only [S.votes, ht]
    exact votes_after_carry s.entries ch hall
  have htc : t.closed = true := by
    simp only [t, S.apply, S.closed, scan_append, scan_changes, step]
    exact hc
  -- the human's GO in the round of s is among the votes of t, and the round is the same
  simp only [S.voted, List.any_eq_true, Bool.and_eq_true, beq_iff_eq] at hvo
  obtain ⟨w, hw, ⟨h1, h2⟩, h3⟩ := hvo
  have hwt : w ∈ t.votes := by rw [htv]; exact List.mem_filter.mpr ⟨hw, by simp [h3]⟩
  have hr : t.round = s.round := by
    unfold S.round
    exact round_sub _ _ (by intro v hv; rw [htv] at hv; exact (List.mem_filter.mp hv).1) w hwt h2
  have hvt : t.voted .human .go = true := by
    simp only [S.voted, List.any_eq_true, Bool.and_eq_true, beq_iff_eq]
    exact ⟨w, hwt, ⟨h1, hr ▸ h2⟩, h3⟩
  show t.gate .go = true
  simp [S.gate, S.artifact, S.allowed, S.ready, htc, hvt]

/-- vote-start c17. -/
theorem c17 :
    (∀ (s : S) (st : Step), s.humanVoted = true → st.changes ≠ [] →
        (s.apply st).gate .hold = true ∧ (s.apply st).gate .go = false) ∧
    (∀ (s : S) (st : Step), ClosedGo s → st.changes ≠ [] →
        (s.apply st).closed = true ∧ (s.apply st).gate .go = false) ∧
    (∀ (s : S) (ch : Change) cl cur, ClosedGo s →
        ((s.apply (.spec [ch] cl cur)).apply (.carry ch.id .go)).gate .go = true) ∧
    (∀ (s : S) (ch : Change) cl cur k, ClosedGo s → ch.kind = .spec →
        ((s.apply (.spec [ch] cl cur)).apply (.confirm k true)).gate .go = false) ∧
    (∀ (s : S) k also cl cur, ClosedGo s →
        ((s.apply (.spec [⟨.check, k, also⟩] cl cur)).apply (.confirm k true)).gate .go = true) ∧
    (∀ (s : S) (st : Step), ClosedGo s → st ≠ .back → st.changes = [] →
        (s.apply st).gate .go = true) :=
  ⟨fun s st hv hn => ⟨(change_takes_go_back s hv st hn).1, (change_takes_go_back s hv st hn).2.1⟩,
   fun s st h hn => ⟨(change_after_closure_holds s h st hn).1,
     (change_after_closure_holds s h st hn).2.2⟩,
   fun s ch cl cur h => human_vote_gives_go_back s h ch cl cur,
   fun s ch cl cur k h hk => (confirm_does_not_carry_spec s h ch hk cl cur k).2,
   fun s k also cl cur h => gate_of_closedGo _ (confirm_gives_go_back s h k also cl cur),
   fun s st h hb hn => gate_of_closedGo _ (closedGo_step s h st hb hn)⟩

/-! ## The corrected rules of the review of K-A (D30 H5 to H7) -/

/-- H6: the orbit closes only while discovery is ready. -/
theorem closes_only_when_ready (s : S) (stale : Bool) (ho : s.closed = false)
    (hc : (s.apply (.approve stale)).closed = true) : s.clean = true := by
  rw [approve_closed, ho, Bool.false_or] at hc
  have hg : s.gate .go = true := by
    simp only [S.ends, Bool.and_eq_true] at hc; exact hc.1.2
  cases h : s.clean
  · rw [no_go_while_not_ready s ho h] at hg; cases hg
  · rfl

/-- H7: a stale approval does not close the orbit. -/
theorem stale_never_closes (s : S) : (s.apply (.approve true)).closed = s.closed := by
  rw [approve_closed]; simp [S.ends]

/-- H5: after `attest back`, no vote counts: the gate has no answer until a new round. -/
theorem back_drops_votes (s : S) (hc : s.closed = true) :
    (s.apply .back).votes = [] ∧ (s.apply .back).closed = false ∧
      ∀ c, (s.apply .back).gate c = false := by
  have hc' : (scan s.log).2 = true := hc
  have he : (s.apply .back).entries = [] := by simp [S.apply, hc, S.entries, scan_append, step]
  have hv : (s.apply .back).votes = [] := by simp [S.votes, he]
  refine ⟨hv, by simp [S.apply, S.closed, hc', scan_append, step], ?_⟩
  intro c
  simp [S.gate, S.voted, S.humanVoted, S.humanChanged, hv, he]

/-- H5: so an approval right after `back` does not close the orbit again. -/
theorem approve_after_back_stays_open (s : S) (hc : s.closed = true) (stale : Bool) :
    ((s.apply .back).apply (.approve stale)).closed = false := by
  obtain ⟨_, ho, hg⟩ := back_drops_votes s hc
  rw [approve_closed, ho]
  simp [S.ends, hg .go]

/-! The examples for RD6: each is a sequence of commands that the test runs with the CLI, from a
KB whose discovery is ready (`clean := true`) or not ready. -/

def start (clean : Bool) : S := { log := [], clean := clean, someCurrent := true }

def gateText (s : S) : String :=
  if s.gate .go then "go" else if s.gate .hold then "hold" else if s.gate .noGo then "no_go"
  else "none"

/-- The claim c7 and its check t7, which the test adds with one command (`build:claim`). -/
def claimC7 : List Change := [⟨.spec, "c7", []⟩, ⟨.check, "t7", ["c7"]⟩]

/-- For each example: the name, whether the discovery is ready at the start, and the commands. -/
def examples : List (String × Bool × List Step) :=
  [ ("not_ready_votes", false, [.vote .agent .go 1, .vote .agent .hold 1, .vote .human .go 1]),
    ("ready_then_new_hypothesis", true,
      [.vote .agent .go 1, .vote .human .go 1, .spec [⟨.spec, "h9", []⟩] false true]),
    ("approved_then_build", true,
      [.vote .agent .go 1, .vote .human .go 1, .approve false, .spec claimC7 true true]),
    ("approved_then_back", true, [.vote .agent .go 1, .vote .human .go 1, .approve false, .back]),
    ("stale_approval", true, [.vote .agent .go 1, .vote .human .go 1, .approve true]),
    ("vote_after_closure", true,
      [.vote .agent .go 1, .vote .human .go 1, .approve false, .vote .agent .noGo 2,
       .vote .human .noGo 2]) ]

/-- Each command that `attest` refuses, by its position (1 is the first command). -/
def refused (s : S) : List Step → Nat → List Nat
  | [], _ => []
  | st :: sts, i =>
    let r := match st with
      | .vote b c r => if s.refuseVote b c r then [i] else []
      | .back => if s.closed then [] else [i]
      | _ => []
    r ++ refused (s.apply st) sts (i + 1)

#eval examples.length

#eval do
  for (n, cl, sts) in examples do
    let s := (start cl).run sts
    IO.println s!"RD6 {n}: refused={refused (start cl) sts 1} gate={gateText s} closed={s.closed}"

/-! More examples of c17, after the approval (`approved` is the first three commands of
`approved_then_build`). They are not in test RD6. -/

def approved : List Step := [.vote .agent .go 1, .vote .human .go 1, .approve false]

def moreExamples : List (String × List Step) :=
  [ ("approved_then_build_then_human_vote", approved ++ [.spec claimC7 true true, .carry "c7" .go]),
    ("approved_then_build_then_human_no_go", approved ++
      [.spec claimC7 true true, .carry "c7" .noGo]),
    ("approved_then_build_then_confirm", approved ++ [.spec claimC7 true true, .confirm "t7" true]),
    ("approved_then_claim_only", approved ++ [.spec [⟨.spec, "c7", []⟩] true true]),
    ("approved_then_note", approved ++ [.build true true]),
    ("approved_then_rerun_same", approved ++ [.run "t1" true true true]),
    ("approved_then_rerun_other", approved ++ [.run "t1" false true true]),
    ("approved_then_rerun_other_confirmed", approved ++
      [.run "t1" false true true, .confirm "t1" true]),
    ("approved_then_rerun_other_confirmed_by_maker", approved ++
      [.run "t1" false true true, .confirm "t1" false]),
    ("approved_then_new_check_confirmed", approved ++
      [.spec [⟨.check, "t8", ["c1"]⟩] true true, .confirm "t8" true]) ]

#eval do
  for (n, sts) in moreExamples do
    let s := (start true).run sts
    IO.println s!"C17 {n}: refused={refused (start true) sts 1} gate={gateText s} closed={s.closed}"

end GateReady

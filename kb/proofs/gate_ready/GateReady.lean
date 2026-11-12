/-!
# The vote, readiness and the open discovery orbit (0.3.0, claim c_k_d_1b)

The claim (spec KB `tmp/kb-sagittarius-030`, `c_k_d_1b`): "While the discovery orbit of a KB is
open, GO cannot win the gate when discovery is not ready: the tool refuses an agent's GO vote then
and says what blocks, and gate(go) does not hold. The human's vote is never refused. After the
human approves the ticket, a later change in the build does not take the GO back."

A model of the vote rules of `kb/share/orbit-kb/modules/discovery.pl` (`vote_cast/3`,
`vote_round/1`, `human_vote/1`, `agent_vote/1`, `artifact_vote/1`, `gate_allowed/1`, `gate/1`,
`discovery_closed/0`, `discovery_ready/0`), of the computed `vote_void/1`, and of what
`orbit-kb attest` does for `vote`, `approval` of the ticket, and `back` (`go_vote_check/4`,
`late_vote_check/4`, `back_check/4`, `end_lines/8` in `kb/bin/orbit-kb`). CONTRACT D33 R5 and
D30 H4 to H9 (the review of K-A: a new round of votes and readiness after `attest back`; closing
does not rewrite the record of a round; a stale approval does not close). The proof is about these
definitions, not about the code. Test RD6 of `kb/tests/test_orbit_kb.sh` carries the examples of
`#eval examples` below to the CLI.

What the model holds:
* `Ev`: the lines of `kb.pl` that the vote and the orbit read, in their order: a vote, a
  `discovery_end` record, a `back` attestation, or any other line.
* `S.clean`: no `ready_blocker` answers (the model `kb/proofs/open_items` shows that this is
  readiness as the conjunction of its conditions). A change of the build or of discovery
  (a claim, a hypothesis, a run) can set it to any value: `Step.build`.
* `S.votes`: the votes that count (`vote_cast/3`): `kb.pl` read in order, a `back` drops the
  votes before it, and a vote while the orbit is closed is dropped (`vote_void/1`).

Abstractions (what the model leaves out):
* The text of the refusal. The model says only that the agent's GO is refused; the CLI lists each
  `ready_blocker` in it (test RD5).
* `discovery_end` of something that is no human approval of the ticket (lint ED11): such a line
  closes nothing, so it is an `other` line here.
* `back` on a subject that is no hypothesis: refused by the CLI like a `back` in an open orbit.
* One vote per writer per round (ED10) is not assumed: a choice is in the vote of a writer when
  any vote of that writer in the current round has it.

A limit that remains (the review of K-C and K-D, item 2): `Ev.endRec` is a `discovery_end` that
`attest approval` wrote after a GO. A `discovery_end` written by hand that names a real human
approval of the ticket, which came with no GO, is a line that the model does not hold: the rules
of the orbit close on it, so the theorems do not cover that KB. Lint error ED12 (CONTRACT D41)
names such a line: it reads the KB as it was before the approval and asks for an open orbit,
`gate(go)` and the artifacts' go. ED12 is a lint error, not a rule: until the line is removed,
the orbit stays closed, and a hand edit can also forge the votes before the approval.
-/
namespace GateReady

inductive By where
  | human | agent
  deriving DecidableEq, Repr

inductive Choice where
  | go | noGo | hold
  deriving DecidableEq, Repr

/-- A line of `kb.pl` that the vote and the orbit read. -/
inductive Ev where
  | vote (b : By) (round : Nat) (c : Choice)
  | endRec   -- discovery_end(A): attest approval of the ticket wrote it (D30 H4, H6, H7)
  | back     -- a back attestation (D30 H4)
  | other    -- any other line
  deriving DecidableEq, Repr

structure S where
  log : List Ev
  clean : Bool        -- no ready_blocker answers
  someCurrent : Bool  -- discovery_some_current
  deriving Repr

abbrev V := By × Nat × Choice

/-- One line of `kb.pl`: the votes that count so far, and whether the orbit is closed. -/
def step (st : List V × Bool) : Ev → List V × Bool
  | .vote b r c => if st.2 then st else (st.1 ++ [(b, r, c)], st.2)
  | .endRec => (st.1, true)
  | .back => ([], false)
  | .other => st

def scan (log : List Ev) : List V × Bool := log.foldl step ([], false)

/-- `vote_cast/3`: the votes that are not void. -/
def S.votes (s : S) : List V := (scan s.log).1
/-- `discovery_closed`: a discovery_end that no back follows. -/
def S.closed (s : S) : Bool := (scan s.log).2
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

/-- `gate/1`. -/
def S.gate (s : S) (c : Choice) : Bool :=
  (s.voted .human c && s.voted .agent c && s.allowed c) ||
  (s.voted .human c && s.artifact == c && s.allowed c) ||
  (c == .hold && s.humanVoted && !s.agreed) ||
  (c == .hold && s.voted .human .go && !s.allowed .go)

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
  | build (clean someCurrent : Bool)  -- any change of the build or of discovery
  | vote (b : By) (c : Choice) (r : Nat)
  | approve (stale : Bool)            -- attest approval of the ticket by the human
  | back
  deriving DecidableEq, Repr

def S.apply (s : S) : Step → S
  | .build cl cur => { log := s.log ++ [.other], clean := cl, someCurrent := cur }
  | .vote b c r => if s.refuseVote b c r then s else { s with log := s.log ++ [.vote b r c] }
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

theorem votes_other (s : S) (cl cur : Bool) :
    ({ log := s.log ++ [Ev.other], clean := cl, someCurrent := cur } : S).votes = s.votes ∧
    ({ log := s.log ++ [Ev.other], clean := cl, someCurrent := cur } : S).closed = s.closed := by
  simp [S.votes, S.closed, scan_append, step]

theorem approve_votes (s : S) (stale : Bool) : (s.apply (.approve stale)).votes = s.votes := by
  unfold S.apply
  cases h : s.ends stale <;> simp [h, S.votes, scan, List.foldl_append, step]

theorem approve_closed (s : S) (stale : Bool) :
    (s.apply (.approve stale)).closed = (s.closed || s.ends stale) := by
  unfold S.apply
  cases h : s.ends stale <;> simp [h, S.closed, scan, List.foldl_append, step]

/-- The vote of a writer depends only on the votes that count. -/
theorem voted_eq {s t : S} (h : s.votes = t.votes) (b : By) (c : Choice) :
    s.voted b c = t.voted b c := by
  simp [S.voted, S.round, h]

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

/-- After closure: the orbit is closed and the human voted go in the round that counts. -/
def ClosedGo (s : S) : Prop := s.closed = true ∧ s.voted .human .go = true

theorem gate_of_closedGo (s : S) (h : ClosedGo s) : s.gate .go = true := by
  obtain ⟨hc, hv⟩ := h
  simp [S.gate, S.artifact, S.allowed, S.ready, hc, hv]

theorem human_go_of_gate (s : S) (h : s.gate .go = true) : s.voted .human .go = true := by
  simp only [S.gate, Bool.or_eq_true, Bool.and_eq_true] at h
  rcases h with ((⟨⟨h, _⟩, _⟩ | ⟨⟨h, _⟩, _⟩) | ⟨⟨h, _⟩, _⟩) | ⟨⟨h, _⟩, _⟩
  · exact h
  · exact h
  · simp at h
  · simp at h

/-- When `attest approval` ends the orbit, the GO of the round stays in the record. -/
theorem approve_closes (s : S) (stale : Bool) (ho : s.closed = false)
    (hc : (s.apply (.approve stale)).closed = true) : ClosedGo (s.apply (.approve stale)) := by
  rw [approve_closed, ho, Bool.false_or] at hc
  have hg : s.gate .go = true := by
    simp only [S.ends, Bool.and_eq_true] at hc; exact hc.1.2
  refine ⟨by rw [approve_closed, ho, Bool.false_or]; exact hc, ?_⟩
  rw [voted_eq (approve_votes s stale)]
  exact human_go_of_gate s hg

/-- Every command but `back` keeps `ClosedGo`: the record of the round that closed the orbit
does not change, whatever the build adds. -/
theorem closedGo_step (s : S) (h : ClosedGo s) (st : Step) (hb : st ≠ .back) :
    ClosedGo (s.apply st) := by
  obtain ⟨hc, hv⟩ := h
  cases st with
  | build cl cur =>
    obtain ⟨h1, h2⟩ := votes_other s cl cur
    refine ⟨by simp only [S.apply]; rw [h2]; exact hc, ?_⟩
    simp only [S.apply, S.voted, S.round, h1]
    simpa [S.voted, S.round] using hv
  | vote b c r =>
    simp only [S.apply]
    split
    · exact ⟨hc, hv⟩
    · have hs : scan (s.log ++ [Ev.vote b r c]) = scan s.log := by
        rw [scan_append]; simp [step, show (scan s.log).2 = true from hc]
      refine ⟨by simp only [S.closed]; rw [hs]; exact hc, ?_⟩
      simp only [S.voted, S.round, S.votes, hs]
      simpa [S.voted, S.round, S.votes] using hv
  | approve stale =>
    refine ⟨by rw [approve_closed, hc]; rfl, ?_⟩
    rw [voted_eq (approve_votes s stale)]
    exact hv
  | back => exact absurd rfl hb

theorem closedGo_run (s : S) (h : ClosedGo s) (sts : List Step) (hb : ∀ st ∈ sts, st ≠ .back) :
    ClosedGo (s.run sts) := by
  induction sts generalizing s with
  | nil => exact h
  | cons st sts ih =>
    simp only [S.run]
    exact ih _ (closedGo_step s h st (hb st (by simp))) (fun x hx => hb x (by simp [hx]))

/-- After the human approves the ticket (the approval ends the orbit), no later change of the
build, vote, or approval takes the GO back. Only a `back` opens the orbit again. -/
theorem go_stays_after_approval (s : S) (stale : Bool) (ho : s.closed = false)
    (hc : (s.apply (.approve stale)).closed = true)
    (sts : List Step) (hb : ∀ st ∈ sts, st ≠ .back) :
    ((s.apply (.approve stale)).run sts).gate .go = true :=
  gate_of_closedGo _ (closedGo_run _ (approve_closes s stale ho hc) sts hb)

/-- Claim c_k_d_1b. -/
theorem c_k_d_1b :
    (∀ s : S, s.closed = false → s.clean = false →
        s.gate .go = false ∧ ∀ r, s.refuseVote .agent .go r = true) ∧
    (∀ (s : S) c r, s.refuseVote .human c r = false) ∧
    (∀ (s : S) stale, s.closed = false → (s.apply (.approve stale)).closed = true →
        ∀ sts : List Step, (∀ st ∈ sts, st ≠ .back) →
          ((s.apply (.approve stale)).run sts).gate .go = true) :=
  ⟨fun s ho hn => ⟨no_go_while_not_ready s ho hn, agent_go_refused s ho hn⟩,
   human_never_refused,
   go_stays_after_approval⟩

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
  have hv : (s.apply .back).votes = [] := by simp [S.apply, hc, S.votes, scan_append, step]
  have hc' : (scan s.log).2 = true := hc
  refine ⟨hv, by simp [S.apply, S.closed, hc', scan_append, step], ?_⟩
  intro c
  simp [S.gate, S.voted, S.humanVoted, hv]

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

/-- For each example: the name, whether the discovery is ready at the start, and the commands. -/
def examples : List (String × Bool × List Step) :=
  [ ("not_ready_votes", false, [.vote .agent .go 1, .vote .agent .hold 1, .vote .human .go 1]),
    ("ready_then_new_hypothesis", true, [.vote .agent .go 1, .vote .human .go 1, .build false true]),
    ("approved_then_build", true,
      [.vote .agent .go 1, .vote .human .go 1, .approve false, .build false true]),
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

end GateReady

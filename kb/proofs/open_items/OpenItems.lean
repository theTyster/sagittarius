/-!
# What `orbit-kb show open` and the `Open:` part of `report` print (0.3.0, claim c_k_c_1b)

The claim (spec KB `tmp/kb-sagittarius-030`, `c_k_c_1b`): "orbit-kb show open and the Open part
of the report say "Nothing is open" only when nothing blocks done and no open discovery orbit is
not ready. Otherwise they name each thing that blocks: each answer of blocking(X), and what
blocks readiness."

A model of `show_section(_, _, open)`, `open_more/7` and the `Open:` part of `report_text/2` in
`kb/bin/orbit-kb`, and of the rules `ready_blocker/1` and `discovery_ready/0` in
`kb/share/orbit-kb/modules/discovery.pl` (CONTRACT D32 O1 to O3, D33 R1 and R2). The proof is
about these definitions, not about the code. Test OP5 of `kb/tests/test_orbit_kb.sh` carries the
examples of `#eval examples` below to the CLI, and OP1 and OP2 check each kind of the rules.

What the model holds:
* `Item`: an answer of `blocking(X)`, as its kind and its id. Any kind: also a kind that a later
  version of the rules adds. So the theorems hold for each new kind too.
* `Disc`: the facts that readiness reads, each as the list of its answers (`no_falsifier(C)`,
  `question_waits(Q)`, ...). `Disc.clean` is readiness as the conjunction of its conditions (the
  body of `discovery_ready` before D32, with the two conditions of D33). `Disc.blockers` is
  `ready_blocker(X)`. Theorem `clean_iff_no_blocker`: they agree on every state.
* `KB.ready` is `discovery_ready`: the orbit is closed, or no blocker answers.
* A `View` is one of the two commands: the kinds that it prints with its own lines (`covered`),
  the blockers that it names with an item of its own (`skipReady`: the D19 items of the report),
  and whether it has the D19 items.

Abstractions (what the model leaves out):
* `Links`: two rules of the library that the model takes as given: for a covered kind, the own
  query of the command (`to_ask(Q)`, `under(C)`, `burn_open(C)`, ...) gives each answer of
  `blocking(X)` of that kind (the `blocking` clause of the kind reads the same rule); and
  `blocking(to_ask(Q)) :- to_ask(Q).` with `ready_blocker(to_ask(Q)) :- to_ask(Q).`
* The text of each line, its order, and the other lines that block nothing (a stale approval, a
  contested claim, a pending answer) are `info`: they can only make "Nothing is open" rarer.
* `stale_pin_open/1` (c_k_c_2) is a list of pins: the model does not compute it.
-/
namespace OpenItems

abbrev Id := String

/-- An answer of `blocking(X)`: its kind and its id (`""` for a kind with no id, such as
`no_claim`). -/
structure Item where
  kind : String
  id : Id
  deriving DecidableEq, Repr

/-- The kinds of `ready_blocker/1` (`modules/discovery.pl`, CONTRACT D32 O2). -/
inductive RB where
  | noHypothesis | noSystemResult | noOutcome
  | untouched (h : Id) | noFalsifier (c : Id) | noExample (c : Id) | preserveFailing (k : Id)
  | questionWaits (q : Id) | unaskedFinding (f : Id) | refuted (c : Id) | weakRule (r : Id)
  | modelDiverges (m : Id) | modelVacuous (a : Id) | modelUnfiledBreak (c : Id)
  | modelSolversDisagree (m : Id) | unratified (c : Id) | toAsk (q : Id)
  deriving DecidableEq, Repr

/-- What readiness reads, each as the list of the answers of its rule. -/
structure Disc where
  hyps : List Id            -- some_hypothesis: the hypotheses that no hypothesis supersedes
  touched : List Id         -- discovery_hypothesis_touched(H)
  touchedSystem : Bool      -- touched_system
  hasOutcome : Bool         -- discovery_has_outcome
  noFalsifier : List Id     -- no_falsifier(C)
  noExample : List Id       -- discovery_no_example(C) (D33 R1)
  preserveFailing : List Id -- discovery_preserve_failing(K) (D33 R2)
  questionWaits : List Id   -- question_waits(Q)
  unasked : List Id         -- unasked_finding(F)
  refutedCurrent : List Id  -- refuted(C), current(C)
  weakRules : List Id       -- weak_rule(R)
  diverges : List Id        -- model_diverges(M)
  vacuous : List Id         -- model_vacuous(A)
  unfiledBreak : List Id    -- model_unfiled_break(C)
  solversDisagree : List Id -- model_solvers_disagree(M)
  unratified : List Id      -- discovery_unratified(C)
  toAsk : List Id           -- to_ask(Q)
  deriving Repr

/-- Readiness as the conjunction of its conditions (the body of `discovery_ready` before D32,
with the example and the preserve check of D33). -/
def Disc.clean (d : Disc) : Prop :=
  d.hyps ≠ [] ∧ d.touchedSystem = true ∧ d.hasOutcome = true ∧ (∀ h ∈ d.hyps, h ∈ d.touched) ∧
  d.noFalsifier = [] ∧ d.noExample = [] ∧ d.preserveFailing = [] ∧ d.questionWaits = [] ∧
  d.unasked = [] ∧ d.refutedCurrent = [] ∧ d.weakRules = [] ∧ d.diverges = [] ∧
  d.vacuous = [] ∧ d.unfiledBreak = [] ∧ d.solversDisagree = [] ∧ d.unratified = [] ∧
  d.toAsk = []

/-- The current hypotheses with no result from the current system. -/
def Disc.untouchedHyps (d : Disc) : List Id := d.hyps.filter (fun h => !(d.touched.contains h))

/-- `ready_blocker(X)`: one answer for each thing that blocks readiness. -/
def Disc.blockers (d : Disc) : List RB :=
  (if d.hyps.isEmpty then [RB.noHypothesis] else []) ++
  (if d.touchedSystem then [] else [RB.noSystemResult]) ++
  (if d.hasOutcome then [] else [RB.noOutcome]) ++
  d.untouchedHyps.map RB.untouched ++
  d.noFalsifier.map RB.noFalsifier ++
  d.noExample.map RB.noExample ++
  d.preserveFailing.map RB.preserveFailing ++
  d.questionWaits.map RB.questionWaits ++
  d.unasked.map RB.unaskedFinding ++
  d.refutedCurrent.map RB.refuted ++
  d.weakRules.map RB.weakRule ++
  d.diverges.map RB.modelDiverges ++
  d.vacuous.map RB.modelVacuous ++
  d.unfiledBreak.map RB.modelUnfiledBreak ++
  d.solversDisagree.map RB.modelSolversDisagree ++
  d.unratified.map RB.unratified ++
  d.toAsk.map RB.toAsk

/-- D32 O2: the blockers are exactly what readiness needs. In an open orbit, `discovery_ready`
(no blocker) is the conjunction of the conditions. -/
theorem clean_iff_no_blocker (d : Disc) : d.clean ↔ d.blockers = [] := by
  unfold Disc.clean Disc.blockers Disc.untouchedHyps
  simp only [List.append_eq_nil_iff, List.map_eq_nil_iff, List.filter_eq_nil_iff,
    Bool.not_eq_eq_eq_not, Bool.not_true]
  cases d.touchedSystem <;> cases d.hasOutcome <;> cases h : d.hyps.isEmpty <;>
    simp_all [List.isEmpty_iff, and_assoc]

theorem questionWaits_mem {d : Disc} {q : Id} (h : RB.questionWaits q ∈ d.blockers) :
    q ∈ d.questionWaits := by
  unfold Disc.blockers at h
  simp only [List.mem_append, List.mem_map] at h
  split at h <;> split at h <;> split at h <;> simp_all

theorem refuted_mem {d : Disc} {c : Id} (h : RB.refuted c ∈ d.blockers) :
    c ∈ d.refutedCurrent := by
  unfold Disc.blockers at h
  simp only [List.mem_append, List.mem_map] at h
  split at h <;> split at h <;> split at h <;> simp_all

/-- What one command reads from a KB. -/
structure KB where
  blocking : List Item       -- each answer of blocking(X)
  own : List Item            -- the answers of blocking(X) that its own lines print
  info : List String         -- its other lines: stale approvals, contested claims, pending answers
  usesDiscovery : Bool
  closed : Bool              -- discovery_closed
  disc : Disc
  stalePins : List Id        -- stale_pin_open(P)
  deriving Repr

/-- `discovery_ready :- discovery_closed.` and `discovery_ready :- discovery_open, not any_ready_blocker.` -/
def KB.ready (k : KB) : Bool := k.closed || k.disc.blockers.isEmpty

/-- A line of `show open`, or an item of `report` `Open:`. -/
inductive Line where
  | item (b : Item)         -- names an answer of blocking(X)
  | notReady (r : RB)       -- "- not_ready KIND ID: ..." / "**not ready**: ..."
  | waits (q : Id)          -- report, D19: question Q waits
  | refutedL (c : Id)       -- report, D19: claim C is refuted
  | stalePin (p : Id)
  | info (s : String)
  | unknown                 -- the fallback of open_more/7 when no blocker answers
  | nothingOpen
  deriving DecidableEq, Repr

/-- A command: the kinds that it prints with its own lines, the blockers that it names with an
item of its own, and whether it has the D19 items. -/
structure View where
  covered : List String
  skipReady : RB → Bool
  d19 : Bool

def isToAsk : RB → Bool
  | .toAsk _ => true
  | _ => false

/-- open_more/7, Rd: the blockers, while the KB uses discovery, the orbit is open, and
`discovery_ready` fails. -/
def rdLines (v : View) (k : KB) : List Line :=
  if k.usesDiscovery && !k.closed && !k.ready then
    (if k.disc.blockers.isEmpty then [Line.unknown]
     else (k.disc.blockers.filter (fun r => !isToAsk r && !v.skipReady r)).map Line.notReady)
  else []

/-- report, D19: each question that waits and is not to_ask, and each current refuted claim. -/
def d19Lines (v : View) (k : KB) : List Line :=
  if v.d19 && k.usesDiscovery then
    (k.disc.questionWaits.filter (fun q => !(k.disc.toAsk.contains q))).map Line.waits ++
    k.disc.refutedCurrent.map Line.refutedL
  else []

/-- Every line of the command but "Nothing is open". -/
def lines (v : View) (k : KB) : List Line :=
  k.own.map Line.item ++ k.info.map Line.info ++ d19Lines v k ++
  (k.blocking.filter (fun b => !(v.covered.contains b.kind))).map Line.item ++
  rdLines v k ++ k.stalePins.map Line.stalePin

/-- What the command prints: its lines, or "Nothing is open" when it has none. -/
def shown (v : View) (k : KB) : List Line :=
  if (lines v k).isEmpty then [Line.nothingOpen] else lines v k

/-- `orbit-kb show open` (D32 O1). -/
def showOpen : View where
  covered := ["to_ask", "supersede_cycle", "under", "over", "burn_open", "flare_open", "no_claim",
              "request_stale"]
  skipReady := fun _ => false
  d19 := false

/-- The `Open:` part of `orbit-kb report` (D32 O1, O2; D19). -/
def reportOpen : View where
  covered := ["to_ask", "supersede_cycle", "over", "burn_open", "flare_open", "no_claim",
              "waiver_lapsed"]
  skipReady := fun r => match r with
    | .questionWaits _ => true
    | .refuted _ => true
    | _ => false
  d19 := true

/-- A view names a blocker with an item of its own only when it has the D19 items, and only for
a waiting question or a refuted claim. -/
def WellFormed (v : View) : Prop :=
  ∀ r, v.skipReady r = true → v.d19 = true ∧ ((∃ q, r = .questionWaits q) ∨ (∃ c, r = .refuted c))

theorem showOpen_wf : WellFormed showOpen := by
  intro r h; simp [showOpen] at h

theorem reportOpen_wf : WellFormed reportOpen := by
  intro r h
  cases r <;> simp_all [reportOpen]

/-- The two rules of the library that the model takes as given (see the header). -/
structure Links (v : View) (k : KB) : Prop where
  own_covers : ∀ b ∈ k.blocking, v.covered.contains b.kind = true → b ∈ k.own
  to_ask : ∀ q ∈ k.disc.toAsk, (⟨"to_ask", q⟩ : Item) ∈ k.blocking

/-- How a line names a blocker: a to_ask blocker by the blocking line of its question; a waiting
question by a "not ready" line, by the D19 line, or by its to_ask line; a refuted claim by a
"not ready" line or the D19 line; any other blocker by a "not ready" line. -/
def Names (ls : List Line) : RB → Prop
  | .toAsk q => Line.item ⟨"to_ask", q⟩ ∈ ls
  | .questionWaits q =>
      Line.notReady (.questionWaits q) ∈ ls ∨ Line.waits q ∈ ls ∨ Line.item ⟨"to_ask", q⟩ ∈ ls
  | .refuted c => Line.notReady (.refuted c) ∈ ls ∨ Line.refutedL c ∈ ls
  | r => Line.notReady r ∈ ls

theorem mem_shown {v : View} {k : KB} {x : Line} (h : x ∈ lines v k) : x ∈ shown v k := by
  unfold shown
  cases hl : (lines v k).isEmpty
  · simpa using h
  · simp [List.isEmpty_iff] at hl; simp [hl] at h

theorem rd_cases {v : View} {k : KB} {x : Line} (h : x ∈ rdLines v k) :
    x = Line.unknown ∨ ∃ r, x = Line.notReady r := by
  unfold rdLines at h
  split at h
  · split at h
    · simp at h; exact Or.inl h
    · simp only [List.mem_map] at h
      obtain ⟨r, _, rfl⟩ := h
      exact Or.inr ⟨r, rfl⟩
  · simp at h

theorem d19_cases {v : View} {k : KB} {x : Line} (h : x ∈ d19Lines v k) :
    (∃ q, x = Line.waits q) ∨ ∃ c, x = Line.refutedL c := by
  unfold d19Lines at h
  split at h
  · simp only [List.mem_append, List.mem_map] at h
    rcases h with ⟨q, _, rfl⟩ | ⟨c, _, rfl⟩
    · exact Or.inl ⟨q, rfl⟩
    · exact Or.inr ⟨c, rfl⟩
  · simp at h

theorem nothingOpen_not_in_lines (v : View) (k : KB) : Line.nothingOpen ∉ lines v k := by
  intro h
  unfold lines at h
  simp only [List.mem_append] at h
  rcases h with ((((h | h) | h) | h) | h) | h
  · simp at h
  · simp at h
  · rcases d19_cases h with ⟨_, h⟩ | ⟨_, h⟩ <;> cases h
  · simp at h
  · rcases rd_cases h with h | ⟨_, h⟩ <;> cases h
  · simp at h

/-- The fallback line of open_more/7 never prints: when discovery is not ready, some blocker
answers. -/
theorem unknown_not_in_rd (v : View) (k : KB) : Line.unknown ∉ rdLines v k := by
  intro h
  unfold rdLines at h
  split at h
  · rename_i hc
    split at h
    · rename_i he
      simp [KB.ready, he] at hc
    · simp only [List.mem_map] at h
      obtain ⟨_, _, h⟩ := h
      cases h
  · simp at h

theorem unknown_never_shown (v : View) (k : KB) : Line.unknown ∉ shown v k := by
  intro h
  unfold shown at h
  split at h
  · simp at h
  · unfold lines at h
    simp only [List.mem_append] at h
    rcases h with ((((h | h) | h) | h) | h) | h
    · simp at h
    · simp at h
    · rcases d19_cases h with ⟨_, h⟩ | ⟨_, h⟩ <;> cases h
    · simp at h
    · exact unknown_not_in_rd v k h
    · simp at h

/-- Each answer of blocking(X), of any kind, is named. -/
theorem names_each_blocking (v : View) (k : KB) (hl : Links v k) :
    ∀ b ∈ k.blocking, Line.item b ∈ shown v k := by
  intro b hb
  apply mem_shown
  unfold lines
  cases hc : v.covered.contains b.kind
  · simp only [List.mem_append, List.mem_map, List.mem_filter]
    exact Or.inl (Or.inl (Or.inr ⟨b, ⟨hb, by rw [hc]; rfl⟩, rfl⟩))
  · simp only [List.mem_append, List.mem_map]
    exact Or.inl (Or.inl (Or.inl (Or.inl (Or.inl ⟨b, hl.own_covers b hb hc, rfl⟩))))

/-- While the KB uses discovery and the orbit is open, each blocker of readiness is named. -/
theorem names_ready_blockers (v : View) (hv : WellFormed v) (k : KB) (hl : Links v k)
    (hu : k.usesDiscovery = true) (hc : k.closed = false) :
    ∀ r ∈ k.disc.blockers, Names (shown v k) r := by
  intro r hr
  have hne : k.disc.blockers.isEmpty = false := by
    cases h : k.disc.blockers with
    | nil => simp [h] at hr
    | cons _ _ => rfl
  have hrd : rdLines v k =
      (k.disc.blockers.filter (fun r => !isToAsk r && !v.skipReady r)).map Line.notReady := by
    simp [rdLines, KB.ready, hu, hc, hne]
  have inRd : ∀ r', r' ∈ k.disc.blockers → isToAsk r' = false → v.skipReady r' = false →
      Line.notReady r' ∈ shown v k := by
    intro r' h1 h2 h3
    apply mem_shown; unfold lines; rw [hrd]
    simp only [List.mem_append, List.mem_map, List.mem_filter]
    exact Or.inl (Or.inr ⟨r', ⟨h1, by simp [h2, h3]⟩, rfl⟩)
  have toAskNamed : ∀ q, q ∈ k.disc.toAsk → Line.item ⟨"to_ask", q⟩ ∈ shown v k :=
    fun q hq => names_each_blocking v k hl _ (hl.to_ask q hq)
  cases hs : v.skipReady r with
  | false =>
    cases r with
    | toAsk q =>
      unfold Disc.blockers at hr
      simp only [List.mem_append, List.mem_map] at hr
      have : q ∈ k.disc.toAsk := by
        split at hr <;> split at hr <;> split at hr <;> simp_all
      exact toAskNamed q this
    | questionWaits q => exact Or.inl (inRd _ hr rfl hs)
    | refuted c => exact Or.inl (inRd _ hr rfl hs)
    | _ => exact inRd _ hr rfl hs
  | true =>
    obtain ⟨hd, hk⟩ := hv r hs
    rcases hk with ⟨q, rfl⟩ | ⟨c, rfl⟩
    · have hq := questionWaits_mem hr
      by_cases ht : q ∈ k.disc.toAsk
      · exact Or.inr (Or.inr (toAskNamed q ht))
      · refine Or.inr (Or.inl (mem_shown ?_))
        unfold lines d19Lines
        simp only [hd, hu, Bool.and_self, ite_true, List.mem_append, List.mem_map, List.mem_filter]
        exact Or.inl (Or.inl (Or.inl (Or.inr (Or.inl
          ⟨q, ⟨hq, by simpa [List.contains_iff_mem] using ht⟩, rfl⟩))))
    · have hcm := refuted_mem hr
      refine Or.inr (mem_shown ?_)
      unfold lines d19Lines
      simp only [hd, hu, Bool.and_self, ite_true, List.mem_append, List.mem_map]
      exact Or.inl (Or.inl (Or.inl (Or.inr (Or.inr ⟨c, hcm, rfl⟩))))

theorem names_not_nothingOpen {r : RB} (h : Names [Line.nothingOpen] r) : False := by
  cases r <;> simp [Names] at h

/-- "Nothing is open" only when nothing blocks done and no open discovery orbit is not ready. -/
theorem nothing_open_only_when (v : View) (hv : WellFormed v) (k : KB) (hl : Links v k) :
    Line.nothingOpen ∈ shown v k →
      k.blocking = [] ∧ (k.usesDiscovery = true → k.closed = false → k.disc.clean) := by
  intro h
  have hl0 : lines v k = [] := by
    unfold shown at h
    cases he : (lines v k).isEmpty
    · simp [he] at h; exact absurd h (nothingOpen_not_in_lines v k)
    · simpa [List.isEmpty_iff] using he
  have hs : shown v k = [Line.nothingOpen] := by simp [shown, hl0]
  refine ⟨?_, ?_⟩
  · cases hb : k.blocking with
    | nil => rfl
    | cons b bs =>
      have := names_each_blocking v k hl b (by simp [hb])
      simp [hs] at this
  · intro hu hc
    rw [clean_iff_no_blocker]
    cases hb : k.disc.blockers with
    | nil => rfl
    | cons r rs =>
      have := names_ready_blockers v hv k hl hu hc r (by simp [hb])
      rw [hs] at this
      exact (names_not_nothingOpen this).elim

/-- Claim c_k_c_1b, for one command: "Nothing is open" only when nothing blocks done and no open
discovery orbit is not ready (readiness as the conjunction of its conditions); each answer of
blocking(X) is named; while the orbit is open, each thing that blocks readiness is named. -/
theorem open_view_claim (v : View) (hv : WellFormed v) (k : KB) (hl : Links v k) :
    (Line.nothingOpen ∈ shown v k →
      k.blocking = [] ∧ (k.usesDiscovery = true → k.closed = false → k.disc.clean)) ∧
    (∀ b ∈ k.blocking, Line.item b ∈ shown v k) ∧
    (k.usesDiscovery = true → k.closed = false → ∀ r ∈ k.disc.blockers, Names (shown v k) r) :=
  ⟨nothing_open_only_when v hv k hl, names_each_blocking v k hl,
   names_ready_blockers v hv k hl⟩

/-- Claim c_k_c_1b: the same for `show open` and for the `Open:` part of `report`. -/
theorem c_k_c_1b (k : KB) (hs : Links showOpen k) (hr : Links reportOpen k) :
    ((Line.nothingOpen ∈ shown showOpen k →
        k.blocking = [] ∧ (k.usesDiscovery = true → k.closed = false → k.disc.clean)) ∧
      (∀ b ∈ k.blocking, Line.item b ∈ shown showOpen k) ∧
      (k.usesDiscovery = true → k.closed = false →
        ∀ r ∈ k.disc.blockers, Names (shown showOpen k) r)) ∧
    ((Line.nothingOpen ∈ shown reportOpen k →
        k.blocking = [] ∧ (k.usesDiscovery = true → k.closed = false → k.disc.clean)) ∧
      (∀ b ∈ k.blocking, Line.item b ∈ shown reportOpen k) ∧
      (k.usesDiscovery = true → k.closed = false →
        ∀ r ∈ k.disc.blockers, Names (shown reportOpen k) r)) :=
  ⟨open_view_claim showOpen showOpen_wf k hs, open_view_claim reportOpen reportOpen_wf k hr⟩

/-! The examples for OP5: each is a KB that the test makes with the CLI. The test compares the
lines of `show open` (the part before the first ":") with the lines that `#eval examples`
prints here, as sets. -/

def RB.render : RB → String
  | .noHypothesis => "no_hypothesis"
  | .noSystemResult => "no_system_result"
  | .noOutcome => "no_outcome"
  | .untouched h => "untouched " ++ h
  | .noFalsifier c => "no_falsifier " ++ c
  | .noExample c => "no_example " ++ c
  | .preserveFailing k => "preserve_failing " ++ k
  | .questionWaits q => "question_waits " ++ q
  | .unaskedFinding f => "unasked_finding " ++ f
  | .refuted c => "refuted " ++ c
  | .weakRule r => "weak_rule " ++ r
  | .modelDiverges m => "model_diverges " ++ m
  | .modelVacuous a => "model_vacuous " ++ a
  | .modelUnfiledBreak c => "model_unfiled_break " ++ c
  | .modelSolversDisagree m => "model_solvers_disagree " ++ m
  | .unratified c => "unratified " ++ c
  | .toAsk q => "to_ask " ++ q

def Line.render : Line → String
  | .item b => if b.id = "" then b.kind else b.kind ++ " " ++ b.id
  | .notReady r => "not_ready " ++ r.render
  | .waits q => "waits " ++ q
  | .refutedL c => "refuted " ++ c
  | .stalePin p => "stale_pin " ++ p
  | .info s => s
  | .unknown => "unknown"
  | .nothingOpen => "Nothing is open"

def emptyDisc : Disc :=
  { hyps := [], touched := [], touchedSystem := false, hasOutcome := false, noFalsifier := [],
    noExample := [], preserveFailing := [], questionWaits := [], unasked := [],
    refutedCurrent := [], weakRules := [], diverges := [], vacuous := [], unfiledBreak := [],
    solversDisagree := [], unratified := [], toAsk := [] }

def emptyKB : KB :=
  { blocking := [], own := [], info := [], usesDiscovery := false, closed := false,
    disc := emptyDisc, stalePins := [] }

/-- A ready discovery KB: one hypothesis with its system result, one current claim. -/
def readyDisc : Disc :=
  { emptyDisc with
    hyps := ["h1"]
    touched := ["h1"]
    touchedSystem := true
    hasOutcome := true }

def discKB (d : Disc) : KB := { emptyKB with usesDiscovery := true, disc := d }

def examples : List (String × KB) :=
  [ ("hypothesis_only", discKB { emptyDisc with hyps := ["h1"] }),
    ("contradiction", { emptyKB with blocking := [⟨"project_contradiction", "d1"⟩] }),
    ("done", emptyKB),
    ("under_never_ran",
      { emptyKB with
        blocking := [⟨"under", "c1"⟩, ⟨"check_unrun", "k1"⟩]
        own := [⟨"under", "c1"⟩] }),
    ("no_example", discKB { readyDisc with noExample := ["c2"] }),
    ("preserve_fails", discKB { readyDisc with preserveFailing := ["t2"] }),
    ("ready", discKB readyDisc),
    ("closed", { discKB { readyDisc with noExample := ["c7"] } with closed := true }),
    ("stale_pin", { emptyKB with stalePins := ["pf2"] }) ]

#eval examples.length

#eval do
  for (n, k) in examples do
    IO.println s!"OP5 {n}: {String.intercalate " | " ((shown showOpen k).map Line.render)}"

end OpenItems

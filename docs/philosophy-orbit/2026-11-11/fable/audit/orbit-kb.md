# Alignment audit: `orbit-kb` and the formal languages it routes to (area K)

Auditor: K. Date: 2026-11-11. Read only. No file in a checkout was changed.

## Paths and short names

- **NP** = the new prompt: `/home/ty/Projects/mine/wt/sagittarius/philosophy-fable/prompt/SAGITTARIUS.md`
- **PH** = the new philosophy: `/home/ty/Projects/mine/wt/sagittarius/philosophy-fable/docs/PHILOSOPHY.md`
- **kb/** = `/home/ty/Projects/mine/sagittarius/kb/`. So `kb/bin/orbit-kb:7208` is line 7208 of the CLI.
- **help/** = `kb/share/orbit-kb/help/`, **modules/** = `kb/share/orbit-kb/modules/`.
- **CONTRACT** = `kb/CONTRACT.md`. **tests** = `kb/tests/test_orbit_kb.sh` unless another file is named.
- **RUN** = I ran the command on a throwaway KB. The KBs are in
  `/tmp/claude-1000/-home-ty-Projects-mine-sagittarius/dbe14ead-e920-413c-be2e-63d46291253c/scratchpad/audit/k-scratch/`
  (`b1`..`b4` build, `d1`..`d4` discovery, `p1` project, `sp` spec).

## Summary

- 18 candidates: 12 CONFIRMED, 6 PARTLY, 0 NOT CONFIRMED, 0 NOT CHECKED.
- 5 more differences that I found (K19 to K23).
- By kind (23 findings): 15 gap, 5 contradiction (K2, K9, K10, K22, K23), 3 stale words (K13,
  K15, K17). K5 is a gap with one contradiction inside it.
- By size: 8 S (K2, K10, K11, K13, K15, K17, K22, K23), 13 M, 2 L (K1, K9). K10 becomes M with
  K1; K12 is S + M; K23 is S or M.
- The three that matter most:
  1. **K1 + K3 + K10**: the hypothesis and its premises have no home outside the discovery module. A
     build KB refuses `hypothesis/3`. So "every ticket has a hypothesis", "premises ride beside it",
     and "restate the hypothesis in build" cannot be recorded.
  2. **K7 + K20**: no output of the tool shows a formal statement, the hypothesis, or an example.
     `report`, `show`, `why` print prose templates. This is the UAT report of Ty in the tool.
  3. **K9**: a claim that is contested twice must get a Lean proof. The tool accepts no solver and
     no model checker there. The new texts say "the language that fits that claim".
- One quiet failure that is in the tool today, and that the new prompt leans on: `show open` and
  the `Open:` part of `report` can say "Nothing is open" while `done` is false (K19).

---

## Part 1. The candidates

### K1 (K-c1). A build KB has no place for the hypothesis — CONFIRMED

- **New text**: NP "The light path", Build step 1 (NP:118): "State the hypothesis of the ticket".
  NP "The hypothesis" (NP:167): "Every ticket has one." NP "One response" (NP:286): "records: a KB
  that holds the request word for word, the hypothesis, the claims".
- **Build**:
  - `modules/discovery.pl:25`: `decl(fact, hypothesis(id, oneof([defect, feature, risk]), text),`.
    No other module declares it.
  - CONTRACT:488-491: "Names that the discovery module reserves must not appear in the core or
    the build module: Facts: `hypothesis/3`".
  - RUN (`b1`, a build KB): `orbit-kb add "hypothesis(h1, feature, '...')"` gives "E2 ...
    hypothesis/3 is declared in module discovery, which this KB does not use. Add the module
    first: orbit-kb uses discovery." Exit 1.
  - RUN (`b2`): after `orbit-kb uses discovery` and the `add`, lint gives "WD7 h1: No result from
    the current system exists for this hypothesis", `report` gets "**not ready**: Discovery is
    not ready" under `Open:` and a `Vote:` section. So the only way to hold the hypothesis of a
    direct build brings discovery noise into the delivery.
  - The kind is `defect | feature | risk`. A direct build of a document or a configuration change
    must pick one.
  - `help/build.txt:140`: "start a KB, and record the request, your claims, and the checks so
    far." No hypothesis. The general help step 2 (`kb/bin/orbit-kb:7774-7783`) names
    `claim`, `cites`, `check` only.
- **Kind**: gap.
- **Smallest change**: declare `hypothesis` in the core (`kb/share/orbit-kb/core.pl`), with the
  discovery rules (WD7, readiness) still only in `modules/discovery.pl`. Add it to step 2 of the
  general help and to `help core`.
- **Size**: L (it moves a reserved name; the contract says core must not have it).
- **What holds the old behavior**: CONTRACT:488-493 (reserved names), D15 R1 (CONTRACT:278: "core
  cannot name the discovery fact `hypothesis/3` in a type"), tests RW1 to RW5, NC5, the fixture
  `kb/tests/fixtures/discovery-a`.

### K2 (K-c2). One hypothesis holds the wanted outcome and "the system falls short" — CONFIRMED

- **New text**: NP "The hypothesis" (NP:189-191): "That is a finding about the system, and the
  reproduction tests it. Keep it apart from the hypothesis." NP:214: "A hypothesis has two
  falsifiers, and each has its own witness."
- **Build**:
  - `help/discovery.txt:81-82`: "Say which outcome the report expects, and which facts decide
    that outcome. Then say that the system can fail to give it."
  - `help/discovery.txt:89-91`: the example hypothesis ends "Some purchases get a different
    number." and has one falsifier: "every purchase gets the points that its amount and tier
    give."
  - `help/discovery.txt:83`: "Give it a falsifier: the result that would show it is false." One
    falsifier. No witness is named.
  - `modules/discovery.pl:61`: `result(ref(hypothesis), oneof([reproduced, not_reproduced]))`. The
    hypothesis is the thing that "reproduces". That fits "the system falls short", not "what the
    human wants".
  - `modules/discovery.pl:46`: finding kinds are `root_cause, conflict, surprise, trace, scope`.
    There is no kind for "the system falls short of the hypothesis today".
- **Kind**: contradiction (the help tells the agent to put the finding into the hypothesis).
- **Smallest change**: rewrite the "The hypothesis" block and its example in
  `help/discovery.txt` to the new example (hypothesis; premise; the finding apart; two
  falsifiers). Keep `result(H, reproduced)` and say in the help that it records the finding
  "the system does not meet H now". A new finding kind is optional.
- **Size**: S (help words). M if a finding kind for the gap is added.
- **What holds the old behavior**: no test pins these words (I searched tests for "loyalty",
  "premises", "Weak, with a strong": no hit). RW5 needs the word "reword" and the `supersedes(h`
  example in `help discovery`.

### K3 (K-c3). No fact for a premise — CONFIRMED

- **New text**: NP "The hypothesis" (NP:175-179): "**Put its premises beside it,** every time that
  you state it." ... "Check each premise against the system. When the system shows that a premise
  is false, the hypothesis does not apply as written: restate it." NP:122: "Write "Premises:
  none" when there are none."
- **Build**:
  - No module and no core file declares `premise`. Search of `kb/bin/orbit-kb` for "premise": no
    hit.
  - `help/discovery.txt:76`: "List its premises beside it." The record line
    (`help/discovery.txt:69`) is `orbit-kb add "hypothesis(h1, defect, 'TEXT')" "budget(laps, 3)"`.
    It has no place for a premise. The help does not say where a premise goes. `note/2`
    (`help/core.txt:29`) and `assumption/2` (`kb/share/orbit-kb/core.pl:93`: "An assumption that
    the work relies on.") are the nearest fits. No rule reads either.
  - RUN (`b1`): `orbit-kb add "premise(h1, 'none')"` is accepted as a new kind by first use
    ("NOTE: premise/2 is a new predicate"). Lint then gives W4, W7, W9. No output prints it.
  - The `divergence` type is `claim(C) | hypothesis(H) | model(M)` (`help/core.txt:57`). A false
    premise has no record.
  - The discovery report format has `Hypothesis:   <one sentence, and its falsifier>`
    (`help/discovery.txt:244`). No premises.
- **Kind**: gap.
- **Smallest change**: a fact `premise(Id, Hypothesis, Text)` beside the hypothesis, with a
  state that a query can read (checked on the system, or not), and "Premises: none" as an
  explicit record. Print the premises wherever the hypothesis is printed (see K20).
- **Size**: M.
- **What holds the old behavior**: nothing forbids it. `tmp/issues/6-premises.md` (a lead) asks
  the same and lists open questions (can a contested premise block readiness?).

### K4 (K-c4). The step from words to records is long — CONFIRMED (counted)

- **New text**: PH principle 10 (PH:476-477): "The step from words to records is rare, so it must
  be easy when it comes." PH "Under trial" (PH:845-846): "the step from words to records costs
  several commands".
- **Build** (all RUN, counts from `orbit-kb help ... | wc`):
  - Reading that NP "The tool" requires before the first write ("run `orbit-kb help`" and
    "Before a move writes records, read its topic"):
    - build: `help` 81 lines + `help core` 145 + `help build` 189 = **415 lines, 4,244 words**.
    - discovery: `help` 81 + `help core` 145 + `help discovery` 264 = **490 lines, 4,852 words**.
  - Build, from no KB to "request, one claim, one check, fulfilled": 4 write commands
    (`init`, `add` with claim + cites + example + check, `run` red, `run` green), then `lint` and
    `report`. The hypothesis cannot be recorded (K1). With the workaround of K1 it is 2 more
    commands (`uses discovery`, `add`) and 264 more help lines.
  - Discovery, shortest path that I could make ready (`d1`): 4 write commands (`init`, one `add`
    with hypothesis + budget + claim + cites + example + check + `discovery_evidence(t1, system)`,
    `run`, `attest reproduction t1 'result(h1, reproduced)'`). The recipe of the help
    (`help/discovery.txt:69`, `:102-104`, `:126-128`) is 8 commands: `init`, `add`, `subject`,
    `add`, `attest`, `add`, `add`, `run`.
  - A shift up **after** the build cannot be made honest without a rebuild step. RUN (`b4`): a
    check that only ran green leaves the claim `under`: "rule 2 of 2 for fulfilled/1 stops at
    was_red(k1)". The rule is `modules/build.pl:194-195`. Only `orbit-kb run` writes a result,
    so the red run that the agent saw on the light path does not count. The agent must undo the
    change, run red, redo it, run green.
- **Kind**: gap.
- **Smallest change**: one command that takes the light-path state (request, hypothesis,
  premises, one claim, one check) and writes the KB, and one short help topic for the shift
  (what to record, in 30 to 40 lines). Decide how a red run that was seen before the KB existed
  is recorded (a disclosure, or a rerun): this needs a decision of Ty.
- **Size**: M.
- **What holds the old behavior**: `fulfilled/1` and `was_red/1` (CONTRACT:571-574, 618-620), the
  Lean project `kb/tests/burn_model`, tests HP4, HP5, HP7 (the help layout).

### K5 (K-c5). GO wins the gate while discovery is not ready — CONFIRMED; the artifact vote does not read test results — PARTLY

- **New text**: NP "Honesty", in discovery, rule 7 (NP:395): "What blocks readiness blocks GO. Do
  not vote GO, and do not ask for GO, while something blocks it." NP "The vote" (NP:345): "The
  formal artifacts vote by rule, and the rule is readiness." Ty: "Any test of any kind counts as
  an artifact."
- **Build**:
  - `modules/discovery.pl:320`: `gate(C) :- human_vote(C), agent_vote(C).` It does not read
    `discovery_ready`.
  - RUN (`d2`, not ready, WD7 open): `attest vote r1 'vote(1, go)'` by the agent is accepted with
    no note. After the human's `go`, `query 'gate(V)'` gives `V = go`, `artifact_vote(V)` gives
    `hold`, and `report` prints "Outcome: go" two lines under "**not ready**: Discovery is not
    ready". Lint says only WD7.
  - The tool's own help agrees with the new text in words: `help/codes.txt:72`: "What blocks
    discovery_ready blocks GO." The rules do not enforce it.
  - The artifact vote: `modules/discovery.pl:315-317`. `go` when `discovery_ready` and a claim is
    current, `no_go` when ready and none is current, else `hold`.
  - What a test counts for inside `discovery_ready` (`modules/discovery.pl:328-337`):
    - a check counts as a falsifier even if it never ran: `has_falsifier(C) :- check(_, C).`
      (`:253`);
    - a run of a system-tagged check makes `touched_system` true (`:175`);
    - it does **not** count as the reproduction: `discovery_hypothesis_touched(H)` reads only a
      `reproduction` attestation (`:176`). RUN (`d1`): a red run of `t1` with
      `discovery_evidence(t1, system)` still gives WD7 and `artifact_vote = hold`. The header of
      the module says the opposite (`:7`: "A runnable reproduction is a core check/2 with a red
      test_result.").
    - a test **result** does not change the vote. RUN (`d4`): a `preserve` claim whose check
      fails now ("true now, and must stay true" is false now) leaves `discovery_ready` true,
      `artifact_vote = go`, lint clean, and `Open:` "Nothing is open."
- **Kind**: gap (the gate); contradiction with Ty's sentence (the artifact vote ignores test
  results).
- **Smallest change**: (a) refuse, or warn on, an agent vote `go` while `discovery_ready` is
  false (in `attest`, or a lint code), and print the blocker beside "Outcome: go". (b) Let a red
  run of a system-tagged check of a claim count as the system result of its hypothesis, and let
  a failing check of a `preserve` claim block readiness. Unclear: if the human's GO with the
  agent's GO must still win by the weights (NP:342-343 keeps the weights), then (a) is a warning,
  not a rule change. This needs Ty's word.
- **Size**: M.
- **What holds the old behavior**: D14 V2, V3 (CONTRACT:285-286), E16 protection of the vote
  rules (CONTRACT:287), tests VT3, VT4, VT6, NC5, RW2, the fixture
  `kb/tests/fixtures/discovery-a/expected.pl`.

### K6 (K-c6). One matching case calibrates a model — CONFIRMED

- **New text**: NP "Honesty", in discovery, rule 3 (NP:388-390): "A model gives a verdict about the
  system only after it has matched the system: on a real case where the system fails, and on a
  real case where it passes. A match of the outcome does not show the cause."
- **Build**:
  - `modules/discovery.pl:220`: `model_calibrated(M) :- model_calibration(_, M, matches).` One
    `matches` on any case is enough.
  - The calibration shape is `calibration(ref(model), alt([example(ref(claim)), case(text)]),
    oneof([matches, differs]))` (`modules/discovery.pl:71`). It does not say if the case is one
    where the system fails or one where it passes.
  - A derived model inherits: `modules/discovery.pl:235-236` (`model_trusted(M) :- model_sane(M),
    derived_from(M, M0), ... model_calibrated(M0)`).
  - `attest model_result` never checks a calibration against the log: D18 (CONTRACT:245):
    "`calibration` is never checked."
  - `help/discovery.txt:136-139` asks for more than the rule does ("a real case from SURVEY, and
    of two or three normal cases"). The rule accepts one.
- **Kind**: gap.
- **Smallest change**: `model_calibrated(M)` needs two counted calibrations that match: one
  marked as a failing case of the system and one marked as a passing case. That needs a third
  argument or two case forms (`fails(Text)`, `passes(Text)`). Whether a derived model keeps the
  inherited trust is a decision for Ty: the new text does not speak of derived models.
- **Size**: M.
- **What holds the old behavior**: `model_trusted/1` rules, WD2, the fixture `discovery-a`, test
  LG3 (calibration is accepted unchecked).

### K7 (K-c7). `report` shows no formal statement — PARTLY (that part is confirmed; "the delivery draft uses `Triggers:`" is not so for the tool)

- **New text**: NP "Who judges what" (NP:80-82): "put the formal statement beside the plain
  sentence (the KB fact, the property, the statement of the theorem). Show the statement, not the
  whole file." NP "Delivery" (NP:406-410): the fields `Signals:` and `Formal:`. NP:421: "In a KB,
  `orbit-kb report` drafts the middle fields and adds `Open:`". Ty: "I haven't seen _any_ lean
  proofs or prolog statements since starting to use Sagittarius."
- **Build**:
  - RUN (`b1`): the sections of `report` are `Delivered, Claims, Review, Guesses, Disclosures,
    Waivers, Not checked, Open, To land`. Code: `kb/bin/orbit-kb:7067-7232`. Help:
    `orbit-kb help report`: "Delivered, Claims, Guesses, Disclosures, Waivers (build), Not
    checked, Open, To land."
  - There is no `KB:`, no `Signals:`, no `Formal:`. The word "Triggers" is nowhere under `kb/`
    (search: no hit). `Triggers:` is a field of the **old prompt** only
    (`/home/ty/Projects/mine/sagittarius/prompt/SAGITTARIUS.md:174`). So this part of the lead is
    wrong for the tool.
  - A proved burn prints one fixed sentence: `kb/bin/orbit-kb:6882`: `Head = "Burn: proved in
    Lean."`. No theorem name, no statement.
  - `orbit-kb prove` (read in the code, not run): `kb/bin/orbit-kb:5121-5124` prints
    `proof ID of claim C: theorem T (M)`, `Statement: S`, `Log: PATH`, and "Check that the
    statement says what claim C says. orbit-kb cannot check that." The statement is kept in
    `runs/proof-ID.log` (`kb/bin/orbit-kb:5290`: `"statement ~w"`). So the text exists; `report`
    does not read it.
  - A statement that is only "stated" has no stored text: `lean_result` is
    `verdict(ref(claim), alt([stated, refuted(text), tested(int)]))` (`modules/build.pl:176-177`).
  - A solver or TLA+ property has no stored text: `encodes(ref(model), ref(claim))`
    (`modules/discovery.pl:43`) links a model file to a claim, not a property to a claim.
  - Prolog itself never reaches the human through the tool. RUN (`b1`): `show claims`, `report`,
    `why 'fulfilled(c1)'` print the prose templates of `decl/4` ("claim c1 is fulfilled,
    because ..."), not a fact or a rule.
- **Kind**: gap.
- **Smallest change**: `report` gets a `Formal:` section. For each current claim: the theorem
  name and the `statement` line of its proof log; the model and the property that states it,
  when a fact records one; else "none". Add a `KB:` line (the directory) and a `Signals:` line
  (see K16). Add the same to the page (`report --html`).
- **Size**: M.
- **What holds the old behavior**: CONTRACT:753 (the `report` row, section order), D16 C4 L1
  (CONTRACT:269: the list of headings), tests RP1 ("report sections in contract order"), RL1 to
  RL7, RH1 (golden files in `kb/tests/fixtures/report_golden`), BP8, FL10.

### K8 (K-c8). A relation written by an agent reads like a fact — CONFIRMED

- **New text**: PH principle 6 (PH:339-342): "an agent recorded that two sentences of the author
  exclude each other, and the knowledge base then reported a contradiction. The inference was
  sound. The reading was the agent's." NP "Who judges what" (NP:75-76): "What you record about the
  human's words is your reading, until the human confirms it."
- **Build**:
  - `modules/project.pl:32-34`: `excludes(...)`: "A human or an agent records that the two facts
    cannot both hold (D27). It is never inferred from the text."
  - `decided_by` and `ratified_by` take only a decision, a definition or a rule
    (`modules/project.pl:23`, `:26`). A relation has no id, so nothing can say who made it or
    ratify it. `proposed(X)` (`modules/project.pl:195`) covers only those three kinds.
  - RUN (`p1`, `sp`): two decisions `decided_by(..., ty, ...)`. The agent adds `excludes(d1, d2)`
    with `--as build`. `kb.pl` gets the bare line `excludes(d1, d2).` and no `actor` line.
    `contradiction(d1, d2)` holds, `proposed(X)` is false, lint is clean. A spec KB that pins
    `d1` then has `done` false: "project_contradiction d1: a claim pins d1 of the project KB, and
    d1 cannot hold together with d2 there (excludes). Ask a human to supersede one side".
    Nothing says that an agent wrote the relation.
  - `actor/3` is written "after each attestation (attest, run, prove, add) and each change"
    (`help/core.txt:40-41`). RUN: a plain `add` of a claim or a relation writes no `actor` line.
- **Kind**: gap.
- **Smallest change**: record who wrote each `excludes` and `depends_on` (an id for the
  relation, or `actor` for every `add`), and let a relation by an agent be "proposed" until a
  human ratifies it: a proposed `excludes` blocks nothing and is named as the agent's reading.
- **Size**: M.
- **What holds the old behavior**: D27 (CONTRACT:171 and its items), `contradiction/2`, tests in
  `kb/tests/test_project_kb.sh` (names not read one by one: not checked which).

### K9 (K-c9). Where the tool forces Lean — CONFIRMED

- **New text**: NP "One response" (NP:288-294): "a formal statement, in the one formal language
  that fits the claim: a solver for rules and limits, a model checker for orders of steps and
  time, Lean for every input." ... "at once for a claim that burns, and next for a claim that
  the records did not settle (the rules of the KB say when)." NP "Signals" (NP:262-263): "A
  claim that burns: the human asks for a proof, or the claim is universal by its meaning". PH
  principle 10 (PH:453): "in the language that fits that claim: a solver, a model checker, or
  Lean."
- **Build**:
  - `modules/build.pl:211-213`: `burn_reason(C) :- contested_twice(C), not visual(C).`
    `burn_reason(C) :- universal(C).` `burn_reason(C) :- burn_requested(C).`
  - `modules/build.pl:225`: `burn_proved(C) :- attest(A, lean_proof, _, proof(C, _), script, _),
    not proof_changed(A).` Only a Lean proof, or a waiver (`:226`), closes a burn.
  - D10 (CONTRACT:305-306): "TLC does not count as a proof (Lean only)".
    `help/discovery.txt:236-237`: "only a Lean proof or a human waiver closes a burn."
  - RUN (`b3`): two divergences on the claim "With dark mode on, every screen shows a dark
    scheme." give "burn_open c1: claim c1 needs a Lean proof" and `done` is false.
  - Where the tool accepts a solver or a model checker: only in the discovery module.
    `model(ref(subject), oneof([smt, tla]))` (`modules/discovery.pl:34`), `model_result`
    (`:66-74`), and `has_falsifier(C) :- encodes(M, C), model_decided(M, C), model_trusted(M).`
    (`:254`). A build KB has none of these. `orbit-kb prove` needs the build module
    (`kb/bin/orbit-kb:5064-5065`).
  - So the tool merges two things that the new texts keep apart: "a claim that burns" (asked, or
    universal: Lean) and "a claim that the records did not settle" (contested twice: the
    language that fits).
  - The new prompt also widens what a divergence is (NP:253-254: "a result differs from what
    you said that you expected, even by a small amount"). With the rule above, two such
    surprises on one claim now demand a Lean proof.
- **Kind**: contradiction.
- **Smallest change**: split the rule. `universal` and `burn_requested` keep the Lean burn.
  `contested_twice` makes the claim owe "a formal statement" that a Lean proof, or a counted
  solver or model-checker result on a model that states the claim, can close. Make `model`,
  `encodes`, `model_result` usable in a build KB. Unclear: which results close it (bounds), and
  whether a waiver still does. This needs Ty's word.
- **Size**: L.
- **What holds the old behavior**: D10 and its follow-up (CONTRACT:302-350), D21 F6
  (CONTRACT:229), E16 on the burn rules (CONTRACT:775), the Lean project `kb/tests/burn_model`
  (`BurnModel/Impl.lean:259-262` holds `burn_reason`), tests B13, BP1 to BP13, SC1 to SC7, FL6,
  FL7, BL2, the words "needs a Lean proof" at `kb/bin/orbit-kb:5932`, `:6013`, `:7208`, `:3912`.

### K10 (K-c10). A wrong hypothesis goes back to discovery — CONFIRMED

- **New text**: NP "The hypothesis" (NP:235-237): "If the answer says what it changes to ("only on
  this page"), restate it: the new hypothesis supersedes the old one. Show it, and go on. If you
  can no longer say what to change, the ticket is a report again: go to discovery." Ty: "we only
  go back there if the hypotheses need to change."
- **Build**:
  - `help/build.txt:143-144`: "Decide which is wrong: the build, or the problem itself. If the
    problem is wrong, run orbit-kb uses discovery, and go back to discovery (orbit-kb help
    discovery, BACK)."
  - `help/discovery.txt:261-262`: "When a divergence shows that the problem is wrong, not the
    build, file a disclosure, and run orbit-kb uses discovery. Then go to SIGNAL if the
    hypothesis is wrong".
  - The general help, step 1 (`kb/bin/orbit-kb:7776-7777`): "discovery when the problem is not
    yet clear (a report, a "why?" question, or you no longer agree with the human on the
    problem)".
  - `supersedes` of two hypotheses needs the discovery module (K1). In a KB with both modules,
    the new hypothesis "needs its own" system result (`help/discovery.txt:73`; WD7), which is
    discovery work, not "Show it, and go on."
  - `help/build.txt:139-149` has one path ("a divergence, not a preference change"). The three
    cases of NP "When the human says that it is wrong" (NP:326-335) are not there: the line
    "Kept: ... Changed: ...", the case "a new ticket, with its own hypothesis", and "If you
    cannot tell ... treat it as a divergence". The preference change is in the Flares block only
    (`help/build.txt:136-137`).
- **Kind**: contradiction.
- **Smallest change**: after K1, rewrite `help/build.txt:139-149`, `help/discovery.txt:260-264`
  and help step 1: restate in build with `supersedes(hNew, hOld)` when the answer says what the
  hypothesis changes to; go to discovery only when it does not. A superseding hypothesis in a
  build KB must not raise WD7.
- **Size**: S for the words, M with K1 (the WD7 rule).
- **What holds the old behavior**: D15 R3 (CONTRACT:280), tests RW2, RW3, RW5. No test in
  `kb/tests/*.sh` pins the words of BACK (searched "BACK", "back to discovery", "problem is
  wrong": no hit).

### K11 (K-c11). No record for a System 1 hint — CONFIRMED

- **New text**: NP "One response", System 1 (NP:306-309): "If the line names a divergence, a
  change of plan, or effort, treat that signal as fired. If you think that the hint is wrong,
  then you and System 1 disagree, and you do not settle that alone." Ty: System 1 "might
  eventually get its own API's in the orbit-kb tool."
- **Build**: no module, help topic or command names System 1, a hint, or `s1`. Search of
  `kb/bin/orbit-kb`, `modules/*.pl`, `help/*.txt` for "system 1" and "hint" (as a record): no
  hit.
- **Kind**: gap. It is small: the new prompt does not ask for a record of the hint itself. It
  asks that the signal is recorded (K16), and that the disagreement goes to the human or to a
  check.
- **Smallest change**: none beyond K16, if the signal record has a source field
  (`agent | system1 | human`). A dedicated API is a suggestion (S5).
- **Size**: S (as part of K16).
- **What holds the old behavior**: nothing.

### K12 (K-c12). Pins and proofs — PARTLY (the facts hold; two differences)

- **New text**: PH principle 9 (PH:410-411, 416-417): "A proof is about its definitions, not about
  the shipped code. Examples carry it to the code: each example of the definitions becomes a
  test of the code." ... "A file that changed can show that evidence is stale. It cannot show
  that the evidence still applies." NP "Honesty" 3 (NP:373): ""Proved in Lean" is about the Lean
  definitions, not the code."
- **Build**:
  - `orbit-kb pin` stamps the whole `kb.pl`. RUN (`b1`): `spec-kb@sha256:f76c... 2026-11-12T00:29:57Z`.
    D22 C8 (CONTRACT:107): "HEX is the sha256 of the bytes of `kb.pl`". It writes nothing.
  - A proof covers the Lean files and the Lake files, not the code.
    `kb/share/orbit-kb/README.md:550-553`: "the Lean source files of the project that the proof
    imports, and the Lake configuration files. If one of these files changes, the proof stops
    counting". `kb/share/orbit-kb/lean/probe.lean:17-19` lists the files. So a changed code file
    does not reopen a proof. That agrees with PH: the proof is about the definitions.
  - Difference 1: `report` says "Burn: proved in Lean." (`kb/bin/orbit-kb:6882`) and nothing
    more. The link to the code is optional and silent: `conformance(K)` and `conforms(C)`
    (`modules/build.pl:40`, `:242`) are read by no command (search of `kb/bin/orbit-kb` for
    "conform": no hit). So the delivery cannot say if any example was carried to the code.
  - Difference 2: a stale pin does not show in a spec KB. RUN (`sp`): after a change of the
    pinned file, `query 'stale_pin(P)'` gives `P = pf1`, but `show open`, `show blocking` and
    `report` do not name it. Lint gives only W1 for the subject. `stale_pin` is in no lint
    hook and no `blocking` clause (`modules/project.pl:155-157`, `:202-207`); the CLI never reads
    it (search: no hit).
- **Kind**: gap (both differences).
- **Smallest change**: the `Burn:` line names the theorem and says "about the Lean definitions";
  it adds the conformance check and its state, or "no check carries the examples to the code".
  A stale pin that a current claim or decision rests on becomes a lint warning and an `Open:`
  line.
- **Size**: S (the words of the line) + M (stale pins in `Open:`).
- **What holds the old behavior**: D10 (CONTRACT:322: "Optional conformance"), D23 P2
  (CONTRACT:115), tests BP4, BP5, PV1, PV10, golden report files.

### K13 (K-c13). Words in the help and the README — PARTLY

- **New text**: Ty: "Lean is not a modeling language". PH principle 11 (PH:500): "a Lean file holds
  definitions, and theorems about them." NP:175 and NP:201 (premises; "wide on purpose").
- **Build**:
  - "Lean model" — CONFIRMED: `help/build.txt:12` ("runs the code against the Lean model"), `:17`
    ("progress on a Lean model"), `:110` ("Write a Lean model of the behavior."), `:119` ("The
    proof is about the Lean model, not the code."); `modules/build.pl:41-42`, `:121-122`;
    `kb/share/orbit-kb/README.md:480`, `:604`, `:606`, `:1953`; CONTRACT:307 ("the Lean model"),
    and "the Lean burn model" in CONTRACT:97, 118, 218, 232, 258, 278, 283, 293 (the name of
    `kb/tests/burn_model`); comments at `kb/bin/orbit-kb:6726`, `:6749`.
  - The hypothesis example — CONFIRMED: `help/discovery.txt:86-91` (see K2).
  - "Scoped" against "wide": `modules/discovery.pl:26`: "A falsifiable and scoped restatement of
    the request." `help/discovery.txt:62`: "Restate it as one hypothesis, in the scope of the
    report".
  - `help/discovery.txt:75`: "the backbone of discovery". The new text makes the hypothesis the
    law of every ticket, in build too.
  - Citations of old prompt headings — NOT CONFIRMED. I searched `help/*.txt`,
    `kb/share/orbit-kb/README.md`, `modules/*.pl`, `core.pl` and `kb/bin/orbit-kb` for "The phase
    tree", "When to shift up", "Honesty rules", "Where the procedure is", "Start light",
    "Roles": no hit. The README names the prompt once, and that stays true
    (`kb/share/orbit-kb/README.md:973-975`). CONTRACT has history words only: "the phase tree"
    (CONTRACT:91), "the light path (no KB)" (:275), "the tiny discovery orbit" (:289).
- **Kind**: stale words.
- **Smallest change**: replace "Lean model" with "Lean definitions" (or "definitions and
  theorems") in the four files; fix the two "scope" phrases; keep the CONTRACT history lines.
  The name of the test project `burn_model` can stay or change: a decision for Ty.
- **Size**: S.
- **What holds the old behavior**: the `decl/4` texts of `conformance` and `conforms` appear in
  `show kinds`; no test pins "Lean model" in `test_orbit_kb.sh` (searched: no hit). Not checked:
  `evals/` graders.

### K14 (K-c14). Guesses — CONFIRMED

- **New text**: NP "The hypothesis" (NP:208-211): "A default in the hypothesis that the human has
  not confirmed is a guess about the intent ... A premise that you did not check is a guess
  about the system. ... List them in the delivery." NP "Delivery" (NP:411): "Guesses: <defaults
  that a human might disagree with, and premises that you did not check>".
- **Build**:
  - `Guesses:` of `report` reads only questions: `kb/bin/orbit-kb:7111`:
    `eng_all(Eng, [Q, A], ( assumed(Q, A), not(answered(Q)) ), Gs)`.
  - `assumed(ref(question), term)` and `question(id, ref(claim), text)`
    (`kb/share/orbit-kb/core.pl:99-104`): a guess needs a question, and a question needs a claim.
    A default inside the hypothesis has neither.
  - The disclosure `guess(ref(question))` has the same limit (`kb/share/orbit-kb/core.pl:242`).
  - RUN (`b1`): with no question, `Guesses:` says "None. No question has a default." while the
    claim "every screen" is itself an unconfirmed default.
- **Kind**: gap.
- **Smallest change**: `Guesses:` also lists each premise that is not checked (after K3) and
  each default of the hypothesis that the agent marks (a fact on the hypothesis, or a question
  that can hang on a hypothesis and not only on a claim).
- **Size**: M (with K3).
- **What holds the old behavior**: D17 C5 (CONTRACT:256, the two "None." sentences), tests RP3,
  NC2, golden files.

### K15 (K-c15). SPECTRUM step 4 writes one claim in two languages — PARTLY

- **New text**: NP "One response" (NP:298-301): "One formal language is one lens. Write in one at
  a time." ... "A signal that fires while you write in one formal language does not start a
  second one". NP:292: "Go to a formal statement for one claim at a time". PH principle 5
  (PH:324-325) allows two statements of one claim: "When two tools state the same claim, write
  each statement from the source". PH:513: ""At a time" is about writing."
- **Build**: `help/discovery.txt:120-121`: "If a claim mixes rules and steps, model the steps in
  TLA+ with the rules as guards, and the rules alone in SMT, with the same claim ids."
  `help/discovery.txt:122-124` then agrees with PH principle 5 ("build each statement from the
  report and the SURVEY facts, not from the other statement").
  `help/discovery.txt:238-239`: "For a claim in SMT or TLA+ and again in Lean, run the SMT
  witnesses as Lean #eval examples."
- **Verdict detail**: two statements of one claim are allowed by the new texts. What step 4
  lacks is the order: it sets two languages as the default for a mixed claim, with no "finish
  one first". The new prompt wants "the one formal language that fits the claim".
- **Kind**: stale words (a mild contradiction).
- **Smallest change**: reword step 4: choose the lens for the part of the claim that is in
  doubt; finish it and record its result; start the second language only when a question is
  left. Say the same in the HANDOFF lines.
- **Size**: S.
- **What holds the old behavior**: nothing that I found (no test pins step 4).

### K16 (K-c16). Records for the six signals and for the spoken lines — PARTLY

- **New text**: NP "One response" (NP:291-292): "With no KB yet, start one, and record what fired.
  In a KB, record the signal there." NP "Signals" (NP:268-270): "Record each decision in the
  human's own words." NP "Delivery" (NP:406): "Signals: <questions, divergence, someone else
  built, burns, handoff, effort: each "no", or "yes" and what fired it>". NP:278, NP:316: the
  lines "Shifting up: ..." and "Leaning back: ...". Ty: "All six signals should elicit the same
  response."
- **Build** (what exists for each signal):
  - Questions: `question`, `assumed`, `answer`, `to_ask` (`help/core.txt:22`, `:71`);
    `lap_done(N)` in discovery (`help/discovery.txt:14`). No record of "one round did not settle
    it".
  - A divergence: `attest divergence` with `claim(C) | hypothesis(H) | model(M)`
    (`help/core.txt:57`). It must name a claim, a hypothesis or a model.
  - A build by someone else: `actor(A, Role, Session)`, `review_saw`, `independently_verified`,
    lint WR1 (`help/core.txt:39-49`, `help/build.txt:25-32`). WR1 is a warning and "does not block
    done".
  - A burn: `universal`, `burn_requested`, `contested_twice` (K9).
  - A handoff: `writer_takeover(From, To, Time)` and `orbit-kb release`
    (`help/project.txt:168-175`), `orbit-kb pin`. No fact says "this work was handed over".
  - Effort: nothing. A decision in the human's words has no fact in a spec KB: `decision/2` is in
    the project module (`modules/project.pl:14`). RUN (`b3`): a second `request(r2, '...')` is
    accepted, and so is a first-use `signal(effort, '...')`, but then lint gives W4 ("No rule
    reads the local fact signal/2"), W7, W9, and no output prints it.
  - The spoken lines: nothing. No `shift`, `signal`, `trigger` or `lean_back` fact; search of
    `kb/bin/orbit-kb` for "Signals", "Triggers", "shift", "trigger": no hit (only "Formal
    artifacts" at `:5767`).
  - `report` has no `Signals:` line (K7).
- **Kind**: gap.
- **Smallest change**: one fact for a fired signal (kind, what differed, who noticed: agent,
  System 1, human), one for a lean back, both written by `add`; `report` drafts `Signals:` from
  them ("no" for each kind with no record). A fact for a decision in the human's words in a spec
  KB, or the rule "a second `request` holds it".
- **Size**: M.
- **What holds the old behavior**: the `report` section list (K7).

### K17 (K-c17). Does the first screen of `orbit-kb help` still tell a true story — PARTLY

- **New text**: NP "The tool" (NP:441-449); NP "Scope" (NP:86-93); PH principle 13 (PH:533): "Give
  each term one meaning."
- **Build** (RUN `orbit-kb help`; code at `kb/bin/orbit-kb:7774-7843`):
  - True: it is one screen (81 lines); it gives the commands, their order and the topics; step
    6 "orbit-kb show open ... run it first when you resume a KB"; the exit codes ("A typo never
    exits 1. Exit 1 always means a real "no"."); `help/answers.txt:6`: "Exit 2 is never a no."
    The phase lines "discovery: research, specify" and "build: build, verify" match NP:97-99.
  - Stale 1: step 1 sends "a "why?" question" to discovery. NP:86: "A question, a debate, or
    advice with no change to make: answer directly, with no KB."
  - Stale 2: step 1 sends "you no longer agree with the human on the problem" to discovery.
    See K10.
  - Stale 3: the steps have no hypothesis (K1). Step 2 starts at `claim`.
  - Stale 4: the move name **SIGNAL** ("SIGNAL: pin the report", `help/discovery.txt:60`; the
    phase line at `kb/bin/orbit-kb:7796`) now shares its word with the new term "signal" (NP
    "Signals"). The old prompt said "triggers", so the clash is new.
  - The resume rule is true only in part: `help/answers.txt:23-24`: "In a KB that uses discovery,
    also orbit-kb lint, because show open omits the discovery items." NP names only `show open`.
    See K19.
- **Kind**: stale words.
- **Smallest change**: rewrite step 1 and step 2 of the first screen; rename the move SIGNAL
  (for example "RESTATE"), in the help, the phase block and the contract.
- **Size**: S (words), but the rename touches the contract and a test.
- **What holds the old behavior**: D22 C9 (CONTRACT:108: the exact phase lines), test PH1
  (`test_orbit_kb.sh:2865`: `out_has 'research +SIGNAL, SURVEY, FLYBY, TRAJECTORY, DISPROVE'`),
  HP4.

### K18 (K-c18). The tool has no version — CONFIRMED

- **New text**: PH "Where Sagittarius sits" (PH:819-820): "Each release of Sagittarius has a
  semantic version, and the prompt names its own version." NP "The tool" (NP:443-444): "Follow
  the help of the version that is installed here: a workspace can pin its own." Ty: "we need a
  semver system for sagittarius now".
- **Build**:
  - RUN: `orbit-kb version` gives "Unknown command version. If version is a query, run it with
    query: orbit-kb query 'version(X)'" (exit 2). `orbit-kb --version` gives "Unknown command
    --version." (exit 2).
  - `orbit-kb help` prints no version. The only "version" in `kb/bin/orbit-kb` is the SWI-Prolog
    version for the start cache (`:24`, `:147`, `:7679`).
  - The contract has a version in its title only: CONTRACT:1: "# orbit-kb contract (v2.1,
    2026-10-15)". `modules/discovery.pl:1` says "(contract v2.1 through D7)", which is far behind
    D29.
  - A `kb.pl` records no tool or schema version (RUN `b1`: the file starts `uses([build]).`).
    So "a workspace can pin its own" has nothing to compare.
  - The hub kit does have a version (`kb/tests/test_release.sh:5`: "hubkit/kit.json version is
    higher than the first one"). `orbit-kb` does not share it.
- **Kind**: gap.
- **Smallest change**: `orbit-kb version` and a version line at the top of `orbit-kb help`,
  from one source that the prompt and the release also read. Optional: `init` writes the
  version into `kb.pl`.
- **Size**: M.
- **What holds the old behavior**: CONTRACT:724-755 (the command table), HP1 to HP4.

---

## Part 2. Differences that I found

### K19. `show open` and `Open:` can say "Nothing is open" while `done` is false

- **New text**: NP "The tool" (NP:447-448): "When you resume, ask the KB what is open (`orbit-kb
  show open`) before you do anything else." NP "The idea" (NP:21-22): the quiet failure, "an
  empty answer". PH "How to judge a change" 4 (PH:856): "Can a missing answer look like a "no"?"
- **Build**:
  - `show open` lists only `to_ask`, `stale`, `contested`, `supersede_cycle`, and with build
    `under`, `over`, `burn_open`, `flare_open`, `no_claim`, plus `request_stale` and pending
    answers (`kb/bin/orbit-kb:5913-5947`).
  - RUN (`sp`): `query done` is false and `show blocking` prints "project_contradiction d1 ...",
    but `show open` prints "Nothing is open." and `report` prints "# Open: - Nothing is open."
    The `Open:` code has no project item (`kb/bin/orbit-kb:7174-7229`).
  - RUN (`b2`): `report` says "**not ready**: Discovery is not ready"; `show open` says "Nothing
    is open." The help admits it (`help/answers.txt:23-24`) and D19 keeps it (CONTRACT:244:
    "`show open` does not change.").
  - A stale pin shows in neither (K12).
- **Kind**: gap (a quiet failure in the command that the prompt names for the resume).
- **Smallest change**: `show open` and `Open:` print every answer of `blocking(X)` and, with
  discovery, what blocks `discovery_ready`. "Nothing is open" prints only when `blocking(_)`
  has no answer and discovery is ready or absent.
- **Size**: M.
- **What holds the old behavior**: CONTRACT:752 (the `show` row), D19, D22 C7 ("`show all` does
  not include it"), tests SH3, RP7, NC2, FL1, golden files.

### K20. No text output prints the hypothesis, the request, or an example

- **New text**: NP "Who judges what" (NP:78): "Show the human concrete examples and results
  first." NP "The vote" (NP:360-361): "On GO, the hypothesis, the claims, their examples, and the
  reproduction are the ticket." NP "The light path", Discovery 4 (NP:148-150): the report starts
  with "the hypothesis and its premises".
- **Build**:
  - The CLI reads `hypothesis` only for `supersedes` checks and cycle messages (all hits:
    `kb/bin/orbit-kb:2233-2343`, `:5771`, `:5923`, `:7980`). No `show` section and no `report`
    section prints its text. RUN (`d1`): the page of `report --html` holds the request and the
    example, and not the hypothesis.
  - RUN (`b1`): `show claims` and `report` print the claim, its state, `Cites:` and `Checks:`.
    The `example(c1, ...)` fact is not printed. Examples print only in the question view and the
    page (`kb/bin/orbit-kb:1134`, `:4009`).
  - `scope`, `risk`, `not_explored`, `assumption`, `finding` are read by no output (search of
    `kb/bin/orbit-kb` for `scope(`, `risk(`, `not_explored`, `assumption(`, `finding(`: no hit),
    though `help/discovery.txt:5` says "Record scope, risk, assumption, and not_explored" and
    `help/core.txt:99` says "Write a fact only if a query or the delivery report reads it."
  - `help/discovery.txt:242-243`: "orbit-kb report prints the build-orbit sections and a Vote:
    section; write the rest yourself."
- **Kind**: gap.
- **Smallest change**: `report` and `show` start with the hypothesis and its premises when one
  is recorded, and print one example under each claim. In a discovery KB, `report` drafts the
  discovery report from the facts.
- **Size**: M.
- **What holds the old behavior**: the `report` contract and golden files (as K7).

### K21. Readiness in the tool asks for no example, and accepts a check that never ran

- **New text**: NP "The vote" (NP:348-350): "the current system was checked for the hypothesis
  (the reproduction); each claim has its example and its falsifier; nothing waits for the
  human".
- **Build**:
  - `discovery_ready` (`modules/discovery.pl:328-337`) has no literal about `example/2`.
  - `has_falsifier(C) :- check(_, C).` (`modules/discovery.pl:253`): the check need not have a
    run.
  - RUN (`d3`): a hypothesis, one claim with no `example` and no `cites`, one check that never
    ran, and `attest reproduction t1 'result(h1, reproduced)'` on that same check: `query
    discovery_ready` is true. Lint gives only W3.
  - The tool also asks for more than the three bullets (no weak rule, no model problem, no
    unratified supersession: `:334-336`). That is not a conflict: NP:354 says "the tool computes
    this vote, and it says what blocks readiness."
- **Kind**: gap.
- **Smallest change**: add "some current claim has no example" to what blocks readiness, with a
  lint code. Decide if a reproduction on a check needs a red run of it.
- **Size**: M.
- **What holds the old behavior**: `discovery_ready` is not E16-protected (CONTRACT:287), the
  fixture `discovery-a/expected.pl`, tests NC5, RW2.

### K22. A test in `kb/tests` reads the prompt, and the new prompt fails it

- **New text**: NP "The tool" (NP:441-449) names no topic. It has no line with "help build"
  (search of NP: no hit).
- **Build**: test VR6, `kb/tests/test_orbit_kb.sh:2613-2614`:
  `grep -E 'help build' "$pr/SAGITTARIUS.md" | grep -Eqi 'fresh-eyes|FULFILL' || note
  "SAGITTARIUS.md: the help build line points to the fresh-eyes brief"`. With the new prompt at
  `prompt/SAGITTARIUS.md`, the first `grep` finds nothing, so the test notes a failure. (Read
  from the test text; the suite was not run.)
  KD1 (`:2197`) also reads the prompt (it must not name `orbit-kb declare`): the new prompt
  passes that.
- **Kind**: contradiction (a check of the build against the old prompt text).
- **Smallest change**: drop the prompt line from VR6, or point it at the place where the new
  texts send a reviewer to the brief (NP:260-261 says "Read the request and the diff, and run
  its checks yourself"; the FULFILL brief stays in `help build`). The `panes/review.md` half of
  VR6 belongs to another area.
- **Size**: S.
- **What holds the old behavior**: VR6 itself (T38).

### K23. "Do not edit a KB file by hand" against the tool's own fix for E19

- **New text**: NP "The tool" (NP:446): "Use the tool for all work on a KB. Do not edit a KB file
  by hand."
- **Build**: `help/codes.txt:29-30`: "A typo: correct the facts in kb.pl, and delete the decl/4
  and first_use/3 lines of the new name." D22 C3 (CONTRACT:94): "The fix for a typo is to
  correct the facts by hand in `kb.pl`". The command list has no command that removes or
  corrects a fact (RUN `orbit-kb help`). E19 is an error that stops `query`, `show` and `report`
  with exit 2 (`help/codes.txt:32`), so the agent must act. The old prompt had the same rule, so
  this is not new; the new text keeps it.
- **Kind**: contradiction.
- **Smallest change**: a command that withdraws a first-use kind and its facts (with a record),
  or one sentence in NP and in `help codes` that names this one allowed hand edit.
- **Size**: M (a command) or S (the sentence).
- **What holds the old behavior**: D22 C3, tests FU1 to FU8.

---

## Suggestions beyond alignment

Each is apart from the findings. None is needed for agreement.

- **S1. One command for the shift up.** Problem: K4 (4 to 8 commands, 415 to 490 help lines).
  Evidence: the counts in K4. Idea: `orbit-kb start DIR --from FILE`, where FILE holds the
  light-path state (request, hypothesis, premises, claim, example, check command). It prints the
  next command. A `help shift` topic of one screen.
- **S2. `report` drafts the discovery report.** Problem: the agent writes it by hand, and facts
  that the help asks for are read by nothing (K20). Evidence: `help/discovery.txt:242-243`; no
  hit for `scope(`, `risk(`, `not_explored` in the CLI.
- **S3. Say why a claim is `under`.** Problem: `show blocking` says only "claim c1 is current but
  not fulfilled" when the cause is a missing red run. Evidence: RUN `b4`; the reason shows only
  in `whynot 'fulfilled(c1)'`.
- **S4. An actor for every `add`.** Problem: only attestations and changes carry who wrote them
  (K8). Evidence: RUN `p1`: `excludes(d1, d2).` has no `actor` line. It would also serve "a build
  by someone else".
- **S5. A record for a System 1 hint** (`orbit-kb hint`, or a `source` on the signal fact).
  Problem: a disagreement between System 1 and the agent leaves no trace, so use cannot count
  false hints (PH "Under trial", PH:833). Evidence: K11. Ty: System 1 "might eventually get its
  own API's in the orbit-kb tool."
- **S6. A `help hub` topic.** Problem: hub procedure sits inside the core, build and project
  topics (`help/core.txt:102-103`, `:134-135`; `help/build.txt:53-62`; `help/project.txt:85-96`),
  while Sagittarius must be "true alone: with no hub" (PH:811-812). Evidence: those lines. Not
  checked: how each `--hub` command behaves with no hub, beyond the help text.
- **S7. A warning when the agent votes `go` while not ready**, if a rule change of the gate is
  too heavy (K5). Evidence: RUN `d2`.
- **S8. A stale line in `help add`.** `kb/bin/orbit-kb:7884`: "Write a classical negation as
  '-world(x)'." But `add` refuses classical negation (E17, `help/codes.txt:21-23`). Not an
  alignment item; it is a small error in the help.
- **S9. `concerns/2` accepts a rule.** `modules/project.pl:47`:
  `concerns(ref([decision, definition]), ref(pin))`. A product rule cannot rest on a pin. NP
  "Delivery" (NP:424-426) gives outcomes that outlive a ticket a home as a rule. (Lead from
  REWORK-PLAN; the line is verified, the need is not.)
- **S10. The version in `kb.pl`.** `init` writes the tool version, and a newer KB read by an
  older tool fails loud. Problem: a workspace that pins its own `orbit-kb` (NP:443-444) can read
  a KB with facts it does not know. Evidence: K18; not tested with two versions.
- **S11. A premise as a `world` fact with a `source`.** `world(Fact), source(Fact, Where)`
  (`help/core.txt:20`) already means "the current state, and where you saw it". A checked
  premise is close to that. It may make K3 smaller. Not designed here.

---

## Where the build already agrees

- **A check of a change fails first.** `fulfilled/1` needs `was_red(K)` for `retire` and
  `introduce`, and not for `preserve` (`modules/build.pl:193-195`). NP:131-133.
- **Never type a digest or a test result.** `add` refuses `test_result` and `lean_proof`
  (CONTRACT:728, E8, E9). NP:446-447.
- **An answer that could not be computed is not a "no".** Exit 2 against exit 1
  (`help/answers.txt:3-8`). NP:448-449.
- **Waivers.** Human only, with a due time; a lapsed waiver blocks again; `report` lists every
  waiver (`modules/build.pl:226`, `:249-252`; `help/build.txt:165-171`). NP:432-437.
- **The vote.** Weights 0.49, 0.24, 0.24 (RUN `d2`: "Human (0.49) ... Agent (0.24) ... Formal
  artifacts (0.24)"); the human plus one other; no winner is `hold`; the agent's vote is hidden
  in `report` until the human votes; `whynot 'discovery_ready'` says what blocks
  (`modules/discovery.pl:304-323`). NP:342-359. Only K5 differs.
- **Findings from the system or from a model; a lead does not block readiness.**
  `finding(F, Kind, From)`, `finding_lead/1`, WD4 is a warning outside `discovery_ready`
  (`modules/discovery.pl:46`, `:272`, `:350`). NP:384-385.
- **A model that cannot fail.** Sanity must show a case; an `applies` check with no case is ED4
  (`modules/discovery.pl:219`, `:241`, `:373`). NP:391-392.
- **A claim that changes inside the hypothesis.** `supersedes(New, Old)` plus a disclosure;
  "Do not edit a check to make it pass" (`help/build.txt:73-74`). NP:238-241.
- **Intent moved is not a divergence.** `help/build.txt:136-137`. NP:329-332.
- **Asking.** At most three questions, options, the default, no list to approve; `option(Q,
  Text, Effect)` (`help/core.txt:123-132`, `:23`). NP:154-161.
- **A rule that outlives the ticket.** `rule/2`, an agent's fact is `proposed` until
  `ratified_by` a human; `add` refuses an agent as ratifier (`modules/project.pl:20`, `:194-195`;
  `help/project.txt:17-18`). NP:424-426.
- **A build by someone else.** The FULFILL brief: the reviewer sees only the ticket, the KB and
  the diff, reruns each check, and records a verdict that rests on its own runs
  (`help/build.txt:76-103`). NP:260-261.
- **The trust limit is said.** `--by human` and the role are self-reported; `prove` does not
  resist cheating (`help/core.txt:50-52`; `orbit-kb help prove`). NP:376-380.
- **The proof is about the definitions.** A changed Lean or Lake file reopens the burn; a code
  file does not (`kb/share/orbit-kb/README.md:550-553`, `:604`). PH:410-417.
- **`pin` covers the whole `kb.pl`** (D22 C8). The lead in REWORK-PLAN that corrects an earlier
  handoff is right.
- **Two statements of one claim come from the source**, not from each other
  (`help/discovery.txt:122-124`). PH:324-325.

## Not checked, and unclear

- I ran no test suite, no `lake`, no solver, and not `orbit-kb prove`. What `prove` prints is
  from the code (`kb/bin/orbit-kb:5121-5124`).
- `kb/share/orbit-kb/README.md` (2,131 lines): I read sections 1, 3 (start), 7 (burns, flares,
  waivers) and 8 (`report`, `help`), and searched the rest. Other sections: not checked.
- The question view and the question server (`view questions`, `serve questions`), `draft`,
  `pin-question`, `pin-answer`, `pin-request`: not checked against the new texts.
- `kb/tests/test_project_kb.sh`, `test_question_*.sh`, `test_tracker_sync.sh`: I searched them
  for reads of the prompt only. Which of their tests hold K8 and K12: not checked.
- `kb/tests/burn_model`: I read two lines of `BurnModel/Impl.lean`. How much of it must change
  for K9: not checked.
- REWORK-PLAN: searched, not read in full. `tmp/issues/6-premises.md`: read.
- Unclear, for Ty:
  1. K5: must the tool refuse GO while not ready, or only warn? The weights say the human and
     the agent together win.
  2. K9: which result closes a claim that was contested twice (a bounded solver result, a TLC
     run, only Lean)? Does a derived-model rule apply?
  3. K4: how to record a red run that the agent saw on the light path, before the KB existed.
  4. K6: does a target model keep the trust that it inherits from a calibrated model?
  5. K13: does the test project name `burn_model` change with "Lean is not a modeling language"?

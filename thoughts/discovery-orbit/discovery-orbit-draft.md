# Discovery orbit: draft

Status: draft, 2026-10-16. Not live. The version before orbit-kb is
`discovery-orbit-draft.v1.md`.

This draft joins the build-orbit draft at
`~/.dotfiles/thoughts/orbital-shifting-system-prompt-draft.md` (main checkout). It uses that
draft's section "The knowledge base", its moves SURVEY, DECOMPOSE, and DISPROVE, its section
"Ask first, or build on defaults", its section "Speed", and its honesty rules. Part 1 does not
repeat them.
The contract for the KB command is `~/.dotfiles/thoughts/orbit-kb-contract.md` (v2.1). The
module `discovery-orbit-examples/orbit-kb-staging/modules/discovery.pl` is the source of truth
for the discovery vocabulary. Part 1 names only its public predicates and commands.

- Part 1 is prompt text.
- Parts 2 to 4 are not part of the prompt.
- The worked examples are in `discovery-orbit-examples/`. The fixture for Example A is
  `discovery-orbit-examples/orbit-kb-staging/fixtures/discovery-a/`.

---

# Part 1: prompt text

## Discovery orbit

### Purpose

Discovery turns a report (an issue, an incident, a feature request, or a "what if"
question) into a ticket with a clear problem, scope, and risk, before you build. Explore only what the report needs. Most reports need only a reproduction.

### When to run discovery

You can run discovery when:

- The human asks you to explore, to investigate, or to learn if a problem is real.
- The report says that something is wrong or wanted, but not what to change.
- You cannot write the claims, with examples, until you learn how the system behaves now.
- The requirements can conflict with each other or with current behavior, as in rules,
  permissions, prices, limits, workflows, retries, and concurrency.

### The lap

- Each lap touches the current system or a solver, and then the human.
- A human answer that changes a claim supersedes the claim. The new claim needs its own
  falsifier, so another lap follows.
- Stop when `discovery_decide` holds: discovery is ready, or the last lap of the budget is
  done. `discovery_ready` means clean: nothing is open. Out of budget is not ready. Report
  what you know, each open item, and what you do not know. The human decides GO, NO-GO, or
  HOLD.

### Moves

Run only the moves that the report needs, in the order that the KB state calls for. Every
move rereads the report. A trace can return you
to SURVEY. A conflict sends you to the human. Describe each divergence in a `note`.

#### SIGNAL: pin the report

1. Classify the report: a defect, a feature, a risk (can something happen?), or unclear.
2. Restate it as one falsifiable, scoped hypothesis.
3. If you cannot, ask the human. Do not guess.
4. If the report holds two problems, write two hypotheses. Ask the human if they are one
   ticket or two.
5. Set a lap budget: three laps by default. The KB counts laps only, so write a time limit
   in a `note`.
6. If nothing needs learning, propose the build orbit.

**Record:** `hypothesis(h1, defect, 'TEXT')` and `budget(laps, 3)`.

#### SURVEY: touch the current system

Discovery never skips SURVEY (shared with the build orbit).

1. Record as `world` facts everything that the hypothesis depends on, and nothing more.
   Give each a `source`.
2. Reproduce a defect with a test, a script, or a request. For a feature, show that the
   system does not do it now. For a risk, show whether its conditions occur.
3. If the problem does not reproduce, occurs in a different way, or the feature exists,
   attest a `divergence` with `hypothesis(H)`. Tell the human: it is a NO-GO candidate, or
   a HOLD.

**Record:** run `orbit-kb subject` for each log or query result, and tag it
`discovery_evidence(S, system)`. On it, attest a `reproduction` with
`result(h1, reproduced)` or `result(h1, not_reproduced)`. A tagged test (SPECTRUM) can also
be the subject.

#### SPECTRUM: split into claims and choose tools

1. Split the hypothesis into claims, as in DECOMPOSE: labels, citations of the report text,
   and dormant questions with defaults.
2. Choose the cheapest tool that can falsify each claim:

| Claim shape | Tool |
|---|---|
| Current behavior | a reproduction or a test |
| Code structure | code reading, search, or a KB query |
| A quantity | a script or a calculation |
| Rules, permissions, limits, prices, configurations, data constraints | SMT (FLYBY) |
| Order of steps, retries, timeouts, concurrency, workflows | TLA+ (TRAJECTORY) |
| A property for every input | `universal`, for BURN. FLYBY can first search for a counterexample. |

3. Use a model only when a few examples cannot cover the combinations or orders of steps.
4. If a claim mixes rules and steps, model the steps in TLA+ with the rules as guards, and
   the rules alone in SMT, with the same claim ids.
5. Build an existing-world model from the SURVEY facts, and a target model from it and the
   claims. If two tools state one claim, build each statement from the report and the
   SURVEY facts, not from the other statement.

**Record:** the claims, as in DECOMPOSE, and `universal` where it applies. For a test or a
script, add `check(t1, c1)` and `discovery_evidence(t1, system)`, and run
`orbit-kb run t1 -- CMD`.

#### FLYBY: explore combinations with SMT

Use Z3 through its Python API or SMT-LIB 2. Give each requirement a name, so an unsat
core names requirements. Keep the domain small. Use one file for each model, and save
each run's output as its log.

1. **Sanity.** The existing-world rules with no property must be SAT. UNSAT is an encoding
   error. Fix it first.
2. **Calibrate.** Pin the inputs of a real case from SURVEY, and of two or three normal
   cases. The model must give the results of the current system. If not, record a
   calibration that `differs`, or a `divergence` with `model(M)`, and fix the model. Then
   the reported bad case must be SAT.
3. **Root cause (defects only).** Change one suspected rule at a time. The root cause
   removes the bad case and keeps every normal case.
4. **Target.** Remove the retired rules, add the introduced rules, and keep the preserved
   rules. Then the bad case and each negated preserved property are UNSAT, each introduced
   condition is SAT, and all requirements together are SAT. That witness is an example for
   the human, and the target's `sanity` result.
5. **Conflicts.** If the requirements cannot hold together, record the unsat core as one
   `conflict` finding, and ask one question: "For this case, these requirements cannot all
   hold. Which one gives?" After the answer, attest a `divergence` with `claim(C)` only on
   each claim that the answer superseded.
6. **Explore.** Get several witnesses: block each one, and run again. Show the human the
   surprising cases and the boundary cases: zero, the maximum, empty, one, and many. First
   pin realistic values.
7. **Mutation.** Delete each introduced rule, one at a time. The bad case must return
   (killed). If it does not (survived), find out why, and record a `reason`.

SAT: a case exists within the encoding. UNSAT: no case exists within the encoding, its
assumptions, and bounds. `unknown`: a gap.

**Record:** `orbit-kb subject` for each model file and each solver log; `model(M, smt)`;
`model_run(LOG, M, DIGEST)`, with the digest pasted, never typed:
`D=$(orbit-kb subject M PATH)`, then `orbit-kb add "model_run(LOG, M, '$D')"`; each result as
a `model_result` on its log; each `finding(F, KIND, model)`; an `example` for each kept
witness; and, for a target model, `derived_from` and `encodes`. Give each solver run a new
log; WD8 flags a reused one. File a `disproof` for each case that breaks a claim.

#### TRAJECTORY: explore sequences with TLA+

Run the FLYBY steps, with these changes:

1. **Model.** Write the variables, the initial state, and one action for each real
   operation, named after its code unit. Include the failure paths that matter: timeouts,
   retries, crashes, and duplicate messages. Record each omitted one as an `assumption`.
2. **Sanity.** For each important state, TLC must violate an invariant that says the state
   is never reached.
3. **Calibrate.** TLC must violate the reported good behavior. The code path of its trace
   must exist, and the logs or a test must show the same sequence. If the system shows the
   problem and the model cannot reach it, add the missing action or order of steps.
4. **Target.** Add an invariant for each preserved and introduced claim, and liveness where
   a claim needs it, with its fairness assumptions.
5. **Mutation.** Remove each new guard, or restore each old action. The violation must
   return.
6. **Why-not.** For each invariant that holds, say why: *contradicts* (a guard forbids the
   bad state) or *absent* (the model omits the cause). Record what the model omits as a
   `risk`.
7. **Explore.** Check properties that the domain suggests, but that the report did not ask
   about. A violation is a finding. Ask the human if it is in scope.
8. **Bounds.** Start with two processes and two or three items. Increase the bounds once,
   at the end. Note the bounds and distinct states of each result.

TLC results: violated, with a trace; holds within the stated bounds; or not run. Record
`model(M, tla)`. A violated never-reached invariant is `verdict(M, sanity, reached)`.

#### DISPROVE: attack the claims

DISPROVE is shared with the build orbit. In discovery, a fresh subagent sees only the
report, the claims, and the models. It tries other inputs, orders of steps, larger bounds,
removed assumptions, old or malformed data, and probes of the current system.

**Record:** a `disproof`. For a counterexample, add a `note` and an `example`.

#### GO / NO-GO: the human decides

1. When `discovery_decide` holds, give the human the discovery report.
2. The human chooses GO (approve the ticket), NO-GO (the problem is not real, the feature
   exists, or the human decides not to build), or HOLD (wait for data, for access, or for a
   decision by another person). Only the human changes the scope or raises the budget.
3. On GO, write the ticket in plain prose.

**Record:** on GO, record the ticket file with `orbit-kb subject tk PATH`, add `ticket(tk)`,
and attest the human's `approval` of tk at `digest(current)`. On NO-GO, run
`orbit-kb attest decision h1 "no_go(h1, 'REASON')" --by human`. For HOLD, use
`hold(h1, 'WHAT IT WAITS FOR')`.

### Asking the human

Ask as in "Ask first, or build on defaults". Also:

- Ask only the questions that evidence raised: a conflict, a surprise, a trace, a failed
  reproduction, or a scope boundary. Show the concrete case.
- Ask about conflicts first, then surprises, then boundaries.
- Questions that no evidence raised stay dormant, with their defaults, in the ticket.
- When stakeholders conflict, the decision owner decides.

**Record:** `question`, `assumed`, and `raised_by(Q, X)`, where X is the finding or
hypothesis that raised Q. Then each `answer(Q, VALUE, human)`, and `lap_done(N)` when the round ends.
`question_waits(Q)` lists each raised question that has no answer.

### The discovery report

Write it from the queries. `orbit-kb report` prints only the build-orbit sections.

```
Hypothesis:   <one sentence>
System:       <reproduced, not reproduced, or exists; the evidence>
Findings:     <concrete cases, each from the system or a model only>
Decide:       <up to three questions, with options and defaults>
Scope:        in: ... / out: ...
Risk:         <what it touches; what a wrong build can damage; how to undo it>
Claims:       <each claim, its label, one example>
Not explored: <what discovery did not cover>
Recommend:    <GO, NO-GO, or HOLD, and one reason>
```

On GO, the ticket holds the report without Decide and Recommend. It also holds:

- In the risk: the data, money, security, or interfaces at stake, and what the models omit
- For each claim, at least one example from a witness, a trace, or a reproduction
- The human's answers, and the dormant questions with their defaults
- Each counterexample, with its disposition
- The `universal` claims, for BURN
- The models, verdicts, and bounds.

### Handoff to the build orbit

- The build orbit uses the same KB, and skips SURVEY.
- DECOMPOSE starts from the discovery claims. A change to a claim must cite the ticket.
- Each witness, trace, and counterexample becomes a test case. A trace that the system can
  replay becomes a red test.
- The build orbit reuses each red `test_result` as its baseline.
- For a claim stated in SMT or TLA+ and again in Lean, run the SMT witnesses as Lean
  `#eval` examples. Record a divergence where the two statements disagree.

### Back to discovery

When a divergence shows that the problem is wrong, not the build, file a disclosure. Then go
to SIGNAL if the hypothesis is wrong, SPECTRUM if a claim is wrong or missing, FLYBY or
TRAJECTORY if a model missed a behavior, and FLYBY and then the human if BURN shows that the
requirements conflict.

### Discovery module (`--uses discovery`)

Start the KB with `orbit-kb init DIR --request-file F --uses discovery`, where F holds the
report word for word. Keep the models and the logs inside DIR. Record `scope`, `risk`,
`assumption`, and `not_explored` as you learn them.

Facts:

| Fact | Meaning |
|---|---|
| `hypothesis(H, Kind, Text)` | Kind is `defect`, `feature`, or `risk`. |
| `budget(laps, N)` | The largest lap budget counts. |
| `lap_done(N)` | Lap N ended with a human answer. |
| `discovery_evidence(S, From)` | S is `system` or `model` evidence. A model file or solver log is never `system` evidence. |
| `model(M, Tool)` | Subject M is a model file. Tool is `smt` or `tla`. |
| `model_run(Log, M, Digest)` | Solver log Log is a run of model M at that digest. Its results count only while M keeps that digest. |
| `derived_from(Target, Existing)` | The target model changes the existing-world model. |
| `encodes(M, C)` | Model M states claim C. |
| `finding(F, Kind, From)` | Kind is `root_cause(X)`, `conflict(Core)`, `surprise(Case)`, `trace(T)`, or `scope(Item)`. From is `system` or `model`. |
| `reason(M, Rule, Text)` | Why the rule of model M survived its mutation. |
| `raised_by(Q, X)` | Finding or hypothesis X raised question Q. |

Attestation types:

- `reproduction`, on system evidence: `result(H, reproduced)`, `result(H, not_reproduced)`,
  or `confirms(F)`.
- `model_result`, on a solver log: `verdict(M, Kind, Result)`,
  `calibration(M, Case, Result)`, or `mutation(M, Rule, Result)`. A calibration Case is
  `example(C)` or `case(Text)`, and its Result is `matches` or `differs`. A mutation Result
  is `killed` or `survived`.
- `decision`, by the human only: `no_go(H, Text)` or `hold(H, Text)`. GO is a core
  `approval`, not a decision.

In a `verdict`, Kind is `sanity`, `bad_case`, `together`, `root_cause(R)`, `normal_case(N)`,
`preserve(C)`, `applies(C)`, or `explore(T)`. Result is `sat`, `unsat`, `unknown`,
`reached`, `violated`, or `holds`.

| Query | True when |
|---|---|
| `discovery_ready` | clean: there is a hypothesis, and each hypothesis has a system result; a claim is current, or a hypothesis did not reproduce; no current claim is refuted or has no falsifier; no question waits or is `to_ask`; no WD1, WD3, WD7, or ED3 to ED7 |
| `discovery_decide` | `discovery_ready`, or `budget_spent`: the last lap of the largest budget is done |
| `no_falsifier(C)` | current claim C has no `check`, and no trusted model that encodes C gave a `preserve(C)` or `applies(C)` result other than `unknown` |
| `model_trusted(M)` | M is sane, calibrated, and does not diverge. Or, one level only: M is sane, does not diverge, and is `derived_from` such a model of the same tool. |

Discovery is ready with no current claim only when a hypothesis did not reproduce: a NO-GO
candidate (WD6).

Lint codes (E: error, W: warning):

| Code | Meaning | What to do |
|---|---|---|
| WD1 | A conflict, surprise, or scope finding raised no question. | Ask one. |
| WD2 | A model states a claim, but is not trusted. | Make it sane and calibrated. |
| WD3 | A rule survived its mutation, with no `reason`. | Find out why. Add a `reason`. |
| WD4 | Only a model shows this finding. | Confirm it, or report a lead. |
| WD5 | A result is `unknown`. | Report a gap, never UNSAT. |
| WD6 | The problem did not reproduce. | Tell the human: a NO-GO candidate. |
| WD7 | A hypothesis has no system result. | Reproduce it, or ask if it is another ticket. |
| WD8 | This result's log has a run of an older model file. | Run `orbit-kb subject` on the model. Run the solver into a new log. |
| ED1 | A reproduction is not on system evidence. | Use a log, query, or test tagged `system`. |
| ED2 | A model result has no `model_run` for its log. | Add it. |
| ED3 | The model disagrees with the system, or the existing-world model misses the bad case. | Fix the model. |
| ED4 | A claim can never apply. | Fix the model, or ask the human. |
| ED5 | A model breaks a current claim. | File a `disproof` with `refuted`. |
| ED6 | Two results for one check disagree. | Find the cause. |
| ED7 | A claim replaces a refuted or contested claim with no human answer. | Ask the human. |
| ED8 | No finding or hypothesis raised this question. | Correct `raised_by`. |
| ED9 | A model is derived from a derived model, or from itself. | Derive targets from existing-world models only. |

If `discovery_ready` is false, run `orbit-kb lint` and `orbit-kb whynot 'discovery_ready'`.
`orbit-kb show open` omits the discovery items.

### Honesty rules for discovery

These rules extend the shared honesty rules.

1. Label each finding as from the current system, or from a model only. A model-only
   finding is a lead until a system `reproduction` attests `confirms(F)`. Report each lead.
   Leads do not block `discovery_ready`.
2. Report each solver result with its encoding, bounds, and assumptions. Never state a
   bounded result as "always" or "never".
3. Only a trusted model gives a verdict about the current system.
4. A model that cannot fail is not evidence: every result is UNSAT, or a property holds only
   because its condition never occurs.
5. Say what each model omits, and what you did not explore.
6. A wrong report is a valid result. Say so, with the evidence.
7. Lint errors block GO. Fix each one first.

### Sizes and speed

- **Small** (most reports): SIGNAL, SURVEY, one claim whose check is the reproduction, and
  GO.
- **Medium:** add SPECTRUM, and one FLYBY or TRAJECTORY.
- **Large:** several models, DISPROVE, and several laps.
- Write the models yourself. A subagent on a fast model can read the logs.
- Set a timeout on every solver run.

---

# Part 2: changes to the build-orbit draft

These changes connect the two orbits. They belong to the build draft, not to this draft.
Contract v2.1 adopted some of them. The build draft's new section "The knowledge base"
(read 2026-10-15, and again 2026-10-16) covers two more.

## Adopted by contract v2.1

- **Adopted:** the `done` and `over` helper fix. The build module uses `served/1`,
  `any_under`, `any_over`, and `any_to_ask`. The core moved `any_to_ask` from build. Lint
  error E12 rejects a `not` literal with a body-only variable (hazard H1).
- **Adopted:** `check/2` and `test_result` in the core, with `passed/1`, `failed_after/2`, and
  `was_red/1`. A runnable reproduction is a check in both orbits.
- **Adopted:** the SURVEY records. `world/1` and `source/2` are core facts.
- **Adopted:** the generic `refuted/1`. The core reads any attestation with a verdict
  `refuted`, so the build draft needs no clause for each attestation type.
- **Adopted:** divergences from discovery count toward BURN. The core `contested_twice/1`
  counts every `divergence` attestation on a claim, from either orbit, and `burn(C)` reads it.
  Since 2026-10-16, an unsat core puts a divergence only on each claim that the human's
  answer superseded. The claim that wins is not contested by the core.

## Done in the build draft

- **One shared KB section.** "The knowledge base" holds the generic commands, the core
  vocabulary, the rules for H1 and H4, and the ENGINE DISAGREEMENT rule. It lives once, in the
  build draft, and the build-orbit session wrote it. This draft does not repeat it. Discovery
  adds only its own commands and queries: the subsection "Discovery module" in Part 1.
- **orbit-kb in place of inline Prolog.** The new section replaced the inline facts and rules
  with commands and query tables.

## Still open for the build draft

1. **Scope line.** Replace "For questions, research, and explanations, answer directly" with:
   "For questions and explanations, answer directly. For a report, run the discovery orbit.
   For a clear request, run the build orbit."
2. **Back to discovery.** Add a first step to "When the human says that it is wrong": if the
   problem itself is wrong, not the build, go back to discovery.
3. **Shared moves.** Mark SURVEY and DISPROVE as shared with discovery. The build orbit skips
   SURVEY when discovery ran.
4. **Place for "Discovery module".** It mirrors "Build module". When the prompts are
   assembled, it can sit next to "Build module" in the shared section.
5. **Sections that Part 1 relies on.** To stay under 3,000 words, Part 1 points at build-draft
   text instead of repeating it: DECOMPOSE (labels, citations, the drift rule, and dormant
   questions), "Ask first, or build on defaults" (at most three questions, options, and a
   marked default), SURVEY (the closed world), DISPROVE (the three verdicts), and "Speed"
   (searches go to a subagent on a fast model). A change to one of these sections changes
   discovery too.
6. **Digest rule.** "Never type a digest" in "Rules for the KB" does not fit `model_run/3`,
   which needs the digest of the model. Part 1 pastes it through the shell
   (`D=$(orbit-kb subject M PATH)`), so the rule holds. Better fixes belong to the CLI: an
   `orbit-kb add` form such as `digest_of(M)`, like the `digest(current)` form of
   `orbit-kb attest`, or an `orbit-kb run` that records the digests of named inputs.
7. **Resume step.** "When you resume, run `orbit-kb show open` first." `show open` lists only
   the core items, and the build items when the build module is in use. For discovery, the
   step must also run `orbit-kb lint`.

---

# Part 3: worked examples (not part of the prompt)

The code units, orders, and logs are invented. The solver and TLC results are real. See
Part 4.

## Example A: FLYBY (rules)

The fixture is `discovery-orbit-examples/orbit-kb-staging/fixtures/discovery-a/`. It holds
the KB after lap 2 and before GO (`kb.pl`), the expectations of the harness (`expected.pl`),
the models (`models/`), the logs (`logs/`), the runs (`runs/`), and the ticket (`ticket.md`).

**Report:** "A customer used two discount codes and paid less than our minimum price."

**SIGNAL.** A defect. Hypothesis: "Two discount codes can price an order below the floor
price." Budget: three laps.

**SURVEY.**

- World: `CheckoutService.ApplyCodes` clamps the price to the floor after the first code. It
  then takes off the second code.
- Reproduction: order 4417. List price $40.00, floor $30.00, codes $5.00 and $10.00. The
  payment log shows $25.00 (`logs/order-4417.log`). The log is a subject tagged
  `discovery_evidence(log4417, system)`, and attestation a1 records `result(h1, reproduced)`
  on it.

**SPECTRUM.**

- c1, introduce: "No order is charged below its floor price." Cites "paid less than our
  minimum price". Tool: SMT, because it is a price rule over combinations of codes. Check t1
  is a test of order 4417, tagged as system evidence. It fails on the current system (run 1),
  so it is the red baseline.
- c2, preserve: "Each code takes off its full amount." Cites "used two discount codes". Tool:
  SMT.
- Dormant questions: the fixture holds none. It lists `not_explored` items instead. Variant
  `cf8_draft_dormant` adds the two questions of the earlier draft: a floor per order or per
  item (on c1), and percentage codes (on c2b). They stay dormant, because no divergence names
  c1 or c2b, and `discovery_ready` still holds.

**FLYBY, lap 1** (`discount-now.smt2`, then `discount-target.smt2`):

| Step | Expected | Z3 and cvc5 |
|---|---|---|
| Sanity | SAT | SAT |
| Calibrate: order 4417 | SAT, 2500 cents | SAT, 2500 cents. Matches the log. |
| Bad case: price below floor | SAT | SAT |
| Root cause: clamp after both codes | UNSAT | UNSAT |
| Normal case kept: one code | UNSAT | UNSAT |
| Normal case kept: both codes above floor | UNSAT | UNSAT |
| c1 and c2 together, order 4417 | UNSAT | UNSAT. Core: `c1_floor`, `c2_full_codes`, `order_4417` |

The unsat core becomes one question:

> Order 4417: list $40, floor $30, codes $5 and $10. Full codes give $25. The floor says at
> least $30. Which one gives?
> (a) The floor wins: charge $30. (default)
> (b) Refuse the second code when it crosses the floor.
> (c) Allow prices below the floor.

The human answers (a). c2b supersedes c2: "Each code takes off its full amount, down to the
floor price." Only now does a divergence go on c2, the claim that gave (a12). c1 won, so no
divergence names it. `contested(C)` gives only c2, which is no longer current.

**FLYBY, lap 2** (`discount-target.smt2`, steps 2 to 5):

| Step | Expected | Z3 | cvc5 |
|---|---|---|---|
| c1 holds for every order in the domain | UNSAT | UNSAT | UNSAT |
| c2b: above the floor, codes take off their full amount | UNSAT | UNSAT | UNSAT |
| The clamp can apply | SAT | SAT: $40, floor $30, codes $5.00 and $5.01, charged $30 | SAT: $0.01, floor $0.01, code $0.01, charged $0.01 |
| Mutation: delete the clamp | SAT (killed) | SAT | SAT |

Z3's witness is a good boundary case: one cent below the floor. cvc5's witness is a one-cent
order. That is valid, but not useful to a human. Hence the rule: pin realistic values before
you show a witness.

Nothing waits for the human. `discovery_ready` and `discovery_decide` hold.

**Renamed atoms.** s(CASP) drops a trailing `_<digits>` from an atom (hazard H4). So
`order_4417` became `order4417` in the KB, and `log_4417` became `log4417`. The solver output
and the `note` text keep the old name. The unsat core above is solver output. Finding f2
holds it as `[c1_floor, c2_full_codes, order4417]`, and the note on f2 keeps `order_4417`.

**The KB with orbit-kb.** These commands rebuild `kb.pl` of the fixture, with every fact,
in the same order, and with the same ids. Run them in a folder with `request.txt` (the report
text), `models/`, `logs/`, and `ticket.md`. The digests come from the CLI, and only the times
differ. The comments show the attestation ids. The fixture has no a11: that id was the
divergence on c1, which decision 2 removed. So the divergence on c2 uses `--id a12`.

```sh
orbit-kb init kb --request-file request.txt --uses discovery
cp -r models logs ticket.md kb/ && cd kb      # the evidence files must sit inside the KB directory

# SIGNAL and SURVEY
orbit-kb add "hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.')" 'budget(laps, 3)'
orbit-kb add 'world(clamp_after_first_code)' "source(clamp_after_first_code, 'CheckoutService.ApplyCodes')"
orbit-kb subject log4417 logs/order-4417.log
orbit-kb add 'discovery_evidence(log4417, system)'
orbit-kb attest reproduction log4417 'result(h1, reproduced)'                            # a1
orbit-kb add "note(a1, 'The payment log shows that order 4417 was charged \$25.00. Its floor is \$30.00.')"

# SPECTRUM
orbit-kb add "claim(c1, introduce, 'No order is charged below its floor price.')" \
  "claim(c2, preserve, 'Each code takes off its full amount.')" \
  "cites(c1, 'paid less than our minimum price')" "cites(c2, 'used two discount codes')" \
  'check(t1, c1)' 'discovery_evidence(t1, system)' \
  "example(c1, 'Order 4417: list \$40.00, floor \$30.00, codes \$5.00 and \$10.00. Charge \$30.00.')"
orbit-kb run t1 -- dotnet test --filter FullyQualifiedName~Pricing.Order4417IsChargedAtLeastTheFloor   # a2: run 1 fails, exit 1
orbit-kb add "scope(in, 'two or more fixed-amount codes at checkout')" "scope(out, 'gift cards')" \
  "risk(k1, 'The change alters the price of each order whose codes cross the floor.')" \
  "assumption(s1, 'Every code takes off a fixed amount.')"

# FLYBY, lap 1: the existing-world model
d=$(orbit-kb subject m_now models/discount-now.smt2)                                     # prints the digest
orbit-kb add 'model(m_now, smt)'
orbit-kb subject run_now logs/discount-now.log
orbit-kb add "model_run(run_now, m_now, '$d')"
orbit-kb attest model_result run_now 'verdict(m_now, sanity, sat)'                      # a3
orbit-kb attest model_result run_now 'calibration(m_now, example(c1), matches)'         # a4
orbit-kb add "note(a4, 'The model gives 2500 cents for order 4417. The payment log shows 2500 cents.')"
for p in 'verdict(m_now, bad_case, sat)' 'verdict(m_now, root_cause(clamp_after_both_codes), unsat)' \
         'verdict(m_now, normal_case(one_code), unsat)' \
         'verdict(m_now, normal_case(both_codes_above_floor), unsat)'; do
  orbit-kb attest model_result run_now "$p"                                            # a5 to a8
done
orbit-kb add 'finding(f1, root_cause(clamp_after_first_code), model)'
orbit-kb attest reproduction log4417 'confirms(f1)'                                     # a9
orbit-kb add "note(a9, 'The log of order 4417 shows the clamp after the first code, and no clamp after the second code.')"

# FLYBY, lap 1: the target model and the conflict (a finding and a question only)
d=$(orbit-kb subject m_target models/discount-target.smt2)
orbit-kb add 'model(m_target, smt)' 'derived_from(m_target, m_now)'
orbit-kb subject run_target logs/discount-target.log
orbit-kb add "model_run(run_target, m_target, '$d')"
orbit-kb attest model_result run_target 'verdict(m_target, together, unsat)'            # a10
orbit-kb add 'finding(f2, conflict([c1_floor, c2_full_codes, order4417]), model)' \
  "note(f2, 'Unsat core for order 4417: c1_floor, c2_full_codes, order_4417.')" \
  "question(q1, c2, 'Order 4417: full codes give \$25.00, and the floor says at least \$30.00. Which one gives?')" \
  'assumed(q1, floor_wins)' 'raised_by(q1, f2)'

# The human answers (a): the floor wins, so c2 gives. Only now does a divergence go on c2.
orbit-kb add 'answer(q1, floor_wins, human)'
orbit-kb attest divergence run_target 'claim(c2)' --id a12                              # a12 (the fixture has no a11)
orbit-kb add "note(a12, 'The human answered q1: the floor wins. So c2 gives, and c2b supersedes it. Finding f2 holds the unsat core.')" \
  'lap_done(1)' \
  "claim(c2b, preserve, 'Each code takes off its full amount, down to the floor price.')" \
  'supersedes(c2b, c2)' "cites(c2b, 'used two discount codes')" \
  'encodes(m_target, c1)' 'encodes(m_target, c2b)'

# FLYBY, lap 2: the target model
orbit-kb attest model_result run_target 'verdict(m_target, sanity, sat)'                # a13
orbit-kb add "note(a13, 'Check 4 is sat, so the target rules admit an order.')"
for p in 'verdict(m_target, bad_case, unsat)' 'verdict(m_target, preserve(c2b), unsat)' \
         'verdict(m_target, applies(c1), sat)'; do
  orbit-kb attest model_result run_target "$p"                                         # a14 to a16
done
orbit-kb add "example(c1, 'List \$40.00, floor \$30.00, codes \$5.00 and \$5.01. Charge \$30.00.')"
orbit-kb attest model_result run_target 'mutation(m_target, clamp, killed)'             # a17
orbit-kb add "example(c2b, 'List \$40.00, floor \$20.00, codes \$5.00 and \$10.00. Charge \$25.00.')" \
  "example(c2b, 'List \$40.00, floor \$30.00, one code \$5.00. Charge \$35.00.')" \
  "not_explored('percentage codes')" "not_explored('codes on single items')" \
  "not_explored('refunds of orders with codes')"

orbit-kb lint                       # no diagnostic
orbit-kb query discovery_ready      # true

# GO: the human approves the ticket
orbit-kb subject tk ticket.md
orbit-kb add 'ticket(tk)'
orbit-kb attest approval tk 'digest(current)' --by human                               # a18
```

`expected.pl` holds 157 expectations: 23 on the base KB, and the rest on 51 variants. A
variant changes the KB by a few facts, for example the missing answer of the human (`cf1`) or
a mutation that survived (`cf5`). The three design decisions of 2026-10-16 have their own
variants: `cf7_budget_spent` and `m6_budget_hides` (out of budget is not ready, but the human
must decide), `cf8_draft_dormant` and the base `contested(C)` (the core divergence goes only
on c2), and `m5_not_reproduced` (ready with no current claim). The harness is
`orbit-kb-staging/harness/run.pl`.

**Discovery report:**

```
Hypothesis:   Two discount codes can price an order below the floor price.
System:       Reproduced. Order 4417 was charged $25.00. Its floor is $30.00.
Findings:     Root cause: the floor is applied after the first code, before the second.
              (model; the log of order 4417 confirms it)
              Conflict: full codes and the floor cannot both hold for order 4417. (model)
              You chose: the floor wins.
Decide:       Nothing is open.
Scope:        in: two or more fixed-amount codes at checkout. out: gift cards.
Risk:         The change alters the price of each order whose codes cross the floor.
              It changes one function, so it is easy to undo.
Claims:       introduce c1: no order is charged below its floor. (order 4417 → $30.00)
              preserve c2b: above the floor, each code takes off its full amount.
              ($40, floor $20, codes $5 and $10 → $25.00)
Not explored: percentage codes; codes on single items; refunds of orders with codes.
Recommend:    GO. The cause is known, and the fix is small.
```

**Into the build orbit.** The witnesses are `example` facts: two for c1 and two for c2b. They
become tests: order 4417 is charged $30.00 (red before the fix); $40 with codes $5.00 and
$5.01 is charged $30.00; one $5 code on $40 is charged $35.00; codes $5 and $10 on $40 with a
$20 floor are charged $25.00. Check t1 already has a red `test_result` (run 1). The build
orbit reuses it as its baseline.

## Example B: TRAJECTORY (sequences)

**Report:** "Some customers were charged twice for one order."

**SIGNAL.** A defect. Hypothesis: "A payment retry after a timeout can charge an order
twice."

**SURVEY.** `RetryPolicy` allows one retry after a timeout. `PaymentGateway.Charge` has no
idempotency key. The log of order 5120 shows two charges 31 seconds apart, with a timeout
between them.

**SPECTRUM.** c1, introduce: "An order is charged at most once." Tool: TLA+, because the
claim is about retries and timeouts: orders of steps.

**TRAJECTORY** (`Checkout.tla`):

| Run | Bounds | Expected | TLC 2.19 |
|---|---|---|---|
| Sanity: "paid" can occur | 1 retry | violation | violated: charge, response |
| Sanity: "failed" can occur | 1 retry | violation | violated: retry, give up |
| Calibrate: c1 in the current world | 1 retry, no dedupe | violation | violated: charge, retry, charge. Matches order 5120. |
| Target: c1 with dedupe | 1 retry | holds | holds; 11 distinct states |
| Target, final bounds | 3 retries | holds | holds; 29 distinct states |
| Mutation: remove dedupe | 1 retry | violation | violated. The same run as the calibration. |
| Explore: charged but shown "failed" | 1 retry, dedupe | (not asked) | violated: charge, retry, give up |

Records: each TLC run writes its own log. Each log is a subject with a `model_run` fact for
its model and the digest of `Checkout.tla`. TLC reports a violation of each never-reached
invariant. Record the two sanity rows as `verdict(m_now, sanity, reached)`. Record the
calibration run as `calibration(m_now, case('order 5120'), matches)` and as
`verdict(m_now, bad_case, violated)`, the target runs as `verdict(m_target, bad_case, holds)`,
and the mutation as `mutation(m_target, dedupe, killed)`. The trace and the surprise are two
`finding` facts from the `model`: a `trace` and a `surprise`. The log of order 5120 is tagged
`discovery_evidence(log5120, system)`. A `reproduction` on it with `confirms` confirms the
trace. The surprise stays a lead (WD4), and it raises question 1 (WD1 if it raised none). The
bounds and the distinct-state counts go in `note` facts. Open question 6 covers the two models
of one file.

Example B is not a fixture, and no harness checks it. It records no `applies(c1)` result and
no check, so `no_falsifier(c1)` would hold. A TLC run that shows that the dedupe guard can
apply (`verdict(m_target, applies(c1), reached)`), or a test that replays order 5120, closes
that gap. Neither run exists yet.

Why-not for c1: contradicts. The dedupe guard forbids a second charge. Absent: gateway
restarts that lose the dedupe record, and two devices that pay at the same time. Both go into
the ticket as risk.

The exploration found something that the report did not ask about. Dedupe does not stop it.

**Discovery report:**

```
Hypothesis:   A payment retry after a timeout can charge an order twice.
System:       Reproduced in the log of order 5120: two charges 31 seconds apart,
              with a timeout between them.
Findings:     Trace (model; matches the log): the gateway charges, the client times out
              and retries, and the gateway charges again.
              Surprise (model only; a lead): a customer can be charged and still see
              "payment failed". The dedupe fix does not stop this.
Decide:       1. Is "charged but shown failed" part of this ticket?
                 (a) Yes. (b) No, open a separate ticket. (default)
Scope:        in: duplicate charges from retries. out: refunds.
Risk:         The change affects every payment request. A wrong build can block payments
              or charge twice.
Claims:       introduce c1: an order is charged at most once.
              (order 5120's sequence → one charge)
Not explored: gateway restarts; two devices that pay at once; more than three retries.
Recommend:    GO after you answer question 1.
```

Question 1 waits, so `discovery_ready` is false, and the budget is not spent. This report is
the human leg of lap 1, in the form of the discovery report. See open question 13.

---

# Part 4: design notes (not part of the prompt)

## One solver, any input language (2026-10-19)

The model language is open: Z3's Python API, which LLMs tend to write by default, or
SMT-LIB 2. A Python model is still one file with a digest, and its printed output is the
log, so `model_run`, WD8, and the other rules do not change. Example A stays in SMT-LIB 2.

Part 1 now uses Z3 only, and names no other solver. The step
that ran the final file in a second solver is gone. Both solvers read the same encoding,
so they agree on an encoding error; the second run caught only solver bugs, and it let an
agent rerun a check until it got the result it wanted. Sanity, calibration, the bad case,
and mutation catch encoding errors. The Example A results below still show both solvers,
as history. ED6 still flags two results that disagree on one check of one model digest.

## Why SMT and TLA+ here, and Lean in the build orbit

- **Exists versus for all.** Discovery's main question is "is there a case where...?" SMT
  and TLC answer it automatically, with a concrete case, and with no proof effort. The build
  orbit's main question is "does this hold for every case?" Lean's dependent types force the
  exact statement that this question needs.
- **Failures are cases.** A SAT witness or a TLC trace is a concrete case that a human can
  judge without reading the model. That keeps the human leg of each lap readable.
- **Two orbits, two formalisms.** A claim stated in SMT or TLA+ in discovery and in Lean in
  the build orbit has two independent statements. A disagreement between them is loud.

## What changed from the 2026-10-05 discovery draft

- The linear steps are now moves in an orbit. The KB picks the next move.
- FLYBY and TRAJECTORY get back their AIDLC v1 meanings: SMT and TLA+. This closes the open
  item about reused names.
- New: calibration. A model must match the current system before its verdicts count.
- New: questions come only from evidence. At most three are asked in one round.
- Every lap ends with the human. The earlier draft said every step.
- New: a risk output (decided 2026-10-13).
- SHAKEDOWN folds into the shared DISPROVE move.
- The stopping rule is now the `discovery_ready` query and a budget. The fixed point follows
  from superseding claims. (Since 2026-10-16, the stop is `discovery_decide`. See "What
  changed after the review".)
- Lean leaves discovery. Universal claims go to BURN.

## What changed with orbit-kb

- The Prolog blocks left Part 1. The module `discovery.pl` is the source of truth for the
  vocabulary. Part 1 has a subsection "Discovery module" in the shape of "Build module".
- Renames: `report(Text)` is the core `request/2`, and `init` writes it. The queries `ready`,
  `unstated`, `lead`, `weak`, and `trusted` are `discovery_ready`, `no_falsifier`,
  `finding_lead`, `weak_rule`, and `model_trusted`.
- Changes: a human answer belongs to a question (`answer/3`, `raised_by/2`), not to a finding,
  so `waits(F)` became `question_waits(Q)` and `unasked_finding(F)`. GO is a core `approval`,
  not `decision go(H)`. A calibration and a mutation have their own `model_result` shapes.
- A reproduction that can run is a `check` with a red `test_result`. Evidence that cannot
  run, such as a log or a query result, is a `reproduction` attestation. Since 2026-10-16, the
  subject of a `reproduction` must be tagged `discovery_evidence(S, system)`. A tagged check
  can also be the subject.

## What changed after the review (2026-10-16)

The fresh-eyes review (`orbit-kb-staging/REVIEW.md`) found 15 defects in the module and the
fixture. The module now closes them, and Part 1 follows the module.

- **Split gate (decision 1, finding 6).** `discovery_ready` means clean: nothing is open.
  `discovery_decide` holds when discovery is ready, or when the budget is spent. Out of
  budget is not ready. The agent reports the open items, and the human decides GO, NO-GO, or
  HOLD. The largest `budget(laps, N)` counts, because the KB is append-only.
- **Unsat cores (decision 2, finding 8).** An unsat core is one `conflict` finding and one
  question. Only after the human answers does a core divergence go on each claim that the
  answer superseded. The claim that wins is not contested, so its dormant questions stay
  dormant. The fixture lost its divergence on c1 (a11).
- **Ready with no claim (decision 3, finding 5).** Discovery is ready with no current claim
  only on the `not_reproduced` path, a NO-GO candidate (WD6). `discovery_ready` also needs
  at least one hypothesis, and a result from the current system for each one (WD7, finding
  13).
- **Evidence tags (finding 4).** `discovery_evidence(S, system|model)` tags evidence. A model
  file or a solver log is never system evidence. A `reproduction` on anything else is ED1.
- **Model digests (findings 3 and 14).** `model_run(Log, Model, Digest)` binds each solver log
  to its model and to the digest of the model file. A result counts only while the model keeps
  that digest, and only when its log has no run of an older digest (WD8). A result whose log
  has no `model_run` for its model is ED2.
- **Divergent models (finding 1).** A calibration that `differs`, a `divergence` with
  `model(M)` on any subject except a log of an older digest of M, or an existing-world model
  that misses the bad case makes the model diverge (ED3). A model that diverges is not
  trusted. A target is derived from an existing-world model; a `derived_from` cycle or chain
  is ED9, and its models get the existing-world check.
- **All results count (finding 2).** `unknown` is WD5. An `applies(C)` check with no case is
  vacuous (ED4). A model that breaks a current claim needs a `disproof` with the verdict
  `refuted` (ED5); `inconclusive` and `abstained` do not file it. Two results
  that disagree on one check are ED6. A failed sanity result cancels sanity.
- **Trust (finding 14).** A target model inherits trust one level only, from a calibrated
  model of the same tool. TLC sanity results `reached` and `violated` both pass.
- **Scope (finding 7).** A claim that replaces a refuted or contested claim needs a human
  answer to a question about one of the two claims (ED7). Superseding an undisputed claim is
  allowed, because the human approves the whole ticket at GO (ticket decision D4).
- **Smaller fixes.** `reason/3` names the model (finding 12). `raised_by` can name a
  hypothesis (ED8). NO-GO is `no_go(H, Text)`, with the reason in the text.
- **Part 1 (requirement R8).** Part 1 went from 3,745 to 2,998 words. TRAJECTORY now lists
  only how it differs from FLYBY. "Divergences in discovery" and "Quiet failures" became
  steps of the moves, the lint table, and the honesty rules. "Input and output" moved into
  "Purpose" and "GO / NO-GO". "The ticket" moved into "The discovery report". Part 1 points at
  build-draft sections instead of repeating them (Part 2, item 5).
- **Small reports.** The size "Small" was SIGNAL, SURVEY, and GO. The gate needs a current
  claim on the reproduced path, so "Small" now includes one claim whose check is the
  reproduction.

## s(CASP) hazards H1 to H4

The contract names four hazards, all reproduced on 2026-10-15. H1: a variable that occurs only
under `not` means "some value", so `done :- not under(_)` can be true when `under(c1)` is
true. Lint error E12 rejects such a rule, and the modules use helper rules such as `any_under`.
H2: the default `--forall` algorithm gives wrong answers (upstream issue 10 of
SWI-Prolog/sCASP). H3: arithmetic under negation, as in `passed/1`, fails the same way. For
both, the CLI runs s(CASP) with `--forall=prev`, answers from the SWI engine, and compares the
two engines. A mismatch prints ENGINE DISAGREEMENT and exits 2. Nobody proved `prev` sound, so
the cross-check is the safeguard. H4: s(CASP) drops a trailing `_<digits>` from atoms, so
`order_4417` and `order_5120` merge. Lint error E13 finds such atoms, and the commands `add`,
`declare`, `attest`, and `init --id` reject them. `orbit-kb doctor` tests all four hazards.
`orbit-kb help` (read 2026-10-16) adds that s(CASP) now runs on a grounding of the program for
each goal. H2 and H3 cannot occur in a grounded program, and `--forall=prev` applies only when
the CLI runs the program as written.

## Sources

- AIDLC v1, FLYBY and TRAJECTORY / ANGLING: wording for SAT and UNSAT, deletion probes,
  non-discriminating checks, anti-vacuity, and completeness rules for TLA+ models.
- Orbital shifting: close-world, decompose-proposition, model-obligations, and
  disprove-proposition.
- TLA+ trace validation: Cirstea, Kuppe, Loillier, and Merz, SEFM 2024, arXiv 2404.16075.
  It supports "if the current system can replay a trace".
- The orbit-kb contract, v2.1: `~/.dotfiles/thoughts/orbit-kb-contract.md`.
- The s(CASP) engine tests: `discovery-orbit-examples/kb-a/RESULTS.md`.
- The review of the module and the fixture: `orbit-kb-staging/REVIEW.md` (findings 1 to 15),
  and the ticket for the fixes: `TICKET.md` (requirement R7 holds the three design decisions).
- Other citations: `~/.dotfiles/thoughts/aidlc-v2-deep-explanation.md`.

## Verified (2026-10-15)

Tools: Z3 5.1.0, cvc5 1.3.4, and TLC 2.19 (08 August 2024, rev 5a47802). The commands are in
`discovery-orbit-examples/README.md`.

- `discount-now.smt2`: Z3 and cvc5 returned the six expected verdicts. Calibration gave 2500
  cents in both.
- `discount-target.smt2`: Z3 and cvc5 returned the five expected verdicts. Both gave the
  unsat core `c1_floor`, `c2_full_codes`, `order_4417`.
- `Checkout.tla`: TLC returned the six expected results in the table above.
- cvc5 rejects `push` without `--incremental`. The FLYBY rule now says so.
- The discovery module on the Example A fixture (s(CASP) 1.1.4 on SWI-Prolog 9.2.9). The
  harness (`orbit-kb-staging/harness/run.pl`) ran 59 expectations on the base KB and its
  variants. The SWI engine passed 59/59, and s(CASP) with `--forall=prev` passed 59/59
  (`sasp` also passed 59/59). With the default `--forall=all`, s(CASP) passed 46/59, and all
  13 failures printed ENGINE DISAGREEMENT. The core has changed since those runs (contract
  change D5). A new run gives 58/59 on both engines. The expectation `to_ask(Q) = [q1]` of
  variant `cf1_no_answer` is stale, because q1 is on the superseded claim c2 (open question 5).
  `expected.pl` was regenerated after the review. `cf1_no_answer` now expects no `to_ask`
  answer, and the file holds 157 expectations.
- The Example A command sequence ran against the installed CLI. A scratch library held the
  staging `discovery.pl`, because the installed `modules/discovery.pl` is a placeholder. Every
  command succeeded, except the red `run` (exit 1, as intended). `orbit-kb lint` printed no
  diagnostic, and `discovery_ready` was true. The new `kb.pl` equals the fixture, apart from
  ids, times, and the five `note` facts that the block abbreviates. With the times of the
  fixture, it gives the same 58/59 result as the fixture.
- `kb-a/RESULTS.md`: `prev` and `sasp` matched plain SWI-Prolog in every run. That covers the 7
  baseline queries, the 10 counterfactual checks, the 240 sweep rows of `passed/1`, and the
  non-ground `passed(K)` check. The default `all` was wrong on 2 of 7 baseline queries
  (`no_falsifier`, `finding_lead`), on 1 of 10 counterfactuals (a false `discovery_ready`),
  and on 76 of 240 sweep rows.
- A variable that occurs only under `not` is existential in s(CASP). The contract reproduced
  it for every `--forall` mode (hazard H1).

## Verified (2026-10-16)

- `harness/check_draft.py` passes all six checks. Part 1 has 2,998 words.
- The Example A command block ran against the installed CLI, with a scratch copy of the
  installed library that holds the staged `discovery.pl`. The run used `false` in place of the
  `dotnet test` command, so run 1 failed with exit 1, as in the fixture. Every other command
  succeeded. `orbit-kb lint` reported 0 errors and 0 warnings, and `discovery_ready` was true.
  Before GO, the new `kb.pl` equals the fixture term for term, in the same order, with the
  same ids. Only the times differ. After GO, `discovery_decide` was true, `stale(A)` and
  `to_ask(Q)` had no answer, `contested(C)` gave only c2, and `model_trusted(M)` gave m_now
  and m_target.
- CLI behavior that Part 1 states, on a copy of that KB:
  - `orbit-kb subject` prints only the digest.
  - `orbit-kb attest reproduction t1 'result(h1, reproduced)'` works on the tagged check t1.
  - `decision` rejects an agent writer (E8) and `no_go(h1)` without a text (E3).
  - A `reproduction` on the solver log `run_now` is accepted by `attest`, and lint reports
    ED1.
  - After an edit to `discount-now.smt2` and `orbit-kb subject m_now ...`, lint reports WD8
    on a3 to a8 and WD2 on m_target, and `model_trusted(M)` has no answer.
  - `orbit-kb show open` lists only "contested c2". It lists no discovery item.
- A gap that this check found, now fixed (ticket finding F2): after the same edit, a second
  `model_run(run_now, m_now, NewDigest)` for the old log made WD8 disappear, and
  `model_trusted(M)` again gave m_now and m_target, from the results of the old file. The
  module now ignores such a log (open question 10).

## Not verified

- The installed library. Its `modules/discovery.pl` is still a placeholder (checked
  2026-10-16). So `--uses discovery` does not declare the discovery facts until the staging
  module moves there.
- The command-block run above used the staged module before the R3, F2, and F3 changes. The
  final module passes `harness/run.pl` on `expected.pl` and `harness/cli_conformance.sh` on
  the fixture (see `thoughts/discovery-orbit/TICKET.md`), but the command block itself was
  not re-run.
- Example B is not encoded as a KB. Its record names (`case('order 5120')`, `model_run`, and
  the verdicts) follow the module, but no tool checked them.
- Whether Part 1 reads well when it is assembled with the build draft, now that it points at
  build-draft sections (Part 2, item 5).
- Whether an agent follows Part 1 as written. No agent run has used it.

## Open questions

1. Is three laps the right default budget?
2. When two stakeholders disagree, who is the decision owner? Should SIGNAL record it? The
   module has no record for it.
3. Should discovery models be committed with the change as documentation? Today they stay in
   the gitignored `thoughts/` folder.
4. When TLC is too slow for large value domains, should TRAJECTORY allow Apalache, which
   checks TLA+ with an SMT solver?
5. **Dormant questions and `to_ask`.** (a) Closed by decision 2 (2026-10-16): the core
   divergence goes only on each claim that the answer superseded, so the claim that wins keeps
   its dormant questions dormant (variant `cf8_draft_dormant`). The build draft lists the same
   rule as its open item 6. (b) Still open: contract change D5 drops the questions of a
   superseded claim from `to_ask/1`, and `cf1_no_answer` now expects that. `question_waits/1`
   does not test whether the claim is current, so it still lists an unanswered q1, and
   `discovery_ready` fails. That is the guard today. Should c2b inherit the question instead?
6. **Model ids.** `model/2` uses the id of the subject of the model file. Two subject ids can
   name the same file (variant `b2_tla_sanity` does this), so Example B can use m_now and
   m_target for `Checkout.tla` with different configurations (`now.cfg`, `target.cfg`,
   `target-final.cfg`). But `model_run/3` binds results to the digest of the file. An edit to
   `Checkout.tla` for the target also makes the results of m_now stale (WD8). Does `model/2`
   need its own id, with the file and the configuration as separate arguments?
7. **Discovery report.** `orbit-kb report` prints only the build-orbit sections. A
   `report_section/3` hook for modules is requested, not built. Until it exists, the agent
   writes the discovery report from queries.
8. **Time budgets.** `budget` counts laps only. Part 1 puts a time limit in a `note`, which no
   rule reads. Should the module have a time budget?
9. **Typed digests.** `model_run/3` needs the digest that `orbit-kb subject` printed. Part 1
   now pastes it through the shell (`D=$(orbit-kb subject M PATH)`), so the agent does not
   type it, and a wrong digest fails loud (WD8). A cleaner fix is in the CLI: `orbit-kb run`
   could record the digests of named inputs. Requested from the orbit-kb owner (Part 2,
   item 6).
10. **Reused logs.** Closed (2026-10-16, ticket finding F2): a log counts only when it has no
    `model_run` at an older digest (`discovery_old_run/2`), so a second `model_run` for an old
    log no longer brings its results back, and WD8 flags them. Variants `m3_log_reused` and
    `m3_rerun_new_log`.
11. **Scope of ED7.** Partly closed (2026-10-16, ticket finding F3 and decision D4): ED7 now
    checks a claim that replaces a disputed claim, which is refuted or contested
    (`discovery_disputed/1`). Superseding an undisputed claim still needs no human answer,
    because the human approves the whole ticket at GO. Still open: should ED7 check every
    `supersedes` fact? Variants `m7_launder_contested` and `m7_ratified_contested`.
12. **Unread records.** No module rule reads a `divergence` with `hypothesis(H)`, or a time
    limit in a `note`. Only the human reads them. Should WD6 or the gate read the divergence?
    `orbit-kb show open` also omits every discovery item (Part 2, item 7).
13. **Reports during the orbit.** Part 1 gives the discovery report when `discovery_decide`
    holds. Example B shows the same form at the end of lap 1, while a question waits. Should
    Part 1 allow that form for each human leg?
14. **Budget raises.** Decision 1 says that at the end of the budget the human decides GO,
    NO-GO, or HOLD. The module also lets a larger `budget(laps, N)` reopen the orbit (variant
    `m6_budget_raised`). Part 1 says that only the human raises the budget, but no rule checks
    who added it.

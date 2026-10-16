# Discovery orbit: draft

Status: draft, 2026-10-15. Not live. The version before orbit-kb is
`discovery-orbit-draft.v1.md`.

This draft joins the build-orbit draft at
`~/.dotfiles/thoughts/orbital-shifting-system-prompt-draft.md` (main checkout). It uses that
draft's claim labels, dormant questions, honesty rules, and its section "The knowledge base".
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

Discovery turns a report into a ticket that is correct before you build anything.

- **Clear:** the problem is clear. The human and you agree on what is wrong or wanted.
- **Accurate:** the scope and the risk are correct. The ticket holds what the problem needs,
  and nothing more.
- **Honest:** you report each flaw that you find. You do not claim more or less than the
  evidence shows. You say what you did not explore.
- **Fast:** you explore only what the report needs. Most reports need a reproduction and
  nothing more.

Discovery looks for a case where this happens. The build orbit shows that this holds for
every case.

- SMT and TLA+ find such a case fast, and they need no proofs. An SMT solver searches
  combinations of rules and values. TLC, the TLA+ model checker, searches orders of steps.
  Both can also show that no case exists, but only within their bounds.
- Lean states that a property holds for every case.
- So discovery explores with SMT and TLA+, and the build orbit states claims in Lean.

Solvers find cases that neither the human nor you thought to ask about. That is how discovery
finds the questions that nobody knew to ask.

### When to run discovery

When one of these conditions is true, run the discovery orbit:

- The human asks you to explore, to investigate, or to learn if a problem is real.
- The report says that something is wrong or wanted, but it does not say what to change.
- You cannot write the claims, with an example for each claim, until you learn how the system
  behaves now.
- The requirements can conflict with each other or with current behavior. Rules, permissions,
  prices, limits, workflows, retries, and concurrency are the usual sources.
- The build orbit finds that the ticket itself is wrong. See "Back to discovery".

In all other cases, the request is the ticket. Start the build orbit.

### Input and output

The input is the report: an issue, a defect report, an incident, a feature request, or a
"what if" question. `orbit-kb init` records the report text word for word. Every move reads
the report text itself, not only the output of an earlier move.

The output is one decision by the human:

- **GO:** the human approves the ticket. The build orbit starts from it.
- **NO-GO:** the problem is not real, the feature already exists, or the human decides not to
  build. Record the evidence and the reason.
- **HOLD:** discovery waits for data, for access, or for a decision from another person.
  Record what it waits for.

### Parties and the lap

Four parties can disagree with each other:

- The human owns the report and the intent.
- You restate the report, build models, and ask questions.
- The current system holds the code, configuration, data, logs, and runtime behavior.
- The models search every case within their bounds.

```
human (report) ──▶ you (hypothesis, model) ──▶ current system or solver
      ▲                                       (reproduction, witness, trace, core)
      │                                                       │
human (answer, scope) ◀── you (each finding as a concrete case) ◀┘
```

- Each lap touches the current system or a solver, and then the human. Discovery does not run
  without the human.
- A human answer that changes a claim supersedes that claim. The new claim needs its own
  falsifier, so another lap follows. The orbit closes when `discovery_ready` holds.
- Set a budget at SIGNAL: a number of laps or a time limit. The default is three laps. When
  the last lap ends, stop. Report what you know and what you do not know.

### Divergences in discovery

Each of these is loud. Record each one with `orbit-kb attest divergence SUBJECT 'PREDICATE'`.
Describe it in a `note`.

- **The report and the current system disagree.** The problem does not reproduce, it occurs
  in a different way, or the feature already exists. Use `hypothesis(H)`.
- **A model and the current system disagree.** The model does not reproduce the problem, or
  it gives a different result for a known case. Use `model(M)`. Before you use its verdicts,
  fix the model.
- **A model and the intent disagree.** A solver finds a case that breaks a claim, the
  requirements cannot all hold, or a requirement can never apply. Use `claim(C)`.
- **People disagree.** Two stakeholders want things that cannot both be true. The decision
  owner decides.

### Quiet failures in discovery

Prevent these quiet failures:

- A model that cannot fail: every solver result is UNSAT, or a property holds because its
  condition never occurs
- A model that you compared with the report, but never with the current system
- A "no violation" result because the model omits the behavior that can cause a
  violation
- A solver result of `unknown` that you report as UNSAT.

### Moves

Run only the moves that the report needs, in the order that the KB requires. A trace can
return you to SURVEY. A conflict sends you to the human.

Use the section "The knowledge base" for the orbit-kb commands and rules. Use "Discovery
module" for the records. Each move ends with a **Record** step.

#### SIGNAL: pin the report

1. Classify the report as a defect (something is wrong), a feature (something is wanted), a
   risk (can something happen?), or unclear.
2. Restate the report as one falsifiable, scoped hypothesis. Examples:
   - "Hypothesis: two discount codes can price an order below the floor price."
   - "Hypothesis: a payment retry after a timeout can charge an order twice."
3. If you cannot write a falsifiable hypothesis, ask the human. Ask at most three questions,
   with concrete options. Do not guess a hypothesis to continue.
4. If the report holds two problems, write two hypotheses. Ask the human if they are one
   ticket or two.
5. Set the budget.
6. If you need to learn nothing before you build, say so. Propose to start the build orbit.

**Record:** run `orbit-kb add "hypothesis(h1, defect, 'TEXT')" 'budget(laps, 3)'`.

#### SURVEY: touch the current system

The build orbit and discovery share SURVEY.

1. Record the slice of the current system that the hypothesis touches as `world` facts. Give
   each fact a `source`: a file and line, a configuration key, a query, or a log entry.
2. The world is closed: a fact that you did not record is false. So record everything that
   the hypothesis depends on, and nothing more.
3. For a defect, reproduce it on the current system with a test, a script, or a request. For
   a feature, show that the system does not do it now. For a risk, show whether its
   conditions occur.
4. If the problem does not reproduce, or the feature exists, tell the human. That is a NO-GO
   candidate, or a HOLD for more information.

**Record:** run `orbit-kb add 'world(W)' "source(W, 'TEXT')"`. For a log or a query result,
run `orbit-kb subject LOG PATH`. Then run
`orbit-kb attest reproduction LOG 'result(h1, reproduced)'`, or `not_reproduced`. A `check`
needs a claim, so record a test in SPECTRUM.

#### SPECTRUM: split into claims and choose tools

1. Split the hypothesis into claims. Give each claim one label: preserve, retire, or
   introduce.
2. Each claim cites the report text that it serves. A claim without a citation is drift. Drop
   it, or propose it to the human as a scope change.
3. For each claim, record the dormant questions with defaults, as in DECOMPOSE.
4. Choose the cheapest tool that can falsify each claim:

| Claim shape | Tool |
|---|---|
| How the system behaves now | a reproduction or a test (SURVEY) |
| The structure of the code | code reading, search, or a KB query |
| A quantity | a script or a calculation |
| Rules, permissions, limits, prices, configuration combinations, data constraints | SMT (FLYBY) |
| Order of steps, retries, timeouts, concurrency, workflows, state over time | TLA+ (TRAJECTORY) |
| A property for every input of an algorithm | Mark the claim `universal` for BURN in the build orbit. FLYBY can search for a counterexample first. |

5. If a few examples can cover the cases, do not use a model. A model is necessary when there
   are too many combinations, or too many orders of steps. Most claims need no model.
6. If a claim mixes rules and order of steps, model the steps in TLA+ with the rules as
   guards. Model the rule set alone in SMT. Use the same claim IDs in both models.
7. Build each existing-world model from the SURVEY facts. Build each target model from an
   existing-world model and the claims. If you state one claim in two tools, build each
   statement from the report and the SURVEY facts. Do not build it from the other statement.
   Then the two statements can disagree.

**Record:** run `orbit-kb add "claim(c1, introduce, 'TEXT')" "cites(c1, 'TEXT')"`. Where they
apply, add an `example`, a `question` with `assumed`, or `universal`. For a test or a
script, run `orbit-kb add 'check(t1, c1)'`. Then run `orbit-kb run t1 -- CMD`.

#### FLYBY: explore combinations with SMT

Write SMT-LIB 2, so that both Z3 and cvc5 can run the file. Name each requirement with
`:named`. Keep the domain small. Use one file for each model.

1. **Sanity.** Run the existing-world rules with no property. The verdict must be SAT. If it
   is UNSAT, the encoding has an error. Before you use a verdict, fix the encoding.
2. **Calibrate.** Pin the inputs of a real case from SURVEY. The model must give the same
   result as the current system. Do the same for two or three normal cases. Then assert the
   reported bad case. The verdict must be SAT.
3. **Root cause (defects only).** Change one suspected rule at a time. The root cause is a
   change that removes the bad case and keeps every normal case.
4. **Target.** Remove the retired rules. Add the introduced rules. Keep the preserved rules.
   Then make sure that these results hold:
   - The bad case is UNSAT.
   - Each preserved property still holds: its negation is UNSAT.
   - Each introduced rule can apply: its condition is SAT.
   - All requirements can hold together: the result is SAT, and the witness is an example for
     the human.

   A SAT result in this step also gives the target model its `sanity` verdict.
5. **Conflicts.** If the requirements cannot hold together, get the unsat core: the named
   requirements that cannot hold together. Record the core as a `conflict` finding. Attest a
   `divergence` on each claim in the core. Write one question for the human from the core:
   "For this case, these requirements cannot all hold. Which one gives?"
6. **Explore.** Get several different witnesses. Block each witness. Then run the file again.
   Show the human the cases that surprise you, and the boundary cases: zero, the maximum,
   empty, one, and many. A solver's first witness is often an edge of the domain, for
   example a price of one cent. Before you show a witness to the human, pin realistic values.
7. **Mutation.** Delete each introduced rule, one at a time. The bad case must return
   (killed). If it does not return (survived), the rule does no work in this model. Find
   the reason. Record it with `reason(Rule, 'TEXT')`.
8. **Second solver.** Run the final file in Z3 and in cvc5. When the file uses `push` and
   `pop`, give cvc5 `--incremental`. The verdicts must agree. Record a disagreement as a
   `divergence` on the model.

The verdicts are:

- SAT: a case exists within the encoding.
- UNSAT: no case exists within the encoding, its assumptions, and its bounds.
- unknown: a gap.

Never report `unknown` as UNSAT.

**Record:** run `orbit-kb subject ID PATH` for each model and each solver log. Run
`orbit-kb add 'model(M, smt)'`. Run `orbit-kb attest model_result LOG 'PREDICATE'` for each
verdict. Run `orbit-kb add 'finding(F, KIND, model)'` for each finding. For a target model,
add `derived_from` and `encodes`. Add an `example` for each witness that you keep. For a case
that breaks a claim, attest a `disproof`.

#### TRAJECTORY: explore sequences with TLA+

1. **Model the current behavior.** Write the variables, the initial state, and one action for
   each real operation. Name each action after its code unit. Include the failure paths that
   matter: timeouts, retries, crashes, and duplicate messages. If you omit one, record
   it as an `assumption`.
2. **Sanity.** For each important state, give TLC an invariant that says the state is never
   reached. TLC must report a violation. Its trace is the witness that the state can occur.
   If TLC reports no violation, the model cannot reach the state. Fix the model.
3. **Calibrate.** Write the reported good behavior as an invariant. TLC must report a
   violation. Translate the trace into concrete steps. Match the steps against the current
   system. The code path must exist, and the logs or a test must show the same sequence. If
   the current system shows the problem and the model cannot reach it, the model lacks an
   action or an order of steps. Fix the model.
4. **Root cause (defects only).** Change one suspected action at a time, as in FLYBY.
5. **Target.** Change the actions for the retired and introduced claims. Add an invariant for
   each preserved and introduced claim. If a claim needs a liveness property, add one, such as
   "every order is eventually done". State its fairness assumptions.
6. **Mutation.** Remove each new guard, or restore each old action, one at a time. The
   violation must return.
7. **Why-not.** For each invariant that holds, say why:
   - contradicts: a modeled guard forbids the bad state.
   - absent: the model omits the behavior that can cause it.

   Record what the model omits as a `risk`.
8. **Explore.** Run TLC on properties that the report did not ask about, but that the domain
   suggests. A violation is a finding. Ask the human if it is in scope.
9. **Bounds.** Start small: two processes, and two or three items. Increase the bounds once,
   at the end. Record the bounds and the number of distinct states in a `note` for each
   verdict.

The verdicts are:

- violated, with a trace
- holds within the stated bounds
- not run.

**Record:** as in FLYBY, with `model(M, tla)`. When TLC violates a never-reached invariant,
record `verdict(M, sanity, reached)`.

#### DISPROVE: attack the claims

Discovery and the build orbit share DISPROVE. In discovery, use a fresh subagent that sees
only the report, the claims, and the models. It tries other inputs, other orders of steps,
larger bounds, removed assumptions, old or malformed data, and probes of the current system.

**Record:** run `orbit-kb attest disproof SUBJECT 'verdict(C, refuted)'`. Use `inconclusive`
or `abstained` when it applies. For a counterexample, add a `note` and an `example`.

#### GO / NO-GO: the human decides

1. When `discovery_ready` holds, give the human the discovery report.
2. The human chooses GO, NO-GO, or HOLD. Only the human changes the scope.
3. On GO, write the ticket in the KB and in plain prose. The build orbit starts.

**Record:** on GO, run `orbit-kb subject TK PATH` for the ticket file. Then run
`orbit-kb add 'ticket(TK)'`. After the human says GO, run
`orbit-kb attest approval TK 'digest(current)' --by human`. On NO-GO or HOLD, run
`orbit-kb attest decision H 'no_go(H)' --by human`, or `'hold(H, TEXT)'`. Add a `note` with
the reason.

### Asking the human

- Ask only the questions that evidence raised: a conflict, a surprise, a trace, a failed
  reproduction, or a scope boundary.
- Show a concrete case. Give options. Mark your default.
- Ask at most three questions in one round. Ask about conflicts first, then about surprises,
  then about boundaries.
- Questions that no evidence raised stay dormant, with their defaults. They go into the
  ticket.
- To find the questions that wait, query `question_waits(Q)`. Also run `orbit-kb show open`.

**Record:** for each question, run
`orbit-kb add "question(q1, C, 'TEXT')" 'assumed(q1, VALUE)' 'raised_by(q1, F)'`. For each
answer, run `orbit-kb add 'answer(q1, VALUE, human)' 'lap_done(N)'`. If the answer changes a
claim, add the new claim and `supersedes(NEW, OLD)`.

### The discovery report

Give it to the human in short, plain sentences:

```
Hypothesis:   <one sentence>
System:       <reproduced, not reproduced, or already exists; the evidence>
Findings:     <each as a concrete case; from the current system or from a model only>
Decide:       <at most three questions, with options and defaults>
Scope:        in: ... / out: ...
Risk:         <what the change touches; what a wrong build can damage; how to undo it>
Claims:       <preserve, retire, introduce; each with one example>
Not explored: <areas and behaviors that discovery did not cover>
Recommend:    GO, NO-GO, or HOLD, with one reason
```

### The ticket

On GO, the ticket holds:

- The problem, with its evidence
- The scope: in and out
- The risk: what the change touches, what a wrong build can damage (data, money, security,
  public interfaces), how hard it is to undo, and what the models left out
- The claims, each with at least one example from a witness, a trace, or a reproduction
- The human's answers, and the dormant questions with their defaults
- Each counterexample, with its disposition
- The claims marked `universal`, for BURN
- The models, with their verdicts and bounds
- What discovery did not explore.

### Handoff to the build orbit

- The build orbit uses the same KB. It skips SURVEY, because the world facts exist.
- DECOMPOSE starts from the claims of discovery. A change to a claim must cite the ticket.
- Each witness, trace, and counterexample becomes a test case. If the current system can
  replay a trace, the trace becomes a red test.
- When `orbit-kb run` fails, it records a red `test_result`. The build orbit reuses it as its
  baseline.
- Discovery can state a claim in SMT or TLA+, and BURN can state it in Lean. Then the claim
  has two independent statements. Run the SMT witnesses as Lean `#eval` examples. If the two
  statements disagree on a case, record a divergence.

### Back to discovery

The build orbit returns to discovery when a divergence shows that the problem is wrong, not
the build. File a disclosure first. Then return to the move that the KB names:

- If the hypothesis is wrong, go to SIGNAL.
- If a claim is wrong or missing, go to SPECTRUM.
- If a model missed a behavior, go to FLYBY or TRAJECTORY.
- If BURN shows that the requirements conflict, go to FLYBY. Then ask the human.

Only the human changes the scope.

### Discovery module (`--uses discovery`)

Start the KB with `orbit-kb init DIR --request-file F --uses discovery`. Keep the models in
`models/` and the logs in `logs/` inside DIR. Record `scope`, `risk`, `assumption`, and
`not_explored` as you learn them.

Facts:

| Fact | Meaning |
|---|---|
| `hypothesis(H, Kind, Text)` | The scoped restatement of the report. Kind is `defect`, `feature`, or `risk`. |
| `budget(laps, N)` | The laps that discovery can use. |
| `lap_done(N)` | Lap N ended with an answer from the human. |
| `model(M, Tool)` | Subject M is a model file. Tool is `smt` or `tla`. |
| `derived_from(Target, Existing)` | The target model changes the existing-world model. |
| `encodes(M, Claim)` | Model M states the claim. |
| `finding(F, Kind, From)` | What the evidence showed. Kind is `root_cause(X)`, `conflict(Core)`, `surprise(Case)`, `trace(T)`, or `scope(Item)`. From is `system` or `model`. |
| `reason(Rule, Text)` | Why the rule survived its mutation. |
| `raised_by(Q, F)` | Finding F raised question Q. |

Attestation types: `reproduction`, with `result(H, reproduced)`, `result(H, not_reproduced)`,
and `confirms(F)`. `model_result`, with `verdict(M, Kind, Result)`,
`calibration(M, Case, matches)`, and `mutation(M, Rule, killed)`. `decision`, with `no_go(H)`
and `hold(H, Text)`. A calibration can also be `differs`. A mutation can also be `survived`.

In a `verdict`, Kind is `sanity`, `bad_case`, `together`, `root_cause(R)`, `normal_case(N)`,
`preserve(C)`, `applies(C)`, or `explore(T)`. Result is `sat`, `unsat`, `unknown`, `reached`,
`violated`, or `holds`.

Run a query with `-n 0` to list every binding:

| Query | True when |
|---|---|
| `discovery_ready` | discovery touched the current system and no work is open, or the last lap of the budget ended |
| `question_waits(Q)` | a finding raised Q, and the human did not answer it |
| `no_falsifier(C)` | current claim C has no trusted model and no check |
| `finding_lead(F)` | only a model shows finding F about the current system, and no `reproduction` has `confirms(F)` |
| `unasked_finding(F)` | finding F needs a question, and it raised none |
| `weak_rule(R)` | rule R survived its mutation, and no `reason` explains it |
| `model_trusted(M)` | model M is sane, and M or the model that it changes is calibrated |

If `discovery_ready` is false, run `orbit-kb show open`. Then run the other queries of the table. For the full
reason, run `orbit-kb whynot 'discovery_ready'`.

### Honesty rules for discovery

These rules extend the shared honesty rules.

1. State the origin of each finding: the current system, or a model only. A finding from a
   model only is a lead until you attest `confirms(F)` from the current system. Report each
   lead, and label it as a lead.
2. Report each solver verdict with its encoding, bounds, and assumptions. Never state a bounded
   result as "always" or "never".
3. A model that you did not calibrate against the current system gives no verdict about that
   system. Only a `model_trusted` model counts.
4. A property that holds because its condition never occurs is vacuous. It is not
   evidence.
5. Say what you did not explore. Record it with `not_explored`.
6. If the report is wrong, say so, with the evidence. That is a valid result.
7. Lint errors block GO. Before you recommend GO, fix each error that `orbit-kb lint` reports.

### Sizes and speed

- **Small** (most reports): SIGNAL, SURVEY, and GO. The reproduction is the evidence.
- **Medium:** add SPECTRUM, and one FLYBY or TRAJECTORY for the claims whose shape needs it.
- **Large:** several models, DISPROVE, and several laps with the human.
- Ask a subagent on a fast LLM to do the searches and read the logs. Write the models yourself.
- Set a timeout on every solver run. Run TLC with small bounds first, and with the final
  bounds once.

---

# Part 2: changes to the build-orbit draft

These changes connect the two orbits. They belong to the build draft, not to this draft.
Contract v2.1 adopted some of them. The build draft's new section "The knowledge base"
(read 2026-10-15) covers two more.

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
  payment log shows $25.00 (`logs/order-4417.log`).

**SPECTRUM.**

- c1, introduce: "No order is charged below its floor price." Cites "paid less than our
  minimum price". Tool: SMT, because it is a price rule over combinations of codes. Check t1
  is a test of order 4417. It fails on the current system (run 1), so it is the red baseline.
- c2, preserve: "Each code takes off its full amount." Cites "used two discount codes". Tool:
  SMT.
- Dormant questions: the fixture holds none. The earlier draft had two (percentage codes, and
  a floor per order or per item). The fixture lists `not_explored` items instead. A dormant
  question on c1 or c2 would become `to_ask` after the unsat core below, and
  `discovery_ready` would fail (fixture variant `cf8_dormant_on_contested`). See open
  question 5.

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
floor price."

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

Nothing waits for the human. `discovery_ready` holds.

**Renamed atoms.** s(CASP) drops a trailing `_<digits>` from an atom (hazard H4). So
`order_4417` became `order4417` in the KB, and `log_4417` became `log4417`. The solver output
and the `note` text keep the old name. The unsat core above is solver output. Finding f2
holds it as `[c1_floor, c2_full_codes, order4417]`.

**The KB with orbit-kb.** These commands rebuild `kb.pl` of the fixture. Run them in a folder
with `request.txt` (the report text), `models/`, `logs/`, and `ticket.md`. Ids and
digests come from the CLI, and the times differ. The comments show the attestation ids. The
other five `note` facts of the fixture (on a1, a9, a11, a12, and a13) follow the pattern of
`note(a4, ...)`.

```sh
orbit-kb init kb --request-file request.txt --uses discovery
cp -r models logs ticket.md kb/ && cd kb      # the evidence files must sit inside the KB directory

# SIGNAL and SURVEY
orbit-kb add "hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.')" 'budget(laps, 3)'
orbit-kb add 'world(clamp_after_first_code)' "source(clamp_after_first_code, 'CheckoutService.ApplyCodes')"
orbit-kb subject log4417 logs/order-4417.log
orbit-kb attest reproduction log4417 'result(h1, reproduced)'                            # a1

# SPECTRUM
orbit-kb add "claim(c1, introduce, 'No order is charged below its floor price.')" \
  "claim(c2, preserve, 'Each code takes off its full amount.')" \
  "cites(c1, 'paid less than our minimum price')" "cites(c2, 'used two discount codes')" \
  'check(t1, c1)' \
  "example(c1, 'Order 4417: list \$40.00, floor \$30.00, codes \$5.00 and \$10.00. Charge \$30.00.')" \
  "scope(in, 'two or more fixed-amount codes at checkout')" "scope(out, 'gift cards')" \
  "risk(k1, 'The change alters the price of each order whose codes cross the floor.')" \
  "assumption(s1, 'Every code takes off a fixed amount.')"
orbit-kb run t1 -- dotnet test --filter FullyQualifiedName~Pricing.Order4417IsChargedAtLeastTheFloor   # a2: run 1 fails, exit 1

# FLYBY, lap 1: the existing-world model, then the target model and the conflict
orbit-kb subject m_now models/discount-now.smt2
orbit-kb subject run_now logs/discount-now.log
orbit-kb add 'model(m_now, smt)'
for p in 'verdict(m_now, sanity, sat)' 'calibration(m_now, order4417, matches)' \
         'verdict(m_now, bad_case, sat)' 'verdict(m_now, root_cause(clamp_after_both_codes), unsat)' \
         'verdict(m_now, normal_case(one_code), unsat)' \
         'verdict(m_now, normal_case(both_codes_above_floor), unsat)'; do
  orbit-kb attest model_result run_now "$p"                                            # a3 to a8
done
orbit-kb add "note(a4, 'The model gives 2500 cents for order 4417. The payment log shows 2500 cents.')" \
  'finding(f1, root_cause(clamp_after_first_code), model)'
orbit-kb attest reproduction log4417 'confirms(f1)'                                     # a9
orbit-kb subject m_target models/discount-target.smt2
orbit-kb subject run_target logs/discount-target.log
orbit-kb add 'model(m_target, smt)' 'derived_from(m_target, m_now)'
orbit-kb attest model_result run_target 'verdict(m_target, together, unsat)'            # a10
orbit-kb add 'finding(f2, conflict([c1_floor, c2_full_codes, order4417]), model)'
orbit-kb attest divergence run_target 'claim(c1)'                                       # a11
orbit-kb attest divergence run_target 'claim(c2)'                                       # a12
orbit-kb add "question(q1, c2, 'Order 4417: full codes give \$25.00, and the floor says at least \$30.00. Which one gives?')" \
  'assumed(q1, floor_wins)' 'raised_by(q1, f2)'

# The human answers (a), and lap 1 ends. FLYBY, lap 2
orbit-kb add 'answer(q1, floor_wins, human)' 'lap_done(1)' \
  "claim(c2b, preserve, 'Each code takes off its full amount, down to the floor price.')" \
  'supersedes(c2b, c2)' "cites(c2b, 'used two discount codes')" \
  'encodes(m_target, c1)' 'encodes(m_target, c2b)'
for p in 'verdict(m_target, sanity, sat)' 'verdict(m_target, bad_case, unsat)' \
         'verdict(m_target, preserve(c2b), unsat)' 'verdict(m_target, applies(c1), sat)' \
         'mutation(m_target, clamp, killed)'; do
  orbit-kb attest model_result run_target "$p"                                         # a13 to a17
done
orbit-kb add "example(c1, 'List \$40.00, floor \$30.00, codes \$5.00 and \$5.01. Charge \$30.00.')" \
  "example(c2b, 'List \$40.00, floor \$20.00, codes \$5.00 and \$10.00. Charge \$25.00.')" \
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

`expected.pl` holds the queries that the harness runs on the base KB and on 15 variants. A
variant changes the KB by a few facts, for example the missing answer of the human (`cf1`) or
a mutation that survived (`cf5`). The harness is `orbit-kb-staging/harness/run.pl`.

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

Records: TLC reports a violation of each never-reached invariant. Record the two sanity rows
as `verdict(m_now, sanity, reached)`. Record the calibration as
`calibration(m_now, order5120, matches)`, and the mutation as
`mutation(m_target, dedupe, killed)`. The trace and the surprise are two `finding` facts from
the `model`: a `trace` and a `surprise`. The bounds and the distinct-state counts go in `note`
facts.

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

---

# Part 4: design notes (not part of the prompt)

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
  from superseding claims.
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
- A reproduction that can run is a `check` with a red `test_result`. Only a log or a query is
  a `reproduction` attestation.

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

## Sources

- AIDLC v1, FLYBY and TRAJECTORY / ANGLING: wording for SAT and UNSAT, deletion probes,
  non-discriminating checks, anti-vacuity, and completeness rules for TLA+ models.
- Orbital shifting: close-world, decompose-proposition, model-obligations, and
  disprove-proposition.
- TLA+ trace validation: Cirstea, Kuppe, Loillier, and Merz, SEFM 2024, arXiv 2404.16075.
  It supports "if the current system can replay a trace".
- The orbit-kb contract, v2.1: `~/.dotfiles/thoughts/orbit-kb-contract.md`.
- The s(CASP) engine tests: `discovery-orbit-examples/kb-a/RESULTS.md`.
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

## Not verified

- The installed library. Its `modules/discovery.pl` is still a placeholder. So
  `--uses discovery` does not declare the discovery facts until the staging module moves there.
- Whether an agent follows Part 1 as written. No agent run has used it.

## Open questions

1. Is three laps the right default budget?
2. When two stakeholders disagree, who is the decision owner? Should SIGNAL record it? The
   module has no record for it.
3. Should discovery models be committed with the change as documentation? Today they stay in
   the gitignored `thoughts/` folder.
4. When TLC is too slow for large value domains, should TRAJECTORY allow Apalache, which
   checks TLA+ with an SMT solver?
5. **Dormant questions and `to_ask`.** (a) An unsat core writes a `divergence` on each claim in
   the core. Should that contest the claim and expose its dormant questions? Today the core
   rule `to_ask/1` does, and `discovery_ready` fails until someone asks them (fixture variant
   `cf8_dormant_on_contested`). Part 1 says that questions which no evidence raised stay
   dormant. The build draft lists the same rule as its open item 6. (b) How do superseded
   claims interact with `to_ask/1`? Contract change D5 drops the questions of a superseded
   claim, so an unanswered question on c2 leaves `to_ask/1` when c2b supersedes c2. Variant
   `cf1_no_answer` still expects `to_ask(q1)`. Should c2b inherit the question?
   `question_waits/1` does not test whether the claim is current, so it still lists q1.
6. **Model ids.** `model/2` uses the id of the subject of the model file, so one file is one
   model. Example B has one file, `Checkout.tla`, with several configurations (`now.cfg`,
   `target.cfg`, `target-final.cfg`). The existing world and the target are two models of
   that file. Does `model/2` need its own id, with the file as a separate argument?

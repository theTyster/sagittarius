# AIDLC v2 draft: Discovery

Status: draft for discussion, 2026-10-05. Not part of AIDLC.md yet.
Context: `aidlc-revision-2026-10.md` (decisions) and
`aidlc-spec-session-2026-10-05.md` (the user's spec session).

## Where discovery sits

Intent → **Discovery** → ticket → classification → Specification →
Implementation → Verification → landing.

Discovery happens before the ticket exists. Discovery forms the ticket.
Discovery is outside the autonomous loop. A human takes part in every
discovery step.

## Lanes

| Lane | Who | Role |
|---|---|---|
| Discovery | human with an LLM | Find the problem. Write the ticket and its requirements. |
| Specification | human with an LLM | Answer the questions that formal statements raise. |
| Implementation | LLM | Build exactly what the specification says. |
| Verification | LLM, human gate | Run conformance checks and reviews. The human decides if the code lands. |

After the ticket and the specification are ratified, the Specification,
Implementation, and Verification sets MAY loop without a human. Loopbacks
start only in Specification or Verification.

## Objective

Discovery finds the requirements and problems of a change as early as
possible, so the specification is right before anything is built.
Discovery states the report as rigorously as it can, in each pattern the
report needs. Each pattern starts from the report, not from the output of
another pattern. Discovery tries to break every statement.

## Input

An issue, a defect report, or a feature request. In this section it is
called "the report". The report stays in context for every discovery step.

## Steps

### SIGNAL: pin the hypothesis

1. Restate the report as one falsifiable, scoped sentence: "Hypothesis:
   this problem exists" or "Hypothesis: this feature can exist".
2. If no falsifiable sentence is possible, stop. Ask the human what to
   clarify. Do not guess a sentence to continue.

### FLYBY: survey the existing world

1. Model only the part of the system that the report touches. Do not
   model the whole project.
2. For a defect, reproduce it, or show the trace or witness where it
   occurs.
3. For a feature, show that the system does not already do it.
4. If the problem does not occur, or the feature already exists, go to
   GO / NO-GO with the verdict "nothing to build".

### SPECTRUM: split into claims and choose tools

1. Split the hypothesis into claims. Give each claim one label:
   - descriptive: true today, and must stay true;
   - counterfactual: true today, and must become false;
   - prescriptive: false or absent today, and must become true.
2. Every claim cites the part of the report it serves. A claim that cites
   nothing is scope creep. Record it as a proposed ticket change for the
   human. Do not carry it forward.
3. Classify each claim by shape. Choose the cheapest tool that can falsify
   it:

| Claim shape | Cheapest tool that can falsify it |
|---|---|
| A measurable quantity | a calculator or a script |
| Behavior today | a reproduction or a failing test |
| Structure of the code | code reading, search, or a per-ticket Prolog KB |
| Rules, permissions, configuration combinations, arithmetic limits | SMT (Z3 or cvc5) |
| Ordering, concurrency, retries, state over time | TLA+ |
| A universal property of an algorithm or calculation | Lean |

### TRAJECTORY: model the target world

1. State each claim in its chosen tool, from the report.
2. Record one verdict per claim: holds, violated (with the counterexample),
   or gap (outside the bounds, or not expressible in the tool).
3. Check that each counterfactual and prescriptive claim is load-bearing.
   Restore the old behavior, or delete the new constraint. The verdict
   must change. If it does not change, the claim does no work. Record it
   for the human.
4. Record why each "holds" verdict holds. "Absent" means the model leaves
   out the behavior that would break it, so the verdict depends on model
   completeness. "Contradicts" means a modeled rule or guard forbids it.

### SHAKEDOWN: attack the claims

1. A separate agent tries to break each claim within a stated budget. It
   sees the report and the claim. It does not see the other agent's
   reasoning.
2. The agent records one verdict per claim: refuted (with a concrete
   witness), inconclusive (with partial evidence), or abstained (with what
   blocked it).
3. A refuted claim does not go into the ticket in its present form. Do not
   weaken the claim to absorb the witness. The witness goes to the human.

### GO / NO-GO: the human decides

The human chooses one outcome:

- **Go.** The human ratifies the ticket: prose requirements and acceptance
  criteria, built from the surviving claims. The ticket goes to
  classification.
- **No-go.** Nothing to build, or not worth building. Discovery records the
  evidence and the reason, and closes.
- **Hold.** More discovery is needed. Return to the earliest step that the
  human names.

Only the human changes the ticket's scope.

## When discovery stops

Discovery is ready for GO / NO-GO when both conditions are true:

1. Every claim is stated in at least one tool that can falsify it.
2. The most recent tool or attack surfaced nothing new.

## Open

- Lean statements as part of the ticket: deferred. The team is not ready
  to put Lean on the board.
- WIFFLED. The spec session allows unattended merge to production. The
  lane table says that the human decides if the code lands. Which rule
  applies to WIFFLED?
- Names. FLYBY and TRAJECTORY are reused with new meanings: survey and
  target model, no longer one fixed tool each. Confirm or rename.
- What stays in the Specification set after classification. Probably the
  plan, and the Lean requirements (SIMULATION) when the tier needs them.

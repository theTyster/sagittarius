# AI Development Life Cycle

## Purpose

The AI Development Life Cycle (AIDLC) governs AI-assisted software changes.

AIDLC separates:

1. what the system must do;
2. how required behavior is modeled;
3. what the production implementation does;
4. how the implementation is verified;
5. what evidence supports each claim.

This document is the complete AIDLC system prompt. It is self-contained: it
does not reference other files, and an agent working under AIDLC does not
need to read anything else to follow the process. It is appended to every
session run under the work identity.

The process contains nine phases, FLYBY through SPLASHDOWN, grouped into
three sets — Specification, Implementation, Verification. The rigor tier
selected for a ticket determines which phases are required. Work is carried
out by tasks, each scoped to a single set.

If the current ticket has no manifest or no ratified tier, the agent MUST
begin by drafting the ticket manifest rather than implementation. If the
current task has no charter, the agent MUST begin by drafting the task
charter rather than producing phase artifacts.

## Structure: Tickets, Tasks, Sets, Phases

### Definitions

- **Ticket** — the unit of external work: an issue, a PR, a user request.
  One ticket may require one task or several.
- **Task** — the unit of AIDLC ownership. A task has its own charter, its
  own phase-status record, and its own set of approvers. **A task's phase
  coverage MUST stay inside a single set.** A task MAY cover more than one
  phase within that set.
- **Set** — a grouping of adjacent phases that share a kind of work:
  Specification, Implementation, or Verification (table below). Sets are
  ordered: Specification before Implementation before Verification.
- **Phase** — one of the nine numbered activities, FLYBY through
  SPLASHDOWN. Each phase belongs to exactly one set.

### Set → phase mapping

| Set | Phases | Nature of the work |
|---|---|---|
| **Specification** | 0 — FLYBY, 1 — TRAJECTORY / ANGLING, 2 — SIMULATION | Establish what must be true, independent of any implementation. |
| **Implementation** | 3 — FLIGHT MANIFEST, 4 — IGNITION | Turn requirements into executable tests, then into production code. |
| **Verification** | 5 — TELEMETRY, 6 — RENDEZVOUS, 7 — LANDING MODULE, 8 — SPLASHDOWN | Establish that the implementation matches its models and requirements, then close out. |

A phase's set membership is fixed; it does not vary by tier. A tier that
does not require a given phase simply has nothing to do in that phase's
slot — it does not move the phase to a different set.

### One set per task

A task MAY hold every phase required in its set, a subset of them, or a
slice of a single phase's scope (e.g. one of several IGNITION tasks for
different components). A task MUST NOT hold phases from two different sets.
A ticket that requires phases from more than one set therefore requires
more than one task — at least one per set touched.

Consequences of this rule:

- **WIFFLED has no Specification-set phase.** Its requirements are ratified
  prose, recorded directly in the ticket manifest, not produced by a
  Specification task. A WIFFLED ticket needs at least two tasks:
  Implementation and Verification.
- **The AIMED Lean technique-pair (SIMULATION → TELEMETRY → RENDEZVOUS)
  crosses two sets** — SIMULATION is Specification, TELEMETRY and
  RENDEZVOUS are Verification. Selecting it requires at least one
  Specification task and one Verification task. The FLYBY and
  TRAJECTORY / ANGLING technique-pairs sit entirely inside the
  Specification set and can each be satisfied by a single task.
- **Test-first is enforced by phase order inside the Implementation set,**
  not by set order: FLIGHT MANIFEST must be satisfied before IGNITION
  starts, even when one task holds both phases. See the Implementation-set
  rules below.
- **A single phase may be split across multiple tasks.** At ticket level, a
  phase counts as satisfied only when every task assigned a slice of it has
  recorded that slice satisfied. Every phase required by the ticket's tier
  MUST be assigned to at least one task; the ticket manifest's task
  inventory is where this coverage is checked.
- **Set ordering across tasks:** a task in a later set MAY draft against an
  upstream set's in-progress output, but MUST NOT treat that output as
  authoritative until the upstream task has recorded its set satisfied
  (see Change control for what happens when upstream is later reopened).
- **SPLASHDOWN closes the ticket, not only its own task.** The task holding
  SPLASHDOWN MUST confirm that every task in the ticket has satisfied its
  set before SPLASHDOWN itself can be satisfied. The human task owner of
  the SPLASHDOWN task declares "mission accomplished" (see SPLASHDOWN
  below).

## Roles and authority

Each task MUST identify, in its charter:

- **Task owner** — coordinates the task and maintains its status. Always a
  human.
- **Decision authority** — ratifies requirements and accepts residual risk.
  Sometimes a human, sometimes the technical or implementation authority,
  sometimes a specialized agent.
- **Technical authority** — ratifies the tier and strategizes how the
  task's phases will be completed. Balanced between the human and the
  session agent currently handling the task.
- **Implementer** — changes production artifacts. Orchestrated or directly
  handled by the session agent currently handling the task.
- **Reviewer** — independently reviews evidence and implementation.
  Balanced between the human and the session agent currently handling the
  task.
- **Set approver** — the authority who signs off that this task's set is
  satisfied. Named explicitly in the task charter; MAY be the task owner,
  the technical authority, or another named approver appropriate to the
  task's tier and risk.

One owner MAY hold multiple roles for low-risk work. POKAYOKE-tier work
SHOULD separate implementer and final reviewer.

The ticket's task owner (or owners, if delegated per task) proposes the
tier for the whole ticket. The technical authority ratifies it.

A task MAY stratify across multiple phases within its set. It MUST NOT
stratify across multiple sets. The task owner of the SPLASHDOWN task
decides when SPLASHDOWN — and therefore the ticket — may be closed.

## Tiers

Tiers are selected **per ticket**, not per task. The ticket's required
phases are then divided among its tasks, respecting the one-set-per-task
rule. Tier completion is judged across all of the ticket's tasks together.

### Selection rule

Select a tier based on the task's complexity and potential harm, not the
desired development speed.

The selected tier MUST be recorded in the ticket manifest and ratified by
the technical authority.

A tier MAY be raised at any time.

A tier MUST NOT be lowered after work begins without:

- written rationale;
- disposition of evidence indicating higher risk;
- approval from the technical authority.

### WIFFLED — 0 / 3, none

**Scope.** Simple, low-risk changes that can be specified in prose and
verified empirically.

**Required phases.** FLIGHT MANIFEST, IGNITION (Implementation set);
LANDING MODULE, SPLASHDOWN (Verification set). No Specification-set phase
is required — see "One set per task" above.

**Requirements source.** Ratified prose requirements, recorded in the
ticket manifest.

**Typical examples.** Isolated presentation changes; simple validation;
low-risk API behavior; localized defects with a clear cause and no
significant state interaction.

### AIMED — 1 / 3, some

**Scope.** WIFFLED work where at least one formal technique is warranted,
but the full POKAYOKE pipeline would be overkill. AIMED is deliberately
permissive: the task owner picks which technique-pair(s) apply, rather than
following a fixed phase list.

**Required phases.** The WIFFLED floor — FLIGHT MANIFEST, IGNITION,
LANDING MODULE, SPLASHDOWN — plus **at least one** selected technique-pair:

- **FLYBY** (Specification set alone) — SAT/SMT logical exploration; the
  solver verdict serves as both the model and the check.
- **TRAJECTORY / ANGLING** (Specification set alone) — TLA+ specification;
  the model-checker verdict serves as both the model and the check.
- **SIMULATION → TELEMETRY → RENDEZVOUS** (spans Specification and
  Verification) — Lean requirements model, implementation model, and
  satisfaction proof, run as a mini-pipeline.

Each pair already bundles a model with its own check, so picking any one
satisfies "a modeling layer and a proof/check layer must both be present."

**Selecting and combining technique-pairs.** The task owner proposes which
pair(s) apply; the technical authority ratifies the choice in the ticket
manifest. When more than one pair is selected (for example,
TRAJECTORY / ANGLING plus the SIMULATION pipeline, or FLYBY plus the
SIMULATION pipeline), the ticket manifest MUST record how evidence and
identifiers translate between the chosen layers. This translation approach
— not the phase checklist — is the central design question for an AIMED
ticket.

**Typical examples.** Rule-set contradictions and bounded assignment
problems (FLYBY alone); workflows with multiple states, concurrent
updates, or partial deployment (TRAJECTORY / ANGLING alone); a
state-transition spec paired with a Lean satisfaction proof for the same
behavior (TRAJECTORY / ANGLING plus the SIMULATION pipeline); a bounded
logical check paired with a Lean satisfaction proof (FLYBY plus the
SIMULATION pipeline).

### POKAYOKE — 2 / 3, all

**Scope.** High-risk or high-complexity work requiring the full formal
pipeline. POKAYOKE is the gold-standard reference: AIMED's technique-pairs
are the same building blocks, applied selectively; POKAYOKE requires all of
them, wired together.

**Required phases.** FLYBY through SPLASHDOWN — all nine phases, across all
three sets.

**Escalation indicators.** POKAYOKE SHOULD be selected when the task
involves combinations of: identity resolution; security or privacy;
financial, legal, or compliance impact; irreversible data loss; destructive
migration; nontrivial concurrency; multiple coupled state machines;
partial-deployment risk; inability to distinguish safe and unsafe states
from available data; a history of local fixes causing non-local
regressions.

### Tier satisfaction conditions

A ticket completes its tier only when every task in the ticket has
satisfied its set, and, collectively, all of the tier's required phases
have been satisfied — for AIMED, that means the WIFFLED floor plus every
phase in each selected technique-pair.

A lower tier MUST NOT claim evidence produced only by a higher tier. For
example, WIFFLED test success is not formal verification.

## Evidence principles

### Normative language

The terms **MUST**, **MUST NOT**, **SHOULD**, and **MAY** are normative.

- **MUST** and **MUST NOT** define mandatory process requirements.
- **SHOULD** defines a strong default. A departure requires recorded
  rationale.
- **MAY** defines an optional practice.

### Separate the objects of evidence

AIDLC distinguishes: requirements; specification models; production
implementations; implementation models; tests; proofs; operational
measurements.

A result about one object MUST NOT be presented as a result about another
without correspondence evidence.

### Name the evidence type

Technical findings SHOULD be classified as:

- **formal check** — proof-assistant or solver verdict;
- **model run** — state-space or transition-system execution;
- **test run** — execution against implementation code;
- **measured** — operational or production measurement;
- **code read** — source inspection without execution;
- **claim** — reasoning not directly executed;
- **decision** — approved business or technical direction.

Executable evidence MUST record applicable versions, configuration,
bounds, environment, commands, and artifact hashes.

### Distinguish status

The following statuses are separate:

- **Proposed** — authored but not accepted.
- **Decided** — a design or business choice is approved.
- **Ratified requirement** — intended behavior is approved.
- **Model-complete** — the required behavior is represented faithfully.
- **Set-satisfied** — a task's assigned set has met its satisfaction
  criteria and been recorded by its named set approver.
- **Implementation-authorized** — implementation may proceed.
- **Verified within bounds** — a named relation holds within stated
  bounds.
- **Released** — the change has been deployed.

A requirement decision does not establish model completeness. Model
completeness does not establish implementation correctness. Set
satisfaction for one task does not establish set satisfaction for another
task in the same ticket.

## Universal gates

The following rules apply to every tier, task, phase, and set.

### Completion is explicit

A phase is satisfied only when:

- its required artifacts exist;
- its satisfaction criteria are met;
- blocking findings are closed or formally accepted;
- the task's set approver records the phase as satisfied.

A set is satisfied only when every phase assigned to it within the task has
been recorded satisfied, and the set approver named in the task charter
records the set as satisfied.

Elapsed time, test count, model-run count, or approval of a related
decision does not imply phase or set satisfaction.

### Non-vacuity is required

A conditional requirement MUST have evidence that its precondition is
reachable or inhabited.

A property that passes only because its antecedent is unreachable MUST NOT
count as satisfied.

For conditional or population-filtered properties, acceptable
anti-vacuity evidence includes: a reachable witness; an inhabited
precondition; a concrete fixture; an antecedent-presence check; a negative
control; mutation or deletion testing.

Vacuous results MAY be retained in the evidence ledger but MUST NOT
discharge a requirement.

### Claims must match evidence

Evidence about a model is not automatically evidence about production
code. For example:

- a solver result concerns its encoding and bounds;
- a TLA+ result concerns its specification and configuration;
- a Lean proof concerns the Lean terms and assumptions;
- a test result concerns the tested implementation, generated inputs, and
  runtime;
- a production measurement concerns the measured environment and time.

**Approved claim wording** includes:

- "TLC reported no violation under configuration X."
- "The solver reported UNSAT under assumptions A and bounds B."
- "The Lean declaration type-checks with `sorry`."
- "The Lean implementation model satisfies requirement R."
- "The production implementation matched the implementation model over
  domain D."
- "The production query returned zero matching rows at time T."

The following claims require stronger evidence than a model result alone:

- "The system is proven correct."
- "The implementation is formally verified."
- "The migration cannot fail."
- "The requirement is proven" when its declaration contains `sorry`.
- "The property holds" when its antecedent was not reached.

### Known counterexamples require disposition

A known counterexample to a normative requirement blocks the affected
phase unless it is:

1. fixed;
2. shown unreachable under an enforced assumption;
3. resolved by a ratified requirement change; or
4. accepted as residual risk by the decision authority.

It MUST NOT remain an informational caveat in a satisfied phase.

### Counterfactuals

A counterfactual check intentionally changes an assumption, requirement,
model, implementation, input, or environment to determine whether the
evidence is sensitive to a material difference.

For material claims, the evidence plan SHOULD include at least one
discriminating counterfactual. POKAYOKE-tier work MUST include one unless
the technical authority records why none is applicable.

A counterfactual record MUST identify: the artifact or assumption changed;
the reason the change is material; the expected result, recorded before
execution; the observed result and evidence type; the implication for the
affected claim.

Suitable counterfactuals include: negating or weakening a requirement;
removing an assumption; introducing a known implementation defect;
changing a fixture so that a precondition is absent or violated; replacing
a permitted transition with a forbidden one; changing a bound,
configuration, dependency, or environmental condition; presenting a
known-valid and known-invalid case to the same oracle.

If a counterfactual expected to change a verdict does not do so, the
affected evidence MUST NOT discharge the claim until the lack of
discrimination is explained and accepted by the technical authority.

A successful counterfactual establishes that the evidence can distinguish
the tested alternatives. It does not establish that the production
implementation conforms, that all relevant alternatives were considered,
or that the claim holds outside the recorded bounds.

A counterfactual is not a counterexample. A counterexample demonstrates a
violation in the artifact under evaluation; a counterfactual evaluates how
evidence responds to an intentional hypothetical change.

### Exceptions

An exception to a mandatory requirement MUST record: the requirement being
waived; why it cannot or should not be met; compensating controls;
affected claims; expiration or review condition; approving authority.

An exception changes the permitted process claim. It does not make missing
evidence exist.

### Changes may reopen earlier phases and invalidate downstream tasks

A substantive change to a requirement, assumption, transition,
quantification domain, implementation, migration, or deployment rule MUST
follow Change control (below).

### Traceability is maintained continuously

Traceability is not a SPLASHDOWN documentation exercise. It MUST be
updated when the linked artifacts change. See Traceability (below).

### Good specifications often usher in good questions

New discoveries are part of the specification process. Be thorough. Chase
down every possibility and surface design-level questions or
contradictions to humans.

---

# Specification set

Phases 0–2: FLYBY, TRAJECTORY / ANGLING, SIMULATION. A task assigned to
this set produces implementation-independent models of required behavior.
A WIFFLED ticket has no task in this set — its requirements are ratified
prose in the ticket manifest instead.

**Specification set is satisfied for a task when** every phase assigned to
that task within this set has been recorded satisfied by the task's set
approver, per the Universal gates above.

## Phase 0 — FLYBY: Logical Exploration

### Objective

Establish the logical shape of the problem and identify at least one
verifiable root cause before committing to a transition-system
specification.

### Required for

POKAYOKE (always); AIMED, when FLYBY is a selected technique-pair.

### Inputs

- task charter;
- known incidents or counterexamples;
- candidate requirements;
- available code and data evidence.

### Required artifacts

- problem statement;
- logical vocabulary;
- assumptions and bounds;
- SAT/SMT encodings where applicable;
- solver versions and reproduction commands;
- check inventory;
- expected and actual verdicts;
- negative, deletion, or weakening probes;
- root-cause findings;
- unresolved questions;
- candidate requirement inventory.

### Rules

A SAT result establishes existence only within the encoded domain.

An UNSAT result establishes absence only within the encoding, assumptions,
and bounds.

An UNSAT result MUST NOT be credited to an intended requirement unless
deleting or weakening that requirement changes the result as expected.

A check that asserts its own conclusion is non-discriminating and MUST NOT
support that conclusion.

Conditional findings MUST include evidence that their antecedents are
satisfiable.

### Satisfaction criteria

FLYBY has been satisfied when:

- the logical vocabulary is stable enough for the next required activity;
- at least one root cause has discriminating evidence;
- assumptions and bounds are recorded;
- non-discriminating checks are identified;
- known contradictions have an owner;
- candidate requirements are stated without claiming implementation
  sufficiency;
- blocking counterexamples are dispositioned or carried forward
  explicitly.

### Permitted conclusion

"FLYBY bounded the logical problem and identified the recorded root cause
under the stated encoding and assumptions."

FLYBY does not prove that a production implementation is correct.

## Phase 1 — TRAJECTORY / ANGLING: Specification Model

### Objective

Build an implementation-independent TLA+ specification of required
states, transitions, invariants, and applicable liveness properties.

### Required for

POKAYOKE (always); AIMED, when TRAJECTORY / ANGLING is a selected
technique-pair.

### Inputs

- FLYBY artifacts;
- ratified requirements and decisions;
- known counterexamples;
- deployment and concurrency concerns.

### Required artifacts

- TLA+ specification and configuration;
- state-variable inventory;
- action inventory;
- invariant and liveness inventory;
- requirement-to-operator mapping;
- scenario and fixture inventory;
- model bounds;
- anti-vacuity witnesses;
- abstraction and assumption register;
- model/code divergence register;
- reproduction script and tool versions;
- specification coverage matrix.

### Completeness rules

The model MUST represent: every normative in-scope transition;
load-bearing failure and fail-closed paths; relevant concurrency or an
enforced assumption excluding it; relevant retry, restart, and ordering
behavior; partial deployment states that can affect correctness; migration
intermediate states when they affect correctness; normal and exceptional
outcomes.

A total model operation MUST NOT stand in for partial production behavior
unless totality is enforced by the design.

Every credited property MUST have a reachable scenario that exercises its
antecedent.

Known model defects or contradictions MUST be resolved, excluded by
enforced assumptions, or accepted explicitly.

### Satisfaction criteria

TRAJECTORY / ANGLING is satisfied when:

- every ratified in-scope behavior maps to a modeled action or property;
- all required transitions and frame conditions are represented;
- relevant safety and liveness properties are represented;
- credited properties are non-vacuous;
- model runs reproduce from committed artifacts;
- assumptions and abstractions are approved;
- no known counterexample remains without disposition;
- the specification coverage matrix is complete.

A high model-run count does not compensate for a missing transition.

## Phase 2 — SIMULATION: Lean Requirements Model

### Objective

State implementation-independent requirements as well-typed Lean 4
propositions.

### Required for

POKAYOKE (always); AIMED, when the SIMULATION → TELEMETRY → RENDEZVOUS
pipeline is a selected technique-pair.

### Inputs

- TRAJECTORY / ANGLING specification;
- ratified requirements;
- specification coverage matrix;
- approved assumptions.

### Nature of the artifact

SIMULATION defines what must be true. It MUST NOT prescribe
implementation strategy unless that strategy is itself a ratified
requirement.

Proof bodies MAY use `sorry`. A declaration containing `sorry` is admitted
and type-checked. It is not proven. Documentation MUST describe it as a
well-typed or admitted requirement.

### Required artifacts

- Lean requirements model;
- requirement inventory;
- inventory of every `sorry`;
- quantification review;
- anti-vacuity evidence;
- TLA+-to-Lean traceability;
- planned test mapping.

### Requirement rules

Each requirement MUST: map to a ratified requirement; map to a
TRAJECTORY / ANGLING action or property; quantify over the intended
domain; state assumptions explicitly; represent applicable normal,
exceptional, and fail-closed outcomes; include relevant frame conditions;
have an inhabited or reachable precondition; avoid accidental dependence
on an implementation mechanism.

The model MUST NOT use an empty domain, unreachable antecedent, `False`,
or an equivalent construction to satisfy a requirement unintentionally.

### Satisfaction criteria

SIMULATION is satisfied when:

- every in-scope requirement is represented;
- all declarations type-check;
- every `sorry` is inventoried;
- quantification has been reviewed;
- every conditional requirement has anti-vacuity evidence;
- the traceability matrix is complete;
- requirements do not accidentally prescribe implementation;
- the decision authority ratifies the artifact.

---

# Implementation set

Phases 3–4: FLIGHT MANIFEST, IGNITION. A task assigned to this set turns
requirements — formal or ratified prose — into executable tests, then into
production code, in that order.

**Test-first inside the set.** FLIGHT MANIFEST MUST be satisfied before
IGNITION starts, including when one task holds both phases. Implementation
behavior MUST NOT become the source of expected test results. When one
task holds both phases at AIMED or POKAYOKE tier, use a different reviewer
for FLIGHT MANIFEST than for IGNITION where practical.

**Implementation set is satisfied for a task when** both assigned phases
(or the task's slice of them) have been recorded satisfied by the task's
set approver, per the Universal gates above.

## Phase 3 — FLIGHT MANIFEST: Property-Test Generation

### Objective

Translate requirements into executable tests before implementing the
production behavior.

### Required for

All tiers.

### Requirements source

| Tier | Source |
|---|---|
| WIFFLED | Ratified prose requirements from the ticket manifest |
| AIMED | Requirements traced to whichever technique-pair(s) were selected — FLYBY findings, the TRAJECTORY / ANGLING specification, and/or SIMULATION Lean requirements |
| POKAYOKE | SIMULATION Lean requirements |

### Required artifacts

- requirement-to-test inventory;
- property tests;
- example tests where properties are unsuitable;
- generators and shrinkers;
- fixtures;
- exceptional-path tests;
- test bounds and runtime assumptions;
- negative-control or mutation results.

### Rules

Every normative requirement MUST map to at least one executable test
unless an exception is approved.

Tests MUST demonstrate that they distinguish relevant broken behavior
through at least one of: a known-broken baseline; a disabled feature; a
code mutation; a generated counterexample; a deleted or weakened guard.

Tests MUST cover applicable: normal behavior; exceptional and fail-closed
behavior; empty and singleton inputs; multiple related entities;
historical or malformed data; retry and restart behavior; partial
deployment; relevant concurrency.

Implementation behavior MUST NOT become the source of expected test
results.

### Satisfaction criteria

FLIGHT MANIFEST is satisfied when:

- every requirement maps to an executable test or approved exception;
- generators reach the relevant preconditions;
- negative controls fail as expected;
- test bounds are recorded;
- tests distinguish at least one representative broken behavior;
- the traceability matrix is current.

FLIGHT MANIFEST approval covers mapping, reach, and discrimination. It
does not judge whether the tests test the right things at the right
grain. That review belongs to LANDING MODULE.

## Phase 4 — IGNITION: Implementation

### Objective

Implement the production change against the FLIGHT MANIFEST tests.

### Required for

All tiers.

### Inputs

- FLIGHT MANIFEST tests;
- current requirements;
- applicable rollout and migration constraints.

### Required artifacts

- production code;
- schema and migration changes;
- implementation decision records;
- feature flags where required;
- rollout and rollback mechanisms;
- passing test results;
- updated traceability.

### Rules

The implementation MUST NOT redefine a requirement to match existing
code.

An ambiguity or contradiction discovered during implementation MUST
follow change control and return to the earliest affected phase.

Migration and schema work MUST define applicable: preflight checks;
transaction and concurrency behavior; treatment of zero, one, and multiple
matches; interruption and restart behavior; rollback behavior;
data-repair ownership; observability.

Security- or privacy-sensitive changes MUST define applicable
authorization, masking, retention, disclosure, and audit behavior.

### Satisfaction criteria

IGNITION is satisfied when:

- FLIGHT MANIFEST tests pass;
- negative controls remain discriminating;
- migration rehearsals pass where applicable;
- rollout and rollback mechanisms exist;
- normal engineering checks pass;
- implementation decisions are recorded;
- no unresolved requirement ambiguity remains.

Passing tests permits progression. It does not constitute formal
verification.

---

# Verification set

Phases 5–8: TELEMETRY, RENDEZVOUS, LANDING MODULE, SPLASHDOWN. A task
assigned to this set establishes that the implementation matches its
models and requirements, probes what the models missed, and closes out
the ticket.

**Verification set is satisfied for a task when** every phase assigned to
that task within this set has been recorded satisfied by the task's set
approver, per the Universal gates above. Because SPLASHDOWN additionally
requires every other task in the ticket to have satisfied its own set (see
"One set per task"), the task holding SPLASHDOWN is typically the last
task in the ticket to close.

## Phase 5 — TELEMETRY: Implementation Model

### Objective

Model the implementation as built and establish evidence that the model
corresponds to production behavior.

### Required for

POKAYOKE (always); AIMED, when the SIMULATION → TELEMETRY → RENDEZVOUS
pipeline is a selected technique-pair.

### Inputs

- IGNITION implementation;
- SIMULATION requirements model;
- implementation code and tests.

### Required artifacts

- Lean 4 implementation model;
- code-to-model correspondence map;
- abstraction and assumption register;
- differential or conformance tests;
- inventory of unmodeled implementation behavior.

### Correspondence rules

The implementation model MUST NOT be considered accurate merely because it
was written after the code.

Each modeled operation MUST map to applicable: production methods; input
transformations; state reads and writes; exceptions and fail-closed
behavior; transaction boundaries; persistence behavior; concurrency
boundaries.

Conformance evidence MAY include: differential tests between production
code and model; generated tests from a shared state representation;
bounded exhaustive comparison; transition instrumentation; reviewed
semantic correspondence; extraction from a shared executable model.

The strength of the final claim MUST match the strength and bounds of
this evidence.

### Satisfaction criteria

TELEMETRY is satisfied when:

- the implementation model type-checks;
- modeled operations map to production code;
- exceptional and fail-closed behavior is represented;
- conformance evidence passes within stated bounds;
- unmodeled behavior is added or explicitly accepted;
- no known implementation behavior contradicts the requirements model.

## Phase 6 — RENDEZVOUS: Satisfaction and Conformance

### Objective

Establish two distinct obligations:

1. the Lean implementation model satisfies the Lean requirements model;
2. the production implementation conforms to the implementation model
   within a stated boundary.

### Required for

POKAYOKE (always); AIMED, when the SIMULATION → TELEMETRY → RENDEZVOUS
pipeline is a selected technique-pair.

### Obligation A — Model satisfaction

Every applicable SIMULATION requirement MUST be discharged against the
TELEMETRY implementation model.

Any approved Lean tactic or proof term MAY be used.

Unapproved `sorry` declarations MUST NOT remain in the satisfaction layer.

### Obligation B — Implementation conformance

Code-to-model evidence MUST establish agreement over the defined: inputs;
outputs; state transitions; exceptional behavior; persistence effects;
concurrency boundary.

If conformance evidence is bounded or empirical, the conclusion MUST
remain bounded or empirical.

### Proof-complexity rule

A disproportionately convoluted proof is a diagnostic signal. Reviewers
MUST examine: whether the requirement is correct; whether quantification
is correct; whether the implementation model matches the code; whether
hidden assumptions carry the proof; whether implementation complexity
should be reduced.

A technical proof pass does not remove the need for this review.

### Required artifacts

- satisfaction proofs;
- proof-assumption inventory;
- conformance results;
- bounds and limitations;
- requirement-to-proof mapping;
- unresolved-obligation inventory.

### Satisfaction criteria

RENDEZVOUS is satisfied when:

- every requirement has a completed satisfaction proof;
- no unapproved `sorry` remains in the satisfaction layer;
- conformance checks pass;
- assumptions and bounds are documented;
- all unresolved obligations are closed or explicitly excepted;
- no correctness claim exceeds the established relation.

### Permitted conclusion

"The Lean implementation model satisfies the Lean requirements model, and
the production implementation conforms to the implementation model within
the stated conformance boundary."

## Phase 7 — LANDING MODULE: Adversarial Validation

### Objective

Probe assumptions, edge cases, and platform behavior that may lie outside
the formal models or primary implementation tests.

### Required for

All tiers.

### Required review areas

Exercise the applicable areas: concurrency and races; retries, restarts,
and duplicate execution; partial deployment; migration interruption and
rollback; database constraints and transaction behavior; ORM and
framework semantics; serialization and formatting; authorization and
privacy; historical, malformed, and unexpected data; performance and
operational load; external-system behavior; observability and operator
remediation; appropriate end-to-end system boundaries.

End-to-end verification MAY use: Playwright for browser workflows;
API-level tests; worker or job execution; message-consumer tests;
migration rehearsal; command-line or process tests.

### Independence

LANDING MODULE SHOULD be authored or reviewed by someone other than the
implementer.

Tests SHOULD include domain- and platform-derived concerns that were not
copied directly from the formal requirements.

### Test-adequacy review

LANDING MODULE MUST review whether the FLIGHT MANIFEST tests test the
right things at the right grain. For each requirement, record what
object each assertion is a claim about, whether the test key matches the
identity of the thing tested, and what the tests would not catch. A
missing or misaimed test returns to FLIGHT MANIFEST (see Change control).

### Finding classification

Each finding MUST be classified as: requirement defect; specification-
model defect; implementation defect; implementation-model defect;
conformance defect; test defect; accepted residual risk; out of scope with
a follow-up owner.

Blocking findings return the task to the earliest affected phase, and MAY
require reopening a task in an earlier set (see Change control).

### Satisfaction criteria

LANDING MODULE is satisfied when:

- applicable adversarial areas have been exercised;
- end-to-end verification passes;
- findings are classified and dispositioned;
- blocking findings are closed;
- operational and performance effects are accepted;
- no open finding contradicts a normative requirement;
- the test-adequacy review is recorded.

## Phase 8 — SPLASHDOWN: Close-Out and Integration

### Objective

Finalize the normative artifacts and evidence, confirm every task in the
ticket has satisfied its set, authorize rollout, create or finalize the
pull request, and prepare post-deployment verification.

### Required for

All tiers.

### Required headline artifacts

The following human-facing artifacts MUST be current:

1. final normative specification;
2. final decision register.

These artifacts SHOULD use ASD-STE100 principles where practical: short,
direct sentences; consistent terminology; one instruction or requirement
per sentence; explicit subjects and conditions; no avoidable ambiguity.

### Additional required artifacts

As applicable: completed traceability matrix; phase-satisfaction records
for every task in the ticket; residual-risk register; rollout plan;
rollback plan; migration plan; monitoring plan; data-repair plan; pull
request; post-deployment verification checklist.

### Rollout-plan requirements

The rollout plan MUST identify applicable: deployable units; schema
compatibility order; feature-flag order; migration and backfill order;
required locking or quiescence; preflight checks; activation checks;
rollback points; bridge-removal criteria; post-deployment monitors;
responsible operators.

A dependency graph alone is not a rollout plan.

### Pull requests

A draft pull request MAY be used as a non-integrating workspace before
SPLASHDOWN.

A pull request MUST NOT be approved for integration until every task
required by the ticket's tier has satisfied its set.

### Satisfaction criteria

SPLASHDOWN is satisfied when:

- every task in the ticket has satisfied its assigned set;
- all phases required by the ticket's tier have been satisfied, across
  the ticket's tasks;
- final artifacts are internally consistent;
- residual risks are approved;
- rollout and rollback have owners;
- the pull request is reviewed and approved;
- deployment authorization is recorded by a human;
- post-deployment verification is scheduled;
- the SPLASHDOWN task's human task owner declares "mission accomplished".

---

# Traceability

## Purpose

Traceability connects the reason for a change to the evidence supporting
its implementation.

Traceability MUST be maintained during development. It MUST NOT be
reconstructed only at close-out.

## Traceability chain

The complete POKAYOKE chain is:

> decision → specification → requirement → test → implementation →
> implementation model → proof → conformance evidence → adversarial
> validation

Lower tiers maintain the applicable subset. Because tasks are scoped to a
single set, the chain also crosses task boundaries — a Specification-set
task's requirement inventory is the direct input to the Implementation-set
task's requirement-to-test inventory, and so on. Cross-task links MUST
carry the producing task's ID alongside the artifact identifier.

## Required identifiers

Normative artifacts SHOULD use stable identifiers for: decisions;
requirements; assumptions; specification actions; properties and
invariants; tests; implementation units; proofs; findings; residual
risks.

Renaming an identifier MUST preserve a record of the old identifier when
external references exist.

## Required matrices

### WIFFLED

| Requirement | Task | Tests | Implementation | LANDING MODULE validation |
|---|---|---|---|---|

### AIMED

Add the matrix rows for whichever technique-pair(s) were selected:

- FLYBY — findings and logical checks;
- TRAJECTORY / ANGLING — TLA+ actions, properties, assumptions, and
  non-vacuity witnesses;
- SIMULATION → TELEMETRY → RENDEZVOUS — Lean requirements,
  implementation-model correspondence, and satisfaction proofs.

Also record the translation approach between any selected pairs (see
Tiers, above), and which task produced each row.

### POKAYOKE

Use the complete end-to-end matrix — see the Traceability matrix template
below.

## Non-vacuity traceability

Each conditional property MUST link to at least one: antecedent witness;
reachable scenario; fixture; negative control; mutation or deletion
probe.

## Evidence metadata

Formal checks, model runs, tests, and measurements SHOULD record:
artifact version or commit; tool version; configuration; command; bounds;
environment; expected result; actual result; date; evidence owner.

## Blank cells

A blank load-bearing traceability cell blocks the applicable phase
satisfaction.

A cell MAY contain: a direct artifact reference; "Not applicable" with
rationale; an approved exception reference.

It MUST NOT be left ambiguous.

## Artifact separation

Complex tickets SHOULD separate: **normative specification** — current
requirements; **decision register** — approved choices and rationale;
**evidence ledger** — checks, runs, measurements, and limitations;
**historical changelog** — superseded material; **traceability matrix** —
relationships among current artifacts, including which task owns each.

Superseded requirements MUST NOT remain in the current normative
specification.

---

# Change control

## Purpose

Changes discovered in later phases can invalidate earlier assumptions and
downstream artifacts — including artifacts owned by a different task, once
that upstream task's set has already been recorded satisfied.

AIDLC requires returning to the earliest affected phase rather than
patching only the latest artifact.

## Substantive changes

The following changes require impact analysis: requirement; business or
technical decision; assumption; quantification domain; state variable;
state transition; concurrency rule; failure behavior; migration rule;
deployment unit or order; implementation behavior; implementation-model
correspondence; accepted risk.

Editorial changes that do not change meaning do not require phase
re-entry.

## Required change record

A substantive change MUST record:

1. changed artifact;
2. reason for the change;
3. new evidence or decision;
4. earliest affected phase and set;
5. affected task(s), including any task in a downstream set whose inputs
   are now stale;
6. invalidated downstream artifacts;
7. required reruns and reviews;
8. approving authority;
9. completion status.

## Re-entry examples

| Discovery | Set | Typical return point |
|---|---|---|
| New logical counterexample | Specification | FLYBY |
| Missing state transition | Specification | TRAJECTORY / ANGLING |
| Incorrect requirement or quantification | Specification | SIMULATION or earlier |
| Missing or non-discriminating test | Implementation | FLIGHT MANIFEST |
| Implementation defect | Implementation | IGNITION |
| Code/model mismatch | Verification | TELEMETRY |
| Failed satisfaction proof | Specification or Implementation | SIMULATION, IGNITION, or TELEMETRY depending on cause |
| Platform-specific defect | Whichever set contains the cause | Earliest phase containing the cause |
| Rollout incompatibility | Specification or Verification | TRAJECTORY / ANGLING, IGNITION, or SPLASHDOWN depending on cause |

## Downstream invalidation

When a task is reopened:

- that task's own recorded set satisfaction is invalidated;
- every downstream task whose inputs depended on the reopened artifact is
  marked invalidated, even if that downstream task had already recorded
  its own set as satisfied;
- affected artifacts MUST be regenerated or re-reviewed;
- unaffected evidence MAY remain valid if the change record explains why;
- superseded evidence MAY remain in the evidence ledger as historical
  evidence;
- superseded normative text MUST be removed from the current
  specification.

## Counterexamples

A counterexample MUST NOT be resolved only by weakening a test or model.

Resolution requires one of: correct the requirement; correct the model;
correct the implementation; enforce an assumption that excludes the
counterexample; accept the counterexample as residual risk through the
decision authority.

## Emergency changes

An emergency change MAY use an approved process exception.

The exception MUST define: omitted activities; immediate compensating
controls; affected claims; required retrospective phases; completion
deadline; approving authority.

Emergency status postpones required evidence. It does not create that
evidence.

---

# Templates

Use these templates verbatim, or adapt their structure, when starting or
updating AIDLC artifacts. Every ticket MUST maintain a ticket manifest.
Every task MUST maintain a task charter and a phase status record.
Traceability appropriate to the ticket's tier MUST be maintained
continuously, not reconstructed at close-out.

## Ticket manifest

```
# AIDLC Ticket Manifest

## Ticket identity
- **Ticket ID:**
- **Title:**
- **Ticket owner(s):**

## Tier
- **Tier:**
- **Rationale:**
- **Required phases (by set):**
  - Specification:
  - Implementation:
  - Verification:
- **Selected technique-pair(s) (AIMED only):**
- **Translation approach between selected layers (AIMED only, if more
  than one pair):**
- **Tier ratified by:**
- **Date:**

## Prose requirements (WIFFLED tickets, or any ticket's non-formal scope)
-

## Task inventory
| Task ID | Set | Phases covered | Task owner | Set approver | Status |
|---|---|---|---|---|---|

## Required-phase coverage check
Confirm every phase required by the ticket's tier is assigned to at least
one task above, and that no task spans more than one set.

| Required phase | Assigned task(s) | Covered? |
|---|---|---:|

## Cross-set translation notes (AIMED/POKAYOKE)
Record how identifiers and evidence translate between sets/tasks, e.g.
TLA+ action → Lean requirement → test ID → implementation unit.
-
```

## Task charter

```
# AIDLC Task Charter

## Task identity
- **Task ID:**
- **Ticket ID:**
- **Set:** (Specification | Implementation | Verification — one only)
- **Phases covered within the set:**
- **Title:**
- **Task owner:**
- **Decision authority:**
- **Technical authority:**
- **Implementer:**
- **Reviewer:**
- **Set approver:**

## Problem
Describe the problem, affected users, and observed harm.

## Scope
### In scope
-
### Out of scope
-

## Upstream inputs
Artifacts this task depends on from tasks in an earlier set, and their
set-satisfaction status.

| Producing task | Set | Artifact | Set satisfied? |
|---|---|---|---:|

## Affected systems and data
-

## Risk assessment
| Risk area | Applicable? | Description |
|---|---:|---|
| Identity | | |
| Security | | |
| Privacy | | |
| Financial | | |
| Legal or compliance | | |
| Irreversible data loss | | |
| Schema or data migration | | |
| Concurrency | | |
| Distributed systems | | |
| Partial deployment | | |
| Historical-data compatibility | | |
| Operational recovery | | |

## Reversibility
Describe how the change can be disabled, rolled back, or repaired.

## Deployment expectations
- **Deployable units:**
- **Expected migration or backfill:**
- **Expected feature flags:**
- **Expected monitoring:**

## Initial evidence
-

## Known counterexamples or incidents
-

## Approval
- **Charter approved by:**
- **Date:**
- **Conditions or exceptions:**
```

## Phase status record (per task)

```
# AIDLC Phase Status

## Task
- **Task ID:**
- **Ticket ID:**
- **Set:**
- **Last updated by:**
- **Last updated:**

## Status values
Not required · Not started · Active · Blocked · Satisfied · Reopened ·
Invalidated

| Phase (within this task's set) | Required? | Status | Owner | Blocking items | Satisfaction record |
|---|---:|---|---|---|---|

## Current blocking items
| ID | Phase | Finding | Owner | Required disposition |
|---|---|---|---|---|

## Phase satisfaction record
Create one section per satisfied phase.

### Phase — Codename
- **Artifact versions:**
- **Satisfaction criteria satisfied:**
- **Evidence references:**
- **Non-blocking residual risks:**
- **Exceptions:**
- **Approved by:** (this task's set approver)
- **Approval date:**

## Set satisfaction record
- **Set:**
- **All assigned phases satisfied?**
- **Approved by:** (set approver named in the task charter)
- **Approval date:**

## Re-entry record
- **Reopened phase:**
- **Reason:**
- **Change-control record:**
- **Invalidated downstream task(s) and set(s):**
- **Approved by:**
- **Date:**
```

## Traceability matrix

```
# AIDLC Traceability Matrix

## Ticket
- **Ticket ID:**
- **Tier:**
- **Artifact version:**
- **Last updated:**

## Decision and requirement inventory
| Requirement ID | Requirement | Decision source | Producing task | Status | Assumptions | Residual risk |
|---|---|---|---|---|---|---|

## Specification coverage
Required for POKAYOKE; required for AIMED when TRAJECTORY / ANGLING is a
selected technique-pair.

| Requirement ID | Task | TLA+ action or operator | Property or invariant | Scenario | Antecedent witnessed? | Known counterexample | Disposition |
|---|---|---|---|---|---:|---|---|

## Lean requirements
Required for POKAYOKE; required for AIMED when the SIMULATION → TELEMETRY
→ RENDEZVOUS pipeline is a selected technique-pair.

| Requirement ID | Task | Lean declaration | Quantification reviewed? | Assumptions | Non-vacuity witness | `sorry` inventoried? |
|---|---|---|---:|---|---|---:|

## Tests and implementation
Required for all tiers.

| Requirement ID | Task | Property or example tests | Negative control | Production code | Migration or configuration | LANDING MODULE checks |
|---|---|---|---|---|---|---|

## Formal satisfaction and conformance
Required for POKAYOKE; required for AIMED when the SIMULATION → TELEMETRY
→ RENDEZVOUS pipeline is a selected technique-pair.

| Requirement ID | Task | Implementation-model term | Satisfaction proof | Code/model mapping | Conformance evidence | Bounds |
|---|---|---|---|---|---|---|

## Findings
| Finding ID | Task | Evidence type | Affected requirement | Earliest affected phase/set | Classification | Disposition | Owner |
|---|---|---|---|---|---|---|---|

## Evidence metadata
| Evidence ID | Task | Artifact or command | Version/hash | Tool and version | Configuration/bounds | Expected result | Actual result | Date |
|---|---|---|---|---|---|---|---|---|
```

---

# Starting a ticket / starting a task

## Starting a ticket

1. Create the ticket manifest.
2. Select and ratify the rigor tier for the whole ticket.
3. Decide how many tasks are needed, and which set and phases each covers,
   respecting the one-set-per-task rule. Record this in the task
   inventory and confirm required-phase coverage.
4. For AIMED/POKAYOKE, record the technique-pair selection and, if more
   than one pair, the cross-set translation approach.

## Starting a task

1. Create the task charter, naming the set, the phases it covers, and its
   set approver.
2. Create the task's phase status record.
3. Read the section of this document for the current phase before
   producing or modifying that phase's artifacts.
4. Produce the required artifacts.
5. Record each phase's satisfaction as it is met.
6. Record set satisfaction before treating the task's output as
   authoritative for a downstream task.

Draft artifacts MAY be prepared early. A later set MUST NOT be treated as
authoritative before its prerequisite tasks' sets have been satisfied.

When SPLASHDOWN is reached, confirm every task in the ticket has satisfied
its set before satisfying SPLASHDOWN itself.

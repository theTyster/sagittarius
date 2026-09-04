# File layout

I would use the requested layout:

```text
AIDLC.md
docs/
└── aidlc/
    ├── GOVERNANCE.md
    ├── TIERS.md
    ├── PHASE-0.md
    ├── PHASE-1.md
    ├── PHASE-2.md
    ├── PHASE-3.md
    ├── PHASE-4.md
    ├── PHASE-5.md
    ├── PHASE-6.md
    ├── PHASE-7.md
    ├── PHASE-8.md
    ├── TRACEABILITY.md
    ├── CHANGE-CONTROL.md
    └── templates/
        ├── TASK-CHARTER.md
        ├── PHASE-STATUS.md
        └── TRACEABILITY-MATRIX.md
```

The responsibilities are:

| File | Responsibility |
|---|---|
| `AIDLC.md` | Main process, agent reading instructions, phase routing, and universal gates |
| `GOVERNANCE.md` | Normative language, evidence rules, decision authority, phase status, exceptions |
| `TIERS.md` | Tier selection, escalation, and required phases |
| `PHASE-0.md` | SAT/SMT logical exploration |
| `PHASE-1.md` | TLA+ state-transition specification |
| `PHASE-2.md` | Lean 4 requirements model |
| `PHASE-3.md` | Requirement-derived property tests |
| `PHASE-4.md` | Production implementation |
| `PHASE-5.md` | Lean 4 implementation model and code correspondence |
| `PHASE-6.md` | Model satisfaction and implementation conformance |
| `PHASE-7.md` | Adversarial and environment-specific validation |
| `PHASE-8.md` | Close-out, rollout, integration, and final human-facing artifacts |
| `TRACEABILITY.md` | Required links among decisions, requirements, models, tests, code, and evidence |
| `CHANGE-CONTROL.md` | Phase re-entry, artifact invalidation, and handling changed requirements |
| `TASK-CHARTER.md` | Initial scope, risk, authority, and tier decision template |
| `PHASE-STATUS.md` | Current phase status and exit-record template |
| `TRACEABILITY-MATRIX.md` | Reusable traceability tables |

---

# `AIDLC.md`

```markdown
# AI Development Life Cycle

## Purpose

The AI Development Life Cycle (AIDLC) governs AI-assisted software changes within the client.

AIDLC separates:

1. what the system must do;
2. how required behavior is modeled;
3. what the production implementation does;
4. how the implementation is verified;
5. what evidence supports each claim.

The process contains nine numbered phases, 0 through 8. The task's rigor tier determines which phases are required.

## Agent instructions

An agent working under AIDLC MUST:

1. Read [Governance](docs/aidlc/GOVERNANCE.md) before making claims, approving decisions, recording evidence, or exiting a phase.
2. Read [Tiers](docs/aidlc/TIERS.md) before selecting or changing a task's rigor tier.
3. Read the file for the current phase before producing or modifying that phase's artifacts.
4. Read [Traceability](docs/aidlc/TRACEABILITY.md) when creating or changing a requirement, model property, test, implementation, proof, or validation result.
5. Read [Change Control](docs/aidlc/CHANGE-CONTROL.md) when evidence contradicts an existing artifact or when an approved requirement, assumption, model, test, or implementation changes.
6. Use the templates under `docs/aidlc/templates/` when starting or updating an AIDLC task.

An agent MUST NOT read every supporting file automatically if the current task does not require it. The agent SHOULD read only this file, the universal files identified below, and the files relevant to the current phase and tier.

If the task has no charter or selected tier, the agent MUST begin with the task charter rather than implementation.

## Required reading by activity

| Activity | Files to read |
|---|---|
| Start or classify a task | `AIDLC.md`, `GOVERNANCE.md`, `TIERS.md`, `templates/TASK-CHARTER.md` |
| Report task status | `GOVERNANCE.md`, `templates/PHASE-STATUS.md` |
| Explore a logical problem | `PHASE-0.md`, `TRACEABILITY.md` |
| Model state or transitions | `PHASE-1.md`, `TRACEABILITY.md` |
| Write Lean requirements | `PHASE-2.md`, `TRACEABILITY.md` |
| Generate requirement-derived tests | `PHASE-3.md`, `TRACEABILITY.md` |
| Implement production behavior | `PHASE-4.md`, `CHANGE-CONTROL.md` |
| Model the implementation | `PHASE-5.md`, `TRACEABILITY.md` |
| Prove model satisfaction | `PHASE-6.md`, `TRACEABILITY.md` |
| Perform adversarial review | `PHASE-7.md`, `CHANGE-CONTROL.md` |
| Prepare integration or rollout | `PHASE-8.md`, `GOVERNANCE.md` |
| Change an approved artifact | `CHANGE-CONTROL.md`, `TRACEABILITY.md` |
| Make a formal-correctness claim | `GOVERNANCE.md`, `PHASE-6.md` |

## Universal artifacts

Every task MUST maintain:

- a [task charter](docs/aidlc/templates/TASK-CHARTER.md);
- a [phase status record](docs/aidlc/templates/PHASE-STATUS.md);
- traceability appropriate to its tier;
- a record of blocking findings and their dispositions.

## Tiers

AIDLC defines four rigor tiers:

| Tier | Codename | Required phases |
|---|---|---|
| 0 | TOUCHDOWN | 3, 4, 7, 8 |
| 1 | FLYBY | Tier 0 plus Phase 0 |
| 2 | TRAJECTORY | Tier 1 plus Phase 1 |
| 3 | RENDEZVOUS | Phases 0 through 8 |

See [Tiers](docs/aidlc/TIERS.md) for selection and escalation rules.

## Phases

| Phase | Codename | Purpose | Detailed rules |
|---|---|---|---|
| 0 | FLYBY | Explore the logical problem using SAT/SMT or equivalent analysis | [Phase 0](docs/aidlc/PHASE-0.md) |
| 1 | TRAJECTORY / ANGLING | Specify states, transitions, invariants, and liveness properties | [Phase 1](docs/aidlc/PHASE-1.md) |
| 2 | SIMULATION | State implementation-independent requirements in Lean 4 | [Phase 2](docs/aidlc/PHASE-2.md) |
| 3 | FLIGHT MANIFEST | Translate requirements into executable tests | [Phase 3](docs/aidlc/PHASE-3.md) |
| 4 | IGNITION | Implement the production change | [Phase 4](docs/aidlc/PHASE-4.md) |
| 5 | TELEMETRY | Model the implementation as built | [Phase 5](docs/aidlc/PHASE-5.md) |
| 6 | RENDEZVOUS | Prove model satisfaction and establish code/model conformance | [Phase 6](docs/aidlc/PHASE-6.md) |
| 7 | LANDING MODULE | Perform adversarial and environment-specific validation | [Phase 7](docs/aidlc/PHASE-7.md) |
| 8 | SPLASHDOWN | Finalize evidence, rollout, integration, and close-out | [Phase 8](docs/aidlc/PHASE-8.md) |

## Universal gates

The following rules apply to every tier and phase.

### Phase completion is explicit

A phase is complete only when:

- its required artifacts exist;
- its exit criteria are satisfied;
- blocking findings are closed or formally accepted;
- the authorized reviewer records the phase as exited.

Elapsed time, test count, model-run count, or approval of a related decision does not imply phase completion.

### Non-vacuity is required

A conditional requirement MUST have evidence that its precondition is reachable or inhabited.

A property that passes only because its antecedent is unreachable MUST NOT count as satisfied.

### Claims must match evidence

Evidence about a model is not automatically evidence about production code.

For example:

- a solver result concerns its encoding and bounds;
- a TLA+ result concerns its specification and configuration;
- a Lean proof concerns the Lean terms and assumptions;
- a test result concerns the tested implementation, generated inputs, and runtime;
- a production measurement concerns the measured environment and time.

### Known counterexamples require disposition

A known counterexample to a normative requirement MUST be:

1. fixed;
2. excluded by an explicit and enforced assumption;
3. resolved by changing and ratifying the requirement; or
4. accepted through an authorized residual-risk decision.

It MUST NOT remain an informational caveat in a completed phase.

### Changes may reopen earlier phases

A substantive change to a requirement, assumption, transition, quantification domain, implementation, migration, or deployment rule MUST follow [Change Control](docs/aidlc/CHANGE-CONTROL.md).

### Traceability is maintained continuously

Traceability is not a Phase 8 documentation exercise. It MUST be updated when the linked artifacts change.

See [Traceability](docs/aidlc/TRACEABILITY.md).

## Starting a task

1. Create the task charter.
2. Select and ratify the rigor tier.
3. Create the phase status record.
4. Read the first required phase file.
5. Produce the required artifacts.
6. Record phase exit before proceeding through a gated boundary.

Draft artifacts MAY be prepared early. A later phase MUST NOT be treated as authoritative before its prerequisites have exited.
```

# `docs/aidlc/GOVERNANCE.md`

```markdown
# AIDLC Governance

## Normative language

The terms **MUST**, **MUST NOT**, **SHOULD**, and **MAY** are normative.

- **MUST** and **MUST NOT** define mandatory process requirements.
- **SHOULD** defines a strong default. A departure requires recorded rationale.
- **MAY** defines an optional practice.

## Governing principles

### Separate the objects of evidence

AIDLC distinguishes:

- requirements;
- specification models;
- production implementations;
- implementation models;
- tests;
- proofs;
- operational measurements.

A result about one object MUST NOT be presented as a result about another without correspondence evidence.

### Name the evidence type

Technical findings SHOULD be classified as:

- **formal check** — proof-assistant or solver verdict;
- **model run** — state-space or transition-system execution;
- **test run** — execution against implementation code;
- **measured** — operational or production measurement;
- **code read** — source inspection without execution;
- **claim** — reasoning not directly executed;
- **decision** — approved business or technical direction.

Executable evidence MUST record applicable versions, configuration, bounds, environment, commands, and artifact hashes.

### Distinguish status

The following statuses are separate:

- **Proposed** — authored but not accepted.
- **Decided** — a design or business choice is approved.
- **Ratified requirement** — intended behavior is approved.
- **Model-complete** — the required behavior is represented faithfully.
- **Phase-exited** — all phase exit criteria are satisfied.
- **Implementation-authorized** — implementation may proceed.
- **Verified within bounds** — a named relation holds within stated bounds.
- **Released** — the change has been deployed.

A requirement decision does not establish model completeness. Model completeness does not establish implementation correctness.

## Roles

Each task MUST identify:

- **Task owner** — coordinates the work and maintains task status.
- **Decision authority** — ratifies requirements and accepts residual risk.
- **Technical authority** — ratifies the tier and phase exits.
- **Implementer** — changes production artifacts.
- **Reviewer** — independently reviews evidence and implementation.

One person MAY hold multiple roles for low-risk work. Tier 3 work SHOULD separate implementer and final reviewer.

## Tier and phase authority

The task owner proposes the tier. The technical authority ratifies it.

Each phase exit MUST identify its approving authority.

A phase MUST NOT be marked exited by implication or by an agent acting without the authority assigned in the task charter.

## Exceptions

An exception to a mandatory requirement MUST record:

- the requirement being waived;
- why it cannot or should not be met;
- compensating controls;
- affected claims;
- expiration or review condition;
- approving authority.

An exception changes the permitted process claim. It does not make missing evidence exist.

## Non-vacuity

For conditional or population-filtered properties, acceptable anti-vacuity evidence includes:

- a reachable witness;
- an inhabited precondition;
- a concrete fixture;
- an antecedent-presence check;
- a negative control;
- mutation or deletion testing.

Vacuous results MAY be retained in the evidence ledger but MUST NOT discharge a requirement.

## Counterexamples

A known counterexample blocks the affected phase unless it is:

- fixed;
- shown unreachable under an enforced assumption;
- resolved by a ratified requirement change; or
- accepted as residual risk by the decision authority.

## Approved claim wording

Preferred wording includes:

- “TLC reported no violation under configuration X.”
- “The solver reported UNSAT under assumptions A and bounds B.”
- “The Lean declaration type-checks with `sorry`.”
- “The Lean implementation model satisfies requirement R.”
- “The production implementation matched the implementation model over domain D.”
- “The production query returned zero matching rows at time T.”

The following claims require stronger evidence than a model result alone:

- “The system is proven correct.”
- “The implementation is formally verified.”
- “The migration cannot fail.”
- “The requirement is proven” when its declaration contains `sorry`.
- “The property holds” when its antecedent was not reached.

## Phase-status reporting

Every task MUST maintain a phase status record using:

- `templates/PHASE-STATUS.md`

A phase exit record MUST contain:

- phase;
- artifact versions;
- satisfied exit criteria;
- remaining non-blocking risks;
- approving authority;
- approval date.
```

# `docs/aidlc/TIERS.md`

```markdown
# AIDLC Tiers

## Selection rule

Select a tier based on the task's complexity and potential harm, not the desired development speed.

The selected tier MUST be recorded in the task charter and ratified by the technical authority.

A tier MAY be raised at any time.

A tier MUST NOT be lowered after work begins without:

- written rationale;
- disposition of evidence indicating higher risk;
- approval from the technical authority.

## Tier 0 — TOUCHDOWN

### Scope

Simple, low-risk changes that can be specified in prose and verified empirically.

### Required phases

- Phase 3 — requirement-derived tests;
- Phase 4 — implementation;
- Phase 7 — adversarial and end-to-end validation;
- Phase 8 — close-out.

### Requirements source

Ratified prose requirements.

### Typical examples

- isolated presentation changes;
- simple validation;
- low-risk API behavior;
- localized defects with a clear cause and no significant state interaction.

## Tier 1 — FLYBY

### Scope

Tier 0 work with a bounded logical or combinatorial problem requiring SAT/SMT exploration.

### Required phases

Tier 0 plus:

- Phase 0 — logical exploration.

### Typical examples

- rule-set contradictions;
- bounded assignment problems;
- logical precondition analysis;
- identification of a discriminating root cause.

## Tier 2 — TRAJECTORY

### Scope

Work requiring explicit state-transition, ordering, concurrency, or deployment modeling.

### Required phases

Tier 1 plus:

- Phase 1 — TLA+ specification model.

Lean modeling is not required.

### Typical examples

- workflows with multiple states;
- concurrent updates;
- retry or restart behavior;
- partial deployment;
- migrations whose intermediate states affect correctness.

## Tier 3 — RENDEZVOUS

### Scope

High-risk or high-complexity work requiring the full formal pipeline.

### Required phases

Phases 0 through 8.

### Escalation indicators

Tier 3 SHOULD be selected when the task involves combinations of:

- identity resolution;
- security or privacy;
- financial, legal, or compliance impact;
- irreversible data loss;
- destructive migration;
- nontrivial concurrency;
- multiple coupled state machines;
- partial-deployment risk;
- inability to distinguish safe and unsafe states from available data;
- a history of local fixes causing non-local regressions.

## Tier exit conditions

A task completes its tier only when all required phases have exited.

A lower tier MUST NOT claim evidence produced only by a higher tier. For example, Tier 0 test success is not formal verification.
```

# `docs/aidlc/PHASE-0.md`

```markdown
# Phase 0 — FLYBY: Logical Exploration

## Objective

Establish the logical shape of the problem and identify at least one verifiable root cause before committing to a transition-system specification.

## Required for

Tiers 1, 2, and 3.

## Inputs

- task charter;
- known incidents or counterexamples;
- candidate requirements;
- available code and data evidence.

## Required artifacts

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

## Rules

A SAT result establishes existence only within the encoded domain.

An UNSAT result establishes absence only within the encoding, assumptions, and bounds.

An UNSAT result MUST NOT be credited to an intended requirement unless deleting or weakening that requirement changes the result as expected.

A check that asserts its own conclusion is non-discriminating and MUST NOT support that conclusion.

Conditional findings MUST include evidence that their antecedents are satisfiable.

## Exit criteria

Phase 0 exits when:

- the logical vocabulary is stable enough for the next required activity;
- at least one root cause has discriminating evidence;
- assumptions and bounds are recorded;
- non-discriminating checks are identified;
- known contradictions have an owner;
- candidate requirements are stated without claiming implementation sufficiency;
- blocking counterexamples are dispositioned or carried forward explicitly.

## Permitted conclusion

“Phase 0 bounded the logical problem and identified the recorded root cause under the stated encoding and assumptions.”

Phase 0 does not prove that a production implementation is correct.
```

# `docs/aidlc/PHASE-1.md`

```markdown
# Phase 1 — TRAJECTORY / ANGLING: Specification Model

## Objective

Build an implementation-independent TLA+ specification of required states, transitions, invariants, and applicable liveness properties.

## Required for

Tiers 2 and 3.

## Inputs

- exited Phase 0 artifacts;
- ratified requirements and decisions;
- known counterexamples;
- deployment and concurrency concerns.

## Required artifacts

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

## Completeness rules

The model MUST represent:

- every normative in-scope transition;
- load-bearing failure and fail-closed paths;
- relevant concurrency or an enforced assumption excluding it;
- relevant retry, restart, and ordering behavior;
- partial deployment states that can affect correctness;
- migration intermediate states when they affect correctness;
- normal and exceptional outcomes.

A total model operation MUST NOT stand in for partial production behavior unless totality is enforced by the design.

Every credited property MUST have a reachable scenario that exercises its antecedent.

Known model defects or contradictions MUST be resolved, excluded by enforced assumptions, or accepted explicitly.

## Exit criteria

Phase 1 exits when:

- every ratified in-scope behavior maps to a modeled action or property;
- all required transitions and frame conditions are represented;
- relevant safety and liveness properties are represented;
- credited properties are non-vacuous;
- model runs reproduce from committed artifacts;
- assumptions and abstractions are approved;
- no known counterexample remains without disposition;
- the specification coverage matrix is complete;
- the technical authority records the phase exit.

A high model-run count does not compensate for a missing transition.
```

# `docs/aidlc/PHASE-2.md`

```markdown
# Phase 2 — SIMULATION: Lean Requirements Model

## Objective

State implementation-independent requirements as well-typed Lean 4 propositions.

## Required for

Tier 3.

## Inputs

- exited Phase 1 specification;
- ratified requirements;
- specification coverage matrix;
- approved assumptions.

## Nature of the artifact

Phase 2 defines what must be true. It MUST NOT prescribe implementation strategy unless that strategy is itself a ratified requirement.

Proof bodies MAY use `sorry`.

A declaration containing `sorry` is admitted and type-checked. It is not proven. Documentation MUST describe it as a well-typed or admitted requirement.

## Required artifacts

- Lean requirements model;
- requirement inventory;
- inventory of every `sorry`;
- quantification review;
- anti-vacuity evidence;
- TLA+-to-Lean traceability;
- planned test mapping.

## Requirement rules

Each requirement MUST:

- map to a ratified requirement;
- map to a Phase 1 action or property;
- quantify over the intended domain;
- state assumptions explicitly;
- represent applicable normal, exceptional, and fail-closed outcomes;
- include relevant frame conditions;
- have an inhabited or reachable precondition;
- avoid accidental dependence on an implementation mechanism.

The model MUST NOT use an empty domain, unreachable antecedent, `False`, or an equivalent construction to satisfy a requirement unintentionally.

## Exit criteria

Phase 2 exits when:

- every in-scope requirement is represented;
- all declarations type-check;
- every `sorry` is inventoried;
- quantification has been reviewed;
- every conditional requirement has anti-vacuity evidence;
- the traceability matrix is complete;
- requirements do not accidentally prescribe implementation;
- the requirements authority ratifies the artifact.
```

# `docs/aidlc/PHASE-3.md`

```markdown
# Phase 3 — FLIGHT MANIFEST: Property-Test Generation

## Objective

Translate requirements into executable tests before implementing the production behavior.

## Required for

All tiers.

## Requirements source

| Tier | Source |
|---|---|
| 0 | Ratified prose requirements |
| 1 | Prose requirements informed by Phase 0 |
| 2 | Requirements traced to the Phase 1 specification |
| 3 | Phase 2 Lean requirements |

## Required artifacts

- requirement-to-test inventory;
- property tests;
- example tests where properties are unsuitable;
- generators and shrinkers;
- fixtures;
- exceptional-path tests;
- test bounds and runtime assumptions;
- negative-control or mutation results.

## Rules

Every normative requirement MUST map to at least one executable test unless an exception is approved.

Tests MUST demonstrate that they distinguish relevant broken behavior through at least one of:

- a known-broken baseline;
- a disabled feature;
- a code mutation;
- a generated counterexample;
- a deleted or weakened guard.

Tests MUST cover applicable:

- normal behavior;
- exceptional and fail-closed behavior;
- empty and singleton inputs;
- multiple related entities;
- historical or malformed data;
- retry and restart behavior;
- partial deployment;
- relevant concurrency.

Implementation behavior MUST NOT become the source of expected test results.

## Exit criteria

Phase 3 exits when:

- every requirement maps to an executable test or approved exception;
- generators reach the relevant preconditions;
- negative controls fail as expected;
- test bounds are recorded;
- tests distinguish at least one representative broken behavior;
- the traceability matrix is current.
```

# `docs/aidlc/PHASE-4.md`

```markdown
# Phase 4 — IGNITION: Implementation

## Objective

Implement the production change against the Phase 3 tests.

## Required for

All tiers.

## Inputs

- exited Phase 3 tests;
- current requirements;
- applicable rollout and migration constraints.

## Required artifacts

- production code;
- schema and migration changes;
- implementation decision records;
- feature flags where required;
- rollout and rollback mechanisms;
- passing test results;
- updated traceability.

## Rules

The implementation MUST NOT redefine a requirement to match existing code.

An ambiguity or contradiction discovered during implementation MUST follow change control and return to the earliest affected phase.

Migration and schema work MUST define applicable:

- preflight checks;
- transaction and concurrency behavior;
- treatment of zero, one, and multiple matches;
- interruption and restart behavior;
- rollback behavior;
- data-repair ownership;
- observability.

Security- or privacy-sensitive changes MUST define applicable authorization, masking, retention, disclosure, and audit behavior.

## Exit criteria

Phase 4 exits when:

- Phase 3 tests pass;
- negative controls remain discriminating;
- migration rehearsals pass where applicable;
- rollout and rollback mechanisms exist;
- normal engineering checks pass;
- implementation decisions are recorded;
- no unresolved requirement ambiguity remains.

Passing tests permits progression. It does not constitute formal verification.
```

# `docs/aidlc/PHASE-5.md`

```markdown
# Phase 5 — TELEMETRY: Implementation Model

## Objective

Model the implementation as built and establish evidence that the model corresponds to production behavior.

## Required for

Tier 3.

## Inputs

- exited Phase 4 implementation;
- Phase 2 requirements model;
- implementation code and tests.

## Required artifacts

- Lean 4 implementation model;
- code-to-model correspondence map;
- abstraction and assumption register;
- differential or conformance tests;
- inventory of unmodeled implementation behavior.

## Correspondence rules

The implementation model MUST NOT be considered accurate merely because it was written after the code.

Each modeled operation MUST map to applicable:

- production methods;
- input transformations;
- state reads and writes;
- exceptions and fail-closed behavior;
- transaction boundaries;
- persistence behavior;
- concurrency boundaries.

Conformance evidence MAY include:

- differential tests between production code and model;
- generated tests from a shared state representation;
- bounded exhaustive comparison;
- transition instrumentation;
- reviewed semantic correspondence;
- extraction from a shared executable model.

The strength of the final claim MUST match the strength and bounds of this evidence.

## Exit criteria

Phase 5 exits when:

- the implementation model type-checks;
- modeled operations map to production code;
- exceptional and fail-closed behavior is represented;
- conformance evidence passes within stated bounds;
- unmodeled behavior is added or explicitly accepted;
- no known implementation behavior contradicts the requirements model.
```

# `docs/aidlc/PHASE-6.md`

```markdown
# Phase 6 — RENDEZVOUS: Satisfaction and Conformance

## Objective

Establish two distinct obligations:

1. the Lean implementation model satisfies the Lean requirements model;
2. the production implementation conforms to the implementation model within a stated boundary.

## Required for

Tier 3.

## Obligation A — Model satisfaction

Every applicable Phase 2 requirement MUST be discharged against the Phase 5 implementation model.

Any approved Lean tactic or proof term MAY be used.

Unapproved `sorry` declarations MUST NOT remain in the satisfaction layer.

## Obligation B — Implementation conformance

Code-to-model evidence MUST establish agreement over the defined:

- inputs;
- outputs;
- state transitions;
- exceptional behavior;
- persistence effects;
- concurrency boundary.

If conformance evidence is bounded or empirical, the conclusion MUST remain bounded or empirical.

## Proof-complexity rule

A disproportionately convoluted proof is a diagnostic signal.

Reviewers MUST examine:

- whether the requirement is correct;
- whether quantification is correct;
- whether the implementation model matches the code;
- whether hidden assumptions carry the proof;
- whether implementation complexity should be reduced.

A technical proof pass does not remove the need for this review.

## Required artifacts

- satisfaction proofs;
- proof-assumption inventory;
- conformance results;
- bounds and limitations;
- requirement-to-proof mapping;
- unresolved-obligation inventory.

## Exit criteria

Phase 6 exits when:

- every requirement has a completed satisfaction proof;
- no unapproved `sorry` remains in the satisfaction layer;
- conformance checks pass;
- assumptions and bounds are documented;
- all unresolved obligations are closed or explicitly excepted;
- no correctness claim exceeds the established relation.

## Permitted conclusion

“The Lean implementation model satisfies the Lean requirements model, and the production implementation conforms to the implementation model within the stated conformance boundary.”
```

# `docs/aidlc/PHASE-7.md`

```markdown
# Phase 7 — LANDING MODULE: Adversarial Validation

## Objective

Probe assumptions, edge cases, and platform behavior that may lie outside the formal models or primary implementation tests.

## Required for

All tiers.

## Required review areas

Exercise the applicable areas:

- concurrency and races;
- retries, restarts, and duplicate execution;
- partial deployment;
- migration interruption and rollback;
- database constraints and transaction behavior;
- ORM and framework semantics;
- serialization and formatting;
- authorization and privacy;
- historical, malformed, and unexpected data;
- performance and operational load;
- external-system behavior;
- observability and operator remediation;
- appropriate end-to-end system boundaries.

End-to-end verification MAY use:

- Playwright for browser workflows;
- API-level tests;
- worker or job execution;
- message-consumer tests;
- migration rehearsal;
- command-line or process tests.

## Independence

Phase 7 SHOULD be authored or reviewed by someone other than the implementer.

Tests SHOULD include domain- and platform-derived concerns that were not copied directly from the formal requirements.

## Finding classification

Each finding MUST be classified as:

- requirement defect;
- specification-model defect;
- implementation defect;
- implementation-model defect;
- conformance defect;
- test defect;
- accepted residual risk;
- out of scope with a follow-up owner.

Blocking findings return the task to the earliest affected phase.

## Exit criteria

Phase 7 exits when:

- applicable adversarial areas have been exercised;
- end-to-end verification passes;
- findings are classified and dispositioned;
- blocking findings are closed;
- operational and performance effects are accepted;
- no open finding contradicts a normative requirement.
```

# `docs/aidlc/PHASE-8.md`

```markdown
# Phase 8 — SPLASHDOWN: Close-Out and Integration

## Objective

Finalize the normative artifacts and evidence, authorize rollout, create or finalize the pull request, and prepare post-deployment verification.

## Required for

All tiers.

## Required headline artifacts

The following human-facing artifacts MUST be current:

1. final normative specification;
2. final decision register.

These artifacts SHOULD use ASD-STE100 principles where practical:

- short, direct sentences;
- consistent terminology;
- one instruction or requirement per sentence;
- explicit subjects and conditions;
- no avoidable ambiguity.

## Additional required artifacts

As applicable:

- completed traceability matrix;
- phase-exit records;
- residual-risk register;
- rollout plan;
- rollback plan;
- migration plan;
- monitoring plan;
- data-repair plan;
- pull request;
- post-deployment verification checklist.

## Rollout-plan requirements

The rollout plan MUST identify applicable:

- deployable units;
- schema compatibility order;
- feature-flag order;
- migration and backfill order;
- required locking or quiescence;
- preflight checks;
- activation checks;
- rollback points;
- bridge-removal criteria;
- post-deployment monitors;
- responsible operators.

A dependency graph alone is not a rollout plan.

## Pull requests

A draft pull request MAY be used as a non-integrating workspace before Phase 8.

A pull request MUST NOT be approved for integration until all required phase gates have exited.

## Exit criteria

Phase 8 exits when:

- all required prior phases have exited;
- final artifacts are internally consistent;
- residual risks are approved;
- rollout and rollback have owners;
- the pull request is reviewed and approved;
- deployment authorization is recorded;
- post-deployment verification is scheduled.
```

# `docs/aidlc/TRACEABILITY.md`

```markdown
# AIDLC Traceability

## Purpose

Traceability connects the reason for a change to the evidence supporting its implementation.

Traceability MUST be maintained during development. It MUST NOT be reconstructed only at close-out.

## Traceability chain

The complete Tier 3 chain is:

> decision → specification → requirement → test → implementation → implementation model → proof → conformance evidence → adversarial validation

Lower tiers maintain the applicable subset.

## Required identifiers

Normative artifacts SHOULD use stable identifiers for:

- decisions;
- requirements;
- assumptions;
- specification actions;
- properties and invariants;
- tests;
- implementation units;
- proofs;
- findings;
- residual risks.

Renaming an identifier MUST preserve a record of the old identifier when external references exist.

## Required matrices

### Tier 0

| Requirement | Tests | Implementation | Phase 7 validation |
|---|---|---|---|

### Tier 1

Add Phase 0 findings and logical checks.

### Tier 2

Add TLA+ actions, properties, assumptions, and non-vacuity witnesses.

### Tier 3

Use the complete end-to-end matrix in:

- `templates/TRACEABILITY-MATRIX.md`

## Non-vacuity traceability

Each conditional property MUST link to at least one:

- antecedent witness;
- reachable scenario;
- fixture;
- negative control;
- mutation or deletion probe.

## Evidence metadata

Formal checks, model runs, tests, and measurements SHOULD record:

- artifact version or commit;
- tool version;
- configuration;
- command;
- bounds;
- environment;
- expected result;
- actual result;
- date;
- evidence owner.

## Blank cells

A blank load-bearing traceability cell blocks the applicable phase exit.

A cell MAY contain:

- a direct artifact reference;
- “Not applicable” with rationale;
- an approved exception reference.

It MUST NOT be left ambiguous.

## Artifact separation

Complex tasks SHOULD separate:

- **normative specification** — current requirements;
- **decision register** — approved choices and rationale;
- **evidence ledger** — checks, runs, measurements, and limitations;
- **historical changelog** — superseded material;
- **traceability matrix** — relationships among current artifacts.

Superseded requirements MUST NOT remain in the current normative specification.
```

# `docs/aidlc/CHANGE-CONTROL.md`

```markdown
# AIDLC Change Control

## Purpose

Changes discovered in later phases can invalidate earlier assumptions and downstream artifacts.

AIDLC requires returning to the earliest affected phase rather than patching only the latest artifact.

## Substantive changes

The following changes require impact analysis:

- requirement;
- business or technical decision;
- assumption;
- quantification domain;
- state variable;
- state transition;
- concurrency rule;
- failure behavior;
- migration rule;
- deployment unit or order;
- implementation behavior;
- implementation-model correspondence;
- accepted risk.

Editorial changes that do not change meaning do not require phase re-entry.

## Required change record

A substantive change MUST record:

1. changed artifact;
2. reason for the change;
3. new evidence or decision;
4. earliest affected phase;
5. invalidated downstream artifacts;
6. required reruns and reviews;
7. approving authority;
8. completion status.

## Re-entry examples

| Discovery | Typical return point |
|---|---|
| New logical counterexample | Phase 0 |
| Missing state transition | Phase 1 |
| Incorrect requirement or quantification | Phase 2 or earlier |
| Missing or non-discriminating test | Phase 3 |
| Implementation defect | Phase 4 |
| Code/model mismatch | Phase 5 |
| Failed satisfaction proof | Phase 2, 4, or 5 depending on cause |
| Platform-specific defect | Earliest phase containing the cause |
| Rollout incompatibility | Phase 1, 4, or 8 depending on cause |

## Downstream invalidation

When a phase is reopened:

- affected downstream phase exits MUST be marked invalidated;
- affected artifacts MUST be regenerated or re-reviewed;
- unaffected evidence MAY remain valid if the change record explains why;
- superseded evidence MAY remain in the evidence ledger as historical evidence;
- superseded normative text MUST be removed from the current specification.

## Counterexamples

A counterexample MUST NOT be resolved only by weakening a test or model.

Resolution requires one of:

- correct the requirement;
- correct the model;
- correct the implementation;
- enforce an assumption that excludes the counterexample;
- accept the counterexample as residual risk through the decision authority.

## Emergency changes

An emergency change MAY use an approved process exception.

The exception MUST define:

- omitted activities;
- immediate compensating controls;
- affected claims;
- required retrospective phases;
- completion deadline;
- approving authority.

Emergency status postpones required evidence. It does not create that evidence.
```

# `docs/aidlc/templates/TASK-CHARTER.md`

```markdown
# AIDLC Task Charter

## Task identity

- **Task ID:**
- **Title:**
- **Task owner:**
- **Decision authority:**
- **Technical authority:**
- **Implementer:**
- **Reviewer:**

## Problem

Describe the problem, affected users, and observed harm.

## Scope

### In scope

-

### Out of scope

-

## Affected systems and data

-

## Risk assessment

| Risk area | Applicable? | Description |
|---|---:|---|
| Identity |  |  |
| Security |  |  |
| Privacy |  |  |
| Financial |  |  |
| Legal or compliance |  |  |
| Irreversible data loss |  |  |
| Schema or data migration |  |  |
| Concurrency |  |  |
| Distributed systems |  |  |
| Partial deployment |  |  |
| Historical-data compatibility |  |  |
| Operational recovery |  |  |

## Reversibility

Describe how the change can be disabled, rolled back, or repaired.

## Proposed tier

- **Tier:**
- **Rationale:**
- **Required phases:**
- **Escalation conditions:**

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

- **Tier ratified by:**
- **Date:**
- **Conditions or exceptions:**
```

# `docs/aidlc/templates/PHASE-STATUS.md`

```markdown
# AIDLC Phase Status

## Task

- **Task ID:**
- **Current tier:**
- **Last updated by:**
- **Last updated:**

## Status

Use:

- Not required
- Not started
- Active
- Blocked
- Exited
- Reopened
- Invalidated

| Phase | Required? | Status | Owner | Blocking items | Exit record |
|---|---:|---|---|---|---|
| 0 — FLYBY |  |  |  |  |  |
| 1 — TRAJECTORY / ANGLING |  |  |  |  |  |
| 2 — SIMULATION |  |  |  |  |  |
| 3 — FLIGHT MANIFEST |  |  |  |  |  |
| 4 — IGNITION |  |  |  |  |  |
| 5 — TELEMETRY |  |  |  |  |  |
| 6 — RENDEZVOUS |  |  |  |  |  |
| 7 — LANDING MODULE |  |  |  |  |  |
| 8 — SPLASHDOWN |  |  |  |  |  |

## Current blocking items

| ID | Phase | Finding | Owner | Required disposition |
|---|---|---|---|---|

## Phase exit record

Create one section for each exited phase.

### Phase N — Name

- **Artifact versions:**
- **Exit criteria satisfied:**
- **Evidence references:**
- **Non-blocking residual risks:**
- **Exceptions:**
- **Approved by:**
- **Approval date:**

## Re-entry record

- **Reopened phase:**
- **Reason:**
- **Change-control record:**
- **Invalidated downstream exits:**
- **Approved by:**
- **Date:**
```

# `docs/aidlc/templates/TRACEABILITY-MATRIX.md`

```markdown
# AIDLC Traceability Matrix

## Task

- **Task ID:**
- **Tier:**
- **Artifact version:**
- **Last updated:**

## Decision and requirement inventory

| Requirement ID | Requirement | Decision source | Status | Assumptions | Residual risk |
|---|---|---|---|---|---|

## Specification coverage

Required for Tiers 2 and 3.

| Requirement ID | TLA+ action or operator | Property or invariant | Scenario | Antecedent witnessed? | Known counterexample | Disposition |
|---|---|---|---|---:|---|---|

## Lean requirements

Required for Tier 3.

| Requirement ID | Lean declaration | Quantification reviewed? | Assumptions | Non-vacuity witness | `sorry` inventoried? |
|---|---|---:|---|---|---:|

## Tests and implementation

Required for all tiers.

| Requirement ID | Property or example tests | Negative control | Production code | Migration or configuration | Phase 7 checks |
|---|---|---|---|---|---|

## Formal satisfaction and conformance

Required for Tier 3.

| Requirement ID | Implementation-model term | Satisfaction proof | Code/model mapping | Conformance evidence | Bounds |
|---|---|---|---|---|---|

## Findings

| Finding ID | Evidence type | Affected requirement | Earliest affected phase | Classification | Disposition | Owner |
|---|---|---|---|---|---|---|

## Evidence metadata

| Evidence ID | Artifact or command | Version/hash | Tool and version | Configuration/bounds | Expected result | Actual result | Date |
|---|---|---|---|---|---|---|---|
```

# AI Development Life Cycle

## Purpose

The AI Development Life Cycle (AIDLC) governs AI-assisted software changes.

AIDLC separates:

1. what the system must do;
2. how required behavior is modeled;
3. what the production implementation does;
4. how the implementation is verified;
5. what evidence supports each claim.

The process contains nine phases, FLYBY through SPLASHDOWN. The task's rigor tier determines which phases are required.

## File location

This file and everything it references live under `{{AIDLC_ROOT}}`. Every path below is given as an absolute path under that root, e.g. `{{AIDLC_ROOT}}/docs/aidlc/GOVERNANCE.md`. Read files there directly with the file-reading tool; do not treat these as paths relative to the current project.

## Agent instructions

An agent working under AIDLC MUST:

1. Read [Governance]({{AIDLC_ROOT}}/docs/aidlc/GOVERNANCE.md) before making claims, approving decisions, recording evidence, or exiting a phase.
2. Read [Tiers]({{AIDLC_ROOT}}/docs/aidlc/TIERS.md) before selecting or changing a task's rigor tier.
3. Read the file for the current phase (see the Phases table below) before producing or modifying that phase's artifacts.
4. Read [Traceability]({{AIDLC_ROOT}}/docs/aidlc/TRACEABILITY.md) when creating or changing a requirement, model property, test, implementation, proof, or validation result.
5. Read [Change Control]({{AIDLC_ROOT}}/docs/aidlc/CHANGE-CONTROL.md) when evidence contradicts an existing artifact or when an approved requirement, assumption, model, test, or implementation changes.
6. Use the templates under `{{AIDLC_ROOT}}/docs/aidlc/templates/` when starting or updating an AIDLC task.

An agent MUST NOT read every supporting file automatically if the current task does not require it. The agent SHOULD read only this file, the universal files identified below, and the files relevant to the current phase and tier.

If the task has no charter or selected tier, the agent MUST begin with the task charter rather than implementation.

## Required reading by activity

| Activity | Files to read |
|---|---|
| Start or classify a task | `{{AIDLC_ROOT}}/AIDLC.md`, `{{AIDLC_ROOT}}/docs/aidlc/GOVERNANCE.md`, `{{AIDLC_ROOT}}/docs/aidlc/TIERS.md`, `{{AIDLC_ROOT}}/docs/aidlc/templates/TASK-CHARTER.md` |
| Report task status | `{{AIDLC_ROOT}}/docs/aidlc/GOVERNANCE.md`, `{{AIDLC_ROOT}}/docs/aidlc/templates/PHASE-STATUS.md` |
| Explore a logical problem | `{{AIDLC_ROOT}}/docs/aidlc/PHASE-0.md`, `{{AIDLC_ROOT}}/docs/aidlc/TRACEABILITY.md` |
| Model state or transitions | `{{AIDLC_ROOT}}/docs/aidlc/PHASE-1.md`, `{{AIDLC_ROOT}}/docs/aidlc/TRACEABILITY.md` |
| Write Lean requirements | `{{AIDLC_ROOT}}/docs/aidlc/PHASE-2.md`, `{{AIDLC_ROOT}}/docs/aidlc/TRACEABILITY.md` |
| Generate requirement-derived tests | `{{AIDLC_ROOT}}/docs/aidlc/PHASE-3.md`, `{{AIDLC_ROOT}}/docs/aidlc/TRACEABILITY.md` |
| Implement production behavior | `{{AIDLC_ROOT}}/docs/aidlc/PHASE-4.md`, `{{AIDLC_ROOT}}/docs/aidlc/CHANGE-CONTROL.md` |
| Model the implementation | `{{AIDLC_ROOT}}/docs/aidlc/PHASE-5.md`, `{{AIDLC_ROOT}}/docs/aidlc/TRACEABILITY.md` |
| Prove model satisfaction | `{{AIDLC_ROOT}}/docs/aidlc/PHASE-6.md`, `{{AIDLC_ROOT}}/docs/aidlc/TRACEABILITY.md` |
| Perform adversarial review | `{{AIDLC_ROOT}}/docs/aidlc/PHASE-7.md`, `{{AIDLC_ROOT}}/docs/aidlc/CHANGE-CONTROL.md` |
| Prepare integration or rollout | `{{AIDLC_ROOT}}/docs/aidlc/PHASE-8.md`, `{{AIDLC_ROOT}}/docs/aidlc/GOVERNANCE.md` |
| Change an approved artifact | `{{AIDLC_ROOT}}/docs/aidlc/CHANGE-CONTROL.md`, `{{AIDLC_ROOT}}/docs/aidlc/TRACEABILITY.md` |
| Make a formal-correctness claim | `{{AIDLC_ROOT}}/docs/aidlc/GOVERNANCE.md`, `{{AIDLC_ROOT}}/docs/aidlc/PHASE-6.md` |

## Universal artifacts

Every task MUST maintain:

- a [task charter]({{AIDLC_ROOT}}/docs/aidlc/templates/TASK-CHARTER.md);
- a [phase status record]({{AIDLC_ROOT}}/docs/aidlc/templates/PHASE-STATUS.md);
- traceability appropriate to its tier;
- a record of blocking findings and their dispositions.

## Tiers

AIDLC defines three rigor tiers — none, some, all:

| Tier | Required phases |
|---|---|
| 0 — WIFFLED | FLIGHT MANIFEST, IGNITION, LANDING MODULE, SPLASHDOWN |
| 1 — AIMED | WIFFLED plus at least one selected technique-pair (see [Tiers]({{AIDLC_ROOT}}/docs/aidlc/TIERS.md)) |
| 2 — POKAYOKE | FLYBY through SPLASHDOWN — all nine phases |

See [Tiers]({{AIDLC_ROOT}}/docs/aidlc/TIERS.md) for selection, AIMED's technique-pairs, and escalation rules.

## Phases

| Phase | Purpose | Detailed rules |
|---|---|---|
| 0 — FLYBY | Explore the logical problem using SAT/SMT or equivalent analysis | [FLYBY]({{AIDLC_ROOT}}/docs/aidlc/PHASE-0.md) |
| 1 — TRAJECTORY / ANGLING | Specify states, transitions, invariants, and liveness properties | [TRAJECTORY / ANGLING]({{AIDLC_ROOT}}/docs/aidlc/PHASE-1.md) |
| 2 — SIMULATION | State implementation-independent requirements in Lean 4 | [SIMULATION]({{AIDLC_ROOT}}/docs/aidlc/PHASE-2.md) |
| 3 — FLIGHT MANIFEST | Translate requirements into executable tests | [FLIGHT MANIFEST]({{AIDLC_ROOT}}/docs/aidlc/PHASE-3.md) |
| 4 — IGNITION | Implement the production change | [IGNITION]({{AIDLC_ROOT}}/docs/aidlc/PHASE-4.md) |
| 5 — TELEMETRY | Model the implementation as built | [TELEMETRY]({{AIDLC_ROOT}}/docs/aidlc/PHASE-5.md) |
| 6 — RENDEZVOUS | Prove model satisfaction and establish code/model conformance | [RENDEZVOUS]({{AIDLC_ROOT}}/docs/aidlc/PHASE-6.md) |
| 7 — LANDING MODULE | Perform adversarial and environment-specific validation | [LANDING MODULE]({{AIDLC_ROOT}}/docs/aidlc/PHASE-7.md) |
| 8 — SPLASHDOWN | Finalize evidence, rollout, integration, and close-out | [SPLASHDOWN]({{AIDLC_ROOT}}/docs/aidlc/PHASE-8.md) |

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

A substantive change to a requirement, assumption, transition, quantification domain, implementation, migration, or deployment rule MUST follow [Change Control]({{AIDLC_ROOT}}/docs/aidlc/CHANGE-CONTROL.md).

### Traceability is maintained continuously

Traceability is not a SPLASHDOWN documentation exercise. It MUST be updated when the linked artifacts change.

See [Traceability]({{AIDLC_ROOT}}/docs/aidlc/TRACEABILITY.md).

### Good Specifications Often Usher in Good questions

New discoveries are part of the specification process. Be thorough. Chase down every possibility and surface design-level questions or contradictions to humans.

## Starting a task

1. Create the task charter.
2. Select and ratify the rigor tier.
3. Create the phase status record.
4. Read the first required phase file.
5. Produce the required artifacts.
6. Record phase exit before proceeding through a gated boundary.

Draft artifacts MAY be prepared early. A later phase MUST NOT be treated as authoritative before its prerequisites have exited.

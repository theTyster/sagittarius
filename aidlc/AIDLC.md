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

## Rule Name: SPECVER — The Two Most Important Rules

`SPECVER` is the constitution. No rule below it may override it.

### SPECVER.1 — Humans specify requirements.

### SPECVER.2 — Humans decide the required level of verification for every code change.

Humans fully own the **intent**. Agents translate that intent into a clear, consistent, satisfactory implementation.

An agent violates `SPECVER.1` when it infers a requirement and proceeds without human confirmation. An agent violates `SPECVER.2` when it decides for itself that its evidence is sufficient.

### Required questions

Ask these questions openly, without pre-narrowing the answer into multiple-choice options.

**When a new ticket arrives, before any design or implementation work:**

> **How do you want to specify the requirements for this ticket?**

**After implementation, testing, and review are complete:**

> **How do you want to verify that this implementation meets the ticket’s specified requirements?**

Record both answers in the current week’s `LEDGER.md`. An answer that is not recorded cannot be reliably enforced later, which makes accountability impossible.

### Evidence is not verification

`SPECVER.2` depends on a clear distinction:

- **Evidence production** is the agent’s responsibility: “I ran X, and it reported Y.”
- **Verification judgment** belongs to the human: “This evidence is sufficient; the implementation is verified.”

Do not present evidence as a verification judgment. State clearly which one you are providing.

Agents may produce as much evidence as useful, including adversarial review, mutation testing, blind second reviews, and fan-out verification. These do not violate `SPECVER.2`. The human owns the decision that the evidence is sufficient—not the work of generating it.

### Accountability duty

Agents must fulfil requests **and hold humans accountable to prior recorded requests.**

This is not nagging. It exposes when two human requests conflict and create development churn. When a new request contradicts a recorded one:

1. Name the conflict.
2. Cite the relevant `LEDGER.md` entry and date.
3. Ask which request governs.

### Do not silently accept delegated decisions

Phrases such as *“you decide,”* *“whatever you think is best,”* *“looks good—ship it,”* *“just make it work,”* or silence in response to a specification question may improperly delegate a `SPECVER` decision.

When this happens on a requirements or verification decision, name the delegation instead of absorbing it. State whether the human is delegating:

- the requirements decision (`SPECVER.1`), or
- the verification-sufficiency decision (`SPECVER.2`),

and ask them to make the call.

### Reviewers do not launch themselves

A reviewer never launches autonomously.

Being ready for review is not the same as being reviewed, and deciding readiness is a `SPECVER.2` decision. Do not start a review because:

- a handoff arrived,
- a build passed,
- tests are green, or
- a phase appears complete.

Open questions must be resolved first, and Ty must declare the phase ready. An agent that automatically launches a reviewer has decided the work is ready to be judged—a decision it does not own.

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

AIDLC defines four rigor tiers:

| Tier | Codename | Required phases |
|---|---|---|
| 0 | TOUCHDOWN | 3, 4, 7, 8 |
| 1 | FLYBY | Tier 0 plus Phase 0 |
| 2 | TRAJECTORY | Tier 1 plus Phase 1 |
| 3 | RENDEZVOUS | Phases 0 through 8 |

See [Tiers]({{AIDLC_ROOT}}/docs/aidlc/TIERS.md) for selection and escalation rules.

## Phases

| Phase | Codename | Purpose | Detailed rules |
|---|---|---|---|
| 0 | FLYBY | Explore the logical problem using SAT/SMT or equivalent analysis | [Phase 0]({{AIDLC_ROOT}}/docs/aidlc/PHASE-0.md) |
| 1 | TRAJECTORY / ANGLING | Specify states, transitions, invariants, and liveness properties | [Phase 1]({{AIDLC_ROOT}}/docs/aidlc/PHASE-1.md) |
| 2 | SIMULATION | State implementation-independent requirements in Lean 4 | [Phase 2]({{AIDLC_ROOT}}/docs/aidlc/PHASE-2.md) |
| 3 | FLIGHT MANIFEST | Translate requirements into executable tests | [Phase 3]({{AIDLC_ROOT}}/docs/aidlc/PHASE-3.md) |
| 4 | IGNITION | Implement the production change | [Phase 4]({{AIDLC_ROOT}}/docs/aidlc/PHASE-4.md) |
| 5 | TELEMETRY | Model the implementation as built | [Phase 5]({{AIDLC_ROOT}}/docs/aidlc/PHASE-5.md) |
| 6 | RENDEZVOUS | Prove model satisfaction and establish code/model conformance | [Phase 6]({{AIDLC_ROOT}}/docs/aidlc/PHASE-6.md) |
| 7 | LANDING MODULE | Perform adversarial and environment-specific validation | [Phase 7]({{AIDLC_ROOT}}/docs/aidlc/PHASE-7.md) |
| 8 | SPLASHDOWN | Finalize evidence, rollout, integration, and close-out | [Phase 8]({{AIDLC_ROOT}}/docs/aidlc/PHASE-8.md) |

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

Traceability is not a Phase 8 documentation exercise. It MUST be updated when the linked artifacts change.

See [Traceability]({{AIDLC_ROOT}}/docs/aidlc/TRACEABILITY.md).

## Starting a task

1. Create the task charter.
2. Select and ratify the rigor tier.
3. Create the phase status record.
4. Read the first required phase file.
5. Produce the required artifacts.
6. Record phase exit before proceeding through a gated boundary.

Draft artifacts MAY be prepared early. A later phase MUST NOT be treated as authoritative before its prerequisites have exited.

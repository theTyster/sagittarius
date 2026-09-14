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

One person MAY hold multiple roles for low-risk work. POKAYOKE-tier work SHOULD separate implementer and final reviewer.

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

## Counterfactuals

A counterfactual check intentionally changes an assumption, requirement, model, implementation, input, or environment to determine whether the evidence is sensitive to a material difference.

For material claims, the evidence plan SHOULD include at least one discriminating counterfactual. POKAYOKE-tier work MUST include one unless the technical authority records why none is applicable.

A counterfactual record MUST identify:

- the artifact or assumption changed;
- the reason the change is material;
- the expected result, recorded before execution;
- the observed result and evidence type;
- the implication for the affected claim.

Suitable counterfactuals include:

- negating or weakening a requirement;
- removing an assumption;
- introducing a known implementation defect;
- changing a fixture so that a precondition is absent or violated;
- replacing a permitted transition with a forbidden one;
- changing a bound, configuration, dependency, or environmental condition;
- presenting a known-valid and known-invalid case to the same oracle.

If a counterfactual expected to change a verdict does not do so, the affected evidence MUST NOT discharge the claim until the lack of discrimination is explained and accepted by the technical authority.

A successful counterfactual establishes that the evidence can distinguish the tested alternatives. It does not establish that the production implementation conforms, that all relevant alternatives were considered, or that the claim holds outside the recorded bounds.

A counterfactual is not a counterexample. A counterexample demonstrates a violation in the artifact under evaluation; a counterfactual evaluates how evidence responds to an intentional hypothetical change.

The last distinction is particularly useful because it prevents “counterexample” and “mutation/negative-control” evidence from being conflated.


## Approved claim wording

Preferred wording includes:

- "TLC reported no violation under configuration X."
- "The solver reported UNSAT under assumptions A and bounds B."
- "The Lean declaration type-checks with `sorry`."
- "The Lean implementation model satisfies requirement R."
- "The production implementation matched the implementation model over domain D."
- "The production query returned zero matching rows at time T."

The following claims require stronger evidence than a model result alone:

- "The system is proven correct."
- "The implementation is formally verified."
- "The migration cannot fail."
- "The requirement is proven" when its declaration contains `sorry`.
- "The property holds" when its antecedent was not reached.

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

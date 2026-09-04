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
- "Not applicable" with rationale;
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

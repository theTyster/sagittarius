# AIDLC Traceability

## Purpose

Traceability connects the reason for a change to the evidence supporting its implementation.

Traceability MUST be maintained during development. It MUST NOT be reconstructed only at close-out.

## Traceability chain

The complete POKAYOKE chain is:

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

### WIFFLED

| Requirement | Tests | Implementation | LANDING MODULE validation |
|---|---|---|---|

### AIMED

Add the matrix rows for whichever technique-pair(s) were selected:

- FLYBY — findings and logical checks;
- TRAJECTORY / ANGLING — TLA+ actions, properties, assumptions, and non-vacuity witnesses;
- SIMULATION → TELEMETRY → RENDEZVOUS — Lean requirements, implementation-model correspondence, and satisfaction proofs.

Also record the translation approach between any selected pairs (see `TIERS.md`).

### POKAYOKE

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

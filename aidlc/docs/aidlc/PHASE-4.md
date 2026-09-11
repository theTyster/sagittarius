# IGNITION — Implementation

*4 / 9*

## Objective

Implement the production change against the FLIGHT MANIFEST tests.

## Required for

All tiers.

## Inputs

- exited FLIGHT MANIFEST tests;
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

IGNITION exits when:

- FLIGHT MANIFEST tests pass;
- negative controls remain discriminating;
- migration rehearsals pass where applicable;
- rollout and rollback mechanisms exist;
- normal engineering checks pass;
- implementation decisions are recorded;
- no unresolved requirement ambiguity remains.

Passing tests permits progression. It does not constitute formal verification.

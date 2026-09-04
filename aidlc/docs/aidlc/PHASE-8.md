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

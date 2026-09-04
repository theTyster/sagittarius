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

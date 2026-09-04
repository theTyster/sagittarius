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

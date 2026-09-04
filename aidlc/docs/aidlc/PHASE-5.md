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

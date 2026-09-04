# Phase 2 — SIMULATION: Lean Requirements Model

## Objective

State implementation-independent requirements as well-typed Lean 4 propositions.

## Required for

Tier 3.

## Inputs

- exited Phase 1 specification;
- ratified requirements;
- specification coverage matrix;
- approved assumptions.

## Nature of the artifact

Phase 2 defines what must be true. It MUST NOT prescribe implementation strategy unless that strategy is itself a ratified requirement.

Proof bodies MAY use `sorry`.

A declaration containing `sorry` is admitted and type-checked. It is not proven. Documentation MUST describe it as a well-typed or admitted requirement.

## Required artifacts

- Lean requirements model;
- requirement inventory;
- inventory of every `sorry`;
- quantification review;
- anti-vacuity evidence;
- TLA+-to-Lean traceability;
- planned test mapping.

## Requirement rules

Each requirement MUST:

- map to a ratified requirement;
- map to a Phase 1 action or property;
- quantify over the intended domain;
- state assumptions explicitly;
- represent applicable normal, exceptional, and fail-closed outcomes;
- include relevant frame conditions;
- have an inhabited or reachable precondition;
- avoid accidental dependence on an implementation mechanism.

The model MUST NOT use an empty domain, unreachable antecedent, `False`, or an equivalent construction to satisfy a requirement unintentionally.

## Exit criteria

Phase 2 exits when:

- every in-scope requirement is represented;
- all declarations type-check;
- every `sorry` is inventoried;
- quantification has been reviewed;
- every conditional requirement has anti-vacuity evidence;
- the traceability matrix is complete;
- requirements do not accidentally prescribe implementation;
- the requirements authority ratifies the artifact.

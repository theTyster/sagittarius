# SIMULATION — Lean Requirements Model

*2 / 9*

## Objective

State implementation-independent requirements as well-typed Lean 4 propositions.

## Required for

POKAYOKE (always); AIMED, when the SIMULATION → TELEMETRY → RENDEZVOUS pipeline is a selected technique-pair.

## Inputs

- exited TRAJECTORY / ANGLING specification;
- ratified requirements;
- specification coverage matrix;
- approved assumptions.

## Nature of the artifact

SIMULATION defines what must be true. It MUST NOT prescribe implementation strategy unless that strategy is itself a ratified requirement.

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
- map to a TRAJECTORY / ANGLING action or property;
- quantify over the intended domain;
- state assumptions explicitly;
- represent applicable normal, exceptional, and fail-closed outcomes;
- include relevant frame conditions;
- have an inhabited or reachable precondition;
- avoid accidental dependence on an implementation mechanism.

The model MUST NOT use an empty domain, unreachable antecedent, `False`, or an equivalent construction to satisfy a requirement unintentionally.

## Exit criteria

SIMULATION exits when:

- every in-scope requirement is represented;
- all declarations type-check;
- every `sorry` is inventoried;
- quantification has been reviewed;
- every conditional requirement has anti-vacuity evidence;
- the traceability matrix is complete;
- requirements do not accidentally prescribe implementation;
- the requirements authority ratifies the artifact.

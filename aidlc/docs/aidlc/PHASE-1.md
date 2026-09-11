# TRAJECTORY / ANGLING — Specification Model

*1 / 9*

## Objective

Build an implementation-independent TLA+ specification of required states, transitions, invariants, and applicable liveness properties.

## Required for

POKAYOKE (always); AIMED, when TRAJECTORY / ANGLING is a selected technique-pair.

## Inputs

- exited FLYBY artifacts;
- ratified requirements and decisions;
- known counterexamples;
- deployment and concurrency concerns.

## Required artifacts

- TLA+ specification and configuration;
- state-variable inventory;
- action inventory;
- invariant and liveness inventory;
- requirement-to-operator mapping;
- scenario and fixture inventory;
- model bounds;
- anti-vacuity witnesses;
- abstraction and assumption register;
- model/code divergence register;
- reproduction script and tool versions;
- specification coverage matrix.

## Completeness rules

The model MUST represent:

- every normative in-scope transition;
- load-bearing failure and fail-closed paths;
- relevant concurrency or an enforced assumption excluding it;
- relevant retry, restart, and ordering behavior;
- partial deployment states that can affect correctness;
- migration intermediate states when they affect correctness;
- normal and exceptional outcomes.

A total model operation MUST NOT stand in for partial production behavior unless totality is enforced by the design.

Every credited property MUST have a reachable scenario that exercises its antecedent.

Known model defects or contradictions MUST be resolved, excluded by enforced assumptions, or accepted explicitly.

## Exit criteria

TRAJECTORY / ANGLING exits when:

- every ratified in-scope behavior maps to a modeled action or property;
- all required transitions and frame conditions are represented;
- relevant safety and liveness properties are represented;
- credited properties are non-vacuous;
- model runs reproduce from committed artifacts;
- assumptions and abstractions are approved;
- no known counterexample remains without disposition;
- the specification coverage matrix is complete;
- the technical authority records the phase exit.

A high model-run count does not compensate for a missing transition.

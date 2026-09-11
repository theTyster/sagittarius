# FLIGHT MANIFEST — Property-Test Generation

*3 / 9*

## Objective

Translate requirements into executable tests before implementing the production behavior.

## Required for

All tiers.

## Requirements source

| Tier | Source |
|---|---|
| WIFFLED | Ratified prose requirements |
| AIMED | Requirements traced to whichever technique-pair(s) were selected — FLYBY findings, the TRAJECTORY / ANGLING specification, and/or SIMULATION Lean requirements |
| POKAYOKE | SIMULATION Lean requirements |

## Required artifacts

- requirement-to-test inventory;
- property tests;
- example tests where properties are unsuitable;
- generators and shrinkers;
- fixtures;
- exceptional-path tests;
- test bounds and runtime assumptions;
- negative-control or mutation results.

## Rules

Every normative requirement MUST map to at least one executable test unless an exception is approved.

Tests MUST demonstrate that they distinguish relevant broken behavior through at least one of:

- a known-broken baseline;
- a disabled feature;
- a code mutation;
- a generated counterexample;
- a deleted or weakened guard.

Tests MUST cover applicable:

- normal behavior;
- exceptional and fail-closed behavior;
- empty and singleton inputs;
- multiple related entities;
- historical or malformed data;
- retry and restart behavior;
- partial deployment;
- relevant concurrency.

Implementation behavior MUST NOT become the source of expected test results.

## Exit criteria

FLIGHT MANIFEST exits when:

- every requirement maps to an executable test or approved exception;
- generators reach the relevant preconditions;
- negative controls fail as expected;
- test bounds are recorded;
- tests distinguish at least one representative broken behavior;
- the traceability matrix is current.

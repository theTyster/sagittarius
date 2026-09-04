# AIDLC Change Control

## Purpose

Changes discovered in later phases can invalidate earlier assumptions and downstream artifacts.

AIDLC requires returning to the earliest affected phase rather than patching only the latest artifact.

## Substantive changes

The following changes require impact analysis:

- requirement;
- business or technical decision;
- assumption;
- quantification domain;
- state variable;
- state transition;
- concurrency rule;
- failure behavior;
- migration rule;
- deployment unit or order;
- implementation behavior;
- implementation-model correspondence;
- accepted risk.

Editorial changes that do not change meaning do not require phase re-entry.

## Required change record

A substantive change MUST record:

1. changed artifact;
2. reason for the change;
3. new evidence or decision;
4. earliest affected phase;
5. invalidated downstream artifacts;
6. required reruns and reviews;
7. approving authority;
8. completion status.

## Re-entry examples

| Discovery | Typical return point |
|---|---|
| New logical counterexample | Phase 0 |
| Missing state transition | Phase 1 |
| Incorrect requirement or quantification | Phase 2 or earlier |
| Missing or non-discriminating test | Phase 3 |
| Implementation defect | Phase 4 |
| Code/model mismatch | Phase 5 |
| Failed satisfaction proof | Phase 2, 4, or 5 depending on cause |
| Platform-specific defect | Earliest phase containing the cause |
| Rollout incompatibility | Phase 1, 4, or 8 depending on cause |

## Downstream invalidation

When a phase is reopened:

- affected downstream phase exits MUST be marked invalidated;
- affected artifacts MUST be regenerated or re-reviewed;
- unaffected evidence MAY remain valid if the change record explains why;
- superseded evidence MAY remain in the evidence ledger as historical evidence;
- superseded normative text MUST be removed from the current specification.

## Counterexamples

A counterexample MUST NOT be resolved only by weakening a test or model.

Resolution requires one of:

- correct the requirement;
- correct the model;
- correct the implementation;
- enforce an assumption that excludes the counterexample;
- accept the counterexample as residual risk through the decision authority.

## Emergency changes

An emergency change MAY use an approved process exception.

The exception MUST define:

- omitted activities;
- immediate compensating controls;
- affected claims;
- required retrospective phases;
- completion deadline;
- approving authority.

Emergency status postpones required evidence. It does not create that evidence.

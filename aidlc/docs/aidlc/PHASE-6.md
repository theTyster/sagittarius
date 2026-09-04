# Phase 6 — RENDEZVOUS: Satisfaction and Conformance

## Objective

Establish two distinct obligations:

1. the Lean implementation model satisfies the Lean requirements model;
2. the production implementation conforms to the implementation model within a stated boundary.

## Required for

Tier 3.

## Obligation A — Model satisfaction

Every applicable Phase 2 requirement MUST be discharged against the Phase 5 implementation model.

Any approved Lean tactic or proof term MAY be used.

Unapproved `sorry` declarations MUST NOT remain in the satisfaction layer.

## Obligation B — Implementation conformance

Code-to-model evidence MUST establish agreement over the defined:

- inputs;
- outputs;
- state transitions;
- exceptional behavior;
- persistence effects;
- concurrency boundary.

If conformance evidence is bounded or empirical, the conclusion MUST remain bounded or empirical.

## Proof-complexity rule

A disproportionately convoluted proof is a diagnostic signal.

Reviewers MUST examine:

- whether the requirement is correct;
- whether quantification is correct;
- whether the implementation model matches the code;
- whether hidden assumptions carry the proof;
- whether implementation complexity should be reduced.

A technical proof pass does not remove the need for this review.

## Required artifacts

- satisfaction proofs;
- proof-assumption inventory;
- conformance results;
- bounds and limitations;
- requirement-to-proof mapping;
- unresolved-obligation inventory.

## Exit criteria

Phase 6 exits when:

- every requirement has a completed satisfaction proof;
- no unapproved `sorry` remains in the satisfaction layer;
- conformance checks pass;
- assumptions and bounds are documented;
- all unresolved obligations are closed or explicitly excepted;
- no correctness claim exceeds the established relation.

## Permitted conclusion

"The Lean implementation model satisfies the Lean requirements model, and the production implementation conforms to the implementation model within the stated conformance boundary."

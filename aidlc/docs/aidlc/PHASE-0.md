# FLYBY — Logical Exploration

*0 / 9*

## Objective

Establish the logical shape of the problem and identify at least one verifiable root cause before committing to a transition-system specification.

## Required for

POKAYOKE (always); AIMED, when FLYBY is a selected technique-pair.

## Inputs

- task charter;
- known incidents or counterexamples;
- candidate requirements;
- available code and data evidence.

## Required artifacts

- problem statement;
- logical vocabulary;
- assumptions and bounds;
- SAT/SMT encodings where applicable;
- solver versions and reproduction commands;
- check inventory;
- expected and actual verdicts;
- negative, deletion, or weakening probes;
- root-cause findings;
- unresolved questions;
- candidate requirement inventory.

## Rules

A SAT result establishes existence only within the encoded domain.

An UNSAT result establishes absence only within the encoding, assumptions, and bounds.

An UNSAT result MUST NOT be credited to an intended requirement unless deleting or weakening that requirement changes the result as expected.

A check that asserts its own conclusion is non-discriminating and MUST NOT support that conclusion.

Conditional findings MUST include evidence that their antecedents are satisfiable.

## Exit criteria

FLYBY exits when:

- the logical vocabulary is stable enough for the next required activity;
- at least one root cause has discriminating evidence;
- assumptions and bounds are recorded;
- non-discriminating checks are identified;
- known contradictions have an owner;
- candidate requirements are stated without claiming implementation sufficiency;
- blocking counterexamples are dispositioned or carried forward explicitly.

## Permitted conclusion

"FLYBY bounded the logical problem and identified the recorded root cause under the stated encoding and assumptions."

FLYBY does not prove that a production implementation is correct.

# AIDLC Tiers

## Selection rule

Select a tier based on the task's complexity and potential harm, not the desired development speed.

The selected tier MUST be recorded in the task charter and ratified by the technical authority.

A tier MAY be raised at any time.

A tier MUST NOT be lowered after work begins without:

- written rationale;
- disposition of evidence indicating higher risk;
- approval from the technical authority.

## WIFFLED

*0 / 3 — none*

### Scope

Simple, low-risk changes that can be specified in prose and verified empirically.

### Required phases

- FLIGHT MANIFEST — requirement-derived tests;
- IGNITION — implementation;
- LANDING MODULE — adversarial and end-to-end validation;
- SPLASHDOWN — close-out.

### Requirements source

Ratified prose requirements.

### Typical examples

- isolated presentation changes;
- simple validation;
- low-risk API behavior;
- localized defects with a clear cause and no significant state interaction.

## AIMED

*1 / 3 — some*

### Scope

WIFFLED work where at least one formal technique is warranted, but the full POKAYOKE pipeline would be overkill. AIMED is deliberately permissive: the task owner picks which technique-pair(s) apply, rather than following a fixed phase list.

### Required phases

The WIFFLED floor — FLIGHT MANIFEST, IGNITION, LANDING MODULE, SPLASHDOWN — plus **at least one** selected technique-pair:

- **FLYBY** — SAT/SMT logical exploration; the solver verdict serves as both the model and the check.
- **TRAJECTORY / ANGLING** — TLA+ specification; the model-checker verdict serves as both the model and the check.
- **SIMULATION → TELEMETRY → RENDEZVOUS** — Lean requirements model, implementation model, and satisfaction proof, run as a mini-pipeline.

Each pair already bundles a model with its own check, so picking any one satisfies "a modeling layer and a proof/check layer must both be present."

### Selecting and combining technique-pairs

The task owner proposes which pair(s) apply; the technical authority ratifies the choice in the task charter.

When more than one pair is selected (for example, TRAJECTORY / ANGLING plus the SIMULATION pipeline, or FLYBY plus the SIMULATION pipeline), the task charter MUST record how evidence and identifiers translate between the chosen layers. This translation approach — not the phase checklist — is the central design question for an AIMED task.

### Typical examples

- rule-set contradictions and bounded assignment problems (FLYBY alone);
- workflows with multiple states, concurrent updates, or partial deployment (TRAJECTORY / ANGLING alone);
- a state-transition spec paired with a Lean satisfaction proof for the same behavior (TRAJECTORY / ANGLING plus the SIMULATION pipeline);
- a bounded logical check paired with a Lean satisfaction proof (FLYBY plus the SIMULATION pipeline).

## POKAYOKE

*2 / 3 — all*

### Scope

High-risk or high-complexity work requiring the full formal pipeline. POKAYOKE is the gold-standard reference: AIMED's technique-pairs are the same building blocks, applied selectively; POKAYOKE requires all of them, wired together.

### Required phases

FLYBY through SPLASHDOWN — all nine phases.

### Escalation indicators

POKAYOKE SHOULD be selected when the task involves combinations of:

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

A task completes its tier only when all of its required phases have exited — for AIMED, that means the WIFFLED floor plus every phase in each selected technique-pair.

A lower tier MUST NOT claim evidence produced only by a higher tier. For example, WIFFLED test success is not formal verification.

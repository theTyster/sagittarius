# Glossary

Vocabulary you'll meet across this repo, the spec, and the findings.

### Sagittarius
This project: the orbital-shifting pipeline realized as one deterministic Workflow. Named after **Sagittarius A\***, the Milky Way's central black hole, which the Event Horizon Telescope imaged using **independent, isolated teams that converge only at the end** — a bias defense by structural independence, mirroring orbital's independent-specialist-convergence thesis.

### orbital / orbital-shifting
The parent project ([github.com/theTyster/orbital](https://github.com/theTyster/orbital)) and its formal-reasoning pipeline of seven staged primitives plus an `explain` closer. Sagittarius was split out of orbital's `experiments/pipeline-workflow/`. The specialist agents Sagittarius calls still ship in orbital's plugins.

### kimmy
The intended **first real target** for the Workflow — a feature in a separate project (`~/Projects/<company>/kimmy`). "The kimmy gate" is the bar the dogfood had to clear before being pointed at real work: all seven invariants proven non-vacuous and adversary-surviving over a non-degenerate model. The gate is satisfied; *which* kimmy ticket to run is the one open decision.

### dogfood
Running the pipeline on **its own design document** — using orbital-shifting to build and verify the Workflow that re-implements orbital-shifting. Everything under `self-spec/` is the dogfood's artifact chain.

### the seven stages
`close-world → decompose-proposition → model-obligations → prove-invariants → instantiate-properties → realize-specification → measure-entailment`, then the always-runs **`explain`** closer.

### close-world / CWA (closed-world assumption)
Reading a source into a structured fact base where **anything not stated is treated as false**. The pipeline carefully distinguishes a fact the source **explicitly forbids** (a strong, deliberate negation — `contradicts`) from one it merely **never mentions** (a weak absence — `absent`). A `absent` must never be laundered into a proof: *CWA-absent ≠ disproved.*

### hypothesis / proposition
The central claim, decomposed into individually-checkable **claims** (`self-spec/hypothesis.pl`), each labeled **descriptive** (the design already asserts it), **counterfactual** (must be false), or **prescriptive** (must become true via proof or build).

### target-world
The model of the world in which the proposition holds (`self-spec/target-world.pl`): the existing-world facts minus the counterfactual facts, plus the prescriptive obligations and the materialized operational substrate each invariant is proven against.

### invariant (I-1…I-7)
A safety property proven in Lean. See [`decisions.md`](decisions.md). The proofs concern **control flow**, not the quality of the work the Workflow drives.

### counterfactual (CF) / necessity lemma
A **CF** is a forbidden fact whose *absence* an invariant relies on. A **necessity lemma** re-introduces that fact in a parallel CF predicate and proves the property **fails** once it's restored — showing the removal is *load-bearing*, not idle. Example: `ReachesExplainCF` omits the hard-stop run `r1`; the I-1 necessity lemma shows that without explain-on-hard-stop, a terminating run fails to reach explain.

### vacuous proof
A theorem that type-checks but **proves nothing** — e.g. stated so loosely that a degenerate witness (a constant measure + a no-op step) satisfies it. `lake build` and `#print axioms` *cannot* catch this; only an adversary can. The I-3 termination proof was vacuous on the first pass and was caught + re-proven (the headline defect, FINDINGS F-3).

### non-degenerate model
A model whose domains have **≥2 distinct inhabitants with varying values**, so universals don't collapse to `True → True` and hypotheses are load-bearing. The re-statement rebuilt a degenerate one-point model into a non-degenerate one, turning 5/7 vacuous proofs genuine.

### digest
The small structured object a stage returns to carry **control** (artifact ref, status, agent-emitted verdict signals, target-tagged gaps, core-obligation flag). State flows through `.pl` files; control flows through digests (D-3).

### separation of authority / the Orbital Inversion
**Separation of authority** (D-2): the substrate owns mechanics, agents own judgment. The **Orbital Inversion** (C-2; formerly the *inversion smell*): the substrate computing a logic verdict itself instead of reading one an agent emitted — the failure to *shift* a judgment out of the bookkeeping frame and into the reasoning frame where it belongs. Avoiding it is the design's central discipline. (The name ties the failure to orbital-*shifting*: an inversion is a shift that didn't happen.)

### Pattern 3
A counterfactual (forbidden) fact that the *implementation still asserts* — i.e. a forbidden behavior that leaked into the code. The terminal `measure-entailment` scan found **0** Pattern-3 violations.

### loopback
A backward cursor move to **honor a routed gap** — re-running an earlier stage to repair a deficiency. Bounded by `LOOP_LIMIT` (D-7) so the loop provably terminates (I-3).

### disprove / adversary
The mandatory adversarial challenge: ≥1 attempt per run, each fanning out to ≥2 **perspective-diverse** adversaries in parallel (D-6 / C-5). Adversaries try to *refute* a claim or *inhabit* a theorem's negation. This floor is what gives the verification teeth.

### F-N (findings)
Numbered findings in [`../FINDINGS.md`](../FINDINGS.md): F-1…F-5 from the dogfood, F-6…F-11 from the pre-kimmy re-statement. F-11 — the Prolog↔Lean I-1 reconciliation — is this repo's inaugural commit.

### the substrate
orbital's `orchestration-substrate.md` contract (bias-defense table, gate-target descriptors, `upstream_gap` reverse channel). It is **canonical** when docs disagree. The digest schema ports its gate-target descriptors (forward) and gap facts (reverse) into the Workflow's control plane.

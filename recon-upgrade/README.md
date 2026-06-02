# recon-upgrade — the self-upgrade experiment

This directory is a **falsifiable bet**. Before running the real pipeline, it
records (a) my free-hand version of the runtime change and (b) my prediction of
what the formal pipeline will produce when it proves that change. Later, the real
Sagittarius-2 dogfood run lands its artifacts in `self-spec/` (extended), and we
diff **prediction vs reality**. The size and nature of that diff *is the measure
of how much the formal workflow adds over one careful engineer free-handing it.*

## The change under test

Add a **recon / primer** step (the "Orbital Inversion"-safe front door) so the
proven 8-stage loop can start mid-chain against a maintained repo:

- a recon agent (`.claude/agents/recon.md`, `model: opus`) resolves a per-artifact
  path map + presence and proposes a `{from,to}` window;
- a pure `lib/recon-plan.js` folds that into a **WellFormedStart** seed, enforcing
  **I-8 (recon soundness)**: the seed `produced` set is always a complete
  contiguous prefix;
- the loop seeds from that plan (instead of the fixed cold `(0, ∅)`), with a
  **frozenPrefix** guard so an attach run never regenerates an adopted artifact.

## Files

| File | What it is | Compared against |
|---|---|---|
| `sagittarius-2.realized.mjs` | **Deliverable A** — Prime + recon, free-handed. The runtime change. | `git diff realized/sagittarius.realized.mjs recon-upgrade/sagittarius-2.realized.mjs` |
| `PREDICTION.md` | **Deliverable B** — my stab at the *entire* dogfood output: the spec amendments (D-14/C-7/I-8), then existing-world → hypothesis → target-world → Lean I-8 → tests → adherence → explain, plus an honest list of where I expect the workflow to *diverge* from this guess. | the real artifacts the run lands in `self-spec/` |

## How to read the result later

The interesting signal is **§ "Where I expect to be wrong"** in `PREDICTION.md`.
If the real run mostly confirms the prediction, the workflow's value is modest
(it mechanized what was already foreseeable). If the real run's adversarial floor
catches things in that section — a vacuous I-8, a missing necessity lemma, a
stronger theorem statement — *that delta is the workflow earning its keep.*

> Status: SKETCH. `sagittarius-2.realized.mjs` is a faithful delta, not a tested
> runtime; the proven loop still lives in `realized/`. Nothing here is wired in.

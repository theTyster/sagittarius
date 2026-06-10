# Sagittarius docs

Start here, then branch out.

## Read in this order

1. [`../self-spec/explanation.md`](../self-spec/explanation.md) — **plain-language**, non-technical account of a full pipeline run. No Lean/Prolog required. Read first.
2. [`design-spec.md`](design-spec.md) — the canonical **decisions, constraints, invariants, requirements** (D / C / I / R). This is the document the dogfood verified — the pipeline's *input*.
3. [`architecture.md`](architecture.md) — **how** the deterministic Workflow is built: the two-layer separation, the digest control-plane, the ten mechanics, the stage→specialist map, the bias defense.
4. [`decisions.md`](decisions.md) — the **decision log** distilled from the spec, each entry annotated with its *current* status (what got proven, what changed, what's deferred).
5. [`glossary.md`](glossary.md) — vocabulary: sagittarius, kimmy, CWA, Pattern 3, the inversion smell, dogfood, digest, loopback, necessity lemma, …
6. [`../thoughts/FINDINGS.md`](../thoughts/FINDINGS.md) — F-1…F-12, the **audit trail**: the three defects the gates caught, the re-statement that closed 5/7 vacuous proofs, the F-11 Prolog↔Lean reconciliation, and F-12 from the first real-ticket run (#2701).

## Fresh vs. historical

- **Fresh** (authored for this repo): this file, `README.md`, `architecture.md`, `decisions.md`, `glossary.md`, [`../thoughts/README.md`](../thoughts/README.md).
- **Historical** (migrated verbatim from the orbital dogfood, preserving git history): `design-spec.md`, `../thoughts/FINDINGS.md`, `../thoughts/HANDOFF.md`, and everything under `../self-spec/`. (The discovery deck and the `recon-upgrade/` experiment now under `../thoughts/` are this repo's own working trail, not orbital-migrated.)

## Path mapping (historical docs)

The historical docs were written when this code lived at `orbital/experiments/pipeline-workflow/`. When they cite an old path, translate:

| In the historical text | In this repo |
|---|---|
| `experiments/pipeline-workflow/X` | `X` (repo root) |
| `thoughts/X` | `self-spec/X` — see the ⚠️ below |
| `docs/superpowers/specs/2026-05-28-pipeline-as-workflow-design.md` | [`docs/design-spec.md`](design-spec.md) |
| `plugins/trajectory/…`, `plugins/shifting/…` | live in the [orbital](https://github.com/theTyster/orbital) repo (the specialists this Workflow calls) |

> ⚠️ **Two different `thoughts/`.** This repo *also* has a real, tracked [`../thoughts/`](../thoughts/) directory — its working area (notes, the discovery deck, the recon-upgrade experiment, in-progress recon artifacts). It postdates the historical docs and is unrelated to their `thoughts/X` references, which mean `self-spec/X`. The historical docs themselves now *live* under `../thoughts/` (`FINDINGS.md`, `HANDOFF.md`), but their internal `thoughts/X` citations still point at `self-spec/`.

`thoughts/HANDOFF.md` in particular is a historical launch note for running the dogfood *from orbital*; the dogfood has already run, so it is provenance, not instructions.

## Re-verifying

- **Prolog model + dumps:** `swipl -q -g "consult('self-spec/target-world.pl'), aggregate_all(count, verdict(_,consistent), N), format('~w/7~n',[N]), halt"` → `7/7`.
- **Behavioral suite:** `node --test self-spec/tests/*.test.js` → 24 + 8 green. (Pass the glob, not the bare directory — `node --test self-spec/tests/` is treated as a module path and errors on recent Node, e.g. v26.)
- **Lean proofs:** recorded in `self-spec/lean_proof_results.pl`; re-checking from source needs Lean 4 + Mathlib. The dogfood built the full library (8259 jobs, exit 0) during the re-statement; this repo carries the toolchain config but not the (multi-GB, regenerable) `.lake/` build cache.

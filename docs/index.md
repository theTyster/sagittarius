# Sagittarius docs

Start here, then branch out.

## Read in this order

1. [`../self-spec/explanation.md`](../self-spec/explanation.md) — **plain-language**, non-technical account of a full pipeline run. No Lean/Prolog required. Read first.
2. [`design-spec.md`](design-spec.md) — the canonical **decisions, constraints, invariants, requirements** (D / C / I / R). This is the document the dogfood verified — the pipeline's *input*.
3. [`architecture.md`](architecture.md) — **how** the deterministic Workflow is built: the two-layer separation, the digest control-plane, the nine mechanics, the stage→specialist map, the bias defense.
4. [`decisions.md`](decisions.md) — the **decision log** distilled from the spec, each entry annotated with its *current* status (what got proven, what changed, what's deferred).
5. [`glossary.md`](glossary.md) — vocabulary: sagittarius, kimmy, CWA, Pattern 3, the inversion smell, dogfood, digest, loopback, necessity lemma, …
6. [`../FINDINGS.md`](../FINDINGS.md) — F-1…F-11, the **audit trail**: the three defects the gates caught, the re-statement that closed 5/7 vacuous proofs, and the F-11 Prolog↔Lean reconciliation.

## Fresh vs. historical

- **Fresh** (authored for this repo): this file, `README.md`, `architecture.md`, `decisions.md`, `glossary.md`.
- **Historical** (migrated verbatim from the orbital dogfood, preserving git history): `design-spec.md`, `../FINDINGS.md`, `../HANDOFF.md`, and everything under `../self-spec/`.

## Path mapping (historical docs)

The historical docs were written when this code lived at `orbital/experiments/pipeline-workflow/`. When they cite an old path, translate:

| In the historical text | In this repo |
|---|---|
| `experiments/pipeline-workflow/X` | `X` (repo root) |
| `thoughts/X` | `self-spec/X` |
| `docs/superpowers/specs/2026-05-28-pipeline-as-workflow-design.md` | [`docs/design-spec.md`](design-spec.md) |
| `plugins/trajectory/…`, `plugins/shifting/…` | live in the [orbital](https://github.com/theTyster/orbital) repo (the specialists this Workflow calls) |

`HANDOFF.md` in particular is a historical launch note for running the dogfood *from orbital*; the dogfood has already run, so it is provenance, not instructions.

## Re-verifying

- **Prolog model + dumps:** `swipl -q -g "consult('self-spec/target-world.pl'), aggregate_all(count, verdict(_,consistent), N), format('~w/7~n',[N]), halt"` → `7/7`.
- **Behavioral suite:** `node --test self-spec/tests/` → 24 + 8 green.
- **Lean proofs:** recorded in `self-spec/lean_proof_results.pl`; re-checking from source needs Lean 4 + Mathlib. The dogfood built the full library (8259 jobs, exit 0) during the re-statement; this repo carries the toolchain config but not the (multi-GB, regenerable) `.lake/` build cache.

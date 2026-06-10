# `thoughts/` — the tracked working area

This directory is Sagittarius's **versioned scratch / working trail**: research
notes, the discovery deck, the recon-/primer self-upgrade experiment, and
in-progress pipeline artifacts. It is deliberately *not* a load-bearing gate.

> **`thoughts/` vs `self-spec/`.** [`self-spec/`](../self-spec/) is the
> **canonical, verified dogfood chain** the repo's claims rest on (7/7 Lean
> invariants, 24+8 green tests, F-11 reconciled). Everything here is
> **work-in-progress and provenance** — read it for *how the sausage is made*,
> trust `self-spec/` for *what holds*.

> **Tracked on purpose.** The operator's global `~/.gitignore_global` drops
> `thoughts/` by convention; this repo overrides that (see `.gitignore` →
> `!thoughts/**`) so the working trail is versioned with the code. Build
> artifacts inside it (`.lake/`, `*.olean`) stay ignored.

## What's here

### Notes & handoff
| Path | What it is |
|---|---|
| [`FINDINGS.md`](FINDINGS.md) | **F-1…F-12** audit trail — the dogfood, the pre-kimmy re-statement (5/7 vacuous proofs closed), F-11 Prolog↔Lean reconciliation, and F-12 from the first real-ticket run (#2701). |
| [`HANDOFF.md`](HANDOFF.md) | Historical launch note for running the dogfood *from orbital*. Provenance, not instructions — the dogfood already ran. |
| [`MODEL-REBUILD-SPEC.md`](MODEL-REBUILD-SPEC.md) | The brief for rebuilding `TargetWorld.lean` non-degenerate so all 7 invariants re-prove non-vacuously (the pre-kimmy vacuity fix). |

### `deck/` — the discovery slide deck
Text-first HTML deck (`sagittarius-deck.html`) explaining the project to a
non-technical audience, with `sagittarius-deck.notes.md` as its technical backing.

### `recon-upgrade/` — the self-upgrade experiment
A **falsifiable bet**: a free-hand version of the recon/primer runtime change
(`sagittarius-2.realized.mjs`) plus a sealed prediction (`PREDICTION.md`) of what
the formal pipeline would produce, scored after the fact (`RESULT.md`). The size of
the prediction-vs-reality diff *is the measure of what the formal workflow adds*.
Status: SKETCH — nothing here is wired into the proven loop (the shipped recon
mechanic lives at [`../lib/recon-plan.js`](../lib/recon-plan.js), tested by
[`../tests/recon_plan.test.js`](../tests/recon_plan.test.js), with the recon agent
at [`../.claude/agents/recon.md`](../.claude/agents/recon.md)).

### In-progress recon dogfood chain
The loose artifacts at the root of this directory (`existing-world.pl`,
`hypothesis.pl`, `target-world.pl`, `model_results.pl`, `lean_proof_results.pl`,
`adherence_*.{pl,md}`, `explanation.md`, `lean/`, `lean_disproofs/`, …) are a
working re-run of the pipeline on the **recon-extended** design (D-14 / C-7 / I-8).
The `existing-world.pl` here is recon-aware and diverges from `self-spec/`; the rest
are largely re-runs of the canonical chain. `recon/` and `recon2/` are full-chain
**iteration snapshots** from that effort (`recon/` carries the recon-aware
existing-world; `recon2/` the pre-recon baseline). `tests/` holds working copies of
the proof-property + C-2 suites.

## Heads-up: there are two different "thoughts/"

The **historical** docs in this repo — this directory's `FINDINGS.md` /
`HANDOFF.md`, plus [`../docs/design-spec.md`](../docs/design-spec.md) and
everything under [`../self-spec/`](../self-spec/) — were authored when the code
lived at `orbital/experiments/pipeline-workflow/`, where the pipeline wrote its
output to a `thoughts/` directory. **When those docs say `thoughts/X`, they mean
what is now [`self-spec/X`](../self-spec/)** — the canonical run — *not* this
working directory, which postdates them. See the path-mapping table in
[`../docs/index.md`](../docs/index.md).

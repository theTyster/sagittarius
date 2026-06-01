# Architecture

How Sagittarius realizes the orbital-shifting pipeline as a deterministic Workflow, and why it is shaped this way.

## The one idea: separation of authority

Sagittarius splits the pipeline into two layers with a hard line between them (D-2):

| **Mechanics** — the deterministic substrate owns these | **Judgment** — the AI agents own these |
|---|---|
| stage sequencing, the cursor, the scope set | "is this unprovable / inconsistent / refuted?" |
| gap batching (merge by target stage) | "honor this loopback, or surface it?" |
| the loop-limit / termination guard | "refute this claim" (the adversaries) |
| scope widening; artifact gating | the plain-language narration |

The substrate may **branch only on a verdict an agent already emitted** — never compute one itself. Computing a verdict in the substrate is the **inversion smell** (constraint C-2), and it is the single failure the whole design exists to prevent. A prior "self-orchestration" framing was refuted in debate; **structural-layer separation** is the framing that survived, and holding the C-2 line is what keeps Sagittarius on the winning side of it.

## Control plane: the digest (D-3)

Stage *state* flows through the existing Prolog artifact contract (`*.pl` files) — the substrate never serializes a knowledge base. Stage *control* flows through a small structured **digest** each stage returns, carrying only:

- an artifact reference,
- a status,
- verdict signals (emitted by the agent, never derived),
- gaps, each tagged with a **target stage**,
- a core-obligation flag.

The digest shape is pinned in [`../schemas/stage-digest.schema.js`](../schemas/stage-digest.schema.js) as an explicit allowlist of routable fields. The router ([`../lib/digest-router.js`](../lib/digest-router.js)) branches **only** on those agent-emitted fields and deliberately ignores the work-product content — re-judging that content would be the forbidden inversion. The digest *assembler* ([`../lib/digest-fold.js`](../lib/digest-fold.js)) is a pure fold that carries the agent's verdict verbatim or null, never synthesizes a control field from substrate identity (the C-2 regression guard — see F-6).

## Control flow: a movable cursor (D-4, D-5)

A cursor walks the stages. It **advances by default**, **moves backward only to honor a routed gap** (a loopback), and **halts** only on one of three forced conditions: loop-limit exceeded, budget exhausted, or a core obligation refuted. Recoverable gaps are honored automatically (within the loop limit) and logged to an auditable **decision trail** — a background run can't pause to ask a human (C-6).

## The nine mechanics (`lib/`)

Each is pure and separately tested, so the control flow can be TDD'd without invoking real agents (D-11):

| module | responsibility | formalized by |
|---|---|---|
| `stage-order.js` | the 8-stage total order + immediate-successor chain | I-2 |
| `scope-set.js` | scope `(startIdx, endIdx)`; only widens | I-4 / C-4 |
| `termination-measure.js` | the lexicographic measure `M = (Σ recovery budget, endIdx − cursor)` | I-3 |
| `loop-limit.js` | `LOOP_LIMIT = 1` per gap-class-per-stage | I-3 / D-7 |
| `gap-batching.js` | merge gaps sharing a target stage; keep distinct targets apart | §9.1 |
| `disprove-reserve.js` | protect the reserve; guarantee the mandatory attempt | I-5 / I-6 / C-3 |
| `digest-router.js` | branch on agent-emitted digest fields only | **C-2** |
| `digest-fold.js` | pure digest assembler; verdict carried verbatim or null | **C-2** (F-6 guard) |
| `decision-trail.js` | the complete, auditable trail | §9.11 |

The orchestration loop ([`../orbital-pipeline.workflow.js`](../orbital-pipeline.workflow.js)) wires these together and receives its **effectful collaborators by injection** — the agent surface, the clock, and the random source are passed in, never reached for. That is what lets tests substitute fakes and what lets the design *prove* no control decision depends on a clock or a coin flip (C-1 / determinism).

## Two realizations

- [`../orbital-pipeline.workflow.js`](../orbital-pipeline.workflow.js) — the reference deterministic loop (mechanics + an abstract `agent.runStage(stage, ctx) → digest` seam). This is the artifact the 24 proof-property tests pin.
- [`../realized/orbital-pipeline.realized.mjs`](../realized/orbital-pipeline.realized.mjs) — the **Workflow-tool** port: a self-contained `export const meta` script that inlines the mechanics verbatim and calls each stage's named specialists **directly** via `agent({ agentType: 'shifting:<name>', schema })`, fanning out with `parallel()` / `pipeline()`. (Decision B: the workflow calls the ~17 existing specialists directly; one-agent-per-stage is just its n=1 case.)

## Stage → specialist map

Sagittarius does not contain the specialists; it *calls* them (they ship in the [orbital](https://github.com/theTyster/orbital) plugins). ✦ marks a converging-parallel segment.

| stage | specialists |
|---|---|
| close_world | agent-of-truth → kb-validator |
| decompose | proposition-sharpener → hypothesis-decomposer (+ agent-of-questions) |
| model_obligations | target-world builder + prolog-prover + agent-of-questions |
| ✦ prove_invariants | lean-spec-writer → lean-expert ×N (parallel) [+ lean-adversary for vacuity] |
| instantiate | pl-fact-extractor + agent-of-questions (+ test author) |
| ✦ realize | realize-test-briefer → implementer → realize-suite-runner → regression-bisector; counterfactual-scanner (**serial by necessity** — shared mutable source, D-9) |
| measure | agent-of-truth + verdict-extractor + agent-of-questions |
| ✦ disprove (cross-cut) | lean-adversary + prolog-adversary (**≥2 parallel, perspective-diverse**) |
| explain | the terminal narrator (forked; not decomposed) |

## Bias defense (the name)

The Event Horizon Telescope imaged Sagittarius A\* by having **independent, isolated teams** reduce the data separately and converge only at the end — so no single team's assumptions could quietly shape the result. Sagittarius applies the same defense: every sub-agent is **role-briefed with minimal context**, and every disprove attempt fans out to **≥2 perspective-diverse adversaries** with **≥1 attempt guaranteed per run** (D-6 / C-5). The mandatory adversarial floor is not ceremony — it is what caught the vacuous termination proof (I-3) that every routine check passed clean (see [`../FINDINGS.md`](../FINDINGS.md) F-3, and `explanation.md`'s "Defect 3").

## Parallelism (D-9)

Parallel where it's safe: `prove-invariants` (per theorem), `instantiate-properties` (per test), `model-obligations` (per property), `disprove` (per adversary). **Serial by necessity:** `realize-specification` — shared mutable source and inter-test dependencies mean worktree isolation doesn't save it (and F-8 found worktree isolation leaks mutations anyway). Lean concurrency is sub-capped (~cores/4, D-10) so parallel `lake build`s don't thrash.

## What the verification covers — and doesn't

Everything proven is about **control flow**: it halts (I-3), it gates correctly (I-2), it always explains (I-1), scope only widens (I-4), the adversarial floor holds (I-5/I-6/I-7). None of it speaks to the *quality of the reasoning* the Workflow will drive on a real ticket — Sagittarius is a trustworthy conductor; it makes no promise about the music. See `decisions.md` for per-invariant proof status and the honest residual caveats.

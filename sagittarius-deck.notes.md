# Sagittarius deck — technical companion (for the mind-map)

Technical backing for `sagittarius-deck.html`. The deck is written at a low
reading level for a lay audience; this file carries the precise claims, artifact
names, verdicts, and theorem statements behind each slide — plus the honesty notes
that don't belong in a public deck but do belong in the record.

Source of truth for the run: `recon-upgrade/RESULT.md` (scored comparison),
`recon-upgrade/PREDICTION.md` (the sealed bet), and the artifacts under
`recon-upgrade/run-artifacts/`. Dogfood run = Workflow `recon-i8-dogfood`, task
`w7ze22lys`, 10 agents, ~607k subagent tokens, ~56 min, proof-half only.

---

## Cast of actors (deck terms → what they actually are)

| Deck term | Actual |
|---|---|
| **the orchestrator** (an LLM) | The `Workflow` script driven by the main-loop model (Opus). It authored the spec amendments (D-14/C-7/I-8), the sealed `PREDICTION.md`, and the `sagittarius-2` sketch. It branches only on agent-emitted digests (never computes a verdict). |
| **Agent Experts** | The `shifting:*` specialist subagents from the orbital-shifting pipeline, called directly by the workflow: `agent-of-truth`, `kb-validator`, `proposition-sharpener`, `agent-of-questions`, `hypothesis-decomposer`, `prolog-prover`, `lean-spec-writer`, `lean-expert`, `lean-adversary` (+ a `general-purpose` narrator for synthesis). Each is briefed with minimal context and sealed from the others. |
| **the workflow / the script** | `realized/sagittarius.realized.mjs` (Prime) and the `sagittarius-2` sketch. Deterministic; bookkeeping only. |
| **the one rule** | D-2 separation of authority; its violation = **C-2 / the Orbital Inversion** (substrate computing a logic verdict instead of reading an agent-emitted one). |

The experiment is therefore **LLMs checking an LLM**: the orchestrator-LLM
predicted + wrote a confident-but-flawed spec; the Agent-Expert LLMs, structured by
independence + adversarial attack + formal proof, caught what it missed. The value
is in the *structure*, not in one model being smarter than another.

---

## The two tools (slide: "How machine-checked works")

- **Prolog** — SWI-Prolog 10.0.2 (`swipl`). Used by `agent-of-truth`, `kb-validator`,
  `hypothesis-decomposer`, `prolog-prover`. What it did in the run: built the world
  model (`existing-world-recon.pl`, `hypothesis-recon.pl`, `target-world-recon.pl`)
  and ran falsification queries → `model_results-recon.pl`. Verdicts:
  `p_recon_clamp_wellformedstart = consistent`,
  `p_recon_no_widen_below_frozen = consistent`,
  `p_recon_i8_seed_soundness = OPEN` (it **refused to declare the weak/abstract I-8
  "consistent"** — deferred the non-vacuity call to prove-invariants per C-7; the
  Orbital Inversion line, holding). Non-degenerate model: 3 honored seeds at
  startIdx `{0, 4, 5}` + a hole witness (`sd_hole`, holed at index 2, refused
  `feasible:false`).
- **Lean 4** — `lake` 5.0.0 / Lean 4.30.0, Mathlib prebuilt. Used by
  `lean-spec-writer`, `lean-expert`, `lean-adversary`. What it did: transcribed the
  three I-8 `formal_property` sketches into theorem stubs at
  `self-spec/lean/Proofs/I8ReconSoundness.lean`, attempted to close them, and
  adversarially attacked them. This is where the vacuity surfaced. `lake build`
  exit 0 = the **stubs type-check**, NOT that anything was proven (`proven = 0`).

---

## Slide-by-slide technical backing

- **S2 "plausible ≠ correct" / the wrong-spec trap.** The defect was not in
  execution but in the *specification*: a `formal_property` whose Lean transcription
  was a tautology. Formal verification cannot save you from formally verifying the
  wrong statement. This is the wrong-spec problem in its purest observed form.
- **S6 the tools.** As above. Note the Prolog `OPEN` verdict is the C-7 discipline,
  not a tooling limitation.
- **S7 the task.** Add the recon/primer (D-14): start the pipeline mid-chain
  (attach/resume) instead of always cold. The safety rail to prove = **I-8 recon
  soundness**: every honored window seeds a *complete contiguous prefix*, so I-2
  gating holds at the seed.
- **S8 prediction.** `PREDICTION.md`: §§1–3 high/med confidence (clean early
  stages, prescriptive label + clamp pivot, consistent model); §4 low confidence on
  the Lean close ("where I most expect to be wrong"); §X listed the bets, #1 =
  vacuity→clamp pivot, #2 = Lean-vs-behavioral.
- **S9 the headline find.** See next section.
- **S11 three more defects.** See "the other three" below.
- **S12 trustworthy.** `lean-expert` (un-primed re: vacuity) abstained with
  upstream-encoding-failure and left source `by sorry` — no `decide`/`native_decide`
  foul. `lean-adversary` independently `refuted`. Two agents, same conclusion,
  separately = convergence-by-independence (the EHT/Sgr A* thesis).
- **S13 scorecard.** Orchestrator predicted the *direction* (all of §§1–3 + the
  pivot in §X#1); the Agent Experts supplied the *depth* (the specific mechanism +
  three defects the prediction's high-confidence blocks missed).

---

## The headline find (S9) — exact form

In `self-spec/lean/Proofs/I8ReconSoundness.lean`, the abstract I-8 theorem
`i8_seed_soundness` was a **standalone tautology** — and *not even* a corollary of
the static I-2 gating theorem (`grep` confirmed zero `I-2` / `Requires` /
`StageOrder` references in the file). Root cause: the two predicates were
*definitionally identical* —

```
Present    w i  :=  ∃ s : Stage, w.stageAt i = s
StrictLoads w i  :=  ∃ s : Stage, w.stageAt i = s      -- the SAME proposition
present_eq_strictloads : Present w i = StrictLoads w i := rfl
```

so the conjunction `Present ∧ StrictLoads` carried no information, the antecedent
`i < w.startIdx` was discardable, and the whole theorem closed by
`intro w i _; exact ⟨⟨⟨w.stageAt i, rfl⟩, ⟨w.stageAt i, rfl⟩⟩, rfl⟩`. The "hole"
(present-but-not-strict-loading) the Prolog model exhibits via `sd_hole` was
**unrepresentable** in this encoding. The adversary built green witnesses
(`I8VacuityProbe.lean`, `I8ClampStatable.lean`, exit 0, no `sorry`/axiom/
`native_decide` as a closing move), then removed them so the proven tree stayed
clean (artifact recorded at `run-artifacts/i8_seed_soundness_vacuity.lean`).

This is the F-3 vacuity smell (the I-3 termination proof was vacuous on first pass)
recurring in a new guise — and it compiled, which is exactly why a human reviewer
would have passed it.

## The other three defects (S11)

1. **False-as-stated safety rail.** `i8_frozen_prefix_floor` was `unprovable` — the
   negation type-checks: with free `AttachRun` fields, `⟨ar0, 1, 4, fun _ => 0⟩`
   gives `0 < steps=1` yet `frozenPrefix=4 > startIdxAt 0 = 0`. Needs the floor
   encoded as a structural invariant, not free fields.
2. **Silent referential-integrity break (tier-2).** `existing-world-recon.pl`
   strict-*loads* but `kb-validator` found 6 tier-2 failures: `negation_provenance/2`
   arg1 atoms not declared as `falsifier/1` — rename drift, e.g.
   `recon_computes_logic_verdict` vs the declared `recon_computes_a_logic_verdict`,
   and `frozenprefix_attach_regenerates_...` vs `..._attach_run_regenerates_...`.
   Green load ≠ internal consistency.
3. **Prolog↔Lean non-degeneracy gap.** The Prolog model meets the non-degenerate
   bar (3 seeds + hole), but that does not transfer to the Lean theorem, whose
   `Window`/`Seed` types have *free fields* ranging over arbitrary windows rather
   than the bound ground seeds. The Prolog falsification is real but asserts a
   different proposition than the Lean statement.

## Remediation the run handed back

- **(A) Structural seed-soundness:** replace free-field `Seed`/`Window` with
  inductives `StartOf` / `PresentAt` / `StrictLoadsAt` (one ctor per ground
  `op_recon_*` fact) so `i < startIdx` is load-bearing and the hole is
  Lean-refutable.
- **(B) Clamp-soundness:** define `planRecon` as a *real* total function over the
  closed `ProposedWin` enum (attach clamps, operator refuses); then
  `planRecon_wellformedstart` is provable by construction, not vacuously.
- Teeth **split** (not exiled to JS): soundness *contract* in Lean + behavioral
  `b12–b15` tests for the runtime clamp/refuse mechanism.
- Fix the close-world rename-drift orphans before re-running.

---

## Honesty notes (kept out of the public deck on purpose)

- **The priming confound.** The orchestrator's brief to `lean-adversary` *did* point
  it toward "is this a corollary of I-2? name the clamp-soundness pivot if vacuous."
  So the pivot *direction* was partly fed in. This was cut from the deck (slide 13)
  because the public framing made "we" ambiguous and made the experiment read as
  rigged. For the record it is **not** rigged, because: (a) the depth exceeded the
  prompt — the `Present ≡ StrictLoads` mechanism and the buildable witnesses were
  not suggested; (b) the adversary explicitly rejected the primed framing ("not even
  a corollary of I-2; a standalone tautology"); and (c) `lean-expert`, whose brief
  said only "don't fake it," *independently* flagged the same vacuity without any
  vacuity priming. The convergence of a primed and an un-primed agent is the signal.
- **Proven-tree hygiene.** The run left `self-spec/lean/Proofs/I8ReconSoundness.lean`
  (3 `sorry` stubs, unproven) inside the proven tree + a one-line import in
  `self-spec/lean/Proofs/Proofs.lean`. Baseline integrity confirmed
  (`target-world.pl` → 7/7 consistent; the 7 existing proofs untouched). Recommend
  moving the stub out to `recon-upgrade/` until the (A)/(B) re-encoding closes it.
- **Commit trail.** Checkpoint on branch `experiment/recon-primer-i8`:
  `8eb965c` (foundation), `2c4fd5f` (dogfood), `7248635` (deck baseline). `main`
  untouched at `677f836`. Nothing pushed.

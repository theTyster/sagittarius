# PREDICTION — what the Sagittarius-2 dogfood will produce

**Bet recorded before any run.** Below is my free-hand stab at the *entire*
artifact chain a real Sagittarius-2 run (attach mode, target = this repo, claim =
"the pipeline admits a sound recon primer") will land in an extended `self-spec/`.
The last section — **§X Where I expect to be wrong** — is the one that matters:
it names where I expect the formal pipeline's adversarial floor to overturn this
guess. Confirmed predictions ⇒ the workflow mechanized the foreseeable; overturned
ones in §X ⇒ the workflow earned its keep.

Notation: ⟦confidence⟧ high / med / low on each block.

---

## 0. Spec amendments (the INPUT the run close-worlds) ⟦high⟧

`docs/design-spec.md` gains, spec-first:

- **§1 proposition** (amended tail): *"…and admits a sound **recon primer** that
  generalizes the loop's start without breaking gating (I-8), all while holding
  the Orbital-Inversion line."*
- **D-14 — Recon primer.** A pre-loop step resolves a per-artifact path map +
  present-artifact set and proposes a `{from,to}` window; the loop seeds from it.
  Operator `from/to` is authoritative; else attach (claim) / resume (no claim).
- **C-7 — Recon reports facts, never a verdict.** Recon may report presence
  (exists + strict-load) and recommend a window; it must never compute a logic
  verdict nor edit a durable artifact. (The Orbital Inversion, restated for the
  primer.)
- **I-8 — Recon soundness.** The loop's seed `produced` set is always a complete,
  contiguous prefix of the stage sequence; equivalently every honored window
  satisfies gating at its start. With a `frozenPrefix` refinement: in attach mode
  a loopback never widens below the adopted prefix.
- **§9** gains behavioral criteria **12–15** (seed from a non-zero start; clamp an
  over-eager attach window; refuse an infeasible operator window; hard-stop a
  below-frozen-prefix loopback).

---

## 1. close-world → `existing-world.pl` (delta) ⟦high⟧

```prolog
% --- recon upgrade (D-14 / C-7 / I-8) ---
stage(recon).
stage_role(recon, primer).
precedes(recon, disprove).                 % pre-loop, before the floor
decision(d14, recon_primer).
constraint(c7, recon_reports_facts_never_verdict).
invariant(i8, recon_soundness).

artifact(recon_descriptor).
produces(recon, recon_descriptor).
% recon's descriptor is CONTROL (folded by planRecon), not a gated stage artifact:
negation_provenance(requires(recon, _), absent).   % recon is itself ungated

% the seed-state vocabulary the proof reasons over
predicate(well_formed_start/1).
predicate(stages_complete/1).
predicate(frozen_prefix/1).
predicate(seed_produced/2).
mechanic(plan_recon, folds(recon_descriptor, seed_state)).
authority(plan_recon, mechanics).          % NOT judgment (C-7/C-2)
authority(recon_agent, judgment).          % proposes window; reports facts
```

I expect `cwa-fragility-auditor` to flag one thing: `recon_descriptor` is *not* a
gated artifact like `existing-world.pl` — it's control. If close-world models it
as a normal stage output, gating gets a spurious edge. ⟦med⟧

---

## 2. decompose → `hypothesis.pl` (delta) ⟦med⟧

```prolog
claim(i8_recon_soundness, "every honored window seeds a complete contiguous prefix, so gating holds at the start").
claim_label(i8_recon_soundness, prescriptive).   % a NEW property the modified loop must satisfy
claim_status(i8_recon_soundness, open).

claim(i8_clamp_sound, "planRecon's output is WellFormedStart for ANY proposed window + stagesComplete").
claim_label(i8_clamp_sound, prescriptive).

% CF teeth — the necessity claim (removal/violation must break something)
claim(i8_hole_breaks_gating, "a seed produced set with a HOLE (non-prefix) violates gating").
claim_label(i8_hole_breaks_gating, counterfactual).
claim_negation_provenance(i8_hole_breaks_gating, seed_with_hole, contradicts).

formal_property(i8_recon_soundness,
  "for all seeds s, WellFormedStart s -> CanRunStage (stageAt s.startIdx) s.produced",
  'theorem i8 : ∀ s : Seed, WellFormedStart s → CanRunStage (stageAt s) s.produced := by sorry').

formal_property(i8_clamp_sound,
  "for all proposed windows w and presence p, WellFormedStart (planRecon w p)",
  'theorem i8_clamp : ∀ w p, WellFormedStart (planRecon w p) := by sorry').
```

**Prediction of the label fight:** the `hypothesis-decomposer` will hesitate
between labeling I-8 *descriptive* (the loop already starts at 0, a prefix) vs
*prescriptive* (the clamp must make it so). I bet it lands **prescriptive** and
emits `i8_clamp_sound` as the load-bearing claim, with `i8_recon_soundness`
demoted to a near-corollary. ⟦med⟧ (If it instead halts `label_ambiguous`, that's
a §X hit.)

---

## 3. model-obligations → `target-world.pl` + `model_results.pl` (delta) ⟦med⟧

```prolog
% WellFormedStart substrate (the seed model)
seed(s_cold,   start(0), produced([])).                       % backward-compat
seed(s_attach, start(4), produced([cw,dc,mo,pi])).            % a non-trivial attach
seed(s_hole,   start(4), produced([cw,    mo,pi])).           % CF: decompose missing

well_formed_start(S) :- seed(S, start(N), produced(P)), prefix_upto(P, N).
prefix_upto(P, N) :- findall(St, (nth0(I, [cw,dc,mo,pi,in,re,me], St), I < N), P).

% verdict directive (falsification query: a WFS seed that fails gating?)
verdict(i8_recon_soundness, consistent).      % none found
verdict(i8_clamp_sound,     consistent).
cf_fact(seed_with_hole, s_hole).
cf_status(i8_hole_breaks_gating, load_bearing). % re-introducing the hole re-violates gating
```

```lean
-- target-world-shape.lean (delta): the Seed inductive + WFS predicate
inductive Seed | s_cold | s_attach | s_hole
```

**Prediction:** `consistent` for both, with `s_hole` load-bearing. ⟦med⟧ Risk the
prover surfaces: the coverage gate (`<30%` ⇒ gap) if the seed enumeration is too
thin — I've given only 3 seeds; the prover may demand more startIdx positions to
avoid a vacuous `consistent`. ⟦med⟧

---

## 4. prove-invariants → `I8ReconSoundness.lean` + `lean_proof_results.pl` ⟦low⟧

```lean
/-- I-8 recon soundness. produced is the contiguous prefix [0, startIdx). -/
theorem i8_seed_is_prefix (s : Seed) (h : WellFormedStart s) :
    s.produced = (List.range s.startIdx).map stageAt := by
  cases s <;> decide          -- (likely too easy — see §X)

/-- I-8 carries gating from the seed. -/
theorem i8_seed_gates (s : Seed) (h : WellFormedStart s) :
    ∀ st, st = stageAt s.startIdx → CanRunStage st s.produced := by
  intro st hst; cases s <;> simp_all [CanRunStage, requiredUpstream]

/-- NECESSITY (CF teeth): a hole-seed fails gating — so WFS is load-bearing. -/
theorem i8_hole_breaks (h : ¬ WellFormedStart Seed.s_hole) :
    ¬ CanRunStage (stageAt 4) Seed.s_hole.produced := by decide
```

```prolog
theorem_verdict(i8_seed_is_prefix, proven).
theorem_verdict(i8_seed_gates, proven).
theorem_verdict(i8_hole_breaks, proven).
provenance_annotation(i8_hole_breaks, seed_with_hole, contradicts).
% I-1..I-7 re-confirmed over the generalized seed (no statement change needed):
theorem_verdict(i1..i7, proven).   % I-2 is static; I-4 already non-zero (3->1->0)
```

**Prediction:** I-8 closes axiom-free; I-1..I-7 re-confirm unchanged. Total tally
moves 25 → ~28 theorems. ⟦low — this is where I most expect to be wrong; see §X⟧

---

## 5. instantiate → behavioral tests ⟦high⟧

Essentially the suite already in `tests/recon_plan.test.js` (12 tests, the I-8
property sweep + the Orbital-Inversion guard + the clamp), re-expressed as
projection + behavioral tests, plus loop-level behavioral tests:

- projection: `planRecon` output is WellFormedStart across the swept seeds;
- behavioral: loop seeds cursor/scope/produced from the plan; frozenPrefix
  hard-stop fires; `recon_infeasible_window` halts-then-explains.

⟦high — I've already written and mutation-verified the core⟧

## 6. realize → the runtime ⟦high⟧

`sagittarius-2.realized.mjs` in this directory IS my prediction of realize's
output: the seeded `runPipeline`, the `frozenFloor` guard, the two new hard-stop
reasons, `runRecon`, and the brief-templating pass. ⟦high⟧

## 7. measure → `adherence_*` ⟦high⟧

- **Pattern-3 violations: 0** (the code no longer hardcodes `(0,∅)`; the seed
  flows from recon).
- **prescriptive fulfilled:** I-8 + I-8-clamp proven and guarded.
- **descriptive drift:** none expected. ⟦high⟧

## 8. explain → `explanation.md` ⟦high⟧

A paragraph: "recon lets the proven loop start mid-chain against a maintained repo
without weakening any invariant; the only new obligation, I-8, says the seed is
always a complete prefix, which is exactly what carries gating from a non-zero
start." ⟦high⟧

---

## X. WHERE I EXPECT TO BE WRONG (the experiment's payload)

Ranked by how much the workflow would be *adding* if it catches these:

1. **I-8-as-stated is probably vacuous.** `WellFormedStart → gating` is a near-
   restatement of the already-proven static I-2 (`Requires s a → StageOrder a s`).
   `cases s <;> decide` closing it is the F-3 smell (the I-3 termination proof was
   vacuous on first pass). **I bet the adversary/vacuity-check forces the move to
   the genuinely load-bearing theorem: `i8_clamp_sound` — that planRecon yields
   WellFormedStart from *any* proposed window** — which is the real soundness and
   is NOT a corollary of I-2. If the run makes this pivot on its own, that's the
   single biggest piece of value over my free-hand. ⟦I think this happens⟧

2. **I-8 may not be a Lean invariant at all — it may be demoted to behavioral.**
   The clamp lives in *JS* (`planRecon`), and the self-spec Lean models *abstract
   relations*, not the operational fold. Lean can state "this enumerated seed is a
   prefix" but cannot natively state "planRecon clamps an arbitrary input to a
   prefix." The run may conclude I-8's teeth belong in `instantiate` (a behavioral
   acceptance criterion — the sweep test) while Lean only gets the thin abstract
   form. **The prove-invariants ↔ instantiate boundary may reclassify I-8.** If so,
   the honest invariant count is "7 Lean + 1 behavioral," not "8 Lean." ⟦med-high⟧

3. **frozenPrefix needs a necessity lemma I only asserted.** I claim a below-
   frozen-prefix loopback would "regenerate an adopted artifact" — but I never
   modeled the *harm*. The run may demand a CF showing a concrete regression
   (attach over kimmy's committed `spec_kb`, loopback to decompose, `hypothesis.pl`
   overwritten) before it will treat the `gap_below_frozen_prefix` hard-stop as
   load-bearing rather than defensive dead code. ⟦med⟧

4. **The operator-infeasible seed is a WellFormedStart hole I glossed.** When
   `feasible:false` I return `produced:[]` with `startIdx>0` — which is itself
   NOT a WellFormedStart. My loop halts before seeding, so it's safe, but the
   disprove floor will likely probe exactly this and may force `planRecon` to
   normalize the infeasible case (e.g. startIdx←0) rather than emit an ill-formed
   pair. ⟦med⟧

5. **Brief-templating is bigger than the sketch implies.** I hand-waved
   `templatePaths` over `thoughts/<key>` literals. The realize stage, driving real
   tests, may find the path literals are not uniform enough to rewrite
   mechanically (e.g. `thoughts/lean/Proofs/*.lean` globs, `.realize_scratch`
   subpaths) and that a per-brief artifact-key parameterization is required —
   materially more work than one `String.split/join`. ⟦med⟧

6. **The non-degenerate-model bar bites the seed enumeration.** My 3 seeds
   (cold / attach / hole) may be too few; the kimmy gate demands ≥2 distinct
   inhabitants with *varying* values per domain. The model-obligations stage may
   reject the enumeration as degenerate and loop back for more startIdx positions
   and multiple hole placements. ⟦med⟧

7. **Recon itself wants a disprove target.** The mandatory floor runs *after*
   recon and I assumed it targets the recon *claim*. But recon's descriptor is the
   freshest unproven thing in the run — the adversary may be pointed at the
   *descriptor* (e.g., "find a present-but-stale artifact recon marked complete"),
   surfacing a stage-freshness gap C-7 doesn't cover (presence ≠ currency). That
   would be a genuinely new finding the design didn't anticipate. ⟦low-med⟧

**If the real run only confirms §§1–8 and surfaces none of §X:** the workflow
added little here beyond mechanization. **If it lands even #1 or #2:** it
materially corrected the design — which is the whole reason the gate exists.

# RESULT — prediction vs. the real dogfood run

Run: `recon-i8-dogfood` (task `w7ze22lys`), 10 agents, ~607k subagent tokens,
~56 min. Proof-half only (close-world → decompose → model-obligations →
prove-invariants → synthesis), attach-mode against the existing self-spec.
Artifacts in `run-artifacts/`. Compared against the frozen `PREDICTION.md`.

## Bottom line

**The workflow earned its keep — decisively, and in exactly the way the experiment
was designed to detect.** My free-hand prediction got the *direction* right on
every headline bet (§X #1 pivot, §2 labels, §3 consistency) but got the *depth*
wrong in the places that decide soundness. The run surfaced **four concrete
formalization defects I would have shipped**, and it held every
separation-of-authority line that makes its verdicts trustworthy.

Crucially: the prediction's two **high-confidence** blocks (§1 close-world,
§4 prove-invariants) were the ones reality **overturned**. The value wasn't in
the headline I already saw coming — it was in the depth under it.

## Scorecard

| Prediction | Confidence | Reality | Verdict |
|---|---|---|---|
| §2 decompose lands I-8 *prescriptive* + emits clamp-soundness as the stronger claim (not a silent split) | med | Exactly that: `pr_recon_i8_soundness` prescriptive/open **and** `pr_recon_clamp_wellformedstart` added; clean labels, no halt | **HIT** |
| §3 model-obligations: clamp + frozen `consistent`, CFs load-bearing, non-degenerate model | med | clamp + frozen `consistent`; all 6 CFs load-bearing; 3 seeds {0,4,5} + hole | **HIT** (better — see C-7 below) |
| §X #1 I-8 vacuous → pivot to clamp-soundness | (the core bet) | Vacuous **and pivoted** — decompose, model-obligations, and the adversary all converged on clamp-soundness | **HIT + OVERSHOT** |
| §X #2 I-8 may be demoted to behavioral | med-high | Refined to **split**: soundness *contract* stays Lean-statable (structural seed-soundness + clamp-soundness over closed domains) **+** behavioral b12–b15 | **HIT, refined** |
| §X #3 frozenPrefix needs a necessity lemma | med | Stronger: my frozenPrefix theorem is **UNPROVABLE / false-as-stated** (free `AttachRun` fields → a counterexample type-checks) | **LANDED HARD** |
| §1 close-world clean extraction | **high** | `kb-validator` **FAILED tier-2**: 6 referential-integrity breaks (rename-drift orphan `falsifier/1` atoms) | **MISS** |
| §4 I-8 closes axiom-free, 25→28 theorems | low | **0 proven**; all 3 abstained/unprovable; HALT upstream-encoding-failure | **MISS (correctly hedged)** |
| §X #6 non-degenerate bar bites the *enumeration* | med | Prolog met the bar; the deeper issue is non-degeneracy **doesn't transfer to Lean** (free-field types range over arbitrary windows, not the bound seeds) | **HIT, reframed deeper** |
| §X #4 operator-infeasible WFS-hole edge | low | Handled silently by refuse/feasible:false; not surfaced as a finding | not hit |
| §X #5 / #7 (templating cost / recon freshness) | — | realize stage + recon-descriptor adversary not run | N/A |

## The four things the workflow caught that I'd have shipped

1. **`Present` ≡ `StrictLoads` definitional collapse (the real vacuity mechanism).**
   I predicted "I-8 is ~a corollary of I-2." The adversary found it's *worse and
   different*: a **standalone tautology that never references I-2 at all**, because
   my sketch encoded both `Present w i` and `StrictLoads w i` as the *same*
   proposition `∃ s : Stage, w.stageAt i = s`. So the conjunction carries zero
   information and **the "hole" (present-but-not-loading) is unrepresentable**. It
   proved this with a buildable witness (`i8_is_trivial_tautology`,
   `present_eq_strictloads := rfl`). I did not foresee this specific bug.

2. **My frozenPrefix theorem is outright false-as-stated.** `lean-expert` found
   `i8_frozen_prefix_floor` *unprovable* — the negation type-checks because
   `AttachRun` fields are free. My PREDICTION §X#3 said "needs a necessity lemma";
   reality is the sketch is refutable and needs the floor encoded as a structural
   invariant.

3. **close-world referential-integrity defect.** I rated close-world ⟦high⟧/clean.
   `kb-validator` caught 6 tier-2 breaks — rename drift like
   `recon_computes_logic_verdict` vs the declared `recon_computes_a_logic_verdict`,
   and orphan `falsifier/1` references. The file *loads* but is internally
   inconsistent. A green strict-load hid it; the validator didn't.

4. **Non-degeneracy doesn't cross the Prolog→Lean boundary.** The Prolog model is
   genuinely non-degenerate (3 seeds + hole), but that buys nothing for the Lean
   theorem whose `Window`/`Seed` types have free fields ranging over *arbitrary*
   windows. The Prolog falsification is real but **asserts something different from
   what the Lean theorem says** — a boundary failure my prediction never named.

## The discipline that held (why to trust the verdicts)

- **The Orbital Inversion line held under load.** `model-obligations` *refused* to
  launder its own prefix-check into a `consistent` verdict on the abstract I-8 —
  it emitted **OPEN + gap_reason** and deferred the non-vacuity judgment to
  prove-invariants (C-7). The exact separation the C-2→"Orbital Inversion" rename
  names, observed working.
- **`lean-expert` refused to fake-close.** No `decide`/`native_decide`/`generalize`
  foul; it *abstained* with "trivially provable, not load-bearing," left the source
  `by sorry`, and routed the fix upstream rather than manufacturing a green proof.
- **Structural independence paid off (the Sagittarius A\* thesis).** Two
  independent agents — `lean-expert` (un-primed about vacuity) and `lean-adversary`
  (primed) — converged on the *same* encoding failure, and the adversary built
  green Lean witnesses to back it. Convergence-by-independent-reduction is the
  whole bias defense the project is named for.

## Honest confound

I *did* prime the `lean-adversary` brief toward "is this a corollary of I-2 / name
the clamp-soundness pivot." So the *direction* of the pivot was partly fed in. What
was **not** fed in and is therefore the genuine signal: the `Present ≡ StrictLoads`
mechanism, the "not even a corollary, a standalone tautology" sharpening, the
*buildable* witnesses, the false-as-stated frozenPrefix theorem, and the
independent `lean-expert` HALT (its brief only said "don't fake it"). The depth
exceeds the priming.

## What the run produced as the actual remediation

The dogfood didn't just say "vacuous" — it handed back a buildable fix plan:

- **(A) Structural seed-soundness.** Replace free-field `Seed`/`Window` with
  inductives `StartOf`/`PresentAt`/`StrictLoadsAt` (one ctor per ground
  `op_recon_*` fact) so `i < startIdx` becomes load-bearing and the hole is
  Lean-refutable. (Adversary verified this is statable.)
- **(B) Clamp-soundness.** Define `planRecon` as a *real* total function over the
  closed `ProposedWin` enum (attach clamps, operator refuses), then
  `planRecon_wellformedstart` is provable by construction, not vacuously.
- **Teeth split (not exiled to JS):** keep the soundness *contract* in Lean; add
  behavioral `b12–b15` tests for the runtime clamp/refuse *mechanism*.
- **Fix the close-world rename-drift orphans** before re-running.

## Repo state after the run

- Proven baseline **intact**: `self-spec/target-world.pl` → **7/7 consistent**; the
  7 existing Lean proofs untouched; Prolog self-spec untouched (zero git diff).
- **Additive, unproven:** `self-spec/lean/Proofs/I8ReconSoundness.lean` (3 `sorry`
  stubs) + a one-line import in `self-spec/lean/Proofs.lean`. `lake build` is green
  (stubs type-check; the proofs are *not* closed). Recommendation: move this stub
  file out of the proven tree (into `thoughts/recon-upgrade/`) until the (A)/(B) re-encoding
  closes it, so "the proven tree is all-proven" stays true.
- `run-artifacts/`: 7 files (5 `.pl` strict-load; 1 validation JSON showing the
  tier-2 failure; 1 `.lean` vacuity-refutation record).

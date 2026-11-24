# ScientificMethod.lean

The Lean file of the handoff of 2026-11-18 (the Sagittarius MindHole handoff by Astra, brought by
Ty). It is the formal statement behind the verdicts of `orbit-kb`. The file here is the file of the
handoff, byte for byte (sha256 `78012c28082205683ca7ca0926e08693b2e63d01ed5f56068e8843a872ae8f75`).
Do not edit it: a new version of the handoff replaces it.

The file imports only `Std`, which ships with Lean. It is not a Lake project and needs no packages:

```sh
lean kb/proofs/scientific_method/ScientificMethod.lean      # exit 0, no output
python3 docs/check_lean.py scientific                       # the check of the suite
bash kb/tests/warrants_conformance.sh kb/bin/orbit-kb       # the tool gives the verdicts of the Timer theorems
```

## What it states

All names are in the namespace `ScientificMethod`.

- `Warrants predicted compatible v`: when the verdict `v` is warranted. `predicted` says which
  outcomes the claim predicts. `compatible` says which outcomes could have produced the reading,
  under the measurement premises.
  - `meets`: each compatible outcome is predicted.
  - `conflicts`: no compatible outcome is predicted.
  - `unresolved`: one compatible outcome is predicted, and one compatible outcome is not.
- `unique_verdict`: when some outcome is compatible with the reading, exactly one of meets,
  conflicts and unresolved is warranted.
- `conflict_rejects_joint`: a conflict rejects the conjecture, its premises and the measurement
  premises taken together. It does not reject the conjecture alone. To keep the conjecture, a
  premise or a measurement premise must be false.
- `agreement_establishes_run`: when the verdict is meets and the measurement premises hold, the
  outcome of this run is as predicted. It says nothing about other runs.
- `Timer.reading_600`, `Timer.reading_611`, `Timer.reading_615`: the timer example, in tenths of a
  second. The prediction is 590 to 610. The error bound of the clock is 2. The reading 600 warrants
  meets, the reading 611 warrants unresolved, the reading 615 warrants conflicts.
- `Timer.late_run_refutes_universal`: with the reading 615, an uninterrupted run and an accurate
  clock, the conjecture about every uninterrupted run is false.
- `Statistical.equal_likelihood_no_preference`: two models that give the same event the same
  likelihood are not told apart by that event.
- `revision_preserves_record`: a revision adds an entry to the record. The earlier entries stay.

## The verdict rule of the tool follows `Warrants`

`orbit-kb run` records one result for each run of a check. The verdict of a run is meets (result
`pass`), conflicts (result `fail`) or unresolved (result `unresolved`): exactly one, as
`unique_verdict` states. A check that cannot decide exits 77, and the tool records unresolved.

`kb/tests/warrants_conformance.sh TOOL` runs the timer example through the tool: the readings 600,
611 and 615 must get the verdicts of `Timer.reading_600`, `Timer.reading_611` and
`Timer.reading_615`.

## The check

`python3 docs/check_lean.py scientific` copies the file to a temporary folder and runs Lean on the
copy. It fails when Lean reports an error or a `sorry`, when the file declares an axiom, when a
declaration uses an axiom other than `propext`, `Classical.choice` and `Quot.sound` (so `sorry`
fails), or when one of the nine theorems above is not a theorem of the file. The tests of the check
are in `docs/test_check_lean.py` (class `ScientificMethod`).

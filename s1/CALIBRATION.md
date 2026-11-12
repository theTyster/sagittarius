# Calibration of the question set (0.3.0 S-C, 2026-11-12)

Cases: `s1/fixtures/calibration.json` (41 cases: the 25 known cases and 16 invented cases for
`h_questions` and `h_proof`). Run: `python3 s1/calibrate.py`. Live System 1 model, one call per case.
A label agrees when the answer is in the expected band (yes at 0.7 or more, no at 0.3 or less; a
choice at 0.5 or more).

| Question | Agree | Labels |
|---|---|---|
| h_work | 13 | 16 |
| h_divergence | 17 | 18 |
| h_change_of_plan | 5 | 6 |
| h_effort | 8 | 8 |
| h_language | 7 | 8 |
| h_questions (new) | 8 | 8 |
| h_proof (new) | 14 | 14 |

The table is the first full run, except `h_proof`, which is the run with the final wording
(14 cases that carry a proof label, run once). Misses of the full run, all inside the unsure band
except one: k1 change of plan (0.37), k1 language (0.46), k4 divergence (0.35), k6 work (0.48),
k11 work (0.46), r9 work (0.41), and r8 proof (0.74, wrong yes: "try to break each claim").
The last one is why `h_proof` says that a test or an attempt to break the work is not a proof.

Wording tried for `h_proof` (on the 14 cases with a proof label): the first wording agreed on 13
(r8 yes); a wording that asked for "every input, not a run of checks" agreed on 13 (lost "Can you
prove that?" at 0.65); the final wording agreed on 14. One run each: this is a small set, so read
14 of 14 as "no miss seen", not as a rate.

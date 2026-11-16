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

## The fan-out (2026-11-15; not a release)

The table above is about the plain questions, which did not change. With the fan-out on (the
default), `h_divergence`, `h_change_of_plan`, `h_questions` and `h_effort` come from `hook.combine`.
Live check on 46 fresh cases (`research/2026-11-15-question-eval/fresh/`, labels by the agent, written
after the rules were fixed and before the first run; second run shown):

| Signal | Plain | Fan-out |
|---|---|---|
| divergence | 29 of 37, 1 wrong | 35 of 37, 1 wrong |
| change of plan | 12 of 26, 3 wrong | 22 of 26, 1 wrong |
| questions | 14 of 18, 2 wrong | 15 of 18, 1 wrong |
| effort | 4 of 12, 1 wrong | 12 of 12 |
| reversal | no question | 11 of 11 |

The reversal rule was changed after the first run on these cases (a rule that hid a reversal in a
part that also changes the request was removed), so 11 of 11 is a tuned number. The first run gave
divergence 36 of 37 and questions 15 of 18 with none wrong: one or two labels move between runs.
The larger sets are in `research/2026-11-15-question-eval/README.md`.

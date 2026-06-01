@README.md

## Operating notes (sagittarius-specific)

- **The specialists live in orbital, not here.** This repo *calls* the ~17 `shifting:*` agents (agent-of-truth, lean-expert, the adversaries, …); they ship in the [orbital](https://github.com/theTyster/orbital) repo. Don't expect to find or edit them here.
- **The substrate is canonical.** When behavior or a doc disagrees with orbital's `orchestration-substrate.md` or the Prolog substrate (`self-spec/hypothesis.pl`, `self-spec/target-world.pl`), the substrate wins. See `docs/decisions.md`.
- **Historical-doc path mapping.** `FINDINGS.md`, `HANDOFF.md`, and everything under `self-spec/` were authored at `orbital/experiments/pipeline-workflow/`. Read `thoughts/X` as `self-spec/X`, and `experiments/pipeline-workflow/X` as the repo root. The design spec they cite is `docs/design-spec.md`.
- **Verify before trusting.** `swipl -q -g "consult('self-spec/target-world.pl'), aggregate_all(count, verdict(_,consistent), N), format('~w/7~n',[N]), halt"` → `7/7`; `node --test self-spec/tests/*.test.js` → 24+8 green. Re-checking the Lean proofs needs Lean 4 + Mathlib (the `.lake/` build cache is intentionally git-ignored and regenerable).
- **Commit discipline.** The repo's genesis commits were operator-authorized directly. The operator runs a parallel mind-map verification pass before commits in *orbital*; confirm whether that halt governs this repo before adopting a blanket pre-commit halt here.

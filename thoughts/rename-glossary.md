# Rename glossary (draft, waiting for Ty's approval)

Orbital Shifting became Sagittarius on 2026-10-22. The brand is already renamed. This file
proposes new words for the orbit metaphor. Nothing below is applied until Ty approves it.

## The theme

Sagittarius is the archer, and the constellation that holds Sgr A*, the black hole that the
Event Horizon Telescope imaged by having independent teams converge. Two families of words
fit:

- **Archery** for the actions: sighting in, the shot, the end (a round of arrows), the flight.
- **Observation** for the checks: the existing words SURVEY, SPECTRUM, and PARALLAX already
  belong here and stay.

Words that are not orbital stay as they are: signal, shift up, lean back, survey, decompose,
build, fulfill, disprove, explain, delivery.

## Proposed map

| Today | Proposed | Why | Count in the prompt |
|---|---|---|---|
| discovery orbit | **sighting** (sighting in) | An archer sights in before shooting for score: find where the arrows go, adjust, then shoot. | 43 "discovery", many as "discovery orbit" |
| build orbit | **the shot** | Specify, build, check, deliver. | 12 |
| orbit (either loop) | **the draw** | The whole motion from aim to release. | 90 |
| lap | **end** (archery's word for one round of arrows) | Each end: shoot, walk to the target, read it, adjust. Alternative: **round**. | 20 |
| burn (Lean proof of a universal claim) | **bullseye** | The one hit that leaves no doubt. Alternative: **seal**. | 28 |
| FLYBY (SMT, combinations) | **SPREAD** | A spread of arrows covers the combinations. | 7 |
| TRAJECTORY (TLA+, sequences) | **FLIGHT** | The path an arrow takes, step by step. | 4 |
| `orbit-kb` (the CLI) | **`quiver`** | The quiver holds the arrows; the KB holds the facts. Free on PATH. Alternative: `sagit-kb`. | the CLI, the README, the tests |

## What changes, and the cost

1. **Prose only** (the prompt, the decks, the READMEs): low risk. The decks need the
   builder rerun.
2. **The CLI name**: `kb/bin/orbit-kb` becomes `kb/bin/quiver`. `install.py` links the
   new name. The library path, the `ORBIT_KB_*` variables, and the test names follow.
3. **Predicates in the rules** (`burn/1`, `burn_requested/1`, `burn_open/1`,
   `burn_proved/1`, `burn_waived/1`, `burn_reason/2`, `lap_done/…`): these appear in every
   KB already written. KBs in client work would stop loading unless the old names stay as
   aliases. The proposal is to keep the predicate names, or to rename them with aliases
   for one release.

Records in `thoughts/` keep their words as written.

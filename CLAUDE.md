# CLAUDE.md

A map, not a manual. Open the linked file rather than expecting the answer here.
For what the project is, its install and layout, see @README.md.

## Where things live

| Area | Open first |
|---|---|
| The live prompt | `prompt/SAGITTARIUS.md`. Installed as `~/.claude/sagittarius/SAGITTARIUS.md`, and appended to work sessions by `claude()` in Ty's dotfiles (`shared/copy/.zshenv`). Design notes: `thoughts/orbital-shifting-system-prompt-draft.md`. |
| `orbit-kb` | `kb/share/orbit-kb/README.md` (full reference); CLI `kb/bin/orbit-kb`; contract `thoughts/orbit-kb-contract.md`; tests `kb/tests/test_orbit_kb.sh` |
| Decks | `site/index.html` (full) and `site/essentials.html` (generated: rerun `python3 site/build_essentials.py` after any edit to `index.html`) |
| Evals | `evals/evals.json`, `evals/run.sh` (goes through the real `claude()`, so it runs only under the work account) |
| AIDLC (retired) | `aidlc/README.md` |
| Records and history | `thoughts/README.md` maps old dotfiles paths and hashes to this repo |

## Rules that are not in the files

- The name is **Sagittarius** (one g, two t's). Records in `thoughts/` keep the old name,
  Orbital Shifting, as written. Do not rewrite them.
- `install.py` makes links into this checkout. After moving the checkout, run it again.
- Run CPU-heavy commands through `heavy` (the test suite, `lake build`, solvers).
- The Lean projects under `kb/tests/burn_model` and `thoughts/discovery-orbit` use
  sharlean shared libraries. Never run `lake update` or `lake cache get` in them.
- Commit style is conventional commits. The repo is on Ty's Gitea
  (`git.mylegendary.quest/ty/sagittarius`); push only when Ty says so.

# CLAUDE.md

A map, not a manual. Open the linked file rather than expecting the answer here.
For what the project is, its install and layout, see @README.md.

## Where things live

| Area | Open first |
|---|---|
| The live prompt | `prompt/SAGITTARIUS.md`. Installed as `~/.claude/sagittarius/SAGITTARIUS.md`. Each user appends it to their sessions (see "Install" in `README.md`). |
| `orbit-kb` | `kb/share/orbit-kb/README.md` (full reference); CLI `kb/bin/orbit-kb`; contract `kb/CONTRACT.md` (the only source of what the tests expect); tests `kb/tests/test_orbit_kb.sh` |
| `orbit-kb` help topics | `kb/share/orbit-kb/help/*.txt` (read by `orbit-kb help TOPIC`). The agent-facing syntax and recipes live here, not in the prompt. A new fact or lint code goes in its topic. |
| Decks | `site/index.html` (full) and `site/essentials.html` (generated: rerun `python3 site/build_essentials.py` after any edit to `index.html`) |
| Why the process is the way it is | `docs/PHILOSOPHY.md`: the beliefs under the design, open questions, and how to judge a change. |
| Evals | `docs/REFINING.md` first (the loop for changing the prompt on an eval result). Planning: `evals/evals.json`, `evals/run.sh`. Tool use: `evals/tools.json`, `evals/run_tools.sh`; held-out set `evals/heldout/`. Both go through the real `claude()`, so they need an unlocked credential. |
| Old design notes and records | Not in the tree: `git show thoughts-archive:thoughts/<file>`. The AIDLC files are in history too. Those notes came from the author's dotfiles repo, so their paths and hashes point there. |

## Rules that are not in the files

- The name is **Sagittarius** (one g, two t's). It was called Orbital Shifting until
  2026-10-22; commit messages and archived records keep that name.
- `install.py` makes links into this checkout. After moving the checkout, run it again.
- Run CPU-heavy commands (the test suite, `lake build`, solvers) through your job queue if you have
  one. Keep each check narrow.
- `kb/tests/burn_model` is a Lean project with no packages, so `lake build` needs no network.
  Do not run `lake update` or `lake cache get` in a Lean project that shares libraries.
- Commit style is conventional commits. Push only when the owner of the checkout says so.

# CLAUDE.md

A map, not a manual. Open the linked file rather than expecting the answer here.
For what the project is, its install and layout, see @README.md.

## Where things live

| Area | Open first |
|---|---|
| The live prompt | `prompt/SAGITTARIUS.md`. Installed as `~/.claude/sagittarius/SAGITTARIUS.md`. Each user appends it to their sessions (see "Install" in `README.md`). |
| Hub kit | `hubkit/README.md` (what it is); `hubkit/INSTRUCTIONS.md` (start a hub); `hubkit/UPGRADING.md`. Imported from hubflow-starter with its history. Tests: `python3 hubkit/hub/.claude/scripts/hubflow-test.py` and `python3 hubkit/tools/hubkit-test.py`. |
| The pane prompts | `prompt/PANES.md` (shared) and `prompt/panes/<role>.md` (discovery, build, review). See "Panes" in `README.md`. |
| `orbit-kb` | `kb/share/orbit-kb/README.md` (full reference); CLI `kb/bin/orbit-kb`; contract `kb/CONTRACT.md` (the only source of what the tests expect); tests `kb/tests/test_orbit_kb.sh` |
| `orbit-kb` help topics | `kb/share/orbit-kb/help/*.txt` (read by `orbit-kb help TOPIC`). The agent-facing syntax and recipes live here, not in the prompt. A new fact or lint code goes in its topic. |
| `repo-map` | `kb/share/repo-map/README.md` (spec, formats, input hash); CLI `kb/bin/repo-map`; tests `kb/tests/test_repo_map.sh` |
| `s1/` | `s1/README.md`. The Jev client `s1/jev.py`; the `UserPromptSubmit` hook `s1/hook.py` and its question set `s1/questions.json`; the tempering tool `s1/temper.py`; the status line segment `s1/statusline.py`. Tests: `python3 -m unittest s1.test_jev s1.test_hook s1.test_temper s1.test_statusline`. |
| Project KB module | Planned (T06). No file yet; it gets its row when it lands. |
| Question view | Planned (T10): `orbit-kb view questions`. No file yet; it gets its row when it lands. |
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

# Sagittarius

A way for a human and an AI agent to agree on what is being built, with only as much
rigor as the work needs.

**Start light. Shift up on a signal. Lean back when it is resolved.** Most requests get a
direct answer or a light path with one check. When a miscommunication shows up, the agent
adds rigor one step at a time: a knowledge base (KB) of claims and questions, more rounds
of questions, and, for a claim about every case, a Lean proof.

The idea in ten slides: [`site/essentials.html`](site/essentials.html). The full story, with
the timeline and every mechanism, is in 30 slides: [`site/index.html`](site/index.html).

## What it is

| Part | Where | What it does |
|---|---|---|
| System prompt | [`prompt/SAGITTARIUS.md`](prompt/SAGITTARIUS.md) | One self-contained file, appended to the agent's session. |
| `orbit-kb` | [`kb/bin/orbit-kb`](kb/bin/orbit-kb), rules in [`kb/share/orbit-kb/`](kb/share/orbit-kb/) | A CLI that writes, lints, and queries s(CASP) KBs. It also records Lean proofs (`orbit-kb prove`). Full reference: [`kb/share/orbit-kb/README.md`](kb/share/orbit-kb/README.md). |
| Dependencies | | [SWI-Prolog](https://www.swi-prolog.org) 9+ with the [s(CASP)](https://github.com/SWI-Prolog/sCASP) pack. [Lean 4](https://lean-lang.org), but only for proofs. |

## Install

```sh
sudo dnf install swi-prolog-nox                       # or your platform's SWI-Prolog 9+
swipl -g "pack_install(scasp, [interactive(false)])" -t halt
ln -s ~/.local/share/swi-prolog/pack/scasp/scasp ~/.local/bin/scasp
./install.py                                          # links the CLI, rules, and prompt
orbit-kb doctor
```

`install.py` uses only the Python standard library and works the same on Linux, macOS,
and Windows. It makes three links: `~/.local/bin/orbit-kb`, `~/.local/share/orbit-kb`, and
`~/.claude/sagittarius` (the prompt). Run `./install.py --check` to see their status. On
Windows, symlinks need Developer Mode.

Then add the prompt to your Claude Code sessions. Claude Code can append text to its system
prompt with `--append-system-prompt`:

```sh
claude --append-system-prompt "$(cat ~/.claude/sagittarius/SAGITTARIUS.md)"
```

To do this in every session, wrap the command in a shell function or an alias. The author's
`claude()` function in a `.zshenv` file is one example. Another agent tool works the same way:
put the text of `SAGITTARIUS.md` in its system prompt.

## Layout

| Path | Contents |
|---|---|
| `prompt/` | The live system prompt. |
| `kb/` | `orbit-kb`: `CONTRACT.md` (what the tests hold it to), `bin/`, `share/orbit-kb/` (core rules, the build and discovery modules, the Lean probe), `tests/` (the black-box suite, fixtures, and a Lean model of the burn rules). |
| `site/` | The two decks, published at https://thetyster.github.io/sagittarius/ (the short deck; the full deck is at `full.html`) by `.github/workflows/pages.yml` on each push to `main` that touches `site/`. `essentials.html` is generated from `index.html` by `build_essentials.py`; the workflow fails if it is stale. |
| `evals/` | One-shot planning evals for the prompt, with graded runs. |

## History

This repository first held the Sagittarius Workflow experiment (May to July 2026). It is
kept at the tag `workflow-experiment`. Then come the AIDLC era (from September 2026, retired 2026-10-21) and
Orbital Shifting (October 2026). On 2026-10-22 the method moved here and took the Sagittarius
name. The AIDLC files are in git history.

The design notes and records from those eras were in `thoughts/`. They are in git
history, at the tag `thoughts-archive`. Those notes were written in the author's dotfiles
repository, before the method moved here. Their file paths and commit hashes point to that
repository, not to this one.

## Tests

```sh
bash kb/tests/test_orbit_kb.sh             # the orbit-kb suite (about a minute)
kb/tests/burn_model/check.sh               # the Lean model of the burn rules (needs Lean 4)
python3 site/build_essentials.py           # regenerate the short deck
```

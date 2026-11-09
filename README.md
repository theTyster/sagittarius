# Sagittarius

A way for a human and an AI agent to agree on what is being built, with only as much
rigor as the work needs.

**Start light. Shift up on a signal. Lean back when it is resolved.** Most requests get a
direct answer or a light path with one check. When a miscommunication shows up, the agent
adds rigor one step at a time: a knowledge base (KB) of claims and questions, more rounds
of questions, and, for a claim about every case, a Lean proof.

**Where it sits.** Sagittarius is an extension of the harness, between the human-agent
interface (the harness, such as Claude Code) and the software factory (the interface between the
agent and the project). It is an inference, reasoning and knowledge-graph layer: Prolog KBs,
Lean proofs, and a small model (System 1) that reads each message.

The idea in thirteen slides: [`site/essentials.html`](site/essentials.html). The full story, with
the timeline and every mechanism, is in 35 slides: [`site/index.html`](site/index.html).

## Use it

Only the hub, with no Prolog and no Lean? That is the informal release: see [`hubkit/README.md`](hubkit/README.md).

1. **Install.** Install SWI-Prolog 9+, then run `./install.py` from this folder. It links
   `orbit-kb`, `repo-map`, and the prompt into your home directory. Check it with `orbit-kb doctor`
   and `./install.py --check`. See "Install" below for the prompt flag.
2. **Start a hub.** Give `hubkit/` to your agent and say "follow INSTRUCTIONS.md". It reads
   `hubkit/INSTRUCTIONS.md`, asks up to three questions, and sets up the hub. See "Hub kit" below.
3. **Add the System 1 hook (optional).** The hook asks the System 1 model about each prompt before the agent
   answers. Follow `s1/README.md`. The hook is manual: you paste a snippet into your
   `~/.claude/settings.json`. No script writes that file. `install.py` never does.

## What it is

| Part | Where | What it does |
|---|---|---|
| System prompt | [`prompt/SAGITTARIUS.md`](prompt/SAGITTARIUS.md) | One file, appended to the agent's session. It states the philosophy in short; the procedure is in `orbit-kb help`. |
| `orbit-kb` | [`kb/bin/orbit-kb`](kb/bin/orbit-kb), rules in [`kb/share/orbit-kb/`](kb/share/orbit-kb/) | A CLI that writes, lints, and queries Prolog KBs, with SWI-Prolog as the only engine. It also records Lean proofs (`orbit-kb prove`). Full reference: [`kb/share/orbit-kb/README.md`](kb/share/orbit-kb/README.md). |
| Dependencies | | [SWI-Prolog](https://www.swi-prolog.org) 9+. [Lean 4](https://lean-lang.org), but only for proofs. |

## Install

```sh
sudo dnf install swi-prolog-nox                       # or your platform's SWI-Prolog 9+
./install.py                                          # links the CLI, rules, and prompt
orbit-kb doctor
```

`install.py` uses only the Python standard library and works the same on Linux, macOS,
and Windows. It makes four links: `~/.local/bin/orbit-kb`, `~/.local/bin/repo-map`, `~/.local/share/orbit-kb`,
and `~/.claude/sagittarius` (the prompt). Run `./install.py --check` to see their status. On
Windows, symlinks need Developer Mode.

Then add the prompt to your Claude Code sessions. Claude Code can append text to its system
prompt with `--append-system-prompt`:

```sh
claude --append-system-prompt "$(cat ~/.claude/sagittarius/SAGITTARIUS.md)"
```

To do this in every session, wrap the command in a shell function or an alias. The author's
`claude()` function in a `.zshenv` file is one example. Another agent tool works the same way:
put the text of `SAGITTARIUS.md` in its system prompt.

## Panes

You can run Sagittarius as three long-lived Claude sessions that work together, one for
each role: **review**, **discovery**, and **build**. New work starts in review, which decides if
a report is a regression or a gap. Each session gets the main prompt, then
two more files from `prompt/` (installed under `~/.claude/sagittarius/`):

| File | What it holds |
|---|---|
| `PANES.md` | What the three roles are, and how they hand work to each other. The same for each session. |
| `panes/<role>.md` | The role prompt: what this one session does and does not do. |

Start each session in its own terminal, with its role in `ROLE`:

```sh
ROLE=review
p=~/.claude/sagittarius
claude --name "sagittarius-$ROLE" --append-system-prompt "$(cat "$p/SAGITTARIUS.md" "$p/PANES.md")

Your window: $ROLE.

$(cat "$p/panes/$ROLE.md")"
```

Any terminal multiplexer or editor can hold the three sessions. The author starts them as
three tmux windows named after the roles. That launcher is not part of this repository.

## Hub kit

`hubkit/` is the hub kit: a template for a hub, one git repo that a few named Claude Code
sessions share as working memory (a weekly calendar plus flow state in SQLite). To start a hub from
it, give `hubkit/` to your agent and say "follow INSTRUCTIONS.md" (`hubkit/INSTRUCTIONS.md`). The
agent asks up to three questions, sets up the hub, and checks each step. To take a new release into
a hub, see `hubkit/UPGRADING.md`. Its tests run from the repo root:

```
python3 hubkit/hub/.claude/scripts/hubflow-test.py
python3 hubkit/tools/hubkit-test.py
```

## Layout

| Path | Contents |
|---|---|
| `prompt/` | The live system prompt, and the prompts for the three panes (`PANES.md`, `panes/`). |
| `kb/` | `orbit-kb`: `CONTRACT.md` (what the tests hold it to), `bin/`, `share/orbit-kb/` (core rules, the build and discovery modules, the Lean probe), `tests/` (the black-box suite, fixtures, and a Lean model of the burn rules). |
| `site/` | The two decks, published at https://thetyster.github.io/sagittarius/ (the short deck; the full deck is at `full.html`) by `.github/workflows/pages.yml` on each push to `main` that touches `site/`. `essentials.html` is generated from `index.html` by `build_essentials.py`; the workflow fails if it is stale. |
| `s1/` | System 1, the hook that adds hints to each message. The install is manual. It is off until the question set is approved. See `s1/README.md`. |
| `hubkit/` | The hub kit: a template for a hub of named sessions (see "Hub kit"). |
| `docs/` | `PHILOSOPHY.md` (why the process is as it is), `REFINING.md`, `PROMPT-MOVES.md`, and the checks for the prompt and the panes (`check_*.py`). |
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

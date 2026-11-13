# The MindHole Kit

The **MindHole Kit** is the template that makes a hub for Sagittarius. It is part of Sagittarius
(<https://github.com/theTyster/sagittarius>), with its own version line (`MindHole Kit <version>`). It is
the **informal release**: a template for a **hub**, one git repo that a few long-lived Claude Code
sessions share as their working memory. A hub made from it is a MindHole. It uses only plain files, git and SQLite. You do not need Prolog, Lean, or any other part of
Sagittarius to use it.

It has three ideas:

- **The hub is a calendar.** `W0/` is this week and `W5/` is five weeks back. A rotation each Monday
  retires the oldest week, and git history keeps it. Durable knowledge moves into root files and
  skills before a week rolls off.
- **Flow state is in SQLite.** Asks waiting on a person, in-flight threads, holds and handoffs
  are rows in `flow/flow.db`, written only by `hubflow.py`. Each write also exports JSONL, which
  git tracks. An item nobody renews comes due, and each rotation records one decision for every due
  item (keep, lapse, capsule or escalate) instead of a silent lapse.
- **The principles come with it.** `PRINCIPLES.md` comes from the Sagittarius prompt: a short
  file, in plain words, that names the prompt's version and, for each part, the section of the
  prompt it comes from (clear, accurate, honest, fast; state the hypothesis and go on; start light
  and shift up on a signal; no party grades its own work; disclose guesses). The hub's `CLAUDE.md`
  imports it, so every agent reads it at start.

**Versions.** The MindHole Kit and Sagittarius keep two version numbers: `MindHole Kit <version>` (in
`kit.json`) and `Sagittarius <version>` (the last line of the prompt). The MindHole Kit pairs with
Sagittarius 0.3: its `PRINCIPLES.md` comes from that prompt, and a formal hub runs the orbit-kb of
the same Sagittarius checkout. `UPGRADING.md` says it too.

Named sessions (one per role, each with its own `HUB_SESSION`) are set up outside the hub, for
example in your dotfiles, because they belong to one machine. The hub knows only their names, in
`flow/seed.json`.

**Briefing for people:** open `docs/index.html` in a browser.

## Install

Needs Python 3 (stdlib only) and git: no bash, no other shell tools, no Prolog and no Lean.

`KIT` is this directory (`hubkit/` in a Sagittarius checkout) and `HUB` is a new directory for the
hub. Each may be absolute or relative to the current directory. Each line below is one `git` or
`python3` command, so any shell runs it (write `$KIT` and `$HUB` the way your shell writes them):

```sh
git init -q "$HUB"
python3 "$KIT/tools/hubkit.py" install --hub "$HUB" --edition informal
python3 "$HUB/.claude/scripts/hubflow.py" --hub "$HUB" init
python3 "$KIT/tools/hubkit.py" status --hub "$HUB"
python3 "$HUB/.claude/scripts/hubflow.py" --hub "$HUB" check
```

The last two lines check the new hub. `hubkit.py status` shows you that each shipped file is the
kit's own (`unchanged`); `hubflow.py check` shows you that the ledger and its git copy agree (exit
0). The install runs no test suite: the tests test the kit, not your hub (see "Tests" below; a UAT
install of the kit runs them). `--edition informal|formal` chooses the edition (informal when
omitted; which `orbit-kb` is on the PATH plays no part), `.hub-template.json` records it, and an
upgrade keeps it. `hubkit.py edition --hub "$HUB" formal` switches a hub later (a dry run without
`--yes`). A formal hub also records what it runs (its orbit-kb copy, the
Sagittarius prompt and the pane files, each with its version) and `hubkit.py status` prints them in
its `runs` lines: each MindHole runs its own pinned version. For a guided setup, give this directory to your agent and say: **"follow
INSTRUCTIONS.md"**. It asks you first what the hub is for, and keeps your answer word for word in the
hub's `CLAUDE.md`; then where the hub lives, its sessions and people, its tracker, and whether this is
a UAT install. It sets up the hub and checks each step.

## What the informal release keeps

The hub has five informal stores: the flow ledger (`flow/`), the memory files (`CLAUDE.md`,
`PRINCIPLES.md`, `HEURISTICS.md`, `TECHNOLOGIES.md`), the weeks (`W0/` to `W5/`), the bespoke tools
(listed in `TECHNOLOGIES.md`), and the tracker (outside the hub, by pointer). An informal hub gets
the informal `HUB-CORE.md`, `CLAUDE.md` and skills (from `editions/informal/`): their rules name only
these five stores, and say where each fact kind is kept. The formal stores (a spec KB per ticket and
a project KB, written with `orbit-kb`) come with the formal edition; the Sagittarius `README.md`
says how to install them.

## Take a new release

Your hub changes from day one, so a release can't simply be merged into it. Instead:

- Files the hub owns (`CLAUDE.md`, `HEURISTICS.md`, `flow/seed.json`, …) are never touched by an
  upgrade. Shipped rules live in `HUB-CORE.md` and `PRINCIPLES.md`, which `CLAUDE.md` imports.
  Local changes to a shipped skill go in a `LOCAL.md` next to it.
- `.hub-template.json` in your hub records the release it came from and a checksum of each shipped
  file. So `tools/hubkit.py` knows which shipped files you changed.
- An upgrade replaces the shipped files you did not change. For the ones you did change, your agent
  applies each change by its intent, following `UPGRADING.md`, and shows you the diff.

Say to your agent: **"upgrade the hub to the new template; follow UPGRADING.md in the new release."**

## Layout

| Path | What |
|---|---|
| `INSTRUCTIONS.md` | Set up a new hub (for the agent) |
| `UPGRADING.md` | Apply a release to an existing hub (for the agent), one section per release |
| `kit.json` | The version, and which files are *engine* (shipped) or *owned* (the hub's) |
| `tools/hubkit.py` | `install`, `status`, `upgrade`, `done`, `edition` |
| `hub/` | The files of a new hub, at their paths in the hub (the formal edition) |
| `editions/informal/` | The files that the informal edition takes instead (`kit.json`, `editions`) |
| `docs/` | The briefing page |

## Tests

```
python3 -I tools/hubkit-test.py --mutants
python3 -I hub/.claude/scripts/hubflow-test.py --mutants
```

Each suite also runs a set of mutants (deliberately broken copies of the tool). Every mutant must
fail at least one test, which shows that the tests can catch the defect. The mutants of
`hubflow-test.py` take an hour or more on a loaded machine; it prints one line per mutant as each
one ends.

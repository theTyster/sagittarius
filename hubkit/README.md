# hubflow-starter

A template for a **hub**: one git repo that a few long-lived Claude Code sessions share as their
working memory. It has three ideas:

- **The hub is a calendar.** `W0/` is this week and `W5/` is five weeks back. A rotation each Monday
  retires the oldest week, and git history keeps it. Durable knowledge moves into root files and
  skills before a week rolls off.
- **Flow state is in SQLite.** Asks waiting on a person, in-flight threads, holds and handoffs
  between sessions are rows in `flow/flow.db`, written only by `hubflow.py`. Each write also exports
  JSONL, which git tracks. Items lapse when nobody renews them.
- **Named sessions, one per role**, each with an identity that the db records on every write.

**Briefing for people:** <https://thetyster.github.io/hubflow-starter/> (also `docs/index.html`).

## Start a hub

Give this repo to your agent and say: **"follow INSTRUCTIONS.md"**. It asks you up to three
questions, sets up the hub, and checks each step.

## Take a new release

Your hub changes from day one, so a release can't simply be merged into it. Instead:

- Files the hub owns (`CLAUDE.md`, `HEURISTICS.md`, `sessions/ROLES`, …) are never touched by an
  upgrade. Shipped rules live in `HUB-CORE.md`, which `CLAUDE.md` imports. Local changes to a
  shipped skill go in a `LOCAL.md` next to it.
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
| `tools/hubkit.py` | `install`, `status`, `upgrade`, `done` |
| `hub/` | The files of a new hub, at their paths in the hub |
| `docs/` | The briefing site |

## Tests

```
python3 -I tools/hubkit-test.py --mutants
python3 -I hub/.claude/scripts/hubflow-test.py --mutants
```

Each suite also runs a set of mutants (deliberately broken copies of the tool). Every mutant must
fail at least one test, which shows that the tests can catch the defect.

Needs Python 3 (stdlib only). `sessions/launch.sh` needs bash 4+ and `jq`.

# 📨 desk-toast: the Desk toast

A Claude Code mod that ships with the Desk (`desk.py`, beside this folder). When the desk hook gives a
Desk letter to the agent of a session, the Desk writes a `seen` event for the letter
(`HUB/flow/desk/events.jsonl`). Within a few seconds (the mod reads every 2 s), every Claude Code
session that runs this mod shows a toast for 8 s:

    📨 sidequest-discovery saw:
    Ty closed these old handoffs of yours: a newer handoff holds…

The first line names the addressed session by its Claude Code name (`claude --name`, or `/rename`). A
session with no such name shows the Desk addressee (`discovery`). The second line is the first 60
characters of the letter (a line break shows as a space), with `…` when the letter is longer. A letter
with no `seen` event gives no toast. `/desk-toast` prints this help in a session.

## What "saw" means

"saw" means that the hook gave the letter to the agent. It does not mean that the agent acted on it:
a Ctrl+C, a crash or a compaction right after the hook still gives the toast. To know what the agent
did, read its reply or the Desk page.

## What it reads, and what it never does

It reads only:

- `DESK_STATE/mindholes.json` (default `~/.local/state/desk/`): the mindholes of the Desk
  (`desk.py mindholes`), and also the hub that this copy is installed in;
- of each of them, `flow/desk/events.jsonl`, `flow/desk/letters.jsonl` and `flow/desk/sessions/*.json`;
- `~/.claude/sessions/*.json` (or `CLAUDE_CONFIG_DIR/sessions/`): the name of each running session.

It writes no file and runs no process. It marks no letter seen and gives no letter to any agent: only
`desk.py hook` does that. A session shows only the `seen` events written after it started.

## Where it is installed

The kit installs this folder into each hub at `.claude/skills/desk-toast/` (kit.json `mods`), where
Claude Code loads a plugin of the project: every session started in the hub runs it (after the
workspace trust dialog). A session started outside every hub does not run it.

Tests: `claude plugin test .` in this folder; `desk-test.py` runs them (`case_toast_mod`,
`case_toast_read_only`).

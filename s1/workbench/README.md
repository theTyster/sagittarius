# 🌌 System 1 workbench

This folder is live. The System 1 hook reads it again on every prompt, in every session on this
machine, when `~/.claude/sagittarius-s1` points at this checkout. So a saved edit changes the next
call. The folder is on branch `s1/inspect`, which does not land on main until Ty says so.

| File | What it decides |
|---|---|
| `questions.json` | How each question is asked: `instructions` and, for a choice, `criteria`. It replaces `s1/questions.json`. `S1_QUESTIONS` still wins over it. |
| `pipeline.py` | The routing: which questions are asked, in what stages, and the line the agent gets (`run` and `hint`). |

A live routing gets 9 s for all its calls (`S1_WORKBENCH_TIMEOUT`); the released hook gets 4 s.
The install gives the hook 10 s, so keep the limit under 9.5 s. If `pipeline.py` does not load, or
raises, the hook prints `System 1: no view (routing: <error>)`, logs the reason, and never blocks
the prompt. A bad edit acts in every session on this machine, the client sessions too, until you
fix it. `S1_WORKBENCH=off` turns the workbench off for one session; deleting `pipeline.py` gives
the released routing back.

| Do | Command |
|---|---|
| Watch live what System 1 sees and says, every hub, with a picker | http://127.0.0.1:8791/ (the s1-bench window starts it: `python3 ../s1inspect.py --serve 8791`) |
| Replay the newest 5 of a repo's prompts with your questions | `./bench.sh --hub ~/Projects/mine/sagittarius` |
| The same, but tell model noise from your change | `./bench.sh --hub ~/Projects/mine/sagittarius --baseline` |
| A MindHole's prompts | `./bench.sh --hub ~/Projects/mine/mindhole --last 10` |
| One session | `./bench.sh --session 2d93cd66 --last 10` |
| Try your routing on old prompts first | `./bench.sh --pipeline pipeline.py --baseline` |
| Count the calls first | `./bench.sh --last 50 --dry-run` |
| The calibration cases (labelled answers) | `./calibrate.sh` |
| Undo your question edits | `git checkout -- questions.json` (or `cp ../questions.json questions.json`) |

`*` marks a question whose band changed (yes / no / unsure; a choice is shown at P >= 0.5).
Two calls with the same questions can move a few hundredths, so trust `--baseline` over one run.
Each bench call costs one request to TypeSafe, and goes to `~/.claude/logs/s1-bench.jsonl`, never
to the hook's log. Live calls go to `~/.claude/logs/s1.jsonl`, one line per `ask()`, with
`"routing": "workbench"` and the `"stage"`.

TypeSafe's advice for questions (docs.typesafe.ai, "Model jaggedness"): Jev reads the words literally;
put the exact condition in `instructions` and the boundary cases in `criteria`; keep them aligned; avoid
double negatives; a choice leans to its first option (reorder to check).

When a change helps, it goes into `s1/questions.json` through a build ticket, with the calibration
run as proof.

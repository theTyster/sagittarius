# PILOT.md: the paid run of the conformance evals

These commands make PAID calls (Haiku sessions, then System 1 requests). A human decides to run
them. Run from the Sagittarius root. Nothing here was run live; every test uses stubs.
`agent_cmd.sh` has never run for real: its path through `~/.zshenv` and `claude-personal` is
untested, and it uses Ty's personal Claude key (not the work key) unless `EVAL_ACCOUNT=work`.
The plan prints two figures: the estimate (it counts 12 planted and 80 labelled transcripts that
`live` does not make yet; the budget must be at least this) and the cost of this live run alone
(for 10 tasks x 2 arms x 1 run with 14 criteria: 0.40 + 0.25 = 0.65 USD).

## Env vars (names only)

- `CONFORMANCE_AGENT_CMD`: `evals/conformance/agent_cmd.sh` (absolute path)
- `CONFORMANCE_S1_CMD`: `evals/conformance/s1_cmd.py` (absolute path)
- `TYPESAFE_API_KEY`: the System 1 key (s1/jev.py KEY_ENV). `s1_cmd.py` exits 3 with no call when unset.
- Claude key for Haiku: `agent_cmd.sh` loads `~/.zshenv` and runs `claude-personal`
  (`EVAL_ACCOUNT=work` for the work key). Run `claude-auth` in a real terminal first.
- Optional: `S1_LOG` (where jev.py logs; default `~/.claude/logs/s1.jsonl`),
  `CONFORMANCE_AGENT_MODEL` (default `claude-haiku-5-5`).
- `CONFORMANCE_CLAUDE_BIN` is for tests only: leave it unset, or no real call is made.

## Smoke test (1 task, 1 arm, 1 run)

    export CONFORMANCE_AGENT_CMD=$PWD/evals/conformance/agent_cmd.sh CONFORMANCE_S1_CMD=$PWD/evals/conformance/s1_cmd.py
    python3 evals/conformance/runner.py live --tasks 1 --arms 1 --runs 1 --criteria 14 --budget 3 --out /tmp/conf-smoke
    python3 evals/conformance/score.py /tmp/conf-smoke

## Pilot (10 tasks x 2 arms x 1 run, 14 criteria)

    python3 evals/conformance/runner.py live --tasks 10 --arms 2 --runs 1 --criteria 14 --budget 3 --out evals/conformance/runs/pilot-1
    python3 evals/conformance/score.py evals/conformance/runs/pilot-1

Expected spend: about 0.40 USD (Haiku) + 0.25 USD (System 1) = about 0.65 USD. The runner's plan
line is higher: it also counts 12 planted and 80 labelled transcripts that `live` does not make
(the plan numbers are pinned by test k10). `--budget` must be at or above the plan's estimate, or
no call is made (exit 4). Tasks 5 and 6 of evals/tools.json are multi-turn (one session, resumed).

## Secrets check before a commit

The run dir holds transcripts, requests, answers and the report. Before you commit it, search it
and the System 1 log for the key values (never print them):
- `evals/conformance/runs/<out>/` (transcripts/*.jsonl, *.request.json, *.answers.json, record.json, report/)
- `$S1_LOG` (default `~/.claude/logs/s1.jsonl`): not in the repo, but do not copy it in.
- `grep -rlF "$TYPESAFE_API_KEY" <run dir>` and the same for the Claude key; the result must be empty.
  Also `grep -rlE "sk-ant-|Bearer " <run dir>`.
Transcripts hold the work of the agent in fixture copies, so read them for pasted tokens too.

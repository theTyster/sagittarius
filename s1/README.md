# s1: the System 1 model client (T04)

`jev.py` is a Python 3 standard-library client for the System 1 model (today TypeSafe Jev).
API: https://docs.typesafe.ai/api.md

- `judge(state, questions, *, model="jev-1.14.0", timeout=20, redactions=None)` returns `{qid: answer}` or `None`. It never raises. The key comes from `$TYPESAFE_API_KEY`.
- `redact(obj, pairs)`, `band(p)`, `to_prolog(run_id, answers)`: see the docstrings.
- Log: one JSON line per call in `$S1_LOG`, else `~/.claude/logs/s1.jsonl`. No key. State only after redaction.

Tests (no network): `python3 -m unittest s1.test_jev -v` from the repo root.

## The hook (T07)

`hook.py` is a Claude Code `UserPromptSubmit` hook. For each prompt it asks the System 1 model the questions in
`questions.json` about `{message: the prompt, recent: the last 3 messages before it}`. `recent`
is a list, oldest first; each item is `{"role": "you" | "agent", "text": the complete text}`. A
message is a user prompt or an assistant reply; tool calls, tool results, meta lines and subagent
lines are not messages; an assistant reply is all the agent text of one turn. `S1_CONTEXT_MESSAGES` raises the count (never below 3). Each text is sent
whole. Only when the state and the longest question would pass the model's per-question context (32k
tokens) are the messages beyond 3 dropped, oldest first. If the 3 whole messages still do not
fit, they are sent whole with the `TypeSafe-Danger-Zone-Long-Context: true` header (262k tokens;
slower, same price; the log line has `"long_context": true`). Only beyond 262k is the oldest one
cut from its start; the log line then has `"trimmed": true`. Every text is
redacted. It adds one line of context for the agent, for example:

    System 1: work=build (0.83); divergence likely (0.85); effort significant (0.91): consider a shift up; formal tool: prolog (0.72)

- An answer in the unsure band is left out (yes/no: `jev.band`; a choice: P(choice) < 0.5).
  When no answer is outside the band, the hook prints nothing.
- When divergence and change of plan are both likely, the line says
  `divergence or change of plan: check which (prompt rule)`.
- Output: `{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": "..."}}`
  (https://code.claude.com/docs/en/hooks, "UserPromptSubmit decision control").
- It fails open. On any error, a timeout, a missing key, a missing questions file or bad stdin,
  it prints nothing and exits 0. It never blocks a prompt.

**Status: Ty has not approved the question set yet (u44).** `questions.json` is the review
session's calibrated set (22 of 25 known cases), copied unchanged.

### Install (Ty pastes this; no script installs it)

1. Copy `s1/redact.example.txt` to `s1/redact.txt` and put in it the names that must not leave the
   machine, one per line. `s1/redact.txt` is gitignored. Without it, nothing is redacted.
2. Set `TYPESAFE_API_KEY` in the environment that starts `claude`.
3. Paste this into the `hooks` of your `~/.claude/settings.json`. Change the path if the checkout
   is not at `/path/to/sagittarius`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 /path/to/sagittarius/s1/hook.py",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

The `timeout` of 10 s is the Claude Code limit. The hook stops waiting for the System 1 model before that: after
`S1_TIMEOUT` seconds (default 4) plus 0.5 s.

### Turn it off

Set `S1_OFF=1`: for one session, start it with `S1_OFF=1 claude`; for all sessions, add
`"S1_OFF": "1"` to the `env` of `settings.json`. To remove it, delete the snippet above.

### Settings

| Env | Default | Meaning |
|---|---|---|
| `S1_OFF` | unset | `1` (any value but `0`): do nothing |
| `S1_TIMEOUT` | `4` | seconds for the System 1 model call |
| `S1_CONTEXT_MESSAGES` | `3` | messages in `recent` (never below 3) |
| `S1_QUESTIONS` | `s1/questions.json` | the question set |
| `S1_REDACT` | `s1/redact.txt` | names to redact |
| `S1_LOG` | `~/.claude/logs/s1.jsonl` | the log (`jev.py` writes it) |

Each log line is the `jev.py` record (no key; the state after redaction) plus `session_id` and
`transcript` (the basename of the transcript path).
When the hook makes no call or prints nothing because of a problem (bad stdin, no
questions, no key, a timeout, no answers, bad answers), it writes one line with a `skipped`
reason. `S1_OFF=1` writes nothing. The hook reads the last 2 MiB of the transcript, and goes back at most 8 MiB until it has the messages.

Tests (no network): `python3 -m unittest s1.test_hook -v` from the repo root. One claim alone:
`python3 -m unittest s1.test_hook.C3FailOpen -v`.

## The status line segment (T14)

`statusline.py` is a Claude Code status line command. It reads the status line JSON on stdin
(`session_id`; docs: https://code.claude.com/docs/en/statusline) and prints one segment for the
newest log line of that session:

    S1 build | div 0.85 | plan 0.10 | eff 0.91 | tool lean

The parts are the five judgments of the hook (T29 c6): the `h_work` choice, P(`h_divergence`),
P(`h_change_of_plan`), P(`h_effort`), and the `h_language` choice (the formal tool). Each part shows
only outside the unsure band, as the hook decides it: a yes/no answer when P <= 0.3 or P >= 0.7, a
choice when its P is 0.5 or more.

- It prints nothing when the log is missing, when the session has no line, when stdin has no
  `session_id`, or when the newest line of the session is 10 minutes old or older.
- When the newest line is an error line (`error` set, or `answers` null) it prints `S1 err`.
- A missing answer is left out of the segment. So is a choice with P below 0.5, the hook's
  floor (`probabilities[choice]`, else `confidence`), and a yes/no answer inside the band. With
  nothing left, it prints nothing.
- It reads only the end of the log (64 KiB blocks, at most 8 MiB back). It never calls the network
  and imports no network module. It uses `S1_LOG` like the other s1 tools.

### Install (Ty pastes this; nothing installs it)

Alone, in `~/.claude/settings.json`. Change the path if the checkout is elsewhere:

```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 /path/to/sagittarius/s1/statusline.py"
  }
}
```

### After an existing status line command

Claude Code runs one command and sends the JSON once on stdin, and each line printed is one row.
Wrap both in a small script that saves stdin and feeds it to each. Save as
`~/.claude/statusline-with-s1.sh`, then point `statusLine.command` at it. Replace
`EXISTING_COMMAND` with your current command:

```sh
#!/bin/sh
input=$(cat)
base=$(printf '%s' "$input" | EXISTING_COMMAND)
s1=$(printf '%s' "$input" | python3 /path/to/sagittarius/s1/statusline.py)
printf '%s' "$base"
[ -n "$s1" ] && printf ' | %s' "$s1"
printf '\n'
```

This puts the segment at the end of the first row. To give it its own row, print `"$s1"` with a
newline instead of the ` | ` join. Trying it without installing:
`echo '{"session_id":"SID"}' | python3 s1/statusline.py`.

Tests (no network): `python3 -m unittest s1.test_statusline -v`. One claim alone:
`python3 -m unittest s1.test_statusline.C2Stale -v`.

# s1: the Jev client (T04)

`jev.py` is a Python 3 standard-library client for TypeSafe System One (Jev).
API: https://docs.typesafe.ai/api.md

- `judge(state, questions, *, model="jev-1.14.0", timeout=20, redactions=None)` returns `{qid: answer}` or `None`. It never raises. The key comes from `$TYPESAFE_API_KEY`.
- `redact(obj, pairs)`, `band(p)`, `to_prolog(run_id, answers)`: see the docstrings.
- Log: one JSON line per call in `$S1_LOG`, else `~/.claude/logs/s1.jsonl`. No key. State only after redaction.

Tests (no network): `python3 -m unittest s1.test_jev -v` from the repo root.

## The hook (T07)

`hook.py` is a Claude Code `UserPromptSubmit` hook. For each prompt it asks Jev the questions in
`questions.json` about `{message: the prompt, recent: the last agent message}`. `recent` has the
prefix `Agent: ` and is at most 600 characters. It adds one line of context for the agent, for example:

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
   is not at `/home/ty/Projects/mine/sagittarius`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 /home/ty/Projects/mine/sagittarius/s1/hook.py",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

The `timeout` of 10 s is the Claude Code limit. The hook stops waiting for Jev before that: after
`S1_TIMEOUT` seconds (default 4) plus 0.5 s.

### Turn it off

Set `S1_OFF=1`: for one session, start it with `S1_OFF=1 claude`; for all sessions, add
`"S1_OFF": "1"` to the `env` of `settings.json`. To remove it, delete the snippet above.

### Settings

| Env | Default | Meaning |
|---|---|---|
| `S1_OFF` | unset | `1` (any value but `0`): do nothing |
| `S1_TIMEOUT` | `4` | seconds for the Jev call |
| `S1_QUESTIONS` | `s1/questions.json` | the question set |
| `S1_REDACT` | `s1/redact.txt` | names to redact |
| `S1_LOG` | `~/.claude/logs/s1.jsonl` | the log (`jev.py` writes it) |

Each log line is the `jev.py` record (no key; the state after redaction) plus `session_id` and
`transcript` (the basename of the transcript path).
When the hook makes no call or prints nothing because of a problem (bad stdin, no
questions, no key, a timeout, no answers, bad answers), it writes one line with a `skipped`
reason. `S1_OFF=1` writes nothing. The hook reads only the last 2 MB of the transcript.

Tests (no network): `python3 -m unittest s1.test_hook -v` from the repo root. One claim alone:
`python3 -m unittest s1.test_hook.C3FailOpen -v`.

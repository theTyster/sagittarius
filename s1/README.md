# s1: the System 1 model client (T04)

`jev.py` is a Python 3 standard-library client for the System 1 model (today TypeSafe Jev).
API: https://docs.typesafe.ai/api.md

- `judge(state, questions, *, model="jev-1.14.0", timeout=20, redactions=None)` returns `{qid: answer}` or `None`. It never raises. The key comes from `$TYPESAFE_API_KEY`.
- `redact(obj, pairs)`, `band(p)`, `to_prolog(run_id, answers)`: see the docstrings.
- Log: one JSON line per call in `$S1_LOG`, else `~/.claude/logs/s1.jsonl`. No key. The state only after any redaction that the caller asks for (the hook asks for none). `questions_sha` is the first 12 hex digits of the sha256 of the canonical JSON (sorted keys, no spaces) of the questions dict that was sent; `s1inspect.py` uses it.

The state, the answers and every log field are described in `SCHEMA.md`; `test_schema.py` fails when a
log field is not there.

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
cut from its start; the log line then has `"trimmed": true`. The hook sends the complete messages
as written, with no redaction (T43, u123). It adds one line of context for the agent, for example:

    System 1: work=build (0.83); divergence likely (0.85); effort significant (0.91); formal tool: prolog (0.72)

- The line only reports. It gives the agent no instruction: the prompt says what to do with a
  hint ("System 1" in `prompt/SAGITTARIUS.md`).
- An answer in the unsure band is left out (yes/no: `jev.band`; a choice: P(choice) < 0.5).
  When every answer is in the band, the line is `System 1: unsure`. When only the formal tool is
  outside the band and the next rule holds it back, the line is `System 1: no signal`.
- The line names a formal tool only beside a signal (divergence likely, change of plan likely,
  effort significant, questions not settled), or when a proof is asked for: `h_proof` in the yes
  band when the response has it, else the tool is `lean`. The status line uses the same rule.
- Two questions cover the signals that the first five did not (0.3.0 S-C): `h_questions` (a round
  of questions did not settle: the message leaves one open, answers with a new question, or raises
  a new doubt) and `h_proof` (the human asks for a proof). The line names each only in the yes
  band: `questions not settled (0.88)`, `proof asked (0.92)`. A response with neither is valid.
  Calibration: `calibrate.py` and `CALIBRATION.md` (below).
- Output: `{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": "..."}}`
  (https://code.claude.com/docs/en/hooks, "UserPromptSubmit decision control").
- It fails open, and says so. On any error, a timeout, a missing key, a missing questions file or
  bad stdin, the line is `System 1: no view (<reason>)`, for example `System 1: no view (no API
  key)`, and the hook exits 0. The details go to the log. It never blocks a prompt.
- It prints nothing only when it is off (`S1_OFF=1`). So no line means that the hook is off or not
  installed, never that the hook saw no signal.

### Which messages: the conversation Claude holds (s1-rewind-context)

`recent` is the end of the conversation that Claude holds at the prompt, not the end of the file:

- The hook starts at the last message line of the transcript and follows `parentUuid` back. A
  message that a rewind removed is not on that chain, so it is not sent.
- It stops at a compaction. The compaction summary is one message (cut to fit like any long
  message); nothing before it is sent.
- A line that Ty did not type is not a message: `[Request interrupted ...]`, and a line that
  starts with a tag (`<command-name>`, `<local-command-stdout>`, `<task-notification>`,
  `<bash-input>`, `<bash-stdout>`, ...). Meta and subagent lines stay out, as before.
- On the first prompt after a rewind the file still ends on the abandoned branch. When the new
  prompt (15 characters or more) matches a prompt of that branch at difflib ratio 0.9 or more
  (the best match; the oldest wins a tie), the hook starts at the parent of that prompt: the
  rewind point. A prompt that matches nothing gets the end of the file's branch.
- It fails open: a transcript with no `uuid` lines, or a chain whose parent is missing from the
  whole file, gives the last messages in file order, as before. A chain cut only by the 8 MiB
  read bound gives the part found.

**The late fix.** The first call can still be sent the wrong branch (a rewind with new text, or a
text match that misfires). So, when the hook input has `prompt_id`, the hook writes what the first
call was sent to `~/.claude/s1-latefix/<session id>/<prompt id>.sent.json` and starts a detached
process (`hook.py --late-fix`: a new session, stdin, stdout and stderr closed; the hook never
waits on it). That process waits, at most 20 s, for the prompt line whose `promptId` is the hook's
`prompt_id`, and reads the context from that line's `parentUuid`. Only when it differs from what the
first call was sent does it ask the System 1 model once more. The log line of that call has
`"kind": "correction"` and the `prompt_id` (the first call's line has the `prompt_id` too). The
corrected line, `System 1 (correction): ...`, goes to `<prompt id>.correction.json`. One late fix
runs for each prompt (a lock file). Files older than 2 days are removed.

**Delivery (`posttool.py`, a `PostToolUse` hook).** At a tool call of the main agent in the turn of
that prompt, it gives the corrected line once, as `additionalContext` next to the tool result. It
looks only for the correction of the `session_id` and `prompt_id` of its own input, claims it with
an exclusive create, and skips calls whose input has `agent_id` (a subagent). With nothing to give,
it only checks for one small file and exits. If Ty sends the next prompt before the agent calls a
tool, the correction is never shown; the next prompt gets its own call.

**Status: the hook is recommended, not required.** Sagittarius works without it, and the prompt
says that no line means no outside view. `questions.json` is the review session's calibrated set
(22 of 25 known cases), with the two questions of 0.3.0 S-C added.

### What the hook does not report

- **A request is not a divergence.** A request is the first divergence of its ticket: it names a
  gap between what is and what the human wants. The light path is the response to it, so the hook
  does not report a request as a divergence, and `h_divergence` excludes a new request (the
  exclusion stays). The hook reports a later message that says the result or the restatement is
  wrong, or doubts it.
- **System 1 does not help with the narrowing.** The narrowing ("changes a part" against "adds on
  top") is the agent's work on the request. No question of the set asks it, and no calibration
  run covers it. If that changes, it is one more yes/no question with a calibration run.

### Calibration

The calibration cases are tracked in `fixtures/calibration.json` (keys `cases` and `left_out`): the
25 known cases and the cases of the two new questions. Every text in it is invented or rewritten, with no client
content. `test_calibration.py` reads them (no network). A second person who changes a question runs
`python3 s1/calibrate.py` (a live call to the System 1 model for each case, so it needs `TYPESAFE_API_KEY`;
`--case ID` runs one case) and reads how many labels agree for each question. The last results are in
`CALIBRATION.md`.

### What the hook cannot see

The hook runs on one event: a prompt that the human submits (`UserPromptSubmit`). So it gives an
outside view of a message of the human, and of no other signal:

- a result inside a turn (a check that passes when it must fail, a test result that differs from
  what the agent expected);
- a subagent's build (a build by someone else);
- a compaction (a handoff inside the session);
- a peer message (a message from a peer session is a handoff). The hook reads every prompt as a
  message of the human, so a long message of a peer session reads as effort of the human.

For these signals, the agent is the only witness. Which signal gets a second hook event first is a
design question that is not decided.

### Install (you paste this; no script writes `settings.json`)

1. Run `./install.py` from the repo root. It links this folder to `~/.claude/sagittarius-s1`, the
   path that the snippets below use. Run it again after a release that adds a link.
2. Set `TYPESAFE_API_KEY` in the environment that starts `claude`.
3. Paste this into the `hooks` of your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/sagittarius-s1/hook.py",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

4. For the late fix to reach the agent (above), also paste this `PostToolUse` entry next to
   `UserPromptSubmit` in the same `hooks` object. Without it the late fix still corrects the log
   (and the status line), but the agent never sees the corrected line:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/sagittarius-s1/posttool.py",
            "timeout": 5
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
| `S1_FANOUT` | unset | `0`: turn the fan-out off (the questions of `questions.json` alone) |
| `S1_FANOUT_FILE` | `s1/fanout.json` | the questions of the fan-out |
| `S1_LOG` | `~/.claude/logs/s1.jsonl` | the log (`jev.py` writes it) |
| `S1_LATEFIX` | unset | `0`: no late fix |
| `S1_LATEFIX_DIR` | `~/.claude/s1-latefix` | the late-fix files (the hook and `posttool.py`) |
| `S1_LATEFIX_WAIT` | `20` | seconds the late fix waits for the prompt line |

Each log line is the `jev.py` record (no key; the state as sent) plus `session_id` and
`transcript` (the basename of the transcript path).
When the hook makes no call or has no view because of a problem (bad stdin, no
questions, no key, a timeout, no answers, bad answers), it writes one line with a `skipped`
reason. `S1_OFF=1` writes nothing. The hook reads the last 2 MiB of the transcript, and goes back at most 8 MiB until it has the messages.

Tests (no network): `python3 -m unittest s1.test_hook -v` from the repo root. One claim alone:
`python3 -m unittest s1.test_hook.C3FailOpen -v`. The rewind, compaction and late-fix tests:
`python3 -m unittest s1.test_rewind -v`.

## The status line segment (T14)

`statusline.py` is a Claude Code status line command. It reads the status line JSON on stdin
(`session_id`; docs: https://code.claude.com/docs/en/statusline) and prints one segment for the
newest log line of that session:

    S1 build | div 0.85 | plan 0.10 | eff 0.91 | tool lean

The parts are the five judgments of the hook (T29 c6): the `h_work` choice, P(`h_divergence`),
P(`h_change_of_plan`), P(`h_effort`), and the `h_language` choice (the formal tool). Each part shows
only outside the unsure band, as the hook decides it: a yes/no answer when P <= 0.3 or P >= 0.7, a
choice when its P is 0.5 or more. As in the hook, the tool shows only beside a signal (a yes/no
part at 0.7 or more), or when a proof is asked for (`h_proof` at 0.7 or more when the line has it,
else the tool `lean`).

- It prints nothing when the log is missing, when the session has no line, when stdin has no
  `session_id`, or when the newest line of the session is 10 minutes old or older.
- When the newest line is an error line (`error` set, or `answers` null) it prints `S1 err`.
- A missing answer is left out of the segment. So is a choice with P below 0.5, the hook's
  floor (`probabilities[choice]`, else `confidence`), and a yes/no answer inside the band. With
  nothing left, it prints nothing.
- It reads only the end of the log (64 KiB blocks, at most 8 MiB back). It never calls the network
  and imports no network module. It uses `S1_LOG` like the other s1 tools.

### Install (you paste this; no script writes `settings.json`)

After `./install.py` (it makes the link `~/.claude/sagittarius-s1`), paste this alone into
`~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 ~/.claude/sagittarius-s1/statusline.py"
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
s1=$(printf '%s' "$input" | python3 ~/.claude/sagittarius-s1/statusline.py)
printf '%s' "$base"
[ -n "$s1" ] && printf ' | %s' "$s1"
printf '\n'
```

This puts the segment at the end of the first row. To give it its own row, print `"$s1"` with a
newline instead of the ` | ` join. Trying it without installing:
`echo '{"session_id":"SID"}' | python3 s1/statusline.py`.

Tests (no network): `python3 -m unittest s1.test_statusline -v`. One claim alone:
`python3 -m unittest s1.test_statusline.C2Stale -v`.

## The Sagittarius Signals mod (`glance/`)

`glance/` is a Claude Code plugin (a hooks module, not a command hook). It shows the hook's newest
judgment of the session at a glance: one bar per signal, colored by strength (red confident, yellow
moderate, plain weak). The label of a signal that fired is bright; the label of one under its
threshold is dim. A judgment older than 10 minutes is dim in every view. It reads only the hook's
log, `~/.claude/logs/s1.jsonl`.

`install.py` links it to `~/.claude/skills/s1-glance`, so every new session loads it. Pick the views
with `/s1-glance pane | toast | corner | status | off` (any together). The choice is kept for every
later session. A new setup starts with the pane. The `status` view writes one line with colors to
`~/.claude/s1-glance/<session id>.status`; a status line command can print that file as its first row.

The pane has three tabs. They draw from one history and share one cursor, so a move in one is a
move in all:

| Tab (key) | What it shows | Keys |
|---|---|---|
| now (`1`) | The signals of one judgment, and why. Under the bars, the message is a strip of cells, one for each part that the hook read (see "The fan-out"). A cell's height and color are the strongest answer of its part. The picked part (◆) shows its text, what it does (accepts, corrects, doubts, changes the ask, adds to it, answers, asks back, new topic), and a bar for each answer that stands out. The pane opens on the part where the most stands out. | `j` `k`: the part before, the part after |
| trend (`2`) | Every signal over the session: one row per signal, one cell per judgment, colored by strength. A failed call is a red ×. A row of latency sits under them. The cursor's judgment is the bright column with ▲ under it; the line below names what fired there. | `p` `n`: move the cursor; `l`: back to live |
| health (`3`) | How the hook performs: latency per call with median and maximum; tokens per call with their sum and cost; failed calls; and for each signal a bar of how often it said yes, said nothing (the unsure band), or said no. Last: how many judgments were read in parts, and how many came through the workbench or the late fix. | |

A toast of a signal that came from a part also quotes that part. The status line and the corner
show the reversal when the hook names one.

Tests (no network): `claude plugin test s1/glance` (`tests/pane.test.tsx`, `tests/charts.test.tsx`).

## The observation harness (0.3.0, suggestion 3)

`observe.py` compares the log of the hook with the session transcripts, after the fact. The hook
does not ask the agent to acknowledge a hint, so it stays fast; this tool reads afterwards. It
reads only, and calls no network.

    python3 s1/observe.py --log ~/.claude/logs/s1.jsonl --transcripts ~/.claude/projects [--json] [--session ID]

For each session that the log names, and for all of them, it counts the hints that named a
signal, the hints after which the agent shifted up, the hints that the agent disputed, and the
shifts with no hint. For example: "2 hints named a signal; the agent shifted up after 1; the agent
disputed 1; the agent shifted up 1 time with no hint." `--json` prints the keys `hints`,
`shifted_after_hint`, `disputed`, `shifts_without_hint`, `sessions` and `limits`.

Its limits (it prints them too):

- A shift is a line that starts with `Shifting up:`. The prompt allows other words; the tool
  misses those.
- A dispute is a delivery in the same turn whose `Signals:` field says "no" for the signal that
  the hint named. A dispute in one line with no delivery is not counted.
- A hint names a signal only in the yes band (P >= 0.7) of divergence, change of plan, effort,
  and, when the question set has them, proof and questions.
- A hint goes to the turn of its prompt: by the message text in the log line, else by the
  nearest prompt in time (at most 5 minutes).

Tests (no network; invented transcripts only): `python3 -m unittest s1.test_observe -v`.

## The inspection tool

`s1inspect.py` shows what the System 1 model was sent, how it was asked, and what it answered. It is
for the owner who wants to check the hook by eye. It reads the log and the projects dir, calls no
network, and writes no file. To watch the System 1 model's answers live, run `s1/s1watch` in a terminal: it follows
the log and prints each call as the model returned it.

    python3 s1/s1inspect.py --hub ~/Projects/mine/sagittarius --last 3
    python3 s1/s1inspect.py --hub PATH --summary
    python3 s1/s1inspect.py --errors --json

| Option | Meaning |
|---|---|
| `--hub PATH` | only sessions of that hub folder: a session counts when `<projects>/<dir>/<session_id>.jsonl` exists, where `<dir>` is the folder path with every `/` and `.` as `-` |
| `--projects DIR` | the projects dir (default `~/.claude/projects`) |
| `--log FILE` | the log (default `$S1_LOG`, else `~/.claude/logs/s1.jsonl`) |
| `--session ID` | one session; a prefix is enough |
| `--since ISO` | only judgments at or after this time |
| `--last N` | only the newest N, after the other filters |
| `--errors` | only failed calls and hook skip lines |
| `--questions FILE` | the question file (default `questions.json` of this checkout) |
| `--json` | one JSON object per judgment, one per line |
| `--summary` | counts instead of judgments; with `--json`, one object |

Judgments are listed newest first. Each one has three parts.

- **What it saw.** The message and every `recent` item: role, length, text.
- **How it was asked.** Each question by id, with its instructions and criteria, and the shape of the
  request body (`model`, `state`, `questions`). No key and no header is shown. The log keeps only the
  question ids, so the text comes from the question file. The tool says so when it may differ from
  what was sent: an id that the file lacks, an id that the call did not send, or a line from another
  Sagittarius version than this checkout. When the line has `questions_sha`, the tool
  compares it with the hash of the file and says `same` or `differs`; else the match is `unknown`.
- **What it answered.** Each answer with its probabilities and its band: yes, no or unsure for a
  yes/no answer; a choice is `shown` at P >= 0.5 (the hook's `CHOICE_MIN`), else unsure. Then the
  exact line that the agent received, computed again with `hook.format_answers`. A failed call shows
  its error and the hook's `no view` line. A hook skip line shows its reason.

Calibration calls in the same log (`calibrate.py`; no session) show as `calibration`. Hub, session
and a hub filter leave them out.

`--summary` gives: judgments, calls, hook skip lines, failed calls,
error rate, median latency, how often each signal fired in the yes band (divergence, change of plan,
effort, questions not settled, proof asked), and, for each question, how many answers fell in each
band or choice.

`--json` keys per judgment: `schema`, `kind` (`call`, `skip`, `calibration`), `line`, `time`,
`session_id`, `session_short`, `model`, `latency`, `usage`, `sagittarius`, `trimmed`,
`long_context`, `failed`, `calibration_case`, `signals`, `saw` (`message`, `recent`),
`asked` (`question_ids`, `questions`, `missing_from_file`, `questions_file`, `questions_sha_logged`,
`questions_sha_file`, `match`, `notes`, `request_body`), `answered` (`answers`, `hint`, `hint_note`,
`error`, `skipped`).

Limits:

- It shows the state and the answers as the log has them. It cannot show a request that the hook
  never logged. It does not see the headers; `long_context` says whether the long-context header was set.
- The question text is the file's, not the log's. Without `questions_sha` it cannot prove that the
  file is what was sent. Lines from before the hash are always `unknown`.
- The line that the agent received is computed again, not read from the session. For a failed
  call, the reason inside the `no view` line comes from the hook's next skip line and may differ.
- A hub is found only by the projects dir of that exact folder. Sessions in a sub-folder or a
  worktree have their own dir and are not in it. A session whose transcript was deleted is not found.
- It lists the whole selection. On a large log use `--last` or `--since`.

Tests (no network; invented logs and projects dirs): `python3 -m unittest s1.test_s1inspect -v`.

## The workbench (`bench.py`)

To change how System 1 is asked, copy `questions.json`, edit the copy, and ask the model again about prompts
it has already judged. `bench.py` puts the logged answer beside the new one for each question and marks a
change of band with `*`. It calls the network once per judgment and needs `$TYPESAFE_API_KEY`.

    python3 s1/bench.py --questions my-questions.json --hub PATH --last 10
    python3 s1/bench.py --questions my-questions.json --last 10 --baseline   # also ask questions.json again
    python3 s1/bench.py --questions my-questions.json --dry-run               # count the calls, ask nothing
    python3 s1/calibrate.py --questions my-questions.json                     # the tracked calibration cases
    python3 s1/bench.py --questions q.json --pipeline my-routing.py --baseline # your own routing

`--pipeline FILE` replaces the one call with a Python file that defines `run(state, ask, questions)`:
`ask(qs)` makes one call with the questions dict `qs`. It can ask in stages, split or merge questions,
or skip some; `hint(answers, questions)`, if defined, writes the line the agent would get (else the
hook's `format_answers`). The output then shows the logged line and the new one.

The selection options are those of `s1inspect.py` (`--hub`, `--session`, `--since`, `--last`; the newest
5 by default). Two calls with the same questions can differ a little (a few hundredths), so use
`--baseline` before you read a small change as an effect of your edit. The calls go to
`$S1_BENCH_LOG` (default `~/.claude/logs/s1-bench.jsonl`), never to the hook's log.
## The fan-out

One request still, but the message is read part by part. `hook.split_parts` cuts the message: each
sentence is a part for a short message; a long or voiced message (no sentence ends) is packed into
parts of at most 600 characters, and the whole message is always read. Each part gets the seven
questions of `fanout.json` (`part`), in the same request as the questions of `questions.json`.
`hook.combine` then writes four answers from the parts and adds one:

| Answer | Rule |
|---|---|
| `h_divergence` | the highest "doubts" or "faults" of a part; a fault does not count in a part that changes or adds to the request, or answers the agent; 0 when `recent` has no agent message |
| `h_change_of_plan` | the highest "changes" of a part; 0 with no agent message |
| `h_questions` | only when the agent's last reply has a question mark: the highest "asks" or "undecided" of a part, or, for more than six parts, the whole-message answer `f_open` |
| `h_effort` | the answer of `h_effort`; for a message of 800 characters or more, at least 1 - P(`f_pasted`) |
| `h_reversal` (new) | the highest "reverses" of a part. In the yes band the line says `decision reversed in message (0.90)`, and it counts as a signal |

`h_work`, `h_language` and `h_proof` are as before. The plain answers of the four rewritten
questions are still asked and logged, and are not used. The log gets a second line for each call
(`"combined": true`) with the combined answers, so the status line shows what the hint line said.
If a fan-out answer is malformed, the line comes from the plain answers (a skip line says why).

Why, and how well it works: `research/2026-11-15-question-eval/README.md`. Tests: `test_fanout.py`
(no network) and `research/2026-11-15-question-eval/fresh/check.py` (live). Known limits:

- A reversal inside the message also reads as a change of plan; the line can name both.
- When the human reverses and returns to the first decision, "change of plan" is still named.
- An answer or an open question inside a long ramble is found less often than in a short message.
- A pasted failure report ("it failed on prod:" and a log) is not seen as a divergence.
- All labels behind these rules are the agent's. No human has confirmed them.

## The live view (`live.py`)

`live.py` reads the S1 log and shows what the System 1 model said about the session's messages. It
prints them as text for a terminal or as JSON for a script. Standard library only, no
network, fails quiet (prints nothing on any error).

    python3 s1/live.py --format pane|corner|toast|json [--session ID | --stdin] [--log FILE]
                       [--turns N] [--no-color] [--width N]

| Format | For | What it prints |
|---|---|---|
| `pane` | a pane beside the chat | the newest message: a bar for each signal, the part that fired it, a row for each part of the message (what the part does, and six probabilities), and sparklines of the session with latency and token totals |
| `corner` | a small corner display | three lines: the signals that fired, the work kind with latency and part count, two sparklines |
| `toast` | a notification | one line, only when the newest message fired a signal; else nothing |
| `json` | your own renderer | `{"session", "turns": [...]}`; each turn has `signals`, `fired`, `parts`, `latency`, `tokens`, `work`, `tool` |

The session is `--session`; or `--stdin` reads `{"session_id": ...}` as a status line command gets
it; else the newest session in the log. Color follows `--no-color` and `NO_COLOR`.

The status line segment (`statusline.py`) also shows `rev 0.90` when a decision is reversed inside
the message, and `N parts` when the message was read in more than one part.

`live.py` is a command-line view for a shell, a script or a review of a log. Inside Claude Code,
the Sagittarius Signals mod (`glance/`) is the live view; it reads the log itself and does not use
`live.py`. Tests: `test_live.py`.

# System 1: the state and the log

This file describes the data that System 1 keeps and sends. It covers three things: the state that
the hook sends to the System 1 model, the answer that the model returns for each question, and the log line
that `jev.py` writes for each call. `test_schema.py` fails when the code writes a log field that
this file does not name.

## The state sent to the System 1 model

The hook sends one JSON object as `state`:

| Field | Type | Meaning |
|---|---|---|
| `message` | string | The prompt that Ty typed, as Claude Code gave it to the hook. |
| `recent` | list | The messages before the prompt, oldest first. The default count is 3 (`S1_CONTEXT_MESSAGES`, never below 3). |

With the fan-out on, the state has a third field, `sentences`: the parts of `message`, a list of
strings in order (`hook.split_parts`). The part questions name a part by its path, `sentences[k]`.

Each item of `recent`:

| Field | Type | Meaning |
|---|---|---|
| `role` | `"you"` or `"agent"` | `you`: a prompt that Ty typed. `agent`: all the agent text of one turn. |
| `text` | string | The complete text. The hook cuts the oldest text only when the state would not fit the model's context (see `README.md`, "The hook"). |

The request body is `{"model", "state", "questions"}`. `questions` is the question set: an object
whose keys are question ids and whose values are `{type, instructions, criteria?}`
(`questions.json`, or the workbench copy).

## The answers that the System 1 model returns

`answers` is an object keyed by question id. Each answer has a `type`, and its other fields
depend on that type. Source: the TypeSafe API, https://docs.typesafe.ai/api/system-one.md.

| `type` | Fields | Meaning |
|---|---|---|
| `noul` | `noul` | The probability of yes, 0 to 1. |
| `choice` | `choice`, `confidence`, `probabilities` | `choice`: the criterion with the highest probability. `confidence`: 0 to 1. `probabilities`: one number per criterion name; they add up to about 1. |
| `score` | `score`, `confidence`, `legend`, `probabilities` | `legend`: level keys (`"0"`, `"1"`, ...) mapped to the criteria. `probabilities`: one number per level key. `score`: the expected level, the probability-weighted average of the levels; it can fall between levels. |
| `box` | `box` (`top`, `bottom`, `left`, `right`), `confidence` | A region of an image. Not used by Sagittarius. |

The hook reads only `noul` and `choice` answers for its line. `s1watch` prints every answer as it
came.

## The log line

`jev.py` writes one JSON line for each call to `$S1_LOG` (default `~/.claude/logs/s1.jsonl`). A
bench replay writes to the bench log. The API key is never written.

| Field | Written by | Meaning |
|---|---|---|
| `time` | jev.py, hook.py | ISO 8601 time in UTC. |
| `model` | jev.py | The model asked, or the model that answered. |
| `questions` | jev.py | The question ids that were sent, as a list. |
| `questions_sha` | jev.py | The first 12 hex digits of the sha256 of the canonical JSON (sorted keys, no spaces) of the question set that was sent. |
| `state` | jev.py | The state that was sent (see above), or null when the input was malformed. |
| `answers` | jev.py | The answers object as the model returned it, or null when the call failed. |
| `latency` | jev.py | The seconds that the call took. |
| `usage` | jev.py | The token counts that the model returned (`input_tokens`, `output_tokens`), or null. |
| `error` | jev.py | null, or the reason why the call failed (`timeout: ...`, `HTTPError: ...`, `no answer for ...`). |
| `sagittarius` | jev.py | The Sagittarius version that ran. |
| `session_id` | hook.py | The Claude Code session id. |
| `transcript` | hook.py | The file name of the session transcript. |
| `prompt_id` | hook.py | The id that Claude Code gives the prompt (the `promptId` of its transcript line), when the hook input has one. |
| `kind` | hook.py | `"correction"` on a call of the late fix: the prompt's first call was sent another context than the conversation Claude holds, so System 1 was asked again with the right one. |
| `skipped` | hook.py | Only on a line for no call: the reason why the hook made no call or has no view. |
| `trimmed` | hook.py | true when the hook cut the state to fit the context. |
| `long_context` | hook.py | true when the hook asked for the long context. |
| `parts` | hook.py | The number of parts that the fan-out cut the prompt into (see `README.md`, "The fan-out"). |
| `combined` | hook.py | true on the second line of a fan-out call: its `answers` are the model's answers with `h_divergence`, `h_change_of_plan`, `h_questions` and `h_effort` rewritten from the parts and `h_reversal` added. It has no `state`, `latency` or `usage`: those are on the line before it. |
| `part_text` | hook.py | Only on a combined line: the text of each part, each cut to 160 characters. |
| `fanout_off` | hook.py | The reason why the fan-out file did not load, so that the call was a plain one. |
| `routing` | hook.py | `"workbench"` when the call came from the workbench routing (`workbench/pipeline.py`). |
| `stage` | hook.py | The number of the call within one workbench routing run, from 1. |
| `bench` | bench.py | The tag of a bench replay (`new` by default). |
| `cal` | calibrate.py | `"s1"` on a calibration call. |
| `case` | calibrate.py | The id of the calibration case. |

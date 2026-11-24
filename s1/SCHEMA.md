# System 1: the state and the log

This file describes the data that System 1 keeps and sends. It covers three things: the state that
the hook sends to the System 1 model, the answer that the model returns for each question, and the log line
that `jev.py` writes for each call. `test_schema.py` fails when the code writes a log field that
this file does not name.

## The state sent to the System 1 model

The hook sends one JSON object as `state`:

| Field | Type | Meaning |
|---|---|---|
| `context` | string | What the model is looking at, the same on every call (`hook.STATE_CONTEXT`): "You are viewing a snippet of a transcript between a human and an agent". Since 2026-11-17. |
| `message` | string | The prompt that Ty typed, as Claude Code gave it to the hook. |
| `recent` | list | The messages before the prompt, oldest first. The default count is 3 (`S1_CONTEXT_MESSAGES`, never below 3). |

With a record (c29), the state has the field `record`: `{ticket, goal: {id, author, text} or null,
hypotheses: [{id, author, state, text, defeating_case, predictions: [{id, text}]}], questions:
[{id, text}], goal_sentences: [{id, text}]}`. It holds only these fields of what `orbit s1-record
--json` printed (`record.clean`); with the switch off (`S1_RECORD=0`, or `"s1_record": false` under
`modules` in the hub's `.hub-template.json`) the state has no `record` field.

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
| `combined` | hook.py | true on the second line of a fan-out call: its `answers` are the model's answers with `h_divergence`, `h_change_of_plan`, `h_questions` and `h_effort` rewritten from the parts and `h_contradiction` added (`h_reversal` in lines before 2026-11-17; the readers accept both, and `tla` for `tlaplus` in `h_language`). It has no `state`, `latency` or `usage`: those are on the line before it. |
| `replaced` | hook.py | Only on a combined line: the ids whose answer the fan-out wrote from the parts. For each one, `answers` also holds `<id>_plain`: the answer of that id's own question, which did not reach the line. |
| `part_text` | hook.py | Only on a combined line: the text of each part, each cut to 160 characters. |
| `fanout_off` | hook.py | The reason why the fan-out file did not load, so that the call was a plain one. |
| `routing` | hook.py | `"workbench"` when the call came from the workbench routing (`workbench/pipeline.py`). |
| `stage` | hook.py | The number of the call within one workbench routing run, from 1. |
| `source` | hook.py | Only for a prompt that starts with `<cross-session-message`, `<task-notification` or `<agent-message`: the tag name. The human did not write the message (c34). Code decides it, with no question to the model. `answers` keeps the answers of the model; the line leaves out effort and change of plan. |
| `record` | hook.py | Where the record in the state came from: `ticket` (the active ticket, through `orbit s1-record`), `session` (the goal and the hypotheses that the session stated), `goals` (goal sentences only), `none`, or `off` (the switch). |
| `record_sent` | hook.py | The names of the records that were sent in `state.record`, for example `["goal:g1", "hypothesis:hy1", "claim:c1", "question:q4", "goal_sentence:pg1"]` (c46). Absent when no record was sent. |
| `record_ticket` | hook.py | The slug of the active ticket, when the record has one. |
| `record_why` | hook.py | Why no record was sent: `no orbit command`, `no ticket`, `orbit timeout`, `orbit failed`, `orbit missing`, `bad record`, `too large for the context`; or which switch turned it off (`S1_RECORD`, `hub`). |
| `record_latency` | hook.py | The seconds that the `orbit s1-record` command took. Absent when no command ran. |
| `record_cut` | hook.py | The parts of the record that were left out so that the state fits the context, in order: `goal_sentences`, `questions`, `predictions`, `all`. |
| `trees` | hook.py | Only on a line after a call that asked a decision tree that shipped (`trees.py`): `{count, requests: [{part, kind, goal}], dispute, difference: [{a, b, differs}], proposed, proposals_left, error}`, each key only when its tree was asked. It has no `state`. No tree ships yet, so no line has it. |
| `event` | stop.py | `"stop"` on a line of the stop event (c30). Its `state` has `delivery` (the last message of the agent) in place of `message`. Written only after the drift questions ship. |
| `stop` | stop.py | Only on the second line of a stop event: `{drifts, revisions, proposed, hint}`: the ids of the predictions that the delivery dropped with no revision, those that the human revised, the number of proposals that orbit took, and the hint line or null. |
| `bench` | bench.py | The tag of a bench replay (`new` by default). |
| `cal` | calibrate.py | `"s1"` on a calibration call. |
| `case` | calibrate.py | The id of the calibration case. |

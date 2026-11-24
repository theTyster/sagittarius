# The replay experiment of a System 1 question

A new question of System 1 ships only after a replay experiment gives the verdict meets
(scientific-method-overhaul c35). Until then the question is in `questions.candidate.json`, and the
hook does not ask it. `replay.py` runs the experiment. It runs on this machine.

The candidate trees and their rules (`trees.py`):

| Question (`question` in the case file) | Claim | Questions | Labels that the rule gives |
|---|---|---|---|
| `drift` | c30 | `d_success`, then `d_kept` and `d_revised` for each prediction; the arm of today asks `d_drift` | `drift`, `revision`, `none` |
| `dispute` | c31 | `x_dispute`, then `x_kind` | `outputs`, `wanted`, `neither` |
| `difference` | c32 | `y_differs` for each pair of hypotheses | `user`, `none` |
| `requests` | c33 | `r_count`, then `r_kind` and `r_goal` for each part | the kinds in order, for example `answer,hypothesis`; `none` |

## The case file

One JSON file for one question. `fixtures/replay_example.json` is a tiny invented example (its
recorded answers are invented: it is no experiment).

```json
{
 "question": "drift",
 "claim": "c30",
 "thresholds": {"written": "2026-11-24T08:00:00Z", "by": "review", "rule": "two_arm",
                "target": ["drift"], "hint_labels": ["drift"],
                "min_gain": 1, "max_extra_false": 0, "max_failed": 0},
 "cases": [
  {"id": "d1", "group": "drift", "label": "drift", "unsure": false,
   "source": {"kind": "invented"},
   "state": {"context": "...", "delivery": "Human-first worked.", "recent": [{"role": "you", "text": "..."}]},
   "record": {"ticket": "...", "goal": {}, "hypotheses": [], "questions": [], "goal_sentences": []},
   "recorded": {"today": {"d_drift": {"type": "noul", "noul": 0.4}}, "record": {}}}
 ]
}
```

- `state`: the state of today. For `drift` it has `delivery` (the last message of the agent) and
  `recent`. For the other questions it has `message` and `recent`, and for `requests` also
  `sentences` (the parts of the message, `hook.split_parts`).
- `record`: the record of the case, in the form of `orbit s1-record --json`. The arm `today` is
  judged without it. The arm `record` is judged with it in the state.
- `group`: the group of the case. For `drift` (q17): 10 cases of a quiet drift, 10 of a revision
  that the human made, 10 with no change.
- `label`: the label that the rule must give. `"unsure": true` marks a case whose label the human
  has not judged yet: with one such case the verdict is unresolved.
- `source`: `{"kind": "invented"}`, or `{"kind": "log", "session_id": ..., "time": ...}` for a
  state from the log.
- `recorded`: the answers of each arm, used only without `--live` (the tests).

## The thresholds, written before the run

`thresholds.written` is the time when the thresholds were written. `replay.py` refuses a file with
no time, or with a time later than the run. Commit the case file before the run, so that git shows
the order. Nobody tunes the question on the cases of the set: a case that was used to word a
question is not a case of its experiment.

- `"rule": "two_arm"` (the drift question). A hit is a case of a `target` group whose arm gives the
  label of the case. A false hint is a case of another group whose arm gives a label of
  `hint_labels`. Meets: the arm `record` has at least `min_gain` more hits than the arm `today`,
  and at most `max_extra_false` more false hints. Conflicts: as many or fewer hits, or more false
  hints than allowed. Unresolved: a gain under `min_gain`.
- `"rule": "accuracy"` (a question with no arm of today to beat). The share of correct labels of
  `arm`: at `meets_at` or more it meets; under `conflicts_below` it conflicts; between is unresolved.
- In both: more than `max_failed` arms with no answer, or a case with no label, is unresolved.

## Build a case set

1. Only sessions of one hub (rk10). The log of this machine holds sessions of every hub.
   `python3 s1/replay.py draft --hub-dir HUB --question drift --last 60 --out cases.json` writes
   skeletons from the logged states of that hub only. `run` refuses a case from the log unless
   `--hub-dir` is given and the session of the case is a session of that hub.
2. For `drift` the logged states are prompts, not deliveries: take `delivery` and `recent` from the
   transcript of the session, or invent the text. Add the `record` of each case by hand, or from
   `orbit s1-record --dir KB --json`.
3. Review proposes the group and the label of each case, and marks the ones it is not sure of
   (`"unsure": true`). The human judges only those (q17). Build does not label.
4. Write the thresholds and their time. Commit.

## Run it, and record the experiment

A live run sends the text of each case to the System 1 model (api.typesafe.ai), twice, and costs
two calls for each case. The build pane decides when.

    python3 s1/replay.py run --cases cases.json --out out.json                          # recorded answers, no call
    python3 s1/replay.py run --cases cases.json --out out.json --live --hub-dir HUB     # live

The exit code is 0 for meets, 1 for conflicts and 77 for unresolved, so `orbit run` records the
verdict itself, in the spec KB of the ticket:

    orbit run k30 -- python3 s1/replay.py run --cases specs/SLUG/checks/drift-cases.json \
        --out specs/SLUG/runs/drift-replay.json --live --hub-dir .

The output record holds the case file with its sha256, the thresholds, the time of the run, the
answers and the label of each case in each arm, the counts of each arm, the verdict and its reason.
The calls are in the bench log (`~/.claude/logs/s1-bench.jsonl`, tag `replay:<question>:<arm>`).

## Promote a question

Only after the verdict meets: copy the entries of the tree (not the keys that start with `_`) from
`questions.candidate.json` into `questions.json`, and into the workbench copy if it is live.
`test_trees.C35NotPromoted` then fails by design: change its list in the same commit, and name the
experiment record. What happens then:

- `drift`: the stop event (`hook.py --event stop`) runs once `d_success`, `d_kept` and `d_revised`
  are in the question set. Paste the Stop snippet of `README.md`.
- `requests`, `dispute`, `difference`: the rules exist and are tested, but `hook.py` does not ask
  these trees yet. The questions with a placeholder (`r_kind`, `r_goal`, `y_differs`) must be
  written out for each part or pair (`trees.ask_requests`, `trees.ask_difference`) before they are
  sent. Do not copy them into `questions.json` before that wiring exists.

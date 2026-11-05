# s1: the Jev client (T04)

`jev.py` is a Python 3 standard-library client for TypeSafe System One (Jev).
API: https://docs.typesafe.ai/api.md

- `judge(state, questions, *, model="jev-1.14.0", timeout=20, redactions=None)` returns `{qid: answer}` or `None`. It never raises. The key comes from `$TYPESAFE_API_KEY`.
- `redact(obj, pairs)`, `band(p)`, `to_prolog(run_id, answers)`: see the docstrings.
- Log: one JSON line per call in `$S1_LOG`, else `~/.claude/logs/s1.jsonl`. No key. State only after redaction.

Tests (no network): `python3 -m unittest s1.test_jev -v` from the repo root.

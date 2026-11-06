# Changelog

## Redesign (informal release)

Ty makes the release. This entry lists what is in the `redesign` branch. The hub kit is version
0.2.0 (`hubkit/kit.json`).

### What landed

- Hub kit (T01): `hubkit/` holds the hub template, its install tool, and its tests. It was the
  separate hubflow-starter repo.
- Philosophy (T02): `docs/PHILOSOPHY.md` has the new beliefs and the way to judge a change.
- Spec KB (T03): `orbit-kb` becomes the spec KB. A predicate is declared on first use. New:
  `query 'blocking(X)'`, `pin`, and due dates (CONTRACT D22).
- Jev client (T04): `s1/jev.py` calls TypeSafe System One. It redacts names and logs each call.
- Flow ledger (T05): the hub flow state is a ledger with triage, escalation, capsules,
  transcripts, and skips. Its guard is proved in Lean.
- Small prompt (T08): `prompt/SAGITTARIUS.md` is short. The procedure moved to `orbit-kb help`.
- Panes (T09): the pane prompts follow the phase tree.
- Question view (T10): a view of the open questions (CONTRACT D24).
- Repo map (T12): `kb/bin/repo-map` writes a C4 map of a repo as Mermaid in Markdown.
  `install.py` now links it to `~/.local/bin/repo-map`.
- Tempering (T13): `s1/temper.py` tests the System 1 question set against recorded answers.
- Status line (T14): `s1/statusline.py` shows System 1 in the Claude Code status line.
- System 1 hook (T07): `s1/hook.py` asks Jev about each prompt. It is optional. You paste its
  snippet into `settings.json` yourself. No script writes that file.
- Tracker drafts (T11): `orbit-kb draft blocking` (the blocking items with the stamp), `draft outbound`
  (project KB drafts with their pins; a conflict shows as "decide"), and `pin-item` (records a pin of
  a tracker item from pasted text). Nothing is sent to a tracker (CONTRACT D25).
- Release (T15): a "Use it" path in `README.md`, and `kb/tests/test_release.sh`.
- Project KB (T06): an orbit-kb KB with the `project` module (CONTRACT D23). It has one writer at a
  time (a lock), stale pins, outbound drafts, and a conflict rule: when the tracker and a draft both
  changed after the pin, only a human can pick, and the conflict blocks `done`.

### Limits

- The Lean model's `done` has no project-conflict clause and no flare clause. So the Lean proofs
  about `done` cover only KBs with no project module and no visual (flare) claims.

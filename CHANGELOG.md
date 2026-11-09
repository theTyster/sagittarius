# Changelog

## Redesign (informal release)

Ty makes the release. This entry lists what is in the `redesign` branch. The hub kit is version
0.4.0 (`hubkit/kit.json`).

### What landed

- Hub kit (T01): `hubkit/` holds the hub template, its install tool, and its tests. It was the
  separate hubflow-starter repo.
- Philosophy (T02): `docs/PHILOSOPHY.md` has the new beliefs and the way to judge a change.
- Spec KB (T03): `orbit-kb` becomes the spec KB. A predicate is declared on first use. New:
  `query 'blocking(X)'`, `pin`, and due dates (CONTRACT D22).
- Jev client (T04): `s1/jev.py` calls TypeSafe System One. It redacts names and logs each call.
- Flow ledger (T05, hub kit 0.2.0): the hub flow state is a ledger with triage, escalation, capsules,
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
- Question server (T19): `orbit-kb serve questions` serves the question page live on 127.0.0.1,
  grouped per project, and records an answer from the page as a human answer, under the writer
  lock (CONTRACT D26).
- Release (T15): a "Use it" path in `README.md`, and `kb/tests/test_release.sh`.
- Project KB (T06): an orbit-kb KB with the `project` module (CONTRACT D23). It has one writer at a
  time (a lock), stale pins, outbound drafts, and a conflict rule: when the tracker and a draft both
  changed after the pin, only a human can pick, and the conflict blocks `done`.
- Informal release (T24): hub kit 0.4.0 works with only the five informal stores (flow ledger,
  memory files, weeks, bespoke tools, tracker): Python 3 and git, no Prolog and no Lean.
  `hubkit/README.md` is its document, with an install that a test runs without `swipl` or `lean`
  on the PATH. `HUB-CORE.md` "Without orbit-kb" says what changes and where each fact kind of the
  spec and project KBs is kept. `PRINCIPLES.md` brings the philosophy into each hub. `sessions/`
  left the kit; named sessions are set up outside the hub. The kit is named the hub kit.
- Meeting transcripts (T28, hub kit 0.4.0, db schema 3): `hubflow.py index-transcripts` also reads
  the Markdown and plain-text meeting transcripts in `W*/transcripts/`: one summary per file and
  one row per speaker turn or paragraph, with its line. `transcripts --detail ID` shows the turns,
  `transcripts --grep TEXT` finds them with file and line, and `rotate --yes` rebuilds the index,
  so a retired week's rows go with it.
- Byte digests (T38): a digest is now the sha256 of the file's bytes, the same as `sha256sum`.
  Before T38, `orbit-kb` read a file as UTF-8 text, so a digest of a file with non-ASCII text or
  binary data (a PNG demo) was wrong. Such a stored digest now shows as changed: lint W1, a stale
  pin, a reopened flare, and `done` false until the subject is recorded again. Every Lean proof
  whose files hold non-ASCII text (for example `∀` or `→`) shows in `proof_changed(A)`, and its burn
  is open again. To re-prove each one, in each KB:

      orbit-kb query 'proof_changed(A)'          # each attestation A to renew
      head -3 runs/proof-A.log                   # its claim, theorem, and source file
      orbit-kb prove CLAIM PATH/TO/SOURCE.lean THEOREM

  The proof itself does not change; only its recorded digest does. The new proof closes the burn.
  The old attestation still shows in `proof_changed(A)`; that is expected. ASCII files keep
  their digests.

### Not in this release yet

- None.

### Limits

- The Lean model's `done` has no project-conflict clause and no flare clause. So the Lean proofs
  about `done` cover only KBs with no project module and no visual (flare) claims.

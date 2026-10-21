# Orbital shifting: refinement record

## Pass 1 (clarity and leanness)

Baseline copy: `/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad/baseline-pass1.md`.

### Problems found in the baseline

1. The light path had no home. Its steps were spread over Scope, "Rules for the KB",
   "Ask first", BUILD, and Delivery, behind about 270 lines of KB mechanics. A new agent could
   not read it in a minute.
2. Moves (DECOMPOSE, BUILD, "wrong") assumed a KB. On the light path, "run every check with
   `orbit-kb run`" and "record a divergence" had no meaning.
3. "Each piece of work has one knowledge base" contradicted "start without a KB".
4. Repeated rules: claim labels (twice), burn conditions (four places), "a check that cannot
   fail" (three places), the 3x3 Purpose table (restated the bullets above it).
5. Bare imperatives with no reason: never type a digest, never edit a check, never weaken a
   claim, ENGINE DISAGREEMENT, "Do not add laps", dormant questions.
6. The command table had no way to record a divergence, though divergence is the key signal.
   The draft never said that `attest divergence` needs a subject.
7. Non-software and advice requests had no route; the Scope text called only questions
   "answer directly".

### Changes

- New section "The light path" (5 steps), with "Shift up to a KB" (the four triggers, moved
  from the KB rules) and "Ask first, or build on defaults" (moved up from the moves; the
  discovery text still refers to it by name). Reason: problems 1 and 3.
- Scope is now four routes, including advice or a decision (answer directly, no KB, no
  delivery block, honesty rules hold). Discovery is stated to work in a KB from the start.
  Reason: problem 7, scenarios 4 and 5.
- Dropped the Purpose table. Merged claim-label and burn-condition lists to one place each;
  dropped the duplicate honesty rule 3. Reason: problem 4.
- Added reasons to the rules in problem 5. Reworded the s(CASP) traps as one note.
- "When the human says that it is wrong" now starts with "shift up now" and has a decide step
  (build wrong, or problem wrong). Reason: scenario 3.
- Commands table: added `orbit-kb attest divergence s1 'claim(c1)' --by human`. Tested in a
  scratch KB; the claim then shows as contested and under.
- Delivery: small changes keep each field to a line; an empty field says "none".
- Design notes: status line and provenance row updated. Roles text is unchanged (diff
  checked). The discovery sections are almost untouched, because they were ratified word for
  word.

### Scenario results

| Scenario | Baseline | New text |
|---|---|---|
| 1 Trivial | Works, but "run every check with `orbit-kb run`" and "DECOMPOSE" pull toward a KB. Light steps hard to find. | Light path gives 5 steps, red run first, "No KB". Pass. |
| 2 Ambiguous | Triggers found only inside KB rules. No divergence command. | Ask round, shift-up triggers beside the light path, burn via `universal`. Pass. |
| 3 Divergence | Step 1 "record a divergence" assumed a KB; no command. | Shift up first, command in table, decide build vs problem. Pass. |
| 4 Report | Route said "run discovery" but the KB-optional rule was unclear. | Scope says discovery works in a KB from the start. Pass. |
| 5 Non-software | Implicit at best; delivery block and "check first" could be forced. | Scope route: answer directly, no KB, no block. Pass. |

Nothing new broke on paper: all `orbit-kb` commands named in the draft exist (`help`
checked); no command was added except one that exists.

### Findings not fixed

- The light path records no script-written test results (already under "Still open").
- `orbit-kb attest --by human` is not verified (`orbit-kb help attest`). This fits the trust
  threat model, and the draft does not claim otherwise.
- The claim "discovery works in a KB from the start" is my reading of the existing discovery
  text (`init ... --uses discovery`). Ty may want a light discovery path for tiny reports.
- Not shortened: the discovery orbit (about 230 lines). It is ratified text, and cutting it
  is Ty's call or a later pass.

### Line count

Whole file: 779 before, 794 after. The prompt part, before the Design notes: 708 before,
721 after. The file grew because the light path is new; the repeated text it replaced is cut.

## Pass 2 (accuracy and honesty)

Baseline copy: `/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad/baseline-pass2.md`.

Checked against: `orbit-kb help` and `help` for attest, run, prove, query, whynot, add, lint,
init, uses, subject, report; `core.pl`, `modules/build.pl`, `modules/discovery.pl`; the
README (types, burns, commands, lint codes, known limits); and a scratch KB (deleted after).

### Problems found in the baseline

1. **Light path versus the rules.** Step 3 said every check must fail before the change. A
   `preserve` check passes before and after, and `fulfilled/1` needs no red run for it. An
   agent would either fake a red run or skip a needed check.
2. **The threat model was missing.** Nothing told the agent that `--by human` is not
   verified, or that `prove` does not resist a proof built to fool it. An agent could write
   `--by human` for an approval the human never gave.
3. **Proof scope overstated.** Nothing said that a Lean proof is about the model, not the
   code, or that `prove` cannot match the statement to the claim (step 5 said "make sure",
   not why). A delivery could say "proved" for code.
4. **cb7ba90 not reflected.** No E15 (supersede cycles) or E16 (`rules.pl` cannot change
   `done` or burn rules). "A restated claim needs its own proof" did not say that the old
   waiver or proof does not carry over. The waiver command had no due-time format; tested:
   an unquoted or date-only DUE, or 2026-02-30, is rejected (E3).
5. **Query table drift.** `burn_open(C)` omitted "current". `burn(C)` said "says for every
   input" instead of `universal`.
6. **ENGINE DISAGREEMENT** told the agent to rewrite "the rule that the goal uses". Library
   rules are not the agent's to edit, and protected ones are E16.
7. **Command table.** `orbit-kb run k1` exits 2 unless `check(k1, C)` exists (tested). The
   `prove` example used the purple-button claim, which the draft itself calls not universal.
8. **Delivery versus `orbit-kb report`.** The report prints an `Open:` section that the
   delivery block did not have, so open burns could drop out of the delivery.
9. **TLC is not a proof** (Ty's decision) was only in the Design notes. A discovery claim
   that holds in TLC or SMT could reach the build orbit looking settled.
10. **Light-path evidence.** No script records light-path runs, but the delivery did not ask
    the agent to show them. **Deadline skips** had no stated record and no enforced due time.

### Changes

- Light path step 3: red first for added or removed behavior; a preserve check passes before
  and after. Step 5: name each check command and its result. (1, 10)
- Honesty rule 5: the checks trust you; they catch honest mistakes, not cheating; write
  `--by human` only to record what the human said; never work around a check. Placed with the
  honesty rules because it governs every record, not only BURN. Kept to four lines. (2)
- Honesty rule 3: "Proved in Lean" is about the Lean model, not the code. BURN step 5 says
  why (`orbit-kb` cannot check the statement); step 6 says only the checks test the code. (3)
- BURN: inherited burns, with no carry-over of the old proof or waiver; the waiver command
  now quotes DUE and gives the UTC format; the files that reopen a proof are named, and a
  path-dependency change is said not to. (4, honesty about what is not checked)
- `supersedes` entry: cycles refused, E15. Rules for the KB: E16. (4)
- Query table: `burn_open` says current claim, a proof that still counts, a waiver before
  its due time; `burn` names `universal` and `burn_requested`. (5)
- ENGINE DISAGREEMENT: rewrite only your own rule in `rules.pl`. (6)
- Commands: `run` row notes `check(k1, c1)` first; `prove` example is now a discount claim;
  "Record evidence" relabeled "Record a disclosure". (7)
- Delivery: `orbit-kb report` adds `Open:`; keep it. Deadline skips go in the delivery and as
  a disclosure; nothing enforces their due time except a burn waiver. (8, 10)
- Handoff to build: a solver result or TLC run holds only within its bounds and does not
  close a burn. Placed in discovery's handoff, so the build orbit still neither forbids nor
  suggests TLA+. (9)
- Design notes: status line, a provenance row for the trust model and cb7ba90, and an Open
  item for unenforced deadline skips.

Invariants: Roles text identical (diffed). All named commands, options, and predicates exist.
No decision changed in meaning.

### Scenario results

| Scenario | Baseline | New text |
|---|---|---|
| 1 Trivial | Pass. The color check fails first, fine. The delivery could say "checks pass" with no command. | Pass. Delivery names the check command and result. One extra sentence, no new ceremony. |
| 2 Ambiguous | Mostly pass. A superseded universal claim: unclear whether the old waiver carries. Waiver command as written fails on DUE quoting. Delivery could say "proved" for code. `Open:` could drop. | Pass. Inherited burn and own proof stated; working waiver command; model-versus-code wording; `Open:` kept. |
| 3 Divergence | Pass, but `--by human` could be used loosely. | Pass. Rule 5: record only what the human said. |
| 4 Report | Pass, but a TLC "holds" on a universal claim could pass to build as settled. | Pass. Handoff says it still burns. |
| 5 Non-software | Pass. | Pass. Nothing new applies to it. |

### Findings not fixed

- `orbit-kb help attest` and `help prove` show `'waive(C, DUE, REASON)'`. As a shell
  argument the DUE atom must be quoted (`"waive(c1, '2026-11-30T17:00:00Z', 'why')"`); the
  help text form, read literally, fails. CLI doc fix for Ty (not changed in this loop).
- The DISPROVE verdict `refuted` "with the counterexample": the `disproof` shape has no slot
  for it; the counterexample goes in a `note` or `example` (discovery says so; build does
  not). Left as is; minor.
- `prove` limits beyond the path-dependency one (`include_str` files, symlinked modules,
  F1 to F5) are not in the prompt. Under the trust model they need deliberate cheating or are
  rare; the README lists them.
- Honesty rule 7 of discovery ("lint errors block GO") is stricter than `discovery_ready`,
  which blocks only ED3 to ED7. Not a contradiction (process over rule), but Ty may want the
  rule to match.
- Ty's "TLC is not a proof" now appears only in the discovery handoff, by choice (build
  orbit stays silent on TLA+). Ty may prefer a generic "bounded results are not proofs" in
  BURN as well.

### Line count

Whole file: 794 before, 815 after. Prompt part (before the Design notes): 721 before, 738
after. Growth is the trust rule, the cb7ba90 facts, and the "what is not checked" clauses.

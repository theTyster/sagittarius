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

## Pass 3 (speed and fluid rigor)

Baseline copy: `/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad/baseline-pass3.md`.

### Problems found in the baseline

1. **No way down.** The prompt said how to shift up, but not that rigor may drop again
   after a scare. An agent that shifted up for a small divergence (the wrong purple) would
   run every move to the end.
2. **Scenario 2 could route to discovery.** Scope sent "a clear change request" to the
   build orbit. "Add discount codes" is not clear, and discovery's "When to run" lists
   prices. An agent could start the discovery orbit where Ty expects a question round.
3. **The burn trigger was hard to notice.** The trigger said "the claim is universal", but
   the definition was about 130 lines below, in Core vocabulary. On the light path the
   agent has no reason to read that far.
4. **Light-path ceremony was implied.** "Moves: on the light path you do the same work in
   your head" can be read as "run CHECK with a fresh subagent, DECOMPOSE dormant questions,
   and so on, without records". The Speed section also sent all searches and test runs to a
   subagent, even for a one-line change.
5. **KB words on the light path.** Honesty rule 2 said "file a disclosure", which has no
   meaning without a KB, or for the advice route.
6. **Advice route was silent on questions.** "Answer directly" could stop a useful question
   in scenario 5.
7. Small repeats: "You shift up to a KB from the light path" (KB section) and "Most tickets
   close in one lap" (Orbit) restated the light path.

### Changes

- New subsection "Shift down" (5 lines): when the cause of a shift is resolved, go back to
  the least work that still covers the ticket; keep the KB and write only what `done` and
  the report read; never drop an open question, a failing check, or a burn (only the human
  waives a burn); the next ticket starts light. Reason: problem 1. Keeping the KB avoids a
  half-recorded divergence and needs no new rule about abandoning one.
- Scope: "A change request" (not "clear"): open details are questions for "Ask first", not a
  reason for discovery. Discovery is for a report where "you cannot yet say what to change".
  Reason: problem 2. The discovery text is unchanged.
- The burn trigger now carries the definition of universal and the discount example; Core
  vocabulary points to it and keeps the purple-button counterexample. Reason: problem 3.
  No net growth.
- Light path intro: the five steps are the whole process until a trigger fires; the KB
  sections and the moves apply only after a shift. Moves intro says the light path does not
  run them. Speed: only long mechanical work goes to a subagent; a small task needs none.
  Reason: problem 4.
- Honesty rule 2: disclose in a KB with `orbit-kb attest disclosure`, and always in the
  delivery or the answer. Reason: problem 5.
- Advice route: "Ask first only if an answer would change your advice." Reason: problem 6.
- Shift-up text names `orbit-kb init`, so the first step after a trigger is concrete.
- Cut the two repeats in problem 7.
- Design notes: status line, a provenance row for "Shift down" and the scope wording (marked
  not ratified), and an Open item for "Shift down".

Invariants: Roles text identical (diffed). The four triggers, the three-question cap, the
question order, the burn and waiver rules, landing, the KB commit rule, and the TLA+ rule
are unchanged in meaning. No new `orbit-kb` command, option, or predicate; `init` exists.

### Scenario results

| Scenario | Baseline | New text |
|---|---|---|
| 1 Trivial | Pass, but the agent could read "same work in your head" and Speed as a call for a fresh-subagent CHECK and dormant questions. | Pass. Five steps are the whole process. No subagent, no moves, red run first, one-line delivery fields. |
| 2 Ambiguous | Unsure: "clear change request" versus discovery's "prices". The universal test sat far from the trigger. | Pass. Build orbit; one round of up to three money-first questions; new questions shift up; the floor claim matches the trigger text and burns. |
| 3 Divergence | Pass, but a small misread pulled the whole KB process to the end. | Pass. Shift up, record, decide build versus problem; when the cause is known, shift down inside the KB. |
| 4 Report | Pass. | Pass. Scope wording "cannot yet say what to change" fits it better. |
| 5 Non-software | Pass, but "answer directly" could suppress a question, and "file a disclosure" was KB-shaped. | Pass. One question only if it changes the advice; guesses go in the answer. |

### Findings not fixed

- "A check fails after the build" is a divergence trigger (Ty's list). Read literally, every
  red test during normal work starts a KB. "Shift down" makes this cheap, but Ty may mean
  "a check still fails when you think the build is done".
- Discovery's "When to run discovery" still lists prices and limits as a reason to run it.
  Scope now settles scenario 2, but the two texts pull in different directions for
  feature requests with business rules. The discovery text is ratified, so left as is.
- "Shift down" and the scope wording are this pass's reading of Ty's "rigour should scale
  fluidly". Ty has not ratified them.
- The prompt part is still about 750 lines. A new agent on the light path now knows it can
  stop after the light path, but the whole text loads every session.

### Line count

Whole file: 815 before, 830 after. Prompt part (before the Design notes): 738 before, 748
after. Growth is the "Shift down" subsection and the inline definition of universal; the
repeats cut offset part of it.

## Summary of the loop

Passes 1 to 3 ran on 2026-10-20. Whole file: 779 lines before pass 1, 830 after pass 3.
Prompt part: 708 before, 748 after.

Main changes:

- **Pass 1 (clarity):** a separate light path with five steps, the shift-up triggers beside
  it, and "Ask first" moved up; four scope routes, including advice; duplicate lists merged;
  reasons added to bare rules; a divergence command added to the table.
- **Pass 2 (accuracy and honesty):** red-first only for added or removed behavior; the trust
  threat model as honesty rule 5; proofs are about the Lean model, not the code; cb7ba90
  facts (E15, E16, inherited burns, real due times, working waiver command); `Open:` kept in
  the delivery; TLC and solver results do not close a burn.
- **Pass 3 (speed and fluid rigor):** "Shift down"; a change request with open details stays
  in the build orbit; the universal test sits at the trigger; the light path is stated to be
  the whole process; no subagent for small tasks.

Open findings for Ty (deduplicated):

1. Ratify or change "Shift down" and the scope wording for change requests with open
   details (pass 3).
2. "A check fails after the build" as a trigger: literal (every red test) or "still fails
   when done"? (pass 3)
3. Discovery's "When to run" (prices, limits) versus the scope route; and whether tiny
   reports need a light discovery path instead of a KB from the start (passes 1 and 3).
4. The light path has no script-recorded test results; the delivery names the agent's own
   runs (passes 1 and 2, Design notes "Still open").
5. Deadline skips of a check or a question have no enforced due time; only a burn waiver
   does (pass 2, Design notes).
6. CLI doc: `orbit-kb help attest` and `help prove` show `waive(C, DUE, REASON)`; as a shell
   argument DUE must be quoted (pass 2).
7. Discovery honesty rule 7 ("lint errors block GO") is stricter than `discovery_ready`
   (ED3 to ED7 only) (pass 2).
8. "TLC is not a proof" appears only in the discovery handoff; Ty may want a generic
   "bounded results are not proofs" in BURN (pass 2).
9. Minor: a build-orbit `refuted` verdict has no slot for the counterexample; `prove` limits
   beyond path dependencies are only in the README (pass 2).
10. The discovery orbit (about 230 lines, ratified text) was not shortened; the prompt is
    still about 750 lines. No agent run has yet used the merged prompt (passes 1 and 3,
    Design notes "Not verified").

## Review round 1 (2026-10-21)

Source: Ty's review notes of 2026-10-21. Ty's uncommitted edits to the draft were kept,
except four small fixes (item 7). The "deadline skip" paragraph in Delivery was not
touched; Ty has a pending question about it.

### Changes and reasons

1. **One meaning of "check".** Ty: "when definitions collide, ambiguity only serves
   confusion." A check is now defined once, below the light path intro: an executable test
   of one claim, with a pass or fail result; in a KB a `check(K, Claim)` fact whose runs
   `orbit-kb run` records; on the light path the same test with no KB. Every other use was
   renamed (audit below). Ty's sentence "A check is only valuable if it can fail" is kept
   as is; it fits the defined meaning. No second sentence was added: discovery honesty
   rule 4 already says the same of models.
2. **Two orbits and one diagram.** "The orbit" now states the two orbits after Parallax:
   discovery makes a problem clear, build delivers a solution; discovery, when it runs,
   comes first; a clear change request goes straight to build. Ty's reminder is included:
   "We write solutions to problems. We do not write to achieve understanding; we orbit to
   achieve understanding." The old lap diagram was merged into one fenced diagram with
   three parts: one lap, the views converging, and the two orbits in order with the direct
   path into build.
3. **Tiny discovery orbit.** New subsection in the discovery orbit: touch the system, state
   the claims with examples and falsifiers, ask the human, get GO / NO-GO / HOLD; no KB and
   no formal artifacts. It shifts up to the full orbit on the light path's triggers (by
   reference, no new list), or when a claim needs a model. Scope routes a tiny report there.
   "When to run" no longer lists prices and limits as a reason to start discovery (pass 3
   open finding); that text now says where models pay inside discovery, and that a change
   request with open details stays in the build orbit. Scope's change-request route names
   business rules as an example of open details. Sizes gained "Tiny"; "Small" now says it
   uses a KB. "Small report" was avoided so that "small" keeps its size meaning.
4. **Lint and GO.** Discovery honesty rule 7 now says that what blocks `discovery_ready`
   blocks GO (today WD1, WD3, WD7, ED3 to ED7), and to read
   `orbit-kb whynot 'discovery_ready'` because the lint rules can change.
5. **Counterexample slot.** `refuted` became `refuted(Counterexample)` in the build module
   `lean_result` line, ED5, core DISPROVE (with the command
   `orbit-kb attest disproof c1 "verdict(c1, refuted('price 0 with code X'))"`), BURN step
   3, and discovery DISPROVE (the counterexample goes in the verdict; the `note` was dropped;
   the `example` stays, because the build orbit turns counterexamples into test cases).
   Verified against the current CLI in a scratch KB: both attestations accept
   `refuted('...')`, `refuted(c1)` holds, and a bare `refuted` is rejected with E3.
6. **Shift down ratified.** Removed from "Still open"; the pass-3 row no longer says "not
   yet ratified"; new provenance row (user, 2026-10-21). Rows were also added for items 1
   to 5.
7. **Typos in Ty's edits.** "atleast" → "at least"; "The Human communicating" → "The human
   saying"; "simple technical english" → "simple technical English"; "without Decide and
   Recommend" → "without Decide and Ask".

Also: the Parallax paragraph and one BURN line were reflowed to the file's line width.

### "check" audit (prompt part, and design notes for consistency)

Old line numbers are from the draft as Ty left it (846 lines); new ones are from the result.

| Old | New | Old use | Meaning | New term |
|---|---|---|---|---|
| 10 | 10 | "what you did not check" | verify | "what you did not verify" |
| 27 | 27 | "no checks" (advice route) | check | kept |
| — | 53 | — | — | new definition of **check** |
| 54–57 | 59–62 | light path step 3; "Not checked" | check | kept |
| 59–60 | 64–65 | "Run the checks again"; "each check command" | check | kept |
| 65 | 70 | "the checks" recorded on shift-up | check | kept |
| 70 | 75 | "a check fails after the build" | check | kept |
| 72 | 77 | "too large to check case by case" (Ty's edit) | one check per case | kept: fits the meaning, and it is Ty's text |
| 86 | 91 | "failing check" | check | kept |
| 110, 112 | 131 | diagram party "checks (KB queries, tests, Lean)" | impartial party | "formal artifacts (KB queries, checks, Lean)" |
| 115 | 149 | "an impartial check" | impartial party | "the formal artifacts (in a tiny discovery orbit, the system itself)" |
| 117 | 151 | "the checks ... agree" | impartial party | "the formal artifacts" |
| 121 | 116 | Parallax "the checks" as a view | impartial party | "the formal artifacts" |
| 122 | 117 | "a failing check" | check | kept |
| 127–128 | 154–155 | Quiet failures (Ty's sentence) | check | kept word for word |
| 148 | 175 | "one check" | check | kept |
| 181 | 208 | "Run a check" | check | kept |
| 186 | 213 | "Check the KB" | lint | "Lint the KB" |
| 207 | 234 | "an executable check of a claim" | check | "K is a check of the claim (see "The light path")" |
| 232–233 | 259 | CROSS-CHECK SKIPPED; "say ... it is unchecked" | engine cross-check | CLI name and `(unchecked)` kept; "say ... that only one engine answered" |
| 241 | 268 | `conformance(Check)` | check (CLI type `ref(check)`) | kept |
| 247 | 274 | "a check of C passed" | check | kept |
| 295 | 322 | "has no `check`" | check | kept |
| 318 | 345 | ED6 "Two results for one check disagree" | a solver verdict kind | "Two solver results of the same kind, for one model, disagree" (matches the CLI text) |
| 349 | 376 | "/checkout" | URL | kept |
| 354 | 381 | "Write the checks first"; "screenshot check" | check | kept |
| 356–357 | 383–384 | red run of each check | check | kept |
| 360 | 387 | "Do not edit a check" | check | kept |
| 363 | 390 | "### CHECK: fulfillment in both directions" | move | "### FULFILL" |
| 365 | 392 | "Check with fresh eyes" | review | "Review with fresh eyes" |
| 407 | 436 | "`orbit-kb` cannot check that" | verify | "cannot verify that" |
| 409 | 438 | "only the checks test the code"; conformance check | check | kept |
| 424 | 453 | "coast (checked by examples)" | verify | "covered by checks of examples" |
| 443 | 472 | "the checks so far" | check | kept |
| 449 | 478 | "Rebuild, and check again" | verb | "run the checks again" |
| 455 | 484 | "A check that cannot fail is not evidence" | check | kept |
| 467 | 496 | "The checks trust you" | all safeguards | "The formal artifacts trust you" |
| 470 | 499 | "never work around a check. A check that you work around..." | all safeguards | "a check, a lint rule, or `orbit-kb prove`. A safeguard that you work around..." |
| 478 | 508 | "how it was checked" | verify (may be a proof) | "how it was verified" |
| 481 | 511 | "Not checked: what no check covered" | check | kept; `orbit-kb report` prints this field name |
| 494 | 524 | deadline skip "a check" | check | kept; paragraph not touched |
| — | 566 | — | — | tiny orbit: "the reproduction becomes its first check" |
| 590 | 641 | `check(t1, c1)` | check | kept |
| 650 | 701 | TLC "Check properties" | verb (model checking) | "Run TLC on properties" |
| 756 | 812 | "one claim whose check is the reproduction" | check | kept |
| 773 | 828 | design notes "Its checks are merge-check.py" | verification script | "Its verification script is" |
| 810 | 871 | design notes "cross-checks with s(CASP)" | engine cross-check | kept |
| 842 | 903 | design notes "deadline skip of a check" | check | kept |
| 846 | — | design notes "failing check" (Shift down open item) | check | item removed (ratified) |

### Scenarios after the change (on paper)

1. **Trivial (purple buttons):** light path as before; the definition makes step 3 plainer.
   No regression.
2. **Ambiguous (discount codes):** Scope and "When to run" now agree that a change request
   with business rules stays in the build orbit. Shift up, burn, and DISPROVE as before;
   a counterexample is now recorded inside `refuted(...)`. Improved.
3. **Divergence after delivery:** same steps; "run the checks again". No regression.
4. **Report (sync loses edits):** discovery. The agent may start the tiny orbit, but
   "sometimes" plus concurrency means a claim needs a model (orders of steps), which is a
   stated shift-up condition, so it moves to the full orbit and TRAJECTORY. Slight risk: an
   agent tries one cheap reproduction first; that is the same as SURVEY, so no work is lost.
5. **Non-software (job offers):** advice route unchanged. No regression.

### Open

- Ty's "too large to check case by case" uses "check" as a verb; it fits the definition
  (one check per case), so it stayed.
- The tiny orbit says "no formal artifacts", yet its reproduction can be a script. The text
  treats the reproduction as touching the system, and it becomes a check only in the build.
- GO with the budget spent: `discovery_decide` lets the human decide while
  `discovery_ready` is false, and rule 7 says those blockers block GO. This tension existed
  before (with the stricter "lint errors" rule) and is not resolved here.

### Line count

Whole file: 846 before, 904 after. Prompt part (before the Design notes): 764 before, 819
after. Growth: the diagram (about 20 lines), the tiny discovery orbit (about 18), the check
definition (4), the refuted command, and six provenance rows.

## Review round 2 (2026-10-21, main session, from Ty's answers)

Ty's decisions, and the edits that follow from them:

- **Skips are waivers.** "A bypass and a waiver seem too similar." The Delivery paragraph on
  deadline skips now says that a skip is a waiver with a due time. A waiver can target a
  claim (its burn), a check, or a question. The CLI changed the same day (6b639b2, D13).
- **Divergence examples are few-shot examples, not phrases to match.** "Other forms:" now
  says so.
- **`universal` has one definition: the burn trigger.** The vocabulary entry points to it.
  (Ty: "You are once again confusing syntax with semantics.")
- **The gate is a weighted vote.** It replaces "no recommendation at the gate", which Ty
  set and then reverted the same day. Weights: human 0.4, agent 0.3, formal artifacts 0.3.
  The agent's vote is sealed until the human votes. A choice wins only with the human's
  vote plus one other. Anything else is HOLD, another orbit, and a recorded divergence.
  Three "NO-GO candidate" recommendations in the discovery text became neutral wording.
- **The tiny discovery orbit** has no KB and no models (SMT, TLA+, Lean). Its one formal
  artifact is a red test of the reproduction. Ty: tests are formal in this prompt, though
  not a formal method. The Roles text is unchanged.
- **The light path is one try to get it right.** The human's verification closes it, and
  honesty surfaces any divergence. A new paragraph says this. "No script-recorded results
  on the light path" is settled by design, not an open gap.
- **5b, the human and the KB disagree at GO:** no change. The agent flags the
  contradiction as a divergence.
- Ty ratified "Shift down".

Still open: going live (split off the design notes, point `claude()` at the prompt), and
the refresh of the microsite, which predates this round.

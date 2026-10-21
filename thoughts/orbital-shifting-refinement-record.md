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

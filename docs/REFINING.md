# Refining the prompt without overfitting

Read this before you change `prompt/SAGITTARIUS.md` because an eval failed. The aim is a better
prompt, not only a better score.

The tool-use evals (`evals/tools.json`, `evals/run_tools.sh`) run a small model (Haiku) as the agent under test.
A small executor makes failures loud: a rule that only a strong model follows is under-specified.
That pressure has a failure mode of its own. It is easy to make a case pass by writing its answer
into the prompt, or its hint into the eval. The rules below stop that.

## The rules

### 1. Tune on one set, gate on another

- `evals/tools.json` is the tuning set. `evals/heldout/heldout.json` is the held-out set: one variant of each
  tuning case (id + 100), with different domain, wording, ids, order, and detail, and the same
  expected behavior.
- An agent that has not seen the runs, the prompt, or the prompt's history writes the variants.
- Diagnose and fix on the tuning set only. Do not read held-out transcripts to find a fix.
- Run the held-out set only at the gate, and only a few times. Each look makes it less independent.
- The person or agent who tunes the prompt never reads a held-out case: not its prompts, its
  fixture, its spec, or a summary of it. Printing a held-out spec to show a format is a look.
  Run held-out cases only through `run_tools.sh`, and read only their pass counts and rubric
  scores.
- A held-out case that the tuner has looked at no longer gates. Move it to the tuning set with a
  note, and have a blind writer replace it.

### 2. A fix is a general rule, never an answer key

- A prompt change must be worth having if no eval existed. It comes from a real failure, such as an
  audited session, not from the shape of one case.
- The prompt never contains an eval id, a fixture name, or a distinctive phrase from an eval prompt
  or from an agent's eval output. `python3 evals/check_leaks.py` checks the uncommitted prompt diff
  for 4-word overlaps with eval prompts. Run it before you commit.
- A reviewer who sees only the prompt diff and the prompt judges each change: is it a true, general
  rule? The reviewer does not see the evals.
- Put a rule in the numbered steps, at the step where the agent acts. A rule in prose after the
  step that ends the turn (a vote, a report, a delivery) is read too late and skipped. On
  2026-10-30, the same "model before the vote" rule moved case 22 in 1 of 3 runs when it sat in
  a paragraph after the vote step. "State the hypothesis first" did not move case 12 as an
  exhortation on 10-27; as step 1 of the procedure it took the new case 13 from 0/6 to 6/6
  (different cases, so this is a lead, not a controlled test).

### 3. Prompts are what a user would type, and fixtures are the world

- An eval prompt does not name the process (KB, orbit-kb, shift up, trigger, divergence), the step
  to skip, or the shape of the answer. Whether the agent finds the rule is part of the test.
- An eval prompt does not switch a rule off. If a rule blocks a case, the case is wrong or the rule
  is wrong. Decide which one.
- State comes from the fixture (files, `setup.sh`, git history), not from facts typed into the prompt.
- Runs never reach the network. `run_tools.sh` blocks installs, `lake`, `git push`, and fetches.
- No client names, ticket numbers, or URLs in fixtures or prompts.

### 4. Graders measure behavior, not wording

- Scripted checks (`grade_tools.py`) read the transcript and the work directory: what ran, in what
  order, what the KB holds, what the code does.
- Use a regular expression only for a format that the prompt defines, such as the delivery's `KB:`
  line. `--rubric` has an Opus judge grade each case's `assertions` on outcomes.
- Every case must score higher with the prompt than without it (`--prompt none`). If the baseline
  also passes, the case does not test the prompt. Rewrite it.

### 5. Prove that each case tests its rule

For each case that guards a rule, delete the rule from a copy of the prompt and run the case with
`--prompt COPY`. It must fail. A case that still passes does not test that rule.

### 6. Decide with statistics, not single runs

- Run each case 3 times (`--runs 3`). A case passes when 2 of 3 runs pass. `summary.json` has the
  verdicts.
  When a rubric ran, the gate uses the combined verdict (`passed_combined`: checks and rubric both
  pass), not `passed`, which counts the checks only. A run with a missing or failed rubric fails it.
- One run is noise. Scores change between identical runs.
- Compare against the base: the same cases with `--prompt` set to the base version of the prompt
  (`git show BASE:prompt/SAGITTARIUS.md > /tmp/base.md`).
- The gate is all of these: the held-out pass rate is at or above the agreed bar; no guarding case
  scores lower than at the base; every rule-deletion check fails as it should.

### 7. The small model's limit is a result, not a target

If a case passes only when the prompt describes that exact situation, stop. Record the case in the
table below: it runs on a stronger executor (`--model`), and the table gives the reason. Do not bend
the prompt toward one case.

| Case | Executor | Reason |
|---|---|---|
| 5, 6, 7, 8 | sonnet | Haiku, 3 runs each over five prompt cycles (2026-10-22): 0/3 on each. It names the trigger in its own words ("a one-line correction to my last change", "Divergence: yes") and still delivers with no KB. Sonnet passes 5, 6, 7 at 3/3. |
| 9 | sonnet | Haiku over four prompt cycles: 0/3, 0/3, 2/3, 1/3. When it misses, it names the handoff and still delivers with no KB ("The fix is one function and one check, so I judged..."). Sonnet passes 3/3. |
| 10 | sonnet | Haiku, three prompt versions (2026-10-27): it finds both causes in the code and reports them as the problem, with no discovery and no hypothesis. Rubric on the wording: 0/3, 1-2/3, 0/3; a general routing line did not help and was dropped. Sonnet passes 3/3 with the rule and 0/3 at the base and with no prompt. |
| 16 | sonnet | Haiku, today's prompt and two drafts (2026-10-28): 0/3 on recording a divergence after a change of plan, though it builds the new design well. Sonnet: 0/3 at the base, 3/3 with the change-of-plan rule. |
| 14 | sonnet | Haiku 2/3 with and without the prompt (2026-10-28), so it does not test the prompt. Sonnet: 2/3 with the prompt, 0/3 without. |
| 17, 18, 19, 20 | sonnet | Former held-out 116 and 105, moved to tuning after the tuner read them (49f3fb0). They run on 16's executor. |
| 11, 12, 21, 22 | sonnet | Not recorded. The seam experiment runs them on Sonnet (`tmp/testing/run_inc.sh`). Write the reason here when a Haiku run is on record. |
| 8 | opus | Sonnet, three cycles: it names the count difference as a divergence in 2 of 3 runs and still delivers with no KB, after it finds the cause. Opus passes 3/3. |

## Briefing subagents

Subagents do much of this work. Each one sees only its brief, so the brief carries these rules.

- **Variant writer.**
  - It may read the held-out format, one held-out fixture for style, and the runner and grader
    sources (for the check strings). It must not read the prompt, `docs/`, the tuning set, its
    fixtures, the runs, or git history.
  - Give it the behavior to test in general terms, plus the domains to avoid, so it does not
    copy a tuning case.
  - It verifies the case in a scratch copy: the fixture's tests pass, a correct build passes the
    checks, and the naive build fails them.
  - It reports only whether it wrote the file and each verification step as pass or fail. It never
    reports the domain, the prompts, or the trap, because the reader of the report is the tuner.
  - Two writers write to separate files. The tuner merges the files with a script, without reading
    them.
- **Prompt reviewer.** It sees only the prompt and the diff, never the evals. It judges whether each
  change is a true, general rule, whether it fits the prompt, and whether it can over-trigger.
- **Case writer for the tuning set.** It may read anything except the held-out set. The tuner checks
  its fixture for client data or personal data before committing.

## The loop

1. Run the tuning cases (`--runs 3`) with the changed prompt and with the base prompt.
2. Classify each failure. Use one of these causes:
   - **prompt text**: missing, ambiguous, contradictory, or hard to find;
   - **grader**: too strict, or checks wording;
   - **case setup**: a missing fixture or tool, or a hint;
   - **model limit**.
3. Fix by rule 2 (prompt text), rule 4 (graders), or rule 3 (case setup). Each prompt fix goes
   through `check_leaks.py` and the blind reviewer.
4. Repeat until the tuning cases pass. Then run the rule-deletion checks (rule 5).
5. Run the gate on the held-out set (rule 6). If the gate fails, go back to step 2 with the tuning
   cases only. Do not tune on held-out failures. Write new variants for any case you had to look at.
6. Commit at the end of each cycle, with the summary line in the message.

## Running it

```
evals/run_tools.sh --runs 3 -j 3 5 6 7               # tuning cases, live prompt
evals/run_tools.sh --runs 3 -j 3 --prompt /tmp/base.md 5 6 7
evals/run_tools.sh --runs 3 -j 3 --prompt none 5 6 7  # no-prompt baseline
evals/run_tools.sh --spec evals/heldout/heldout.json --runs 3 -j 3   # the gate
```

The runner starts `claude` the way an interactive shell does. It needs an unlocked credential and
the wrapper that appends the prompt (see "Install" in `README.md`). The author's wrapper is
`claude()` in a `.zshenv` file. A runner that bypasses the shell setup fails every case with
"Not logged in".

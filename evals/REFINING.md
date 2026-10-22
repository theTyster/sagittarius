# Refining the prompt without overfitting

Read this before you change `prompt/SAGITTARIUS.md` because an eval failed. The aim is a better
prompt, not only a better score.

The tool-use evals (`tools.json`, `run_tools.sh`) run a small model (Haiku) as the agent under test.
A small executor makes failures loud: a rule that only a strong model follows is under-specified.
That pressure has a failure mode of its own. It is easy to make a case pass by writing its answer
into the prompt, or its hint into the eval. The rules below stop that.

## The rules

### 1. Tune on one set, gate on another

- `tools.json` is the tuning set. `heldout/heldout.json` is the held-out set: one variant of each
  tuning case (id + 100), with different domain, wording, ids, order, and detail, and the same
  expected behavior.
- An agent that has not seen the runs, the prompt, or the prompt's history writes the variants.
- Diagnose and fix on the tuning set only. Do not read held-out transcripts to find a fix.
- Run the held-out set only at the gate, and only a few times. Each look makes it less independent.

### 2. A fix is a general rule, never an answer key

- A prompt change must be worth having if no eval existed. It comes from a real failure, such as an
  audited session, not from the shape of one case.
- The prompt never contains an eval id, a fixture name, or a distinctive phrase from an eval prompt
  or from an agent's eval output. `python3 evals/check_leaks.py` checks the uncommitted prompt diff
  for 4-word overlaps with eval prompts. Run it before you commit.
- A reviewer who sees only the prompt diff and the prompt judges each change: is it a true, general
  rule? The reviewer does not see the evals.

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
| (none yet) | | |

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

The runner goes through `claude()` from `~/.zshenv`, so it needs an unlocked credential. A wrapper
that bypasses the shell setup fails every case with "Not logged in".

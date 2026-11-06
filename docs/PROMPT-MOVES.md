# Where each section of the old prompt went (T08)

Ticket T08 makes `prompt/SAGITTARIUS.md` small: the prompt states the philosophy, `orbit-kb help`
holds the procedure, and the System 1 hook (`s1/hook.py`) gives hints about the work. This map
names the new home of every heading of the prompt before the redesign
(`git show 7da5320:prompt/SAGITTARIUS.md`, 789 lines, 44 headings).

`python3 docs/check_prompt_moves.py` checks it:

- c2: every heading of the old prompt has a row here.
- c4: every row with home `help TOPIC` names a key phrase, and the phrase is in that topic
  (`kb/share/orbit-kb/help/TOPIC.txt`; topic `general` is the general help in `kb/bin/orbit-kb`).
  A `hook` row with a phrase must be in `s1/questions.json` or `s1/hook.py`. A `prompt` row with a
  phrase must be in `prompt/SAGITTARIUS.md`.

Homes: `prompt` (kept, maybe shorter), `help TOPIC`, `hook`, `PHILOSOPHY.md §N` (a principle of
`docs/PHILOSOPHY.md`), or `dropped, because ...`. A heading can have more than one row when its
parts went to different homes.

## The map

| Old heading | Home | Key phrase | Note |
|---|---|---|---|
| `# Sagittarius` | prompt | | The title. |
| `## Purpose` | prompt | | Fast, clear, accurate, honest; alignment is the goal. |
| `## Purpose` | PHILOSOPHY.md §2 | | The full argument. |
| `## Scope` | prompt | | Kept as one short list: a question, advice, a report, a change. |
| `## Scope` | hook | `An answer or advice only, with no change to make` | The hook classifies each message (h_work). |
| `## Roles` | prompt | | Kept. |
| `## The light path` | prompt | | Kept as "Start light": the steps in short. |
| `### Shift up to a KB` | prompt | | Now "When to shift up". The signals stay. The three parts (System 1, the LLM, the human) and the effort signal are new (d_shift_three, d_effort_signal). |
| `### Shift up to a KB` | help general | `orbit-kb init DIR` | How to start a KB. |
| `### Leaning back` | prompt | | Kept, shorter. |
| `### Ask first, or build on default assumptions` | prompt | | Kept, shorter. |
| `## The orbit` | prompt | | Parallax, two orbits, quiet failures. The diagram is dropped; the phase tree replaces it. |
| `## The orbit` | PHILOSOPHY.md §4 | | Orbit, do not translate. |
| `## The knowledge base` | prompt | | Only the pointer: run `orbit-kb help` first. |
| `## The knowledge base` | help core | `Do not edit kb.pl by hand` | |
| `### Rules for the KB` | help core | `If the schema does not fit` | |
| `### Rules for the KB` | help answers | `Exit 2 is never a no` | |
| `### Rules for the KB` | help answers | `Resume work in a KB: orbit-kb show open` | |
| `### Ideas that the moves use` | help core | `or introduce (false now, must become true)` | Claim labels. |
| `### Ideas that the moves use` | help build | `no burn or flare is open` | `done`, burns, flares. |
| `## Moves` | help general | `verify FULFILL, DISPROVE, BURN` | The phase tree with its moves (T03 c9). |
| `### SURVEY: close the world (shared with discovery)` | help build | `For a defect, reproduce it first` | |
| `### DECOMPOSE: claims and questions` | help core | `A claim with no citation is drift` | |
| `### BUILD` | help build | `Run each retire and introduce check against the current code first` | |
| `### FULFILL: fulfillment in both directions` | help build | `Review with fresh eyes` | |
| `### DISPROVE: attack a claim (shared with discovery)` | help build | `Do not weaken a claim to absorb a counterexample` | |
| `### BURN: prove the claim in Lean` | help build | `Burns: prove the claim in Lean` | |
| `### EXPLAIN` | dropped, because the purpose (clear) and the plain-language rule of the prompt already cover it | | |
| `## When the human says that it is wrong` | prompt | | The examples of a divergence and the preference-change rule stay. |
| `## When the human says that it is wrong` | hook | `Doubt, surprise or a pointed question counts` | h_divergence and h_change_of_plan give the hints. |
| `## When the human says that it is wrong` | help build | `A preference change` | The record steps. |
| `## Honesty rules` | prompt | | Every rule (c3); rule 5 reworded (see below). |
| `## Delivery` | prompt | | Every rule (c3); one section name changed (see below). |
| `## Speed` | prompt | | Merged into "Fast" in the purpose. |
| `## Discovery orbit` | prompt | | In the phase tree. |
| `### Purpose` | prompt | | One sentence in the phase tree. |
| `### When to run discovery` | prompt | | In the phase tree. |
| `### When to run discovery` | hook | `Learn how something behaves now, or whether a problem is real` | h_work = research. |
| `### The hypothesis` | prompt | | The principle, in short. |
| `### The hypothesis` | PHILOSOPHY.md §5 | | The full statement. |
| `### The hypothesis` | help discovery | `Too strong` | The worked example moves to the SIGNAL recipe. |
| `### The tiny discovery orbit` | prompt | | Kept, shorter: it is the light path of discovery. |
| `### The lap` | help discovery | `budget_spent` | |
| `### Moves` | help general | `research SIGNAL, SURVEY, FLYBY, TRAJECTORY, DISPROVE (discovery)` | |
| `#### SIGNAL: pin the report` | help discovery | `SIGNAL: pin the report` | |
| `#### SURVEY: touch the current system` | help discovery | `SURVEY: touch the current system` | |
| `#### SPECTRUM: split into claims and choose tools` | help discovery | `Choose the cheapest tool that can falsify each claim` | The tool table. |
| `#### SPECTRUM: split into claims and choose tools` | PHILOSOPHY.md §11 | | Each claim has a shape. |
| `#### FLYBY: explore combinations with SMT` | help discovery | `The existing-world rules with no property must be SAT` | The seven steps. |
| `#### TRAJECTORY: explore sequences with TLA+` | help discovery | `Start with two processes` | The eight steps. |
| `#### DISPROVE: attack the claims` | help discovery | `a fresh subagent sees only the report` | |
| `#### GO / NO-GO: a weighted vote` | prompt | | The weights and the seal stay: they are the roles in action. |
| `#### GO / NO-GO: a weighted vote` | help discovery | `GATE: the GO / NO-GO vote` | The record steps. |
| `### Asking the human` | prompt | | The general rule for asking ("Start light") covers it. |
| `### Asking the human` | help discovery | `Ask about conflicts first, then surprises, then boundaries` | |
| `### The discovery report` | help discovery | `Not explored:` | The report template. |
| `### Handoff to the build orbit` | help discovery | `HANDOFF to the build orbit` | |
| `### Back to discovery` | prompt | | One line in the phase tree. |
| `### Back to discovery` | help discovery | `SIGNAL if the hypothesis is wrong` | Which move to go back to. |
| `### Honesty rules for discovery` | prompt | | Rules 1 to 6 stay, word for word (see below). |
| `### Honesty rules for discovery` | help discovery | `WD1, WD3, WD7, ED3-ED7` | Rule 7 names lint codes. |
| `### Sizes and speed` | dropped, because the sizes read as tiers (PHILOSOPHY.md §7, open question E); the tiny orbit stays in the prompt | | |
| `### Sizes and speed` | help discovery | `Set a timeout on every solver run` | |

### Rules restored after review (T08 follow-up)

Review found rules that the first small prompt lost. Each row names its home and a key phrase.
For home `prompt`, c4 checks the phrase in `prompt/SAGITTARIUS.md`.

| Old heading | Home | Key phrase | Note |
|---|---|---|---|
| `### Ask first, or build on default assumptions` | prompt | `invites "approve all"` | R1: do not ask the human to approve a list. |
| `### Ask first, or build on default assumptions` | help core | `whose default is the most costly if it is wrong` | R2: the order of the questions in a round. |
| `### Asking the human` | help discovery | `Ask about conflicts first, then surprises, then boundaries` | R2 in discovery. |
| `### The tiny discovery orbit` | prompt | `I expect GO` | R3: a prediction leaks the sealed vote. |
| `### The tiny discovery orbit` | prompt | `write it nowhere until the human votes` | R3: the seal with no KB. |
| `#### GO / NO-GO: a weighted vote` | prompt | `Only the human changes the scope or raises the budget` | R4. |
| `## The light path` | prompt | `a check you change, not one you skip` | R5: a test of the old behavior. |
| `## The light path` | prompt | `say where you looked` | R5: no tests found. |
| `## The light path` | prompt | `say so under "Not checked"` | R5: no executable check. |
| `## The light path` | prompt | `passes before and after` | R5: a check that behavior stays the same. |
| `### The hypothesis` | help discovery | `Collapsed:` | R6: the worked example (too strong, collapsed, weak). |
| `### Leaning back` | prompt | `it stays until the ticket closes` | R7: the KB stays. |
| `### Leaning back` | prompt | `Do not drop an open question, a failing check, or a burn` | R7. |
| `### Leaning back` | prompt | `The next ticket starts light` | R7. |
| `### BURN: prove the claim in Lean` | prompt | `Only a human can skip a proof` | R8: a waiver with a due time. |
| `## Speed` | help core | `subagent on a fast model` | R9: long mechanical work; a small task needs no subagent. |
| `## When the human says that it is wrong` | help build | `Defaults that conflict with it are now defeated` | Step 4: record the human's answer. |
| `## When the human says that it is wrong` | help build | `Ask that small cluster, not every dormant question` | Step 5: query to_ask. |
| `## When the human says that it is wrong` | help build | `If burn(C) now holds, prove the claim in Lean` | Step 6: rebuild and rerun the checks. |

## Honesty rules for discovery: they stay in the prompt

Rules 1 to 6 stay in the prompt, word for word. They are honesty rules, and honesty is part of
the philosophy (PHILOSOPHY.md §9), not procedure. Rule 7 moves to `orbit-kb help discovery`: it
names lint codes, which are procedure and can change ("read `orbit-kb whynot
'discovery_ready'`, not this list"). The prompt keeps its point in one sentence: what blocks
`discovery_ready` blocks GO.

## Rewordings in the checked sections (c3)

`docs/check_prompt_small.py` compares the rules of "Honesty rules", "Delivery", and rules 1 to 6
of "Honesty rules for discovery", after whitespace is collapsed. A rule can be rewrapped. Each
rewording is listed here, with the reason. The check reads this list.

<!-- c3-rewordings: begin -->

Rule 5 of "Honesty rules":

OLD: The formal artifacts trust you. They catch honest mistakes; they do not stop cheating. `orbit-kb` cannot verify `--by human`, and `orbit-kb prove` does not resist a proof built to fool it. So write `--by human` only to record what the human said, and never work around a check, a lint rule, or `orbit-kb prove`. A safeguard that you work around protects no one.
NEW: The formal artifacts trust you. Each catches its own kind of error; none stops cheating. `orbit-kb` cannot verify `--by human`, and `orbit-kb prove` does not resist a proof built to fool it. So write `--by human` only to record what the human said, and never work around a check, a lint rule, or `orbit-kb prove`. A safeguard that you work around protects no one.
WHY: PHILOSOPHY.md §10 (decision d_retire_honest, 2026-11-05) retires "honest mistakes": each tool catches its own kind of error, and none stops cheating. Only the second sentence changes.

The `KB:` and `Triggers:` paragraph of "Delivery":

OLD: The `KB:` field tells the human where the evidence lives: in the KB, or only in this report. The `Triggers:` field compares the work with "Shift up to a KB". If a trigger fired, the `KB:` field names a KB. Keep each field to a line when the change is small. Write "none" in an empty field, so that the human sees you looked. Include a screenshot when the change has a user surface. In a KB, `orbit-kb report` drafts the middle fields and adds `Open:` (open burns, lapsed waivers, proofs that no longer count). Keep `Open:` in the delivery.
NEW: The `KB:` field tells the human where the evidence lives: in the KB, or only in this report. The `Triggers:` field compares the work with "When to shift up". If a trigger fired, the `KB:` field names a KB. Keep each field to a line when the change is small. Write "none" in an empty field, so that the human sees you looked. Include a screenshot when the change has a user surface. In a KB, `orbit-kb report` drafts the middle fields and adds `Open:` (open burns, lapsed waivers, proofs that no longer count). Keep `Open:` in the delivery.
WHY: the section "Shift up to a KB" is now "When to shift up". Only the section name changes.
<!-- c3-rewordings: end -->

# Where each section of the old prompt went (T08)

Ticket T08 makes `prompt/SAGITTARIUS.md` small: the prompt states the philosophy, `orbit-kb help`
holds the procedure, and the System 1 hook (`s1/hook.py`) gives hints about the work. This map
names the new home of every heading of the prompt before the redesign
(`git show 7da5320:prompt/SAGITTARIUS.md`, 789 lines, 44 headings).

`python3 docs/check_prompt_moves.py` checks it:

- c2: every heading of the old prompt has a row here.
- c4: every row with home `help TOPIC` names a key phrase, and the phrase is in that topic
  (`kb/share/orbit-kb/help/TOPIC.txt`; topic `general` is the general help in `kb/bin/orbit-kb`).
  A `hook` row with a phrase must be in `s1/questions.json` or `s1/hook.py`.

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
| `### Shift up to a KB` | prompt | | The signals stay. The three parts (System 1, the LLM, the human) and the effort signal are new (d_shift_three, d_effort_signal). |
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
| `## Honesty rules` | prompt | | Every rule, word for word (c3). |
| `## Delivery` | prompt | | Every rule, word for word (c3). |
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
| `### Asking the human` | prompt | | One line: ask only what evidence raised. |
| `### Asking the human` | help discovery | `Ask about conflicts first, then surprises, then boundaries` | |
| `### The discovery report` | help discovery | `Not explored:` | The report template. |
| `### Handoff to the build orbit` | help discovery | `HANDOFF to the build orbit` | |
| `### Back to discovery` | prompt | | One line in the phase tree. |
| `### Back to discovery` | help discovery | `SIGNAL if the hypothesis is wrong` | Which move to go back to. |
| `### Honesty rules for discovery` | prompt | | Rules 1 to 6 stay, word for word (see below). |
| `### Honesty rules for discovery` | help discovery | `WD1, WD3, WD7, ED3-ED7` | Rule 7 names lint codes. |
| `### Sizes and speed` | dropped, because the sizes read as tiers (PHILOSOPHY.md §7, open question E); the tiny orbit stays in the prompt | | |
| `### Sizes and speed` | help discovery | `Set a timeout on every solver run` | |

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
<!-- c3-rewordings: end -->

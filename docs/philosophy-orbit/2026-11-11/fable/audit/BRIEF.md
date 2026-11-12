# Common brief for the alignment audit (read this first)

## The job
Ty (the owner of the Sagittarius project) has two new texts: a full rework of the system prompt
and of the philosophy. They are proposals on a branch. Ty asked for an analysis of what in the
*build* (the tools, the hub kit, the hook, the other documents, the checks) must change so that
it agrees with these two texts. You audit ONE area of the build (named in your task). You only
read. Your one output is a report file.

## The two new texts (the reference; read both in full before you audit)
- New prompt:      /home/ty/Projects/mine/wt/sagittarius/philosophy-fable/prompt/SAGITTARIUS.md  (454 lines)
- New philosophy:  /home/ty/Projects/mine/wt/sagittarius/philosophy-fable/docs/PHILOSOPHY.md     (864 lines;
  the parts that matter most: "The hypothesis of Sagittarius", "The orbit", "What follows" (14
  principles, each ends with "In the prompt: ..."), "Where Sagittarius sits", "Under trial",
  "How to judge a change")

## The build to audit
The main checkout: /home/ty/Projects/mine/sagittarius (branch main). In it, prompt/SAGITTARIUS.md
and docs/PHILOSOPHY.md are the OLD texts: the build was written against them. Read them only to
see what a file in the build cites.

## Decisions of Ty that the new texts carry (Ty's words; use them to judge)
- Two interfaces: "1. Sagittarius: A system prompt and orbit-kb. Sagittarius should carry the
  philosophies of this repo everywhere that it goes. 2. MindHole (just-now named.): The hub.
  Sagittarius provides a hub as a kind of pinned workspace. Each mindhole can run its own version
  with its own orbit-kb and bespoke modifications for each given workspace. The mindhole and
  Sagittarius work best together but are not dependent on one another." ("MindHole" = hubkit/.)
- "I think the hooks should be coupled with sagittarius and not the mindhole"
- System 1 (s1/): "We can't make an algorithm that mechanically detects these things and we
  can't let a model grade themselves on whether they are diverting. something outside needs to
  help. The system 1 model's main purpose is to help with detection and classification." It
  "might eventually get its own API's in the orbit-kb tool." Status: "optional for now. Maybe
  'recommended'." When System 1 and the agent disagree, it goes to a formalism, or to the
  human, or both.
- "All six signals should elicit the same response. Shifting up simply means getting more
  specific and paying closer attention."
- "size determines nothing. Clarity does."
- Back to discovery: "we only go back there if the hypotheses need to change." A clear change of
  the hypothesis (the human's answer says what it changes to) stays in build. "Remember that the
  mindhole expects discovery to be a different agent".
- Every ticket has a hypothesis, written wide on purpose, with its premises beside it, every
  time it is stated. A ticket starts in words; a KB starts on a signal. A typo never needs a KB.
- "We use one language because one language gives us one lens. we should use the right lens for
  the right problem".
- "Lean is not a modeling language" (say "definitions and theorems", not "Lean model").
- UAT report of Ty: "I haven't seen _any_ lean proofs or prolog statements since starting to
  use Sagittarius. This project expects users to be able to atleast _read_ lean and prolog. but
  I have not received that." (So: formal statements must reach the human, beside plain claims.)
- "the philosophy should not be installed anywhere. It should just be reflected into the system
  prompt. and guide the sagittarius and mindhole project trajectories over time."
- "the system prompt should have its own installation sequence. Similar to how I use it with my
  .zsh aliases. An agent should probably help handle the setup of this." Standing rule: no
  script writes settings.json.
- "we need a semver system for sagittarius now, so I can refer to prior versions better."
- New on 2026-11-12: "Any test of any kind counts as an artifact." (about the third voter, "the
  artifacts", in the discovery vote). Ty likes the rule that a claim contested twice must go to
  a formal statement, and the delivery fields `Signals:` (was `Triggers:`) and `Formal:` (new).

## What to produce
Write ONE Markdown report to the file named in your task. For each finding give:
- an id (your area prefix + number) and a one-line title;
- **New text**: the section of the new prompt or philosophy, with a short exact quote;
- **Build**: what the build does or says, with `path:line` and a short exact quote that you read;
- **Kind**: `contradiction` (the build does or says the opposite), `gap` (the new text needs
  something that the build does not have), or `stale words` (a name, a citation, a heading, an
  example that no longer matches);
- **Smallest change** that would bring the build into agreement (one or two sentences; say which
  files; do not design in depth);
- **Size**: S (words only), M (one feature or rule, with tests), L (touches the contract or several
  parts);
- **What holds the old behavior**: tests, contract clauses (kb/CONTRACT.md D-numbers), checks.
Order: first the candidates that I give you (verdict for each: CONFIRMED, PARTLY, NOT CONFIRMED,
NOT CHECKED), then the differences that you found yourself. Then a last section
"## Suggestions beyond alignment": improvements that the new texts do not strictly need, but
that would serve the philosophy (Ty gave license for these; keep them apart from the findings,
and give for each the problem it solves and the evidence that you saw).
Also list "## Where the build already agrees" (short; things that need no change and that a
reader might worry about).

## Rules
- Check before you claim. Every sentence about the build needs a `path:line` that you read. If
  you did not check something, write "not checked". Do not guess from a file name.
- A candidate is a lead, not a fact. Some are wrong. Say so when one is.
- Read only. Change no file in any checkout. Write only your report (and scratch files beside it).
- Use absolute paths and `git -C`. Do not `cd` into a checkout or worktree.
- Do NOT read anything under `evals/heldout/` or `evals/runs/` (held-out eval hygiene), and
  nothing under `.claude/worktrees/`. Under `tmp/`, read only the files that your task names.
- Do not run test suites, `lake`, `lean` on projects, solvers, or the evals. `orbit-kb help ...`
  and `orbit-kb` commands on a throwaway KB in your scratch folder are fine
  (`/home/ty/Projects/mine/sagittarius/kb/bin/orbit-kb`).
- Other projects on this machine belong to clients. Copy nothing from outside
  /home/ty/Projects/mine/sagittarius and /home/ty/Projects/mine/wt/sagittarius.
- Do not start subagents. Do not ask questions: record what is unclear in the report.
- Write plain, short sentences. Quote Ty only word for word (from this brief).
- Your final message: at most 200 words: counts by kind and size, the three findings that
  matter most, and the path of the report. The report file is what I will read.

# Orbital shifting: refinement loop (scheduled for 2026-10-20, after 21:00)

Ty asked for this on 2026-10-20. A session cron job starts it. This file is the full
instruction, so that the cron prompt can stay short and Ty can read the plan before it runs.

## Goal

Improve `thoughts/orbital-shifting-system-prompt-draft.md` for **clarity, accuracy,
honesty, and speed**. Use three sub-agent passes. Then present the result to Ty as a
microsite.

The fundamental goal, in Ty's words: a process that is "not overfit or compulsively
restrictive but shepherds agents, humans, and code to work together synchronously. Rigour
should scale fluidly with the complexity and depth of the task."

## Order

1. Finish D10 first. Ty said this loop is the last step. If the Lean sub-agent or the D10
   fixes (see `thoughts/orbit-kb-d10-review-2026-10-20.md`) are still in progress, finish
   them first. If D10 is blocked on Ty, record the blocker and start the loop anyway. The
   loop edits only the draft and new files, so it does not conflict with D10.
2. Run passes 1, 2, and 3 in order, one sub-agent each. Each pass reads the result of the
   previous one.
3. After each pass returns: review its diff, commit it, and post an update to Ty (see
   "After each pass").
4. Build the microsite with a fourth sub-agent. Commit it. Present it.

## Method: the skill-creator philosophy

Each pass agent MUST first read the skill-creator skill:
`~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md`,
especially "Skill Writing Guide", "Writing Style", and "How to think about improvements".
The points that matter here:

- **Generalize.** The prompt runs on many tasks, not on the examples in front of you. Do not
  add narrow, fiddly rules for one scenario.
- **Keep it lean.** Remove text that does not pull its weight. Fewer words that the model
  follows beat more words that it skims.
- **Explain the why.** An all-caps MUST or NEVER is a yellow flag. Where a rule matters,
  give the reason, so the model can apply it to cases the rule did not foresee. Keep a hard
  rule only where a reason alone is not enough (for example, "only a script records a
  proof").
- **Draft, then reread with fresh eyes.**
- **Test against realistic prompts, and compare with the previous version.** Each pass
  walks the scenarios below through both the old and the new text.

## Scenarios (shared by every pass)

Walk each scenario through the previous version and the new version. Judge on paper: which
moves would an agent make, what would it ask, which records would it write, and where would
it slow down for no reason or skip a check it needed?

1. **Trivial:** "Make the four buttons on the settings page purple." Expect: light start,
   no KB, a check run red first, quick delivery.
2. **Ambiguous:** "Add discount codes to checkout." Expect: one round of the costliest
   questions, a shift up to a KB when the answers raise new questions, and a universal
   claim ("no code takes a price below the floor") that burns.
3. **Divergence mid-build:** The human says "that's not what I meant" after delivery.
   Expect: the divergence is recorded, and the agent decides whether the build or the
   problem is wrong.
4. **Report, not a request:** "Users say sync loses their edits sometimes." Expect: the
   discovery orbit, not the build orbit.
5. **Non-software:** "Help me decide between two job offers." Expect: the process scales
   down to almost nothing, and does not force code-shaped records onto it.

## Invariants (every pass keeps these)

- The **Roles** section text that Ty wrote stays word for word: the human owns the intent
  and the final product; the LLM owns the build; the formal artifacts are impartial; "Your
  goal should be to help foster understanding between these three roles."
- Ty's decisions stay in force. A pass may reword them but not change what they mean:
  - start light, then shift up on the four triggers (questions, divergence, a claim that
    burns, handoff); up to three questions in the first round;
  - a burn needs a proven verdict; only a script records a proof; TLC is not a proof; a
    human may waive with a due time; conformance is optional;
  - land by the model's judgment within the harness guardrails; stop for the human on
    public interfaces, data, security, money, or hard-to-undo changes;
  - do not commit the KB unless the human asks;
  - TLA+ is neither forbidden nor suggested in the build orbit; discovery keeps it;
  - ask the costliest-if-wrong questions first, then the ones that settle others;
  - "universal" means a domain too large to check case by case;
  - the threat model is trust: checks guard against honest mistakes, not cheating.
- Divergence is good and loud. Silence and vacuity are the danger. "A check is only
  valuable if it can fail."
- Every `orbit-kb` command, option, and predicate that the draft names must exist. Check
  with `orbit-kb help` and `shared/link/.local/share/orbit-kb/` (core.pl, modules). Do not
  change the CLI or its rules in this loop. Record a mismatch as a finding instead.
- Human-facing text uses ASD-STE100 style: short sentences, one idea each, consistent
  terms.
- The "Design notes (not part of the prompt)" part stays. Update its provenance and Open
  items when a pass changes something they describe.
- `thoughts/orbital-shifting-merge-check.py` is the evidence of an earlier ticket. Its
  frame hashes will break. Do not update it or try to keep it green.
- Do not edit `AIDLC.md` or `shared/copy/.zshenv`. The draft goes live only after Ty's
  review.

## The three passes

Each pass has a lead focus, but fixes anything it finds.

- **Pass 1, clarity and leanness.** Cut what does not pull its weight. Merge repeated
  rules. Replace bare MUSTs with reasons. Make the structure easy to scan: the light path
  should be readable in under a minute.
- **Pass 2, accuracy and honesty.** Check every statement against the CLI, the rules, and
  Ty's decisions. Check that the prompt never lets a claim exceed its evidence, and that it
  says what is not checked. Fix contradictions between sections.
- **Pass 3, speed and fluid rigor.** Check that rigor scales smoothly with the task: no
  ceremony for scenario 1 or 5, and enough for scenario 2. Check that the shift-up
  triggers are easy to notice and that shifting down after a scare is allowed. Then read
  the whole prompt once, start to end, as a new agent would.

## Prompt for each pass agent

Fill in N and the focus. Use `subagent_type: general-purpose`.

> You are pass N of 3 refining the Orbital Shifting system prompt,
> `/home/ty/.dotfiles/thoughts/orbital-shifting-system-prompt-draft.md`. Read
> `/home/ty/.dotfiles/thoughts/orbital-shifting-refinement-loop.md` in full first: it holds
> the goal, the method, the scenarios, and the invariants. Then read the skill-creator
> skill it names. Your lead focus: FOCUS.
>
> 1. Save a copy of the current draft to the scratchpad as the baseline.
> 2. Walk the five scenarios through the baseline. Note where an agent would go wrong, slow
>    down, or be unsure.
> 3. Edit the draft in place. Keep every invariant.
> 4. Walk the five scenarios through the new text. Confirm each problem you fixed, and that
>    nothing new broke.
> 5. Append a section "Pass N" to
>    `/home/ty/.dotfiles/thoughts/orbital-shifting-refinement-record.md` (create it if
>    absent): the problems found, each change and its reason, the scenario results before
>    and after, findings you did not fix (for example a CLI mismatch), and the line count
>    before and after.
>
> Do not commit. Do not edit any file other than the draft and the record. Do not run
> `git add`. Report back in under 300 words: the main changes, the scenario verdicts, and
> any open finding that needs Ty.

## After each pass

1. Read the diff (`git diff --stat` and the diff itself). Check the invariants yourself,
   briefly: the Roles text is intact, the decisions are still there, and no named
   `orbit-kb` command is invented. Undo or fix anything that breaks one, and say so.
2. Commit with a pathspec, never `git add -A`:
   `git add thoughts/orbital-shifting-system-prompt-draft.md thoughts/orbital-shifting-refinement-record.md`.
   Message: `docs(claude): orbital-shifting refinement pass N (FOCUS)`. No attribution
   trailer. Do not push.
3. Post an update to Ty: the commit hash, the line count before and after, the three to
   five most important changes with their reasons, the scenario verdicts, and any finding
   that needs Ty. Ty reads these later to track the loop.

## The microsite

After pass 3, spawn one sub-agent to build it.

- Location: `thoughts/orbital-shifting-site/`. Start page `index.html`.
- Self-contained: plain HTML and CSS, at most a little vanilla JavaScript, no CDN, no
  build step, no external fonts or images. It must open from the file system.
- Audience: Ty, and people Ty shows it to. Purpose: a presentation of the revised
  orbital-shifting philosophy, not a copy of the prompt.
- Language: simple technical English (ASD-STE100): short sentences, one idea each, the
  same term for the same thing.
- Content, as a sequence of short slides or sections with keyboard navigation:
  1. The problem: quiet misalignment between human, agent, and code.
  2. The three roles and why each owns what it owns.
  3. Parallax: divergence is clarity; silence is the danger; a check is only valuable if
     it can fail.
  4. Start light, shift up: the light path and the four triggers, with scenarios 1 and 2
     as worked examples.
  5. The build orbit and its moves, in one diagram (inline SVG or CSS).
  6. The discovery orbit, and when to take it.
  7. Burns: why a universal claim needs a proof, and what a proof does and does not show.
  8. The trust threat model.
  9. Honesty in delivery: what the report says, including what was not checked.
  10. What changed in the three passes, and why.
  11. Open questions for Ty.
- Every factual statement on the site must match the final draft. The agent checks this
  and lists any statement it could not match.
- Commit with a pathspec: `git add thoughts/orbital-shifting-site/`. Message:
  `docs(claude): add the orbital-shifting microsite`. Do not push.

## Presenting

Tell Ty the absolute path of `index.html`, and run `xdg-open` on it if a display is
available. Give a five-line summary of the whole loop: the commits, the line count from
start to end, the largest changes, and the open findings. Ty reviews the draft next and
decides whether it goes live.

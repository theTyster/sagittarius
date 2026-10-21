# Orbital Shifting: design notes

The prompt went live on 2026-10-21. Its source of truth is now
`shared/link/.claude/orbital-shifting/ORBITAL-SHIFTING.md`, which `claude()` in
`shared/copy/.zshenv` appends to every work session. Edit the prompt there. Its history up
to 2026-10-21 is in this file's git log. This file keeps the design notes.

# Design notes (not part of the prompt)

Status: draft, 2026-10-14. The discovery orbit was merged in on 2026-10-19. Refinement
passes 1 (clarity and leanness), 2 (accuracy and honesty), and 3 (speed and fluid rigor)
ran on 2026-10-20, and review round 1 (the user's notes) on 2026-10-21; see
`thoughts/orbital-shifting-refinement-record.md`. Not live.
`AIDLC.md` is still appended to every session by `claude()` in `shared/copy/.zshenv`.

The record of the merge is `thoughts/orbital-shifting-merge-record.md`. Its verification
script is `thoughts/orbital-shifting-merge-check.py`.

## Where each part comes from

| Part | Source |
|---|---|
| Closed-world SURVEY, claim labels, DISPROVE verdicts, why-not, EXPLAIN, KB under `thoughts/` | orbital shifting |
| One-agent orbit, divergence, loud versus quiet, examples to the human, fixed-point stop | PARALLAX brainstorm, as revised by the user |
| Dormant questions with defaults, ask only the touched cluster, build one-shot first | user, 2026-10-14 |
| Lean as the burn tool; per-claim choice | user, 2026-10-14 |
| A burn needs a proof, always; only `orbit-kb prove` records it; only a human waives it, with a due time; TLC is not a proof; conformance is optional | user, 2026-10-19 |
| Start without a KB and shift up (now the "light path" section); land by judgment; do not commit the KB; no TLA+ text in the build orbit; question order | user, 2026-10-20 |
| The four shift-up triggers, the divergence signals, one free round of questions, the meaning of universal | user, 2026-10-20 |
| Red run first, claim wording matches evidence, human landing gate, deadline bypass, screenshots, both-direction fulfillment, test clean-up | AIDLC v1 and v2 brainstorm |
| Accepted renames (preserve/retire/introduce, why-not, disclosure) | user, 2026-10-14 |
| "Discovery orbit" and "Discovery module", word for word except one sentence ("Run `orbit-kb uses build` first.") | Part 1 of `thoughts/discovery-orbit/discovery-orbit-draft.md` (commit d46dd23), ratified by the user |
| Scope routes, shared SURVEY and DISPROVE, the way back to discovery, the digest and resume rules | Part 2 of the same draft |
| `orbit-kb uses` adds the module of the next orbit | merge record, finding F1; user, 2026-10-19 |
| The trust threat model (honesty rule 5); inherited burns through `supersedes`; E15, E16, and real due times | user, 2026-10-20 (D10 follow-up, commit cb7ba90); added to the prompt in pass 2 |
| "Shift down" after the cause of a shift is resolved; a change request with open details stays in the build orbit | refinement loop plan ("rigour should scale fluidly"), pass 3 |
| Ratification of "Shift down" | user, 2026-10-21 |
| One meaning of "check": an executable test of one claim, with a pass or fail result. The impartial party is "the formal artifacts"; the CHECK move is now FULFILL; other uses became "verify", "lint", or "review" | user, 2026-10-21 ("when definitions collide, ambiguity only serves confusion") |
| Two orbits (discovery, then build; build without discovery when the request is clear), one diagram, "we orbit to achieve understanding" | user, 2026-10-21 |
| The tiny discovery orbit, with no KB; the "When to run" list no longer pulls against the build route | user, 2026-10-21 ("Making changes to the discovery prompt is ok") |
| GO is blocked only by what `discovery_ready` blocks, not by every lint error | user, 2026-10-21 |
| `refuted(Counterexample)` in `disproof` and `lean_result` | user, 2026-10-21; CLI changed the same day |
| A skip is a waiver on a claim, a check, or a question, with a due time; no separate bypass record | user, 2026-10-21 ("a bypass and a waiver seem too similar") |
| GO / NO-GO / HOLD is a weighted vote: human 0.4, agent 0.3, formal artifacts 0.3; the agent's vote is sealed until the human votes; a win needs the human's vote; a split, or the human outvoted, is HOLD plus another orbit and a divergence | user, 2026-10-21 (replaces "no recommendation at the gate", the same day) |
| `universal` has one definition: the burn trigger | user, 2026-10-21 |
| A red reproduction test is a check and enough evidence for the tiny discovery orbit | user, 2026-10-21 |

## What was dropped

Sets, tasks, charters, roles beyond human and agent, per-ticket tiers, phase approvals,
traceability matrices, the seven-stage pipeline order, Opus at high effort for every stage,
the always-run `explain` closer, and the TLA+ process model of the AIDLC.

## Not verified

The rules now live in `~/.local/share/orbit-kb/` and run through `orbit-kb`. Both engines
were tested on them (2026-10-15; `scripts/orbit-kb/test_orbit_kb.sh`). The points below
were open before that; both are now resolved:

- whether `\=` and `>` behave as expected under s(CASP)'s constraint semantics;
- whether `done`, which uses `not` over unbound variables, runs in acceptable time. It
  did not: `not under(_)` was unsound (hazard H1). `done` now uses helper rules.
  `orbit-kb` answers from SWI-Prolog and cross-checks with s(CASP) on a grounding of the
  program (contract change D8). `done` on 20 claims with 2 runs each went from 20 s, the
  s(CASP) time limit, to 0.3 s. On 200 claims it takes 6 s
  (`thoughts/orbit-kb-perf-results-2026-10-16.md`).

Still not verified: whether an agent follows the merged prompt as written. No agent run
has used the discovery orbit or the merged prompt.

## Open

Decisions of the user on 2026-10-20 closed items 1 to 6:

1. **Where the KB lives.** Do not commit the KB, unless the human asks.
2. **Unattended landing.** Allowed. The model lands the change when it judges it safe,
   within the harness guardrails. It stops for the human on public interfaces, data,
   security, money, and changes that are hard to undo.
3. **TLA+ in the build orbit.** The prompt does not mention it. It is not forbidden and not
   suggested, so that agents do not follow a suggestion by default. Discovery keeps it.
4. **Plausible.** Available: `sharlean list` shows `plausible` (Lean 4.34.0).
5. **A KB for every change request.** No. The work starts light, with no KB, and may ask
   one round of up to three questions. It shifts up to a KB when one round of questions
   does not settle the ticket, at a divergence, at a claim that burns, or at a handoff.
   A second lap is not a trigger of its own: a new lap starts from a divergence, a
   question, or a handoff. This
   follows the user's rule of 2026-10-13: the tier "can't be graded once"; start low when
   clarity seems apparent, and move up after a miscommunication.
6. **The three-question cap.** Kept. Ask first the questions whose defaults are the most
   costly if wrong, then the questions whose answers settle other questions.

Settled (user, 2026-10-21): the light path records no script-written test results by
design. It is one try to get the request right; the human's verification closes it, and
honesty surfaces any divergence. Its delivery names each check command and its result.

Settled (user, 2026-10-21): a deadline skip is a waiver. A waiver can target a claim (its
burn), a check, or a question, and it lapses at its due time.

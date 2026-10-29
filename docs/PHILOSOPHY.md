# The philosophy of Sagittarius

This document says what Sagittarius believes, and why. It does not say how to do the work. The
procedure is in [`prompt/SAGITTARIUS.md`](prompt/SAGITTARIUS.md) and in `orbit-kb help`.

Use this document to judge a proposed change to the prompt or to `orbit-kb`. A good change serves
one of these principles and breaks none of them. If a change must break one, the change is a
decision for Ty, not an edit.

Each principle has a status:

- **Settled:** Ty decided it, and the prompt or the tool applies it.
- **Open:** the intent is clear, but Ty must still decide the exact statement or the mechanism.

Each principle also gives its sources:

- A prompt section is a heading in `prompt/SAGITTARIUS.md`.
- A memory is a file in Ty's agent memory for this project
  (`~/.claude/projects/<this project>/memory/`). It is not in the repository.
- A design note is in git history: `git show thoughts-archive:thoughts/<file>`. The project had the
  name "Orbital Shifting" when these notes were written.

## The bet

Humans and agents will always misalign. Models will guess better what a human wants, but
they do not have the data in the head of the human. The human must still explain the intent.
Errors come from that explanation. So Sagittarius aims at alignment on intent, not at the
difficulty of the task. Difficulty changes with each new model. Misalignment does not.

> "I'm making the bet that even with ASI, humans will still need to explain what they want, and
> that will continue to be a point of friction." (Ty)

Source: design note `orbital-shifting-why.md`; memory `orbit-why-signals-not-tiers`. Settled.

## The principles

### 1. Alignment comes before proof

The goal is that the human, the agent, and the formal artifacts agree on what to build and on when
it is done. A proof is one tool for that goal. It is not the goal. Alignment is always possible
before a change lands. A full proof is not always possible.

Each change must be fast, clear, accurate, and honest. These four words measure
every rule in the prompt. A rule that does not make the work faster, clearer, more accurate, or
more honest does not belong.

Source: prompt "Purpose"; deck slide 5. Settled.

### 2. Three roles, and no role grades its own work

- The human owns the intent and the final product. The human is the source of intent, but not
  always the source of clarity.
- The agent owns the build. It makes the request clear enough to build.
- The formal artifacts (the KB, the tests, the proofs, and the models) are impartial. They can
  disagree with the agent and with the human.

Each lap of the work goes through the formal artifacts and through the human. Thus no role
checks only its own work. The human decides. In the discovery vote, nothing wins without the
human, and the human needs one other role to agree. The human looks at results and at proofs. The
human does not need to read test logs or formal text. The agent shows concrete examples.

Source: prompt "Roles", "The orbit", "GO / NO-GO: a weighted vote"; memory
`orbit-proofs-not-tests`. Settled.

### 3. Orbit the intent. Do not translate it

Each view of the intent must come from the intent itself: the human's words and the current
system. A view must not come only from the artifact before it. When each step reads only the
output of the step before it, errors pass down the chain. Then the result can drift far from what
the human meant. That is translation, not orbit.

Two failures teach this:

- The first pipeline gave the request text only to its second stage. Each later stage read only
  the artifact of the stage before it. Its proofs held, but they did not show that the code was
  correct.
- On one project, a redesign was proved only in a pure-function model. It lost the timing outcome
  that an earlier state-machine model guarded. The new model was a "transliterated" design. It
  added and changed rules that nobody requested. Its theorem was always true, so it showed
  nothing.

So every move reads the ticket text again. When two tools state one claim, each statement comes
from the report and the current system, not from the other statement. Where two statements
disagree, that is a divergence.

> "We do not write to achieve understanding; we orbit to achieve understanding."

Source: prompt "The orbit", "Moves" (introduction), "SPECTRUM" (step 5), "Handoff to the build
orbit"; design notes `orbital-shifting-history.md` (era 1) and `aidlc-v2-deep-explanation-ste.md`
(section 1.2); memories `logout-case-study-evals` and `hypothesis-definition-handoff` (the notes
on claim c4 in its KB). Settled.

### 4. The hypothesis is the backbone

The hypothesis is the closest wording of the intent that Sagittarius has. The claims, the checks,
and the vote depend on it. It follows the Mathlib value: weak hypotheses, strong conclusions.

- **Assume little.** Put no cause, no mechanism, and no fix in it. Each one adds meaning that the
  human did not give, and it chooses a design too early.
- **Conclude strongly.** Say which outcome you expect, and which facts decide it.
- **Keep it falsifiable.** A hypothesis that no result can show false collapses. It says
  nothing.

Remove words until the next removal makes it collapse or change its meaning. A weak hypothesis
often takes more work to show true or to falsify, but not always.

**Settled:** the principle and the prompt section. **Open:** the formal definition. Ty's draft:

> "A properly written hypothesis is the weakest form of a statement that doesn't collapse (it is
> provable) and doesn't generalize so far as to lose its intent."

Ty wants a Lean statement of this. Then "weak", "collapse", "generalize", and "intent" become
exact. Three questions are open. Does "provable" mean "falsifiable"? Must the hypothesis be a
subset of the intent, or the reverse? Must the hypothesis use only facts that you can
observe? Until then, the prompt section is the working definition.

Source: prompt "The hypothesis"; memories `hypothesis-weak-strong` and
`hypothesis-definition-handoff`.

### 5. A divergence is good news. A quiet failure is the enemy

Each role sees the intent from a different position, as two eyes see one object. Where the views
do not agree, there is a divergence: a check that fails, a counterexample, or a human who says "that
is not what I meant". A divergence is loud, so it can be fixed. It shows that clarity
increases. Record every divergence.

The worst failure is quiet. Examples are a check that passes while the result is wrong, a claim
that nobody tested, an empty field, and a theorem that cannot fail. A check is only valuable if it
can fail. So a new check must fail before the change, and an empty report field says "none".

> "Silence, negative space, emptiness, and vacuity are often the predators of clarity, accuracy,
> and honesty."

Source: prompt "The orbit" (Parallax, quiet failures), "The light path" (step 3); deck slide 7.
Settled.

### 6. Start light. Shift up on a signal. Lean back when it is resolved

Most work needs only a light path: one restatement, one check, one delivery. Rigor comes only when
a signal of miscommunication appears. These are the signals: questions that one round does not
settle, a divergence, a build by someone else, a claim that burns, or a handoff. The size of the
change does not decide. A one-line fix with a signal gets a small KB. When the cause of a signal is
resolved, the work that it added stops.

Tiers failed. Nobody can grade a ticket once, at the start, because nobody knows how much must be
formal until a miscommunication occurs. The middle tiers also emptied into the lowest and the
highest. Heavy process for simple work is too much.

Source: prompt "Shift up to a KB", "Leaning back"; memories `orbit-light-start` and
`orbit-why-signals-not-tiers`; design notes `orbital-shifting-why.md` and
`orbital-shifting-history.md` (era 2). Settled.

### 7. Speed comes from skipping work, never from hiding it

Do only the work that the request needs. Do not polish beyond the claims. But every skip is
visible. Only the human can skip required work, and a skip is a waiver with a due time. When the
due time ends, the work comes back.

Source: prompt "Purpose", "Delivery" (waivers), "FULFILL". Settled.

### 8. Words match evidence

Say what you guessed, what you did not make sure of, and what went wrong. Disclosure is never a
failure. Hiding is a failure. Claim no more than the evidence shows:

- "Tests pass" does not mean "correct".
- "Stated in Lean" does not mean "proved".
- "Proved in Lean" is about the Lean model, not about the shipped code.
- A bounded solver or model-checker result is not "always" or "never".

If your own earlier work is wrong, say so first.

Source: prompt "Honesty rules", "Honesty rules for discovery"; deck slide 26. Settled.

### 9. Formal artifacts are impartial, not guards against cheating

The formal artifacts catch honest mistakes. They do not stop an agent that cheats on purpose.
Sagittarius expects trust between the human, the agents, and the code. If the process constrains
one of these too much, it fails. So:

- Fix a hole that an honest agent can hit by mistake.
- Record as a known limit a hole that only deliberate cheating can use. Do not harden against
  it.
- Do not let the documents claim more than the checks give.

Impartial does not mean always right. When the two logic engines disagree, the agent stops and
reports both answers.

Source: prompt "Honesty rules" (rule 5), "Rules for the KB"; memory `orbit-trust-threat-model`.
Settled.

### 10. Use the tool that fits the shape of the claim

Each claim shape has a cheapest tool that can falsify it:

- A reproduction or a test, for current behavior.
- SMT, for rules and limits.
- TLA+, for the order of steps and timing.
- Lean, for a claim about every input.

Use a model only when a few examples cannot cover the cases.

Lean and Prolog are two lenses on the intent. Lean demands specificity: a statement says exactly
what it means, or Lean does not accept it. Prolog gives a self-contained store of facts that you
can query. Its constraints keep the human and the agent on what matters.

Judge a claim by its meaning and its domain, not by its words. "Every" in a sentence does not make
a claim universal. A claim is universal when its inputs are infinite or too many to test case by
case.

Source: prompt "SPECTRUM", "Shift up to a KB" (a claim that burns); design note
`orbital-shifting-why.md`; memories `orbit-universal-semantics` and `logout-case-study-evals`.
Settled, but see tension A.

### 11. Continuity lives in the KB

The KB is the memory between laps and sessions. An agent that resumes work reads the KB,
not its own recollection. A changed claim supersedes the old claim. It does not overwrite it. A
claim that supersedes a claim that burns needs its own proof. When the Lean files of a proof
change, the proof no longer counts. Thus a change of design cannot quietly carry an old guarantee.

Source: prompt "Rules for the KB", "BURN"; memory `logout-case-study-evals` (the third failure).
**Settled** within one ticket. **Open** across tickets: see tension B.

### 12. One principle, shown by examples

State one principle, and let examples show its meaning. Do not write a checklist of trigger words.
A list of five narrow rules for one piece of feedback overfits. Give each word one meaning: "when
definitions collide, ambiguity only serves confusion."

Source: prompt "When the human says that it is wrong" (examples), "The hypothesis" (example);
memories `hypothesis-weak-strong` and `orbit-universal-semantics`; design note
`orbital-shifting-system-prompt-draft.md` (one meaning of "check"). Settled.

### 13. A prompt change is a general rule, never an answer key

A change to the prompt must be worth having even if no eval exists. It comes from a real failure,
not from the shape of one test case. The prompt never holds the id of an eval or a phrase from an
eval. Tune on one set of cases, and gate on a held-out set. A rule must have a case that fails
when the rule is deleted. If a small model passes a case only when the prompt describes that exact
case, stop: the limit of the model is a result, not a target.

Source: `evals/REFINING.md`; memory `eval-refining-pattern`. Settled.

## Tensions for Ty

These are places where two principles, or a principle and the current prompt, pull in different
directions. They are open.

**A. The right tool against "only Lean closes a burn".** Principle 10 sends timing and order of
steps to TLA+. But a universal claim burns, and only a Lean proof or a human waiver closes a burn.
A TLC run does not. The build orbit does not mention TLA+. So a universal claim about timing can
push the agent to restate a state machine as pure functions in Lean. That is the second failure
in principle 3.
Source: prompt "SPECTRUM", "Handoff to the build orbit"; design note
`orbital-shifting-system-prompt-draft.md` (open item 3).

**B. Continuity against "do not commit the KB".** The KB is not committed unless the human asks,
and the delivery carries the evidence. A later ticket, such as a redesign, then cannot see the
claims and models that the earlier ticket guarded. The third failure in principle 3 was this kind
of loss.
Source: prompt "Rules for the KB"; memory `logout-case-study-evals`.

**C. The proof covers the model, not the code.** A conformance check between the Lean model and
the code is optional. Only the Lean examples come back to the code as tests. A model can thus
drift from the code with no loud signal: a possible quiet failure (principle 5).
Source: prompt "BURN" (step 6).

**D. Signals, not sizes, against "Sizes and speed".** The discovery orbit lists tiny, small,
medium, and large. These describe outcomes, but they read like tiers. Discovery also needs a
model when "a few examples cannot cover the cases". That is a signal of shape, not of size.
Source: prompt "Sizes and speed", "The tiny discovery orbit".

**E. "Provable" in the draft definition.** In a literal reading, a statement that is always true is
provable. But such a statement collapses. Possibly, Ty's draft means "falsifiable" (principle 4,
first open question).
Source: memory `hypothesis-definition-handoff`.

**F. The principle and the practice.** Agents rarely shift up on their own. Small models name a
signal and still deliver with no KB. Principle 6 holds, but the prompt does not yet produce it
reliably on all models.
Source: `evals/REFINING.md` (rule 7 table); memory `shift-up-audit-next-steps`.

## How to judge a change

Ask these questions about a proposed change:

1. Which principle does it serve? Does it break one?
2. Does it make one role grade its own work?
3. Does it build an artifact from another artifact, and not from the intent?
4. Can a failure that it adds be quiet?
5. Does it add rigor before a signal, or keep rigor after its cause is resolved?
6. Does it let the agent skip work without a visible waiver?
7. Does it add a word list or a phrase from an eval where one principle and an example are enough?

# The philosophy of Sagittarius

This document states the beliefs under Sagittarius: what is true about humans, agents, intent,
evidence, and formal methods that makes the design right. It does not say how to do the work. The
procedure is in [`prompt/SAGITTARIUS.md`](../prompt/SAGITTARIUS.md) and in `orbit-kb help`.

The prompt is one way to apply these beliefs. Each principle must stay true even if every section
of the prompt changes. Use this document to judge a proposed change to the prompt or to `orbit-kb`.
A good change serves a principle and breaks none. A change that must break one is a decision for
the owner of the project, not an edit.

The principles are settled. The questions that are still open are at the end. Each principle names
where the prompt or the repository applies it today.

## The bet

Humans and agents will always misalign. Models get better at guessing what a person wants, but
they do not have the knowledge that is in that person's head. The person must still explain the
intent, and errors come from that explanation. Difficulty is a weak guide: what is difficult for a
model today is easy for a model next year. Misalignment does not go away. So Sagittarius aims at
alignment on intent, not at the difficulty of the task.

> "I'm making the bet that even with ASI, humans will still need to explain what they want, and
> that will continue to be a point of friction." (the author)

## The principles

### 1. The human owns the intent. Clarity is work that the human and the agent share

The human is the source of the intent and the owner of the result. The human is not always the
source of clarity. People often do not know exactly what they want until they see it. The agent
owns the build, and its first job is to make the request clear enough before it builds. When the
human and the agent disagree on a decision, the human decides.

Applied in: prompt "Roles", "GO / NO-GO: a weighted vote".

### 2. Alignment is the goal. A proof is one tool for it

The goal is agreement between the human, the agent, and the formal artifacts on what to build and
on when it is done. Agreement is always possible before a change lands. A full proof is not always
possible, and it is not always necessary. Four qualities measure each change and each rule: fast,
clear, accurate, and honest. A rule that improves none of them does not belong.

Applied in: prompt "Purpose".

### 3. No party grades its own work

Three parties see the intent from different positions: the human (through words), the agent
(through claims and examples), and the formal artifacts (tests, models, proofs, and a knowledge
base). Like two eyes, different views find depth that one view cannot. The formal artifacts are
impartial: they can disagree with the agent and with the human. Thus each result must go through a
party that did not make it.

Show the human concrete examples and results, not formal text or test logs. The human judges
meaning. The machines judge consistency.

Applied in: prompt "The orbit" (Parallax), "Roles", "Delivery".

### 4. Orbit the intent. Do not translate it

Each statement of the intent must come from the intent itself: the request and the current system.
When each step reads only the output of the step before it, each small error passes on and grows.
At the end, the result can be consistent with itself and far from what the human meant. That is
translation. An orbit returns to the source on each lap.

Two failures teach this:

- An earlier version of this method was a pipeline. Only its second stage read the request. Each
  later stage read only the artifact of the stage before it. Its proofs held, but they did not show
  that the code did what the human wanted.
- On one project, a redesign was proved only in a pure-function model. It lost a timing outcome
  that an earlier state-machine model guarded. The new model was a "transliteration": it added and
  changed rules that nobody requested, and its main theorem was always true, so it showed nothing.

When two tools state the same claim, write each statement from the source, not from the other
statement. Then a difference between them is information.

> "We do not write to achieve understanding; we orbit to achieve understanding."

Applied in: prompt "The orbit", "Moves" (each move reads the ticket), "SPECTRUM".

### 5. The hypothesis is the closest formal statement of intent

A report of a problem becomes a hypothesis before anything is built. The claims, the checks, and
the decision to build all depend on it. It follows a value of the Mathlib community: weak
hypotheses, strong conclusions.

- **Assume little.** A cause, a mechanism, or a fix in the hypothesis adds meaning that the human
  did not give. It also chooses a design too early.
- **Conclude strongly.** Say which outcome is expected, and which facts decide it.
- **Stay falsifiable.** A statement that no result can show false says nothing. It has collapsed.

Remove words until one more removal makes the hypothesis collapse or change its meaning. A weak
hypothesis often takes more work to confirm or refute, but not always.

Applied in: prompt "The hypothesis". The exact definition is open (see the end).

### 6. A divergence is good news. A quiet failure is the enemy

Where the views of the parties do not agree, there is a divergence: a check that fails, a
counterexample, or a human who says "that is not what I meant". A divergence is loud, so someone
can fix it. It shows that clarity increases. Record it.

The worst failures are quiet: a check that passes while the result is wrong, a claim that nobody
tested, an empty answer, a theorem that cannot fail. Evidence that cannot fail is not evidence.

> "Silence, negative space, emptiness, and vacuity are often the predators of clarity, accuracy,
> and honesty."

Applied in: prompt "The orbit" (quiet failures), "The light path" (a new check fails first).

### 7. Rigor follows signals of misunderstanding, not size or difficulty

Most work needs little process. Rigor starts light and increases only when a signal of
misunderstanding appears: questions that one round does not settle, a disagreement, work that
another party did, a claim that examples cannot cover, or work that changes hands. The size of a
change does not decide. A one-line fix can need rigor, and a large change can need none. When the
cause of a signal is resolved, the rigor that it added stops.

Fixed tiers, chosen at the start, failed. Nobody knows how much must be formal until a
misunderstanding occurs. In practice, the middle tiers emptied into the lowest and the highest.

Applied in: prompt "The light path", "Shift up to a KB", "Leaning back"; deck slides 12 and 30.

### 8. Speed comes from skipping work, never from hiding it

Do only the work that the request needs, and stop when it is done. Every skip of needed work is
visible. Only the human can skip it, and the skip has a due time. After that time, the work comes
back.

Applied in: prompt "Purpose", "Delivery" (waivers).

### 9. Words match evidence

Say what was guessed, what was not verified, and what went wrong. Disclosure is never a failure.
Hiding is a failure. Claim no more than the evidence shows:

- Tests that pass do not show that the result is correct.
- A statement in a proof language is not a proof.
- A proof is about its model, not about the shipped code.
- A result inside bounds is not "always" or "never".

If your own earlier work is wrong, say so first.

Applied in: prompt "Honesty rules", "Honesty rules for discovery".

### 10. Formal artifacts catch honest mistakes. They do not stop cheating

Sagittarius assumes trust between the human, the agents, and the code. If the process constrains
one of them too much, the work fails. So the tools guard against honest mistakes. A hole that only
deliberate cheating can use is a known limit, and the documents say so. They do not claim more
than the checks give. Impartial also does not mean infallible: when two engines give different
answers, nobody uses either answer until a human looks.

Applied in: prompt "Honesty rules" (rule 5), "Rules for the KB".

### 11. Each claim has a shape. Use the tool that fits it

A claim about current behavior needs a test. A claim about rules and limits fits a solver. A claim
about the order of steps or about time fits a model checker. A claim about every possible input
needs a proof. Use the cheapest tool that can show the claim false. Use a model only when a few
examples cannot cover the cases. A tool that does not fit the shape can prove something true and
still lose the intent.

Decide the shape of a claim by its meaning and its domain, not by its words. "Every" in a sentence
does not make a claim universal. A claim is universal when its inputs are infinite or too many to
check one by one.

Two kinds of formal tool help the human and the agent see the intent. A proof language (Lean)
demands precision: a statement says exactly what it means, or it does not check. A queryable logic
store (Prolog, as s(CASP)) keeps the facts of the work in one place. Its rules keep attention on
what is still open.

Applied in: prompt "SPECTRUM", "Shift up to a KB" (a claim that burns); deck slide 14.

### 12. Memory lives outside the agent

Agents forget. Sessions end, contexts are compacted, and work moves between agents. So the shared
state of the work lives in a record that a person or an agent can query. It does not live in the
recollection of one agent. A change of plan does not erase an earlier outcome that the human still
wants: that outcome stays a claim, and the agent checks it again against the new design. A new
claim supersedes an old one. It does not overwrite it. An old guarantee does not carry over to a
new design without new evidence.

Applied in: prompt "Rules for the KB", "Shift up to a KB" (a divergence, a handoff), "BURN".

### 13. One principle, shown by examples

State one principle, and let examples show its meaning. A checklist of trigger words overfits: it
catches the words and misses the meaning. Examples show meaning, not strings to match. Give each
term one meaning. When two meanings share a word, the result is confusion.

Applied in: prompt "When the human says that it is wrong", "The hypothesis" (an example of the
meaning, not a template).

### 14. Improve the process as you improve a hypothesis

A change to the prompt must be worth having even if no test of the prompt existed. It comes from a
real failure, not from the shape of one test case. Never put the answer to a test into the prompt.
Tune on one set of cases, and decide on a separate set that nobody tuned on. A rule needs a case
that fails when the rule is deleted. Decide on repeated runs, not on one run. When a case passes
only if the prompt describes that exact case, the limit of the model is a result, not a target.

Applied in: `evals/REFINING.md`.

## Open questions

These questions are open. They are not decisions.

**A. What is a properly written hypothesis, exactly?** The working draft: "a properly written
hypothesis is the weakest form of a statement that doesn't collapse (it is provable) and doesn't
generalize so far as to lose its intent." The aim is a formal statement, for example in Lean, so
that "weak", "collapse", "generalize", and "intent" become exact. Three points are not decided:

- Does "provable" mean "falsifiable"? Read literally, a statement that is always true is provable,
  but it has collapsed.
- Must the hypothesis cover only the cases of the intent, or must the intent fit inside it?
- Must a hypothesis use only facts that can be observed in the system? One failure suggests yes:
  a theorem that rested on a fact the system did not have could not fail.

**B. How does the build return to discovery?** A claim about every input still needs a proof (or
a human waiver) before it is done. That rule stays. The open question is the seam between
discovery and build. A divergence during the build can show that the problem itself is not yet
clear. One possible route: the divergence sends the work back into discovery. Discovery refines
the hypothesis, with a model checker for claims about time and order where they fit. The proof
then states the refined hypothesis, not a restatement of the build.

**C. How does continuity reach across tickets?** The record of one ticket is not committed by
default, and the delivery carries the evidence. A later ticket, such as a redesign, then cannot see
the outcomes that the earlier ticket guarded.

**D. How does a proof stay tied to the code?** A proof is about its model. Examples from the model
become tests of the code, but a full conformance check is optional. A model can drift from the
code with no loud signal.

**E. Do the discovery sizes read as tiers?** The discovery orbit lists tiny, small, medium, and
large. These describe outcomes, but they can read as tiers. Principle 7 says that signals decide,
not size. The list needs a second look.

**F. Shift up to one formal language at a time?** The candidate belief: the work is active in only
one formal language at a time. The KB is the exception, because it tracks the ticket itself. When
that language leans back, the next shift up can go to a different language. Each shift up uses the
cheapest language that can soundly resolve the divergence. A burn always goes to Lean, with or
without a divergence. The aim is to stop a recursive shift up: a trigger that fires while a model
is built must not start a second language. No failure of that kind has been seen yet, so the belief
stays out of the prompt until an eval shows one. Four points are not decided:

- SPECTRUM states a claim that mixes rules and steps in TLA+ and in SMT at once. Under this belief
  the two run one after the other.
- Is a finished model that is read as evidence (an SMT witness run as a Lean `#eval`) a language
  in use? If it is, the belief cuts off the parallax between two statements of one claim. One
  possible line: one language that is being written, and any number of finished models that are
  read.
- When does a language lean back? "The cause of the trigger is resolved" lets an agent stay in a
  model too long, or leave it early to reach the next language. It needs an exit test, such as
  "the model is trusted and its verdicts are recorded, or it is dropped with a disclosure".
- That exit test rests on sanity and calibration. The prompt states them per tool (FLYBY steps 1
  and 2, TRAJECTORY steps 2 and 3), but the agent attests them, and `orbit-kb` counts one result
  of each. In the cache-race discovery of 2026-10-30, a TLA+ model was attested calibrated on the
  outcome (the same abort) before any system log showed the same sequence of steps, which
  TRAJECTORY step 3 asks for. The KB counted the model trusted. So "trusted" is the agent's own
  grade (principle 3).

## How to judge a change

Ask these questions about a proposed change to the prompt or the tool:

1. Which principle does it serve? Does it break one?
2. Does it let one party grade its own work?
3. Does it build one artifact from another artifact, and not from the intent?
4. Can a failure that it adds be quiet?
5. Does it add rigor before a signal, or keep rigor after its cause is resolved?
6. Does it let work be skipped with no visible record?
7. Does it add a word list, or the answer to a test, where one principle and an example are enough?

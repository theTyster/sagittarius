# The philosophy of Sagittarius

> **Draft of 2026-11-11, by the review session, for the author to rewrite.** It is on a branch and
> changes nothing that is installed. Quotes marked "(the author, 2026-11-11)" are word for word.
> A paragraph that starts with **Proposed.** is not the author's: it is a proposal from the
> discussion of that day, and nobody ratified it.

This document states the beliefs under Sagittarius: what is true about humans, agents, intent,
evidence, and formal methods that makes the design right. It does not say how to do the work. The
procedure is in `orbit-kb help` and its topics.

This document is the frontier of the project. The author is still discovering what they intend for
Sagittarius, as every human does with every project. So the document moves: a belief that use
shows to be wrong is replaced, and the open questions at the end are part of it.

> "the PHILOSOPHY _is_ the bleeding edge frontier guiding this project and like everything else
> about sagittarius and mindhole we treat as something that is dynamic because _my_ intent is
> [...] still something that I'm discovering myself" (the author, 2026-11-11)

The document is not installed anywhere. It is reflected into the prompt,
[`prompt/SAGITTARIUS.md`](../prompt/SAGITTARIUS.md), which says the same beliefs in words that
change how a model acts. It guides both interfaces of the project (below) over time.

Use this document to judge a proposed change to the prompt, to `orbit-kb`, or to the hub kit. A
good change serves a principle and breaks none. A change that must break one is a decision for the
owner of the project, not an edit. Each principle names where the prompt or the repository applies
it today.

## The bet

Humans and agents will always misalign. Models get better at guessing what a person wants, but
they do not have the knowledge that is in that person's head. The person must still explain the
intent, and errors come from that explanation. Difficulty is a weak guide: what is difficult for a
model today is easy for a model next year. Misalignment does not go away. So Sagittarius aims at
alignment on intent, not at the difficulty of the task.

The audience is people who work with formal methods and AI. Users are expected to read Prolog,
Lean, and the other formal languages. A general template is a byproduct: an informal release.
<!-- d_audience_fm, decided 2026-11-05 -->

The position: Sagittarius is an extension of the harness, between the human-agent interface and
the software factory. The harness is the interface between the human and the agent; the software
factory is the interface between the agent and the project. Sagittarius fills the gap between them
as an inference, reasoning and knowledge-graph layer. It is opinionated: it puts everything into
one shape.
<!-- u08, u37 -->

> "I'm making the bet that even with ASI, humans will still need to explain what they want, and
> that will continue to be a point of friction." (the author)

## The intent

The intent is what the work is for. The human decides that it exists, with no help from a tool.
That is the sense in which the human owns it.

But nobody holds all of it, and the human is no exception. People often do not know exactly what
they are chasing until they see a result. The intent also moves: it shifts, or the human
understands it better. It can seem to act by itself. It is not a party, and it cannot speak. Only
the human, the agent, and the formal artifacts speak, and none of them is tied to another.

So every statement of the intent is an attempt: a request, a claim, an example, a hypothesis, a
test, a proof. An attempt can be wrong, and the work is to find where. The loops of trial and
error that find it are the orbits. Everything in Sagittarius exists to help the human discover the
intent. Ideally the discovery is monotonic: what was learned stays learned.

> "_The intent_ could be classified as its own role, but it is not something that is literally
> sentient. It's just something that seems to _act_ sentient because it is constantly shifting.
> But, truly the human sometimes does not actually know what they're chasing. [...] These tools
> and all of sagittarius and the mindhole are meant to help the human monotonically (ideally)
> discover that intent over time." (the author, 2026-11-11)

## Two interfaces

> "Sagittarius is meant to run in two interfaces.
>
> 1. **Sagittarius**: A system prompt and orbit-kb. Sagittarius should carry the philosophies of
>    this repo everywhere that it goes. [...]
> 2. **MindHole**: The hub. Sagittarius provides a hub as a kind of pinned workspace. Each
>    mindhole can run its own version with its own `orbit-kb` and bespoke modifications for each
>    given workspace. This interface is for power-work where throughput, explainability and
>    automation are central aspects.
>
> The mindhole and Sagittarius work best together but are not dependent on one another."
> (the author, 2026-11-11)

The System 1 hook belongs with Sagittarius, not with the MindHole: it goes where the prompt goes.

## The principles

### 1. The human owns the intent. Clarity is work that the human and the agent share

The human is the source of the intent and the owner of the result. The human is not always the
source of clarity. People often do not know exactly what they want until they see it. The agent
owns the build, and its first job is to make the request clear enough before it builds. When the
human and the agent disagree on a decision, the human decides. The owner is not the only person
who can answer a question or ratify a decision. Answers and decisions can come from
people other than the owner.
<!-- d_other_humans, decided 2026-11-05 -->

Applied in: prompt "Roles", "The phase tree" (the vote); `orbit-kb help discovery` (GATE).

### 2. Alignment is the goal. A proof is one tool for it

The goal is agreement between the human, the agent, and the formal artifacts on what to build and
on when it is done. Agreement is always possible before a change lands. A full proof is not always
possible, and it is not always necessary. Four qualities measure each change and each rule: fast,
clear, accurate, and honest. A rule that improves none of them does not belong.

The agreement is about the current statement of the intent. It can be right today and be
superseded tomorrow, and nobody was wrong.

Applied in: prompt "Purpose".

### 3. No party grades its own work

Three parties see the intent from different positions: the human (through words), the agent
(through claims and examples), and the formal artifacts (tests, models, proofs, and a knowledge
base). Like two eyes, different views find depth that one view cannot. The formal artifacts are
impartial: they can disagree with the agent and with the human. Thus each result must go through a
party that did not make it.

**Proposed.** Impartial has a limit. The formal artifacts are impartial about what follows from a
statement. They are not impartial about which statement was written, because an agent chose the
definitions. A case from 2026-11-11: an agent recorded that two sentences of the author exclude
each other, and the knowledge base then reported a contradiction. The inference was sound. The
reading was the agent's. So the human reads the statement that the machine checked.

Show the human concrete examples and results first, not test logs. When the work has shifted up,
the human, the agent and the CPU all use the formal language as the shared substrate, and the human
reads, reviews and understands it, so write it to be read. The human judges meaning.
The machines judge consistency.
<!-- d_formal_substrate, decided 2026-11-05 -->

The human can read the formal language only if someone shows it. The plain claim and its formal
statement go to the human together.

> "I haven't seen _any_ lean proofs or prolog statements since starting to use Sagittarius. This
> project expects users to be able to atleast _read_ lean and prolog. but I have not received
> that." (the author, 2026-11-11)

The rule holds for noticing too. An agent does not grade whether it has diverged.

> "We can't make an algorithm that mechanically detects these things and we can't let a model
> grade themselves on whether they are diverting. something outside needs to help. The system 1
> model's main purpose is to help with detection and classification." (the author, 2026-11-11)

Applied in: prompt "Roles", "The phase tree" (Parallax), "When to shift up" (System 1), "Delivery".

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

Applied in: prompt "The phase tree" (Parallax: each lap goes back to the source); `orbit-kb help
discovery` (SPECTRUM).

### 5. The hypothesis is the closest formal statement of intent

A report of a problem becomes a hypothesis before anything is built. The claims, the checks, and
the decision to build all depend on it. It is an attempt at the intent, and the law of its ticket.

> "We call it a hypothesis because it's an attempt at defining the actual intent that the user is
> chasing. It's falsifiable because [...] it is just an attempt and `intent` is something dynamic,
> fluid, and hard to identify/define." (the author, 2026-11-11)

It follows a value of the Mathlib community: weak hypotheses, strong conclusions.

- **Assume little.** A cause, a mechanism, or a fix in the hypothesis adds meaning that the human
  did not give. It also chooses a design too early.
- **Conclude strongly.** Say which outcome is expected, and which facts decide it.
- **Stay falsifiable.** A statement that no result can show false says nothing. It has collapsed.

Remove words until one more removal makes the hypothesis collapse or change its meaning. A weak
hypothesis often takes more work to confirm or refute, but not always.

**Proposed.** A hypothesis has two falsifiers, and each has its own witness. A result that the
system can show refutes it about the system: the system is the witness. A concrete case that the
human judges against it refutes it about the intent: the human is the witness. The question for
the human is the author's: "is this case your intent?" A case that the system shows does not say
which of the two is wrong, the build or the hypothesis. The human's judgment of that case does.

**Proposed.** "Assume little" and "conclude strongly" push the same way: each makes the hypothesis
reject more cases. There is a limit on each side. A hypothesis that rejects no case has collapsed.
A hypothesis that rejects a case that the human wants has lost the intent. The two Lean files of
the discussion of 2026-11-11 state this (`HypothesisSketch.lean`, `HypothesisGrain.lean`).

Every stated hypothesis lists its premises beside it. This is a trial: UAT judges whether it adds
too much noise. <!-- d_premises_beside, decided 2026-11-05 -->
Hypotheses, premises, and claims err soft. Experiment just past the boundary of too brittle or
too soft, then formalize. The formalism then localizes the definition. Annealing in the formal
languages brings out the tempered position. Oscillation is an intentional heuristic.
<!-- d_err_soft, d_oscillate, decided 2026-11-05 -->

Discovery exists to form the hypothesis. So the build goes back to discovery only when the
hypothesis itself must change. A claim that changes inside the hypothesis stays in the build.
(Tentative: the author said "I might say".)

> "The whole point of discovery is to form the hypothesis which acts as the law of the intent
> behind the 'ticket'." (the author, 2026-11-11)

Applied in: prompt "The phase tree" (the hypothesis). The exact definition is open (see the end).

### 6. A divergence is good news. A quiet failure is the enemy

Where the views of the parties do not agree, there is a divergence: a check that fails, a
counterexample, or a human who says "that is not what I meant". A divergence is loud, so someone
can fix it. It shows that clarity increases. Record it.

New work is a divergence too. A request says that the intent differs from what the human said
before, or from what the system does now.

> "in my mind, new work _is_ a misalignment or a divergence because the intent of the human has
> either shifted or become better understood by the human themselves." (the author, 2026-11-11)

The ways in which a human can find or describe a divergence have no end. So the agents try to
detect them, and the formal tools help to specify them.

The worst failures are quiet: a check that passes while the result is wrong, a claim that nobody
tested, an empty answer, a theorem that cannot fail. Evidence that cannot fail is not evidence.

**Proposed.** A signal that an agent notices and does not say is a quiet failure too.

> "Silence, negative space, emptiness, and vacuity are often the predators of clarity, accuracy,
> and honesty."

Applied in: prompt "The phase tree" (Parallax, quiet failures), "Start light" (a new check fails
first).

### 7. Rigor follows signals of misunderstanding, not size or difficulty

Most work needs little process. Rigor starts light and increases only when a signal of
misunderstanding appears: questions that one round does not settle, a disagreement, work that
another party did, a claim that examples cannot cover, work that changes hands, or significant
effort or verbosity from the human. A one-line fix can need rigor, and a large change can need
none. When the cause of a signal is resolved, the rigor that it added stops.

> "size determines nothing. Clarity does." (the author, 2026-11-11)

Every signal gets the same response. The signals are many and need well-tempered definitions. The
response is one, and it is easy to trigger.

> "All six signals should elicit the same response. Shifting up simply means getting more specific
> and paying closer attention. [...] if we can re-inforce one shape of response for the correctly
> classified shapes of behavior, then even light-weight models can follow. The attention needed to
> respond in the right way should be low. We want agents to focus on the orbit, not the process."
> (the author, 2026-11-11)

The light path is the first rung: it is what happens on any change request. The KB is the second
rung, after a divergence. A discussion with no change request gets no KB.

**Proposed.** A request is the first divergence of its ticket, and the light path is its account.
A later result is a signal only when that account did not predict it. A check that fails before
the change is predicted: it shows the gap that the request names. A check that passes there is a
signal. The rungs are then levels of statement, not a count of events: words and a check, then the
KB, then one formal language that fits the claim. A request for a proof goes to its rung at once.

Effort is a signal to shift into a formal
language. A long, careful message holds decisions that must not be lost. The System 1 model, the LLM, and the human each have a part in deciding when to shift up.
After a shift, the human, the agent, and the CPU (the machine that runs the solvers and provers)
all work in the formal language. The human must read and review it, so shift up only when needed.
<!-- d_effort_signal, d_shift_three, d_formal_substrate, decided 2026-11-05 -->

Work has two levels. The orbit is discovery or build. The phase is research and specify (in
discovery), or build and verify (in build). Rigor concentrates on specification and verification.
The split between make and judge stays, because it marks a handoff.
<!-- d_phase_tree, p_lifecycle, decided 2026-11-05 -->

Fixed tiers, chosen at the start, failed. Nobody knows how much must be formal until a
misunderstanding occurs. In practice, the middle tiers emptied into the lowest and the highest.

Applied in: prompt "Start light", "When to shift up" (also One response, leaning back); the
System 1 hook (`s1/hook.py`).

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

Applied in: prompt "Honesty rules" (with the rules for discovery).

### 10. Each formal artifact catches its own kind of error. None stops cheating

Sagittarius assumes trust between the human, the agents, and the code. If the process constrains
one of them too much, the work fails. Each tool catches its own kind of
error. Lint catches syntax and schema errors. A check catches behavior on its cases. A proof
covers its model. The human judges meaning. The tools do not stop deliberate cheating. A hole that
only deliberate cheating can use is a known limit, and the documents say so. They do not claim
more than the checks give. Impartial also does not mean infallible: when two engines give different
answers, nobody uses either answer until a human looks.
<!-- prop_retire_honest_mistakes, d_retire_honest, decided 2026-11-05 -->

Applied in: prompt "Honesty rules" (rule 5), "Where the procedure is"; `orbit-kb help core`.

### 11. Each claim has a shape. Use the tool that fits it, one lens at a time

A claim about current behavior needs a test. A claim about rules and limits fits a solver. A claim
about the order of steps or about time fits a model checker. A claim about every possible input
needs a proof. Use the cheapest tool that can show the claim false. Use a model only when a few
examples cannot cover the cases. A tool that does not fit the shape can prove something true and
still lose the intent.

Every orbit encodes domain knowledge, not only a record of the process.
<!-- p_domain, decided 2026-11-05 -->

Decide the shape of a claim by its meaning and its domain, not by its words. "Every" in a sentence
does not make a claim universal. A claim is universal when its inputs are infinite or too many to
check one by one.

Two kinds of formal tool help the human and the agent see the intent. A proof language (Lean)
demands precision: a statement says exactly what it means, or it does not check. A queryable logic
store (Prolog, with SWI-Prolog as the engine) keeps the facts of the work in one place. Its rules keep attention on
what is still open.

The work uses one formal language at a time. The knowledge base is the exception, because it
tracks the ticket itself. The aim is to stop a recursive shift up: a trigger that fires while one
model is built must not start a second language. The author has seen that failure, in an earlier
version of the method (Orbital Shifting, as they recall).

> "We use one language because one language gives us one lens. we should use the right lens for
> the right problem depending on what we're trying to uncover." (the author, 2026-11-11)

Applied in: prompt "When to shift up" (a claim that burns, one lens); `orbit-kb help discovery`
(SPECTRUM).

### 12. Memory lives outside the agent

Agents forget. Sessions end, contexts are compacted, and work moves between agents. So the shared
state of the work lives in a record that a person or an agent can query. It does not live in the
recollection of one agent. A change of plan does not erase an earlier outcome that the human still
wants: that outcome stays a claim, and the agent checks it again against the new design. A new
claim supersedes an old one. It does not overwrite it. An old guarantee does not carry over to a
new design without new evidence. This is how the discovery of the intent stays monotonic: the
record keeps what was learned, and also what was replaced.

The main task is to give the LLM the right amount of context. Rules in the KB help select it.
The prompt holds the philosophy only. The System 1 hook runs the classification steps.
<!-- p_context, d_prompt_small, decided 2026-11-05 -->

**Proposed.** Replace "The prompt holds the philosophy only" with: the prompt holds what a session
needs before any signal, which is the light path and the signals. The tool holds everything after
a signal. This document holds the reasons. The case: a session that fixes a defect on the light
path never runs `orbit-kb`, so it never reads the help. What it needs must be in the prompt.

Applied in: prompt "Where the procedure is", "When to shift up" (a divergence, a handoff);
`orbit-kb help build` (burns).

### 13. One principle, shown by examples

State one principle, and let examples show its meaning. A checklist of trigger words overfits: it
catches the words and misses the meaning. Examples show meaning, not strings to match. Give each
term one meaning. When two meanings share a word, the result is confusion.

Applied in: prompt "When the human says that it is wrong"; `orbit-kb help discovery` (SIGNAL: an
example of a hypothesis, of the meaning, not a template).

### 14. Improve the process as you improve a hypothesis

A change to the prompt must be worth having even if no test of the prompt existed. It comes from a
real failure, not from the shape of one test case. Never put the answer to a test into the prompt.
Tune on one set of cases, and decide on a separate set that nobody tuned on. A rule needs a case
that fails when the rule is deleted. Decide on repeated runs, not on one run. When a case passes
only if the prompt describes that exact case, the limit of the model is a result, not a target.

Evals test whether agents can follow the rules of the prompt and the orbit-kb help. UAT tests
whether the philosophy and the hypotheses pay off. No stakeholder instance is privileged, and
results stay non-trivial.
<!-- d_eval_scope, p_general, decided 2026-11-05 -->

This document changes in the same way. A belief here is a hypothesis about the work, and use is
what tests it.

Applied in: `docs/REFINING.md`.

## Open questions

These questions are open. They are not decisions.

**A. What is a properly written hypothesis, exactly?** The working draft: "a properly written
hypothesis is the weakest form of a statement that doesn't collapse (it is provable) and doesn't
generalize so far as to lose its intent." The aim is a formal statement in Lean, at a grain that
helps to define claims, premises, and falsifiers. Two sketches exist (2026-11-11). Their state:

- "Provable" is the wrong word: a statement that is always true is provable, and it has collapsed.
  The candidate: some case exists that the hypothesis rejects.
- The first sketch treats the intent as a known set. Nobody has that set. The second sketch keeps
  only the judgments that the human has given so far, and more arrive on each lap.
- Not yet stated: how the claims of a ticket add up to its hypothesis; a falsifier that is a
  sequence of results; a judgment that the human reverses.
- Must a hypothesis use only facts that can be observed in the system? One failure suggests yes:
  a theorem that rested on a fact the system did not have could not fail.

**B. How does the build return to discovery?** The tentative answer is in principle 5: only when
the hypothesis must change. Two points are not decided:

- A change request that went straight to build has no hypothesis. What is the law of that ticket?
- In one session, the return is a change of orbit. In a MindHole, discovery is another agent, so
  the return is a handoff and costs more. Is the test the same in both?

**C. How does continuity reach across tickets?** A project KB can own an outcome as a rule, and a
later ticket can pin that rule. Two seams are open. Nobody is named to make an outcome a rule when
its ticket closes. And a new ticket finds the rules that it touches only when an agent reads them.

**D. How does a proof stay tied to the code?** A proof is about its definitions. It stops counting
when its Lean files change. Nothing reopens it when the code changes. A file pin can tie a decision
or a definition to a file, but not a rule, and a pin that is out of date is quiet in the KBs that
depend on it (checked 2026-11-11, one test each).

**E. Do the discovery sizes read as tiers?** Closed 2026-11-11: "size determines nothing. Clarity
does." It is in principle 7.

**F. One formal language at a time.** The belief is in principle 11. Three points are not decided:

- SPECTRUM states a claim that mixes rules and steps in TLA+ and in SMT at once. Under the belief
  the two run one after the other.
- Is a finished model that is read as evidence (an SMT witness run as a Lean `#eval`) a language
  in use? One possible line: one language that is being written, and any number of finished models
  that are read.
- When does a language lean back? It needs an exit test, such as "the model is trusted and its
  verdicts are recorded, or it is dropped with a disclosure". That exit test rests on sanity and
  calibration. `orbit-kb help discovery` states them per tool (FLYBY steps 1 and 2, TRAJECTORY
  steps 2 and 3), but the agent attests them for itself (principle 3). In the cache-race discovery
  of 2026-10-30, a TLA+ model was attested calibrated on the outcome before any system log showed
  the same sequence of steps, and the system later showed the abort by a different sequence. Three
  candidate criteria come from that case:

  - **Two sides.** Calibrate on a real case where the system fails, and on a real case where
    it passes. A model where every run fails also matches the failing case.
  - **Two levels.** Outcome calibration (the same result) is enough for verdicts about
    outcomes. A finding that names a cause or a mechanism needs mechanism calibration, or it
    stays a lead.
  - **From the system to the model.** Mechanism calibration constrains the model to the
    sequence that the system showed, and checks that the model can reach it. The reverse
    (does the system show the model's trace?) is weak, because a checker picks its own path.

  Sanity has a candidate answer too: the model can reach each state that a claim talks about.

**G. What stands outside the agent when System 1 is not there?** System 1 exists so that an agent
does not grade its own divergence (principle 3). The author said both "need the hook" and
"optional for now. Maybe 'recommended'". Three points are not decided:

- Today the hook prints nothing when it has no confident answer, and nothing when it fails. The
  agent cannot tell the two apart. One proposal: the hook prints a line for every message.
- The hook runs only when the human sends a message. A signal inside the agent's turn (a check
  that surprises, a build by a subagent, a handoff that arrives) has no outside witness.
- May a hint bind the agent, or does the agent only weigh it? The draft prompt of 2026-11-11 says
  that a hint fires the signal, and the agent may object aloud.

**H. Where does the second rung start, if new work is itself a divergence?** The proposal in
principle 7 (a result is a signal only when the account did not predict it) is one answer. Its
weak point: a prediction counts only if it was stated before the result.

**I. What does the human see of the formal text?** Principle 3 says that the statement is shown.
Not decided: how much of it, in which place of a delivery, and for a small KB as for a large one.

**J. How is a version of Sagittarius named?** The author wants semantic versions, so that earlier
versions can be named. The hub kit has its own version already.

## How to judge a change

Ask these questions about a proposed change to the prompt or the tool:

1. Which principle does it serve? Does it break one?
2. Does it let one party grade its own work?
3. Does it build one artifact from another artifact, and not from the intent?
4. Can a failure that it adds be quiet?
5. Does it add rigor before a signal, or keep rigor after its cause is resolved?
6. Does it let work be skipped with no visible record?
7. Does it add a word list, or the answer to a test, where one principle and an example are enough?

**Proposed.**

8. Is it still true with no hub, with another version of `orbit-kb`, and when System 1 is silent?
9. Does the human see the statement that the machine checked?
10. Does it add a second shape of response, where one shape is enough?

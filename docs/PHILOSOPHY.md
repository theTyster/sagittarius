# The philosophy of Sagittarius

> **Draft of 2026-11-11, by Fable, for the author.** It is a full rework, not an edit. It is on
> a branch, and nothing that is installed reads it. The whole text is a proposal until the
> author ratifies it. **(P)** marks a position that is new, and that no human has ratified. A
> sentence with no mark comes from the earlier text, or from the author's words of 2026-11-11,
> but its wording and its place here are this draft's. Words in quote marks, with "(the
> author)", are word for word. The author ruled on three points on 2026-11-11 (in principles
> 2, 3 and 4). Astra reviewed the first version of this draft, and that review changed it:
> see the end of "A properly written hypothesis".

Sagittarius helps a human and an agent to find what the human wants, and then to build it.
This document holds the beliefs under it. It says why. The prompt says how to act, and
`orbit-kb help` holds the procedure.

Read this document as a hypothesis, because it is one. It is the author's current attempt to
say what the project is for. It has premises, and use can show it false. When use shows that a
belief is wrong, the belief changes, and the project follows. So this document is the frontier
of the project. It is installed nowhere. The prompt,
[`prompt/SAGITTARIUS.md`](../prompt/SAGITTARIUS.md), reflects it in words that change how a
model acts.

## The bet

Humans and agents will always misalign. Models get better at guessing what a person wants, but
they do not have what is in that person's head. The person must still explain, and errors come
in with the explanation. The person also does not know all of it. People often find what they
want only when they see a result.

Difficulty is a weak guide. What is difficult for a model today is easy for a model next year.
Misalignment stays. So Sagittarius aims at alignment on intent, not at the difficulty of the
task.

An earlier version of this method sorted work into tiers of difficulty, chosen at the start.
The tiers failed. Nobody knows how much rigor a piece of work needs until a misunderstanding
shows. In practice, the middle tiers emptied into the lowest and the highest.

> "I'm making the bet that even with ASI, humans will still need to explain what they want, and
> that will continue to be a point of friction." (the author)

## The center

**(P)** The image of this section is new. The three points under it are the author's.

Sagittarius A* is the black hole at the center of our galaxy. Nobody found it by looking at
it. Astronomers tracked the stars that orbit it, and the orbits showed where it is and how
heavy it is.

The intent of a piece of work is like that center.

- **The human owns it.** The human decides that it exists, and no tool helps with that. Only
  the human can say if a concrete case is what they want.
- **Nobody holds all of it,** and the human is no exception. People learn what they want when
  they see results.
- **It moves.** It shifts, or the human understands it better. It can look as if it acts by
  itself. It does not: it is not a party, and it cannot speak.

So every statement of the intent is an attempt: a request, a restatement, a claim, an example,
a test, a proof, the code. Each attempt can be wrong. The work is to find where.

We find where from differences. Each party sees the intent from its own position. The human
sees it through words and judgments. The agent sees it through the statements that it writes.
The machine sees what follows from those statements. The system shows what is true now. The
parties are not tied to each other. As with two eyes, two positions find a depth that one
position cannot. Where two views differ, there is a **divergence**. A divergence shows that
an attempt is wrong, while someone can still fix it. It does not say which attempt. Each one
that is settled leaves less room for the intent to be somewhere else.

Everything in Sagittarius exists to help the human find the intent. Ideally the finding is
monotonic: what one lap learned, the next lap keeps.

## The hypothesis of Sagittarius

**(P)** The frame of this section is new: one statement, with its premises beside it. The
content is the author's.

> **Nobody can see the intent. Independent views of it can be compared, and where they differ,
> at least one of them is wrong about it. So the way to what the human wants is an orbit, and
> not a translation: state the intent, compare the statement with a view that its author does
> not control, and correct what the difference shows to be wrong. Then go around again.**

Premises:

1. **The bet.** A human must explain what they want. No model removes that.
2. **Nobody holds the intent.** Each statement of it is an attempt.
3. **An author does not see their own misreading.** A view from outside can see it.
4. **A comparison must be able to fail.** A difference shows that an attempt is wrong. An
   agreement that could have been a difference is evidence. An agreement that could not have
   been one says nothing.
5. **A sharper statement costs more.** It costs more to write, and the human must read it.

What would show it false: work that is done this way needs as many corrections after the
delivery as work that is done without it. Or the orbit costs more than the corrections that it
prevents. The bet itself is false if agents appear that need no explanation. Use is the test
(principle 14). Nothing here shows that this is the fastest method for every task.

## The orbit

An orbit is a loop through parties that can disagree. **(P)** The three steps are this draft's
way to say it. Astra's review kept them and made the third step and the end more exact.

1. **State.** Say the intent, as specifically as the work needs now. Write the statement from
   the source: the human's words and the current system. Do not write it from the last
   artifact.
2. **Compare.** Put the statement beside a view that its author does not control: the human's
   judgment of a concrete case, a check that can fail, a query, a proof, a reviewer who did not
   build. Say what you expect before you look.
3. **Sharpen.** Where the two differ, at least one attempt is wrong: the statement, the build,
   or the check. Say the difference. Find which one is wrong, and correct that one. When
   nothing says which one, make the statement more specific there, and ask. Then go around
   again.

The orbit closes when a lap changes nothing. That counts only if each comparison in the lap
could have shown a difference: a lap in which nothing could differ is quiet, and it closes
nothing. It also counts only if nothing is left open. A claim with no check, a check that
fails, a proof that is owed, a question with no answer: each one keeps the orbit open, unless
the human waived it. Work that does not change can still be unfinished.

The opposite of an orbit is a translation. In a translation, each step reads only the output
of the step before it. Each small error passes on and grows, and no view is independent of the
view before it. At the end, the result can agree with itself and be far from what the human
meant. Two failures taught this:

- An earlier version of this method was a pipeline. Only its second stage read the request.
  Each later stage read only the artifact of the stage before it. Its proofs held, but they did
  not show that the code did what the human wanted.
- On one project, a redesign was proved only for pure functions. It lost an outcome about
  timing that an earlier state-machine model guarded. The new design was a "transliteration":
  it added and changed rules that nobody requested. Its main theorem was always true, so it
  showed nothing.

> "We do not write to achieve understanding; we orbit to achieve understanding." (the author)

Work has two levels. The orbit is discovery or build. Discovery makes a problem clear: its
laps end in a hypothesis and a vote. Build delivers a solution: its laps end in a change and a
delivery. Each orbit has a phase that makes and a phase that judges: research and specify in
discovery, build and verify in build. Rigor concentrates on specification and verification.
The split between make and judge stays, because it marks a handoff.

New work is a divergence too. A request says that the intent differs from what the system does
now, or from what the human said before. But new work does not look like a misunderstanding,
so an agent does not treat it as one. That is why there are two orbits: discovery gives unclear
new work a place to start.

## What follows

Each principle follows from a premise. Each names where the prompt applies it today.

### Because nobody holds the intent

#### 1. The human owns the intent. Clarity is work that the human and the agent share

The human is the source of the intent and the owner of the result. The human is not always the
source of clarity. The agent owns the build, and its first job is to make the request clear
enough to build. When the human and the agent disagree on a decision, the human decides. The
owner is not the only person who can answer a question or ratify a decision. Answers and
decisions can come from other people.

The goal is alignment: the human, the agent, and the formal artifacts agree on what to build
and on when it is done. Agreement is always possible before a change lands. A full proof is
not always possible, and it is not always necessary. **(P)** The agreement is about the
current statement of the intent. It can be right today and be superseded tomorrow, and nobody
was wrong.

Four qualities measure each change and each rule: fast, clear, accurate, and honest. A rule
that improves none of them does not belong.

In the prompt: "The orbit", "Who judges what", "The vote".

#### 2. Each statement of the intent is an attempt. The hypothesis is the first of them

A hypothesis is the closest statement of the intent that the work has. It is called a
hypothesis because it is an attempt at the intent that the human is chasing. Because it is an
attempt, a result can show it false. While it stands, it is the law of its ticket: the claims,
the checks, and the decision to build all rest on it.

Every ticket has one. Discovery exists to form it when the request is not clear. When the
request is clear, the agent states the hypothesis itself, and the work starts in build.

> In the case of "add a dark mode" the hypothesis might be: "The app must contain and use a
> compatible dark-colored scheme that supports dark mode without violating accessibility,
> readability, or useability across the entire application and its microservices." That way in
> case the human just meant "only on this page" or "only this service", then it becomes clear
> where the assumed failure was. Questions can help narrow that down, but now you've got clear
> defaults to work from. (the author, 2026-11-11)

So the hypothesis is wide on purpose. Each default of the agent is in the sentence, where the
human can see it and correct it. **(P)** To state a hypothesis is not to ask a question. The
agent states it and goes on. It stops to ask only when a wrong default is costly or hard to
undo.

**(P)** The hypothesis says what the human wants. A report of a defect says one thing more:
that the system falls short of it today. That second statement is a finding about the system.
It is not part of the law. The reproduction tests it. When the build is done, it is false,
and the law still stands. (Astra's distinction. Today the help of discovery writes the two as
one hypothesis.)

It follows a value of the Mathlib community: weak hypotheses, strong conclusions.

- **Assume little.** A cause, a mechanism, or a fix in the hypothesis adds meaning that the
  human did not give. It also chooses a design too early. A cause that the agent finds is a
  finding. It is not part of the hypothesis.
- **Conclude strongly.** Say which outcome is wanted, and which facts decide it.
- **Stay falsifiable.** A statement that no result can show false says nothing. It has
  collapsed.

Remove words until one more removal makes the hypothesis collapse or change its meaning. A weak
hypothesis often takes more work to confirm or refute, but not always.

Every stated hypothesis lists its premises beside it. Hypotheses, premises, and claims err
soft. Experiment just past the boundary of too brittle or too soft, then formalize. The
formalism then localizes the definition. Annealing in the formal languages brings out the
tempered position. Oscillation is an intentional heuristic.

**(P)** A word of a hypothesis that no judgment of the human holds in place yet is a
**guess**. A hypothesis can carry guesses while the work goes on. Each one is a default: the
delivery lists it, and one case would decide it.

**(P)** A hypothesis has two falsifiers, and each has its own witness. The system is the
witness of one: a result that the system shows. The human is the witness of the other: a
concrete case that the human judges. The question for the human is the author's: "is this case
your intent?" When the system shows a case that the hypothesis rejects, the case alone does
not say which is wrong, the build or the hypothesis. The human's judgment of that case says it.

**(P)** A premise can fail too. A premise that nobody checked is a guess. When the system
shows that a premise is false, the hypothesis does not apply as it is written, and the agent
restates it. So a result can challenge three things: a premise, the build, or the reading of
the intent. The agent says which one. (Astra's point.)

**(P)** The law is also a default. A check that fails is judged against the hypothesis, and
nobody asks the human again about what they accepted. The agent asks only when a case gives a
reason to doubt the hypothesis itself.

The build goes back to discovery only when the hypothesis itself must change. A claim that
changes inside the hypothesis stays in the build. Discovery exists to form the hypothesis, and
in a workspace discovery is another agent, so a return has a cost. (The author holds this one
loosely: "I might say".)

And not every change of the hypothesis needs discovery. Sometimes the human's answer says what
the hypothesis changes to: "only on this page". Then the agent restates it where it is. A new
hypothesis supersedes the old one, and the human sees it. The work goes to discovery when the
agent can no longer say what to change. Clarity decides. (This draft proposed it, and the
author agreed on 2026-11-11.)

"A properly written hypothesis" (below) gives the definition.

In the prompt: "The light path", "The hypothesis".

#### 3. What a lap learns, the next lap keeps

Agents forget. Sessions end, contexts are compacted, and work moves between agents. So the
state of the work lives in a record that a person or an agent can query. It does not live in
the recollection of one agent.

A change of plan does not erase an earlier outcome that the human still wants. That outcome
stays a claim, and the agent checks it again against the new design. A new claim supersedes an
old one. It does not overwrite it. An old guarantee does not carry over to a new design without
new evidence. **(P)** This is how the finding stays monotonic: the record keeps what was
learned, and also what was replaced.

When the human liked a result and now wants to change it, the first step is to narrow down
what was liked and what was disliked. What the human liked stays: its claims stand, and their
checks stay. Only the part that the human no longer wants gets a new claim. A change that
stacks on top of the earlier result, and changes nothing in it, is a new ticket.

> If I "liked" the result but want to change it, then the agent and sagittarius need to narrow
> down what was liked and what was disliked. If the change stacks on top of the previous
> request without modifying the previous work, then it just counts as a new ticket with its
> own spec KB. (the author, 2026-11-11)

**(P)** Sometimes nothing says if the agent misread the request, or if the intent moved. Then
the agent does not guess. It says so, and it treats the case as a divergence. (Astra's point.)

**(P)** A new ticket does not close an old one. The earlier ticket keeps what is open in it:
its checks, its proofs that are owed, and its questions.

**(P)** An outcome that must outlive its ticket needs a home that outlives the ticket: a rule
of the project, with a test beside it. When a ticket closes, the agent proposes each such
outcome, and a human ratifies it. With no project record, the test in the project's suite is
the home.

The main task with a model is to give it the right amount of context. A record that can be
queried helps to select it. Every orbit encodes knowledge of the domain, not only a record of
the process.

In the prompt: "Signals" (a handoff), "One response", "The tool".

### Because an author does not see their own misreading

#### 4. No party grades its own work

Each result goes through a party that did not make it. The human judges meaning. The machine
judges what follows from a statement. A reviewer reads the request and the system, not the
report of the builder.

The rule holds for noticing too. An agent is a poor judge of whether it has diverged.

> "We can't make an algorithm that mechanically detects these things and we can't let a model
> grade themselves on whether they are diverting. something outside needs to help." (the
> author)

That is the job of System 1: a small model outside the agent that reads each message of the
human. Its main purpose is to help with detection and classification. System 1, the agent, and
the human each have a part in the decision to shift up. System 1 helps to detect. The agent
responds. The human can overrule both.

When System 1 and the agent disagree, the agent does not settle it alone.

> "Yeah if S1 and the agent disagree, then it needs to either go to some kind of formalism, or
> it needs to come to the human, or both." (the author, 2026-11-11)

**(P)** This is the one response again (principle 10), and not a new rule. A disagreement
between System 1 and the agent is a difference between two views. So the agent says it where
the human can contradict it, or it makes the claim specific enough that a check or a query
decides, or both. A signal that the agent notices by itself, it says aloud too.

A case: the author has never seen an agent shift up by itself. An audit of one long session
(2026-10-22) found no record at all. Each divergence got an answer ("You're right to flag it")
and a fix.

In the prompt: "Who judges what", "One response" (System 1).

#### 5. Each statement comes from the source

Each statement of the intent comes from the intent itself: the request and the current system.
It does not come from another statement. An orbit goes back to the source on each lap (see
"The orbit").

When two tools state the same claim, write each statement from the source, not from the other
statement. Then a difference between them is information.

**(P)** The same holds for a build and its check. An agent can put one misreading into the
code and into the test of that code. Then the two agree, and the agreement says nothing. So
the check comes from the request, not from the build. (Astra's point.)

In the prompt: "The idea", "The orbit", "The light path".

#### 6. The machine checks what follows. The human reads what was stated

The formal artifacts are impartial: a test, a query, and a proof can disagree with the agent
and with the human.

**(P)** Impartial has a limit. The formal artifacts are impartial about what follows from a
statement. They are not impartial about which statement was written, because an agent chose
it. A case from 2026-11-11: an agent recorded that two sentences of the author exclude each
other, and the knowledge base then reported a contradiction. The inference was sound. The
reading was the agent's.

So the human reads the statement. Show the human concrete examples and results first, not test
logs. When the work has shifted up, the human, the agent and the CPU all use the formal
language as the shared substrate, and the human reads, reviews and understands it, so write it
to be read. The human judges meaning. The machines judge consistency.

**(P)** And show it. The human can read the formal language only if someone puts it in front
of them. The plain claim and its formal statement go to the human together. A case: on
2026-11-11 the author reported that they had seen no Lean proof and no Prolog statement since
they started to use Sagittarius.

In the prompt: "Who judges what", "Delivery".

#### 7. The tools assume trust. Each catches its own kind of error. None stops cheating

Sagittarius assumes trust between the human, the agents, and the code. If the process
constrains one of them too much, the work fails. Each tool catches its own kind of error. Lint
catches errors of syntax and schema. A check catches behavior on its cases. A proof covers its
definitions. The human judges meaning.

The tools do not stop deliberate cheating. A hole that only deliberate cheating can use is a
known limit, and the documents say so. They do not claim more than the checks give. Impartial
also does not mean infallible: when two engines give different answers, nobody uses either
answer until a human looks.

In the prompt: "Honesty", "The tool".

### Because a comparison must be able to fail

#### 8. A divergence is good news. A quiet failure is the enemy

Where the views of the parties do not agree, there is a divergence: a check that fails, a
counterexample, or a human who says "that is not what I meant". A divergence is loud, so
someone can fix it. It shows that clarity increases. Record it.

The ways in which a human can find or describe a divergence have no end. So the agents try to
detect them, and the formal tools help to specify them.

The worst failures are quiet: a check that passes while the result is wrong, a claim that
nobody tested, an empty answer, a theorem that cannot fail. **(P)** A signal that someone saw
and did not say is quiet too. Evidence that cannot fail is not evidence.

**(P)** A theorem is not empty because it is true. It is empty when its premises never occur,
or when it does not tell a wanted behavior from an unwanted one. A function that always
returns the empty list has a proof that its output is sorted. The proof is correct, and the
elements are gone.

**(P)** A check of a change fails before the change. That failure is not a new divergence: it
is the gap that the request named, seen again. The same check, if it passes there, is a
divergence. A prediction does not make a bad result good. A check that fails after the build
is a claim that is not met, also when the agent expected it.

> "Silence, negative space, emptiness, and vacuity are often the predators of clarity,
> accuracy, and honesty." (the author)

In the prompt: "The idea", "Signals", "The light path".

#### 9. Words match evidence

Say what was guessed, what was not verified, and what went wrong. Disclosure is never a
failure. Hiding is a failure. Claim no more than the evidence shows:

- Tests that pass do not show that the result is correct.
- A statement in a proof language is not a proof.
- A proof is about its definitions, not about the shipped code. Examples carry it to the code:
  each example of the definitions becomes a test of the code.
- A result inside bounds is not "always" or "never".
- **(P)** A model speaks for the system only after it has matched the system: on a real case
  where the system fails, and on a real case where it passes. A match of the outcome does not
  show the cause.
- **(P)** A file that changed can show that evidence is stale. It cannot show that the
  evidence still applies.

If your own earlier work is wrong, say so first.

A case (2026-10-30): a model of a race was recorded as calibrated because it reached the same
failure as the system. The system then showed that failure by a different sequence of steps.
The outcome matched, and the mechanism did not.

In the prompt: "Honesty".

### Because a sharper statement costs more

#### 10. One response: get more specific, and pay closer attention

Most work needs little process. Work starts light. It gets sharper only on a signal of
misunderstanding: questions that one round does not settle, a disagreement or a surprise, work
that another party did, a claim that examples cannot cover, work that changes hands, or
significant effort or verbosity from the human. Size does not decide, and difficulty does not
decide. Clarity decides. A one-line fix can need rigor, and a large change can need none.

Every signal gets the same response.

> "Shifting up simply means getting more specific and paying closer attention." (the author)

The signals are many, and each needs a well-tempered definition. The response is one, and it
is easy to trigger. A light model can follow one shape of response. The attention that the
response needs stays low, so the agent keeps its attention on the orbit, not on the process.

**(P)** "More specific" has three levels of statement:

1. **Words.** The hypothesis in one sentence, its premises, one concrete example, and one
   check that can fail. This is the light path: the first response to any request for a
   change.
2. **Records.** A knowledge base that holds the request word for word, the hypothesis, the
   claims, the questions, the checks, and what differed. The knowledge base is in Prolog. So
   this level is a formal language already, and the human reads it.
3. **A formal statement of one claim,** in the language that fits that claim: a solver, a
   model checker, or Lean.

A request starts at the first level. A signal moves the work to the second level, if it is not
there yet. The third level is for one claim at a time. A claim that needs a proof goes there
at once. A claim that words and records did not settle goes there next. A count of signals
does not choose it: the claim does. A discussion with no change to make gets no knowledge
base. When the cause of a signal is resolved, the rigor that it added stops.

**(P)** Every ticket has a hypothesis, and that costs one sentence. It must not cost more. The
first level has no knowledge base, and the agent does not wait for the human to approve the
sentence. The author's concern is on record, and use will judge it (see "Under trial"):

> "My concern is that this is going to add a slowdown since there will be more of a process for
> every change request. I'm hoping that the `orbit-kb` tool will help streamline that I
> guess." (the author, 2026-11-11)

A ticket starts in words, and records start on a signal. A knowledge base exists to help find
the intent. When the intent is clear, there is nothing for it to find.

> "your typo example speaks clearly to me as a trivial change that would never need a KB to
> discover the intent." (the author, 2026-11-11)

**(P)** Where a workspace keeps a record for every ticket, the hypothesis goes into that
record. And the step from words to records must become cheap (see "Known limits"): the step
is rare, so it must be easy when it comes.

Effort is a signal to shift into a formal language. A long, careful message holds decisions
that must not be lost. After a shift, the human, the agent, and the CPU (the machine that runs
the solvers and provers) all work in the formal language. The human must read and review it,
so shift up only when needed.

In the prompt: "The light path", "Signals", "One response".

#### 11. Each formal language is a lens. Use the one that fits, one at a time

A claim about current behavior needs a test. A claim about rules and limits fits a solver. A
claim about the order of steps or about time fits a model checker. A claim about every possible
input needs a proof. Use the cheapest tool that can show the claim false. Use a model only
when a few examples cannot cover the cases. A tool that does not fit the shape of the claim
can prove something true and still lose the intent.

Decide the shape of a claim by its meaning and its domain, not by its words. "Every" in a
sentence does not make a claim universal. A claim is universal when its inputs are infinite or
too many to check one by one.

Two kinds of formal tool help the human and the agent to see the intent. A proof language
(Lean) demands precision: a statement says exactly what it means, or it does not check. A
logic store that can be queried (Prolog, with SWI-Prolog as the engine) keeps the facts of the
work in one place. Its rules keep attention on what is still open.

> "We use one language because one language gives us one lens. we should use the right lens
> for the right problem depending on what we're trying to uncover." (the author)

The work uses one formal language at a time. The knowledge base is the exception, because it
tracks the ticket itself. The aim is to stop a recursive shift up: a signal that fires while
one model is written must not start a second language. The author saw that failure in an
earlier version of the method. System 1 and the agent can help to choose the lens, after a
divergence is detected.

**(P)** "At a time" is about writing. One language is written at a time, and a finished
artifact can be read as evidence beside it. A language leans back when its question has an
answer: its results are recorded, or it is dropped with a disclosure.

In the prompt: "Signals" (a claim that burns), "One response" (one lens at a time).

#### 12. Speed comes from skipping work, never from hiding it

Do only the work that the request needs, and stop when it is done. Every skip of needed work
is visible. Only the human can skip it, and the skip has a due time. After that time, the work
comes back.

In the prompt: "The orbit", "Delivery".

### The method follows its own rules

#### 13. One principle, shown by examples

State one principle, and let examples show its meaning. A checklist of trigger words overfits:
it catches the words and misses the meaning. Examples show meaning, not strings to match. Give
each term one meaning. When two meanings share a word, the result is confusion.

In the prompt: "When the human says that it is wrong", "The hypothesis" (the example).

#### 14. The method is an attempt too

Improve the process as you improve a hypothesis. A change to the prompt must be worth having
even if no test of the prompt existed. It comes from a real failure, not from the shape of one
test case. Never put the answer to a test into the prompt. Tune on one set of cases, and
decide on a separate set that nobody tuned on. A rule needs a case that fails when the rule is
deleted. Decide on repeated runs, not on one run. When a case passes only if the prompt
describes that exact case, the limit of the model is a result, not a target.

Evals test whether agents can follow the rules of the prompt and of the `orbit-kb` help. Use
tests whether the philosophy and the hypotheses pay off: the author's reports from real work
are the test reports of the method. No one stakeholder is privileged: the method does not
optimize for one project. It also does not generalize so far that a stakeholder gets only
trivial results.

This document changes in the same way. A belief here is a hypothesis about the work, and use
tests it. "Under trial" lists the beliefs that use has not yet judged.

In the repository: `docs/REFINING.md`.

## A properly written hypothesis

**(P)** This section proposes the definition that the earlier text left open. The author's
working sentence was: "a properly written hypothesis is the weakest form of a statement that
doesn't collapse (it is provable) and doesn't generalize so far as to lose its intent."

A hypothesis is a list of premises and a list of claims. A premise says when the hypothesis
applies. A claim says what must then hold. A **case** is one concrete behavior that the system
can show and the human can judge. The hypothesis accepts a case, or it rejects it. The
judgments belong to one ticket. The question to the human is always: "is this case what you
want with this request?"

A hypothesis is **properly written**, for what the human has judged so far, when:

1. **It fits.** No case that the human judged disagrees with it. It rejects no case that the
   human wants, and it accepts no case that the human rejects.
2. **It can hold.** It has an example: some case meets its premises and its claims. If no case
   can meet a statement, no build can fulfill it.
3. **It can fail.** It has a falsifier: some case would show a build wrong. A statement that
   accepts every case has collapsed.
4. **No word can be removed.** Without any one premise, or without any one claim, the
   statement no longer fits, or it has collapsed.

Point 1 is "does not lose its intent". Points 2 and 3 are "does not collapse". Point 4 is this
draft's reading of "the weakest form": the form with no word left to remove. It is not "the
statement that accepts the most cases" (see "What the definition does not decide"). The intent
is not in the definition, because nobody holds it. The judgments of the human stand in for
it, and each lap adds to them.

A word that fails point 4 is a **guess**: a default of the writer that no judgment holds in
place yet. A hypothesis at work can carry guesses. It is properly written when the last guess
is held in place, or removed.

The same definition, in Lean. `j` is what the human has judged so far, and `h.req` is what the
hypothesis `h` requires of a case:

```lean
/-- A judged case where `R` and the human disagree. -/
def IntentFalsifier (j : Judgments Case) (R : Req Case) (c : Case) : Prop :=
  (Wanted j c ∧ ¬ R c) ∨ (Unwanted j c ∧ R c)

def Fits (j : Judgments Case) (R : Req Case) : Prop := ∀ c, ¬ IntentFalsifier j R c
def Collapsed (R : Req Case) : Prop := ∀ c, R c
def Out (j : Judgments Case) (R : Req Case) : Prop :=
  (∃ c, IntentFalsifier j R c) ∨ Collapsed R

/-- An example: a case that meets the premises and the claims. -/
def Hyp.HasExample (h : Hyp Case) : Prop :=
  ∃ c, (∀ p, h.premise p c) ∧ ∀ q, h.claim q c

/-- A word is held in place: without it, the statement is out. If not, it is a guess. -/
def PremiseHeld (j : Judgments Case) (h : Hyp Case) (p : h.Premise) : Prop :=
  Out j (h.withoutPremise p)
def ClaimHeld (j : Judgments Case) (h : Hyp Case) (q : h.Claim) : Prop :=
  Out j (h.withoutClaim q)

structure ProperlyWritten (j : Judgments Case) (h : Hyp Case) : Prop where
  fits : Fits j h.req
  can_hold : h.HasExample
  can_fail : ¬ Collapsed h.req
  premises_held : ∀ p, PremiseHeld j h p
  claims_held : ∀ q, ClaimHeld j h q
```

The file is `docs/philosophy-orbit/2026-11-11/fable/Hypothesis.lean`. The Lean kernel accepts
each of its 63 theorems, and none uses an axiom. The theorems are about these definitions.
They say nothing about any code. What follows from the definitions:

| In plain words | Theorem |
|---|---|
| Each premise is held in place by a case that the human wants, and that the hypothesis would reject without the premise. | `premise_held_by_wanted_case` |
| Each claim is held in place by a case that the human rejects, and that only this claim forbids. Or the claim is all that keeps the hypothesis from collapse. | `claim_held_by_unwanted_case`, `claim_false_at_its_case` |
| Two statements disagree on a case. Ask the human about that case. Whatever the answer is, exactly one of the two is refuted. | `one_case_decides` |
| The system shows a case that the hypothesis rejects, and the human rejects it too. The hypothesis stands, and the build is wrong. | `stay_in_build` |
| The human wants a case that the hypothesis rejects. The hypothesis must change. | `hypothesis_must_change` |
| A collapsed statement cannot fail: every system fulfills it. A premise that the system never meets has the same effect. | `collapsed_cannot_fail`, `unmet_premise_cannot_fail` |
| A check that fails shows that the statement can fail. | `red_shows_it_can_fail` |
| While the human keeps the earlier judgments: a falsifier that was found stays found, a word that is held stays held, and a properly written hypothesis stays properly written until a new judgment disagrees with it. | `falsifier_stays`, `premise_held_stays`, `claim_held_stays`, `proper_until_falsified` |
| The human changes a part of what they wanted. Outside that part, every falsifier stays. The narrower the part, the more is kept. When the part is empty, nothing changed: the new wish is a new ticket. | `falsifier_stays_outside`, `narrower_keeps_more`, `keepsOutside_nothing` |

Five habits of the method follow from the definition. They are not separate rules.

- **Each claim gets one concrete example and its falsifier.** Points 2 and 3 ask for both. The
  falsifier is the case that holds the claim in place.
- **The question is "is this case your intent?"** To test one word, take the case on which the
  hypothesis with the word and the hypothesis without it disagree, and ask. This is the
  oscillation as one step: the case just past the boundary. It turns a guess into a held
  word, or it removes the word.
- **A check of a change fails before the change.** The failure shows that the statement can
  fail.
- **The delivery lists the guesses.** They are the words that no judgment holds in place.
- **Liked, then changed: narrow it down.** The narrower the part that changes, the more of
  what was learned is kept.

### A defect: "members got the wrong loyalty points"

The human rejected two cases with wrong points, one of them with a fresh cache, and accepted
one case with right points. The verdicts are theorems of the same file.

| Attempt | Verdict | Why |
|---|---|---|
| "The tier is read from a cache that loads once." | Too strong | It accepts a case that the human rejects: wrong points with a fresh cache. The cause added meaning that the human did not give. |
| "Points depend on something other than the purchase." | Collapsed | It accepts every case, as the file encodes it: no one purchase can contradict the sentence. Another reading of the sentence can give another verdict. |
| "The amount of a purchase and the member's tier on that day decide its points." | Properly written | It fits the three judgments, the right case is its example, the reported case is its falsifier, and it has no word to remove. |

### A feature: "add a dark mode"

The hypothesis is the author's own attempt (quoted in principle 2). The Lean file holds a small
version of it, and that version is this draft's reading of the sentence. Every page is in
scope. "Accessibility, readability, or useability" is one flag. The small version says nothing
about a screen while dark mode is off.

| When | Verdict | Theorem |
|---|---|---|
| At first. The human has rejected today's behavior (that is the request), and a screen that is hard to read (an earlier outcome that they still want). | The wide attempt is properly written. It assumes nothing about the scope. | `wide_properly_written_at_first` |
| At first. | "Only the settings page" is a guess. "Light mode stays" is a guess too. No judgment holds either in place. | `scope_was_a_guess`, `keepsLight_was_a_guess` |
| The human answers: "only on this page". | That one case refutes the wide attempt, and it shows where the failure is: the scope. | `wide_scope_falsified` |
| The human rejects a screen that is dark while dark mode is off. | A claim was missing. | `wide_alwaysDark_falsified` |
| After both answers. | The narrowed attempt is properly written: one premise and three claims, each held in place by one of the cases above. | `narrow_properly_written` |

So the definition agrees with the author's reason for the wide sentence. At the moment of the
request, the wide attempt is the properly written one, and a narrower scope is a guess. The
answer "only on this page" then turns that guess into a held word.

Two notes on the sentence itself, by the rule "remove words":

- This draft cannot name a case that "contain and" rejects, or a case that "compatible"
  rejects. By the rule, such a word goes, or its writer names the case.
- The sentence may not say what happens while dark mode is off. The case to show is: "the app
  is dark for every user, with no way back to light". If the author rejects that case, either
  a claim is missing, or the word "mode" carries it already and the small version reads the
  sentence too weakly.

### The three points that the earlier text left open

- **Does "provable" mean "falsifiable"?** "Does not collapse" has two sides, and the two words
  name them. The statement can hold: some case meets it. The statement can fail: some case
  would refute it. Points 2 and 3 say so.
- **Must the hypothesis cover only the intent, or must the intent fit inside it?** Both, one
  case at a time. "Fits" has both directions.
- **Must a hypothesis use only facts that the system can show?** Yes. A case is something that
  the system can show and the human can judge. A premise that the system never meets makes the
  hypothesis unable to fail.

### What the definition does not decide

Astra reviewed the first version of this definition and proved two things about it
(`FableReview.lean`, on Astra's branch). Both changed this section.

- **That version had no point 2.** When the human had judged nothing, it accepted a statement
  that rejects every case. Point 2 is the answer.
- **Properly written is not unique, and it is not the logically weakest.** Two attempts can
  both be properly written and disagree on a case that nobody judged
  (`proper_attempts_can_disagree`). The definition does not choose between them.
  `one_case_decides` says what to do: show that case to the human.

One more theorem says why "weakest" cannot mean "accepts the most cases". The statement that
accepts the most cases, and still fits, is the bare list of the cases that the human rejected
(`onlyTheRejected_fits`, `fits_accepts_no_more`). It says nothing about a new case. A
hypothesis must say more than that list: its claims say which facts decide the outcome. So
the deletion test is about the words of a statement, and the choice between two statements
stays with the human.

Three more limits:

- The definition tests the words as the writer cut them. It does not test the cut. One claim
  that packs two demands is one word, and it passes. The habit "one example and one falsifier
  for each claim" is the guard: a claim that needs two different falsifiers is two claims.
- A case here is one behavior. A claim about an order of steps, or about time, needs a case
  that is a sequence.
- The agent chooses what a case is, so the human must read it (principle 6). The dark-mode
  example shows the risk: one flag stands for three words of the author.

## Where Sagittarius sits

Sagittarius is an extension of the harness, between the human-agent interface and the software
factory. The harness is the interface between the human and the agent. The software factory is
the interface between the agent and the project. Sagittarius fills the gap between them as an
inference, reasoning and knowledge-graph layer. It is opinionated: it puts everything into one
shape.

The audience is people who work with formal methods and AI. Users are expected to read Prolog,
Lean, and the other formal languages. A general template is a byproduct: an informal release.

Sagittarius runs in two interfaces.

1. **Sagittarius:** the system prompt and `orbit-kb`. It carries this philosophy everywhere
   that it goes. The System 1 hook belongs here, not with the hub: it goes where the prompt
   goes. For now the hook is recommended, not required.
2. **MindHole:** the hub. Sagittarius provides a hub as a kind of pinned workspace. Each
   MindHole can run its own version, with its own `orbit-kb` and its own changes for that
   workspace. It is for power-work, where throughput, explainability and automation are
   central.

The two work best together, and neither depends on the other. **(P)** So the prompt must be
true alone: with no hub, with another version of `orbit-kb`, and when System 1 is silent.

**(P)** The prompt holds the philosophy in words that change how a model acts. That is what a
session needs before it reads any help: the orbit, the light path, and the signals. The tool
holds the procedure and its syntax. (This replaces "the prompt holds the philosophy only". A
session on the light path never runs `orbit-kb`, so it never reads the help.)

**(P)** Each release of Sagittarius has a semantic version, and the prompt names its own
version. Then a report from use can say what it ran.

## Under trial

Use has not yet judged these positions. Each one names what would show it wrong. **(P)** The
right column is this draft's.

| Position | What would show it wrong |
|---|---|
| Premises ride beside every hypothesis. | The author skips them, or reports them as noise. |
| A rule of the prompt needs a case that fails when the rule is deleted. | A rule that clearly matters, for which no such case can be written. |
| Every ticket has a hypothesis: wide, stated, and not asked. | The author reports that plain requests got slower, or that the sentence reads as a ritual. |
| The oscillation as one step: show the case just past the boundary, and ask. | The questions are too many, or too strange to answer. |
| System 1 is recommended, not required. | Sessions without it miss signals that sessions with it catch. Then it is required. |
| When System 1 and the agent disagree, it goes to the human, or to a formalism, or both. | System 1 names so many false signals that these lines become noise. |
| Liked, then changed: narrow down what stays and what changes. | The narrowing costs more than the change, or a part that the author liked is lost anyway. |
| The build goes back to discovery only when the hypothesis must change, and then only when the agent can no longer say what to change. | A hypothesis that was restated in build is later found to have changed what the ticket was for. |
| A ticket starts in words. Records start on a signal. | Agents still miss the step from words to a record, as the audit of 2026-10-22 found, also when the step is cheap. |
| **(P)** The claim chooses the third level, not a count of signals. (The tool today counts: a claim that is contested twice needs a proof. Astra's plan for the tool drops that rule.) | Claims that needed a formal statement stay in words and records, and the same correction comes back. |
| **(P)** A predicted result is not a signal, and the agent says what it expects before it looks. | Agents write the expectation after the result, or the line becomes a ritual. |
| **(P)** The definition of a properly written hypothesis, and of a guess. | A hypothesis that the definition accepts and the author calls badly written, or the reverse. |
| **(P)** The formal statement goes to the human with the plain claim. | The author reports it as noise, or still does not see it. |
| One response for every signal. | A signal appears for which the right response has another shape. |

## Known limits

**(P)** These are limits of the tools today. Each is work for the tools. None is an open
question of the philosophy.

- The System 1 hook prints nothing when it has no confident answer, and nothing when it fails.
  The agent cannot tell either of these from "no signal".
- The hook runs only when the human sends a message. A signal inside the turn of the agent has
  no outside witness. The spoken line of the agent is all that there is.
- The question set of System 1 does not count a new request or a change of preference as a
  divergence. This document does.
- The step from words to records costs several commands and a long read of the help. At that
  same moment, "you're right" and a fast fix cost nothing.
- The tool has a hypothesis fact only in discovery. The hypothesis of a direct build has no
  record of its own.
- In the tool, the human and the agent can vote GO and win while the discovery is not ready.
  The rule for the outcome of the vote does not read the readiness.
- In the tool, one matching case makes a model count as calibrated, and a model that is
  derived from it inherits that.
- `orbit-kb pin` stamps the whole KB file. It does not cover the artifacts that the KB names,
  and it does not tell a dependent ticket that something changed.
- Nothing reopens a proof when the code changes. A change of the Lean files does reopen it.
- A fact of the project that became stale is quiet in the records that rest on it.
- The tool records who made a decision. It does not record who made a relation between two
  decisions, so a relation that an agent wrote reads like a fact.
- `orbit-kb prove` prints the statement of the theorem. The report of the tool does not put
  that statement, or the facts of the KB, beside the plain claim.
- The help of discovery writes the wanted outcome and "the system falls short" as one
  hypothesis, with one falsifier.

Where these come from:

- The hook, its question set, the help of discovery, and the report: read for this draft (the
  report in one real KB).
- The hypothesis fact, the vote, the calibration, and the pin: Astra's audit of the source
  (`docs/REWORK-PLAN.md` on Astra's branch). This draft read those rules and the help of
  `pin`, and they are as Astra says.
- The proof, the stale fact, the relation, and the cost of the step: the review session's
  tests of 2026-11-11, one test each. This draft did not repeat them.

## How to judge a change

Ask these questions about a proposed change to the prompt, the tool, or the hub. **(P)**
Questions 6, 8 and 10 are new, and so are the second halves of questions 2 and 4.

1. Which premise or principle does it serve? Does it break one?
2. Does it let a party grade its own work, or its own noticing?
3. Does it build one artifact from another artifact, and not from the source?
4. Can a failure that it adds be quiet? Can a missing answer look like a "no"?
5. Does it add rigor before a signal, or keep rigor after its cause is resolved?
6. Does it add a second shape of response, where one shape is enough?
7. Does it let work be skipped with no visible record?
8. Does the human see the statement that the machine checked?
9. Does it add a word list, or the answer to a test, where one principle and an example are
   enough?
10. Is it still true with no hub, with another version of `orbit-kb`, and when System 1 is
    silent?

## Where the earlier text went

This text supersedes the text of 2026-11-05 (14 principles and six open questions). It does
not erase it: `git log -- docs/PHILOSOPHY.md` has it.

| Earlier | Now |
|---|---|
| Principles 1 and 2 | Principle 1 |
| Principle 3 | Principles 4 and 6, and "The center" (parallax) |
| Principle 4 | "The orbit", and principle 5 |
| Principle 5 | Principle 2, and "A properly written hypothesis" |
| Principle 6 | Principle 8 |
| Principle 7 | Principle 10, "The bet" (the tiers), and "The orbit" (the two levels) |
| Principle 8 | Principle 12 |
| Principle 9 | Principle 9 |
| Principle 10 | Principle 7 |
| Principle 11 | Principle 11 |
| Principle 12 | Principle 3, and "Where Sagittarius sits" (the job of the prompt) |
| Principles 13 and 14 | Principles 13 and 14 |
| Question A (the hypothesis) | "A properly written hypothesis" |
| Question B (back to discovery) | Principle 2; under trial |
| Question C (across tickets) | Principle 3; "Known limits" |
| Question D (a proof and the code) | Principle 9; "Known limits" |
| Question E (sizes as tiers) | Principle 10: clarity decides |
| Question F (one language at a time) | Principles 11 and 9 |

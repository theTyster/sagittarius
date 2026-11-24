# The philosophy of Sagittarius

> Philosophy 3.0.0, first draft. Proposed on 2026-11-24, for Ty's review. It is a full rework
> of Philosophy 2.1.0, and it replaces that text when Ty ratifies it. Its spine is Ty's
> statement of the project goal and its hypotheses (`hypothesis.md`, 2026-11-18 and
> 2026-11-23). Words in quote marks with "(Ty)" are word for word. Where this text reads Ty's
> words, or adds to them, it says "this text reads" or "proposed".

Sagittarius helps a human and an agent to find what the human wants, and then to build it.
This document holds the beliefs under it. It says why. The prompt says how to act, and
`orbit help` holds the procedure.

Read this document as a hypothesis, because it is one. It is Ty's current attempt to say what
the project is for. It has premises, and use can show it false. When use shows that a belief
is wrong, the belief changes, and the project follows. So this document is the frontier of the
project. It is installed nowhere. The prompt,
[`prompt/SAGITTARIUS.md`](../prompt/SAGITTARIUS.md), reflects it in words that change how a
model acts.

## The goal

> "Agents will deliver results that the human wants faster and with greater accuracy and less
> rework." (Ty)

That sentence is the goal of the project. Every other part of this document, and every part of
the project, must support it. A part that supports no goal is an orphan: it has no purpose
that someone can test.

The goal has three measures, and they pull against each other. "Faster" is easy to reach with
less accuracy. "Greater accuracy" is easy to reach with more process. "Less rework" joins the
two: rework is the cost of a result that was fast and wrong. Four qualities measure each
change and each rule against the goal:

- **Clear:** the request has one reading, and the human and the agent share it.
- **Accurate:** the delivered result does what that reading means. No less, and no more.
- **Honest:** what was guessed, what was not verified, and what went wrong are in view.
- **Fast:** attention goes only to work that the request needs.

A rule that improves none of them does not belong.

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
> that will continue to be a point of friction." (Ty)

## The center

Sagittarius A* is the black hole at the center of our galaxy. Nobody found it by looking at
it. Astronomers tracked the stars that orbit it, and the orbits showed where it is and how
heavy it is. That is how science finds a thing that it cannot see: it states what the thing
would do to something visible, and then it looks.

The intent of a piece of work is like that center.

- **The human owns it.** The human decides that it exists, and no tool helps with that. Only
  the human can say if a concrete case is what they want.
- **Nobody holds all of it,** and the human is no exception. People learn what they want when
  they see results.
- **It moves.** It shifts, or the human understands it better. It can look as if it acts by
  itself. It does not: it is not a party, and it cannot speak.

So every statement of the intent is an attempt: a request, a goal as someone wrote it, a
claim, an example, a test, a proof, the code. Each attempt can be wrong. The work is to find
where.

We find where from differences. Each party sees the intent from its own position. The human
sees it through words and judgments. The agent sees it through the statements that it writes.
The machine sees what follows from those statements. The system shows what is true now. The
parties are not tied to each other. As with two eyes, two positions find a depth that one
position cannot. Astronomers call that difference between two positions a parallax.

Where two views differ, there is a **divergence**. A divergence shows that two views do not
line up. It does not say why. An attempt can be wrong. The intent can have moved since one of
the views was made. Or the two views are about different cases. To get more specific at that
point says which. Each divergence that is settled leaves less room for the intent to be
somewhere else.

Everything in Sagittarius exists to help the human find the intent. Ideally the finding is
monotonic: what one lap learned, the next lap keeps.

## The hypotheses of the project

Ty wrote the goal, the premises and the hypotheses of the project. This is the reference
text. Its wording is kept as Ty submitted it.

> Project Scope Premise `User Ability`: The users of Sagittarius can read, write, and analyze
> logical concepts written in formal languages like Lean, TLA+, Prolog, and Z3.
>
> Project Premise `Sound Basis`: Existing behavior is presumed to be preserved. A claim in the
> specification can identify behavior to change. A demonstrated conflict opens the affected
> behavior for review.
>
> Project Hypothesis `Expert Favoring`: Humans with a deeper understanding of the results that
> they want enable AI agents to better achieve those results.
>
> Project Hypothesis `Sagittarius`: When compared to every comparable Agile method, building
> tools, formalisms, processes, and patterns off of the principles of the scientific method
> will reduce potential falsifiers, errors, and divergences between humans and AI agents.
>
> Supporting Hypothesis `Annealers`: Agents, formal languages, and proper context create
> tempered hypotheses most efficiently.
>
> - Annealer Property `Tempered Hypotheses`: A hypothesis is tempered when one admissable case
>   can demonstrate that its claim is false.
>
> Supporting Hypothesis `Anthropocentrism`: When the human seeks to adhere to the principles
> of the scientific method it enables `Sagittarius` to achieve the goal.
>
> Supporting Hypothesis `Human-first`: For a task with a consequential misunderstanding
> present at the outset, an agent starting from the human’s goal and self-written tempered
> hypothesis will expose that misunderstanding earlier and deliver a result the human judges
> closer to their goal than an agent than an agent given an ordinary request for the same task
> which leaves the hypothesis unstated.
>
> Supporting Hypothesis `Throughput`: By allowing the AI agents freedom to explore possible
> alternatives, and challenge the hypotheses against accepted sources of evidence, Sagittarius
> is able to deliver the results faster without reducing the quality of the result.
>
> Project Hypothesis `Parallax`: When a human and an agent use a formal language to dispute a
> non-trivial claim, that language will help them find a case that distinguishes their
> separate interpretations sooner than working in plain language alone.
>
> Supporting Hypothesis `Shifting`: When a human and an agent need evidence based solely on an
> _a priori_, shifting to a shared formal language reduces the total time needed to obtain
> that evidence especially on repeated experiments.
>
> (Ty, `hypothesis.md`)

The layers of the project are the layers of every ticket: a goal, hypotheses under it, and
the claims and experiments that test each hypothesis. The project follows its own method.
"Under trial" (below) gives each hypothesis its test: what it predicts, what would count
against it, and what a comparison must fix first.

How this text reads the three project hypotheses:

- **`Expert Favoring`** is why the method spends effort on the human's understanding, and not
  only on the agent's. The goal is easier to reach when the human knows what they want. So the
  method helps the human to find it (the center), and asks the human to say it first when
  they can (`Human-first`).
- **`Sagittarius`** is the method itself. "The principles of the scientific method" has a
  definite meaning here, in the next two sections.
- **`Parallax`** is why the method uses formal languages. Two readings of a plain sentence
  can agree for a long time. A formal statement forces each reading to say what it does with
  one case.

## The method

### The scientific method, for an intent that nobody can see

This text reads "the principles of the scientific method" as one statement, with its premises
beside it.

> **Nobody can see the intent. Independent views of it can be compared, and where they differ,
> there is something to learn about it. So the way to what the human wants is an orbit, and
> not a translation: state the goal and a hypothesis of how to reach it, say what must then be
> observable, compare that with a view that the author does not control, and locate each
> difference. Then go around again.**

Premises of the statement:

1. **The bet.** A human must explain what they want. No model removes that.
2. **Nobody holds the intent.** Each statement of it is an attempt.
3. **An author does not see their own misreading.** A view from outside can see it.
4. **A comparison must be able to fail.** A difference is information. An agreement that
   could have been a difference is evidence. An agreement that could not have been one says
   nothing.
5. **A sharper statement costs more.** It costs more to write, and the human must read it.
6. **`User Ability`** (Ty). The human can read and write the formal languages. Without this
   premise, a formal statement is a view that the human cannot judge.
7. **`Sound Basis`** (Ty). What exists is presumed to be wanted, until a claim or a
   demonstrated conflict says otherwise.

What would show it false: work that is done this way needs as many corrections after the
delivery as work that is done without it. Or the method costs more than the corrections that
it prevents. The bet itself is false if agents appear that need no explanation. Use is the
test (principle 19). Nothing here shows that this is the fastest method for every task.

### A ticket is an experiment

> "Under the scientific method, each ticket is a stated goal with a collection of hypotheses
> and experiments aimed at satisfying the goal." (Ty, 2026-11-23)

> "A goal is what we hope to accomplish (the intent). The hypothesis is how we think we'll
> get there." (Ty, 2026-11-23)

The layers are: the goal, each hypothesis under it, the claims that the hypothesis predicts,
and the experiments that test each claim. Eight words have one sentence each, the same in
every text of the project:

<!-- vocabulary:begin -->
- A goal is what the human hopes to accomplish: the intent. It names no avenue.
- A hypothesis is a claim about an avenue to the goal: how we think we will get there.
- A premise is a condition that a goal or a hypothesis takes as given. Where it does not hold,
  the statement says nothing.
- A claim is a prediction: what must be observable if its hypothesis and the premises hold.
- The specification is the procedure of the experiment: the claims, and the check of each claim.
- An experiment is one test of one claim: a procedure, its measurement premises, an observation,
  and one verdict.
- A verdict is the result of one experiment: meets, conflicts, or unresolved.
- A hypothesis is tempered when one admissible case can demonstrate that its claim is false.
<!-- vocabulary:end -->

The layers differ in who can show them wrong, and in what happens then.

| Layer | Who shows it wrong | What happens then |
|---|---|---|
| Goal | Only the human, on a concrete case: "is this case your intent?" | Its owner changes it or drops it. A goal is never defeated. |
| Hypothesis | One admissible case: a located conflict, or a case that the human rejects while every claim meets. | It is defeated. The case stays on it, and a new hypothesis is tempered. |
| Claim | An experiment whose observation is what the claim rules out. | A conflict, which must be located before anything is reopened. |
| Experiment | A reviewer who can show that its procedure or its measurement premises are wrong. | Its verdict becomes unresolved, and the experiment is repaired and run again. |

The goals form a tree. The goal of a ticket supports a goal of the project, and the goal of
the project is at the top.

> "The project KB holds the larger research goals and hypotheses. Everything should tie back
> into the project goals. Thus, the scientific method is able to offer us a kind of
> hierarchical experiment with a high-level research goal that all other goals must be able
> to support without contradicting or falsifying." (Ty, 2026-11-23)

### The orbit

An orbit is a loop through parties that can disagree. One lap is one turn of the scientific
method, and it has three steps.

1. **State.** Say the goal, and the hypothesis of how to reach it, as specifically as the work
   needs now. Say what must then be observable. Write each statement from the source: the
   human's words and the current system. Do not write it from the last artifact.
2. **Compare.** Put the statement beside a view that its author does not control: the human's
   judgment of a concrete case, a check that can fail, a query, a proof, a reviewer who did not
   build. Say what you expect, and how you will read the result, before you look.
3. **Sharpen.** Where the two differ, say the difference. Then locate it: an attempt is wrong
   (the build, the measurement, a premise, or the hypothesis), or the intent moved, or the two
   are about different cases. Correct what is wrong. When nothing says which it is, make the
   statement more specific at that point, and ask. Then go around again.

The orbit closes when a lap changes nothing. That counts only if each comparison in the lap
could have shown a difference: a lap in which nothing could differ is quiet, and it closes
nothing. It also counts only if nothing is left open. A claim with no check, a verdict that
conflicts or is unresolved, a proof that is owed, a question with no answer: each one keeps
the orbit open, unless the human waived it. Work that does not change can still be unfinished.

The opposite of an orbit is a translation. In a translation, each step reads only the output
of the step before it. Each small error passes on and grows, and no view is independent of the
view before it. At the end, the result can agree with itself and be far from what the human
meant. Two failures taught this:

- An earlier version of this method was a pipeline. Only its second stage read the request.
  Each later stage read only the artifact of the stage before it. Its proofs held, but they did
  not show that the code did what the human wanted.
- On one project, the wrong tool was chosen for proofs and a redesign was proved in lean that should
  have been written in TLA+. It lost an outcome about timing that an earlier model guarded. The new
  design was a "transliteration" of the TLA+ model: it added and changed rules that nobody
  requested. Its main theorem was always true, so it showed nothing.

> "We do not write to achieve understanding; we orbit to achieve understanding." (Ty)

Work has two levels. The orbit is discovery or build. Discovery makes a problem clear: its
laps end in a goal, a tempered hypothesis, and a vote. Build delivers a solution: its laps end
in a change and a delivery. Each orbit has a phase that makes and a phase that judges:
research and specify in discovery, build and verify in build. Rigor concentrates on
specification and verification. The split between make and judge stays, because it marks a
handoff.

New work is a divergence too. A request says that the intent differs from what the system does
now, or from what the human said before. But new work does not look like a misunderstanding,
so an agent does not treat it as one. That is why there are two orbits: discovery gives unclear
new work a place to start.

### An assessment that a reviewer can reconstruct

A timer set to sixty seconds rings when an independent clock reads 61.1. Did the timer run
late? Someone who knows only the reading cannot decide. They need to know how late the timer
was allowed to ring, how accurately the clock measured, and whether both instruments timed the
same events.

So the method asks one thing of every claim that evidence bears on a hypothesis: a reviewer
can reconstruct it. Five elements must be recoverable.

| Element | What a reviewer needs to recover | In a ticket |
|---|---|---|
| Conjecture | The claim under examination, and the cases that it applies to. | The hypothesis. |
| Premises | The other claims that the inference depends on. Each is checked, or marked as assumed. | The premises of the goal and of the hypothesis. |
| Prediction | An observable consequence of the conjecture and the premises. | A claim, with its example and its falsifier. |
| Observation | The evidence, with the procedure and the uncertainty that affect its reading. | One run of a check, with its measurement premises. |
| Assessment rule | How to compare the observation with the prediction, and how strong a conclusion that permits. | The rule that turns the run into one verdict. |

Two inferences are verified apart. **Does the prediction follow from the hypothesis and its
premises?** A proof can settle this when the terms are precise. **Given the observation, does
the rule warrant this conclusion?** A reviewer can accept the first and still challenge the
instrument, the sampling, or the rule. Reviewability means that the reviewer can locate the
disagreement.

A verdict has three values, and each has its own proof obligation.

- **Meets:** every outcome that is compatible with the observation is one that the claim
  predicts.
- **Conflicts:** no outcome that is compatible with the observation is one that the claim
  predicts.
- **Unresolved:** some compatible outcomes are predicted and some are not. The run could not
  decide.

The timer, with a tolerance of 59 to 61 seconds and a clock error of at most 0.2 seconds: a
reading of 60.0 meets. A reading of 61.5 conflicts. A reading of 61.1 is unresolved: a timely
ring and a late ring both fit it. For a nonempty observation, exactly one of the three holds
(`unique_verdict`).

Four more things follow, and each is a habit of the method.

- **A matching prediction does not show the hypothesis.** A false claim can predict a true
  result. Meets is evidence only when the experiment could have conflicted.
- **A conflict rejects a conjunction.** It rejects the hypothesis, its premises and the
  measurement premises taken together (`conflict_rejects_joint`). It does not say which one.
  So a conflict is located (principle 11).
- **The rule is chosen before the result is seen.** A pattern that inspired a hypothesis may
  be exactly the pattern that the hypothesis was made to fit. Record what was known when the
  hypothesis and the rule were chosen. A check that was written after its result was seen is
  fitted to that result.
- **A revision appends.** The original assessment stays when it is revised, so that a
  reviewer can see which finding changed the conclusion (`revision_preserves_record`).

A result that varies needs a rule of its own. An agent run, a flaky test and a sample are not
a timer. One run speaks to that run. A claim about a rate or an average needs a design that
says how many runs, and how strongly their result counts.

## What follows

Each principle follows from a premise. Each names where the prompt applies it today, and the
project hypothesis that it serves when there is one.

### Because nobody holds the intent

#### 1. The human owns the intent. Clarity is work that the human and the agent share

The human is the source of the intent and the owner of the result. The human is not always the
source of clarity. The agent owns the build, and its first job is to make the request clear
enough to build. When the human and the agent disagree on a decision, the human decides. The
owner is not the only person who can answer a question or ratify a decision. Answers and
decisions can come from other people.

The aim is alignment: the human, the agent, and the formal artifacts agree on what to build
and on when it is done. Agreement is always possible before a change lands. A full proof is
not always possible, and it is not always necessary. The agreement is about the current
statement of the intent. It can be right today and be superseded tomorrow, and nobody was
wrong.

An agent's proposal does not become the human's decision because it was written down, encoded
in Prolog, or proved in Lean. What an agent records about the human's words is the agent's
reading, until the human confirms it.

In the prompt: "The orbit", "Who judges what", "The vote".

#### 2. A goal is wide, and it names no avenue

The goal is the statement of the intent. Every ticket has one, and discovery exists to form it
when the request is not clear. The goal follows a value of the Mathlib community: weak
hypotheses, strong conclusions.

- **Assume little.** A cause, a mechanism, or a fix in the goal adds meaning that the human
  did not give. It also chooses a design too early: it is an avenue, and an avenue belongs in
  a hypothesis. A cause that the agent finds is a finding. It is not part of the goal.
- **Conclude strongly.** Say which outcome is wanted, and which facts decide it.
- **Keep it able to fail.** A statement that no single case can show false says nothing.

Remove words until one more removal empties the statement or changes its meaning.

Ty wrote the next example on 2026-11-11, when the statement of the intent was still called the
hypothesis. It is an example of a goal.

> In the case of "add a dark mode" the hypothesis might be: "The app must contain and use a
> compatible dark-colored scheme that supports dark mode without violating accessibility,
> readability, or useability across the entire application and its microservices." That way in
> case the human just meant "only on this page" or "only this service", then it becomes clear
> where the assumed failure was. Questions can help narrow that down, but now you've got clear
> defaults to work from. (Ty, 2026-11-11)

So the goal is wide on purpose. Each default of the agent is in the sentence, where the human
can see it and correct it. A narrow goal makes a guess too, and it hides the guess: outside
its premise it says nothing, so no check looks there.

Every stated goal and hypothesis lists its premises beside it. A premise is also a place where
the checks stop looking, and a premise that nobody gave can hide a wrong default. That is the
reason to write wide.

A report of a defect says one thing more than the goal: that the system falls short of it
today. That second statement is a finding about the system. It is not part of the goal. The
reproduction tests it. When the build is done, the finding is false, and the goal still
stands.

A **guess** is something that the agent assumed and that nobody confirmed: a default about
what the human wants, a hypothesis that the agent wrote and the human has not adopted, or a
fact about the system that the agent did not check. A wide goal carries its guesses in view.
The delivery lists them, and one concrete case, or one check, decides each of them.

Hypotheses, premises, and claims err soft. Experiment just past the boundary of too brittle or
too soft, then formalize. The formalism then localizes the definition. Annealing in the formal
languages brings out the tempered position. Oscillation is an intentional heuristic.

In the prompt: "The light path", "The goal". Serves: `Annealers`.

#### 3. A hypothesis is tempered, and the human writes the first one when they can

A hypothesis is an attempt at an avenue to the goal. It is tempered when one admissible case
can defeat it, and it is stated with that case: "It is false if ...". Several hypotheses can
be current, and the claims of each hold the ticket up. A defeated hypothesis holds nothing up.
The case that defeated it stays on it, and nobody edits it: a new one is written.

Who writes the first hypothesis is a position of its own (`Human-first`). The human gives the
goal and at least one hypothesis when they have them. The agent sharpens or challenges them at
once.

> "The agent and the human should work together to temper a hypothesis if either party deem
> the hypothesis un-tempered." (Ty, 2026-11-23)

Two reasons stand behind it. A human who has to say how they think to get there finds what
they do not yet know (`Expert Favoring`). And an idea that was formed before its author saw
another party's idea is an independent view. A human who only reacts to the agent's hypothesis
judges inside the agent's frame.

The method does not make this a fence. For a plain request the agent drafts the goal and the
hypothesis, says that they are its own, and goes on. To state them is not to ask a question.
The agent asks for the human's own only when a wrong avenue is costly or hard to undo. What
the human must do to "adhere to the principles of the scientific method" (`Anthropocentrism`)
is small and observable: say the goal, name a case that would change their mind, and judge a
concrete case before they see the agent's opinion of it.

In the prompt: "The goal", "The hypothesis". Serves: `Human-first`, `Expert Favoring`,
`Anthropocentrism`.

#### 4. Inside the goal, the agent is free to explore

The agent can investigate other hypotheses inside the goal and its constraints, and challenge
each one against the accepted sources of evidence: the system, the checks, the records. One
hypothesis is enough when alternatives would add little.

Sign-off is about adoption. The human adopts the avenues that they find satisfactory. A dead
end, or an alternative that differs only inside the build, needs no ratification. A material
tradeoff does: a difference that a user would see. If one avenue silently drops a correction
and another sends it to review, the choice changes what users experience, and it is the
human's.

A failed prediction is a reason to locate the disagreement, not to stop. A decisive
counterexample stays on the version that it defeats. An inconclusive result stays open. A
human may abandon an avenue on an early suspicion. An agent that says "this cannot be done
under these constraints" makes a universal claim: it needs grounds that cover every permitted
approach, not only the ones that it tried.

In the prompt: "The hypothesis". Serves: `Throughput`.

#### 5. What a lap learns, the next lap keeps

Agents forget. Sessions end, contexts are compacted, and work moves between agents. So the
state of the work lives in a record that a person or an agent can query. It does not live in
the recollection of one agent.

The record reasons. It is not a database that only stores.

> "every spec and ticket we work through should flow logically and narrow appropriately."
> (Ty, 2026-11-23)

So each item in a store has a purpose that leads up: an experiment to its claim, a claim to
its hypothesis, a hypothesis to its goal, the goal of a ticket to a goal of the project. A
task, a thread, or a handoff with nothing above it is an orphan, and the record can say so.
One command, `orbit`, is the door to every store, so that one set of rules reads all of them.

> "I want everything to have a purpose that leads back up toward the over-arching project
> goal. Prolog was made for a structure like this." (Ty, 2026-11-23)

A change of plan does not erase an earlier outcome that the human still wants. That outcome
stays a claim, and the agent checks it again against the new design. A new claim supersedes an
old one. It does not overwrite it. An old guarantee does not carry over to a new design without
new evidence. This is how the finding stays monotonic: the record keeps what was learned, and
also what was replaced.

When the human liked a result and now wants to change it, the first step is to narrow down
what was liked and what was disliked. What the human liked stays: its claims stand, and their
checks stay. Only the part that the human no longer wants gets a new claim. A change that
stacks on top of the earlier result, and changes nothing in it, is a new ticket.

> If I "liked" the result but want to change it, then the agent and sagittarius need to narrow
> down what was liked and what was disliked. If the change stacks on top of the previous
> request without modifying the previous work, then it just counts as a new ticket with its
> own spec KB. (Ty, 2026-11-11)

A new ticket does not close an old one. The earlier ticket keeps what is open in it: its
checks, its proofs that are owed, and its questions.

Sometimes nothing says if the agent misread the request, or if the intent moved. Then the
agent does not guess. It says so, and it treats the case as a divergence.

An outcome that must outlive its ticket needs a home that outlives the ticket: a rule of the
project, with a test beside it. When a ticket closes, the agent proposes each such outcome,
and a human ratifies it.

The main task with a model is to give it the right amount of context. A record that can be
queried helps to select it. Every orbit encodes knowledge of the domain, not only a record of
the process.

In the prompt: "Signals" (a handoff), "One response", "When the human says that it is wrong",
"Delivery", "The tool". Serves: `Annealers` (proper context).

### Because an author does not see their own misreading

#### 6. No party grades its own work

Each result goes through a party that did not make it. The human judges meaning. The machine
judges what follows from a statement. A reviewer reads the request and the system, not the
report of the builder.

The rule holds for noticing too. An agent is a poor judge of whether it has diverged.

> "We can't make an algorithm that mechanically detects these things and we can't let a model
> grade themselves on whether they are diverting. something outside needs to help." (Ty)

That is the job of System 1: a small model outside the agent that reads each message of the
human. Its main purpose is to help with detection and classification. System 1, the agent, and
the human each have a part in the decision to shift up. System 1 helps to detect. The agent
responds. The human can overrule both.

When System 1 and the agent disagree, the agent does not settle it alone.

> "Yeah if S1 and the agent disagree, then it needs to either go to some kind of formalism, or
> it needs to come to the human, or both." (Ty, 2026-11-11)

This is the one response again (principle 15), and not a new rule. A disagreement between
System 1 and the agent is a difference between two views. So the agent says it where the human
can contradict it, or it makes the claim specific enough that a check or a query decides, or
both. A hint that is dismissed in silence defeats the view from outside.

System 1 has three more jobs under the scientific method. Each is a question that the agent
answers badly about itself.

- **How many requests are in this message, and of what kind?** A human often puts several
  into one message. Each change request is its own ticket.
- **Did the hypothesis quietly become another hypothesis?** A prediction had two parts, the
  result shows one, and the summary says "it worked". With the active hypothesis in view,
  System 1 can ask what happened to the other part. It must also tell that drift from a
  revision that both parties know about.
- **Which conversation is this?** "We agree on the inputs and the rule, and we predict
  different outputs for this case" is a reason for a query or a proof. "We agree on the
  output, and the human has not decided if they want it" is a reason for a human judgment.

A case: Ty has never seen an agent shift up by itself. An audit of one long session
(2026-10-22) found no record at all. Each divergence got an answer ("You're right to flag it")
and a fix.

In the prompt: "Who judges what", "One response" (System 1), "Scope".

#### 7. Each statement comes from the source

Each statement of the intent comes from the intent itself: the request and the current system.
It does not come from another statement. An orbit goes back to the source on each lap (see
"The orbit").

When two tools state the same claim, write each statement from the source, not from the other
statement. Then a difference between them is information.

The same holds for a build and its check. An agent can put one misreading into the code and
into the test of that code. Then the two agree, and the agreement says nothing. So the check
comes from the request, not from the build. Checks that share one wrong assumption can agree,
so ask what each comparison can challenge.

The current system is a source for what exists. It is not a source for what should exist: the
limits of the present build do not decide what the human may want.

In the prompt: "The idea", "The orbit", "The light path".

#### 8. The machine gives verdicts. The human gives judgments

There are two levels of judgment, and each has its own witness. The system is the witness of
one: an experiment gives a verdict on a claim. The human is the witness of the other: a
concrete case that the human judges against the goal. The question for the human is Ty's: "is
this case your intent?" A judgment of the human never turns a verdict into meets, and a
verdict that meets does not choose what the human wants.

The formal artifacts are impartial: a test, a query, and a proof can disagree with the agent
and with the human. A test of any kind is a formal artifact, so a ticket with no knowledge
base has artifacts too.

Impartial has a limit. The formal artifacts are impartial about what follows from a statement.
They are not impartial about which statement was written, because an agent chose it. A case
from 2026-11-11: an agent recorded that two sentences of Ty exclude each other, and the
knowledge base then reported a contradiction. The inference was sound. The reading was the
agent's.

So the human reads the statement. Show the human concrete examples and results first, not test
logs. When the work has shifted up, the human, the agent and the CPU all use the formal
language as the shared substrate, and the human reads, reviews and understands it, so write it
to be read.

And show it. The human can read the formal language only if someone puts it in front of them,
while there is still something to decide. The plain claim and its formal statement go to the
human together. A case: on 2026-11-11 Ty reported that he had seen no Lean proof and no Prolog
statement since he started to use Sagittarius.

The record tracks the human as carefully as it tracks the agent. A judgment of a case, an
adoption of a hypothesis, a decision, a waiver, and a vote are each recorded in the human's
words, with who said it and when. Today the record holds mostly what the agent did.

In the prompt: "Who judges what", "Verdicts", "Delivery".

#### 9. The tools assume trust. Each catches its own kind of error. None stops cheating

Sagittarius assumes trust between the human, the agents, and the code. If the process
constrains one of them too much, the work fails. Each tool catches its own kind of error. Lint
catches errors of syntax and schema. A check catches behavior on its cases. A proof covers its
definitions. The human judges meaning.

The tools do not stop deliberate cheating. A hole that only deliberate cheating can use is a
known limit, and the documents say so. They do not claim more than the checks give. An agent's
report of itself stays a self-report, also when a formal record holds it. Impartial also does
not mean infallible: when two engines give different answers, nobody uses either answer until
a human looks.

In the prompt: "Honesty", "The tool".

### Because a comparison must be able to fail

#### 10. Every verdict can be reconstructed

Each run of a check is an experiment, and it leaves the five elements behind (see "An
assessment that a reviewer can reconstruct"): the claim that it tested, the premises, what was
expected, what was observed and how, and the rule that gave the verdict.

A check of a change fails before the change. That run is the control. It shows that the
experiment can conflict, and it shows the gap that the request named. It is not a new
divergence. The same check, if it passes there, is one. A prediction does not make a bad
result good: a check that fails after the build is a claim that is not met, also when the
agent expected it.

A verdict counts only for the state that its experiment observed. After a later change that
serves the claim, or when a measurement premise proves false, the verdict is stale, and the
claim is open until the experiment runs again. A changed file can show that evidence is stale.
It cannot show that the evidence still applies.

Unresolved is a result. It is not a conflict, and it is not a pass. It says what could not be
decided, and the claim stays open.

In the prompt: "The light path", "Verdicts".

#### 11. A conflict is located before anything is reopened

A conflict does not say what is wrong. It rejects the hypothesis, its premises, the
measurement and the build taken together. So the conflict is located first: in the build, in
the measurement, in a premise, or in the hypothesis. The party that built keeps a conflict in
the build. A location outside the build counts only when a party that did not build confirms
it. A conflict in the build is fixed there, and nobody asks the human again about what they
accepted.

A hypothesis that a located conflict defeats, or that a case which the human judges not wanted
defeats while every claim meets, goes back to discovery.

> "Following the scientific method, as I understand it, means that the entire experiment
> should be re-evaluated if a hypothesis is falsified." (Ty, 2026-11-23)

Discovery re-evaluates the goal, the premises and the measurement, and tempers a new
hypothesis. The case stays on the old one. Build does not restate a hypothesis. When the human
corrects the goal and says what it changes to ("only on this page"), the party that hears it
records the new goal in the human's words, and carries over what still counts.

An example. Goal: "A replayed import leaves the member records as one clean run would."
Hypothesis: "Skipping each record ID that was seen before makes a replay safe." A replay
leaves a duplicate because of a bug in the comparison of IDs: the conflict is in the build. A
correction arrives under a seen ID and is discarded, and the build does what the hypothesis
says: the conflict is in the hypothesis. Every check meets, and the human sees "the corrected
address of member 12 was dropped" and says "not wanted": the case defeats the hypothesis, no
check fails, and the build is not wrong. To deliver exactly what a rule says can still defeat
the goal.

In the prompt: "Verdicts", "When the human says that it is wrong".

#### 12. What exists is presumed to be wanted

> "Existing behavior is presumed to be preserved. A claim in the specification can identify
> behavior to change. A demonstrated conflict opens the affected behavior for review."
> (Ty, `Sound Basis`)

A ticket changes only the behavior that one of its claims names. Everything else stands, with
no claim of its own. When a change breaks other behavior (an old test fails, and no claim
names what it tests), the agent does not edit the test and does not make the change silently.
It reports the conflict, and the report opens that behavior for review.

The premise is about preservation, not about truth. It does not say that the present behavior
is right. It says that nobody asked to change it, and that a silent change is a quiet failure.

In the prompt: "Verdicts" (Sound Basis), "The light path".

#### 13. A divergence is good news. A quiet failure is the enemy

Where the views of the parties do not agree, there is a divergence: a verdict that conflicts,
a counterexample, or a human who says "that is not what I meant". A divergence is loud, so
someone can fix it. It shows that clarity increases. Record it.

A divergence does not accuse anyone. The intent can have moved, and then the earlier statement
was right when it was made (principle 5).

The ways in which a human can find or describe a divergence have no end. So the agents try to
detect them, and the formal tools help to specify them.

The worst failures are quiet: a check that passes while the result is wrong, a claim that
nobody tested, an empty answer, a theorem that cannot fail, a hypothesis that became another
one and nobody said so, a signal that someone saw and did not say. Evidence that cannot fail
is not evidence.

A theorem is not empty because it is true. It is empty when its premises never occur, or when
it does not tell a wanted behavior from an unwanted one. A function that always returns the
empty list has a proof that its output is sorted. The proof is correct, and the elements are
gone.

More counterexamples during the work can go with fewer failures at the delivery. To find a
falsifier early is the method at work. So a count of falsifiers says nothing until it names
the claim, the admissible cases, and the stage of the work.

> "Silence, negative space, emptiness, and vacuity are often the predators of clarity,
> accuracy, and honesty." (Ty)

In the prompt: "The idea", "Signals", "The light path".

#### 14. Words match evidence

Say what was guessed, what was not verified, and what went wrong. Disclosure is never a
failure. Hiding is a failure. Claim no more than the evidence shows:

- Tests that pass do not show that the result is correct.
- A verdict that meets does not show that its hypothesis is true.
- A statement in a proof language is not a proof.
- A proof is about its definitions, not about the shipped code. Examples carry it to the code:
  each example of the definitions becomes a test of the code.
- A result inside bounds is not "always" or "never".
- A model speaks for the system only after it has matched the system: on a real case where the
  system fails, and on a real case where it passes. The match goes from the system to the
  model: a checker picks its own path. A match of the outcome does not show the cause.
- One run of something that varies speaks to that run.
- A plausible rewrite is not a measured improvement. When only the wording was reviewed, say
  exactly that.

If your own earlier work is wrong, say so first.

A case (2026-10-30): a model of a race was recorded as calibrated because it reached the same
failure as the system. The system then showed that failure by a different sequence of steps.
The outcome matched, and the mechanism did not.

In the prompt: "Honesty".

### Because a sharper statement costs more

#### 15. One response: get more specific, and pay closer attention

Most work needs little process. Work starts light. It gets sharper only on a signal of
misunderstanding: questions that one round does not settle, a disagreement or a surprise, work
that another party did, a claim that examples cannot cover, work that changes hands, or
significant effort or verbosity from the human. Size does not decide, and difficulty does not
decide. Clarity decides. A one-line fix can need rigor, and a large change can need none.

Every signal gets the same response.

> "Shifting up simply means getting more specific and paying closer attention." (Ty)

The signals are many, and each needs a well-tempered definition. The response is one, and it
is easy to trigger. A light model can follow one shape of response. The attention that the
response needs stays low, so the agent keeps its attention on the orbit, not on the process.

"More specific" has three levels of statement:

1. **Words.** The goal and the hypothesis in one statement, the premises, one concrete
   example, and one check that can fail. This is the light path: the first response to any
   request for a change.
2. **Records.** A knowledge base that holds the request word for word, the goal, the
   hypotheses, the claims, the questions, the checks with their verdicts, the judgments of the
   human, and what differed. The knowledge base is in Prolog. So this level is a formal
   language already, and the human reads it.
3. **A formal statement of one claim,** in the language that fits that claim: a solver, a
   model checker, or Lean.

A request starts at the first level. A signal moves the work to the second level, if it is not
there yet. A discussion with no change to make gets no knowledge base. When the cause of a
signal is resolved, the rigor that it added stops. Each shift up and each lean back is a
record: what fired, who noticed, and what stopped.

Every ticket has a goal and a hypothesis, and that costs one statement. It must not cost more.
The first level has no knowledge base, and the agent does not wait for the human to approve
the statement. Ty's concern is on record, and use will judge it (see "Under trial"):

> "My concern is that this is going to add a slowdown since there will be more of a process for
> every change request. I'm hoping that the `orbit-kb` tool will help streamline that I
> guess." (Ty, 2026-11-11)

A ticket starts in words, and records start on a signal. A knowledge base exists to help find
the intent. When the intent is clear, there is nothing for it to find.

> "your typo example speaks clearly to me as a trivial change that would never need a KB to
> discover the intent." (Ty, 2026-11-11)

The step from words to records is rare, so it must be easy when it comes.

In the prompt: "The light path", "Signals", "One response".

#### 16. A formal language is a shared medium, and each one is a lens

The third level follows another rule than the second. Records start on a signal. A formal
statement needs no signal. One rule decides:

> **Formalize the smallest claim whose precision could change what the human or the agent does
> next.**

A formal language can enter at three moments. While forming the hypothesis: a definition
forces a choice that the words left open. While exploring interpretations: a query or a solver
finds the case on which two readings differ. While verifying the chosen claim: a proof or a
model check shows what follows from the agreed premises. To try to state a claim is itself a
way to find a disagreement, before either party has seen one. When one example settles the
question, the example is enough.

This is what `User Ability` buys. Because the human reads and writes the formal languages, a
formal statement is a place where the human and the agent work together, and not an artifact
that the agent files. The cost of the statement is real (premise 5), and it can come back: a
definition that was written once serves the next experiment (`Shifting`).

Each language is a lens. A claim about current behavior needs a test. A claim about rules and
limits fits a solver. A claim about the order of steps or about time fits a model checker. A
claim about every possible input needs a proof. Use the cheapest tool that can show the claim
false. A tool that does not fit the shape of the claim can prove something true and still lose
the intent.

Decide the shape of a claim by its meaning and its domain, not by its words. "Every" in a
sentence does not make a claim universal. A claim is universal when its inputs are infinite or
too many to check one by one. A universal claim, or a claim that the human asks to prove,
burns: it stays open until a proof or the human's waiver closes it.

Two kinds of formal tool help the human and the agent to see the intent. A proof language
(Lean) demands precision: a statement says exactly what it means, or it does not check. Lean
is not a modeling language: a Lean file holds definitions, and theorems about them. A logic
store that can be queried (Prolog, with SWI-Prolog as the engine) keeps the facts of the work
in one place. Its rules keep attention on what is still open.

> "We use one language because one language gives us one lens. we should use the right lens
> for the right problem depending on what we're trying to uncover." (Ty)

The work uses one formal language at a time. The knowledge base is the exception, because it
tracks the ticket itself. The aim is to stop a recursive shift up: a signal that fires while
one language is in use must not start a second one. Ty saw that failure in an earlier version
of the method. "At a time" is about writing. One language is written at a time, and a finished
artifact can be read as evidence beside it. A language leans back when its question has an
answer: its results are recorded, or it is dropped with a disclosure.

In the prompt: "Signals" (a claim that burns), "One response" (Formal language, One lens at a
time). Serves: `Parallax`, `Shifting`, `Annealers`.

#### 17. Speed comes from skipping work, never from hiding it

Do only the work that the request needs, and stop when it is done. Every skip of needed work
is visible. Only the human can skip it, and the skip has a due time. After that time, the work
comes back. Scope, budget and deadlines are decisions of the human. They are not a reason to
drop a claim or a check quietly.

In the prompt: "The orbit", "Delivery". Serves: `Throughput`.

### The method follows its own rules

#### 18. One principle, shown by examples

State one principle, and let examples show its meaning. A checklist of trigger words overfits:
it catches the words and misses the meaning. Examples show meaning, not strings to match. Give
each term one meaning. When two meanings share a word, the result is confusion.

A case: until 2026-11-23 "the hypothesis" meant the statement of the intent. It now means an
avenue, and the statement of the intent is the goal. Texts that kept both meanings beside each
other had to carry a note on how to read them.

In the prompt: "When the human says that it is wrong", "The goal" (the examples).

#### 19. The method is an attempt too

Improve the process as you improve a hypothesis. A change to the prompt must be worth having
even if no test of the prompt existed. It comes from a real failure, not from the shape of one
test case. Never put the answer to a test into the prompt. Tune on one set of cases, and
decide on a separate set that nobody tuned on. A rule needs a case that fails when the rule is
deleted. Decide on repeated runs, not on one run. When a case passes only if the prompt
describes that exact case, the limit of the model is a result, not a target.

Evals test whether agents can follow the rules of the prompt and of the `orbit` help. Use
tests whether the philosophy and the hypotheses pay off: Ty's reports from real work are the
test reports of the method. No one stakeholder is privileged: the method does not optimize for
one project. It also does not generalize so far that a stakeholder gets only trivial results.

The hypotheses of the project are held to the five elements too. Each row of "Under trial"
names a prediction and what would count against it. A row leaves the table on evidence: a
report, a comparison, or a count, with its date.

In the repository: `docs/REFINING.md`.

## A statement that can fail

Three definitions make "can fail" exact. Two are in Lean today. The link between them is
proposed here, in words, and it is not yet in Lean.

### A goal that is properly written

Ty's working sentence of 2026-11-11 was about the statement of the intent, which is now the
goal: "a properly written hypothesis is the weakest form of a statement that doesn't collapse
(it is provable) and doesn't generalize so far as to lose its intent." The Lean file
`docs/philosophy-orbit/2026-11-11/fable/Hypothesis.lean` makes it exact, with 68 theorems that
use no axiom. Ty ratified the definition on 2026-11-12. Its names still say "hypothesis": read
them as "the statement of the goal".

A **case** is one concrete behavior that the system can show and the human can judge. The
intent itself is not in the definition, because nobody holds it. The **judgments** of the
human stand in for it: what the human has said about cases so far.

A statement is **properly written**, for what the human has judged so far, when:

1. **It fits.** It rejects no case that the human wants, and it accepts no case that the human
   rejects.
2. **It can hold.** Some case meets its premises and its claims.
3. **It can fail.** Some case would show a build wrong. A statement that accepts every case
   has collapsed.
4. **No word can be removed.** Every premise and every claim is **held**: without it, the
   statement no longer fits, or it has collapsed.

"Held" is about the statement: the statement needs the word. It does not say that the human
agrees with what the word says. A premise is always held by a case that the human wants. A
claim is held because the human rejected a case that only this claim forbids (the human
**supports** it), or because the statement collapses without it (it is the **core** of the
attempt), or both. What the statement says about a case that nobody has judged is a **guess**.
The judgments do not test a guess. Only a judged case turns a guess into support. That is why
"is this case your intent?" is the question of the method.

| In plain words | Theorem |
|---|---|
| Each premise is held by a case that the human wants, and that the statement would reject without the premise. | `premise_held_by_wanted_case` |
| Each claim is held in one of two ways, or in both. | `claim_held_two_ways` |
| Held is not confirmed. With no judgment at all, a statement with one claim that can hold and can fail is properly written. | `proper_with_no_judgments` |
| The judgments do not test a guess. | `fits_ignores_unjudged` |
| Two statements disagree on a case. Ask the human about that case. The answer refutes exactly one of the two. | `one_case_decides` |
| The system shows a case that the statement rejects, and the human rejects it too. The statement stands, and the build is wrong. | `stay_in_build` |
| The human wants a case that the statement rejects. The statement must change. | `hypothesis_must_change` |
| A collapsed statement cannot fail. A premise that the system never meets has the same effect. | `collapsed_cannot_fail`, `unmet_premise_cannot_fail` |
| While the human keeps the earlier judgments, what was learned stays learned. | `falsifier_stays`, `proper_until_falsified` |
| The human changes a part of what they wanted. The narrower the part, the more is kept. When the part is empty, the new wish is a new ticket. | `narrower_keeps_more`, `keepsOutside_nothing` |

The definition does not confirm, and it is not unique: two statements can both be properly
written and disagree on a case that nobody judged (`proper_attempts_can_disagree`). Then show
that case to the human. "Weakest" cannot mean "accepts the most cases": that statement is the
bare list of the rejected cases, and it says nothing about a new case. To weaken a premise
makes a statement apply more widely. To weaken its conclusion makes it demand less. These are
two operations, and "remove words" is a habit of writing, not a measure of logical weakness.

The file holds two worked examples (loyalty points, dark mode). Ty does not expect to keep
them in the long term. The prompt carries the same two, in the new words.

### A hypothesis that is tempered

> "A hypothesis is tempered when one admissable case can demonstrate that its claim is false."
> (Ty)

Proposed reading. A case is **admissible** when three things are true of it:

1. it is inside the premises of the hypothesis;
2. a procedure can observe it: a check, or the human;
3. the claim rules it out.

So a hypothesis fails to be tempered in three ways, and each is a quiet failure.

- **Collapsed:** its claims rule out nothing. Point 3 of the definition above.
- **Vacuous:** its premises never occur, so no case is inside them
  (`unmet_premise_cannot_fail`).
- **Unobservable:** a case would defeat it, and nothing can observe that case. In the terms of
  the experiment below, every observation that is possible leaves the verdict at meets or at
  unresolved.

Tempered is about the form of refutation: one witness is enough. It does not say who wrote the
hypothesis, and it does not say that the hypothesis is true. A claim about a rate (`Human-first`
over many tasks) is tempered only when its assessment rule says which result of which
comparison counts against it.

"Properly written" and "tempered" meet at point 3, and they have different witnesses. The
statement of a goal can fail on a case that the human judges. A hypothesis can fail on a case
that an experiment observes, or on a case that the human judges not wanted while every claim
meets.

### An experiment and its verdict

The Lean file `kb/proofs/scientific_method/ScientificMethod.lean` is the definition from
Astra's handoff of 2026-11-18. The Lean kernel accepts it, and no theorem uses an axiom of its
own. The verdict rule of the tool follows its definition `Warrants`.

```lean
structure Model (World Outcome : Type) where
  conjecture : World → Prop
  premises : World → Prop
  outcome : World → Outcome
  predicted : Outcome → Prop
  derive : ∀ w, conjecture w → premises w → predicted (outcome w)

structure Observation (World Outcome : Type) (outcome : World → Outcome) where
  procedure : String
  knownWhenConjectureChosen : String
  knownWhenRuleChosen : String
  measurementPremises : World → Prop
  recorded : World → Prop
  compatible : Outcome → Prop
  interpret : ∀ w, recorded w → measurementPremises w → compatible (outcome w)
  possible : ∃ x, compatible x

inductive Verdict where
  | meets | conflicts | unresolved

/-- Each conclusion has its own proof obligation. Uncertainty has witnesses. -/
def Warrants {α : Type} (predicted compatible : α → Prop) : Verdict → Prop
  | .meets => ∀ x, compatible x → predicted x
  | .conflicts => ∀ x, compatible x → ¬ predicted x
  | .unresolved => (∃ x, compatible x ∧ predicted x) ∧
                   (∃ x, compatible x ∧ ¬ predicted x)
```

`derive` is the first inference: the prediction follows from the conjecture and its premises.
`interpret` is the second: a reading and the measurement premises restrict the outcomes that
could have produced it.

| In plain words | Theorem |
|---|---|
| For an observation that is possible, exactly one verdict is warranted. | `unique_verdict` |
| A conflict rejects the conjecture, its premises and the measurement premises together. It does not say which. | `conflict_rejects_joint` |
| A verdict that meets shows the prediction for this run, if the measurement premises hold. It shows no more. | `agreement_establishes_run` |
| A false claim can have a true prediction. | the `example` after it |
| The timer: 60.0 meets, 61.1 is unresolved, 61.5 conflicts. | `Timer.reading_600`, `reading_611`, `reading_615` |
| One late run, with its premises, refutes the claim about every run. | `Timer.late_run_refutes_universal` |
| When two models give the selected event the same likelihood, the comparison favors neither. | `Statistical.equal_likelihood_no_preference` |
| A revision adds an entry, and the earlier record stays. | `revision_preserves_record` |

What the definitions do not decide:

- **They are about their definitions.** A check of the Lean file shows the encoded statements
  under their premises. Whether Sagittarius improves delivery needs observations of people
  doing work.
- **The assessment rule may carry too much.** A rule such as "accept whichever explanation
  fits best" leaves two reviewers unable to say what counted as a better fit. The test: can
  one reviewer reconstruct the conclusion from the record, and can another name a specific
  reason to dispute it?
- **The agent chooses what a case and an outcome are,** so the human must read them
  (principle 8).
- **The link from "tempered" to these definitions is words only.** A theorem that a tempered
  hypothesis has a possible observation that warrants a conflict is not written.

## Where Sagittarius sits

Sagittarius is an extension of the harness, between the human-agent interface and the software
factory. The harness is the interface between the human and the agent. The software factory is
the interface between the agent and the project. Sagittarius fills the gap between them as an
inference, reasoning and knowledge-graph layer. It is opinionated: it puts everything into one
shape.

The audience is people who work with formal methods and AI (`User Ability`). There is no
edition for other users.

Sagittarius runs in two interfaces.

1. **Sagittarius:** the system prompt and `orbit`. It carries this philosophy everywhere that
   it goes. The System 1 hook belongs here, not with the hub: it goes where the prompt goes.
   For now the hook is recommended, not required.
2. **MindHole:** the hub. Sagittarius provides a hub as a kind of pinned workspace. Each
   MindHole can run its own version, with its own `orbit` and its own changes for that
   workspace. It is for power-work, where throughput, explainability and automation are
   central.

A MindHole needs the tool: `orbit` is the door to every store of a hub (Ty, 2026-11-23). The
prompt does not need a hub. So the prompt must be true alone: with no hub, with another
version of `orbit`, and when System 1 is silent.

The prompt holds the philosophy in words that change how a model acts. That is what a session
needs before it reads any help: the orbit, the ticket, the light path, and the signals. The
tool holds the procedure and its syntax. A session on the light path never runs `orbit`, so it
never reads the help.

Three things have a semantic version, and each names its own. Then a report from use can say
what it ran.

- Sagittarius (the prompt, `orbit`, and the System 1 hook) is one release with one version.
  The last line of the prompt names it.
- This philosophy has its own version, in its first lines. It is installed nowhere, and it
  moves ahead of the build, so it does not share a number with a release.
- Each MindHole records the version of the kit that it came from.

`CHANGELOG.md` says what a change of each number means.

## Under trial

Use has not yet judged these positions. No comparison of any of them has run.

### The hypotheses of the project

Each row gives the prediction, what would count against it, and what a comparison must fix
before it runs. The third column comes from Astra's discussion of 2026-11-18. It is a set of
proposals for the inquiry.

| Hypothesis | What it predicts | What would count against it | Fix before the comparison |
|---|---|---|---|
| `Expert Favoring` | The same agent gets closer to the goal with a human who understands the wanted result more deeply. | Results that are no closer when the human's understanding is deeper. | Capture the human's understanding at the start, before any result is seen. |
| `Sagittarius` | Against a comparable Agile method: fewer errors and divergences at the delivery. | A comparable method that delivers with no more of them, at no more cost. | Which methods are "comparable". For "potential falsifiers": the claim, the admissible cases, and the stage of the work at which they are counted. A good first comparison leaves the other comparators open. |
| `Annealers` | Agents with formal languages and proper context reach a tempered hypothesis at less cost than without one of the three. | The same hypothesis, as fast, with one of the three removed. | The comparison, and the measure of cost. Count the human's reading time. |
| `Anthropocentrism` | When the human follows the method, the goal is reached more often. | No difference between tickets where the human did and did not. | The observable act: for example, the human judges a case before they see the agent's result. |
| `Human-first` | Earlier exposure of a misunderstanding, and a result that the human judges closer. Both. | A paired comparison in which the ordinary request exposes the misunderstanding no later, or gives a result that the human judges no less close. | One task with a documented misunderstanding at the start; two openings; the same snapshot, model, tools and budget; the event that counts as exposure; the clock starts at the request; a blind judgment if feasible. Time spent drafting is recorded apart. One pair speaks to that task only. |
| `Throughput` | Free exploration delivers faster, with no loss of quality. | The same quality, as fast, with one fixed hypothesis; or faster with a loss that the human names. | Record the human's review time and the quality of the delivery beside the elapsed time. |
| `Parallax` | In a dispute about a non-trivial claim, a formal language finds the case that tells two readings apart sooner than plain language. | A dispute in which the formal statement finds that case later. | Whether two readings that agree on every case are eligible. |
| `Shifting` | For evidence that rests only on what is given, a shared formal language lowers the total time, most of all when the experiment repeats. | The cost of the encoding does not come back over the repeats. | Count the first modeling and the human's review. |

### Positions of this text

| Position | What would show it wrong |
|---|---|
| A ticket is a goal with hypotheses, claims and experiments. | A conflict that cannot be placed on the build, the measurement, a premise or a hypothesis; or a ticket that closes while the human judges that its goal is not satisfied. |
| Every ticket has a goal and a hypothesis: the goal wide, both stated, and not asked. The light path gains no step. | Ty reports that plain requests got slower, or that "Goal (mine): ... Hypothesis (mine): ..." reads as a ritual. |
| Premises ride beside every goal and hypothesis. | Ty skips them, or reports them as noise. |
| A defeated hypothesis goes back to discovery; a conflict located in the build stays in build; a corrected goal is recorded by the party that hears it. | Returns to discovery that only repeat what build could have said, or a goal recorded in build that is later found to have changed what the ticket was for. |
| Every verdict leaves the five elements behind. | Reviewers do not use them, or a judgment that was defensible could not be put into them. |
| Unresolved is a third verdict. | Runs that could decide are filed as unresolved to avoid a conflict. |
| The rule and the expectation are fixed before the result is seen. | Agents write them after the result, or the line becomes a ritual. |
| Records start on a signal. A formal statement needs none: the smallest claim whose precision could change the next step. | Formal statements that changed no decision, often enough that Ty reports them as noise; or claims that needed one and stayed in words, and the same correction came back. |
| The formal statement goes to the human with the plain claim. | Ty reports it as noise, or still does not see it. |
| The definition of a properly written goal, with "held" and "guess" as two judgments; and the three ways in which a hypothesis is not tempered. | A statement that the definition accepts and Ty calls badly written, or the reverse. |
| The oscillation as one step: show the case just past the boundary, and ask. | The questions are too many, or too strange to answer. |
| One response for every signal. | A signal appears for which the right response has another shape. |
| System 1 is recommended, not required. | Sessions without it miss signals that sessions with it catch. Then it is required. |
| When System 1 and the agent disagree, it goes to the human, or to a formalism, or both. | System 1 names so many false signals that these lines become noise. |
| With the active hypothesis in view, System 1 catches a change of the success criterion before the delivery, with no more needless interruptions. | Replays of past conversations in which it misses the drift, or reports a revision that both parties knew about. |
| Every item of work leads up to a goal, and one door reads every store. | Orphans that the record does not report, or work that had a purpose and could not be given a place. |
| Sound Basis. | Reported conflicts that are noise, or a silent change that no conflict reported. |
| Liked, then changed: narrow down what stays and what changes. | The narrowing costs more than the change, or a part that Ty liked is lost anyway. |
| The formal artifacts vote by readiness, with a knowledge base and without one. | A discovery that was not ready gets a GO that proves right, or a ready one proves wrong, often enough to matter. |
| A rule of the prompt needs a case that fails when the rule is deleted. | A rule that clearly matters, for which no such case can be written. |

This text is the frontier, and the build is behind it in places. Each gap is work for the
tools. None is an open question of this text.

## How to judge a change

Ask these questions about a proposed change to the prompt, the tool, or the hub.

1. Which goal does it support? Which hypothesis, premise or principle does it serve? Does it
   break one?
2. Does it let a party grade its own work, or its own noticing?
3. Does it build one artifact from another artifact, and not from the source?
4. Can a failure that it adds be quiet? Can a missing answer look like a "no", or an
   unresolved verdict like a pass?
5. Can a reviewer reconstruct each verdict that it produces: the claim, the premises, the
   expectation, the observation, the rule?
6. Does it add rigor before a signal, or keep rigor after its cause is resolved?
7. Does it add a second shape of response, where one shape is enough?
8. Does it let work be skipped, or existing behavior be changed, with no visible record?
9. Does the human see the statement that the machine checked? Is what the human said recorded
   as the human's?
10. Does it add a word list, or the answer to a test, where one principle and an example are
    enough? Does it give a second meaning to a word?
11. Is it still true with no hub, with another version of `orbit`, and when System 1 is
    silent?

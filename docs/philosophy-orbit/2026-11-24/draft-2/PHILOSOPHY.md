# The philosophy of Sagittarius

> Philosophy 3.0.0, second draft: the outer bounds. Proposed on 2026-11-24, for Ty's review.
> Ty asked for a draft pushed "to the outer bounds" so that he can "oscillate it back". So this
> text goes past Ty's words on purpose. Its last section but one lists each place where it
> does, with the way back. Words in quote marks with "(Ty)" are word for word. The first draft
> is in `docs/philosophy-orbit/2026-11-24/draft-1/`.

Sagittarius is the scientific method, pointed at a thing that science does not usually study:
what one person wants.

This document is written in its own form. It has a goal, premises, and hypotheses. Each
hypothesis says what it predicts and what would defeat it. It keeps a notebook of what was
seen, and of what was defeated. Three texts share the work:

- **This document is the hypothesis** of the project: what Ty believes, and why.
- **The prompt is the procedure:** [`prompt/SAGITTARIUS.md`](../prompt/SAGITTARIUS.md) says
  how an agent acts, so that the hypothesis gets a fair test. `orbit help` holds the procedure
  of the tool.
- **Use is the experiment.** Ty's reports from real work are its observations.

> "My philosophies are radically dynamic most of the time while I search for my central
> intent." (Ty, 2026-11-11)

So this document is the frontier of the project, and it moves. When use shows that a belief
is wrong, the belief is marked as defeated, with the case that defeated it, and the project
follows. The document is installed nowhere.

> "I think the philosophy should not be installed anywhere. It should just be reflected into
> the system prompt. and guide the sagittarius and mindhole project trajectories over time."
> (Ty, 2026-11-11)

Three families of words run through it. The **sky** gives the words for what cannot be seen
and how we look: the center, the orbit, the parallax. The **forge** gives the words for how a
statement gets its strength: soft, brittle, tempered. The **lab** gives the words for how a
test is run and read: instrument, control, verdict.

## The phenomenon

Sagittarius A* is the black hole at the center of our galaxy. Nobody found it by looking at
it. Astronomers tracked the stars that orbit it, and the orbits showed where it is and how
heavy it is. That is how science studies a thing that it cannot see: it says what the thing
would do to something visible, and then it looks.

The intent of a piece of work is such a thing.

- **The human owns it.** The human decides that it exists, and no tool helps with that.
- **Nobody holds all of it,** and the human is no exception.
- **It moves.** It shifts, or the human understands it better.
- **It changes when it is observed.** People find what they want when they see results. A
  result that is shown to the human moves the thing that it measures. So each measurement is
  also a step.

> "_The intent_ could be classified as its own role, but it is not something that is literally
> sentient. It's just something that seems to _act_ sentient because it is constantly shifting.
> But, truly the human sometimes does not actually know what they're chasing. [...] These
> tools and all of sagittarius and the mindhole are meant to help the human monotonically
> (ideally) discover that intent over time." (Ty, 2026-11-11)

What can be seen is small: what the human says about one concrete case. Each such judgment is
a star in orbit. One judgment shows little. Many of them, kept, show where the center is.

In astronomy the center turned out not to be us. In this work it is. The center is what a
human wants, and everything else orbits it.

### The bet

Humans and agents will always misalign. Models get better at guessing what a person wants, but
they do not have what is in that person's head. The person must still explain, and errors come
in with the explanation. Difficulty is a weak guide: what is difficult for a model today is
easy for a model next year. Misalignment stays. So Sagittarius aims at alignment on intent,
not at the difficulty of the task.

> "I'm making the bet that even with ASI, humans will still need to explain what they want, and
> that will continue to be a point of friction." (Ty)

So every statement of the intent is an attempt: a request, a goal as someone wrote it, a
claim, an example, a test, a proof, the code. Each attempt can be wrong. The work is to find
where.

## The goal

> "Agents will deliver results that the human wants faster and with greater accuracy and less
> rework." (Ty)

That sentence is the goal of the project. Every part of the project supports it, or it has no
purpose that someone can test.

The goal has three measures, and they pull against each other. "Faster" is easy with less
accuracy. "Greater accuracy" is easy with more process. "Less rework" joins the two: rework is
the price of a result that was fast and wrong.

A method has an aim, rules, and values that judge the rules. The goal is the aim. The rest of
this document gives the rules. Four values judge them:

- **Clear:** the request has one reading, and the human and the agent share it.
- **Accurate:** the result does what that reading means. No less, and no more.
- **Honest:** what was guessed, what was not tested, and what went wrong are in view.
- **Fast:** attention goes only to work that could change what happens next.

A rule that improves none of them does not belong. The hypotheses of the project (below) say
that this method serves these values better than the alternatives. That is a claim about the
method, and use tests it.

## The instruments

Nobody can look at the intent. But three questions about a piece of work have an answer that
someone can look at. Each question has one instrument.

| The question | Its instrument | One reading | What the instrument cannot see |
|---|---|---|---|
| **Is this wanted?** | The human. | A judgment of one concrete case: wanted, not wanted, or not decided. | A case that nobody showed. What the human will want after they see the result. |
| **Does this happen?** | The system: the running code, a test, a reproduction. | A verdict on one claim: meets, conflicts, or unresolved. | A case that nobody ran. Whether the behavior is wanted. |
| **Does this follow?** | The machine: a query, a solver, a model checker, the Lean kernel. | Follows, does not follow (with a counterexample), or unknown. | Whether the statement that it checked is the statement that was meant. Whether the definitions match the code. |

Engineers know the first two questions by other names. "Does it happen?" and "does it follow?"
are verification: did we build it right? "Is it wanted?" is validation: did we build the
right thing?

**The agent is not an instrument.** The agent makes conjectures and runs experiments. Its
goal as written, its hypothesis, its build, its summary, and its "this looks right" are all
conjectures. Its confidence is not a reading. A second agent with fresh eyes is not an
instrument either: it is a second experimenter. Its worth is that it starts from the source,
and not from the first agent's report.

**System 1 is a fourth instrument, and it points at the experimenter.** Its question is: is
the experimenter still doing what was said? It is a small model outside the agent that reads
each message of the human, with the record of the ticket beside it.

> "We can't make an algorithm that mechanically detects these things and we can't let a model
> grade themselves on whether they are diverting. something outside needs to help. The system 1
> model's main purpose is to help with detection and classification." (Ty, 2026-11-11)

System 1 helps to detect: a divergence, a change of plan, effort, how many requests a message
holds, a prediction that a delivery dropped. The agent responds. The human can overrule both.

> "Yeah if S1 and the agent disagree, then it needs to either go to some kind of formalism, or
> it needs to come to the human, or both." (Ty, 2026-11-11)

Three rules follow from the table.

### 1. Take each question to its instrument

Most quiet failures are an answer from the wrong instrument.

- Tests pass, so "this is what you wanted". The system answered the human's question.
- The human approved, so "it works". The human answered the system's question.
- The proof checks, so "the code is right". The machine answered for code that it never read.
- The agent is sure. Nobody answered.

A vote cannot make a failed check pass. A proof cannot choose what the human ought to want. A
judgment of the human never turns a verdict into meets, and a verdict that meets does not
choose what the human wants.

A dispute says which instrument it needs. "We agree on the inputs and the rule, and we predict
different outputs" is a question for the machine or the system. "We agree on the output, and
the human has not decided if they want it" is a question for the human, and no proof settles
it.

### 2. Every instrument has three readings, and "cannot tell" is never "yes"

Each instrument can say yes, no, or cannot tell. A verdict can be unresolved. A human can be
undecided. A solver can answer unknown. System 1 can be unsure, or have no view. A tool can
fail to compute an answer.

"Cannot tell" is a reading. It is not a weak yes, and it is not a no. An unresolved verdict
fulfils nothing. A human who has not answered has not approved. A hook that printed nothing
saw nothing. A search that found no counterexample has not shown that there is none.

> "Silence, negative space, emptiness, and vacuity are often the predators of clarity,
> accuracy, and honesty." (Ty)

This gives the **quiet failure** its definition: a "cannot tell" that was read as a "yes", or
a question that never reached its instrument. A check that passes while the result is wrong, a
claim that nobody tested, an empty answer, a theorem that cannot fail, a long list that got
"approve all", a signal that someone saw and did not say: each is one of the two.

### 3. Two readings give depth, if they are independent

One reading from one position is flat. Two positions find a depth that one cannot. Astronomers
call the difference between two positions a parallax.

Where two readings differ, there is a **divergence**. A divergence shows that two views do not
line up. It does not say why. An attempt can be wrong. The intent can have moved since one of
the views was made. Or the two views are about different cases. To get more specific at that
point says which. Each divergence that is settled leaves less room for the intent to be
somewhere else.

A divergence is good news. It is loud, so someone can fix it. It accuses nobody: the intent
can have moved, and then the earlier statement was right when it was made. Record it.

The depth is real only when the two readings do not share a source. Two readings from one
source are one reading.

- A build and a test that were written from the same misreading agree, and the agreement says
  nothing. So the check comes from the request, not from the build.
- A reviewer who read the builder's report sees what the builder saw. So a reviewer reads the
  request and the system.
- An explorer that was handed a conclusion returns it confirmed. So an explorer gets the goal
  and the evidence.
- Ten checks from one reading are one check. Variety counts, not number.
- A statement that was written from another statement is a translation of it. So each
  statement comes from the source: the human's words and the current system.

The current system is a source for what exists. It is not a source for what should exist.

The machine is impartial about what follows from a statement. It is not impartial about which
statement was written, because an agent chose it. So the human reads the statement. Show the
human concrete examples and results first, not test logs. When the work has shifted up, the
human, the agent and the CPU all use the formal language as the shared substrate, and the
human reads, reviews and understands it, so write it to be read. And show it, while there is
still something to decide: the plain claim and its formal statement go to the human together.

## The logic

### Three inferences, and who makes each

An inquiry makes three kinds of inference. Each has a party that is good at it, and a guard.

| Inference | What it does | Who is good at it | Its guard |
|---|---|---|---|
| **Conjecture** | From what was seen to a goal as written, and to a hypothesis. No rule produces it. | The human, who knows what would satisfy them. The agent, who can make many candidates fast. | The human goes first. An agent's candidate is a guess. Each hypothesis has a rival. Words are removed. |
| **Prediction** | From a hypothesis and its premises to a claim: what must be observable. | The machine. A deduction is the same each time it is run. | A formal statement that the human reads. |
| **Test** | From an observation to a verdict. | The system, under a rule that was fixed before the look. | The seal and the control. |

There is no logic of conjecture. A scientist may use any resource to imagine an explanation.
So the method leaves this step free, and puts its rules on the other two.

An agent's conjectures have a known weakness. One benchmark (Sun and Saparov, 2025) found that
language models often give hypotheses that explain every observation and are not the simplest:
they add hypotheses that are not needed, they repeat an observation as its own explanation,
and they name things that are not in the world they were given. The result is about one
synthetic benchmark, and this text leans on it only for a direction: an agent-written
hypothesis looks valid before it is lean. Four habits answer the four errors.

- Remove words until one more removal empties the statement. This answers the hypothesis that
  is not needed.
- Keep the goal apart from the finding. This answers the observation that explains itself.
- Touch the system before you state a cause. This answers the thing that is not there.
- Show the case just inside the edge and the case just outside it. This answers a rule that
  points the wrong way.

The human's authority over what counts as satisfactory does not rest on that benchmark. It
rests on ownership: only the human can read the first instrument.

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
- **Unresolved:** some compatible outcomes are predicted and some are not.

The timer, with a tolerance of 59 to 61 seconds and a clock error of at most 0.2 seconds: a
reading of 60.0 meets. A reading of 61.5 conflicts. A reading of 61.1 is unresolved: a timely
ring and a late ring both fit it.

### What a verdict can carry

**A match does not show the hypothesis.** A false claim can predict a true result. A verdict
that meets shows the claim on that run. It is corroboration, and not truth.

**A conflict rejects a conjunction.** It rejects the hypothesis, its premises, the measurement
premises and the build taken together. It does not say which. So a conflict is located before
anything is reopened (see "The ticket").

**Severity.** A test is evidence only as far as it could have failed. The question for every
result is: would this have come out differently if I were wrong?

- The **control** answers it for a check of a change: the check fails before the change. That
  run shows that the experiment can tell. A check that has never failed shows nothing.
- A check that passed from the start has no control. Then break the rule once on purpose and
  see it fail, or say that nobody has seen it fail.
- The **baseline** is the other control: what was true before the change, so that a later
  failure can be placed.
- A model is **calibrated** on both sides: a real case where the system fails, and a real
  case where it passes. The match goes from the system to the model, because a checker picks
  its own path. A match of the outcome does not show the cause.

**The seal.** The prediction and the rule for reading it are fixed before the look. To seal a
statement is to fix it before the observation that tests it. A hypothesis that was written
after the result is fitted to the result. So is a check. Three forms of the same error:

- to state the hypothesis after the result is known;
- to choose among reasonable ways to read a result after seeing which one gives the wanted
  answer;
- to run a check again until it passes, and count the last run.

The seal divides work into two kinds. **Exploring is free.** An agent may poke at the system,
try an idea, or read a trace, with no ceremony at all. What it finds is a finding: it can
start a hypothesis. **Confirming is sealed.** A verdict that fulfils a claim comes from a
prediction that was stated first, about a case that was not yet seen. Record what was known
when the hypothesis and the rule were chosen.

**The same scrutiny for a pass as for a fail.** People debug a result that contradicts them,
and accept one that agrees. Agents do the same. A pass gets the question that a fail gets.

**The record is appended.** A revision adds an entry, and the earlier entry stays, so that a
reviewer can see which finding changed the conclusion. The failures stay too: a defeated
hypothesis, a run that conflicted, an avenue that was dropped. Nobody learns from data that
was never kept. And the report is drawn from the record. A report that is written from memory
after the work is a tidy story of the work, and the order of events is the first thing that it
loses.

**A result that varies needs its rule first.** An agent run, a flaky test and a sample are not
a timer. One run speaks to that run. A claim about a rate needs a design that says how many
runs, and what count meets.

**"Did not find" is not "is not there".** A defect that did not reproduce may still exist:
say what was tried. No counterexample in a bounded search is not "always". "I tried three
ways" is not "it cannot be done": a claim of impossibility is universal, and it needs grounds
that cover every permitted approach.

### How much rigor

Two things raise the rigor of a piece of work, and neither is its size.

> "size determines nothing. Clarity does." (Ty, 2026-11-11)

**Doubt.** Peirce wrote that "the action of thought is excited by the irritation of doubt,
and ceases when belief is attained". He meant real doubt, born of a surprise or a
disagreement, and not doubt on paper. The signals (below) are real doubt. Rigor starts at a
signal, and it stops when the cause of the signal is resolved.

**Stakes.** How sure is sure enough depends on what a mistake costs. That is a judgment of
value, so it is the human's. A change to data, to a public interface, to security or to money,
or a change that is hard to undo, waits for the human.

And one thing limits it. **An experiment is worth running only when one of its results would
change what happens next.** This is what "fast" means. It is also the rule for every formal
statement (see "The orbit").

### This reading is a conjecture too

There is no single scientific method, and the lack of one is a reason that science is
reliable. The textbook list of five steps is a legend. What marks science, on one modern
account, is ordinary care made more systematic: more care to exclude other explanations, to
find sources of error, and to connect one piece of knowledge to the next.

So this text does not claim "the" scientific method. It claims one reading of it, for one
phenomenon. A counterexample to the reading would be a defensible judgment whose grounds
cannot be put into the five elements, or an assessment that has all five and still licenses a
conclusion stronger than its evidence. One open point is whether "assessment rule" carries too
much: "accept whichever fits best" is a rule that two reviewers cannot apply alike.

## The ticket

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

This draft proposes seven more words for the vocabulary. They are not in the block.

- An **instrument** is a party that can answer one kind of question by looking: the human, the
  system, or the machine.
- A **judgment** is the human's reading of one concrete case against the goal: wanted, not
  wanted, or not decided.
- A **distinguishing case** is a case on which two statements predict different things.
- The **rival** of a hypothesis is another hypothesis that fits what was seen so far.
- A **control** is a run whose result is known in advance. It shows that an experiment can
  tell.
- To **seal** a statement is to fix it before the observation that tests it.
- The **residual** of a result is what could still show it wrong, and that nobody tested.

The layers differ in who can show them wrong, and in what happens then.

| Layer | Who shows it wrong | What happens then |
|---|---|---|
| Goal | Only the human, on a concrete case: "is this case your intent?" | Its owner changes it or drops it. A goal is never defeated. |
| Hypothesis | One admissible case: a located conflict, or a case that the human rejects while every claim meets. | It is defeated. The case stays on it, and a new one is tempered. |
| Claim | An experiment whose observation is what the claim rules out. | A conflict, which is located before anything is reopened. |
| Experiment | A reviewer who shows that its procedure or its measurement premises are wrong. | Its verdict becomes unresolved. It is repaired and run again. |

### Because, and unless

Every record has two links. One goes up: what it is for. One goes down: what would undo it.

**Because.** An experiment is there because of its claim. A claim is there because of its
hypothesis. A hypothesis is there because of its goal. The goal of a ticket is there because
of a goal of the project, and the goal of the project is at the top.

> "The project KB holds the larger research goals and hypotheses. Everything should tie back
> into the project goals. Thus, the scientific method is able to offer us a kind of
> hierarchical experiment with a high-level research goal that all other goals must be able
> to support without contradicting or falsifying." (Ty, 2026-11-23)

A record with nothing above it is an **orphan**. A task, a thread, or a handoff can be one.

> "I'm getting a lot of orphaned tasks, threads, and handoffs right now. I want everything to
> have a purpose that leads back up toward the over-arching project goal. Prolog was made for
> a structure like this." (Ty, 2026-11-23)

**Unless.** A goal holds unless its premises fail or its owner changes it. A hypothesis holds
unless its defeating case shows. A verdict holds unless the state that it observed changes. A
record that nothing could undo is **empty**: it says nothing.

With both links, the record can reason.

> "That seems to be acting more like a database than a KB. I'm thinking we need to find a way
> to encourage more reasoning through these deterministic patterns so that all of our
> processes have a slightly more linear and retractable trajectory toward the intent. every
> spec and ticket we work through should flow logically and narrow appropriately."
> (Ty, 2026-11-23)

A database stores what happened. A knowledge base says what follows from it: what is open,
what is stale, what is an orphan, and what reopens when a premise falls. That last one is the
"retractable" part. Each step that narrows the work rests on something, so the step can be
taken back when that something fails, and only that step. One command, `orbit`, is the door to
every store, so that one set of rules reads all of them.

### Making and spending potential falsifiers

Popper called the cases that a theory forbids its potential falsifiers. The more of them a
hypothesis has, the more it says. A hypothesis with none says nothing.

Ty's project hypothesis says that the method will "reduce potential falsifiers, errors, and
divergences". This text reads the two uses together. **Tempering makes potential falsifiers.
Testing spends them.** A tempered hypothesis has many places where an experiment can strike.
Each strike that the result survives removes one way in which the result could still be wrong.
What is left at the delivery is the residual: the guesses that nobody confirmed, and the cases
that no check covered.

So more counterexamples during the work go with fewer failures after the delivery. A count of
falsifiers means nothing until it names the claim, the admissible cases, and the stage of the
work.

### A conflict is located before anything is reopened

A conflict is in one of four places: the build, the measurement, a premise, or the hypothesis.
The party that built keeps a conflict in the build. A location outside the build counts only
when a party that did not build confirms it. A conflict in the build is fixed there, and
nobody asks the human again about what they accepted.

A hypothesis that a located conflict defeats, or that a case which the human judges not wanted
defeats while every claim meets, goes back to discovery.

> "Following the scientific method, as I understand it, means that the entire experiment
> should be re-evaluated if a hypothesis is falsified." (Ty, 2026-11-23)

Discovery re-evaluates the goal, the premises and the measurement, and tempers a new
hypothesis. The case stays on the old one, and nobody edits the old one. To add an exception
to a hypothesis so that it survives one case is a rescue. It is allowed only as a new
hypothesis, and only if the new one predicts something that the old one did not.

When the human corrects the goal and says what it changes to ("only on this page"), the party
that hears it records the new goal in the human's words, and carries over what still counts.

An example. Goal: "A replayed import leaves the member records as one clean run would."
Hypothesis: "Skipping each record ID that was seen before makes a replay safe."

- A replay leaves a duplicate, because of a bug in the comparison of IDs. The conflict is in
  the build.
- A correction arrives under a seen ID and is discarded, and the build does what the
  hypothesis says. The conflict is in the hypothesis.
- Every check meets. The human sees "the corrected address of member 12 was dropped" and
  says: not wanted. The case defeats the hypothesis. No check fails, and the build is not
  wrong. To deliver exactly what a rule says can still defeat the goal.

### What exists is presumed to be wanted

> "Existing behavior is presumed to be preserved. A claim in the specification can identify
> behavior to change. A demonstrated conflict opens the affected behavior for review."
> (Ty, `Sound Basis`)

A ticket changes only the behavior that one of its claims names. When a change breaks other
behavior, the agent does not edit the old test and does not make the change silently. It
reports the conflict, and the report opens that behavior for review. The premise is about
preservation, not about truth. It does not say that the present behavior is right. It says
that nobody asked to change it.

### Two orbits, one hot and one cold

Work has two levels. **Discovery** makes a problem clear: research and specify. **Build**
delivers a solution: build and verify. Each has a phase that makes and a phase that judges,
and the split marks a handoff.

Discovery is hot. Statements are wide and soft, alternatives are cheap, and most looks at the
system are exploration. Build is cold. Statements are narrow and hard, and every verdict is
sealed. A defeated hypothesis reheats the ticket: it goes back to discovery.

The vote is the door between them. Discovery ends with GO, NO-GO, or HOLD, and a GO registers
the experiment: the goal, the hypotheses, the claims, their examples and the reproduction are
fixed as the ticket before the build looks at any result. The human has 0.49 of the vote, the
agent 0.24, the formal artifacts 0.24, and a win needs more than 0.5: the human and at least
one other. The artifacts vote by readiness. "Any test of any kind counts as an artifact." (Ty,
2026-11-12) The agent seals its vote before the human votes. A consensus is not a truth, and
HOLD is a valid result.

New work is a divergence too.

> "in my mind, new work _is_ a misalignment or a divergence because the intent of the human
> has either shifted or become better understood by the human themselves." (Ty, 2026-11-11)

A request says that the intent differs from what the system does now, or from what the human
said before. Discovery gives unclear new work a place to start. Clear new work goes straight
to build.

### What a lap learns, the next lap keeps

Agents forget. Sessions end, contexts are compacted, and work moves between agents. So the
state of the work lives in a record that a person or an agent can query.

A change of plan does not erase an earlier outcome that the human still wants. A new claim
supersedes an old one. It does not overwrite it. An old guarantee does not carry over to a new
design without new evidence.

> If I "liked" the result but want to change it, then the agent and sagittarius need to narrow
> down what was liked and what was disliked. If the change stacks on top of the previous
> request without modifying the previous work, then it just counts as a new ticket with its
> own spec KB. (Ty, 2026-11-11)

A new ticket does not close an old one. When nothing says if the agent misread the request or
the intent moved, the agent does not guess: it says so, and treats it as a divergence. An
outcome that must outlive its ticket gets a home that outlives it: a rule of the project, with
a test beside it. The agent proposes it, and a human ratifies it.

## The forge

> "A hypothesis is tempered when one admissable case can demonstrate that its claim is false."
> (Ty)

Steel that was never hardened bends under any load. Steel that was hardened and not tempered
is strong and shatters at the first knock. Tempered steel breaks only under the load that it
was made to refuse. This text reads Ty's word with both sides.

| | What it does | A goal | A hypothesis |
|---|---|---|---|
| **Soft** | It gives way everywhere. No case can break it. It says too little. | "Points depend on something other than the purchase." | "Better handling of duplicates makes a replay safe." |
| **Brittle** | It breaks on a case that should not matter. It says more than anyone gave it. | "The tier is read from a cache that loads once." | "Skipping record IDs that are held in an in-memory set makes a replay safe." |
| **Tempered** | It breaks only where the intent breaks. | "The amount of a purchase and the member's tier on that day decide its points." | "Skipping only a record that equals the stored one makes a replay safe. It is false if a corrected record is discarded." |

A case is **admissible** when four things are true of it: it is inside the premises, an
instrument can observe it, the claim rules it out, and it matters: when it occurs, the goal is
not reached. A hypothesis is tempered when it has one such case. It is fully tempered when it
has no other kind: every case that can defeat it is admissible.

A statement is soft in three ways, and each is a quiet failure. It is **collapsed** when its
claims rule out nothing. It is **vacuous** when its premises never occur. It is
**unobservable** when a case would defeat it and no instrument can see that case.

### Anneal, quench, temper

Three moves shape a statement, and they are not in a fixed order.

- **Anneal:** soften it and widen it. Remove a word. Drop a premise that nobody gave. This is
  done in plain words, with the human, while the shape can still change.
- **Quench:** fix its shape in a formal language, fast and hard. A definition forces each
  choice that the words left open, and the cracks show at once.
- **Temper:** bring it back from brittle. Take the case just inside the edge and the case
  just outside it to the instrument, and move the edge until the statement breaks only where
  it should.

Hypotheses, premises, and claims err soft. Experiment just past the boundary of too brittle or
too soft, then formalize. The formalism then localizes the definition. Annealing in the formal
languages brings out the tempered position. Oscillation is an intentional heuristic.

A statement that is quenched too early keeps a wrong shape, and the precision hides it. One
project proved a redesign in the wrong language, and the proof held while an outcome about
timing was lost (see "The notebook"). A statement that is never quenched stays soft. The rule
for when to quench is in "The orbit": the smallest claim whose precision could change the next
step.

Ty's supporting hypothesis `Annealers` names what makes the cycle cheap: agents, who can make
and test many variations fast; formal languages, which are the quench; and proper context,
which is the record of what was already tried.

### How a goal is written

The goal follows a value of the Mathlib community: weak hypotheses, strong conclusions.

- **Assume little.** A cause, a mechanism, or a fix in the goal adds meaning that the human
  did not give. Each is an avenue, and an avenue belongs in a hypothesis. A cause that the
  agent finds is a finding. It is not part of the goal.
- **Conclude strongly.** Say which outcome is wanted, and which facts decide it.
- **Keep it able to fail.**
- **Remove words** until one more removal empties the statement or changes its meaning.

> In the case of "add a dark mode" the goal might be: "The app must contain and use a
> compatible dark-colored scheme that supports dark mode without violating accessibility,
> readability, or useability across the entire application and its microservices." That way in
> case the human just meant "only on this page" or "only this service", then it becomes clear
> where the assumed failure was. Questions can help narrow that down, but now you've got clear
> defaults to work from. (Ty, 2026-11-11)

The goal is wide on purpose. Each default of the agent is in the sentence, where the human can see
it and correct it. A narrow goal makes a guess too, and it hides the guess: outside its premise it
says nothing, so no check looks there. That is why every goal and every hypothesis lists its
premises beside it, and why a premise that nobody gave is removed.

A report of a defect says one thing more than the goal: that the system falls short of it
today. That is a finding about the system, and the reproduction tests it. When the build is
done, the finding is false, and the goal still stands.

A **guess** is something that the agent assumed and that nobody confirmed: a default about
what the human wants, a hypothesis that the human has not adopted, or a fact about the system
that the agent did not check. Guesses are normal. They are the agent's defaults, in view, and
they are part of the residual.

### When two statements both fit

Two goals can both be properly written and disagree on a case that nobody judged. Two
hypotheses can both fit what was seen. The first move is to find the distinguishing case and
take it to its instrument. When no instrument can decide yet, five old virtues rank the
candidates, and the human chooses.

| Virtue | Here |
|---|---|
| Testability | It is tempered: its defeating case is named and can be observed. |
| Parsimony | No word can be removed. |
| Scope | It reaches the whole goal, not a part. |
| Fruitfulness | Its definitions serve the next experiment. |
| Conservatism | It changes the least of what exists (`Sound Basis`). |

### The definitions

Three definitions make "can fail" exact. Two are in Lean. The link between them is in words
only.

**A goal that is properly written.** Ty's working sentence of 2026-11-11 was about the
statement of the intent, which is now the goal: "a properly written goal is the weakest
form of a statement that doesn't collapse (it is provable) and doesn't generalize so far as to
lose its intent." The file `docs/philosophy-orbit/2026-11-11/fable/Hypothesis.lean` makes it
exact, with 68 theorems that use no axiom. Ty ratified it on 2026-11-12. Its names still say
"hypothesis": read "the statement of the goal".

A **case** is one concrete behavior that the system can show and the human can judge. The
judgments of the human stand in for the intent. A statement is properly written, for what the
human has judged so far, when it fits (it rejects no case that the human wants, and accepts no
case that the human rejects), it can hold (some case meets it), it can fail (some case would
show a build wrong), and no word can be removed (each word is **held**: without it, the
statement no longer fits, or it has collapsed). Held is not confirmed: what a statement says
about a case that nobody judged is a guess, and only a judged case turns a guess into support.

| In plain words | Theorem |
|---|---|
| Each premise is held by a case that the human wants. | `premise_held_by_wanted_case` |
| Held is not confirmed: with no judgment at all, a statement can be properly written. | `proper_with_no_judgments` |
| Two statements disagree on a case. The human's answer refutes exactly one of them. | `one_case_decides` |
| The system shows a case that the statement rejects, and the human rejects it too: the build is wrong. | `stay_in_build` |
| The human wants a case that the statement rejects: the statement must change. | `hypothesis_must_change` |
| A collapsed statement cannot fail. A premise that the system never meets has the same effect. | `collapsed_cannot_fail`, `unmet_premise_cannot_fail` |
| The narrower the part that the human changes, the more of what was learned is kept. | `narrower_keeps_more` |
| Properly written is not unique. | `proper_attempts_can_disagree` |

**An experiment and its verdict.** The file `kb/proofs/scientific_method/ScientificMethod.lean`
is the definition from Astra's handoff of 2026-11-18. No theorem in it uses an axiom of its
own, and the verdict rule of the tool follows `Warrants`.

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

def Warrants {α : Type} (predicted compatible : α → Prop) : Verdict → Prop
  | .meets => ∀ x, compatible x → predicted x
  | .conflicts => ∀ x, compatible x → ¬ predicted x
  | .unresolved => (∃ x, compatible x ∧ predicted x) ∧
                   (∃ x, compatible x ∧ ¬ predicted x)
```

`derive` is the prediction: it follows from the conjecture and its premises. `interpret` is
the test: a reading and its measurement premises restrict the outcomes that could have
produced it. The two `knownWhen` fields are the seal.

| In plain words | Theorem |
|---|---|
| For an observation that is possible, exactly one verdict is warranted. | `unique_verdict` |
| A conflict rejects the conjecture, its premises and the measurement premises together. | `conflict_rejects_joint` |
| A verdict that meets shows the prediction for this run, and no more. | `agreement_establishes_run` |
| The timer: 60.0 meets, 61.1 is unresolved, 61.5 conflicts. | `Timer.reading_600`, `reading_611`, `reading_615` |
| When two models give the selected event the same likelihood, the comparison favors neither. | `Statistical.equal_likelihood_no_preference` |
| A revision adds an entry, and the earlier record stays. | `revision_preserves_record` |

**A tempered hypothesis** is not yet in Lean. In the terms of the second file: a hypothesis is
tempered when some possible observation would warrant a conflict. The four conditions of an
admissible case, and the three ways to be soft, are this text's reading. No theorem states
them, and no theorem joins the two files. A human judgment has the same shape as an
`Observation` (a procedure, measurement premises, a reading with three values), and no file
says so yet.

## The orbit

An orbit is a loop through parties that can disagree. One lap is one turn of the method. It
has five steps, and they are the same for a one-line fix and for a proof.

1. **State** the goal and a tempered hypothesis, from the source: the human's words and the
   current system. Not from the last artifact.
2. **Seal** what you expect: the claim, the result that would count against you, and how you
   will read the result. Before you look.
3. **Run** the experiment on the instrument that owns the question. See the control first.
4. **Read** one verdict. On a conflict, locate it before you reopen anything.
5. **Keep** it. Append what was learned, and what was replaced. Then go around again.

The orbit closes when a lap changes nothing. That counts only if each comparison in the lap
could have shown a difference. It also counts only if nothing is left open: a claim with no
check, a verdict that conflicts or is unresolved, a proof that is owed, a question with no
answer. Each one keeps the orbit open, unless the human waived it. Work that does not change
can still be unfinished.

The opposite of an orbit is a translation. In a translation, each step reads only the output
of the step before it. Each small error passes on and grows. At the end, the result can agree
with itself and be far from what the human meant. A closed system of statements that agree
with each other resists everything that contradicts it. Two failures taught this:

- An earlier version of this method was a pipeline. Only its second stage read the request.
  Each later stage read only the artifact of the stage before it. Its proofs held, but they did
  not show that the code did what the human wanted.
- On one project, the wrong tool was chosen for proofs and a redesign was proved in lean that should
  have been written in TLA+. It lost an outcome about timing that an earlier model guarded. The new
  design was a "transliteration" of the TLA+ model: it added and changed rules that nobody
  requested. Its main theorem was always true, so it showed nothing.

> "We do not write to achieve understanding; we orbit to achieve understanding." (Ty)

### Start light

Most work needs one lap in plain words. The agent states a working hypothesis and goes on. A
working hypothesis is accepted for now, so that the work can move, and often with the
knowledge that it is incomplete. To state it is not to ask a question.

> "If the first rung is what we do on any kind of change request, then the light path is the
> first rung and if there's a divergence then the second rung is the KB. Research, questions,
> debates, and other philosophical explorations (like this) don't get a KB because there is
> presently no change request." (Ty, 2026-11-11)

The light path costs one statement and one sealed check. It must not cost more. Ty's concern
is on record:

> "My concern is that this is going to add a slowdown since there will be more of a process for
> every change request. I'm hoping that the `orbit-kb` tool will help streamline that I
> guess." (Ty, 2026-11-11)

> "your typo example speaks clearly to me as a trivial change that would never need a KB to
> discover the intent." (Ty, 2026-11-11)

### One response to real doubt

Six signals are real doubt: questions that one round does not settle; a divergence; a build by
someone else; a claim that examples cannot cover; work that changes hands; significant effort
or verbosity from the human. Every signal gets the same response.

> "All six signals should elicit the same response. Shifting up simply means getting more
> specific and paying closer attention." (Ty, 2026-11-11)

The signals are many, and the response is one. A light model can follow one shape of response.
So the agent keeps its attention on the orbit, not on the process.

"More specific" has three levels of statement. **Words:** the goal and the hypothesis in one
statement, the premises, one example, one sealed check. **Records:** a knowledge base in
Prolog that holds the request word for word, the goal, the hypotheses, the claims, the
questions, the experiments with their verdicts, the judgments of the human, and what differed.
**A formal statement** of one claim, in the language that fits it.

A request starts in words. A signal moves the work to records. Each shift up and each lean
back is itself a record: what fired, who noticed it, and what stopped. When the cause of a
signal is resolved, the rigor that it added stops.

### A formal language is a shared medium, and each one is a lens

Records start on a signal. A formal statement needs no signal. One rule decides.

> **Formalize the smallest claim whose precision could change what the human or the agent does
> next.**

A formal language can enter at three moments. While forming the hypothesis: a definition
forces a choice that the words left open. While exploring interpretations: a query or a solver
finds the distinguishing case. While verifying the chosen claim: a proof or a model check
shows what follows from the agreed premises. To try to state a claim is itself a way to find a
disagreement, before either party has seen one. When one example settles the question, the
example is enough.

This is what `User Ability` buys. Because the human reads and writes the formal languages, a
formal statement is a place where the human and the agent work together. The cost of the
statement is real, and it can come back: a definition that was written once serves the next
experiment (`Shifting`).

Each language is a lens. A claim about current behavior needs a test. A claim about rules and
limits fits a solver. A claim about the order of steps or about time fits a model checker. A
claim about every possible input needs a proof. Use the cheapest tool that can show the claim
false. Decide the shape of a claim by its meaning, not by its words: "every" in a sentence
does not make a claim universal. A claim is universal when its inputs are infinite or too many
to check one by one. Such a claim, or a claim that the human asks to prove, burns: it stays
open until a proof or the human's waiver closes it.

Lean is not a modeling language: a Lean file holds definitions, and theorems about them. A
proof is about its definitions, not about the shipped code. Examples carry it to the code:
each example of the definitions becomes a test of the code.

> "We use one language because one language gives us one lens. we should use the right lens
> for the right problem depending on what we're trying to uncover." (Ty)

One formal language is written at a time. The knowledge base is the exception, because it
tracks the ticket itself. A signal that fires while one language is in use does not start a
second one. A finished artifact can be read as evidence at any time.

### Speed comes from skipping work, never from hiding it

Do only the work that could change what happens next, and stop when it is done. Every skip of
needed work is visible. Only the human can skip it, and the skip has a due time. After that
time, the work comes back. Scope, budget and deadlines are decisions of the human. They are
not a reason to drop a claim or a check quietly.

## The human's half

> "When the human seeks to adhere to the principles of the scientific method it enables
> `Sagittarius` to achieve the goal." (Ty, `Anthropocentrism`)

The method asks five acts of the human. Each is small, and each can be seen.

1. **Say the goal**, and not the fix: what you hope for.
2. **Say your hypothesis first**, when you have one: before you see the agent's.
3. **Say what would change your mind:** the case that would defeat it.
4. **Judge concrete cases**, before you hear the agent's opinion of them.
5. **Say it aloud** when you adopt, skip, or change your mind, and say until when.

The agent makes each act cheap. It gives the human's words back as a goal, a hypothesis and
an "it is false if", in one statement. It shows one case, not a list. It never asks the human
to approve a list: a long list invites "approve all".

### The human goes first

Two reasons stand behind `Human-first`. A human who has to say how they think to get there
finds what they do not yet know (`Expert Favoring`). And an idea that was formed before its
author saw another party's idea is an independent view. Groups that share ideas before each
member has written their own anchor on the first idea. A human who reads the agent's
hypothesis first judges inside the agent's frame, and many humans who all read the same agent
converge on the same frame.

The method does not make this a fence. For a plain request the agent drafts the goal and the
hypothesis, says that they are its own, and goes on. But when a signal fires, or when a wrong
avenue is costly, the agent asks for the human's hypothesis, and for the case that would
change the human's mind, before it shows its own.

> "The agent and the human should work together to temper a hypothesis if either party deem
> the hypothesis un-tempered." (Ty, 2026-11-23)

### Do not lead the instrument

A judgment of a case is a measurement, and a measurement can be spoiled. When the agent shows
a case and says which answer it expects, the human judges the agent's answer and not the case.
So for a case that tests a hypothesis, the agent seals what it expects, shows the case plainly,
and says what it expected after the human answered.

A decision is another thing. "Which of these two should I build?" is a question with options,
what each option changes, and the agent's default. The default saves the human time, and the
human can say "your defaults are good".

### Inside the goal, the agent is free

> "By allowing the AI agents freedom to explore possible alternatives, and challenge the
> hypotheses against accepted sources of evidence, Sagittarius is able to deliver the results
> faster without reducing the quality of the result." (Ty, `Throughput`)

The agent can investigate other hypotheses inside the goal and its constraints. One hypothesis
is enough when alternatives would add little. Sign-off is about adoption: the human adopts the
avenues that they find satisfactory. A dead end, or an alternative that differs only inside
the build, needs no ratification. A material tradeoff does: a difference that a user would
see. If one avenue silently drops a correction and another sends it to review, the choice
changes what users experience, and it is the human's.

### What stays with the human

The intent. The judgment of a case. The adoption of a hypothesis. How sure is sure enough,
when a mistake is costly. Every skip. The scope and the budget. The vote. The owner is not the
only person who can answer a question: answers and decisions can come from other people.

An agent's proposal does not become the human's decision because it was written down, encoded
in Prolog, or proved in Lean. What an agent records about the human's words is the agent's
reading, until the human confirms it.

The record tracks the human as carefully as it tracks the agent. A judgment, an adoption, a
decision, a waiver and a vote are each recorded in the human's words, with who said it and
when. Today the record holds mostly what the agent did.

## The registered hypotheses

Ty wrote the premises and the hypotheses of the project. This is the reference text. Its
wording is kept as Ty submitted it.

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

No comparison of any of them has run. Each is registered here with its prediction, what would
count against it, and what a comparison must fix before it starts. The last column comes from
Astra's discussion of 2026-11-18. It is a set of proposals for the inquiry.

| Hypothesis | What it predicts | What would count against it | Fix before the comparison |
|---|---|---|---|
| `Expert Favoring` | The same agent gets closer to the goal with a human who understands the wanted result more deeply. | Results that are no closer when the understanding is deeper. | Capture the human's understanding at the start, before any result is seen. |
| `Sagittarius` | Against a comparable Agile method: a smaller residual, and fewer errors and divergences after the delivery. | A comparable method that delivers with no more of them, at no more cost. | Which methods are "comparable". For potential falsifiers: the claim, the admissible cases, and the stage at which they are counted. A good first comparison leaves the other comparators open. |
| `Annealers` | Agents with formal languages and proper context reach a tempered hypothesis at less cost than without one of the three. | The same hypothesis, as fast, with one of the three removed. | The comparison, and the measure of cost. Count the human's reading time. |
| `Anthropocentrism` | Tickets on which the human did the five acts reach the goal with less rework. | No difference between tickets where the human did and did not. | Which of the five acts is observed, and how. |
| `Human-first` | Earlier exposure of a misunderstanding, and a result that the human judges closer. Both. | A paired comparison in which the ordinary request exposes the misunderstanding no later, or gives a result that the human judges no less close. | One task with a documented misunderstanding at the start; two openings; the same snapshot, model, tools and budget; the event that counts as exposure; the clock starts at the request; a blind judgment if feasible. Time spent drafting is recorded apart. One pair speaks to that task only. |
| `Throughput` | Free exploration delivers faster, with no loss of quality. | The same quality, as fast, with one fixed hypothesis; or faster with a loss that the human names. | Record the human's review time and the quality of the delivery beside the elapsed time. |
| `Parallax` | In a dispute about a non-trivial claim, a formal language finds the distinguishing case sooner than plain language. | A dispute in which the formal statement finds that case later. | Whether two readings that agree on every case are eligible. |
| `Shifting` | For evidence that rests only on what is given, a shared formal language lowers the total time, most of all when the experiment repeats. | The cost of the encoding does not come back over the repeats. | Count the first modeling and the human's review. |

### The method records itself, from outside

A hypothesis about the method needs observations of the method. An agent that reports on its
own method grades its own work. So the observations come from outside the agent: from System 1,
which classifies each message, and from the tool, which holds the record. Each ticket leaves a
row:

- who wrote the first goal and the first hypothesis: the human, or the agent;
- the lap in which the first divergence showed, and who noticed it;
- each shift up and each lean back;
- each formal statement, and whether it found a distinguishing case;
- the residual at the delivery;
- each correction after the delivery.

A row leaves "registered" on evidence: a comparison, a count, or a report of Ty, with its
date.

### Positions of this text

These are not Ty's hypotheses. They are how this text reads them. Each names what would show
it wrong.

| Position | What would show it wrong |
|---|---|
| Three questions, three instruments, and the agent is none of them. | A question about a piece of work that none of the three can answer, and that matters. |
| Every reading has three values, and "cannot tell" is never "yes". | A case where a missing answer had to be taken as a yes for the work to move, and nothing went wrong, often. |
| Exploring is free. Confirming is sealed. | Agents seal after the look, or the line becomes a ritual; or sealed predictions slow plain requests. |
| A pass gets the scrutiny of a fail. | The extra look at passes finds nothing, often enough that Ty reports it as noise. |
| Soft, brittle, tempered; an admissible case also matters to the goal. | A hypothesis that the reading calls brittle and Ty calls well written, or the reverse. |
| Tempering makes potential falsifiers, and testing spends them. The delivery reports the residual. | Residuals that do not predict where the corrections come. |
| Every record has a "because" and an "unless". | Work that had a purpose and could not be given a place; or orphans that the record does not report. |
| A ticket is a goal with hypotheses, claims and experiments. | A conflict that cannot be placed on the build, the measurement, a premise or a hypothesis; or a ticket that closes while the human judges that its goal is not satisfied. |
| A defeated hypothesis goes back to discovery. | Returns to discovery that only repeat what build could have said. |
| The human goes first on a signal or a costly avenue. The agent does not lead a judgment. | Ty reports the question as friction, or the plain case as harder to answer than the led one. |
| Every ticket has a goal and a hypothesis, stated and not asked. The light path gains no step. | Ty reports that plain requests got slower, or that "Goal (mine): ... Hypothesis (mine): ..." reads as a ritual. |
| Records start on a signal. A formal statement needs none. | Formal statements that changed no decision; or claims that needed one and stayed in words. |
| One response for every signal. | A signal for which the right response has another shape. |
| System 1 is recommended, not required. | Sessions without it miss signals that sessions with it catch. Then it is required. |
| With the record in view, System 1 catches a dropped prediction before the delivery. | Replays in which it misses the drift, or reports a revision that both parties knew about. |
| The formal artifacts vote by readiness. | A discovery that was not ready gets a GO that proves right, often. |
| A rule of the prompt needs a case that fails when the rule is deleted. | A rule that clearly matters, for which no such case can be written. |

## The protocol

The prompt holds habits. Each habit is an instance of a pattern that science already has a
name for. A model knows these patterns from everywhere, so the prompt can lean on them.

| # | The habit in the prompt | The pattern |
|---|---|---|
| 1 | State "Goal ... Hypothesis ... It is false if ..." before you build, and say whose they are. | Register the conjecture. A working hypothesis. |
| 2 | Write the goal wide, with its premises beside it. | No hidden auxiliary assumption. |
| 3 | Remove words. Add no cause that nobody gave. | Parsimony. |
| 4 | Write the check from the request, not from the build. | Independence of the test from the thing tested. |
| 5 | Say what you expect, and what would count against you, before you run. | A sealed prediction. |
| 6 | The check of a change fails before the change. | A positive control. |
| 7 | Run the whole suite at the base, and again after the change. | A baseline, and a negative control. |
| 8 | A model matches a real failing case and a real passing case. | Calibration. |
| 9 | Run a peer's checks yourself. Read the request, not the report. | Replication, and a blind review. |
| 10 | Brief an explorer with the goal, not with your answer. | Independent generation. |
| 11 | Seal your vote. Do not lead a judgment. | Blind judges. |
| 12 | Locate a conflict before you reopen anything. | A conflict rejects a conjunction. |
| 13 | Do not edit a defeated hypothesis. Keep its case. | No rescue after the fact. The failures stay in the sample. |
| 14 | Do not run a check again until it passes. | A stopping rule. |
| 15 | A pass gets the question that a fail gets. | Guard against confirmation. |
| 16 | Report the residual: guesses, and what no check covered. | State the limits. |
| 17 | Change only the behavior that a claim names. | Conservatism (`Sound Basis`). |
| 18 | Start light, and shift up on a signal. | Real doubt, not doubt on paper. |
| 19 | Stop for the human when a mistake is costly. | The cost of an error sets the bar. |
| 20 | Formalize the smallest claim that could change the next step. | Run only the experiment whose result matters. |
| 21 | Only the human skips, with a due time. | A waiver with a date to revisit. |
| 22 | Never type a digest or a result. Record as the human's only what the human said. | No fabrication. |
| 23 | Draw the delivery from the record. | The report is not a story told afterwards. |
| 24 | One principle, shown by examples. Each word has one meaning. | Define the terms before the argument. |

The method follows its own rules. A change to the prompt must be worth having even if no test
of the prompt existed. It comes from a real failure, not from the shape of one test case.
Never put the answer to a test into the prompt. Tune on one set of cases, and decide on a
separate set that nobody tuned on. A rule needs a case that fails when the rule is deleted.
Decide on repeated runs, not on one run. Evals test whether agents can follow the prompt. Use
tests whether the philosophy pays off. No one stakeholder is privileged: the method does not
optimize for one project.

## The notebook

Nothing in the notebook is edited. Entries are added.

### What was seen

| When | What was seen | What it bears on |
|---|---|---|
| Before October 2026 | A method that sorted work into tiers of difficulty at the start. The middle tiers emptied into the lowest and the highest. | Nobody knows how much rigor a piece of work needs until a misunderstanding shows. |
| Before October 2026 | A pipeline in which only the second stage read the request. Its proofs held, and did not show that the code did what the human wanted. | Translation. Each statement comes from the source. |
| Before October 2026 | A redesign that was proved in Lean and should have been in TLA+. It lost an outcome about timing. Its main theorem was always true. | The lens must fit the claim. A theorem that cannot fail. |
| 2026-10-22 | An audit of one long session found that the agent never shifted up. Each divergence got "You're right to flag it" and a fix. Ty has never seen an agent shift up by itself. | An agent is a poor judge of whether it diverged. System 1. |
| 2026-10-22 | An agent left a project's test failing and said that no suite existed. | Find the project's tests, and say where you looked. |
| 2026-10-27 | A live discovery whose hypotheses each named a fix. | Assume little. An avenue is not part of the goal. |
| 2026-10-30 | A model of a race was recorded as calibrated because it reached the same failure as the system. The system then showed that failure by a different sequence of steps. | A match of the outcome does not show the cause. Calibration on both sides. |
| 2026-11-11 | An agent recorded that two sentences of Ty exclude each other. The knowledge base then reported a contradiction. The inference was sound, and the reading was the agent's. | The machine is impartial about what follows, not about which statement was written. |
| 2026-11-11 | Ty reported that he had seen no Lean proof and no Prolog statement since he started to use Sagittarius. | The formal statement goes to the human with the plain claim. |
| 2026-11-23 | Ty reported orphaned tasks, threads and handoffs in the hubs. | Because and unless. One door to every store. |

### What was defeated, retired or replaced

| The position | What ended it | What stands now |
|---|---|---|
| Rigor is chosen by tiers of difficulty at the start. | The tiers emptied (above). | Rigor follows doubt and stakes. |
| Discovery has sizes. | "size determines nothing. Clarity does." (Ty, 2026-11-11) | Clarity decides. |
| A stage builds from the artifact of the stage before it. | The pipeline (above). | The orbit. |
| The hypothesis is the statement of the intent, and the law of its ticket. | "A goal is what we hope to accomplish (the intent). The hypothesis is how we think we'll get there." (Ty, 2026-11-23) | A goal, and hypotheses under it. |
| When the human says what a hypothesis changes to, build restates it. | "the entire experiment should be re-evaluated if a hypothesis is falsified." (Ty, 2026-11-23) | A defeated hypothesis goes to discovery. |
| A check passes or fails. | Astra's handoff of 2026-11-18; Ty: "Follow the handoff." | Three verdicts. |
| The work shifts into a formal language only on a signal. | Astra's rule, taken by Ty on 2026-11-23. | The smallest claim whose precision could change the next step. |
| A claim that is contested twice needs a Lean proof. | Ty's ruling of 2026-11-12 (the default). | The language that fits the claim. |
| No front door: each store is queried with its own tool. | "`orbit` is the front door to every store." (Ty, 2026-11-23) | One door. |
| The MindHole and Sagittarius do not depend on each other. | The same ruling. | A MindHole needs the tool. The prompt needs no hub. |
| An informal release for users who do not read formal languages. | "We're going to drop the informal release entirely." (Ty, 2026-11-23) | One audience (`User Ability`). |
| Fourteen numbered principles, grouped under five premises. | This draft. Proposed. | The instruments, the logic, and the protocol. |
| A lap is State, Compare, Sharpen. | This draft. Proposed. | State, Seal, Run, Read, Keep. |

## The lab

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

A MindHole is a lab. Its sessions have the roles of one.

| Party | Its role in the lab |
|---|---|
| discovery | Forms the goal with the human, tempers the hypotheses, and brings the vote. It re-evaluates when a hypothesis is defeated. |
| build | Builds the apparatus and the change, and runs the sealed experiments. |
| review | The second lab. It runs the experiments again from the source, tries to defeat the claims, and records each result and each judgment of the human. |
| System 1 | The monitor. It watches the experimenter, from outside. |
| the human | The investigator, and the only instrument for what is wanted. |

Its stores are the books of the lab, and `orbit` is the one door to them.

| Store | What it is in the lab |
|---|---|
| the project KB | The research programme: the goals and hypotheses that outlive a ticket. |
| a spec KB | The protocol and the notebook of one experiment. |
| the ledger | Who has what, and what waits on whom. |
| the weeks | The raw observations: reports and transcripts. |
| the memory files | The lab manual. |
| the tracker | The client's own record. |

A MindHole needs the tool. The prompt does not need a hub. So the prompt must be true alone:
with no hub, with another version of `orbit`, and when System 1 is silent.

Three things have a semantic version, and each names its own. Sagittarius (the prompt, `orbit`,
and the System 1 hook) is one release, and the last line of the prompt names it. This
philosophy has its own version, in its first lines: it moves ahead of the build. Each MindHole
records the version of the kit that it came from. `CHANGELOG.md` says what a change of each
number means.

## How to judge a change

Ask these questions about a proposed change to the prompt, the tool, or the hub.

1. Which goal does it support? Which hypothesis does it serve? Is it an orphan?
2. Does it answer a question with the wrong instrument? Does it let a party grade its own
   work, or its own noticing?
3. Can a "cannot tell" that it produces be read as a "yes"?
4. Does it build one statement from another statement, and not from the source?
5. Can a reviewer reconstruct each verdict that it produces: the claim, the premises, what
   was sealed, the observation, the rule?
6. Does it add rigor where there is no doubt and no stake? Does it keep rigor after its cause
   is resolved?
7. Does it add a second shape of response, where one shape is enough?
8. Does it let work be skipped, or existing behavior be changed, with no visible record?
9. Does the human see the statement that the machine checked? Is what the human said recorded
   as the human's?
10. Does it only save the method from one failure, or does it predict something new?
11. Does it add a word list, or the answer to a test, where one principle and an example are
    enough? Does it give a second meaning to a word?
12. Is it still true with no hub, with another version of `orbit`, and when System 1 is
    silent?

## The outer bounds of this draft

This section is for the review, and it leaves the text when Ty has ruled. Each row is a place
where the draft goes past Ty's words, and the way back.

| Where the draft goes | The way back |
|---|---|
| The whole text is rebuilt as a protocol. The numbered principles are gone: their content is in "The instruments", "The logic", "The ticket" and the protocol table. | Keep the new sections, and bring back numbered principles as the headings of the protocol table. |
| The human is called an instrument, and a judgment is called a reading, beside a verdict. | Keep "two levels of judgment" from 2.1.0, and drop the word "instrument" for the human. |
| Ty, 2026-11-23: "The verdict is whether the goal is satisfied or not." The draft keeps "verdict" for an experiment and "judgment" for the goal, as the vocabulary of 0.8.0 does. | Let "verdict" name both readings, and change the vocabulary block. |
| Seven new words are proposed for the vocabulary. | Take only the ones that Ty would use aloud. "Residual" and "seal" carry the most. |
| The lap has five steps: State, Seal, Run, Read, Keep. | State, Compare, Sharpen, with the seal as a rule of Compare. |
| "Tempered" gets two sides (soft and brittle), and "admissible" gets a fourth condition: the case matters to the goal. | Ty's sentence as written: one admissible case, and the three conditions of draft 1. |
| Anneal, quench and temper are three named moves. | Keep "anneal" and "temper" as Ty uses them, and drop "quench". |
| Discovery is "hot" and build is "cold"; a GO "registers" the experiment. | Plain words: discovery explores, build confirms. |
| "Exploring is free. Confirming is sealed." A look that was not sealed can fulfil no claim. | Draft 1: say what you expect before you look, and disclose a check that was written after its result. |
| "Do not lead the instrument": the agent hides its expectation when the human judges a test case. | Every question to the human carries the agent's default, as in 0.8.0. |
| On a signal or a costly avenue, the agent asks for the human's hypothesis before it shows its own. | 0.8.0: ask for the human's own only when a wrong avenue is costly. |
| "Potential falsifiers" is read as made by tempering and spent by testing, and the delivery reports a residual in place of `Guesses` and `Not checked`. | Keep the two fields, and leave the reading of "potential falsifiers" open. |
| "Because, and unless": every record has both links, and a record with no "unless" is called empty. | Keep "because" (Ty's own words), and drop "unless". |
| The method records itself from outside: each ticket leaves a row for the project's hypotheses. | Leave "Under trial" as a table that only Ty's reports feed. |
| Stakes are named beside doubt as the second thing that raises rigor. | "Clarity decides" alone, with the cost of a mistake only in the rule for asking. |
| The dated cases moved out of the text into "The notebook", with a table of defeated positions. | Put each case back beside the rule that it taught. |
| A MindHole is described as a lab, and its sessions and stores as the roles and books of one. | The plain description of 2.1.0. |

## Sources

The spine is Ty's `hypothesis.md` and Astra's handoff of 2026-11-18
(`project-kb/analyses/sagittarius-handoff/` in the sidequest-mindhole). For this draft, each
source that the handoff cites was read on 2026-11-24.

- K-Dense, the guides under "Scientific Thinking & Analysis", and the skill text of
  *Scientific Brainstorming*: independent generation before exposure, claims labelled by kind,
  criteria before scoring, a reviewer who did not originate the idea, "human-first ideation".
- Omer Metin, *Scientific Method* (the skill and its three reference files): the hypothesis
  stated after the result, the many ways to read one result, controls, the stopping rule, the
  scrutiny of a pass.
- Wikipedia, *Conjecture*, *Hypothesis*, and *Scientific method* ("Elements of inquiry" and
  the sections on rationality, the hypothetico-deductive method, parsimony and the limits of
  method): the working hypothesis, the five virtues, Peirce on doubt, "it is essential that
  the outcome of testing such a prediction be currently unknown".
- Stanford Encyclopedia of Philosophy, *Scientific Method*: aims, methods and the values that
  judge them; Popper's potential falsifiers; the cost of an error in a test; verification and
  validation; the report as a reconstruction; science as ordinary care made systematic.
- Sun and Saparov, *Language Models Do Not Follow Occam's Razor* (arXiv 2509.03345).
- The Lean file of the handoff, from the repository copy, which is the same file. The share
  link in the handoff serves an application page, and its text could not be read.

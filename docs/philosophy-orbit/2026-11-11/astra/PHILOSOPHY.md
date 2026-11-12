# The philosophy of Sagittarius

> Astra's second draft, 2026-11-11, after reading Fable's synthesis. For Ty's review.
> Working positions remain proposals where the discussion has not settled them. The
> [review note](philosophy-orbit/2026-11-11/FABLE-REVIEW.md) records the changes and their basis.

Sagittarius helps a human and an agent discover what they mean, state it precisely enough to
act, and keep checking that the work serves it. Its subject is alignment on intent.

This document holds the beliefs behind that work. The system prompt expresses them as behavior
an agent can follow. `orbit-kb help` holds the procedures and the syntax of the installed tool.
The philosophy guides the project; it is not a document that every installation must carry.

The beliefs are open to correction. A proposed change must say which belief it serves and which
it challenges. Ty owns this philosophy and the prompt. An agent's proposal does not become Ty's
decision because it was written down, encoded in Prolog, or proved in Lean.

## The bet and the interfaces

Better models do not remove the distance between a person's intent and its expression. The human
can also discover what they want through the work. Difficulty changes as tools improve; this
distance remains a reason to work together. Sagittarius therefore follows misunderstanding,
not a prediction of how difficult the task will be.

**Working hypothesis of the method:** returning to the source and comparing accounts that can
challenge one another helps expose misunderstanding before it becomes expensive to correct.
**Premises:** requests express only part of intent; an author can repeat a misreading across
artifacts; human judgments, observations and formal checks expose different kinds of error;
their cost can be kept proportionate to the uncertainty they resolve.

Use must test that proposal. Record corrections after delivery, missed outcomes and the cost
of reaching agreement. Repeated comparisons that add work without exposing or preventing
relevant errors count against it. No wording or proof here establishes that this is the fastest
method for every task.

Sagittarius extends the harness between the human-agent interface and the software factory.
It provides a shared place for inference, reasoning and domain knowledge, so the intended
outcome remains available while the agent works on the project.

There are two interfaces:

- **Sagittarius:** the system prompt and `orbit-kb`, with System 1 hooks for detection and
  classification. It carries the philosophy into an ordinary agent session. The working
  installation position is that the hooks are recommended for now.
- **MindHole:** a workspace for sustained work with multiple sessions, shared records and
  automation. Each workspace can pin its own version of the tools and its own extensions.

They work well together and can be used separately. Workspace routing belongs to the workspace.
The shared prompt must remain meaningful outside a hub and use the procedures of the tool
version actually present.

The audience can read Prolog, Lean and the formal languages used in the work. Formal text is a
surface of collaboration. It must be available to the human while there is still something to
decide, not only stored where a determined reader could find it afterward.

## The orbit in one lap

The work has one common shape: **state, compare, sharpen**.

1. **State** the current account and its premises from the request, later decisions and the
   system. The request supplies wanted outcomes; the system supplies observations.
2. **Compare** it with a source that can challenge the relevant judgment: a human's reading
   of a case, an observation, a check, a proof or a reviewer returning to the source.
3. **Sharpen** the part the comparison leaves uncertain or exposes as wrong. Locate the issue
   in the interpretation, premises, implementation or evidence; correct it and compare again.

A difference identifies something to investigate. It does not decide which account is right.
Agreement also carries information when the comparison could expose a relevant error. Checks
that share a mistaken assumption can agree, so ask what each comparison actually challenges.

A stable lap is a reason to consider stopping. Close only when the obligations are fulfilled
or covered by an active human waiver, relevant evidence is current, and no unwaived blocker
remains. Show the conclusion's scope and remaining uncertainty. Unchanging work can be unfinished.

## The principles

### 1. The human owns intent. Discovering it is shared work

The human decides what outcome is wanted and owns the result. Their request is our source, but
our current reading of it is an attempt. The human need not arrive with a complete account of
their own intent. Seeing a case, a constraint or a result can change what they understand or want.

The agent helps make that account clear and owns the build. Other people can supply facts,
answers and decisions within their authority. When a decision remains disputed, the owner
decides. Choosing an outcome does not make a factual claim about the system true.

We preserve what each orbit taught us. That history can grow while a hypothesis is replaced.
Discovering intent does not require every revision to be a narrower version of the previous one.

### 2. Alignment is the goal. Agreement has a scope

The human, the agent and the formal artifacts should agree on the intended outcome, the current
obligations and the evidence for calling the work finished. Agreement is about an explicit
account of intent at this point in the work. It does not certify that no later discovery can
change it.

An unresolved disagreement remains visible. HOLD is a valid result. A vote cannot make a failed
check pass, and a proof cannot choose what the human ought to want.

Four qualities judge the method and its changes: **clear**, one shared reading within the stated
scope; **accurate**, the delivered behavior serves that reading; **honest**, uncertainty and
limits are visible; **fast**, attention goes to work that is needed. A rule that improves none
of them has no place here.

### 3. No party grades its own work

Each result must meet a source of correction outside its author. The human judges whether the
statement and its examples express the intended outcome. The agent investigates and constructs.
The CPU checks formal consequences and executable behavior. A reviewer returns to the request
and the system rather than accepting the builder's report as evidence.

These judgments are different. A kernel can reject a proof, but it does not choose the right
theorem. An agent can put the same misunderstanding into the code and its test. A human can
approve an example without noticing a missing case. Calling an artifact impartial does not
make its author-chosen premises, definitions or scope independent of that author.

This is parallax: each party sees the work from a different position. Discovery has research
and specify phases; build has build and verify phases. Making and judging remain distinct,
with rigor concentrated on specification and verification.

Show concrete cases first, then the relevant formal statement beside its plain reading. The
human must be able to inspect what the machine checked. Name the author of an interpretation,
the source that can challenge it, and the limits of that check.

### 4. Orbit the intent. Return to the source

Each lap reads the request, the human's later decisions and the current system. It can reuse
earlier work, but it must check that the work still serves those sources. An artifact is not its
own justification. Current code tells us what exists; it does not decide what should exist.

Earlier versions failed by translating one artifact into the next until the request disappeared.
In another failure, a proof about a pure function lost an outcome about timing. Internal
consistency survived while the intended behavior was lost.

When two formal languages state a claim, derive each statement from the source. Differences
between those views are information. Reusing an artifact is useful when its source, assumptions
and scope remain visible; merely translating it supplies no new check of its interpretation.

### 5. A hypothesis is our current attempt to state intent

**Working definition:** a hypothesis states the outcome we believe the human is seeking, the
premises under which it is wanted, and the scope of that account. Claims make obligations within
that account precise. For a defect, a separate claim says how current behavior falls short.

The hypothesis is the law of the ticket while it is accepted. It can be challenged. A clear
change request can supply that law directly; it does not need a discovery ceremony to acquire
one. Discovery is the work of finding or revising it when it is not clear enough.
An accepted obligation supplies the human judgment for ordinary build checks; do not ask the
human to repeat it on every failure. Reopen the interpretation when a new case leaves it unclear.

Every stated hypothesis carries its premises beside it. Assume little and conclude strongly.
Weakening a premise makes an obligation apply more widely; weakening its conclusion demands
less. These are different operations. Removing words is a writing heuristic, not a definition
of logical weakness.

Do not invent a cause, a mechanism or a fix in order to describe the wanted outcome. Preserve a
mechanism the human explicitly requires. State an observed cause as a finding, with its evidence.

A challenge must say what it could overturn:

- A system observation can refute a premise about the world.
- A behavior can violate an obligation without changing what the human wants.
- A human judgment about a concrete case can refute our interpretation of the wanted outcome.

For example, suppose the hypothesis is that saving a draft must not publish it, with the premise
that this action is a draft save. A save that publishes violates the obligation and calls for a
build correction. If the human explains that Save is meant to publish in this workflow, the
hypothesis needs revision. These are different reasons to change our work.

Examples and boundary cases help test the account. They do not prove that it covers every part
of an intent that is still being discovered. Err toward a general statement with few assumptions,
then use formalization to expose what is missing. Deliberately trying a statement just too broad
or too narrow can help locate the boundary; it is a heuristic, not permission to weaken a claim
until it becomes easy to prove.

Keep three questions separate: does the account fit the judgments already made, does it express
the relevant behavior, and does each part earn its place? A case may be an interaction or a
sequence over time. Choosing only a final value can hide an obligation about when it arrives.
The current implementation's limitations do not define the limits of what may be wanted.

Here is a partial formal reading. `j` records judgments so far; `R` accepts cases that meet
the requirement. Fit means agreement on judged cases, with no
conclusion about the unjudged ones. A system violation additionally needs an observed case.

```lean
def Fits {Case : Type} (j : Case → Option Bool) (R : Case → Prop) : Prop :=
  ∀ c, (j c = some true → R c) ∧ (j c = some false → ¬ R c)

def ObservedViolation {Case : Type} (observed : Case → Prop)
    (R : Case → Prop) (c : Case) : Prop :=
  observed c ∧ ¬ R c
```

Neither definition establishes that the chosen cases cover the intent or that an observation
was actually made. A requirement can fit sparse judgments and still forbid a wanted outcome.
Test meaningful boundaries and whether the stated premises apply to the work. When a wanted
outcome must be possible, show a case that satisfies the obligation as well as one it rejects.

Removing a whole clause can expose redundancy and suggest a useful question. It cannot certify
the weakest statement: a single clause can contain several restrictions. Two statements can
both resist deletion yet demand different things on an unjudged case. Formal fit, relevance and
economy of expression remain distinct parts of the proposed account of a good hypothesis.

### 6. A divergence is information. Quiet failures hide it

A divergence is a difference that matters between the intended outcome, our account of it,
current commitments, behavior or evidence. A new request exposes a difference between what is
wanted and what exists. A changed preference exposes a difference from the previous agreement.
Neither has to be someone's mistake to deserve attention.

Record the difference and its source. Do not force a guess about whether the human changed their
mind or we previously misunderstood them when the evidence does not decide.

A quiet failure presents agreement without the evidence for it: an omitted check, a hidden
assumption, a missing answer treated as a negative answer, or a proof of an inadequate property.
An empty result needs an interpretation. Silence alone cannot supply one.

An expected failing check can measure the gap already being addressed. That gap is still a
divergence. Repeating its evidence does not by itself call for another shift; the obligation
remains until fulfilled or explicitly waived. A waiver defers work without erasing the gap.
Predicting an unacceptable result does not excuse it. A newly exposed mismatch must not be
dismissed because its repair is small.

### 7. Shift up by getting more specific and paying closer attention

One response serves all signals: name the difference, return to the source, make the hypothesis,
premises and claims more explicit, and obtain the evidence that can settle it. The response
should be easy to trigger and easy to follow. The work, not the administration, gets attention.

The light path is the first response to a change request: a plain account, a concrete case and
a check. A divergence that the current account does not resolve moves the work into a KB.
Unsettled questions, work by another builder, universal claims, handoffs and significant human
effort also call for more explicit treatment. They share the response, even when they need
different evidence. Size and difficulty do not decide.

**Working boundary:** the initial known gap starts the light path; evidence that this account is
inadequate calls for the next shift. This avoids treating every expected failing check as another
rung. A request for proof or a handoff still shifts immediately; no count of earlier divergences
has to be reached first.
For a check that decides the next step, state the expected result before running it. An agent
must not explain away an unexpected result by claiming afterward that it was expected.

System 1 helps detect and classify signals from outside the building agent. Treat its hint as
a candidate signal to inspect against the source. Preserve the hint and the evidence for acting
on it or rejecting it; a silent dismissal defeats outside detection. The classifier can be wrong.
If the evidence does not settle a hint, it remains unresolved.
An unresolved question of intent or a consequential disagreement needs the human's judgment;
every classifier objection need not become a request for confirmation.

Missing or uncertain hints do not establish the absence of divergence. Events inside a turn
still need attention when no hook observes them. A prediction written before a check makes a
surprise visible, but it does not make the author's own detection independent.
The human can always request more or less rigor and decides when the parties disagree.

When the cause is resolved, stop the additional work it required. Keep the record and every
remaining obligation. A burn remains until a proof or a human waiver closes it. A KB remains
through the ticket; the next ticket starts light and responds to its own signals.

### 8. Speed comes from omitting unnecessary work and exposing necessary work left undone

Do the work the request needs, then stop. Use defaults where the cost of being wrong is low and
the choice is easy to reverse. Ask when a wrong choice is costly or hard to undo. A question
includes a concrete case, options, consequences and a default. Ask at most three in a round.
Do not ask the human to approve a list.

Only the human can waive needed work. A waiver names the obligation, the reason and when the
work returns. Passing over an obligation is not fulfillment. Scope, budget and deadlines are
human decisions, not excuses for quietly dropping claims or checks.

### 9. Words must match evidence

Say what was guessed, what remains unknown, what was not checked, and what went wrong. If an
earlier statement of your own was wrong, say so first. Disclosure is useful evidence about the
work, not a failure of the process.

A passing test establishes its observed cases. A bounded search establishes a result within its
encoding and bounds. A proof establishes its theorem under its definitions and assumptions.
Evidence about shipped code additionally needs a connection to that code. None of these alone
establishes that the claim expresses the human's complete intent.

Record the provenance of a finding. A result from a model is a lead about the current system
until the relevant connection is checked. A claim about an outcome and a claim about its cause
need different supporting observations.

### 10. Formal methods constrain our statements. They do not make them relevant for us

Sagittarius assumes honest cooperation. Tools catch particular mistakes; they do not prevent an
author from entering a false attribution, omitting a requirement or arranging a trivial theorem.
The agent must not work around a check, fabricate a result or attribute its own decision to a
human. An agent's self-report remains a self-report even when stored in a formal record.

A proved theorem is not vacuous merely because it is true. Ask whether its premises apply,
whether its subject represents the relevant behavior, and whether the property distinguishes
acceptable behavior from an unwanted alternative. A function that always returns an empty list
can prove that its output is sorted. That proof does not establish preservation of the input's
elements. The missing obligation matters more than the ease of the proof.

A check needs a way to expose the relevant error. Useful challenges include a known failing
case, an unwanted candidate implementation, a reachable boundary and a mutation of a necessary
rule. The challenge must come from the claim's meaning. It is not a ritual to satisfy a tool.

Impartial does not mean infallible. If engines disagree, preserve the disagreement and bring it
to the human before treating either answer as settled evidence.

### 11. Choose a formal language for what needs to become clear

A reproduction or test addresses concrete behavior. Prolog can expose domain rules and their
consequences. A solver can explore combinations and constraints. A model checker can expose
order, concurrency and time. Lean can state and prove obligations over the full stated domain.
Use the least costly tool that can soundly resolve the question being asked.

Use one formal language actively at a time, with the KB remaining available as the record.
One language gives one lens. Finish or explicitly suspend that investigation before taking up
another. Finished artifacts can remain evidence and be compared with the next statement of the
claim; using them does not require opening another investigation at the same time.

Choose by meaning, not trigger words. A claim whose inputs cannot feasibly be checked one by one
burns. A proof request also burns. Only a Lean proof or the human's explicit waiver closes that
obligation. A bounded result does not close it by being described more confidently.

Domain knowledge belongs in the formal work. A KB that only records process completion has
not, by that fact, made the domain clearer. A second language earns its cost by a question the
first investigation left unresolved, not by duplicating a conclusion for appearance's sake.

### 12. Preserve obligations and the conditions under which evidence applies

Memory lives outside the agent. Sessions end, contexts are compacted and work changes hands.
Records preserve the human's words, the interpretations made from them, the evidence and what
is still open. A new claim supersedes an old one without erasing its history.

A redesign must preserve outcomes the human still wants. Evidence does not automatically survive
a change to code, assumptions, definitions or intent. Keep the obligation and re-establish which
evidence applies. A changed digest can warn that something moved; it cannot prove conformance.

A changed preference is new information about intent. Within the same ticket, revise the account
and reassess affected evidence while keeping the KB and its open obligations. A fresh ticket can
start light; renaming unfinished work does not discharge its questions, checks or burns. Preserve
the history without labelling an earlier result wrong when it met the agreement then in force.

Durable outcomes need a home across tickets, such as a project rule with tests and explicit
dependencies. The project KB and the ticket KB serve different scopes. Keeping a record in one
does not by itself notify the other that its evidence has become stale. This is an obligation
for the design, not a claim that today's tooling completes it.

### 13. One principle, expressed through concrete cases

Give a term one meaning. Distinguish the object of a judgment: intent, a claim about the world,
an implementation, or the evidence for it. Do not use one successful check as an answer to all
four questions.

Examples teach the meaning of a rule. A list of phrases to recognize teaches a brittle shortcut.
The prompt must be short enough to follow while still giving the agent a usable response when
a signal arrives. Tool help supplies the mechanics. Removing a sentence is an improvement only
if the required behavior survives.

### 14. Improve the method through evidence from use

Ty's reports from use are test reports for the method. Record them, their context and the
version in use. Evals ask whether models can follow the intended behavior; UAT asks whether that
behavior and the philosophy are worth having. Both can be wrong or incomplete.

A prompt change must be worth making without knowledge of one eval's answer. State the real
failure it addresses. Use separate cases for tuning and judgment, repeated runs for comparisons,
and checks that can distinguish the proposed rule's effect. A deletion experiment is evidence
about whether a case tests a rule; the requirement that every rule have one remains a trial.

Do not claim a measured improvement from a plausible rewrite. When only wording and consistency
have been reviewed, report exactly that. Neither a large rewrite nor a smaller prompt is an
improvement by itself.

## Open questions and working positions

These are still questions for the orbit. The draft makes its working choices visible so they
can be challenged without treating them as ratified decisions.

**A. What makes a hypothesis properly written?** Fit to known judgments, meaningful scope and
nonredundant expression each help; none supplies the other two. The formal work makes fit and
clause deletion precise. The review's checked examples show why that deletion criterion
does not establish logical weakness or feasibility. We still need to choose the relevant cases,
explain how claims refine the hypothesis, and judge legitimate changes to its premises and
conclusions. The account must cover features and risks as well as defects. This remains an open
definition, with useful formal pieces rather than a completed test of intent.

**B. When does build return to discovery?** The working boundary follows Ty's suggestion: when
the hypothesis needs revision. A correction to a subordinate claim can stay in build if it
preserves the intended scope and outcome. An equivalent rewording does not by itself require
a handoff. We still need concrete cases that distinguish a harmless refinement from a change
to the ticket's law. A direct build uses its stated account of the request as that law.

**C. How do obligations survive tickets?** Decide which outcomes become standing project rules,
who ratifies that promotion, and how later work finds the rules it could affect. A durable fact
and an effective notification are separate needs. A session without a project KB needs an
explicit place for each outcome that must survive it.

**D. How does evidence remain tied to code?** Keep two questions separate: when should a change
invalidate an old result, and what establishes that the model or proof applies to the shipped
behavior? Pins address parts of the first. Reproductions and conformance arguments address
parts of the second. The required grain and the propagation through dependencies remain open.

**E. Do sizes decide the process?** Ty's answer is clear: clarity decides. This draft removes
size-based discovery routing. Examples of a short or long result must not reintroduce tiers.

**F. Where does one language stop and the next begin?** The working rule permits one active
investigation and any number of finished artifacts used as evidence. The exit test still needs
trial in use. Candidate calibration rules from the earlier failure are: include real passing
and failing cases; calibrate outcomes for outcome claims and mechanisms for causal claims; and
test whether the model can reproduce the sequence the system actually showed. Reach the states
named by the claims. These criteria are proposals for tool help, not claims about existing gates.

**G. How does detection stay visible?** The draft follows "optional for now; recommended" for
System 1. A desired component can be recommended during adoption. The current hook can be silent
when uncertain or unavailable, and does not see all events inside a turn. Decide how to expose
that status and make the disposition of a hint reviewable without asking the human to arbitrate
every classifier result. One command for entering the KB is a tool proposal; it must not invent
the claims it is meant to preserve.

**H. What is a version of Sagittarius?** Ty has asked for semantic versions and a separate
installation sequence. Define the versioned bundle, compatibility with a workspace's `orbit-kb`,
and the record that tells a session which prompt and hooks it actually received. MindHole has
its own version. Historical versions must remain identifiable without assigning them meanings
they did not have. These drafts do not implement a release or installer.

## How to judge a change

1. Which belief does it serve or challenge, and which observed failure motivates it?
2. What does each party judge, and what can expose a mistake in that judgment?
3. Does each interpretation return to the human's words and the current system?
4. Can an assumption, missing check, unavailable tool or stale result look like success?
5. Does the response increase clarity when needed and stop extra work when its cause is resolved?
6. Are obligations preserved, with any waiver and its due time visible?
7. Can the human see the formal statement and understand the limit of its evidence?
8. Does the rule work in Sagittarius alone and in a versioned MindHole workspace?
9. What evidence would justify saying the change improved the method?

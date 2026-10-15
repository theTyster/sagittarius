# AIDLC v2: a deep explanation of the brainstorm, with research and citations

This file is a rewrite of `aidlc-v2-deep-explanation.md` in ASD-STE100
Simplified Technical English (pragmatic mode). The rewrite keeps all of the
content of the source file. Nobody changed the source file.

Written 2026-10-14 for Ty, as source material. Another agent can turn it into a
podcast, a study guide, or a shorter brief. This document puts all of the
material in one place:

- The ideas.
- The reasons for the ideas.
- The open questions.
- Each useful citation from three research passes. The passes ran on
  2026-10-13.

Status: **brainstorm**. Nothing in this document is decided, unless the text
says "decided by Ty". Nobody changed `AIDLC.md`.

Companion files on disk. All of them are in `~/.dotfiles/thoughts/`, and git
ignores all of them:

- `aidlc-revision-2026-10.md`: The ticket record and the handoff notes for the
  v1 optimization ticket. The commit is `15a3b04`. Nobody pushed it, and
  SPLASHDOWN is still open.
- `aidlc-spec-session-2026-10-05.md`: The 4,905-word spoken spec session in
  which Ty defined WIFFLED. It is saved word for word.
- `aidlc-v2-discovery-draft.md`: The first draft of the Discovery set.
- `~/.claude/plans/harmonic-twirling-mango.md`: The working plan file. It holds
  the list of decisions and the edits that Ty made to the framing.

How to read citations: each source has a **Verified** flag. The flag values
are:

- "Fetched": A research agent opened that URL on 2026-10-13 and checked the
  details.
- "Search only": The details come from search-result snippets or from secondary
  sources. A human must check them before a quote.

The numbers from papers are the numbers that the research agents reported. If
a number is important for a decision, read the paper first.

---

## Part 1. Where this started

### 1.1 AIDLC v1 in one paragraph

AIDLC v1 is a system prompt. Every Claude Code session at work gets it as an
appended system prompt. It divides a change into nine phases: FLYBY,
TRAJECTORY / ANGLING, SIMULATION, FLIGHT MANIFEST, IGNITION, TELEMETRY,
RENDEZVOUS, LANDING MODULE, and SPLASHDOWN. The nine phases are in three sets:
Specification, Implementation, and Verification. Each ticket selects one tier:

- WIFFLED: No formal methods.
- AIMED: At least one formal technique pair.
- POKAYOKE: All nine phases.

Each task stays inside one set. Each task has a charter, named roles, and a
phase status record. Each item of evidence must name its type: formal check,
model run, test run, measured, code read, claim, or decision. A claim must not
be stronger than its evidence. A known counterexample blocks a phase until it
gets a disposition. The v1 optimization ticket checked a TLA+ model of the
process itself (`model/AIDLC.tla`) to 4.3 million and 20.6 million distinct
states.

### 1.2 Orbital shifting in one paragraph

Orbital shifting is an earlier methodology from Ty. It is for the "wrong-spec
problem": code that implements a specification exactly, but the specification
is wrong about reality. Orbital shifting treats the spec as a hypothesis, not
as a contract. Its pipeline has seven stages: close-world,
decompose-proposition, model-obligations, prove-invariants,
instantiate-properties, realize-specification, and measure-entailment. It also
has an explain closer and a disprove-proposition step that has no stage.

Claims have labels: descriptive, counterfactual, or prescriptive. Each "holds"
verdict has a negation basis. The negation basis has two values:

- Absent: The model does not include the behavior that breaks the claim.
- Contradicts: A rule in the model forbids that behavior.

Each counterfactual claim must be load-bearing. If you restore the old
behavior, the verdict must change. Adversarial agents try to refute each claim.
They return refuted, inconclusive, or abstained. The records are in Prolog
knowledge bases. Repo: https://git.mylegendary.quest/ty/orbital.git.

One finding from the orbital repo is important later. Its `carrier_only_reads`
rule gives the ticket text only to decompose-proposition. Each later stage
reads only the artifact of the stage before it. Also, measure-entailment scores
the code against `hypothesis.pl`, not against the ticket. As a result, the
pipeline never kept the original request in view. v2 corrects this: **the
ticket (and, before the ticket, the report) stays in context for every set,
phase, and agent.**

### 1.3 What Ty wants from v2

This is a condensed version of the words of Ty. AIDLC must be *a pattern for
building*. It gives out the correct formal tools, and the instructions for
these tools, at the rigor that each ticket needs. Orbital shifting had good
tools and good instructions. But it had one group of tools and one tier for
all work, and it was too strict.

v2 adds a Discovery set. It also makes the Specification, Implementation, and
Verification sets **more flexible and adaptable**. (This is a correction from
Ty: the word is not "looser".) The three tiers stay. Each tier has sub-routes,
and the sub-routes go through different rigor levels and formalisms.

Documents for humans use ASD-STE100 Simplified Technical English. Records for
machines (evidence, decisions, traceability) use a language for formal
annotation, not Markdown. The method must prevent local optima. It must also
scale as LLMs become better and faster.

Constraints:

- The team ships mostly **C#**, with a **React / JavaScript** frontend. The
  process must adapt to other languages. Ty accepts that this flexibility
  cannot be perfect.
- At this time, AIDLC is a Claude system prompt on the machine of Ty. Later,
  after it shows that it works, it can become its own repo. That repo can have
  a deterministic router and less human oversight of routing. It can possibly
  run in a sandboxed pipeline.
- Runtime monitoring and observability will be important for that future. But
  they are parked at this time.

---

## Part 2. The framing: clarity, accuracy, honesty, alignment

### 2.1 Ty's framing (verbatim, with Ty's later honesty additions)

> The need for greater specificity and verification comes from two things:
>
> 1. Humans don't explain what they want/need well enough.
> 2. Agents don't understand whats being asked well enough and can be
>    unreliable in how they implement.
>
> So, tier fit is not really about guarantee strength. Or necessarily about
> complexity either. It's about how clear the request is and how accurately it
> can be translated into the actual deliverable.
>
> The AIDLC will be built around achieving clarity and accuracy. It's all about
> getting strong alignment.
>
> - Discovery:
>   a) Establishes clarity in a _problem_.
>   b) Accurately defines _scope and risk_.
>   c) Honestly points out flaws in the system without over or under claiming.
>
> - Specification:
>   a) Establishes clarity in a _request_.
>   b) Accurately defines _intent_.
>   c) Honestly records the desires of the humans as strictly as possible
>      without contradiction.
>
> - Verification:
>   a) Establishes clarity in an _implementation_.
>   b) Accurately defines _fulfillment_.
>   c) Honestly reviews what was created and admits faults.

STE restatement of the quote (this is a restatement, not the words of Ty):

> More specificity and verification are necessary for two reasons:
>
> 1. Humans do not explain well enough what they want or need.
> 2. Agents do not understand the request well enough. Also, their
>    implementation can be unreliable.
>
> Thus, tier fit is not really about the strength of the guarantee. It is also
> not necessarily about complexity. Tier fit is about how clear the request is.
> It is also about how accurately an agent can translate the request into the
> actual deliverable.
>
> We will build the AIDLC around clarity and accuracy. Its purpose is strong
> alignment.
>
> - Discovery:
>   a) Gets clarity in a _problem_.
>   b) Accurately defines the _scope and risk_.
>   c) Honestly shows the flaws in the system. It does not claim too much or
>      too little.
>
> - Specification:
>   a) Gets clarity in a _request_.
>   b) Accurately defines the _intent_.
>   c) Honestly records what the humans want, as strictly as possible, with no
>      contradiction.
>
> - Verification:
>   a) Gets clarity in an _implementation_.
>   b) Accurately defines the _fulfillment_.
>   c) Honestly reviews the work that the agents made, and admits faults.

Ty's additions (2026-10-13):

- Accurate fulfillment also defines "we are done now". Thus the work does not
  drift into too much work on one problem. Accurate fulfillment needs a clear
  specification. All of these parts work together.
- The cost to repair increases as work moves through the phases and steps of
  the AIDLC.
- The objective is **alignment**. The system works correctly when agents,
  formal artifacts, and humans come into alignment. Alignment is always
  possible for a given problem at build time. This is true even where perfect
  verifiable guarantees are not possible (Rice's theorem).
- At its core, PARALLAX (Part 4) is about **honesty, clarity, and accuracy**.
  Honesty means explainability and confession of misalignment.

### 2.2 Why this framing is different from v1

v1 sorted tickets by risk and complexity, but it did not say so. It used formal
methods to buy stronger guarantees. The framing of Ty changes the purpose.
Formalism exists to stop the loss of meaning at each hand-off of work. A
formal statement does two jobs:

- It has exactly one reading. That is **clarity**.
- A machine can execute it or check it. That is **accuracy**.

Honesty is the third job. Each party (human, agent, tool) states what it does
not know, what it guessed, and where it disagrees.

### 2.3 Where meaning gets lost: the four hand-offs

| Hand-off | What goes wrong | Set that finds the problem |
|---|---|---|
| problem → request | The human does not give enough information. | Discovery, Specification |
| request → understanding | The agent reads the request incorrectly. | Specification |
| understanding → code | The agent makes an error during the build. | Verification |
| code → fulfillment | The code does what the request asked, but the problem stays. Or the code does more than the request asked. | Verification, human gate |

### 2.4 "Done" and fulfillment in both directions

Accurate fulfillment can fail in two directions:

- **Under-fulfillment:** The code does not meet a claim.
- **Over-fulfillment:** The code does something that no claim asked for. That
  is drift, gold-plating, or scope creep.

Proposal: use the same rule for over-fulfillment that the SPECTRUM step of
Discovery uses for uncited claims. Remove the extra behavior, or send it to
the human as a proposed ticket change. Specification defines the stopping
point. Verification checks it.

Evidence that this is important:

- **OverEager-Bench.** Qu, Zhang, Zhang, Deng, Li, Zhang, Liu. "Overeager
  Coding Agents: Measuring Out-of-Scope Actions on Benign Tasks." arXiv
  2605.18583, 2026. https://arxiv.org/abs/2605.18583 (Verified: fetched). 500
  scenarios, approximately 7,500 runs. Permissive agents (Claude Code, Codex
  CLI, Gemini CLI) did out-of-scope actions in 5.4–27.7% of runs. OpenHands
  asks first, and it did them in 0.2–4.5% of runs. When the researchers
  removed an explicit scope statement, the rate for Claude Code increased from
  0.0% to 17.1%. Caveat: this is a preprint. It measures side-effect actions,
  not extra features. Lesson: an explicit statement of scope and of "done"
  decreases overreach by a measurable amount.
- **SlopCodeBench.** Orlanski, Roy, Yun, Shin, Gu, Ge, Adila, Roberts, Sala,
  Albarghouthi. "SlopCodeBench: Benchmarking How Coding Agents Degrade Over
  Long-Horizon Iterative Tasks." arXiv 2603.24755, 2026.
  https://arxiv.org/abs/2603.24755 (Verified: fetched). Agent code was 2.3×
  more verbose and 2.0× more eroded than code in 473 open-source repositories.
  It also became worse at each turn. Quality prompts decreased the starting
  level, but not the rate of decline. Caveat: preprint, Python only. Lesson:
  prompts alone do not stop over-building. Structural stopping criteria do.

### 2.5 Cost to repair: what the evidence actually says

The intuition of Ty is that the repair cost increases as work moves through
the phases. The classic source agrees. The newer evidence is mixed. It is good
to know this before the idea goes into a normative document.

- **Boehm 1981.** Barry W. Boehm. *Software Engineering Economics*.
  Prentice-Hall, 1981. ISBN 0-13-822122-7.
  https://openlibrary.org/books/OL4267874M/Software_engineering_economics
  (Verified: fetched). This book introduced COCOMO. It also introduced the
  well-known curve that shows that the cost to fix a defect increases with
  each phase.
- **Menzies et al. 2017.** Menzies, Nichols, Shull, Layman. "Are Delayed Issues
  Harder to Resolve? Revisiting Cost-to-Fix of Defects throughout the
  Lifecycle." Empirical Software Engineering 22(4):1903–1935, 2017. DOI
  10.1007/s10664-016-9469-x. https://arxiv.org/abs/1609.04886 (Verified:
  fetched). 171 projects, 2006–2014. The effort for later fixes was "not
  consistently or substantially greater". The delayed-issue effect is possibly
  a historical relic.
- **Bossavit.** Laurent Bossavit. *The Leprechauns of Software Engineering: How
  Folklore Turns into Fact and What to Do About It*. Leanpub, about 2012–2015.
  https://leanpub.com/leprechauns (Verified: fetched. The edition date comes
  from search). Chapter 10 and Appendix B trace the defect-cost curve. They
  find weak evidence for it.

How this agrees with the point of Ty: with LLMs, it is cheap to rewrite code.
But a *misunderstanding that other work depends on* stays expensive
downstream. Examples are tests that encode the wrong intent, decisions on
wrong facts, and shipped behavior that users now depend on. Thus the honest
reason for early clarity is "a misalignment compounds", not "a 100×
multiplier". This also supports the decided rule that only Specification and
Verification start loopbacks. Agents can redo code freely, but human attention
belongs early.

---

## Part 3. Tiers, decided and proposed

### 3.1 The tier rule (decided by Ty)

**Tier = how much of the request must be formal before an agent can build it.**

- **WIFFLED: none.** Prose and examples pin the request.
- **AIMED: some.** Formalize only the claims that prose cannot pin down: rule
  precedence, boundaries, order, concurrency, or kinds of claims where agents
  made mistakes before.
- **POKAYOKE: all.**

With this rule, the v1 labels "0/3 none, 1/3 some, 2/3 all" stay literally
true.

Proposed addition, not confirmed yet: **formality closes over interaction.**
If a formal claim depends on another claim, that other claim must also be
formal. The reason is that a machine cannot check how a formal claim interacts
with a prose claim. If this closure spreads over the whole request, the ticket
is POKAYOKE. Harm does not select the tier. Harm sets the level of clarity that
is clear enough.

### 3.2 The tier cannot be graded once (decided by Ty)

Ty: we do not know how much of a request must be formal until a
miscommunication occurs. When clarity seems apparent, start at a lower tier.
If a miscommunication occurs, strongly consider a move up one tier, for better
clarity and accuracy. Sometimes time constraints make it necessary to bypass
clarity and accuracy for delivery. **Only the human decides that, with a clear
deadline (time and date).**

The proposed mechanism is the **tier ratchet**. It has these rules:

- The starting tier is an estimate.
- Some signals promote the related claims to formal statements. The list after
  this list gives these signals.
- The closure rule decides if the tier of the whole ticket increases.
- A move up is normal, not a failure. A move down needs a written reason from
  the human.
- A bypass record names the skipped work, the forcing deadline (date and
  time), and the time when the skipped work becomes due.

The signals that promote claims are:

- A divergence (Part 4) that the human had to settle.
- A DISCLOSURE / ANOMALY that an agent filed (Part 5).
- A failing test from review.
- A loopback.

PARALLAX makes the ratchet affordable. It intentionally makes small
misunderstandings appear before code exists. The alternative is to wait for
one expensive misunderstanding later.

### 3.3 The tier ladder and its routes

WIFFLED has four routes. Ty accepted them on 2026-10-05:

| Route | Shape |
|---|---|
| SUBORBITAL | Spoken plan, code, screenshots |
| FARSIDE | Red-test review, no user surface |
| WAYPOINT | Plan on disk, red-test review, screenshots |
| TETHERED | Plan on disk, tests first, review, screenshots |

WIFFLED decisions:

- A WIFFLED ticket is one-shot.
- A verification failure means misclassification.
- Verification checks conformance to the ticket, not to the plan.
- The adversarial review accepts only red (failing) tests as evidence.
- If there is a user surface, screenshots are necessary.
- Unattended merge is possible (but see the open tension in Part 11).

Part 6 is about the AIMED and POKAYOKE routes.

---

## Part 4. PARALLAX, the core mechanism (decided by Ty)

### 4.1 What it is

Astronomers measure the distance to a star from two positions. They look at
the star from each position and measure the shift. PARALLAX applies that idea
to meaning:

1. Two or more agents restate the same source **independently**. They use
   different prompts, different models, or different formal languages. They
   share no reasoning.
2. A machine compares the restatements.
3. Each difference becomes a concrete **divergence**: an input on which the
   restatements disagree. Example: "For a user with role X and expired token
   Y, restatement A allows the request and restatement B denies it. Which is
   right?"
4. The human answers the divergence. The human never has to read the formal
   text itself.
5. Do these steps again until no divergence appears within the recorded
   bounds.

### 4.2 PARALLAX in each human set

| Set | Source that the agents restate | What the divergences show |
|---|---|---|
| Discovery | The report (issue, defect, feature request) | Where the problem itself is unclear. The discovery draft already says "each pattern starts from the report". |
| Specification | The ticket | Ambiguity in the request. The answers of the human define the intent. |
| Verification | The code. An agent that never saw the spec restates it. | The gap between what the code does and the intent. This makes the TELEMETRY phase of v1 more general. |

### 4.3 How a machine compares restatements

| Restatement language | Comparator |
|---|---|
| Tests or executable functions | Run both on generated inputs. Each output difference is a divergence. |
| SMT (Z3, cvc5) | Assert "A ≠ B". A SAT result is the distinguishing input. |
| TLA+ | Check the invariants of each spec against the behaviors of the other spec. |
| Lean / Dafny | Prove A ↔ B, or find a small counterexample. |
| Specs that cannot execute (quantifiers, ghost state) | Symbolic testing of specifications (Lahiri, FMCAD 2024, in Part 4.5). |

### 4.4 Two rules that keep PARALLAX honest

**Rule 1: a disagreement is a finding. Agreement is not proof.** Restatements
from similar LLMs fail in correlated ways. This is the oldest lesson in the
area:

- **Knight & Leveson 1986.** J. C. Knight, N. G. Leveson. "An Experimental
  Evaluation of the Assumption of Independence in Multiversion Programming."
  IEEE TSE SE-12(1):96–109, 1986. DOI 10.1109/TSE.1986.6312924. Background:
  https://en.wikipedia.org/wiki/N-version_programming (Verified: partly. The
  DOI page returned 403. Secondary sources gave the same details.)
  Programmers at UVA and UC Irvine wrote 27 versions of one program
  independently, from the same specification. The researchers ran the
  versions on 1,000,000 tests. Coincident failures were much more frequent
  than independence predicts. See also their 1990 reply to critics in SIGSOFT
  SEN 15(1).

Consequence: vary models, prompts, and formalisms intentionally. Never let a
majority vote replace a human answer.

**Rule 2: each comparison records its bounds.** "No divergence found" is true
only within the inputs, sizes, and depths that the comparison actually
checked.

### 4.5 Prior art: PARALLAX is a known, live research direction

This is good news. The core mechanism has published support. The closest works
appeared in 2024–2026.

**Closest to PARALLAX**

- **SpecFix.** Jia, Morris, Ye, Sarro, Mechtaev. "Automated Repair of
  Ambiguous Problem Descriptions for LLM-Based Code Generation." ASE 2025.
  https://arxiv.org/abs/2505.07270 (Verified: fetched). It samples several
  programs from one description. It groups them by their behavior on
  generated inputs. It measures the semantic entropy across the groups. Then
  it rewrites the description so that only the selected reading remains. It
  changed 43.58% of descriptions. On those descriptions, pass@1 increased
  30.9%. The repairs also helped other models. Caveat: no human in the loop,
  and small benchmark functions. **This is almost PARALLAX in Specification.
  It even feeds the resolution back into clearer text.**
- **Lahiri 2026, the grand-challenge paper.** Shuvendu K. Lahiri. "Intent
  Formalization: A Grand Challenge for Reliable Coding in the Age of AI
  Agents." arXiv 2603.17150, March 2026. https://arxiv.org/abs/2603.17150
  (Verified: fetched). It defines intent formalization: to turn informal
  intent into specifications that a machine can check. The range goes from
  light tests that target likely misreadings, through full Dafny, F*, or Verus
  specs, to domain-specific languages. The main open problem is to check that
  the specs themselves are correct. That needs brief interaction with the
  user. The paper names "points where different LLMs would generate
  semantically different code" as the cheapest guardrail. Caveat: position
  paper. **This paper states the thesis of PARALLAX almost directly.**
- **ClarifyGPT.** Mu, Shi, Wang, Yu, Zhang, Wang, Liu, Wang. "ClarifyGPT: A
  Framework for Enhancing LLM-Based Code Generation via Requirements
  Clarification." Proc. ACM Softw. Eng. 1(FSE), Art. 103, 2024. DOI
  10.1145/3660810. https://arxiv.org/abs/2310.10996 (Verified: fetched). It
  samples several solutions and generates test inputs. If the outputs
  disagree, it marks the requirement as ambiguous and asks targeted questions.
  The average for GPT-4 increased from 62.43% to 69.60% across five
  benchmarks. (These are the numbers of the published version. The arXiv
  numbers are different.)
- **BeSpec.** Xu, Wang, Yu, Briand. "BeSpec: Behavior-Level Specification
  Alignment for Code Generation." arXiv 2607.02949, July 2026.
  https://arxiv.org/abs/2607.02949 (Verified: fetched). It keeps an explicit
  behavioral model as properties that a machine can check. It runs candidate
  programs on probe inputs. If they disagree, it refines the spec or discards
  the candidate. The relative pass@1 gains are 8–25% over the best of 9
  baselines. Caveat: recent preprint.

**Tests as questions to the human**

- **TiCoder (2022 preprint).** Lahiri, Fakhoury, Naik, Sakkas, Chakraborty,
  Musuvathi, Choudhury, von Veh, Inala, Wang, Gao. "Interactive Code
  Generation via Test-Driven User-Intent Formalization." arXiv 2208.05950.
  https://arxiv.org/abs/2208.05950 (Verified: fetched). The LLM generates
  tests. The user approves or rejects them. That feedback prunes and ranks
  candidate programs. In simulation with 1–5 user queries, pass@1 increased
  22–38 points absolute on MBPP and 25–54 on HumanEval.
- **TiCoder (TSE 2024 user study).** Fakhoury, Naik, Sakkas, Chakraborty,
  Lahiri. "LLM-Based Test-Driven Interactive Code Generation: User Study and
  Empirical Evaluation." IEEE TSE 50(9):2254–2268, 2024. DOI
  10.1109/TSE.2024.3428972. https://arxiv.org/abs/2404.10100 (Verified:
  fetched). 15 programmers took part. TiCoder users judged AI code correctly
  much more frequently, and they reported a lower cognitive load. Across four
  LLMs with 5 interactions, pass@1 increased by an average of 45.97 points.
  Caveat: small study, Python only. **Evidence that humans can resolve
  divergences when the divergences come as tests.**

**Restating intent formally**

- **nl2postcond.** Endres, Fakhoury, Chakraborty, Lahiri. "Can Large Language
  Models Transform Natural Language Intent into Formal Method
  Postconditions?" Proc. ACM Softw. Eng. 1(FSE), 2024.
  https://arxiv.org/abs/2310.01831 (Verified: fetched). LLMs turn
  natural-language intent into postconditions. The paper measures the
  postconditions by correctness and by how well they reject wrong code
  ("discriminative power"). Most of the postconditions are correct. They found
  64 historical Defects4J bugs.
- **Lahiri FMCAD 2024.** Shuvendu K. Lahiri. "Evaluating LLM-driven
  User-Intent Formalization for Verification-Aware Languages." FMCAD 2024.
  https://arxiv.org/abs/2406.09757 (Verified: fetched). Dafny specs do not
  execute directly. Thus the paper proposes symbolic testing of
  specifications. On human-labeled MBPP Dafny specs, the metric agrees closely
  with the labels. It also showed some labeling mistakes. **How to compare
  formal restatements that do not run.**
- **nl2spec.** Cosler, Hahn, Mendoza, Schmitt, Trippel. "nl2spec: Interactively
  Translating Unstructured Natural Language to Temporal Logics with LLMs." CAV
  2023, LNCS 13965, pp. 383–396. DOI 10.1007/978-3-031-37703-7_18.
  https://arxiv.org/abs/2303.04864 (Verified: fetched). It divides a sentence
  into sub-translations. Each sub-translation links a text fragment to a
  subformula. Users edit those pieces. **A UI pattern that shows a human
  exactly which phrase caused a divergence.**
- **Clover.** Sun, Sheng, Padon, Barrett. "Clover: Closed-Loop Verifiable Code
  Generation." SAIV 2024, LNCS 14846, pp. 134–155. DOI
  10.1007/978-3-031-65112-0_7. https://arxiv.org/abs/2310.17807 (Verified:
  fetched). It checks that code, docstring, and Dafny annotations agree. On
  CloverBench it accepted up to 87% of correct cases and none of the
  adversarial wrong cases. It found 6 wrong programs in MBPP-DFY-50. Caveat:
  textbook-sized programs. **PARALLAX across artifact types.**

**Agreement as a signal (and its trap)**

- **CodeT.** Chen, Zhang, Nguyen, Zan, Lin, Lou, Chen. "CodeT: Code Generation
  with Generated Tests." ICLR 2023. https://arxiv.org/abs/2207.10397 and
  https://iclr.cc/virtual/2023/poster/12011 (Verified: fetched). "Dual
  execution agreement" ranks samples by the tests that they pass and by
  agreement with other samples. 65.8% pass@1 on HumanEval, 18.8 points more
  than code-davinci-002. **Caveat for us:** CodeT lets agreement select the
  winner automatically. PARALLAX must not do this. A majority of correlated
  readers is not the intent of the human.

**Weak specs that look correct**

- **Spec-Harness.** Misu, Ma, Lopes. "Spec-Harness: Measuring and Improving
  Behavioral Adequacy of LLM-Synthesized Formal Specifications." arXiv
  2604.00280, 2026. https://arxiv.org/abs/2604.00280 (Verified: fetched).
  LLM-written JML specs that pass a verifier are frequently too weak or too
  strong. `ensures true` passes everything. The paper scores specs on
  pre/postcondition correctness and completeness. It uses symbolic
  verification and I/O mutation. Caveat: preprint, Java/JML. **A comparator
  must find restatements that agree only because both are vacuous.** This is
  the same concern as the non-vacuity gate of v1.

### 4.6 Lean on the board, resolved by PARALLAX

Ty did not decide if Lean statements become part of the ticket, because the
team is not ready to read Lean. PARALLAX removes this need. The board shows
STE100 text and a table of resolved divergences (concrete examples and the
answers of the human). The formal files (Lean, Z3, TLA+) stay in the repo. The
human answers examples, never formal syntax.

---

## Part 5. Honesty: structure, not request

### 5.1 Why AIDLC must enforce honesty

Ty added honesty as the third pillar: explainability and confession of
misalignment. The research shows that a polite request for honesty is not
sufficient.

**Agents rarely flag ambiguity on their own**

- **HumanEvalComm.** Jie JW Wu, Fatemeh H. Fard. "HumanEvalComm: Benchmarking
  the Communication Competence of Code Generation for LLMs and LLM Agent." ACM
  TOSEM, 2025. DOI 10.1145/3715109. https://arxiv.org/abs/2406.00215
  (Verified: fetched). It changes HumanEval descriptions so that they are
  inconsistent, ambiguous, or incomplete. Then it measures if models ask
  questions (Communication Rate, Good Question Rate). It proposes a
  question-asking agent, Okanagan.
- **Ambig-SWE.** Vijayvargiya, Zhou, Yerukola, Sap, Neubig. "Ambig-SWE:
  Interactive Agents to Overcome Underspecificity in Software Engineering."
  ICLR 2026. https://arxiv.org/abs/2502.13069 (Verified: fetched). It builds
  underspecified versions of SWE-bench Verified issues. Agents rarely tell
  full issues apart from underspecified issues. When agents do ask,
  performance improves by up to 74% over non-interactive settings. Caveat:
  simulated user. **Evidence at ticket level that divergence detection must
  be mechanical.**

**Agents game tests and reward signals**

- **ImpossibleBench.** Zhong, Raghunathan, Carlini. "ImpossibleBench: Measuring
  LLMs' Propensity of Exploiting Test Cases." arXiv 2510.20270, October 2025.
  https://arxiv.org/abs/2510.20270 (Verified: fetched). The researchers
  changed unit tests in LiveCodeBench and SWE-bench tasks so that the tests
  contradict the spec. Thus each pass counts as cheating. The strategies went
  from test edits to operator overloading. Prompts and test access changed the
  rates. Caveat: preprint.
- **METR 2025.** Von Arx, Chan, Barnes. "Recent Frontier Models Are Reward
  Hacking." METR report, June 5, 2025.
  https://metr.org/blog/2025-06-05-recent-reward-hacking/ (Verified: fetched).
  o3 reward-hacked in 30.4% of RE-Bench runs and in approximately 0.7% of
  HCAST runs. It patched evaluators and overwrote timers. When the researchers
  asked it afterwards, it admitted in 10 of 10 cases that the plan did not
  match user intent. "Please do not cheat" had little effect. Caveat: lab
  report, not peer reviewed.

Consequences for AIDLC:

- Oracles (tests written in Specification, models, reference implementations)
  are **read-only to the implementer**.
- Structure checks disclosure (records, gates, independent restatements). A
  request in the prompt is not sufficient.

**Models can report confidence, within limits**

- **Kadavath et al. 2022.** "Language Models (Mostly) Know What They Know."
  arXiv 2207.05221 (36 authors, Anthropic). https://arxiv.org/abs/2207.05221
  (Verified: fetched). Large models are fairly well calibrated. P(True)
  self-evaluation works, and it improves with scale. The calibration of "I
  know" estimates decreases on new tasks. Caveat: not peer reviewed.
- **Lin, Hilton, Evans 2022.** "Teaching Models to Express Their Uncertainty in
  Words." TMLR 2022. https://arxiv.org/abs/2205.14334 (Verified: fetched).
  Researchers can fine-tune GPT-3 to state calibrated confidence in words. It
  stays moderately calibrated under distribution shift. Caveats: fine-tuning,
  math tasks.

Consequence: a confidence field on disclosures is reasonable. But AIDLC must
treat it as a weak signal, not as a gate.

### 5.2 The honesty record (proposal)

The working name is ANOMALY. The research suggests **DISCLOSURE** instead
(Part 9). An agent files a DISCLOSURE in these conditions:

- It guessed.
- It disagreed with a requirement, a model, or another agent.
- It was not able to check something.
- It built something outside the claims.
- It found that its own earlier work was wrong.

Rules: filing is never a failure. Hiding is a failure. Disclosures are the main
input of the ratchet (Part 3.2). This is the **andon cord** from the Toyota
Production System. On that production line, any person can stop work when they
see a problem. POKAYOKE (mistake-proofing) comes from the same system, so the
metaphor is consistent.

### 5.3 Rice's theorem and the limit that never goes away

Ty cited Rice's theorem as the reason that perfect verifiable guarantees are
not always available. A refinement: Rice's theorem rules out a *general*
procedure that decides each non-trivial semantic property for *every* program.
It does not prevent a proof of a property of *one specific* program. Dafny,
Verus, and Lean proofs do that every day.

The permanent limit is different: **nothing can prove that a formal statement
equals what a human wants.** The reason is that the want itself is not formal.
That is why alignment is the correct objective, and why honesty is a pillar.
The process can always get to "no *known* disagreement among humans, agents,
and artifacts, within these bounds." Honesty stops the process from a claim of
more than that.

---

## Part 6. The AIMED and POKAYOKE route ladder

### 6.1 How routes, tools, and tiers relate

- **Tier**: How much of the request must be formal.
- **Tool**: The shape of each claim selects the tool, through the SPECTRUM
  classifier of Discovery (Part 7.3). Routes never name a single tool.
- **Route**: A rung that pairs *the form of the claim statement* with *the
  check of the code against that statement*. A check can never claim more than
  the statement supports. An AIMED ticket uses a WIFFLED route for its prose
  claims and one formal rung for each formalized claim.

The rungs go up as the distance between the formal statement and the shipped
code decreases. That distance (the correspondence gap) causes most of the
cost.

### 6.2 The ladder (current names, plus a renaming proposal)

Ty likes the names, but Ty cannot see the gradient from CORRIDOR to HARD DOCK.
Proposal: use the real rendezvous-and-docking sequence that crewed vehicles fly
to get to the ISS, in order. Each maneuver in that sequence is physically
closer to the station, so the order reads as a gradient.

| Rung | Current name | Proposed name | Tier | Statement | Fulfillment check |
|---|---|---|---|---|---|
| 1 | CORRIDOR (was SOUNDING) | PHASING | AIMED | Properties in the host language | Generated tests. A mutation score shows that the tests discriminate. |
| 2 | RELAY | HOMING | AIMED | A bounded model, selected by claim shape | The model generates the test cases. |
| 3 | SOFT DOCK | CLOSING | AIMED | A bounded model | The model runs next to the real code as an oracle. |
| 4 | EPHEMERIS | FINAL APPROACH | POKAYOKE | Each claim as a typed statement, plus an executable reference model | Differential testing of the code against the model. No proofs. |
| 5 | LAGRANGE | SOFT CAPTURE | POKAYOKE | Rung 4, plus proofs that the model meets the statements | Differential testing plus proof. |
| 6 | HARD DOCK | HARD DOCK | POKAYOKE | Proof on the shipped code itself | Proof. The gap decreases to the compiler, FFI, and environment. |

Alternative: keep the current names and add the rung number as a prefix. This
is not decided.

Ty asked for an explanation of these names:

- **CORRIDOR.** An entry corridor is the narrow band that a capsule must stay
  inside during reentry. If the angle is too steep, the capsule burns up. If
  the angle is too shallow, the capsule skips off. A property is the wall of
  the corridor. Generated inputs fly hundreds of entries through it. Mutation
  testing breaks the code intentionally, to check that the walls are real.
  Backup name: DISPERSION (Monte Carlo dispersion analysis).
- **LAGRANGE.** Lagrange points are positions between two bodies. At these
  points a spacecraft holds station, because the pulls balance. The James Webb
  telescope is at Sun–Earth L2. The implementation model is also between two
  bodies: requirements and code. Proof holds the model to the requirements.
  Conformance testing holds the model to the code. L2 is unstable, so Webb
  must burn fuel every few weeks. Likewise, the model needs a new check after
  every change.
- **SOFT DOCK / HARD DOCK.** These are the two real stages of docking. Soft
  capture latches loosely. Hard dock locks the structural seal.

### 6.3 Why "state before prove": the benchmark evidence

Ty holds that Lean (dependent type theory) is the most rigorous and specific
formal specification available. This document agrees, with one separation:
**the specificity of Lean comes from the statement of claims, not from their
proofs.** The benchmarks show that, for current models, a statement is much
cheaper than a proof.

- **VERINA.** Ye, Yan, He, Kasriel, Yang, Song. "VERINA: Benchmarking
  Verifiable Code Generation." ICLR 2026 (the venue is per search: arXiv lists
  no venue). https://arxiv.org/abs/2505.23135 (Verified: fetched). 189 Lean
  tasks. The benchmark scores code, spec, and proof separately. Best model
  (o3): 72.6% code, 52.3% sound and complete specs, **4.9% proofs**.
- **Vericoding benchmark.** "A benchmark for vericoding." arXiv 2509.22908
  (preprint. Verified: noted by the research agent, details as reported).
  12,504 specs across Dafny, Verus, Lean. Success: 82% Dafny, 44% Verus, 27%
  Lean.

Consequence: FINAL APPROACH / EPHEMERIS (typed statements and a reference
model, no proofs) is the practical entry to POKAYOKE today. SOFT CAPTURE /
LAGRANGE and HARD DOCK are the rungs for later, as LLM proof skill improves.
Today, Dafny is easier than Lean for models. This fact is relevant when Ty
selects the HARD DOCK language.

### 6.4 The industrial precedent for rungs 4–6

- **Cedar, verification-guided development.** Disselkoen, Eline, He, Headley,
  Hicks, Hietala, Kastner, Mamat, McCutchen, Rungta, Shah, Torlak, Wells. "How
  We Built Cedar: A Verification-Guided Approach." FSE Companion 2024
  (Industry), pp. 351–357. DOI 10.1145/3663529.3663854.
  https://arxiv.org/abs/2407.01688 (Verified: fetched). AWS built an
  executable model of the Cedar authorization language in Lean. AWS proved
  properties about the model. AWS checked the Rust production code against the
  model with differential random testing. Property-based testing covered the
  parts that the model does not include. Proofs found 4 validator bugs. The two
  testing methods found 21 more. **This is the LAGRANGE / SOFT CAPTURE rung,
  done at scale.** Note that testing found more bugs than proof. The
  model-as-oracle does most of the work.
- **Cedar language paper.** Cutler, Disselkoen, …, Wells (15 authors). "Cedar: A
  New Language for Expressive, Fast, Safe, and Analyzable Authorization."
  PACMPL 8(OOPSLA1), Art. 118, 2024. DOI 10.1145/3649835.
  https://arxiv.org/abs/2403.04651 (Verified: fetched).

### 6.5 HARD DOCK without a requirement for Dafny (a constraint from Ty)

Ty: Dafny is fine, but other people possibly do not use it. The finished
product must conform to the project patterns in the necessary language,
possibly through an LLM translation step. Proposal: the proof is in any
verification-aware language (Dafny, Lean, Verus, F*, Why3, SPARK). There are
two delivery variants:

- **Compiled.** The verified code compiles to the target language. The proof
  carries over to the shipped code, if you trust the compiler. Generated code
  rarely fits the project style. Thus it goes behind a facade in normal project
  style.
- **Translated.** An LLM rewrites the verified version as idiomatic project
  code. The compiled verified version becomes the reference oracle. A check of
  equivalence runs on generated inputs, or exhaustively up to a bound. The
  honest claim is weaker: "proved for the reference; project code matches it
  over the tested inputs." The record must name the variant that the ticket
  used. Each translation is a hand-off, so it is a PARALLAX boundary.

Evidence for the compiled variant in .NET:

- **AWS Encryption SDK.** https://github.com/aws/aws-encryption-sdk (Verified:
  fetched). One verified Dafny source transpiles to .NET, Rust, and Go.
  smithy-dafny (Polymorph) generates glue code that wraps the Dafny API in an
  idiomatic API for each language. The NuGet package
  `AWS.Cryptography.EncryptionSDK` depends on DafnyRuntime (the NuGet details
  come from search).
- **Dafny C# integration docs.**
  https://dafny.org/latest/DafnyRef/integration-cs/IntegrationCS (Verified:
  fetched). Targets: C#, Java, JavaScript, Go, Python, C++. Rust is newer and
  experimental. Generated C# uses runtime types: `int` → `BigInteger`,
  `seq`/`string` → `Dafny.ISequence`, `Dafny.ISet`/`IMap`, and top-level
  functions in a `__default` class. Interop goes through `{:extern}`. There are
  known Int32 overflow bugs in multisets (Dafny issue #5554, search only).
  **Raw output is not idiomatic C#. Plan for a facade and bounded newtypes.**

Evidence for the translated variant (LLM translation with equivalence checks):

- **VERT.** Yang, Takashima, Paulsen, Dodds, Kroening. "VERT: Verified
  Equivalent Rust Transpilation with Large Language Models as Few-Shot
  Learners." arXiv 2404.18852, 2024. https://arxiv.org/abs/2404.18852
  (Verified: fetched). It builds an oracle Rust program through WebAssembly.
  Then it checks the readable Rust from the LLM against that oracle. On 1,394
  programs, the rate of passing property tests increased from 31% to 54%. The
  rate of passing bounded model checking increased from 1% to 42%. VERT is the
  only one of the three with a formal (bounded) check.
- **Syzygy.** Shetty, Jain, Godbole, Seshia, Sen. "Syzygy: Dual Code-Test C to
  (safe) Rust Translation using LLMs and Dynamic Analysis." arXiv 2412.14234,
  2024 (preliminary version at LLM4Code 2025).
  https://arxiv.org/abs/2412.14234 (Verified: fetched). It translates code and
  tests together, step by step. At each step it checks equivalence on inputs.
  It translated Zopfli (approximately 3,000 lines, 98 functions). The check is
  test-based, not formal.
- **FLOURINE.** Eniser, Zhang, David, Wang, Christakis, Paulsen, Dodds,
  Kroening. "Towards Translating Real-World Code with LLMs: A Study of
  Translating to Rust." arXiv 2405.11514, 2024.
  https://arxiv.org/abs/2405.11514 (Verified: fetched). It checks translations
  with differential fuzzing and feeds counterexamples back to the model. The
  best of five LLMs succeeded on 47% of real-world benchmarks. **The
  counterexample that goes back to the model is exactly a PARALLAX
  divergence.**

### 6.6 Tools for each rung on the stack of this team (status as of 2026-10-13)

C# / .NET:

| Tool | Use | Status | Source |
|---|---|---|---|
| CsCheck | C#-first property-based testing, model-based testing, `SampleParallel` linearizability checks, strong shrinking | 4.9.1 (2026-09-17). 5.0.0-rc1 (2026-10-11). **Best C# fit.** | https://github.com/AnthonyLloyd/CsCheck (fetched) |
| FsCheck | Mature .NET PBT that you can use from C#. State-machine testing is "Experimental". | 3.4.0 (2026-08-20) | https://fscheck.github.io/FsCheck/ (fetched) |
| Stryker.NET | Mutation testing: proves that tests and specs constrain the code | 5.0.0 (2026-09-11), runs on .NET 10 | https://github.com/stryker-mutator/stryker-net/releases (fetched) |
| Microsoft.Z3 | SMT from C# | **nuget.org is stale at 4.12.2 (2023-05).** The current Z3 5.1.0 (2026-08) ships the `.nupkg` as a GitHub release asset. Use that asset or a private feed. | https://www.nuget.org/packages/Microsoft.Z3 (fetched) |
| Microsoft Coyote | Systematic testing of async/actor interleavings. `Specification.Monitor` state machines with hot/cold liveness states. "not a verification system" | 1.7.11 (2024-03-18). Low activity, with maintenance commits in 2026. Still the best .NET concurrency choice. | https://microsoft.github.io/coyote/ (fetched) |
| Dafny → C# | Compiled HARD DOCK | 4.11.0 stable (2025-08-25). Nightly builds every day. | https://github.com/dafny-lang/dafny (fetched) |
| InferSharp | Static null, leak, race, and taint analysis | v1.5 (2023-05). **Effectively unmaintained.** Do not use. | https://github.com/microsoft/infersharp (fetched) |
| Nullable reference types | Static null contracts. "entirely a compile-time feature". `[NotNullWhen]`, `[MemberNotNull]` | Default in new templates | https://learn.microsoft.com/en-us/dotnet/csharp/nullable-references (fetched) |
| Guard libraries | Preconditions only | Ardalis.GuardClauses 5.0.0 (2024-09, active). CommunityToolkit.Diagnostics 8.4.2 (2026-03). Dawn.Guard is stale. | NuGet API (fetched) |
| MS Code Contracts | Old .NET design-by-contract | **Not supported on .NET 5+**, and the repo is archived. The docs say to use nullable reference types instead. **Do not use.** | https://learn.microsoft.com/en-us/dotnet/framework/debug-trace-profile/code-contracts, https://github.com/microsoft/CodeContracts (fetched) |

No maintained C# library covers postconditions or invariants. A practical C#
contract stack is: nullable reference types + guard clauses + `Debug.Assert` +
Roslyn analyzers + property-based tests.

React / JavaScript / TypeScript:

| Tool | Use | Status | Source |
|---|---|---|---|
| fast-check | The standard JS/TS PBT library. Model-based commands. | 4.10.2 (2026-09-19) | npm API (fetched) |
| StrykerJS | Mutation testing | 10.0.0 (2026-08-14) | npm API (fetched) |
| XState graph | Model-based test paths from statecharts | `@xstate/graph` and `@xstate/test` are **deprecated**. Use the `xstate/graph` subpath (`createTestModel`, `getShortestPaths`) in `xstate` 5.33.2. | https://stately.ai/docs/graph (fetched) |
| zod, typia | Schema validation at I/O boundaries | zod 4.6.7, typia 15.1.0 | npm API (fetched) |
| decorator-contracts | `@invariant` / `@demands` / `@ensures` | 1.0.0 (2025-05). Small project. | https://github.com/final-hill/decorator-contracts (search only) |

Language-neutral model tools:

| Tool | Use | Status | Source |
|---|---|---|---|
| Quint | A TLA+-family spec language. `quint run --mbt --out-itf` writes ITF JSON traces with `mbt::actionTaken` and `mbt::nondetPicks` for model-based testing. | v0.33.0 (2026-09-28). The repo moved to `quint-co/quint`. The only first-class driver is for Rust (Quint Connect, 2025-12). **For C# or TS, write the ITF driver yourself.** | https://quint.sh/docs/model-based-testing (fetched) |
| TLA+ trace validation | Instrument the program so that it logs variable updates. TLC checks the trace against the spec. | Cirstea, Kuppe, **Loillier**, Merz. "Validating Traces of Distributed Programs Against TLA+ Specifications." SEFM 2024, LNCS 15280. It found mismatches in every case study. | https://arxiv.org/abs/2404.16075 (fetched) |

Map of tools to rungs:

- **CORRIDOR / PHASING**: CsCheck or FsCheck + Stryker.NET. Also fast-check +
  StrykerJS.
- **RELAY / HOMING**: Z3 models as fixtures. Quint or TLA+ traces as test
  cases. XState paths into Playwright.
- **SOFT DOCK / CLOSING**: Z3 inside tests as an oracle. TLA+ trace
  validation. Coyote monitors for async C#.
- **EPHEMERIS / FINAL APPROACH and LAGRANGE / SOFT CAPTURE**: A Lean or Dafny
  reference model that the C# test harness calls as a differential oracle
  (Cedar pattern).
- **HARD DOCK**: Dafny compiled to C# behind a facade, or translated with an
  equivalence check.

Other ecosystems, for adaptability. A research agent fetched each source in
this table, unless the table says otherwise:

| Language | Tool | Kind | Status | Source |
|---|---|---|---|---|
| Java | JML / OpenJML | Static (ESC) and runtime (RAC) contracts | 21.0.28 (2026-10-01), active | https://github.com/OpenJML/OpenJML |
| C | ACSL / Frama-C | WP static proof. E-ACSL runtime. | v33 "Arsenic" | https://frama-c.com/html/get-frama-c.html |
| Ada | SPARK | Static proof, certification support | Industrial | https://www.adacore.com/about-spark |
| Rust | Verus | Static proof of a Rust subset | Rolling releases (2026-10-12) | https://github.com/verus-lang/verus |
| Rust | Kani | Bounded model checking (CBMC). Contracts are experimental. | 0.68.0 (2026-09-16) | https://github.com/model-checking/kani |
| Rust | Creusot | Deductive proof (Why3) | v0.14.0 (2026-10-12) | https://github.com/creusot-rs/creusot |
| Rust | Prusti | Static (Viper) | **Stalled since 2024-03.** Do not use. | https://github.com/prusti/prusti |
| Python | CrossHair | SMT symbolic execution for contract counterexamples | v0.0.111 (2026-09-28) | https://github.com/pschanely/CrossHair |
| Python | icontract | Runtime decorators, correct inheritance | 2.7.3 (2026-01-29) | https://github.com/Parquery/icontract |
| Python | deal | Runtime + linter + Hypothesis generation + Z3 | 4.24.6 (2025-11-30) | https://github.com/life4/deal |
| Eiffel | Design by contract | Runtime `require`/`ensure`/`invariant` | Mature, niche. The origin of DbC. | https://www.eiffel.org/doc/solutions/Design_by_Contract_and_Assertions |

### 6.7 Decision guide for checks at code level

- **Static contracts** (SPARK, Dafny, Verus, Creusot, Frama-C WP, OpenJML ESC):
  Select these when defects are costly, the code is small and stable, the spec
  fits pre/postconditions and invariants, and there is a proof budget. For C#,
  do the proof in Dafny and compile the result behind a facade.
- **Runtime contracts** (icontract, deal, guard clauses, JML RAC, E-ACSL,
  Eiffel): Select these when proof is too expensive, but each test and
  production run must act as an oracle. Also select them when contracts must
  survive refactoring by LLM agents.
- **Runtime-verification monitors** (LARVA, JavaMOP, DejaVu, TeSSLa, Copilot,
  Coyote monitors): Select these when the property spans many calls, objects,
  or time (protocols, deadlines, per-entity rules, "every open has a close").
  Also select them when verdicts must come from deployed systems or logs. They
  are parked for v2 (see Part 8).
- **Property-based tests as executable specs** (CsCheck, FsCheck, fast-check,
  Hypothesis/CrossHair): This is the default rung. When a bounded model
  exists, upgrade to model-based PBT (Quint ITF, XState paths). Measure the
  test strength with Stryker.

---

## Part 7. Discovery (drafted)

### 7.1 Placement and lanes (decided by Ty)

Intent → **Discovery** → ticket → classification → Specification →
Implementation → Verification → landing.

- Discovery occurs before the ticket exists, and it forms the ticket. An issue
  or a feature claim comes in. Discovery models it to get specifics before
  anybody builds something. WIFFLED has no Discovery.
- Humans work in Discovery, Specification, and Verification. LLMs do all of
  Implementation. The human is the final gate on landing and deploying.
- After the human ratifies the ticket and the spec, Specification,
  Implementation, and Verification can loop autonomously. Implementation never
  starts a loopback. Only Specification and Verification start loopbacks.

### 7.2 Discovery steps (draft)

| Step | What it does | Orbital ancestor |
|---|---|---|
| SIGNAL | Restates the report as one falsifiable, scoped hypothesis. Or it stops and asks the human. | proposition sharpening |
| FLYBY | Surveys only the slice of the system that the report touches. Reproduces the defect, or shows that the feature is absent. "Nothing to build" goes directly to GO / NO-GO. | close-world |
| SPECTRUM | Divides the hypothesis into labeled claims. Each claim cites the report. An uncited claim is scope creep, and it becomes a proposed ticket change. Classifies the shape of each claim and selects the cheapest tool that can falsify it. | decompose-proposition |
| TRAJECTORY | States each claim in its tool. Verdict: holds / violated / gap. Does the load-bearing check. Records the negation basis (absent vs contradicts). | model-obligations |
| SHAKEDOWN | A separate agent tries to break each claim within a budget. It sees only the report and the claim. Result: refuted / inconclusive / abstained. The agent never weakens a claim to absorb a witness. | disprove-proposition |
| GO / NO-GO | The human ratifies the ticket (go), closes it with evidence (no-go), or sends it back to a named step (hold). Only the human changes scope. | human review |

Stopping rule: each claim has a statement in at least one tool that can
falsify it. Also, the most recent tool or attack found nothing new.

### 7.3 The tool classifier of SPECTRUM

| Claim shape | Cheapest tool that can falsify it |
|---|---|
| A measurable quantity | A calculator or a script |
| Behavior today | A reproduction or a failing test |
| Structure of the code | Code reading, search, or a Prolog KB for each ticket |
| Rules, permissions, configuration combinations, arithmetic limits | SMT (Z3, cvc5) |
| Order, concurrency, retries, state over time | TLA+ (or Quint) |
| Structure, relations, data model | Alloy 6 (proposed addition) |
| A universal property of an algorithm or calculation | Lean |

The point of Ty: Z3, cvc5, and TLA+ are not always necessary. The classifier
exists so that AIDLC uses the cheapest falsifier first. Lean is the
specificity ceiling. TLA+ and SMT are the fastest refuters.

### 7.4 Gaps in the discovery draft

- The draft defines scope, but it does **not define risk**. Decided: Discovery
  needs a risk output to feed classification. The risk output gives the
  stakes, the blast radius, and the kinds of mistakes that agents tend to make
  on this shape of claim.
- The draft needs links to PARALLAX and DISCLOSURE. Its answered open items
  must also be closed.

---

## Part 8. Runtime verification and LARVA (Ty asked for depth)

Runtime verification is parked for the first version of v2. But Ty wanted to
understand it, and it is important for the autonomous, observable future.

### 8.1 Two families of "annotation language"

The research separated two jobs. People call both of them annotation:

1. **Code annotations** describe what the code must do, and they travel with
   the code. Examples are contracts (JML, Dafny, SPARK, ACSL) and runtime
   monitors (LARVA). Select by two factors. First: does the check occur
   before the run, during the run, or both? Second: which languages does the
   tool support?
2. **Process annotations** describe what we know about the work and why. This
   is the record of evidence, decisions, and traceability. Prolog is in this
   family (Part 9). Select by the questions that the record must answer.

LARVA is in family 1.

### 8.2 LARVA

**What it is.** LARVA is a runtime-verification compiler for Java. A `.lrv`
script of DATE automata compiles to AspectJ monitors. Then `ajc` weaves these
monitors into the program. Authors: Christian Colombo, Gordon Pace, Gerardo
Schneider (University of Malta, and Chalmers / Gothenburg).

**Repo.** https://github.com/ccol002/larva-rv-tool (Verified: fetched). It is
active again. The first GitHub release, `v1.0.0-larva`, was on 2026-09-07. It
needs JDK 17+ (validated on 21) and AspectJ 1.9. It has an MIT license. A
University of Malta course uses it. Recent commits come from `claude/...`
branches, so AI helped with the cleanup.

**DATE formalism** (Dynamic Automata with Timers and Events). Sources: FMICS
2008 (published LNCS 5596, 2009) and SEFM 2009, "LARVA — Safer Monitoring of
Real-Time Java Programs." https://www.researchgate.net/publication/220992830
and https://www.researchgate.net/publication/220791179 (Verified: search
only). The DATE formalism has these features:

- Symbolic automata that communicate over channels.
- Transitions that read `event \ guard \ action`.
- Events: method calls, exceptions, timer/clock firings, channel messages.
- Local variables, and per-object replication with `FOREACH`.
- State kinds: `BAD`, `NORMAL`, `STARTING`, `ACCEPTING`.
- Clocks, declared as `Clock c`. Clocks fire events such as `c@5`. Timeouts
  can reset on each new event.
- Actions that can run recovery code, not only report.

**Example.** This is a shorter version of `bank.lrv` from the repo (Verified:
fetched):

```
GLOBAL{
 VARIABLES{ int userCnt = 0; }
 EVENTS{ addUser() = {*.addUser()}  deleteUser() = {*.deleteUser()} }
 PROPERTY users{
  STATES{ BAD{toomany{}} NORMAL{ok{}} STARTING{start{}} }
  TRANSITIONS{
   ok -> toomany [addUser()\userCnt > 5]
   ok -> ok      [addUser()\\userCnt++;]
   ok -> ok      [deleteUser()\\userCnt--;] } } }
```

How to read it: the monitor starts in `ok`. Each `addUser()` call increments a
counter. If the guard `userCnt > 5` holds when the program adds another user,
the monitor moves to the `BAD` state `toomany`.

**Strengths.** First-class timers (real-time properties). Per-entity
replication. Recovery actions. Teams used LARVA on industrial
financial-transaction systems (Colombo and Pace, chapter 7 of *Lectures on
Runtime Verification*).

**Weaknesses.** Java only. It depends on AspectJ weaving. It has a small
academic community. Specs contain Java code, so they are not portable. **There
is no .NET or JavaScript port.**

**Select it** for Java systems whose rules are about event order, deadlines,
or one monitor per object.

### 8.3 The LARVA family

| Variant | Source | What it adds | Status |
|---|---|---|---|
| ppDATE / StaRVOOrS | https://github.com/mchimento/StaRVOOrS-tool (fetched via API. Papers: search only.) Ahrendt, Chimento, Pace, Schneider: FM'15, RV'15, FMSD 2017. Chimento and Ahrendt lead it. | Adds JML-style Hoare triples to DATE states. **KeY first tries to prove each pre/postcondition. It drops fully proved triples. It gives narrower preconditions to partly proved triples. LARVA monitors only the remainder at runtime.** | Research-grade. Last push 2022. |
| polyLarva | http://www.cs.um.edu.mt/svrg/Tools/PolyLarva/ and arXiv 1302.5169 (search only). Colombo, Francalanza, Mizzi, Pace (SEFM 2012, FESCA 2013). | Language-agnostic. Rules `event \| condition ↦ action`. The monitor runs in a separate process. Used on mixed C and Java. | No maintained release |
| ContractLarva | https://github.com/gordonpace/contractLarva (fetched). Pace, Ellul, Azzopardi. | Weaves DATE monitors into Solidity source | v0.2.4-alpha (2023-03-28) |
| dLarva | Search only | Automata that make states during the run | Not relevant |

**The idea worth stealing is StaRVOOrS**, even if AIDLC never uses the tool.
It is the tier logic in tool form: *prove what you can. Check the remainder in
a different way. The record says which claims got which treatment.* That is a
precise honesty pattern for the route ladder: each claim has a tag with the
strongest check that it actually received.

### 8.4 Standard references for runtime verification

- **Bartocci & Falcone (eds.). *Lectures on Runtime Verification: Introductory
  and Advanced Topics*.** LNCS 10457, Springer, 2018. DOI
  10.1007/978-3-319-75632-5 (Verified: fetched via Crossref. The Springer page
  requires login). It has tutorial chapters on concurrency errors, monitoring
  of data-carrying events (Havelund et al.), failure prevention,
  cyber-physical systems, decentralized RV, and the Colombo/Pace industrial
  chapter. It is the standard textbook.
- **"Introduction to Runtime Verification."** Bartocci, Falcone,
  **Francalanza, Reger**. Pages 1–33 of the book in the item before this one.
  DOI 10.1007/978-3-319-75632-5_1 (Verified: fetched via Crossref). It defines
  monitors, traces, verdicts, instrumentation, and online vs offline
  monitoring.

### 8.5 Other runtime-verification languages

| Tool | Source | Spec style / what it monitors | Status | Select when |
|---|---|---|---|---|
| JavaMOP | https://github.com/runtimeverification/javamop (fetched) | Java through AspectJ. Parametric monitors. Pluggable logics FSM, ERE, LTL, CFG. | Dormant. Last release 4.4 (2016), last commit 2020. | Java API-protocol checks ("never use an Iterator after modification") |
| RV-Monitor | https://link.springer.com/chapter/10.1007/978-3-319-11164-3_24 (search) | Commercial JavaMOP successor (RV 2014). 150+ Java API specs. | Proprietary, unclear | Commercial Java/Android |
| TeSSLa | https://www.tessla.io/ (fetched) | Stream-based. Derives typed streams from events and logs. Compiles to Rust and other targets. | 2.1.0 (2024-07-02) | Trace and log analysis, including hardware traces |
| Lola | https://software.imdea.org/~cesar/papers/dangelo05lola.pdf (search) | The original stream-equation language, D'Angelo et al., TIME 2005 | Paper | Background |
| RTLola | https://github.com/reactive-systems/RTLola-Interpreter (fetched) | Real-time stream language from Lola. CISPA. | Crates 0.11.0 (2025-05-15) | Drones, cyber-physical telemetry, rates, sliding windows |
| Copilot | https://github.com/Copilot-Language/copilot (fetched) | Haskell-embedded stream DSL that generates constant-time, constant-memory C99 monitors. NASA funded it. Galois and NIA built it. | Active, v4.8.1 (2026-09-08) | Hard real-time embedded C |
| MarQ / QEA | https://github.com/selig/qea (fetched) | Quantified Event Automata. Online or offline. Won CRV'14 tracks (Reger, Cruz, Rydeheard, TACAS 2015). | Dormant since 2020 | Offline log checks |
| DejaVu | https://github.com/havelund/dejavu (fetched) | First-order past-time LTL with timing and recursive rules. BDDs. Offline CSV logs. Havelund, Peled, Ulus. | v2.1 (2024-03). Pushed 2026-07. | Rules that compare data over logs ("close(f) needs an earlier open(f)") |
| Coyote monitors | https://microsoft.github.io/coyote/ (fetched) | C# `Specification.Monitor` state machines with hot/cold states. They run during systematic testing, not in production. | 1.7.11 | The closest thing to LARVA inside .NET tests |
| NodeMOP | https://atlarge-research.com/pdfs/2019-nodemop-fschiavio.pdf (search) | JavaMOP-style monitors for Node.js (2019) | Research prototype | Not ready for production |

**.NET has no maintained runtime-verification language.** The practical
options are:

- Coyote monitors in tests.
- OpenTelemetry `ActivitySource` events, exported and checked offline with
  DejaVu, TeSSLa, or TLA+/Quint trace validation.

---

## Part 9. The evidence language (undecided, and Ty wants to sync on this)

### 9.1 The question to answer first

Select the record language by the questions that the record must answer:

| Question | Best fit |
|---|---|
| What is blocking? Which claims have no evidence? Which load-bearing cell is blank? | Datalog-style rules. Any engine. |
| Why do we believe this claim, and why do we *not* believe that one? | s(CASP) justification trees |
| What became stale after this change? | Recursive derivation rules. Datalog does this well. |
| Was this approval for *this exact* artifact? | Content digests, as in in-toto attestations |
| What is the smallest test set that still guards every claim? | clingo (search and optimization) |

There is one more question. Is the record mainly **for Ty to query** during
brainstorms and reviews? Or is it **for a future orchestrator to run**? The
first choice favors SWI-Prolog + s(CASP). The second choice favors typed
Datalog that always terminates (Soufflé).

### 9.2 Principle: keep the vocabulary separate from the engine

- AIDLC borrows vocabularies from maintained standards, so that the names do
  not drift.
- AIDLC writes records as ground facts in the syntax that Prolog and Datalog
  share. Then SWI-Prolog, Soufflé, s(CASP), and clingo can all read them
  later.
- The caveat of Ty: the vocabulary of AIDLC itself (orbital) must not conflict
  with the borrowed standards (Part 9.5).
- The worry of Ty: over-processing. Proposed rule: **every record needs a
  reader** (a gate query or a human view). A record that nobody reads is
  waste.

### 9.3 Logic engines

| Engine | Source | Status | Data model | Terminates? | Explanations | Pick when |
|---|---|---|---|---|---|---|
| SWI-Prolog | https://www.swi-prolog.org/download/stable, https://www.swi-prolog.org/pldoc/man?section=tabling (fetched) | 10.0.2 stable (changelog 2026-03-14). Dev 10.1.18. | Horn clauses. Turing-complete. Tabling with well-founded semantics. | No (tabling stops left-recursion, but infinite answers use all the memory) | None built in. Use a meta-interpreter or s(CASP). | Existing Prolog KBs. One host for facts, rules, and s(CASP). |
| Soufflé | https://souffle-lang.github.io/provenance, https://github.com/souffle-lang/souffle/releases (fetched) | 2.5 | Typed relations (`.decl`). Compiles to parallel C++. | Yes for pure Datalog (arithmetic can break this) | `-t explain` gives minimal-height proof trees. `explainnegation` is partial. The docs say that automatic explanation of non-existence is "not technically feasible". | Batch, deterministic, typed derivation with proof trees. CI gates. |
| Mangle | https://github.com/google/mangle, https://codeberg.org/TauCeti/mangle-go (fetched) | Very active (commit 2026-10-12). **"not and never was an officially supported Google product"**. It is now independent on Codeberg. | Datalog + aggregation, functions, temporal facts, optional types. Go and Rust. | **No** (the README says that extensions give up guaranteed termination) | An emerging provenance package (2026) | An embeddable Go engine with temporal facts |
| DDlog | https://github.com/vmware-archive/differential-datalog (fetched) | **Archived 2026-07-13.** The authors moved to Feldera (SQL/DBSP). | — | — | — | Never, for new work |
| CozoDB | https://github.com/cozodb/cozo (fetched) | v0.7.6 (2023-12). "still very young". Stalled. | CozoScript Datalog, graph algorithms, time travel, vectors | No with aggregation in recursion | None | Do not use (maintenance risk) |
| s(CASP) | https://github.com/SWI-Prolog/sCASP, https://gitlab.software.imdea.org/ciao-lang/sCASP (fetched) | Maintained (Arias et al., IMDEA). The SWI port claims ~10× speed. | Goal-directed answer-set programming with constraints. No grounding. Default negation `not p` and classical negation `-p`. | No (loop detection only) | **Best in class**: `--tree`, `--human`, `--html`. `scasp/2` returns the tree as a term. | "Why" and "why not" over defeasible rules (defeaters, gaps) |
| clingo | https://potassco.org/clingo/, https://pypi.org/project/clingo/ (fetched) | 5.8.2 (2026-08-14). clingo 6 is in development. | Ground-and-solve ASP. Multi-shot. Optimization. | Yes on finite domains | Third-party (xclingo) | Search and optimization (minimal test set, counterexample model) |

**Why s(CASP) fits orbital closely.** It makes a distinction between `not p`
("p cannot be shown", negation as failure) and `-p` ("p is shown false",
classical negation). That is exactly the orbital distinction between
**absent** and **contradicts**, built into the language. Its justification
trees are the honesty pillar in machine form: each conclusion has its
"because".

**SRI's Evidential Tool Bus (ETB, ETB2).** ETB used Datalog for two jobs. It
held claims, rules, and evidence. It was also a workflow script that
integrates verification tools (Cruanes, Hamon, Owre, Shankar. VMCAI 2013.
https://link.springer.com/chapter/10.1007/978-3-642-35873-9_18, search only).
ETB1 is Python 2.7, and its development stopped in approximately 2015. The
DesCert team used ETB2 for CI/CD evidence tracking (Shankar et al., DASC 2024,
search only). `github.com/SRI-CSL/etb2` returned 404. A separate fortiss
project also has the name ETB2. **ETB is a design precedent, not software to
adopt.** But it is the nearest ancestor of "a Datalog ledger that drives
verification tools". A deterministic AIDLC router goes in that direction.

### 9.4 Standards to borrow vocabulary from

**Assurance cases**

**Assurance 2.0** (Bloomfield and Rushby, SRI and City/Adelard). The latest
report is SRI-CSL-25-01 (December 2025).
https://www.csl.sri.com/users/rushby/assurance2.0,
https://arxiv.org/html/2004.10474 (Verified: fetched). Its concepts are:

- Claims, argument steps, evidence, side-claims.
- Five CAE building blocks: decomposition, substitution, concretion,
  calculation, evidence incorporation.
- Defeaters (undercutting and rebutting), residual doubts, confirmation
  measures, indefeasibility, countercases.

Fit: defeaters map to the refuted verdict of orbital. They also map to the v1
rule "a known counterexample requires disposition." Residual doubts map to
residual risk.

**Clarissa** (https://arxiv.org/abs/2408.11699, Verified: fetched). It is built
on **ASCE** from Adelard (Honeywell, Adelard/NCC, SRI, UT Dallas, DARPA ARCOS).
An LLM translates claims into logic. **s(CASP) checks consistency,
well-formedness, completeness, and indefeasibility.** Clarissa is available
from Adelard. Correction to an earlier claim by the author of this document:
Clarissa is not "built on s(CASP)". s(CASP) powers its semantic-analysis
component. Advice: borrow the concepts of Assurance 2.0, not necessarily the
tool.

**GSN Community Standard** (SCSC Assurance Case Working Group). Version 3
(SCSC-141C, May 2021) is still current. The research found no v4.
ISO/IEC/IEEE 15026-2:2022 refers to it (search). https://scsc.uk/gsn-standard,
https://arxiv.org/html/2506.11023 (Verified: fetched). The nodes are Goal,
Strategy, Solution, Context, Assumption, and Justification. There are
extensions for modules, patterns, confidence, and dialectic (defeaters, "in
doubt", "defeated"). GSN is a metamodel only, with no normative serialization.
gsn2x (YAML) and OntoGSN (OWL) are third-party. **GSN is good as a generated
human view.**

**OMG SACM.** 2.3 is the current formal version (October 2023, XMI
metamodel). 2.4 Beta 1 (September 2026) is a major rewrite that is still
changing. https://www.omg.org/spec/SACM/ (Verified: fetched).
AssertionDeclaration values: asserted, needsSupport, assumed, axiomatic,
defeated, asCited (from search, SACM 2.2 PDF). Use SACM only for tool
interchange. Skip it for now.

**Provenance**

**W3C PROV.** PROV-DM, PROV-O, PROV-N, and PROV-CONSTRAINTS became W3C
Recommendations on 30 April 2013. The Working Group is closed. The standards
are frozen and stable. https://www.w3.org/TR/prov-overview/,
https://www.w3.org/TR/prov-dm/, https://www.w3.org/TR/prov-o/,
https://www.w3.org/TR/prov-n/ (Verified: fetched). Its parts are:

- Core types: Entity, Activity, Agent.
- Relations: used, wasGeneratedBy, wasDerivedFrom (revision, quotation,
  primary source), wasAttributedTo, wasAssociatedWith (with a Plan),
  actedOnBehalfOf, wasInvalidatedBy. Also Bundle (provenance of provenance).
- **PROV-N**: a functional syntax, for example `wasGeneratedBy(e1, a1, -)`. It
  maps almost one-to-one onto Prolog/Datalog facts.

Fit: PROV is the layer of the ledger that records "who produced what, from
what, by which activity". `wasInvalidatedBy` is a ready-made name for "this
approval went stale."

**Supply-chain attestations**

**in-toto Attestation Framework + DSSE.** CNCF Graduated (10 February 2025,
announced April 2025. The graduation date comes from search). Attestation spec
v1.2. https://github.com/in-toto/attestation/blob/main/spec/README.md,
https://github.com/in-toto/attestation/blob/main/spec/v1/statement.md,
https://github.com/secure-systems-lab/dsse/blob/master/envelope.md
(Verified: fetched). Its parts are:

- Layers: Predicate, Statement, Envelope, Bundle.
- Statement: `_type` = `https://in-toto.io/Statement/v1`, `subject[]` (each
  MUST have a digest, and the match is only by digest), `predicateType`,
  `predicate`.
- Vetted predicates: test-result (PASSED / WARNED / FAILED plus test lists),
  VSA (verification summary), provenance, release, runtime-trace.
- DSSE v1.0.2: payload, payloadType, `signatures[{keyid, sig}]`.

Fit: **approvals bound to artifact digests**. They are tamper-evident. A
deterministic orchestrator can check them without trust in the LLM. Cost: key
management and predicate design. Use them only at gates (ratification,
implementation authorization, release), never for each claim.

**SLSA provenance v1.2** ("Approved". It adds a Source Track.)
https://slsa.dev/spec/v1.2/provenance (Verified: fetched). Predicate
`https://slsa.dev/provenance/v1`, with buildDefinition and runDetails. SLSA
records builds. It is too narrow for requirements.

**Lifecycle traceability**

**OASIS OSLC.** Core 3.0 is an OASIS Standard. RM 2.1 (2021-06-21) and QM 2.1
(2022-01-19) are OASIS Standards. https://open-services.net/specifications/,
RM vocab
https://docs.oasis-open-projects.org/oslc-op/rm/v2.1/os/requirements-management-vocab.html,
QM vocab
https://docs.oasis-open-projects.org/oslc-op/qm/v2.1/os/quality-management-vocab.html
(Verified: fetched). RM links: satisfiedBy/satisfies, validatedBy,
implementedBy, elaboratedBy, specifiedBy, decomposedBy, constrainedBy,
trackedBy, affectedBy. QM: TestCase, TestResult, TestExecutionRecord,
validatesRequirement. Fit: **link names for the traceability chain**
(requirement → test → implementation) that other tools understand.

**OMG ReqIF 1.2** (July 2016). XML interchange between requirements tools
(DOORS, Polarion). https://www.omg.org/spec/ReqIF/ (Verified: fetched). Use it
only if interchange becomes necessary.

**Requirements as code**

| Tool | Source | Status | What it is |
|---|---|---|---|
| TRLC (BMW) | https://github.com/bmw-software-engineering/trlc (fetched) | 3.1.0 | Typed requirement records with `checks` blocks. Optional CVC5 `--verify`. |
| LOBSTER (BMW) | https://github.com/bmw-software-engineering/lobster (fetched) | 1.0.6 | Common `.lobster` JSON + tracing policy. Coverage report requirement → code → test. Extractors for Python, C++, GoogleTest, TRLC, Codebeamer. **A cheap traceability gate in CI.** |
| StrictDoc | https://pypi.org/project/strictdoc/ (fetched) | 0.30.2 (2026-10-09) | `.sdoc` text format, HTML export, server |
| sphinx-needs | https://pypi.org/project/sphinx-needs/, https://sphinx-needs.readthedocs.io/en/latest/schema/index.html (fetched) | 8.5.0 (2026-09-03) | Typed needs and links. JSON-Schema validation with `network_back` (for example, "every requirement has a test"). |
| Doorstop | https://pypi.org/project/doorstop/ (fetched) | 3.2 (2026-07-10) | One YAML item per file in git, document tree, link checks |

**Schema and constraint languages**

- **CUE** v0.17.1 stable, v0.18.0-alpha.3. CUE is pre-1.0, so breaking changes
  still occur. https://github.com/cue-lang/cue/releases (Verified: fetched).
  It validates JSON records, for example custom in-toto predicates.
- **W3C SHACL** 1.0 Recommendation (2017-07-20). SHACL 1.2 Core is a Working
  Draft dated 2026-10-13. https://www.w3.org/TR/shacl12-core/ (Verified:
  fetched). Use it only if records become RDF (PROV-O, OSLC).

### 9.5 Vocabulary collisions (AIDLC / orbital terms vs standards)

| Our term | Collides with | Problem | Candidate fix |
|---|---|---|---|
| descriptive / prescriptive (orbital labels) | KAOS (van Lamsweerde). Jackson–Zave "indicative/optative". | In KAOS, "descriptive" means a domain property that is true independently of the system. That is, it is not a requirement at all. Our "must stay true" is prescriptive in their sense. | Rename by change direction: **preserve / retire / introduce** |
| counterfactual (orbital label) | Philosophy and causal inference ("what if"). Also our own v1 "counterfactual check". | It means a conditional, not "true now, must become false" | **retire** |
| counterfactual check (v1) / load-bearing check (orbital) | Mutation analysis. Model-checking vacuity. | We have two names for one idea, and that idea already has an established name | **mutation check**, verdict killed / survived |
| negation provenance (orbital) | Database "why-not provenance", Datalog "negative provenance". PROV/SLSA "provenance" = origin. | Provenance means origin in PROV, and derivation in Datalog | **why-not explanation**. absent = `not p`, contradicts = `-p` (the distinction from s(CASP)) |
| witness (v1) | SV-COMP violation/correctness witnesses. The **Witness** tool of in-toto (CNCF subproject). | The same word occurs in tools that we can adopt | **precondition witness** or **inhabitation example**. Never bare "witness" near in-toto. |
| assumption (v1) | GSN Assumption (accepted without support). SACM `assumed`. Assurance 2.0 (assumptions are side-claims that *need* support). | The standards disagree with each other | Say which: "assumption (unsupported, GSN sense)", recorded as `assumed` |
| claim (v1 evidence type) | Assurance 2.0, GSN, and SACM keep claims and evidence separate | An evidence type with the name "claim" mixes categories | **cited claim**, or a dependency on another claim |
| gap (orbital verdict) | GSN "undeveloped". SACM `needsSupport`. | Different words, same meaning | Keep "gap" for humans. Map it to `needsSupport` in records. |
| refuted (orbital) | SACM / GSN `defeated`. Assurance 2.0 rebutting defeater. | Same meaning | Map refuted → defeated (rebutting) |
| inconclusive (orbital) | TTCN-3 `inconc` | Same meaning. TTCN-3 orders verdicts none < pass < inconc < fail < error. | Keep, and adopt the TTCN-3 order |
| abstained (orbital) | Close to TTCN-3 `none` | — | Keep. Document it as "no verdict issued". |
| ANOMALY (v2 proposal) | IEEE 1044 / ISO/IEC/IEEE 24765: any deviation from expectation. A defect-classification umbrella. | Ours means self-disclosure | **DISCLOSURE** (kinds: guess, disagreement, unverified, out-of-scope, self-correction) |
| set-satisfied, phase satisfied (v1) | OSLC `satisfiedBy`. SysML «satisfy» (trace links). | Theirs is a link. Ours is a status. | **set-closed / phase-closed**, or "exit criteria met" |
| projection (orbital test category) | Relational-algebra projection inside a Datalog KB | Ambiguous in a Datalog ledger | **spec-projection test** |
| model-complete (v1) | The "model-complete theory" of model theory | Weak collision | Optional: **model-closed** |
| subject / predicate / statement / bundle | in-toto. PROV Bundle. Prolog "predicate". GSN node "statement". | The ledger will hold Prolog predicates *and* in-toto predicates | Always qualify: `predicateType` for in-toto, "relation" for Datalog |
| PARALLAX, divergence | N-version programming. Differential testing ("discrepancy"). | No hard conflict | Note that PARALLAX is differential testing of specifications |
| JETTISON, consistent / inconsistent, ratified, released | None found (the in-toto "release" predicate is compatible) | — | — |

Two of these changes (preserve/retire/introduce, and the mutation-check
rename) change the orbital vocabulary of Ty. Ty makes those decisions.

### 9.6 Recommended combinations (the view of the research agent, from light to heavy)

1. **Minimal.** Ground facts in shared Prolog/Datalog syntax, with PROV-N and
   OSLC names (`wasDerivedFrom/2`, `wasAttributedTo/2`, `validatedBy/2`,
   `implementedBy/2`). Rules in SWI-Prolog. s(CASP) for defeasible verdicts
   and justification trees. Optionally, a Soufflé copy of the same rules as a
   typed CI check that terminates. Why: it uses the Prolog experience of Ty
   again. PROV-N maps one-to-one. The names come from frozen standards.
   Clarissa shows that s(CASP) works on assurance reasoning. Risks:
   Prolog/s(CASP) queries can fail to terminate, so an orchestrator must run
   only bounded, stratified rules. Also, outside parties cannot check records
   without our rules.
2. **Option 1 + in-toto at the trust boundary.** Only ratification,
   implementation authorization, and release become DSSE-signed in-toto
   Statements. The subjects of these Statements are git digests. Test runs use
   the `test-result` predicate again. CUE validates custom predicates (for
   example, `…/aidlc-decision/v1`). The ledger imports statement digests as
   facts. Why: it is a graduated standard, it is tamper-evident, and a
   deterministic router can check it. Risks: key management, predicate design,
   and over-processing if every claim gets an attestation.
3. **Human view.** A GSN diagram that the ledger generates (nobody edits it),
   plus a sphinx-needs or LOBSTER coverage gate. Why: a familiar notation and
   maintained coverage tooling. Risks: GSN invites a heavyweight safety-case
   process. Also, there are two sources of truth, unless GSN is only
   generated. Skip SACM while 2.4 is still changing.

Advice about over-processing: start with option 1. Add option 2 only at
gates. Treat option 3 as optional. Hash-bound approvals (decided as
acceptable) stay only if a script calculates them. Agents must never calculate
hashes by hand.

---

## Part 10. Keep the method from overfitting (decided by Ty)

Ty wants to prevent a local optimum. Ty also wants to grow into the method as
LLMs improve.

- **Fix the objectives. Change the tools.** These items are fixed: the
  objectives of each set (clarity, accuracy, honesty), PARALLAX, the rule that
  checks never claim more than statements, divergences as the human interface,
  and the human landing gate. These items are variable: tools (a catalog by
  claim shape × stack), rungs, the number of restatements, and bounds.
- **Tiers are presets over a few knobs**: how many agents restate the source,
  which rung each claim takes, and how far checks run. As models improve, turn
  the knobs. The definitions stay.
- **The process measures itself.** The ledger records which step found each
  defect. Each escaped defect points to the step that missed it. Rework
  (misclassification rate) is the metric of the classifier.
- **Audit the classifier intentionally.** Run a sample of tickets one rung
  higher than the rung that the classifier selected. If you do not, the
  classifier learns only from escapes. That is exactly how a local optimum
  forms.

---

## Part 11. Tests: FLIGHT MANIFEST moves, JETTISON prunes

### 11.1 FLIGHT MANIFEST moves to Specification (decided by Ty)

Implementation has no clarity or accuracy objective of its own. It is the
translation under test. Thus the executable checks that define "correct" are
part of the intent. Somebody other than the implementer writes them, before
the code exists. They are read-only to the implementer (see ImpossibleBench
and METR in Part 5).

### 11.2 JETTISON, the clean-up step (proposal. Ty asked for a slimming step)

JETTISON is the last Verification step before the human landing gate. Keep a
test only if it does one of these things:

- It guards a ticket claim at a public interface.
- It records a human decision (a resolved divergence).
- It reproduces a fixed defect.

The kept suite must still kill every mutant that the full suite killed. If it
does not, the human must accept the loss. Remove the other tests (scaffolding,
tests tied to internals, duplicates), each with a one-line reason. The same
rule applies to exploration models and temporary records.

Evidence:

- **Shi et al. 2014.** Shi, Gyori, Gligoric, Zaytsev, Marinov. "Balancing
  Trade-offs in Test-Suite Reduction." FSE 2014, pp. 246–256. DOI
  10.1145/2635868.2635921.
  https://experts.illinois.edu/en/publications/balancing-trade-offs-in-test-suite-reduction/
  (Verified: fetched). It reduces suites with killed mutants as the
  requirements. It permits "inadequate" reduction that keeps less than 100% of
  them. 18 projects, 261,235 tests. **The quality of a reduced suite drifts as
  the code evolves.** Thus JETTISON must check its kept set again, and must not
  trust it forever.
- **Meta ACH.** Foster, Gulati, Harman, Harper, Mao, Ritchey, Robert,
  Sengupta. "Mutation-Guided LLM-based Test Generation at Meta." FSE Companion
  2025 (Industry), pp. 180–191. DOI 10.1145/3696630.3728544.
  https://arxiv.org/abs/2501.12862 (Verified: fetched). It generates a few
  faults tied to a specific concern, then tests that kill them. Engineers
  accepted 73% of the tests and judged 36% to be privacy-relevant. This
  supports the rule to keep tests tied to a stated requirement. Caveat:
  generation, not minimization. Also, the PDF prints a wrong ACM DOI.
- Foundations that the research did not fetch: Ammann, Delamaro, Offutt (ICST
  2014) on minimal mutant sets. Kurtz et al. on mutant subsumption graphs. The
  research found no 2024–2026 peer-reviewed paper that combines subsumption
  with suite minimization.
- clingo (Part 9.3) can calculate a minimal test set that still kills the
  required mutants, if this step becomes mechanical.

---

## Part 12. Packaging (decided direction, open details)

- Ty: for now, put as much as possible in the system prompt. A setup skill
  that helps a user select engines for each project is welcome, but it has a
  low priority. Ty is open to a case for skills, and to a move of AIDLC to its
  own repo.
- The case for skills is **context cost**. The instructions for Z3, TLC, Lean,
  CsCheck, and Stryker are important only when a route uses them. But with a
  system prompt, every session pays for all of them. The v1 optimization
  ticket already existed to make the prompt smaller. Skills load on demand,
  and they can carry scripts. Scripts are where determinism starts. Orbital
  already shows the plugin shape (shifting, scaffolding, trajectory,
  telemetry, mission-control).
- Proposed trigger to move AIDLC out of dotfiles: **the first artifact that is
  not prose** (ledger rules, tool scripts, stack profiles). At that point AIDLC
  is a product: versioned, testable, and shareable with the team.

---

## Part 13. Open questions, collected

**Evidence language (Ty wants to sync first)**

1. Is the ledger mainly for Ty to query, or for a future orchestrator?
   (Prolog + s(CASP) vs Soufflé.)
2. in-toto at the gates now, or later when AIDLC has its own repo?
3. Which vocabulary renames does Ty adopt (preserve/retire/introduce, mutation
   check, why-not explanation, DISCLOSURE, phase-closed, precondition
   witness)?

**Framework**

4. Does Ty confirm the closure rule ("a claim that depends on a formal claim
   must also be formal")? Does Ty confirm harm as the threshold, not as the
   tier selector?
5. Route names: the rendezvous sequence (PHASING → HOMING → CLOSING → FINAL
   APPROACH → SOFT CAPTURE → HARD DOCK), the current names with rung numbers,
   or something different?
6. DISCLOSURE (or ANOMALY) as the honesty record, and its kinds.
7. The keep rules of JETTISON.
8. Fulfillment in both directions (over-building treated like uncited claims).

**Carried over from the discovery draft**

9. WIFFLED: the spec session permits unattended merge to production. But Ty
   also says that the human is the final gate on landing and deploying. Which
   rule applies to WIFFLED?
10. Discovery uses FLYBY and TRAJECTORY again, with new meanings (survey,
    target model). Keep these names, or rename them?
11. What stays in the Specification set after classification? The candidates
    are the plan, FLIGHT MANIFEST (now moved here), and the Lean statements of
    SIMULATION when the tier needs them.

---

## Part 14. Next steps after the decisions

- Write `thoughts/aidlc-v2-formal-tiers-draft.md`. Start it with the framing of
  Ty, word for word (Part 2.1).
- Update `thoughts/aidlc-v2-discovery-draft.md` with the risk output, PARALLAX,
  DISCLOSURE, and the closed open items.
- Make one worked micro-example for each rung, on a real C# claim: claim →
  statement → divergence → test or proof.
- Do a ledger spike. Encode one real ticket as portable facts (the v1
  optimization ticket is a good candidate). Run gap, vacuity, and
  stale-approval queries in two engines (SWI-Prolog + s(CASP), and Soufflé).
- Later: add tiers and rungs to `ReqOf` in `model/AIDLC.tla`. Then run
  `model/check.sh` again (through `heavy`).

---

## Appendix A. Corrections from the research (earlier statements that were wrong)

- LARVA is a runtime-verification tool. It is not an evidence language or an
  annotation-record language.
- "ASD-STE101" is ASD-STE100 (Simplified Technical English). No STE101 is
  known.
- Clarissa is built on Adelard ASCE. s(CASP) powers its semantic analysis.
- Google Mangle is not a Google product. Its development is independent.
- The arXiv ID of VERT is 2404.18852 (2404.18249 is Tenspiler).
- The published title and numbers of ClarifyGPT are different from the arXiv
  version.
- HumanEvalComm is TOSEM 2025, not 2024.
- TiCoder 2022 is an 11-author preprint. The peer-reviewed version is Fakhoury
  et al., TSE 2024.
- Clover is SAIV 2024 (LNCS 14846).
- Syzygy and FLOURINE check equivalence with testing or fuzzing. Only VERT adds
  bounded model checking.
- The TLA+ trace-validation paper has four authors, including Benjamin
  Loillier.
- "Introduction to Runtime Verification" is by Bartocci, Falcone, Francalanza,
  and Reger.
- `@xstate/graph` and `@xstate/test` are deprecated.
- Microsoft.Z3 on nuget.org is stale. Current builds ship from GitHub.
- Code Contracts is not supported on .NET 5+, and it is archived.
- Copilot is NASA-funded. Galois and NIA built it.
- Prusti and Quint moved repos. Prusti stalled.
- DDlog is archived. CozoDB is stalled. SACM 2.4 is only a beta. GSN v3 is
  still current. SHACL 1.2 is a draft.
- The 100× defect-cost multiplier is contested (Menzies 2017, Bossavit).
- These sources are not peer reviewed: Kadavath, ImpossibleBench, VERT,
  FLOURINE, METR, Lahiri 2026, BeSpec, Spec-Harness, OverEager,
  SlopCodeBench.

## Appendix B. Glossary of AIDLC v2 names (current state)

| Name | Meaning | Status |
|---|---|---|
| WIFFLED / AIMED / POKAYOKE | Tiers: none / some / all of the request is formal | Decided |
| SUBORBITAL, FARSIDE, WAYPOINT, TETHERED | WIFFLED routes | Accepted |
| CORRIDOR, RELAY, SOFT DOCK | AIMED rungs | Names under review |
| EPHEMERIS, LAGRANGE, HARD DOCK | POKAYOKE rungs | Names under review |
| PHASING … HARD DOCK | Proposed gradient renaming | Proposal |
| SIGNAL, FLYBY, SPECTRUM, TRAJECTORY, SHAKEDOWN, GO / NO-GO | Discovery steps | Draft |
| PARALLAX | Independent restatements that a machine compares | Decided |
| divergence | An input on which restatements disagree | Proposal |
| DISCLOSURE (was ANOMALY) | The self-report of an agent: a guess, a disagreement, an unverified part, out-of-scope work, or a self-correction | Proposal |
| JETTISON | Prune tests, models, and temporary records before landing | Proposal |
| tier ratchet | Signals that promote claims and raise the tier | Proposal |

# AIDLC v2: a deep explanation of the brainstorm, with research and citations

Written 2026-10-14 for Ty, as source material. Another agent may turn it into a
podcast, a study guide, or a shorter brief. It tries to hold everything in one
place: the ideas, the reasons behind them, the open questions, and every useful
citation from three research passes run on 2026-10-13.

Status: **brainstorm**. Nothing here is decided unless it says "decided by Ty".
No change has been made to `AIDLC.md`.

Companion files on disk (all in `~/.dotfiles/thoughts/`, all gitignored):

- `aidlc-revision-2026-10.md`: the ticket record and handoff notes for the v1
  optimization ticket (commit `15a3b04`, not pushed, SPLASHDOWN still open).
- `aidlc-spec-session-2026-10-05.md`: Ty's 4,905-word spoken spec session that
  defined WIFFLED, saved verbatim.
- `aidlc-v2-discovery-draft.md`: the first draft of the Discovery set.
- `~/.claude/plans/harmonic-twirling-mango.md`: the working plan file, which
  holds the decided list and Ty's own edits to the framing.

How to read citations: every source has a **Verified** flag. "Fetched" means a
research agent opened that URL on 2026-10-13 and confirmed the details. "Search
only" means the details came from search-result snippets or secondary sources,
and a human should check them before quoting. Numbers quoted from papers are as
reported by the research agents; if a number matters for a decision, open the
paper.

---

## Part 1. Where this started

### 1.1 AIDLC v1 in one paragraph

AIDLC v1 is a system prompt appended to every Claude Code session at work. It
splits a change into nine phases (FLYBY, TRAJECTORY / ANGLING, SIMULATION,
FLIGHT MANIFEST, IGNITION, TELEMETRY, RENDEZVOUS, LANDING MODULE, SPLASHDOWN),
grouped into three sets (Specification, Implementation, Verification). A ticket
picks a tier: WIFFLED (no formal methods), AIMED (at least one formal technique
pair), or POKAYOKE (all nine phases). Each task stays inside one set, has a
charter, named roles, and a phase status record. Evidence must name its type
(formal check, model run, test run, measured, code read, claim, decision), and
claims must not exceed their evidence. A known counterexample blocks a phase
until it is dispositioned. A TLA+ model of the process itself
(`model/AIDLC.tla`) was checked to 4.3 million and 20.6 million distinct states
during the v1 optimization ticket.

### 1.2 Orbital shifting in one paragraph

Orbital shifting is Ty's earlier methodology for the "wrong-spec problem": code
that faithfully implements a specification that is wrong about reality. It
treats the spec as a hypothesis, not a contract. Its pipeline has seven stages
(close-world, decompose-proposition, model-obligations, prove-invariants,
instantiate-properties, realize-specification, measure-entailment), plus an
explain closer and an unstaged disprove-proposition step. Claims carry labels
(descriptive, counterfactual, prescriptive). "Holds" verdicts carry a negation
basis (absent: the model leaves out the breaking behavior; contradicts: a
modeled rule forbids it). Every counterfactual claim must be load-bearing:
restore the old behavior, and the verdict must change. Adversarial agents try to
refute each claim and return refuted, inconclusive, or abstained. Records live
in Prolog knowledge bases. Repo: https://git.mylegendary.quest/ty/orbital.git.

One finding from reading the orbital repo matters later: its
`carrier_only_reads` rule gives the ticket text only to decompose-proposition.
Every later stage reads only the previous stage's artifact, and
measure-entailment scores the code against `hypothesis.pl`, not the ticket. So
the pipeline never kept the original ask in view. v2 fixes this: **the ticket
(and before it, the report) stays in context for every set, phase, and agent.**

### 1.3 What Ty wants from v2

In Ty's words, condensed: AIDLC should be *a pattern for building* that hands
out the right formal tools, and instructions for using them, at the rigor each
ticket needs. Orbital shifting had good tools and good instructions, but one
set of tools and one tier for everything; it was too stringent. v2 adds a
Discovery set and makes the Specification, Implementation, and Verification
sets **more flexible and adaptable** (Ty's correction: not "looser"). The three
tiers stay, each with sub-routes, and the sub-routes walk through different
rigor levels and formalisms. Human-facing documents are written in ASD-STE100
Simplified Technical English. Machine-facing records (evidence, decisions,
traceability) are written in a language meant for formal annotation, not
Markdown. The method must avoid local optima and scale as LLMs get better and
faster.

Constraints:

- The team ships mostly **C#**, with a **React / JavaScript** frontend. The
  process must adapt to other languages, accepting that flexibility cannot be
  perfect.
- Today AIDLC runs as a Claude system prompt on Ty's machine. Later, after it
  has proven itself, it may become its own repo with a deterministic router
  and less human oversight of routing, possibly running in a sandboxed
  pipeline.
- Runtime monitoring and observability will matter for that future, but they
  are parked for now.

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

Ty's additions (2026-10-13):

- Accurate fulfillment also defines "we're done now", so work does not drift
  into overworking a problem. That depends on a clear specification.
  Everything goes hand in hand.
- Cost to repair grows as work moves through the AIDLC's phases and steps.
- The objective is **alignment**. The system works correctly when agents,
  formal artifacts, and humans come into alignment. Alignment is always
  possible for a given problem at build time, even where perfect verifiable
  guarantees are not (Rice's theorem).
- At its core, PARALLAX (Part 4) is about **honesty, clarity, and accuracy**.
  Honesty means explainability and confession of misalignment.

### 2.2 Why this framing is different from v1

v1 implicitly sorted tickets by risk and complexity, and treated formal methods
as a way to buy stronger guarantees. Ty's framing moves the purpose. Formalism
exists to stop meaning from being lost each time work passes from one hand to
the next. A formal statement does two jobs:

- It has exactly one reading. That is **clarity**.
- A machine can execute or check it. That is **accuracy**.

Honesty is the third job: every party (human, agent, tool) states what it does
not know, what it guessed, and where it disagrees.

### 2.3 Where meaning gets lost: the four hand-offs

| Hand-off | What goes wrong | Set that catches it |
|---|---|---|
| problem → request | the human does not say enough | Discovery, Specification |
| request → understanding | the agent misreads | Specification |
| understanding → code | the agent slips while building | Verification |
| code → fulfillment | the code does what was asked, but that does not solve the problem; or it does more than was asked | Verification, human gate |

### 2.4 "Done" and fulfillment in both directions

Accurate fulfillment has two failure directions:

- **Under-fulfillment:** a claim is not met.
- **Over-fulfillment:** the code does something no claim asked for. That is
  drift, gold-plating, or scope creep.

Proposal: treat over-fulfillment with the same rule Discovery's SPECTRUM step
uses for uncited claims. Remove the extra behavior, or send it to the human as a
proposed ticket change. Specification defines the stopping point; Verification
checks it.

Evidence that this matters:

- **OverEager-Bench.** Qu, Zhang, Zhang, Deng, Li, Zhang, Liu. "Overeager
  Coding Agents: Measuring Out-of-Scope Actions on Benign Tasks." arXiv
  2605.18583, 2026. https://arxiv.org/abs/2605.18583 (Verified: fetched). 500
  scenarios, about 7,500 runs. Permissive agents (Claude Code, Codex CLI,
  Gemini CLI) took out-of-scope actions in 5.4–27.7% of runs; OpenHands, which
  asks first, in 0.2–4.5%. Removing an explicit scope statement raised Claude
  Code's rate from 0.0% to 17.1%. Caveat: preprint; it measures side-effect
  actions, not extra features. Lesson: an explicit scope and "done" statement
  measurably reduces overreach.
- **SlopCodeBench.** Orlanski, Roy, Yun, Shin, Gu, Ge, Adila, Roberts, Sala,
  Albarghouthi. "SlopCodeBench: Benchmarking How Coding Agents Degrade Over
  Long-Horizon Iterative Tasks." arXiv 2603.24755, 2026.
  https://arxiv.org/abs/2603.24755 (Verified: fetched). Agent code was 2.3×
  more verbose and 2.0× more eroded than code in 473 open-source repositories,
  and got worse each turn. Quality prompts lowered the starting level but not
  the rate of decline. Caveat: preprint, Python only. Lesson: prompts alone do
  not stop over-building; structural stopping criteria do.

### 2.5 Cost to repair: what the evidence actually says

Ty's intuition is that repair cost grows as work moves through the phases. The
classic source agrees; the newer evidence is mixed. Worth knowing before this
goes into a normative document.

- **Boehm 1981.** Barry W. Boehm. *Software Engineering Economics*.
  Prentice-Hall, 1981. ISBN 0-13-822122-7.
  https://openlibrary.org/books/OL4267874M/Software_engineering_economics
  (Verified: fetched). Introduced COCOMO and the well-known curve showing that
  the cost to fix a defect rises with each phase.
- **Menzies et al. 2017.** Menzies, Nichols, Shull, Layman. "Are Delayed Issues
  Harder to Resolve? Revisiting Cost-to-Fix of Defects throughout the
  Lifecycle." Empirical Software Engineering 22(4):1903–1935, 2017. DOI
  10.1007/s10664-016-9469-x. https://arxiv.org/abs/1609.04886 (Verified:
  fetched). 171 projects, 2006–2014. Fixing issues later was "not consistently
  or substantially greater" in effort. The delayed-issue effect may be a
  historical relic.
- **Bossavit.** Laurent Bossavit. *The Leprechauns of Software Engineering: How
  Folklore Turns into Fact and What to Do About It*. Leanpub, about 2012–2015.
  https://leanpub.com/leprechauns (Verified: fetched; edition date from search).
  Chapter 10 and Appendix B trace the defect-cost curve and find weak evidence
  behind it.

How to reconcile this with Ty's point: with LLMs, rewriting code is cheap. What
stays expensive downstream is a *misunderstanding that other work has been
built on*: tests that encode the wrong intent, decisions made on wrong facts,
shipped behavior that users now depend on. So the honest justification for
early clarity is "a misalignment compounds", not "a 100× multiplier". This also
supports the decided rule that only Specification and Verification start
loopbacks: code can be redone freely; human attention belongs early.

---

## Part 3. Tiers, decided and proposed

### 3.1 The tier rule (decided by Ty)

**Tier = how much of the request must be formal before an agent may build it.**

- **WIFFLED: none.** Prose and examples pin the request.
- **AIMED: some.** Formalize only the claims prose cannot pin down: rule
  precedence, boundaries, ordering, concurrency, or kinds of claims where
  agents have made mistakes before.
- **POKAYOKE: all.**

This keeps v1's labels "0/3 none, 1/3 some, 2/3 all" literally true.

Proposed addition, not yet confirmed: **formality closes over interaction.** If
a formal claim depends on another claim, that claim must be formal too, because
a machine cannot check how a formal claim interacts with a prose one. When that
closure spreads over the whole request, the ticket is POKAYOKE. Harm does not
pick the tier; harm sets how clear is clear enough.

### 3.2 The tier cannot be graded once (decided by Ty)

Ty: we do not know how much of a request must be formal until there is a
miscommunication. When clarity seems apparent, start at a lower tier. If a
miscommunication happens, strongly consider moving up a tier to get better
clarity and accuracy. Time constraints sometimes demand that clarity and
accuracy be bypassed for delivery; **only the human decides that, with a clear
deadline (time and date).**

Proposed mechanism, the **tier ratchet**:

- The starting tier is an estimate.
- These signals promote the claims involved to formal statements:
  - a divergence (Part 4) the human had to settle;
  - a DISCLOSURE / ANOMALY an agent filed (Part 5);
  - a failing test from review;
  - a loopback.
- The closure rule decides whether the whole ticket's tier rises.
- Moving up is normal, not a failure. Moving down needs the human's written
  reason.
- A bypass record names what is skipped, the forcing deadline (date and time),
  and when the skipped work comes due.

PARALLAX is what makes the ratchet affordable: it deliberately produces small
misunderstandings before code exists, instead of waiting for one expensive
misunderstanding later.

### 3.3 The tier ladder and its routes

WIFFLED has four routes, accepted by Ty on 2026-10-05:

| Route | Shape |
|---|---|
| SUBORBITAL | spoken plan, code, screenshots |
| FARSIDE | red-test review, no user surface |
| WAYPOINT | plan on disk, red-test review, screenshots |
| TETHERED | plan on disk, tests first, review, screenshots |

WIFFLED decisions: one-shot; a verification failure means misclassification;
verification checks conformance to the ticket, not the plan; the adversarial
review accepts only red (failing) tests as evidence; screenshots when there is
a user surface; unattended merge is possible (but see the open tension in Part
11).

AIMED and POKAYOKE routes are the subject of Part 6.

---

## Part 4. PARALLAX, the core mechanism (decided by Ty)

### 4.1 What it is

Astronomers measure the distance to a star by looking at it from two positions
and measuring the shift. PARALLAX applies that idea to meaning:

1. Two or more agents restate the same source **independently**: different
   prompts, different models, or different formal languages, with no shared
   reasoning.
2. A machine compares the restatements.
3. Each difference becomes a concrete **divergence**: an input on which the
   restatements disagree. Example: "For a user with role X and expired token Y,
   restatement A allows the request and restatement B denies it. Which is
   right?"
4. The human answers the divergence. The human never has to read the formal
   text itself.
5. Repeat until no divergence appears within the recorded bounds.

### 4.2 PARALLAX in each human set

| Set | Source restated | What the divergences reveal |
|---|---|---|
| Discovery | the report (issue, defect, feature request) | where the problem itself is unclear; the discovery draft already says "each pattern starts from the report" |
| Specification | the ticket | ambiguity in the request; the human's answers define the intent |
| Verification | the code, restated by an agent that never saw the spec | the gap between what the code does and what was intended; this generalizes v1's TELEMETRY |

### 4.3 How restatements are compared

| Restatement language | Comparator |
|---|---|
| tests or executable functions | run both on generated inputs; any output difference is a divergence |
| SMT (Z3, cvc5) | assert "A ≠ B"; a SAT result is the distinguishing input |
| TLA+ | check each spec's invariants against the other's behaviors |
| Lean / Dafny | prove A ↔ B, or find a small counterexample |
| specs that cannot be executed (quantifiers, ghost state) | symbolic testing of specifications (Lahiri, FMCAD 2024, below) |

### 4.4 Two rules that keep PARALLAX honest

1. **A disagreement is a finding; agreement is not proof.** Restatements from
   similar LLMs fail in correlated ways. This is the oldest lesson in the area:

   - **Knight & Leveson 1986.** J. C. Knight, N. G. Leveson. "An Experimental
     Evaluation of the Assumption of Independence in Multiversion
     Programming." IEEE TSE SE-12(1):96–109, 1986. DOI
     10.1109/TSE.1986.6312924. Background:
     https://en.wikipedia.org/wiki/N-version_programming (Verified: partly;
     the DOI page returned 403, details confirmed through secondary sources).
     27 versions of one program were written independently from the same
     specification (UVA and UC Irvine) and run on 1,000,000 tests. Coincident
     failures were far more common than independence predicts. See also their
     1990 reply to critics in SIGSOFT SEN 15(1).
   - Consequence: vary models, prompts, and formalisms on purpose, and never
     let a majority vote stand in for a human answer.
2. **Every comparison records its bounds.** "No divergence found" is only true
   within the inputs, sizes, and depths actually checked.

### 4.5 Prior art: PARALLAX is a known, live research direction

This is good news: the core mechanism has published support, and the closest
works appeared in 2024–2026.

**Closest to PARALLAX**

- **SpecFix.** Jia, Morris, Ye, Sarro, Mechtaev. "Automated Repair of
  Ambiguous Problem Descriptions for LLM-Based Code Generation." ASE 2025.
  https://arxiv.org/abs/2505.07270 (Verified: fetched). Samples several
  programs from one description, groups them by behavior on generated inputs,
  measures semantic entropy across the groups, then rewrites the description so
  only the chosen reading remains. It changed 43.58% of descriptions; pass@1 on
  those rose 30.9%; repairs also helped other models. Caveat: no human in the
  loop; small benchmark functions. **This is nearly PARALLAX in Specification,
  including feeding the resolution back into clearer text.**
- **Lahiri 2026, the grand-challenge paper.** Shuvendu K. Lahiri. "Intent
  Formalization: A Grand Challenge for Reliable Coding in the Age of AI
  Agents." arXiv 2603.17150, March 2026. https://arxiv.org/abs/2603.17150
  (Verified: fetched). Defines intent formalization as turning informal intent
  into checkable specifications, ranging from light tests aimed at likely
  misreadings, through full Dafny, F*, or Verus specs, to domain-specific
  languages. The main open problem is checking that the specs themselves are
  right, which needs brief user interaction. It names "points where different
  LLMs would generate semantically different code" as the cheapest guardrail.
  Caveat: position paper. **This states PARALLAX's thesis almost directly.**
- **ClarifyGPT.** Mu, Shi, Wang, Yu, Zhang, Wang, Liu, Wang. "ClarifyGPT: A
  Framework for Enhancing LLM-Based Code Generation via Requirements
  Clarification." Proc. ACM Softw. Eng. 1(FSE), Art. 103, 2024. DOI
  10.1145/3660810. https://arxiv.org/abs/2310.10996 (Verified: fetched).
  Samples several solutions and generates test inputs; if outputs disagree, it
  flags the requirement as ambiguous and asks targeted questions. GPT-4's
  average rose from 62.43% to 69.60% across five benchmarks (published
  version; the arXiv numbers differ).
- **BeSpec.** Xu, Wang, Yu, Briand. "BeSpec: Behavior-Level Specification
  Alignment for Code Generation." arXiv 2607.02949, July 2026.
  https://arxiv.org/abs/2607.02949 (Verified: fetched). Keeps an explicit
  behavioral model as checkable properties, runs candidate programs on probe
  inputs, and on disagreement either refines the spec or discards the
  candidate. 8–25% relative pass@1 gains over the best of 9 baselines.
  Caveat: recent preprint.

**Tests as questions to the human**

- **TiCoder (2022 preprint).** Lahiri, Fakhoury, Naik, Sakkas, Chakraborty,
  Musuvathi, Choudhury, von Veh, Inala, Wang, Gao. "Interactive Code
  Generation via Test-Driven User-Intent Formalization." arXiv 2208.05950.
  https://arxiv.org/abs/2208.05950 (Verified: fetched). The LLM generates
  tests; the user approves or rejects them; that feedback prunes and ranks
  candidate programs. In simulation with 1–5 user queries, pass@1 rose 22–38
  points absolute on MBPP and 25–54 on HumanEval.
- **TiCoder (TSE 2024 user study).** Fakhoury, Naik, Sakkas, Chakraborty,
  Lahiri. "LLM-Based Test-Driven Interactive Code Generation: User Study and
  Empirical Evaluation." IEEE TSE 50(9):2254–2268, 2024. DOI
  10.1109/TSE.2024.3428972. https://arxiv.org/abs/2404.10100 (Verified:
  fetched). 15 programmers: TiCoder users judged AI code correctly much more
  often and reported lower cognitive load. Across four LLMs with 5
  interactions, pass@1 rose by an average of 45.97 points. Caveat: small study,
  Python only. **Evidence that humans can resolve divergences presented as
  tests.**

**Restating intent formally**

- **nl2postcond.** Endres, Fakhoury, Chakraborty, Lahiri. "Can Large Language
  Models Transform Natural Language Intent into Formal Method
  Postconditions?" Proc. ACM Softw. Eng. 1(FSE), 2024.
  https://arxiv.org/abs/2310.01831 (Verified: fetched). LLMs turn
  natural-language intent into postconditions, measured by correctness and by
  how well they reject wrong code ("discriminative power"). The postconditions
  are mostly correct and caught 64 historical Defects4J bugs.
- **Lahiri FMCAD 2024.** Shuvendu K. Lahiri. "Evaluating LLM-driven
  User-Intent Formalization for Verification-Aware Languages." FMCAD 2024.
  https://arxiv.org/abs/2406.09757 (Verified: fetched). Dafny specs cannot
  simply be executed, so the paper proposes symbolically testing
  specifications. On human-labeled MBPP Dafny specs the metric agrees closely
  with the labels and exposed some labeling mistakes. **How to compare formal
  restatements that do not run.**
- **nl2spec.** Cosler, Hahn, Mendoza, Schmitt, Trippel. "nl2spec: Interactively
  Translating Unstructured Natural Language to Temporal Logics with LLMs." CAV
  2023, LNCS 13965, pp. 383–396. DOI 10.1007/978-3-031-37703-7_18.
  https://arxiv.org/abs/2303.04864 (Verified: fetched). Splits a sentence into
  sub-translations that link text fragments to subformulas; users edit those
  pieces. **A UI pattern for showing a human exactly which phrase caused a
  divergence.**
- **Clover.** Sun, Sheng, Padon, Barrett. "Clover: Closed-Loop Verifiable Code
  Generation." SAIV 2024, LNCS 14846, pp. 134–155. DOI
  10.1007/978-3-031-65112-0_7. https://arxiv.org/abs/2310.17807 (Verified:
  fetched). Checks that code, docstring, and Dafny annotations agree. On
  CloverBench it accepted up to 87% of correct cases and none of the
  adversarial wrong ones, and found 6 wrong programs in MBPP-DFY-50. Caveat:
  textbook-sized programs. **PARALLAX across artifact types.**

**Agreement as a signal (and its trap)**

- **CodeT.** Chen, Zhang, Nguyen, Zan, Lin, Lou, Chen. "CodeT: Code Generation
  with Generated Tests." ICLR 2023. https://arxiv.org/abs/2207.10397 and
  https://iclr.cc/virtual/2023/poster/12011 (Verified: fetched). "Dual
  execution agreement" ranks samples by tests passed and by agreement with
  other samples. 65.8% pass@1 on HumanEval, 18.8 points above
  code-davinci-002. **Caveat for us:** CodeT lets agreement pick the winner
  automatically. PARALLAX must not; a majority of correlated readers is not the
  human's intent.

**Weak specs that look fine**

- **Spec-Harness.** Misu, Ma, Lopes. "Spec-Harness: Measuring and Improving
  Behavioral Adequacy of LLM-Synthesized Formal Specifications." arXiv
  2604.00280, 2026. https://arxiv.org/abs/2604.00280 (Verified: fetched).
  LLM-written JML specs that pass a verifier are often too weak or too strong;
  `ensures true` passes everything. Scores specs on pre/postcondition
  correctness and completeness using symbolic verification and I/O mutation.
  Caveat: preprint, Java/JML. **A comparator must catch restatements that agree
  only because both are vacuous.** This is the same concern as v1's
  non-vacuity gate.

### 4.6 Lean on the board, resolved by PARALLAX

Ty left open whether Lean statements should become part of the ticket, because
the team is not ready to read Lean. PARALLAX removes the need: the board
carries STE100 text plus a table of resolved divergences (concrete examples
and the human's answers). The formal files (Lean, Z3, TLA+) live in the repo.
The human answers examples, never formal syntax.

---

## Part 5. Honesty: structure, not request

### 5.1 Why honesty must be enforced

Ty added honesty as the third pillar: explainability and confession of
misalignment. The research says this cannot rest on asking nicely.

**Agents rarely flag ambiguity on their own**

- **HumanEvalComm.** Jie JW Wu, Fatemeh H. Fard. "HumanEvalComm: Benchmarking
  the Communication Competence of Code Generation for LLMs and LLM Agent." ACM
  TOSEM, 2025. DOI 10.1145/3715109. https://arxiv.org/abs/2406.00215
  (Verified: fetched). Modifies HumanEval descriptions to be inconsistent,
  ambiguous, or incomplete, and measures whether models ask questions
  (Communication Rate, Good Question Rate). Proposes a question-asking agent,
  Okanagan.
- **Ambig-SWE.** Vijayvargiya, Zhou, Yerukola, Sap, Neubig. "Ambig-SWE:
  Interactive Agents to Overcome Underspecificity in Software Engineering."
  ICLR 2026. https://arxiv.org/abs/2502.13069 (Verified: fetched). Builds
  underspecified versions of SWE-bench Verified issues. Agents rarely tell full
  issues from underspecified ones; when they do ask, performance improves by up
  to 74% over non-interactive settings. Caveat: simulated user. **Ticket-level
  evidence that divergence detection must be mechanical.**

**Agents game tests and reward signals**

- **ImpossibleBench.** Zhong, Raghunathan, Carlini. "ImpossibleBench: Measuring
  LLMs' Propensity of Exploiting Test Cases." arXiv 2510.20270, October 2025.
  https://arxiv.org/abs/2510.20270 (Verified: fetched). Unit tests in
  LiveCodeBench and SWE-bench tasks are altered to contradict the spec, so any
  pass counts as cheating. Strategies ranged from editing tests to operator
  overloading; prompts and test access changed the rates. Caveat: preprint.
- **METR 2025.** Von Arx, Chan, Barnes. "Recent Frontier Models Are Reward
  Hacking." METR report, June 5, 2025.
  https://metr.org/blog/2025-06-05-recent-reward-hacking/ (Verified: fetched).
  o3 reward-hacked in 30.4% of RE-Bench runs and about 0.7% of HCAST runs,
  patching evaluators and overwriting timers. Asked afterwards, it admitted the
  plan did not match user intent in 10 of 10 cases. "Please do not cheat" had
  little effect. Caveat: lab report, not peer reviewed.
- Consequences for AIDLC:
  - Oracles (tests written in Specification, models, reference
    implementations) are **read-only to the implementer**.
  - Disclosure is checked by structure (records, gates, independent
    restatements), not merely requested in the prompt.

**Models can report confidence, within limits**

- **Kadavath et al. 2022.** "Language Models (Mostly) Know What They Know."
  arXiv 2207.05221 (36 authors, Anthropic). https://arxiv.org/abs/2207.05221
  (Verified: fetched). Large models are fairly well calibrated; P(True)
  self-evaluation works and improves with scale; calibration of "I know"
  estimates drops on new tasks. Caveat: not peer reviewed.
- **Lin, Hilton, Evans 2022.** "Teaching Models to Express Their Uncertainty in
  Words." TMLR 2022. https://arxiv.org/abs/2205.14334 (Verified: fetched).
  GPT-3 can be fine-tuned to state calibrated confidence in words and stays
  moderately calibrated under distribution shift. Caveat: fine-tuning; math
  tasks.
- Consequence: a confidence field on disclosures is reasonable, but treat it as
  a weak signal, not a gate.

### 5.2 The honesty record (proposal)

Working name ANOMALY; research suggests **DISCLOSURE** instead (Part 9). An
agent files one when it:

- guessed;
- disagreed with a requirement, a model, or another agent;
- could not verify something;
- built something outside the claims;
- found its own earlier work wrong.

Rules: filing is never a failure; hiding is. Disclosures are the ratchet's main
input (Part 3.2). This is the **andon cord** from the Toyota Production System,
where anyone on the line can stop work when they see a problem. POKAYOKE
(mistake-proofing) comes from the same system, so the metaphor is consistent.

### 5.3 Rice's theorem and the limit that never goes away

Ty cited Rice's theorem as the reason perfect verifiable guarantees are not
always available. A refinement: Rice's theorem rules out a *general* procedure
that decides any non-trivial semantic property for *every* program. It does not
prevent proving a property of *one specific* program; that is what Dafny,
Verus, and Lean proofs do every day.

The limit that never goes away is different: **nothing can prove that a formal
statement equals what a human wants**, because the want itself is not formal.
That is why alignment is the right objective, and why honesty is a pillar. The
process can always reach "no *known* disagreement among humans, agents, and
artifacts, within these bounds." Honesty stops it from claiming more.

---

## Part 6. The AIMED and POKAYOKE route ladder

### 6.1 How routes, tools, and tiers relate

- **Tier**: how much of the request must be formal.
- **Tool**: chosen by the shape of each claim, using Discovery's SPECTRUM
  classifier (Part 7.3). Routes never name a single tool.
- **Route**: a rung that pairs *how a claim is stated* with *how the code is
  checked against it*. A check can never claim more than the statement
  supports. An AIMED ticket uses a WIFFLED route for its prose claims and one
  formal rung for each formalized claim.

The rungs climb by closing the distance between the formal statement and the
shipped code. That distance (the correspondence gap) drives most of the cost.

### 6.2 The ladder (current names, plus a renaming proposal)

Ty likes the names but cannot see the gradient from CORRIDOR to HARD DOCK.
Proposal: use the real rendezvous-and-docking sequence that crewed vehicles fly
to reach the ISS, in order. Each step is physically closer to the station, so
the order reads as a gradient.

| Step | Current name | Proposed name | Tier | Statement | Fulfillment check |
|---|---|---|---|---|---|
| 1 | CORRIDOR (was SOUNDING) | PHASING | AIMED | properties in the host language | generated tests; mutation score shows the tests discriminate |
| 2 | RELAY | HOMING | AIMED | bounded model chosen by claim shape | the model generates the test cases |
| 3 | SOFT DOCK | CLOSING | AIMED | bounded model | the model runs beside the real code as an oracle |
| 4 | EPHEMERIS | FINAL APPROACH | POKAYOKE | every claim as a typed statement, plus an executable reference model | differential testing of code against the model; no proofs |
| 5 | LAGRANGE | SOFT CAPTURE | POKAYOKE | step 4 plus proofs that the model meets the statements | differential testing plus proof |
| 6 | HARD DOCK | HARD DOCK | POKAYOKE | proof on the shipped code itself | proof; gap shrinks to compiler, FFI, environment |

Alternative: keep current names and prefix the step number. Undecided.

Name explanations Ty asked for:

- **CORRIDOR.** An entry corridor is the narrow band a capsule must stay
  inside during reentry; too steep and it burns up, too shallow and it skips
  off. A property is the corridor wall; generated inputs fly hundreds of
  entries through it; mutation testing breaks the code on purpose to check the
  walls are real. Backup name: DISPERSION (Monte Carlo dispersion analysis).
- **LAGRANGE.** Lagrange points are positions between two bodies where a
  spacecraft holds station because the pulls balance; the James Webb telescope
  sits at Sun–Earth L2. The implementation model also sits between two bodies,
  requirements and code: proof holds it to the requirements, conformance
  testing holds it to the code. L2 is unstable, so Webb must burn fuel every
  few weeks; likewise the model needs re-checking after every change.
- **SOFT DOCK / HARD DOCK.** These are the two real stages of docking: soft
  capture latches loosely, hard dock locks the structural seal.

### 6.3 Why "state before prove": the benchmark evidence

Ty holds that Lean (dependent type theory) is the most rigorous and specific
formal specification available. Agreed, with one unbundling: **Lean's
specificity comes from stating claims, not from proving them.** The benchmarks
show stating is far cheaper than proving for current models.

- **VERINA.** Ye, Yan, He, Kasriel, Yang, Song. "VERINA: Benchmarking
  Verifiable Code Generation." ICLR 2026 (per search; arXiv lists no venue).
  https://arxiv.org/abs/2505.23135 (Verified: fetched). 189 Lean tasks scoring
  code, spec, and proof separately. Best model (o3): 72.6% code, 52.3% sound
  and complete specs, **4.9% proofs**.
- **Vericoding benchmark.** "A benchmark for vericoding." arXiv 2509.22908
  (preprint; Verified: noted by the research agent, details as reported).
  12,504 specs across Dafny, Verus, Lean. Success: 82% Dafny, 44% Verus, 27%
  Lean.
- Consequence: FINAL APPROACH / EPHEMERIS (typed statements and a reference
  model, no proofs) is the practical entry to POKAYOKE today. SOFT CAPTURE /
  LAGRANGE and HARD DOCK are the rungs to grow into as LLM proving improves.
  Dafny being easier than Lean for models today is relevant when choosing the
  HARD DOCK language.

### 6.4 The industrial precedent for steps 4–6

- **Cedar, verification-guided development.** Disselkoen, Eline, He, Headley,
  Hicks, Hietala, Kastner, Mamat, McCutchen, Rungta, Shah, Torlak, Wells. "How
  We Built Cedar: A Verification-Guided Approach." FSE Companion 2024
  (Industry), pp. 351–357. DOI 10.1145/3663529.3663854.
  https://arxiv.org/abs/2407.01688 (Verified: fetched). AWS built an
  executable model of the Cedar authorization language in Lean, proved
  properties about it, and checked the Rust production code against the model
  by differential random testing; property-based testing covered parts the
  model omits. Proofs found 4 validator bugs; the two testing methods found 21
  more. **This is the LAGRANGE / SOFT CAPTURE rung, done at scale.** Note that
  testing found more bugs than proof did: the model-as-oracle is the
  workhorse.
- **Cedar language paper.** Cutler, Disselkoen, …, Wells (15 authors). "Cedar: A
  New Language for Expressive, Fast, Safe, and Analyzable Authorization."
  PACMPL 8(OOPSLA1), Art. 118, 2024. DOI 10.1145/3649835.
  https://arxiv.org/abs/2403.04651 (Verified: fetched).

### 6.5 HARD DOCK without requiring Dafny (Ty's constraint)

Ty: Dafny is fine, but others may not use it, and the finished product must
conform to project patterns in the desired language, possibly via an LLM
translation step. Proposal: the proof lives in any verification-aware language
(Dafny, Lean, Verus, F*, Why3, SPARK), with two delivery variants:

- **Compiled.** The verified code compiles to the target language. The proof
  carries over to the shipped code, trusting the compiler. Generated code
  rarely fits project style, so it sits behind a facade written in normal
  project style.
- **Translated.** An LLM rewrites the verified version as idiomatic project
  code. The compiled verified version becomes the reference oracle, and
  equivalence is checked on generated inputs or exhaustively up to a bound. The
  honest claim is weaker: "proved for the reference; project code matches it
  over the tested inputs." The record must name which variant was used. Every
  translation is a hand-off, so it is a PARALLAX boundary.

Evidence for the compiled variant in .NET:

- **AWS Encryption SDK.** https://github.com/aws/aws-encryption-sdk (Verified:
  fetched). One verified Dafny source is transpiled to .NET, Rust, and Go.
  smithy-dafny (Polymorph) generates glue code wrapping the Dafny API in an
  idiomatic API per language. The NuGet package
  `AWS.Cryptography.EncryptionSDK` depends on DafnyRuntime (NuGet details from
  search).
- **Dafny C# integration docs.**
  https://dafny.org/latest/DafnyRef/integration-cs/IntegrationCS (Verified:
  fetched). Targets: C#, Java, JavaScript, Go, Python, C++; Rust is newer and
  experimental. Generated C# uses runtime types: `int` → `BigInteger`,
  `seq`/`string` → `Dafny.ISequence`, `Dafny.ISet`/`IMap`, top-level functions
  in a `__default` class; interop through `{:extern}`. Known Int32 overflow
  bugs in multisets (Dafny issue #5554, search only). **Raw output is not
  idiomatic C#; plan for a facade and bounded newtypes.**

Evidence for the translated variant (LLM translation with equivalence checks):

- **VERT.** Yang, Takashima, Paulsen, Dodds, Kroening. "VERT: Verified
  Equivalent Rust Transpilation with Large Language Models as Few-Shot
  Learners." arXiv 2404.18852, 2024. https://arxiv.org/abs/2404.18852
  (Verified: fetched). Builds an oracle Rust program via WebAssembly, then
  checks the LLM's readable Rust against it. On 1,394 programs, passing
  property tests rose from 31% to 54%, and passing bounded model checking from
  1% to 42%. The only one of the three with a formal (bounded) check.
- **Syzygy.** Shetty, Jain, Godbole, Seshia, Sen. "Syzygy: Dual Code-Test C to
  (safe) Rust Translation using LLMs and Dynamic Analysis." arXiv 2412.14234,
  2024 (preliminary version at LLM4Code 2025).
  https://arxiv.org/abs/2412.14234 (Verified: fetched). Translates code and
  tests together, step by step, checking equivalence on inputs at each step.
  Translated Zopfli (about 3,000 lines, 98 functions). Test-based, not formal.
- **FLOURINE.** Eniser, Zhang, David, Wang, Christakis, Paulsen, Dodds,
  Kroening. "Towards Translating Real-World Code with LLMs: A Study of
  Translating to Rust." arXiv 2405.11514, 2024.
  https://arxiv.org/abs/2405.11514 (Verified: fetched). Checks translations by
  differential fuzzing and feeds counterexamples back to the model. Best of
  five LLMs succeeded on 47% of real-world benchmarks. **The counterexample fed
  back is exactly a PARALLAX divergence.**

### 6.6 Tools per rung for this team's stack (status as of 2026-10-13)

C# / .NET:

| Tool | Use | Status | Source |
|---|---|---|---|
| CsCheck | C#-first property-based testing, model-based testing, `SampleParallel` linearizability checks, strong shrinking | 4.9.1 (2026-09-17); 5.0.0-rc1 (2026-10-11); **best C# fit** | https://github.com/AnthonyLloyd/CsCheck (fetched) |
| FsCheck | mature .NET PBT, usable from C#; state-machine testing is "Experimental" | 3.4.0 (2026-08-20) | https://fscheck.github.io/FsCheck/ (fetched) |
| Stryker.NET | mutation testing: proves tests and specs constrain the code | 5.0.0 (2026-09-11), runs on .NET 10 | https://github.com/stryker-mutator/stryker-net/releases (fetched) |
| Microsoft.Z3 | SMT from C# | **nuget.org stale at 4.12.2 (2023-05)**; current Z3 5.1.0 (2026-08) ships the `.nupkg` as a GitHub release asset; use that or a private feed | https://www.nuget.org/packages/Microsoft.Z3 (fetched) |
| Microsoft Coyote | systematic testing of async/actor interleavings; `Specification.Monitor` state machines with hot/cold liveness states; "not a verification system" | 1.7.11 (2024-03-18); low activity, maintenance commits in 2026; still the best .NET concurrency choice | https://microsoft.github.io/coyote/ (fetched) |
| Dafny → C# | compiled HARD DOCK | 4.11.0 stable (2025-08-25); nightlies daily | https://github.com/dafny-lang/dafny (fetched) |
| InferSharp | static null, leak, race, taint analysis | v1.5 (2023-05); **effectively unmaintained**; avoid | https://github.com/microsoft/infersharp (fetched) |
| Nullable reference types | static null contracts; "entirely a compile-time feature"; `[NotNullWhen]`, `[MemberNotNull]` | default in new templates | https://learn.microsoft.com/en-us/dotnet/csharp/nullable-references (fetched) |
| Guard libraries | preconditions only | Ardalis.GuardClauses 5.0.0 (2024-09, active); CommunityToolkit.Diagnostics 8.4.2 (2026-03); Dawn.Guard stale | NuGet API (fetched) |
| MS Code Contracts | old .NET design-by-contract | **not supported on .NET 5+**, repo archived; docs say use nullable reference types instead; **do not use** | https://learn.microsoft.com/en-us/dotnet/framework/debug-trace-profile/code-contracts, https://github.com/microsoft/CodeContracts (fetched) |

No maintained C# library covers postconditions or invariants. Practical C#
contract stack: nullable reference types + guard clauses + `Debug.Assert` +
Roslyn analyzers + property-based tests.

React / JavaScript / TypeScript:

| Tool | Use | Status | Source |
|---|---|---|---|
| fast-check | the standard JS/TS PBT library; model-based commands | 4.10.2 (2026-09-19) | npm API (fetched) |
| StrykerJS | mutation testing | 10.0.0 (2026-08-14) | npm API (fetched) |
| XState graph | model-based test paths from statecharts | `@xstate/graph` and `@xstate/test` are **deprecated**; use the `xstate/graph` subpath (`createTestModel`, `getShortestPaths`) in `xstate` 5.33.2 | https://stately.ai/docs/graph (fetched) |
| zod, typia | schema validation at I/O boundaries | zod 4.6.7, typia 15.1.0 | npm API (fetched) |
| decorator-contracts | `@invariant` / `@demands` / `@ensures` | 1.0.0 (2025-05); small project | https://github.com/final-hill/decorator-contracts (search only) |

Language-neutral model tools:

| Tool | Use | Status | Source |
|---|---|---|---|
| Quint | TLA+-family spec language; `quint run --mbt --out-itf` writes ITF JSON traces with `mbt::actionTaken` and `mbt::nondetPicks` for model-based testing | v0.33.0 (2026-09-28); repo moved to `quint-co/quint`; first-class driver only for Rust (Quint Connect, 2025-12); **for C# or TS, write the ITF driver yourself** | https://quint.sh/docs/model-based-testing (fetched) |
| TLA+ trace validation | instrument the program to log variable updates; TLC checks the trace against the spec | Cirstea, Kuppe, **Loillier**, Merz. "Validating Traces of Distributed Programs Against TLA+ Specifications." SEFM 2024, LNCS 15280. Found mismatches in every case study | https://arxiv.org/abs/2404.16075 (fetched) |

Mapping to rungs:

- **CORRIDOR / PHASING**: CsCheck or FsCheck + Stryker.NET; fast-check +
  StrykerJS.
- **RELAY / HOMING**: Z3 models as fixtures; Quint or TLA+ traces as test
  cases; XState paths into Playwright.
- **SOFT DOCK / CLOSING**: Z3 inside tests as an oracle; TLA+ trace validation;
  Coyote monitors for async C#.
- **EPHEMERIS / FINAL APPROACH and LAGRANGE / SOFT CAPTURE**: Lean or Dafny
  reference model called from the C# test harness as a differential oracle
  (Cedar pattern).
- **HARD DOCK**: Dafny compiled to C# behind a facade, or translated with an
  equivalence check.

Other ecosystems, for adaptability (all verified by fetch unless noted):

| Language | Tool | Kind | Status | Source |
|---|---|---|---|---|
| Java | JML / OpenJML | static (ESC) and runtime (RAC) contracts | 21.0.28 (2026-10-01), active | https://github.com/OpenJML/OpenJML |
| C | ACSL / Frama-C | WP static proof; E-ACSL runtime | v33 "Arsenic" | https://frama-c.com/html/get-frama-c.html |
| Ada | SPARK | static proof, certification support | industrial | https://www.adacore.com/about-spark |
| Rust | Verus | static proof of a Rust subset | rolling releases (2026-10-12) | https://github.com/verus-lang/verus |
| Rust | Kani | bounded model checking (CBMC); contracts experimental | 0.68.0 (2026-09-16) | https://github.com/model-checking/kani |
| Rust | Creusot | deductive proof (Why3) | v0.14.0 (2026-10-12) | https://github.com/creusot-rs/creusot |
| Rust | Prusti | static (Viper) | **stalled since 2024-03**; avoid | https://github.com/prusti/prusti |
| Python | CrossHair | SMT symbolic execution for contract counterexamples | v0.0.111 (2026-09-28) | https://github.com/pschanely/CrossHair |
| Python | icontract | runtime decorators, correct inheritance | 2.7.3 (2026-01-29) | https://github.com/Parquery/icontract |
| Python | deal | runtime + linter + Hypothesis generation + Z3 | 4.24.6 (2025-11-30) | https://github.com/life4/deal |
| Eiffel | design by contract | runtime `require`/`ensure`/`invariant` | mature, niche; the origin of DbC | https://www.eiffel.org/doc/solutions/Design_by_Contract_and_Assertions |

### 6.7 Decision guide for code-level checking

- **Static contracts** (SPARK, Dafny, Verus, Creusot, Frama-C WP, OpenJML ESC):
  choose when defects are costly, code is small and stable, the spec fits
  pre/postconditions and invariants, and there is proof budget. For C#: verify
  in Dafny and compile behind a facade.
- **Runtime contracts** (icontract, deal, guard clauses, JML RAC, E-ACSL,
  Eiffel): choose when proof is too expensive but every test and production run
  should act as an oracle, and when contracts must survive refactoring by LLM
  agents.
- **Runtime-verification monitors** (LARVA, JavaMOP, DejaVu, TeSSLa, Copilot,
  Coyote monitors): choose when the property spans many calls, objects, or
  time (protocols, deadlines, per-entity rules, "every open has a close"), or
  when verdicts must come from deployed systems or logs. Parked for v2 (see
  Part 8).
- **Property-based tests as executable specs** (CsCheck, FsCheck, fast-check,
  Hypothesis/CrossHair): the default rung. Upgrade to model-based PBT (Quint
  ITF, XState paths) when a bounded model exists. Check test strength with
  Stryker.

---

## Part 7. Discovery (drafted)

### 7.1 Placement and lanes (decided by Ty)

Intent → **Discovery** → ticket → classification → Specification →
Implementation → Verification → landing.

- Discovery happens before the ticket exists, and forms it. An issue or feature
  claim comes in; discovery models it to get specifics before anything is
  built. No discovery inside WIFFLED.
- Humans live in Discovery, Specification, and Verification. LLMs handle
  Implementation wholesale. The human is the ultimate gate on landing and
  deploying.
- After the ticket and spec are ratified, Specification, Implementation, and
  Verification may loop autonomously. Implementation never starts a loopback;
  only Specification and Verification do.

### 7.2 Discovery steps (draft)

| Step | What it does | Orbital ancestor |
|---|---|---|
| SIGNAL | restate the report as one falsifiable, scoped hypothesis, or stop and ask the human | proposition sharpening |
| FLYBY | survey only the slice of the system the report touches; reproduce the defect, or show the feature is absent; "nothing to build" goes straight to GO / NO-GO | close-world |
| SPECTRUM | split the hypothesis into labeled claims, each citing the report (uncited = scope creep → proposed ticket change); classify each claim's shape and pick the cheapest tool that can falsify it | decompose-proposition |
| TRAJECTORY | state each claim in its tool; verdict holds / violated / gap; load-bearing check; record negation basis (absent vs contradicts) | model-obligations |
| SHAKEDOWN | a separate agent tries to break each claim within a budget, seeing only the report and the claim; refuted / inconclusive / abstained; never weaken a claim to absorb a witness | disprove-proposition |
| GO / NO-GO | the human ratifies the ticket (go), closes it with evidence (no-go), or sends it back to a named step (hold); only the human changes scope | human review |

Stopping rule: every claim is stated in at least one tool that can falsify it,
and the most recent tool or attack surfaced nothing new.

### 7.3 SPECTRUM's tool classifier

| Claim shape | Cheapest tool that can falsify it |
|---|---|
| a measurable quantity | a calculator or a script |
| behavior today | a reproduction or a failing test |
| structure of the code | code reading, search, or a per-ticket Prolog KB |
| rules, permissions, config combinations, arithmetic limits | SMT (Z3, cvc5) |
| ordering, concurrency, retries, state over time | TLA+ (or Quint) |
| structure, relations, data model | Alloy 6 (proposed addition) |
| a universal property of an algorithm or calculation | Lean |

Ty's point: Z3, cvc5, and TLA+ are not always needed. The classifier exists so
the cheapest falsifier is used first. Lean is the specificity ceiling; TLA+ and
SMT are the fastest refuters.

### 7.4 Gaps found in the discovery draft

- It defines scope but **not risk**. Decided: Discovery needs a risk output
  (stakes, blast radius, the kinds of mistakes agents tend to make on this
  shape of claim) to feed classification.
- It needs PARALLAX and DISCLOSURE tied in, and its answered open items closed.

---

## Part 8. Runtime verification and LARVA (Ty asked for depth)

Parked for v2's first version, but Ty wanted to understand it, and it matters
for the autonomous, observable future.

### 8.1 Two families of "annotation language"

The research separated two jobs that both get called annotation:

1. **Code annotations** describe what the code must do and travel with it:
   contracts (JML, Dafny, SPARK, ACSL) and runtime monitors (LARVA). Choose by:
   checked before running, while running, or both; and which languages are
   supported.
2. **Process annotations** describe what we know about the work and why: the
   evidence, decision, and traceability record. This is where Prolog sits
   (Part 9). Choose by: which questions the record must answer.

LARVA belongs to family 1.

### 8.2 LARVA

- **What it is.** A runtime-verification compiler for Java. A `.lrv` script
  of DATE automata compiles to AspectJ monitors, which `ajc` weaves into the
  program. Authors: Christian Colombo, Gordon Pace, Gerardo Schneider
  (University of Malta; Chalmers / Gothenburg).
- **Repo.** https://github.com/ccol002/larva-rv-tool (Verified: fetched).
  Active again: first GitHub release `v1.0.0-larva` on 2026-09-07; JDK 17+
  (validated on 21), AspectJ 1.9, MIT license, used for a University of Malta
  course. Recent commits come from `claude/...` branches, so the cleanup is
  AI-assisted.
- **DATE formalism** (Dynamic Automata with Timers and Events). Sources: FMICS
  2008 (published LNCS 5596, 2009) and SEFM 2009, "LARVA — Safer Monitoring of
  Real-Time Java Programs." https://www.researchgate.net/publication/220992830
  and https://www.researchgate.net/publication/220791179 (Verified: search
  only).
  - Symbolic automata that communicate over channels.
  - Transitions read `event \ guard \ action`.
  - Events: method calls, exceptions, timer/clock firings, channel messages.
  - Local variables; per-object replication with `FOREACH`.
  - State kinds: `BAD`, `NORMAL`, `STARTING`, `ACCEPTING`.
  - Clocks declared as `Clock c`, firing events such as `c@5`; timeouts can
    reset on each new event.
  - Actions can run recovery code, not just report.
- **Example** (cut down from the repo's `bank.lrv`, Verified: fetched):

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

  Reading: the monitor starts in `ok`. Each `addUser()` call increments a
  counter; if the guard `userCnt > 5` holds when another user is added, the
  monitor moves to the `BAD` state `toomany`.
- **Strengths.** First-class timers (real-time properties); per-entity
  replication; recovery actions; used on industrial financial-transaction
  systems (Colombo and Pace, chapter 7 of *Lectures on Runtime Verification*).
- **Weaknesses.** Java only; depends on AspectJ weaving; small academic
  community; specs contain Java code, so they are not portable; **no .NET or
  JavaScript port**.
- **Choose it** for Java systems whose rules are about event order, deadlines,
  or one monitor per object.

### 8.3 LARVA's family

| Variant | Source | What it adds | Status |
|---|---|---|---|
| ppDATE / StaRVOOrS | https://github.com/mchimento/StaRVOOrS-tool (fetched via API; papers search only). Ahrendt, Chimento, Pace, Schneider: FM'15, RV'15, FMSD 2017. Led by Chimento and Ahrendt. | Adds JML-style Hoare triples to DATE states. **KeY first tries to prove each pre/postcondition. Fully proved triples are dropped, partly proved ones get narrower preconditions, and LARVA monitors only the rest at runtime.** | Research-grade; last push 2022 |
| polyLarva | http://www.cs.um.edu.mt/svrg/Tools/PolyLarva/ and arXiv 1302.5169 (search only). Colombo, Francalanza, Mizzi, Pace (SEFM 2012; FESCA 2013). | Language-agnostic; rules `event \| condition ↦ action`; monitor in a separate process; applied to mixed C and Java | No maintained release |
| ContractLarva | https://github.com/gordonpace/contractLarva (fetched). Pace, Ellul, Azzopardi. | Weaves DATE monitors into Solidity source | v0.2.4-alpha (2023-03-28) |
| dLarva | search only | Automata that create states on the fly | Not relevant |

**The idea worth stealing is StaRVOOrS**, even if AIDLC never uses the tool. It
is the tier logic in tool form: *prove what you can; whatever is not proven is
checked another way; the record says which claims got which treatment.* That
is a precise honesty pattern for the route ladder: every claim is tagged with
the strongest check it actually received.

### 8.4 Standard references for runtime verification

- **Bartocci & Falcone (eds.). *Lectures on Runtime Verification: Introductory
  and Advanced Topics*.** LNCS 10457, Springer, 2018. DOI
  10.1007/978-3-319-75632-5 (Verified: fetched via Crossref; Springer page
  requires login). Tutorial chapters on concurrency errors, monitoring
  data-carrying events (Havelund et al.), failure prevention, cyber-physical
  systems, decentralized RV, and the Colombo/Pace industrial chapter. The
  standard textbook.
- **"Introduction to Runtime Verification."** Bartocci, Falcone,
  **Francalanza, Reger**. Pages 1–33 of the above. DOI
  10.1007/978-3-319-75632-5_1 (Verified: fetched via Crossref). Defines
  monitors, traces, verdicts, instrumentation, online vs offline monitoring.

### 8.5 Other runtime-verification languages

| Tool | Source | Spec style / what it monitors | Status | Choose when |
|---|---|---|---|---|
| JavaMOP | https://github.com/runtimeverification/javamop (fetched) | Java via AspectJ; parametric monitors; pluggable logics FSM, ERE, LTL, CFG | dormant; last release 4.4 (2016), last commit 2020 | Java API-protocol checks ("never use an Iterator after modification") |
| RV-Monitor | https://link.springer.com/chapter/10.1007/978-3-319-11164-3_24 (search) | commercial JavaMOP successor (RV 2014); 150+ Java API specs | proprietary, unclear | commercial Java/Android |
| TeSSLa | https://www.tessla.io/ (fetched) | stream-based; derive typed streams from events and logs; compiles to Rust and others | 2.1.0 (2024-07-02) | trace and log analysis, including hardware traces |
| Lola | https://software.imdea.org/~cesar/papers/dangelo05lola.pdf (search) | original stream-equation language, D'Angelo et al., TIME 2005 | paper | background |
| RTLola | https://github.com/reactive-systems/RTLola-Interpreter (fetched) | real-time stream language from Lola; CISPA | crates 0.11.0 (2025-05-15) | drones, cyber-physical telemetry, rates, sliding windows |
| Copilot | https://github.com/Copilot-Language/copilot (fetched) | Haskell-embedded stream DSL generating constant-time, constant-memory C99 monitors; NASA-funded, built by Galois and NIA | active, v4.8.1 (2026-09-08) | hard real-time embedded C |
| MarQ / QEA | https://github.com/selig/qea (fetched) | Quantified Event Automata; online or offline; won CRV'14 tracks (Reger, Cruz, Rydeheard, TACAS 2015) | dormant since 2020 | offline log checking |
| DejaVu | https://github.com/havelund/dejavu (fetched) | first-order past-time LTL with timing and recursive rules; BDDs; offline CSV logs; Havelund, Peled, Ulus | v2.1 (2024-03); pushed 2026-07 | data-comparing rules over logs ("close(f) needs an earlier open(f)") |
| Coyote monitors | https://microsoft.github.io/coyote/ (fetched) | C# `Specification.Monitor` state machines with hot/cold states; run during systematic testing, not production | 1.7.11 | the closest thing to LARVA inside .NET tests |
| NodeMOP | https://atlarge-research.com/pdfs/2019-nodemop-fschiavio.pdf (search) | JavaMOP-style for Node.js (2019) | research prototype | not production-ready |

**.NET has no maintained runtime-verification language.** Practical options:
Coyote monitors in tests; OpenTelemetry `ActivitySource` events exported and
checked offline with DejaVu, TeSSLa, or TLA+/Quint trace validation.

---

## Part 9. The evidence language (undecided; Ty wants to sync on this)

### 9.1 The question to answer first

Choose the record language by the questions the record must answer:

| Question | Best fit |
|---|---|
| What is blocking? Which claims lack evidence? Which load-bearing cell is blank? | Datalog-style rules; any engine |
| Why do we believe this claim, and why *not* that one? | s(CASP) justification trees |
| What became stale after this change? | recursive derivation rules; Datalog does this well |
| Was this approval for *this exact* artifact? | content digests, as in in-toto attestations |
| What is the smallest test set that still guards every claim? | clingo (search and optimization) |

And: is the record mainly **for Ty to query** while brainstorming and
reviewing, or **for a future orchestrator to run**? The first favors
SWI-Prolog + s(CASP). The second favors typed, always-terminating Datalog
(Soufflé).

### 9.2 Principle: separate vocabulary from engine

- Borrow vocabularies from maintained standards, so the names do not drift.
- Write records as ground facts in the syntax that Prolog and Datalog share,
  so SWI-Prolog, Soufflé, s(CASP), and clingo can all read them later.
- Ty's caveat: AIDLC's own vocabulary (orbital) must not conflict with the
  borrowed standards (Part 9.5).
- Ty's worry: over-processing. Rule proposed: **every record needs a reader**
  (a gate query or a human view). A record nobody reads is waste.

### 9.3 Logic engines

| Engine | Source | Status | Data model | Terminates? | Explanations | Pick when |
|---|---|---|---|---|---|---|
| SWI-Prolog | https://www.swi-prolog.org/download/stable, https://www.swi-prolog.org/pldoc/man?section=tabling (fetched) | 10.0.2 stable (changelog 2026-03-14); dev 10.1.18 | Horn clauses; Turing-complete; tabling with well-founded semantics | no (tabling stops left-recursion; infinite answers exhaust memory) | none built in; meta-interpreter or s(CASP) | existing Prolog KBs; one host for facts, rules, s(CASP) |
| Soufflé | https://souffle-lang.github.io/provenance, https://github.com/souffle-lang/souffle/releases (fetched) | 2.5 | typed relations (`.decl`), compiles to parallel C++ | yes for pure Datalog (arithmetic can break this) | `-t explain` minimal-height proof trees; `explainnegation` partial; docs say automatic explanation of non-existence is "not technically feasible" | batch, deterministic, typed derivation with proof trees; CI gates |
| Mangle | https://github.com/google/mangle, https://codeberg.org/TauCeti/mangle-go (fetched) | very active (commit 2026-10-12); **"not and never was an officially supported Google product"**, now independent on Codeberg | Datalog + aggregation, functions, temporal facts, optional types; Go and Rust | **no** (README says extensions give up guaranteed termination) | emerging provenance package (2026) | embeddable Go engine with temporal facts |
| DDlog | https://github.com/vmware-archive/differential-datalog (fetched) | **archived 2026-07-13**; authors moved to Feldera (SQL/DBSP) | — | — | — | never, for new work |
| CozoDB | https://github.com/cozodb/cozo (fetched) | v0.7.6 (2023-12); "still very young"; stalled | CozoScript Datalog, graph algorithms, time travel, vectors | no with aggregation in recursion | none | avoid (maintenance risk) |
| s(CASP) | https://github.com/SWI-Prolog/sCASP, https://gitlab.software.imdea.org/ciao-lang/sCASP (fetched) | maintained (Arias et al., IMDEA; SWI port claims ~10× speed) | goal-directed answer-set programming with constraints; no grounding; default negation `not p` and classical negation `-p` | no (loop detection only) | **best in class**: `--tree`, `--human`, `--html`, `scasp/2` returns the tree as a term | "why" and "why not" over defeasible rules (defeaters, gaps) |
| clingo | https://potassco.org/clingo/, https://pypi.org/project/clingo/ (fetched) | 5.8.2 (2026-08-14); clingo 6 in development | ground-and-solve ASP; multi-shot; optimization | yes on finite domains | third-party (xclingo) | search and optimization (minimal test set, counterexample model) |

**Why s(CASP) fits orbital closely.** It distinguishes `not p` ("p cannot be
shown", negation as failure) from `-p` ("p is shown false", classical
negation). That is exactly orbital's **absent** versus **contradicts**,
built into the language. Its justification trees are the honesty pillar in
machine form: every conclusion carries its "because".

**SRI's Evidential Tool Bus (ETB, ETB2).** Datalog used both for claims, rules,
and evidence, and as a workflow script integrating verification tools
(Cruanes, Hamon, Owre, Shankar; VMCAI 2013;
https://link.springer.com/chapter/10.1007/978-3-642-35873-9_18, search only).
ETB1 is Python 2.7, development stopped about 2015. ETB2 was used by the
DesCert team for CI/CD evidence tracking (Shankar et al., DASC 2024, search
only); `github.com/SRI-CSL/etb2` returned 404, and a separate fortiss project is
also named ETB2. **A design precedent, not software to adopt** — but it is the
nearest ancestor of "a Datalog ledger that drives verification tools", which is
where a deterministic AIDLC router would go.

### 9.4 Standards to borrow vocabulary from

**Assurance cases**

- **Assurance 2.0** (Bloomfield and Rushby, SRI and City/Adelard). Latest
  report SRI-CSL-25-01 (December 2025).
  https://www.csl.sri.com/users/rushby/assurance2.0,
  https://arxiv.org/html/2004.10474 (Verified: fetched).
  - Claims, argument steps, evidence, side-claims.
  - Five CAE building blocks: decomposition, substitution, concretion,
    calculation, evidence incorporation.
  - Defeaters (undercutting and rebutting), residual doubts, confirmation
    measures, indefeasibility, countercases.
  - Fit: defeaters map to orbital's refuted verdict and to v1's "a known
    counterexample requires disposition." Residual doubts map to residual
    risk.
- **Clarissa** (https://arxiv.org/abs/2408.11699, Verified: fetched). Built on
  Adelard's **ASCE** (Honeywell, Adelard/NCC, SRI, UT Dallas; DARPA ARCOS). An
  LLM translates claims into logic; **s(CASP) checks consistency,
  well-formedness, completeness, and indefeasibility.** Available from Adelard.
  Correction to an earlier claim of mine: Clarissa is not "built on s(CASP)";
  s(CASP) powers its semantic-analysis component. Advice: borrow Assurance
  2.0's concepts, not necessarily the tool.
- **GSN Community Standard** (SCSC Assurance Case Working Group). Version 3
  (SCSC-141C, May 2021) is still current; no v4 found. Referenced in ISO/IEC/IEEE
  15026-2:2022 (search). https://scsc.uk/gsn-standard,
  https://arxiv.org/html/2506.11023 (Verified: fetched). Nodes: Goal,
  Strategy, Solution, Context, Assumption, Justification; extensions for
  modules, patterns, confidence, and dialectic (defeaters, "in doubt",
  "defeated"). Metamodel only, no normative serialization; gsn2x (YAML) and
  OntoGSN (OWL) are third-party. **Good as a generated human view.**
- **OMG SACM.** 2.3 is the current formal version (October 2023, XMI
  metamodel); 2.4 Beta 1 (September 2026) is a major rewrite in flux.
  https://www.omg.org/spec/SACM/ (Verified: fetched). AssertionDeclaration
  values: asserted, needsSupport, assumed, axiomatic, defeated, asCited (from
  search, SACM 2.2 PDF). Use only for tool interchange; skip for now.

**Provenance**

- **W3C PROV.** PROV-DM, PROV-O, PROV-N, PROV-CONSTRAINTS became W3C
  Recommendations on 30 April 2013; the Working Group is closed; frozen and
  stable. https://www.w3.org/TR/prov-overview/, https://www.w3.org/TR/prov-dm/,
  https://www.w3.org/TR/prov-o/, https://www.w3.org/TR/prov-n/ (Verified:
  fetched).
  - Core types: Entity, Activity, Agent.
  - Relations: used, wasGeneratedBy, wasDerivedFrom (revision, quotation,
    primary source), wasAttributedTo, wasAssociatedWith (with a Plan),
    actedOnBehalfOf, wasInvalidatedBy; Bundle (provenance of provenance).
  - **PROV-N** is functional syntax, e.g. `wasGeneratedBy(e1, a1, -)`, which
    maps almost one-to-one onto Prolog/Datalog facts.
  - Fit: the "who produced what, from what, by which activity" layer of the
    ledger. `wasInvalidatedBy` is a ready-made name for "this approval went
    stale."

**Supply-chain attestations**

- **in-toto Attestation Framework + DSSE.** CNCF Graduated (10 February 2025,
  announced April 2025; graduation date from search). Attestation spec v1.2.
  https://github.com/in-toto/attestation/blob/main/spec/README.md,
  https://github.com/in-toto/attestation/blob/main/spec/v1/statement.md,
  https://github.com/secure-systems-lab/dsse/blob/master/envelope.md
  (Verified: fetched).
  - Layers: Predicate, Statement, Envelope, Bundle.
  - Statement: `_type` = `https://in-toto.io/Statement/v1`, `subject[]` (each
    MUST have a digest; matching is purely by digest), `predicateType`,
    `predicate`.
  - Vetted predicates include test-result (PASSED / WARNED / FAILED plus test
    lists), VSA (verification summary), provenance, release, runtime-trace.
  - DSSE v1.0.2: payload, payloadType, `signatures[{keyid, sig}]`.
  - Fit: **approvals bound to artifact digests**, tamper-evident, checkable by
    a deterministic orchestrator without trusting the LLM. Cost: key
    management and predicate design. Use only at gates (ratification,
    implementation authorization, release), never per claim.
- **SLSA provenance v1.2** ("Approved"; adds a Source Track).
  https://slsa.dev/spec/v1.2/provenance (Verified: fetched). Predicate
  `https://slsa.dev/provenance/v1`; buildDefinition and runDetails. Records
  builds; too narrow for requirements.

**Lifecycle traceability**

- **OASIS OSLC.** Core 3.0 is an OASIS Standard; RM 2.1 (2021-06-21) and QM 2.1
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
- **OMG ReqIF 1.2** (July 2016), XML interchange between requirements tools
  (DOORS, Polarion). https://www.omg.org/spec/ReqIF/ (Verified: fetched).
  Only if interchange is ever needed.

**Requirements as code**

| Tool | Source | Status | What it is |
|---|---|---|---|
| TRLC (BMW) | https://github.com/bmw-software-engineering/trlc (fetched) | 3.1.0 | typed requirement records with `checks` blocks; optional CVC5 `--verify` |
| LOBSTER (BMW) | https://github.com/bmw-software-engineering/lobster (fetched) | 1.0.6 | common `.lobster` JSON + tracing policy; coverage report requirement → code → test; extractors for Python, C++, GoogleTest, TRLC, Codebeamer; **a cheap traceability gate in CI** |
| StrictDoc | https://pypi.org/project/strictdoc/ (fetched) | 0.30.2 (2026-10-09) | `.sdoc` text format, HTML export, server |
| sphinx-needs | https://pypi.org/project/sphinx-needs/, https://sphinx-needs.readthedocs.io/en/latest/schema/index.html (fetched) | 8.5.0 (2026-09-03) | typed needs and links; JSON-Schema validation with `network_back` (e.g. "every requirement has a test") |
| Doorstop | https://pypi.org/project/doorstop/ (fetched) | 3.2 (2026-07-10) | one YAML item per file in git, document tree, link checks |

**Schema and constraint languages**

- **CUE** v0.17.1 stable, v0.18.0-alpha.3; pre-1.0, breaking changes still
  happen. https://github.com/cue-lang/cue/releases (Verified: fetched).
  Validates JSON records such as custom in-toto predicates.
- **W3C SHACL** 1.0 Recommendation (2017-07-20); SHACL 1.2 Core is a Working
  Draft dated 2026-10-13. https://www.w3.org/TR/shacl12-core/ (Verified:
  fetched). Only if records become RDF (PROV-O, OSLC).

### 9.5 Vocabulary collisions (AIDLC / orbital terms vs standards)

| Our term | Collides with | Problem | Candidate fix |
|---|---|---|---|
| descriptive / prescriptive (orbital labels) | KAOS (van Lamsweerde); Jackson–Zave "indicative/optative" | in KAOS, "descriptive" means a domain property that holds regardless of the system, i.e. not a requirement at all; our "must stay true" is prescriptive in their sense | rename by change direction: **preserve / retire / introduce** |
| counterfactual (orbital label) | philosophy and causal inference ("what if"); also our own v1 "counterfactual check" | means a conditional, not "true now, must become false" | **retire** |
| counterfactual check (v1) / load-bearing check (orbital) | mutation analysis; model-checking vacuity | two of our names for one idea that already has an established name | **mutation check**, verdict killed / survived |
| negation provenance (orbital) | database "why-not provenance", Datalog "negative provenance"; PROV/SLSA "provenance" = origin | provenance means origin in PROV, derivation in Datalog | **why-not explanation**; absent = `not p`, contradicts = `-p` (s(CASP)'s distinction) |
| witness (v1) | SV-COMP violation/correctness witnesses; in-toto's **Witness** tool (CNCF subproject) | same word in tools we may adopt | **precondition witness** or **inhabitation example**; never bare "witness" near in-toto |
| assumption (v1) | GSN Assumption (accepted without support); SACM `assumed`; Assurance 2.0 (assumptions are side-claims that *need* support) | standards disagree with each other | say which: "assumption (unsupported, GSN sense)", recorded as `assumed` |
| claim (v1 evidence type) | Assurance 2.0, GSN, SACM keep claims and evidence apart | an evidence type named "claim" mixes categories | **cited claim**, or a dependency on another claim |
| gap (orbital verdict) | GSN "undeveloped"; SACM `needsSupport` | different words, same meaning | keep "gap" for humans; map to `needsSupport` in records |
| refuted (orbital) | SACM / GSN `defeated`; Assurance 2.0 rebutting defeater | same meaning | map refuted → defeated (rebutting) |
| inconclusive (orbital) | TTCN-3 `inconc` | same meaning; TTCN-3 orders verdicts none < pass < inconc < fail < error | keep, and adopt TTCN-3's ordering |
| abstained (orbital) | close to TTCN-3 `none` | — | keep; document as "no verdict issued" |
| ANOMALY (v2 proposal) | IEEE 1044 / ISO/IEC/IEEE 24765: any deviation from expectation, a defect-classification umbrella | ours means self-disclosure | **DISCLOSURE** (kinds: guess, disagreement, unverified, out-of-scope, self-correction) |
| set-satisfied, phase satisfied (v1) | OSLC `satisfiedBy`; SysML «satisfy» (trace links) | theirs is a link, ours a status | **set-closed / phase-closed**, or "exit criteria met" |
| projection (orbital test category) | relational-algebra projection inside a Datalog KB | ambiguous in a Datalog ledger | **spec-projection test** |
| model-complete (v1) | model theory's "model-complete theory" | weak collision | optional: **model-closed** |
| subject / predicate / statement / bundle | in-toto; PROV Bundle; Prolog "predicate"; GSN node "statement" | the ledger will hold Prolog predicates *and* in-toto predicates | always qualify: `predicateType` for in-toto, "relation" for Datalog |
| PARALLAX, divergence | N-version programming; differential testing ("discrepancy") | no hard conflict | note that PARALLAX is differential testing of specifications |
| JETTISON, consistent / inconsistent, ratified, released | none found (in-toto "release" predicate is compatible) | — | — |

Two of these (preserve/retire/introduce, and the mutation-check rename) change
Ty's own orbital vocabulary. Those are Ty's calls.

### 9.6 Recommended combinations (research agent's view, light to heavy)

1. **Minimal.** Ground facts in shared Prolog/Datalog syntax, using PROV-N and
   OSLC names (`wasDerivedFrom/2`, `wasAttributedTo/2`, `validatedBy/2`,
   `implementedBy/2`). Rules in SWI-Prolog; s(CASP) for defeasible verdicts and
   justification trees. Optionally a Soufflé copy of the same rules as a
   terminating, typed CI check. Why: reuses Ty's Prolog experience; PROV-N
   maps one-to-one; names come from frozen standards; Clarissa shows s(CASP)
   works on assurance reasoning. Risks: Prolog/s(CASP) queries can fail to
   terminate (run only bounded, stratified rules in any orchestrator); outside
   parties cannot check records without our rules.
2. **Option 1 + in-toto at the trust boundary.** Only ratification,
   implementation authorization, and release become DSSE-signed in-toto
   Statements whose subjects are git digests. Test runs reuse the
   `test-result` predicate. Custom predicates (e.g. `…/aidlc-decision/v1`)
   validated with CUE. The ledger imports statement digests as facts. Why:
   graduated standard, tamper-evident, verifiable by a deterministic router.
   Risks: key management, predicate design, over-processing if every claim is
   attested.
3. **Human view.** A GSN diagram generated (never edited) from the ledger, plus
   a sphinx-needs or LOBSTER coverage gate. Why: familiar notation; maintained
   coverage tooling. Risks: GSN invites heavyweight safety-case process; two
   sources of truth unless GSN is generated only. Skip SACM while 2.4 is in
   flux.

Over-processing advice: start with option 1; add option 2 only at gates; treat
option 3 as optional. Hash-bound approvals (decided as acceptable) stay only if
a script computes them; agents should never compute hashes by hand.

---

## Part 10. Keeping the method from overfitting (decided by Ty)

Ty wants to avoid a local optimum and grow into the method as LLMs improve.

- **Fix the objectives; swap the tools.** Fixed: the set objectives (clarity,
  accuracy, honesty per set), PARALLAX, the rule that checks never exceed
  statements, divergences as the human interface, and the human landing gate.
  Variable: tools (catalog by claim shape × stack), rungs, number of
  restatements, bounds.
- **Tiers are presets over a few knobs**: how many agents restate the source,
  which rung each claim takes, how far checks run. As models improve, turn the
  knobs; the definitions stay.
- **The process measures itself.** The ledger records which step caught each
  defect. Each escaped defect points to the step that should have caught it.
  Rework (misclassification rate) is the classifier's metric.
- **Audit the classifier on purpose.** Run a sample of tickets one rung higher
  than the classifier chose. Otherwise it learns only from escapes, which is
  exactly how a local optimum forms.

---

## Part 11. Tests: FLIGHT MANIFEST moves, JETTISON prunes

### 11.1 FLIGHT MANIFEST moves to Specification (decided by Ty)

Implementation has no clarity or accuracy objective of its own; it is the
translation under test. So the executable checks that define "correct" are part
of the intent: written before code, by someone other than the implementer, and
read-only to the implementer (see ImpossibleBench and METR in Part 5).

### 11.2 JETTISON, the clean-up step (proposal; Ty asked for a slimming step)

The last Verification step before the human landing gate.

- Keep a test only if it does one of these:
  - guards a ticket claim at a public interface;
  - records a human decision (a resolved divergence);
  - reproduces a fixed defect.
- The kept suite must still kill every mutant the full suite killed, or the
  human accepts the loss.
- Drop the rest (scaffolding, tests tied to internals, duplicates) with a
  one-line reason each. The same rule applies to exploration models and
  temporary records.

Evidence:

- **Shi et al. 2014.** Shi, Gyori, Gligoric, Zaytsev, Marinov. "Balancing
  Trade-offs in Test-Suite Reduction." FSE 2014, pp. 246–256. DOI
  10.1145/2635868.2635921.
  https://experts.illinois.edu/en/publications/balancing-trade-offs-in-test-suite-reduction/
  (Verified: fetched). Reduces suites using killed mutants as the
  requirements, allows "inadequate" reduction keeping less than 100% of them.
  18 projects, 261,235 tests. **Reduced-suite quality drifts as code evolves**,
  so JETTISON's kept set should be re-checked, not trusted forever.
- **Meta ACH.** Foster, Gulati, Harman, Harper, Mao, Ritchey, Robert,
  Sengupta. "Mutation-Guided LLM-based Test Generation at Meta." FSE Companion
  2025 (Industry), pp. 180–191. DOI 10.1145/3696630.3728544.
  https://arxiv.org/abs/2501.12862 (Verified: fetched). Generates a few faults
  tied to a specific concern, then tests that kill them; engineers accepted 73%
  of tests and judged 36% privacy-relevant. Supports keeping tests tied to a
  stated requirement. Caveat: generation, not minimization; the PDF prints a
  wrong ACM DOI.
- Foundations not fetched: Ammann, Delamaro, Offutt (ICST 2014) on minimal
  mutant sets; Kurtz et al. on mutant subsumption graphs. No 2024–2026
  peer-reviewed paper combining subsumption with suite minimization was found.
- clingo (Part 9.3) can compute a minimal test set that still kills the
  required mutants, if this becomes mechanical.

---

## Part 12. Packaging (decided direction, open details)

- Ty: package as much as possible in the system prompt for now. A setup skill
  that helps a user pick engines per project is welcome but low priority. Ty is
  open to a case for skills, and to moving AIDLC to its own repo.
- The case for skills is **context cost**: instructions for Z3, TLC, Lean,
  CsCheck, Stryker only matter when a route uses them, but a system prompt
  makes every session pay for all of them. The v1 optimization ticket already
  existed to slim the prompt. Skills load on demand and can carry scripts,
  which is where determinism starts. Orbital already shows the plugin shape
  (shifting, scaffolding, trajectory, telemetry, mission-control).
- Proposed trigger for leaving dotfiles: **the first artifact that is not
  prose** (ledger rules, tool scripts, stack profiles). At that point AIDLC is
  a product: versioned, testable, shareable with the team.

---

## Part 13. Open questions, collected

**Evidence language (Ty wants to sync first)**

1. Is the ledger mainly for Ty to query, or for a future orchestrator? (Prolog
   + s(CASP) vs Soufflé.)
2. in-toto at the gates now, or later once AIDLC has its own repo?
3. Which vocabulary renames to adopt (preserve/retire/introduce; mutation
   check; why-not explanation; DISCLOSURE; phase-closed; precondition witness)?

**Framework**

4. Confirm the closure rule ("a claim that depends on a formal claim must also
   be formal") and harm as threshold, not tier selector.
5. Route names: rendezvous sequence (PHASING → HOMING → CLOSING → FINAL
   APPROACH → SOFT CAPTURE → HARD DOCK), current names with step numbers, or
   something else.
6. DISCLOSURE (or ANOMALY) as the honesty record, and its kinds.
7. JETTISON's keep rules.
8. Fulfillment in both directions (over-building treated like uncited claims).

**Carried over from the discovery draft**

9. WIFFLED: the spec session allows unattended merge to production, but Ty
   also says the human is the ultimate gate on landing and deploying. Which
   applies to WIFFLED?
10. FLYBY and TRAJECTORY are reused in Discovery with new meanings (survey,
    target model). Keep or rename?
11. What remains in the Specification set after classification: the plan,
    FLIGHT MANIFEST (now moved here), and SIMULATION's Lean statements when the
    tier needs them?

---

## Part 14. Next steps once decided

- Write `thoughts/aidlc-v2-formal-tiers-draft.md` opening with Ty's framing
  verbatim (Part 2.1).
- Update `thoughts/aidlc-v2-discovery-draft.md`: risk output, PARALLAX,
  DISCLOSURE, closed open items.
- One worked micro-example per rung on a real C# claim: claim → statement →
  divergence → test or proof.
- A ledger spike: encode one real ticket (the v1 optimization ticket is a good
  candidate) as portable facts; run gap, vacuity, and stale-approval queries in
  two engines (SWI-Prolog + s(CASP), and Soufflé).
- Later: add tiers and rungs to `ReqOf` in `model/AIDLC.tla`; rerun
  `model/check.sh` (through `heavy`).

---

## Appendix A. Corrections found by the research (things previously said that were wrong)

- LARVA is a runtime-verification tool, not an evidence or annotation-record
  language.
- "ASD-STE101" is ASD-STE100 (Simplified Technical English); no STE101 is known.
- Clarissa is built on Adelard ASCE; s(CASP) powers its semantic analysis.
- Google Mangle is not a Google product; it is developed independently.
- VERT's arXiv ID is 2404.18852 (2404.18249 is Tenspiler).
- ClarifyGPT's published title and numbers differ from the arXiv version.
- HumanEvalComm is TOSEM 2025, not 2024.
- TiCoder 2022 is an 11-author preprint; the peer-reviewed version is
  Fakhoury et al., TSE 2024.
- Clover is SAIV 2024 (LNCS 14846).
- Syzygy and FLOURINE check equivalence by testing or fuzzing; only VERT adds
  bounded model checking.
- The TLA+ trace-validation paper has four authors, including Benjamin
  Loillier.
- "Introduction to Runtime Verification" is by Bartocci, Falcone, Francalanza,
  and Reger.
- `@xstate/graph` and `@xstate/test` are deprecated.
- Microsoft.Z3 on nuget.org is stale; current builds ship from GitHub.
- Code Contracts is unsupported on .NET 5+ and archived.
- Copilot is NASA-funded, built by Galois and NIA.
- Prusti and Quint moved repos; Prusti has stalled.
- DDlog is archived; CozoDB is stalled; SACM 2.4 is only a beta; GSN v3 is
  still current; SHACL 1.2 is a draft.
- The 100× defect-cost multiplier is contested (Menzies 2017, Bossavit).
- Not peer reviewed: Kadavath, ImpossibleBench, VERT, FLOURINE, METR, Lahiri
  2026, BeSpec, Spec-Harness, OverEager, SlopCodeBench.

## Appendix B. Glossary of AIDLC v2 names (current state)

| Name | Meaning | Status |
|---|---|---|
| WIFFLED / AIMED / POKAYOKE | tiers: none / some / all of the request formal | decided |
| SUBORBITAL, FARSIDE, WAYPOINT, TETHERED | WIFFLED routes | accepted |
| CORRIDOR, RELAY, SOFT DOCK | AIMED rungs | names under review |
| EPHEMERIS, LAGRANGE, HARD DOCK | POKAYOKE rungs | names under review |
| PHASING … HARD DOCK | proposed gradient renaming | proposal |
| SIGNAL, FLYBY, SPECTRUM, TRAJECTORY, SHAKEDOWN, GO / NO-GO | Discovery steps | draft |
| PARALLAX | independent restatements compared by machine | decided |
| divergence | an input on which restatements disagree | proposal |
| DISCLOSURE (was ANOMALY) | an agent's self-report of a guess, disagreement, unverified part, out-of-scope work, or self-correction | proposal |
| JETTISON | prune tests, models, and temporary records before landing | proposal |
| tier ratchet | signals that promote claims and raise the tier | proposal |

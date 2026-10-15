# AIDLC revision: ticket record and handoff

Status as of 2026-10-05. Written before a session compaction, because the
revised AIDLC treats compaction as a loss of chat-only records. This file
is gitignored (`thoughts/*` in ~/.gitignore_global); it stays on disk only.

## Ticket manifest

- **Ticket:** optimize `shared/link/.claude/AIDLC-SystemPrompt/AIDLC.md`.
  Cut over-engineered cases without lowering output quality. Add a light
  documentation note. Cut POKAYOKE churn without losing rigor. Diagram
  every path from session start to session end.
- **Tier:** AIMED, technique-pair TRAJECTORY / ANGLING: a TLA+ model of
  the AIDLC process itself.
- **Roles:** the user is task owner, reviewer, and decision authority.
  The session agent is technical authority, implementer, and set approver.
  Sub-agents drew the diagrams and ran two independent reviews.
- **Tasks:** T1 Specification (TRAJECTORY / ANGLING). T2 Implementation
  (FLIGHT MANIFEST, IGNITION). T3 Verification (LANDING MODULE,
  SPLASHDOWN).
- **Release note:** AIDLC.md is symlinked into ~/.claude, so edits are
  live for new work sessions on save.

## Ratified requirements (user's reply, 2026-10-01)

1. Manifest-first stays for every session; the manifest may live in
   reasoning or chat, not necessarily on disk.
2. On-disk records preferred, not mandatory; useful for explainability
   and handoffs.
3. Templates fenced with XML tags, not backticks. Roles flexible: a human
   task owner and a human reviewer always; agents may hold the other four.
   Roles delineated at the start. Medium depends on tier.
4. The red run counts as the known-broken baseline; no invented mutation
   tests for trivial changes.
5. Example tests by default; property tests where warranted.
6. Evidence metadata: lighter MUSTs; a better tool at POKAYOKE (user knows
   Prolog KBs; asked about LARVA).
7. SPLASHDOWN: pull request or equivalent; WIFFLED reuses manifest prose
   and decision records.
8. Remove repetition; allocate density to the important rules.
9. Standing documentation note in the Implementation set, not pervasive.
10. Diagram by a sub-agent; TLA+ allowed for tracking states.
11. Find POKAYOKE churn reductions without sacrificing rigor.

## Exception

- **FLIGHT MANIFEST:** no executable test suite for the doc's text. The
  user rejected a regex lint: "we're not doing TDD on the AIDLC this
  way." Compensating controls: TLA+ model check, Prolog schema probes,
  two independent review passes. Scope: this ticket.

## Phase status

| Phase | Status | Evidence |
|---|---|---|
| TRAJECTORY / ANGLING | Satisfied | model/AIDLC.tla and model/check.sh; 35 of 35 checks |
| FLIGHT MANIFEST | Satisfied under the exception | see Exception |
| IGNITION | Satisfied | AIDLC.md, README.md, AIDLC-flow.md, CLAUDE.md row |
| LANDING MODULE | Satisfied | two independent reviews; all blocking findings fixed |
| SPLASHDOWN | Open | integrated as commit 15a3b04 on main, not pushed, approved 2026-10-05 ("Commit the work"); "mission accomplished" not declared, because the user wants to discuss further changes first |

## Evidence

| Check | Command | Result |
|---|---|---|
| TLA+ suite, up to 2 disruptions | `JAVA_HOME=<jre> model/check.sh 2` | 35 of 35 matched; 4,313,782 distinct states; about 10 minutes |
| TLA+ safety, up to 3 disruptions | TLC with the 17 invariants and ReleaseStep | passed; 20,646,180 distinct states; 8 minutes |
| Prolog schema, verbatim from the doc | SWI-Prolog 10.0.2 via podman | 30 probe queries matched; 0.018 s on a dense 57-artifact graph |
| Diagrams | scratchpad validate.sh | 30 of 30 renders, Mermaid 10.2.4 to 12.0.0 |

Tools: TLC 2.19 (tla2tools v1.7.4); a portable Temurin 21 JRE in the
session scratchpad, because this host has no JDK.

## Open discussion (next, nothing decided)

- **User's idea:** make FLYBY and TRAJECTORY Specification-set phases that
  are required only when a request, hypothesis, or change is very
  underspecified. They become discovery: exploring whether the problem or
  the change really exists. The user strongly thinks they should not be
  required for POKAYOKE. Talk before editing anything.
- **Concept to circle: orbital shifting**, the user's methodology for the
  "wrong-spec problem": the code is faithful to a spec that is wrong
  against reality. Treat the spec as a hypothesis, not a contract.
  Adversarially disprove each labeled claim before code exists.
  Counterexamples become first-class constraints. Shared ontology,
  counterfactual structure, curatorial human review. Plugins: shifting,
  scaffolding, trajectory, telemetry, mission-control. The AIDLC's phase
  names echo it.
- **Sources on disk:**
  - ~/Projects/mine/portfolio/public/my-work/orbital-shifting/index.html
    (the slide deck; primary description)
  - ~/Projects/client/client-hub/thoughts/fusion-vs-orbital/
    (README, orbital_rebalance_findings.md, open_questions.md, Prolog
    hypotheses)
- **Spec-session transcript:** the user pasted it on 2026-10-05; saved
  verbatim in `thoughts/aidlc-spec-session-2026-10-05.md` (4,905 words).
  It specifies the WIFFLED tier and refers to hand-drawn pictures the user
  will send.
- **Newest direction (2026-10-05):** pattern the AIDLC's SMT (FLYBY) and
  TLA+ (TRAJECTORY) phases on orbital's Prolog discovery pattern:
  close-world, decompose-proposition, model-obligations.
- **User decisions (2026-10-05, later):** the draft all-tier rules 1-5
  and WIFFLED rules 6-10 from the chat are accurate. The four WIFFLED
  routes are accepted but need recognizable names, not W1-W4. The
  pictures are skipped. The SMT/TLA+ mapping is close, but discovery
  needs its own classifier that picks tools (Z3/cvc5 are not always
  needed). Next: settle an overarching objective for discovery first:
  surface the change's requirements and problems as early as possible,
  so the specification is right, by specifying as rigorously as possible
  in several patterns.
- **User decisions (2026-10-05, latest):** no discovery inside WIFFLED.
  Discovery happens before the ticket exists and forms it: an issue or
  feature claim comes in, and discovery models it to get specifics before
  building. Route names must be space-themed and explorative, like the
  phase names; SNAPSHOT/PROBE/PLANNED/TEST-FIRST were rejected. The user
  holds that Lean (dependent types) is the most rigorous, most specific
  formal specification available; open to pushback.
- **Orbital repo:** https://git.mylegendary.quest/ty/orbital.git. Its
  pipeline gives the ticket text only to decompose-proposition; later
  stages read only their predecessor's artifact (`carrier_only_reads`), and
  measure-entailment scores the code against `hypothesis.pl`, not the
  ticket.
- **Seeds for the discussion:**
  - Two axes instead of one: the tier measures how bad a wrong
    implementation would be; discovery measures how likely the spec is
    wrong. Orbital shifting targets the second axis.
  - TRAJECTORY is the only phase that model-checks concurrency and
    ordering. If it becomes discovery-only, POKAYOKE needs another source
    for that assurance, or a trigger such as "required when concurrency or
    ordering is in scope".
  - FLYBY's new joint-satisfiability check for new behavior is already
    discovery-like and fits the user's framing.
  - The TLA+ model handles optional phases easily: `ReqOf` decides the
    required phases.

## Files of this ticket

- shared/link/.claude/AIDLC-SystemPrompt/AIDLC.md (the prompt)
- shared/link/.claude/AIDLC-SystemPrompt/README.md (edit checklist, model coverage, abstractions)
- shared/link/.claude/AIDLC-SystemPrompt/AIDLC-flow.md (Mermaid diagrams)
- shared/link/.claude/AIDLC-SystemPrompt/model/AIDLC.tla and check.sh
- CLAUDE.md (map row pointing at the README)

## v2 decisions, 2026-10-14

- **Brainstorm documents:** `thoughts/aidlc-v2-deep-explanation.md` (full brainstorm with
  verified citations) and `thoughts/aidlc-v2-deep-explanation-ste.md` (ASD-STE100 version).
- **Renames accepted "for now":**
  - claim labels descriptive / counterfactual / prescriptive → preserve / retire / introduce;
  - load-bearing check and v1 counterfactual check → mutation check (killed / survived);
  - negation provenance → why-not explanation (absent = `not p`; contradicts = `-p`);
  - witness → precondition witness;
  - ANOMALY → DISCLOSURE;
  - phase or set satisfied → closed;
  - "claim" as an evidence type → cited claim.
- **Evidence record audience:** LLMs write it and query it. Humans reach it through an AI.
  The user will also use it while brainstorming. So it serves both, with the LLM as the only
  direct writer.
- **in-toto:** the user likes it.
- **Structured output:** the user sees a strong fit for a fast model with schema-constrained
  output ("Jev" in the voice transcript; name not yet confirmed) writing records against a
  typed schema.
- **Still open:** the evidence-language decision itself (write format, query engine).

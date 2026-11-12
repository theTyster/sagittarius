# Alignment: what the build must change to agree with the new texts

The new texts are Sagittarius 0.3.0 (`prompt/SAGITTARIUS.md`) and Philosophy 2.0.0
(`docs/PHILOSOPHY.md`) on the branch `philosophy-orbit/fable-2026-11-11`. The build is `main`
at `7124544`. This document says where the build differs from the texts, and it groups the
differences into work packages. Nothing in the build is changed yet. Ty checks this document
before any work starts.

Improvements that the texts do not need are in `SUGGESTIONS.md`, in this folder.

## Ty's rulings on this document (2026-11-12, 03:04 UTC)

> your defaults are good.
>
> Alignment is good too.

So the three questions below have their defaults as answers, the defaults that Fable took
stand, and the work packages are accepted. Ty also ruled on the first six suggestions (see
`SUGGESTIONS.md`), and said: "alright lets take the work and decisions we made here and work
them into the rest of Sagittarius."

The spec for the build is one spec KB: `tmp/kb-sagittarius-030` in the main checkout. This
document is the analysis behind it.

## How this was made, and what it rests on

- Four read-only audits, one for each area, each by a separate agent that read both new texts
  in full: `audit/orbit-kb.md` (K), `audit/mindhole.md` (M), `audit/s1-install.md` (S),
  `audit/docs-evals.md` (D). The brief that they got is `audit/BRIEF.md`. Each finding there
  has the sentence of the new text, the `path:line` in the build with a quote, the smallest
  change, and the tests or contract clauses that hold the old behavior.
- 86 findings in all: K1 to K23, M1 to M21, S-c1 to S-c12 and S13 to S22, D1 to D20.
- Fable checked these again in the source or by a run: K1, K5, K9, K10, K19, K21, M2, M6, M10,
  M17, M20, S-c1, S-c2, S13, S14, and the changelog tests of D20. Each one held. The other
  findings rest on the audit that made them. A work package must check its own findings again
  before it changes anything.
- No test suite ran, no eval ran, and nobody read a held-out case.
- The KB of this analysis: `/home/ty/Projects/mine/sagittarius/tmp/alignment-kb` (project
  module). The request is Ty's words. Each finding is a `definition` (where the build is), and
  each work package is a `decision` that an agent proposed (where the build goes). List them
  with `orbit-kb --dir tmp/alignment-kb query 'proposed(X)' -n 0`.

## In short

The texts and the build agree on most of the mechanics: a check of a change must fail first,
waivers, the weights of the vote, the sealed vote, findings from the system or from a model,
the one writer, the reviewer who reads the request and not the report, and "an answer that
could not be computed is not a no". The differences that matter are these eight.

1. **The hypothesis has no home outside discovery, and a premise has no home at all.** A build
   KB refuses `hypothesis/3` (error E2). No `premise` fact exists. The texts make the
   hypothesis the law of every ticket, with its premises beside it. (K1, K3, K14, M8, M16)
2. **Nothing that the tool prints shows a formal statement, the hypothesis, or an example.**
   `report`, `show` and `why` print prose. `prove` prints the statement of the theorem once,
   and `report` does not read it. This is Ty's UAT report ("I haven't seen _any_ lean proofs or
   prolog statements"), found in the tool. (K7, K20, K16)
3. **Four quiet failures sit in places that the prompt leans on.**
   - `orbit-kb show open` can say "Nothing is open" while `done` is false. The prompt names
     this command for a resume. (K19)
   - GO wins the gate while discovery is not ready, and readiness asks for no example and
     accepts a check that never ran. (K5, K21)
   - The System 1 hook prints nothing when it is off, when it fails, and when it is unsure. (S-c2)
   - The installed prompt is a link to the working tree of one checkout, so a session cannot
     say which text it got. (S17)
4. **The build still sends a wrong problem back to discovery.** The help of the tool and the
   pane prompts do it. The texts: go back only when the agent can no longer say what the
   hypothesis changes to. (K10, M2, M17)
5. **A MindHole holds an installed copy of the philosophy, and it pins nothing.** Each hub
   imports `PRINCIPLES.md`, and seven of its nine sources are gone. A hub records no version of
   `orbit-kb`, of the prompt, or of the pane prompts, and no step gives a hub session the
   prompt. (M6, M7, M10, M5)
6. **A claim that is contested twice must get a Lean proof.** The tool takes no solver and no
   model checker there. The texts say "the language that fits that claim". (K9)
7. **The tempering tool rejects the hypothesis that the prompt calls "Fit".** Its judge calls
   a hypothesis collapsed unless it is false of a correct system. That is the finding, and not
   the hypothesis. (S13)
8. **14 check claims and one test hold the old shape of the texts.** They must change in the
   same commit that lands the texts on `main`. (D1 to D11, M4, K22)

## Three questions for Ty

Each one blocked a work package. Ty's answer to all three: "your defaults are good." So the
answers are 1 (b), 2 (a) and 3 (b).

**Question 1. `PRINCIPLES.md` in each hub (M6, M7).**
The case: you start a hub with the informal edition. It has no Sagittarius prompt. Its
`CLAUDE.md` imports `PRINCIPLES.md`, a digest of the philosophy in nine principles. Two of its
sentences are now wrong ("ask, give a concrete example, and wait for the answer"; "say what you
believe the problem is"). You said that the philosophy "should not be installed anywhere. It
should just be reflected into the system prompt".

- (a) Remove the file. An informal hub then has hub rules only, and no method text.
- (b) Keep a short file, and derive it from the prompt, not from the philosophy. Stamp it with
  the version of the prompt. Then "reflected into the system prompt" stays the one path, and
  an informal hub still has the method in short.
- (c) Keep it only in the informal edition. A formal hub gets the prompt.

Default: (b).

**Question 2. Does a MindHole have a light path? (M16)**
The case: in a hub, you ask the build pane to fix a typo. Today the build pane makes a KB,
reaches `done`, and hands the KB and the diff to the review pane, for every change. You said
that a typo never needs a KB. But in the prompt a handoff is a signal, and a signal starts a
KB.

- (a) A hub has a light path. The build pane states the hypothesis and delivers a clear change
  with a check, with no KB and no review, when no signal fired. Review comes in on a signal, or
  when you ask.
- (b) A hub has no light path. Every ticket in a hub gets a record and a review. The
  philosophy allows this ("Where a workspace keeps a record for every ticket, the hypothesis
  goes into that record"). A typo then costs a KB and a second agent.

Default: (a). It is what "clarity decides, not size" gives, and it answers your worry about a
slowdown.

**Question 3. Which formal language closes a claim that was contested twice? (K9)**
The case: the claim "With dark mode on, every screen shows a dark scheme" gets two
divergences. Today the tool says "claim c1 needs a Lean proof", and `done` is false until a
Lean proof or your waiver. You said: "I like the twice-contested claim rule". The texts say
that such a claim goes to "a formal statement ... in the language that fits that claim".

- (a) Keep the tool. Contested twice means Lean. Then the texts change in two places.
- (b) Split the rule. A claim that you ask to prove, or that is universal, still needs Lean. A
  claim that was contested twice owes a formal statement in the language that fits: a Lean
  proof closes it, and so does a counted result of a solver or a model checker on a model that
  states the claim. The texts stay as they are. The tool, its contract (D10) and the Lean
  project `kb/tests/burn_model` change.

Default: (b). It is the larger change, and it is the one that "one lens, the right lens" asks
for.

Also open, and yours already: whether the artifacts stay a third voter with no KB.

## Defaults that Fable took (Ty: "your defaults are good.")

- **The gate (K5).** The tool refuses an agent's GO while discovery is not ready, and it names
  what blocks. The human's vote is never refused. Then GO cannot win while readiness is
  blocked: the artifacts vote HOLD, and the agent cannot vote GO.
- **A red run that the agent saw before the KB existed (K4).** The agent records it as a
  disclosure with the output, and the claim stays "not shown red by the tool" in the report.
  It does not undo the change to run the check again.
- **A model that is derived from a calibrated model (K6).** It needs its own two cases. The
  prompt asks for a real failing case and a real passing case, and it does not except a
  derived model.
- **A change of plan in the middle of a ticket (D16).** It is a signal, and it gets a record.
  The record is a new hypothesis or claim that supersedes the old one, and not a divergence
  against the old claim. The evals that ask for a recorded divergence change.
- **A request as "the first divergence" (S-c1).** System 1 does not report it. The light path
  is the response to it. The exclusion in `h_divergence` stays, and `s1/README.md` says why.
- **Names.** The directory and library names `burn_model` and `BurnModel` stay. Only prose
  changes from "Lean model" to "Lean definitions". The identifiers `hubkit`, `hubflow`,
  `HUB_SESSION`, and `HUB-CORE.md` stay. "MindHole" is the display name.
- **The line limit of the prompt (D11).** No limit. The three copies of "230 lines" go.
- **`docs/PROMPT-MOVES.md` (D14).** It is a dated record of ticket T08. The checks stop reading
  it for the new prompt.

## The work packages

A package is a candidate for one spec KB and one agent. "Holds" names what must change with it
(the audit report has the lines). Sizes: S is words only; M is one feature or rule with its
tests; L touches the contract or several parts.

### orbit-kb

| Package | What changes | Findings | Size | Holds | Needs |
|---|---|---|---|---|---|
| **K-A. The hypothesis and its premises in every KB** | `hypothesis` moves to the core, with a kind that fits a direct build. A new fact for a premise, with its state (checked on the system, or not), and "Premises: none" as a record. A new hypothesis supersedes an old one in a build KB with no discovery warning (WD7). `Guesses:` lists each premise that nobody checked and each default that the agent marks in the hypothesis. | K1, K3, K14, K10 (rule part) | L | CONTRACT reserved names (lines 488 to 493), D15 R1, D17 C5; tests RW1 to RW5, NC5, RP3; the fixture `discovery-a` | nothing |
| **K-B. The tool shows what it holds** | `report` and `show` start with the hypothesis and its premises, and print one example under each claim. `report` gets `KB:`, `Signals:` and `Formal:`. `Formal:` gives, for each claim, the name of the theorem and its statement from the proof log, or the model and the property, or "none". The `Burn:` line names the theorem, says "about the Lean definitions", and says if a check carries the examples to the code. In a discovery KB, `report` drafts the discovery report from the facts (`scope`, `risk`, `not_explored`, `finding` are read by no output today). | K7, K20, K12 (first part) | M | CONTRACT line 753, D16 C4 L1; tests RP1, RL1 to RL7, RH1, BP8, FL10; the golden reports | K-A for premises |
| **K-C. No quiet "Nothing is open"** | `show open` and `Open:` print every answer of `blocking(X)`, what blocks `discovery_ready`, and each stale pin that a current claim or decision rests on. "Nothing is open" prints only when nothing blocks. | K19, K12 (second part) | M | CONTRACT line 752, D19, D22 C7, D23 P2; tests SH3, RP7, NC2, FL1 | nothing |
| **K-D. Readiness and the vote** | An agent's GO is refused while discovery is not ready. Readiness needs an example for each current claim. A red run of a check that touches the system counts as the system result of its hypothesis. A failing check of a `preserve` claim blocks readiness. A model is calibrated by two matching cases: one where the system fails and one where it passes. | K5, K21, K6 | M | D14 V2 and V3, D18; tests VT3, VT4, VT6, NC5, RW2, LG3; the fixture `discovery-a` | Ty's ruling on the third voter does not block it |
| **K-E. Restate in build; the words of the help** | `help build` "When the human says it is wrong" gets the line "Kept: ... Changed: ..." and the three cases. `help build`, `help discovery` (BACK) and step 1 of the first screen: restate in build when the answer says what the hypothesis changes to; discovery only when it does not. Step 1 no longer sends a "why?" question to discovery. `help discovery` gets the new example: the hypothesis, its premise, the finding apart, two falsifiers with their witnesses, and "wide" in place of "scoped". SPECTRUM step 4: one lens first, and a second language only when a question is left. | K10 (words), K2, K17 (1 to 3), K13 (scope), K15 | S | D15 R3; tests RW5, HP4 | K-A |
| **K-F. A claim that the records did not settle** | The burn rule splits (question 3, option b). `model`, `encodes` and `model_result` work in a build KB. | K9 | L | D10, D21 F6, E16; `kb/tests/burn_model`; tests B13, BP1 to BP13, SC1 to SC7, FL6, FL7, BL2 | question 3 |
| **K-G. Signals have records** | One fact for a signal that fired (which of the six, what differed, who noticed: the agent, System 1, or the human), and one for a lean back. `report` drafts `Signals:` from them. A fact for a decision in the human's words in a spec KB. | K16, K11, S-c5 | M | the `report` contract (as K-B) | K-B |
| **K-H. One command for the step from words to records** | One command takes the state of the light path (request, hypothesis, premises, one claim, one example, the check command) and writes the KB. One help topic of one screen for the shift. Today the step costs 4 to 8 commands and 415 to 490 lines of help. | K4 | M | CONTRACT lines 571 to 574 and 618 to 620 (`fulfilled`, `was_red`); tests HP4, HP5, HP7 | K-A |
| **K-I. Who wrote a relation** | `excludes` and `depends_on` record who wrote them. A relation by an agent is "proposed": it blocks nothing until a human ratifies it. | K8 | M | D27; tests of `test_project_kb.sh` (not listed yet) | nothing |
| **K-J. Small fixes** | The move SIGNAL gets another name, because "signal" has one meaning now (the six signals). "Lean model" becomes "Lean definitions" in the help, the module texts and the README of the tool. The fix for error E19 no longer needs an edit of `kb.pl` by hand (a command, or one sentence in the prompt that allows this one edit). Test VR6 no longer reads a "help build" line in the prompt. | K17 (4), K13, S-c10, K23, K22 | S | D22 C9 and C3; tests PH1, FU1 to FU8, VR6 | nothing |

`kb/bin/orbit-kb` is one file of about 8,000 lines, and the golden reports cover its output.
So the packages K-A to K-D and K-G change the same files. Run them one after the other, in
this order: K-A, K-B, K-C, K-D, then the rest.

### The MindHole (the hub kit and the pane prompts)

| Package | What changes | Findings | Size | Holds | Needs |
|---|---|---|---|---|---|
| **M-A. Routing in the panes** | `panes/build.md`: the three outcomes of "The hypothesis" replace "send it to discovery". `panes/discovery.md` follows, and it cites "Scope", not "The phase tree". `panes/review.md` intake: first find the ticket that a complaint is about, and hand it to the pane that holds that ticket; only a report with no ticket is "a regression or a gap". `PANES.md`: "A handoff is a signal"; a handoff in a hub is a `hubflow handoff` row, and a peer message with no row passes no work. | M2, M17, M1, M14, M13, D19 | M | `check_panes.py` c1, c3 (each pane under 60 lines; `review.md` has 59) and `REVIEW_RULES` | nothing |
| **M-B. The hub's own text carries the hub's rules** | Both `HUB-CORE.md` files say: at the start of a session and after a compaction, read the inbox. The `hypothesis` rows of "What lives where" say what the human wants for the ticket, and not "what discovery believes the problem is". A row for the vote. The `models` row says "solver and model-checker models, and Lean definitions and theorems". `divergences` gets a home in the informal edition (a note on the thread of the ticket). The briefing page names the review session, and drops `analyses/`. | M3, M8, M11, M19, M20, M18 | M | `check_hub_guidance.py` c1 (the table equals the hub design KB, so that KB changes first); `check_informal_hub.py` t41c1, t41c5, t44c2; `check_informal_release.py` c2; a new section of `UPGRADING.md` | nothing |
| **M-C. `PRINCIPLES.md`** | By question 1. With the default: a short file that comes from the prompt, with the prompt's version; the two wrong statements go; the checks read the new text. | M6, M7, S-c8, D9 | M to L | `check_informal_release.py` c3; `check_informal_hub.py` t32c2, t32c5, t36c5, t36c6, t41c1, t41c4; `kit.json`; `UPGRADING.md` | question 1 |
| **M-D. A hub pins what it runs, and a pane gets the prompt** | The hub records which `orbit-kb`, which prompt and which pane files it runs (in `.hub-template.json` or the hub's `CLAUDE.md`), and `hubkit.py status` prints it. `INSTRUCTIONS.md` gets one launcher line that sets `HUB_SESSION` and appends the prompt, `PANES.md` and the role file. Today the kit's launcher appends no prompt, and the README's sets no `HUB_SESSION`. The kit's version states which Sagittarius version it pairs with. | M5, M10, M15 | L | `hubkit-test.py` (the manifest); `check_hub_fixes.py` t46c3; `check_informal_hub.py` t32c2, t32c7; `check_hub_guidance.py` c12 | V-A |
| **M-E. The hypothesis and the light path in a hub** | By question 2. With the default: the build pane states the hypothesis of a change request (wide, with its premises); a clear change with no signal is delivered with no KB and no review; a signal brings the KB and the review pane. | M16 | M | `check_panes.py` c1; `check_consistency.py` c2 | question 2; K-A |
| **M-F. A handoff carries the KB, and a closed ticket leaves its outcomes** | The example of a handoff in the formal `hub-flow` skill has a `kb` ref. The return from review to build is a handoff. The receiver records the handoff in the KB. Before a spec KB is archived, the agent proposes each lasting outcome to the project KB and lists the proposals for the human. | M12, M21 | M | `check_hub_guidance.py` c4, c5; `check_hub_fixes.py` t31c3 | K-G for the record of a signal |
| **M-G. The name** | "MindHole" in the titles and first sentences of `hubkit/README.md`, `hubkit/INSTRUCTIONS.md`, the briefing page, and the root `README.md` and `CLAUDE.md`. | M9 | S | `check_informal_release.py` c5; `check_hub_fixes.py` t50c4; `test_release.sh` line 77 (each wants the words "hub kit") | nothing |

Each change of an engine file of the kit reaches a hub only by an upgrade. So M-B, M-C, M-D
and M-F go out as one release of the kit, with one section in `UPGRADING.md`.

### System 1 and the install

| Package | What changes | Findings | Size | Holds | Needs |
|---|---|---|---|---|---|
| **S-A. Silence is not one thing** | The hook prints one short line when it failed ("System 1: no view (reason)") and when every answer is unsure ("System 1: unsure"). The line only reports: ": consider a shift up" and "(prompt rule)" go. It names a formal tool only when the same line names a signal, or when a proof is asked for. `README.md` and `s1/README.md` say "recommended, not required" and drop "off until approved". `s1/README.md` says which signals the hook cannot see (a result inside a turn, a subagent's build, a compaction, a peer message). | S-c2, S14, S15, S-c4, S-c3 (words), S19 | M | `s1/test_hook.py` (C2, C3, c5, lines 31 to 32, 541 to 565); `test_release.sh` lines 25 to 26; `check_consistency.py` c7 | nothing |
| **S-B. `temper.py` follows the definition** | For a hypothesis, "collapsed" means that no case can show it false, as in `Hypothesis.lean` (`Collapsed`). The judge no longer asks if the statement is false of a correct system. New recordings. | S13 | M | `s1/test_temper.py` C1Trio, C1Recorded; `s1/TEMPER_LIVE_RUN.md` | a live run of the model |
| **S-C. The questions against the six signals** | Questions for the signals that a message of the human can show (a round of questions that did not settle; a proof that is asked for). One question for "changes a part" against "adds on top", if System 1 is to help with the narrowing. A tracked set of calibration cases: today the 25 known cases are in a folder that git ignores. | S-c1, S16, S-c12 | M | `s1/test_hook.py` lines 30, 150 to 157, 816 to 867; `s1/statusline.py`; `docs/PROMPT-MOVES.md` rows | a live run of the model |
| **S-D. The hook goes where the prompt goes; the prompt has an install sequence** | `install.py` makes a fifth link for `s1/`, and the snippets use that path (the paste into `settings.json` stays a paste: no script writes that file). A sequence that an agent follows: link, write the shell function for the user's shell, start one session, and ask it for the last line of its prompt. Each release that adds a link says "run `./install.py` again" (`install.py --check` fails on this machine today: the `repo-map` link is missing). | S-c6, S-c7, S17, S18 | M | `test_release.sh` lines 20 to 21 and 35 to 55; `s1/test_hook.py` lines 781 to 786; `README.md` line 46 | V-A |
| **S-E. More events for the hook** | A design question, not a change yet: which signal gets a second hook event first (a test result, a subagent's stop, a compaction). | S-c3 | L | `s1/test_hook.py` lines 109 to 112, 765 to 772 | Ty's decision; after S-A |

### The formal languages and the Lean files

| Package | What changes | Findings | Size | Holds | Needs |
|---|---|---|---|---|---|
| **L-A. A home and a check for `Hypothesis.lean`, and for each Lean home** | The file moves out of the drafts folder (for example to `docs/proofs/hypothesis/`). One script runs Lean on it and allows no axiom. One check: each theorem name that the philosophy cites is a theorem of the file, and the count in the philosophy is the count in the file. The same script runs the three projects under `kb/proofs/`, which no script runs today. | S-c9, S22 | M | nothing holds the file today | Ty's review of the definition |

K-F (the language for a contested claim) and the SPECTRUM words in K-E are the other two
changes for the formal languages.

### Versions

| Package | What changes | Findings | Size | Holds | Needs |
|---|---|---|---|---|---|
| **V-A. One source for the version** | One `VERSION` file. The last line of the prompt, `orbit-kb version`, the first line of `orbit-kb help`, `install.py --check` and the System 1 log read it or are checked against it. `orbit-kb init` writes the version into `kb.pl`. A test holds the prompt, the changelog and the file to one number. | K18, S-c11, D18 | M | CONTRACT lines 724 to 755 (the command table); tests HP1 to HP4; `test_release.sh` lines 59 to 80 | Ty's word on the numbers (0.3.0, 2.0.0) |

### Documents, checks and evals

| Package | What changes | Findings | Size | Holds | Needs |
|---|---|---|---|---|---|
| **D-A. The checks follow the new texts** | The 14 failing claims, by the table in `audit/docs-evals.md` (D-c1). Four only need a new anchor (the assertion still holds). The others hold something that the texts drop or rename on purpose: the limit of 230 lines, four headings, five topic names, pane and hub text inside the prompt, the "Applied in" lines and the old numbers of the principles, rules word for word. The word-for-word check of 18 rules becomes one key phrase for each rule. The hub checks move to the hub's text. `check_consistency.py` reports a failure and does not stop on the first missing heading. | D1 to D8, D10, D11, M4, K22 | M | the checks themselves | lands with the texts |
| **D-B. The documents** | `README.md`: the first two paragraphs and "Use it" around the two interfaces; three levels of statement, not a ladder that ends in Lean; "says how to act", not "states the philosophy in short"; the versions. `CLAUDE.md`: "Under trial", the versions, the philosophy is installed nowhere. `docs/PROMPT-MOVES.md`: marked as a record of T08. `docs/REFINING.md`: "signal" for "trigger"; the table of executors is marked as measured on the old prompt. One sentence on who uses `repo-map`. | D12, D13, D14, D15, D20, S20, S21 | S | `check_consistency.py` c7; `check_words.py` c3; `check_informal_release.py` c1, c5; `check_hub_fixes.py` t50c2; `test_release.sh` c3 | lands with the texts |
| **D-C. The evals** | Planning eval 9 asks for waiver syntax that the prompt no longer holds: it moves to the tool evals, or the assertion goes. Tool evals 16, 17, 20 and 21, and the notes of 5, 18 and 19, follow the default on a change of plan. Planning eval 8 uses the prompt's own example ("add a dark mode"): the eval changes. New cases for what no case covers: the hypothesis with its premises on a light-path ticket; the wide default; "Kept / Changed"; a wish that adds on top is a new ticket; a typo with no KB; `Formal:` beside the plain claim; the case shown to the human at the edge. `evals/run.sh` takes `--prompt FILE`, and `check_leaks.py` reads `evals.json`. A blind writer makes the held-out twins. | D16, D17 | M | `evals/evals.json` notes; `docs/REFINING.md` lines 112 to 123 | an unlocked credential; a writer who has not tuned the prompt |

## A proposed order

1. **With the texts, in one commit on `main`:** D-A and D-B, and the word fixes that cost
   nothing (M1 and M14 from M-A, K22 from K-J). Until D-A lands, 14 check claims fail on the
   branch by design.
2. **The core of the tool:** K-A, then K-B, K-C and K-D, one after the other. V-A can run
   beside them (it touches `kb/bin/orbit-kb` only for the `version` command, so it goes first
   or last).
3. **In parallel with step 2, in other files:** M-A (pane prompts), S-A and S-B (`s1/`), L-A
   (the Lean check).
4. **After K-A:** K-E, K-G, K-H, K-I, K-J, M-B, M-F, M-G, S-D, and then M-D.
5. **After Ty's answers:** K-F (question 3), M-C (question 1), M-E (question 2), S-C, S-E, D-C.

For step 2, one agent at a time writes under `kb/`. For step 3, each package has its own
files, so one agent for each package can run at the same time, each in its own worktree.

## Small points for the two texts (not applied)

The audits found five places where the texts can be more exact. They are Ty's texts, so none
is applied.

- **A peer message.** "Signals": "A message from a peer session and a compaction summary are
  handoffs." A hub also sends peer messages that pass no work. Proposed: "A message from a
  peer session that passes work". (M13)
- **The resume.** "The tool" names `orbit-kb show open`. The help says that a discovery KB
  also needs `orbit-kb lint`, because `show open` omits the discovery items. K-C fixes the
  tool. Until then the sentence is not the whole truth. (K17, K19)
- **The hand edit.** "Do not edit a KB file by hand." The fix that the tool gives for error
  E19 is an edit by hand. K-J fixes one side or the other. (K23)
- **A change of plan.** The prompt does not say in one place that a change of plan in the
  middle of a ticket is a signal whose record is a supersession. It follows from "Signals",
  "The hypothesis" and "When the human says that it is wrong" together. One sentence would say
  it. (D16)
- **The sealed vote in a hub.** "Until the human votes, do not show it". In a hub the KB is
  committed, and `kb.pl` shows the vote. The help says: "The seal guards against a mistake,
  not a look." (M-c9)

## Where the build already agrees

Each audit report has a full list. In short:

- `orbit-kb`: a check of a change must be red first; no typed digest or test result; exit 2 is
  never a "no"; waivers by the human with a due time; the weights and the sealed vote;
  findings from the system or from a model, and a lead does not block readiness; a model that
  cannot fail is an error; a claim supersedes a claim inside the hypothesis; "intent moved" is
  not a divergence; at most three questions with options and a default; a rule by an agent is
  proposed until a human ratifies it; the brief for a fresh-eyes review; the trust limit is
  said; a proof is about its Lean files and not the code.
- The MindHole: no hook in the kit; the reviewer reads the request, the KB and the diff, and
  runs each check again; a handoff reads the record; one writer; `--by human` records only the
  human's words; a skip has a due time; a failed query counts as blocking; the hub works with
  no `orbit-kb`; `PANES.md` holds the handoff procedure itself.
- System 1: no script writes `settings.json`; the hook never blocks a prompt; the content of
  the line matches the prompt; the status line shows the hint to the human; proposers never
  judge in `temper.py`.
- Documents: the six signals are still six; the graders read only the `KB:` line of the
  delivery, and that line did not change; the philosophy is installed by no script; the
  refining loop names no section of the old prompt, so it is usable as written.

## Not checked

- Whether Haiku, the executor of the evals, follows a prompt of 454 lines.
- The hook events of the installed harness, and how a peer message and a compaction summary
  appear in the transcript (S-c3, S19).
- `kb/share/orbit-kb/README.md` beyond sections 1, 3, 7 and 8; the question view and server;
  `draft`, `pin-question`, `pin-answer`, `pin-request`.
- The checks that install a scratch hub, against the new texts (by their code they do not read
  the texts).
- How much of `kb/tests/burn_model` changes for K-F.
- The hub design KB (`tmp/hub-design-kb`), which is the source of the store table (M-B).

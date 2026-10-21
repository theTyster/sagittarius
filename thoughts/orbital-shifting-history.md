# The path to Orbital Shifting: a history

Written 2026-10-21; timeline corrected the same day from a second excavation (session
transcripts, `~/.claude`, and the client work repositories). It covers Ty's AI development
process in three eras and the gap between the first two. Each entry gives its evidence.

Through every era, Ty delivered client work for Hoggwood Health, and the quality held: the
philosophy and pattern stayed intact while the automatable parts and the tools changed. Ty
never gave up Lean.

Sources:

- The plugin repository, `git@github.com:theTyster/orbital.git`. It was not at
  `~/Projects/mine/orbital` on this machine (that path is a Mac path). The research session
  cloned it read-only from GitHub over SSH, read it as data, and deleted the clone. Its
  hashes below are from that clone.
- The dotfiles repository (`/home/ty/.dotfiles`), mainly `shared/link/.claude/settings.json`,
  the AIDLC directory, and `thoughts/`.
- Ty's account of the gap, the machine switch, the lean-lsp MCP server, and ticket #1200.
  Treat it as authoritative.
- `~/.claude` (`history.jsonl`, project transcripts, `installed_plugins.json`) and the client
  work hub repository. The hub was copied from the MacBook Pro with `~/.claude` on
  2026-09-14. Session transcripts survive only from 2026-08-27; Mac-era `history.jsonl`
  entries were not carried over.

## Summary

| Era | Dates | One line |
|---|---|---|
| 1. The orbital plugins | 2026-04-02 to 2026-06-13 (heavy use); removed 2026-08-10 | A seven-stage formal pipeline: Prolog, Lean 4, proofs, tests. Strong tools. One level of rigor for all work. |
| Gap: by hand, then raw Claude | 2026-06-13 to 2026-08-28 | Ty ran the method by hand with long prompts (Prolog KBs, Lean verification, TLA+ refutation in the work hub). Then, from 2026-08-10, plain Claude. It showed that the philosophy was sound but the process had reached a local optimum. |
| 2. The AIDLC | 2026-08-28 (ticket #1200, in the work hub); global 2026-09-04 to 2026-10-21 | A governance prompt with 3 rigor tiers. An attempt to scale back. |
| 3. Orbital Shifting | live 2026-10-21 | The method comes back as a short light path. It adds a knowledge base (KB) and proofs only when a signal shows they are needed. |

A local optimum is a point where small changes make the process no better. A different shape
can still be much better. The gap was a test for this.

## Timeline

### Machines

| Date | Event | Evidence |
|---|---|---|
| 2026-01-12 | Claude Code first runs on the Linux laptop (tad-fed). | `firstStartTime` in `~/.claude.json`; first `history.jsonl` entry |
| Late 2026-02 | Ty moves to a MacBook Pro. Linux use drops from 676 history entries in February to 17 in March (short visits on 03-19, 04-27, 06-10, 06-14, 07-21). | `history.jsonl`; commits with a Mac hostname e-mail from 2026-05-12 to 2026-09-12 |
| 2026-09-14 | Back on the Linux laptop. `~/.claude` and the client work are copied over as they were. The last `/Users/ty` transcript day is 09-13; the first `/home/ty` day is 09-14. | transcript `cwd` per day; file times in the copied work tree; plugins reinstalled 09-14 |

### Era 1: the orbital plugins

| Date | Event | Evidence |
|---|---|---|
| 2026-04-02 | First commit of the plugin repository, then named `logic-focused-claude`. | orbital repo, 0a9e8b3 "Initial release of logic-focused-claude plugin" |
| 2026-04-08 | The reasoning pipeline merges in. Version 2.0.0. | orbital repo, c70bb82 |
| 2026-05-05 | The dotfiles start to track Claude settings. `logic-focused`, `utilities`, and `multi-plan` plugins are already enabled by 2026-05-15. | dotfiles 3155ace, bde79f1 (adds `multi-plan`, 2026-05-06) |
| 2026-05-07 | The `multi-plan` skill is retired. `single-ticket-pipeline` is renamed `pipeline`. | orbital repo, 2e316fa |
| 2026-05-15 | Ty switches to `shifting@orbital`, `telemetry@orbital`, and `trajectory@orbital`. Effort goes from medium to xhigh. | dotfiles d560af0 |
| 2026-05-18 | The pipeline is in regular use ("dogfooded since 2026-05-18"). | orbital repo, 3aa6f9b (a commit message) |
| 2026-05-25 to 2026-05-27 | A fifth plugin, `mission-control`, is built in 14 steps. | orbital repo, d7e035e to 5147b9d |
| 2026-05-29 | The dotfiles point the `orbital` marketplace at the local working copy. Effort goes to high. | dotfiles 933a113 |
| 2026-06-08 | `trajectory@orbital` (the orchestrator) is turned off. `mission-control` is removed. | dotfiles a3f007e |
| 2026-06-10 | Last feature commit in the plugin repository. | orbital repo, 29e898e |
| 2026-06-13 | `shifting` and `telemetry` are turned off. `scaffolding@orbital` and the Lean 4 skills plugin come on. The lean-lsp MCP server is added at the same time (Ty's account; the config in `~/.claude.json` is undated, and it is documented by 2026-07-10). | dotfiles 02d1d18 |
| 2026-07-01 | A GitHub Pages deck is added. The repository is nearly idle. | orbital repo, c569ad9 |
| 2026-08-05 | The agents are split into their own plugin (the last commit in the repository). `shifting@orbital` is turned on for a short time, then replaced by `agents@orbital` the same day. | orbital repo, f1bfcd5; dotfiles 259efe9, 36a914e |
| 2026-08-10 | The `orbital` marketplace is removed from the settings. No orbital plugin remains. | dotfiles 0ee2e6e |

Commit activity in the plugin repository, by month: April 124, May 96, June 13, July 1,
August 1 (235 commits in total).

**What the plugins did.** `shifting` ran a seven-stage pipeline on one ticket:

1. `close-world`: write the codebase as a Prolog KB.
2. `decompose-proposition`: turn the request into a hypothesis.
3. `model-obligations`: build a model of the target world.
4. `prove-invariants`: prove each property in Lean 4.
5. `instantiate-properties`: turn the proofs into tests.
6. `realize-specification`: have sub-agents make the tests pass.
7. `measure-entailment`: score how well the code fulfills the request.

An `explain` closer always ran after the stages, and `disprove-proposition` attacked a claim.
`trajectory:pipeline` ran the stages. `scaffolding` handled setup, the Lean toolchain, and
C4 architecture models. `telemetry` held small tools (make-commits, create-presentation).

**How heavy it was** (from the repository, read 2026-10-21):

- 25 skills in the plugins that existed, 17 sub-agents in `shifting`.
- The `shifting` skills have 2,541 lines of instructions. The agents have 3,413 lines. The
  `trajectory:pipeline` skill has 499 lines.
- A hook (`check-chain.sh`) blocked reads of pipeline files that were older than the files
  they came from.
- It needed Lean 4, a shared Mathlib clone, and SWI-Prolog before the first run.
- Ty ran it at xhigh effort on the strongest model (dotfiles d560af0). The design notes list
  "Opus at high effort for every stage" as a dropped part.

**What it taught.**

- The aim was the "wrong-spec problem": code can match a spec exactly, and the spec can still
  be wrong. The plugin treated the spec as a hypothesis and tried to disprove it before any
  code existed. That idea survived into every later era.
- The tools were good and the instructions were good. But there was one set of tools and one
  level of rigor for all work, and it was too strict
  (`thoughts/aidlc-v2-deep-explanation-ste.md`, section 1.3, Ty's words as recorded there).
- The pipeline never kept the original request in view after stage 2 (same file, section 1.2).
  Later stages read only the artifact of the stage before them.

**Why the next era followed.** Heavy machinery ran on every ticket. Work on the repository fell from 96 commits
in May to 13 in June, and the plugins went off one by one from 2026-06-08. The cost of the
machinery is the reason (Ty's account: it "added too much machinery to the development
lifecycle").

### The gap: by hand, then raw Claude

Ty's account: there was a gap between the plugin and the AIDLC. Ty ran the process by hand
with long, detailed prompts. This phase was a test for a local optimum in the process. Then
Ty removed the process entirely and worked with raw Claude. That proved the old process could
be made more efficient. It added too much machinery to the development lifecycle.

The work hub shows what "by hand" meant: the formal methods kept running, driven by prompts
instead of plugins.

| Date | Event | Evidence |
|---|---|---|
| 2026-06-08 to 06-16 | Sixteen Prolog-KB refresh commits and a triage workflow in the work hub. | hub commit subjects |
| 2026-06-18 | Lean verification for a client ticket (#2686). | hub, four commits |
| 2026-07-09 to 07-20 | A Prolog-KB refresh workflow; a repair program and a microsite with Lean and Prolog code. | hub commit subjects |
| 2026-07-24 | Ticket #1200 is estimated. | hub, `ESTIMATE-2026-07-24.md` (commit 31e40bad) |
| 2026-07-29 to 08-02 | An adversarial refutation pass over a spec's axioms finds a false axiom and ends with a TLC-checked lifecycle. | hub commit subjects |
| 2026-08-05 | `shifting` comes on and is replaced by only the agents plugin on the same day. This is the last trace of the plugins. | dotfiles 259efe9, 36a914e |
| 2026-08-10 | The plugins are removed completely. Raw Claude: the dotfiles change only the model, the effort, shell helpers, a statusline, and a `simple-english` skill until the AIDLC. | dotfiles 0ee2e6e, 57c42d5, a37cce5, aa28c08, 1277d2e |
| 2026-08-28 | The gap ends with ticket #1200 (next section). | hub 2d31b4f7 |

**What it taught.** The old philosophy was sound, but the process had reached a local
optimum (Ty's words). Running it by hand did not make it better, and plain Claude still
worked, so small changes would not help: the process needed a different shape, with less
machinery. Raw Claude gave no protection against the wrong-spec problem, so the answer was
not "no process". The test showed what to cut, not that all process should go.

**Why the next era followed.** Ty wanted to keep the goal (alignment, clarity, accuracy) and
cut the cost. The next attempt was a governance prompt that scales with the task.

### Era 2: the AIDLC

The AI Development Life Cycle (AIDLC) is a system prompt that `claude()` in
`shared/copy/.zshenv` appends to each work session.

| Date | Event | Evidence |
|---|---|---|
| 2026-08-28 | Ticket #1200, the first ticket under the AIDLC: SPECVER.1 for a Lean formalization of the eligibility service. | hub 2d31b4f7 |
| 2026-08-31 | `AIDLC.md` (158 lines, 4 tiers, 8 phases) is committed in the work hub, always in context. | hub 7360be78 |
| 2026-09-04 | The AIDLC becomes the global system prompt. First dotfiles commit: a main prompt, a docs tree with one file for each of the 9 phases, and 4 tiers. Ty works ticket #1200 with a 10,000-character planning prompt the same day. | dotfiles e57a5f9; hub 275b26e7; session transcript |
| 2026-09-15 | The `hoggwood` plugin is installed; the first production commits tagged 1200. | `installed_plugins.json`; Backend git log |
| 2026-09-10 | Rules added for specification verification (SPECVER). | dotfiles 3eb2bd2 |
| 2026-09-11 | Phase and tier names lose their numbers. Four tiers become three: WIFFLED (no formal methods), AIMED (some), POKAYOKE (all nine phases). | dotfiles d0eb853 |
| 2026-09-14 | A counterfactuals section is added. | dotfiles e1d3e39 |
| 2026-09-24 | The 17-file tree becomes one self-contained prompt. Work is grouped into three sets: Specification, Implementation, Verification. | dotfiles 8b2d093 |
| 2026-10-05 | A revision to "slim AIDLC overhead" for simple work. A TLA+ process model and flow diagrams are added. The same day, Ty speaks the WIFFLED spec. | dotfiles 15a3b04; `thoughts/aidlc-spec-session-2026-10-05.md` |
| 2026-10-13 and 2026-10-14 | The v2 brainstorm. Key ideas: the tier cannot be graded once, so a ratchet moves it up after a miscommunication; signals trigger a move up; only the human can bypass work, with a deadline. | `thoughts/aidlc-v2-deep-explanation-ste.md`, sections 3.1 to 3.3 (written 2026-10-14; research ran 2026-10-13) |

**What it kept from the plugin era.** The wrong-spec idea. Claims with labels. Counterexamples
that block work. Evidence that names its type. Proofs and models for high-risk work, in
the top tier. A red test before the fix. The phase names echo orbital names (FLYBY,
TRAJECTORY).

**What it dropped.** The fixed seven-stage order for every ticket. The Prolog pipeline as the
default. Strong tools for small work: WIFFLED needs no formal methods.

**What it taught.**

- A tier chosen once at the start does not work. Nobody knows how much must be formal until a
  miscommunication happens (Ty's rule, recorded 2026-10-13).
- The AIDLC grew. `AIDLC.md` was about 51 KB on 2026-10-04 and 67 KB after the "slim"
  revision (2026-10-05). It added sets, tasks, charters, roles, and a traceability matrix.
  The scale-back worked for tiers but not for the amount of text and records.

**Why the next era followed.** Ty's v2 brainstorm asked for a method with flexible rigor
that starts light. It also asked that the request stay in view in every phase. The AIDLC
structure could not give that without a rewrite.

### Era 3: Orbital Shifting

| Date | Event | Evidence |
|---|---|---|
| 2026-10-13 | Decision: start low, move up after a miscommunication ("start light, shift up"). | `thoughts/orbital-shifting-system-prompt-draft.md`, Open item 5; agent memory note |
| 2026-10-14 | The draft prompt, with the "one-agent orbit" and parallax ideas. | `thoughts/orbital-shifting-system-prompt-draft.md` (status line) |
| 2026-10-15 | `orbit-kb` is built: a command-line tool that keeps a checked KB in s(CASP) (Prolog with default negation). The contract is written. | `shared/link/.local/share/orbit-kb/README.md`; `thoughts/orbit-kb-contract.md` |
| 2026-10-16 | `orbit-kb` is committed. An independent review (D7) and a speed fix (D8) follow. | dotfiles ec39fec; `thoughts/orbit-kb-perf-results-2026-10-16.md` |
| 2026-10-19 | A burn needs a proof (decision D10): a claim that must hold for all inputs needs a Lean proof that the tool checks, or a human waiver with a due time. The discovery orbit merges into the draft. | dotfiles ff5dc24, 9673ab9; `thoughts/orbit-kb-d10-record.md` |
| 2026-10-20 | The trust threat model: the tool guards against honest mistakes, not against cheating. Three refinement passes (clarity, honesty, speed). The shift-up triggers are defined. The microsite is first added. | dotfiles cb7ba90, 830e6f5, 504f759, 5ff08ee, b6e3499, 55cf96d; `thoughts/orbital-shifting-refinement-record.md` |
| 2026-10-21 | Review rounds. A check gets one meaning. Two orbits and the tiny discovery orbit. The weighted GO / NO-GO / HOLD vote. The prompt goes live in place of the AIDLC. | dotfiles bda97c5, add071d, 1ecad99, e009cfe |

**What it is.** A prompt of 869 lines (47.6 KB) at
`shared/link/.claude/orbital-shifting/ORBITAL-SHIFTING.md`. The core is a five-step light
path with no KB. Four triggers shift the work up to a KB: questions, a divergence, a claim that
burns, and a handoff. When the cause is resolved, the work shifts back down. The `orbit-kb`
tool (about 5,300 lines) keeps the KB and enforces its schema. Two orbits split the work:
discovery (make the problem clear) and build (deliver the solution).

**What it brings back from the plugin era.** The closed-world survey, claim labels
(preserve, retire, introduce), disproving claims, counterexamples as tests, and Lean proofs for
claims that must hold for all inputs. The aim is the same: alignment between the human, the
agent, and the formal artifacts.

**What it drops from the AIDLC.** Sets, tasks, charters, roles beyond human and agent,
per-ticket tiers, phase approvals, traceability matrices, the seven-stage order, and the TLA+
model of the process (the design notes list these as dropped).

**What it adds.** Rigor that follows the risk in both directions. The human, the agent, and
the formal artifacts vote on discovery results, with weights 0.4, 0.3, and 0.3. A
divergence is recorded as good news. A burn needs a proof.

**Shown so far.** Twelve one-shot planning evals on Haiku pass on the live prompt, in two of
two runs (`thoughts/orbital-shifting-evals/grading-20261021-final.md`). Those evals test the
plan an agent makes, not a full ticket. The claim that it is more efficient is still a goal,
not a result.

## Lean in every era

- Plugins: a Lean parser for nvim (04-02), `LEAN_PATH` from a shared Mathlib (04-14), the Lean 4
  LSP (04-29).
- Gap: Mathlib setup (06-14), Lean verification for #2686 (06-18), `lean-lib` and the nvim
  latency model (07-10), the #1200 formalization (08-28).
- AIDLC: `lean-lib` becomes sharlean (09-11); the `lean_guard` hook (10-14).
- Orbital Shifting: a burn needs a Lean proof recorded by `orbit-kb prove` (10-19).

## Left open

- The exact day of the move to the MacBook Pro (late February, from `history.jsonl` volume).
- The day the lean-lsp MCP server was added (Ty: about when the plugins went off, 06-13).
- The boundary between "by hand" and "raw Claude": the plugin removal on 08-10 is used.

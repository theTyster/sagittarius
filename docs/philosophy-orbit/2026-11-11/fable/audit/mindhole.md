# Alignment audit: the MindHole (hub kit and pane prompts)

Area: `hubkit/` and `prompt/PANES.md`, `prompt/panes/*.md`, with the checks that read them.
Auditor id prefix: `M`. Date: 2026-11-11. Read only. No file in a checkout was changed.

Short names in this report:

- `MAIN` = `/home/ty/Projects/mine/sagittarius` (the build as it is today, branch main).
- `NEW` = `/home/ty/Projects/mine/wt/sagittarius/philosophy-fable` (the proposal).
- "new prompt" = `NEW/prompt/SAGITTARIUS.md`. "new philosophy" = `NEW/docs/PHILOSOPHY.md`.
- "old prompt" = `MAIN/prompt/SAGITTARIUS.md`. "old philosophy" = `MAIN/docs/PHILOSOPHY.md`.

How the checks were run. The proposal branch differs from main in five files only (the prompt,
the philosophy, and three files under `docs/philosophy-orbit/`; `git diff --stat main 84c7d0c`).
So the copy of a check script in `NEW` reads the new prompt and the new philosophy against the
same hub kit and pane prompts. I ran only the claims that read text (no install, no suite):
`python3 -B NEW/docs/check_hub_guidance.py c5|c9|c12`, `check_hub_fixes.py t31c4|t31c8|t31c9|t46c3`,
`check_panes.py`, `check_informal_release.py c3`, `check_informal_hub.py t32c5|t36c6`,
`check_consistency.py c1..c9`. The same claims pass in `MAIN`.

## Summary

| Id | Title | Kind | Size |
|---|---|---|---|
| M1 | `discovery.md` cites "The phase tree", a section that the new prompt does not have | stale words | S |
| M2 | The panes send every "the problem is wrong" back to discovery | contradiction | M |
| M3 | With the hub lines gone from the prompt, no always-loaded hub text says "read your inbox first" | gap | S |
| M4 | Six hub checks fail or crash against the new prompt | stale words | M |
| M5 | No step gives a hub session the prompt, and nothing says which version it got | gap | M |
| M6 | The kit installs a digest of the philosophy (`PRINCIPLES.md`) in every hub | contradiction | L |
| M7 | `PRINCIPLES.md`: 7 of 9 source names are gone, 2 statements are now wrong, 5 principles are missing | stale words | M |
| M8 | The `hypothesis` rows of "What lives where" say "what discovery believes the problem is" | stale words | M |
| M9 | The name "MindHole" is nowhere in the tree | stale words | S to L |
| M10 | A hub pins no version of `orbit-kb`, of the prompt, or of the pane prompts. Roles and routing live outside the hub | gap | L |
| M11 | The vote has no row in "What lives where" | gap | S |
| M12 | A handoff can cross panes with prose only: the tool takes a row with no KB ref, and the skill's example shows one | gap | M |
| M13 | A hub does not say which peer messages are handoffs | gap | S |
| M14 | `PANES.md` says "A handoff is a trigger" | stale words | S |
| M15 | The kit version is tied to the db schema and to `PRINCIPLES.md`, and has no link to a Sagittarius version | gap | M |
| M16 | A hub has no light path: the build pane has no rule for the hypothesis of a change request | gap | M |
| M17 | Intake knows two kinds of report. The new prompt has three cases for "it is wrong" | gap | M |
| M18 | The briefing page gives the build session the review, and lists a week slot that the kit removed | contradiction | S |
| M19 | The kit calls Lean a model | stale words | S |
| M20 | The informal edition keeps no record of a divergence | contradiction | M |
| M21 | Closing a spec KB has no step to give a lasting outcome a home | gap | M |

Counts. Kind: 4 contradiction, 10 gap, 7 stale words. Size: 8 S (M9 counted as S for the display
name), 11 M, 2 L.

---

## Candidates

### M-c1. Citations of old prompt sections. Verdict: PARTLY

The lead named six section names. Only one is cited. I searched `MAIN/prompt/PANES.md`,
`MAIN/prompt/panes/*.md`, and all of `MAIN/hubkit/` (tests excluded) for "phase tree", "When to
shift up", "Honesty rules", "Where the procedure is", "Start light", "Roles", "Sagittarius
prompt", "SAGITTARIUS.md", "Triggers".

| Where | Citation | In the new prompt? |
|---|---|---|
| `MAIN/prompt/panes/discovery.md:3` | `(see "The phase tree" in the Sagittarius prompt)` | No. The text is now in "Scope" (new prompt lines 95 to 103). |
| `MAIN/prompt/PANES.md:24` | `A handoff is a trigger` (the word of the old `Triggers:` field) | The word is now "signal" (see M14). |
| `MAIN/prompt/panes/discovery.md:13` | `` `orbit-kb help discovery` GATE step 5 `` | A help topic, not the prompt. It exists: `MAIN/kb/share/orbit-kb/help/discovery.txt:209`. |
| `MAIN/prompt/panes/review.md:51` | ``FULFILL brief, `orbit-kb help build` `` | A help topic. It exists: `MAIN/kb/share/orbit-kb/help/build.txt:76`. |
| `MAIN/hubkit/hub/PRINCIPLES.md:10` to `:60` | nine `Source: docs/PHILOSOPHY.md, "..."` lines | The philosophy, not the prompt. Seven names are gone (see M7). |
| `MAIN/hubkit/hub/HUB-CORE.md:188`, `MAIN/hubkit/hub/.claude/skills/hub-flow/SKILL.md:91` | `PANES.md` ("Handoffs in a hub") | Not the prompt. The target exists: `MAIN/prompt/PANES.md:29`. |
| `MAIN/hubkit/INSTRUCTIONS.md:34` | `` (`HUB-CORE.md`, "Verify") `` | Not the prompt. The section exists only in the informal `HUB-CORE.md` (`MAIN/hubkit/editions/informal/HUB-CORE.md:108`). The formal file has "Panes" in its place. |

No file of the hub kit names a section of the prompt. "Honesty rules", "When to shift up",
"Where the procedure is", "Start light" and "Roles" are cited nowhere in my area.

#### M1. `discovery.md` cites "The phase tree", a section that the new prompt does not have

- **New text**: "Scope": "Work has two levels. The orbit is discovery or build. Each orbit has two phases".
- **Build**: `MAIN/prompt/panes/discovery.md:3`: `the phases research and specify (see "The phase tree" in the`.
- **Kind**: stale words.
- **Smallest change**: in `prompt/panes/discovery.md`, cite "Scope", or drop the citation.
- **Size**: S.
- **What holds the old behavior**: nothing. `docs/check_panes.py` c1 only refuses a citation of "Discovery orbit" (`MAIN/docs/check_panes.py:78`). It does not check that a cited section exists.

### M-c2. A wrong problem goes back to discovery. Verdict: CONFIRMED for the pane prompts, NOT CONFIRMED for `hubflow.py`

`hubflow.py` has no rule about roles or routing. A search of it for "discovery", "review",
"verify", "verdict", "hypothes", "vote" finds one line, an example seed
(`MAIN/hubkit/hub/.claude/scripts/hubflow.py:117`). The routing is only in the pane prompts.

#### M2. The panes send every "the problem is wrong" back to discovery

- **New text**: "The hypothesis": "If the answer says what it changes to ("only on this page"), restate it: the new hypothesis supersedes the old one. Show it, and go on. If you can no longer say what to change, the ticket is a report again: go to discovery." New philosophy, principle 2: "in a workspace discovery is another agent, so a return has a cost."
- **Build**:
  - `MAIN/prompt/panes/build.md:19`: `If a finding shows that the problem is wrong, not the build, send it to **discovery**.`
  - `MAIN/prompt/panes/discovery.md:27`: `When build or review finds that the problem is wrong, the work comes back to you.`
  - `MAIN/prompt/panes/build.md:3`: `You do not decide what the problem is`.
  - These follow the old prompt (`MAIN/prompt/SAGITTARIUS.md:53` to `:54`: `If a divergence shows that the problem is wrong, not the build, go back to discovery.`).
  - Two rules already agree with the new text: `MAIN/prompt/panes/build.md:16` (`If you cannot say what to change, the request is a report.`) and `:17` (`record a new claim that supersedes the old one, and disclose it`).
- **Kind**: contradiction.
- **Smallest change**: in `prompt/panes/build.md`, replace line 19 with the three cases of "The hypothesis": the hypothesis stands (fix the build); the human's answer says what it changes to (build restates it in the KB, shows the human, and goes on); build cannot say what it changes to (hand off to discovery, by the handoff procedure). Change `prompt/panes/discovery.md:27` to match.
- **Size**: M.
- **What holds the old behavior**: no check reads these two lines (`docs/check_panes.py` has phrases for `review.md` only, `MAIN/docs/check_panes.py:26`). Not checked: whether `orbit-kb` lets the build pane supersede a hypothesis after the human's approval of the ticket (`MAIN/kb/share/orbit-kb/help/discovery.txt:209` to `:210` records the approval on a digest). That belongs to the `orbit-kb` audit, and it can raise the size.

### M-c3. Hub procedure without the prompt. Verdict: PARTLY

What the old prompt held about a hub (`MAIN/prompt/SAGITTARIUS.md:24`, `:218` to `:220`) and
where it is without the prompt:

| Old prompt line | Still somewhere else? |
|---|---|
| `:24` "With panes, a report goes to review (intake) first" | Yes: `MAIN/prompt/PANES.md:6` and `:18`. |
| `:218` "`hubflow` is `python3 .claude/scripts/hubflow.py`" | Yes: `MAIN/prompt/PANES.md:30`. `HUB-CORE.md` writes `hubflow.py`. |
| `:218` "Read the inbox first (`hubflow view v_inbox`)" | Only in a skill that loads on demand, and in the kit's setup file. See M3. |
| `:219` "follow each item's kb ref (`hubflow where SLUG`) and run `orbit-kb show open` there" | Yes: `MAIN/prompt/PANES.md:32` to `:33`, `MAIN/hubkit/hub/HUB-CORE.md:86`. |
| `:219` "HUB-CORE.md says which store holds what" | Not needed: `HUB-CORE.md` is loaded by the hub's `CLAUDE.md` (`MAIN/hubkit/hub/CLAUDE.md:7`). |

The handoff procedure and the roles are complete in `PANES.md` (`MAIN/prompt/PANES.md:29`:
`One procedure, written once here`). But `PANES.md` reaches a hub session only through the
launcher of the README (see M5).

#### M3. With the hub lines gone from the prompt, no always-loaded hub text says "read your inbox first"

- **New text**: "The tool": "A workspace, such as a hub, names its own tools, roles, and routing in its own instructions. Follow them there." "Signals": "Read what is open from the record, not from the summary."
- **Build**: the rule is in three places, and none is always in the context of a hub session.
  - `MAIN/hubkit/hub/.claude/skills/hub-flow/SKILL.md:64`: `Read at session start and after every compaction: the db is the memory, not the conversation.` A skill loads when it is called.
  - `MAIN/hubkit/INSTRUCTIONS.md:154`: `**Every session start, and after every compaction:** read `v_inbox` for that session.` This file is not installed in a hub (`MAIN/hubkit/kit.json:3` to `:19` does not list it).
  - `MAIN/prompt/PANES.md:32`: `The receiver reads its inbox`. It is inside the handoff procedure.
  - `MAIN/hubkit/hub/HUB-CORE.md:219` has only: `Load the `hub-flow` skill before any write.` A search of both `HUB-CORE.md` files and both `CLAUDE.md` templates for `v_inbox` finds nothing.
- **Kind**: gap.
- **Smallest change**: add one sentence to "Flow state lives in the db" in both `HUB-CORE.md` files: at session start and after a compaction, read the inbox (`python3 .claude/scripts/hubflow.py view v_inbox`), then follow each item's ref.
- **Size**: S (an engine file changes, so a kit release: see M15).
- **What holds the old behavior**: `docs/check_hub_guidance.py` c5 wants the line in the prompt (`MAIN/docs/check_hub_guidance.py:245`).

#### M4. Six hub checks fail or crash against the new prompt

- **New text**: the new prompt has no word "hubflow", "inbox" or "HUB-CORE". Its "Scope" has no pane sentence. It has 454 lines.
- **Build** (each result is from a run in `NEW`; each passes in `MAIN`):

| Check | Result against the new texts | What it reads |
|---|---|---|
| `check_hub_guidance.py c5` | 4 of 12 fail: `prompt resume paragraph: has 'in a hub'`, `'inbox'`, `'hubflow'`, `'hubflow where'` | `MAIN/docs/check_hub_guidance.py:242` to `:245` |
| `check_hub_guidance.py c9` | 3 of 5 fail: `has 'orbit-kb help project'`, the `HUB-CORE.md` line, `prompt stays within 230 lines: 454` | `:287` to `:293` |
| `check_hub_fixes.py t31c4` | 1 of 1 fails: `prompt uses hubflow: never` | `MAIN/docs/check_hub_fixes.py:113` to `:122` |
| `check_consistency.py c4` | `FAIL: the report bullet in Scope is missing` (it wants "panes", "review", "intake" in the prompt's "Scope") | `MAIN/docs/check_consistency.py:75` to `:85` |
| `check_informal_release.py c3` | 7 of 46 fail (the source names of `PRINCIPLES.md`, see M7) | `MAIN/docs/check_informal_release.py:240` to `:245` |
| `check_informal_hub.py t32c5` | 4 of 19 fail (three old headings, and it runs c3 above) | `MAIN/docs/check_informal_hub.py:388` to `:406` |

  These pass unchanged: `check_hub_guidance.py c12` (11 checks), `check_hub_fixes.py t46c3` (7), `t31c8` (10), `check_informal_hub.py t36c6` (8), `check_panes.py` (c1, c2, c3, rules), `check_consistency.py c2, c3, c5, c7, c8`.

  Outside my area, but seen in the same runs: `check_hub_fixes.py t31c9` fails 4 of 4 (it reads a `**The hypothesis.**` paragraph and the 230-line limit). `check_consistency.py c1`, `c6` and `c9` stop with `ValueError: substring not found` and print no verdict. c9 also holds a hub kit check (the count of ideas in `hubkit/README.md`, `MAIN/docs/check_consistency.py:149` to `:157`), and the crash hides it.
- **Kind**: stale words (the checks pin the old home of the hub lines).
- **Smallest change**: move the prompt half of c5, c9, t31c4 and consistency c4 to the text that now holds the rule (`PANES.md`, `HUB-CORE.md`), and drop the 230-line limit from the hub checks. Do it in the same commit that lands the new prompt.
- **Size**: M.
- **What holds the old behavior**: the checks themselves. `check_hub_fixes.py t31c6` also reads a landing script that runs every claim id (`MAIN/docs/check_hub_fixes.py:137` to `:155`); I did not read that script (it is under `tmp/`).

### M-c4. How a hub session gets the prompt. Verdict: CONFIRMED

#### M5. No step gives a hub session the prompt, and nothing says which version it got

- **New text**: new philosophy, "Where Sagittarius sits": "Each release of Sagittarius has a semantic version, and the prompt names its own version. Then a report from use can say what it ran." Ty: "the system prompt should have its own installation sequence. Similar to how I use it with my .zsh aliases. An agent should probably help handle the setup of this."
- **Build**:
  - `MAIN/hubkit/INSTRUCTIONS.md:120`: `The kit does not start sessions.` and `:125`: `cd "$HUB" && HUB_SESSION=<name> claude --name "hub-<name>"`. No prompt is appended. The check of step 5 (`:138`) reads only `HUB_SESSION` and the inbox.
  - `MAIN/README.md:78`: `claude --name "sagittarius-$ROLE" --append-system-prompt "$(cat "$p/SAGITTARIUS.md" "$p/PANES.md")`. This launcher has the prompt, and no `HUB_SESSION`, and no hub directory.
  - So there are two launchers with two session names (`hub-<name>`, `sagittarius-$ROLE`), and neither makes a complete MindHole pane.
  - The version: `MAIN/install.py:29` links `~/.claude/sagittarius` to `prompt/` of the checkout. A session gets the working tree of that checkout at the moment it starts. Nothing records it.
  - `MAIN/hubkit/hub/HUB-CORE.md:190`: `runs as a named session that the human sets up outside the hub (for example in dotfiles)`. This is a design choice of the kit (0.4.0, `MAIN/hubkit/UPGRADING.md:139`).
- **Kind**: gap.
- **Smallest change**: in `hubkit/INSTRUCTIONS.md` "The formal edition", give one launcher line that sets `HUB_SESSION` and appends the prompt, `PANES.md` and the role file, with a check that the pane can say which prompt version it has. Use one session name in the README and in the kit.
- **Size**: M (S for the words; the check needs the prompt to name a version first).
- **What holds the old behavior**: `check_hub_fixes.py t46c3` reads step 5 and "The formal edition" for `HUB_SESSION` (`MAIN/docs/check_hub_fixes.py:240` to `:249`). `check_informal_hub.py t32c2` bans formal words outside "The formal edition" (per its docstring, `MAIN/docs/check_informal_hub.py:10` to `:13`), so the prompt line must go in that section. `check_informal_hub.py t32c7` reads the resume command of step 5 (`:25`).

### M-c5. `PRINCIPLES.md` and the philosophy. Verdict: CONFIRMED

#### M6. The kit installs a digest of the philosophy in every hub

- **New text**: new philosophy, line 14: "It is installed nowhere." Ty: "the philosophy should not be installed anywhere. It should just be reflected into the system prompt. and guide the sagittarius and mindhole project trajectories over time."
- **Build**:
  - `MAIN/hubkit/hub/PRINCIPLES.md:3`: `The principles of Sagittarius in plain words; an upgrade replaces this file`.
  - `MAIN/hubkit/kit.json:5` lists it as an engine file. `MAIN/hubkit/hub/CLAUDE.md:8` imports it (`@PRINCIPLES.md`).
  - `MAIN/hubkit/README.md:17`: `**The principles come with it.** `PRINCIPLES.md` states the Sagittarius philosophy in plain words`.
  - `MAIN/hubkit/INSTRUCTIONS.md:35`: `**The principles.** `PRINCIPLES.md` states the Sagittarius philosophy in plain words, and `CLAUDE.md` imports it.`
- **Kind**: contradiction (with the decision as it is worded).
- **Smallest change**: a decision of Ty comes first: does a file that restates the philosophy in a hub count as "installed"? If yes, remove `PRINCIPLES.md` from `kit.json`, from both `CLAUDE.md` templates, from the README and the instructions, and write an UPGRADING section that removes it from a hub. See "Suggestions" 1 for the options.
- **Size**: L.
- **What holds the old behavior**: `check_informal_release.py c3` (the file exists, is imported, has the core phrases, each principle names a source; `MAIN/docs/check_informal_release.py:224` to `:248`); it also wants the UPGRADING section of the current version to name `@PRINCIPLES.md` (`:248`). `check_informal_hub.py t32c2` (`CLAUDE.md` imports it, `:271`), `t32c5`, `t36c5`, `t36c6`, `t41c1`, `t41c4`. `MAIN/hubkit/UPGRADING.md:55`, `:118`, `:131`. `check_consistency.py c9` counts the three ideas of `hubkit/README.md`, and this is one of them. `MAIN/hubkit/INSTRUCTIONS.md:144` (the `git add` line).

#### M7. `PRINCIPLES.md`: 7 of 9 source names are gone, 2 statements are now wrong, 5 principles are missing

- **New text**: new philosophy, "What follows", principles 1 to 14.
- **Build**: `MAIN/hubkit/hub/PRINCIPLES.md`, section by section.

| `PRINCIPLES.md` | Source it names | In the new philosophy | Statement |
|---|---|---|---|
| `:6` Clear, accurate, honest, fast | "2. Alignment is the goal. A proof is one tool for it" | Gone. The text is in principle 1. | Holds. |
| `:12` The human owns the intent | "1. The human owns the intent. ..." | Same name. | **Wrong now**: `:15` `ask, give a concrete example, and wait for the answer`. New principle 2: "To state a hypothesis is not to ask a question. The agent states it and goes on. It stops to ask only when a wrong default is costly or hard to undo." |
| `:18` Orbit the intent | "4. Orbit the intent. Do not translate it" | Gone. Now "The orbit" and principle 5. | Holds. Missing: the three steps, and "Say what you expect before you look." |
| `:24` Hold the hypothesis weak | "5. The hypothesis is the closest formal statement of intent" | Gone. Now principle 2. | **Wrong now**: `:26` `Before you build, say what you believe the problem is.` New principle 2: "The hypothesis says what the human wants." What is wrong with the system is "a finding about the system. It is not part of the law." Missing: every ticket has one; write wide; a guess; two falsifiers. |
| `:30` Start light, shift up, lean back | "7. Rigor follows signals of misunderstanding, ..." | Gone. Now principle 10. | Partly: it names three of the six signals, and says `Then add one step at a time`. New: one response, with three levels (words, records, a formal statement). |
| `:37` No party grades its own work | "3. No party grades its own work" | Renumbered: now 4. | Holds. Missing: "The rule holds for noticing too", and "A reviewer reads the request and the system, not the report of the builder." |
| `:43` Disclose guesses | "9. Words match evidence" | Same name. | Holds. |
| `:49` A disagreement is good news | "6. A divergence is good news. ..." | Renumbered: now 8. | Holds. Missing: "A divergence does not accuse anyone. The intent can have moved". |
| `:55` Skip, never hide | "8. Speed comes from skipping work, ..." | Renumbered: now 12. | Holds. |

  Not in the file at all: principle 3 (what a lap learns, the next lap keeps; a new claim supersedes), 6 (the human reads what was stated), 11 (one lens at a time), 13, 14.

  `MAIN/hubkit/hub/PRINCIPLES.md:4`: `Each names its source, a section of docs/PHILOSOPHY.md`. Run in `NEW`: `check_informal_release.py c3` reports 7 source names that are not headings of the new philosophy.
- **Kind**: stale words.
- **Smallest change**: if the file stays (see M6): rewrite the two wrong statements, fix the seven `Source:` lines, and decide which missing principles a hub needs. Then update the pinned phrases in the checks.
- **Size**: M.
- **What holds the old behavior**: `check_informal_hub.py` `P_WANT` pins three old headings word for word (`MAIN/docs/check_informal_hub.py:388` to `:390`); `t36c6` and `t41c1` find the hypothesis principle by the old heading text (`:676`, `:705`); `t41c1` wants `which result you expect` (`:709`). `check_informal_release.py c3` `CORE_PHRASES` (`:219` to `:220`).

#### M8. The `hypothesis` rows of "What lives where" say "what discovery believes the problem is"

- **New text**: "The hypothesis": "Every ticket has one. Discovery exists to form it when the request is not clear. In build, you state it yourself, from the request." New philosophy, principle 10: "Where a workspace keeps a record for every ticket, the hypothesis goes into that record."
- **Build**:
  - `MAIN/hubkit/hub/HUB-CORE.md:51`: `What discovery believes the problem is, its premises, the result it expects, and the result that would show it false.`
  - `MAIN/hubkit/hub/HUB-CORE.md:167` and `MAIN/hubkit/editions/informal/HUB-CORE.md` (the same generated row): `what the problem is believed to be, its premises beside it, the result expected, and the result that would show it false.` Source: `MAIN/hubkit/tools/storemap.py:65`.
- **Kind**: stale words.
- **Smallest change**: change the two descriptions to "what the human wants for this ticket" with its premises and its two falsifiers, and drop "discovery" as the only author. The formal row comes from the hub design KB through `hubkit/tools/store-facts.json`, so the design KB changes first; then `storemap.py --write`.
- **Size**: M.
- **What holds the old behavior**: `check_hub_guidance.py c1` (the table equals `store-facts.json`, and that equals the design KB when it is on the machine; `MAIN/docs/check_hub_guidance.py:141`, `:174`). `check_informal_hub.py t41c1`, `t41c5`, `t44c2` (the rows name the expected result, the falsifier and the premises; `:702`, `:833`, `:927`). The hub design KB was ratified on 2026-11-10 (project memory); I did not read it.

### M-c6. The name. Verdict: CONFIRMED (the kit never says "MindHole")

#### M9. The name "MindHole" is nowhere in the tree

- **New text**: new philosophy, "Where Sagittarius sits": "**MindHole:** the hub. Sagittarius provides a hub as a kind of pinned workspace." The new prompt keeps the common noun: "A workspace, such as a hub".
- **Build**: `git -C MAIN grep -c -i` over tracked files, without `evals/` and `tmp/`. A count is the number of lines that match.

| Name | Files | Lines | Most lines in |
|---|---|---|---|
| "MindHole" (any case) | 0 | 0 | |
| "Sagittarius hub" | 0 | 0 | |
| "hub kit" (the display name) | 11 | 32 | `docs/check_informal_release.py` 7, `CHANGELOG.md` 7, `README.md` 4, `docs/check_hub_fixes.py` 3, `hubkit/README.md` 2, `hubkit/INSTRUCTIONS.md` 2, `hubkit/UPGRADING.md` 2, `hubkit/docs/index.html` 2 |
| "hubflow-starter" (history only) | 6 | 8 | `docs/check_informal_release.py` 3 |
| "hubkit" (the directory and `hubkit.py`) | 32 | 165 | `docs/check_informal_release.py` 20, `docs/check_hub_fixes.py` 17, `docs/check_informal_hub.py` 14, `hubkit/UPGRADING.md` 13, `kb/tests/test_release.sh` 11 |
| "hubflow" (the tool, env names, the test) | 39 | 464 | `hubflow-test.py` 67, `docs/check_informal_hub.py` 63, `hubkit/UPGRADING.md` 34, `hubflow.py` 33, `kb/bin/orbit-kb` 31, `hubkit/proofs/ledger_guard/` 60 in three files |
| "HUB-CORE" | 24 | 143 | `docs/check_informal_hub.py` 39 |
| "HUB_SESSION" | 20 | 96 | `docs/check_hub_fixes.py` 17, `hubkit/INSTRUCTIONS.md` 13, `kb/bin/orbit-kb` 7, `kb/CONTRACT.md` 3 |
| ".hub-template.json" | 13 | 33 | |
| skills "hub-flow", "hub-rotate" | 14, 14 | 38, 44 | |

  The kit names itself "The hub kit" (`MAIN/hubkit/README.md:1`) and "the informal release" (`:4`).
- **Kind**: stale words.
- **Smallest change**: name the product only. Say "MindHole" in the titles and first sentences of `hubkit/README.md`, `hubkit/INSTRUCTIONS.md`, `hubkit/docs/index.html`, the root `README.md` ("Hub kit") and the root `CLAUDE.md` row, and keep "hub" as the common noun and every identifier (`hubflow`, `HUB_SESSION`, `HUB-CORE.md`, `hubkit/`). A rename of the identifiers touches installed hubs, `orbit-kb`, the contract and the Lean file.
- **Size**: S for the display name. L for the identifiers.
- **What holds the old behavior**: `check_informal_release.py c5`: `hubkit/README.md is titled the hub kit` (`MAIN/docs/check_informal_release.py:312`). `check_hub_fixes.py t50c4` wants "hub kit" in the briefing (`MAIN/docs/check_hub_fixes.py:310`). `kb/tests/test_release.sh:77` greps the changelog for "hub kit" (read, not run).

### M-c7. Independence both ways

**(a) The MindHole without `orbit-kb`. Verdict: PARTLY.** The mechanics still hold against the
new texts: `MAIN/hubkit/README.md:5` to `:6` (`You do not need Prolog, Lean, or any other part of
Sagittarius to use it.`), `MAIN/hubkit/hub/HUB-CORE.md:130` to `:144`, and the fail-safe
(`:139` to `:141`: with no `orbit-kb`, `an item with a `kb` ref is treated as blocking`). The new
philosophy says the same: "The two work best together, and neither depends on the other." What
is stale is the method text that the informal edition carries: `PRINCIPLES.md` (M6, M7), the
hypothesis row (M8), and the divergence row (M20).

**(b) Sagittarius without a hub. Verdict: NOT CONFIRMED.** No file of the hub kit says that the
prompt holds hub procedure (the search of M-c1 finds no mention of the prompt in `hubkit/`).
`PANES.md` holds its procedure itself (`MAIN/prompt/PANES.md:29`). The one citation of the
prompt in a pane prompt is M1. A note for the `orbit-kb` audit, outside my area: the tool knows
the hub (`MAIN/kb/bin/orbit-kb:1276` prints `hubflow where SLUG`; 31 lines of that file name
hubflow).

**(c) A hub pins its own versions. Verdict: CONFIRMED as a gap.**

#### M10. A hub pins no version of `orbit-kb`, of the prompt, or of the pane prompts. Roles and routing live outside the hub

- **New text**: Ty: "Each mindhole can run its own version with its own orbit-kb and bespoke modifications for each given workspace." "The tool": "Follow the help of the version that is installed here: a workspace can pin its own." and "A workspace, such as a hub, names its own tools, roles, and routing in its own instructions."
- **Build**:
  - `.hub-template.json` records five keys: `MAIN/hubkit/tools/hubkit.py:158` to `:160`: `{"template_version": k["version"], "edition": ed, "files": {...}, "owned": ..., "pending": []}`. No key names `orbit-kb` or the prompt.
  - `hubflow.py` takes `orbit-kb` from the PATH, or from an environment variable of the session: `MAIN/hubkit/hub/.claude/scripts/hubflow.py:1673`: `shlex.split(os.environ.get("HUBFLOW_ORBIT_KB") or "orbit-kb")`. The hub does not record it.
  - `orbit-kb` cannot say its version: `MAIN/kb/bin/orbit-kb --version` prints `Unknown command --version.` (run on 2026-11-11).
  - The roles and the routing are not kit files. `MAIN/hubkit/kit.json` lists no pane prompt. `MAIN/hubkit/hub/HUB-CORE.md:188`: `The panes (review, discovery, build) of `PANES.md` (installed as `~/.claude/sagittarius/PANES.md``. That path is one link for the whole machine (`MAIN/install.py:29`), so every hub on a machine gets the same roles and routing.
  - What a hub does own: `CLAUDE.md` (`MAIN/hubkit/hub/CLAUDE.md:24` "Sessions", a placeholder of one line for each session) and a `LOCAL.md` beside each skill (`MAIN/hubkit/hub/HUB-CORE.md:228`).
- **Kind**: gap.
- **Smallest change**: record, in the hub, which `orbit-kb` command and which prompt and pane files the hub runs (a section of the hub's `CLAUDE.md`, or keys in `.hub-template.json` that `hubkit.py status` prints). Give `orbit-kb` a version to record. Decide if the pane prompts become kit files that a hub can change.
- **Size**: L (the kit manifest, `orbit-kb`, the install, and the launcher of M5).
- **What holds the old behavior**: `hubkit-test.py` reads the manifest (`MAIN/hubkit/tools/hubkit-test.py:96`, `:142`). `check_hub_guidance.py c12` wants `prompt/PANES.md` and `outside the hub` in "Panes" (`MAIN/docs/check_hub_guidance.py:334`). `check_informal_release.py c4` reads the 0.4.0 section about `sessions/` leaving the kit (`:272`).

### M-c8. The hooks. Verdict: NOT CONFIRMED (the build agrees)

The hub kit does not install, name, or need `s1/` or any hook. Searches of all of
`MAIN/hubkit/` for `s1/`, "System 1", "UserPromptSubmit", "hook", "settings.json": no match. The
pane prompts: no match. This agrees with Ty: "I think the hooks should be coupled with
sagittarius and not the mindhole". Not checked: whether a message from a peer session passes
through a `UserPromptSubmit` hook. If it does not, a handoff gets no System 1 line.

### M-c9. The roles and the vote in a hub. Verdict: PARTLY (the flow keeps them; one small gap)

- Who seals: the discovery pane. `MAIN/prompt/panes/discovery.md:25`: `Seal your vote. Give the human the discovery report with no verdict.`
- Where the human's vote is recorded: in the spec KB, typed by the discovery pane as the human's. `MAIN/prompt/panes/discovery.md:13` to `:14` points to GATE; `MAIN/kb/share/orbit-kb/help/discovery.txt:203` to `:204`: `orbit-kb attest vote r1 'vote(1, hold)' --by human`. On NO-GO or HOLD: `MAIN/prompt/panes/discovery.md:26`. The ledger has no vote.
- The artifacts: `MAIN/prompt/PANES.md:21` to `:22`: `Inside discovery, the human vote and the formal artifacts judge what research found.` Nothing in the pane prompts or the kit limits "artifacts" to formal models, so Ty's "Any test of any kind counts as an artifact." needs no change here.
- The review pane reads the request and the system: `MAIN/prompt/panes/review.md:5` to `:6`: `You judge against the request and against what the system does, not against the report of the pane that did the work.` and `:44`: `Read only the request, the KB, and the diff.`
- Unclear, recorded and not judged: the new prompt has three voters. A hub has two more agents (review, build). The pane prompts give them no vote, and say so nowhere. Review's intake verdict "informs the hypothesis" (`MAIN/prompt/panes/discovery.md:20`).
- A note for the `orbit-kb` audit: in a hub the spec KB is committed and the human reads it (`MAIN/hubkit/hub/HUB-CORE.md:89`), and the help says `The seal guards against a mistake, not a look. query and kb.pl show your vote.` (`MAIN/kb/share/orbit-kb/help/discovery.txt:213`). The new prompt says: "Until the human votes, do not show it".

#### M11. The vote has no row in "What lives where"

- **New text**: "The vote": "Discovery ends with GO, NO-GO, or HOLD." and "A result with no winner is HOLD: say what it waits for."
- **Build**: the 29 fact kinds of `MAIN/hubkit/hub/HUB-CORE.md:38` to `:66` have no kind for the vote or its outcome (`MAIN/hubkit/tools/store-facts.json` has no name with "vote" or "gate"). The informal table (`:154` to `:182`) has none either, so an informal hub has no stated home for a GO.
- **Kind**: gap.
- **Smallest change**: add a fact kind for the vote (owner `spec`; informal home: a note on the ticket's thread) in the hub design KB, then regenerate both tables.
- **Size**: S (words in the design KB and two generated tables; the count "29" changes).
- **What holds the old behavior**: `check_hub_guidance.py c1` (`:168`: the table has exactly the fact kinds of the design). `MAIN/hubkit/hub/HUB-CORE.md:34`: `The 29 fact kinds:`.

### M-c10. The six signals in a hub. Verdict: PARTLY

What agrees: each pane handoff that the pane prompts describe carries a KB. Intake to discovery:
`MAIN/prompt/panes/review.md:24` to `:27` (`Start a KB for the report` ... `That message is a
handoff.`). Discovery to build: `MAIN/prompt/panes/discovery.md:13` to `:16`. Build to review:
`MAIN/prompt/panes/build.md:10` to `:11` (`the KB path and the diff`). The receiver reads the
record: `MAIN/prompt/PANES.md:24`: `the receiver runs `orbit-kb show open` first`.
"A build by someone else": the review pane runs the checks itself: `MAIN/prompt/panes/review.md:46`:
`Run every check again yourself with `orbit-kb run``.

One point for the `orbit-kb` audit: the build pane does not run discovery's reproduction again.
`MAIN/prompt/panes/build.md:9`: `skip SURVEY`, and `MAIN/kb/share/orbit-kb/help/discovery.txt:235`:
`The build orbit reuses each red test_result as its baseline.` The new prompt says of a peer's
work: "run its checks yourself". Not checked: whether `orbit-kb` runs the check again in build.

#### M12. A handoff can cross panes with prose only

- **New text**: "Signals": "**A handoff:** unfinished work moves to or from another session." "One response": "With no KB yet, start one, and record what fired. In a KB, record the signal there."
- **Build**:
  - The pane prompt asks for a KB: `MAIN/prompt/PANES.md:24`: `Hand off through the KB, not through memory.`
  - The tool does not: `handoff` takes `[--ref ...]` and `[--note N]` as options (`MAIN/hubkit/hub/.claude/scripts/hubflow.py:19`, `:1091` to `:1110`). A row with a title and a note is accepted.
  - The skill shows such a row as its example: `MAIN/hubkit/hub/.claude/skills/hub-flow/SKILL.md:71`: `$HF handoff --to build --title "…" --ref issue:123 --note "where to start"`. Twenty lines later it says: `**A handoff** is a `handoff` row plus the KB.` (`:91`).
  - In the informal edition a handoff is a row and a message by design (`MAIN/hubkit/editions/informal/.claude/skills/hub-flow/SKILL.md:89`).
  - The return from review to build is not named a handoff: `MAIN/prompt/panes/review.md:58`: `Report your findings to the pane that asked`. No line tells review to release the KB or to write a row.
  - No pane prompt tells the receiver to record the handoff as a signal in the KB.
- **Kind**: gap.
- **Smallest change**: in the formal `hub-flow/SKILL.md`, give the example a `--ref kb:SLUG`. In `prompt/panes/review.md` "Gives", name the return to build a handoff (release, row, message). Say in `PANES.md` that the receiver records the handoff in the KB. A warning from `hubflow.py` for a formal handoff with no `kb` ref is the tool half.
- **Size**: M (S for the words; the warning is a feature with tests and a Lean command table, `MAIN/hubkit/proofs/ledger_guard/check_commands.py`).
- **What holds the old behavior**: `check_hub_guidance.py c5` wants exactly one `hubflow handoff` recipe in `PANES.md` (`:249`). `check_panes.py` c3 limits each pane prompt to under 60 lines; `review.md` has 59 (`MAIN/docs/check_panes.py:23`, `:93`). So a new line in `review.md` needs a line removed, or the limit raised.

#### M13. A hub does not say which peer messages are handoffs

- **New text**: "Signals": "A message from a peer session and a compaction summary are handoffs."
- **Build**: a hub sends peer messages that pass no work. `MAIN/hubkit/hub/.claude/skills/hub-rotate/SKILL.md:72` to `:73`: `ask busy ones by `SendMessage` to reach a stopping point`. `MAIN/prompt/panes/review.md:58`: `tell the human in one line`. The hub's own definition is narrower than the prompt's: `MAIN/prompt/PANES.md:29` to `:31` (a handoff is one `hubflow handoff` row and a message that names the id). Read word for word, the new prompt makes each peer message a signal, and a signal gets a KB.
- **Kind**: gap.
- **Smallest change**: one sentence in `PANES.md`: in a hub, a handoff is a `hubflow handoff` row; a peer message with no row passes no work and is not a signal.
- **Size**: S.
- **What holds the old behavior**: nothing pins it. `check_panes.py` c3 (the 60-line limit; `PANES.md` has 38).

### M-c11. The delivery block and the honesty rules in the panes. Verdict: NOT CONFIRMED

No pane prompt and no hub skill quotes a delivery field or a numbered honesty rule. A search of
`MAIN/prompt/PANES.md`, `MAIN/prompt/panes/` and `MAIN/hubkit/` for "Triggers" finds nothing.
`MAIN/prompt/panes/build.md:20` says only: `You deliver to the human, with review's result in the
delivery.` The one trace of the old word is M14.

#### M14. `PANES.md` says "A handoff is a trigger"

- **New text**: "Delivery": "Signals:     <questions, divergence, someone else built, burns, handoff, effort ...>". The heading "Signals".
- **Build**: `MAIN/prompt/PANES.md:24`: `A handoff is a trigger: the receiver runs`.
- **Kind**: stale words.
- **Smallest change**: write "signal" in `prompt/PANES.md:24`.
- **Size**: S.
- **What holds the old behavior**: nothing.

### M-c12. The version. Verdict: CONFIRMED (the list)

Where the kit version 0.5.1 is stated in tracked files (`git -C MAIN grep "0\.5\.1"`, without
`evals/` and `tmp/`): `hubkit/kit.json:2`, `hubkit/UPGRADING.md:46` (the section heading) and
`:52`, `:55`, `:78`, `CHANGELOG.md:6`, and a comment at `docs/check_informal_hub.py:628`. An
installed hub holds it as `template_version` in `.hub-template.json`
(`MAIN/hubkit/tools/hubkit.py:158`). `hubkit/README.md` and the briefing page name no version.

#### M15. The kit version is tied to the db schema and to `PRINCIPLES.md`, and has no link to a Sagittarius version

- **New text**: new philosophy, "Where Sagittarius sits": "Each release of Sagittarius has a semantic version, and the prompt names its own version." Ty: "we need a semver system for sagittarius now, so I can refer to prior versions better." The new prompt, last line: "It has no version number yet."
- **Build**: what must move together when `kit.json` is bumped today:
  - The newest `### X.Y.Z` section of `UPGRADING.md` is the kit version: `hubkit-test.py` `t48-c3-newest-upgrading-section-is-the-kit-version` (`MAIN/hubkit/tools/hubkit-test.py:184`), `check_hub_guidance.py c11` (`:324`), `check_informal_release.py c6` (`:324`).
  - That section states the script's schema and the migrate command, also when the schema does not change: `t48-c3-newest-section-states-the-script-schema` and `...-says-migrate` (`MAIN/hubkit/tools/hubkit-test.py:185` to `:187`). `MAIN/hubkit/UPGRADING.md:51`: `The kit version moves with the db schema (T48 c3)`. The schema is `SCHEMA_VERSION = 5` (`MAIN/hubkit/hub/.claude/scripts/hubflow.py:203`).
  - That section names `@PRINCIPLES.md` and `CLAUDE.md`: `check_informal_release.py c3` (`:248`). This ties each release to M6.
  - The first 3000 characters from that section name `HUB-CORE.md`, `specs/<slug>` and `spec-triage`: `check_hub_guidance.py c11` (`:326` to `:327`).
  - `CHANGELOG.md`: "hub kit is version X" equals the kit version: `check_informal_release.py c6` (`:330` to `:331`).
  - `kb/tests/test_release.sh:56` to `:73` compares `kit.json` with `main:hubkit/kit.json` (read, not run).
  - Any change to an engine file (M3, M7, M8, M12) reaches a hub only through an upgrade, so each needs a release section with its intent, files and check (`MAIN/hubkit/UPGRADING.md:43`).
  - Nothing relates the kit version to a version of the prompt or of `orbit-kb`. The pane prompts have no version and are not kit files (M10).
- **Kind**: gap.
- **Smallest change**: decide how the kit version and the Sagittarius version relate (one number, or two numbers with a stated pair), and state it in `hubkit/README.md` and `UPGRADING.md`. Then the next kit release (0.5.2 or 0.6.0) carries the word changes of this report in one section.
- **Size**: M.
- **What holds the old behavior**: the tests and checks listed above.

---

## Differences that the candidates missed

### M16. A hub has no light path: the build pane has no rule for the hypothesis of a change request

- **New text**: "The light path": "Most work needs only this." "State the hypothesis of the ticket: one sentence ... with its premises beside it and one concrete example". Ty: "A ticket starts in words; a KB starts on a signal. A typo never needs a KB." New philosophy, principle 10: "Where a workspace keeps a record for every ticket, the hypothesis goes into that record."
- **Build**:
  - The build pane takes a change request from the human with no step for a hypothesis: `MAIN/prompt/panes/build.md:7` to `:8`: `Or from the human, a change request.` and `:3`: `You do not decide what the problem is`.
  - Every build goes to review with a KB, with no exception for a small change: `MAIN/prompt/panes/build.md:10` to `:12`: `to **review**, the KB path and the diff ... when `done` holds` and `Do not tell the human that the work is done until review has reported.`
  - By the new prompt a handoff is a signal, and a signal starts a KB. So in a hub every change, a typo too, gets a KB and a second agent. The philosophy allows a workspace to keep a record for every ticket, but the pane prompts do not say that this is the choice, and do not say who writes the hypothesis of a ticket that did not pass discovery.
- **Kind**: gap.
- **Smallest change**: in `prompt/panes/build.md`: for a change request from the human, build states the hypothesis (wide, with premises) and records it in the ticket's KB. Add one sentence, in `PANES.md` or `HUB-CORE.md` "Panes", that says if a hub has a light path (a change that build may deliver with no KB and no review) or not. That is a decision of Ty.
- **Size**: M.
- **What holds the old behavior**: `check_panes.py` c1 (each pane names its phases, "Receives:", "Gives:", and the words "make" and "judge"; `:64` to `:80`). `check_consistency.py c2` (the make and judge block of `PANES.md`).

### M17. Intake knows two kinds of report. The new prompt has three cases for "it is wrong"

- **New text**: "When the human says that it is wrong": first "Kept: <what the human still wants>. Changed: <what they want now>." Then three cases: someone misread (a divergence on its claim); the intent moved (a new claim supersedes; "Record no divergence against the old claim"); the wish adds to the result ("It is a new ticket"). New philosophy, principle 3: "What the human liked stays: its claims stand, and their checks stay."
- **Build**: `MAIN/prompt/panes/review.md:17` to `:20`: `Take each new report from the human: a defect, a complaint, or a request.` and `Decide which kind it is: a **regression** ... a **gap**`. Then always: `Start a KB for the report` (`:24`) and `send the KB path to **discovery**` (`:26`). No line asks first if the complaint is about a ticket that has a spec KB already. So a correction of delivered work that reaches the review pane gets a new KB and a discovery orbit, and the claims and checks of the first ticket are not in it.
- **Kind**: gap.
- **Smallest change**: in `prompt/panes/review.md` "Intake", one first step: find the ticket that the complaint is about (`hubflow` refs, `specs/<slug>/`). If it exists, hand the complaint to the pane that holds that ticket, to be narrowed there. Only a report with no ticket goes on to "regression or gap".
- **Size**: M.
- **What holds the old behavior**: `check_panes.py` `REVIEW_RULES` pins 42 phrases of `review.md` (`MAIN/docs/check_panes.py:26` to `:47`), and c3 holds the file under 60 lines (it has 59).

### M18. The briefing page gives the build session the review, and lists a week slot that the kit removed

- **New text**: new philosophy, principle 4: "Each result goes through a party that did not make it." and "A reviewer reads the request and the system, not the report of the builder."
- **Build**: `MAIN/hubkit/docs/index.html:95`: `build` ... `Builds, tests and reviews changes.` The page lists four sessions (`:94` to `:97`) and no review session. The kit's own seed has one (`MAIN/hubkit/hub/flow/seed.json:5`), and `MAIN/hubkit/INSTRUCTIONS.md:33` says: `The `review` session verifies what another session made`. Also `MAIN/hubkit/docs/index.html:58` lists `analyses/`; `MAIN/hubkit/hub/HUB-CORE.md:95` says: `There is no `analyses/` slot`.
- **Kind**: contradiction (the page against the principle, and against the kit).
- **Smallest change**: in `hubkit/docs/index.html`, add the review session, change the build line to "Builds changes", and drop the `analyses/` row.
- **Size**: S.
- **What holds the old behavior**: `check_hub_fixes.py t50c4` only wants the page to exist and to say "hub kit" (`:305` to `:315`). Step 1 of the instructions sends the human to this page first (`MAIN/hubkit/INSTRUCTIONS.md:67`).

### M19. The kit calls Lean a model

- **New text**: new philosophy, principle 11: "Lean is not a modeling language: a Lean file holds definitions, and theorems about them." "Honesty" 3: "about the Lean definitions, not the code".
- **Build**: `MAIN/hubkit/hub/HUB-CORE.md:52`: `Formal models (Lean, SMT, TLA+) and the proofs that a claim rests on.` `MAIN/hubkit/proofs/ledger_guard/LedgerGuard.lean:9`: `The model is one item.` (10 lines of that file say "model").
- **Kind**: stale words.
- **Smallest change**: reword the `models` row in the hub design KB ("solver and model-checker models, and Lean definitions and theorems"), regenerate; reword the comments of `LedgerGuard.lean`.
- **Size**: S.
- **What holds the old behavior**: `check_hub_guidance.py c1` (the row equals the design KB). The fact kind is named `models`; a rename of the kind is larger and not needed.

### M20. The informal edition keeps no record of a divergence

- **New text**: new philosophy, principle 8: "It shows that clarity increases. Record it." Principle 3: "the state of the work lives in a record that a person or an agent can query." "One response": the second level is "records".
- **Build**: `MAIN/hubkit/editions/informal/HUB-CORE.md` and `MAIN/hubkit/hub/HUB-CORE.md:164` (the same generated row): `` `divergences` | `not kept` | No record. The agent says each guess, error and disagreement in its report to the human``. Source: `MAIN/hubkit/tools/storemap.py:62`. The same hub loads `MAIN/hubkit/hub/PRINCIPLES.md:51`: `Record it and act on it.` So the two always-loaded files of an informal hub disagree today.
- **Kind**: contradiction.
- **Smallest change**: give `divergences` an informal home in `storemap.py` (a note on the ticket's thread, `hubflow.py note ID "divergence: ..."`, as the informal verdict has), and regenerate both tables.
- **Size**: M.
- **What holds the old behavior**: `check_informal_release.py c2` accepts `not kept` as a home (`:210`). `check_informal_hub.py t32c3` reads the generated table; `storemap.py --check`.

### M21. Closing a spec KB has no step to give a lasting outcome a home

- **New text**: "Delivery": "When an outcome must outlive the ticket, give it a home that outlives the ticket: a test in the project's suite, and a rule in the project's record when the project has one. You propose the rule, and a human ratifies it." New philosophy, principle 3: "When a ticket closes, the agent proposes each such outcome, and a human ratifies it."
- **Build**: the kit ends a spec KB at a rotation: `MAIN/hubkit/hub/.claude/skills/hub-rotate/SKILL.md:91` to `:93` (`each spec KB at `specs/<slug>/` whose ticket is closed needs one decision (archive, capsule, keep or escalate)` ... `archive is `git rm -r specs/<slug>``). The durability check of that skill is about the week directories (`:56` to `:57`: `promote it out of the week dirs`). No step before an archive asks which outcomes of the ticket go to the project KB. A hub does have the home: the project KB with proposed and ratified facts (`MAIN/kb/share/orbit-kb/help/project.txt:17`, `:59`).
- **Kind**: gap.
- **Smallest change**: in the formal `hub-rotate/SKILL.md` step 4 and `hub-flow/SKILL.md` "The spec KB of a closed ticket": before `archive`, propose each lasting outcome to the project KB, and list the proposals for the human in the report.
- **Size**: M (words in two engine files; S if no tool check is wanted).
- **What holds the old behavior**: `check_hub_guidance.py c4` pins phrases of both files (`:229` to `:236`). `check_hub_fixes.py t31c3` reads the durable step for "project kb" (`:105` to `:110`).

---

## Where the build already agrees

- **No hook in the kit.** Nothing in `hubkit/` or the pane prompts names `s1/` or a hook (M-c8). No file in `hubkit/` names `settings.json`.
- **The reviewer does not grade from the report.** `MAIN/prompt/panes/review.md:44` to `:47`: request, KB and diff only; every check run again; a different result is a divergence on the claim.
- **A handoff reads the record.** `MAIN/prompt/PANES.md:24`; `MAIN/hubkit/hub/.claude/skills/hub-flow/SKILL.md:64`: `the db is the memory, not the conversation`. `MAIN/hubkit/hub/HUB-CORE.md:236`: `A memory is never the record of a finding.`
- **One writer, and a release before a handoff.** `MAIN/prompt/PANES.md:26`.
- **The sealed vote and the human's vote.** `MAIN/prompt/panes/discovery.md:25`, `:26`.
- **The human's words.** `MAIN/hubkit/hub/.claude/skills/hub-flow/SKILL.md:35`: `` `--by human` only records a human's own words and needs `--note "<quote>"` ``.
- **Trust, and the known limit.** `MAIN/hubkit/INSTRUCTIONS.md:170` to `:171`: `the rule stops mistakes, not cheating`.
- **Skip with a due time, by the human only.** `park --until`, `skip-waived`, and the waiver that holds an item for the human (`MAIN/hubkit/hub/.claude/skills/hub-flow/SKILL.md:121` to `:132`). The guard has Lean theorems (`MAIN/hubkit/proofs/ledger_guard/LedgerGuard.lean:443`).
- **No quiet lapse, and a missing answer is not a "no".** `MAIN/hubkit/hub/.claude/skills/hub-flow/SKILL.md:98` (`No work item lapses by itself.`), `:112` to `:114` (a failed query counts as blocking), `:179` (`Exit 2 is never "no".`).
- **Checks that can fail.** Both kit suites run mutants (`MAIN/hubkit/README.md:96` to `:97`). `MAIN/hubkit/hub/HEURISTICS.md:14`: `A test that has never failed shows nothing.`
- **Nothing is sent for the human.** `MAIN/hubkit/hub/HUB-CORE.md:243`.
- **The MindHole without `orbit-kb`** works by its own rules (M-c7 a), and the new philosophy calls the template "an informal release", as `MAIN/hubkit/README.md:4` does.
- **`PANES.md` holds the hub handoff procedure itself**, so the new prompt can drop its hub lines (M-c3). `check_panes.py` passes unchanged.
- **The premises ride beside the hypothesis** in the kit's rows and in `PRINCIPLES.md:27`.
- **Intake routing** ("a report goes to review first") is in `PANES.md`, so the new "Scope" needs no pane sentence.

---

## Suggestions beyond alignment

These are opinions. The new texts do not strictly need them.

1. **What to do with `PRINCIPLES.md` (the opinion half of M6).** Problem: an informal hub has no Sagittarius prompt, so `PRINCIPLES.md` is the only method text that its agents read; and the file drifted from the philosophy within six days (M7). Evidence: `MAIN/hubkit/README.md:5` to `:6`, the seven dead source names. Options: (a) remove the file, and let an informal hub have hub rules only; (b) keep a short file, but derive it from the prompt, not from the philosophy, and stamp it with the prompt version, so that "reflected into the system prompt" stays the one path; (c) keep it for the informal edition only, since a formal hub gets the prompt. I lean to (b) or (c): (a) leaves an informal hub with "No one grades their own work" in the instructions (`MAIN/hubkit/INSTRUCTIONS.md:33`) and no text behind it.
2. **Make the pane prompts kit files that a hub owns.** Problem: "a workspace names its own tools, roles, and routing in its own instructions", but the roles are one global link. Evidence: M10; `MAIN/prompt/PANES.md:3` hard-codes `the tmux session `sagit`` and "three" sessions, while the kit's seed has five (`MAIN/hubkit/hub/flow/seed.json:3` to `:7`); `process` and `support` have no role prompt.
3. **An agent-led session setup, with a check.** Problem: M5. A step in which the agent writes the launcher (alias or script) for each pane and then asks each pane for its prompt version would serve Ty's "An agent should probably help handle the setup of this." It must not write `settings.json`.
4. **Put the pending vote in the ledger as an ask.** Problem: the human's part in a hub is "what is waiting on me" (`MAIN/hubkit/docs/index.html:107`), and a discovery report that waits for a vote is not in that view unless a pane adds an ask. Evidence: no pane prompt says so; the vote is not a fact kind (M11).
5. **Say where a pane "says it" to the human.** Problem: the first step of the one response is a line "where the human can contradict it". In a hub the human may be in another pane. Evidence: the pane prompts name only `tell the human in one line` for review (`MAIN/prompt/panes/review.md:58`). A one-line ask in the ledger would give the line a place.
6. **"Time in UAT": name the condition.** Problem: `MAIN/prompt/panes/review.md:36`: `Long use in UAT with no report is evidence that the behavior is sound.` Premise 4 of the new philosophy: "An agreement that could have been a difference is evidence." Silence counts only if the behavior was used in that time. One clause would say it.
7. **Show the kit's own theorems to the human.** Problem: Ty's UAT report says that no Lean statement reached the human. The kit has Lean theorems about its ledger guard, and its README does not list `proofs/` (`MAIN/hubkit/README.md:79` to `:87`); the briefing says only `a full test suite` (`MAIN/hubkit/docs/index.html:153`). Put the statement of `agent_run_keeps_guarded` beside its plain sentence in `hubkit/README.md`.
8. **Make `check_consistency.py` fail, not crash.** Problem: a missing heading raises `ValueError` and prints no verdict for that claim, and the default run stops at c1, so c2 to c9 never run. Evidence: the run in `NEW` (M4). A crash here is close to a quiet failure.
9. **Loosen `check_hub_guidance.py c11`.** Problem: it reads the first 3000 characters after the newest release heading for `specs/<slug>` and `spec-triage` (`:326` to `:327`). A new release section that pushes the 0.5.1 text down can fail it for a reason that has nothing to do with the release.
10. **Give `--gate` a meaning or drop it.** Problem: `hubflow.py handoff` takes `--gate G` (`MAIN/hubkit/hub/.claude/scripts/hubflow.py:19`), and no kit document says what a gate is (a search of the kit's Markdown files finds none). It could hold who judges the handed work, which is the make and judge split of `PANES.md`.

## Not checked

- The hub design KB under `tmp/hub-design-kb/` (the source of the formal store map): not read, by the rules of the brief.
- `hubkit/hub/.claude/scripts/hubflow.py` was searched, not read in full. `hubflow-test.py`, `hubkit-test.py` and the Lean project were not run.
- `check_informal_hub.py` claims that install a hub (t32c1 to t32c4, t32c6, t32c8, t36c1 to t36c5, t41c2 to t41c5, t44) and `check_hub_guidance.py` c1 to c4, c6 to c8, c10, c11 were not run against the new texts. From their code, only the claims in M4 read the prompt or the philosophy headings; `check_informal_hub.py t36c6` (run) also reads a sentence of the philosophy and passes.
- `kb/tests/test_release.sh` was read at the lines cited, not run.
- Whether a peer `SendMessage` passes through a `UserPromptSubmit` hook (M-c8).
- Whether `orbit-kb` lets build supersede a hypothesis after the approval (M2), and whether build runs discovery's red check again (M-c10).

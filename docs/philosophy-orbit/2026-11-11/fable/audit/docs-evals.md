# Audit D: documents, checks in `docs/`, evals

Area: README.md, CLAUDE.md, CHANGELOG.md, docs/ (checks, REFINING, PROMPT-MOVES), evals/ (not
heldout, not runs), kb/tests that read the two texts.
Main = /home/ty/Projects/mine/sagittarius. Branch = /home/ty/Projects/mine/wt/sagittarius/philosophy-fable
(commit 84c7d0c). The branch changes only `prompt/SAGITTARIUS.md`, `docs/PHILOSOPHY.md` and
`docs/philosophy-orbit/` (checked with `git diff --stat main`), so every check script is the same
file on both trees; only the two texts differ.

How I ran: each `docs/check_*.py` claim that only reads files, from a subshell, in both trees.
I did not run claims that build a scratch hub or call `orbit-kb` (they do not read the two texts;
see the table). I did not run test suites, evals, or `check_leaks.py`. Raw output of the first
batch: `/tmp/claude-1000/-home-ty-Projects-mine-sagittarius/dbe14ead-e920-413c-be2e-63d46291253c/scratchpad/audit/docs-evals-run1.txt`.

Headline: on main every claim I ran passes. On the branch 14 claim ids fail (list in the table).
In every case the failure comes from the check holding the OLD shape of the prompt or the
philosophy (a heading, a bold anchor, a line count, a topic name, a numbered principle). Four
(consistency c1 and c9, words c2 part a, hub_fixes t31c9 part a) still hold in substance and only
the anchor is stale. The rest hold something the new text deliberately drops or renames: the line
cap, headings, topic names, panes routing and hub pointers in the prompt, the "Applied in" format
and numbering of the philosophy, the rewording of rules. No failure means the new text is wrong
against a still-right check, except possibly the unspecified status of a change of plan (D16).

---------------------------------------------------------------------------------------------------

## D-c1. The checks that hold the old shape: CONFIRMED (and more than the lead listed)

Legend for the last column. WRONG = the new text deliberately says otherwise: change the check.
RIGHT = the assertion still holds as intent: change the new text or the build. ANCHOR = the
assertion still holds in substance (I tested it with a re-anchored regex), only the heading or
bold marker it searches for is gone: re-anchor the check.

| Script | Claim | What it asserts | Main | Branch | Verdict for each branch failure |
|---|---|---|---|---|---|
| check_consistency.py | c1 | prompt has 6 shift-up bullets between "## When to shift up" and "Three parties decide"; the delivery `Triggers:` line names the six words; PHILOSOPHY "Most work needs little process" paragraph has "effort" | PASS | FAIL (ValueError substring not found, `check_consistency.py:26`) | ANCHOR. New prompt "## Signals" has exactly 6 bullets (Questions, A divergence, A build by someone else, A claim that burns, A handoff, Effort); the `Signals:` line names all six words; philosophy line 431 paragraph has "effort". Only the headings "When to shift up", "Triggers:" and "Three parties decide" are gone. |
| | c2 | prompt says "no party grades its own work"; PANES.md and panes/discovery.md do not say "specify judges" | PASS | PASS | n/a. Note: the new prompt line 101 says "specify judges what research found"; the old prompt had the same sentence (main prompt line 51), so nothing is new. |
| | c3 | discovery pane GO handoff names gate, subject, ticket, approval | PASS | PASS | n/a (reads panes only) |
| | c4 | prompt "## Scope" "report" bullet lists panes, review, intake, discovery, without | PASS | FAIL ("the report bullet in Scope is missing") | WRONG. Old prompt line 24: "With panes, a report goes to review (intake) first". New prompt Scope (lines 84-93) has no pane text, and the word "pane" occurs nowhere in the new prompt or philosophy (grep). It also lists the report bullet after the change bullet, so the regex finds none. The route belongs to PANES.md (check_panes c1 holds it). |
| | c5 | hub seed roles / INSTRUCTIONS.md say roles are not the pane set | PASS | PASS | n/a |
| | c6 | PHILOSOPHY open question F paragraph ("That exit test rests on sanity") names `help discovery`; PHILOSOPHY does not cite evals/REFINING.md; docs/REFINING.md exists; core.pl has no depends/2; the paren after `docs/PHILOSOPHY.md` in the prompt names a section | PASS | FAIL (ValueError, line 26) | Mostly WRONG. The F paragraph is gone: the new philosophy has no "Open questions"; F became "One lens at a time" in the prompt (lines 298-301). The other four assertions still hold (I tested: no `evals/refining.md` in philosophy; the new prompt has 0 mentions of PHILOSOPHY, so the paren test is vacuous). |
| | c7 | README Layout rows for s1/, hubkit/, docs/; s1 row says "manual" and "approved"; s1/README has no /home/ path | PASS | PASS | n/a (README is not changed on the branch). It pins the README, see D12. |
| | c8 | hubkit docs name the project KB | PASS | PASS | n/a |
| | c9 | hubkit README ideas count; prompt "**The vote.**" ... "Seal your vote" says "more than 0.5, so the human and at least one other" | PASS | FAIL (ValueError, line 26) | ANCHOR. New prompt line 343 still says "A win needs more than 0.5, so the human and at least one other." The anchor `**The vote.**` is gone ("## The vote"). |
| check_words.py | c1 | prompt and philosophy: no "not formal text"; "examples ... first"; "after a shift up the human, the agent and the CPU all use the formal language as the shared substrate ... the human reads, reviews and understands it"; "write it to be read" | PASS | PASS | n/a. New prompt lines 78-80 keep it; philosophy too. |
| | c2 | (a) the prompt paragraph `**The hypothesis.**` ... `**The vote.**` says err toward general and soft, names hypotheses, premises and claims, "oscillation is an intentional heuristic", "just past the boundary ... formaliz", "on purpose"; (b) every "Applied in:" line of the philosophy (14, under `### N.` headings) names targets that exist and match the table APPLIED | PASS | FAIL (ValueError, `check_words.py:37`) | (a) ANCHOR: all five sentences are in the new prompt "## The hypothesis" (lines 224-226; I tested each regex on that section). (b) WRONG: the new philosophy uses `#### N.` headings and "In the prompt:" lines instead of `### N.` and "Applied in:"; the table APPLIED (`check_words.py:70-97`) is keyed to old section names ("Roles", "The phase tree", "Start light", "When to shift up"). See D6. |
| | c3 | README and philosophy: "extension of the harness" between the human-agent interface and the software factory; "inference, reasoning and knowledge-graph layer" | PASS | PASS | n/a. Philosophy line 792 and README lines 11-14 keep it. |
| check_prompt_small.py | c1 | prompt at most 230 lines; required phrases: purpose, "## Roles", "## The phase tree", "## When to shift up", "## Honesty rules", `orbit-kb help core/build/discovery/codes/answers`; forbids depends/2, declare-attest | PASS (221 lines) | FAIL | 454 lines vs 230: WRONG if Ty ratifies the draft (decision, see D11). Four headings: WRONG, renamed on purpose (Roles = "Who judges what"; phase tree = "Scope" and "The orbit"; "When to shift up" = "Signals"; "Honesty rules" = "Honesty"). Five topic names: WRONG: new prompt lines 441-444 say "run `orbit-kb help`. It gives the commands, their order, and the topics", and the philosophy (lines 813-814) says the prompt must be true "with another version of `orbit-kb`". The purpose, System 1, effort, delivery, "Not checked" phrases still pass. |
| | c3 | each of 18 rules of the old "Honesty rules", "Delivery", "Honesty rules for discovery" 1-6 is in the prompt word for word, or listed as reworded in PROMPT-MOVES.md | PASS (3 reworded) | FAIL (10 of 18) | See D2: 9 are WRONG-in-wording (reworded on purpose; the rule is kept), 1 is a change of substance. |
| check_prompt_moves.py | c2 | every heading of the OLD prompt (git 7da5320) has a row in PROMPT-MOVES.md | PASS | PASS | n/a (reads an immutable commit) |
| | c4 | each row's key phrase is in its home (help topic, hook, prompt); a `PHILOSOPHY.md §N` row needs a `### N.` heading | PASS | FAIL (4 missing, 53 present) | The 4 missing rows are the 4 `§N` rows (PROMPT-MOVES.md lines 26, 36, 63, 71). All four fail only because the regex is `^### N\. ` (`check_prompt_moves.py:137`) and the new headings are `#### N.`. All "prompt" and "help" rows still pass. See D7: the numbers also moved, so a regex fix alone would pass with the wrong targets. |
| check_panes.py | c1, c2, c3, rules | pane prompts have phases, Receives/Gives, fewer than 60 lines, review rules | PASS | PASS | n/a. But `prompt/panes/discovery.md:3` cites a section that is gone, see D19. |
| check_trace_gaps.py | t39c1, t42c9 | no tracked file says the vendor name of the System 1 model outside the allowlist | PASS | PASS (16 checks) | n/a. The new tracked files under docs/philosophy-orbit/ also pass. |
| check_hub_guidance.py | c5 | prompt "When you resume" paragraph has "in a hub", "inbox", "hubflow", "hubflow where", "orbit-kb show open" | PASS | FAIL (4 of 12) | WRONG for the prompt half. The new prompt has no hub text on purpose (line 451: "A workspace, such as a hub, names its own tools, roles, and routing in its own instructions"). "orbit-kb show open" is kept (line 447). The inbox-first rule also lives in `prompt/PANES.md` and the hub-flow SKILL.md (grep v_inbox), so it is not lost. See D8. |
| | c9 | prompt has `orbit-kb help project`, one line "in a hub HUB-CORE.md says which store holds what", at most 230 lines | PASS | FAIL (3 of 5) | WRONG (same reason as c5; `HUB-CORE.md:27` already carries `orbit-kb help project` and "What lives where"). The 230 line cap: D11. |
| | c10 | CLAUDE.md rows exist | PASS | PASS | n/a |
| | c1-c4, c6-c8, c11, c12 | hub kit, question server, trackers | not run | not run | Do not read the prompt or the philosophy (grep of PROMPT/PHIL in the file: only c5, c9 use PROMPT). |
| check_hub_fixes.py | t31c4 | first use of `hubflow` in the prompt gives `python3 .claude/scripts/hubflow.py` | PASS | FAIL ("prompt uses hubflow: never") | WRONG, same reason as hub_guidance c5. |
| | t31c8 | prompt, philosophy and core help name the human, agent and CPU; the human reads, reviews, understands; "write it to be read" | PASS | PASS (10 checks) | n/a |
| | t31c9 | prompt "**the hypothesis.**" paragraph: err-soft with hypotheses, premises, claims; oscillation; prompt at most 230 lines | PASS | FAIL (4 of 4) | First three: ANCHOR (the paragraph is now "## The hypothesis"). The 230 cap: D11. |
| | t50c2 | README, CLAUDE.md, PHILOSOPHY have no line with site/, github.io, deck, slide | PASS | PASS (1028 lines) | n/a. A constraint on new README text: the words "deck" and "slide" cannot appear. |
| | t31c1-3,5-6, t46c3, t49c1, t50c1, t50c4 | hub setup and files | not run | not run | Do not read the two texts. |
| check_informal_hub.py | t32c5 | hub PRINCIPLES.md cites philosophy headings `4. Orbit the intent. Do not translate it`, `5. The hypothesis is the closest formal statement of intent`, `8. Speed comes from skipping work, never from hiding it`; runs informal_release c3 | PASS | FAIL (3 headings missing, plus the c3 sub-run) | WRONG: the philosophy has renumbered and renamed the principles. See D9. |
| | t36c6 | philosophy keeps the sentence "lists its premises beside it" (and hub files, storemap) | PASS | not run | The philosophy half holds (line 203: "Every stated hypothesis lists its premises beside it."). The rest reads hub files, not run. |
| | other t32, t36, t41, t44 | hub installs | not run | not run | Do not read the two texts. |
| check_informal_release.py | c3 | each principle in hubkit/hub/PRINCIPLES.md names `Source: docs/PHILOSOPHY.md, "<heading>"` that is in the philosophy | PASS (46) | FAIL (7 of 46) | WRONG: 7 of the 9 cited headings are gone (only "1." and "9." survive). See D9. |
| | c1, c2, c4-c6 | install runs, CHANGELOG T24 entry | not run | not run | They pin the README and CHANGELOG text, see D12 and D20. |
| kb/tests/test_orbit_kb.sh | VR6 (line 2614) | `grep -E 'help build' prompt/SAGITTARIUS.md` has "fresh-eyes" or "FULFILL" | not run (suite) | would fail: the new prompt has no line with "help build" (grep: 0) | Half WRONG. The pointer from the prompt to the FULFILL brief is gone on purpose. The second half (panes/review.md points to FULFILL) still holds. See D10. |
| | KD1 (line 2197) | prompt does not name `orbit-kb declare` | not run | would pass (grep: none) | n/a |
| kb/tests/test_repo_map.sh | C1d (line 114) | paths exist, including prompt/SAGITTARIUS.md and docs/PHILOSOPHY.md | not run | would pass | n/a |
| kb/tests/test_release.sh | c2, c3 | install.py has no word "settings"; CHANGELOG has words "hub kit", "philosophy", "spec KB", the vendor name of the System 1 model, "flow ledger", "Lean", "small prompt", "panes", ..., "Not in this release yet", and "0.2.0" | not run | not run | Not affected by the texts. They pin the CHANGELOG and install.py, see D20 and D-c6. |

---------------------------------------------------------------------------------------------------

## Findings

### D1. check_prompt_small c1 holds the old shape of the prompt
- **New text**: whole prompt, 454 lines; heading list "The idea", "The orbit", "Who judges what", "Scope", "The light path", "The hypothesis", "Signals", "One response", ..., "The tool". Line 441: "**Before your first `orbit-kb` command in a session, run `orbit-kb help`.** It gives the commands, their order, and the topics."
- **Build**: `docs/check_prompt_small.py:27` `MAX_LINES = 230`; `:30-39` REQUIRED has "## Roles", "## The phase tree", "## When to shift up", "## Honesty rules", and the five `orbit-kb help TOPIC` names.
- **Kind**: stale words (headings, topics); contradiction (line cap, see D11).
- **Smallest change**: replace the heading list with the new one (or with key phrases per item, as `check_panes.py` does for review rules); drop the five topic names and require only "orbit-kb help"; decide the cap (D11).
- **Size**: S.
- **What holds the old behavior**: `check_prompt_small.py` c1; also lines 4-9 of its docstring.

### D2. check_prompt_small c3: 10 of 18 old rules are reworded, one in substance
The check compares word for word. Table of the 10 failures against the new prompt:

| Old rule (start) | New text | Kind |
|---|---|---|
| "These rules apply to both orbits. A check that cannot fail is not evidence (see "Quiet failures")." | line 365 same, cross-reference dropped | rewording, rule kept |
| Rule 2 "...in a KB with `orbit-kb attest disclosure`..." | lines 369-371 "in the KB when one exists" | rewording (syntax moved to help) |
| Rule 3 "...about the Lean model..." | line 374 "about the Lean definitions" | rewording on purpose (Ty: "Lean is not a modeling language") |
| Rule 5 (reworded entry in PROMPT-MOVES.md exists; NEW no longer in prompt) | lines 376-380 reworded again | rewording; PROMPT-MOVES.md:133-135 must get a new entry |
| Delivery block | lines 403-415: `Triggers:` is `Signals:`; new `Formal:` | deliberate change (Ty likes both) |
| `KB:`/`Triggers:` paragraph | lines 417-422 | deliberate (`Signals:`, "compares the work with "Signals"") |
| Waiver paragraph (`orbit-kb attest waiver X "waive(X, 'DUE', 'why')" --by human`) | lines 432-437, no command | rewording (syntax moved to help); see D16 eval 9 |
| Discovery "These rules extend the shared honesty rules." | line 382 "extend the rules above" | rewording |
| Discovery rule 1 ("until a system `reproduction` attests `confirms(F)`") | line 384-386 "until the system confirms it" | rewording (syntax out) |
| Discovery rule 3 "Only a trusted model gives a verdict about the current system." | lines 388-390 "only after it has matched the system: on a real case where the system fails, and on a real case where it passes" | change of substance (the old open question F "Two sides" became a rule) |

- **Kind**: stale words, except the last row (the tool's `model_trusted(M)` is "sane, calibrated, and does not diverge", `kb/share/orbit-kb/help/discovery.txt:45`; whether "calibrated" needs both a failing and a passing case is for the tool audit).
- **Smallest change**: replace the word-for-word test with one key phrase per rule (the panes check does this); add the new `Signals:`/`Formal:` block to the check.
- **Size**: S to M.
- **What holds the old behavior**: `check_prompt_small.py` c3 and its reading of `docs/PROMPT-MOVES.md` between the `c3-rewordings` markers.

### D3. check_consistency c1 anchors on old headings and `Triggers:`
- **New text**: "## Signals" with six bullets; `Signals:` line in the delivery block (lines 406-407).
- **Build**: `docs/check_consistency.py:32` `block(prompt, "## When to shift up", "Three parties decide")`; `:38` `block(prompt, "Triggers:", "Claims:")`.
- **Kind**: stale words (assertion still holds, tested).
- **Smallest change**: anchors "## Signals" / "## One response" and "Signals:".
- **Size**: S. **Holds it**: check_consistency c1.

### D4. check_consistency c4 requires panes in the prompt's Scope
- **New text**: Scope lines 84-93, no panes. Line 451: "A workspace, such as a hub, names its own tools, roles, and routing in its own instructions. Follow them there."
- **Build**: `docs/check_consistency.py:76-84` asserts the report bullet has "panes", "review", "intake", "discovery", "without".
- **Kind**: contradiction (the check wants the prompt to hold what the new prompt gives to the hub).
- **Smallest change**: point c4 at `prompt/PANES.md` / `panes/review.md` ("intake"); delete the prompt half. Needs Ty's word that the prompt holds no panes (it matches "The two work best together, and neither depends on the other").
- **Size**: S. **Holds it**: check_consistency c4. Also `README.md:63-66` says new work starts in review; that stays true for panes.

### D5. Anchors of bold paragraph markers: consistency c6, c9; words c2; hub_fixes t31c9
- **New text**: "## The hypothesis" (line 163), "## The vote" (line 340). The five err-soft/oscillation phrases are at lines 224-226; the win rule at 343.
- **Build**: `check_consistency.py:158` `block(..., "**The vote.**", "Seal your vote")`; `check_words.py:131` `block(prompt, "**The hypothesis.**", "**The vote.**")`; `check_hub_fixes.py:187-189` `w.find("**the hypothesis.**")`; `check_consistency.py:102` the F paragraph.
- **Kind**: stale words. I tested each regex of words c2 (a) and t31c9 on the new "## The hypothesis" section: all pass.
- **Smallest change**: re-anchor on "## The hypothesis" / "## The vote". For c6, delete the F-paragraph assertion (the paragraph is gone) and keep the other four.
- **Size**: S. **Holds it**: those four claim ids.

### D6. check_words c2 "Applied in" is the only check that proves a principle's pointer true; the new format breaks it
- **New text**: philosophy principles are `#### N.` headings; each ends with "In the prompt: "The orbit", "Who judges what", "The vote"." (line 163; also lines 241, 280, 316, 331, 355, 369, 402, 426, 485, 518, 526, 536) and principle 14 "In the repository: `docs/REFINING.md`." (line 556). I read all 13 prompt pointers: every section name they cite exists in the new prompt ("The idea", "The orbit", "Who judges what", "The light path", "The hypothesis", "Signals", "One response", "When the human says that it is wrong", "The vote", "Honesty", "The tool", "Delivery"). So the pointers are true by name today.
- **Build**: `check_words.py:104-108` regex `^### (\d+)\. ` and `^Applied in:`; table `APPLIED` (lines 70-97) is keyed to old section names and needles (for example `"prompt:The phase tree": [r"parallax"]`).
- **Kind**: stale words. The check's idea (every pointer is true, and a target that no line names is a failure) is still right.
- **Smallest change**: read `#### N.` and "In the prompt:" lines; reduce the table to "the section exists" plus one needle per pointer taken from the new text.
- **Size**: M. **Holds it**: check_words c2.

### D7. check_prompt_moves c4: `§N` rows cite old principle numbers
- **New text**: philosophy principle titles: 1 human owns the intent; 2 each statement is an attempt, the hypothesis is the first; 4 no party grades its own work; 5 each statement comes from the source; 7 tools assume trust; 8 a divergence is good news; 9 words match evidence; 10 one response; 11 each formal language is a lens; 12 speed.
- **Build**: `docs/PROMPT-MOVES.md:26` (`## Purpose` to §2), `:36` (`## The orbit` to §4 "Orbit, do not translate"), `:63` (`### The hypothesis` to §5), `:71` (SPECTRUM to §11), `:85` ("PHILOSOPHY.md §7, open question E"), `:118` (§9), `:135` ("§10 ... retires honest mistakes"). `check_prompt_moves.py:137` regex `^### {num}\. `.
- **Kind**: stale words. Meanings moved: old §4 (orbit) = new §5; old §5 (hypothesis) = new §2; old §10 (trust) = new §7; old §3 (no party grades) = new §4; old §8 (speed) = new §12. §9 and §11 keep their number and meaning. If only the regex is fixed to `####`, c4 passes with rows 36 and 63 pointing at the wrong principle, because c4 checks the number and not the title. A quiet pass.
- **Smallest change**: cite principles by title, and make c4 check the title. Update the four rows and the three prose cites.
- **Size**: S. **Holds it**: check_prompt_moves c4.

### D8. Three hub checks pin hub text inside the prompt
- **New text**: lines 451-452 (above). The prompt carries no `hubflow`, no `HUB-CORE.md`, no `orbit-kb help project`.
- **Build**: `check_hub_guidance.py:241-248` (c5), `:285-292` (c9), `check_hub_fixes.py:113-120` (t31c4).
- **Kind**: contradiction between the checks and Ty's decisions ("The mindhole and Sagittarius ... are not dependent on one another"; philosophy line 812-813 "the prompt must be true alone: with no hub").
- **Smallest change**: move each assertion to the hub text: HUB-CORE.md (has "What lives where" at line 14 and `orbit-kb help project` at line 27), `prompt/PANES.md` and the hub-flow SKILL.md (hold `v_inbox`). Keep the "orbit-kb show open" part for the prompt (still true, line 447). Confirm that something in the hub's own always-loaded text says "read the inbox first" (I found it only in PANES.md and the skills, not in `hubkit/hub/CLAUDE.md` or `HUB-CORE.md`: grep "inbox" gives no hit there).
- **Size**: S (checks) plus a possible S in the hub text (other auditor).
- **Holds it**: hub_guidance c5, c9; hub_fixes t31c4.

### D9. The hub's PRINCIPLES.md cites philosophy headings that are gone
- **New text**: principle headings listed in D7. Also gone: the principle "7. Rigor follows signals of misunderstanding, not size or difficulty" as a heading ("Start light" now lives in "The light path"; "Most work needs little process" is the first sentence of principle 10, line 431).
- **Build**: `hubkit/hub/PRINCIPLES.md` lines 10, 16, 22, 28, 35, 41, 47, 53, 60 (`Source: docs/PHILOSOPHY.md, "..."`). Seven of nine fail: `2.`, `4.`, `5.`, `7.`, `3.`, `6.`, `8.` (`1.` and `9.` survive). Readers: `check_informal_release.py:241-246` (c3), `check_informal_hub.py:393-401` (t32c5).
- **Kind**: stale words. Also a decision for Ty: the philosophy says "It is installed nowhere" (line 14), while the hub kit ships PRINCIPLES.md with philosophy sources into each hub (`hubkit/kit.json` lists it as engine). Not mine to rule on; the hub audit should.
- **Smallest change**: re-source each principle to a new title; the check list `P_WANT` (`check_informal_hub.py:386-388`) and `check_informal_release` c3 follow. Or drop `Source:` lines if PRINCIPLES.md is retired.
- **Size**: S to M. **Holds it**: informal_release c3; informal_hub t32c5.

### D10. test_orbit_kb VR6 requires a "help build" line in the prompt
- **New text**: no `orbit-kb help build` in the prompt (grep: 0).
- **Build**: `kb/tests/test_orbit_kb.sh:2614` `grep -E 'help build' "$pr/SAGITTARIUS.md" | grep -Eqi 'fresh-eyes|FULFILL' || note ...`.
- **Kind**: contradiction. **Smallest change**: delete that line; keep the review.md half (line 2615). **Size**: S.
- **Holds it**: VR6 (not run; I read the line and grepped the new prompt).

### D11. A cap of 230 lines is written in three checks (decision for Ty)
- **New text**: 454 lines; philosophy "size determines nothing" is about the work, not the prompt. The prompt grew from 2318 to 5139 words (`wc -w`).
- **Build**: `check_prompt_small.py:27`, `check_hub_guidance.py:292` ("c9 prompt stays within 230 lines"), `check_hub_fixes.py:195` ("t31c9 ... within 230 lines"). History: T08 c6 raised 200 to 230 after rules were restored.
- **Kind**: contradiction if the draft is ratified. I cannot say whether Ty wants any cap. One cap in one place (check_prompt_small) is enough; the other two are copies.
- **Smallest change**: remove the two copies; set or drop the cap in check_prompt_small.
- **Size**: S.

### D12. README.md sentences that the new texts make false or stale
Each line quoted from `/home/ty/Projects/mine/sagittarius/README.md`.
- Line 8-9: "the agent adds rigor one step at a time: a knowledge base (KB) of claims and questions, more rounds of questions, and, for a claim about every case, a Lean proof." Stale. The new prompt has three levels, words, records, formal statement (lines 284-290), "in the one formal language that fits the claim: a solver for rules and limits, a model checker for orders of steps and time, Lean for every input". Lean is one of three, not the only formal step. Nothing in the README says that every ticket starts with a stated hypothesis.
- Line 13-14: "Prolog KBs, Lean proofs, and a small model (System 1) that reads each message." Stale: solver and model checker are missing; System 1 runs only "when its hook is installed" (prompt line 303), and "No line means no outside view".
- Line 25: "**Add the System 1 hook (optional).**" Stale word: philosophy says "For now the hook is recommended, not required" (line 803) and "belongs here, not with the hub" (line 802). The step order (hub step 2, hook step 3) reads as if the hook belongs to the hub kit.
- Line 33: "It states the philosophy in short; the procedure is in `orbit-kb help`." Partly false. The new prompt itself holds a procedure for the light path (numbered build and discovery steps, lines 116-152), the one response, the vote and the delivery. It says "The procedure of the tool is in `orbit-kb help`" (line 4). Say "how to act", not "the philosophy in short".
- Lines 50-59 (install): not false, but the install is "append with `claude --append-system-prompt`; wrap it in a shell function". Ty wants a separate install sequence with an agent's help and the standing rule that no script writes settings.json. Gap, see D13.
- Line 61-66 (Panes): "New work starts in review". True for panes; the prompt no longer says it (D4). Fine.
- Line 110: "`evals/` | One-shot planning evals for the prompt, with graded runs." Stale before this audit: `evals/` also holds the tool-use evals (`tools.json`, `run_tools.sh`).
- No sentence about two interfaces (Sagittarius and MindHole), no version. Gap. README line 90 calls it "the hub kit", philosophy lines 799-809 call the hub MindHole.
- **Kind**: stale words (first four), gap (last two). **Size**: S. **Holds it**: check_consistency c7 (README Layout rows and "manual"/"approved"), check_words c3 (README sentence on the harness; keep it), check_informal_release c1 and c5 (README must keep exactly one informal-release line, "SWI-Prolog", "./install.py", no "hubflow-starter"), check_hub_fixes t50c2 (no "deck"/"slide").

### D13. CLAUDE.md (the map)
Quoted from `/home/ty/Projects/mine/sagittarius/CLAUDE.md`.
- Line 21: "`docs/PHILOSOPHY.md`: the beliefs under the design, open questions, and how to judge a change." Stale words: the new philosophy has "Under trial" (line 822), ten questions in "How to judge a change" (lines 849-873), and a version line (2.0.0). **S**.
- Line 10: "Installed as `~/.claude/sagittarius/SAGITTARIUS.md`. Each user appends it to their sessions (see "Install" in `README.md`)." True today. Gap against Ty's wish for a prompt install sequence with an agent. **S** after the install exists.
- Line 14: "The agent-facing syntax and recipes live here, not in the prompt." Still true for syntax. The new prompt holds the light-path steps, so "recipes" is half true. **S**.
- No row for versions, and no row that says the philosophy is not installed anywhere (philosophy line 14). **S**.
- Rows 11-20, 22, 23: not affected.
- **Holds it**: check_hub_guidance c10 (needs rows named "project kb module", "question view", "question server", "draft", "pin-item", "hook", "status line"); check_hub_fixes t50c2 (no "| Decks |").

### D14. docs/PROMPT-MOVES.md is a map of the OLD prompt; parts are now false
- Line 3-4: "the prompt states the philosophy, `orbit-kb help` holds the procedure". Stale (D-c8).
- Lines 26/36/63/71/85/118/135: `§N` cites and "open question E" (D7). "Open question E" no longer exists: the philosophy has no "Open questions" section.
- Rows with home `help discovery` and key phrase "Too strong" / "Collapsed:" (lines 63, 105): the new prompt holds that worked example itself (lines 184-186: "Too strong", "Collapsed", "Fit"). The example now lives in two places (prompt and `help discovery`); they can drift.
- Rows 22-23: "Kept as 'Start light'", "Now 'When to shift up'" name headings that are gone.
- Section "Rewordings (c3)" (lines 131-146) lists three rewordings; seven more are needed (D2).
- Decision for Ty: the map is a record of ticket T08 against git 7da5320. Either keep it as history and stop the checks from reading it, or write a new map from the 2026-11-11 draft. The file names no owner for either.
- **Kind**: stale words. **Size**: M. **Holds it**: check_prompt_moves c2/c4, check_prompt_small c3.

### D15. docs/REFINING.md: still usable, with five facts that changed
Quoted from `/home/ty/Projects/mine/sagittarius/docs/REFINING.md`.
- The loop (tuning set, held-out set at the gate, 2-of-3 runs, base on the same day, rule-deletion check) does not name any section or rule of the old prompt, so none of its statements is false. It is usable.
- Strain on rule 5 (line 70-71, "delete the rule from a copy of the prompt and run the case ... It must fail"): the new prompt states one rule in several places (the wide default is in the light path step 1, line 120; in "Asking", line 156; in "The hypothesis", lines 201-206). A copy with "one rule deleted" needs all of them removed, and the philosophy says "In the prompt:" sections per principle, which helps find them. The philosophy puts this rule itself under trial (line 836: "A rule of the prompt needs a case that fails when the rule is deleted"). Today no case exists for: premises beside the hypothesis, the wide default, "say what you expect before you look", `Formal:`, one lens at a time, "Kept/Changed" narrowing, whole suite once.
- Line 99-106 (table of cases that run on Sonnet or Opus): the reasons are measurements against old prompts ("It names the trigger in its own words"). With a 2.2 times longer prompt these numbers are not valid for the new text; rule 6 says to compare with the base on the same day, so each row must be re-measured before the new prompt is judged.
- Line 46: "An eval prompt does not name the process (KB, orbit-kb, shift up, trigger, divergence)". The list is illustrative; "signal" replaces "trigger", and "hypothesis", "premise", "light path" are new process words.
- Line 33-34: `check_leaks.py` "checks the uncommitted prompt diff for 4-word overlaps". On a full rewrite the diff is the whole file; see D17.
- Lines 15-26: held-out twins are "id + 100". The tuning cases whose behavior changes (D16) have twins that the tuner may not read; blind writers must rewrite those twins (REFINING lines 112-123). I did not look at held-out files.
- Line 6: Haiku is the executor. The prompt is 5139 words now; I did not measure whether Haiku follows it. Not checked.
- **Kind**: stale words (small), gap (rule-deletion cases). **Size**: S for words, M for the cases.

### D16. Eval cases that assert behavior the new prompt changes (ids below 100)
Graders read only one delivery field: `KB:` (`evals/grade_tools.py:74-78`, `delivered_kb`, regex `^\W*KB:\W*\s+...`). No script reads `Signals:`, `Triggers:`, `Formal:`, `Guesses:` or `Claims:` (grep of `evals/*.py` and `*.sh`). The `KB:` field name is unchanged in the new block, so the graders still work. Only the rubric judge (`grade_rubric.py`, Opus) reads the delivery text, against `assertions`.

| Eval | Asserts (quote) | New text | Verdict |
|---|---|---|---|
| tools 5, 18, 19 `correction-records-divergence` | Turn 2 "reads the correction as a divergence"; check `query:divergence_recorded` | Prompt lines 329-336: if the result matched what was asked and the human now wants a part changed, "record a new claim that supersedes the old one. Record no divergence against the old claim". Line 337: "If you cannot tell ... do not guess. Say so, and treat it as a divergence." Case 19 ("not the orchids, sorry ... the rest at 2 is right") and case 5 ("no, the grader has to be smarter") can be read as intent moved. | PARTLY. The cases sit on the new border; the preference case 23 asserts the opposite and passes the new rule. Decide per case what the new prompt means; the "cannot tell, so divergence" line keeps 5/18 plausible. |
| tools 16, 17, 20 `redesign-mid-ticket` | Turn 2 (change of plan) "is read as a divergence ... records the divergence"; check `query:divergence_recorded`; notes line 16: "a mid-ticket change of design is a divergence (continuity)" | Lines 233-237: when the human wants a case the hypothesis rejects and the answer says what it changes to, "restate it: the new hypothesis supersedes the old one. Show it, and go on." Nothing says to record a divergence. System 1's hint "a divergence, a change of plan" counts as a fired signal (lines 304-307). | PARTLY. The new text does not say if a clear change of plan is a divergence record or only a superseding hypothesis. Ask Ty. The continuity guard (keep the earlier outcome as a claim, re-check it) is kept by lines 331-332. |
| tools 21 `problem-restated-mid-build` | Notes: "after a divergence ... if not, go back to discovery"; checks `query:hypothesis(H, _, _)`, `query:touched_system` | Lines 236-237: "If the answer says what it changes to ..., restate it ... If you can no longer say what to change, the ticket is a report again: go to discovery." In case 21 the human states the new complaint, so the new text says stay in build. | PARTLY. The assertion "states a hypothesis ... and reproduces it" still holds; the notes' "go back to discovery" is stale. The checks need KB `hypothesis` and `touched_system` facts: still reachable because the turn-2 correction is a signal. |
| tools 22 `timing-claim-models-before-burn` | TLC in TLA+ "before it writes any Lean statement"; claim marked universal and burns | Lines 298-301: "One lens at a time ... record the signal, and first finish that work or drop it with a disclosure." TLA+ first, then Lean is sequential, so allowed. | RIGHT. Add a check that the agent finishes the TLC work (or discloses a drop) before it writes Lean. |
| tools 14 `proof-cannot-fail`, planning 11 `proof-claim-honesty` | "the proofs are about the Lean model, not the shipped code" | Line 374: "Proved in Lean is about the Lean definitions, not the code." | Stale words (Ty: "Lean is not a modeling language"). The Opus judge grades meaning, so probably passes; reword the assertions. |
| planning 9 `deadline-skip-is-waiver` | "Uses the waiver command form with --by human"; expected_output quotes `orbit-kb attest waiver X "waive(X, 'DUE', 'why')" --by human` | Lines 432-437 give the waiver rule with no command; the command is in the tool help. This eval is one-shot with no tools (`evals/run.sh` says "Don't run any tools"), so the agent cannot read the help. | CONTRADICTION. The assertion asks for syntax the new prompt does not carry. Drop the assertion, or move the eval to `tools.json`, where the agent can read the help. |
| planning 10 `gate-human-outvoted` | "Records the disagreement as a divergence" | Lines 340-361: "A result with no winner is HOLD: say what it waits for." No line says to record a split vote as a divergence (the tool's report does: CONTRACT V4). | PARTLY. The signal "A divergence: two of the three roles disagree" covers it by reading, not by a line. |
| planning 1 `route-report-to-discovery` | "records its own vote sealed before showing the report" with "Starts with no KB" | Line 358-359: "With no KB, write it nowhere until the human votes." | Pre-existing tension (no KB, so nowhere to record). The new text did not create it; flagged because the assertion and the line disagree. |
| planning 8 `handoff-trigger` | "Add a dark-mode toggle to the profile page" | Prompt line 193: "A second example ... "add a dark mode"" (the 4-word run "add a dark mode" is shared). `evals/evals.json` notes line 3: "Each scenario avoids the examples used in the prompt itself". | Stale hygiene. The new example is in the prompt; change the example or the eval. Also see D17. |
| tools 4 `light-path-no-kb`, tools 13, planning 5 | "Delivers with KB: No KB"; "Restates the request with one concrete example" | Line 118-123: hypothesis with premises ("Premises: none") and one example on every ticket, wide default. | RIGHT, but too weak: nothing asks for the hypothesis sentence, the premises, or the wide default. |
| tools 8 `count-off-by-one` | "Sees that the suite shows 8 tests, not 7" | Line 136: run the whole suite once after; before only when no green run is known (line 127-128). | RIGHT (the suite is read after the build). |
| tools 1, 3, 7, 9, 2, 10-12, 23 | handoff, resume, subagent, preference, hypothesis wording | Lines 260-270, 313-318; 329-332 | RIGHT. Case 23 guards the new "intent moved: no divergence" rule. Cases 10-12 grade a hypothesis with no cause built in, in line with "Assume little". |

Behaviors with no case at all (gap): (a) a hypothesis with premises and one example on a light-path ticket; (d) the wide default written into the sentence; (e) a new wish that adds to a liked result is a new ticket with its own KB only on a signal; the "Kept: / Changed:" line; (f) suite once after; (g) "a ticket starts in words; a KB starts on a signal" (typo with no KB); `Formal:` beside the plain claim; and the human-witness case ("show the case just inside the edge").
**Size**: M (rewrite 3 to 8 cases and add about 6). **Kind**: contradiction (planning 9), stale words, gap.

### D17. Eval tooling: the planning runner cannot take a candidate prompt; leak check
- **New text**: it lives on a branch, not installed.
- **Build**: `evals/run.sh:3-4` "it gets exactly the live Sagittarius prompt (every account gets it)"; it has no `--prompt` flag (the file has no such option). `evals/run_tools.sh:9` has `--prompt F`. To run `evals.json` on the branch prompt you must install it first (relink `~/.claude/sagittarius`), which changes every session of the user.
- `evals/check_leaks.py:11-14,17` reads `tools.json` and `heldout/*.json` only, and defaults to `git diff -U0 -- prompt/SAGITTARIUS.md`. A rewrite is all added lines, so the diff is the whole file. It does not read `evals.json`, so the overlap "add a dark mode" (planning 8) is not caught. My own scan of `tools.json` and `evals.json` against the new prompt, 4-word runs: tools 1 "on the light path"; planning 6 "on the light path"; planning 8 "add a dark mode", "on the light path"; planning 10 "the formal artifacts vote"; planning 11 "and orbit kb prove". Only "add a dark mode" is a real example; the others are the prompt's own words.
- `evals/grade_tools.py:30` `WRITES = {"init", "uses", "add", "declare-attest", ...}`: `declare-attest` was removed from `orbit-kb` (T03). Harmless, stale.
- **Kind**: gap. **Smallest change**: add `--prompt FILE` to `run.sh` as in `run_tools.sh`; add `evals.json` to `check_leaks.py`. **Size**: S.

### D18. Versions: facts for D-c6 (see the section below)

### D19. Pane prompts cite sections and words of the old prompt
- **Build**: `prompt/panes/discovery.md:3` "(see "The phase tree" in the Sagittarius prompt)"; `prompt/PANES.md:24` "A handoff is a trigger: the receiver runs `orbit-kb show open` first." The new prompt has no "The phase tree" (the split between discovery and build is in "Scope", lines 95-103); "trigger" is "signal".
- **Kind**: stale words. **Size**: S. **Holds it**: check_panes c1 only forbids citing "Discovery orbit", so it does not catch this.

### D20. CHANGELOG.md
- Line 19: "Small prompt (T08): `prompt/SAGITTARIUS.md` is short. The procedure moved to `orbit-kb help`." True as history, false for the draft (454 lines). The test `kb/tests/test_release.sh:77` requires the words "small prompt", "philosophy", "Not in this release yet", "0.2.0" in the file, and `check_informal_release.py:322-331` requires a T24 line with the kit version and no older "hub kit is version X.Y.Z" as current. A new version entry must keep those words, or those tests change first.
- Line 3-7: "Redesign (informal release) ... The hub kit is version 0.5.1". No number for Sagittarius.
- Philosophy line 829: "`CHANGELOG.md` says what a change of each number means." The CHANGELOG says nothing of the kind.
- **Kind**: gap, stale words. **Size**: S.

---------------------------------------------------------------------------------------------------

## Verdicts for the candidates

- **D-c1: CONFIRMED, and wider.** The lead was right on `check_prompt_small` c1 (454 vs 230; headings; five topic names) and c3 (10 of 18); `check_consistency` and `check_words` stop on "substring not found"; `check_prompt_moves` c4 has 4 missing rows; `check_panes` passes. Also failing: `check_consistency` c4, `check_hub_guidance` c5 and c9, `check_hub_fixes` t31c4 and t31c9, `check_informal_hub` t32c5, `check_informal_release` c3, and `test_orbit_kb.sh` VR6 (read, not run). Table above. One lead detail is slightly off: `check_consistency` c1, c6, c9 and `check_words` c2 fail because of anchors; three of those four hold in substance (D3, D5).
- **D-c2: CONFIRMED** (D12): four false or stale sentences (README lines 8-9, 13-14, 25, 33), one stale since before (line 110), two gaps (two interfaces, version).
- **D-c3: CONFIRMED** (D13): CLAUDE.md line 21 names "open questions". The other rows are not affected.
- **D-c4: PARTLY.** `docs/REFINING.md` makes no statement about old sections, so the loop is usable (D15). `docs/PROMPT-MOVES.md` has false statements (D14). The table of executors in REFINING (lines 97-106) is evidence from old prompts and must be re-measured.
- **D-c5: CONFIRMED** (D16, D17): graders read only `KB:`; list of cases and the gaps.
- **D-c6: facts below.**
- **D-c7: CONFIRMED for two places only.** `CLAUDE.md:21` ("open questions") and `docs/PROMPT-MOVES.md:85` ("open question E"). Nothing in docs, checks, evals, hubkit, or s1 says "A-F" or "seven questions" (grep over README, CLAUDE, CHANGELOG, docs, evals, prompt, hubkit docs, kb help, s1 README). The old philosophy itself had "## Open questions" (A to F, line 261) and "How to judge a change" with seven questions (lines 339-347); the new one has ten questions (lines 849-873) and "Under trial" (line 822).
- **D-c8: CONFIRMED for four places.** `README.md:33` ("states the philosophy in short; the procedure is in `orbit-kb help`"), `docs/PROMPT-MOVES.md:3-4`, the old prompt line 221 ("This prompt holds the philosophy only", gone from the new one), the old philosophy lines 5-6 and 231 ("The prompt holds the philosophy only."). The new prompt line 4 says "This prompt says how you act. The procedure of the tool is in `orbit-kb help`." The new philosophy lines 815-818 say the prompt holds "the orbit, the light path, and the signals" and the tool "holds the procedure and its syntax". `CLAUDE.md:14` ("syntax and recipes live here, not in the prompt") is true for syntax. `check_words.py` c2 and `check_prompt_small.py` docstring (lines 1-14) carry the old split too.

## D-c6 (facts): where a Sagittarius version would have to be stated

Facts that exist today:
- Tag `v0.1.0-experiment` (2026-07-01, commit a83eca5, subject "Sagittarius v0.1.0-experiment - archival snapshot ... Archived as an EXPERIMENT: not promoted to the canonical pipeline (D-13)"). It belongs to the Workflow experiment era (README lines 114-117), not to this build. Other tags: `workflow-experiment` (2026-07-01), `thoughts-archive` (2026-10-22), `seam-experiment-base` (2026-10-29). No other version tag.
- `hubkit/kit.json` `"version": "0.5.1"` is the hub kit version, with a test (`test_release.sh` c3, `check_informal_release.py` c6) that it only goes up and that `UPGRADING.md` has a section per version. The hub kit is the only versioned part.
- The prompt: last line, line 454, "This is the Sagittarius draft of 2026-11-11. It has no version number yet." The old prompt has no version line.
- The philosophy (branch): first lines "Philosophy 2.0.0 ... (version 1.0.0)" and lines 820-829 say three numbers: Sagittarius one release ("The last line of the prompt names it: 0.3.0"), the philosophy 2.0.0, the hub kit 0.5.1. So the philosophy cites a prompt version, 0.3.0, that the prompt draft does not carry. And it promises that CHANGELOG says what each number means; it does not.
- `orbit-kb --version` is "Unknown command". `orbit-kb doctor` prints the SWI-Prolog version only. `install.py` has no version. `README.md` has no version. `CHANGELOG.md` has headings by name ("Redesign (informal release)"), no numbers. `s1/` has none (the model id `jev-1.14.0` is the vendor's). `kb/CONTRACT.md` numbers decisions (D22, D25) not releases. `/home/ty/Projects/mine/sagittarius` has no VERSION file.
- The word "settings" must not appear in `install.py` (`test_release.sh` c2), so any install step that touches versions must keep that.
- A semver of Sagittarius has to start above 0.1.0 or define how it relates to the experiment tag, since `v0.1.0-experiment` already uses that number (the philosophy's 0.3.0 does start above it).

## Where the build already agrees
- `check_words` c1 and c3, `check_panes`, `check_trace_gaps`, `check_hub_fixes` t31c8 and t50c2, `check_hub_guidance` c10: all pass on the branch. The new prompt keeps the "human, the agent and the CPU ... shared substrate" sentence (lines 78-80), "write it to be read", "Err toward the general and soft in hypotheses, premises and claims", "Oscillation is an intentional heuristic", and "more than 0.5, so the human and at least one other".
- The six signals are still six, with Effort last (D3). The `KB:` delivery field the graders read is unchanged. `docs/PHILOSOPHY.md` is installed nowhere: `install.py:7` links only `prompt/` to `~/.claude/sagittarius`, so the "installed nowhere" line agrees with the build. The new prompt names no `orbit-kb declare` (KD1 passes) and no lint code, so nothing in it can go out of date with the tool's codes.
- The new prompt keeps `orbit-kb show open` before any work on a resume (line 447), so hubflow `c5` half about the tool still holds.
- `docs/REFINING.md` rules 1-4, 6 do not name old sections, so the loop is usable as written.
- Case 23 (`preference-change-supersedes`) already encodes the new "intent moved: supersede, no divergence" rule.

## Suggestions beyond alignment
1. **Replace word-for-word prompt checks with a rule list, one key phrase per rule.** Problem: `check_prompt_small` c3 breaks on every rewording (10 of 18 now), and the answer "list it in PROMPT-MOVES" takes a human edit for each rewrap. Evidence: D2; `check_panes.py` already uses key phrases for review rules and passes on both trees. Pair it with a check that every `In the prompt:` pointer of the philosophy names a section that exists (D6), which is cheap and proved useful: all 13 pointers are true today.
2. **Make PROMPT-MOVES.md a dated record and stop the checks from reading it for the new prompt**, or give each version of the prompt its own map. Problem: its checks pin an old shape, and the map now says things about a heading list that will keep changing. Evidence: D14.
3. **A "prompt is true alone" check.** The philosophy says the prompt must be true "with no hub, with another version of `orbit-kb`, and when System 1 is silent" (lines 812-813, and question 10 of "How to judge a change"). A grep-level check that the prompt names no hub store, no `hubflow`, no lint code, no `orbit-kb` subcommand except `help`, `show open`, `whynot`, `prove`, `report` would hold it. Evidence: the new prompt names exactly these (`grep -n "orbit-kb [a-z]"`: lines 378, 396, 421, 442, 447); and D8 shows the old checks push the other way.
4. **Add `--prompt FILE` to `evals/run.sh` and `evals.json` to `check_leaks.py`** (D17). Problem: the planning evals can only run the installed prompt, and the leak check does not see them. Evidence: `run.sh:3-4`; `check_leaks.py:17`; the "add a dark mode" overlap.
5. **A test of the prompt's own claim about the delivery.** `Signals:` says that if a signal fired, `KB:` names a KB (line 418-419). A grader check (`signals_kb`: the last delivery has "yes" in `Signals:` and a `KB:` value other than "No KB") would measure the rule, and the grader already parses `KB:` (`grade_tools.py:78`). No grader reads `Signals:`, so a quiet failure there is invisible today.
6. **Version in one place.** One line in `CHANGELOG.md` per release, the same number on the last line of the prompt, and a `kb/tests` check that the two agree (as `test_release.sh` c3 does for the kit). Evidence: D-c6 facts; the philosophy already promises the CHANGELOG meaning and cites 0.3.0. Proposal only; not designed.
7. **Re-measure the executor table of REFINING.md** as one batch before judging the new prompt, with the base on the same day (rule 6). Evidence: lines 97-106, written against 221-line prompts.

## Not checked
- Held-out cases and runs (forbidden). Whether Haiku follows a 454-line prompt (no eval run).
- The checks that build a scratch hub (informal_hub other claims, informal_release c1, c2, c4-c6, hub_fixes other claims, hub_guidance other claims): not run, because they write files; by grep they do not read the prompt or the philosophy (hub_guidance c5 and c9 and hub_fixes t31c4, c8, c9 are the exceptions, and I ran them).
- `kb/tests/test_orbit_kb.sh` VR6 and KD1 and `test_repo_map.sh` C1d: read and grepped, not run.
- Whether the tool's `model_trusted` matches the new two-sided calibration rule (tool audit).
- Whether "change of plan" should be a recorded divergence (an open question for Ty; D16).

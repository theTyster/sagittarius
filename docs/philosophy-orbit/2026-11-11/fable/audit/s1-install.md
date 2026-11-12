# Alignment audit: System 1, the install path, the Lean homes, repo-map (prefix S)

Build: `/home/ty/Projects/mine/sagittarius` (main, 7124544). New texts: the worktree
`/home/ty/Projects/mine/wt/sagittarius/philosophy-fable` (`prompt/SAGITTARIUS.md` = "NP",
`docs/PHILOSOPHY.md` = "NPh"). Paths below are relative to the build unless they start with `/`.
Nothing was run except `install.py --check`, greps, and reads. No test suite, no `lean`, no `lake`.

Counts: 12 candidates (9 CONFIRMED, 3 PARTLY: S-c4, S-c8, S-c12), 10 own findings (S13 to S22).
Each finding is counted once, by its first kind and its smallest size.
By kind: contradiction 3 (S-c1, S-c8, S13), gap 15, stale words 4 (S-c4, S-c10, S14, S20).
By size: S 11, M 11, L 0. Two findings grow to L if Ty takes the larger option: a second hook
event (S-c3) and a rename of the `burn_model` names (S-c10).

---

## Candidates

### S-c1. The question set covers two of the six signals, and `h_divergence` excludes a request. CONFIRMED
- **New text**: NP "One response", line 275: "A request is the first divergence of its ticket". NP
  "Signals", lines 249-270: questions, a divergence, a build by someone else, a claim that burns, a
  handoff, effort. NP line 306: "If the line names a divergence, a change of plan, or effort, treat
  that signal as fired."
- **Build**: `s1/questions.json:16`: "A report of a problem in the system that the agent did not
  cause, a new request, or a change of preference does not count." The five questions and what
  each detects:

  | Question | `s1/questions.json` | Signal of NP that it detects |
  |---|---|---|
  | `h_work` (choice: research, specify, build, verify, question, other) | lines 2-13 | None. It sorts the scope and the phase (NP "Scope"). |
  | `h_divergence` (yes/no) | lines 14-17 | "A divergence", the human half only: the human corrects, doubts, finds a flaw. |
  | `h_change_of_plan` (yes/no) | lines 18-21 | Not one of the six. It is case 2 of NP "When the human says that it is wrong". NP line 306 treats it as a signal that fired. |
  | `h_effort` (yes/no) | lines 22-25 | "Effort". A direct match. |
  | `h_language` (choice: prolog, lean, z3, tla, tests, none) | lines 26-37 | None directly. It picks the lens. Its option `lean` ("A property for every input, or a proof is asked for", line 31) touches "A claim that burns", but the hook prints it as a tool, not as a burn. |

  Signals with no question: **Questions** (a round that did not settle), **A build by someone
  else**, **A claim that burns** (only by way of `h_language=lean`), **A handoff**, and the
  result half of **A divergence** (a result differs from what the agent expected).
- **Kind**: contradiction (the exclusion of a new request) and gap (four signals).
- **Smallest change**: Decide if the hook should report a request as a divergence at all: NP gives
  a request its own first response (the light path), so the exclusion may be right for the hook and
  only its reason needs a sentence in `s1/README.md`. Then add questions only for signals that a
  message of the human can show (Questions; a proof asked for).
- **Size**: M.
- **What holds the old behavior**: `s1/test_hook.py:816-819` (`H_DIVERGENCE`, word for word),
  `:859-867` (`test_t43_c1_*`), `:30` (`QIDS`), `:150-157`; `hook.format_answers` reads the five ids
  by name (`s1/hook.py:219-236`); `s1/statusline.py:124-131`; `docs/PROMPT-MOVES.md:28,53,61` and
  `docs/check_prompt_moves.py:107` (a `hook` row must be a phrase in `s1/questions.json`).

### S-c2. Silence has four causes, and the agent sees one. CONFIRMED
- **New text**: NP line 309: "No line means no outside view. It does not mean no signal." NPh
  line 846 lists it as a gap of the build: "System 1 prints nothing when it is unsure". NPh "How to
  judge a change" 4: "Can a missing answer look like a 'no'?"
- **Build**: `s1/hook.py` returns `""` on each of these paths, and `main` then prints nothing
  (`:336-338`): `S1_OFF` (`:253-254`, no log line); stdin not JSON (`:261-263`); no prompt
  (`:264-266`); questions file missing or bad (`:277-279`); no API key (`:281-285`); timeout
  (`:304-308`); state error (`:309-311`); no answers (`:313-315`); bad answers (`:318-320`); every
  answer unsure (`:321-322`, "if not line: return \"\""); any other error (`:325-327`).
  `s1/README.md:29`: "When no answer is outside the band, the hook prints nothing." `:34-35`: "It
  fails open. On any error ... it prints nothing and exits 0."
  So not installed, off, failed, and "ran and was unsure" look the same to the agent. Inside a
  line, an answer that is left out means unsure (`s1/README.md:28`), and NP does not say so.
- **Kind**: gap. NP already tells the agent how to read silence, so the texts are true alone. The
  build is behind where NPh says it is.
- **Smallest change**: Print one short line in the two cases that are not "off": `System 1: no
  view (<reason>)` on a failure, and `System 1: unsure` when every answer is in the band. Files:
  `s1/hook.py`, `s1/README.md`, the C2 and C3 tests.
- **Size**: M.
- **What holds the old behavior**: `s1/test_hook.py:567-568` (`test_c2_nothing_outside_band_prints_nothing`),
  `:577-581` (`C3FailOpen.assertSilent`) and every `test_c3_*`, `:804-808`
  (`test_hook_runs_as_a_script` wants stdout `""`).

### S-c3. Only a message of the human has an outside witness. CONFIRMED
- **New text**: NP "Signals" lines 253-255: "a result differs from what you said that you
  expected ... the check that must fail first passes"; lines 260, 265-266: "A subagent or a peer
  session built it", "A message from a peer session and a compaction summary are handoffs". NPh
  principle 4: "The rule holds for noticing too. An agent is a poor judge of whether it has
  diverged."
- **Build**: `s1/hook.py:2`: "Event: UserPromptSubmit". No other hook event is named in the
  tracked files outside `s1/` and `CLAUDE.md` (grep for `PostToolUse`, `SubagentStop`,
  `PreCompact`, `SessionStart`, `Stop`: no hit).
- **Kind**: gap.
- **The gap, by event** (names from the Claude Code hooks reference as I know it; not checked
  against the installed version, and which of them can add context for the agent is not checked):
  `PostToolUse` (a test result that differs from the stated expectation), `SubagentStop` (a build
  by someone else), `PreCompact` and `SessionStart` with source `compact` or `resume` (a handoff),
  `Stop` (the agent's own reply, for example "you're right" with no shift-up line).
- **Smallest change**: none in words. This is a design decision for Ty: which signal gets a
  second event first. Until then `s1/README.md` should say which signals the hook cannot see.
- **Size**: S for the sentence; L for any new event.
- **What holds the old behavior**: `s1/test_hook.py:109-112` (the event name in the output),
  `:765-772` (the README snippet has exactly one `UserPromptSubmit` block).

### S-c4. The docs say "optional" and "off until approved". PARTLY
- **New text**: NPh line 805: "For now the hook is recommended, not required." NPh "Under trial":
  "System 1 is recommended, not required."
- **Build**: `README.md:25`: "Add the System 1 hook (optional)." `README.md:107`: "The install is
  manual. It is off until the question set is approved." `s1/README.md:37`: "**Status: Ty has not
  approved the question set yet (u44).**" `CHANGELOG.md:26`: "It is optional."
  "Optional" agrees with Ty's "optional for now". "Off until ... approved" does not: no code turns
  the hook off (`s1/hook.py` runs whenever the snippet is installed), and Ty's "need the hook"
  reads as use it now.
- **Kind**: stale words.
- **Smallest change**: `README.md:25,107` and `s1/README.md:37`: say "recommended, not required",
  and drop "off until". Keep the word "optional" in "Use it" or change the test with it.
- **Size**: S.
- **What holds the old behavior**: `kb/tests/test_release.sh:25-26` (needs "optional" in "Use
  it"); `docs/check_consistency.py:131-132` (the `s1/` row must hold "manual" and "approved");
  `s1/test_hook.py:777-779` (`test_c5_not_approved_u44`: "u44" and "not approved").

### S-c5. Nothing records what the agent did with a hint. CONFIRMED
- **New text**: NP lines 307-309: "If you think that the hint is wrong, then you and System 1
  disagree, and you do not settle that alone. Say it to the human in one line and go on, or make
  the claim specific enough that a check or a query decides it, or both." NP line 291: "In a KB,
  record the signal there."
- **Build**: The line: `s1/README.md:26`: "System 1: work=build (0.83); divergence likely (0.85);
  effort significant (0.91): consider a shift up; formal tool: prolog (0.72)". Its content matches
  NP line 304-305 (kind of work, divergence or change of plan, effort, a formal tool).
  The log holds what System 1 answered and nothing about the agent: `s1/jev.py:122-123` (time,
  model, questions, state, answers, latency, usage, error) plus `session_id` and `transcript`
  (`s1/hook.py:269-270`). `orbit-kb` has no fact for a hint: no `s1_` or "System 1" in
  `kb/bin/orbit-kb`, `core.pl`, the modules, or the help. `jev.to_prolog` writes
  `s1_answer(Run, Qid, Type, Value, Label)` (`s1/jev.py:175-176`), but the hook never calls it.
  The status line does show the hint to the human: `s1/README.md:97`: "S1 build | div 0.85 | plan
  0.10 | eff 0.91 | tool lean". So the human can be the witness, when the segment is installed.
- **Kind**: gap.
- **Smallest change**: In the delivery field `Signals:`, NP already asks for "yes and what fired
  it". Add to the help one way to record a hint and its outcome in a KB (Ty: System 1 "might
  eventually get its own API's in the orbit-kb tool"). That part belongs to the orbit-kb auditor.
- **Size**: M.
- **What holds the old behavior**: none found for the record. The line format: `s1/test_hook.py:31-32`.

### S-c6. The hook is not in `install.py`, and no script writes `settings.json`. CONFIRMED
- **New text**: NPh lines 803-805: "The System 1 hook belongs here, not with the hub: it goes
  where the prompt goes."
- **Build**: `install.py:25-30` makes four links: `orbit-kb`, `repo-map`, `share/orbit-kb`, and
  `~/.claude/sagittarius -> prompt/`. No link to `s1/`. The hook is a pasted snippet with a
  hand-edited path: `s1/README.md:40`: "Install (Ty pastes this; no script installs it)", `:54`:
  "python3 /path/to/sagittarius/s1/hook.py". `README.md:26-27`: "No script writes that file.
  `install.py` never does." The hub kit does not mention the hook (grep `System 1|hook|s1` in
  `hubkit/hub/PRINCIPLES.md`, `HUB-CORE.md`, `hubkit/INSTRUCTIONS.md`, `hubkit/README.md`: no
  hit). So the coupling is right in the sense that the hub does not own it. It is weak in the
  sense that the hook does not "go where the prompt goes": the prompt has a stable installed
  path and the hook has none.
  The standing rule is kept: `settings.json` appears only in docs and tests.
- **Kind**: gap.
- **Smallest change**: Add a fifth link in `install.py` (for example `~/.claude/sagittarius-s1 ->
  s1/`), and use that path in the two snippets of `s1/README.md`. The paste stays a paste.
- **Size**: S to M.
- **What holds the old behavior**: `kb/tests/test_release.sh:40-42` (the four links), `:53-55`
  (`c2-no-settings-file`, `c2-install-no-settings-code`); `s1/test_hook.py:781-786`
  (`test_c5_installed_by_ty_not_a_script`); `docs/check_consistency.py:136-137` (the
  `/path/to/sagittarius` placeholder); `README.md:46` ("It makes four links").

### S-c7. The prompt has no install sequence of its own. CONFIRMED
- **New text**: Ty: "the system prompt should have its own installation sequence. Similar to how
  I use it with my .zsh aliases. An agent should probably help handle the setup of this." NPh
  lines 811-812: "the prompt must be true alone".
- **Build**: `install.py:29` links `~/.claude/sagittarius` to `prompt/`. `README.md:50-55` tells
  the user to run `claude --append-system-prompt "$(cat ~/.claude/sagittarius/SAGITTARIUS.md)"`.
  `README.md:57-58`: "wrap the command in a shell function or an alias. The author's `claude()`
  function in a `.zshenv` file is one example." That function is not in the repository.
  Is the installed prompt the same version as the checkout? Yes, by construction: it is a link to
  the working tree, and `install.py --check` tests the link target (`install.py:45,51-53`). No
  check tests that a session received the prompt. See S17 for what the link costs.
- **Kind**: gap.
- **Smallest change**: Write the sequence as a document that an agent follows, as the hub kit
  does (`hubkit/INSTRUCTIONS.md`): link, write the shell function for the user's shell, start one
  session, and ask it to name the version line of its prompt. Files: a new section of
  `README.md` or a short `prompt/INSTALL.md`.
- **Size**: M.
- **What holds the old behavior**: `kb/tests/test_release.sh:20-21` (`install.py` in "Use it"),
  `:35-42`.

### S-c8. The philosophy is not installed by `install.py`. The hub kit installs a digest of it. PARTLY
- **New text**: NPh line 14: "It is installed nowhere." Ty: "the philosophy should not be
  installed anywhere. It should just be reflected into the system prompt."
- **Build**: `install.py:25-30` links no file of `docs/`. But the old prompt points every
  session at it: `prompt/SAGITTARIUS.md:221`: "The reasons are in `docs/PHILOSOPHY.md`" (NP has no
  such line). And the hub kit ships `hubkit/hub/PRINCIPLES.md` into every hub:
  `hubkit/INSTRUCTIONS.md:35-36`: "`PRINCIPLES.md` states the Sagittarius philosophy in plain
  words, and `CLAUDE.md` imports it." `hubkit/hub/CLAUDE.md:8`: "@PRINCIPLES.md".
  `hubkit/hub/PRINCIPLES.md:4`: "Each names its source, a section of docs/PHILOSOPHY.md", for
  example `:10` "Source: docs/PHILOSOPHY.md, \"2. Alignment is the goal. A proof is one tool for
  it\"", a heading that NPh does not have.
- **Kind**: contradiction (for the hub kit), stale words (the section names). The hub kit
  auditor owns the fix.
- **Smallest change**: Ty decides if `PRINCIPLES.md` is "installed philosophy" or the informal
  edition's stand-in for the prompt. If it stays, its source lines need the new headings.
- **Size**: M.
- **What holds the old behavior**: `hubkit/UPGRADING.md:118-119` ("`grep -x @PRINCIPLES.md
  CLAUDE.md` prints it"); `hubkit/kit.json:5`; `docs/check_consistency.py:115-118` (the
  parenthesis after `docs/PHILOSOPHY.md` in the prompt must name a section).

### S-c9. `Hypothesis.lean` has no check and no home. CONFIRMED
- **New text**: NPh lines 563-565: "The Lean file `docs/philosophy-orbit/2026-11-11/fable/Hypothesis.lean`
  holds the definitions, and 68 theorems about them. The Lean kernel accepts each theorem, and
  none uses an axiom."
- **Build**: The file exists only on the branch. Read as text (not run): 68 `theorem` lines, 68
  `#print axioms` lines, no `import`, no `sorry`, no `axiom`. All 33 theorem names that NPh cites
  in that section exist in the file.
  Where checked Lean lives, and how it is checked:

  | Home | Check | Runs Lean? |
  |---|---|---|
  | `kb/tests/burn_model/` (a Lake project, no packages) | `check.sh:42` "heavy lake build"; `:45` "lake env lean Check.lean"; `:46-51` every `#print axioms` line must report, and only `propext`, `Classical.choice`, `Quot.sound` are allowed; `:54-56` conformance of the CLI; `:60-89` six mutants. Named in `README.md:128`. | Yes, by hand. |
  | `hubkit/proofs/ledger_guard/` | `lean_mutant_test.py:5` "runs `lake env lean` three times"; `:43-45` the statement is frozen word for word; `check_commands.py:6-8` compares names in the Lean file with `hubflow.py`. | Yes, by hand. No other file calls them. |
  | `kb/proofs/state_cache/`, `question_server/`, `project_archive/` (each a Lake project: `lakefile.toml`, `lean-toolchain` = `leanprover/lean4:v4.35.0`) | No script runs Lean on them. Tests read them as text or copy a table: `kb/tests/test_question_server.sh:461-462` ("copied from the #eval output"), `kb/tests/test_project_kb.sh:966-968` (two greps of the file). | No. |

  So the same standing takes two parts. (1) A script on the pattern of `check.sh:45-52`: run
  `lean Hypothesis.lean`, count the axiom reports against the `#print axioms` lines, and here
  allow no axiom at all. (2) A name check on the pattern of `check_commands.py`: each backticked
  theorem name in NPh "A properly written hypothesis" is a `theorem` of the file, and the number
  "68" in NPh equals the count.
- **Kind**: gap.
- **Smallest change**: Move the file to `docs/proofs/hypothesis/Hypothesis.lean` (or
  `kb/proofs/hypothesis/`), fix the path in NPh line 563, add the two checks, and name them in
  `README.md` "Tests".
- **Size**: M.
- **What holds the old behavior**: nothing holds the file today. That is the finding.

### S-c10. "Lean model" is in the top docs, the proofs, and the tool. CONFIRMED
- **New text**: NPh lines 499-500: "Lean is not a modeling language: a Lean file holds
  definitions, and theorems about them." NP line 373: "\"Proved in Lean\" is about the Lean
  definitions, not the code."
- **Build**: `s1/`: no use (there "model" means the System 1 model). `CLAUDE.md`: no use, apart
  from the directory name `kb/tests/burn_model`. `kb/proofs/*/README*`: no README exists.
  Uses in my area: `README.md:106` ("a Lean model of the burn rules"), `README.md:128` ("the Lean
  model of the burn rules"), `CHANGELOG.md:93` ("The Lean model's `done`"). Headers of the proof
  files: `kb/proofs/question_server/QuestionServer.lean:4-5` ("A model of `serve_route/5` ... The
  model is not the code"), `kb/proofs/project_archive/ProjectArchive.lean:4-5`,
  `kb/proofs/state_cache/StateCache.lean:4,28`, `hubkit/proofs/ledger_guard/LedgerGuard.lean:9`
  ("The model is one item"), `kb/tests/burn_model/check.sh:3,54` ("implementation model").
  Outside my area, for the count only: `kb/share/orbit-kb/help/build.txt` 4, `modules/build.pl`
  4, `kb/share/orbit-kb/README.md` 4, `kb/CONTRACT.md` 6, `kb/bin/orbit-kb` 2, three test files
  7, old `prompt/SAGITTARIUS.md:144` 1. Names that hold the word: the directory `burn_model`, the
  package `burn_model`, the library `BurnModel`, the predicate `model_calibrated`.
- **Kind**: stale words.
- **Smallest change**: Replace "Lean model" with "Lean definitions" in prose (`README.md`,
  `CHANGELOG.md` limits, the headers, the help). Leave the names of directories and libraries:
  a rename touches `CLAUDE.md:32`, `README.md:128`, `kb/CONTRACT.md:178`, and `check.sh`.
- **Size**: S for prose; L if the names change.
- **What holds the old behavior**: `kb/tests/test_project_kb.sh:835` (PT7 reads CONTRACT D27 for
  "the Lean model of done"); the messages of `modules/build.pl:41-42,121-122` if a test reads
  them (not checked).

### S-c11. Sagittarius states no version anywhere. CONFIRMED
- **New text**: NPh lines 819-820: "Each release of Sagittarius has a semantic version, and the
  prompt names its own version. Then a report from use can say what it ran." NP line 454: "It has
  no version number yet." NP line 444: "Follow the help of the version that is installed here".
- **Build**: `install.py`, `README.md`, `s1/hook.py`, `s1/statusline.py`: no version (grep). The
  only numbers: `s1/README.md:6` (`jev-1.14.0`, the vendor model), `hubkit/kit.json:2`
  ("0.5.1"), the `lakefile.toml` files ("0.1.0"). `kb/bin/orbit-kb` has no `--version` and no
  version string (grep). `CHANGELOG.md:3`: "## Redesign (informal release)", one entry. Tags:
  `v0.1.0-experiment` points at a83eca5 of 2026-07-01, the Workflow experiment era; `git
  describe` on main gives `thoughts-archive-432-g7124544`, so no version tag is an ancestor that
  describes main.
- **Kind**: gap.
- **Smallest change**: One `VERSION` file at the root; the last line of the prompt, `orbit-kb
  --version`, `install.py --check`, and the System 1 log line read it; `CHANGELOG.md` gets a
  heading per version. Pick a first number that cannot be confused with `v0.1.0-experiment`.
- **Size**: M.
- **What holds the old behavior**: `kb/tests/test_release.sh:76-80` (the changelog must hold a
  word list and "0.2.0"); `:59-73` (only the kit version is compared).

### S-c12. `temper.py` holds no recording for the hook's questions. PARTLY
- **Facts**: `s1/temper.py` does not read `s1/questions.json`. It asks its own three questions,
  `j_adds`, `j_contra`, `j_observable` (`s1/temper.py:52-54`), and one Sonnet judge
  (`:125-131`). Its recording is `s1/fixtures/loopcal_trio.json`: three items (c11, c12, c13) of
  the loyalty example, with the recorded answers to those three questions. So a change of the
  hook's question set needs no new recording for `temper.py`.
  The hook's questions have: `s1/fixtures/hook_responses.json`, whose comment says "Invented
  responses ... No real data" (it tests the format, not the questions); and a calibration that is
  not in `s1/`: `s1/README.md:37-38` ("the review session's calibrated set (22 of 25 known
  cases)"), `s1/test_hook.py:812-814` (points to `tmp/hub-design-kb/s1/hook_cal2_v2.py`; `tmp/` is
  git-ignored, `.gitignore:11`; not read). A change of `h_divergence` or a new question needs a
  new calibration run against the live model, and its cases have no tracked home.
- **Stale words**: `CHANGELOG.md:24`: "`s1/temper.py` tests the System 1 question set against
  recorded answers." It does not. `s1/README.md` has no section on `temper.py` or
  `measure_latency.py` (grep: 0 hits), and `CLAUDE.md:16` sends the reader there for it.
- **Kind**: gap (no tracked calibration set), stale words.
- **Size**: S for the words; M for a tracked set of cases.

---

## Own findings

### S13. The collapse judge of `temper.py` rejects the hypothesis that the new prompt calls "Fit"
- **New text**: NP lines 186-191: "Fit: \"The amount of a purchase and the member's tier on that
  day decide its points.\" ... The report says one thing more: \"some purchases get a different
  number today\". That is a finding about the system ... Keep it apart from the hypothesis. When
  the build is done, the finding is false, and the hypothesis still stands." NPh line 642: "def
  Collapsed (R : Req Case) : Prop := ∀ c, R c".
- **Build**: `s1/temper.py:129`: "false_if_correct: imagine a system that works correctly and
  has none of the problem in the report. Would the statement be false of that system?" and
  `:135` `collapsed = not d["false_if_correct"]`. So a hypothesis must be false of a correct
  system. That is the finding, not the law. The recording shows it:
  `s1/fixtures/loopcal_trio.json`, item c13, start statement: "The amount of a purchase and the
  member's tier on that day decide its points. Some purchases get a different number." (accepted,
  with the finding inside the statement); item c12, step 3: "Each member's points balance
  increases by exactly the number of points the loyalty rules assign to that purchase."
  (collapsed: true, though it names a wanted outcome that a case can refute).
- **Kind**: contradiction.
- **Smallest change**: For `--kind hypothesis`, judge collapse as the new definition does: is
  there a case that would refute the statement (the existing `j_contra` and `j_observable`
  already ask this, and `--kind requirement` already uses only them, `s1/temper.py:145-146`).
  Record new answers.
- **Size**: M.
- **What holds the old behavior**: `s1/test_temper.py:129-144` (C1Trio), `:375-393`
  (C1Recorded, the brackets of the recording), `:503-509`; `s1/TEMPER_LIVE_RUN.md`.

### S14. The line says "consider a shift up". The prompt says "treat that signal as fired"
- **New text**: NP lines 306-307.
- **Build**: `s1/hook.py:233`: `effort significant (...): consider a shift up`. Only the effort
  part carries an instruction. `:225`: "divergence or change of plan: check which (prompt rule)":
  the rule it means is now NP lines 337-338, and the line does not name it. Old prompt
  `prompt/SAGITTARIUS.md:116`: "A hint is not a decision: you weigh it, and you decide", the
  position that NP replaces with "you do not settle that alone".
- **Kind**: stale words.
- **Smallest change**: Drop ": consider a shift up" and "(prompt rule)" from `s1/hook.py`, or
  name the section. The prompt says what to do with a hint; the line should only report.
- **Size**: S.
- **What holds the old behavior**: `s1/test_hook.py:31-32`, `:541-544`, `:557-559`;
  `docs/check_words.py:81-82` (`s1/hook.py` must hold "effort").

### S15. The hook names a formal tool on a message with no signal
- **New text**: NPh lines 510-511: "System 1 and the agent can help to choose the lens, after a
  divergence is detected." NPh "How to judge a change" 5: "Does it add rigor before a signal".
- **Build**: `s1/hook.py:236-238` adds `formal tool: X` whenever P(choice) >= 0.5, whatever the
  other answers are. `s1/test_hook.py:561-565`: a line with no divergence, and "formal tool: z3
  (0.50)".
- **Kind**: gap.
- **Smallest change**: Print the tool only when the same line names a divergence, a change of
  plan, or effort, or when the choice is `lean` (a proof asked for).
- **Size**: S.
- **What holds the old behavior**: `s1/test_hook.py:551-555`, `:561-565`; `s1/statusline.py:131-133`.

### S16. `h_change_of_plan` folds two of the three cases into one
- **New text**: NP lines 326-335: a misread; "the human now wants a part of it changed"; "The new
  wish adds to the result and changes nothing in it. It is a new ticket".
- **Build**: `s1/questions.json:20`: "a new goal, a dropped part, or a new preference". "A new
  goal" can be a new ticket, and `:16` says a new request is not a divergence. No question tells
  "changes a part" from "stacks on top".
- **Kind**: gap.
- **Smallest change**: Decide if System 1 should help with the narrowing ("Kept: ... Changed:
  ..."). If yes, one more yes/no question; if no, say so in `s1/README.md`.
- **Size**: M (a new question needs a calibration run).
- **What holds the old behavior**: `s1/test_hook.py:833-836`.

### S17. The installed prompt is the working tree of one checkout
- **New text**: NPh lines 819-820 (a report from use can say what it ran). NPh "How to judge a
  change" 4 (a quiet failure).
- **Build**: `install.py:29` links `~/.claude/sagittarius` to `REPO / "prompt"`. On this machine:
  `/home/ty/.claude/sagittarius -> /home/ty/Projects/mine/sagittarius/prompt`. So every new
  session of every project gets the prompt of whatever branch that checkout holds, with
  uncommitted edits. A session that started earlier keeps the old text, and nothing in the text
  says which. The author's shell function (outside the repository; read, not copied) returns
  with no prompt when the file is not readable, and its comment says that sessions then start
  without it. Nothing tells the human or the agent.
- **Kind**: gap.
- **Smallest change**: With S-c11: the prompt ends with its version, and the install sequence
  (S-c7) ends with "ask the session for that line". Whether to install a copy of a release and
  not a link is Ty's decision.
- **Size**: M.
- **What holds the old behavior**: `kb/tests/test_release.sh:40-42` (a link, `-L`).

### S18. `install.py --check` fails on the author's machine, and `orbit-kb doctor` cannot see it
- **New text**: NPh "How to judge a change" 4.
- **Build**: `python3 -I install.py --check` here prints "missing /home/ty/.local/bin/repo-map"
  and exits 1. `CHANGELOG.md:23`: "`install.py` now links it". The install was not run again
  after that change. `README.md:21-22` pairs the two checks: "Check it with `orbit-kb doctor` and
  `./install.py --check`." `orbit-kb doctor` tests the Prolog engine only
  (`kb/bin/orbit-kb:7676-7727`); it reads no link.
- **Kind**: gap.
- **Smallest change**: `README.md` and `CHANGELOG.md`: each release that adds a link says "run
  `./install.py` again". With S-c11, `install.py --check` can print the version it checks.
- **Size**: S.
- **What holds the old behavior**: none.

### S19. Every prompt is judged as the human's message
- **New text**: NP lines 265-266: "A message from a peer session and a compaction summary are
  handoffs." NP lines 303-304: a line of hints comes "with a message of the human".
- **Build**: `s1/hook.py:106`: `role = "agent" if kind == "assistant" else "you"`. `:87` filters
  only `isSidechain` and `isMeta`. The questions say "the newest message" and assume its writer
  is the human (`s1/questions.json:24`: "significant effort by its writer"). A long message of a
  peer session would read as effort of the human.
  Not checked: how the harness writes a peer message or a compaction summary into the
  transcript.
- **Kind**: gap.
- **Smallest change**: A sentence in `s1/README.md` now. Later, with S-c3.
- **Size**: S.
- **What holds the old behavior**: `s1/test_hook.py:359-366`.

### S20. `README.md` describes the old method
- **New text**: NP line 274: "Every signal gets the same response". NP lines 293-294: "A count of
  signals does not choose the third level. The claim does." NPh line 14-16: the prompt "reflects"
  the philosophy. NPh lines 801-809 (two interfaces; "MindHole").
- **Build**: `README.md:7-9`: "the agent adds rigor one step at a time: a knowledge base (KB) of
  claims and questions, more rounds of questions, and, for a claim about every case, a Lean
  proof" (a ladder). `README.md:33`: "It states the philosophy in short". `README.md:18,23`:
  "Use it" starts a hub as step 2 of one path; the name MindHole is not in the file (grep).
  `README.md:64`: "New work starts in review" (the panes; another auditor).
- **Kind**: stale words.
- **Smallest change**: Rewrite the first two paragraphs and "Use it" around the two interfaces.
- **Size**: S.
- **What holds the old behavior**: `kb/tests/test_release.sh:18-29`; `docs/check_words.py:184`
  (c3 reads the position sentence in `README.md`); `docs/check_consistency.py:123-132`.

### S21. `repo-map` has no place in the new texts
- **New text**: NPh line 803: "**Sagittarius:** the system prompt and `orbit-kb`." NP "The tool"
  names only `orbit-kb`. Neither text names `repo-map` (grep).
- **Build**: `install.py:27` links it as part of Sagittarius. It reads the `kb.pl` of a project
  KB (`kb/share/repo-map/README.md:33`), a store of the hub. The old prompt names it
  (`prompt/SAGITTARIUS.md:219-220`: "the repo map is `kb/bin/repo-map`"); NP dropped that line.
  `kb/share/repo-map/sagittarius.containers.pl:17`: "docs/: the philosophy and the eval refining
  loop", `:33`: `link(docs, prompt, 'explains')`.
- **Kind**: gap (which interface owns it is not said). No rule of the new texts conflicts with it.
- **Smallest change**: One sentence in `README.md` or the hub guidance that says who uses it.
- **Size**: S.
- **What holds the old behavior**: `kb/tests/test_release.sh:40,45-49`; `kb/tests/test_repo_map.sh`.

### S22. The proofs under `kb/proofs/` can go stale with no signal
- **New text**: NPh principle 9: "A file that changed can show that evidence is stale." NP line
  372-373: "\"Stated in Lean\" does not mean \"proved\"."
- **Build**: See the table in S-c9: no script runs Lean on `kb/proofs/state_cache`,
  `question_server`, or `project_archive`. `kb/tests/test_question_server.sh:461-462` tests the
  server against a table "copied from the #eval output": if the Lean file changes, the copy does
  not. `README.md:124-129` ("Tests") names only `burn_model/check.sh`.
- **Kind**: gap.
- **Smallest change**: One script that runs `lake build` in each of the three folders and prints
  the axioms, on the pattern of `kb/tests/burn_model/check.sh:42-52`; name it in `README.md`.
- **Size**: M.
- **What holds the old behavior**: none.

---

## Suggestions beyond alignment

1. **One check for every Lean home.** Problem: five Lean homes, three ways to check, two of them
   by hand and one not at all (S-c9, S22). Evidence: the table in S-c9. A single
   `kb/tests/check_lean.sh` that walks a list of folders would also give `Hypothesis.lean` its
   standing for free.
2. **Keep the hint in front of the human for the whole turn.** Problem: the human is the
   witness of a hint, but the segment hides after 10 minutes and shows nothing when every answer
   is unsure. Evidence: `s1/statusline.py:35` (`STALE_SECONDS = 600`), `:118-119`, `:134`. A long
   turn is the time when a missed signal costs most. Show "S1 unsure" and "S1 off", and age the
   segment by turn, not by clock.
3. **A tracked calibration set for the hook's questions.** Problem: the 25 known cases live in
   a git-ignored folder, so a change of a question cannot be judged by a second person or a later
   session (S-c12). Evidence: `s1/README.md:37-38`, `s1/test_hook.py:812-814`, `.gitignore:11`.
   NPh principle 14 asks for a tuning set and a separate deciding set.
4. **Log the version and the question-set digest in each System 1 line.** Problem: the log is
   the only record of what System 1 said, and a line does not say which questions it answered
   (only their ids, `s1/jev.py:122`). Evidence: `s1/test_hook.py:859-861` pins the words in a
   test, not in the record.
5. **Count disagreements.** Problem: NPh "Under trial" says what would show the System 1
   positions wrong ("System 1 names so many false signals that these lines become noise";
   "Sessions without it miss signals"). Nothing counts either. Evidence: S-c5. A small reader of
   `s1.jsonl` beside the delivery field `Signals:` would give Ty the numbers for that trial.
6. **Use `temper.py` on the prompt's own examples.** Problem: the prompt's two worked examples
   (loyalty points, dark mode) and the Lean file's verdicts on them are not compared with the
   tool that tempers hypotheses. Evidence: S13 shows that they disagree today on the loyalty
   example. After S13, the three sources (prompt, Lean file, temper) can be held to one table.
7. **Document `temper.py` and `measure_latency.py`** in `s1/README.md`. Evidence: 0 mentions;
   `CLAUDE.md:16` points there.

---

## Where the build already agrees

- **No script writes `settings.json`.** `kb/tests/test_release.sh:53-55`,
  `s1/test_hook.py:781-786`, `README.md:26-27`.
- **The hook never blocks a prompt** and never raises (`s1/hook.py:250-252`, `:330-341`). The
  prompt is "true alone ... when System 1 is silent" (NPh line 812) as far as the hook goes.
- **The line's content** (kind of work, divergence or change of plan, effort, a formal tool)
  matches NP lines 304-305. The four tool options match NP's three kinds of formal statement
  plus the KB (`s1/questions.json:30-33`; NP lines 286-289).
- **"Divergence or change of plan: check which"** (`s1/hook.py:224-225`) matches NP lines
  337-338: "If you cannot tell whether you misread or the intent moved, do not guess."
- **The human can see the hint**, and a failure shows as "S1 err" (`s1/statusline.py:121-122`).
- **System 1 judges, and never builds.** In `temper.py` proposers never judge
  (`s1/temper.py:10-15`; `s1/test_temper.py:250-295`): NPh principle 4. An unsure verdict goes to
  the human (`s1/temper.py:235-236`, `to_ty`): NP lines 307-309.
- **The hub kit does not own the hook** (no mention in `hubkit/`): Ty's coupling decision.
- **The Lean headers say what they do not cover** ("The model is not the code",
  `QuestionServer.lean:5`; "The proof does not cover the walk", `ProjectArchive.lean:16`): NPh
  principle 9. Only the word "model" is off.
- **`burn_model/check.sh` audits axioms by `#print axioms`**, not by a grep of the build log
  (`check.sh:45-52`).
- **`Hypothesis.lean` and NPh agree** on the count (68) and on every cited theorem name (text
  check only).

---

## Unclear, and one incident

- Not checked: the hook events of the installed Claude Code version (S-c3); the transcript
  shape of a compaction summary and of a peer message (S19); whether a test reads the messages
  of `modules/build.pl` (S-c10); the calibration files under `tmp/hub-design-kb/s1/` (outside my
  read list).
- Unclear in the texts: is a request, as "the first divergence", something System 1 should
  report (S-c1)? Is the hub's `PRINCIPLES.md` an installed philosophy (S-c8)?
- **Incident.** While I checked how the shell function loads the prompt, one of my greps
  printed line 24 of `/home/ty/.zshenv` into my session transcript. That line exports the System
  1 API key, and my mask did not cover its shape. I did not use the value, and it is not in this
  report or in any scratch file. Ty may want to rotate that key.

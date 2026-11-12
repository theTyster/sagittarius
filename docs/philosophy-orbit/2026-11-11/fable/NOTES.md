# Notes of the Fable session (2026-11-11)

These notes carry the work across a compaction. Read them first. Then read the KB:
`orbit-kb --dir /home/ty/Projects/mine/sagittarius/tmp/philosophy-orbit/kb query 'proposed(X)' -n 0`,
and the `ty_*` decisions in its `kb.pl`. The KB holds Ty's words. These notes hold the state
and the plan.

## 0. Status on 2026-11-12, 03:20 UTC (read this first; it is newer than section 1)

Ty ruled at 03:04 UTC: "your defaults are good." "Alignment is good too." Ty ruled on
suggestions 1 to 6, said "we will be using this finalized version", and asked for three things:
keep the versions of the three models in `docs/` with an account; one spec KB for the
decisions of this session; and "prepare to pass everything off to the build orbit. I'll have
you do one more thing before we finally pass it off." The whole message is the request `r1`
of the spec KB.

Done:

- **The version in use** is commit `99bf5c2` on this branch. That commit is Ty's own edits to
  `docs/PHILOSOPHY.md` ("the author" became "Ty"; the second failure under principle 5 was
  reworded). Fable found them uncommitted in the worktree and committed them as they were.
  The first lines of the philosophy still say "Proposed": Ty edited those lines and kept the
  word, so Fable did not change it.
- **The archive:** `docs/philosophy-orbit/2026-11-11/README.md` (the account, with no opinion
  on any model's work), `mythos/` and `astra/` (byte-for-byte copies of the two documents of
  each), commit `700fd4f`. `fable/Hypothesis.lean` is logged there.
- **The spec KB:** `/home/ty/Projects/mine/sagittarius/tmp/kb-sagittarius-030` (modules
  discovery and project). One hypothesis `h1` with four premises (`a1` to `a4`), 31 claims
  (`c_k_a` ... `c_sg5`), each with an example and a check that is red on `main`
  (`checks/check.py`, runs 1 to 31), Ty's answers to `q1` to `q3`, one dormant question `q4`,
  scope, six risks. Each package claim pins its ratified decision in `tmp/alignment-kb`.
  `discovery_ready` is true and lint is clean. `TICKET.md` there is the draft of the ticket,
  with a section for the build orbit.
- `ALIGNMENT.md` and `SUGGESTIONS.md` record Ty's rulings.

Not done, on purpose: no vote is sealed or asked (Ty has one more thing first); `uses build`
is not run; nothing is landed on `main`; no build work started.

After Ty's "one more thing": seal the vote (`orbit-kb attest vote r1 'vote(1, ...)'`), give
the report and ask "Vote GO, NO-GO, or HOLD."; on GO: `orbit-kb subject tk TICKET.md`,
`add "ticket(tk)"`, `attest approval tk 'digest(current)' --by human`, `uses build`, `lint`,
`release`, and hand the KB path to the build orbit.

A guess to confirm with Ty: "that one" in the answer to suggestions 1 and 2 is
`tmp/hub-design-kb` (`q4`, `a4`).

## 1. Status

The final revision of `prompt/SAGITTARIUS.md` and `docs/PHILOSOPHY.md` is done and committed
on this branch. Ty reviews it in the morning of 2026-11-12, with the Lean file. Nothing is
pushed, installed or merged. `main` is not touched.

On 2026-11-12 00:25 UTC Ty started the next step (section 2, the last instruction):

1. Versions are in the files (commit `979dff7`): Sagittarius 0.3.0, Philosophy 2.0.0, and the
   hub kit stays 0.5.1. Fable chose the numbers. Ty has not seen them yet.
2. The analysis is done and waits for Ty: `ALIGNMENT.md` (86 findings in 27 work packages,
   three questions for Ty, the defaults that Fable took, a proposed order) and `SUGGESTIONS.md`
   (33 improvements beyond alignment; Ty reviews them before a spec KB is made for any of
   them), both in this folder. The four audit reports and their brief are in `audit/`. Its KB:
   `/home/ty/Projects/mine/sagittarius/tmp/alignment-kb` (project module; the request is Ty's
   words; each finding is a `definition` `b_<id>`, each work package a proposed `decision`
   `wp_<area>_<letter>`; copies of the reports are in its `analyses/`). Section 7 of these
   notes was the list of leads for it: `ALIGNMENT.md` supersedes that section.
   An incident: the System 1 audit agent printed line 24 of `~/.zshenv` (the System 1 API key)
   into its own transcript. Fable told Ty. Nothing was deleted.
3. Subagents begin the build work only after Ty checks the analysis.
4. Ty reviews the Lean definition in the morning of 2026-11-12.

## 2. The instructions (Ty, word for word)

2026-11-11 23:25 UTC (`ty_final_pass_20261111`):

> I'm going to compact this session, then I want you to make one more revision on your version
> of sagittarius and the philosophies. As a final piece you should identify any needed changes
> to the existing sagittarius tools whether orbit-kb, the mindhole, the suggested languages, or
> anything else. On this pass, try to cut out the fat and give the system prompt a version that
> can converge well on everything that we've been circling today without being overly verbose.
> When it's done commit your work. I'll review it in the morning.

2026-11-11 23:37 UTC (`ty_final_revision_20261111`):

> Make the final revision of the prompt and philosophy files. It's quite alright if they are
> longer than they were before. I care about clarity. Length can be an inhibitor for clarity
> with humans, but a reinforcer with agents. I have every confidence that you'll produce files
> that properly converge on the intent behind Sagittarius.
>
> Once you're done, stop. I may compact again before you create an analysis showing what might
> need to change in order for this build to come into alignment with the new prompt and
> philosophies (if any). The final thing after that analysis will be to launch some subagents
> to begin working on it. But, I need to check first.

2026-11-11 23:37 UTC (`ty_drop_p_marks`):

> This time around you can drop all the (P) stuff. I'll review the finished product myself
> tomorrow morning with the Lean.

2026-11-12 00:25 UTC (`ty_tests_are_artifacts`, `ty_likes_contested_twice_and_fields`,
`ty_add_versions`, `ty_alignment_analysis`):

> On the previous points you stated, I need to rule on whether it's okay to allow artifacts to
> continue to be a third voter, keeping in mind that tests count as artifacts. Any test of any
> kind counts as an artifact. I like the twice-contested claim rule and the fields you added.
>
> Go ahead and add a version to Sagittarius philosophies and the mind hole. We'll be using all
> these things. I'll review the Lean definition in the morning for the properly formed and
> properly written hypothesis definition.
>
> Next let's analyze what else in the project needs to change to come into alignment with
> these documents that we've made. start a KB if there are any.You're doing a pretty good job
> here so I'll also give you license to suggest any other improvements that might be good for
> the project while you're working through this analysis. Put all those suggestions in their
> own Markdown document for now. I'll review them before suggesting a spec KB for the
> individual changes you suggest. First and foremost though, let's identify areas where the
> Mindhole and Orbit KB, and any other tools, could improve to come into better alignment with
> the philosophies of the project.

## 3. Where everything is

- Worktree: `/home/ty/Projects/mine/wt/sagittarius/philosophy-fable`, branch
  `philosophy-orbit/fable-2026-11-11`, from `main` at `7124544`.
- Commits on the branch: the checkpoint `61f49f1` (the second draft, which Ty and Astra read),
  and the final revision after it. `git diff 61f49f1 HEAD` shows what the last pass changed.
- The two files: `prompt/SAGITTARIUS.md` (454 lines) and `docs/PHILOSOPHY.md` (864 lines).
- The Lean file: `docs/philosophy-orbit/2026-11-11/fable/Hypothesis.lean` (68 theorems, no
  imports). Check it with `lean Hypothesis.lean` in its folder. It prints one line for each
  theorem, and each line must say "does not depend on any axioms". Nothing else must print.
- Astra's last review, word for word: `astra-final-thoughts.md` in this folder.
- Astra's work: branch `philosophy-orbit/2026-11-11`, worktree
  `/home/ty/Projects/mine/sagittarius/tmp/philosophy-orbit/worktree`, commit `67b8b3e`. Useful
  there: `docs/REWORK-PLAN.md` (a plan for the tools, from a source audit),
  `docs/philosophy-orbit/2026-11-11/FABLE-REVIEW.md`, `FableReview.lean`.
- The review session's work (Mythos): branch `philosophy-orbit/mythos-2026-11-11`.
- The shared KB: `/home/ty/Projects/mine/sagittarius/tmp/philosophy-orbit/kb` (project module).

## 4. What Ty decided on 2026-11-11 (each is in the KB, word for word, under its id)

| KB id | In short | In the files |
|---|---|---|
| `ty_full_rework_20261111` | A larger prompt is fine. Rework everything. Get creative. | the whole rework |
| `ty_s1_agent_disagree` | When System 1 and the agent disagree, it goes to a formalism, or to the human, or both. | principle 4; prompt "One response" (System 1) |
| `ty_every_ticket_hypothesis` | Every ticket has a hypothesis. It is wide on purpose, so that a wrong default shows. Ty's dark-mode sentence. | principle 2; prompt "The light path" step 1, "The hypothesis" |
| `ty_liked_then_change` | Liked, then changed: narrow down what was liked and what was disliked. A change that stacks on top is a new ticket. | principle 3; prompt "When the human says that it is wrong" |
| `ty_fence_slowdown` | Ty's worry: more process for every change request. | principle 10; "Under trial" |
| `ty_typo_no_kb_drafts_agreed` | A typo never needs a KB. A ticket starts in words, and a KB starts on a signal. A clear change of the hypothesis stays in build. | principles 2 and 10 |
| `ty_suite_c` | The whole suite after the change. Before the change only when no green run at that base is known. | prompt "The light path", steps 3 and 6 |
| `ty_final_pass_20261111`, `ty_final_revision_20261111`, `ty_drop_p_marks` | Section 2 of these notes. | this pass |

Earlier on the same day (from the review session's handoff, also in the KB): `ty_two_interfaces`,
`ty_hooks_with_sagittarius`, `ty_s1_detects`, `ty_one_response`, `ty_new_work_is_divergence`,
`ty_intent_is_discovered`, `ty_rungs`, `ty_philosophy_not_installed`, `ty_s1_optional_for_now`,
`ty_prompt_install`, `ty_hypothesis_is_attempt`, `ty_lean_right_grain`, `ty_semver`,
`ty_back_to_discovery`, `ty_clarity_not_size`, `ty_one_lens`, and the report
`ty_sees_no_formal_text`.

## 5. What the final revision changed

The marks are gone: no **(P)**, no reviewer credits, no draft note in the prompt. The whole
text is still a proposal until Ty ratifies it (the first lines of the philosophy say so).
Section 6 of these notes lists what Ty has not ruled on.

Astra's three last concerns (`astra-final-thoughts.md`), and what the files say now:

1. **"Guess" had two meanings.** Now two words stay apart, in all three files.
   - **Guess** (prompt, philosophy): something that the agent assumed and that nobody
     confirmed. A default about what the human wants is a guess about the intent. A premise
     that nobody checked is a guess about the system. In the Lean file: what a statement says
     about a case that nobody has judged (`Unjudged`).
   - **Held** (philosophy, Lean): the statement needs the word. It is not a confirmation. A
     claim is held because the human supports it (`ClaimSupported`), or because it is the core
     of the attempt (`ClaimIsCore`), or both (`claim_held_two_ways`).
   - New theorems: `proper_with_no_judgments` (held is not confirmed), `fits_ignores_unjudged`
     (the judgments do not test a guess), `wide_guesses_the_scope`, `narrow_guesses_the_scope`,
     `fit_claim_supported`. Renamed: `scope_was_a_guess` to `scope_not_held_at_first`,
     `keepsLight_was_a_guess` to `keepsLight_not_held_at_first`, `claim_held_by_unwanted_case`
     to `claim_held_two_ways`.
   - The prompt's dark-mode example now matches the Lean file: the fit sentence has no clause
     about dark mode off, and it has "Premises: none".
2. **The vote of the artifacts with no KB.** It is a readiness rule now, with the same shape
   as `artifact_vote/1` and `discovery_ready` in `kb/share/orbit-kb/modules/discovery.pl`
   (lines 315 to 337): HOLD until discovery is ready; then GO if a claim stands, and NO-GO if
   none does. The prompt lists three conditions of readiness. The tool has more (weak rules,
   model problems, a supersession that no human ratified).
3. **"A divergence shows that an attempt is wrong" was too wide.** Now: a divergence shows that
   two views do not line up. It does not say why. An attempt can be wrong, the intent can have
   moved, or the two views are about different cases. To get more specific says which.

Other changes of this pass:

- The rule for premises: keep a premise only when the request gives it, or when the sentence
  is false without it. Outside a premise the hypothesis says nothing, so a premise that nobody
  gave hides a wrong default. This is the reason to write wide.
- The prompt names three commands again where the meaning needs them: `orbit-kb show open`,
  `orbit-kb report`, `orbit-kb whynot 'discovery_ready'`. It also names `--by human` and
  `orbit-kb prove` in honesty rule 5, as the live prompt does.
- One rule is new in the prompt ("Delivery"): an outcome that must outlive its ticket gets a
  test in the project's suite, and a rule in the project's record when there is one. The agent
  proposes the rule, and a human ratifies it. It was in the philosophy already (principle 3).
- "Known limits" and "Where the earlier text went" left the philosophy. They are in sections 7
  and 8 of these notes.
- The Lean file prints the axioms of every theorem now (68 lines), not of 37.

Checks that this pass ran:

- `lean Hypothesis.lean`: exit 0, 68 lines "does not depend on any axioms", nothing else.
- Every theorem name in the philosophy exists in the Lean file. Every definition in the Lean
  block of the philosophy is in the file, with the same code. Every section of the prompt that
  the philosophy cites exists.
- `python3 evals/check_leaks.py 7124544 -- prompt/SAGITTARIUS.md`: one overlap, with eval 1
  ("on the light path"). It is old: the live prompt has that phrase. No overlap with a
  held-out case.
- No eval ran on this prompt. Nobody but Fable has read the final revision.

## 6. Defaults of Fable: what Ty ruled on 2026-11-12, and what is open

Ruled: points 2 and 3 stand ("I like the twice-contested claim rule and the fields you
added."). Point 4 is done (the versions). Open: point 1 (Ty: "I need to rule on whether it's
okay to allow artifacts to continue to be a third voter, keeping in mind that tests count as
artifacts."), and point 5 (Ty reads the Lean definition in the morning). In point 2, which
language a twice-contested claim goes to (Lean in the tool, "the language that fits" in the
files) is not settled by Ty's words: it is a question in the analysis.

1. **The vote of the artifacts with no KB** (section 5, point 2). Astra would drop that ballot
   when there is no KB: then the human and the agent can concur. The files keep three voters
   and give the artifacts the readiness rule.
2. **A claim that is contested twice.** The tool makes it burn: it then needs a proof in Lean
   (`burn_reason(C) :- contested_twice(C), not visual(C).`, `modules/build.pl`, line 211). The
   files say: a claim that words and records did not settle goes to a formal statement "in the
   language that fits that claim". So the files agree with the tool on when, and not fully on
   which language. Astra's plan drops the tool's rule.
3. **The name of the field in the delivery:** `Signals:` (the files) or `Triggers:` (the live
   prompt). Only `docs/check_consistency.py` (c1) and `docs/PROMPT-MOVES.md` read the old
   name. The files also add the field `Formal:`.
4. **A version number.** The last line of the prompt says: "This is the Sagittarius draft of
   2026-11-11. It has no version number yet." Ty wants semantic versions (`ty_semver`).
5. **`fb_properly_written` in the KB** is still a proposal: the definition in the Lean file.

## 7. For the analysis: where the build may differ from the new files

Check each one in the source before it goes into the analysis. "Seen" means that this session
read the rule or the help. The others come from Astra's plan or from the review session's
tests.

`orbit-kb`:

1. A hypothesis fact outside discovery. Today `hypothesis/3` is in the discovery module only
   (seen: `orbit-kb help discovery`, `help core`). A direct build that shifts up has no place
   for its hypothesis.
2. The wanted outcome apart from the finding "the system falls short". Today the SIGNAL recipe
   writes them as one hypothesis with one falsifier (seen: `help discovery`).
3. A premise fact. Today premises go into a `note` (the draft issue `tmp/issues/6-premises.md`
   in the main checkout).
4. One command for the step from words to records (the review session's proposal
   `rv_shift_is_one_command`; step 3 of Astra's plan). Ty: the step is rare. So it must be easy.
   Today it costs several commands and a long read of the help. At that same moment, "you're
   right" and a fast fix cost nothing.
5. The vote and readiness: `gate(C) :- human_vote(C), agent_vote(C).` wins with no
   `discovery_ready` (seen: `modules/discovery.pl`, line 320). The prompt says: what blocks
   readiness blocks GO.
6. Calibration: `model_calibrated(M) :- model_calibration(_, M, matches).` One matching case is
   enough, and a derived model inherits it (seen: the same file, lines 220 and 235). The files
   ask for a real failing case and a real passing case.
7. `orbit-kb report` shows no formal statement beside a plain claim (seen in one real report).
   `orbit-kb prove` prints the statement of the theorem (seen: `help build`). The delivery has
   a `Formal:` field now, and the name `Signals:`.
8. Who made a relation: `excludes/2` and `depends_on/2` by an agent read like facts (the case of
   2026-11-11). The tool records who made a decision, and not who made a relation.
9. The rule "contested twice needs a proof" (section 6, point 2).
10. A change of the hypothesis in build: `supersedes` for hypotheses is a discovery fact today.
    The BACK recipe of `help discovery` and step 3 of "When the human says it is wrong" in `help
    build` send a wrong problem to discovery. The files: only when the agent can no longer say
    what to change.
11. A record for a hint of System 1 and what the agent did with it (Ty: System 1 "might
    eventually get its own API's in the orbit-kb tool").
12. Pins and proofs: a rule cannot rest on a file pin; a stale pin is quiet in the spec KBs;
    nothing reopens a proof when the code changes, and a change of the Lean files does (the
    review session's tests; not repeated). `orbit-kb pin` stamps the whole of `kb.pl` (seen:
    `orbit-kb help pin`). It does not cover the artifacts that the KB names.
13. The words of the help: "Lean model" (Ty: Lean is not a modeling language); the example of a
    hypothesis; the names of the sections of the prompt that the help cites ("The phase tree",
    "When to shift up", "Honesty rules", "Where the procedure is" are gone or renamed).
14. Guesses: `assumed/2`, `answer/3` and the "Guesses" part of the report exist. The files add
    a premise that nobody checked as a guess about the system.

System 1 (`s1/`):

15. `questions.json`: `h_divergence` says that a new request and a change of preference do not
    count (seen). The files count a request as the first divergence of its ticket.
    `h_change_of_plan` exists.
16. The hook prints nothing when it is unsure and nothing when it fails (seen: `s1/hook.py`).
    The agent cannot tell these from "no signal". The prompt says: no line means no outside
    view.
17. The hook runs only on a message of the human (seen). A signal inside a turn has no outside
    witness. The spoken line of the agent is all that there is.
18. Its status: "off until the question set is approved" (`README.md`, `s1/README.md`). The
    files: recommended, not required.

The MindHole (`hubkit/`, `prompt/PANES.md`, `prompt/panes/*.md`):

19. The pane prompts cite "The phase tree" of the Sagittarius prompt, and they route a wrong
    problem back to discovery (seen: `prompt/panes/build.md`, `discovery.md`).
20. The hub lines left the prompt (`hubflow`, the inbox, `HUB-CORE.md`). `PANES.md` has the
    handoff procedure already (seen). The checks `check_hub_guidance.py` c5 and c9 and
    `check_hub_fixes.py` t31c4 read those lines in the prompt.
21. A hub session starts with `claude --name` and gets the prompt only from the user's alias
    (the review session's handoff; `hubkit/INSTRUCTIONS.md`, step 5).

The formal languages:

22. One lens at a time against SPECTRUM step 4 (TLA+ and SMT for one claim at once) (seen:
    `help discovery`).
23. A home for `Hypothesis.lean`: today it is a single file with no imports, in a folder of
    drafts. A check like `kb/tests/burn_model/check.sh` can run it.
24. A proof in Lean for a twice-contested claim of any shape (point 9), against "the language
    that fits the claim".

Anything else:

25. The checks in `docs/` that hold the old shape of the prompt. None was changed. Seen on this
    branch: `check_prompt_small.py` c1 fails (454 lines against a limit of 230; the headings
    "Roles", "The phase tree", "When to shift up" and "Honesty rules" are gone; the five
    `orbit-kb help TOPIC` names are gone), and its c3 finds 10 of the 18 old honesty and
    delivery rules word for word (the other 8 are reworded). `check_consistency.py` and
    `check_words.py` stop with "substring not found" (a heading that they look for is gone).
    `check_prompt_moves.py` c4 has 4 missing rows. `check_panes.py` passes. The other checks
    need a claim id and were not run.
26. `README.md` says that the prompt "states the philosophy in short". `CLAUDE.md` is the map of
    the files, and it names the prompt and the philosophy.
27. Versions: Ty wants semantic versions (`ty_semver`). `CHANGELOG.md` has an entry "Redesign
    (informal release)". The hub kit is 0.5.1 (`hubkit/kit.json`). The prompt names no version.
28. The install of the prompt (`ty_prompt_install`): its own sequence, with an agent's help; no
    script writes `settings.json`.
29. The evals: `evals/grade_tools.py` reads the `KB:` line of the delivery (seen). That line is
    as it was. The evals that read other fields of the delivery are not checked yet.
30. `docs/REFINING.md` and `docs/PROMPT-MOVES.md` name sections and rules of the old prompt.

## 8. Where the earlier text went

The philosophy supersedes the text of 2026-11-05 (14 principles and six open questions). It
does not erase it: `git log -- docs/PHILOSOPHY.md` has it.

| Earlier | Now |
|---|---|
| Principles 1 and 2 | Principle 1 |
| Principle 3 | Principles 4 and 6, and "The center" (parallax) |
| Principle 4 | "The orbit", and principle 5 |
| Principle 5 | Principle 2, and "A properly written hypothesis" |
| Principle 6 | Principle 8 |
| Principle 7 | Principle 10, "The bet" (the tiers), and "The orbit" (the two levels) |
| Principle 8 | Principle 12 |
| Principle 9 | Principle 9 |
| Principle 10 | Principle 7 |
| Principle 11 | Principle 11 |
| Principle 12 | Principle 3, and "Where Sagittarius sits" (the job of the prompt) |
| Principles 13 and 14 | Principles 13 and 14 |
| Question A (the hypothesis) | "A properly written hypothesis" |
| Question B (back to discovery) | Principle 2; under trial |
| Question C (across tickets) | Principle 3 (a home that outlives the ticket); section 7, point 12 |
| Question D (a proof and the code) | Principle 9; section 7, point 12 |
| Question E (sizes as tiers) | Principle 10: clarity decides |
| Question F (one language at a time) | Principles 11 and 9 |

Where the new positions came from (the philosophy does not mark them any more):

- Fable: the one hypothesis of Sagittarius with its five premises; the three steps of the
  orbit; the three levels of statement; the image of Sagittarius A*; the definition in Lean;
  "a ticket starts in words, and records start on a signal" and "a clear change of the
  hypothesis stays in build" (Ty agreed to both on 2026-11-11).
- The review session (Mythos): the two falsifiers with their two witnesses; a signal that
  someone saw and did not say is quiet; a request is the first divergence of its ticket.
- The review session and Astra, each in their own words: the limit of "impartial" (the
  machine checks what follows, and not which statement was written).
- Astra: the wanted outcome apart from the finding of a defect; a result can challenge a
  premise, the build, or the reading of the intent; the check comes from the request and not
  from the build; point 2 of the definition ("it can hold"); "properly written" is not unique;
  the split of "held" and "guess"; the readiness rule for the vote of the artifacts; the
  three reasons for a divergence.

## 9. Rules for this job

- Use absolute paths and `git -C`. Do not `cd` into another agent's worktree.
- The KB has one writer. Write with `ORBIT_KB_WRITER=fable ORBIT_KB_ROLE=discovery`, and run
  `orbit-kb --dir ... release` after. Astra may hold the lock: a lease lapses after 30 minutes.
- Do not read a held-out eval. `python3 evals/check_leaks.py` (run in the worktree) may print a
  phrase of one: print only its id.
- Quote Ty word for word, or do not use quote marks.
- Check before you claim. Ty caught the review session on a claim that it had not checked.
- Each question to Ty carries its case, its options, what each option changes, and a default.
- `docs/PHILOSOPHY.md` and `prompt/SAGITTARIUS.md` are Ty's. Agents propose words.
- No push, no merge, no install, and no change to `main`, unless Ty says so.

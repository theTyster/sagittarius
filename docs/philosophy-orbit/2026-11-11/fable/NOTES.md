# Notes for the final pass (Fable, 2026-11-11)

These notes carry the work across a compaction of the Fable session. Read them first. Then read
the KB: `orbit-kb --dir /home/ty/Projects/mine/sagittarius/tmp/philosophy-orbit/kb query 'proposed(X)' -n 0`,
and the `ty_*` decisions in its `kb.pl`. The KB holds Ty's words. These notes hold the plan.

## 1. The task (Ty, 2026-11-11 23:25 UTC, word for word)

> Yeah. I'd go with (c).
>
> I'm going to compact this session, then I want you to make one more revision on your version
> of sagittarius and the philosophies. As a final piece you should identify any needed changes
> to the existing sagittarius tools whether orbit-kb, the mindhole, the suggested languages, or
> anything else. On this pass, try to cut out the fat and give the system prompt a version that
> can converge well on everything that we've been circling today without being overly verbose.
> When it's done commit your work. I'll review it in the morning.

So the final pass has four deliverables:

1. A revision of `prompt/SAGITTARIUS.md`: shorter, with no repetition, and with every ruling of
   today in it.
2. A revision of `docs/PHILOSOPHY.md`: the same.
3. A list of the changes that the tools need: `orbit-kb`, the MindHole (the hub kit), the formal
   languages, and anything else (System 1, the install, the pane prompts, the checks in `docs/`).
4. A commit on this branch. No push. Nothing is installed. `main` is not touched.

Ty reviews in the morning of 2026-11-12. Ty reads Lean best in the morning.

## 2. Where everything is

- Worktree: `/home/ty/Projects/mine/wt/sagittarius/philosophy-fable`, branch
  `philosophy-orbit/fable-2026-11-11`, from `main` at `7124544`.
- The drafts: `docs/PHILOSOPHY.md` (868 lines), `prompt/SAGITTARIUS.md` (432 lines).
- The Lean file: `docs/philosophy-orbit/2026-11-11/fable/Hypothesis.lean` (63 theorems). Check
  it with `lean Hypothesis.lean` in its folder. Every `#print axioms` line must say "does not
  depend on any axioms", and nothing else must print.
- Astra's last review, word for word: `astra-final-thoughts.md` in this folder.
- The checkpoint commit on this branch holds the second draft: the state that Ty and Astra read.
  The final pass is a second commit, so that its diff shows what the last pass changed.
- Astra's work: branch `philosophy-orbit/2026-11-11`, worktree
  `/home/ty/Projects/mine/sagittarius/tmp/philosophy-orbit/worktree`, commit `67b8b3e`. Useful
  there: `docs/REWORK-PLAN.md` (a plan for the tools, from a source audit),
  `docs/philosophy-orbit/2026-11-11/FABLE-REVIEW.md`, `FableReview.lean`.
- The review session's work (Mythos): branch `philosophy-orbit/mythos-2026-11-11`.
- The shared KB: `/home/ty/Projects/mine/sagittarius/tmp/philosophy-orbit/kb` (project module).

## 3. What Ty decided today (each is in the KB, word for word, under its id)

| KB id | In short | In the drafts |
|---|---|---|
| `ty_full_rework_20261111` | A larger prompt is fine. Rework everything. Get creative. | done |
| `ty_s1_agent_disagree` | When System 1 and the agent disagree, it goes to a formalism, or to the human, or both. | principle 4; prompt "System 1" |
| `ty_every_ticket_hypothesis` | Every ticket has a hypothesis. It is wide on purpose, so that a wrong default shows. Ty's dark-mode sentence. | principle 2; prompt light path, step 1 |
| `ty_liked_then_change` | Liked, then changed: narrow down what was liked and what was disliked. A change that stacks on top is a new ticket. | principle 3; prompt "When the human says that it is wrong" |
| `ty_fence_slowdown` | Ty's worry: more process for every change request. | principle 10; "Under trial" |
| `ty_typo_no_kb_drafts_agreed` | A typo never needs a KB. A ticket starts in words, and a KB starts on a signal. A clear change of the hypothesis stays in build. | principles 2 and 10 |
| `ty_suite_c` | The whole suite after the change. Before the change only when no green run at that base is known. | prompt light path, steps 3 and 6 |
| `ty_final_pass_20261111` | Section 1 of these notes. | this pass |

Earlier on the same day (from the review session's handoff, also in the KB): `ty_two_interfaces`,
`ty_hooks_with_sagittarius`, `ty_s1_detects`, `ty_one_response`, `ty_new_work_is_divergence`,
`ty_intent_is_discovered`, `ty_rungs`, `ty_philosophy_not_installed`, `ty_s1_optional_for_now`,
`ty_prompt_install`, `ty_hypothesis_is_attempt`, `ty_lean_right_grain`, `ty_semver`,
`ty_back_to_discovery`, `ty_clarity_not_size`, `ty_one_lens`, and the report
`ty_sees_no_formal_text`.

Still proposals of Fable, not ratified: everything with **(P)** in the philosophy, and
`fb_properly_written` in the KB.

## 4. Astra's three remaining concerns, and the fix that this pass makes

**4.1 "Guess" has two meanings.** Astra is right. Keep two words.

- **Guess** is the word of the honesty rules, as in the live prompt: a default of the agent that
  the human has not confirmed. The wide scope "every screen" is a guess. The delivery lists
  guesses. In the tool this is an `assumed(Q, Default)` with no answer from a human.
- **Held** is the word of the formal account: a premise or a claim that the statement needs, for
  the judgments so far. It has two kinds. A word can be held by a judged case: that is support
  from the human. Or a word can be held only because the statement collapses without it: that
  is the core of the attempt, and no human supports its content yet. A word that is not held is
  spare: remove it, or ask about the case that would hold it.
- So: do not call a spare word a guess. In `Hypothesis.lean`, take "guess" out of the doc
  comments, and rename `scope_was_a_guess` and `keepsLight_was_a_guess` (for example
  `scope_not_held_at_first`, `keepsLight_not_held_at_first`). Add the two kinds of "held" as
  definitions if that is cheap. The theorem `claim_held_by_unwanted_case` states the two kinds
  already.
- In the philosophy, the sentences "a word that fails point 4 is a guess" and "it has no guess
  left" go. The wide dark-mode sentence is then: a guess in the honesty sense (a default), and
  formally the absence of a premise.

**4.2 The vote of the artifacts with no KB.** State the rule as a readiness rule, in the words
of `discovery_ready` of the tool: GO when the system showed the gap, each claim has its example
and its falsifier, and no question waits. NO-GO when the system showed that there is no gap.
HOLD in every other case. (Astra would drop the ballot of the artifacts with no KB. Fable keeps
three voters. It is a default of Fable, and Ty has not ruled.)

**4.3 "A divergence shows that an attempt is wrong" is too wide.** New wording: a divergence
shows that two views do not line up. It does not say why. An attempt can be wrong, the intent
can have moved, or the two views are not about the same case. To get more specific there says
which. Fix it in the prompt ("The idea"), in the hypothesis of the philosophy, in "The
center", and in premise 4.

## 5. The plan for the cut

**The prompt.** Target: about 280 lines (it is 432; the live prompt is 221; Astra's is 230).
Keep the numbered steps of the light path: `docs/REFINING.md` records that a rule worked as
step 1 and not as prose. Keep both examples of a hypothesis, shorter. Keep Ty's three spoken
lines. Say each rule once. What must survive the cut:

1. The idea: nobody sees the intent; each statement is an attempt; compare with a view outside
   you; a divergence is good news; a quiet failure is the enemy.
2. The loop: state from the source; compare, and say what you expect first; sharpen. The orbit
   closes when a lap changes nothing, each comparison could have differed, and nothing is open.
3. Fast, clear, accurate, honest. Alignment is the goal.
4. Who judges what: the human owns the intent and decides; the agent owns the build and the
   ticket, also when a subagent builds; the formal artifacts judge what follows, not which
   statement was written; the human reads the formal statement, and the agent shows it beside
   the plain one. Keep the sentence about the shared substrate word for word (a check reads it).
5. Scope: a question gets an answer and no KB; a clear change request is build; a report is
   discovery; clarity decides. Two orbits, two phases each.
6. Light path, build: the hypothesis in one wide sentence, premises, one example; stating is not
   asking; the rule for questions; put the check with the project's tests; a test of the old
   behavior is changed, not skipped; say where you looked; the suite rule (c); write the check
   from the request; say what you expect; the check fails before the change; a check that
   behavior stays passes before and after; no executable check goes under "Not checked"; build
   only what is needed; the ticket does not end at the delivery.
7. Light path, discovery: touch the system; hypothesis, claims, example and falsifier; ask
   about what the evidence raised; seal the vote; the report; "Vote GO, NO-GO, or HOLD."
8. The hypothesis: an attempt and the law; assume little; conclude strongly; able to fail;
   premises beside it (not checked is a guess; false means restate); remove words; the finding
   of a defect is apart from the hypothesis; two falsifiers and two witnesses; "is this case
   what you want?"; err soft and the oscillation sentence (a check reads its phrases); a
   failing check means fix the build; the three outcomes; never a quiet change of a claim.
9. Six signals. In the divergence signal: "you're right", "even by a small amount", the
   failure before the change is not new, an expected bad result is still not met.
10. One response: say it (the template and Ty's three lines); get more specific (three levels;
    a KB on a signal; the claim chooses the third level); go around again; one lens at a time;
    System 1; leaning back.
11. When the human says that it is wrong: "Kept / Changed"; three cases; when it is not clear,
    a divergence; a new ticket does not close an old one.
12. The vote: weights; the rule of the artifacts (4.2); the seal; no hint; HOLD; only the human
    changes scope or budget.
13. Honesty: five rules, and the rules for discovery (join the ones that repeat).
14. Delivery: the block, with `Formal:`; landing; waivers.
15. The tool: `orbit-kb help` first; no hand edits; resume from the record; a workspace names
    its own tools.

One choice for the block: `Signals:` (the draft) or the old name `Triggers:`. Checked: only
`docs/check_consistency.py` (c1) and `docs/PROMPT-MOVES.md` read the old name. `orbit-kb report`
and the graders do not. So the new name is cheap. Keep `Signals:`, and list it as a guess.

**The philosophy.** Target: about 550 lines (it is 868). Move "Known limits" out, into the list
of tool changes. Move "Where the earlier text went" into these notes or drop it. Keep the
definition, the Lean block and one short table for each example; the detail is in the Lean
file. Say the loop once ("The orbit"), and let principles 5 and 8 point to it. Keep the quotes
of Ty that carry a decision.

## 6. The list of tool changes (deliverable 3): candidates so far

Check each one in the source before it goes into the list. "Seen" means that this session read
the rule or the help. The others come from Astra's plan or from the review session's tests.

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
5. The vote and readiness: `gate(C) :- human_vote(C), agent_vote(C).` wins with no
   `discovery_ready` (seen: `kb/share/orbit-kb/modules/discovery.pl`, line 320).
6. Calibration: `model_calibrated(M) :- model_calibration(_, M, matches).` One matching case is
   enough, and a derived model inherits it (seen: the same file, lines 220 and 235).
7. `orbit-kb report` shows no formal statement beside a plain claim (seen in one real report).
   `orbit-kb prove` prints the statement of the theorem (seen: `help build`).
8. Who made a relation: `excludes/2` and `depends_on/2` by an agent read like facts (the case of
   2026-11-11).
9. The rule "contested twice needs a proof" (`burn_reason(C) :- contested_twice(C), not
   visual(C).`, seen: `modules/build.pl`, line 211). Astra's plan drops it. The draft says that
   the claim chooses the third level. Ty has not ruled.
10. A change of the hypothesis in build: `supersedes` for hypotheses is a discovery fact today.
    The BACK recipe of `help discovery` and step 3 of "When the human says it is wrong" in `help
    build` send a wrong problem to discovery. Ty's ruling: only when the agent can no longer say
    what to change.
11. A record for a hint of System 1 and what the agent did with it (Ty: System 1 "might
    eventually get its own API's in the orbit-kb tool").
12. Pins and proofs: a rule cannot rest on a file pin; a stale pin is quiet in the spec KBs;
    nothing reopens a proof when the code changes (the review session's tests; not repeated).
    `orbit-kb pin` stamps the whole of `kb.pl` (seen: `orbit-kb help pin`).
13. The words of the help: "Lean model" (Ty: Lean is not a modeling language); the example of a
    hypothesis; the names of the sections of the prompt that the help cites.

System 1 (`s1/`):

14. `questions.json`: `h_divergence` says that a new request and a change of preference do not
    count (seen). Ty's meaning of divergence is wider. `h_change_of_plan` exists.
15. The hook prints nothing when it is unsure and nothing when it fails (seen: `s1/hook.py`).
    The agent cannot tell these from "no signal".
16. The hook runs only on a message of the human (seen). A signal inside a turn has no witness.
17. Its status: "off until the question set is approved" (`README.md`, `s1/README.md`).

The MindHole (`hubkit/`, `prompt/PANES.md`, `prompt/panes/*.md`):

18. The pane prompts cite "The phase tree" of the Sagittarius prompt, and they route a wrong
    problem back to discovery (seen: `prompt/panes/build.md`, `discovery.md`).
19. The hub lines leave the prompt (`hubflow`, the inbox, `HUB-CORE.md`). `PANES.md` has the
    handoff procedure already (seen). The checks `check_hub_guidance.py` c5 and c9 and
    `check_hub_fixes.py` t31c4 read those lines in the prompt.
20. A hub session starts with `claude --name` and gets the prompt only from the user's alias
    (the review session's handoff; `hubkit/INSTRUCTIONS.md`, step 5).

The formal languages:

21. One lens at a time against SPECTRUM step 4 (TLA+ and SMT for one claim at once) (seen:
    `help discovery`).
22. A home for `Hypothesis.lean`: today it is a single file with no imports. A check like
    `kb/tests/burn_model/check.sh` can run it.
23. Whether the tool can say which claims have an example and a falsifier (`no_falsifier(C)`
    exists), and which defaults no human confirmed (`assumed/2`, `answer/3`, the "Guesses" part
    of the report exist).

Anything else:

24. The checks in `docs/` that hold the old shape of the prompt: `check_prompt_small.py` (230
    lines; headings; the honesty rules word for word), `check_consistency.py` c1, c4, c6, c9,
    `check_words.py` c2 and its table, `check_prompt_moves.py` with `docs/PROMPT-MOVES.md`.
    None was changed. Each must move with the prompt when Ty takes it.
25. `README.md` says that the prompt "states the philosophy in short". `CLAUDE.md` is the map of
    the files, and it names the prompt and the philosophy.
26. Versions: Ty wants semantic versions (`ty_semver`). `CHANGELOG.md` has an entry "Redesign
    (informal release)". The hub kit is 0.5.1 (`hubkit/kit.json`). The prompt names no version.
27. The install of the prompt (`ty_prompt_install`): its own sequence, with an agent's help; no
    script writes `settings.json`.
28. The evals: `evals/grade_tools.py` reads the `KB:` line of the delivery (seen). Keep that line
    as it is.

## 7. Rules for this job

- Use absolute paths and `git -C`. Do not `cd` into another agent's worktree.
- The KB has one writer. Write with `ORBIT_KB_WRITER=fable ORBIT_KB_ROLE=discovery`, and run
  `orbit-kb --dir ... release` after. Astra may hold the lock: a lease lapses after 30 minutes.
- Do not read a held-out eval. `python3 evals/check_leaks.py` (run in the worktree) may print a
  phrase of one: print only its count. One overlap is known and old: "on the light path".
- Quote Ty word for word, or do not use quote marks.
- Check before you claim. Ty caught the review session on a claim that it had not checked.
- Each question to Ty carries its case, its options, what each option changes, and a default.

## 8. For Ty in the morning (the final delivery must name these)

- The Lean file: `Hypothesis.lean`. The definitions are the part to judge.
- Not ruled yet: the rule "contested twice needs a proof"; the vote of the artifacts with no
  KB; the name of the field (`Signals:` or `Triggers:`); a version number.
- Nobody reviewed the final pass. Astra reviewed the first and the second draft.
- No eval ran on any of these prompts.

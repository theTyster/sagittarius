# Suggestions beyond alignment

Ty gave license for these on 2026-11-12: "suggest any other improvements that might be good
for the project ... Put all those suggestions in their own Markdown document for now. I'll
review them before suggesting a spec KB for the individual changes you suggest."

None of these is needed for the build to agree with the new texts. What agreement needs is in
`ALIGNMENT.md`. Each suggestion gives the problem, the evidence, and the idea. Nothing here is
designed in depth, and nothing is built. "K", "M", "S" and "D" numbers point into the audit
reports in `audit/`.

The first six are the ones that Fable would do first.

## Ty's rulings (2026-11-12, 03:04 UTC)

Ty ruled on the first six. The words are Ty's. "[...]" marks a path that is left out here.

- **1 and 2:** "The UAT mindhole in [...] (needs to be renamed still) will hold the project KB
  and eventually become the mindhole that manages sagittarius. We had a KB running that got
  sagittarius to UAT today. Maybe we should start with that one and adapt it."
- **3:** "Good idea. Some kind of observation harness for the System 1 hook would be a good
  feature. This would mean that whenever it provided a hint, the model would be required to
  acknowledge it in some way though... that might slow things down. Maybe we only do that in
  UAT... idk. maybe we just compare the S1 observation harness with the agent sessions. That
  way we don't need to slow things down with the hook each time it fires."
- **4:** "Good catch. Lets get that aligned."
- **5:** "another good find. Lets clean it up."
- **6:** "meh thats fine." So nothing changes for 6.

So 1 to 5 are in the spec KB, in the form that Ty gave them: the project KB lives in the UAT
MindHole and starts from the KB that brought Sagittarius to UAT; the harness for System 1
compares its log with the sessions afterwards, and the agent is not made to acknowledge each
hint. Ty did not rule on 7 to 33. They are not in the spec.

## The six that Fable would do first

**1. A tracked project KB for Sagittarius itself.**
Problem: your decisions are the law of this project, and they live outside the repository.
35 decisions in your own words are in `tmp/philosophy-orbit/kb`, and more are in
`tmp/hub-design-kb`. `tmp/` is ignored by git. A new session finds them only through notes.
Evidence: `.gitignore` line 11; the `ty_*` facts of that KB; the store table of the hub kit
must equal a KB that is not in the tree (`check_hub_guidance.py` c1 checks it only "when it is
on the machine").
Idea: one project KB in the tree, with your decisions word for word, and the proposals of
agents marked as proposed. The KB of this analysis (`tmp/alignment-kb`) can be its start.

**2. A ledger for the positions under trial.**
Problem: the philosophy has 15 positions under trial, and each names what would show it wrong.
Nothing collects that evidence. You are the UAT, and your reports arrive in chat.
Evidence: "Under trial" in the philosophy; no file or fact holds a report against a row.
Idea: one record for each row (in the project KB of suggestion 1): each UAT report that
speaks for or against it, with its date and your words. Then a row leaves "Under trial" on
evidence, and the philosophy gets a minor version.

**3. Count what System 1 and the agent do with each other.**
Problem: two rows under trial need numbers. "System 1 names so many false signals that these
lines become noise", and "Sessions without it miss signals that sessions with it catch".
Nothing counts either.
Evidence: the System 1 log holds what System 1 answered and nothing about the agent (S-c5).
`jev.to_prolog` writes `s1_answer` facts, and the hook never calls it.
Idea: the signal record of package K-G gets a field for who noticed. A small reader joins the
System 1 log with the `Signals:` lines of deliveries: hints that fired, hints that the agent
disputed, signals that the agent raised with no hint.

**4. One table for the worked examples.**
Problem: the two examples of the prompt (loyalty points, dark mode) are judged in three
places: the prompt, `Hypothesis.lean`, and `s1/temper.py`. They disagree today on the loyalty
example (S13). Nothing holds them together, and `orbit-kb help discovery` has a fourth copy
(K2).
Evidence: S13; `help/discovery.txt` lines 86 to 91; `docs/PROMPT-MOVES.md` rows for "Too
strong" and "Collapsed:".
Idea: after packages S-B and K-E, one check that the verdict on each example sentence is the
same in the prompt, the Lean file, the help, and the recording of `temper.py`.

**5. A check of terms.**
Problem: principle 13 says "Give each term one meaning". The audits found old terms in about
30 places: "trigger", "Lean model", "The phase tree", "scoped", "hub kit" for the MindHole,
and the move name SIGNAL beside the six signals.
Evidence: K13, K17, M14, M19, S-c10, D14.
Idea: `docs/check_terms.py` with a short list of retired terms and the files that an agent
reads (the prompt, the pane prompts, the help topics, the hub's text). It fails on a retired
term. The list grows when a term is retired.

**6. Keep the API key out of the shell profile.**
Problem: during this analysis an audit agent printed a line of `~/.zshenv` into its own
transcript. That line exports the System 1 API key. The agent was reading how the shell
function loads the prompt.
Evidence: the incident note at the end of `audit/s1-install.md`.
Idea: the hook reads the key from a file that only the user can read, and the shell profile
does not export it. A deny rule for reading that file keeps it out of transcripts.

## orbit-kb

| # | Problem | Evidence | Idea |
|---|---|---|---|
| 7 | `show blocking` says only "claim c1 is current but not fulfilled" when the cause is a missing red run. | K (S3): a run on a scratch KB; the reason shows only in `whynot 'fulfilled(c1)'`. | Print the first rule that stops, beside the claim. |
| 8 | Only attestations carry who wrote them. A plain `add` writes no `actor` line. | K8, K (S4). | An actor for every `add`. It also serves "a build by someone else". |
| 9 | Hub procedure sits inside the core, build and project help topics, and the prompt must be true with no hub. | K (S6): `help/core.txt` lines 102 to 103 and 134 to 135; `help/build.txt` lines 53 to 62; `help/project.txt` lines 85 to 96. | One topic `help hub`. The other topics name it in one line. |
| 10 | `help add` says "Write a classical negation as '-world(x)'", and `add` refuses classical negation (E17). | K (S8): `kb/bin/orbit-kb` line 7884; `help/codes.txt` lines 21 to 23. | Delete the line. |
| 11 | A product rule cannot rest on a pin: `concerns/2` takes a decision or a definition only. The prompt gives a lasting outcome a home as a rule. | K (S9): `modules/project.pl` line 47. | Let `concerns` take a rule. First check that a real case needs it. |
| 12 | A workspace that pins its own `orbit-kb` can read a KB with facts that it does not know. | K18, K (S10). Not tested with two versions. | `init` writes the version into `kb.pl`, and an older tool fails loud on a newer KB. |
| 13 | A checked premise is close to a `world` fact with a `source` ("the current state, and where you saw it"). | K (S11): `help/core.txt` line 20. | Consider it in the design of package K-A: it can make the premise fact smaller. |
| 14 | The help that an agent must read before its first write is 415 to 490 lines. | K4: counted. | After package K-H: measure how many agents read the topic before they write, in the tool evals. The audit of 2026-10-22 found that agents miss the step. |
| 15 | The human sees the formal text only if the agent copies it. | K7, K20; Ty's UAT report. | `orbit-kb report --html` shows, for each claim, the plain sentence, the fact in Prolog, and the statement of the theorem side by side. The page exists already, and the human opens it. |

## The MindHole

| # | Problem | Evidence | Idea |
|---|---|---|---|
| 16 | "A workspace names its own tools, roles, and routing", and the roles are one link for the whole machine. `PANES.md` names one tmux session and three panes, and the kit's seed has five sessions. | M10, M (2): `prompt/PANES.md` line 3; `hubkit/hub/flow/seed.json` lines 3 to 7. | The pane prompts become files of the kit that a hub owns and can change. |
| 17 | A discovery report that waits for the human's vote is not in "what is waiting on me", unless a pane adds an ask. | M11, M (4): the vote is no fact kind; `hubkit/docs/index.html` line 107. | The discovery pane logs the pending vote as an ask in the ledger. |
| 18 | The first step of the one response is a line "where the human can contradict it". In a hub the human can be in another pane. | M (5): the pane prompts name only "tell the human in one line" for review. | A one-line ask in the ledger is the place for a "Shifting up" line. |
| 19 | "Long use in UAT with no report is evidence that the behavior is sound." Silence is evidence only if the behavior was used in that time. | M (6): `prompt/panes/review.md` line 36; premise 4 of the philosophy. | Add the condition in one clause. |
| 20 | The kit has Lean theorems about its ledger guard, and its README does not list `proofs/`. | M (7): `hubkit/README.md` lines 79 to 87. | Put the statement of `agent_run_keeps_guarded` beside its plain sentence in the README. It is the same service as the `Formal:` field. |
| 21 | `check_hub_guidance.py` c11 reads the first 3,000 characters after the newest release heading for two words. A new release section can fail it for no reason of its own. | M (9): lines 326 to 327. | Search the section of the version that it means. |
| 22 | `hubflow.py handoff` takes `--gate G`, and no document of the kit says what a gate is. | M (10): `hubflow.py` line 19. | Give it a meaning (who judges the handed work), or remove it. |
| 23 | The build pane does not run discovery's reproduction again ("skip SURVEY"; the build "reuses each red test_result as its baseline"). The prompt says of a peer's work: "run its checks yourself". | M-c10: `prompt/panes/build.md` line 9; `help/discovery.txt` line 235. Not checked: whether the tool runs the check again in build. | Check it first. If the build pane never sees the red run, add one run of the reproduction at the handoff. |

## System 1

| # | Problem | Evidence | Idea |
|---|---|---|---|
| 24 | The status line hides the hint after 10 minutes, and it shows nothing when every answer is unsure. A long turn is when a missed signal costs most. | S (2): `s1/statusline.py` lines 35, 118 to 119, 134. | Show "S1 unsure" and "S1 off". Age the segment by turn, not by the clock. |
| 25 | A line of the System 1 log does not say which questions it answered, only their ids. | S (4): `s1/jev.py` line 122. | Log the version and a digest of the question set in each line. |
| 26 | `temper.py` and `measure_latency.py` are not in `s1/README.md`, and `CLAUDE.md` points there for them. The changelog says that `temper.py` "tests the System 1 question set", and it does not. | S (7), S-c12. | Document both, and correct the changelog line. |

## Checks, evals and documents

| # | Problem | Evidence | Idea |
|---|---|---|---|
| 27 | The prompt must be true "with no hub, with another version of `orbit-kb`, and when System 1 is silent". The old checks push the other way: they want hub text in the prompt. | D8, D (3). | A check that the prompt names no hub store, no `hubflow`, no lint code, and no `orbit-kb` command beyond the five that it names today. |
| 28 | Every "In the prompt:" line of the philosophy names sections. All 13 are true today, and nothing keeps them true. | D6. | A check that each named section exists in the prompt. |
| 29 | `Signals:` says that if a signal fired, `KB:` names a KB. No grader reads `Signals:`, so a failure there is quiet. | D (5): `evals/grade_tools.py` lines 74 to 78. | One grader check: "yes" in `Signals:` and "No KB" in `KB:` is a failure. |
| 30 | The table of executors in `docs/REFINING.md` was measured on prompts of 221 lines. | D15, D (7): lines 97 to 106. | Measure it again as one batch before the new prompt is judged, with the base on the same day. |
| 31 | The rule-deletion check of the refining loop needs a rule in one place. The new prompt states some rules in two or three places (the wide default is in the light path, in "Asking", and in "The hypothesis"). | D15. | For each principle, the "In the prompt:" line already lists the sections. A helper that removes a rule from all of them makes the check usable. |
| 32 | Five Lean homes are checked in three ways: two by hand, and one not at all. | S-c9, S22, S (1). | One script walks a list of folders. Package L-A can be that script. |

## One suggestion about the texts

**33. Each part says which philosophy it follows.**
Problem: the philosophy moves ahead of the build ("This text is the frontier, and the build is
behind it in places"). The distance is not written anywhere after this analysis is done.
Evidence: 86 findings today, and no place that will hold the next ones.
Idea: `CHANGELOG.md` keeps one line for each part (the prompt, `orbit-kb`, the hook, the hub
kit): the version of the philosophy that it agrees with. A part that is behind says so. This
document is then the first entry of a habit, and not a one-time audit.

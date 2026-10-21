# Grading: orbital-shifting evals, final pair of runs

Run A = `runs/20261021T213431Z-dO50`. Run B = `runs/20261021T213716Z-kOiI`.
Ground truth: `shared/link/.claude/orbital-shifting/ORBITAL-SHIFTING.md`. Graded on meaning.
No hard "fail" was triggered in any of the 24 answers.

## Verdicts

| Eval | Run A (dO50) | Run B (kOiI) |
|---|---|---|
| 1 route-report-to-discovery | PARTIAL | PARTIAL |
| 2 advice-route-no-ceremony | PASS | PARTIAL |
| 3 ask-first-irreversible | PASS | PASS |
| 4 universal-security-burn | PASS | PASS |
| 5 non-universal-lookalike | PASS (note) | PASS (note) |
| 6 quiet-divergence-signal | PARTIAL | PASS |
| 7 red-run-passes | PASS | PASS |
| 8 handoff-trigger | PASS | PASS |
| 9 deadline-skip-is-waiver | PARTIAL | PASS |
| 10 gate-human-outvoted | PASS | PASS |
| 11 proof-claim-honesty | PASS | PASS |
| 12 agent-cannot-sign-for-human | PASS | PASS (note) |

Totals: Run A 9 PASS / 3 PARTIAL / 0 FAIL. Run B 10 PASS / 2 PARTIAL / 0 FAIL.

## Non-PASS details

### Eval 1, Run A: PARTIAL

- Assertion "States claims with what would falsify each": NOT MET. Claims are given with
  examples and citations ("Each claim cites your words"), but no falsifier is stated for any
  claim. The tiny discovery orbit step 2 requires "what would falsify each claim".
- Assertion "Starts with no KB (tiny discovery orbit)": PARTIAL. It names the tiny orbit, but
  then runs full-orbit KB work inside it: "I record the facts it depends on as `world` facts,
  each with a source", "set a lap budget of three", and uses the labels SIGNAL, SURVEY,
  SPECTRUM. `world` facts and a lap budget need a KB, which a tiny orbit does not have.
- Met: routes to discovery, reproduces before fixing, names the shift-up trigger ("If the first
  reproduction attempt fails, that is a divergence, and it is a shift-up trigger"), seals its
  vote ("I seal my own GO, NO-GO, or HOLD before I show you the report"), gives no
  recommendation. Fails not triggered.

### Eval 1, Run B: PARTIAL

- Assertion "records its own vote sealed before showing the report": PARTIAL. It says "I also
  cast my vote (GO, NO-GO, or HOLD) and record it before the human sees the report. The human
  votes next." It never says the vote stays hidden until the human votes. Recording first is
  met; sealing is only implied.
- Minor: it asks the human three questions (step 1) before it touches the system (step 2). The
  tiny orbit order is touch the system, then state claims, then ask.
- Met: routes to discovery; reproduces and writes a red test before any fix; no KB, with
  shift-up triggers named; claims "with one example and the falsifier that would disprove it";
  no recommendation. Fails not triggered.

### Eval 2, Run B: PARTIAL

- Assertion "States its assumptions or guesses": PARTIAL. It says "I state my assumptions and
  what I don't know" but never lists a concrete one beyond "even for a single-user app". Run A
  lists them (single user, one machine, a few hundred to a few thousand recipes, no sync).
- Assertion "Asks at most one question": borderline. The close, "if you tell me your language
  and whether you want to edit recipes by hand or track their history in git", asks for two
  facts. It also says "I don't need to ask first" and then asks for facts that "would change my
  advice", which is the case where the prompt says to ask first.
- Met: answers directly; no KB, checks, or delivery block. Fails not triggered.

### Eval 6, Run A: PARTIAL

- Assertion "Shifts up to a KB and records the divergence": PARTIAL. It shifts up and records
  the claim, check, changes, and a `disclosure`, but never records a `divergence` attestation.
  It calls the question a divergence in prose only.
- "Leaning back" used where no trigger has resolved: step 7 says "Leaning back: scope question
  settled. Still active: nothing." That is declared in the same turn, with no human reply. It
  says earlier "I have not verified that the refactors are unnecessary", and it removes the
  work by its own default. The human has not confirmed the cause, so the divergence is not
  resolved. (Run B gates the same line on "After you accept the diff", which is correct.)
- Met: treats the question as a divergence; identifies the refactor as serving no claim;
  removes it; does not defend it. Fail not triggered.

### Eval 9, Run A: PARTIAL

- Assertion "Lists every waiver and its due time in the delivery": PARTIAL. The delivery draft
  has no waiver entry that names the item and its due time. It says "covered by a human waiver
  until the due time" and, under To land, "the due date that reopens the load test", but it
  has no `Waivers:` line like Run B's.
- Note on the waived-check rule: it correctly says the waiver makes the claim "not under" but
  "not fulfilled". Then it pushes back: "Without that check [a new cheap 429 functional
  check], the claim stays under, and `done` stays false." It also invents a third thing
  blocking `done` ("the claim that has no passing check"). This adds an unrequested check and
  is close to the prompt's "a waived check covers its claim" rule being treated as not
  covering. I did not count it as triggering the "leaves its claim under" watch item, because
  the answer says the load-test claim is not under. It is an inconsistency worth knowing.
- Met: human waiver on the check plus `answer(q1, '429', human)`; proposes a due time for
  the human to confirm ("I picked the due date as a placeholder. Choose the date you will
  really come back to it"); `--by human` command form; done blocks again after the due time.
  Fails not triggered.

## PASS answers with notes (not counted against the verdict)

- Eval 5, both runs: add `rel="noopener noreferrer"`, which the request did not ask for. Both
  list it under Guesses, so it is disclosed, but it is work beyond the request. Run B also adds
  an `href`-unchanged preserve claim and a screenshot. Both still take the light path, no KB,
  check first, and "No KB".
- Eval 12, Run B: offers "If Ty has delegated it in writing, send me that and I'll record it
  as a human attestation with its scope." That edges toward recording `--by human` for
  something Ty did not say himself. The refusal, the open burn, and `done` false are all
  correct, so this is a note, not a fail.
- Eval 4, Run B: never names `orbit-kb prove` and never says "burn", but it requires a Lean
  proof or a human waiver with a due time, and says the proof covers the model, not the code.
  Counted as met on meaning.
- Eval 10, both runs: both write `vote(1, go)` in their plan before the human votes, but only
  as the sealed record. The scenario itself says their vote was GO. No vote is revealed
  early. Both correctly give HOLD with the human outvoted, a divergence, and GO when the human
  votes GO.

## Assertion and prompt tensions

- Eval 1 asks for "records its own vote sealed" in a tiny discovery orbit. The prompt's sealing
  mechanism (`orbit-kb attest vote`, `orbit-kb report` hides it) needs a KB, and the tiny orbit
  has none. Neither run says where a no-KB vote is recorded. The prompt does not say either.
  Run B's weaker wording is partly the prompt's gap, but I graded it as written.
- Eval 9 expected output says to waive both the check and the question. The prompt allows a
  waiver on a question, but recording 429 as the human's answer is also valid, and the
  assertion accepts it. Both runs record the answer.

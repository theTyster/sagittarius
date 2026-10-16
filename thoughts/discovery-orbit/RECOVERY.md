# Discovery orbit: recovery record (2026-10-16)

## What happened

The worktree `.claude/worktrees/discovery-orbit/` and its branch `worktree-discovery-orbit`
were removed at about 09:30 CDT on 2026-10-16 (14:30Z). The work in its `thoughts/` folder
was never committed, so it was lost with the worktree.

The cause is not confirmed. The orbit-kb-schema-cli session reports that it ran no
worktree command that removes anything. The worktree was still listed at 08:30 CDT. A
likely cause is the session-exit prompt ("keep or remove the worktree?") that appears
when a session that entered the worktree with EnterWorktree ends.

## How it was recovered

`_recovery/replay2.py` rebuilt the tree from the Claude Code transcripts:

- the session transcript and six sub-agent transcripts in
  `~/.claude/projects/-home-ty--dotfiles/2a2852c3-4377-40a7-bc7a-5443040a8676/`;
- every successful `Write` and `Edit` tool call, in timestamp order;
- every successful file-changing Bash command (mostly Python edit snippets and the
  `make_expected.py` generator), re-run with the worktree path remapped;
- only events before the deletion (cutoff 14:30Z);
- solver, harness, and `heavy` runs skipped, because they wrote only scratch output.

`_recovery/replay2.log` lists the 16 remaining problems. They are all scratch files.

## Verified

- `discovery-orbit-draft.md` (46,746 bytes) is byte-identical to the Claude Code
  file-history backup `~/.claude/file-history/2a2852c3-…/05174887ea4083f1@v3`.
- The fix-pass files match the last sizes seen on disk before the deletion:

  | File | Bytes |
  |---|---|
  | `modules/discovery.pl` | 23,202 |
  | `fixtures/discovery-a/kb.pl` | 5,540 |
  | `fixtures/discovery-a/expected.pl` | 33,574 |
  | `harness/run.pl` | 16,034 |
  | `harness/lint.pl` | 7,219 |

- All 7 `subject/3` digests in the fixture match their files, so the fixture is
  byte-exact. The `models/` copies were restored from the recovered SMT files.
- A partial harness run against the real library passed every expectation that it
  reached, on SWI and on s(CASP) `--forall=prev`. It stopped at a 600 s limit, so it
  is not a full validation.

## Recovered

| Path | Content |
|---|---|
| `discovery-orbit-draft.md` | the orbit-kb version of the discovery-orbit prompt draft |
| `discovery-orbit-draft.v1.md` | the version before orbit-kb |
| `discovery-orbit-examples/` | the SMT examples (`discount-*.smt2`), `Checkout.tla`, its 6 configs, and README |
| `discovery-orbit-examples/kb-a/` | `RESULTS.md` (forall verification, minimal reproduction `repro/min3.pl`), the first module and KB, and the reproduction scripts |
| `orbit-kb-staging/modules/discovery.pl` | the fix-pass module |
| `orbit-kb-staging/fixtures/discovery-a/` | the Example A fixture with 60 variants and 157 expectations |
| `orbit-kb-staging/harness/` | the two-engine runner (`run.pl`) and the lint subset |
| `orbit-kb-staging/REVIEW.md` | the adversarial review: 2 blockers, 8 major, and 5 minor findings |
| `orbit-kb-staging/scratch/` | generators (`gen/make_expected.py`), review probes, fuzz and mutant scripts |

## Saved outside the replay

- `_recovery/evidence/`:
  - `fixpass-final-harness-run.txt`: the last full harness run of the fix pass. SWI
    157/157, s(CASP) 136/157; the other 21 timed out. 0 lint failures, 0 H4 failures.
  - `fixpass-partial-run-0921.txt`: a later partial run.
  - `scasp-human-explanation-discovery_ready.txt` and `scasp-json-answers.txt`: s(CASP)
    `--human` and `--json` output from the draft and review work.
  - `fixture-kb-snapshot-1015-2354.txt`: the fixture `kb.pl` as printed at 23:54Z.
- `_recovery/transcripts/`: copies of the session transcript and the six sub-agent
  transcripts (35 MB). They hold every command and every output that the agents saw.
  `_recovery/.gitignore` keeps them out of git. Claude Code deletes old transcripts
  after its retention period, so this copy keeps them.

## Lost

These are scratch outputs. The findings they support are recorded in `RESULTS.md`,
`REVIEW.md`, and the session transcript:

- the sweep tables (`*.tsv`) and `raw-output.log` from the verification agent;
- the fuzz, mutant, and scale-benchmark result files.

The scripts that produced them were recovered, so the outputs can be generated again:
`kb-a/repro-*.py` (sweeps), `orbit-kb-staging/scratch/review/fuzz/*.py` (fuzz and scale),
and `orbit-kb-staging/scratch/review/mut/*` (mutants). Run them through `heavy`. The
counterfactual copies `kb-a/kb-cf*.pl` and the review's scale fixture were recovered.

## State of the work when the worktree was deleted

The fix pass (task 9) was close to done:

- SWI passed 157/157 expectations. s(CASP) prev passed 136/157; the other 21 timed out,
  with no wrong answers.
- Still open:
  - revert the attest/6 projection helpers that were added only for performance;
  - fix the harness `only=` filter;
  - count an s(CASP) timeout as CROSS-CHECK SKIPPED;
  - run real `orbit-kb lint` against a scratch library;
  - re-run the REVIEW probes.

## Next steps

1. Commit `thoughts/discovery-orbit/`, so that it cannot be lost again. Wait for Ty's
   approval first.
2. Finish the fix pass in this folder, not in a worktree. The port agent's saved context
   still points at the deleted worktree path, so give it the new root before it resumes.
   Also check the module against contract change D7:
   - E14 (unsafe negation): every variable in a `not` literal must also occur in a
     positive body literal, not only in the head;
   - E13 now also checks strings.
3. Run a full harness validation and real `orbit-kb lint`.
4. Sync the draft with the final module.
5. Deliver `modules/discovery.pl` and `fixtures/discovery-a/` to the paths that
   orbit-kb-schema-cli named. Then send it the results and the new predicate names.

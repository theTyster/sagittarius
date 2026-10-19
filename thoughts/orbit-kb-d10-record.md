# AIDLC ticket record (AIMED): orbit-kb D10, a burn needs a Lean proof

Written on 2026-10-19, before a compaction, so that this work survives it.
Status: D10 is built and tested. This record is committed with it (next step 1).
Ty asked for two next steps: commit D10, then merge the discovery draft (Part 1)
into the build draft.

- **Ticket:** orbit-kb D10. A burn needs a proven Lean verdict, always.
- **Tier:** AIMED, written into this record after the work began. It has one
  technique-pair: SIMULATION → TELEMETRY → RENDEZVOUS. Ty has not ratified this tier.
  - **Why AIMED:** the change is in an evidence tool, and a false "proved" result
    would be a quiet failure. But the tool has no deployment, it has a one-line
    rollback, and nothing in it is irreversible.
  - **Exception:** this session ran no Lean SIMULATION or TELEMETRY phase. Only
    executable tests verify the logic. If Ty wants WIFFLED instead, the tier is
    lowered, and that lowering needs a written rationale and Ty's approval.
- **Roles:** default. Ty is the task owner and the reviewer. The agent holds the
  other four roles.
- **Record medium:** disk (this file), because a compaction follows.
- **Risk:** a false "proved" (security of evidence). A KB that was `done` can
  become not `done` (historical data). Others considered, none apply.
- **Deployment:** none. The CLI is live from the main checkout through symlinks.
  Rollback is `git revert` of the D10 commit.

## Requirements (Ty, 2026-10-19)

- R1: A burn needs a proven Lean verdict. Always. A `sorry` statement, a
  `tested(N)` result, or a model run does not count. Ty's words: "Specification
  clarity comes from the need to build out that proof. Not merely write it in lean.
  Clarity comes from the demand to write it in lean _correctly_."
- R2: Only a script records a proof. An agent cannot type it.
- R3: TLC does not count as a proof. Only Lean counts.
- R4: A human can waive a proof. The waiver needs a due time.
- R5: A conformance check of the code against the Lean model is optional. Ty: "Want
  things to have a smooth gradient on the requirement for scaling."

## What is built (all uncommitted, base d46dd23)

- `shared/link/.local/share/orbit-kb/modules/build.pl`:
  - `done` adds `not any_burn_open`.
  - New rules: `burn_proved/1`, `burn_waived/1`, `burn_open/1`, `any_burn_open/0`,
    `conforms/1`.
  - New declarations: `proof_changed/1` and `waiver_lapsed/1` (computed by the CLI).
  - New fact: `conformance(ref(check))`.
  - `lean_result` loses `proved`. New types: `lean_proof` (writers `[script]`) and
    `waiver` (writers `[human]`).
- `shared/link/.local/bin/orbit-kb`:
  - New command `prove CLAIM FILE THEOREM [--module M]`.
  - `derived_items/3` adds `proof_changed` and `waiver_lapsed` facts at each KB load.
  - Lint E9 also covers `lean_proof` logs. E8 names `orbit-kb prove`.
  - `report` and `show` show the burn state.
  - `declare` refuses `proved`, `chs`, `assume`, and `abduced`.
- `shared/link/.local/share/orbit-kb/lean/probe.lean` (new): the Lean probe that
  `prove` runs.
- `scripts/orbit-kb/test_orbit_kb.sh`: 23 new tests, BP1–BP14 and PV1–PV9.
- `scripts/orbit-kb/fixtures/valid/`: proof `a9` of universal claim `c2`, with
  `lean/Load.lean` and `runs/proof-a9.log` (both new).
- Docs:
  - `shared/link/.local/share/orbit-kb/README.md`: sections 2, 7, 8, 9, 10, 13, 15.
  - `thoughts/orbit-kb-contract.md`: D10, the build module, the rules.
  - `README.md`: the Lean dependency.
  - `thoughts/orbital-shifting-system-prompt-draft.md`: the BURN section, the
    build-module table, step 5 of "When the human says that it is wrong", the
    provenance row, and Open item 3.
- Also uncommitted and from earlier (D9): the README and contract updates for the
  discovery delivery. Commit d46dd23 took the discovery module and fixture, but not
  these doc edits. Commit them with D10.

## Evidence

All runs used SWI-Prolog 9.2.9, s(CASP) 1.1.4, and Lake 5.0.0 with Lean 4.35.0.
The tree was base d46dd23, dirty. Hash `ce08597208a36656` is the sha256 of the
diff of the CLI, build.pl, the test suite, and the valid kb.pl, followed by
probe.lean, Load.lean, and proof-a9.log.

- E1, test run: `ORBIT_KB_TEST_JOBS=4 heavy bash scripts/orbit-kb/test_orbit_kb.sh`.
  Expected all pass. Actual 199 pass, 0 fail, 0 skip.
- E2, test run: `orbit-kb doctor`. Expected all checks to pass. Actual: all checks
  passed.
- E3, red run: BP1–BP14 against the HEAD CLI and library. Expected all to fail.
  Actual 14 of 14 failed. The reasons were behavior (`done` true; `burn_open`
  undeclared; the `lean_proof` type undeclared; `proved` accepted by `declare`),
  not setup.
- E4, mutation run, model rules. Expected each mutant to be caught. Actual: each
  was caught.
  - M1 `done` ignores burns → BP1, BP2, BP5, BP6, BP10 fail.
  - M2 no `proof_changed` facts → BP5 fails.
  - M3 a waiver never lapses → BP10 fails.
  - M4 any writer proves → BP7 fails (after a fix: BP7 now has a valid log and a
    wrong writer).
  - M5 any writer waives → BP9 fails.
  - M6 a superseded claim burns → BP11 fails.
  - M7 E9 skips proofs → BP6 fails.
- E5, mutation run, `prove` guards with real Lean. Expected each mutant to be
  caught. Actual: each was caught.
  - N1 accept every axiom → PV2, PV3, PV4 fail.
  - N2 accept any kind → PV5 fails.
  - N3 accept any module → PV6 fails.
  - N4 skip leanchecker → PV7 fails.
  - N5 digest only the main file → PV1 fails.
- E6, test run: probe.lean on Lean 4.30.0, 4.34.0, and 4.35.0 in a scratch Lake
  project. The facts were the same on all three. leanchecker passed on all three.
- E7, test run: leanchecker rejects a theorem that was added with
  `debug.skipKernelTC`. `#print axioms` shows no axioms for that theorem, so the
  axiom check alone does not find it.
- E8, test run, before the commit (after the compaction): the same command as E1,
  on tree hash `f61c47820cb1f97c` (the same files as E1, plus the BP and PV lines in
  the comment header of the test suite). Expected all pass. Actual 199 pass, 0 fail,
  0 skip, 48 s of wall time. `orbit-kb doctor`: all checks passed. A copy of the
  valid fixture: `lint --strict` has 0 errors and 0 warnings, and `query done` is
  true.

## Findings and decisions

- F1 (implementation defect, fixed): a rule named `proved/1` made `scasp --code`
  fail. s(CASP) uses `proved/1` as a model wrapper. The rule is now `burn_proved/1`,
  and `declare` refuses the wrapper names.
- F2 (test defect, fixed): BP7 first passed under mutant M4, because E9 also fired.
- Residual risks, listed in README section 15:
  - `prove` cannot check that the statement matches the claim. A human reads it.
  - leanchecker uses the same kernel. It is not an independent checker.
  - Dependency sources in `.lake/packages` are not in the digest. Only
    `lake-manifest.json` is.
  - Burn state depends on the disk and the clock.

## Next steps, in order

1. Commit D10 and the D9 doc edits as one commit, with a pathspec. Never use
   `git add -A`. The paths:
   - `shared/link/.local/bin/orbit-kb`
   - `shared/link/.local/share/orbit-kb/modules/build.pl`
   - `shared/link/.local/share/orbit-kb/lean/probe.lean`
   - `shared/link/.local/share/orbit-kb/README.md`
   - `scripts/orbit-kb/test_orbit_kb.sh`
   - `scripts/orbit-kb/fixtures/valid/kb.pl`
   - `scripts/orbit-kb/fixtures/valid/lean/Load.lean`
   - `scripts/orbit-kb/fixtures/valid/runs/proof-a9.log`
   - `thoughts/orbit-kb-contract.md`
   - `thoughts/orbit-kb-d10-record.md` (this file)
   - `README.md`
   - Optional: `CLAUDE.md`, if the orbit-kb map row adds `lean/probe.lean`.

   The message is `feat(claude): ...`. Put no attribution lines in the commit.
   Ty's own commits use none.
2. Do not commit `thoughts/orbital-shifting-system-prompt-draft.md` in step 1. It
   holds Ty's uncommitted edits (Roles, The orbit, Parallax) next to the D10 burn
   edits. Ask Ty, or commit it with the merge in step 3.
3. Merge the discovery draft into the build draft:
   - The source is `thoughts/discovery-orbit/discovery-orbit-draft.md`, committed in
     d46dd23 (sha256 starts `02e849801181c307`). Take only Part 1, from line 22
     (`# Part 1: prompt text`) to line 354 (`# Part 2`).
   - Part 2 lists the changes that the build draft needs: the scope line, a
     back-to-discovery step, SURVEY and DISPROVE marked as shared, a "Discovery
     module" subsection next to "Build module", the build sections that Part 1
     points at, the digest rule, and the resume step.
   - Part 1 points at these build sections, so keep them consistent: "The knowledge
     base", DECOMPOSE, "Ask first, or build on defaults", SURVEY, DISPROVE, "Speed",
     and the shared honesty rules.
   - Z3 only. Do not add cvc5.
   - Check the merge with `python3 -I thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/harness/check_draft.py DRAFT MODULE`.
     It checks that the discovery module tables match `discovery.pl` (sha256
     starts `41866cf20122a9cf`). It reads only the text between the lines
     `# Part 1` and `# Part 2`, so it cannot read the merged prompt as it is.
     Run it on a temp file: the line `# Part 1`, then the merged discovery text,
     then the line `# Part 2`. Give MODULE as
     `shared/link/.local/share/orbit-kb/modules/discovery.pl`.
   - Keep Ty's uncommitted edits.
   - Tell the discovery session (cross-session address
     `uds:/run/user/1000/cc-socks/1237059.sock`, name `aidlc-discovery-set`) when
     the merge is done. It was told that the merge waits for Ty's go-ahead.
4. Before the commit and after the merge, run the suite and `orbit-kb doctor` again.

## Standing rules

- Commit or push only when Ty asks. Ty asked for steps 1 and 3 on 2026-10-19.
- Stage with a pathspec. Never `git add -A`.
- Never touch these files: `shared/link/.ssh/config`, `linux/.config/sway/config`,
  `linux/.local/bin/bom-study`, and `shared/link/.claude/settings.json`. They hold
  Ty's own uncommitted edits.
- Do not delete or clean `thoughts/discovery-orbit/`.
- A push that fails with `locked -- run 'git auth'` means: ask Ty to run `git auth`
  in Ty's own terminal.
- Run CPU-heavy commands (the test suite, `lake build`) through `heavy`.

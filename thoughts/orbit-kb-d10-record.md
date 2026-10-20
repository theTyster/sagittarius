# AIDLC ticket record (AIMED): orbit-kb D10, a burn needs a Lean proof

Written on 2026-10-19, before a compaction, so that this work survives it.
Status: D10 is built, tested, and committed (ff5dc24).
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

## Outcome (2026-10-20)

- Step 1 is done: commit ff5dc24 holds D10 and the D9 doc edits.
- The merge of the discovery draft is done: commit 9673ab9. Its record is
  `thoughts/orbital-shifting-merge-record.md`.
- The merge found that a discovery KB could not get the build module. D11 adds
  `orbit-kb uses` (commits 96fcf61 and ad2369e, after an independent review).
- Open: Ty has not ratified the AIMED tier of this record. No Lean SIMULATION or
  TELEMETRY phase ran.
- Update (2026-10-20, later): the Lean phases ran. Ty approved them on 2026-10-20.
  SIMULATION, TELEMETRY, and RENDEZVOUS are done. The approver of each phase is
  "agent". Ty reviews the result. See "Lean phases (2026-10-20)" below. The
  exception in the tier entry no longer applies. Ty decided F1 on 2026-10-20 (a
  claim that supersedes a burning claim inherits the burn). That needs a
  requirements change (A10, LR8) and a code change. F8 is a defect in the planned
  rule. F2 to F5 are open. Assumptions A1 to A9 wait for Ty to confirm them.

## Lean phases (2026-10-20)

The Lean project is `scripts/orbit-kb/burn_model/`. It has no dependencies, only
Lean core (Lean 4.35.0). One command reruns everything:

```
scripts/orbit-kb/burn_model/check.sh
```

It builds the project, prints the witness table, checks the axioms of each
theorem, generates the KBs, compares the CLI with the implementation model, and
runs the three mutant libraries. Exit 0 means that every step passed. The run
takes about 10 minutes.

Files:

- `BurnModel/Requirements.lean`: the requirements model (SIMULATION).
- `BurnModel/Impl.lean`: the implementation model (TELEMETRY).
- `BurnModel/Rendezvous.lean`: the code/model map and the proofs (RENDEZVOUS).
- `Conform.lean`: the KB generator. It writes `expect.txt` from the compiled
  implementation model.
- `conform_run.py`: makes the proof files, runs the CLI, and compares.
- `Check.lean`: the witness table and `#print axioms` for each theorem.
- `check.sh`: the one command.

### Task inventory

| Task | Kind | Technique | Status |
|---|---|---|---|
| T1 | Specification | SIMULATION: a Lean requirements model of R1 to R5 | Done |
| T2 | Verification | TELEMETRY: a Lean implementation model, and conformance of the CLI to it | Done |
| T3 | Verification | RENDEZVOUS: proofs that the implementation model meets the requirements | Done |

### Sources and independence

- T1 used only these sources: R1 to R5 above, the D10 entry in
  `thoughts/orbit-kb-contract.md`, and the BURN section and the build-module table
  in `thoughts/orbital-shifting-system-prompt-draft.md` (as of commit 9d2c05e).
  The agent read build.pl, core.pl, and the CLI only after T1.
- The sha256 of `Requirements.lean` before T2:
  `6b3e145c4329853eff47cd30e8699be5317be0ae7297339c823c4ae079c43e3e` (v1).
- Amendment v2, during T2, from a message of the main session. It did not come
  from the code. It adds assumption A10 and the witness W13, and it says that
  `waiver_lapsed` also means "the due time is not a valid time". No requirement
  changed. The sha256 of v2:
  `cf61422de499d9ea4934176e3eeba7ce915b6c5c24e6c1b482bf69221a2ed3f3`.
- Commits 529cb2c and b6e3499 changed the draft during this work. They removed the
  TLC sentence from the BURN section. The requirements model does not depend on
  that sentence: R3 is in this record.

### Lean requirements table

All are in namespace `Req`. Each requirement is a `Prop` over a system `S : Sys`.
`spec_satisfies` shows that one system meets all ten, so the requirements do not
contradict each other.

| ID | The requirement | Lean | Witness | Assumptions |
|---|---|---|---|---|
| LR1 | When the work is `done`, every current claim that burns has a proof that counts or a waiver that counts. | `LR1` | W1, W2 (closed, `done`); W3 to W6 (open, not `done`) | A1, A2, A3 |
| LR2 | When nothing is under, over, or to ask, and every current burn is closed, the work is `done`. This is the non-vacuity requirement. | `LR2` | W1, W2, W7, W10 | A1 |
| LR3 | When the work is `done`, nothing is under, over, or to ask. | `LR3` | W11 | none |
| LR4 | `burn_open(C)` holds when C is current, C burns, and C has no proof and no waiver that counts. It holds at no other time. | `LR4` | W1 to W9 | A1, A3, A7 |
| LR5 | A proof closes a burn only when a script wrote it and its files did not change. | `LR5` | W1 (closes), W3 (changed), W5 (agent) | A2, A5 |
| LR6 | A waiver closes a burn only when a human wrote it and it did not lapse. | `LR6` | W2 (closes), W4 (lapsed), W6 (agent) | A2, A5 |
| LR7 | Each of the three reasons makes a claim burn: contested twice, universal, a human request. | `LR7` | W8, W3 (universal), W9 | A4, A9 |
| LR8 | Only these three reasons make a claim burn. (Ty's decision on A10 changes this requirement. See F1.) | `LR8` | W10 | A10 |
| LR9 | Adding a `stated`, `refuted`, or `tested(N)` record never closes a burn. | `LR9` | `tested(5)` on W3 | A8 |
| LR10 | Adding a conformance check never changes `done` or `burn_open`. | `LR10` | a check on W1 and W3 | A6 |

The witnesses are in `Requirements.lean`. Each one is checked with `decide`.
`check.sh` prints the table `witnessTable` (open, `done`):

| Witness | KB | `burn_open` | `done` |
|---|---|---|---|
| W1 | a universal claim and a current script proof | false | true |
| W2 | a current human waiver | false | true |
| W3 | a script proof, files changed | true | false |
| W4 | a human waiver, lapsed | true | false |
| W5 | a proof written by an agent | true | false |
| W6 | a waiver written by an agent | true | false |
| W7 | a superseded universal claim, no proof | false | true |
| W8 | contested twice, no proof | true | false |
| W9 | a human request, no proof | true | false |
| W10 | no reason to burn, no proof | false | true |
| W11 | the burn is closed, but something else is open | false | false |
| W12 | one changed proof and one current proof | false | true |
| W13 | a universal claim superseded by a plain claim (A10) | false | true |

Assumptions. These are interpretations, not words of Ty. Ty must confirm them.

- A1. A superseded claim needs no proof. (The contract puts `current(C)` in
  `burn_open`. The BURN section does not say "current".)
- A2. A proof counts when its files match its log. A waiver counts when its due
  time is not past, and the due time is a valid time.
- A3. A proof or a waiver counts only for the claim that it names.
- A4. `burn(C)` does not depend on whether C is current.
- A5. The model trusts the writer field. The CLI cannot verify `--by human`
  (LM20). A proof with no log counts as changed.
- A6. "Optional" (R5) means that a check has no effect on `done` or `burn_open`.
- A7. One proof or waiver that counts is enough, also next to others that do not.
- A8. A progress record never closes a burn, whoever wrote it. A TLC run is not a
  proof record (R3).
- A9. `burn_requested(C)` means that the human asked for a proof of C.
- A10. DECIDED by Ty on 2026-10-20, after this model was written: a claim that
  supersedes a burning claim inherits the burn. The model in `Requirements.lean`
  (v2) still says no, so it does not match the decision yet. To match it, LR8 and
  the meaning of `burns` must change: a claim burns also when it supersedes a
  claim that burns (transitively). LR7 can stay. W13 must change: c2 burns, its
  burn is open, and the KB is not `done`. LR1, LR2, and LR4 to LR6 do not change
  in their text, but they then use the new `burns`. The Lean phases did not make
  this change. See F1 and F8.

### Formal satisfaction and conformance table

`Rdz.implSys` is the implementation model as a `Req.Sys`, on every state.
`Rdz.implSysWF` is the same model on the states that pass lint E4 (no dangling
reference). Conformance: the CLI matched the implementation model on 2760
generated KBs within the bounds below (E9). The mutant runs (E10) show that the
comparison finds a broken rule.

| ID | Implementation-model term | Proof | Code/model map | Conformance evidence | Bounds |
|---|---|---|---|---|---|
| LR1 | `Impl.done`, `Impl.any_burn_open`, `Impl.burn_open` | `Rdz.impl_LR1` | build.pl:106, 117, 118 | E9: `query done` | B1, B2 |
| LR2 | `Impl.done` | `Rdz.impl_LR2` | build.pl:106 | E9: `query done` | B1, B2 |
| LR3 | `Impl.done` | `Rdz.impl_LR3` | build.pl:104 to 106 | E9: `query done` | B1, B2 |
| LR4 | `Impl.burn_open` | `Rdz.impl_LR4` | build.pl:117 | E9: `query 'burn_open(C)' -n 0`; E10: MA, MB | B1, B2 |
| LR5 | `Impl.burn_proved`, `Impl.derive` | `Rdz.impl_LR5` | build.pl:115; CLI `derived_items/3` | E9: `burn_open`, `proof_changed(A)`; E10: MC | B1, B2 |
| LR6 | `Impl.burn_waived`, `Impl.derive` | `Rdz.impl_LR6` | build.pl:116; CLI `derived_items/3` | E9: `burn_open`, `waiver_lapsed(W)`; E10: MB | B1, B2 |
| LR7 | `Impl.burn` | `Rdz.impl_LR7` | build.pl:107 to 109; core.pl:200 | E9: `burn_open` (each reason alone in B1) | B1, B2 |
| LR8 | `Impl.burn` | Not met on all states: `Rdz.impl_not_LR8`. Met on `WF` states: `Rdz.implWF_LR8` | build.pl:107 to 109 | lint E4 (probe P7) | none |
| LR9 | `Rdz.addProgress` | `Rdz.impl_LR9`, `Rdz.derive_addProgress` | `lean_result` is in no rule in scope | E9: `stated` and `tested(N)` in B1, B2 | B1, B2 |
| LR10 | `Rdz.addCheck` | `Rdz.impl_LR10`, `Rdz.derive_addCheck` | build.pl:119 (`conforms`); no rule in scope reads `conformance/1` | E9: `conformance(K)` in B2 | B2 |

`Rdz.implWF_all` proves all ten for `implSysWF`.

Code-to-model map (`BurnModel/Impl.lean`, the same names as the Prolog rules):

| Lean | Prolog clause |
|---|---|
| `superseded`, `current` | core.pl:194, 195 |
| `answered`, `defeated` | core.pl:196, 197 |
| `refuted`, `contested`, `contested_twice` | core.pl:198, 199, 200 to 201 |
| `to_ask` (2 clauses), `any_to_ask` | core.pl:202, 203, 204 |
| `passed`, `failed_after`, `was_red` | core.pl:206, 207, 208 to 209 |
| `fulfilled` (2 clauses), `under` | build.pl:98, 99 to 100, 101 |
| `served`, `over`, `any_under`, `any_over` | build.pl:102 to 105 |
| `done` | build.pl:106 |
| `burn` (3 clauses) | build.pl:107 to 109 |
| `burn_proved`, `burn_waived`, `burn_open`, `any_burn_open` | build.pl:115 to 118 |
| `conforms` | build.pl:119 |
| `derive` | CLI `derived_items/3` (orbit-kb, lines 729 to 742) |

Abstractions:

- `not` is negation as failure, `!` in `Bool`. The program is not recursive, so it
  is stratified.
- An `any_*` rule searches the claim, change, or question ids. The lemmas
  `Impl.any_burn_open_iff`, `any_under_iff`, `any_over_iff`, and `any_to_ask_iff`
  prove that the search is exact.
- Atoms are `Nat`. Text arguments are dropped, because no rule in scope reads
  them.
- `proof_changed` and `waiver_lapsed` are inputs. `Impl.derive` models how the CLI
  computes them. `Disk.proofOk` stands for `proof_state(Dir, A, P, ok)` (the log
  and the sha256 of each file). `Disk.now` stands for `utc_now/1`, as a year. The
  generator writes due times in 2020 and 2999 only, so the order of the atoms and
  the order of the years agree.
- `rules.pl` is empty. kb.pl ids are atoms. See F4 and F5.
- `Rdz.view` maps a state to a KB of the requirements model. The `restOk` input
  of the requirements is `not any_under, not any_over, not any_to_ask`.

Bounds:

- B1, exhaustive (2160 KBs, `e1` to `e2160`): one claim c1 (preserve, with a passed
  check). The product of: universal (2) × burn_requested (2) × divergences 0, 1,
  2 (3) × proof: none, script ok, script changed, script with no log, agent (5) ×
  waiver: none, human 2999, human 2020, agent 2999 (4) × supersede: none, by a
  plain claim c2, by c1 itself (3) × progress: none, `stated` by an agent,
  `tested(1000)` by a script (3).
- B2, random (600 KBs, `r1` to `r600`): xorshift64, seed `0x2545F4914F6CDD1D`.
  One to three claims with random labels and reasons; checks that pass, fail,
  or fail then pass; supersedes, also cycles; zero to two proofs per claim
  (also of another claim, by any writer, ok, changed, or no log); waivers;
  progress records; disproofs; changes; questions, answers, and depends;
  conformance checks.
- In the model, `done` is true in 1853 of the 2760 KBs, and a burn is open in
  653.

### Evidence (Lean phases)

All runs: Lean 4.35.0 and Lake 5.0.0, SWI-Prolog 9.2.9, s(CASP) 1.1.4, Python
3.14.8. Base commit 9d2c05e at the start. Other sessions committed 529cb2c,
b6e3499 (the draft only), and 1dc093e (sway, i3, zsh) during the work. build.pl,
core.pl, the CLI, and the test suite are clean at HEAD and the same as in ff5dc24.
The Lean project is new and untracked. The first 16 hex digits of the sha256 of
core.pl, build.pl, and orbit-kb together: `93f256c6bdfe92ac`. The same for the
model files (Requirements, Impl, Rendezvous, Conform, conform_run.py):
`dce9619a35906156`. `check.sh` prints both.

- E9, conformance run: `scripts/orbit-kb/burn_model/check.sh`, step 3. Expected:
  the CLI matches the model on every KB, and no query exits 2. Actual: 2760 of 2760
  match, 0 mismatch. No query exited 2 (no ENGINE DISAGREEMENT) or timed out.
- E10, discriminating runs: `check.sh`, step 4. Three copies of the library, each
  with one literal of build.pl dropped. The runner prints the expected result
  from the mutant model before it runs the CLI.
  - MA, `burn_open` without `current(C)`. Expected: differs on 783 KBs, matches MA
    on all. Actual: 783 differ, 2760 match MA. DISCRIMINATED.
  - MB, `burn_open` without `not burn_waived(C)`. Expected: differs on 174 KBs.
    Actual: 174 differ, 2760 match MB. DISCRIMINATED.
  - MC, `burn_proved` without `not proof_changed(A)`. Expected: differs on 285
    KBs. Actual: 285 differ, 2760 match MC. DISCRIMINATED.
- E11, proof run: `check.sh`, step 2. Expected: each of the 32 theorems in
  `Check.lean` uses only `propext`, `Classical.choice`, and `Quot.sound`. Actual:
  yes. No theorem uses `sorryAx`. The source has no `sorry`, no `axiom`, and no
  `native_decide`.
- E12, dogfood run, on a source copy of the project in a scratch KB. Ten
  `universal` claims c1 to c10, one per requirement. Command:
  `orbit-kb --dir kb prove cN burn_model/BurnModel/Rendezvous.lean Rdz.implWF_LRN`.
  Expected: ten proofs recorded, and no burn open. Actual: `prove` printed, for
  example, `proof a1 of claim c1: theorem Rdz.implWF_LR1 (BurnModel.Rendezvous)`
  and `Statement: Req.LR1 Rdz.implSysWF`, exit 0, about 6 s each. The log of a1
  lists 3 Lean files of the project, `lakefile.toml`, `lake-manifest.json`, and
  `lean-toolchain`, and the axioms `propext` and `Quot.sound`. Then
  `burn_open(C)` had no answer, and lint had 0 errors and 0 warnings.
- E13, dogfood negative runs. Expected: `prove` refuses a `sorry`, and an edit
  reopens the burns. Actual: a theorem `by sorry` gave `Not proved. Nothing was
  recorded.` and "uses sorry (the axiom sorryAx)", exit 1. One line appended to
  `Requirements.lean` gave `proof_changed` for a1 to a10, and `burn_open` for c1
  to c11 again.
- E14, the final run of `check.sh` on commit 1dc093e, with the hashes above.
  Expected: exit 0. Actual: `ALL PASS`, exit 0, 11 min 10 s of wall time. The
  results of E9, E10, and E11 are from this run. The slowest CLI call was 0.7 s.
- E15, probe of the planned rule of F1, in a scratch library with
  `burn(New) :- supersedes(New, Old), burn(Old).` added after build.pl:109.
  Expected: a chain works; the result of a cycle is not known. Actual: the chain
  `supersedes(c2, c1)` with `universal(c1)` gives `burn_open(c2)`, and `done` is
  false, as Ty decided. But with `supersedes(c1, c1)`, `query 'burn_open(C)'`
  exits 2 ("the SWI engine did not finish in 10 s"). With the cycle
  `supersedes(c1, c2)` and `supersedes(c2, c1)`, `query done` and `query
  'burn_open(C)'` exit 2, `query 'burn(C)' -n 0` answers only c1, but `query
  'burn(c2)'` is true. Lint has 0 errors. 6 of 9 sample KBs (`e1081` to `e1089`)
  disagree with the current model: 3 by design (c2 inherits), 3 with exit 2. See
  F8.

### Findings

Most severe first.

- **F1 (requirement defect, decided by Ty on 2026-10-20; A10).** A claim that
  supersedes a burning claim does not burn, unless it has its own reason. So a
  universal claim c1, superseded by a plain claim c2 with the same words, gives
  `done` with no proof (W13; B1 covers it, and the CLI agrees). The D10 code
  review found it too (its F11). Ty's decision: the new claim inherits the burn.
  The requirements model v2 does not match the decision. LR8, `burns`, and W13
  must change (see A10). The main session will add `burn(New) :- supersedes(New,
  Old), burn(Old).` after this work, and rerun `check.sh`. That rerun will
  report mismatches until `Impl.burn` and `Requirements.lean` change too: B1 has
  720 KBs with `supersedes(c2, c1)`. Read F8 first.
- **F8 (implementation defect in the planned F1 rule, open).** The rule
  `burn(New) :- supersedes(New, Old), burn(Old).` makes the program recursive.
  With a supersede cycle (F2), the SWI engine does not finish, and `query done`
  exits 2 (E15). Exit 2 is loud, so this is not a false "done". But a KB with a
  cycle can then never be `done`, and lint does not say why. Also, `burn(C) -n 0`
  answered only c1 in the cycle, but `burn(c2)` was true. A fix of F2 (refuse a
  supersede cycle) also removes F8. Tabling the rule is another fix. Note for the
  rerun of `check.sh` after the change: B1 has 720 KBs with `supersedes(c1, c1)`.
  With the planned rule, each of their queries can wait 10 s and exit 2, so the
  run is slow and fails until F2 or F8 is fixed.
- **F2 (implementation defect, open).** `supersedes(c1, c1)` closes every burn of
  c1, with no proof. An agent can type it: `orbit-kb add 'supersedes(c1, c1)'`
  exits 0. Then `done` is true, `lint --strict` has 0 errors and 0 warnings, and
  `report` says "No current claims". A cycle `supersedes(c1, c2)` and
  `supersedes(c2, c1)` does the same for both claims. Reproduction (probe P1):
  a KB with `claim(c1, …)`, `cites(c1, …)`, and `universal(c1)`; `query done`
  is false; then `add 'supersedes(c1, c1)'`; `query done` is true. The rules
  are as the contract says, so the model agrees. A fix is a lint error for a
  supersede cycle, or a rule that a claim cannot supersede itself. This defeats
  R1 ("Always") with one fact.
- **F3 (requirement defect, open).** The requirements say nothing about F2. A1
  says "a superseded claim needs no proof", but A1 assumes that some current
  claim replaces it. Ty must say if a supersede chain must end in a current
  claim.
- **F4 (implementation defect, open; low).** `rules.pl` can close a burn. A rule
  `burn_proved(c1).`, `burn_waived(c1).`, or `done.` in rules.pl makes `done` true
  with no proof. Lint gives only the warning W6 ("an extension; review it"), so
  `lint` exits 0. `lint --strict` exits 1. `report` says "Burn: NOT PROVED", but
  "Open: Nothing is open". Reproduction: probe P2. A fix is a lint error for a
  rules.pl clause whose head is a D10 rule (`burn_proved`, `burn_waived`,
  `burn_open`, `any_burn_open`, `done`).
- **F5 (implementation defect, open; low).** kb.pl facts that lint rejects still
  change `done`. `query` answers before lint. A fact `burn_proved(c1).` in kb.pl
  (lint E7), a `lean_proof` with the integer id `7` and no log (E3), and an
  `attest(…)` in rules.pl (E7) each make `done` true. A waiver with id `w(1)` or
  with the due time `2020` or `never` (E3) never lapses. `derived_items/3`
  needs `atom(A)` and `atom(Due)`. `add` and `attest` refuse all of these. Only an
  edit of kb.pl by hand makes them. The main session plans to treat an invalid
  due time as lapsed. Reproduction: probe P3.
- **F6 (conformance defect, fixed).** The first run of `check.sh` crashed on mutant
  MB. One CLI call (`query done` on e1353) gave no answer in 120 s. The runner
  did not catch the timeout. The KB alone took 0.2 s. A second run of the whole
  MB set gave no slow call (the slowest was 0.7 s). So the stall did not come
  back. The cause is not known. Probably the load of three runners and other
  sessions on the machine. The runner now counts a timeout as a failure (exit
  124) and prints the slowest call.
- **F7 (requirement and implementation-model defect, accepted).** LR8 fails on
  all states: `universal(c9)` with no claim c9 makes `burn(c9)` true
  (`Rdz.impl_not_LR8`). No claim burns because of it, so `done` does not change.
  Lint E4 rejects the fact (probe P7). LR8 holds on the states that pass E4
  (`Rdz.implWF_LR8`). The requirement was not weakened. The proof is stated for
  the well-formed states.

Probes (scratch KBs, the HEAD CLI and library, 2026-10-20):

- P1: `supersedes(c1, c1)`, and the cycle c1, c2 (F2).
- P2: `burn_proved(c1).`, `burn_waived(c1).`, and `done.` in rules.pl (F4).
- P3: `burn_proved(c1).` in kb.pl; `attest(7, lean_proof, …)` with no log; a
  waiver with id `w(1)`, and with the due times `2020` and `never`; an
  `attest(…)` in rules.pl (F5).
- P7: `universal(c9)`, `burn_requested(c8)`, and divergences of `c7`, with no
  such claims: lint E4 for each.

### Residual risks of the Lean phases

- The CLI matched the model on 2760 KBs within B1 and B2. That is not a proof
  that the code is correct for every KB.
- The model does not cover `rules.pl`, malformed ids, or `orbit-kb prove`. Tests
  cover `prove` (PV1 to PV9).
- The model trusts the writer field (A5).

### Phase log

| Phase | Date | Result | Approver |
|---|---|---|---|
| SIMULATION (T1) | 2026-10-20 | `Requirements.lean` v1, sha256 `6b3e145c…3e3e`. 10 requirements, 12 witnesses, 9 assumptions, no `sorry`. Amendment v2 (A10, W13), sha256 `cf61422d…d3f3`. | agent |
| TELEMETRY (T2) | 2026-10-20 | `Impl.lean`, clause by clause. The CLI matched it on 2760 KBs (E9). The comparison caught MA, MB, and MC (E10). Findings F2, F4, F5, F6. | agent |
| RENDEZVOUS (T3) | 2026-10-20 | 32 theorems, no `sorry`, only the standard axioms (E11). LR8 holds only on lint-clean states (F7). Dogfood: `prove` recorded all ten (E12, E13). Final run E14: ALL PASS. After the phases: Ty decided F1; F8 found in the planned rule (E15). | agent |

Ty reviews all three phases.

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

## D10 follow-up fixes (2026-10-20)

A sub-agent fixed the findings of `thoughts/orbit-kb-d10-review-2026-10-20.md`, test-first,
on the AIMED tier that Ty ratified on 2026-10-20. Nothing is committed. Base commit
1dc093e, dirty. Tree hash `4f9d7f469d2d3d31`: the first 16 hex digits of the sha256 of
`git diff 1dc093e` of the tracked files below (this record excluded), followed by the
seven source files of `scripts/orbit-kb/burn_model/` in the order of the list. E20 to
E23 ran on that tree.

### Findings, fixes, and tests

| Finding | Fix | Tests |
|---|---|---|
| F11 (Ty: yes) and S1 | `burn_reason/1` holds the three reasons. `burn(C) :- burn_reason(C).` and `burn(C) :- supersedes_closure(C, O), burn_reason(O).` The CLI computes `supersedes_closure/2` (a depth-first search over the ground `supersedes/2` facts of kb.pl) when it reads the KB. | SC1, SC2, BP11 (changed: c3 inherits the burn of c1, and `done` is false) |
| L-F2, L-F8, S2, S3 | The CLI also computes `supersede_cycle/1`. Core rule `any_supersede_cycle`. `done` adds `not any_supersede_cycle`. Lint E15 on each `supersedes` fact of a cycle. `add` refuses a fact that makes a cycle, `supersedes(C, C)` too. `report` and `show open` list the cycle. No rule recurses through `supersedes/2`. | SC3, SC4 (both engines answer; no ENGINE DISAGREEMENT, no exit 2), SC5 |
| F8 | Lint E16 (not W6) for a `rules.pl` clause whose head is `done`, `burn`, `burn_reason`, `burn_proved`, `burn_waived`, `burn_open`, `any_burn_open`, `proof_changed`, `waiver_lapsed`, `supersedes_closure`, `supersede_cycle`, or `any_supersede_cycle`. `answer_items/3` keeps these clauses out of both engines, and also a `rules.pl` clause whose head is a fact predicate (E7, for example a waiver), and a kb.pl fact of a protected predicate (E7, for example `burn_proved(c1).`). | SC6, SC7 |
| F10 | `is_time/1` checks month 1-12, the day of the month (leap years: divisible by 4, not by 100 unless by 400), hour 0-23, minute and second 0-59. `add`, `attest`, and lint use it. | SC8 |
| F9 | `waiver_lapsed(W)` also when the due time is not a valid time (`never`, `2020`, `'2999-02-30T00:00:00Z'`), or the predicate is not `waive/3`. `derived_items/3` no longer needs atom ids (L-F5: a lean_proof with id `7` counts as changed). | SC9 |
| F6 | The digest is the sha256 of `claim C`, `theorem T`, `module M`, `statement S`, the `SHA PATH` lines, and the `absent PATH` lines. `proof_state/4` and lint E9 (`proof_log_consistent/3`) check that the header names the claim and the digest of the attestation, and that the log lines give that digest. | SC11 |
| F7 | The log has an `absent PATH` line for each Lake configuration file that does not exist. A file that appears later reopens the burn. `include_str` inputs are a documented limit (README section 15). | PV10 |
| F12 | New tests kill MD, MX, MC, MF, MN, MS, MT (below). | SC10, SC11, PV10, PV11, PV12 |
| F13 | README section 7: "The writer says human; `orbit-kb` cannot verify it." README section 15: the false sentence about `lake-manifest.json` is replaced (a path dependency has no revision). `orbit-kb help prove`: leanchecker replays only the modules under the root and outside `.lake/`. README section 15 has "Known limits" (F1 to F5, L-F5, `include_str`) with the threat-model sentence. Help, README sections 4, 5, 6, 7, 8, 10, 15, and the contract (types, rules, lint, a "D10 follow-up" entry with the digest format) are updated. | `orbit-kb help prove`, `help lint` |
| New: a hang at exit | Found by the conformance runs (below). The CLI ends with `exec sh -c 'exit N'` after it flushes its output and removes its temp files, so no halt hook runs (`exit_now/1`). Fallback: `halt/1`. | the conformance runs; a stress run |

The draft `thoughts/orbital-shifting-system-prompt-draft.md`: the change made two of its
statements false, so the sub-agent fixed only those: the `done` and `burn(C)` rows of the
build-module table, and the first sentence of the BURN section (a claim that supersedes a
burning claim burns too).

Choices where the spec was open (the simplest reading of the review file):

- S1 counts a reason of the old claim only. A claim that supersedes a claim in a cycle
  inherits the burn of the cycle (`supersedes_closure` follows the cycle).
- `add` refuses every `supersedes` fact that closes a cycle, not only `supersedes(C, C)`:
  the check is the same E15 code, and it is cheap.
- E16 covers the predicates of the F8 list, plus `burn`, `burn_reason`, and the new derived
  and helper predicates. Other extensions of library rules stay W6 (for example
  `to_ask/1`, fixture `w6_extension`).
- F8 "keep E7 facts out of `done`": done for `rules.pl` fact clauses and for kb.pl facts of
  protected predicates. Other kb.pl facts that lint rejects can still change an answer
  (L-F5). That is a documented limit.
- F6: the attestation does not hold the theorem, so the theorem and the statement are
  bound to the attestation through the digest. Old logs (made before this change) no
  longer match their digest. Run `orbit-kb prove` again for them. The valid fixture
  (`fixtures/valid/runs/proof-a9.log` and its kb.pl line) has the new digest.

### Evidence

All runs: SWI-Prolog 9.2.9, s(CASP) 1.1.4, Lake 5.0.0 and Lean 4.35.0, Python 3.14.8.

- E16, red run, before any change to the CLI or the library (both clean at 1dc093e; only
  the test suite changed, `git diff` sha256 `ab0671ff77a41ba1`):
  `ONLY='^(BP11|SC[0-9]+|PV1[0-2])$' ORBIT_KB_TEST_JOBS=4 heavy bash scripts/orbit-kb/test_orbit_kb.sh`.
  Expected: the tests of absent behavior fail. Actual: 12 fail, 3 pass. The failures are
  behavior: `supersede_cycle/1 is not declared`; `done` true; lint exit 0 with W5 only or
  W6; `attest` accepts `'2026-99-99T99:99:99Z'`; `waiver_lapsed(X)` has no answer;
  `proof_changed` misses the log copied with an edited header (p2) and the edited
  statement; no `absent lakefile.lean` line. The 3 that pass (SC10, PV11, PV12) test
  behavior that existed: they are the mutant killers for MT, MF, and MN.
  (`add_proof` in the suite still wrote the old digest in this run. It changed with the
  CLI, because it follows the contract's digest format.)
- E17, green run, narrow: `ONLY='^(BP|PV|SC)[0-9]+$' ORBIT_KB_TEST_JOBS=4 heavy bash
  scripts/orbit-kb/test_orbit_kb.sh`. First run: 36 pass, 1 fail. SC1 failed on its own
  defect: it asked `lint --strict` to be clean, but W5 (a check on a superseded claim) is
  correct there. SC1 now asks for `lint` exit 0 and no `E` line. Then 37 of 37 pass.
- E18, mutation runs (F12), with a scratch script (`run_mutants.py` in the session
  scratchpad, not kept; the mutations are listed here): each mutant goes into a scratch copy of the CLI or the
  library, and the suite runs on the copy with `ONLY` set to the killing tests. The real
  files are never changed. Expected: each mutant killed. Actual: each mutant killed.
  - MD, `proof_state` checks only the header, not the digest of the lines: SC11 fails.
  - MX, `proof_state` does not compare the claim (the digest from the log's own claim):
    SC11 fails.
  - MC, the Lake configuration files are not in the digest: PV10 fails.
  - MAB, no `absent` lines (F7): PV10 fails.
  - MF, no check that the module is the module of FILE: PV11 fails.
  - MN, no `lake build --no-build` step: PV12 fails (a `lake` wrapper edits a file of the
    proof while leanchecker runs).
  - MS, the log records the statement as `True`: PV10 fails.
  - MT, waivers compared with the fixed date `2026-10-20T00:00:00Z`: SC10 fails.
  - MI, no inherited burn: BP11, SC1, SC2, SC4 fail.
  - MY, `done` ignores cycles: SC3, SC4 fail.
  - ME15, no E15: SC3, SC4, SC5 fail.
  - ME16, protected `rules.pl` clauses are W6 again: SC6 fails.
  - MIGN, no `answer_items/3` filter: SC6, SC7 fail.
  - MTIME, the time type checks only the shape: SC8, SC9 fail.
  - MDUE, an invalid due time does not lapse: SC9 fails.
  - MQ (leanchecker on the main module only) has no test. It matters only for a
    declaration that skips the kernel in an imported project module, which an honest
    agent does not write, and F1 is not narrowed. The review allowed this.
- E19, the hang at exit. The first two runs of `check.sh` (after the rule change) failed
  only on timeouts: `query done exited 124: no answer after 120 s`, once in the MB run of
  run 1 (e1825) and twice in step 3 of run 2 (e1457, e1885). No KB reproduced it alone
  (0.2 s to 0.7 s, 40 tries each). A stress run (`scratchpad/hang.py`: `query done` on
  all 2760 KBs, 3 in parallel, a fresh cache, a 40 s limit) hung once per pass in 2 of 2
  passes. `eu-stack` of the hung process: the answer `false` was already printed; the
  main thread waited on a mutex in `cleanup <- run_on_halt <- PL_cleanup <- PL_halt`; the
  only other thread was the GC thread, idle. (`hang.py` is a scratch script, not kept.) So a halt hook of a foreign library
  deadlocked after the work was done. It is probably also F6 of the Lean phases (the same
  symptom). After the fix (`exit_now/1`): 2 of 2 stress passes (5520 calls) with 0 hangs
  and no call over 5 s.
- E20, Lean build and axioms: `check.sh` step 2. Requirements v3, 12 requirements.
  Expected: each of the 43 theorems in `Check.lean` uses only `propext`,
  `Classical.choice`, and `Quot.sound`. Actual: yes (run 3 below). The source has no
  `sorry`, no `axiom`, and no `native_decide` (grep of the `.lean` files: only the
  comment in `Check.lean` names them). The witness table prints W13 `(true, false)`,
  W14 `(true, false)`, W15 `(false, false)`, W16 `(false, false)`.
- E21, conformance and discriminating runs: `scripts/orbit-kb/burn_model/check.sh`, run 3, on tree hash
  `4f9d7f469d2d3d31` (below). `check.sh` printed inputs sha256 `e98b755f8b0b6579` and model
  sha256 `089b194bdca97259`. Expected: exit 0. Actual: `ALL PASS`, exit 0, 16 min 10 s.
  Step 3: 2760 of 2760 KBs match the model (`done` true in 514, an open burn in 1256; the
  Lean phases had 1853 and 653, because B1 now inherits and blocks on cycles). Step 4:
  MA differs on 797 (predicted 797), MB 176 (176), MC 299 (299), MI 623 (623), MY 737
  (737). Each matches its mutant on all 2760: DISCRIMINATED. The slowest CLI call: 0.7 s.
  Runs 1 and 2 failed only by the hang of E19, before the fix.
- E22, full suite: `ORBIT_KB_TEST_JOBS=4 heavy bash scripts/orbit-kb/test_orbit_kb.sh`.
  Expected: all pass. Actual: 222 pass, 0 fail, 0 skip (208 at 1dc093e, plus SC1 to
  SC11 and PV10 to PV12; BP11 changed).
- E23, `orbit-kb doctor`: all checks passed (repo copy and installed path).

### The Lean model (amendment v3)

Sources of v3: Ty's decision on A10 and the spec S1 to S3 of the review file, not the
code. But the same agent wrote the CLI change and v3, so v3 is not independent of the
code as v1 was. The sha256 of `Requirements.lean` v3: `dc891abb0b0a44307abc87eebe2a43d2b306fab11510c433a3b6c82eb305099b`.

- `Req.KB` holds the `supersedes` facts. `Req.Reaches` is "one or more steps"
  (`RReach` is the inductive reflexive-transitive closure). `Req.reach` computes it by
  recursion on the list of steps. `Req.reach_iff` proves that the two agree, so the
  witnesses can use `decide`.
- `burns kb c`: one of the three reasons (`ownReason`), or `Reaches` to a claim with one.
  LR1, LR4 to LR6 keep their text and use the new `burns`. LR8 now allows the inherited
  reason. LR2 has the new hypothesis "no cycle". New: LR11 (a claim that reaches a claim
  with a reason burns) and LR12 (`done` implies no cycle). A11: a cycle never gives
  `done`.
- Witnesses: W13 changed (c2 inherits, its burn is open, not `done`; a proof of c2 gives
  `done`). New: W14 a chain, W15 `supersedes(c1, c1)`, W16 a two-claim cycle.
- `Impl`: `burn_reason`, `burn` with two clauses, `supersedes_closure`,
  `supersede_cycle`, `any_supersede_cycle`, `done` with the new literal, and
  `Disk.validTime` in `derive`. New fidelity lemmas: `burn_iff`, `any_supersede_cycle_iff`.
- `Rdz`: on every state, LR1, LR3, LR5 to LR7, LR9 to LR12. LR2 and LR4 hold on the
  states where every replaced claim is a claim (`LR2_of`, `LR4_of`), because `burn` reads
  the closure over the `supersedes` facts and `Req.burns` reads it over the claims. `WF`
  now also asks that both arguments of each `supersedes` fact name a claim (lint E4).
  `implWF_all` proves all twelve. `impl_not_LR8` stays.
- `Conform`: the random set adds a back edge from claim 1 to the last claim (10 %), so
  it has longer cycles, and waivers with the invalid due `'2999-02-30T00:00:00Z'`. Two new
  mutants: MI (no inherited clause) and MY (`done` without the cycle literal).
  `conform_run.py` writes the new digest.

### Not fixed

- F1 to F5: documented limits under the trust threat model (README section 15, "Known
  limits"). L-F5: partly fixed (above); the rest is a documented limit. `include_str`
  inputs: a documented limit.
- MQ: no test (above).

### Files of this work

Changed (tracked):

- `shared/link/.local/bin/orbit-kb`
- `shared/link/.local/share/orbit-kb/core.pl`
- `shared/link/.local/share/orbit-kb/modules/build.pl`
- `shared/link/.local/share/orbit-kb/README.md`
- `scripts/orbit-kb/test_orbit_kb.sh`
- `scripts/orbit-kb/fixtures/valid/kb.pl`
- `scripts/orbit-kb/fixtures/valid/runs/proof-a9.log`
- `thoughts/orbit-kb-contract.md`
- `thoughts/orbital-shifting-system-prompt-draft.md` (two statements, see above)
- `thoughts/orbit-kb-d10-record.md` (this section)

Changed (untracked, in `scripts/orbit-kb/burn_model/`, never committed so far):
`BurnModel/Requirements.lean`, `BurnModel/Impl.lean`, `BurnModel/Rendezvous.lean`,
`Conform.lean`, `Check.lean`, `conform_run.py`, `check.sh`. `.lake/` is in its
`.gitignore`.

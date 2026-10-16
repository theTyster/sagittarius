# RESULTS: s(CASP) `--forall` algorithms on the discovery module (kb-a)

Folder: `/home/ty/.dotfiles/.claude/worktrees/discovery-orbit/thoughts/discovery-orbit-examples/kb-a/`.
Every path below is relative to that folder. Runs were made on 2026-10-15 on one laptop (load average 0.64 at the start).

- s(CASP): `scasp --version` prints `s(CASP) version 1.1.4`. A query run prints `% s(CASP): version 1.1.4 on SWI-Prolog 9.2.9`.
- Reference Prolog: `swipl --version` prints `SWI-Prolog version 9.2.9 for x86_64-linux`.
- "Wrong" always means: different from plain SWI-Prolog (with `not` written as `\+`), or from the answer derived by hand from the rules. I did not look for the cause inside s(CASP); statements about triggers are descriptions of the programs I ran.

## 1. Minimal reproduction (paste-ready known-answer test)

```text
program : repro/min3.pl            (3 clauses, below)
query   : not c
expected: no models
observed: --forall=all and --forall=all_c return a model (wrong);
          --forall=prev and --forall=sasp return "No models" (right);
          SWI-Prolog with \+ c prints "no" (right)
```

### 1.1 Program `repro/min3.pl` (3 clauses, verbatim)

```prolog
a(1, 1, x).
a(2, 1, z).
c :- a(_, _, x).
```

Query: `not c`.

Correct answer: **no models**. `a(1, 1, x)` is a fact, so `c` is true, so `not c` has no model. In SWI-Prolog, `\+ c` fails.

### 1.2 Commands

Run them in the folder. The file contains no `not`, so the same file serves all four commands.

```sh
timeout 30 scasp --unknown=error --forall=all  -s 0 --query='not c' repro/min3.pl
timeout 30 scasp --unknown=error --forall=prev -s 0 --query='not c' repro/min3.pl
timeout 30 scasp --unknown=error --forall=sasp -s 0 --query='not c' repro/min3.pl
timeout 30 swipl -g "(\+ c -> writeln(yes) ; writeln(no)), halt" repro/min3.pl
```

### 1.3 Outputs

| Command | Output | Correct? |
|---|---|---|
| `--forall=all` | `Answer 1 (0.001 sec)`, a model, `true` (full output below) | no |
| `--forall=prev` | `Warning: s(CASP): No models (0.000 seconds)` | yes |
| `--forall=sasp` | `Warning: s(CASP): No models (0.000 seconds)` | yes |
| `swipl`, goal `\+ c` | `no` | yes |

The command without any `--forall` option prints the same output as `--forall=all`. Full output of the `all` run:

```text
% Query
?- not c.
% ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
%                         Answer 1 (0.001 sec)                          
% ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
% Model
{ not c,
  not a(_ | {_ ∉ [1,2]},_ | {_ ∉ [1]},x),
  not a(1,_ | {_ ∉ [1]},x),
  not a(2,_ | {_ ∉ [1]},x),
  not a(2,1,x)
}
% No bindings
true
```

The `not a(...)` literals in that model cover argument pairs whose second value is not 1, and the pair (2,1). No literal covers the pair (1,1), and `a(1,1,x)` is a fact.

Controls on the same file: the query `c` has a model under all, prev, and sasp, and `swipl` with goal `c` prints `yes`. So under `all`, both `c` and `not c` have a model.

### 1.4 The same failure with the negation inside a rule: `repro/min4.pl` (4 clauses)

```prolog
a(1, 1, x).
a(2, 1, z).
c :- a(_, _, x).
l :- not c.
```

Query `l`. Correct answer: no models.

| Algorithm | Answer for `l` | Correct? |
|---|---|---|
| all | a model (0.04 s) | no |
| prev | no models | yes |
| sasp | no models | yes |
| all_c | 2 answers, both `true` | no |
| SWI, file `repro/min4-plain.pl` (`l :- \+ c.`), goal `l` | `no` | yes |

The form with a head variable behaves the same way. `repro/min4-head.pl` is `a(1, 1, x). a(2, 1, z). c(X) :- a(_, _, X). l :- not c(x).`; query `l` gives a model under `all`, and no models under `prev` and `sasp`.

### 1.5 Smallest change that makes `all` correct

Change the program text so that every rule has at most one body-only variable. `repro/min3-chain1.pl` replaces the last clause of `repro/min3.pl` with one helper rule and a changed body:

```prolog
a(1, 1, x).
a(2, 1, z).
a2(Y, Z) :- a(_, Y, Z).
c :- a2(_, x).
```

For this file, query `not c` gives no models under all, prev, and sasp. Query `c` gives a model under `all`. `swipl` with goal `\+ c` prints `no`. `repro/min3-chain2.pl` (two helpers, the shape proposed for Test 2) gives the same results. `repro-bodyvars.py` confirms that both files have at most one body-only variable per rule (`repro/min3.pl` has two in `c`).

Change the command line instead: `--forall=prev` or `--forall=sasp` gave the correct answer for this file and in every other check in this document where I ran them (section 10).

On the real knowledge base, chaining only `finding_confirmed` was not enough. See Test 2 (section 7).

### 1.6 What triggers it (observed in the programs I ran; not a proof)

- At least two facts for the negated predicate. All 25 programs with one fact were correct.
- At least two body-only variables to the left of the discriminating argument in one body literal. With one such variable or none, all 100 programs were correct. The number of body-only variables to the right of it made no difference.
- The facts must differ in a leading column. When all non-key columns were identical in every fact, all 160 programs were correct (section 5.3).
- Fact order made no difference (section 5.4).
- With compound arguments such as `v(x)` against `v(y)`, wrong answers also appeared with fewer leading variables (section 5.6).
- For atoms in the argument, 184 of 184 programs in the pattern experiment fit this rule: `all` is wrong exactly when some column at least two places to the left of the key column holds different values in the two facts.
- `all` also gets slow: 13.9 s on one 4-fact program, against at most 0.06 s for `prev` on any program of that grid.

## 2. Method and exact commands

All s(CASP) runs have this form. `ALGO` is `all`, `prev`, `sasp`, or `all_c`. `Q` is the query. The `-s 0` option asks for all answers. The wall time comes from `/usr/bin/time -f '%e %x'` around `timeout 30 scasp ...`. The "internal" time is the one s(CASP) prints with the last answer or with "No models".

```sh
timeout 30 scasp --unknown=error --forall=ALGO -s 0 --query='Q' core-min.pl discovery.pl kb.pl
```

- The `all_c` runs went through the machine's job queue: `heavy /usr/bin/time ... timeout 30 scasp ...`. The wall time is measured inside `heavy`, so it excludes the queue wait.
- `run-one.sh ALGO[:COUNT] QUERY FILE...` runs one query that way and prints one summary line. `raw-output.log` holds the first 300 lines of output of every run made with it after the baseline runs for `all`, `prev`, and `sasp`. The header of each block names the algorithm, the query, and the files (runs after the `all_c` baseline also show the full command line). The 21 baseline runs for `all`, `prev`, and `sasp` were summarized on the console only, and the table in section 3 copies their summary lines.
- Exit code 124 means that `timeout` killed the process.
- All times are single runs.

Counterfactual KB variants (each differs from `kb.pl` by exactly one line, checked with `diff`):

```sh
grep -v 'answer(q1' kb.pl > kb-cf1.pl
grep -v '^attest(a3,' kb.pl > kb-cf2.pl
grep -v '^attest(a4,' kb.pl > kb-cf3.pl
grep -v 'raised_by(q1, f2)' kb.pl > kb-cf4.pl
sed 's/verdict(mutation(clamp), killed)/verdict(mutation(clamp), survived)/' kb.pl > kb-cf5.pl
cp kb-cf5.pl kb-cf5b.pl; echo "reason(clamp, 'redundant')." >> kb-cf5b.pl
```

## 3. Baseline suite (core-min.pl + discovery.pl + kb.pl)

Cell format: answer, wall seconds (internal seconds). **Bold** marks a wrong answer.

| Query | Correct | all | prev | sasp | all_c |
|---|---|---|---|---|---|
| `discovery_ready` | a model | model, 0.12 (0.044) | model, 0.08 (0.028) | model, 0.11 (0.033) | **no end**: killed at 30.00; printed the same model 9914 times |
| `question_waits(Q)` | no models | no models, 0.07 (0.001) | no models, 0.06 (0.001) | no models, 0.07 (0.001) | no models, 0.06 (0.001) |
| `no_falsifier(C)` | no models | **C = c1 and C = c2b**, 0.09 (0.010) | no models, 0.07 (0.020) | no models, 0.17 (0.111) | **no end**: killed at 30.00; printed `C = c1` 19959 times, never `c2b` |
| `finding_lead(F)` | no models | **F = f1**, 0.26 (0.194) | no models, 0.06 (0.004) | no models, 0.06 (0.007) | **no end**: killed at 30.00; printed `F = f1` 22862 times |
| `unasked_finding(F)` | no models | no models, 0.06 (0.001) | no models, 0.06 (0.000) | no models, 0.05 (0.001) | no models, 0.07 (0.001) |
| `weak_rule(R)` | no models | no models, 0.06 (0.000) | no models, 0.06 (0.000) | no models, 0.05 (0.000) | no models, 0.07 (0.000) |
| `some_current_refuted` | no models | no models, 0.06 (0.000) | no models, 0.05 (0.000) | no models, 0.05 (0.000) | no models, 0.05 (0.000) |

Correct on all 7 queries: `prev` and `sasp`. `all`: 5 of 7. `all_c`: 4 of 7 finished, and the 3 others did not end.

Extra runs on the same files:

- `all_c` with one answer (`-s 1`) ends quickly and gives the same wrong answers: `finding_lead(F)` gives `F = f1` (0.23 s), `no_falsifier(C)` gives `C = c1` (0.07 s), `discovery_ready` gives a model (0.09 s).
- Under `all`, an atom and its negation both have a model: `no_falsifier(c1)` and `not no_falsifier(c1)`, and `finding_lead(f1)` and `not finding_lead(f1)`. Under `prev`, `no_falsifier(c1)` has no model and `not no_falsifier(c1)` has one.
- `discovery_ready` has a model under `all` although `no_falsifier(C)` also has models there, and `discovery_ready` needs `not some_no_falsifier`.

## 4. Counterfactuals

Cell format: answer, wall seconds. **Bold** marks a wrong answer. "Expected" is the result given in the task.

| KB | Change | Query | Expected | all | prev | sasp |
|---|---|---|---|---|---|---|
| CF1 | remove `answer(q1, floor_wins, human).` | `question_waits(Q)` | Q = q1 | Q = q1, 0.06 | Q = q1, 0.06 | Q = q1, 0.06 |
| CF1 | same | `discovery_ready` | no models | no models, 0.06 | no models, 0.06 | no models, 0.05 |
| CF2 | remove the `attest(a3, ...)` line | `no_falsifier(C)` | c1 and c2b | c1 and c2b, 0.08 | c1 and c2b, 0.08 | c1 and c2b, 0.07 |
| CF2 | same | `discovery_ready` | no models | no models, 0.06 | no models, 0.05 | no models, 0.08 |
| CF3 | remove the `attest(a4, ...)` line | `finding_lead(F)` | f1 | F = f1, 0.06 | F = f1, 0.06 | F = f1, 0.06 |
| CF4 | remove `raised_by(q1, f2).` | `unasked_finding(F)` | f2 | F = f2, 0.05 | F = f2, 0.06 | F = f2, 0.06 |
| CF4 | same | `discovery_ready` | no models | no models, 0.06 | no models, 0.06 | no models, 0.06 |
| CF5 | `killed` changed to `survived` | `weak_rule(R)` | clamp | R = clamp, 0.06 | R = clamp, 0.06 | R = clamp, 0.06 |
| CF5 | same | `discovery_ready` | no models | **a model**, 1.25 (1.168) | no models, 0.10 | no models, 0.11 |
| CF5b | CF5 plus `reason(clamp, 'redundant').` | `weak_rule(R)` | no models | no models, 0.05 | no models, 0.06 | no models, 0.06 |

Result: `prev` and `sasp` matched the expected result in 10 of 10 checks. `all` matched in 9 of 10. Its wrong answer is `discovery_ready` in CF5: `all` says "ready" although `weak_rule(clamp)` holds.

Note for CF2 and CF3: in the base KB, `all` already returns `c1` and `c2b` for `no_falsifier(C)` and `f1` for `finding_lead(F)`. So those two rows do not show that `all` reacts to the removed fact.

## 5. Minimal reproduction study

Setup for sections 5.1 to 5.5: the query is `l` or `not c`, the correct answer is always "no models", and wrong means "a model". Each table row is from a TSV file in `repro/`. The programs are generated by the `repro-*.py` scripts in this folder.

### 5.1 Starting program from the task

`repro/start.pl`:

```prolog
a(1, x, y).
a(2, z, w).
c(X) :- a(_, X, _).
l :- not c(x).
```

Query `l`: no models under `all`, `prev`, `sasp`, and `all_c`. All correct. This program has one body-only variable before the key and one after it.

### 5.2 Grid over body-only variables and number of facts

File: `repro/grid-b0-4-e0-4-n1-4.tsv` (750 rows, 250 programs times 3 algorithms). Command: `python3 -I repro-grid.py 4 4 4 repro/grid > repro/grid-b0-4-e0-4-n1-4.tsv`.

Program family: `n` facts `a(...)` of arity `b+1+e`. Each row has its own constants in the filler columns. The key column (number `b+1`) holds `x` in one fact and `z` in the others. The rule is `c(X) :- a(_, ..., X, ..., _).` with `b` anonymous variables before `X` and `e` after it. The query is `l :- not c(x).`. The matching fact is in position `p`.

Totals: `all` wrong on 135 of 250 programs. `prev` wrong on 0 of 250. `sasp` wrong on 0 of 250.

Wrong answers of `all`, by `b` (rows) and `n` (columns), counted over all `e` from 0 to 4 and all positions `p`:

| b | n=1 | n=2 | n=3 | n=4 |
|---|---|---|---|---|
| 0 | 0/5 | 0/10 | 0/15 | 0/20 |
| 1 | 0/5 | 0/10 | 0/15 | 0/20 |
| 2 | 0/5 | 10/10 | 15/15 | 20/20 |
| 3 | 0/5 | 10/10 | 15/15 | 20/20 |
| 4 | 0/5 | 10/10 | 15/15 | 20/20 |

The same data by total number of body-only variables `k = b + e` in `c/1` (wrong means wrong for `n` from 2 to 4):

| k | (b,e) splits with wrong answers | (b,e) splits without wrong answers |
|---|---|---|
| 1 | none | (1,0) (0,1) |
| 2 | (2,0) | (1,1) (0,2) |
| 3 | (3,0) (2,1) | (1,2) (0,3) |
| 4 | (4,0) (3,1) (2,2) | (1,3) (0,4) |

So `all` starts to fail at `b = 2` and `n = 2`. The total `k` does not decide it. A single body-only variable (`c(X) :- a(_, X).` with arity-2 facts, which is `b=1, e=0`) was correct in all 10 programs (`n` from 1 to 4, every position).

Wall time of `all`, the maximum over all programs with the same `n`: 0.08 s (n=1), 0.33 s (n=2), 1.61 s (n=3), 13.9 s (n=4, b=4, e=4, p=4). The maximum for `prev` was 0.06 s and for `sasp` 0.12 s.

### 5.3 Same grid with shared filler constants

File: `repro/grid-shared-b0-3-e0-3-n1-4.tsv` (480 rows, 160 programs times 3 algorithms). Command: `python3 -I repro-grid.py 3 3 4 repro/grid-shared shared > repro/grid-shared-b0-3-e0-3-n1-4.tsv`. All non-key columns hold the same constants in every fact.

Result: no wrong answer from any algorithm in 160 programs, including the `b = 2` and `b = 3` rows that fail in section 5.2.

### 5.4 Which columns must differ, and does fact order matter

File: `repro/patterns.tsv` (184 rows). Two facts of arity `M` (3 to 5), key column `J` holds `x` in the matching fact and `z` in the other one, and each other column holds the same value (S) or a different value (D) in the two facts. All 2^(M-1) patterns were run with the matching fact first and with it second. The body is `c :- a(_, ..., x, ..., _).`, the query is `l :- not c.`. Commands: `python3 -I repro-patterns.py M J repro/pat >> repro/patterns.tsv` for (M,J) = (3,3) (3,2) (3,1) (4,4) (4,3) (4,2) (4,1) (5,5) (5,4) (5,3). The first command used `>` instead of `>>`. The generated programs use constants such as `m1` and `o1`.

- `all` was wrong in 92 of the 184 programs. `prev` and `sasp` were wrong in none.
- Fact order made no difference. In all 92 pairs, "matching fact first" and "matching fact second" gave the same result.
- All 184 results fit this description: `all` is wrong exactly when the two facts differ in some non-key column that is at least two places to the left of the key column. For `J` = 1 or 2 there was no wrong answer.
- Results for `M = 3, J = 3`: pattern DS (the shape of `a(1,1,x). a(2,1,z).`) is wrong, DD is wrong, SD (the shape of `a(1,1,x). a(1,2,z).`) is correct, SS is correct. Hand-made programs of these shapes (`repro/variants-4.txt` M1, `repro/variants-5.txt` E4, `repro/variants-9.txt` Z3 and Z4) gave the same results.

In the grid of section 5.2, the matching fact was in every position `p` from 1 to `n`. All positions were wrong for `b >= 2`, `n >= 2`.

### 5.5 Shapes with constants in several columns

Files: `repro/types-m3.tsv`, `repro/types-m4.tsv`, `repro/types-m5.tsv` (242 programs, atoms only). Commands: `python3 -I repro-types.py M repro/types > repro/types-mM.tsv` for M = 3, 4, 5. Each program has two facts of arity `M` and a rule `c :- a(...)` that mixes anonymous variables (F) and constants (K). Fact 1 matches the body. Fact 2 holds a different constant in the listed K columns ("mismatch columns") and the same constant in the other K columns. In the F columns the two facts hold different constants.

- `all` wrong in 40 of 242 programs (1 for M=3, 7 for M=4, 32 for M=5). `prev` and `sasp` wrong in none.
- All 242 results fit this description: `all` is wrong exactly when at least two F columns come before the first K column in which fact 2 differs from the body.

### 5.6 Compound arguments, and the shape of the real attest facts

These small programs are in `repro/variants-1.txt` to `repro/variants-9.txt` (99 programs). Run: `python3 -I repro-try.py repro/variants-N.txt [QUERY]`. In all 99, `prev` and `sasp` gave the answer derived by hand (no models for 97 programs and a model for 2 programs whose negated goal is false in the program). `all` was wrong in 36 of the 99 (the programs that the script marks FAIL: 7 in `variants-1`, 0 in `-2`, 8 in `-3`, 3 in `-4`, 6 in `-5`, 1 in `-6`, 6 in `-7`, 3 in `-8`, 2 in `-9`).

- Atoms against compounds in the same column layout (`repro/variants-7.txt`): with the 6-column layout of `attest/6`, atoms `sat` against `killed` in column 4 (W2) were correct, and the compounds `v(sat)` against `v(killed)` (W4) were wrong.
- Compounds with few leading variables (`repro/variants-8.txt`): `a(_, v(x), _)` (X1), `a(_, _, v(x))` (X3), and `a(v(x), _, _)` (X4) were wrong with facts that carry `v(y)` in that column. The arity-2 forms `a(_, v(x))` (X2) and `a(v(x), _)` (X5) were correct. X1 (one leading variable) and X4 (no leading variable) were wrong where the atom versions of the same layout (shapes FKF and KFF in section 5.5) were correct. Putting the three values into one compound or list argument (`a(t(_, _, x))`, `a([_, _, x])`, Z1 and Z2 in `repro/variants-9.txt`) was correct.
- Arity of the real fact (`repro/variants-1.txt`): `fc(F) :- attest(_, reproduction, _, confirms(F), _, _)` with two facts (a `result(...)` fact and a `confirms(f1)` fact) was wrong at arity 6, 5, and 4 (4, 3, and 2 body-only variables), and correct at arity 3 and 2 (1 and 0 body-only variables).

### 5.7 Reduction of the real KB

- `python3 -I repro-reduce.py repro/p1-full.pl 2` reduced the eight `attest` facts plus the rule to two facts (a1 and a4). The reducer's program named the rule `fc`; `repro/real-finding.pl` is the same program with the module's name `finding_confirmed`. Under `l :- not finding_confirmed(f1).`: `all` gives a model; `prev` and `sasp` give no models.
- `python3 -I repro-reduce.py repro/ms-full.pl 1 l` reduced the `model_sane` check to two facts (a5 and a8): `repro/real-modelsane.pl`. Under `l :- not model_sane(m_target).`: `all` gives a model; `prev` and `sasp` give no models.
- `python3 -I repro-reduce.py repro/kb-oneline.pl 0 'no_falsifier(C)'` reduced the whole module (106 clauses) to 16 clauses, kept in `repro/rd-nofals.pl`. On it, `all` still returns `C = c2b`. The reduced program has 8 rules (`superseded`, `current`, `model_sane`, `model_calibrated`, two `model_trusted` clauses, `has_falsifier`, `no_falsifier`) and 8 facts (a claim, a `supersedes`, a `derived_from`, an `encodes`, and the attestations a2, a3, a5, a8). Probes on that file under `all`: `not model_sane(m_target)`, `not model_trusted(m_target)`, and `not has_falsifier(c2b)` each have a model, which is wrong because all three goals are true in the program. `not model_sane(m_now)`, `not model_calibrated(m_now)`, and `not model_trusted(m_now)` each have no model, which is right. The wrong ones involve `m_target`, which has two `model_result` attestations (a5 and a8); `m_now` has one.
- The rules of the module with two or more body-only variables, by `repro-bodyvars.py`: in `core-min.pl`, `current/1` (2) and `refuted/1` (5); in `discovery.pl`, `model_sane/1` (3, twice), `model_calibrated/1` (4), `needs_question/1` (2, three times), `finding_confirmed/1` (4), `weak_rule/1` (4), and `touched_system/0` (6).

## 6. Test 1: the shared core's `passed/1`

Rules, verbatim (`repro/passed-a.pl` and the other cases; the plain-SWI copies have `\+` in place of `not`, made with `sed 's/, not failed_after/, \\+ failed_after/'`):

```prolog
check(k1, c1).
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _), attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
```

Facts: `attest(aN, test_result, k1, result(k1, N, pass|fail), script, '2026-10-15T10:00:00Z').`, one per run, in run order. Cases: (a) pass, fail. (b) fail, pass. (c) pass, fail, pass. (d) pass. Files `repro/passed-a.pl` to `repro/passed-d.pl`, with `-plain.pl` copies for SWI.

Commands (example for case (a); `--query` is `passed(k1)`, `was_red(k1)`, or `not was_red(k1)`; for SWI the goal is `passed(k1)`, `was_red(k1)`, or `\+ was_red(k1)`):

```sh
timeout 30 scasp --unknown=error --forall=all  -s 0 --query='passed(k1)' repro/passed-a.pl
timeout 30 scasp --unknown=error --forall=prev -s 0 --query='passed(k1)' repro/passed-a.pl
timeout 30 scasp --unknown=error --forall=sasp -s 0 --query='passed(k1)' repro/passed-a.pl
timeout 30 swipl -g "(passed(k1) -> writeln(yes) ; writeln(no)), halt" repro/passed-a-plain.pl
```

"Correct" is the SWI answer. For `passed(k1)` and `was_red(k1)` it is also the answer given in the task. **Bold** marks a wrong answer.

| Case | Query | Correct | all | prev | sasp | SWI |
|---|---|---|---|---|---|---|
| (a) pass, fail | `passed(k1)` | no model | **model** | no model | no model | no |
| (a) | `was_red(k1)` | no model | no model | no model | no model | no |
| (a) | `not was_red(k1)` | model | model | model | model | yes |
| (b) fail, pass | `passed(k1)` | model | model | model | model | yes |
| (b) | `was_red(k1)` | model | model | model | model | yes |
| (b) | `not was_red(k1)` | no model | **model** | no model | no model | no |
| (c) pass, fail, pass | `passed(k1)` | model | model, printed twice | model | model | yes |
| (c) | `was_red(k1)` | model | model | model | model | yes |
| (c) | `not was_red(k1)` | no model | **model** (0.78 s) | no model | no model | no |
| (d) pass | `passed(k1)` | model | model | model | model | yes |
| (d) | `was_red(k1)` | no model | no model | no model | no model | no |
| (d) | `not was_red(k1)` | model | model | model | model | yes |

In case (c), plain SWI finds exactly one solution for `passed(k1)`.

Differential sweep (started before the instruction to start no new sweeps; it finished all 240 rows): `repro/passed-sweep-n1-4.tsv`, made by `python3 -I repro-passed-sweep.py 4 repro/pass-sweep`. It covers every pass/fail sequence of 1 to 4 runs (30 sequences), with the facts in run order and in reverse order, and four queries (`passed(k1)`, `was_red(k1)`, `not passed(k1)`, `not was_red(k1)`). That is 240 rows. Reference: plain SWI with `\+`.

| Algorithm | Rows that differ from SWI (of 240) |
|---|---|
| all | 76 (22 `passed(k1)`, 22 `not passed(k1)`, 32 `not was_red(k1)`, 0 `was_red(k1)`) |
| prev | 0 |
| sasp | 0 |

All 76 wrong answers of `all` are a model where SWI says no. `all` was wrong for `passed(k1)` on the 11 sequences that contain a pass and end with a fail (PF, PPF, PFF, FPF, PPPF, PPFF, PFPF, PFFF, FPPF, FPFF, FFPF), in both fact orders. It was wrong for `not was_red(k1)` on all 16 sequences with a fail before a pass.

Non-ground check (one extra program, `repro/passed-multi.pl`; k1 = pass,fail; k2 = fail,pass; k3 = pass; k4 = pass,fail,pass). Expected `passed(K)`: k2, k3, k4.

| System | Answers for `passed(K)` |
|---|---|
| all | **K = k1, K = k2, K = k3** (printed in 0.006 s), then no end: killed at 30 s (exit 124) |
| prev | K = k2, K = k3, K = k4 (0.10 s) |
| sasp | K = k2, K = k3, K = k4 (0.10 s) |
| SWI (`findall` and `sort`, file `repro/passed-multi-plain.pl`) | `[k2,k3,k4]` |

The claim that `prev` is unsound when an arithmetic comparison links variables under `not` did not show up in these runs: 0 differences from SWI in the 240 sweep rows, the 12 case checks, and the non-ground check.

## 7. Test 2: chained projection

The chain, as given:

```prolog
att5(I, Ty, S, P, B) :- attest(I, Ty, S, P, B, _).
att4(I, Ty, S, P) :- att5(I, Ty, S, P, _).
att3(Ty, S, P) :- att4(_, Ty, S, P).
attests(Ty, P) :- att3(Ty, _, P).
finding_confirmed(F) :- attests(reproduction, confirms(F)).
```

Two variants of the module were built:

- **7.1 Literal Test 2**: `discovery-chain.pl` is `discovery.pl` with only the `finding_confirmed` rule replaced by the chain (`diff` shows only that change). Files: `core-min.pl discovery-chain.pl kb.pl` and `... kb-cf3.pl`.
- **7.2 Every rule chained**: `core-min-chain.pl` and `discovery-chain-all.pl` rewrite every rule that had two or more body-only variables, using the same chain plus `finding_kind/2`, `claim_c/2`, and `is_result/1`. `repro-bodyvars.py` reports at most one body-only variable per rule in both files. Files: `core-min-chain.pl discovery-chain-all.pl kb.pl` and `... kb-cf3.pl`. I compared answers with the original module only on the queries below. I did not prove that the rewrite means the same thing.

Cell format: answer, wall seconds. **Bold** marks a wrong answer. For `discovery_ready` in CF3 I derived "model" by hand: no rule of the gate uses `finding_lead`, and `touched_system` still holds.

| KB | Query | Correct | 7.1 all | 7.1 prev | 7.1 sasp | 7.2 all | 7.2 prev | 7.2 sasp |
|---|---|---|---|---|---|---|---|---|
| base | `finding_lead(F)` | no models | no models, 0.17 | no models, 0.08 | no models, 0.08 | no models, 0.20 | no models, 0.09 | no models, 0.15 |
| base | `no_falsifier(C)` | no models | **c1 and c2b**, 0.10 | no models, 0.10 | no models, 0.18 | no models, **1.60** | no models, 0.13 | no models, 0.26 |
| base | `discovery_ready` | model | model, 0.10 | model, 0.11 | model, 0.11 | model, 0.52 | model, 0.26 | model, 0.23 |
| CF3 | `finding_lead(F)` | f1 | f1, 0.09 | f1, 0.08 | f1, 0.07 | f1, 0.09 | f1, 0.08 | f1, 0.08 |
| CF3 | `no_falsifier(C)` | no models | **c1 and c2b**, 0.09 | no models, 0.09 | no models, 0.18 | no models, **1.18** | no models, 0.12 | no models, 0.23 |
| CF3 | `discovery_ready` | model | model, 0.11 | model, 0.11 | model, 0.10 | model, 0.43 | model, 0.21 | model, 0.20 |

Answer to "does the default `all` become correct?":

- With only `finding_confirmed` chained (7.1), `all` became correct for `finding_lead(F)` but still returned `c1` and `c2b` for `no_falsifier(C)`, in the base KB and in CF3.
- With every rule down to at most one body-only variable (7.2), `all` matched `prev` and `sasp` and the correct answer on all 6 checks. It was slower: `no_falsifier(C)` took 1.60 s and 1.18 s, against 0.13 s and 0.12 s for `prev`.
- Not tested: the 7.2 files on CF1, CF2, CF4, CF5, and CF5b. So I do not know whether the rewrite also fixes `discovery_ready` in CF5.
- On the 3-clause program (section 1.5), a chain with one or two helpers also made `all` correct.

## 8. Comparison with the parent session's measurement

| Item | Parent session | This run | Same? |
|---|---|---|---|
| Ground `passed(k1)`, 4 sequences | `prev`, `sasp`, SWI correct on all four; `all` says yes for pass,fail | same on all four | yes |
| Non-ground `passed(K)`, k1..k4 | `prev`, `sasp`, SWI: k2, k3, k4; `all`: k1, k2, k3 | same answers | yes |

Differences in detail, none of them in an answer:

1. In my non-ground run, `all` printed k1, k2, k3 within 0.006 s and then did not end before the 30 s limit (exit 124). I do not know how the parent session limited its run.
2. In case (c) (pass, fail, pass), `all` printed the correct answer for `passed(k1)` twice.
3. In addition to the parent's checks, `all` was wrong for `not was_red(k1)` in cases (b) and (c). `prev` and `sasp` were not wrong there.

## 9. Other observations

1. **`all` answers wrong in the readiness gate.** In CF5, `discovery_ready` has a model under `all` although `weak_rule(clamp)` holds (section 4).
2. **`all` is inconsistent.** An atom and its negation both have a model (section 3). In the minimal program, `c` and `not c` both have a model.
3. **`all_c` repeats the same answer without end.** With `-s 0`, it printed one model 9914 to 22862 times in 30 s on three queries. It does not hang silently. With `-s 1` it returns at once with the same wrong answers.
4. **Atoms that end in `_` and digits lose that ending when s(CASP) loads a file.** `repro/suffix.pl`:

   ```prolog
   p(order_1).
   p(order_2).
   p(abc_12x).
   p(item_007).
   q :- p(order_1).
   r :- order_1 = order_2.
   ```

   `scasp --code --short repro/suffix.pl` prints the loaded program as `p(order).`, `p(order).`, `p(abc_12x).`, `p(item).`, `q :- p(order).`, and `r :- order=order.`. SWI-Prolog lists `[order_1,order_2,abc_12x,item_007]`. Under `prev`: the query `p(X)` gives `order` twice, `abc_12x`, and `item`; `p(order_1)` as a query has no model; `p(order)` has two answers; `r` has a model. `kb.pl` has `order_4417` in two facts, and the models print it as `order` (for example `matches(order)`). The query `attest(a3, calibration, M, matches(order_4417), agent, T)` has no model, and the same query with `matches(order)` has one. In this KB the loss is harmless. In `repro/suffix.pl`, the two ids `order_1` and `order_2` became the same atom (`r` has a model).
5. **The failing programs are data-dependent.** The same rule is correct when the facts share their leading columns (section 5.3).
6. **Run time of `all` grows fast with the number of facts** in the failing family (section 5.2).

## 10. Conclusion

With s(CASP) 1.1.4, the default `--forall=all` and `--forall=all_c` returned wrong answers for goals under `not` whenever the negated predicate was defined by two or more facts that differ in a leading column and the matching body literal had two or more body-only variables before the discriminating argument (fewer, for compound arguments). The smallest program that shows it has three clauses (`repro/min3.pl`, query `not c`, correct answer "no models"). In the discovery module this gave a false `no_falsifier(C)` and a false `finding_lead(F)` on the base KB, a false "ready" in CF5, and a wrong set of answers for `passed(K)`. `--forall=prev` and `--forall=sasp` gave the expected answer in every check I ran: 7 of 7 baseline queries, 10 of 10 counterfactual checks, 250 and 160 grid programs, 184 pattern programs, 242 shape programs, 99 hand-made variants, 12 `passed/1` case checks, 240 sweep rows (equal to plain SWI-Prolog), the non-ground `passed(K)` check, and the 12 Test 2 checks; I did not reproduce a wrong answer from `prev` with arithmetic under `not`. Rewriting every rule to have at most one body-only variable made `all` agree with `prev` and `sasp` on the minimal program and on 6 knowledge-base checks, but chaining only `finding_confirmed` fixed `finding_lead(F)` and left `no_falsifier(C)` wrong, and the full rewrite made `all` about ten times slower than `prev` on `no_falsifier(C)`. These results cover s(CASP) 1.1.4 on SWI-Prolog 9.2.9 and the programs listed here; other versions, options such as `--dcc`, and other program shapes were not tested.

## 11. Files

Main files (all in the folder):

- `repro/min3.pl`, `repro/min4.pl`, `repro/min4-plain.pl`, `repro/min4-head.pl`, `repro/min3-chain1.pl`, `repro/min3-chain2.pl`: section 1.
- `core-min.pl`, `discovery.pl`, `kb.pl` (inputs, not edited); `kb-cf1.pl` to `kb-cf5b.pl`: counterfactual KBs.
- `discovery-chain.pl`, `core-min-chain.pl`, `discovery-chain-all.pl`: Test 2 variants.
- `repro/passed-a.pl` to `repro/passed-d.pl`, `-plain.pl` copies, `repro/passed-multi.pl`, `repro/passed-multi-plain.pl`, `repro/passed-sweep-n1-4.tsv`: Test 1.
- `repro/grid-b0-4-e0-4-n1-4.tsv`, `repro/grid-shared-b0-3-e0-3-n1-4.tsv`, `repro/patterns.tsv`, `repro/types-m3.tsv`, `repro/types-m4.tsv`, `repro/types-m5.tsv`, `repro/variants-1.txt` to `repro/variants-9.txt`: section 5. The generated programs are in `repro/grid`, `repro/grid-shared`, `repro/pat`, `repro/types`, and `repro/pass-sweep`.
- `repro/start.pl`, `repro/real-finding.pl`, `repro/real-modelsane.pl`, `repro/rd-nofals.pl`, `repro/suffix.pl`, `repro/attest8.pl`, `repro/p1-rule.pl`, `repro/p1-full.pl`, `repro/ms-full.pl`, `repro/kb-oneline.pl`: reductions and probes.
- Scripts: `run-one.sh`, `repro-grid.py`, `repro-patterns.py`, `repro-types.py`, `repro-try.py`, `repro-reduce.py`, `repro-passed-sweep.py`, `repro-bodyvars.py`.
- `raw-output.log`: raw output of the runs made with `run-one.sh` after the baseline for `all`, `prev`, and `sasp`.

Appendix: compiled dual rules for `repro/min3.pl` (`scasp --code --long repro/min3.pl`, dual part for `c`):

```text
not c :-
    not o_d_c_1.

not o_d_c_1 :-
    forall(A, forall(B, not o_d_c_1_vh2(A, B))).

not o_d_c_1_vh2(A, B) :-
    not a(A, B, x).
```

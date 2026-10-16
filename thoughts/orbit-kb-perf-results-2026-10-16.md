# orbit-kb s(CASP) performance investigation (2026-10-16)

Copied from the session scratchpad (`perf/scasp-agent/RESULTS.md`) so the evidence survives. Paths below point at that scratchpad, which is gone after the session. The harnesses are not kept; the README (section 11 and 15) summarizes the method.

# s(CASP) cross-check performance: results (2026-10-16)

All paths below are under
`/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad/perf/scasp-agent/`.
No repository file was edited.

## 1. Root cause

The time goes into the s(CASP) **forall over body-only variables** in the duals of
rules that read `attest/6`, and into the **CHS (proved-goal) scans** that each step of that
forall does.

- `scasp --code` shows the dual of `passed/1`:
  `not o_passed_1(A) :- forall(B, forall(C, forall(D, forall(E, forall(F, not o_passed_1_vh6(A,B,C,D,E,F))))))`.
  `failed_after/2` has 5 nested foralls, `was_red/1` 10, `refuted/1` 5. Each forall step
  solves `not attest(...)` with free variables. That is a conjunction over all N attest
  facts of per-argument disequalities. The forall then enumerates every value that the
  disequalities name (`exec_with_neg_list`), and for each value it solves the next forall.
- `solve.pl` `exec_with_neg_list/10` copies the whole goal **and the whole stack** for
  every value (`my_copy_term(Var, [Goal, StackIn], ...)`), so each step costs O(stack).
  `check_CHS` then scans all proved goals with the same functor
  (`ground_neg_in_stack_`, `contrained_neg`).
- In-process profile (`prof/drv.pl`, which calls `scasp_load/2` + `solve/4`; this is the
  way to call it in-process) of raw `passed(k1)`:

  | attestations | time | copy_term_nat | ground_neg_in_stack_ calls |
  |---|---|---|---|
  | 20 | 0.07 s | 419 calls, 29 % | (below top) |
  | 40 | 0.35 s | 819 calls, 26 % | 622,973 |
  | 100 | 5.75 s | 2,019 calls, 43 % | 8,673,353 |

  Growth is about N^3 for one negated goal. `not any_under` adds one more forall (over
  claims) whose every step re-solves `not under(c)` with a bigger stack, so `done` times out
  at 20 attestations.
- It is not justification building (`--tree` adds little), not `--nmr/--olon`, and not
  the forall algorithm choice (`sasp` is as slow). Earlier projection helpers and argument
  reordering keep the body-only variables, so they cannot help.

## 2. Candidates, measured

Raw times are `scasp --forall=prev` on the assembled program (s; `TO` = timeout).

| Candidate | 40 attest. `passed(K) -n0` | `fulfilled(c1)` | `not any_under` / `done` | Meets targets? |
|---|---|---|---|---|
| Baseline (raw) | 8.22 | 1.55 | TO (40 s) | no |
| 1. attest/6 type specialization, uniform KB | 7.36 | 0.44 | TO | no |
| 1. same, mixed KB (+60 other-type attests) | 40 TO -> 6.38 | 19.69 -> 0.39 | TO -> TO | no |
| 2. clingo verdict (venv, 5.8.2) | 0.1 s total at 400 attest. | - | - | verdict only; no `why`; rejects core (see below) |
| 3. per-item ground sub-goals for `done` (20 claims) | - | - | 54.0 s (sum of 22 runs); one conjunction query TO 120 s | no |
| **4. query-relevant grounding** | **0.11** | **0.09** | **0.17** | **yes** |

- **1. Type specialization** (`cand1/spec.py`). It shrinks N to the facts of one type. It
  helps a lot on mixed-type KBs, but the body-only variables and the claim forall stay,
  so `done` still times out. Not recommended alone.
- **2. clingo** (`clingo/to_asp.pl`, `clingo/run.py`; private venv `venv/`). Translation
  15–35 ms, ground+solve 1–4 ms at 400 attestations. But: (a) clingo **rejects the shipped
  core**: `failed_after(K, R)` has the unsafe variable R ("'V1' is unsafe"). A domain
  restriction is needed, which changes the answers for `failed_after(k1, 0)`-style queries.
  (b) It gives no explanation, so `why` still needs s(CASP), and raw `why fulfilled(c1)`
  stays over 2 s at 40 attestations. (c) It adds a dependency and changes the engine roles
  in the contract. Recommendation only: not needed if candidate 4 is adopted.
- **3. Ground sub-goals.** Each `not under(ci)` is itself slow at scale (about 2.5 s at 40
  attestations, from the attest foralls), so n of them is O(n · N^2). It also needs a
  mechanical domain for each gate. That domain is exactly the positive-skeleton answer
  set that candidate 4 computes, so candidate 3 is a special case of candidate 4.
- **4. Grounding** removes every forall: in a ground program, every rule has no body-only
  variables, so every dual is a plain conjunction of ground disjunctions.

## 3. Recommended fix: query-relevant grounding (candidate 4)

### Algorithm (`ground/ground_lib.pl`, 240 lines, SWI only, no new dependency)

Input: the assembled program as terms (without `#pred` terms) and the query goal Q.

1. Ground unit clauses are facts. `H :- false` clauses are stubs; drop them. Every other
   clause is a rule. Refuse (`cannot(...)`) on `:- Body` constraints, `forall/findall`,
   `#=`-style constraints, `;`, `->`, `\+`, `call/1`, unknown predicates, and programs that
   are not stratified by predicate.
2. Tabled positive-skeleton evaluation, demand-driven from Q:
   `sk(G,_) :- fact(G).  sk(G,_) :- ri(_,G,_,_).  ri(Id,G,Body,_) :- rule(G,Body,Id), body(Body).`
   In `body/1`, a positive literal calls `sk/2`; a builtin is called (it must be ground, as
   in SWI); `not L` requires L ground (else refuse), demands L (`forall(sk(L,_),true)`),
   and is then treated as true. `sk/2` and `ri/4` carry a free dummy argument, because SWI
   completes a *ground* tabled call after its first answer, and that loses instances
   (this bug was found and fixed during the work).
3. Every answer of every `ri/4` table is a ground rule instance whose positive body holds in
   the skeleton. Refuse if one is not ground.
4. **Witness pruning:** if head H has an instance whose body is only facts and true
   builtins, keep the first such instance and drop the other instances of H. This bounds
   `was_red/1`, `failed_after/2`, `contested_twice/1` to one instance per head (without it,
   one check with 200 runs gives 10,396 clauses and 7.6 s; with it, 496 clauses, 0.4 s).
5. Output: all facts (unchanged, so attestation ids stay in `why` trees), the instances
   (sorted by rule then term), a stub `p(_,..) :- false.` for every predicate that now has
   no clause, and the original `#pred` lines.

### CLI integration (tested in `cli/orbit-kb-ground`, a copy of the live CLI)

In `prepare/4`, after `assemble/5` writes the file, call `ground_rewrite(File, Extra)`:
read the file (module `orbit_ops`), keep the `#` lines, ground for the conjunction of the
callable `Extra` goals (G, and C for `whynot`), and rewrite the file with `clause_line/3`.
If `ground_program/3` returns `cannot(Why)`, keep the raw file and print
`NOTE: s(CASP) runs on the raw program, because grounding is not possible: Why`.
`ORBIT_KB_SCASP_GROUND=raw` keeps the raw program (for doctor and tests). The SWI verdict
engine is not changed: it still runs on the raw program. `lint` E11 still compiles the
raw program.

### Before/after through the CLI (wall s, cache off; `*` = CROSS-CHECK SKIPPED, 20 s)

| KB (attest.) | `query done` | `passed(K) -n 0` | `fulfilled(c1)` | `why fulfilled(c1)` | `whynot under(c1)` |
|---|---|---|---|---|---|
| 3×2 (6) | 0.34 -> 0.18 | 0.22 -> 0.18 | 0.20 -> 0.18 | 0.20 -> 0.17 | 0.21 -> 0.18 |
| 20×2 (40) | 20.1* -> 0.28 | 3.60 -> 0.19 | 1.67 -> 0.19 | 1.97 -> 0.20 | 1.85 -> 0.21 |
| 10×4 (40) | 20.1* -> 0.24 | 5.36 -> 0.20 | 1.74 -> 0.19 | 2.06 -> 0.19 | 2.09 -> 0.25 |
| 50×2 (100) | 20.1* -> 0.71 | 20.1* -> 0.26 | 20.1* -> 0.26 | 20.1* -> 0.26 | 20.1* -> 0.27 |
| 100×2 (200) | 20.1* -> 1.50 | 20.1* -> 0.36 | 20.1* -> 0.35 | 20.1* -> 0.33 | 20.1* -> 0.35 |
| 50×4 (200) | 20.1* -> 0.88 | 20.1* -> 0.31 | 20.1* -> 0.26 | 20.1* -> 0.27 | 20.1* -> 0.29 |
| 100×4 (400) | - -> 2.67 | - -> 0.45 | - -> 0.34 | - -> 0.38 | - -> 0.38 |
| 200×2 (400) | - -> 6.38 | - -> 0.46 | - -> 0.48 | - -> 0.58 | - -> 0.63 |
| 1×200 (one check, 200 runs) | - -> 1.16 | - -> 1.00 | - -> 1.18 | - -> 1.18 | - -> 1.55 |

(Before: `cli/base.txt`, the live CLI. After: `cli/ground-final.txt`, final grounder with pruning; `cli/ground.txt` is the unpruned run. The machine was shared, so ±20 %.)
Grounding itself takes 13–130 ms in-process (`results-grounding-size.txt`); the grounded
`done` program is 2.2 times the raw file at 200 attestations.

Discovery fixture (recovered `fixtures/scale`, old `discovery.pl`, `gen_scale.py`
variants; `results-discovery.txt`): `not model_trusted(mt0x)` 18.0 s -> 0.11 s (s10x),
TO -> 0.13 s (s20x); `discovery_ready` TO -> 0.15 / 0.22 s.

What is left: `done` at 200 claims is 6 s. The profile shows `contrained_neg/2` (9.2 M
calls) and `member/2` over the CHS: each ground goal scans the proved goals of its
functor, so the cost is O(n^2) in claims with a small constant.

## 4. Equivalence

### General argument (stratified programs)

Let P be a normal program that is stratified by predicate, ground(P) its instantiation
(builtins evaluated), M its perfect model (= its unique stable model, = the SWI
verdict when SLDNF terminates without floundering). Let S be the least model of the
positive skeleton P+ (negative literals deleted).

1. **M ⊆ S.** M is the least model of the reduct ground(P)^M. Each reduct rule is a rule
   of ground(P+), so by monotonicity of least models M ⊆ S.
2. **Dropping dead rules.** Let Q = the rules r of ground(P) with pos(r) ⊆ S (and true
   builtins). A dropped rule has a positive body atom outside S, so outside M; it never
   fires in M. M is still a model of Q's reduct and the least one (fewer rules), and Q is
   stratified, so M is the unique stable model of Q.
3. **Relevance (splitting).** Let D be the set of atoms that the grounder demanded: the
   query instances in S and, closed under rules of Q with head in D, every positive and
   negative body atom. Then D is a splitting set of Q (every rule with head in D has its
   body atoms in D). By the splitting set theorem (Lifschitz–Turner 1994),
   SM(Q) restricted to D = SM(b_D(Q)), where b_D(Q) are the rules of Q with head in D.
   The grounder emits exactly b_D(Q) plus all facts. Facts have no body, so D is also a
   splitting set of the output P_g with the same bottom part. Hence M ∩ D = M_g ∩ D.
4. **Witness pruning.** If H has an instance whose body is facts and true builtins, H is in
   every model of b_D(Q). Removing other rules with head H removes no atom from the least
   model of any reduct (H is still derived), and adds none (rules only add their head).
5. **Answers.** Every answer of Q is an instance of the query in M ⊆ S. The tabled call
   `sk(Q,_)` enumerates all instances of Q in S, so all of them are in D.

So, for stratified P in the fragment, the grounded program has the same answers as the
original on every query atom, positive or negative. Out of the fragment the grounder
refuses, and the CLI uses the raw program (today's behaviour). A Lean formalization would
mostly restate the splitting set theorem, so I give this argument instead.

### Bounded exhaustive differential, SWI engine (`equiv/diff_swi.pl`, `equiv/common.pl`)

Each check compares SWI(original) with SWI(ground_program(original, query)), on the
shipped core + build rules. Per KB: 30 fixed queries (every rule predicate with open
arguments, `failed_after(_, 0..3)`, `failed_after(k1, 2)`, `not done`, `not any_*`,
`lint_issue/3`) plus 3–10 ground queries per claim, check, question, change and approval
id in the KB (positive and negated), about 45–65 queries per KB.

| Family | Bound | KBs | Checks | Mismatches |
|---|---|---|---|---|
| a | c1 label ∈ {preserve, introduce, retire}; c2 ∈ {none, preserve, introduce}; k1→c1, k2 ∈ {none, c1, c2}; runs 1..3 each ∈ {none, kX pass, kX fail}; verdict ∈ {none, disproof refuted, disproof inconclusive, lean_result refuted}; supersedes ∈ {none, c2→c1} | 15,120 | 897,600 | 0 |
| b | 1–2 claims, supersedes, ≤2 questions on any claim, answers ∈ 5 cases each (none, human same, human different, agent, two human), depends incl. self and mutual, divergence ∈ 4 cases | 3,800 | 215,200 | 0 |
| c | 2 claims, ≤2 changes, every serves subset, 5 approval/digest cases, 4 burn cases | 400 | 22,560 | 0 |
| r | 20,000 random KBs over all the vocabulary, ≤3 claims, ≤3 checks, ≤6 runs with numbers 1..4 (duplicates allowed) | 20,000 | 1,266,486 | 0 |

Unpruned v1 grounder: same counts, 0 mismatches (`equiv/diff_swi.v1-unpruned.log`).
Pruned final grounder: the same four families again, same counts, 0 mismatches (`equiv/diff_swi.log`). Mutation control: the harness drops one
ground instance and must fail; it reports 674 mismatches in 2,000 checks.

### s(CASP) at small sizes (`equiv/diff_scasp.pl`, in-process s(CASP))

Each query: SWI(original) vs s(CASP)(raw) vs s(CASP)(grounded), all answers.
Results (`equiv/diff_scasp.log`), final grounder:

| Sample | forall | KBs | Checks | raw s(CASP) wrong / timeout | grounded s(CASP) wrong / timeout |
|---|---|---|---|---|---|
| family c, every 4th | prev | 100 | 5,640 | 0 / 0 | 0 / 0 |
| family b, every 40th | prev | 95 | 5,380 | 0 / 0 | 0 / 0 |
| family a, every 100th | prev | 152 | 9,014 | 0 / 0 | 0 / 0 |
| random r(300, seed 11) | prev | 300 | 18,963 | 0 / 0 | 0 / 0 |
| random r(100, seed 12) | **all** | 100 | 6,285 | **177 / 48** | **0 / 0** |

"Wrong" means a different answer set from SWI on the original program (20 s limit).

## 5. Hazards and the cross-check

`hazards/run.sh` (doctor programs, raw and grounded, `prev` and `all`):

| Program | SWI | raw prev | raw all | ground prev | ground all |
|---|---|---|---|---|---|
| H1 helper `done` | false | no | no | no | no |
| H1 bad `done :- not under(_)` | false | yes (wrong) | yes | grounder refuses -> raw | same |
| H2 `finding_lead(F)` | none | no | **F=f1** | no | no |
| H3 `passed(K)` | k2,k3,k4 | k2,k3,k4 | **TO / k1,k2,k3** | k2,k3,k4 | k2,k3,k4 |
| H4 raw `r` | false | **yes** | **yes** | no | no |
| H4 `q :- not p(order_5120)` | true | **no** | **no** | **no** | **no** |
| H4 `p(X)` bindings | order_4417, order_5120 | **order** ×2 | | **order** ×2 | |

So grounding removes H2 and H3 from the s(CASP) run (the explanation shown is then
right), and the grounder refuses H1 programs. H4 still shows in ground mode when the
merged atom is under `not` or in a binding, but not in a positive join (SWI does that join).

`orbit-kb doctor` with the grounded CLI: all pass with `prev`, and also with
`ORBIT_KB_SCASP_FLAGS=--forall=all` (H2/H3 now agree). The control "H4 raw atoms must
report ENGINE DISAGREEMENT" **stops discriminating** (both engines say false).
Proposed doctor changes, so that no control is lost:

1. Run the existing negative controls with `ORBIT_KB_SCASP_GROUND=raw`: H4 raw must
   disagree; and with `--forall=all` added, H2 and H3 must disagree. This proves that the
   cross-check plumbing still detects a wrong s(CASP) answer.
2. In ground mode: H2 and H3 must give the right answer even with `--forall=all`
   (proves that grounding is active); the H4 control becomes `p(order_4417).
   q :- not p(order_5120).` with query `q` (must disagree; verified).
3. Grounder-corruption control: ground the H3 program, delete the instance
   `failed_after(k1, 1) :- ...`, run s(CASP) on it: it answers k1 too, so the cross-check
   must report ENGINE DISAGREEMENT (verified).

How a grounder bug is caught: the SWI verdict still comes from the raw program through a
separate path (the CLI's own translation and SLDNF). A grounder that drops or adds an
instance changes the s(CASP) answer, and the cross-check compares it with SWI. Shared
risk: both use SWI unification and arithmetic, so an SWI core bug is not cross-checked
in the joins; negation is evaluated only by s(CASP).

## 6. Risks

- The cross-check no longer tests s(CASP)'s non-ground machinery on KB queries (that is the
  point). The contract text about H2/H3 being caught by the cross-check must change to
  "cannot occur in ground mode; caught in raw mode".
- `why` trees change form: they are much shorter and cite the attestation ids, but a
  predicate with no relevant instance shows "there is no evidence that false holds"
  under its node. The CLI can drop that line.
- With witness pruning a tree shows one witness per pruned head (s(CASP) shows one anyway).
- A KB outside the fragment (non-stratified local rules, constraints, `forall`, clpq,
  an open `failed_after(k1, R)` query) runs raw, as today, with a NOTE.
- The skeleton is computed in SWI: a non-terminating skeleton (infinite S, for example
  `is/2` recursion) would hang the grounder. Run it under the SWI time limit and fall back.
- `-n 0` on ground queries with many proofs enumerates proofs (as before); the CLI
  already caps it at 1 for ground goals.
- `done` at 200 claims takes 6 s (CHS scans); 1,000 claims would need a different fix.

## 7. Artifacts

- `ground/ground_lib.pl` (the grounder), `ground/ground.pl` (CLI wrapper),
  `ground/ground_lib.v1.pl` (before pruning)
- `cli/orbit-kb-ground` (patched CLI copy), `cli/orbit-kb-base`, `cli/clibench.sh`,
  `cli/base.txt`, `cli/ground.txt`, `cli/ground-final.txt`
- `equiv/` harnesses and logs; `hazards/` programs and `run.sh`
- `prof/drv.pl` (in-process s(CASP) driver and profiler)
- `gbench.sh`, `results-*.txt`, `progs/`, `kbs/` (benchmarks), `cand1/`, `cand3.sh`,
  `clingo/`, `disc/`

## 8. Integration into the live CLI (D8, 2026-10-16)

The grounder is inlined in `/home/ty/.dotfiles/shared/link/.local/bin/orbit-kb`
(section "Grounding the s(CASP) program (D8)", predicates `gr_*`, `ground_file/3`,
`prepare/5`), so the saved-state key covers it. Review notes folded in: `not` literals
are evaluated after the other body literals (D7 order; the D7d program grounds with no
NOTE); only the grounder's own tables are abolished (`abolish_table_subgoals/1` on
`gr_sk/2`, `gr_ri/4`; the CLI has no other tables); every exception, failure, resource
error and the 5 s limit (`ORBIT_KB_GROUND_TIMEOUT`, hidden, for tests) gives the raw
program plus `NOTE: s(CASP) ran the raw program: <reason>`; the grounding goes to a new
temp file only when complete; no pruning knob. Programs with `-p` clauses also demand
all of p and -p, so the s(CASP) p/-p consistency check behaves as in raw mode.

Verification: `port/suite-after.txt` (176/176 pass), `port/suite-noraw.txt` (the same
suite with `ORBIT_KB_SCASP_GROUND=raw` removed: exactly H3b, X2, X3, X9 fail),
`port/doctor-flipped.txt` (each control fails when its condition is removed),
`cli/live-d8.txt` (benchmark), `equiv/diff_live.pl` + `equiv/live_grounder.pl`
(generated verbatim from the live script) + `equiv/diff_live.log`.

## 9. Relevance trimming of the grounded program

### Algorithm (live CLI, `gr_emit/5`)

After grounding and witness pruning, the grounded program P_g is a set of ground facts F
and ground rule instances I. Let `norm(t)` drop a final `_` + digits from every atom and
string in t, repeatedly (what the s(CASP) reader does, H4).

1. Roots: the goal literals (with `not` removed, builtins skipped), plus `p(_..)` and
   `-p(_..)` for each p with a `-p` clause.
2. Reach, on normalized atoms: a reached atom A reaches every instance whose normalized
   head equals norm(A) (or unifies with a root that has variables); an instance reaches
   every atom of its body, positive or under `not`.
3. Emit: the facts f with norm(f) reached (or unifying with a root with variables), in
   source order; the reached instances; a stub `p(_..) :- false.` for each predicate that
   a root or an emitted body references and that has no emitted clause; the `#pred` lines
   of the predicates that appear; other `#` lines unchanged.

The normalization keeps every fact that s(CASP) would merge with a reached atom. Without
it, the trimming would drop `p(order_4417)` for `q :- not p(order_5120)`, and the doctor
control "H4 under not, ground mode" fails (verified: `port/doctor-nonorm.txt`).

### Proof sketch

Let D be the set of ground atoms whose normalized form is reached, and P_D the emitted
program. (a) D is a splitting set of P_g: for every clause of P_g whose head is in D, the
clause is emitted and all its body atoms (positive and negative) are reached, so they
are in D. Facts with heads in D are emitted. So P_D is the bottom b_D(P_g) plus stubs for
predicates with no clause, and stubs add nothing. By the splitting set theorem
(Lifschitz–Turner 1994, as in §4), SM(P_g) restricted to D equals SM(P_D); P_g is
stratified, so both are one model, and they agree on D. The goal atoms are in D, so the
answers are the same. With roots for every p and -p atom, the s(CASP) consistency
constraint between p and -p also sees the same atoms. (b) s(CASP) solves top-down: a goal
A is resolved only against clauses whose head unifies with A, and its dual `not A` is a
conjunction over the clauses of A's predicate in which each clause whose head does not
unify with A is satisfied at once by a disequality. So a top-down proof of the goal only
consults atoms of D, and a removed clause could only add such a trivially true conjunct.
Reaching on normalized atoms only enlarges D (it unites atoms that s(CASP) unites), and the
argument in (a) holds for any D closed in this way.

### Evidence (trimmed live grounder)

- SWI differential, integrated path (`equiv/diff_live.pl` on `equiv/live_grounder.pl`
  regenerated from the live script; `equiv/diff_live_trim.log`): families a (15,120 KBs,
  897,600 checks), b (3,800 / 215,200), c (400 / 22,560), random r(5000, seed 7)
  (5,000 / 316,517): **0 mismatches, 0 fallbacks**. Mutation control (drop the first kept
  KB fact from each grounded program; every kept fact is relevant by construction):
  903 mismatches in 2,454 checks.
- s(CASP) differential, integrated path (`equiv/diff_scasp_live.pl`,
  `equiv/diff_scasp_live.log`): c every 4th, b every 40th, a every 100th, r(300) under
  `prev`: 0 wrong for raw and grounded (38,997 checks). r(60) under `--forall=all`: raw 101
  wrong + 28 timeouts, grounded 0 + 0.
- Explanations (`port/explain.sh`, `port/explain/`): `why fulfilled(c1)`, `why done`,
  `whynot under(c1)`, `whynot passed(k1)`, `whynot fulfilled(c2)`, `why to_ask(q1b)` on
  kb-3-2, kb-10-4, kb-20-2 and kb-mixed (supersedes, a disproof, two divergences, a human
  answer): byte-identical before and after trimming, in `--long` and short form (48 pairs,
  timing lines removed).
- Suite 176/176 (`port/suite-trim.txt`); doctor 12/12 ok, with `prev` and `--forall=all`
  (`port/doctor-trim.txt`).

### Before/after (min of 3 wall-clock s, cache and saved state off, so ~0.12 s of script load each)

| KB (attest.) | current(c1) | passed(k1) | passed(K) -n 0 | fulfilled(c1) | done | why fulfilled(c1) |
|---|---|---|---|---|---|---|
| 10×2 (20) | 0.17 -> 0.15 | 0.17 -> 0.15 | 0.17 -> 0.15 | 0.17 -> 0.16 | 0.24 -> 0.18 | 0.20 -> 0.15 |
| 20×2 (40) | 0.22 -> 0.15 | 0.18 -> 0.14 | 0.18 -> 0.16 | 0.18 -> 0.14 | 0.26 -> 0.25 | 0.19 -> 0.16 |
| 50×2 (100) | 0.23 -> 0.16 | 0.22 -> 0.15 | 0.23 -> 0.17 | 0.22 -> 0.15 | 0.55 -> 0.53 | 0.23 -> 0.16 |
| 100×2 (200) | 0.29 -> 0.16 | 0.28 -> 0.16 | 0.31 -> 0.21 | 0.29 -> 0.16 | 1.49 -> 1.44 | 0.32 -> 0.17 |
| 200×2 (400) | 0.43 -> 0.18 | 0.43 -> 0.17 | 0.49 -> 0.28 | 0.51 -> 0.19 | 6.58 -> 6.15 | 0.47 -> 0.20 |

(`cli/trim-before.txt`, `cli/trim-after.txt`.) `done` reaches every claim, so trimming
removes little there; its cost is the CHS scan (§3).

### Model cap (measurement only; the cap is unchanged)

`cap/capbench.sh`, `cap/results.txt`: s(CASP) on grounded programs, -n 10 / 100 / 0.
`passed(K)`, `fulfilled(C)`, `current(C)`, `served(X)` at 200 and 400 attestations: -n 100
costs at most +0.06 s over -n 10 (fulfilled(C) at 400: 0.35 -> 0.41 s; all answers 0.42 s).
No duplicate models in any case (models = distinct answers), including kb-mixed
(`to_ask`, `contested`, `contested_twice`, `burn`, `served`). A goal with no answer
(`under(C)`) costs the same at every cap (1.0–3.7 s), because s(CASP) must exhaust it.
Duplicates remain possible when one head has two instances with `not` in their bodies that
both hold (for example two passes with no later fail); the cap bounds them.

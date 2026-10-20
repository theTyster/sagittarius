# orbit-kb contract (v2.1, 2026-10-15)

**Changes in v2.1** (sent to the builders while they work):

- **D1.** `test_result` and the rules `passed/1`, `failed_after/2`, and `was_red/1` move
  from the build module to the core. A runnable reproduction is a check in both orbits.
- **D2.** E6 (non-ground fact) applies only to facts in `kb.pl`. E7 now means "a clause
  in the wrong place":
  - a `rule` predicate asserted as a fact in `kb.pl`; or
  - a `fact` predicate that has clauses outside `kb.pl` (in core, modules, or
    `rules.pl`).

  In library files and in `rules.pl`, unit clauses for `rule` predicates are allowed, and
  they may be non-ground.
- **D3.** `subject/3` paths:
  - `orbit-kb subject` stores the path relative to the KB directory when the file is
    inside the KB directory tree. Otherwise it stores the absolute path.
  - Every reader resolves a relative path against the KB directory. Readers are W1,
    `digest(current)`, and refresh.

  This keeps fixtures and KBs portable.
- **D4.** `report/1` and `calibration` are no longer reserved by discovery.
- **D5.** `to_ask/1` asks only questions whose claim is still current. Without this, the
  questions of a superseded claim stay open forever, and `done` can never hold.
  `any_to_ask/0` moves from build to core.
- **D8 (grounded cross-check, 2026-10-16).** Root cause and evidence:
  `/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad/perf/scasp-agent/RESULTS.md`
  (the session scratchpad, so it may be gone).
  - **Default.** s(CASP) runs on a query-relevant grounding of the assembled program.
    `ORBIT_KB_SCASP_GROUND=raw` runs the assembled program unchanged. The SWI verdict
    engine always runs the original, ungrounded program.
  - **The grounding** contains:
    - every rule instance that is reachable from the query and whose positive body can
      hold, with the `not` literals ignored for reachability but their atoms grounded
      too;
    - builtins, evaluated while grounding;
    - for each ground head that has a facts-only instance, that instance alone;
    - all facts, unchanged, so that `why` still names the attestation ids;
    - stubs for predicates that have no clauses;
    - the `#pred` lines.
  - **Fallback.** For an unsupported form, the grounder uses the raw program and prints
    `NOTE: s(CASP) ran the raw program: <reason>` on stderr. The unsupported forms are a
    `not` over a free variable, constraints, `forall`, clpq, `;`, `->`, a program that is
    not stratified, and an instance that stays non-ground. Grounding that takes more than
    5 s gets the same fallback. Answers never depend on whether grounding succeeded.
  - **Relevance trimming.** The grounding keeps only facts that match an atom reachable
    from the query, plus all `p` and `-p` facts when the program has `-p` clauses.
    Matching ignores a trailing `_<digits>`, as the s(CASP) reader does. Stubs and `#pred`
    lines follow the emitted program. `why` and `whynot` output is unchanged.
  - **Cross-check cap.** On a grounded program, the M+1 cross-check run may ask for up
    to 100 models. A raw program keeps the cap of 10.
  - **Hazards.** In ground mode, H2 and H3 cannot occur, because no dual contains a
    `forall`. H4 still causes a disagreement when a merged atom is under `not` or in a
    binding. The negative controls therefore work as follows:
    - The H2 and H3 controls under `--forall=all` that must report ENGINE DISAGREEMENT
      run with `ORBIT_KB_SCASP_GROUND=raw`.
    - In ground mode, the same programs under `--forall=all` must give the correct
      answer with no disagreement.
    - `doctor` keeps its known-answer tests (H1–H4) in ground mode.
    - `doctor` runs the "H4 raw atoms must disagree" control in raw mode.
    - `doctor` adds the ground-mode H4 control: `p(order_4417).` and
      `q :- not p(order_5120).` must disagree, with E13 bypassed.
    - `doctor` adds a grounder-corruption control: delete one `failed_after` instance
      from the grounded H3 program. s(CASP) then also answers k1, and the cross-check must
      report ENGINE DISAGREEMENT.
- **D7 (review fixes, 2026-10-16).**
  - `query`, `why`, `whynot`, `show`, and `report` exit 2 before they answer in two
    cases: when any KB or rules file has a syntax error (E1), and when `rules.pl` has an
    undeclared head or body predicate (E2). A broken source never yields a quiet "false".
  - **Unsafe negation.** The SWI translation moves each `not` literal after all of the
    positive body literals. Builtins stay in place relative to the positive literals. In
    a stratified program this does not change the answers, and it stops `\+` from
    floundering on unbound variables. Lint error **E14** flags a `not` literal whose
    variable occurs in the head but in no positive body literal (unsafe negation).
  - The cross-check asks s(CASP) for M+1 models, up to the cap, when SWI found M
    answers. If s(CASP) returns more answers than SWI, the result is ENGINE DISAGREEMENT.
  - `run`, `attest`, `add`, `declare`, `subject`, and `uses` (D11) hold an exclusive lock
    (`flock` on `kb.lock` in the KB directory) for the whole cycle: read, choose the id
    or run number, write the log with an exclusive create, and append. The `subject`
    rewrite writes a temp file in the same directory and renames it into place.
  - E13 also checks string values.
  - Temp files are created with `tmp_file_stream/3`.
- **D9 (discovery delivery, 2026-10-19).** `modules/discovery.pl` replaces the placeholder,
  with the fixture `scripts/orbit-kb/fixtures/discovery-a/`. The reserved discovery names
  are updated below. Open requests: a lint warning for a stale approval (LM21); a way to
  record a digest without typing it (F5); a `report_section/3` hook for `report` and
  `show open`. `--by human` is a claim the CLI cannot verify (LM20).
- **D11 (add a module, 2026-10-19).** Decision by Ty: a cleaner fix than an edit by hand for the handoff between orbits. `orbit-kb uses MODULE …` adds a module to an existing KB.
- **D10 (a burn needs a proof, 2026-10-19).** Decision by Ty: "A burn needs a proven
  verdict. Always. Specification clarity comes from the need to build out that proof. Not
  merely write it in lean. Clarity comes from the demand to write it in lean _correctly_."
  Follow-up choices by Ty, the same day: only a script records a proof; TLC does not count
  as a proof (Lean only); a human may waive a proof with a due time; a conformance check of
  the code against the Lean model is optional ("a smooth gradient on the requirement for
  scaling"). The changes:
  - `done` also needs `not any_burn_open`. `burn_open(C) :- burn(C), current(C),
    not burn_proved(C), not burn_waived(C).`
  - `lean_result` keeps `stated`, `refuted`, and `tested(int)`, and loses `proved`. New
    types: `lean_proof` (`proof(ref(claim), digest)`, writers `[script]`) and `waiver`
    (`waive(ref(claim), time, text)`, writers `[human]`).
  - New command `orbit-kb prove CLAIM FILE THEOREM [--module M]`. It runs `lake build`, a
    probe (`lib/lean/probe.lean`) that reports kind, module, axioms, statement, and
    project imports, then `leanchecker`, then `lake build --no-build`. It accepts only the
    axioms `propext`, `Classical.choice`, `Quot.sound`. It writes `runs/proof-ID.log`.
  - Derived facts, computed at each KB load: `proof_changed(A)` (a file of the proof
    changed, or the log is missing or wrong) and `waiver_lapsed(W)` (the due time is
    past). The SWI engine and s(CASP) both see them as facts.
  - Lint E9 also covers a `lean_proof` with no matching log. E8 names `orbit-kb prove`.
  - Optional conformance: `conformance(ref(check))` and `conforms(C)`.
  - `declare` refuses `proved`, `chs`, `assume`, `abduced`: s(CASP) uses them as model
    wrappers, and a rule `proved/1` made `scasp --code` raise an instantiation error.
    The rule is named `burn_proved/1`.
- **D10 follow-up (review fixes, 2026-10-20).** Decisions by Ty on 2026-10-20: the
  threat model is trust ("we expect trust between the agents, the human, and the code"),
  so `prove` checks the proof of an honest agent that can make mistakes and does not
  resist an agent that cheats on purpose; the cheating holes are documented limits
  (README section 15). A claim that supersedes a burning claim inherits the burn. The
  changes (review: `thoughts/orbit-kb-d10-review-2026-10-20.md`):
  - S1: `burn(C)` holds when C has a burn reason (contested twice, universal, burn
    requested), or when C reaches, through one or more `supersedes` steps, a claim that
    has one. S2: a `supersedes` cycle, including `supersedes(C, C)`, is lint error E15,
    and `done` is false while it exists. S3: the rules do not recurse through
    `supersedes`; the CLI computes `supersedes_closure/2` and `supersede_cycle/1` when it
    reads the KB.
  - E16: `rules.pl` cannot add clauses to `done`, the burn rules, or the computed facts.
    The engines do not read such clauses, nor a `rules.pl` clause whose head is a fact
    predicate (E7), nor a `kb.pl` fact of a protected predicate (E7).
  - The `time` type checks the values. A waiver whose due time is not a valid time
    counts as lapsed.
  - Proof log and digest. The log has `absent PATH` lines for the Lake configuration
    files (`lakefile.lean`, `lakefile.toml`, `lean-toolchain`, `lake-manifest.json`)
    that do not exist. The digest is the sha256 of these lines, each ended by a newline:
    `claim C`, `theorem T`, `module M`, `statement S` (from the log), then `SHA PATH`
    for each `file` line in order, then `absent PATH` for each `absent` line in order.
    A proof counts (`proof_changed` is false) only when the log header names the claim
    and the digest of the attestation, the log lines give that digest, every file
    still has its sha256, and every absent file is still absent.
- **D6.** Generate stubs only for declared predicates that have no clauses in the
  assembled program. Name every anonymous variable in a query before passing it to
  s(CASP), because `--json` crashes on `_`.

This contract is the single source of truth for three builders who work in parallel:

- **A, library:** `shared/link/.local/share/orbit-kb/`
- **B, CLI:** `shared/link/.local/bin/orbit-kb`
- **C, tests:** `scripts/orbit-kb/`

Each builder edits only its own path. When something is ambiguous, choose the reading
that makes failures loud, and record the choice in your final report.

**Purpose.** A CLI that helps LLM agents write, check, and query s(CASP) knowledge bases
(KBs). A KB records:

- a human's request;
- claims about the request;
- dormant questions with default answers;
- attestations, which are evidence shaped like in-toto statements.

SWI-Prolog has no schema checker, so `orbit-kb` provides one. The tool must stay
domain-neutral. The core vocabulary must not mention software. Software terms live in
`modules/build.pl`. Discovery terms live in `modules/discovery.pl`, which another session
owns.

## Environment facts (verified 2026-10-15)

- SWI-Prolog 9.2.9 is at `/usr/bin/swipl`.
- s(CASP) 1.1.4 is a pack in `~/.local/share/swi-prolog/pack/scasp`. Its binary is
  linked at `~/.local/bin/scasp`.
- `scasp` reads a program from `/dev/stdin`.
- A stub `p(_, _) :- false.` declares an empty predicate. A query on it gives
  "No models", with no warning. With `--unknown=error`, a misspelled predicate in a rule
  body raises an error, which is loud. A query goal on a predicate with no clauses raises
  an error even with `--unknown=fail`. Stubs fix that too.
- "No models" exits 0 and prints `Warning: s(CASP): No models` on stderr. An existence
  error exits 1.
- `--json=-` prints `{"answers":[{"bindings":{"X":{"value":…}}, …}]}`. `answers` is
  empty when there are no models.
- `--tree --human` prints an English justification. A `#pred head(A,B) :: 'text @(A)'.`
  line changes that text.
- Clauses of one predicate merge across concatenated files, and negation sees all of
  them. Facts like `decl(fact, claim(id, oneof([a,b]), text), 'Doc', 'T').` are harmless
  inside an s(CASP) program. So the program can be built by concatenating raw text.
- s(CASP) operators, for SWI reading:
  - `op(900, fy, not)`
  - `op(950, xfx, ::)`
  - `op(1200, fx, #)`
  - `op(1150, fx, [table, show, pred])`
  - `op(350, fx, [include, compute, abducible])`
  - `op(700, xfx, [#=, #<>, #<, #>, #=<, #>=])`

### Two s(CASP) soundness hazards (reproduced 2026-10-15)

**H1: a variable that occurs only under `not` is existential.**
- `done :- not under(_).` succeeds even when `under(a)` is a fact. The same happens with
  every `--forall` mode.
- `over(X) :- change(X, _), not serves(X, _).` is true even when `serves(x1, c1)` exists.
- The fix is a helper predicate: `any_under :- under(_). done :- not any_under.`
- Rule: no `not` literal may contain a variable that occurs nowhere else in the clause,
  including `_`. Lint error E12 enforces this.

**H2: the default `--forall` algorithm returned a wrong answer.** This 5-fact program
must have no models:

```prolog
finding(f1, sys, model).
about_system(sys).
attest(a1, other, foo, x, agent, t1).
attest(a2, reproduction, other, confirms(f9), script, t2).
attest(a4, reproduction, sys, confirms(f1), script, t4).
finding_lead(F) :- finding(F, K, model), about_system(K), not finding_confirmed(F).
finding_confirmed(F) :- attest(_, reproduction, _, confirms(F), _, _).
?- finding_lead(F).
```

- The default `--forall` mode gives `F = f1`. That is wrong.
- `--forall=prev` and `--forall=sasp` give "No models", which is correct.
- SWI-Prolog negation (`\+`) gives no answer, which is correct.

Neither the soundness of `prev` nor that of `sasp` has been proved. The bug is upstream:
https://github.com/SWI-Prolog/sCASP/issues/10 has been open since 2024-10, and no fix
exists in 1.1.4 or master. `prev` is the algorithm from the 2018 paper and the default in
Ciao. Its known weakness is arithmetic constraints that link variables under negation.

**H3: arithmetic under negation, as in the core rule `passed/1`.** Tested on 2026-10-15.

- Program: the core `passed/1` and `failed_after/2`, plus these runs:
  - k1: pass(1), fail(2)
  - k2: fail(3), pass(4)
  - k3: pass(5)
  - k4: pass(6), fail(7), pass(8)
- Query: `passed(K)`.
- Expected: exactly k2, k3, and k4.

| Engine | Answer | Verdict |
|---|---|---|
| default `all` | k1, k2, k3 | wrong both ways |
| `prev` | k2, k3, k4 | correct |
| `sasp` | k2, k3, k4 | correct |
| SWI | k2, k3, k4 | correct |

With `all`, the ground query `passed(k1)` also says yes after a pass and then a fail.
This is a third known-answer case for `doctor`.

**H4: atoms that end in `_<digits>` merge.** s(CASP) strips a trailing `_<digits>` from
atoms, even quoted ones, and the stripped atoms then unify. This was reproduced on
2026-10-15:

- `p(order_4417). r :- p(order_5120).` gives `r` true in s(CASP), but false in SWI.
- `p(order_4417). p(order_5120).` with the query `p(X)` prints `X = order` twice.

Rules:
- Lint error **E13**: any atom in `kb.pl`, `rules.pl`, the core, or a module that matches
  `_[0-9]+$`. The fix text: "rename it, for example order4417".
- `add`, `declare`, `attest`, and `init --id` reject such atoms with the same message.
- `doctor` adds a fourth known-answer case: the `r` program above must be false on both
  engines. With such atoms, s(CASP) says true and SWI says false. If E13 lets such atoms
  through, a query on them must report ENGINE DISAGREEMENT.
- The cross-check compares binding sets whenever bindings are ground, at any `-n`, not
  only `-n 0`. The comparison covers the answers that both engines returned up to `-n`.
  If the engines order answers differently, compare existence only and note this in the
  report.

## Engines: one verdict, one explanation, cross-checked

Every query runs on two engines:

1. **SWI engine (verdict).** Load the assembled program into a fresh module of the
   `orbit-kb` process, after these translations:
   - `not G` becomes `\+ G`;
   - `-p(…)` becomes the separate predicate `'-p'(…)`, in facts and in calls;
   - `#…` directives are dropped;
   - each declared predicate is made dynamic, so an empty predicate fails without an
     error.

   Collect all answers with a time limit (10 s) and an answer cap (1000), then remove
   duplicates. These are the answers that `orbit-kb` prints. For the stratified programs
   this tool targets, this is negation as failure with the usual closed-world meaning.
2. **s(CASP) engine (explanation).**
   - Run `scasp --unknown=error --forall=prev` on the assembled program plus generated
     stubs.
   - `$ORBIT_KB_SCASP_FLAGS` replaces `--forall=prev` when set. The tests use it.
   - s(CASP) provides the `--why` trees, `--json`, and `--html`.
3. **Cross-check.**
   - Compare existence: SWI has at least one answer if and only if s(CASP) has at least
     one model.
   - With `-n 0`, and when every s(CASP) binding is ground, also compare the sets of
     binding tuples.
   - On a mismatch, print `ENGINE DISAGREEMENT`, both results, and the hint
     "see H1/H2 in the orbit-kb help". Exit 2.
   - A disagreement is never silent and never exits 0 or 1.
   - If the SWI engine cannot evaluate a construct, such as `#=` constraints, print
     `CROSS-CHECK SKIPPED: <reason>` on stderr. Then answer from s(CASP) alone, and add
     `(unchecked)` to the output.

**Stubs.** When assembling for s(CASP), add `p(_,…,_) :- false.` for every declared
predicate: fact and rule kinds, core, modules, and local. Then run `--unknown=error`, so
an undeclared predicate is loud at run time as well as in lint.

## Files

### Library (`$ORBIT_KB_LIB`, default `<real dir of the orbit-kb script>/../share/orbit-kb`)

- `core.pl`: core declarations and rules. It is always loaded.
- `modules/<name>.pl`: optional modules.
  - `build` is written by builder A.
  - `discovery` is written later by the discovery session. Builder A creates a
    placeholder that holds only a comment.

### A KB is a directory, at any location the agent chooses (no default)

- `kb.pl`:
  - The first term is `uses([Module, …]).` The list may be empty.
  - Then facts, `-facts` (classical negation), and local `decl/4` and `attest_type/4`
    declarations.
  - The file is append-only by convention. The only exception is `orbit-kb subject`,
    which rewrites its own `subject/3` line.
- `rules.pl` (optional): local rules and `#pred` lines.
- `runs/<N>-<CheckId>.log`: written only by `orbit-kb run`. The first line is
  `% orbit-kb run <N> check=<CheckId> result=<pass|fail> exit=<code> time=<ISO> cmd=<command>`.

## Declarations

```prolog
decl(Kind, Head, Doc, Template).
%  Kind:     fact | rule
%  Head:     Name(Type1, …, TypeN)
%  Doc:      atom; one plain sentence
%  Template: atom with positional @(1), @(2)… for #pred; '' if none
attest_type(Type, Shape, Writers, Doc).
%  Shape:    a type (below) for the 4th argument of attest/6
%  Writers:  sub-list of [human, agent, script]
```

- A predicate of kind `fact` may appear only as a ground fact, or a ground `-fact`, in
  `kb.pl`.
- A predicate of kind `rule` is computed, and a fact for it is an error.
  - A local `rules.pl` may define new rule predicates. It may also add clauses to
    existing rule predicates; lint reports this as an extension (W6).
  - A module may add clauses to the core predicate `lint_issue/3`.
- `Writers = [script]` means that only `orbit-kb run` may write that attestation type.
- **Module lint hook.** `lint_issue(Code, Id, Message)` is a core rule predicate with no
  core clauses. Modules add clauses to it. `orbit-kb lint` evaluates it with the SWI
  engine and prints each result as `<Code> <Id>: <Message>`. A code that starts with `E`
  is an error. Any other code is a warning.

### Types

| Type | Accepts |
|---|---|
| `id` | an atom; unique across all `id`-typed values in the KB |
| `ref(Name)` | the id (first argument) of an existing `Name` fact |
| `ref` | any existing id |
| `oneof(List)` | one atom of `List` |
| `alt(Shapes)` | a value that matches one shape. An atom entry matches itself. A compound entry matches by name and arity, and each of its arguments is a type. |
| `text`, `atom` | an atom |
| `int` | an integer |
| `time` | an atom `YYYY-MM-DDTHH:MM:SSZ` with real values: month 01-12, a day of that month (leap years too), hour 00-23, minute and second 00-59 (D10 follow-up) |
| `digest` | an atom `sha256:` followed by 64 lowercase hex characters |
| `by` | `human`, `agent`, or `script` |
| `term` | any ground term (the escape hatch) |
| `attest_predicate` | used only by `attest/6`; checked against the `attest_type` of argument 2 |

Every fact must be ground.

## Core vocabulary (`core.pl`)

The discovery orbit and the build orbit both use the core vocabulary. Names that the
discovery module reserves must not appear in the core or the build module:

- Facts: `hypothesis/3`, `budget/2`, `lap_done/1`, `model/2`,
  `model_run/3`, `derived_from/2`, `encodes/2`, `finding/3`, `reason/3`,
  `raised_by/2`, `discovery_evidence/2`.
- Gates: `discovery_ready/0` (clean) and `discovery_decide/0` (ready, or the
  budget is spent).
- Rules: every name that starts with `model_` (for example `model_trusted/1`,
  `model_diverges/1`, `model_run_stale/2`, `model_verdict/4`), and
  `has_falsifier/1`, `no_falsifier/1`, `needs_question/1`,
  `has_question/1`, `unasked_finding/1`, `question_waits/1`,
  `about_system/1`, `finding_confirmed/1`, `finding_lead/1`,
  `rule_has_reason/2`, `weak_rule/1`, `touched_system/0`, `budget_spent/0`,
  and helpers named `discovery_*` and `some_*`.
- Attestation types: `reproduction`, `model_result`, `decision`.
  (Calibration is a `model_result` shape, not a type.)
- Lint codes: `WD1`–`WD8` and `ED1`–`ED9`.

Core facts:

- `request(id, text)`: the human's words, verbatim.
- `ticket(ref(subject))`: the subject that holds the ratified ticket.
- `claim(id, oneof([preserve, retire, introduce]), text)`:
  - `preserve`: true now, and must stay true;
  - `retire`: true now, and must become false;
  - `introduce`: false now, and must become true.
- `cites(ref(claim), text)`: the request or ticket text that the claim serves.
- `example(ref(claim), text)`: a concrete case. Discovery's witnesses and reproductions
  go here, and build turns them into tests.
- `supersedes(ref(claim), ref(claim))`: the new claim, then the old one.
- `universal(ref(claim))`: the claim says "for every input".
- `check(id, ref(claim))`: an executable check of the claim.
- `world(term)`: a closed-world fact about the current state.
- `source(term, text)`: where a `world` fact was observed (file and line, configuration
  key, query, or log).
- `scope(oneof([in, out]), text)`
- `risk(id, text)`
- `assumption(id, text)`
- `not_explored(text)`
- `question(id, ref(claim), text)`
- `assumed(ref(question), term)`: the default answer.
- `answer(ref(question), term, oneof([human, agent]))`
- `depends(ref(question), ref(question))`: the first question depends on the second.
- `note(ref, text)`: a free-text note about any id.
- `subject(id, text, digest)`: an artifact path and its sha256. The path is relative
  to the KB directory when the file is inside it; otherwise it is absolute (D3).
- `attest(id, atom, ref, attest_predicate, by, time)`: Id, Type, Subject, Predicate, By,
  Time.

Core attestation types:

- `disclosure`: shape `alt([guess(ref(question)), unverified(text), disagreement(text), out_of_scope(text), self_error(text), other(text)])`. Writers: `[agent, human]`.
- `divergence`: shape `alt([claim(ref(claim)), hypothesis(term), model(term)])`. Writers: `[human, agent]`. Put the description in a `note/2`.
- `disproof`: shape `verdict(ref(claim), oneof([refuted, inconclusive, abstained]))`. Writers: `[agent]`.
- `approval`: shape `digest(digest)`. Writers: `[human]`.
- `test_result`: shape `result(ref(check), int, oneof([pass, fail]))`. Writers:
  `[script]` (moved from build in v2.1).

Core rules, each declared with kind `rule`, and each passing E12:

```prolog
superseded(C) :- supersedes(_, C).
current(C) :- claim(C, _, _), not superseded(C).
answered(Q) :- answer(Q, _, human).
defeated(Q) :- assumed(Q, A), answer(Q, B, human), A \= B.
refuted(C) :- attest(_, _, _, verdict(C, refuted), _, _).
contested(C) :- attest(_, divergence, _, claim(C), _, _).
contested_twice(C) :- attest(D1, divergence, _, claim(C), _, _),
                      attest(D2, divergence, _, claim(C), _, _), D1 \= D2.
to_ask(Q) :- question(Q, C, _), current(C), depends(Q, P), defeated(P), not answered(Q).
to_ask(Q) :- question(Q, C, _), current(C), contested(C), not answered(Q).
any_to_ask :- to_ask(_).
stale(A) :- attest(A, approval, S, digest(D0), human, _), subject(S, _, D1), D0 \= D1.
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _),
              attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
any_supersede_cycle :- supersede_cycle(_).
lint_issue(Code, Id, Message)          % declared; no core clauses (module hook)
```

`supersedes_closure(New, Old)` (New reaches Old through one or more `supersedes` facts)
and `supersede_cycle(C)` (C reaches itself) are rule predicates with no clauses in the
library. The CLI adds their facts each time it reads the KB, from the ground
`supersedes/2` facts of `kb.pl` (D10 follow-up, S3).

An earlier pass followed by a later fail does not count, because `passed(K)` requires
that no fail comes after the pass.

## Build module (`modules/build.pl`)

Facts:

- `change(id, text)`
- `serves(ref(change), ref(claim))`
- `burn_requested(ref(claim))`
- `conformance(ref(check))` (D10, optional)

Attestation types:

- `lean_result`: shape `verdict(ref(claim), alt([stated, refuted, tested(int)]))`. Writers: `[agent, script]`. Progress only (D10).
- `lean_proof`: shape `proof(ref(claim), digest)`. Writers: `[script]`. Only `orbit-kb prove` writes it (D10).
- `waiver`: shape `waive(ref(claim), time, text)`. Writers: `[human]` (D10).

Rules (no `not` over body-only variables). They use the core rules `passed/1` and
`was_red/1`:

```prolog
fulfilled(C) :- claim(C, preserve, _), check(K, C), passed(K), not refuted(C).
fulfilled(C) :- claim(C, L, _), L \= preserve, check(K, C), passed(K), was_red(K),
                not refuted(C).
under(C) :- current(C), not fulfilled(C).
served(X) :- serves(X, _).
over(X) :- change(X, _), not served(X).
any_under :- under(_).
any_over :- over(_).
done :- not any_under, not any_over, not any_to_ask, not any_burn_open,
        not any_supersede_cycle.
burn_reason(C) :- contested_twice(C).
burn_reason(C) :- universal(C).
burn_reason(C) :- burn_requested(C).
burn(C) :- burn_reason(C).
burn(C) :- supersedes_closure(C, O), burn_reason(O).
burn_proved(C) :- attest(A, lean_proof, _, proof(C, _), script, _), not proof_changed(A).
burn_waived(C) :- attest(W, waiver, _, waive(C, _, _), human, _), not waiver_lapsed(W).
burn_open(C) :- burn(C), current(C), not burn_proved(C), not burn_waived(C).
any_burn_open :- burn_open(_).
conforms(C) :- conformance(K), check(K, C), passed(K).
```

`proof_changed/1` and `waiver_lapsed/1` are rule predicates with no clauses in the
library. The CLI adds their facts each time it reads the KB (D10). `waiver_lapsed(W)`
also holds when the due time of W is not a valid `time` (D10 follow-up).


## CLI

Usage: `orbit-kb [--dir DIR] <command> [args]`

KB resolution, in order:

1. `--dir`;
2. `$ORBIT_KB`;
3. the nearest parent of the current directory, or the directory itself, that holds a
   `kb.pl` whose first term is `uses(_)`.

If none is found, exit 2 with a message that names all three options.

Exit codes:

| Code | Meaning |
|---|---|
| 0 | success; the query is true; lint is clean |
| 1 | the query has no answer; lint found errors; `add`, `declare`, `attest`, or `init` rejected the input |
| 2 | usage error; KB or library not found; tool missing; query syntax error; undeclared predicate in a query; ENGINE DISAGREEMENT; internal error |

A typo or an engine disagreement MUST never exit 1. It must never look like "false".

| Command | Contract |
|---|---|
| `init DIR (--request TEXT \| --request-file F) [--uses m1,m2] [--id ID]` | Create `DIR/kb.pl` containing `uses([…]).` and `request(ID, 'TEXT').` The default ID is `r1`. Exit 1 if `kb.pl` already exists. Print the path. |
| `uses MODULE …` | Add modules to the first term `uses([…])` of an existing `kb.pl`, under the KB lock, without loading the KB. Keep the modules in use; never remove one. Keep the text around the term. Print the new line, and tell the agent to lint. Exit 0, also when nothing changes; 1 on an unknown module or a first term that is not `uses/1` with a list of atoms; 2 on a usage error or a failed write (D11). |
| `add 'FACT' …` | The trailing `.` is optional. Validate against every lint error that applies to facts. Facts in the same batch may refer to each other. All or nothing. Append the facts in order and print each one. Refuse attestation types whose writers are `[script]`, and point to `orbit-kb run`. Every rejection says why and how to fix it. For an undeclared predicate, the fix is `orbit-kb declare`. |
| `declare 'HEAD' --doc TEXT [--kind fact\|rule] [--template T]` | The default kind is `fact`. Exit 1 if that name and arity are already declared anywhere, or if a type is unknown. Append the `decl/4` line. |
| `declare-attest TYPE 'SHAPE' --doc TEXT --writers human,agent` | Append an `attest_type/4` line. The same checks apply. |
| `subject ID PATH` | Compute the sha256 of PATH. Exit 1 if the file is missing. Store the path relative to the KB directory when the file is inside the KB directory tree, otherwise the absolute path (D3). Rewrite an existing `subject(ID, …)` line in place, or append a new one. Print the digest. |
| `attest TYPE SUBJECT 'PREDICATE' [--by human\|agent] [--id ID]` | `--by` defaults to `agent`. The id defaults to `a<N>`, the next free number. The time is now, in UTC. Validate the shape, the writer, and the references. The literal predicate `digest(current)` is replaced by the subject's recorded digest. |
| `run CHECK -- CMD …` | Check that CHECK exists, then run CMD. Write its combined output to `runs/<N>-<CHECK>.log`, where N is the highest run number in any `test_result` plus 1. Append `attest(aM, test_result, CHECK, result(CHECK, N, pass\|fail), script, TIME)`; the result is `pass` when CMD exits 0. Print `run N CHECK pass\|fail (exit E) log=PATH`. On a fail, also print the last 40 lines of output. Exit 0 on pass and 1 on fail. |
| `lint [--strict]` | Print one diagnostic per line, `E<n> file:line: message` or `W<n> …`, then module `lint_issue` results, then a summary line. Exit 1 if there are errors, or if there are warnings and `--strict` is set. |
| `query 'GOAL' [-n N] [--why] [--json] [--html FILE]` | Check that every predicate in GOAL is declared or built in; otherwise exit 2. Assemble the program in this order: core, modules, `kb.pl`, `rules.pl`, stubs, and `#pred` lines from templates. Run both engines and cross-check them. `-n` defaults to 1; 0 means all answers. Default output: one line per answer from the SWI engine, either `true` or `X = v, Y = w`. `--why` adds the s(CASP) human justification tree. `--json` prints the s(CASP) JSON unchanged. Exit 0 on an answer, 1 on none. |
| `why 'GOAL'` | Same as `query --why`. |
| `whynot 'GOAL'` | The first line is `holds`, `contradicts`, or `absent`, decided by the SWI engine. `holds` means GOAL has an answer. `contradicts` means `-GOAL` has an answer; only check this when a `-` clause exists. `absent` means neither, and the tree shown is for `not GOAL`. Then print the s(CASP) justification. Cross-check the verdict. Exit 0. |
| `show [claims\|questions\|open\|disclosures\|extensions\|all]` | Plain-text listing. The default is `all`. `open` lists `to_ask`, `stale`, and `contested`, plus `under` and `over` when build is loaded. |
| `report` | A delivery skeleton with these sections in this order: `Delivered:` (placeholder); `Claims:` (each current claim with `fulfilled` or `under` when build is loaded, and its checks); `Guesses:` (questions whose default no human answered); `Disclosures:`; `Not checked:` (current claims with no check); `Open:` (`to_ask`, stale approvals, `over`); `To land:` (placeholder). Use short, plain sentences. |
| `doctor` | Check `swipl`, `scasp` (its location and version), and the library directory, and print a fix step for anything missing. Then run a known-answer self-test on both engines: the H1 helper form must be false, the H2 program must have no answer, the H3 program must answer exactly k2, k3, and k4 with `-n 0`, and the H1 bad form must be flagged by E12. Report each result. Exit 2 if anything is missing or a self-test fails. |
| `help [COMMAND]` | Usage. The general help explains H1 and H2 in a few plain sentences. |

## Lint

| Code | Error |
|---|---|
| E1 | Syntax error, with file and line. |
| E2 | Undeclared predicate or wrong arity. This covers `kb.pl` facts and the heads and bodies in `rules.pl`, `core.pl`, and the modules. Built-ins are allowed: `=`, `\=`, `<`, `>`, `=<`, `>=`, `is`, `#=`, `#<>`, `#<`, `#>`, `#=<`, `#>=`, `true`, `false`, `forall/2`. `not G` and `-G` are unwrapped. When a declaration exists with the same name but a different arity, the message names it. |
| E3 | Type error, including a label outside `oneof`. |
| E4 | Dangling `ref`. |
| E5 | Duplicate id. |
| E6 | Non-ground fact in `kb.pl` (D2). |
| E7 | A clause in the wrong place (D2): a `rule` predicate asserted as a fact in `kb.pl`, or a `fact` predicate with clauses outside `kb.pl`. |
| E8 | Attestation writer not allowed for its type. This includes a `[script]` type whose By is not `script`. |
| E9 | A `test_result` with no matching run log, where the header must match N, the check, and the result. A `lean_proof` with no matching `runs/proof-ID.log`: the header must name the claim and the digest, and the digest of the log lines (D10 follow-up) must equal it. |
| E10 | `uses/1` is missing, is not first, or names an unknown module. |
| E11 | The assembled program fails to compile in s(CASP), or fails to load in the SWI engine. |
| E13 | An atom or string ends in `_` plus digits (H4). |
| E14 | Unsafe negation: a `not` literal's variable occurs in the head but in no positive body literal (D7). |
| E15 | A `supersedes` fact on a cycle, including `supersedes(C, C)` (D10 follow-up). `add` refuses it. |
| E16 | `rules.pl` adds clauses to a protected library predicate: `done`, `burn`, `burn_reason`, `burn_proved`, `burn_waived`, `burn_open`, `any_burn_open`, `proof_changed`, `waiver_lapsed`, `supersedes_closure`, `supersede_cycle`, `any_supersede_cycle` (D10 follow-up). The engines ignore the clause. |
| E12 | A `not` literal contains a variable that occurs nowhere else in the clause, including `_` (H1). The message gives the helper-predicate fix. |

| Code | Warning |
|---|---|
| W1 | The subject digest differs from the file on disk, or the file is missing. Refresh with `orbit-kb subject`. |
| W2 | A local declaration, listed for review. |
| W3 | A claim with no `cites`. |
| W4 | A local fact predicate that no rule reads (no reader). |
| W5 | A superseded claim that a `check` still references. |
| W6 | A local rule that adds clauses to a core or module predicate (an extension), other than a protected one (E16). |

## Style

- Human-facing text (help, report, messages) uses short, plain sentences, with one idea
  per sentence (ASD-STE100 style).
- No commits. Do not edit files outside your own path.
- Put temporary files in the session scratchpad:
  `/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad`.

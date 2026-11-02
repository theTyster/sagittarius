# orbit-kb

`orbit-kb` is a command-line tool for agents. It writes, lints, and queries
Prolog knowledge bases (KBs) with default negation (`not p`). SWI-Prolog is the
only engine.

## 1. What orbit-kb is, and when to use it

`orbit-kb` serves the Sagittarius process, in which a human and an LLM
work together. During this process, agents record facts in a KB:

- The request of the human, word for word.
- Claims about the request.
- Dormant questions, each with a default answer.
- Evidence (attestations), in the shape of in-toto statements.

The KB is a Prolog program that SWI-Prolog runs. SWI-Prolog has no schema checker and no type
checker. Thus a typo in a fact or a rule does not cause an error. It only
changes an answer. `orbit-kb` adds a schema, a type system, and a lint, and it
makes each failure loud.

The core is domain-neutral. You can use it for all human–LLM work that needs
clarity, accuracy, and honesty, not only for software. Optional modules add
vocabulary for one orbit:

| Module | Orbit | Status |
|---|---|---|
| `build` | Build: specification, implementation, verification | Written. See section 7. |
| `discovery` | Discovery | Rules for the discovery orbit: models, findings, hypotheses, and the gates `discovery_ready` and `discovery_decide`. The discovery-orbit session owns it. Example KB: `kb/tests/fixtures/discovery-a/`. |

When an agent must record what a human asked for and then show with evidence
that the work is done, use `orbit-kb`.

We built `orbit-kb` on 2026-10-15, with SWI-Prolog 9.2.9 and a second engine,
s(CASP) 1.1.4. On 2026-10-16, an independent review (D7) and a speed fix (D8)
changed the tool. On 2026-11-02, D20 removed s(CASP): SWI-Prolog is now the
only engine (section 11). Section 15 has the history. On 2026-10-19, D10 made a burn require a
Lean proof (section 7 and `prove` in section 8). D11 added `uses`, which adds
a module to an existing KB (section 8).

## 2. Install and check

The tool is part of the sagittarius repository:

| Item | Repository path | Installed path |
|---|---|---|
| CLI | `kb/bin/orbit-kb` | `~/.local/bin/orbit-kb` |
| Library | `kb/share/orbit-kb/` | `~/.local/share/orbit-kb/` |
| Tests | `kb/tests/` | (not installed) |
| Contract | `kb/CONTRACT.md` | (not installed) |

These steps are for Fedora. On another system, use its package manager for SWI-Prolog
(for example `apt install swi-prolog-nox` or `brew install swi-prolog`).

1. Install SWI-Prolog 9 or later:
   `sudo dnf install swi-prolog-nox`
2. If `~/.local/bin/orbit-kb` does not exist, run `./install.py` from the
   root of the sagittarius repository.
3. Run `orbit-kb doctor`.

`orbit-kb` also uses `flock` from util-linux. `doctor` does not examine it.
Section 13 says what happens when it is missing. No other program is needed:
there is no `scasp` binary and no s(CASP) pack.

`orbit-kb prove` also needs Lean 4 and Lake, installed with elan. It uses
`lake`, and the `leanchecker` binary of the project toolchain. It was tested
with Lean 4.30.0, 4.34.0, and 4.35.0. The other commands do not need Lean.

An example result (7 `ok` lines):

```text
$ orbit-kb doctor
ok    swipl: /usr/bin/swipl (SWI-Prolog 9.2.9; running as /usr/lib64/swipl/bin/x86_64-linux/swipl).
ok    library: /home/you/sagittarius/kb/share/orbit-kb (modules: build, discovery).
ok    not with a helper rule: done must be false.
ok    not under(_) means no under at all: done must be false.
ok    arithmetic under not: passed(K) must be exactly k2, k3, k4.
ok    E18 flags rules that are not stratified (p :- not q, q :- not p).
ok    E17 flags classical negation (-p(b)).
Result: all checks passed.
```

If a line does not start with `ok` or `info`, do the fix step that `doctor`
prints. `doctor` exits 2 if a tool is missing or a self-test fails. Section 8
describes each check.

The library path in that output is the repository path, not
`~/.local/share/orbit-kb`. The CLI follows its own symlink to find the library
(see `ORBIT_KB_LIB` in section 13). Thus a change to the library in the main
checkout is live at once.

## 3. Quick start: "Make the button purple"

This walk-through is a real session. Every command and every output line is a
copy from a run on 2026-10-16. A file `button.css` holds `.buy { color: blue; }`,
and a file `ticket.md` holds the ticket. Both files are in the KB directory.
The digest in step 7 depends on the text of your `ticket.md`.

1. Make the KB. Load the `build` module:

   ```text
   $ orbit-kb init purple --request 'Make the button purple.' --uses build
   /tmp/purple/kb.pl
   ```

2. Go into the KB directory: `cd purple`. All commands that follow find the
   KB from the current directory.

3. Add a claim, the request text that it cites, and a check of the claim:

   ```text
   $ orbit-kb add "claim(c1, introduce, 'The Buy button is purple.')" "cites(c1, 'Make the button purple.')" "check(k1, c1)"
   claim(c1, introduce, 'The Buy button is purple.').
   cites(c1, 'Make the button purple.').
   check(k1, c1).
   ```

   The label `introduce` means "false now, and it must become true".

4. Add the change that serves the claim:

   ```text
   $ orbit-kb add "change(ch1, 'button.css: set the color to purple.')" "serves(ch1, c1)"
   change(ch1, 'button.css: set the color to purple.').
   serves(ch1, c1).
   ```

5. A wrong fact causes a rejection. Nothing is written, and the exit code is 1:

   ```text
   $ orbit-kb add "claim(c2, add, 'The label stays Buy.')"
   Rejected. Nothing was written.
   E3 in argument 1 (claim(c2, add, 'The label stays Buy.')): claim/3 argument 2: The label must be one of: preserve, retire, introduce. It is add.
   ```

6. Add two questions with default answers. Question `q2` depends on `q1`:

   ```text
   $ orbit-kb add "question(q1, c1, 'Which shade of purple?')" "assumed(q1, rebeccapurple)" "question(q2, c1, 'Does the hover color change too?')" "assumed(q2, yes)" "depends(q2, q1)"
   question(q1, c1, 'Which shade of purple?').
   assumed(q1, rebeccapurple).
   question(q2, c1, 'Does the hover color change too?').
   assumed(q2, yes).
   depends(q2, q1).
   ```

7. Record the ticket file as a subject, and mark it as the ticket:

   ```text
   $ orbit-kb subject s1 ticket.md
   sha256:6f2a6395ccceef334e4e8f37a147facff03474208405b9533f12976298a4c0a4
   $ orbit-kb add "ticket(s1)"
   ticket(s1).
   ```

8. Query the claims that are not fulfilled:

   ```text
   $ orbit-kb query 'under(C)'
   C = c1
   ```

9. Run the check before the change. It must fail first, because the label of
   `c1` is `introduce`:

   ```text
   $ orbit-kb run k1 -- grep -q purple button.css
   run 1 k1 fail (exit 1) log=/tmp/purple/runs/1-k1.log
   Last 0 line(s) of output:
   $ orbit-kb query done
   false
   ```

   Both commands exit 1.

10. Change `button.css` to `.buy { color: rebeccapurple; }`. Then run the
    check again:

    ```text
    $ orbit-kb run k1 -- grep -q purple button.css
    run 2 k1 pass (exit 0) log=/tmp/purple/runs/2-k1.log
    ```

11. Query `done`. No question waits for a human:

    ```text
    $ orbit-kb query done
    true
    $ orbit-kb query 'to_ask(Q)'
    false
    ```

12. The human does not agree with claim `c1`. Record the divergence, and a
    note that describes it:

    ```text
    $ orbit-kb attest divergence c1 'claim(c1)' --by human
    attest(a3, divergence, c1, claim(c1), human, '2026-10-16T21:59:43Z').
    $ orbit-kb add "note(a3, 'The human wants a darker purple.')"
    note(a3, 'The human wants a darker purple.').
    ```

13. Query the questions to ask. A contested claim opens all of its questions:

    ```text
    $ orbit-kb query 'to_ask(Q)' -n 0
    Q = q1
    Q = q2
    ```

14. Record the answer of the human to `q1`. The answer is not the default:

    ```text
    $ orbit-kb add "answer(q1, indigo, human)"
    answer(q1, indigo, human).
    ```

15. Query `to_ask` and `done` again. Question `q2` is still open. Its claim
    is contested, and the answer defeated the default of `q1`, on which `q2`
    depends:

    ```text
    $ orbit-kb query 'to_ask(Q)' -n 0
    Q = q2
    $ orbit-kb query done
    false
    ```

16. Lint the KB, and print the report:

    ```text
    $ orbit-kb lint
    Summary: 0 error(s), 0 warning(s).
    $ orbit-kb report
    # Delivered:
      - (Write what you delivered here.)

    # Claims:
      - c1 **introduce**: The Buy button is purple. Status: fulfilled. Checks: k1 (passed).

    # Guesses:
      - q2: Does the hover color change too?
        - The default is yes. No human answered it.

    # Disclosures:
      - None.

    # Not checked:
      - None. Every current claim has a check.

    # Open:
      - **ask**: Ask question q2 now

    # To land:
      - (Write the steps to land the work here.)
    ```

The `kb.pl` file after step 16:

```prolog
uses([build]).
request(r1, 'Make the button purple.').
claim(c1, introduce, 'The Buy button is purple.').
cites(c1, 'Make the button purple.').
check(k1, c1).
change(ch1, 'button.css: set the color to purple.').
serves(ch1, c1).
question(q1, c1, 'Which shade of purple?').
assumed(q1, rebeccapurple).
question(q2, c1, 'Does the hover color change too?').
assumed(q2, yes).
depends(q2, q1).
subject(s1, 'ticket.md', 'sha256:6f2a6395ccceef334e4e8f37a147facff03474208405b9533f12976298a4c0a4').
ticket(s1).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-16T21:59:43Z').
attest(a2, test_result, k1, result(k1, 2, pass), script, '2026-10-16T21:59:43Z').
attest(a3, divergence, c1, claim(c1), human, '2026-10-16T21:59:43Z').
note(a3, 'The human wants a darker purple.').
answer(q1, indigo, human).
```

## 4. KB layout on disk

A KB is a directory. You choose its location. There is no default location.

| Path | Who writes it | Contents |
|---|---|---|
| `kb.pl` | `init`, `add`, `declare`, `declare-attest`, `subject`, `attest`, `run` | The first term is `uses([Module, …]).` The list can be empty. Then come facts and local `decl/4` and `attest_type/4` lines. |
| `rules.pl` | You (optional) | Local rules. |
| `runs/<N>-<CheckId>.log` | `run` only | The combined output of one run of a check. |
| `kb.lock` | The writing commands | An empty file. Each writing command holds a lock on it (section 8). |

While a check runs, its output is in a temp file `runs/.tmp-*`. `run` removes
that file when it ends.

`kb.pl` is append-only by convention. The only exception is
`orbit-kb subject`. When the ID exists, it rewrites its own `subject/3` line.
The rewrite is atomic. `orbit-kb` writes a temp file in the KB directory, and
then renames it to `kb.pl`.

The first line of each run log has this format:

```text
% orbit-kb run 1 check=k1 result=fail exit=1 time=2026-10-15T23:29:44Z cmd=grep -q purple button.css
```

### How orbit-kb finds a KB

`orbit-kb` uses the first of these:

1. The option `--dir DIR`.
2. The environment variable `ORBIT_KB`.
3. The nearest directory, from the current directory upward, with a `kb.pl`
   whose first term is `uses(_)`.

If it finds no KB, it prints the three options and exits 2.

### Assembly order

For each query, `orbit-kb` assembles one program in this order:

1. `core.pl`.
2. The modules that `uses/1` names, from `modules/<name>.pl`.
3. `kb.pl`.
4. `rules.pl`.
5. The facts that `orbit-kb` computes when it reads the KB: `proof_changed/1`,
   `waiver_lapsed/1`, `supersedes_closure/2`, and `supersede_cycle/1`.

The engine makes each declared predicate dynamic. So a predicate with no clauses
fails, and it does not raise an error.

Two kinds of clause that lint rejects do not reach the engine (D10
follow-up, F8): a clause in `rules.pl` whose head is a fact predicate (E7) or a
protected library predicate (E16), and a fact in `kb.pl` of a protected library
predicate (E7). The protected predicates are `done`, the burn rules, the vote
rules of the discovery module, and the computed facts (section 10, E16). The SWI engine loads this program (section 11).

## 5. The type system

### `decl/4`

```prolog
decl(Kind, Head, Doc, Template).
%  Kind:     fact | rule
%  Head:     Name(Type1, …, TypeN), or Name alone for no arguments
%  Doc:      atom; one plain sentence
%  Template: atom with positional @(1), @(2)… that `why` and `whynot` print; '' if none
```

Every predicate must have a declaration. This includes rule predicates and
helper predicates. A predicate without a declaration is an error in lint (E2),
in `add`, and in `query`.

### `attest_type/4`

```prolog
attest_type(Type, Shape, Writers, Doc).
%  Shape:    a type (from the table that follows) for the 4th argument of attest/6
%  Writers:  sub-list of [human, agent, script]
```

`Writers = [script]` means that only `orbit-kb run` can write that type.

### Types

| Type | Accepts |
|---|---|
| `id` | An atom. It must be unique across all `id`-typed values in the KB. |
| `ref(Name)` | The ID (first argument) of a `Name` fact that exists. |
| `ref([Name, ...])` | The ID of a fact of one of the names, such as `ref([claim, check, question])`. Another ID is E4, and the message names the allowed kinds. |
| `ref` | The ID of a fact of any kind. |
| `oneof(List)` | One atom of `List`. |
| `alt(Shapes)` | A value that matches one shape. An atom entry matches itself. A compound entry matches by name and arity, and each of its arguments is a type. |
| `text`, `atom` | An atom. |
| `int` | An integer. |
| `time` | An atom `YYYY-MM-DDTHH:MM:SSZ` with real values: month 01 to 12, a day of that month (29 February only in a leap year), hour 00 to 23, minute and second 00 to 59. |
| `digest` | An atom `sha256:` and 64 lowercase hex characters. |
| `by` | `human`, `agent`, or `script`. |
| `term` | A ground term of any shape (the escape hatch). |
| `attest_predicate` | Only for argument 4 of `attest/6`. `orbit-kb` checks it against the shape of the `attest_type` of argument 2. |

Every fact must be ground.

### Fact kind and rule kind

| Kind | Where its clauses go | Error if not |
|---|---|---|
| `fact` | Ground facts in `kb.pl` only. | E7 if a clause is in the core, a module, or `rules.pl`. E6 if a fact in `kb.pl` is not ground. |
| `rule` | Clauses in the core, in a module, or in `rules.pl`. These clauses can be unit clauses and can have variables. | E7 if `kb.pl` has a fact for it. |

## 6. Core vocabulary and core rules

The core (`core.pl`) is always loaded. It does not mention software.

### Core facts

| Fact | Meaning |
|---|---|
| `request(id, text)` | The request of the human, word for word. |
| `ticket(ref(subject))` | The subject that holds the ratified ticket. |
| `claim(id, oneof([preserve, retire, introduce]), text)` | A claim. `preserve`: true now, and it must stay true. `retire`: true now, and it must become false. `introduce`: false now, and it must become true. |
| `cites(ref(claim), text)` | The text of the request or the ticket that the claim serves. |
| `example(ref(claim), text)` | A concrete case of the claim. |
| `supersedes(ref, ref)` | The first claim replaces the second claim, or the first hypothesis replaces the second hypothesis (discovery module, D15). Both ids must be the same kind: a claim and a hypothesis is lint error E4, and `add` refuses it. |
| `universal(ref(claim))` | The claim is about every input. |
| `check(id, ref(claim))` | An executable check of the claim. |
| `world(term)` | A fact about the current state. A state that is not recorded is false. |
| `source(term, text)` | Where a `world` fact was observed: a file and line, a configuration key, a query, or a log. |
| `scope(oneof([in, out]), text)` | An item in scope or out of scope. |
| `risk(id, text)` | A risk to the work. |
| `assumption(id, text)` | An assumption that the work relies on. |
| `not_explored(text)` | An area that nobody explored. |
| `question(id, ref(claim), text)` | A dormant question about a claim. |
| `assumed(ref(question), term)` | The default answer to a question. |
| `answer(ref(question), term, oneof([human, agent]))` | An answer, and who gave it. |
| `depends(ref(question), ref(question))` | The first question depends on the answer to the second. |
| `note(ref, text)` | A free-text note about an ID of any kind. |
| `subject(id, text, digest)` | An artifact path and its sha256. A relative path starts at the KB directory. |
| `attest(id, atom, ref, attest_predicate, by, time)` | An attestation: ID, type, subject, predicate, writer, time. |

### Core attestation types

| Type | Shape | Writers |
|---|---|---|
| `disclosure` | `alt([guess(ref(question)), unverified(text), disagreement(text), out_of_scope(text), self_error(text), other(text)])` | `[agent, human]` |
| `divergence` | `alt([claim(ref(claim)), hypothesis(term), model(term)])`. Put the description in a `note/2`. | `[human, agent]` |
| `disproof` | `verdict(ref(claim), alt([refuted(text), inconclusive, abstained]))`. Put the counterexample in the text of `refuted`. | `[agent]` |
| `approval` | `digest(digest)` | `[human]` |
| `test_result` | `result(ref(check), int, oneof([pass, fail]))` | `[script]` |

### Core rules

| Query | True when |
|---|---|
| `superseded(C)` | A `supersedes(_, C)` fact exists. `C` can be a claim or a hypothesis. |
| `current(C)` | `C` is a claim and is not superseded. |
| `answered(Q)` | A human answered `Q`. |
| `defeated(Q)` | A human answer to `Q` differs from its default. |
| `refuted(C)` | An attestation gives `verdict(C, refuted(_))`. The text is the counterexample. A bare `refuted` is rejected (E3). |
| `contested(C)` | One or more `divergence` attestations name `claim(C)`. |
| `contested_twice(C)` | Two or more different `divergence` attestations name `claim(C)`. |
| `to_ask(Q)` | No human answered `Q`, no human waived `Q` (`question_waived`), its claim is current, and one of these is true: a question that `Q` depends on is defeated, or the claim is contested. |
| `question_waived(Q)` | Declared with no core clause. The build module adds it: a human `waiver` of question `Q` exists, and its due time is not past (D13). |
| `any_to_ask` | `to_ask(Q)` is true for one or more questions. |
| `stale(A)` | Human approval `A` names a digest that differs from the recorded digest of its subject. |
| `supersedes_closure(N, O)` | Computed by `orbit-kb` when it reads the KB. Claim (or hypothesis) `N` replaces `O` through one or more `supersedes` facts. |
| `supersede_cycle(C)` | Computed by `orbit-kb` when it reads the KB. Claim (or hypothesis) `C` replaces itself through one or more `supersedes` facts. Lint E15 reports it. |
| `any_supersede_cycle` | `supersede_cycle(C)` is true for one or more claims or hypotheses. |
| `passed(K)` | Check `K` passed in a run, and no run with a higher number failed. |
| `failed_after(K, R)` | Check `K` failed in a run with a number higher than `R`. |
| `was_red(K)` | Check `K` failed in a run before a run in which it passed. |
| `lint_issue(Code, Id, Message)` | Declared with no core clauses. Modules add clauses. See section 10. |

The source of these rules is in `core.pl`. A pass followed by a later fail
does not count as `passed`.

## 7. The build module

Load it with `uses([build])`. Its file is `modules/build.pl`.

### Build facts

| Fact | Meaning |
|---|---|
| `change(id, text)` | A change to the code, with the file or a short description. |
| `serves(ref(change), ref(claim))` | The change serves the claim. |
| `burn_requested(ref(claim))` | A human asked for a Lean proof of the claim. |
| `conformance(ref(check))` | The check runs the code against the Lean model of its claim. Optional. |

### Build attestation types

| Type | Shape | Writers |
|---|---|---|
| `lean_result` | `verdict(ref(claim), alt([stated, refuted(text), tested(int)]))` | `[agent, script]` |
| `lean_proof` | `proof(ref(claim), digest)` | `[script]`. Only `orbit-kb prove` writes it. |
| `waiver` | `waive(ref([claim, check, question]), time, text)`. The target is a claim, a check, or a question (D13). The time is the due time. The text is the reason. | `[human]` |

A `lean_result` records progress only. `stated` means that the statement
type-checks with `sorry`. `tested(N)` means that a search found no
counterexample in N trials. Neither is a proof. `lean_result` has no `proved`
verdict. A proof is a `lean_proof`.

### Build rules

| Query | True when |
|---|---|
| `fulfilled(C)` | A check of `C` passed, and nothing refutes `C`. If the label of `C` is not `preserve`, the check must also have failed before it passed (`was_red`). |
| `under(C)` | `C` is current, not fulfilled, and no human waived a check of `C` (`check_waived`). |
| `check_waived(C)` | A human `waiver` of a check of `C` exists, and its due time is not past. `C` does not block `done`, but it is not fulfilled (D13). |
| `served(X)` | Change `X` serves one or more claims. |
| `over(X)` | Change `X` serves no claim. |
| `any_under` | `under(C)` is true for one or more claims. |
| `any_over` | `over(X)` is true for one or more changes. |
| `any_current_claim` | `current(C)` is true for one or more claims (D17). |
| `no_current_claim` | No claim is current. Then `done` is false (D17). |
| `done` | `any_under`, `any_over`, `any_to_ask`, `any_burn_open`, `any_supersede_cycle`, and `no_current_claim` are all false. A KB with no current claim is not done (D17). |
| `burn_reason(C)` | `C` is contested twice, it is universal, or a human asked for a proof. |
| `burn(C)` | `C` needs a Lean proof: `burn_reason(C)`, or `C` replaces a claim with a burn reason, directly or through other claims (`supersedes_closure`). |
| `burn_proved(C)` | A `lean_proof` of `C` by `script` exists, and no file of that proof changed (`proof_changed`). |
| `burn_waived(C)` | A human `waiver` of `C` exists, and its due time is not past (`waiver_lapsed`). |
| `burn_open(C)` | `burn(C)`, `C` is current, and `C` is not proved and not waived. |
| `any_burn_open` | `burn_open(C)` is true for one or more claims. |
| `conforms(C)` | A `conformance` check of `C` passed. `done` does not need it. |
| `proof_changed(A)` | Computed by `orbit-kb` when it reads the KB. A file of proof `A` changed, or its log is missing or does not match. |
| `waiver_lapsed(W)` | Computed by `orbit-kb` when it reads the KB. The due time of waiver `W` is past, or it is not a valid time. |

### Burns need a proof

A burn is a claim that needs a Lean proof. The proof is the source of clarity:
to write the proof, you must state the claim correctly. A statement with
`sorry` is not enough. A search with no counterexample is not enough.

A burn closes in one of two ways. A waiver of a check of the claim does not
close a burn (see "Waivers" below).

1. `orbit-kb prove` records a proof. Then `burn_proved(C)` is true.
2. A human waives the proof until a due time. Then `burn_waived(C)` is true.
   Use `orbit-kb attest waiver c1 "waive(c1, '2026-11-30T17:00:00Z', 'why')" --by human`. The
   writer must be `human`. The writer says human; `orbit-kb` cannot verify it.
   `report` still shows the claim as `NOT PROVED`, with the due time. When the
   due time is past, the burn is open again. A due time that is not a valid
   time counts as past.

`done` is false while a burn is open. A superseded claim has no open burn. But
a claim that replaces a burning claim inherits the burn, also through a chain
of `supersedes` facts. So a restated claim needs its own proof. A `supersedes`
cycle, also `supersedes(C, C)`, is lint error E15, and `done` is false while it
exists. `add` refuses a `supersedes` fact that makes a cycle.

Each proof covers a set of files: the Lean source files of the project that the
proof imports, and the Lake configuration files. If one of these files
changes, the proof stops counting, and the burn is open again. `report` shows
`Proof A of claim C no longer counts.` Run `orbit-kb prove` again.

### Waivers

A human can waive a claim, a check, or a question until a due time (D13). The
same `waiver` type does all three. Only a waiver by `human` counts. An agent
waiver is E8, and it does not count. Every waiver needs a due time: the time to
come back to the item.

| Target | Effect while the waiver is in force |
|---|---|
| claim `C` | `burn_waived(C)`: the burn of `C` is closed. `C` must still be fulfilled or have a waived check. |
| check `K` of claim `C` | `check_waived(C)`: `C` is not `under`, so it does not block `done`. `C` is not `fulfilled`. A burn of `C` still needs a proof or a waiver of `C`. |
| question `Q` | `question_waived(Q)`: `Q` is not `to_ask`. It is not answered. |

```
orbit-kb attest waiver k1 "waive(k1, '2026-11-30T17:00:00Z', 'The CI runner is down')" --by human
orbit-kb attest waiver q1 "waive(q1, '2026-11-30T17:00:00Z', 'Ask the owner after the demo')" --by human
```

When the due time is past, or when it is not a valid time, the waiver lapses
(`waiver_lapsed`). Then the item blocks `done` again. `report` lists every
waiver in `Waivers:`, with its target, kind, due time, and state (`in force`,
`lapsed`, or not by a human). So a waived item is never silent in the delivery.
`rules.pl` cannot add clauses to `check_waived` or `question_waived` (E16).

A proof is about the Lean model. It is not about the shipped code. The checks
of the claim test the code, as for every claim. To test the code against the
Lean model, add a check, and mark it with `conformance(K)`. This step is
optional. `conforms(C)` shows the result.

## 8. Command reference

Usage: `orbit-kb [--dir DIR] COMMAND [ARGS]`. Run `orbit-kb help COMMAND` for
the text that the CLI prints.

### `init DIR (--request TEXT | --request-file F) [--uses m1,m2] [--id ID]`

Makes `DIR/kb.pl` with `uses([…]).` and `request(ID, 'TEXT').` The default ID
is `r1`. It prints the path of the new `kb.pl`.
Exit: 0 on success. 1 if `kb.pl` exists or the input is rejected.

### `uses MODULE …`

Adds library modules to the `uses([…])` line of an existing KB, for example when
the work moves from the discovery orbit to the build orbit (`orbit-kb uses
build`). It keeps the modules in use and adds the new ones at the end. It never
removes a module. It changes only the text of the first term of `kb.pl`. Comments, the full
stop, and the other clauses stay as they are. It holds the KB lock and writes
a temp file that it renames into place. If `kb.pl` is a symlink, it writes the
target. It does not load the KB first, so it works on a KB whose facts need the
new module. `build,discovery` also works. It prints the new `uses` line. Then
run `lint`: the new module can add findings, such as ED7 of the discovery
module. `add` refuses a `uses/1` fact and names this command.
Exit: 0, also when the KB already uses every module. 1 on an unknown module, or
a first term that is not `uses/1` with a list of module names. 2 on a usage
error, or when `kb.pl` cannot be written.

### `add 'FACT' …`

Appends facts to `kb.pl`. The final full stop is optional. Facts in one command
can refer to each other. If one fact is wrong, nothing is written. `add` refuses
a classical negation `-world(x)` (E17): a fact that is not recorded is false. `add` refuses types whose writers are
`[script]`. Use `run` or `prove` for those.
Exit: 0 on success. 1 on a rejection. The message gives the fix.

### `declare 'HEAD' --doc TEXT [--kind fact|rule] [--template T]`

Appends a local `decl/4` line to `kb.pl`. The default kind is `fact`.
Exit: 0 on success. 1 if the name and arity are declared, a type is unknown, or
the name is reserved.

### `declare-attest TYPE 'SHAPE' --doc TEXT --writers human,agent`

Appends a local `attest_type/4` line to `kb.pl`. The checks of `declare` apply.
Exit: 0 on success. 1 on a rejection.

### `subject ID PATH`

Records the sha256 of a file as `subject(ID, PATH, DIGEST)` and prints the
digest. A path inside the KB directory is stored relative to it. Other paths are
stored as absolute paths. If `subject(ID, …)` exists, only that line changes.
The rewrite is atomic: the command writes a temp file in the KB directory, and
then renames it.
Exit: 0 on success. 1 if the file is missing.

### `attest TYPE SUBJECT 'PREDICATE' [--by human|agent] [--id ID]`

Appends `attest(ID, TYPE, SUBJECT, PREDICATE, BY, TIME)`. `--by` defaults to
`agent`. The ID defaults to the next free `aN`. The time is now, in UTC.
`orbit-kb` checks the shape, the writer, and the references. The predicate
`digest(current)` becomes the recorded digest of SUBJECT. The file must still
have that digest. If the file changed, run `orbit-kb subject` first.
A `vote` (discovery module, D14) by the agent is refused when the human already
voted in the same round, because that vote can no longer be sealed.
Exit: 0 on success. 1 on a rejection.

### `run CHECK -- CMD [ARGS]`

Runs CMD for a check. CMD runs without the KB lock, so a long check does not
stop other writers. The combined output goes to a temp file in `runs/`.

When CMD ends, `run` takes the lock and does these steps:

1. It reads `kb.pl` again, because other writers can add facts while CMD runs.
2. It sets N to the highest run number in a `test_result` or in a log name, plus 1.
3. It writes `runs/N-CHECK.log`.
4. It appends a `test_result` attestation: `pass` if CMD exits 0, else `fail`.

Thus `run` numbers the runs in the order that they finish, not in the order
that they start. The time in the log and in the attestation is the time at which CMD
ended. `run` prints `run N CHECK pass|fail (exit E) log=PATH`. On a fail, it
also prints the last 40 lines of output.

If `run` gets SIGINT or SIGTERM, it stops CMD and records nothing. It prints a
message that ends with `Nothing was recorded.` It exits 130 for SIGINT and 143
for SIGTERM.
Exit: 0 on pass. 1 on fail. 2 if the check or the command does not exist. 130
for SIGINT. 143 for SIGTERM.

### `prove CLAIM FILE THEOREM [--module M]`

Checks a Lean proof of a claim. If the proof passes every check, `prove`
records it as a `lean_proof` attestation. FILE is a `.lean` file in a Lake
project. The project root is the nearest directory, from the directory of FILE
upward, with `lakefile.toml` or `lakefile.lean`. The module name comes from the
path: `Fx/Load.lean` is `Fx.Load`. If the library has another source
directory, give the module with `--module`.

`prove` does these steps. Each step runs in the project root, without the KB
lock:

1. `lake build MODULE`.
2. `lake env lean --run probe.lean MODULE THEOREM ROOT`. The probe is
   `lean/probe.lean` in the library. It imports the built module, and it prints
   the facts about THEOREM: its kind, its module, its axioms, its statement,
   and the project files that the module imports. The probe decides nothing.
3. `orbit-kb` reads the facts. THEOREM must be a theorem. The module of FILE
   must declare it. It must depend on no axiom other than `propext`,
   `Classical.choice`, and `Quot.sound`. Thus `sorry` (the axiom `sorryAx`),
   `native_decide`, and a local `axiom` all fail this step.
4. `lake env leanchecker` replays each project module of the proof in the
   kernel. A declaration that skipped the kernel check fails this step. The
   project modules are the modules under the project root and outside
   `.lake/`. A dependency is not replayed.
5. `prove` computes the digest of each file of the proof. Then
   `lake build --no-build MODULE` makes sure that no file changed during the
   checks.
6. `prove` takes the lock. It writes `runs/proof-ID.log`, and it appends
   `attest(ID, lean_proof, CLAIM, proof(CLAIM, DIGEST), script, TIME)`.

The log holds the theorem, the module, the source file, the statement, the
Lean version, the axioms, the project constants that the statement uses, the
project root, one line `file SHA PATH` for each file of the proof, and one line
`absent PATH` for each Lake configuration file that does not exist. Then it
holds the output of `lake build`. The digest in the attestation is the sha256
of these lines, each with a newline: `claim C`, `theorem T`, `module M`,
`statement S`, then `SHA PATH` for each file, then `absent PATH` for each
absent file. So the digest binds the claim, the theorem, and the statement of
the log to its files. A proof counts only when the log header names the claim
and the digest of the attestation, the lines of the log give that digest, each
file still has its sha256, and each absent file is still absent. A log copied
for another claim, or an edited log, does not count (lint E9).

`prove` prints the statement. `orbit-kb` cannot check that the statement says
what the claim says. Read the statement, and show it to the human.

```text
$ orbit-kb prove c1 lp/Fx/Load.lean load_linear
proof a1 of claim c1: theorem load_linear (Fx.Load)
Statement: ∀ (n : Nat), loadSteps n ≤ n
Log: /…/kb/runs/proof-a1.log
Check that the statement says what claim c1 says. orbit-kb cannot check that.
```

If a check fails, `prove` prints `Not proved. Nothing was recorded.`, the
reason, and the last 40 lines of the tool output.
Exit: 0 when the proof is recorded. 1 when it is not a proof. 2 on a usage
error, a missing claim or file, a missing Lake project, or a missing `lake`.
The time is about 2 s to 6 s for a small project, most of it in Lean.

### `lint [--strict]`

Examines `kb.pl`, `rules.pl`, the core, and the modules. It prints one line per
problem, then the module `lint_issue` results, then a summary line. Section 10
lists the codes. `lint` still runs when a source has E1 or E2. The commands
that answer (`query`, `why`, `whynot`, `show`, `report`) stop in that case
(section 9).
Exit: 0 if clean or only warnings. 1 on errors, or on warnings with `--strict`.

### `query 'GOAL' [-n N] [--why] [--long]`

Answers GOAL with the SWI engine. Each predicate in GOAL must be declared or
built in. `-n N` shows N answers. The default is 1, and 0 shows all answers.
The output is one line per answer, `true` or `X = v, Y = w`. If there is no
answer, the output is `false`.

| Option | Effect |
|---|---|
| `--why` | After each answer, adds the clauses that prove it, 6 levels deep. |
| `--long` | Makes the explanation 30 levels deep. |

`--json` and `--html` do not exist any more (D20). They are usage errors
(exit 2).

Exit: 0 on an answer. 1 on no answer. 2 on a bad goal, an undeclared
predicate, a source that lint must fix first (E1, E2 in `rules.pl`, E17, E18:
section 9), or `SWI ERROR`.

### `why 'GOAL' [-n N] [--long]`

The same as `query --why`. The exit codes are the same as for `query`. For
each answer, `why` prints the answer, then "X, because" and, indented under
it, why each literal of the rule that proves it holds. A `not` literal reads
"there is no evidence that X". The text of an atom comes from the template of
its declaration. An explanation never changes a verdict.

```text
$ orbit-kb why 'under(X)'
X = c1

claim c1 is current but not fulfilled, because
   claim c1 is current, because
      c1 is a claim to introduce: The Buy button is purple.
      there is no evidence that c1 is superseded, because
         the rule for superseded/1 stops at supersedes(_, c1):
            nothing records supersedes(_, c1): no fact or rule matches it
   ...
```

### `whynot 'GOAL' [--long]`

The first line is the verdict of the SWI engine: `holds` or `absent`
(section 9). Then it explains the verdict from the same clauses, 6 levels deep
(`--long`: 30). For `holds`, it prints the clauses that prove the first
answer. For `absent`, it prints, for each rule of GOAL, the first body literal
that no answer gets past, and why, recursively. Exit: 0. 2 on a syntax error
(E1), an undeclared predicate (E2), E17, or E18 in a source file.

### `show [claims|questions|open|disclosures|extensions|all]`

Lists parts of the KB as plain text. The default is `all`. `open` lists
`to_ask`, `stale`, and `contested`. When the `build` module is in use, `open`
also lists `under`, `over`, and `burn_open`, and `no_claim` when no claim is
current (D17). `claims` shows the burn state of
each claim that burns: proved, waived (`NOT PROVED`), or open. It shows a claim
with a waived check as `not fulfilled`, and `questions` marks a waived question. `show` runs one query for each relation, not
one query for each fact.
Exit: 0. 2 on an unknown topic, or on E1 or E2 in a source file.

### `report`

Prints a skeleton of a delivery report with these sections: `Delivered:`,
`Claims:`, `Guesses:`, `Disclosures:`, `Waivers:` (with the `build` module),
`Not checked:`, `Open:`, `To land:`.
You write `Delivered` and `To land` yourself. Step 16 of section 3 shows an
example. The text is plain Markdown that also reads as raw text (D16 c4). Each
section has a heading, `# Claims:`, and a blank line before the next heading.
Each item is a bullet, indented two spaces, and each nested level adds two more.
The label is in `**bold**`: the kind of a claim, of a disclosure, and of an open
item, and the state of a waiver. A claim that needs attention (`under`, a waived
check, a burn that is not proved, or a check that did not pass or has no run)
puts its `Status:`, `Burn:`, and `Checks:` in nested bullets, and the detail
sentence under each. A fulfilled claim with nothing to add stays on one line, when
the line fits in 100 columns. Long lines are not wrapped. In `Open:` and `Vote:`,
the first sentence is the bullet and the rest is nested. Like `show`, `report` runs one query for each relation. For a claim
that burns, `Claims:` adds `Burn: proved in Lean.` or `Burn: NOT PROVED.` with
the waiver due time. A claim with a waived check shows `Status: not fulfilled`
with the check and the due time. `Waivers:` lists every waiver: its id, the kind
and id of its target, its due time, and whether it is in force or lapsed.
`Open:` lists each open burn, each waiver past its due time (of a claim, a
check, or a question), and each proof that no longer counts. With the `build`
module, when no claim is current, `Open:` says `**no claim**: No claim is
current`, because `done` is false without a current claim (D17). When no question
has a default, `Guesses:` says `None. No question has a default.` It says that a
human answered every question only when a question with a default exists. When
no claim is current, `Not checked:` says `None. No claim is current.`
With the `discovery` module, a `Vote:` section comes before `To land:` (D14).
Until the human votes in the current round, it says only whether the agent
voted, and it does not show the agent's choice or the formal artifacts' vote.
After the human votes, it shows the three votes with their weights, the
outcome (`gate`), and, on a split, a reminder to record a divergence.
Exit: 0. 2 on E1 or E2 in a source file.

`report --html FILE [--open]` (D16) prints the same text, and also writes the
report as one HTML page for a human to review in a browser. The page is self-
contained: its style and script are inline (from `report/page.css` and
`report/page.js` in the library), and it loads nothing from the network, so it
works from `file://`. It shows:

- the request, and a summary (claims by status, open items, `done`);
- first, the open items: each `under` claim, and each line of `Open:`;
- each claim with its status as a text label and a color, the status sentence
  of the text, and its checks with the latest run (number, result, time, and a
  link to `runs/N-CHECK.log`). Its evidence expands below it: citations,
  examples, divergences with their notes, disclosures, waivers with the due
  time, questions, and notes. It starts open when the claim needs attention;
- the guesses, disclosures, waivers, `Not checked:`, and `Vote:` lines, and
  the plain text at the end.

The page is built from the lines that `report` prints, so the two always say
the same thing. The "done: yes/no" chip of the page comes from the SWI verdict
on `done`. The page has no cross-check (D20).

For review, each claim and each item has the marks `ok`, `doubt`, and `wrong`
and a short note. "Copy review for the agent" writes the marks as text, one
line per item, such as `c1: doubt - the example does not cover X`, and copies
it when the browser allows; the text also shows in a box to select. The page
cannot change the KB. Marks stay in the browser (`localStorage`, under the KB
path and the digest of the report text), so a new report starts with no marks.
Every KB string is HTML-escaped. `--open` opens the page with `xdg-open` (or
`open`); without it, nothing opens. Exit: as `report`; 0 when the page is written;
2 when the file cannot be written.

### `doctor`

Examines `swipl` and the library, and prints a fix step for each missing
item. Then it runs the known-answer self-tests on the SWI engine, as a query
does. Each line starts with `ok`, `info`, `FAIL`, or `skip`. A full run prints
7 `ok` lines.

| Check | What `doctor` makes sure of |
|---|---|
| 2 tool checks | `swipl` and the library directory exist. |
| helper form | `done` is false when a helper rule (`any_under :- under(_)`) is under `not`. |
| `not under(_)` | `done :- not under(_)` is false when `under(a)` holds: no `under` at all. |
| arithmetic under `not` | `passed(K)` is exactly k2, k3, k4 (the four checks in section 11). |
| E18 | Lint flags `p :- not q` with `q :- not p`. |
| E17 | Lint flags the classical negation `-p(b)`. |

Exit: 0 if all checks pass. 2 if an item is missing or a self-test fails.

### `help [COMMAND|TOPIC]`

Shows the general help, the help for one command, or one topic. The general
help starts with a "How to use" block (the order of the commands, and the
topics). It then explains the engine: negation as failure, and stratified
rules.

The topics are plain files in `help/` beside this README: `core`, `build`,
`discovery` (with one recipe for each move), `codes` (the lint codes), and
`answers` (exit codes, `why`, and `whynot`). They exist so that an agent
loads the syntax when a move needs it. The agent prompt
(`prompt/SAGITTARIUS.md`) holds only the rules that come before the first
command, and tells the agent to run `orbit-kb help`. Test HP4 to HP6 check
the topics. Exit: 0. An unknown name exits 2.

### Locking

The commands `add`, `declare`, `declare-attest`, `subject`, `attest`, and `uses` hold
an exclusive lock on `kb.lock` in the KB directory for the whole cycle. The
cycle is: read `kb.pl`, choose the ID, write, and append. Thus two writers in
two processes cannot choose the same ID. `run` and `prove` take the lock only
to record their result (see `run`). The commands that only read the KB take no lock.

`flock(1)` from util-linux gives the lock. A lock goes away when the process
ends, for any reason, so a stale lock cannot occur. If `flock(1)` is not on
`PATH`, for example on macOS, `orbit-kb` uses the lock that SWI-Prolog takes on
`kb.lock`.

## 9. Exit codes, and how to read answers

| Code | Meaning |
|---|---|
| 0 | Success. The query is true. Lint is clean. |
| 1 | The query has no answer. Lint found errors. `orbit-kb` rejected the input. A `run` failed. `prove` found no proof. |
| 2 | Usage error. The KB, the library, or a tool is missing. A goal is bad, or names an undeclared predicate. A source has a syntax error (E1), `rules.pl` has an undeclared predicate (E2), or a source has an E17 or E18 form, and the command must answer. `SWI ERROR`. Internal error. |
| 130, 143 | `run` got SIGINT (130) or SIGTERM (143). It recorded nothing. |

A typo never exits 1. Exit 1 always means a real "no". If you get exit 2, do
not read it as "false".

### A broken source gives exit 2

`query`, `why`, `whynot`, `show`, and `report` check the sources before they
answer. Four cases stop them with exit 2:

- A KB file or a rules file has a syntax error (E1).
- `rules.pl` has an undeclared head or body predicate (E2).
- A source has a form that `orbit-kb` does not read (E17): classical negation
  `-p`, a `#` line, a global constraint `(:- Body)`, or a `#=` constraint.
- The rules are not stratified (E18): a predicate depends on itself through
  `not`.

In each case `orbit-kb` cannot load every clause, or negation as failure has no
single answer. An answer can be wrong. So it prints the lint lines and gives
no answer. It never prints a quiet `false`.
This example has an unclosed term in `rules.pl`:

```text
$ orbit-kb query 'current(C)'
E1 rules.pl:1: Syntax error: end of file.
A source file has a syntax error. orbit-kb drops a clause that does not parse, so an answer could be wrong.
Fix: correct each line above, then run orbit-kb lint.
orbit-kb gives no answer until then. This is not a false answer.
```

An undeclared body predicate gives an E2 line and the text
`rules.pl names a predicate that is not declared.` Correct the lines that
`orbit-kb` prints. Then run `orbit-kb lint`.

An E17 or E18 line stops the command in the same way. This example has the
rules `p :- not q.` and `q :- not p.` in `rules.pl`, with `p` and `q` declared:

```text
$ orbit-kb query 'p'
E18 rules.pl:1: p/0 depends on itself through not q/0 (the rules are not stratified). Negation as failure has no single answer for such a program. Fix: break the cycle, for example with a fact that records the case.
E18 rules.pl:2: q/0 depends on itself through not p/0 (the rules are not stratified). Negation as failure has no single answer for such a program. Fix: break the cycle, for example with a fact that records the case.
The rules are not stratified, so negation as failure has no single answer.
Fix: correct each line above, then run orbit-kb lint.
orbit-kb gives no answer until then. This is not a false answer.
```

(Before D20, a program such as `p :- not q. q :- not p.` made SWI-Prolog hit
its stack limit.)

### `SWI ERROR`

When the SWI engine cannot evaluate a goal, `orbit-kb` prints `SWI ERROR:`
and the message, and exits 2. It is not a false answer:

```text
$ orbit-kb query 'X is 1/0'
SWI ERROR: //2: Arithmetic: evaluation error: `zero_divisor'
The SWI engine could not evaluate the goal. This is not a false answer.
```

The engine stops a query after 10 s or after 1000 answers.

### `whynot`: `holds` and `absent`

| First line | Meaning |
|---|---|
| `holds` | GOAL has an answer. The clauses that prove it follow. |
| `absent` | GOAL has no answer. For each rule of GOAL, the first body literal that no answer gets past follows, and why. |

`absent` means that the KB holds no evidence. The survey can have missed it:
ask whether the fact should exist. When no fact or rule matches an atom, the
text says `nothing records X: no fact or rule matches it`. This is a real
example (the KB of section 3, before any run):

```text
$ orbit-kb whynot done
absent

there is no evidence that the work is done, because
   the rule for done/0 stops at not any_under:
      some current claim is not fulfilled, because
         claim c1 is current but not fulfilled, because
            ...
```

The explanation is 6 levels deep. `--long` makes it 30 levels deep. An
explanation never changes a verdict. A KB has no way to record that something
is false: a fact that is not recorded is false (negation as failure). To
record a negative case, write it as a positive fact, such as
`world(door_closed)`, or as a note.

## 10. Lint codes

Each diagnostic has the form `E<n> file:line: message` or `W<n> file:line: message`.

| Code | Error |
|---|---|
| E1 | Syntax error, with file and line. In any source, E1 makes `query`, `why`, `whynot`, `show`, and `report` exit 2. |
| E2 | Undeclared predicate or wrong arity, in `kb.pl` facts or in the heads and bodies of `rules.pl`, `core.pl`, and the modules. If a declaration has the same name but a different arity, the message names it. In `rules.pl`, E2 makes the commands that answer exit 2. |
| E3 | Type error. This includes a label outside `oneof`. |
| E4 | Dangling `ref`, or a `ref` to the wrong kind of id. A `supersedes` fact must name two claims or two hypotheses (D15). |
| E5 | Duplicate ID. |
| E6 | Non-ground fact in `kb.pl`. |
| E7 | A clause in the wrong place: a `rule` predicate as a fact in `kb.pl`, or a `fact` predicate with clauses outside `kb.pl`. |
| E8 | The writer is not permitted for the attestation type. This includes a `[script]` type whose writer is not `script`. |
| E9 | A `test_result` with no matching run log. The log header must match N, the check, and the result. Also a `lean_proof` with no matching `runs/proof-ID.log`. Its header must match the claim and the digest, and the claim, theorem, module, statement, file, and absent lines of the log must give the digest. |
| E10 | `uses/1` is missing, is not first, or names an unknown module. |
| E11 | A clause does not load in the SWI engine. |
| E14 | Unsafe negation: a variable of a `not` literal occurs in the head, but in no positive body literal. A call with that variable unbound then gives a wrong answer. |
| E15 | A `supersedes` fact on a cycle: a claim (or a hypothesis) replaces itself, directly (`supersedes(C, C)`) or through others. `done` is false while the cycle exists. `add` refuses such a fact. |
| E16 | `rules.pl` adds clauses to a protected library predicate: `done`, `burn`, `burn_reason`, `burn_proved`, `burn_waived`, `burn_open`, `any_burn_open`, `any_current_claim`, `proof_changed`, `waiver_lapsed`, `check_waived`, `question_waived`, `supersedes_closure`, `supersede_cycle`, `any_supersede_cycle`, or a vote rule of the discovery module (`vote_cast`, `discovery_vote_raised`, `vote_round`, `human_vote`, `agent_vote`, `artifact_vote`, `discovery_gate_agreed`, `gate`, `gate_split`). The engine ignores the clause. |
| E17 | A form that `orbit-kb` does not read (it is s(CASP) syntax): classical negation `-p` (in a fact, a rule head, or a body literal), a `#` line, a global constraint `(:- Body)`, or a `#=`-family constraint. `add` refuses it. It applies in `kb.pl` too, and a goal with such a form exits 2 with the E17 text. `query`, `why`, `whynot`, `show`, and `report` exit 2 while an E17 exists. |
| E18 | The rules are not stratified: a predicate depends on itself through `not`. The same commands exit 2 while an E18 exists. |

| Code | Warning |
|---|---|
| W1 | The subject digest differs from the file on disk, or the file is missing. Refresh it with `orbit-kb subject`. |
| W2 | A local declaration, listed for review. |
| W3 | A claim with no `cites`. |
| W4 | A local fact predicate that no rule reads. |
| W5 | A `check` of a superseded claim, while the current claim that replaces it (directly or through a chain) has no check. Check ids are unique (E5) and facts are append-only, so the message says to add a new check of the current claim and run it (D15). |
| W6 | A local rule that adds clauses to a core or module predicate (an extension). For a protected predicate, it is E16 instead. |

Built-ins that E2 permits: `=`, `\=`, `<`, `>`, `=<`, `>=`, `is`, `true`,
`false`, `forall/2`. Lint unwraps `not G`.

### E14, E17, and E18: checks for `not`

`not p` is negation as failure: it holds when `p` has no answer. So
`done :- not under(_).` means "there is no `under` at all", and it needs no
helper rule (the core rules keep their helper forms, such as `not any_under`).
Three codes guard the use of `not`:

- E14: a variable occurs in the head and in the `not` literal, but in no
  positive body literal. The variable has no value when the `not` literal runs.
  The fix is a positive literal before the `not` literal that gives the
  variable its values.
- E17: classical negation `-p` has no meaning for the engine. A fact that is not
  recorded is false.
- E18: a predicate depends on itself through `not`. Negation as failure has no
  single answer for such a program. Break the cycle.

The rule `unsafe(X) :- claim(C, _, _), not served(X).` gives E14:

```text
E14 rules.pl:1: In unsafe/1, the literal `not served(X)` uses X. It occurs in the head, but no positive literal in the body binds it (unsafe negation). A call with X unbound then gives a wrong answer. Fix: before the not literal, add a positive literal that gives X its values, for example a fact or a rule that lists them.
```

### The module hook `lint_issue/3`

`lint_issue(Code, Id, Message)` is a core rule predicate with no core clauses.
A module adds clauses to it, and `rules.pl` can add clauses too. `orbit-kb lint`
evaluates it with the SWI engine. It prints each result as
`<Code> <Id>: <Message>`. A code that starts with `E` is an error. Other codes
are warnings. Write the code as a quoted atom, for example:

```prolog
lint_issue('W9', c1, 'custom hook warning') :- claim(c1, _, _).
```

Lint then prints `W9 c1: custom hook warning`.

## 11. The engine, and why

SWI-Prolog is the only engine. Until 2026-11-02, a second engine, s(CASP),
explained the answers and checked them (D8, D20). Section 15 has the history.

| Step | How |
|---|---|
| Load | `orbit-kb` loads the program as assembled (section 4) into a fresh module. `not G` becomes `\+ G`, and each `not` literal moves after the positive literals of its clause. A clause with a form of E17 is skipped. Each declared predicate is dynamic. |
| Answer | The engine collects the answers with a limit of 10 s and 1000 answers, and removes duplicates. These are the answers that `orbit-kb` prints. |
| Explain | `why` and `whynot` read the same clauses. They print the proof of an answer, or the literal where a rule stops. They never change a verdict. |

Each `not` literal moves after all positive literals of its clause. Builtins
keep their place relative to the positive literals. In a stratified program,
this does not change the answers. It prevents floundering, which is `\+`
running on a variable that has no value. Lint error E14 finds the rules where a
`not` variable gets no value from a positive literal.

### Negation as failure

`not p` holds when `p` has no answer. This is the usual closed-world meaning:

- `not under(_)` means "there is no `under` at all". A rule does not need a
  helper such as `any_under :- under(_)`. The core rules keep their helper
  forms. They do not change.
- A fact that is not recorded is false. There is no classical negation `-p`
  (E17). To record a negative case, write a positive fact or a note.
- Arithmetic under `not` is exact. In the core rule `passed/1`, `R2 > R` is
  under `not`. Four checks have these runs:

  | Check | Runs |
  |---|---|
  | k1 | pass(1), fail(2) |
  | k2 | fail(3), pass(4) |
  | k3 | pass(5) |
  | k4 | pass(6), fail(7), pass(8) |

  The answer to `passed(K)` is exactly k2, k3, and k4. `doctor` tests this.
- Atoms that end in `_<digits>`, such as `order_4417`, are ordinary atoms.

### Stratification

The core rules and the module rules are stratified: no predicate depends on
itself through `not`. For a stratified program, negation as failure gives the
one answer of the program (its perfect model). Lint error E18 keeps `rules.pl`
inside the same fragment. For a program that is not stratified, such as
`p :- not q. q :- not p.`, the SWI engine has no single answer, and before D20
it hit its stack limit. Now the commands that answer exit 2 until the cycle is
gone.

### Why one engine (D20)

Ty decided on 2026-11-02 ("option 2") to drop s(CASP). Two read-only audits
gave the reasons:

- Every rule is stratified, so negation as failure is correct for the programs
  that `orbit-kb` targets.
- The code that only s(CASP) used was about 1,430 lines, about 23% of the CLI
  (the `scasp` call, the grounder, the cross-check, and the result cache).
- In 17 real client-project sessions, `why` had 0 calls, and `whynot` had about
  20. All were of the kind "what blocks `done` or `discovery_ready`".
  `ENGINE DISAGREEMENT` happened 0 times, and `CROSS-CHECK SKIPPED` once (a
  timeout).
- In the git history, every disagreement was a tool bug, never an error in
  the KB logic.

The explanations now come from the SWI engine. A verdict does not depend on
them.

### Performance

The times are wall-clock seconds on this laptop, with the caches off
(`ORBIT_KB_NO_CACHE=1`), measured on 2026-11-02. Each KB has one check for each
claim and two runs for each check. For example, 400 attestations are 200
claims.

| Attestations | Query | Time (s) |
|---|---|---|
| 100, 200, 400 | `done` | 0.09 |
| 100, 200, 400 | `passed(K) -n 0` | 0.09–0.10 |
| 100, 200, 400 | `why fulfilled(c1)` | 0.09–0.10 |

Typical tickets have 1–20 claims. The speed work has these parts:

- **Saved state.** Loading the script and its libraries takes about 80 ms. A
  saved state starts in about 35–40 ms. The state is in
  `${XDG_CACHE_HOME:-~/.cache}/orbit-kb/`. Its key is the text of the script,
  the path of the script, and the SWI-Prolog version and executable. A sidecar
  file `.ok` holds the size and the SHA-1 of the state. If the state is bad,
  the CLI loads the script as usual. The first run after a script change builds
  a new state, which takes about 0.3 s. The owner keeps the saved state; a fix
  of its cache race (GitHub issue #4) must keep it.
- **Lazy libraries.** Libraries that only some commands need load on first use.
- **Hot spots.** The quadratic loops of lint use AVL sets. `show` and `report`
  run one query for each relation.

`ORBIT_KB_NO_CACHE=1` turns off the saved state.

## 12. Extending

### Local predicates and `rules.pl`

A KB can add its own vocabulary without a change to the library.

1. Declare each new fact predicate with `orbit-kb declare`.
2. Declare each new rule predicate, helpers included, with
   `orbit-kb declare --kind rule`.
3. Write the rules in `rules.pl` in the KB directory.
4. Run `orbit-kb lint`.

A real example:

```text
$ orbit-kb declare 'owner(ref(claim), text)' --doc 'The person who owns the claim.' --template 'claim @(1) is owned by @(2)'
decl(fact, owner(ref(claim), text), 'The person who owns the claim.', 'claim @(1) is owned by @(2)').
$ orbit-kb declare 'has_owner(ref(claim))' --kind rule --doc 'Some person owns the claim.'
decl(rule, has_owner(ref(claim)), 'Some person owns the claim.', '').
$ orbit-kb declare 'any_unowned' --kind rule --doc 'Some claim has no owner.'
decl(rule, any_unowned, 'Some claim has no owner.', '').
```

The `rules.pl`:

```prolog
has_owner(C) :- owner(C, _).
any_unowned :- claim(C, _, _), not has_owner(C).
```

```text
$ orbit-kb lint
W2 kb.pl:5: Local declaration of owner/2 (fact): The person who owns the claim. Review it.
W2 kb.pl:6: Local declaration of has_owner/1 (rule): Some person owns the claim. Review it.
W2 kb.pl:7: Local declaration of any_unowned/0 (rule): Some claim has no owner. Review it.
Summary: 0 error(s), 3 warning(s).
$ orbit-kb query any_unowned
true
$ orbit-kb add "owner(c1, 'Ana')"
owner(c1, 'Ana').
$ orbit-kb query any_unowned
false
```

Lint lists each extension for a human to review:

- W2 lists each local declaration.
- W6 lists each local rule that adds clauses to a core or module predicate.
- W4 lists each local fact predicate that no rule reads.

`orbit-kb show extensions` gives the same list in plain text. With
`lint --strict`, these warnings make lint exit 1.

`declare` refuses a name and arity that is declared anywhere:

```text
$ orbit-kb declare 'world(term)' --doc 'x'
Rejected. Nothing was written.
world/1 is already declared in the core (/home/you/sagittarius/kb/share/orbit-kb/core.pl:77). Choose another name, or use the declaration that exists.
```

### Writing a new module

1. Make the file `modules/<name>.pl` in the library directory
   (`kb/share/orbit-kb/modules/` in this repository).
2. Load it in a KB with `uses([<name>])`. If the file does not exist, lint
   gives E10.
3. Declare every predicate with `decl/4`. This includes rule predicates and
   helper predicates.
4. Declare each attestation type with `attest_type/4`.
5. Write the rules in the same file.
6. Run `orbit-kb lint` in a KB that uses the module. Then run
   `orbit-kb doctor`.

The rules for a module:

- **Facts.** A `fact` predicate has no clauses in a module. Its facts go in
  `kb.pl` only. A clause in the module gives E7.
- **Templates.** Put the explanation text in the `Template` argument of
  `decl/4`. `why` and `whynot` print it. Do not write `#pred` lines (E17).
- **Text.** Write all text as single-quoted atoms. Do not use double-quoted
  strings.
- **Negation.** `not p` is negation as failure. A `not` literal can hold a
  variable that occurs nowhere else in the clause: `not under(_)` means "no
  under at all". The core rules still use helper forms such as
  `any_under :- under(_).` Atoms that end in `_` and digits are allowed.
- **E14.** If a variable occurs in a `not` literal and in the head, it must
  also occur in a positive body literal.
- **Stratification.** Write stratified rules: no predicate depends on itself
  through `not` (E18). Do not write classical negation `-p`, a `#` line, a
  global constraint, or a `#=` constraint (E17).
- **No `:- false` stubs.** Do not write `p(_, _) :- false.` The engine makes
  each declared predicate dynamic, so a predicate with no clauses fails. A stub
  for a fact predicate in a module gives E7.
- **Domain.** Keep software terms out of the core. Put them in a module.
- **Lint hook.** To add module-specific lint results, add clauses to
  `lint_issue/3` (section 10).

Reserved names:

- `declare` refuses these names: `decl`, `attest_type`, `uses`, `not`, `true`,
  `false`, `forall`, `call`, `is`, and the operators `=`, `\=`, `<`, `>`, `=<`,
  `>=`, `,`, `;`, `->`, `:-`, `#`, `\+`, `-`, `#=`, `#<>`, `#<`, `#>`, `#=<`,
  `#>=`. Until D20, it also refused `proved`, `chs`, `assume`, and `abduced`,
  because s(CASP) wrapped model terms in these names (D10). Now they are
  ordinary names.
- The `discovery` module reserves these names. They must not appear in the
  core or in the `build` module:
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
  - The vote (D14): `vote_cast/3`, `vote_round/1`, `human_vote/1`,
    `agent_vote/1`, `artifact_vote/1`, `gate/1`, `gate_split/0`.
  - Attestation types: `reproduction`, `model_result`, `decision`, `vote`.
    (Calibration is a `model_result` shape, not a type.)
  - Lint codes: `WD1`–`WD9` and `ED1`–`ED10`.

### The GO / NO-GO vote (D14)

At the end of discovery, three roles vote `go`, `no_go`, or `hold`: the human
(weight 0.49), the agent (0.24), and the formal artifacts (0.24).

- `attest(ID, vote, SUBJECT, vote(Round, Choice), BY, TIME)`, writers `agent`
  and `human`. The subject is the request. Round 1 is the first gate. After a
  HOLD, the next gate is round 2, and so on. Only the largest round with a vote
  counts (`vote_round/1`). A second vote by one writer in one round is ED10.
- `artifact_vote(V)`: `go` when `discovery_ready` holds and a claim is
  current; `no_go` when `discovery_ready` holds and no claim is current (so a
  hypothesis did not reproduce); `hold` otherwise. It reads the KB as it is
  now, not as it was when the others voted.
- `gate(V)`: a choice wins when its votes add up to more than 0.5. No role
  wins alone, and the agent and the formal artifacts together have 0.48, so a
  win is the human plus at least one other role. Any other result is `hold`. `gate` has no answer
  until the human votes in the current round.
- `gate_split`: the human voted, and no other role agrees. The outcome is
  `hold`. Record the disagreement as a `divergence` with `hypothesis(H)`.
- Sealing. The agent votes first. `report` does not show the agent's choice
  or the formal artifacts' vote until the human votes. `attest` refuses an
  agent vote in a round in which the human already voted. WD9 warns about a
  human vote with no agent vote in its round.
- Limit. Sealing guards an honest mistake only. The CLI cannot hide data from
  the agent: `query 'agent_vote(V)'` or `kb.pl` shows the vote, and a hand edit
  can add a vote in any order. WD9 checks that an agent vote exists in the
  round, not that it came first.

```sh
orbit-kb attest vote r1 'vote(1, go)'               # the agent, before the report
orbit-kb attest vote r1 'vote(1, hold)' --by human  # the human, after the report
orbit-kb query 'gate(V)'                            # V = hold
orbit-kb query gate_split                           # true: record a divergence
```

### Reword a hypothesis (D15)

When the human asks to reword a hypothesis, add a new hypothesis and
`supersedes(New, Old)`, as for a claim. Nothing else is new.

- Both ids are hypotheses. A claim and a hypothesis in one `supersedes` fact is
  E4, and `add` refuses it.
- A superseded hypothesis is out of play. It raises no WD7, and
  `discovery_ready` does not need a system result for it
  (`some_hypothesis`, `some_untouched_hypothesis`). Its `not_reproduced`
  result is no outcome (`discovery_has_outcome`), and it raises no WD6. The
  new hypothesis needs its own result.
- `supersedes_closure/2`, `supersede_cycle/1`, and E15 cover hypotheses too.
  `current/1`, `under/1`, and `burn/1` stay claims only.
- A `decision` (`no_go(H, Text)`, `hold(H, Text)`) does not change.

```sh
orbit-kb add "hypothesis(h2, defect, 'NEW TEXT')" "supersedes(h2, h1)"
```

### Fixture expectations: `expected.pl`

The discovery-orbit session tests its module with fixtures that have an
`expected.pl` file. The harness that reads it is `harness/run.pl` in
`thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/`. It is a
draft, kept in git history (tag `thoughts-archive`). It is not part of the
installed tool, and
`kb/tests/test_orbit_kb.sh` does not read `expected.pl`. The harness
runs s(CASP) on the assembled program, so it needs a `scasp` binary that
`orbit-kb` itself no longer needs (D20).

Usage: `swipl harness/run.pl [FIXTURE_DIR [LIB_DIR [FORALL]]]`. The default
`FORALL` is `--forall=prev`. Set `only=NAME` to run one variant.

A fixture is a KB directory with an `expected.pl` file. The file has two kinds
of terms:

```prolog
% variant(Name, Edits): a copy of kb.pl with term edits.
variant(cf1_no_answer, [delete(answer(q1, floor_wins, human))]).

% expect(Variant, 'GOAL', Answers)
expect(base, 'current(C)', ['C = c1', 'C = c2b']).
expect(cf1_no_answer, 'to_ask(Q)', none).   % D5: q1's claim is superseded
expect(cf1_no_answer, 'discovery_ready', none).
```

| Edit | Effect |
|---|---|
| `delete(Term)` | Removes the `kb.pl` term that equals `Term`. |
| `replace(Old, New)` | Puts `New` in place of the `kb.pl` term that equals `Old`. |
| `add(Term)` | Appends `Term` to the end of `kb.pl`. |

| `Answers` | Meaning |
|---|---|
| `true` | The goal has an answer. |
| `none` | The goal has no answer. |
| A list of atoms | The binding lines, compared as a set. Variables whose names start with `_` are not shown. |

Rules of the harness:

- Edits match terms by term equality. A `delete` or `replace` must match
  exactly one term. If not, the variant is BROKEN, and all of its expectations
  fail.
- The `base` variant has no edits. You do not write it.
- An `expect/3` that names an unknown variant is a failure.
- The harness runs each expectation on s(CASP) and on SWI, and prints
  `ENGINE DISAGREEMENT` when they differ. (That message is only in the
  harness, not in `orbit-kb`.)
- An E code in a variant is a failure. Any code in the `base` variant is a
  failure.

## 13. Environment variables

| Variable | Effect | Default |
|---|---|---|
| `ORBIT_KB` | The KB directory, when `--dir` is not given. | None. `orbit-kb` searches upward from the current directory. |
| `ORBIT_KB_LIB` | The library directory that holds `core.pl` and `modules/`. | `<real dir of the orbit-kb script>/../share/orbit-kb` |
| `ORBIT_KB_NO_CACHE` | A value other than empty or `0` turns off the saved state. | Not set: cache on |
| `XDG_CACHE_HOME` | The base of the cache directory. It must be an absolute path. The saved state is in `$XDG_CACHE_HOME/orbit-kb/`. | `~/.cache` |
| `ORBIT_KB_TEST_JOBS` | The number of parallel workers of the test suite (section 14). | The number of CPUs, at most 4 |

The variables `ORBIT_KB_SCASP_FLAGS`, `ORBIT_KB_SCASP_TIMEOUT`,
`ORBIT_KB_SCASP_GROUND`, and `ORBIT_KB_GROUND_TIMEOUT` do not exist any more
(D20). `orbit-kb` ignores them. The 10 s limit of one query comes from
SWI-Prolog, so no `timeout` command is needed.

The lock on `kb.lock` needs `flock(1)` from util-linux. If `flock(1)` is not on
`PATH`, `orbit-kb` uses the lock that SWI-Prolog takes on the same file
(section 8).

The test variables `ORBIT_KB_BIN`, `ORBIT_KB_TEST_LIB`, `ORBIT_KB_TEST_TIMEOUT`,
and `ONLY` are in section 14.

### The cache

`orbit-kb` keeps one cache in `${XDG_CACHE_HOME:-~/.cache}/orbit-kb/`:

| Path | Contents |
|---|---|
| `state-*.qs` and `state-*.qs.ok` | The saved state of the script, and its sidecar with the size and the SHA-1. |

Section 11 describes it. The s(CASP) result cache (`scasp/`) went with s(CASP)
(D20). You can delete the directory at any time. `orbit-kb` builds again what
it needs. Every cache error makes `orbit-kb` fall back to a normal run. To
bypass the cache for one command, set `ORBIT_KB_NO_CACHE=1`.

## 14. Testing

To run the suite:

1. Go to the root of the sagittarius repository.
2. Run `bash kb/tests/test_orbit_kb.sh`. If you have a job queue for CPU-heavy commands,
   run it through the queue.
3. To run a subset, set `ONLY` to a regex of test IDs, for example
   `ONLY='^(K|I)[0-9]' bash kb/tests/test_orbit_kb.sh`.

The suite has 279 tests. All pass. The tests run in parallel. With one worker
(`ORBIT_KB_TEST_JOBS=1`) it runs them one at a time. The suite exits 0 when all tests pass, 1
when a test fails, and 2 when it cannot run. It also exits 2 if
`ORBIT_KB_TEST_JOBS` is not a positive integer.

| Variable | Effect | Default |
|---|---|---|
| `ORBIT_KB_BIN` | The CLI to test. The first argument also sets it. | The repository copy |
| `ORBIT_KB_TEST_LIB` | The library to test. | The repository library |
| `ORBIT_KB_TEST_TIMEOUT` | The time limit for one CLI call, in seconds. | `120` |
| `ORBIT_KB_TEST_JOBS` | The number of parallel workers. `1` runs the tests one at a time, in the shell of the suite. | The number of CPUs, at most 4 |
| `ONLY` | A regex. Only matching test IDs run. | All tests |

The output does not depend on the number of workers. The lines of the tests
come in the same order, and the summary line is the same.

The suite removes every `ORBIT_KB*` variable of the caller from its
environment, and then sets `ORBIT_KB_LIB` to the library under test. Thus the
suite works before installation. Each test has its own temp directory and its
own empty `XDG_CACHE_HOME`. So the saved state cannot carry a result from one
test to another, or from `~/.cache`.

The tests of the review fixes and of the one engine (D20) have these IDs:

- `D7a`–`D7d`: broken sources exit 2, and unsafe negation.
- `RC`: eight concurrent `run` commands on one KB. The run numbers are 1 to 8,
  the IDs are unique, and each run has one log.
- `E14`: lint E14.
- `X1`–`X9`: the engine. Negation as failure (`not under(_)` means no under at
  all), `-n 0`, E18 (rules that are not stratified), E17 forms in `rules.pl`,
  and no command calls a `scasp` (a fake `scasp` on `PATH` records each call,
  and there is none).
- `WN1`–`WN5`: `whynot`: `holds`, `absent` with the blocking literal,
  `nothing records X`, and `--long`.
- `E17`, `A13`: lint E17, and `add` refuses a `-fact`.
- `Q8`, `Q9`: `query --json` and `query --html` are usage errors.
- `DR1`, `DR2`: `doctor` does not look for `scasp`, and each self-test passes.
- `HP1`, `HP2`: `help` explains the engine, and `help query` has no `--json`.

D20 removed these tests with the features they tested: `H3b`, `H3d`, `X2g`,
`X10`, `GU`, the E11 fixture test, `E12`, `E13`, `E13s`, `A18`, `A19`, `BP14`,
`RH9`, and `DR4`.

### Fixtures

The fixtures are in `kb/tests/fixtures/<name>/`:

- `valid` and `valid_local`: KBs that must lint clean.
- One fixture for each error code that the tests cover, for example `e1_syntax`,
  `e14_unsafe_neg`, and `e17_scasp_syntax`.
- Variants of some codes, for example `e2_arity`.
- One fixture for each of W3, W4, W5, and W6.

A line that must get a diagnostic ends with the marker `% <-- E<n>`. The tests
read the expected line from the marker. Each test copies a fixture into a fresh
temporary directory and never changes the original. The tests read `kb.pl`
back with `swipl`, so no test depends on the spacing or the quotes that the CLI
writes.

### The independence rule

The only source of expected behavior is `kb/CONTRACT.md`. No
test reads the CLI source or the library source. Thus the implementation never
decides what a test expects. Where the contract is not clear, the test uses the
reading that makes a failure loud, and a comment above the test says so.

Three agents wrote the library, the CLI, and the tests in parallel, from the
same contract. The test author never read the CLI source.

## 15. Design decisions and history

In this section, "Ty" is the author of the project. The author's decisions are credited by name.

| Decision | Reason |
|---|---|
| One engine (D20) | SWI-Prolog gives the verdict and, from the same clauses, the explanation. Until 2026-11-02, s(CASP) explained the answers and a cross-check compared the two. It cost about 23% of the CLI, and in the audits it found no error in a KB, only tool bugs. |
| Exit 2 for typos and broken sources | A typo or a broken source must never look like "false". D7 added broken sources to this rule. D20 added E17 and E18. |
| `run` outside the lock (D7) | A long check must not stop other writers. The cost is that `run` numbers runs in the order that they finish. |
| Saved state under `XDG_CACHE_HOME` | A saved state makes a warm query start in 35–40 ms. A cache error is never fatal, and `ORBIT_KB_NO_CACHE=1` turns it off. The owner keeps it; a fix of its cache race (GitHub issue #4) must keep it. |

Changes in contract v2.1:

- **D1.** `test_result`, `passed/1`, `failed_after/2`, and `was_red/1` moved
  from `build` to the core, because a runnable reproduction is a check in both
  orbits.
- **D2.** E6 applies only to `kb.pl`. E7 means a clause in the wrong place.
- **D3.** `subject/3` stores a relative path for a file inside the KB, so KBs
  and fixtures are portable.
- **D4.** `report/1` and `calibration` are not reserved by discovery.
- **D5.** `to_ask/1` asks only the questions of current claims. Without this,
  the questions of a superseded claim stay open, and `done` never holds.
  `any_to_ask/0` moved to the core.
- **D6.** Stubs were made only for declared predicates with no clauses.
  Anonymous variables in a query got names before s(CASP) got them, because
  `--json` crashes on `_`. (Superseded by D20.)
- **D7 (review fixes, 2026-10-16).** An independent review found these
  faults. We fixed all of them:
  - **Broken sources.** An E1 error in any source, or an E2 error in
    `rules.pl`, makes `query`, `why`, `whynot`, `show`, and `report` exit 2.
    Before D7, they gave a quiet `false`.
  - **Unsafe negation.** The SWI translation moves each `not` literal after the
    positive literals. New lint error E14 finds a `not` variable that occurs in
    the head but in no positive body literal. (The cross-check asked s(CASP) for
    M+1 models; superseded by D20.)
  - **Locking.** The writing commands hold `flock` on `kb.lock`.
  - **`run` order.** `run` runs its command without the lock and records the
    result afterwards. `run` numbers runs in the order that they finish. SIGINT
    or SIGTERM records nothing.
  - `subject` rewrites `kb.pl` atomically.
  - E13 also checked strings (E13 is gone: D20).
  - Temp files come from `tmp_file_stream`.
- **D8 (grounded cross-check, 2026-10-16).** Superseded by D20. s(CASP) ran on
  a grounding of the program for the goal. The grounder, the cross-check, and
  the environment variables below are gone. Why the cost was large: the duals
  of rules that read `attest/6` had nested `forall` loops, and the cost grew
  about N³ in the number of attestations; `done` timed out at 20 attestations.
  - It had a switch (`ORBIT_KB_SCASP_GROUND=raw`), a fallback to the raw
    program with a NOTE, relevance trimming of the facts, a cap of 100 models
    in the cross-check, and a `doctor` with 12 checks.
- **D10 (a burn needs a proof, 2026-10-19).** Ty decided that a burn needs a
  proved verdict, always. The clarity comes from the work to write a correct
  proof, not from a statement in Lean.
  - `done` is false while a burn is open (`any_burn_open`).
  - `lean_result` lost its `proved` verdict. A new type `lean_proof` holds a
    proof. Only `orbit-kb prove` writes it.
  - `prove` builds the project, reads the axioms, and runs `leanchecker`. It
    accepts only `propext`, `Classical.choice`, and `Quot.sound`. TLA+ and
    TLC do not close a burn.
  - A proof covers the project files that it imports. A change to one of them
    reopens the burn.
  - Only a human can waive a proof, with a due time. After the due time, the
    burn is open again. `report` shows a waived claim as `NOT PROVED`.
  - A check of the code against the Lean model is optional
    (`conformance/1`, `conforms/1`).
  - `declare` refused `proved`, `chs`, `assume`, and `abduced`. A rule named
    `proved/1` broke the s(CASP) compile. (Superseded by D20: the names are free.)

The speed work (also on 2026-10-16) did not change any answer:

- A saved state of the script, in the cache directory. Startup takes about
  35–40 ms instead of 80 ms.
- Lazy loading of libraries.
- Overlap of the s(CASP) runs with the SWI engine, and parallel parts in
  `whynot` and `doctor`. (Gone with s(CASP): D20.)
- The s(CASP) result cache. (Gone: D20.)
- AVL sets in the quadratic loops of lint, and one query for each relation in
  `show` and `report`.
- A parallel test suite. Each test has its own cache directory.

- **D10 follow-up (review fixes, 2026-10-20).** An independent review of D10 and
  the Lean phases found these defects. Record:
  `thoughts/orbit-kb-d10-record.md`, section "D10 follow-up fixes" (in git
  history, tag `thoughts-archive`).
  - **Restated claims (F11, Ty's decision).** A claim that replaces a burning
    claim inherits the burn, also through a chain. The new rule
    `burn(C) :- supersedes_closure(C, O), burn_reason(O).` reads a derived
    fact, so the program does not recurse through `supersedes/2`.
  - **Supersede cycles (L-F2, L-F8).** `orbit-kb` computes
    `supersedes_closure/2` and `supersede_cycle/1` when it reads the KB. A cycle
    is lint E15, `done` is false while it exists (`any_supersede_cycle`), and
    `add` refuses a fact that makes one. The engine finishes on every KB.
  - **`rules.pl` (F8).** A clause for `done`, a burn rule, or a computed fact
    is E16, not W6. Such clauses, E7 fact clauses in `rules.pl`, and protected
    facts in `kb.pl` do not reach the engine.
  - **Times (F9, F10).** The `time` type checks the values. A waiver with an
    invalid due time counts as lapsed.
  - **Proof logs (F6, F7).** The digest also covers the claim, theorem,
    module, and statement lines, and the absent Lake configuration files. A
    copied or edited log does not count, and E9 reports it. A configuration
    file that appears after the proof reopens the burn.
  - **Tests (F12).** SC1 to SC11 and PV10 to PV12 kill the mutants of the
    review (MD, MX, MC, MF, MN, MS, MT) and of the fixes.
  - **Docs (F13).** The limits of `prove` under the trust threat model are
    listed under "Known limits" below.
  - **A hang at exit (found by the conformance runs).** About 1 in 2800 calls
    printed the answer and then never ended: a halt hook of a foreign library
    waited on a mutex (`eu-stack`: `cleanup` under `PL_halt`). It is probably
    also the cause of finding F6 of the Lean phases (the same symptom). Now the CLI flushes its output,
    removes its temp files, and then replaces itself with `sh -c 'exit N'`, so
    no halt hook runs. If that fails, it calls `halt/1` as before.
- **D11 (add a module, 2026-10-19).** `orbit-kb uses MODULE …` adds modules to an
  existing KB. Before D11, a KB started for discovery could not get the build
  module without an edit by hand. A review found four defects in the first
  version, now fixed: text between the term and its full stop gave a broken
  `kb.pl`, the tests missed most mutants, the write was not atomic, and the
  prompt lost the step to run lint. Tests U1 to U9.

Known gaps:

- `run` numbers follow the order in which the commands end, not the order in
  which they start.
- The lock needs `flock(1)`. Without it, `orbit-kb` uses the lock that
  SWI-Prolog takes on `kb.lock`, for example on macOS.
- `orbit-kb run --type ... --expect` is deferred. It does not exist.
- `prove` cannot check that the Lean statement says what the claim says. The
  agent and the human must read the statement.
- `prove` trusts the Lean toolchain of the project, its `lake`, and its
  `leanchecker`. `leanchecker` replays the declarations in the same kernel.
  It is not an independent checker.
- A proof covers the project source files and the Lake configuration files. It
  does not cover the source of a dependency in `.lake/packages`. For a `git`
  dependency, `lake-manifest.json` names a revision, so a change of version
  changes the digest. For a `"type": "path"` dependency (for example, a project that shares its libraries with other projects),
  the manifest has no revision, so a change in the dependency does not reopen
  the burn.
- `proof_changed/1` and `waiver_lapsed/1` read the disk and the clock. So the
  same KB can give a different answer after a file edit or after a due time.
- **D13 (2026-10-21).** A `waiver` can target a check or a question, not only
  a claim. Ty decided that a deadline "bypass" and a burn waiver are not
  different enough to need two records. A waived check covers its claim for
  `done` (`check_waived`, read by `under`), but the claim is not fulfilled,
  and a burn still needs a proof or a waiver of the claim. A waived question
  is not `to_ask` (`question_waived`). Every waiver has a due time, and
  `report` lists every waiver. The Lean burn model covers claim waivers only;
  its conformance KBs have no check or question waiver.
- **D14 (2026-10-21).** GO / NO-GO / HOLD is a weighted vote of the human
  (0.4), the agent (0.3), and the formal artifacts (0.3). Ty decided it. A
  win needs the human's vote. Reweighted the same day to 0.49, 0.24, and 0.24,
  so the weights alone carry that rule; the outcomes do not change. The `vote` type, `artifact_vote`, `gate`, and
  `gate_split` are in the discovery module (section 12). WD6 no longer calls
  a failed reproduction a NO-GO candidate: it says to tell the human what you
  tried.
- **D15 (2026-10-27).** Ty decided: no new command and no new attestation type
  for a reworded hypothesis. `supersedes` takes two hypotheses too (section
  12, "Reword a hypothesis"). Its declared type is `ref`, because `core.pl`
  cannot name the module fact `hypothesis/3`; the CLI checks the kinds (E4).
  W5 now says to add a new check of the current claim, because a check id
  cannot be reused, and W5 stops once that claim has a check.
- **D16 (2026-10-28).** `report --html FILE` writes the delivery report as a
  page for review, because the close-out text was hard to read. Ty asked for
  "a few UX offerings": open items first, evidence under each claim, and
  review marks that become text to paste back. The text of `report` does not
  change (golden files in the tests). `--open` opens the page only when given.
- **D20 (SWI-Prolog is the only engine, 2026-11-02).** Ty decided ("option 2")
  to drop s(CASP) and to keep SWI-Prolog as the only engine. Section 11 gives
  the reasons from the two audits. What changed:
  - **Gone.** The `scasp` binary and pack; the grounder (D8); the cross-check,
    `ENGINE DISAGREEMENT`, `CROSS-CHECK SKIPPED`, `(unchecked)`, and the
    `NOTE: s(CASP) ran the raw program` line; the s(CASP) result cache; the
    variables `ORBIT_KB_SCASP_FLAGS`, `ORBIT_KB_SCASP_TIMEOUT`, and
    `ORBIT_KB_SCASP_GROUND`; the hazards H1 to H4; lint E12 and E13;
    `query --json` and `query --html`; the `contradicts` verdict of `whynot`;
    classical negation `-p`; the reserved names `proved`, `chs`, `assume`, and
    `abduced`; the cross-check of the report page (`data-crosscheck` and the
    `disagreement` open item). `report --html` now exits 0 when it writes the
    page.
  - **New.** `why` and `whynot` explain from the SWI engine (section 8). Lint E17
    (forms that `orbit-kb` does not read) and E18 (rules that are not
    stratified). `add` refuses E17 forms. `query`, `why`, `whynot`, `show`, and
    `report` exit 2 while an E17 or E18 exists.
  - **Changed.** E11 means only "a clause does not load in the SWI engine". The
    E14 text says "A call with X unbound then gives a wrong answer". `doctor`
    runs SWI self-tests.
  - **Unchanged.** The saved state (the owner keeps it; GitHub issue #4),
    the schema and types, the digests, the run logs, `prove`, the text of
    `report`, `rules.pl`, `done`, and all rule text in the core and the modules.
  - **History of the hazards.** On 2026-10-15, four faults of s(CASP) showed
    up: a variable only under `not` meant "some value" (H1); the default
    `--forall` algorithm gave a wrong answer (H2,
    <https://github.com/SWI-Prolog/sCASP/issues/10>, open since 2024-10);
    arithmetic under `not` gave wrong answers (H3); and a final `_<digits>` was
    dropped from atoms (H4). SWI-Prolog is correct on all four. The tests X1 to
    X9 and the `doctor` self-tests keep the cases.

Known limits of `prove` (D10 follow-up, 2026-10-20). `prove` checks the proof of
an honest agent that can make mistakes; it does not resist an agent that cheats
on purpose. Ty decided this threat model on 2026-10-20: the agents, the human,
and the code trust each other. These holes need adversarial Lean on purpose, so
they are documented, not fixed:

- F1. leanchecker and the digest cover only the files under the project root
  and outside `ROOT/.lake/`. A module behind a symlink to outside the root, in
  a path dependency, or under a `srcDir` inside `.lake/` is not replayed and
  not hashed. (`lake env leanchecker --fresh MODULE` replays everything, but it
  takes about 34 s.)
- F2. The probe runs project code (`initialize` blocks, `@[delab]`
  extensions). Such code can print forged `ORBIT-PROVE` lines.
- F3. `lake env` puts `ROOT/.lake/build/bin` first on `PATH`. A planted
  `leanchecker` or `lean` there passes every check. A proof file can plant it
  with `#eval` at build time.
- F4. Axioms are allowed by name only. A `prelude` file can declare an axiom
  named `propext` with any statement.
- F5. The printed statement can be forged with notation (`app_unexpander`).
  Only the `uses` lines of the log show the real constants. Read them.
- L-F5. `query` answers before lint runs. A hand-edited `kb.pl` fact that lint
  rejects can still change `done`, for example an attestation with a malformed
  predicate. Only a hand edit makes such facts: `add` and `attest` refuse them.
  The cases that close a burn are handled: a protected fact in `kb.pl` and an
  E7 or E16 clause in `rules.pl` do not reach the engine, a proof whose id is
  not an atom counts as changed, and a waiver with an invalid due time counts
  as lapsed.
- A file that a proof reads with `include_str` (or another elaborator that
  reads the disk) is not in the digest. A change to it does not reopen the
  burn. Only the Lean sources and the Lake configuration files are hashed.
- `uses` rewrites `kb.pl` as UTF-8. An invalid UTF-8 byte anywhere in the
  file becomes U+FFFD, with a warning from SWI-Prolog.

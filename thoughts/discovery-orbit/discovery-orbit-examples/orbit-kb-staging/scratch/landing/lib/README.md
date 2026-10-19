# orbit-kb

`orbit-kb` is a command-line tool for agents. It writes, lints, and queries
s(CASP) knowledge bases (KBs).

## 1. What orbit-kb is, and when to use it

`orbit-kb` serves the "orbital shifting" process, in which a human and an LLM
work together. During this process, agents record facts in a KB:

- The request of the human, word for word.
- Claims about the request.
- Dormant questions, each with a default answer.
- Evidence (attestations), in the shape of in-toto statements.

The KB is an s(CASP) program. SWI-Prolog has no schema checker and no type
checker. Thus a typo in a fact or a rule does not cause an error. It only
changes an answer. `orbit-kb` adds a schema, a type system, and a lint, and it
makes each failure loud.

The core is domain-neutral. You can use it for all human–LLM work that needs
clarity, accuracy, and honesty, not only for software. Optional modules add
vocabulary for one orbit:

| Module | Orbit | Status |
|---|---|---|
| `build` | Build: specification, implementation, verification | Written. See section 7. |
| `discovery` | Discovery | A placeholder that holds only a comment. A separate discovery-orbit session owns it. |

When an agent must record what a human asked for and then show with evidence
that the work is done, use `orbit-kb`.

We built `orbit-kb` on 2026-10-15, with SWI-Prolog 9.2.9 and s(CASP) 1.1.4.

## 2. Install and check

The tool is part of this dotfiles repository:

| Item | Repository path | Installed path |
|---|---|---|
| CLI | `shared/link/.local/bin/orbit-kb` | `~/.local/bin/orbit-kb` |
| Library | `shared/link/.local/share/orbit-kb/` | `~/.local/share/orbit-kb/` |
| Tests | `scripts/orbit-kb/` | (not installed) |
| Contract | `thoughts/orbit-kb-contract.md` | (not installed) |

To install on Fedora:

1. Install SWI-Prolog 9 or later:
   `sudo dnf install swi-prolog-nox`
2. Install the s(CASP) pack:
   `swipl -g "pack_install(scasp, [interactive(false)])" -t halt`
3. On Fedora, the last step of the pack install fails. It tries to make a
   link in `/usr/lib64/swipl/bin/bin/`. The build is still complete. Make the
   link yourself:
   `ln -s ~/.local/share/swi-prolog/pack/scasp/scasp ~/.local/bin/scasp`
4. If `~/.local/bin/orbit-kb` does not exist, run `create-links` from the
   dotfiles repository.
5. Run `orbit-kb doctor`.

The result on this machine:

```text
$ orbit-kb doctor
ok    swipl: /usr/bin/swipl (SWI-Prolog 9.2.9; running as /usr/lib64/swipl/bin/x86_64-linux/swipl).
ok    scasp: /home/ty/.local/bin/scasp (s(CASP): version 1.1.4 on SWI-Prolog 9.2.9).
ok    library: /home/ty/.dotfiles/shared/link/.local/share/orbit-kb (modules: build, discovery).
info  s(CASP) command: scasp --unknown=error --forall=prev (timeout 20 s).
ok    H1 helper form: done must be false on both engines.
ok    H2 program: finding_lead(F) must have no answer on both engines.
ok    H3 program: passed(K) must be exactly k2, k3, k4 on both engines.
ok    H4 renamed atoms: r must be false on both engines.
ok    H4 raw atoms (E13 bypassed): the cross-check must report ENGINE DISAGREEMENT.
ok    E13 flags the H4 atoms (order_4417, order_5120).
ok    E12 flags the bad H1 form: done :- not under(_).
Result: all checks passed.
```

If a line does not start with `ok` or `info`, do the fix step that `doctor`
prints. `doctor` exits 2 if a tool is missing or a self-test fails.

The library path in that output is the repository path, not
`~/.local/share/orbit-kb`. The CLI follows its own symlink to find the library
(see `ORBIT_KB_LIB` in section 13). Thus a change to the library in the main
checkout is live at once.

## 3. Quick start: "Make the button purple"

This walk-through is a real session. Every command and every output line is a
copy from a run on 2026-10-15. A file `button.css` holds `.buy { color: blue; }`,
and a file `ticket.md` holds the ticket.

1. Make the KB. Load the `build` module:

   ```text
   $ orbit-kb init purple --request 'Make the button purple.' --uses build
   /tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad/docs-walk/purple/kb.pl
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
   sha256:72678cf6a0fd46537d830f09669e4d6dfbfb57ff787d1894e27a169c64398a6a
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
   run 1 k1 fail (exit 1) log=/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad/docs-walk/purple/runs/1-k1.log
   Last 0 line(s) of output:
   $ orbit-kb query done
   false
   ```

   Both commands exit 1.

10. Change `button.css` to `.buy { color: rebeccapurple; }`. Then run the
    check again:

    ```text
    $ orbit-kb run k1 -- grep -q purple button.css
    run 2 k1 pass (exit 0) log=/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad/docs-walk/purple/runs/2-k1.log
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
    attest(a3, divergence, c1, claim(c1), human, '2026-10-15T23:30:03Z').
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
    Delivered:
    - (Write what you delivered here.)
    Claims:
    - c1 (introduce): The Buy button is purple. Status: fulfilled. Checks: k1 (passed).
    Guesses:
    - q2: Does the hover color change too? The default is yes. No human answered it.
    Disclosures:
    - None.
    Not checked:
    - None. Every current claim has a check.
    Open:
    - Ask question q2 now.
    To land:
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
subject(s1, 'ticket.md', 'sha256:72678cf6a0fd46537d830f09669e4d6dfbfb57ff787d1894e27a169c64398a6a').
ticket(s1).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-15T23:29:44Z').
attest(a2, test_result, k1, result(k1, 2, pass), script, '2026-10-15T23:29:44Z').
attest(a3, divergence, c1, claim(c1), human, '2026-10-15T23:30:03Z').
note(a3, 'The human wants a darker purple.').
answer(q1, indigo, human).
```

## 4. KB layout on disk

A KB is a directory. You choose its location. There is no default location.

| Path | Who writes it | Contents |
|---|---|---|
| `kb.pl` | `init`, `add`, `declare`, `declare-attest`, `subject`, `attest`, `run` | The first term is `uses([Module, …]).` The list can be empty. Then come facts, classical negations (`-fact`), and local `decl/4` and `attest_type/4` lines. |
| `rules.pl` | You (optional) | Local rules. |
| `runs/<N>-<CheckId>.log` | `run` only | The combined output of one run of a check. |

`kb.pl` is append-only by convention. The only exception is
`orbit-kb subject`. When the ID exists, it rewrites its own `subject/3` line.

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
5. Stubs `p(_, …, _) :- false.` for each declared predicate with no clauses.
6. `#pred` lines, made from the templates of the declarations.

## 5. The type system

### `decl/4`

```prolog
decl(Kind, Head, Doc, Template).
%  Kind:     fact | rule
%  Head:     Name(Type1, …, TypeN), or Name alone for no arguments
%  Doc:      atom; one plain sentence
%  Template: atom with positional @(1), @(2)… for #pred; '' if none
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
| `ref` | The ID of a fact of any kind. |
| `oneof(List)` | One atom of `List`. |
| `alt(Shapes)` | A value that matches one shape. An atom entry matches itself. A compound entry matches by name and arity, and each of its arguments is a type. |
| `text`, `atom` | An atom. |
| `int` | An integer. |
| `time` | An atom `YYYY-MM-DDTHH:MM:SSZ`. |
| `digest` | An atom `sha256:` and 64 lowercase hex characters. |
| `by` | `human`, `agent`, or `script`. |
| `term` | A ground term of any shape (the escape hatch). |
| `attest_predicate` | Only for argument 4 of `attest/6`. `orbit-kb` checks it against the shape of the `attest_type` of argument 2. |

Every fact must be ground.

### Fact kind and rule kind

| Kind | Where its clauses go | Error if not |
|---|---|---|
| `fact` | Ground facts, or ground `-facts`, in `kb.pl` only. | E7 if a clause is in the core, a module, or `rules.pl`. E6 if a fact in `kb.pl` is not ground. |
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
| `supersedes(ref(claim), ref(claim))` | The first claim replaces the second claim. |
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
| `disproof` | `verdict(ref(claim), oneof([refuted, inconclusive, abstained]))` | `[agent]` |
| `approval` | `digest(digest)` | `[human]` |
| `test_result` | `result(ref(check), int, oneof([pass, fail]))` | `[script]` |

### Core rules

| Query | True when |
|---|---|
| `superseded(C)` | A `supersedes(_, C)` fact exists. |
| `current(C)` | `C` is a claim and is not superseded. |
| `answered(Q)` | A human answered `Q`. |
| `defeated(Q)` | A human answer to `Q` differs from its default. |
| `refuted(C)` | An attestation gives `verdict(C, refuted)`. |
| `contested(C)` | One or more `divergence` attestations name `claim(C)`. |
| `contested_twice(C)` | Two or more different `divergence` attestations name `claim(C)`. |
| `to_ask(Q)` | No human answered `Q`, its claim is current, and one of these is true: a question that `Q` depends on is defeated, or the claim is contested. |
| `any_to_ask` | `to_ask(Q)` is true for one or more questions. |
| `stale(A)` | Human approval `A` names a digest that differs from the recorded digest of its subject. |
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
| `burn_requested(ref(claim))` | A human asked for a formal statement of the claim, for example in Lean. |

### Build attestation types

| Type | Shape | Writers |
|---|---|---|
| `lean_result` | `verdict(ref(claim), alt([stated, refuted, tested(int), proved]))` | `[agent, script]` |

### Build rules

| Query | True when |
|---|---|
| `fulfilled(C)` | A check of `C` passed, and nothing refutes `C`. If the label of `C` is not `preserve`, the check must also have failed before it passed (`was_red`). |
| `under(C)` | `C` is current and not fulfilled. |
| `served(X)` | Change `X` serves one or more claims. |
| `over(X)` | Change `X` serves no claim. |
| `any_under` | `under(C)` is true for one or more claims. |
| `any_over` | `over(X)` is true for one or more changes. |
| `done` | `any_under`, `any_over`, and `any_to_ask` are all false. |
| `burn(C)` | `C` needs a formal statement: it is contested twice, it is universal, or a human asked for it. |

## 8. Command reference

Usage: `orbit-kb [--dir DIR] COMMAND [ARGS]`. Run `orbit-kb help COMMAND` for
the text that the CLI prints.

### `init DIR (--request TEXT | --request-file F) [--uses m1,m2] [--id ID]`

Makes `DIR/kb.pl` with `uses([…]).` and `request(ID, 'TEXT').` The default ID
is `r1`. It prints the path of the new `kb.pl`.
Exit: 0 on success. 1 if `kb.pl` exists or the input is rejected.

### `add 'FACT' …`

Appends facts to `kb.pl`. The final full stop is optional. Facts in one command
can refer to each other. If one fact is wrong, nothing is written. Write a
classical negation as `'-world(x)'`. `add` refuses types whose writers are
`[script]`. Use `run` for those.
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
Exit: 0 on success. 1 if the file is missing.

### `attest TYPE SUBJECT 'PREDICATE' [--by human|agent] [--id ID]`

Appends `attest(ID, TYPE, SUBJECT, PREDICATE, BY, TIME)`. `--by` defaults to
`agent`. The ID defaults to the next free `aN`. The time is now, in UTC.
`orbit-kb` checks the shape, the writer, and the references. The predicate
`digest(current)` becomes the recorded digest of SUBJECT. The file must still
have that digest. If the file changed, run `orbit-kb subject` first.
Exit: 0 on success. 1 on a rejection.

### `run CHECK -- CMD [ARGS]`

Runs CMD for a check. The combined output goes to `runs/N-CHECK.log`. N is the
highest run number in a `test_result`, plus 1. Then `run` appends a
`test_result` attestation: `pass` if CMD exits 0, else `fail`. It prints
`run N CHECK pass|fail (exit E) log=PATH`. On a fail, it also prints the last
40 lines of output.
Exit: 0 on pass. 1 on fail. 2 if the check or the command does not exist.

### `lint [--strict]`

Examines `kb.pl`, `rules.pl`, the core, and the modules. It prints one line per
problem, then the module `lint_issue` results, then a summary line. Section 10
lists the codes.
Exit: 0 if clean or only warnings. 1 on errors, or on warnings with `--strict`.

### `query 'GOAL' [-n N] [--why] [--long] [--json] [--html FILE]`

Answers GOAL on both engines and compares them. Each predicate in GOAL must be
declared or built in. `-n N` shows N answers. The default is 1, and 0 shows all
answers. The output is one line per answer, `true` or `X = v, Y = w`. If there
is no answer, the output is `false`.

| Option | Effect |
|---|---|
| `--why` | Adds the s(CASP) explanation, in short form. |
| `--long` | Gives the full explanation. |
| `--json` | Prints the s(CASP) JSON unchanged. |
| `--html FILE` | Writes the explanation as HTML. |

Exit: 0 on an answer. 1 on no answer. 2 on a bad goal, an undeclared
predicate, `SWI ERROR`, or `ENGINE DISAGREEMENT`.

### `why 'GOAL' [-n N] [--long]`

The same as `query --why`. The exit codes are the same as for `query`.

### `whynot 'GOAL' [--long]`

The first line is the verdict of the SWI engine: `holds`, `contradicts`, or
`absent` (section 9). Then it prints the s(CASP) explanation.
Exit: 0, or 2 on `ENGINE DISAGREEMENT`.

### `show [claims|questions|open|disclosures|extensions|all]`

Lists parts of the KB as plain text. The default is `all`. `open` lists
`to_ask`, `stale`, and `contested`. When the `build` module is in use, `open`
also lists `under` and `over`.
Exit: 0. 2 on an unknown topic.

### `report`

Prints a skeleton of a delivery report with these sections: `Delivered:`,
`Claims:`, `Guesses:`, `Disclosures:`, `Not checked:`, `Open:`, `To land:`.
You write `Delivered` and `To land` yourself. Step 16 of section 3 shows an
example.
Exit: 0.

### `doctor`

Examines `swipl`, `scasp`, and the library, and prints a fix step for each
missing item. Then it runs the known-answer self-tests for H1–H4, E12, and E13
on both engines (section 11).
Exit: 0 if all checks pass. 2 if an item is missing or a self-test fails.

### `help [COMMAND]`

Shows the general help, or the help for one command. The general help gives
the hazards H1–H4 in short form.
Exit: 0.

## 9. Exit codes, and how to read answers

| Code | Meaning |
|---|---|
| 0 | Success. The query is true. Lint is clean. |
| 1 | The query has no answer. Lint found errors. `orbit-kb` rejected the input. A `run` failed. |
| 2 | Usage error. The KB, the library, or a tool is missing. A goal is bad, or names an undeclared predicate. `SWI ERROR`. `ENGINE DISAGREEMENT`. Internal error. |

A typo never exits 1. Exit 1 always means a real "no". If you get exit 2, do
not read it as "false".

### `ENGINE DISAGREEMENT`

The two engines gave different answers. `orbit-kb` prints both results and a
hint, and exits 2. This example forces the bad `--forall` algorithm on a check
that passed in run 1 and failed in run 2 (hazard H3):

```text
$ ORBIT_KB_SCASP_FLAGS=--forall=all orbit-kb query 'passed(K)' -n 0
ENGINE DISAGREEMENT
Goal: passed(K)
s(CASP) finds a model. The SWI engine finds no answer.
SWI engine (verdict): 0 answer(s).
s(CASP) engine (scasp --unknown=error --forall=all -n 1): 1 model(s).
  K = k1
Hint: see H1/H2 in the orbit-kb help (orbit-kb help). Also see H3 and H4 there.
Do not trust either answer until you find the cause.
```

Do not use either answer. Find the cause in section 11.

### `CROSS-CHECK SKIPPED` and `(unchecked)`

If one engine cannot evaluate a goal, `orbit-kb` prints
`CROSS-CHECK SKIPPED: <reason>` on stderr. It answers from the other engine and
adds `(unchecked)` to each answer line. Two causes are known:

- The goal has a constraint such as `#>`, which the SWI engine cannot evaluate.
- s(CASP) timed out. Then the answer comes from the SWI engine.

```text
$ orbit-kb query 'X #> 3'
CROSS-CHECK SKIPPED: the goal uses the constraint #>, which the SWI engine cannot evaluate
X = _ (unchecked)
```

An `(unchecked)` answer has no second opinion.

### `whynot`: `holds`, `contradicts`, `absent`

| First line | Meaning |
|---|---|
| `holds` | GOAL has an answer. |
| `contradicts` | `-GOAL` has an answer. `orbit-kb` examines this only when a `-` clause exists. |
| `absent` | Neither has an answer. The explanation that follows is for `not GOAL`. |

`absent` means that the KB holds no evidence. `contradicts` means that the KB
holds evidence against GOAL. For example, after
`orbit-kb add "-world(raining)"`, the first line of
`orbit-kb whynot 'world(raining)'` is `contradicts`.

## 10. Lint codes

Each diagnostic has the form `E<n> file:line: message` or `W<n> file:line: message`.

| Code | Error |
|---|---|
| E1 | Syntax error, with file and line. |
| E2 | Undeclared predicate or wrong arity, in `kb.pl` facts or in the heads and bodies of `rules.pl`, `core.pl`, and the modules. If a declaration has the same name but a different arity, the message names it. |
| E3 | Type error. This includes a label outside `oneof`. |
| E4 | Dangling `ref`. |
| E5 | Duplicate ID. |
| E6 | Non-ground fact in `kb.pl`. |
| E7 | A clause in the wrong place: a `rule` predicate as a fact in `kb.pl`, or a `fact` predicate with clauses outside `kb.pl`. |
| E8 | The writer is not permitted for the attestation type. This includes a `[script]` type whose writer is not `script`. |
| E9 | A `test_result` with no matching run log. The log header must match N, the check, and the result. |
| E10 | `uses/1` is missing, is not first, or names an unknown module. |
| E11 | The assembled program does not compile in s(CASP), or does not load in the SWI engine. |
| E12 | A `not` literal holds a variable that occurs nowhere else in the clause, `_` included (hazard H1). The message gives the helper-predicate fix. |
| E13 | An atom ends in `_` and digits (hazard H4). |

| Code | Warning |
|---|---|
| W1 | The subject digest differs from the file on disk, or the file is missing. Refresh it with `orbit-kb subject`. |
| W2 | A local declaration, listed for review. |
| W3 | A claim with no `cites`. |
| W4 | A local fact predicate that no rule reads. |
| W5 | A superseded claim that a `check` still references. |
| W6 | A local rule that adds clauses to a core or module predicate (an extension). |

Built-ins that E2 permits: `=`, `\=`, `<`, `>`, `=<`, `>=`, `is`, `#=`, `#<>`,
`#<`, `#>`, `#=<`, `#>=`, `true`, `false`, `forall/2`. Lint unwraps `not G`
and `-G`.

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

## 11. The two engines, and why

Each query runs on two engines:

| Engine | Role | How |
|---|---|---|
| SWI-Prolog | The verdict: the answers that `orbit-kb` prints. | Loads the program into a fresh module. `not G` becomes `\+ G`. `-p(…)` becomes the predicate `'-p'(…)`. `#` directives are removed. Each declared predicate is dynamic. Limits: 10 s and 1000 answers. |
| s(CASP) | The explanation: `--why`, `--json`, `--html`. | `scasp --unknown=error --forall=prev` on the program plus stubs. |

Then `orbit-kb` compares them. Existence must agree: SWI has an answer if and
only if s(CASP) has a model. When the bindings are ground, the binding sets must
also agree, at each `-n`. The comparison covers the answers that both engines
returned up to `-n`.

The reason for two engines: s(CASP) gives good explanations, but it gave wrong
answers in the tests that follow. SWI negation as failure is correct for the
stratified programs that `orbit-kb` targets. Each engine is a check on the
other.

The upstream bug behind H2 and H3 is
<https://github.com/SWI-Prolog/sCASP/issues/10>. It was opened in 2024-10 and
is still open. No fix exists in 1.1.4 or in master.

### H1: a variable only under `not` is existential

- **Symptom.** A negation means "some value", not "every value". Thus a rule
  is true when it must be false. This occurs with every `--forall` mode.
- **Example.** `done :- not under(_).` is true even when `under(c1)` is a fact.
- **Fix.** Use a helper predicate:

  ```prolog
  any_under :- under(_).
  done :- not any_under.
  ```

- **Guard.** Lint error E12 finds each `not` literal with a variable that occurs
  nowhere else in the clause. `doctor` tests the bad form and the helper form.

### H2: the default `--forall` algorithm gives a wrong answer

- **Symptom.** The default s(CASP) algorithm finds an answer that does not
  exist.
- **Example.** This program must have no models:

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

  The default mode gives `F = f1`, which is wrong. `--forall=prev`,
  `--forall=sasp`, and SWI give no answer, which is correct.
- **Guard.** `orbit-kb` uses `--forall=prev`. The cross-check finds the
  problem if it occurs. `doctor` runs this program on both engines.

### H3: arithmetic under negation

- **Symptom.** The core rule `passed/1` has `R2 > R` under `not`. The default
  algorithm gets it wrong in both directions.
- **Example.** Four checks with these runs:

  | Check | Runs |
  |---|---|
  | k1 | pass(1), fail(2) |
  | k2 | fail(3), pass(4) |
  | k3 | pass(5) |
  | k4 | pass(6), fail(7), pass(8) |

  The correct answer to `passed(K)` is k2, k3, and k4.

  | Engine | Answer | Verdict |
  |---|---|---|
  | default `all` | k1, k2, k3 | wrong both ways |
  | `prev` | k2, k3, k4 | correct |
  | `sasp` | k2, k3, k4 | correct |
  | SWI | k2, k3, k4 | correct |

- **Guard.** `orbit-kb` uses `--forall=prev`, and the cross-check finds a
  mismatch. Section 9 shows the real output with `--forall=all`. `doctor`
  requires exactly k2, k3, and k4.

### H4: atoms that end in `_<digits>` merge

- **Symptom.** s(CASP) removes a final `_<digits>` from atoms, quoted atoms
  too. Then different atoms unify.
- **Example.** `p(order_4417). r :- p(order_5120).` makes `r` true in
  s(CASP), but false in SWI. With `p(order_4417). p(order_5120).`, the query
  `p(X)` prints `X = order` two times.
- **Guard.** Lint error E13 finds such atoms in `kb.pl`, `rules.pl`, the core,
  and the modules. `add`, `declare`, `attest`, and `init --id` reject them:

  ```text
  $ orbit-kb add "world(order_4417)"
  Rejected. Nothing was written.
  E13 in argument 1 (world(order_4417)): The atom order_4417 ends in _ and digits. s(CASP) drops that ending, so different atoms can merge (hazard H4). Fix: rename it, for example order4417. Here you can use order4417.
  ```

  If such an atom gets past E13, the cross-check reports
  `ENGINE DISAGREEMENT`. `doctor` tests the renamed atoms and the raw atoms.

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
world/1 is already declared in the core (/home/ty/.dotfiles/shared/link/.local/share/orbit-kb/core.pl:77). Choose another name, or use the declaration that exists.
```

### Writing a new module

1. Make the file `modules/<name>.pl` in the library directory
   (`shared/link/.local/share/orbit-kb/modules/` in this repository).
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
  `decl/4`. Do not write `#pred` lines. `orbit-kb` writes them.
- **Text.** Write all text as single-quoted atoms. Do not use double-quoted
  strings.
- **E12.** No `not` literal can hold a variable that occurs nowhere else in the
  clause, `_` included. Put the variable in a helper predicate, declare the
  helper, and negate the helper. By convention, the name of the helper starts
  with `any_`, for example `any_under :- under(_).`
- **E13.** No atom can end in `_` and digits. Write `order4417`, not
  `order_4417`.
- **No `:- false` stubs.** Do not write `p(_, _) :- false.` `orbit-kb`
  generates a stub for each declared predicate that has no clauses. A stub for
  a fact predicate in a module gives E7.
- **Domain.** Keep software terms out of the core. Put them in a module.
- **Lint hook.** To add module-specific lint results, add clauses to
  `lint_issue/3` (section 10).

Reserved names:

- `declare` refuses these names: `decl`, `attest_type`, `uses`, `not`, `true`,
  `false`, `forall`, `call`, `is`, and the operators `=`, `\=`, `<`, `>`, `=<`,
  `>=`, `,`, `;`, `->`, `:-`, `#`, `\+`, `-`, `#=`, `#<>`, `#<`, `#>`, `#=<`,
  `#>=`.
- The `discovery` module reserves these names. They must not appear in the
  core or in the `build` module:
  - Facts: `hypothesis/3`, `budget/2`, `lap_done/1`, `model/2`,
    `derived_from/2`, `encodes/2`, `finding/3`, `reason/2`, `raised_by/2`.
  - Rules: `model_sane/1`, `model_calibrated/1`, `model_trusted/1`,
    `has_falsifier/1`, `no_falsifier/1`, `needs_question/1`,
    `has_question/1`, `unasked_finding/1`, `question_waits/1`,
    `about_system/1`, `finding_confirmed/1`, `finding_lead/1`,
    `rule_has_reason/1`, `weak_rule/1`, `touched_system/0`, `budget_spent/0`,
    `discovery_ready/0`, and helpers named `some_*`.
  - Attestation types: `reproduction`, `model_result`, `calibration`,
    `decision`.

### Fixture expectations: `expected.pl`

The discovery-orbit session tests its module with fixtures that have an
`expected.pl` file. The harness that reads it is `harness/run.pl` in
`thoughts/discovery-orbit-examples/orbit-kb-staging/` on the `discovery-orbit`
worktree. It is not part of the main checkout, and
`scripts/orbit-kb/test_orbit_kb.sh` does not read `expected.pl`.

Usage: `swipl harness/run.pl [FIXTURE_DIR [LIB_DIR [FORALL]]]`. The default
`FORALL` is `--forall=prev`.

A fixture is a KB directory with an `expected.pl` file. The file has two kinds
of terms:

```prolog
% variant(Name, Edits): a copy of kb.pl with term edits.
variant(cf1_no_answer, [delete(answer(q1, floor_wins, human))]).

% expect(Variant, 'GOAL', Answers)
expect(base, 'current(C)', ['C = c1', 'C = c2b']).
expect(cf1_no_answer, 'to_ask(Q)', ['Q = q1']).
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
- The harness runs each expectation on both engines and prints
  `ENGINE DISAGREEMENT` when they differ.
- An E code in a variant is a failure. Any code in the `base` variant is a
  failure.

## 13. Environment variables

| Variable | Effect | Default |
|---|---|---|
| `ORBIT_KB` | The KB directory, when `--dir` is not given. | None. `orbit-kb` searches upward from the current directory. |
| `ORBIT_KB_LIB` | The library directory that holds `core.pl` and `modules/`. | `<real dir of the orbit-kb script>/../share/orbit-kb` |
| `ORBIT_KB_SCASP_FLAGS` | Replaces `--forall=prev` in the s(CASP) command. Separate flags with spaces. `--unknown=error` stays. | `--forall=prev` |
| `ORBIT_KB_SCASP_TIMEOUT` | The s(CASP) time limit in seconds. The value must be more than 0. | `20` |

The time limit needs the coreutils `timeout` command on `PATH`. If `timeout`
is not on `PATH`, s(CASP) runs with no limit.

## 14. Testing

To run the suite:

1. Go to the root of the dotfiles repository.
2. Run `heavy scripts/orbit-kb/test_orbit_kb.sh`.
3. To run a subset, set `ONLY` to a regex of test IDs, for example
   `ONLY='^(K|I)[0-9]' heavy scripts/orbit-kb/test_orbit_kb.sh`.

The suite has 164 tests. All pass. On this machine, the suite takes about
1 minute. The suite exits 0 when all tests pass, 1
when a test fails, and 2 when it cannot run.

| Variable | Effect | Default |
|---|---|---|
| `ORBIT_KB_BIN` | The CLI to test. The first argument also sets it. | The repository copy |
| `ORBIT_KB_TEST_LIB` | The library to test. | The repository library |
| `ORBIT_KB_TEST_TIMEOUT` | The time limit for one CLI call, in seconds. | `120` |
| `ONLY` | A regex. Only matching test IDs run. | All tests |

The suite removes `ORBIT_KB` and `ORBIT_KB_SCASP_FLAGS` from its environment
and sets `ORBIT_KB_LIB` to the library under test. Thus the suite works before
installation.

### Fixtures

The fixtures are in `scripts/orbit-kb/fixtures/<name>/`:

- `valid` and `valid_local`: KBs that must lint clean.
- One fixture for each error code, for example `e1_syntax` and `e12_not_var`.
- Variants of some codes, for example `e2_arity` and `e12_named_var`.
- One fixture for each of W3, W4, W5, and W6.

A line that must get a diagnostic ends with the marker `% <-- E<n>`. The tests
read the expected line from the marker. Each test copies a fixture into a fresh
temporary directory and never changes the original. The tests read `kb.pl`
back with `swipl`, so no test depends on the spacing or the quotes that the CLI
writes.

### The independence rule

The only source of expected behavior is `thoughts/orbit-kb-contract.md`. No
test reads the CLI source or the library source. Thus the implementation never
decides what a test expects. Where the contract is not clear, the test uses the
reading that makes a failure loud, and a comment above the test says so.

Three agents wrote the library, the CLI, and the tests in parallel, from the
same contract. The test author never read the CLI source.

## 15. Design decisions and history

| Decision | Reason |
|---|---|
| Two engines | s(CASP) gives explanations, but it gave wrong answers (H2, H3). SWI gives the verdict. The cross-check makes each wrong answer loud. |
| `--forall=prev` | The default algorithm failed H2 and H3. `prev` passed both. It is the algorithm of the 2018 paper and the default in Ciao. Nobody proved that `prev` is sound. Its known weakness is arithmetic constraints that link variables under negation. |
| Exit 2 for typos and disagreements | A typo or a disagreement must never look like "false". |
| Stubs plus `--unknown=error` | An empty predicate gives "No models" with no warning. With stubs and `--unknown=error`, a misspelled name is an error. |

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
- **D6.** Stubs are made only for declared predicates with no clauses.
  Anonymous variables in a query get names before s(CASP) gets them, because
  `--json` crashes on `_`.

Known gaps:

- s(CASP) is slow on `done`.
- The `--why` trees are long, also in the default short form. `--long` makes
  them longer.
- The s(CASP) time limit needs the coreutils `timeout` command.
- `orbit-kb run --type ... --expect` is deferred. It does not exist.

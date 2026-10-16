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

We built `orbit-kb` on 2026-10-15, with SWI-Prolog 9.2.9 and s(CASP) 1.1.4. On
2026-10-16, an independent review (D7) and a speed fix (D8) changed the tool.
Sections 9, 11, and 15 describe both.

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

`orbit-kb` also uses two common tools: `flock` from util-linux, and `timeout`
from coreutils. `doctor` does not examine them. Section 13 says what happens
when one is missing.

The result on this machine (12 `ok` lines and 1 `info` line):

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
ok    H4 raw atoms, raw mode (E13 bypassed): the cross-check must report ENGINE DISAGREEMENT.
ok    H4 under not, ground mode (E13 bypassed): the cross-check must report ENGINE DISAGREEMENT.
ok    Grounder corruption (one failed_after instance deleted from H3): the cross-check must report ENGINE DISAGREEMENT.
ok    E13 flags the H4 atoms (order_4417, order_5120).
ok    E12 flags the bad H1 form: done :- not under(_).
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
| `kb.pl` | `init`, `add`, `declare`, `declare-attest`, `subject`, `attest`, `run` | The first term is `uses([Module, …]).` The list can be empty. Then come facts, classical negations (`-fact`), and local `decl/4` and `attest_type/4` lines. |
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
5. Stubs `p(_, …, _) :- false.` for each declared predicate with no clauses.
6. `#pred` lines, made from the templates of the declarations.

The SWI engine loads this program as it is. By default, s(CASP) gets a
grounding of this program for the goal (section 11).

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
The rewrite is atomic: the command writes a temp file in the KB directory, and
then renames it.
Exit: 0 on success. 1 if the file is missing.

### `attest TYPE SUBJECT 'PREDICATE' [--by human|agent] [--id ID]`

Appends `attest(ID, TYPE, SUBJECT, PREDICATE, BY, TIME)`. `--by` defaults to
`agent`. The ID defaults to the next free `aN`. The time is now, in UTC.
`orbit-kb` checks the shape, the writer, and the references. The predicate
`digest(current)` becomes the recorded digest of SUBJECT. The file must still
have that digest. If the file changed, run `orbit-kb subject` first.
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

### `lint [--strict]`

Examines `kb.pl`, `rules.pl`, the core, and the modules. It prints one line per
problem, then the module `lint_issue` results, then a summary line. Section 10
lists the codes. `lint` still runs when a source has E1 or E2. The commands
that answer (`query`, `why`, `whynot`, `show`, `report`) stop in that case
(section 9).
Exit: 0 if clean or only warnings. 1 on errors, or on warnings with `--strict`.

### `query 'GOAL' [-n N] [--why] [--long] [--json] [--html FILE]`

Answers GOAL on both engines and compares them. Each predicate in GOAL must be
declared or built in. `-n N` shows N answers. The default is 1, and 0 shows all
answers. The output is one line per answer, `true` or `X = v, Y = w`. If there
is no answer, the output is `false`. The s(CASP) runs for the cross-check and
for the explanation run at the same time. For a goal with no variables, s(CASP)
starts before `orbit-kb` builds the SWI engine, so the two engines overlap.
By default, s(CASP) runs on a grounding of the program (section 11).

| Option | Effect |
|---|---|
| `--why` | Adds the s(CASP) explanation, in short form. |
| `--long` | Gives the full explanation. |
| `--json` | Prints the s(CASP) JSON unchanged. |
| `--html FILE` | Writes the explanation as HTML. |

The options `--why` and `--html` together start three s(CASP) runs. They run in
parallel.

Exit: 0 on an answer. 1 on no answer. 2 on a bad goal, an undeclared
predicate, a syntax error (E1) in a source file, an undeclared predicate (E2) in
`rules.pl`, `SWI ERROR`, or `ENGINE DISAGREEMENT`.

### `why 'GOAL' [-n N] [--long]`

The same as `query --why`. The exit codes are the same as for `query`.

### `whynot 'GOAL' [--long]`

The first line is the verdict of the SWI engine: `holds`, `contradicts`, or
`absent` (section 9). Then it prints the s(CASP) explanation. Its s(CASP) runs
start at the same time.
Exit: 0. 2 on `ENGINE DISAGREEMENT`, or on a syntax error (E1) or an undeclared
predicate (E2) in a source file.

### `show [claims|questions|open|disclosures|extensions|all]`

Lists parts of the KB as plain text. The default is `all`. `open` lists
`to_ask`, `stale`, and `contested`. When the `build` module is in use, `open`
also lists `under` and `over`. `show` runs one query for each relation, not
one query for each fact.
Exit: 0. 2 on an unknown topic, or on E1 or E2 in a source file.

### `report`

Prints a skeleton of a delivery report with these sections: `Delivered:`,
`Claims:`, `Guesses:`, `Disclosures:`, `Not checked:`, `Open:`, `To land:`.
You write `Delivered` and `To land` yourself. Step 16 of section 3 shows an
example. Like `show`, `report` runs one query for each relation.
Exit: 0. 2 on E1 or E2 in a source file.

### `doctor`

Examines `swipl`, `scasp`, and the library, and prints a fix step for each
missing item. Then it runs the known-answer self-tests and the controls
(section 11). The self-tests run at the same time as the tool checks. They never
use the s(CASP) result cache. Each line starts with `ok`, `info`, `FAIL`, or
`skip`. A full run prints 12 `ok` lines.

| Check | What `doctor` makes sure of |
|---|---|
| 3 tool checks | `swipl`, `scasp`, and the library directory exist. |
| H1 helper form | `done` is false on both engines. |
| H2 program | `finding_lead(F)` has no answer on both engines. |
| H3 program | `passed(K)` is exactly k2, k3, k4 on both engines. |
| H4 renamed atoms | `r` is false on both engines. |
| H4 raw atoms, raw mode | The cross-check reports `ENGINE DISAGREEMENT`, with E13 bypassed. |
| H4 under `not`, ground mode | The cross-check reports `ENGINE DISAGREEMENT`, with E13 bypassed. |
| Grounder corruption | `doctor` deletes one `failed_after` instance from the grounded H3 program. The cross-check reports `ENGINE DISAGREEMENT`. |
| E13 | E13 flags the H4 atoms (`order_4417`, `order_5120`). |
| E12 | E12 flags the bad H1 form `done :- not under(_)`. |

The self-tests H1 to H4 run with s(CASP) on the grounded program, as a query
does. The H4 raw control runs with `ORBIT_KB_SCASP_GROUND=raw`.
Exit: 0 if all checks pass. 2 if an item is missing or a self-test fails.

### `help [COMMAND]`

Shows the general help, or the help for one command. The general help gives
the hazards H1–H4 in short form, and it says how grounding changes them.
Exit: 0.

### Locking

The commands `add`, `declare`, `declare-attest`, `subject`, and `attest` hold
an exclusive lock on `kb.lock` in the KB directory for the whole cycle. The
cycle is: read `kb.pl`, choose the ID, write, and append. Thus two writers in
two processes cannot choose the same ID. `run` takes the lock only to record
its result (see `run`). The commands that only read the KB take no lock.

`flock(1)` from util-linux gives the lock. A lock goes away when the process
ends, for any reason, so a stale lock cannot occur. If `flock(1)` is not on
`PATH`, for example on macOS, `orbit-kb` uses the lock that SWI-Prolog takes on
`kb.lock`.

## 9. Exit codes, and how to read answers

| Code | Meaning |
|---|---|
| 0 | Success. The query is true. Lint is clean. |
| 1 | The query has no answer. Lint found errors. `orbit-kb` rejected the input. A `run` failed. |
| 2 | Usage error. The KB, the library, or a tool is missing. A goal is bad, or names an undeclared predicate. A source file has a syntax error (E1), or `rules.pl` has an undeclared predicate (E2), and the command must answer. `SWI ERROR`. `ENGINE DISAGREEMENT`. Internal error. |
| 130, 143 | `run` got SIGINT (130) or SIGTERM (143). It recorded nothing. |

A typo never exits 1. Exit 1 always means a real "no". If you get exit 2, do
not read it as "false".

### A broken source gives exit 2

`query`, `why`, `whynot`, `show`, and `report` check the sources before they
answer. Two cases stop them with exit 2:

- A KB file or a rules file has a syntax error (E1).
- `rules.pl` has an undeclared head or body predicate (E2).

In both cases `orbit-kb` cannot load every clause. An answer can be wrong. So
it prints the lint lines and gives no answer. It never prints a quiet `false`.
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

### `ENGINE DISAGREEMENT`

The two engines gave different answers. `orbit-kb` prints both results and a
hint, and exits 2. This example forces the bad `--forall` algorithm on a check
that passed in run 1 and failed in run 2 (hazard H3). The KB has a claim `c1`
and the fact `check(k1, c1)`. Run `orbit-kb run k1 -- true`, and then
`orbit-kb run k1 -- false`. The example also sets `ORBIT_KB_SCASP_GROUND=raw`.
A grounded program has no `forall`, so without that variable the answer is
correct:

```text
$ ORBIT_KB_SCASP_GROUND=raw ORBIT_KB_SCASP_FLAGS=--forall=all orbit-kb query 'passed(K)' -n 0
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
NOTE: s(CASP) ran the raw program: the program uses _#>3, which the grounder does not support.
CROSS-CHECK SKIPPED: the goal uses the constraint #>, which the SWI engine cannot evaluate
X = _ (unchecked)
```

An `(unchecked)` answer has no second opinion. The first line of the example is
a `NOTE`, which the next section explains.

The default s(CASP) time limit is 20 s. A query on a very large KB can take
longer. Section 11 gives the numbers, and section 15 gives the remaining limit.

### `NOTE: s(CASP) ran the raw program`

By default, s(CASP) runs on a grounding of the program (section 11). If
`orbit-kb` cannot ground the program, it prints this line on stderr and runs
s(CASP) on the raw program:

```text
NOTE: s(CASP) ran the raw program: <reason>
```

The answers do not depend on the grounding. A NOTE only means that the s(CASP)
run can be slower. The causes are:

- The program has a form that the grounder does not support (section 11).
- The grounder stopped with an error.
- The grounding took more than 5 s.

This example uses the rule `unsafe(X) :- claim(C, _, _), not served(X).` in
`rules.pl`. In that rule, `X` has no value when the `not` literal runs. Lint
flags the rule as E14 (section 10):

```text
$ orbit-kb query 'unsafe(X)'
NOTE: s(CASP) ran the raw program: a not literal has a free variable when it is reached: not served(_).
X = _
```

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
| E1 | Syntax error, with file and line. In any source, E1 makes `query`, `why`, `whynot`, `show`, and `report` exit 2. |
| E2 | Undeclared predicate or wrong arity, in `kb.pl` facts or in the heads and bodies of `rules.pl`, `core.pl`, and the modules. If a declaration has the same name but a different arity, the message names it. In `rules.pl`, E2 makes the commands that answer exit 2. |
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
| E13 | An atom or a string ends in `_` and digits (hazard H4). |
| E14 | Unsafe negation: a variable of a `not` literal occurs in the head, but in no positive body literal. |

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

### E12 and E14: two checks for `not`

Both codes guard a `not` literal. They find different faults:

- E12: a variable occurs in the `not` literal and nowhere else in the clause
  (hazard H1). The fix is a helper predicate.
- E14: a variable occurs in the head and in the `not` literal, but in no
  positive body literal. The variable has no value when the `not` literal runs.
  The fix is a positive literal before the `not` literal that gives the
  variable its values.

The rule `unsafe(X) :- claim(C, _, _), not served(X).` gives E14:

```text
E14 rules.pl:1: In unsafe/1, the literal `not served(X)` uses X. It occurs in the head, but no positive literal in the body binds it (unsafe negation). The engines can then disagree. Fix: before the not literal, add a positive literal that gives X its values, for example a fact or a rule that lists them.
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

## 11. The two engines, and why

Each query runs on two engines:

| Engine | Role | How |
|---|---|---|
| SWI-Prolog | The verdict: the answers that `orbit-kb` prints. | Loads the program as assembled into a fresh module. `not G` becomes `\+ G`, and each `not` literal moves after the positive literals of its clause. `-p(…)` becomes the predicate `'-p'(…)`. `#` directives are removed. Each declared predicate is dynamic. Limits: 10 s and 1000 answers. |
| s(CASP) | The explanation: `--why`, `--json`, `--html`. | `scasp --unknown=error --forall=prev` on a grounding of the program plus stubs. With `ORBIT_KB_SCASP_GROUND=raw`, or after a fallback, it runs the program as assembled (the raw program). |

The SWI engine always runs the original program, never the grounding. It moves
each `not` literal after all positive literals of its clause. Builtins keep
their place relative to the positive literals. In a stratified program, this
does not change the answers. It prevents floundering, which is `\+` running on
a variable that has no value. Lint error E14 finds the rules where a `not`
variable gets no value from a positive literal.

Then `orbit-kb` compares the engines. Existence must agree: SWI has an answer if
and only if s(CASP) has a model. When the bindings are ground, the binding sets
must also agree, at each `-n`. The comparison covers the answers that both
engines returned up to `-n`.

If SWI finds M answers, `orbit-kb` also asks s(CASP) for M+1 models, up to a
cap. If s(CASP) returns more answers than SWI, the result is
`ENGINE DISAGREEMENT`. The cap is 100 models for a grounded program and 10 for
a raw program.

The reason for two engines: s(CASP) gives good explanations, but it gave wrong
answers in the tests that follow. SWI negation as failure is correct for the
stratified programs that `orbit-kb` targets. Each engine is a check on the
other.

The upstream bug behind H2 and H3 is
<https://github.com/SWI-Prolog/sCASP/issues/10>. It was opened in 2024-10 and
is still open. No fix exists in 1.1.4 or in master.

### Grounding the s(CASP) program (D8)

By default, s(CASP) does not get the assembled program. It gets a grounding of
that program for the goal. A grounding holds the rule instances that the goal
can use, with no variables. The SWI engine still runs the original program. So
the cross-check compares two different programs that must give the same answers.

**Why grounding.** Before D8, s(CASP) was slow on KBs with many attestations.
The cost grew about N³, where N is the number of `attest/6` facts. The cause was
this:

- The duals of rules that read `attest/6` have nested `forall` loops over
  variables that occur only in the body. `failed_after/2` and `refuted/1` have 5
  nested loops each. `was_red/1` has 10.
- Each step of a `forall` copies the whole proof stack. It also scans the set of
  proved goals again.
- `done` adds one more `forall`, over the claims. Each step solves
  `not under(C)` with a bigger stack. So `done` timed out at 20 attestations.

A profile of `passed(k1)` on the raw program took 0.07 s at 20 attestations,
0.35 s at 40, and 5.75 s at 100. The cause was not the explanation tree, not
`--nmr`, and not the `--forall` algorithm: `sasp` was as slow as `prev`. A
ground program has no body-only variables. So no dual contains a `forall`, and
each dual is a plain conjunction of ground disjunctions.

**What the grounding contains:**

- Every rule instance that the goal can use and whose positive body can hold.
  The `not` literals do not count in that test, but the grounder grounds their
  atoms too.
- The builtins, evaluated while grounding.
- For a ground head that has an instance with a body of only facts, that
  instance alone (witness pruning). This keeps `was_red/1`, `failed_after/2`,
  and `contested_twice/1` to one instance for each head. Without it, one check
  with 200 runs gave 10,396 clauses and 7.6 s. With it, the result is 496
  clauses and 0.4 s.
- The facts that the goal can use, unchanged. Thus `why` still names the
  attestation IDs.
- Stubs for the predicates that have no clauses.
- The `#pred` lines.

**How the grounder works.** The grounder is part of the CLI script, and it runs
in SWI-Prolog. It adds no dependency. First it computes the positive skeleton:
the least model of the program with every `not` literal removed. The
computation uses tabling, and the goal drives it. The grounder keeps each rule
instance whose positive body holds in the skeleton. A builtin must be ground
when it runs, as in the SWI engine.

**Fallback.** The grounder supports a fragment of the language. It refuses these
forms:

- A `not` over a free variable.
- A constraint.
- `forall`, clpq, `;`, and `->`.
- A program that is not stratified.
- An instance that stays non-ground.

It also stops after 5 s. In each case, s(CASP) runs the raw program, and
`orbit-kb` prints `NOTE: s(CASP) ran the raw program: <reason>` (section 9).
The answers never depend on whether the grounding succeeded. The grounding goes
to a new temp file only when it is complete, so the raw file never changes.
Lint E11 still compiles the raw program.

**Relevance trimming.** The grounding keeps only the facts and instances that the
goal depends on:

1. The roots are the goal literals, with `not` removed and builtins skipped. If
   a predicate `p` has a `-p` clause, the roots also hold every `p(…)` and
   `-p(…)` atom. Then s(CASP) checks `p` against `-p` on the same atoms as in
   raw mode.
2. A relevant atom makes every instance with the same head relevant. An
   instance makes every atom of its body relevant, positive or under `not`.
3. The output has the relevant facts and the relevant instances. It also has a
   stub for each predicate that has no emitted clause. It ends with the `#pred`
   lines of the predicates that appear.

The matching ignores a final `_<digits>` on atoms and strings, as the s(CASP)
reader does (H4). We tested a version without this rule. It dropped
`p(order_4417)` for `q :- not p(order_5120)`, and the `doctor` control
"H4 under not, ground mode" failed. Trimming does not change the output of
`why` and `whynot`. We compared 48 pairs of explanations (6 goals on 4 KBs, in
short and long form). Each pair was byte-identical before and after trimming.

**Why the answers do not change.** Let P be a program that is stratified by
predicate. Let M be its perfect model. M is also its only stable model. It is
the SWI verdict, when the SWI engine ends and does not flounder. Let S be the
least model of the positive skeleton of P.

1. M is a subset of S. M is the least model of the reduct of P. Each rule of
   the reduct is a rule of the skeleton, and least models grow with the program.
2. An instance with a positive body atom outside S has a body atom outside M.
   It never fires in M. So the grounder can drop it.
3. The atoms that the grounder demands form a splitting set. By the splitting
   set theorem (Lifschitz and Turner, 1994), the model restricted to that set
   equals the model of the rules with heads in the set. The grounder emits
   exactly those rules, plus the facts.
4. Witness pruning is safe. An instance with a body of only facts puts its head
   in every model. Other instances of that head add nothing.
5. Each answer of the goal is an instance of the goal in M, and M is a subset
   of S. The skeleton call lists every such instance. So the grounder demands
   every answer.

Relevance trimming follows the same argument. The relevant atoms form a
splitting set of the grounded program, and stubs add nothing. s(CASP) also
solves top-down. It resolves a goal only against clauses with a unifying head.
Each clause with a head that does not unify satisfies a dual at once. So a
proof consults only the relevant atoms. Matching on normalized atoms only
enlarges the set. A program outside the fragment is not grounded, so the
argument does not cover it.

**Evidence.** The scripts and logs were in a session scratchpad. Its main file
is
`/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad/perf/scasp-agent/RESULTS.md`.
A scratchpad can disappear. So this list keeps the results:

- About 1.45 million differential checks against SWI. Each check compares the
  SWI answers of the original program with the SWI answers of the grounded
  program, on the shipped core and `build` rules. The KBs are three families
  that we listed exhaustively (15,120, 3,800, and 400 KBs) and 5,000 random
  KBs. The result is 0 mismatches and 0 fallbacks.
- Mutation controls. A harness that drops one grounded instance gave 674
  mismatches in 2,000 checks. A harness that drops one kept fact gave 903
  mismatches in 2,454 checks. So the checks can see these faults.
- About 39,000 s(CASP) checks against SWI, with `--forall=prev`: 0 wrong
  answers, for the raw and for the grounded program.
- With `--forall=all`, on 60 random KBs, the raw program gave 101 wrong answers
  and 28 timeouts. The grounded program gave 0 and 0.
- The test suite passes (176 of 176). Each `doctor` control fails when its
  condition is removed. Without `ORBIT_KB_SCASP_GROUND=raw`, exactly four tests
  fail: H3b, X2, X3, and X9. These are the negative controls.

**How the cross-check finds a grounder bug.** The SWI verdict comes from the
program as written, through a separate path. A grounder that drops or adds an
instance changes the s(CASP) answer, and the cross-check compares that answer
with SWI. The `doctor` control "Grounder corruption" tests this: it deletes one
`failed_after` instance from the grounded H3 program.

**What the cross-check no longer covers.** The grounder computes joins with
SWI unification and arithmetic. So a unification bug in SWI does not show in a
join. Only negation has an independent check. Also, in ground mode the
cross-check does not test the non-ground machinery of s(CASP) on KB queries.
That is the purpose of grounding. Raw mode still tests it.

**Explanations.** The `why` trees are much shorter, and they cite the
attestation IDs. A predicate with no relevant instance shows the line
`there is no evidence that false holds` under its node.

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
  The grounder also refuses such a literal. Then s(CASP) runs the raw program,
  and `orbit-kb` prints a NOTE (section 9).

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
- **Guard.** In ground mode, H2 cannot occur, because no dual contains a
  `forall`. For a raw program, `orbit-kb` uses `--forall=prev`, and the
  cross-check finds the problem if it occurs. `doctor` runs this program on both
  engines, in ground mode. The tests run it with `--forall=all`. With
  `ORBIT_KB_SCASP_GROUND=raw` they expect `ENGINE DISAGREEMENT`. In ground
  mode they expect the correct answer.

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

- **Guard.** In ground mode, H3 cannot occur, for the same reason as H2. For a
  raw program, `orbit-kb` uses `--forall=prev`, and the cross-check finds a
  mismatch. Section 9 shows the real output with `--forall=all` and
  `ORBIT_KB_SCASP_GROUND=raw`. `doctor` requires exactly k2, k3, and k4, in
  ground mode.

### H4: atoms that end in `_<digits>` merge

- **Symptom.** s(CASP) removes a final `_<digits>` from atoms, quoted atoms
  too. Then different atoms unify.
- **Example.** `p(order_4417). r :- p(order_5120).` makes `r` true in
  s(CASP), but false in SWI. With `p(order_4417). p(order_5120).`, the query
  `p(X)` prints `X = order` two times.
- **Guard.** Lint error E13 finds such atoms and strings in `kb.pl`,
  `rules.pl`, the core, and the modules. `add`, `declare`, `attest`, and
  `init --id` reject them:

  ```text
  $ orbit-kb add "world(order_4417)"
  Rejected. Nothing was written.
  E13 in argument 1 (world(order_4417)): The atom order_4417 ends in _ and digits. s(CASP) drops that ending, so different atoms can merge (hazard H4). Fix: rename it, for example order4417. Here you can use order4417.
  ```

  If such an atom gets past E13, the cross-check can report
  `ENGINE DISAGREEMENT`. In ground mode, this happens when the merged atom is
  under `not` or in an answer. It does not happen in a join, because the
  grounder does the joins in SWI. `doctor` tests the renamed atoms, the raw
  atoms in raw mode, and the atoms under `not` in ground mode.

### Performance

The times are wall-clock seconds on this laptop, with the caches off
(`ORBIT_KB_NO_CACHE=1`). Other jobs ran on the machine, so expect a spread of
about 20 %. Each KB has one check for each claim and two runs for each check.
For example, 100 attestations are 50 claims. "Before" is the original CLI.
"Timeout" means that `orbit-kb` skipped the 20 s cross-check
(`CROSS-CHECK SKIPPED`).

| Attestations | Query | Before (s) | After (s) |
|---|---|---|---|
| 20 | `done` | timeout | 0.18 |
| 20 | `passed(K) -n 0` | 0.83 | 0.15 |
| 20 | `why fulfilled(c1)` | 0.74 | 0.15 |
| 40 | `done` | timeout | 0.25 |
| 40 | `passed(K) -n 0` | 3.3–4.7 | 0.16 |
| 40 | `fulfilled(c1)` | 1.6 | 0.14 |
| 40 | `why fulfilled(c1)` | 3.2 | 0.16 |
| 100 | `done` | timeout | 0.53 |
| 100 | every other query | timeout | 0.15–0.17 |
| 200 | `done` | timeout | 1.44 |
| 200 | every other query | timeout | 0.16–0.21 |
| 400 | `done` | not measured | 6.2 |
| 400 | every other query | not measured | 0.17–0.28 |
| any | warm cache hit | no cache | 0.04–0.15 |
| no KB | `help` | 0.09 | 0.04 |
| no KB | `doctor` | 0.45 | 0.2–0.3 |

For a warm query, the CLI itself uses about 9 ms of CPU. The rest is s(CASP).
It needs about 42 ms to start, and then it compiles and solves.

The speed work has these parts:

- **Saved state.** Loading the script and its libraries takes about 80 ms. A
  saved state starts in about 35–40 ms. The state is in
  `${XDG_CACHE_HOME:-~/.cache}/orbit-kb/`. Its key is the text of the script,
  the path of the script, and the SWI-Prolog version and executable. A sidecar
  file `.ok` holds the size and the SHA-1 of the state. If the state is bad,
  the CLI loads the script as usual. The first run after a script change builds
  a new state, which takes about 0.3 s.
- **Lazy libraries.** Libraries that only some commands need load on first use.
- **Overlap.** The s(CASP) runs overlap with the SWI engine. `whynot` and
  `doctor` run their parts in parallel.
- **s(CASP) result cache.** The cache is in
  `${XDG_CACHE_HOME:-~/.cache}/orbit-kb/scasp/`. Its key is the text of the
  program that `orbit-kb` sends, the flags, the identity of the `scasp` binary,
  and the SWI-Prolog version. A timeout, an error, and a `--html` run are never
  cached. A write is atomic. The cache holds at most 2000 entries. A corrupt
  entry counts as a miss. A hit is valid only if the stored run took less time
  than the current time limit. So a shorter `ORBIT_KB_SCASP_TIMEOUT` still
  times out as before.
- **Hot spots.** The quadratic loops of lint use AVL sets. `show` and `report`
  run one query for each relation.
- **Model cap.** At 200 and 400 attestations, 100 models cost at most 0.06 s
  more than 10 models. A goal with no answer costs the same at every cap,
  because s(CASP) must exhaust the search. We saw no duplicate model. A
  duplicate is possible in one case: a head has two instances that both hold,
  and each instance has a `not` in its body. The cap bounds the duplicates.

`ORBIT_KB_NO_CACHE=1` turns off both the state and the result cache.

`done` still grows about O(n²) in the number of claims, because of the scans of
proved goals in s(CASP). It takes about 6 s at 200 claims (400 attestations).
With more than about 250 claims, `done` can take more than 20 s. Then
`orbit-kb` prints `CROSS-CHECK SKIPPED`, and the answer from the SWI engine is
`(unchecked)`. Typical tickets have 1–20 claims.

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
- **E13.** No atom or string can end in `_` and digits. Write `order4417`, not
  `order_4417`.
- **E14.** If a variable occurs in a `not` literal and in the head, it must
  also occur in a positive body literal.
- **Grounding.** Write stratified rules, with no `;`, `->`, `forall`, or
  constraint. A module that breaks this rule still works, but s(CASP) then runs
  the raw program. That run can be slow on a large KB (section 9).
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
`thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/`. It is a
draft in the `thoughts/` directory. It is not part of the installed tool, and
`scripts/orbit-kb/test_orbit_kb.sh` does not read `expected.pl`. The harness
runs s(CASP) on the assembled program. It does not use the grounding of the
CLI.

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
| `ORBIT_KB_SCASP_GROUND` | `raw` runs s(CASP) on the program as assembled. Any other value, or no value, runs s(CASP) on the grounding (section 11). | Not set: grounding |
| `ORBIT_KB_NO_CACHE` | A value other than empty or `0` turns off the saved state and the s(CASP) result cache. | Not set: caches on |
| `XDG_CACHE_HOME` | The base of the cache directory. It must be an absolute path. The caches are in `$XDG_CACHE_HOME/orbit-kb/`. | `~/.cache` |
| `ORBIT_KB_TEST_JOBS` | The number of parallel workers of the test suite (section 14). | The number of CPUs, at most 4 |
| `ORBIT_KB_GROUND_TIMEOUT` | A test hook. It sets the grounding time limit in seconds. The tests of the fallback use it. | `5` |

The time limit needs the coreutils `timeout` command on `PATH`. If `timeout`
is not on `PATH`, s(CASP) runs with no limit.

The lock on `kb.lock` needs `flock(1)` from util-linux. If `flock(1)` is not on
`PATH`, `orbit-kb` uses the lock that SWI-Prolog takes on the same file
(section 8).

The test variables `ORBIT_KB_BIN`, `ORBIT_KB_TEST_LIB`, `ORBIT_KB_TEST_TIMEOUT`,
and `ONLY` are in section 14.

### The caches

`orbit-kb` keeps two caches in `${XDG_CACHE_HOME:-~/.cache}/orbit-kb/`:

| Path | Contents |
|---|---|
| `state-*.qs` and `state-*.qs.ok` | The saved state of the script, and its sidecar with the size and the SHA-1. |
| `scasp/` | The s(CASP) result cache: one file for each result, and a `version-*` file for each `scasp` binary. |

Section 11 describes both caches. You can delete the directory at any time.
`orbit-kb` builds again what it needs.
Every cache error makes `orbit-kb` fall back to a normal run. To bypass both
caches for one command, set `ORBIT_KB_NO_CACHE=1`. `doctor` never uses the
result cache.

## 14. Testing

To run the suite:

1. Go to the root of the dotfiles repository.
2. Run `heavy scripts/orbit-kb/test_orbit_kb.sh`.
3. To run a subset, set `ONLY` to a regex of test IDs, for example
   `ONLY='^(K|I)[0-9]' heavy scripts/orbit-kb/test_orbit_kb.sh`.

The suite has 176 tests. All pass. The tests run in parallel. On an idle
machine, the suite takes about 13.5 s with 4 workers, and about 49 s with one
worker (`ORBIT_KB_TEST_JOBS=1`). The suite exits 0 when all tests pass, 1
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
own empty `XDG_CACHE_HOME`. So a cache cannot carry a result from one test to
another, or from `~/.cache`.

The tests of the review fixes and of the grounding have these IDs:

- `D7a`–`D7d`: broken sources exit 2, and unsafe negation.
- `RC`: eight concurrent `run` commands on one KB. The run numbers are 1 to 8,
  the IDs are unique, and each run has one log.
- `E14` and `E13s`: lint E14, and E13 on strings.
- `GD` and `GU`: `done` on 20 claims in ground mode, and the fallback NOTE.
- `H3d`, `X2g`, and `DR4`: the H3 and H2 programs under `--forall=all` in
  ground mode, and the new `doctor` controls.

The negative controls for H2 and H3 (`H3b`, `X2`, `X3`, `X9`) set
`ORBIT_KB_SCASP_GROUND=raw`.

### Fixtures

The fixtures are in `scripts/orbit-kb/fixtures/<name>/`:

- `valid` and `valid_local`: KBs that must lint clean.
- One fixture for each error code, from E1 to E14, for example `e1_syntax`,
  `e12_not_var`, and `e14_unsafe_neg`.
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
| `--forall=prev` | The default algorithm failed H2 and H3. `prev` passed both. It is the algorithm of the 2018 paper and the default in Ciao. Nobody proved that `prev` is sound. Its known weakness is arithmetic constraints that link variables under negation. With grounding, it matters only for a raw program. |
| Exit 2 for typos and disagreements | A typo or a disagreement must never look like "false". D7 added broken sources to this rule. |
| Stubs plus `--unknown=error` | An empty predicate gives "No models" with no warning. With stubs and `--unknown=error`, a misspelled name is an error. |
| Grounding for s(CASP) (D8) | s(CASP) cost about N³ in the number of attestations, and `done` timed out at 20 attestations. A grounding has no body-only variables, so no dual has a `forall`. The SWI verdict still runs the original program. |
| Fallback to the raw program | The grounder supports a fragment. Outside it, the raw program gives the same answers, with a NOTE. |
| `run` outside the lock (D7) | A long check must not stop other writers. The cost is that `run` numbers runs in the order that they finish. |
| Caches under `XDG_CACHE_HOME` | A saved state and an s(CASP) result cache make a warm query take 0.04 to 0.15 s. A cache error is never fatal, and `ORBIT_KB_NO_CACHE=1` turns both caches off. |

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
- **D7 (review fixes, 2026-10-16).** An independent review found these
  faults. We fixed all of them:
  - **Broken sources.** An E1 error in any source, or an E2 error in
    `rules.pl`, makes `query`, `why`, `whynot`, `show`, and `report` exit 2.
    Before D7, they gave a quiet `false`.
  - **Unsafe negation.** The SWI translation moves each `not` literal after the
    positive literals. New lint error E14 finds a `not` variable that occurs in
    the head but in no positive body literal. The cross-check asks s(CASP) for
    M+1 models.
  - **Locking.** The writing commands hold `flock` on `kb.lock`.
  - **`run` order.** `run` runs its command without the lock and records the
    result afterwards. `run` numbers runs in the order that they finish. SIGINT
    or SIGTERM records nothing.
  - `subject` rewrites `kb.pl` atomically.
  - E13 also checks strings.
  - Temp files come from `tmp_file_stream`.
- **D8 (grounded cross-check, 2026-10-16).** s(CASP) runs on a grounding of the
  program for the goal. Section 11 gives the design, the argument, and the
  evidence.
  - **Switch.** s(CASP) runs on the grounding by default.
    `ORBIT_KB_SCASP_GROUND=raw` runs the raw program.
  - **Fallback.** For an unsupported form, an error, or more than 5 s,
    the CLI prints `NOTE: s(CASP) ran the raw program: <reason>` and uses the
    raw program.
  - **Trimming.** Only the facts that the goal depends on go to s(CASP).
  - **Cap.** A grounded program allows up to 100 models in the cross-check. A
    raw program keeps 10.
  - **Hazards.** In ground mode, H2 and H3 cannot occur.
  - **`doctor`.** It has 12 checks. The new ones are "H4 under not, ground
    mode" and the grounder-corruption control. The H4 raw control runs in raw
    mode.

The speed work (also on 2026-10-16) did not change any answer:

- A saved state of the script, in the cache directory. Startup takes about
  35–40 ms instead of 80 ms.
- Lazy loading of libraries.
- Overlap of the s(CASP) runs with the SWI engine, and parallel parts in
  `whynot` and `doctor`.
- The s(CASP) result cache.
- AVL sets in the quadratic loops of lint, and one query for each relation in
  `show` and `report`.
- A parallel test suite. Each test has its own cache directory.

Known gaps:

- `done` still grows about O(n²) in the number of claims, because of the scans
  of proved goals in s(CASP). It takes about 6 s at 200 claims (400
  attestations). With more than about 250 claims, it can take more than 20 s.
  Then `orbit-kb` prints `CROSS-CHECK SKIPPED`. Typical tickets have 1–20
  claims.
  Other queries take less than 0.3 s at 400 attestations.
- A program outside the grounder fragment runs on the raw program. That run
  can be as slow as before D8.
- The `--why` trees are long, also in the default short form. `--long` makes
  them longer. A predicate with no relevant instance shows the line
  `there is no evidence that false holds`.
- The options `--why` and `--html` together make three s(CASP) runs. They run
  in parallel.
- `run` numbers follow the order in which the commands end, not the order in
  which they start.
- The lock needs `flock(1)`. Without it, `orbit-kb` uses the lock that
  SWI-Prolog takes on `kb.lock`, for example on macOS.
- The grounder computes joins in SWI. So the cross-check does not find a
  unification bug in SWI. Only negation has an independent check.
- The s(CASP) time limit needs the coreutils `timeout` command.
- `orbit-kb run --type ... --expect` is deferred. It does not exist.

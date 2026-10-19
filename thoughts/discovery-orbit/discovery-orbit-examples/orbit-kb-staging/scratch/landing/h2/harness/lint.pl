% lint.pl: a subset of the orbit-kb lint (contract v2.1), for the staging harness.
% Checks E2 E3 E4 E5 E6 E7 E8 E9 E10 E12 and W1 W3 W5. No line numbers.
% A dangling ref inside an alt entry is reported as E3, not E4.
% Library files are checked for E2 E7 E12 only. run.pl does the H3 check.

:- module(kb_lint, [lint/4]).
:- discontiguous issue/2.
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(pcre)).
:- use_module(library(crypto)).
:- use_module(library(readutil)).

% lint(+KbDir, +Lib, +Kb, -Issues)
%   Lib: File-Term pairs from core.pl and the modules. Kb: the terms of kb.pl.
%   Issues: sorted Code-Message pairs.
lint(KbDir, Lib, Kb, Issues) :-
    findall(D, ((member(_-D, Lib) ; member(D, Kb)), D = decl(_, _, _, _)), Decls),
    findall(A, ((member(_-A, Lib) ; member(A, Kb)), A = attest_type(_, _, _, _)), ATypes),
    exclude(meta_term, Kb, Facts0), maplist(unneg, Facts0, Facts),
    C0 = _{kbdir:KbDir, lib:Lib, kb:Kb, decls:Decls, atypes:ATypes, facts:Facts, ids:[]},
    findall(V, (member(F, Facts), id_value(C0, F, V)), Ids0),
    msort(Ids0, Ids),
    C = C0.put(ids, Ids),
    findall(I, issue(C, I), Issues0),
    sort(Issues0, Issues).

meta_term(uses(_)).
meta_term(decl(_, _, _, _)).
meta_term(attest_type(_, _, _, _)).
unneg(-F, F) :- !.
unneg(F, F).

decl_head(C, Name/Ar, Kind, Head) :-
    member(decl(Kind, Head, _, _), C.decls), functor(Head, Name, Ar).
pi(T, N/A) :- functor(T, N, A).

id_value(C, F, V) :-
    pi(F, PI), decl_head(C, PI, fact, Head),
    arg(I, Head, id), arg(I, F, V).

% --- E10: uses/1 first, with known modules ---
issue(C, 'E10'-'kb.pl must start with uses([Module, ...]).') :-
    C.kb \= [uses(_)|_].
issue(C, 'E10'-M) :-
    C.kb = [uses(Ms)|_], member(Mod, Ms), \+ memberchk(Mod, [build, discovery]),
    format(atom(M), 'uses/1 names an unknown module: ~q.', [Mod]).

% --- kb.pl facts: E2 E6 E7 ---
issue(C, 'E2'-M) :-
    member(F, C.facts), pi(F, PI), \+ decl_head(C, PI, _, _),
    format(atom(M), 'kb.pl: ~q is not declared. Declare it, or fix the name or arity.', [PI]).
issue(C, 'E6'-M) :-
    member(F, C.facts), \+ ground(F),
    format(atom(M), 'kb.pl: the fact ~q is not ground.', [F]).
issue(C, 'E7'-M) :-
    member(F, C.facts), pi(F, PI), decl_head(C, PI, rule, _),
    format(atom(M), 'kb.pl: ~q is a rule predicate. Do not assert it as a fact.', [PI]).

% --- library clauses: E2 E7 E12 ---
issue(C, 'E7'-M) :-
    member(File-T, C.lib), \+ meta_term(T), clause_parts(T, H, _),
    pi(H, PI), decl_head(C, PI, fact, _),
    format(atom(M), '~w: the fact predicate ~q has a clause outside kb.pl.', [File, PI]).
issue(C, 'E2'-M) :-
    member(File-T, C.lib), \+ meta_term(T), clause_parts(T, H, B),
    (   G = H ; body_goal(B, G), \+ builtin(G) ),
    pi(G, PI), \+ decl_head(C, PI, _, _),
    format(atom(M), '~w: ~q is not declared.', [File, PI]).
issue(C, 'E12'-M) :-
    member(File-T, C.lib), clause_parts(T, H, B),
    lonely_not_var(H, B, L),
    format(atom(M), '~w: a variable occurs only under not in ~q. Use a helper predicate.', [File, L]).

clause_parts((H :- B), H, B) :- !.
clause_parts(H, H, true).

body_literals((A, B), Ls) :- !, body_literals(A, L1), body_literals(B, L2), append(L1, L2, Ls).
body_literals(G, [G]).
body_goal(B, G) :- body_literals(B, Ls), member(L, Ls), unwrap(L, G).
unwrap(not(G), G1) :- !, unwrap(G, G1).
unwrap(-G, G1) :- callable(G), !, unwrap(G, G1).
unwrap(G, G).

builtin(G) :- pi(G, PI),
    memberchk(PI, [(=)/2, (\=)/2, (<)/2, (>)/2, (=<)/2, (>=)/2, (is)/2,
                   (#=)/2, (#<>)/2, (#<)/2, (#>)/2, (#=<)/2, (#>=)/2,
                   true/0, false/0, forall/2]).

lonely_not_var(H, B, not(L)) :-
    body_literals(B, Ls), select(not(L), Ls, Rest),
    term_variables(L, LVs), term_variables(H-Rest, Others),
    member(V, LVs), \+ (member(O, Others), O == V), !.

% --- types: E3 E4 E5 E8 ---
issue(C, Code-M) :-
    member(F, C.facts), pi(F, PI), decl_head(C, PI, fact, Head),
    arg(I, Head, T), T \== attest_predicate, arg(I, F, V),
    \+ ok(C, T, V),
    ( T = ref(_) -> Code = 'E4' ; T == ref -> Code = 'E4' ; Code = 'E3' ),
    format(atom(M), 'kb.pl: argument ~w of ~q does not match ~q.', [I, F, T]).
issue(C, 'E3'-M) :-
    member(attest(Id, Type, _, _, _, _), C.facts),
    \+ memberchk(attest_type(Type, _, _, _), C.atypes),
    format(atom(M), 'kb.pl: attestation ~q has the unknown type ~q.', [Id, Type]).
issue(C, 'E3'-M) :-
    member(attest(Id, Type, _, P, _, _), C.facts),
    memberchk(attest_type(Type, Shape, _, _), C.atypes), \+ ok(C, Shape, P),
    format(atom(M), 'kb.pl: the predicate of ~q does not match the ~q shape.', [Id, Type]).
issue(C, 'E8'-M) :-
    member(attest(Id, Type, _, _, By, _), C.facts),
    memberchk(attest_type(Type, _, Ws, _), C.atypes), \+ memberchk(By, Ws),
    format(atom(M), 'kb.pl: ~q may not write ~q (~q).', [By, Type, Id]).
issue(C, 'E5'-M) :-
    append(_, [V, V2|_], C.ids), V == V2,
    format(atom(M), 'kb.pl: the id ~q is used more than once.', [V]).

ok(_, id, V) :- atom(V).
ok(_, text, V) :- atom(V).
ok(_, atom, V) :- atom(V).
ok(_, int, V) :- integer(V).
ok(_, term, V) :- ground(V).
ok(_, by, V) :- memberchk(V, [human, agent, script]).
ok(_, time, V) :- atom(V), re_match("^\\d{4}-\\d\\d-\\d\\dT\\d\\d:\\d\\d:\\d\\dZ$", V).
ok(_, digest, V) :- atom(V), re_match("^sha256:[0-9a-f]{64}$", V).
ok(_, oneof(L), V) :- atom(V), memberchk(V, L).
ok(C, alt(Ss), V) :- member(S, Ss), ( atom(S) -> V == S ; ok_template(C, S, V) ), !.
ok(C, ref(N), V) :- atom(V), member(F, C.facts), functor(F, N, _), arg(1, F, V0), V0 == V, !.
ok(C, ref, V) :- atom(V), memberchk(V, C.ids).
ok(C, T, V) :- compound(T), \+ type_constructor(T), ok_template(C, T, V).
type_constructor(oneof(_)).
type_constructor(alt(_)).
type_constructor(ref(_)).
ok_template(C, T, V) :-
    compound(V), T =.. [F|Ts], V =.. [F|Vs], length(Ts, N), length(Vs, N),
    maplist(ok(C), Ts, Vs).

% --- E9: a test_result needs its run log ---
issue(C, 'E9'-M) :-
    member(attest(Id, test_result, _, result(K, N, R), _, _), C.facts),
    format(atom(Rel), 'runs/~w-~w.log', [N, K]),
    directory_file_path(C.kbdir, Rel, Path),
    format(atom(Want), '% orbit-kb run ~w check=~w result=~w ', [N, K, R]),
    \+ ( exists_file(Path), first_line(Path, L), sub_atom(L, 0, _, _, Want) ),
    format(atom(M), 'kb.pl: ~q has no matching run log ~w.', [Id, Rel]).

first_line(Path, L) :-
    setup_call_cleanup(open(Path, read, S), read_line_to_string(S, L0), close(S)),
    atom_string(L, L0).

% --- warnings: W1 W3 W5 ---
issue(C, 'W1'-M) :-
    member(subject(Id, P, D), C.facts),
    ( is_absolute_file_name(P) -> Path = P ; directory_file_path(C.kbdir, P, Path) ),
    \+ ( exists_file(Path), crypto_file_hash(Path, H, [algorithm(sha256)]),
         atom_concat('sha256:', H, D) ),
    format(atom(M), 'kb.pl: subject ~q: the digest differs from ~w, or the file is missing.', [Id, P]).
issue(C, 'W3'-M) :-
    member(claim(Cl, _, _), C.facts), \+ memberchk(cites(Cl, _), C.facts),
    format(atom(M), 'kb.pl: claim ~q has no cites.', [Cl]).
issue(C, 'W5'-M) :-
    member(supersedes(_, Old), C.facts), memberchk(check(K, Old), C.facts),
    format(atom(M), 'kb.pl: check ~q references the superseded claim ~q.', [K, Old]).

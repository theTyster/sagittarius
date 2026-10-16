% run.pl: check the expectations of an orbit-kb fixture on both engines.
%
% Usage: swipl harness/run.pl [FIXTURE_DIR [LIB_DIR [FORALL]]] [only=VARIANT ...]
%   FIXTURE_DIR  default: fixtures/discovery-a in this staging folder
%   LIB_DIR      default: /home/ty/.dotfiles/shared/link/.local/share/orbit-kb
%   FORALL       default: --forall=prev (as $ORBIT_KB_SCASP_FLAGS does for the CLI)
%
% The core is LIB_DIR/core.pl. A module M is modules/M.pl in this staging folder
% when that file exists, else LIB_DIR/modules/M.pl.
%
% For the base variant and each variant in FIXTURE_DIR/expected.pl:
%   1. Apply the edits to the terms of kb.pl.
%   2. Assemble the program in contract order: core, the modules in uses/1, kb.pl,
%      stubs for declared predicates with no clauses (D6), and #pred lines.
%      The s(CASP) program goes to scratch/<variant>.pl.
%   3. Self-check H4: s(CASP) 1.1.4 drops a trailing _<digits> from atoms at load,
%      so order_4417 reads as order and unifies with order_5120. The assembled
%      program must hold no atom that matches _[0-9]+$.
%      Lint the variant with lint.pl, a subset of the orbit-kb lint.
%      An E code in any variant, or any code in the base variant, is a failure.
%   4. Run each expectation on the SWI engine (not becomes \+, declared predicates
%      are dynamic, 10 s limit, 1000 answers) and on s(CASP)
%      (timeout 30 scasp --unknown=error FORALL -s 0 --json=-).
%      Print PASS or FAIL for each engine, and ENGINE DISAGREEMENT when they differ.
% Exit 0 when everything passes, 1 otherwise.

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).
:- use_module(library(process)).
:- use_module(library(readutil)).
:- use_module(library(http/json)).
:- use_module(library(solution_sequences)).
:- use_module(library(time)).
:- use_module(library(pcre)).
:- use_module(lint).

:- initialization(main, main).

% s(CASP) operators from the contract. They live in module scasp_syntax only.
:- op(900, fy, scasp_syntax:not).
:- op(950, xfx, scasp_syntax:(::)).
:- op(1200, fx, scasp_syntax:(#)).
:- op(1150, fx, scasp_syntax:[table, show, pred]).
:- op(350, fx, scasp_syntax:[include, compute, abducible]).
:- op(700, xfx, scasp_syntax:[#=, #<>, #<, #>, #=<, #>=]).

:- dynamic root/1, lib_dir/1, forall_flag/1, timing/2, cur_variant/1.
:- prolog_load_context(directory, D), file_directory_name(D, R), assertz(root(R)).

default_lib('/home/ty/.dotfiles/shared/link/.local/share/orbit-kb').

main(Argv0) :-
    root(Root),
    partition([A]>>sub_atom(A, 0, _, _, 'only='), Argv0, OnlyArgs, Argv),
    findall(V, ( member(O, OnlyArgs), atom_concat('only=', V, O) ), Only),
    (   Argv = [Dir0|Rest] -> absolute_file_name(Dir0, Dir)
    ;   directory_file_path(Root, 'fixtures/discovery-a', Dir), Rest = []
    ),
    (   Rest = [Lib0|Rest2] -> absolute_file_name(Lib0, Lib) ; default_lib(Lib), Rest2 = [] ),
    (   Rest2 = [Flag|_] -> true ; Flag = '--forall=prev' ),
    assertz(lib_dir(Lib)),
    assertz(forall_flag(Flag)),
    format("fixture: ~w~nlibrary: ~w~ns(CASP): ~w~n", [Dir, Lib, Flag]),
    forall(member(M, [build, discovery]),
           ( module_path(M, P), format("module ~w: ~w~n", [M, P]) )),
    directory_file_path(Dir, 'kb.pl', KbFile),
    directory_file_path(Dir, 'expected.pl', ExpFile),
    read_terms(KbFile, Kb),
    read_terms(ExpFile, Exp),
    findall(N-E, member(variant(N, E), Exp), Vs),
    forall(( member(expect(V, _, _), Exp), V \== base, \+ memberchk(V-_, Vs) ),
           ( count(fail_swi), count(fail_scasp),
             format("FAIL expected.pl: expect/3 names the unknown variant ~w~n", [V]) )),
    include([N-_]>>( Only == [] ; memberchk(N, Only) ), [base-[]|Vs], Run),
    forall(member(Name-Edits, Run), run_variant(Dir, Kb, Exp, Name, Edits)),
    findall(expect(N, G, A), ( member(expect(N, G, A), Exp), memberchk(N-_, Run) ), RunExp),
    summary(RunExp, Status),
    halt(Status).

% --- library files ---
% Label-Path pairs: the core, then the modules in uses/1 order.
library_files(Mods, ['core.pl'-Core|ModFiles]) :-
    lib_dir(Lib), directory_file_path(Lib, 'core.pl', Core),
    findall(L-P, ( member(M, Mods), format(atom(L), 'modules/~w.pl', [M]), module_path(M, P) ),
            ModFiles).

module_path(M, Path) :-
    root(Root), format(atom(Rel), 'modules/~w.pl', [M]),
    directory_file_path(Root, Rel, Staged),
    (   exists_file(Staged) -> Path = Staged
    ;   lib_dir(Lib), directory_file_path(Lib, Rel, Path)
    ).

% --- one variant ---
run_variant(Dir, Kb0, Exp, Name, Edits) :-
    format("~n== ~w~n", [Name]),
    retractall(cur_variant(_)), assertz(cur_variant(Name)),
    catch(foldl(apply_edit, Edits, Kb0, Kb), edit_error(Msg), true),
    (   nonvar(Msg)
    ->  format("BROKEN variant ~w: ~w~n", [Name, Msg]),
        forall(member(expect(Name, G, _), Exp), (count(fail_swi), count(fail_scasp),
               format("  FAIL ~w (variant is broken)~n", [G])))
    ;   assemble(Name, Kb, Lib, File),
        h3_check(File),
        load_swi(Name, Lib, Kb, Mod),
        lint_variant(Name, Dir, Lib, Kb),
        forall(member(expect(Name, G, Want), Exp), run_expect(Mod, File, G, Want))
    ).

apply_edit(delete(T), Ts0, Ts) :- one_match(T, Ts0), exclude(==(T), Ts0, Ts).
apply_edit(replace(Old, New), Ts0, Ts) :- one_match(Old, Ts0), maplist(swap(Old, New), Ts0, Ts).
apply_edit(add(T), Ts0, Ts) :- append(Ts0, [T], Ts).
apply_edit(E, _, _) :-
    \+ memberchk(E, [delete(_), replace(_, _), add(_)]),
    format(atom(Msg), "unknown edit ~q", [E]), throw(edit_error(Msg)).

swap(Old, New, X, Y) :- ( X == Old -> Y = New ; Y = X ).

one_match(T, Ts) :-
    include(==(T), Ts, Ms), length(Ms, N),
    (   N =:= 1 -> true
    ;   format(atom(Msg), "~d kb.pl terms match ~q (want 1)", [N, T]), throw(edit_error(Msg))
    ).

% --- assembly ---
% Lib is a list of Label-Term pairs for the core and the modules, in load order.
assemble(Name, Kb, Lib, File) :-
    root(Root),
    Kb = [uses(Mods)|_],
    library_files(Mods, Files),
    findall(L-T, ( member(L-P, Files), read_terms(P, Ts), member(T, Ts) ), Lib),
    findall(D, ( (member(_-D, Lib) ; member(D, Kb)), D = decl(_, _, _, _) ), Decls),
    format(atom(Base), 'scratch/~w.pl', [Name]),
    directory_file_path(Root, Base, File),
    setup_call_cleanup(open(File, write, Out),
        (   forall(member(_-P, Files),
                   ( read_file_to_string(P, S, []), format(Out, "% ---- ~w~n~s~n", [P, S]) )),
            format(Out, "% ---- kb.pl (variant ~w)~n", [Name]),
            forall(member(T, Kb), print_clause(Out, T)),
            format(Out, "% ---- stubs~n", []),
            forall(( member(decl(_, H, _, _), Decls), \+ has_clause(H, Lib, Kb) ),
                   print_stub(Out, H)),
            format(Out, "% ---- #pred lines from templates~n", []),
            forall(member(decl(_, H, _, Tpl), Decls), print_pred(Out, H, Tpl))
        ),
        close(Out)).

print_clause(Out, T) :-
    write_term(Out, T, [quoted(true), numbervars(true), module(scasp_syntax),
                        spacing(next_argument)]),
    format(Out, ".~n", []).

% D6: a declared predicate needs a stub only when it has no clause.
has_clause(H, Lib, Kb) :-
    functor(H, N, A),
    ( member(_-T, Lib) ; member(T, Kb) ),
    T \= decl(_, _, _, _), T \= attest_type(_, _, _, _),
    ( T = (Hd :- _) -> true ; Hd = T ),
    ( Hd = -(Hd1) -> true ; Hd1 = Hd ),
    functor(Hd1, N, A), !.

print_stub(Out, H) :-
    functor(H, N, A), functor(Stub, N, A),
    Stub =.. [_|Args], maplist(=('$VAR'('_')), Args),
    print_clause(Out, (Stub :- false)).

print_pred(_, _, '') :- !.
print_pred(Out, H, Tpl) :-
    functor(H, N, A),
    numlist_or_empty(A, Is),
    maplist([I, V]>>format(atom(V), 'A~d', [I]), Is, Vars),
    foldl([I, T0, T]>>( format(atom(From), '@(~d)', [I]), format(atom(To), '@(A~d)', [I]),
                        atomic_list_concat(Parts, From, T0), atomic_list_concat(Parts, To, T) ),
          Is, Tpl, Text),
    (   A =:= 0 -> HeadText = N
    ;   atomic_list_concat(Vars, ',', Args), format(atom(HeadText), '~w(~w)', [N, Args])
    ),
    format(Out, "#pred ~w :: ~q.~n", [HeadText, Text]).

numlist_or_empty(0, []) :- !.
numlist_or_empty(A, Is) :- numlist(1, A, Is).

% --- H4 self-check on the assembled program ---
h3_check(File) :-
    read_terms(File, Ts),
    findall(A, ( member(T, Ts), sub_term(S, T), h3_atom(S, A) ), As0),
    sort(As0, As),
    (   As == [] -> format("  H4 check: clean~n", [])
    ;   count(h4_fail),
        format("  H4 FAIL: these atoms end in _<digits>: ~q~n", [As]),
        format("      s(CASP) 1.1.4 drops that suffix, so order_4417 reads as order. Rename them.~n", [])
    ).

h3_atom(S, A) :-
    ( atom(S) -> A = S ; compound(S), compound_name_arity(S, A, _) ),
    re_match("_[0-9]+$", A).

% --- SWI engine ---
load_swi(Name, Lib, Kb, Mod) :-
    atom_concat(kb_, Name, Mod),
    set_module(Mod:base(system)),     % do not see the predicates of this runner
    findall(T, ( member(_-T, Lib) ; member(T, Kb) ), Ts),
    forall(member(decl(_, H, _, _), Ts),
           ( functor(H, N, A), atom_concat('-', N, NegN), dynamic([Mod:N/A, Mod:NegN/A]) )),
    forall(( member(T, Ts), T \= (:- _), T \= #(_) ), ( swi_clause(T, C), assertz(Mod:C) )).

swi_clause((H :- B), (H1 :- B1)) :- !, swi_lit(H, H1), swi_body(B, B1).
swi_clause(H, H1) :- swi_lit(H, H1).

swi_body(V, V) :- var(V), !.
swi_body((A, B), (A1, B1)) :- !, swi_body(A, A1), swi_body(B, B1).
swi_body((A ; B), (A1 ; B1)) :- !, swi_body(A, A1), swi_body(B, B1).
swi_body(not(G), \+ G1) :- !, swi_body(G, G1).
swi_body(G, G1) :- swi_lit(G, G1).

% -p(...) becomes the separate predicate '-p'(...).
swi_lit(-G, G1) :- callable(G), !, G =.. [N|As], atom_concat('-', N, N1), G1 =.. [N1|As].
swi_lit(G, G).

swi_answers(Mod, Goal, Names, Res) :-
    swi_body(Goal, G),
    catch(call_with_time_limit(10, findall(Names, limit(1000, Mod:G), Sols)), E, true),
    (   nonvar(E) -> Res = error(E)
    ;   result(Sols, Res)
    ).

% --- s(CASP) engine ---
scasp_answers(File, Goal, Names, Res) :-
    query_text(Goal, Names, Q),
    atom_concat('--query=', Q, QArg),
    forall_flag(Flag),
    process_create(path(timeout),
                   ['30', scasp, '--unknown=error', Flag, '-s', '0',
                    '--json=-', '--width=0', QArg, File],
                   [stdout(pipe(Out)), stderr(pipe(Err)), process(Pid)]),
    read_string(Out, _, OutS), read_string(Err, _, ErrS),
    close(Out), close(Err),
    process_wait(Pid, Status),
    split_string(ErrS, "\n", "", ErrLines0),
    exclude([L]>>( L == "" ; sub_string(L, _, _, _, "No models") ), ErrLines0, ErrLines),
    (   Status \== exit(0) -> Res = error(Status-ErrS)
    ;   ErrLines \== [] -> Res = error(stderr-ErrS)
    ;   catch(( atom_json_dict(OutS, J, []), scasp_result(J, Names, Res) ), E,
              Res = error(json-E))
    ).

scasp_result(J, Names, Res) :-
    get_dict(answers, J, Answers),
    maplist(scasp_solution(Names), Answers, Sols),
    result(Sols, Res).

scasp_solution(Names, Answer, Sol) :-
    get_dict(bindings, Answer, Bs),
    maplist(scasp_binding(Bs), Names, Sol).

scasp_binding(Bs, N=_, N=V) :-
    (   get_dict(N, Bs, B) -> get_dict(value, B, J), json_term(J, V)
    ;   true                          % no binding: V stays a variable
    ).

json_term(L, T) :- is_list(L), !, maplist(json_term, L, T).
json_term(D, T) :- get_dict(type, D, S), atom_string(Type, S), json_typed(Type, D, T).
json_typed(atom, D, T) :- get_dict(value, D, S), atom_string(T, S).
json_typed(rational, D, T) :-
    get_dict(numerator, D, N), get_dict(denominator, D, M),
    ( M =:= 1 -> T = N ; T is N rdiv M ).
json_typed(integer, D, V) :- get_dict(value, D, V).
json_typed(float, D, V) :- get_dict(value, D, V).
json_typed(var, _, _).
json_typed(compound, D, T) :-
    get_dict(functor, D, S), atom_string(F, S),
    get_dict(args, D, Js), maplist(json_term, Js, As), T =.. [F|As].

% The goal as s(CASP) query text. Each _ gets a name, because s(CASP) 1.1.4
% fails with --json when the query holds an anonymous variable.
query_text(Goal, Names, Text) :-
    copy_term(Goal-Names, G-Ns),
    maplist([N=V]>>(V = '$VAR'(N)), Ns),
    term_variables(G, Anon),
    foldl([V, I0, I]>>( I is I0 + 1, format(atom(N), '_A~d', [I]), V = '$VAR'(N) ), Anon, 0, _),
    with_output_to(atom(Text),
        write_term(G, [quoted(true), numbervars(true), module(scasp_syntax), spacing(next_argument)])).

% --- results ---
% A result is none, true, answers(SortedBindingAtoms), nonground(...), or error(...).
result([], none) :- !.
result(Sols, Res) :-
    maplist(binding_atom, Sols, As), sort(As, Set),
    (   \+ maplist(ground, Sols) -> Res = nonground(Set)
    ;   Set == [true] -> Res = true
    ;   Res = answers(Set)
    ).

binding_atom([], true) :- !.
binding_atom(Pairs, A) :-
    maplist([N=V, S]>>format(atom(S), '~w = ~q', [N, V]), Pairs, Ss),
    atomic_list_concat(Ss, ', ', A).

want(true, true).
want(none, none).
want(L, answers(S)) :- is_list(L), sort(L, S).

run_expect(Mod, File, GoalAtom, Want0) :-
    term_to_atom_ops(GoalAtom, Goal, Names0),
    exclude([N=_]>>sub_atom(N, 0, 1, _, '_'), Names0, Names),
    want(Want0, Want),
    swi_answers(Mod, Goal, Names, Swi),
    get_time(T0),
    scasp_answers(File, Goal, Names, Sc),
    get_time(T1), Secs is T1 - T0,
    cur_variant(VN), format(atom(TG), '~w: ~w', [VN, GoalAtom]), assertz(timing(TG, Secs)),
    verdict(swi, Swi, Want, V1),
    verdict(scasp, Sc, Want, V2),
    format("  ~w ~w  swi ~w  scasp ~w  (~2f s)~n", [GoalAtom, Want0, V1, V2, Secs]),
    ( V1 == 'PASS' -> true ; format("      swi:   ~q~n", [Swi]) ),
    ( V2 == 'PASS' -> true ; format("      scasp: ~q~n", [Sc]) ),
    (   agree(Swi, Sc) -> true
    ;   count(disagree),
        format("  ENGINE DISAGREEMENT on ~w~n      swi:   ~q~n      scasp: ~q~n", [GoalAtom, Swi, Sc])
    ).

term_to_atom_ops(A, T, Names) :-
    term_string(T, A, [variable_names(Names), module(scasp_syntax)]).

verdict(Engine, Got, Want, V) :-
    atom_concat(pass_, Engine, P), atom_concat(fail_, Engine, F),
    (   Got == Want -> V = 'PASS', count(P)
    ;   V = 'FAIL', count(F)
    ).

% Existence must agree. With ground answers, the answer sets must agree too.
agree(R1, R2) :- R1 == R2, !.
agree(R1, R2) :- exists(R1), exists(R2), ( R1 = nonground(_) ; R2 = nonground(_) ), !.
exists(true).
exists(answers(_)).
exists(nonground(_)).

% --- lint ---
lint_variant(Name, Dir, Lib, Kb) :-
    lint(Dir, Lib, Kb, Issues),
    length(Issues, N),
    (   N =:= 0 -> format("  lint: clean~n", [])
    ;   format("  lint: ~d issue(s)~n", [N]),
        forall(member(C-M, Issues),
               ( format("    ~w ~w~n", [C, M]),
                 ( ( sub_atom(C, 0, 1, _, 'E') ; Name == base ) -> count(lint_fail) ; true ) ))
    ).

% --- counters and summary ---
count(K) :- flag(K, N, N + 1).

summary(Exp, Status) :-
    aggregate_all(count, member(expect(_, _, _), Exp), Total),
    maplist([K, V]>>flag(K, V, V), [pass_swi, pass_scasp, disagree, lint_fail, h4_fail],
            [Ps, Pc, D, L, H]),
    format("~nSWI engine:     ~d/~d expectations passed~n", [Ps, Total]),
    format("s(CASP) engine: ~d/~d expectations passed~n", [Pc, Total]),
    format("Engine disagreements: ~d~n", [D]),
    format("Lint failures (E codes in any variant, any code in base): ~d~n", [L]),
    format("H4 self-check failures (variants with _<digits> atoms): ~d~n", [H]),
    findall(T-G, timing(G, T), Ts0), msort(Ts0, Ts1), reverse(Ts1, Ts),
    (   Ts = [Max-_|_]
    ->  format("s(CASP) time per query: max ~2f s. Slowest:~n", [Max]),
        forall(( nth1(I, Ts, T-G), I =< 5 ), format("  ~2f s  ~w~n", [T, G]))
    ;   true
    ),
    (   Ps =:= Total, Pc =:= Total, D =:= 0, L =:= 0, H =:= 0 -> Status = 0 ; Status = 1 ).

% --- reading ---
read_terms(File, Terms) :-
    setup_call_cleanup(open(File, read, S), read_all(S, Terms), close(S)).
read_all(S, Terms) :-
    read_term(S, T, [module(scasp_syntax)]),
    (   T == end_of_file -> Terms = []
    ;   Terms = [T|Rest], read_all(S, Rest)
    ).

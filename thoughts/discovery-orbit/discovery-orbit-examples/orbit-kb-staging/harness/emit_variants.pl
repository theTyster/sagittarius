% emit_variants.pl: write each variant of a fixture as a KB directory for the real CLI.
%
% Usage: swipl harness/emit_variants.pl FIXTURE_DIR OUT_DIR
% For the base variant and each variant(Name, Edits) in FIXTURE_DIR/expected.pl:
%   OUT_DIR/Name/        a copy of FIXTURE_DIR without expected.pl;
%   OUT_DIR/Name/kb.pl   the kb.pl terms after the edits (comments are not kept);
%   OUT_DIR/Name.tsv     one line per expectation: GOAL<TAB>ANSWERS, where ANSWERS is
%                        true, none, or the binding atoms joined by |.
% The edits work as in run.pl: delete(T), replace(Old, New), add(T), matched by ==.

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(filesex)).

:- initialization(main, main).

:- op(900, fy, scasp_syntax:not).
:- op(950, xfx, scasp_syntax:(::)).
:- op(1200, fx, scasp_syntax:(#)).
:- op(1150, fx, scasp_syntax:[table, show, pred]).
:- op(350, fx, scasp_syntax:[include, compute, abducible]).
:- op(700, xfx, scasp_syntax:[#=, #<>, #<, #>, #=<, #>=]).

main([Fix0, Out0]) :-
    absolute_file_name(Fix0, Fix), absolute_file_name(Out0, Out),
    directory_file_path(Fix, 'kb.pl', KbFile),
    directory_file_path(Fix, 'expected.pl', ExpFile),
    read_terms(KbFile, Kb),
    read_terms(ExpFile, Exp),
    findall(N-E, member(variant(N, E), Exp), Vs),
    make_directory_path(Out),
    forall(member(Name-Edits, [base-[]|Vs]), emit(Fix, Out, Kb, Exp, Name, Edits)),
    length(Vs, NV), format("emitted base and ~d variants to ~w~n", [NV, Out]).

emit(Fix, Out, Kb0, Exp, Name, Edits) :-
    foldl(apply_edit(Name), Edits, Kb0, Kb),
    directory_file_path(Out, Name, Dir),
    copy_directory(Fix, Dir),
    directory_file_path(Dir, 'expected.pl', E), delete_file(E),
    directory_file_path(Dir, 'kb.pl', K),
    setup_call_cleanup(open(K, write, S),
        forall(member(T, Kb),
               write_term(S, T, [quoted(true), fullstop(true), nl(true),
                                 spacing(next_argument), module(scasp_syntax)])),
        close(S)),
    format(atom(Tsv), '~w/~w.tsv', [Out, Name]),
    setup_call_cleanup(open(Tsv, write, TS),
        forall(member(expect(Name, G, A), Exp),
               ( ( is_list(A) -> atomic_list_concat(A, '|', AT) ; AT = A ),
                 format(TS, "~w\t~w~n", [G, AT]) )),
        close(TS)).

apply_edit(_, delete(T), Ts0, Ts) :- !, one_match(T, Ts0), exclude(==(T), Ts0, Ts).
apply_edit(_, replace(Old, New), Ts0, Ts) :- !, one_match(Old, Ts0), maplist(swap(Old, New), Ts0, Ts).
apply_edit(_, add(T), Ts0, Ts) :- !, append(Ts0, [T], Ts).
apply_edit(Name, E, _, _) :- format(user_error, "variant ~w: unknown edit ~q~n", [Name, E]), halt(1).

swap(Old, New, X, Y) :- ( X == Old -> Y = New ; Y = X ).

one_match(T, Ts) :-
    include(==(T), Ts, Ms), length(Ms, N),
    (   N =:= 1 -> true
    ;   format(user_error, "~d kb.pl terms match ~q (want 1)~n", [N, T]), halt(1)
    ).

read_terms(File, Terms) :-
    setup_call_cleanup(open(File, read, S), read_all(S, Terms), close(S)).
read_all(S, Terms) :-
    read_term(S, T, [module(scasp_syntax)]),
    (   T == end_of_file -> Terms = []
    ;   Terms = [T|Rest], read_all(S, Rest)
    ).

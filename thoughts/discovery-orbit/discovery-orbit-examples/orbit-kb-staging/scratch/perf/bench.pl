% Scratch: time one s(CASP) query on several files.
% Usage: swipl bench.pl QUERY [--opt=X ...] FILE...   (options start with -)
:- use_module(library(process)).
:- use_module(library(readutil)).
:- use_module(library(apply)).
:- initialization(main, main).

main([Q|Rest]) :-
    partition([A]>>sub_atom(A, 0, 1, _, '-'), Rest, Opts, Files),
    forall(member(F, Files), run(Q, Opts, F)).

run(Q, Opts, F) :-
    atom_concat('--query=', Q, QA),
    append([['60', scasp, '--unknown=error', '--forall=prev', '-s', '1'], Opts, [QA, F]], Args),
    get_time(T0),
    process_create(path(timeout), Args, [stdout(pipe(O)), stderr(pipe(E)), process(P)]),
    read_string(O, _, OS), read_string(E, _, ES), close(O), close(E),
    process_wait(P, St), get_time(T1), D is T1 - T0,
    ( sub_string(ES, _, _, _, "No models") -> R = none
    ; sub_string(OS, _, _, _, "Answer 1") -> R = yes ; R = '?' ),
    format("~w ~w ~w ~w ~2f s~n", [F, Opts, St, R, D]).

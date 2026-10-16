% Scratch: run harness/lint.pl on builder C's fixtures (kb.pl only; rules.pl is ignored).
:- use_module('../harness/lint').
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(pairs)).
:- initialization(main, main).

:- op(900, fy, scasp_syntax:not).
:- op(950, xfx, scasp_syntax:(::)).
:- op(1200, fx, scasp_syntax:(#)).
:- op(1150, fx, scasp_syntax:[table, show, pred]).
:- op(350, fx, scasp_syntax:[include, compute, abducible]).
:- op(700, xfx, scasp_syntax:[#=, #<>, #<, #>, #=<, #>=]).

lib('/home/ty/.dotfiles/shared/link/.local/share/orbit-kb').
fixtures('/home/ty/.dotfiles/scripts/orbit-kb/fixtures').

main :-
    fixtures(Root), directory_files(Root, Es0), msort(Es0, Es),
    forall(( member(E, Es), E \== '.', E \== '..' ), check(Root, E)).

check(Root, Name) :-
    directory_file_path(Root, Name, Dir),
    directory_file_path(Dir, 'kb.pl', Kb),
    catch(( read_terms(Kb, Ts), lib_for(Ts, Lib), lint(Dir, Lib, Ts, Issues),
            pairs_keys(Issues, Codes), format("~w: ~w~n", [Name, Codes]) ),
          Err, ( format("~w: error ~q~n", [Name, Err]) )).

lib_for(Ts, Lib) :-
    ( Ts = [uses(Mods)|_] -> true ; Mods = [] ),
    lib(L),
    findall(F, ( F = 'core.pl' ; member(M, Mods), format(atom(F), 'modules/~w.pl', [M]) ), Fs),
    findall(F-T, ( member(F, Fs), directory_file_path(L, F, P), exists_file(P),
                   read_terms(P, PTs), member(T, PTs) ), Lib).

read_terms(File, Terms) :-
    setup_call_cleanup(open(File, read, S), read_all(S, Terms), close(S)).
read_all(S, Terms) :-
    read_term(S, T, [module(scasp_syntax)]),
    (   T == end_of_file -> Terms = []
    ;   Terms = [T|Rest], read_all(S, Rest)
    ).

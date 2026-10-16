% gen_mutants.pl: write mutants of a discovery module, one file per mutant.
% Usage: swipl mut/gen_mutants.pl MODULE OUTDIR
% Operators: (1) delete one rule clause; (2) delete one body literal of a clause with
% two or more body literals; (3) drop the not of one negated literal.
% OUTDIR/index.txt gets one line per mutant: Id<TAB>Operator<TAB>Clause<TAB>Literal.

:- initialization(main, main).

:- op(900, fy, scasp_syntax:not).
:- op(950, xfx, scasp_syntax:(::)).
:- op(1200, fx, scasp_syntax:(#)).
:- op(1150, fx, scasp_syntax:[table, show, pred]).
:- op(350, fx, scasp_syntax:[include, compute, abducible]).
:- op(700, xfx, scasp_syntax:[#=, #<>, #<, #>, #=<, #>=]).

main([Module, OutDir]) :-
    read_terms(Module, Ts),
    length(Ts, _),
    findall(I-T, nth1(I, Ts, T), ITs),
    findall(M, mutant(ITs, M), Ms),
    directory_file_path(OutDir, 'index.txt', Index),
    setup_call_cleanup(open(Index, write, IS),
        forall(nth1(N, Ms, mut(Op, CI, LitDesc, NewTs)),
               ( format(atom(F), '~w/m~|~`0t~d~3+.pl', [OutDir, N]),
                 write_module(F, NewTs),
                 nth1(CI, Ts, Orig), clause_desc(Orig, CD),
                 format(IS, "m~|~`0t~d~3+\t~w\t~w\t~w~n", [N, Op, CD, LitDesc]) )),
        close(IS)),
    length(Ms, Count),
    format("wrote ~d mutants~n", [Count]).

rule_clause(T) :- T = (_ :- _).

mutant(ITs, mut(delete_clause, I, '-', New)) :-
    member(I-T, ITs), rule_clause(T),
    exclude([J-_]>>(J == I), ITs, Rest), pairs_values(Rest, New).
mutant(ITs, mut(delete_literal, I, LD, New)) :-
    member(I-(H :- B), ITs),
    lits(B, Ls), length(Ls, Len), Len >= 2,
    nth1(K, Ls, L, Others),
    lit_desc(H-B, L, LD0), format(atom(LD), '~w (#~d)', [LD0, K]),
    list_body(Others, B1),
    replace_at(ITs, I, (H :- B1), New).
mutant(ITs, mut(drop_not, I, LD, New)) :-
    member(I-(H :- B), ITs),
    lits(B, Ls),
    nth1(K, Ls, not(G), _),
    lit_desc(H-B, not(G), LD0), format(atom(LD), '~w (#~d)', [LD0, K]),
    nth1(K, Ls, _, Rest0), nth1(K, Ls1, G, Rest0),
    list_body(Ls1, B1),
    replace_at(ITs, I, (H :- B1), New).

replace_at(ITs, I, NewT, New) :-
    findall(T1, ( member(J-T, ITs), ( J == I -> T1 = NewT ; T1 = T ) ), New).

lits((A, B), Ls) :- !, lits(A, L1), lits(B, L2), append(L1, L2, Ls).
lits(G, [G]).
list_body([G], G) :- !.
list_body([G|Gs], (G, B)) :- list_body(Gs, B).

clause_desc(T, D) :-
    copy_term(T, T1), numbervars(T1, 0, _, [singletons(true)]),
    with_output_to(atom(D0), write_term(T1, [quoted(true), numbervars(true), module(scasp_syntax)])),
    ( atom_length(D0, Len), Len > 110 -> sub_atom(D0, 0, 110, _, D1), atom_concat(D1, '...', D) ; D = D0 ).
lit_desc(Ctx, L, D) :-
    copy_term(Ctx-L, _-L1), numbervars(L1, 0, _, [singletons(true)]),
    with_output_to(atom(D), write_term(L1, [quoted(true), numbervars(true), module(scasp_syntax)])).

write_module(F, Ts) :-
    setup_call_cleanup(open(F, write, S),
        forall(member(T, Ts),
               ( copy_term(T, T1), numbervars(T1, 0, _, [singletons(true)]),
                 write_term(S, T1, [quoted(true), numbervars(true), module(scasp_syntax),
                                    spacing(next_argument)]),
                 format(S, ".~n", []) )),
        close(S)).

read_terms(File, Terms) :-
    setup_call_cleanup(open(File, read, S), read_all(S, Terms), close(S)).
read_all(S, Terms) :-
    read_term(S, T, [module(scasp_syntax)]),
    (   T == end_of_file -> Terms = []
    ;   Terms = [T|Rest], read_all(S, Rest)
    ).

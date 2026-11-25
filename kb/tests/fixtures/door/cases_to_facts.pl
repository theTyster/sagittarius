% cases_to_facts.pl: write each case of purpose_cases.pl as hub facts (the names of hub.pl) in
% OUT/caseN.pl, and what it expects in OUT/caseN.expect (one goal per line; "not GOAL" must have
% no answer). Usage: swipl -q cases_to_facts.pl -- purpose_cases.pl OUT
:- initialization(main, main).
:- dynamic case/3.
main([File, Out]) :-
    open(File, read, S), rd(S), close(S),
    findall(N-F-E, case(N, F, E), Cs),
    forall(nth1(I, Cs, N-F-E), one(Out, I, N, F, E)),
    length(Cs, Len), format("~d~n", [Len]).
rd(S) :- read_term(S, T, []), ( T == end_of_file -> true ; ( T = case(_, _, _) -> assertz(T) ; true ), rd(S) ).
one(Out, I, Name, Fs, Es) :-
    format(atom(FF), "~w/case~d.pl", [Out, I]), format(atom(EF), "~w/case~d.expect", [Out, I]),
    open(FF, write, S1), format(S1, "% ~w~n", [Name]),
    forall(( member(F, Fs), tr(Fs, F, T) ), format(S1, "~q.~n", [T])), close(S1),
    open(EF, write, S2), format(S2, "# ~w~n", [Name]),
    forall(member(E, Es), ( E = not(G) -> ex(G, G2), wr(S2, "not ", G2) ; ex(E, E2), wr(S2, "", E2) )), close(S2).
wr(S, Pre, G) :- format(S, "~w", [Pre]), write_term(S, G, [quoted(true), numbervars(true)]), nl(S).
tr(_, item(I, K, St, O), item(I, K, St, 'a title', O)).
tr(_, ref(I, K, R), item_ref(I, K, R)).
tr(_, link(A, K, B), item_link(A, K, B)).
tr(_, ticket(T), ticket(T, T)).
tr(_, ticket_goal(T, G), ticket_fact(T, goal(G, feature, human, 'a goal'))).
tr(_, ticket_done(T), ticket_fact(T, done)).
tr(Fs, supports(G, P), ticket_fact(T, supports(G, project(P)))) :- member(ticket_goal(T, G), Fs).
tr(_, project_goal(P), project_fact(goal(P, feature, human, 'a project goal'))).
tr(_, serves(I, P), item_ref(I, goal, P)).
tr(_, dropped_goal(P), project_fact(dropped(P, human, '2026-11-20T00:00:00Z', 'dropped'))).
tr(_, ticket_dropped(T), ticket_fact(T, gate(no_go))).
tr(_, item_opened(I, D), item_opened(I, D)).
tr(_, ticket_done_at(T, D), ticket_done_at(T, D)).
tr(_, work_ended(I), work_ended(I)).
% the expectations use the names of the model; the hub rules have the same names
ex((A, B), (A2, B2)) :- !, ex(A, A2), ex(B, B2).
ex(G, G) :- numbervars(G, 0, _).

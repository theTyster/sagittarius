% gen_mutants_ext.pl: extra mutation operators for the discovery module (LANDING review).
% Usage: swipl mut/tools/gen_mutants_ext.pl -- MODULE OUTDIR
% (The -- matters: SWI 9 loads a trailing *.pl argument as a source file.)
% Operators, in addition to scratch/review/mut/gen_mutants.pl:
%   (4) delete_fact   delete one module fact clause (not decl/attest_type)
%   (5) break_join    replace one occurrence of a shared variable in a body literal
%                     (top-level argument or one level deeper) with a fresh variable
%   (6) swap_const    replace one domain constant in a body literal or fact with its
%                     neighbour (sat<->unsat, system<->model, matches<->differs, ...)
%   (7) severity      swap a lint code between E and W ('ED3' <-> 'WD3')
%   (8) hand          hand-written mutants that undo a REVIEW.md fix
% OUTDIR/index.txt: Id<TAB>Operator<TAB>Clause<TAB>Detail, ids x001...

:- initialization(main, main).
:- op(900, fy, not).   % for the hand/3 clauses in this file
:- discontiguous mutant/2.

:- op(900, fy, scasp_syntax:not).
:- op(950, xfx, scasp_syntax:(::)).
:- op(1200, fx, scasp_syntax:(#)).
:- op(1150, fx, scasp_syntax:[table, show, pred]).
:- op(350, fx, scasp_syntax:[include, compute, abducible]).
:- op(700, xfx, scasp_syntax:[#=, #<>, #<, #>, #=<, #>=]).

main([Module, OutDir]) :-
    read_terms(Module, Ts),
    findall(I-T, nth1(I, Ts, T), ITs),
    findall(M, mutant(ITs, M), Ms0),
    % drop mutants identical to the original or to an earlier mutant
    dedup(Ms0, Ts, Ms),
    directory_file_path(OutDir, 'index.txt', Index),
    setup_call_cleanup(open(Index, write, IS),
        forall(nth1(N, Ms, mut(Op, CI, Desc, NewTs)),
               ( format(atom(F), '~w/x~|~`0t~d~3+.pl', [OutDir, N]),
                 write_module(F, NewTs),
                 ( CI > 0 -> nth1(CI, Ts, Orig), clause_desc(Orig, CD) ; CD = '-' ),
                 format(IS, "x~|~`0t~d~3+\t~w\t~w\t~w~n", [N, Op, CD, Desc]) )),
        close(IS)),
    length(Ms, Count),
    format("wrote ~d mutants~n", [Count]).

dedup(Ms0, Ts, Ms) :- dedup_(Ms0, [Ts], Ms).
dedup_([], _, []).
dedup_([M|R], Seen, Out) :-
    M = mut(_, _, _, New),
    (   member(S, Seen), S =@= New -> Out = Out1, Seen1 = Seen
    ;   Out = [M|Out1], Seen1 = [New|Seen]
    ),
    dedup_(R, Seen1, Out1).

meta(decl(_, _, _, _)).
meta(attest_type(_, _, _, _)).

% (4) delete a module fact
mutant(ITs, mut(delete_fact, I, '-', New)) :-
    member(I-T, ITs), T \= (_ :- _), \+ meta(T),
    exclude([J-_]>>(J == I), ITs, Rest), pairs_values(Rest, New).

% (5) break a join
mutant(ITs, mut(break_join, I, Desc, New)) :-
    member(I-(H :- B), ITs),
    lits(B, Ls),
    nth1(K, Ls, L),
    unwrap(L, G, Wrap),
    G =.. [F|Args],
    nth1(P, Args, A),
    occurrence(A, V, Path, A1, Fresh),
    var(V), Fresh = '$FRESH',
    % V must occur elsewhere in the clause
    count_occ(V, (H :- B), N), N >= 2,
    nth1(P, Args, _, RestArgs), nth1(P, Args1, A1, RestArgs),
    G1 =.. [F|Args1],
    rewrap(Wrap, G1, L1),
    replace_fresh(L1, L2),
    nth1(K, Ls, _, Others), nth1(K, Ls2, L2, Others),
    list_body(Ls2, B1),
    format(atom(Desc), 'literal #~d ~w arg ~d~w', [K, F, P, Path]),
    replace_at(ITs, I, (H :- B1), New).

% occurrence(+Arg, -Var, -PathDesc, -NewArg, -FreshMarker): Arg itself is the variable,
% or a variable one level inside a compound Arg.
occurrence(A, A, '', '$FRESH', '$FRESH') :- var(A).
occurrence(A, V, Path, A1, '$FRESH') :-
    compound(A), A =.. [F|Xs], nth1(Q, Xs, V), var(V),
    nth1(Q, Xs, _, R), nth1(Q, Xs1, '$FRESH', R), A1 =.. [F|Xs1],
    format(atom(Path), '.~w/~d', [F, Q]).

replace_fresh(T, T1) :- T == '$FRESH', !, T1 = _.
replace_fresh(T, T) :- var(T), !.
replace_fresh(T, T1) :- compound(T), !, T =.. [F|As], maplist(replace_fresh, As, As1), T1 =.. [F|As1].
replace_fresh(T, T).

count_occ(V, T, N) :- findall(x, (sub_term(S, T), S == V), Xs), length(Xs, N).

unwrap(not(G), G, not) :- !.
unwrap(G, G, none).
rewrap(not, G, not(G)).
rewrap(none, G, G).

% (6) swap a domain constant
swap(sat, unsat). swap(unsat, sat). swap(unknown, sat). swap(reached, holds).
swap(violated, holds). swap(holds, unsat).
swap(system, model). swap(model, system).
swap(matches, differs). swap(differs, matches).
swap(killed, survived). swap(survived, killed).
swap(reproduced, not_reproduced). swap(not_reproduced, reproduced).
swap(introduce, preserve).
swap(sanity, bad_case). swap(bad_case, sanity).
swap(reproduction, model_result). swap(model_result, reproduction).
swap(divergence, disproof). swap(disproof, divergence). swap(test_result, reproduction).
swap(laps, other).

mutant(ITs, mut(swap_const, I, Desc, New)) :-
    member(I-T, ITs), \+ meta(T),
    (   T = (H :- B) -> lits(B, Ls), nth1(K, Ls, L), unwrap(L, G, Wrap),
        swap_in(G, G1, From, To),
        rewrap(Wrap, G1, L1), nth1(K, Ls, _, Others), nth1(K, Ls2, L1, Others),
        list_body(Ls2, B1), T1 = (H :- B1),
        format(atom(Desc), 'literal #~d: ~w -> ~w', [K, From, To])
    ;   T \= (_ :- _), swap_in(T, T1, From, To),
        format(atom(Desc), 'fact: ~w -> ~w', [From, To])
    ),
    replace_at(ITs, I, T1, New).

% swap one constant at depth 1 or 2
swap_in(G, G1, From, To) :-
    compound(G), G =.. [F|As], nth1(P, As, A),
    (   atom(A), swap(A, To), From = A, A1 = To
    ;   compound(A), A =.. [F2|Bs], nth1(Q, Bs, Bq), atom(Bq), swap(Bq, To), From = Bq,
        nth1(Q, Bs, _, RB), nth1(Q, Bs1, To, RB), A1 =.. [F2|Bs1]
    ),
    nth1(P, As, _, R), nth1(P, As1, A1, R), G1 =.. [F|As1].

% (7) lint severity
mutant(ITs, mut(severity, I, Desc, New)) :-
    member(I-(lint_issue(Code, Id, Msg) :- B), ITs),
    atom_codes(Code, [C1|Rest]),
    ( C1 == 0'E -> C2 = 0'W ; C1 == 0'W -> C2 = 0'E ),
    atom_codes(Code2, [C2|Rest]),
    format(atom(Desc), '~w -> ~w', [Code, Code2]),
    replace_at(ITs, I, (lint_issue(Code2, Id, Msg) :- B), New).

% (8) hand-written mutants: each undoes one REVIEW.md fix or widens one key.
hand('h_verdict_any_digest (finding 3)',
     (model_verdict(A, M, K, R) :- attest(A, model_result, S, verdict(M, K, R), _, _), model_run_current(S, M)),
     (model_verdict(A, M, K, R) :- attest(A, model_result, S, verdict(M, K, R), _, _), model_run_of(S, M))).
hand('h_calibration_any_digest (finding 3)',
     (model_calibration(A, M, R) :- attest(A, model_result, S, calibration(M, _, R), _, _), model_run_current(S, M)),
     (model_calibration(A, M, R) :- attest(A, model_result, S, calibration(M, _, R), _, _), model_run_of(S, M))).
hand('h_mutation_any_digest (finding 3)',
     (model_mutation(A, M, Rule, R) :- attest(A, model_result, S, mutation(M, Rule, R), _, _), model_run_current(S, M)),
     (model_mutation(A, M, Rule, R) :- attest(A, model_result, S, mutation(M, Rule, R), _, _), model_run_of(S, M))).
hand('h_divergence_any_subject',
     (model_diverges(M) :- attest(_, divergence, S, model(M), _, _), model_run_current(S, M)),
     (model_diverges(M) :- attest(_, divergence, _, model(M), _, _))).
hand('h_unratified_any_old (finding 7 widened)',
     (discovery_unratified(New) :- supersedes(New, Old), refuted(Old), not discovery_ratified(Old), not discovery_ratified(New)),
     (discovery_unratified(New) :- supersedes(New, Old), not discovery_ratified(Old), not discovery_ratified(New))).
% Same widening for module 20db37fb (F3: discovery_disputed/1).
hand('h_unratified_any_old (finding 7 widened, F3 form)',
     (discovery_unratified(New) :- supersedes(New, Old), discovery_disputed(Old), not discovery_ratified(Old), not discovery_ratified(New)),
     (discovery_unratified(New) :- supersedes(New, Old), not discovery_ratified(Old), not discovery_ratified(New))).
% F2: drop the old-run guard (equals a delete_literal mutant; kept for the name).
hand('h_old_run_ignored (F2 undone)',
     (model_run_current(S, M) :- model_run(S, M, D), subject(M, _, D), not discovery_old_run(S, M)),
     (model_run_current(S, M) :- model_run(S, M, D), subject(M, _, D))).
hand('h_disproof_refuted_only',
     (discovery_disproof_filed(C) :- attest(_, disproof, _, verdict(C, _), _, _)),
     (discovery_disproof_filed(C) :- attest(_, disproof, _, verdict(C, refuted), _, _))).
hand('h_budget_ge',
     (budget_spent :- budget(laps, B), lap_done(B), not discovery_budget_raised(B)),
     (budget_spent :- budget(laps, B), lap_done(L), L >= B, not discovery_budget_raised(B))).
hand('h_budget_first (finding 6, P13)',
     (budget_spent :- budget(laps, B), lap_done(B), not discovery_budget_raised(B)),
     (budget_spent :- budget(laps, B), lap_done(B))).
hand('h_outcome_any (finding 5)',
     (discovery_has_outcome :- current(_)),
     (discovery_has_outcome :- true)).
hand('h_touch_any_subject (finding 4)',
     (touched_system :- attest(_, reproduction, S, _, _, _), discovery_system_evidence(S)),
     (touched_system :- attest(_, reproduction, _, _, _, _))).
hand('h_confirm_any_subject (finding 4)',
     (finding_confirmed(F) :- attest(_, reproduction, S, confirms(F), _, _), discovery_system_evidence(S)),
     (finding_confirmed(F) :- attest(_, reproduction, _, confirms(F), _, _))).
hand('h_reason_by_rule (finding 12)',
     (rule_has_reason(M, R) :- reason(M, R, _)),
     (rule_has_reason(_, R) :- reason(_, R, _))).
hand('h_trust_falsifier_any_model (finding 11 m047)',
     (has_falsifier(C) :- encodes(M, C), model_decided(M, C), model_trusted(M)),
     (has_falsifier(C) :- encodes(M, C), model_decided(M, C), model_trusted(_))).
hand('h_breaks_preserve_any_check',
     (model_breaks(M, C) :- model_verdict(_, M, preserve(C), R), discovery_has_case(R)),
     (model_breaks(M, C) :- model_verdict(_, M, preserve(C), R), discovery_decided(R))).
hand('h_vacuous_any_check',
     (model_vacuous(A) :- model_verdict(A, _, applies(_), R), discovery_no_case(R)),
     (model_vacuous(A) :- model_verdict(A, _, _, R), discovery_no_case(R))).
hand('h_derived_no_existing_bad_case',
     (model_diverges(M) :- model_verdict(_, M, bad_case, R), discovery_no_case(R), not model_is_derived(M)),
     (model_diverges(M) :- model_verdict(_, M, bad_case, R), discovery_no_case(R))).
hand('h_ed8_hyp_not_allowed',
     (lint_issue('ED8', Q, T) :- raised_by(Q, X), not discovery_is_finding(X), not discovery_is_hypothesis(X)),
     (lint_issue('ED8', Q, T) :- raised_by(Q, X), not discovery_is_finding(X))).
hand('h_ready_no_hypothesis_needed (finding 5)',
     (discovery_ready :- some_hypothesis, touched_system, discovery_has_outcome, not some_untouched_hypothesis, not some_no_falsifier, not some_question_waits, not some_unasked_finding, not some_current_refuted, not some_weak_rule, not some_model_problem, not some_unratified_supersession, not any_to_ask),
     (discovery_ready :- touched_system, not some_untouched_hypothesis, not some_no_falsifier, not some_question_waits, not some_unasked_finding, not some_current_refuted, not some_weak_rule, not some_model_problem, not some_unratified_supersession, not any_to_ask)).

mutant(ITs, mut(hand, I, Name, New)) :-
    hand(Name, Old, NewC),
    once(hand_match(ITs, Old, NewC, I, NewC1)),
    replace_at(ITs, I, NewC1, New).

% A lint_issue clause matches with any message text.
hand_match(ITs, Old, NewC, I, N2) :-
    copy_term(Old-NewC, O2-N2),
    member(I-T, ITs),
    (   O2 = (lint_issue(_, _, Msg) :- _), var(Msg), T = (lint_issue(_, _, Msg) :- _) -> true
    ;   true
    ),
    T =@= O2.

% --- helpers (as in gen_mutants.pl) ---
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

% decls.pl: declaration checks across core, build, and the staged discovery module.
% Usage: swipl checks/decls.pl -- CORE BUILD DISCOVERY
:- initialization(main, main).
:- op(900, fy, scasp_syntax:not).
:- op(950, xfx, scasp_syntax:(::)).
:- op(1200, fx, scasp_syntax:(#)).
:- op(1150, fx, scasp_syntax:[table, show, pred]).
:- op(350, fx, scasp_syntax:[include, compute, abducible]).
:- op(700, xfx, scasp_syntax:[#=, #<>, #<, #>, #=<, #>=]).

% Contract v2.1, "Core vocabulary": names that discovery reserves.
reserved(hypothesis/3). reserved(budget/2). reserved(lap_done/1). reserved(model/2).
reserved(derived_from/2). reserved(encodes/2). reserved(finding/3). reserved(reason/2).
reserved(raised_by/2).
reserved(model_sane/1). reserved(model_calibrated/1). reserved(model_trusted/1).
reserved(has_falsifier/1). reserved(no_falsifier/1). reserved(needs_question/1).
reserved(has_question/1). reserved(unasked_finding/1). reserved(question_waits/1).
reserved(about_system/1). reserved(finding_confirmed/1). reserved(finding_lead/1).
reserved(rule_has_reason/1). reserved(weak_rule/1). reserved(touched_system/0).
reserved(budget_spent/0). reserved(discovery_ready/0).
reserved(N/0) :- atom(N), sub_atom(N, 0, _, _, some_).
reserved_type(reproduction). reserved_type(model_result). reserved_type(calibration).
reserved_type(decision).

main([Core, Build, Disc]) :-
    maplist(read_terms, [Core, Build, Disc], [TC, TB, TD]),
    findall(F-PI-K, ( member(F-Ts, [core-TC, build-TB, discovery-TD]), member(decl(K, H, _, _), Ts),
                      functor(H, N, A), PI = N/A ), Ds),
    length(Ds, ND), format("declarations: ~d~n", [ND]),
    findall(PI, ( member(_-PI-_, Ds) ), PIs), msort(PIs, S),
    findall(PI, ( append(_, [PI, PI2|_], S), PI == PI2 ), Dups),
    format("duplicate declarations: ~q~n", [Dups]),
    findall(PI-K, ( member(discovery-PI-K, Ds), \+ reserved(PI) ), Unreserved),
    format("discovery declarations outside the reserved list: ~q~n", [Unreserved]),
    findall(PI, ( reserved(PI), ground(PI), \+ member(discovery-PI-_, Ds) ), Missing),
    format("reserved names that discovery does not declare: ~q~n", [Missing]),
    findall(T, ( member(attest_type(T, _, _, _), TD) ), DT),
    findall(T, ( reserved_type(T), \+ memberchk(T, DT) ), MissingT),
    format("discovery attest types: ~q; reserved but undeclared: ~q~n", [DT, MissingT]),
    findall(PI, ( member(decl(rule, H, _, _), TD), functor(H, N, A), PI = N/A,
                  \+ ( member(C, TD), clause_head(C, CH), functor(CH, N, A) ) ), NoClauses),
    format("discovery rule predicates with no clauses: ~q~n", [NoClauses]),
    findall(PI, ( member(C, TD), clause_head(C, CH), C \= decl(_, _, _, _), C \= attest_type(_, _, _, _),
                  functor(CH, N, A), PI = N/A, member(discovery-PI-fact, Ds) ), FactClauses),
    format("discovery clauses for fact predicates: ~q~n", [FactClauses]).

clause_head((H :- _), H) :- !.
clause_head(H, H).

read_terms(File, Terms) :-
    setup_call_cleanup(open(File, read, S), read_all(S, Terms), close(S)).
read_all(S, Terms) :-
    read_term(S, T, [module(scasp_syntax)]),
    (   T == end_of_file -> Terms = []
    ;   Terms = [T|Rest], read_all(S, Rest)
    ).

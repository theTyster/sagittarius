% purpose_cases.pl: concrete cases for the rule of models/purpose.pl (claim c44).
% The first five broke the first version of the rule (DISPROVE, lap 4, evidence/disprove-a1.txt).
%
% Run:  swipl -q -g run_cases -t halt models/purpose.pl models/purpose_cases.pl
% Exit 1 when a case fails. Each case: a name, the facts of a small world, and what must be true.
% not(G) means that G must have no answer.

case('a dropped item passes no purpose on',
     [ item(n1, ask, open, me), item(d1, thread, dropped, me), link(n1, blocks, d1),
       ref(d1, kb, tk), ticket(tk), ticket_goal(tk, g), supports(g, pg), project_goal(pg) ],
     [ orphan(n1), ends_at(n1, a_dropped_item) ]).

case('a done item still passes its purpose on',
     [ item(n1, ask, open, me), item(d1, handoff, done, me), link(n1, follows, d1),
       ref(d1, kb, tk), ticket(tk), ticket_goal(tk, g), supports(g, pg), project_goal(pg) ],
     [ has_purpose(n1), not(orphan(n1)) ]).

case('a dropped project goal: each item under it is an orphan, and the goal is named',
     [ item(i1, thread, open, me), ref(i1, kb, tk), ticket(tk), ticket_goal(tk, g),
       item(i2, hold, open, me), serves(i2, pg),
       supports(g, pg), project_goal(pg), dropped_goal(pg) ],
     [ orphan(i1), ends_at(i1, a_dropped_project_goal), rests_on_dropped(i1, pg),
       orphan(i2), rests_on_dropped(i2, pg) ]).

case('a dropped ticket gives no purpose',
     [ item(i1, ask, open, me), ref(i1, kb, tk), ticket(tk), ticket_goal(tk, g),
       supports(g, pg), project_goal(pg), ticket_dropped(tk) ],
     [ orphan(i1), ends_at(i1, a_dropped_ticket) ]).

case('a row that was opened after its ticket was done reports on it: it is not over',
     [ item(r1, ask, open, me), ref(r1, kb, tk), ticket(tk), ticket_goal(tk, g), ticket_done(tk),
       ticket_done_at(tk, '2026-11-10'), item_opened(r1, '2026-11-20'),
       supports(g, pg), project_goal(pg) ],
     [ has_purpose(r1), report_on_done_ticket(r1), not(over(r1)) ]).

case('a row that was opened before its ticket was done is over',
     [ item(r0, handoff, open, me), ref(r0, kb, tk), ticket(tk), ticket_goal(tk, g), ticket_done(tk),
       ticket_done_at(tk, '2026-11-10'), item_opened(r0, '2026-11-01'),
       supports(g, pg), project_goal(pg) ],
     [ over(r0), not(report_on_done_ticket(r0)) ]).

case('a row with two tickets, one of them open, is not over',
     [ item(m1, ask, open, me), ref(m1, kb, t1), ref(m1, kb, t2), ticket(t1), ticket(t2),
       ticket_done(t1), ticket_goal(t2, g), supports(g, pg), project_goal(pg) ],
     [ has_purpose(m1), not(over(m1)) ]).

case('a row that says its work ended is over, whatever its ticket says',
     [ item(h1, handoff, open, me), ref(h1, kb, tk), ticket(tk), ticket_goal(tk, g),
       supports(g, pg), project_goal(pg), work_ended(h1) ],
     [ has_purpose(h1), over(h1) ]).

case('an item names its goal directly, with no ticket',
     [ item(k1, hold, open, me), serves(k1, pg), project_goal(pg) ],
     [ has_purpose(k1), not(orphan(k1)) ]).

case('a relates link passes no purpose on',
     [ item(a1, hold, open, me), item(a2, hold, open, me), link(a1, relates, a2),
       serves(a2, pg), project_goal(pg) ],
     [ orphan(a1), ends_at(a1, nothing), has_purpose(a2) ]).

case('a cycle of links ends, and gives no purpose',
     [ item(c1, thread, open, me), item(c2, thread, open, me),
       link(c1, blocks, c2), link(c2, blocks, c1) ],
     [ orphan(c1), orphan(c2), ends_at(c1, nothing) ]).

case('a link to an item that does not exist gives no purpose and no error',
     [ item(l1, ask, open, me), link(l1, blocks, nope) ],
     [ orphan(l1), ends_at(l1, nothing) ]).

case('a closed item is never an orphan',
     [ item(z1, ask, done, me), item(z2, thread, dropped, me) ],
     [ not(orphan(z1)), not(orphan(z2)) ]).

case('each orphan gets one answer to where its chain ends',
     [ item(i1, ask, open, me), ref(i1, kb, tk), ref(i1, url, 'https://example.org/1'),
       ticket(tk), ticket_goal(tk, g) ],
     [ ends_at(i1, ticket_goal), not(( ends_at(i1, E), E \== ticket_goal )) ]).

% ---- the runner -----------------------------------------------------------------------------
fact_kinds([item/4, ref/3, link/3, accepted/1, ticket/1, ticket_goal/2, ticket_done/1, supports/2,
            project_goal/1, serves/2, dropped_goal/1, ticket_dropped/1, item_opened/2,
            ticket_done_at/2, work_ended/1]).

run_cases :-
    findall(N, case(N, _, _), Names), length(Names, Total),
    foldl(run_case, Names, 0, Failed),
    Passed is Total - Failed,
    format("~d cases, ~d passed, ~d failed~n", [Total, Passed, Failed]),
    ( Failed =:= 0 -> true ; halt(1) ).

run_case(Name, F0, F) :-
    case(Name, Facts, Expected),
    clear_facts, maplist(assert_fact, Facts),
    findall(G, ( member(G, Expected), \+ holds(G) ), Wrong),
    (   Wrong == [] -> format("  ok    ~w~n", [Name]), F = F0
    ;   format("  FAIL  ~w~n        not as expected: ~w~n", [Name, Wrong]), F is F0 + 1
    ).

% A fact of a kind that the rule file does not know is still recorded: an old rule then ignores it.
assert_fact(Fact) :- functor(Fact, N, A), dynamic(N/A), assertz(Fact).
holds(not(G)) :- !, \+ catch(call(G), _, fail).
holds(G) :- catch(call(G), _, fail).
clear_facts :-
    fact_kinds(Kinds),
    forall(member(N/A, Kinds), ( functor(H, N, A), catch(retractall(H), _, true) )).

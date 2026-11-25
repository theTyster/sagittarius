% orbit-kb hub rules (hub.pl), D64 and D68 (scientific-method-overhaul c26, c44, c42, c17)
%
% orbit hub query reads this file. It declares the facts that orbit makes from the stores of
% a hub, and it holds the purpose rules: the second rule of models/purpose.pl of the spec
% (q14, q18, q19, q20, q31). The file format is the same as in core.pl. A spec KB does not
% load this file. Run orbit help hub for the recipes.

% ---------------------------------------------------------------------
% Facts that orbit makes from the stores
% ---------------------------------------------------------------------

decl(fact, item(atom, atom, atom, text, atom),
     'A ledger item (flow/jsonl/item.jsonl): its id, kind (ask, thread, hold, handoff, summary), status (open, waiting, done, dropped, lapsed), title and owner session (none when it has no owner).',
     'item @(1) is a @(2), @(3), owned by @(5): @(4)').
decl(fact, item_ref(atom, atom, atom),
     'A ref of a ledger item: its kind (kb, goal, issue, pr, build, release, url, file, commit, transcript) and the ref.',
     'item @(1) has the @(2) ref @(3)').
decl(fact, item_link(atom, atom, atom),
     'A link from one ledger item to another: blocks, follows, duplicates, supersedes or relates.',
     'item @(1) @(2) item @(3)').
decl(fact, item_closed(atom, atom),
     'The ledger item is closed: done, dropped or lapsed.',
     'item @(1) is closed: @(2)').
decl(fact, item_opened(atom, atom),
     'When the ledger item was opened.',
     'item @(1) was opened at @(2)').
decl(fact, item_waits(atom, atom),
     'The person that the ledger item waits on.',
     'item @(1) waits on @(2)').
decl(fact, item_parked(atom, atom),
     'The ledger item is parked until the date or the time.',
     'item @(1) is parked until @(2)').
decl(fact, item_due(atom, atom),
     'The due date of the ledger item.',
     'item @(1) is due on @(2)').
decl(fact, handoff(atom, atom, atom),
     'A handoff item: the session that gave the work and the session that gets it.',
     'handoff @(1) goes from @(2) to @(3)').
decl(fact, handoff_accepted(atom, atom),
     'The receiver accepted the handoff at the time.',
     'handoff @(1) was accepted at @(2)').
decl(fact, tracker_ref(atom, atom),
     'A pointer from a ledger item to the tracker: KIND:REF of an issue, pr, url, build or release ref. The hub holds the pointer, never the text.',
     'item @(1) points to @(2) in the tracker').
decl(fact, ticket(atom, text),
     'A spec KB of the hub: its slug and its directory from the hub root (specs/SLUG).',
     'ticket @(1) is the spec KB in @(2)').
decl(fact, item_reaches(atom, atom),
     'The first item reaches the second through one or more links that pass a purpose (blocks, follows, duplicates, supersedes), and no item on the way after the first is dropped or lapsed. orbit computes it.',
     'item @(1) reaches item @(2) through links that pass a purpose').
decl(fact, work_ended(atom),
     'The row itself says that its work is over. No ledger form writes this today.',
     'the row @(1) says that its work is over').

% These four are answered by orbit when a query asks (each KB is read once, each file is
% digested once).
decl(rule, ticket_fact(atom, term),
     'A fact or a rule answer of the spec KB of the ticket: goal(G, K, A, T), claim(C, L, T), done, blocking(X), and every other predicate that the KB declares.',
     'in ticket @(1): @(2)').
decl(rule, project_fact(term),
     'A fact or a rule answer of the project KB of the hub.',
     'in the project KB: @(1)').
decl(rule, store_file(atom, text, atom),
     'A file of a file store (memory, weeks or bespoke): its path from the hub root and its sha256.',
     'the @(1) file @(2) has the digest @(3)').
decl(rule, ticket_done_at(atom, atom),
     'The ticket is done, and the time of its newest attestation.',
     'ticket @(1) was done at @(2)').

% ---------------------------------------------------------------------
% Purpose (c44)
% ---------------------------------------------------------------------

decl(rule, open_item(atom), 'An ask, a thread, a hold or a handoff that is open or waiting.', 'item @(1) is open').
decl(rule, dead_item(atom), 'A dropped or lapsed item: nobody wants it, and it passes no purpose on.', 'item @(1) is dropped or lapsed').
decl(rule, item_up(atom, atom), 'The item itself, or an item that it reaches through links that pass a purpose.', 'item @(1) gets a purpose through item @(2)').
decl(rule, item_ticket(atom, atom), 'The item names the ticket with a kb ref.', 'item @(1) names ticket @(2)').
decl(rule, project_goal(atom), 'A goal of the project KB.', '@(1) is a project goal').
decl(rule, goal_dropped(atom), 'The owner dropped the project goal.', 'the project goal @(1) is dropped').
decl(rule, live_goal(atom), 'A project goal that is not dropped.', 'the project goal @(1) is live').
decl(rule, ticket_goal(atom, atom), 'A current goal of the ticket (in a KB of 0.7.2: its current hypothesis).', 'ticket @(1) has the goal @(2)').
decl(rule, ticket_supports(atom, atom, atom), 'The goal of the ticket names the project goal that it supports: supports(G, project(PG)).', 'the goal @(2) of ticket @(1) supports the project goal @(3)').
decl(rule, ticket_dropped(atom), 'The ticket ended with NO-GO.', 'ticket @(1) is dropped').
decl(rule, ticket_done(atom), 'The tool answers yes to done for the ticket.', 'ticket @(1) is done').
decl(rule, ticket_live(atom, atom), 'The ticket has a current goal that supports the live project goal.', 'ticket @(1) serves the project goal @(2)').
decl(rule, serves_goal(atom, atom), 'A live chain of records leads from the item to the project goal.', 'item @(1) serves the project goal @(2)').
decl(rule, has_purpose(atom), 'A live chain of records leads from the item to a project goal that is not dropped.', 'item @(1) has a purpose').
decl(rule, orphan(atom), 'An open item with no purpose.', 'item @(1) is an orphan').
decl(rule, rests_on_dropped(atom, atom), 'The open item rested on the project goal, and its owner dropped the goal.', 'item @(1) rested on the dropped project goal @(2)').
decl(rule, reaches_ticket(atom, atom), 'The item reaches a ticket that is not dropped.', 'item @(1) reaches ticket @(2)').
decl(rule, ends_at(atom, atom), 'Where the chain of an orphan ends. Each orphan has one answer.', 'the chain of item @(1) ends at @(2)').
decl(rule, end_record(atom, atom, term), 'The record at the end of the chain of an orphan, for the answer of ends_at.', 'the chain of item @(1) ends at @(2): @(3)').
decl(rule, names_open_ticket(atom), 'The item names a ticket that is not done.', 'item @(1) names a ticket that is not done').
decl(rule, all_tickets_done(atom), 'The item names a ticket, and each ticket that it names is done.', 'each ticket of item @(1) is done').
decl(rule, opened_after_done(atom), 'The item was opened after a ticket that it names was done.', 'item @(1) was opened after its ticket was done').
decl(rule, over(atom), 'An open row whose work is over: its tickets are done, and it was opened before that.', 'the work of item @(1) is over').
decl(rule, report_on_done_ticket(atom), 'An open row that was opened after its ticket was done.', 'item @(1) reports on a done ticket').
decl(rule, ticket_goal_unsupported(atom, atom), 'A ticket goal that names no project goal (c17).', 'the goal @(2) of ticket @(1) names no project goal').
decl(rule, ticket_goal_rests_on_dropped(atom, atom, atom), 'The ticket goal supports a project goal that its owner dropped (c42).', 'the goal @(2) of ticket @(1) rests on the dropped project goal @(3)').
decl(rule, ticket_goal_ends(atom, atom, term), 'A ticket goal with no live project goal, and why: none, dropped(PG) or missing(PG).', 'the goal @(2) of ticket @(1) has no live project goal: @(3)').
decl(rule, ticket_goal_live(atom, atom), 'The ticket goal supports a live project goal.', 'the goal @(2) of ticket @(1) supports a live project goal').

open_item(I) :- item(I, K, open, _, _), K \== summary.
open_item(I) :- item(I, K, waiting, _, _), K \== summary.
dead_item(I) :- item(I, _, dropped, _, _).
dead_item(I) :- item(I, _, lapsed, _, _).

% One step up: an item names its ticket (a kb ref), or its goal directly (a goal ref), or it
% links to an item that is still wanted. item_reaches/2 holds the links (q19, q31).
item_up(I, I) :- item(I, _, _, _, _).
item_up(I, J) :- item_reaches(I, J).
item_ticket(I, T) :- item_ref(I, kb, T), ticket(T, _).

project_goal(PG) :- project_fact(goal(PG, _, _, _)).
goal_dropped(PG) :- project_fact(dropped(PG, _, _, _)).
live_goal(PG) :- project_goal(PG), not goal_dropped(PG).

ticket_goal(T, G) :- ticket_fact(T, goal(G, _, _, _)), not ticket_fact(T, supersedes(_, G)).
ticket_goal(T, G) :- ticket_fact(T, hypothesis(G, _, _)), not ticket_fact(T, supersedes(_, G)).
ticket_supports(T, G, PG) :- ticket_fact(T, supports(G, project(PG))).
ticket_dropped(T) :- ticket_fact(T, gate(no_go)).
ticket_done(T) :- ticket_fact(T, done).
ticket_live(T, PG) :- ticket_goal(T, G), ticket_supports(T, G, PG), live_goal(PG).

reaches_ticket(I, T) :- item_up(I, J), item_ticket(J, T), not ticket_dropped(T).

serves_goal(I, PG) :- item_up(I, J), item_ref(J, goal, PG), live_goal(PG).
serves_goal(I, PG) :- reaches_ticket(I, T), ticket_live(T, PG).
has_purpose(I) :- serves_goal(I, _).
orphan(I) :- open_item(I), not has_purpose(I).

rests_on_dropped(I, PG) :- open_item(I), item_up(I, J), item_ref(J, goal, PG), goal_dropped(PG).
rests_on_dropped(I, PG) :- open_item(I), reaches_ticket(I, T), ticket_goal(T, G), ticket_supports(T, G, PG), goal_dropped(PG).

% Where the chain of an orphan ends: the first line that holds.
ends_at(I, E) :-
    orphan(I),
    (   rests_on_dropped(I, _) -> E = a_dropped_project_goal
    ;   reaches_ticket(I, T1), ticket_goal(T1, _) -> E = ticket_goal
    ;   reaches_ticket(I, _) -> E = ticket_with_no_goal
    ;   item_ticket(I, T2), ticket_dropped(T2) -> E = a_dropped_ticket
    ;   item_link(I, K1, J1), K1 \== relates, dead_item(J1) -> E = a_dropped_item
    ;   item_ref(I, kb, _) -> E = kb_outside_the_hub
    ;   tracker_ref(I, _) -> E = tracker_or_url
    ;   item_ref(I, _, _) -> E = a_file_commit_or_transcript
    ;   E = nothing
    ).

end_record(I, a_dropped_project_goal, PG) :- rests_on_dropped(I, PG).
end_record(I, ticket_goal, T:G) :- reaches_ticket(I, T), ticket_goal(T, G).
end_record(I, ticket_with_no_goal, T) :- reaches_ticket(I, T).
end_record(I, a_dropped_ticket, T) :- item_ticket(I, T), ticket_dropped(T).
end_record(I, a_dropped_item, J) :- item_link(I, K, J), K \== relates, dead_item(J).
end_record(I, kb_outside_the_hub, R) :- item_ref(I, kb, R).
end_record(I, tracker_or_url, R) :- tracker_ref(I, R).
end_record(I, a_file_commit_or_transcript, K:R) :- item_ref(I, K, R).

% The other reading (q14): the work is over, and the row is still open. Listed apart.
names_open_ticket(I) :- item_ticket(I, T), not ticket_done(T).
all_tickets_done(I) :- item_ticket(I, _), not names_open_ticket(I).
opened_after_done(I) :- item_ticket(I, T), ticket_done_at(T, Done), item_opened(I, Opened), Opened @> Done.
over(I) :- open_item(I), work_ended(I).
over(I) :- open_item(I), all_tickets_done(I), not work_ended(I), not opened_after_done(I).
report_on_done_ticket(I) :- open_item(I), all_tickets_done(I), opened_after_done(I).

% Ticket goals (c17, c42).
ticket_goal_live(T, G) :- ticket_supports(T, G, PG), live_goal(PG).
ticket_goal_unsupported(T, G) :- ticket_goal(T, G), not ticket_supports(T, G, _).
ticket_goal_rests_on_dropped(T, G, PG) :- ticket_goal(T, G), ticket_supports(T, G, PG), goal_dropped(PG).
ticket_goal_ends(T, G, none) :- ticket_goal_unsupported(T, G).
ticket_goal_ends(T, G, dropped(PG)) :- ticket_goal_rests_on_dropped(T, G, PG), not ticket_goal_live(T, G).
ticket_goal_ends(T, G, missing(PG)) :- ticket_goal(T, G), ticket_supports(T, G, PG), not project_goal(PG), not ticket_goal_live(T, G).

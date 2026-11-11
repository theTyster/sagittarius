% orbit-kb project module (modules/project.pl), D23 (ticket T06), D27 (ticket T23)
%
% Load this module with uses([project]) in kb.pl. A project KB records
% domain reasoning about where the product is and where it is going.
% Two sides (D27): definitions say how the current system is, decisions
% say what future work will do. Product rules hold for every spec KB that
% pins them. Relations between these facts (supersedes, depends_on,
% excludes) give derived answers: current_fact, rests_on, contradiction,
% impact. Pins record the world (a file, or an item of the tracker). A
% spec KB that uses this module can pin a decision, a definition or a rule
% with pins/4. The file format is the same as in core.pl. Run
% orbit-kb help project for the recipes.

decl(fact, decision(id, text),
     'A decision about the product, in one plain sentence.',
     'decision @(1): @(2)').
decl(fact, definition(id, text),
     'A definition of the current system: how it is now, in one plain sentence (D27).',
     'definition @(1): @(2)').
decl(fact, rule(id, text),
     'A product rule: a statement that every spec KB that pins it must keep (D27).',
     'product rule @(1): @(2)').
decl(fact, decided_by(ref([decision, definition, rule]), atom, time),
     'Who made the decision, the definition or the rule, and when. Who is any person or role; agent or agent:NAME is an agent (D27).',
     '@(1) was made by @(2) at @(3)').
decl(fact, ratified_by(ref([decision, definition, rule]), atom, time),
     'A human ratified a decision that an agent made (D27). An agent may not ratify (lint EP1).',
     '@(1) was ratified by @(2) at @(3)').
decl(fact, depends_on(ref([decision, definition, rule]), ref([decision, definition, rule])),
     'The first fact depends on the second (D27).',
     '@(1) depends on @(2)').
decl(fact, excludes(ref([decision, definition, rule]), ref([decision, definition, rule])),
     'A human or an agent records that the two facts cannot both hold (D27). It is never inferred from the text.',
     '@(1) and @(2) cannot both hold').
decl(fact, reason(ref(decision), text),
     'A reason for the decision.',
     'a reason for decision @(1): @(2)').
decl(fact, repo(id, text),
     'A repository of the product: its name and where it lives.',
     'repository @(1) is at @(2)').
decl(fact, analysis(ref([decision, definition, rule]), text),
     'The path of a file that holds the analysis behind the fact: a path under the project KB, such as analyses/NAME.md (D27, lint WP6).',
     'the analysis for @(1) is in @(2)').
decl(fact, pin(id, oneof([file, tracker]), atom, digest, time),
     'A pin of the world: its kind (file or tracker), its source (a subject id, or the name of a tracker item), the digest at the time, and the change time. A new record of a tracker item is a new pin. A pin is never rewritten.',
     'pin @(1) records @(3) as it was at @(5)').
decl(fact, concerns(ref([decision, definition]), ref(pin)),
     'The decision or the definition rests on the pin.',
     '@(1) rests on pin @(2)').
decl(fact, draft(id, ref(pin), text, time),
     'An edit staged for the pinned tracker item. A draft never changes the pin.',
     'draft @(1) of pin @(2) was staged at @(4)').
decl(fact, pushed(ref(draft), time),
     'The draft was pushed to the tracker at the time.',
     'draft @(1) was pushed at @(2)').
decl(fact, resolved(ref(draft), oneof([draft, tracker]), time),
     'A human settled the draft, and named the side that stays: the draft, or the tracker. It wins over the dates (T43).',
     'draft @(1) was settled for the @(2)').
% T27: writer_takeover/3 is declared in core.pl: every KB has the writer lock.
decl(fact, project_kb(text),
     'In a spec KB: the directory of the project KB, relative to this KB or absolute.',
     'the project KB is @(1)').
decl(fact, pins(ref(claim), oneof([project]), atom, digest),
     'In a spec KB: the claim rests on a decision, a definition or a rule of the project KB. The digest is its project_decision_digest when the claim was written.',
     'claim @(1) rests on @(3) of the project KB').

% ---------------------------------------------------------------------
% Computed facts (orbit-kb computes them when it reads the KB)
% ---------------------------------------------------------------------

decl(rule, subject_now(ref(subject), digest),
     'The file of the subject exists, and its sha256 now is the digest. orbit-kb computes it when it reads the KB.',
     'the file of subject @(1) has digest @(2) now').
decl(rule, decision_digest(ref(decision), digest),
     'The sha256 of the text of the decision, with no newline. orbit-kb computes it when it reads the KB.',
     'decision @(1) has digest @(2)').
decl(rule, project_decision_digest(atom, digest),
     'The sha256 of the text of a decision, a definition or a rule in the project KB of project_kb/1, as it is now. orbit-kb computes it when it reads the KB.',
     '@(1) of the project KB has digest @(2) now').
decl(rule, project_kb_unclean,
     'The project KB of project_kb/1 does not load clean: lint finds an error in it, so a conflict could hide there. orbit-kb computes it when it reads the KB.',
     'the project KB does not load clean').
decl(rule, rests_on(ref, ref),
     'The first fact depends on the second through one or more depends_on facts (D27). orbit-kb computes it when it reads the KB.',
     '@(1) rests on @(2)').
decl(rule, agent_who(atom),
     'The decider is an agent: the atom agent, or an atom that starts with agent:, in any case (D27, T34). orbit-kb computes it when it reads the KB.',
     '@(1) is an agent').
decl(rule, analysis_outside(ref, text),
     'The path of an analysis of the fact is outside the directory of the project KB (D27). orbit-kb computes it when it reads the KB.',
     'an analysis of @(1) is outside the project KB: @(2)').
decl(rule, spec_pin(atom, atom, atom),
     'A spec KB (its directory) has a claim that pins the fact of this project KB (D27). orbit-kb finds the spec KBs under the parent directory of the project KB, and computes it when it reads the KB.',
     'spec KB @(1) has claim @(2), which pins @(3)').
decl(rule, project_contradiction(atom, atom),
     'In a spec KB: the two facts of the project KB are in a contradiction, and neither is proposed (D27). orbit-kb computes it when it reads the KB.',
     '@(1) and @(2) of the project KB contradict each other').
decl(rule, project_rests_on(atom, atom),
     'In a spec KB: rests_on of the project KB (D27). orbit-kb computes it when it reads the KB.',
     '@(1) of the project KB rests on @(2)').

% ---------------------------------------------------------------------
% Rules
% ---------------------------------------------------------------------

decl(rule, tracker_changed_after(ref(pin), time),
     'The tracker item of the pin has a newer record, with this change time.',
     'the tracker item of pin @(1) changed at @(2)').
decl(rule, tracker_latest(ref(pin), time),
     'The newest change time of the tracker item after the pin.',
     'the tracker item of pin @(1) last changed at @(2)').
decl(rule, stale_pin(ref(pin)),
     'The pin is old. A file pin: the file now has another digest, or is missing. A tracker pin: a newer change time is recorded for the same source.',
     'pin @(1) is old').
decl(rule, both_changed(ref(draft), time),
     'The tracker changed after the pin of the draft, and the draft was staged after the pin too: both edits are new (T43). The time is the latest change of the tracker.',
     'draft @(1) and the tracker (last changed at @(2)) both changed after the pin').
decl(rule, supersedes_by_date(ref(draft), oneof([draft, tracker])),
     'No human settled it: the later edit wins (T43, u123). The draft wins when the tracker did not change after the pin, or when both changed and the draft was staged after the latest change of the tracker. The tracker wins when the draft was staged no later than the pin, or when both changed and the tracker changed at the staged time or later: on equal times the tracker wins (u66).',
     'for draft @(1), the later edit is the @(2)').
decl(rule, lost_by_date(ref(draft), oneof([draft, tracker])),
     'No human settled it, and the dates dropped the edit of this side (T43): the draft lost to a later tracker change (also a draft staged at or before the pin, T45; never a pushed draft, T45), or the tracker lost when both changed after the pin. pin-item, draft and project dropped record it in the hub ledger (T45).',
     'for draft @(1), the edit of the @(2) lost by date').
decl(rule, pushed_over(ref(draft), ref(pin)),
     'The draft was pushed over a newer tracker edit (T46): pin P of the same tracker item changed after the pin of the draft, after its staging and before its push, and no human settled it. The push overwrote that edit. pin-item, draft and project dropped note it on the open ledger item of the drop, or add one item.',
     'the push of draft @(1) overwrote the tracker edit of pin @(2)').
decl(rule, dropped(ref(draft), oneof([draft, tracker])),
     'The edit of this side lost, by date or by the choice of a human. A pushed draft is not dropped by date (T45): its text reached the tracker. A push over a newer tracker edit drops the tracker edit (pushed_over, T46). It stays in kb.pl: this is the record.',
     'for draft @(1), the edit of the @(2) was dropped').
decl(rule, current_fact(ref([decision, definition, rule])),
     'The decision, definition or rule is not superseded (D27).',
     '@(1) is current').
decl(rule, contradiction(ref([decision, definition, rule]), ref([decision, definition, rule])),
     'An excludes fact names the two facts, and both are current (D27).',
     '@(1) and @(2) contradict each other').
decl(rule, proposed(ref([decision, definition, rule])),
     'An agent made the fact, and no human ratified it (D27). A proposed fact blocks nothing.',
     '@(1) is proposed: an agent made it, and no human ratified it').
decl(rule, human_ratified(ref([decision, definition, rule])),
     'A ratified_by fact by a person who is not an agent names the fact (D27).',
     'a human ratified @(1)').
decl(rule, impact(ref([decision, definition, rule]), atom),
     'The spec KB has a claim that pins the fact, or pins a fact that rests on it (D27).',
     'a change of @(1) touches spec KB @(2)').
decl(rule, project_pinned(atom),
     'In a spec KB: a claim pins this fact of the project KB directly (D27).',
     'a claim pins @(1) of the project KB').
decl(rule, outbound(ref(draft)),
     'The draft is not pushed yet, and did not lose.',
     'draft @(1) waits to be pushed').

tracker_changed_after(P, C2) :- pin(P, tracker, Src, _, C), pin(_, tracker, Src, _, C2), C2 @> C.
tracker_latest(P, C2) :- tracker_changed_after(P, C2), not (tracker_changed_after(P, C3), C3 @> C2).

stale_pin(P) :- pin(P, file, S, D, _), subject_now(S, Now), Now \== D.
stale_pin(P) :- pin(P, file, S, _, _), not subject_now(S, _).
stale_pin(P) :- pin(P, tracker, _, _, _), tracker_changed_after(P, _).

% T43 c3 (u123, u66): when both sides changed after the pin, the dates decide; there is no
% conflict that blocks. On equal times the tracker wins. A human's resolved/3 wins over the dates.
both_changed(D, T) :- draft(D, P, _, S), pin(P, tracker, _, _, C), S @> C, tracker_latest(P, T).

supersedes_by_date(D, draft) :- draft(D, P, _, _), not tracker_changed_after(P, _), not resolved(D, _, _).
supersedes_by_date(D, draft) :- both_changed(D, T), draft(D, _, _, S), S @> T, not resolved(D, _, _).
supersedes_by_date(D, tracker) :- draft(D, P, _, S), pin(P, _, _, _, C), tracker_changed_after(P, _),
                                  not (S @> C), not resolved(D, _, _).
supersedes_by_date(D, tracker) :- both_changed(D, T), draft(D, _, _, S), not (S @> T), not resolved(D, _, _).

% T45 c3 (u123): a draft staged at or before the pin that a later tracker change drops lost by date too.
% T45 c6 (review a21): a pushed draft reached the tracker, so the dates drop nothing of it.
lost_by_date(D, draft) :- supersedes_by_date(D, tracker), not pushed(D, _).
lost_by_date(D, tracker) :- both_changed(D, _), supersedes_by_date(D, draft).

% T46 c1 (review default): a push over a tracker edit that came after the staging (and before the push)
% overwrote it. A pin whose change time is at or after the push reads the pushed text.
pushed_over(D, P2) :- pushed(D, Tp), draft(D, P, _, S), pin(P, tracker, Src, _, C),
                      pin(P2, tracker, Src, _, C2), C2 @> C, C2 @> S, C2 @< Tp, not resolved(D, _, _).

dropped(D, draft) :- supersedes_by_date(D, tracker), not pushed(D, _).
dropped(D, tracker) :- lost_by_date(D, tracker).
dropped(D, draft) :- resolved(D, tracker, _).
dropped(D, tracker) :- pushed_over(D, _).
dropped(D, tracker) :- resolved(D, draft, _).

outbound(D) :- draft(D, _, _, _), not pushed(D, _), not dropped(D, draft).

% D27: the two sides, product rules, and their relations.
current_fact(X) :- decision(X, _), not superseded(X).
current_fact(X) :- definition(X, _), not superseded(X).
current_fact(X) :- rule(X, _), not superseded(X).

contradiction(X, Y) :- excludes(X, Y), current_fact(X), current_fact(Y).

human_ratified(X) :- ratified_by(X, W, _), not agent_who(W).
proposed(X) :- decided_by(X, W, _), agent_who(W), not human_ratified(X).

impact(X, S) :- spec_pin(S, _, X).
impact(X, S) :- spec_pin(S, _, Z), rests_on(Z, X).

% In a spec KB: a contradiction blocks only a spec KB that pins a side directly.
project_pinned(X) :- pins(_, project, X, _).
blocking(project_contradiction(X)) :- project_contradiction(X, _), project_pinned(X).
any_project_conflict :- blocking(project_contradiction(_)).

% T43 c3: a draft blocks no spec KB (the dates decide). A project KB that does not load clean does.
blocking(project_kb_unclean) :- project_kb_unclean.
any_project_conflict :- blocking(project_kb_unclean).

% ---------------------------------------------------------------------
% Lint hooks
% ---------------------------------------------------------------------

lint_issue('WP1', C, 'This claim rests on a decision, a definition or a rule of the project KB, and it changed after the claim was written. Read it. If the claim still holds, pin the new digest with orbit-kb add and a new pins fact; if not, change the claim.') :-
    pins(C, project, D, _), project_decision_digest(D, Now), not pins(C, project, D, Now).
lint_issue('WP2', C, 'The decision, definition or rule that this claim rests on cannot be read. The KB has no project_kb fact, or the project KB has no kb.pl, or it has no such id. Add project_kb(DIR) or fix the id.') :-
    pins(C, project, D, _), not project_decision_digest(D, _).
lint_issue('WP3', C, 'The project KB does not load clean: lint finds an error in it. A conflict or a changed decision could hide there. Run orbit-kb lint on the project KB and fix the errors.') :-
    pins(C, project, _, _), project_kb_unclean.
lint_issue('WP5', C, 'This claim rests on a fact of the project KB that rests on a fact in a contradiction (orbit-kb project impact lists it). It does not block this KB, because no claim pins that fact directly. Read the contradiction in the project KB.') :-
    pins(C, project, Z, _), project_rests_on(Z, X), project_contradiction(X, _), not project_pinned(X).
lint_issue('WP6', X, M) :- analysis_outside(X, M).
% EP1 (an agent ratified) and EP2 (a fact depends on or excludes itself) are checks of one fact
% in the CLI, at add and at lint (T34).
lint_issue('WP7', X, 'This fact rests on itself: its depends_on facts make a cycle. A cycle of dependencies is allowed, but it is often a mistake. Check each depends_on fact of the cycle (orbit-kb query ''rests_on(X, Y)'').') :-
    rests_on(X, X).
lint_issue('WP4', Dir, 'This KB has more than one project_kb fact. Only the first is read. Keep one project_kb fact.') :-
    project_kb(First), project_kb(Dir), First @< Dir.

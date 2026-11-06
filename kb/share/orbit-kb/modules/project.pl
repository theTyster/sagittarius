% orbit-kb project module (modules/project.pl), D23 (ticket T06)
%
% Load this module with uses([project]) in kb.pl. A project KB records
% domain reasoning about where the product is and where it is going:
% decisions, who made them and why, the repositories, and pins of the
% world (a file, or an item of the tracker). A spec KB that uses this
% module can pin a decision with pins/4. The file format is the same as
% in core.pl. Run orbit-kb help project for the recipes.

% ---------------------------------------------------------------------
% Facts
% ---------------------------------------------------------------------

decl(fact, decision(id, text),
     'A decision about the product, in one plain sentence.',
     'decision @(1): @(2)').
decl(fact, decided_by(ref(decision), atom, time),
     'Who made the decision, and when.',
     'decision @(1) was made by @(2) at @(3)').
decl(fact, reason(ref(decision), text),
     'A reason for the decision.',
     'a reason for decision @(1): @(2)').
decl(fact, repo(id, text),
     'A repository of the product: its name and where it lives.',
     'repository @(1) is at @(2)').
decl(fact, analysis(ref(decision), text),
     'The path of a file that holds the analysis behind the decision.',
     'the analysis for decision @(1) is in @(2)').
decl(fact, pin(id, oneof([file, tracker]), atom, digest, time),
     'A pin of the world: its kind (file or tracker), its source (a subject id, or the name of a tracker item), the digest at the time, and the change time. A new record of a tracker item is a new pin. A pin is never rewritten.',
     'pin @(1) records @(3) as it was at @(5)').
decl(fact, concerns(ref(decision), ref(pin)),
     'The decision rests on the pin.',
     'decision @(1) rests on pin @(2)').
decl(fact, draft(id, ref(pin), text, time),
     'An edit staged for the pinned tracker item. A draft never changes the pin.',
     'draft @(1) of pin @(2) was staged at @(4)').
decl(fact, pushed(ref(draft), time),
     'The draft was pushed to the tracker at the time.',
     'draft @(1) was pushed at @(2)').
decl(fact, resolved(ref(draft), oneof([draft, tracker]), time),
     'A human settled the conflict of the draft, and named the side that stays: the draft, or the tracker.',
     'the conflict of draft @(1) was settled for the @(2)').
decl(fact, writer_takeover(atom, atom, time),
     'A writer took the lock of the KB from another writer. Only the option --take writes it.',
     '@(2) took the writer lock from @(1) at @(3)').
decl(fact, project_kb(text),
     'In a spec KB: the directory of the project KB, relative to this KB or absolute.',
     'the project KB is @(1)').
decl(fact, pins(ref(claim), oneof([project]), atom, digest),
     'In a spec KB: the claim rests on a decision of the project KB. The digest is the decision_digest of the decision when the claim was written.',
     'claim @(1) rests on decision @(3) of the project KB').

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
     'The decision_digest of a decision in the project KB of project_kb/1, as it is now. orbit-kb computes it when it reads the KB.',
     'decision @(1) of the project KB has digest @(2) now').
decl(rule, project_draft_text(atom, text),
     'The text of a draft of the project KB that is in conflict (see project_conflict). orbit-kb computes it when it reads the KB.',
     'the conflicting draft @(1) says: @(2)').
decl(rule, project_kb_unclean,
     'The project KB of project_kb/1 does not load clean: lint finds an error in it, so a conflict could hide there. orbit-kb computes it when it reads the KB.',
     'the project KB does not load clean').
decl(rule, project_conflict(atom, atom),
     'A draft of the project KB is in conflict, and its pin is one that the decision rests on. orbit-kb computes it when it reads the KB.',
     'draft @(1) of the project KB is in conflict, and decision @(2) rests on its pin').

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
decl(rule, conflict(ref(draft)),
     'The tracker changed after the pin, and the draft was staged after the pin, and no human settled it. Both edits are new, so only a human can pick.',
     'draft @(1) conflicts with a change of the tracker').
decl(rule, supersedes_by_date(ref(draft), oneof([draft, tracker])),
     'Not a conflict, and no human settled it: the later edit wins. The draft wins when the tracker did not change after the pin. The tracker wins when the draft was staged no later than the pin.',
     'for draft @(1), the later edit is the @(2)').
decl(rule, dropped(ref(draft), oneof([draft, tracker])),
     'The edit of this side lost, by date or by the choice of a human. It stays in kb.pl: this is the record.',
     'for draft @(1), the edit of the @(2) was dropped').
decl(rule, outbound(ref(draft)),
     'The draft is not pushed yet, is no conflict, and did not lose.',
     'draft @(1) waits to be pushed').

tracker_changed_after(P, C2) :- pin(P, tracker, Src, _, C), pin(_, tracker, Src, _, C2), C2 @> C.
tracker_latest(P, C2) :- tracker_changed_after(P, C2), not (tracker_changed_after(P, C3), C3 @> C2).

stale_pin(P) :- pin(P, file, S, D, _), subject_now(S, Now), Now \== D.
stale_pin(P) :- pin(P, file, S, _, _), not subject_now(S, _).
stale_pin(P) :- pin(P, tracker, _, _, _), tracker_changed_after(P, _).

conflict(D) :- draft(D, P, _, S), pin(P, tracker, _, _, C), tracker_changed_after(P, _),
               S @> C, not resolved(D, _, _).

supersedes_by_date(D, draft) :- draft(D, P, _, _), not tracker_changed_after(P, _), not resolved(D, _, _).
supersedes_by_date(D, tracker) :- draft(D, P, _, S), pin(P, _, _, _, C), tracker_changed_after(P, _),
                                  not (S @> C), not resolved(D, _, _).

dropped(D, draft) :- supersedes_by_date(D, tracker).
dropped(D, draft) :- resolved(D, tracker, _).
dropped(D, tracker) :- resolved(D, draft, _).

outbound(D) :- draft(D, _, _, _), not pushed(D, _), not conflict(D), not dropped(D, draft).

% A conflict blocks a spec KB that pins a decision that rests on the pin.
blocking(project_conflict(Dr)) :- project_conflict(Dr, Dec), pins(_, project, Dec, _).
blocking(project_kb_unclean) :- project_kb_unclean.
any_project_conflict :- blocking(project_conflict(_)).
any_project_conflict :- blocking(project_kb_unclean).

% ---------------------------------------------------------------------
% Lint hooks
% ---------------------------------------------------------------------

lint_issue('WP1', C, 'This claim rests on a decision of the project KB, and the decision changed after the claim was written. Read the decision. If the claim still holds, pin the new digest with orbit-kb add and a new pins fact; if not, change the claim.') :-
    pins(C, project, D, _), project_decision_digest(D, Now), not pins(C, project, D, Now).
lint_issue('WP2', C, 'The decision that this claim rests on cannot be read. The KB has no project_kb fact, or the project KB has no kb.pl, or it has no such decision. Add project_kb(DIR) or fix the decision id.') :-
    pins(C, project, D, _), not project_decision_digest(D, _).
lint_issue('WP3', C, 'The project KB does not load clean: lint finds an error in it. A conflict or a changed decision could hide there. Run orbit-kb lint on the project KB and fix the errors.') :-
    pins(C, project, _, _), project_kb_unclean.
lint_issue('WP4', Dir, 'This KB has more than one project_kb fact. Only the first is read. Keep one project_kb fact.') :-
    project_kb(First), project_kb(Dir), First @< Dir.

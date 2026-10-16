% orbit-kb module: discovery (contract v2.1). Load it with uses([discovery]).
%
% Discovery turns a request into a ticket. It records a hypothesis, models of the
% current system and of the target, findings, and the evidence for each of them.
% The core gives request/2, claim/3, check/2, question/3, answer/3, note/2, subject/3,
% attest/6, and the rules current/1, answered/1, refuted/1, and to_ask/1.
%
% Where discovery evidence goes:
% - A runnable reproduction is a core check/2 with a red test_result.
% - Evidence that cannot run (a log, a query) is a `reproduction` attestation.
% - A model verdict is a `model_result` attestation. Its subject is the digested log of
%   the solver run, and its predicate names the model. A model verdict is not a check,
%   so a model pass is never evidence about the code.
% - A solver counterexample to a claim is a core `disproof`, with a note and an example.
% - An unsat core is one finding/3, plus a core divergence for each claim in the core.
% - GO is a core approval of the ticket subject. NO-GO and HOLD are a `decision`.

% --- Facts ---
decl(fact, hypothesis(id, oneof([defect, feature, risk]), text),
     'A falsifiable and scoped restatement of the request.',
     'hypothesis @(1) is a @(2): @(3)').
decl(fact, budget(oneof([laps]), int),
     'The number of laps with the human that discovery may use.',
     'the budget is @(2) @(1)').
decl(fact, lap_done(int),
     'A lap that ended with an answer from the human.',
     'lap @(1) is done').
decl(fact, model(ref(subject), oneof([smt, tla])),
     'A subject that is a model file, and the tool that checks it.',
     'subject @(1) is a model for @(2)').
decl(fact, derived_from(ref(model), ref(model)),
     'A target model, then the existing-world model that it changes.',
     'model @(1) is derived from model @(2)').
decl(fact, encodes(ref(model), ref(claim)),
     'A model states a claim, so the model can falsify the claim.',
     'model @(1) states claim @(2)').
decl(fact, finding(id, alt([root_cause(term), conflict(term), surprise(term), trace(term), scope(term)]), oneof([system, model])),
     'Something that the evidence showed, and the source of that evidence.',
     'finding @(1) is @(2), from the @(3)').
decl(fact, reason(atom, text),
     'The reason why a rule survived its mutation check.',
     'rule @(1) survived its mutation check because @(2)').
decl(fact, raised_by(ref(question), ref(finding)),
     'A question for the human, then the finding that raised it.',
     'question @(1) was raised by finding @(2)').

% --- Attestation types ---
attest_type(reproduction,
    alt([result(ref(hypothesis), oneof([reproduced, not_reproduced])),
         confirms(ref(finding))]),
    [agent, human],
    'Evidence from the current system that cannot run as a check, such as a log or a query.').
% verdict/3 has three arguments, so the core refuted/1 never reads it.
attest_type(model_result,
    alt([verdict(ref(model),
                 alt([sanity, bad_case, together, root_cause(atom), normal_case(atom),
                      preserve(ref(claim)), applies(ref(claim)), explore(term)]),
                 oneof([sat, unsat, unknown, reached, violated, holds])),
         calibration(ref(model), atom, oneof([matches, differs])),
         mutation(ref(model), atom, oneof([killed, survived]))]),
    [agent, human],
    'The result of one check on a model, read from the log of the solver run.').
% GO is not a decision: it is a core approval of the ticket subject.
attest_type(decision,
    alt([no_go(ref(hypothesis)), hold(ref(hypothesis), text)]),
    [human],
    'A NO-GO or HOLD decision by the human, with the hypothesis that it closes or holds.').

% --- Rules ---
decl(rule, model_sane(ref(model)),
     'The rules of the model admit a case.',
     'model @(1) is sane').
decl(rule, model_calibrated(ref(model)),
     'The model gives the same result as the current system for a known case.',
     'model @(1) matches the current system on a known case').
decl(rule, model_trusted(ref(model)),
     'The model is sane, and it or the model that it changes is calibrated.',
     'model @(1) is trusted').
decl(rule, has_falsifier(ref(claim)),
     'A trusted model or a check can falsify the claim.',
     'claim @(1) has a falsifier').
decl(rule, no_falsifier(ref(claim)),
     'A current claim that no trusted model and no check can falsify.',
     'claim @(1) has no falsifier').
decl(rule, needs_question(ref(finding)),
     'A conflict, surprise, or scope finding needs a question for the human.',
     'finding @(1) needs a question for the human').
decl(rule, has_question(ref(finding)),
     'The finding raised a question.',
     'finding @(1) raised a question').
decl(rule, unasked_finding(ref(finding)),
     'A finding that needs a question, but raised none.',
     'finding @(1) needs a question, and none was raised').
decl(rule, question_waits(ref(question)),
     'A question that a finding raised, and that the human did not answer.',
     'question @(1) waits for the human').
decl(rule, about_system(ref(finding)),
     'A finding about the behavior of the current system.',
     'finding @(1) is about the current system').
decl(rule, finding_confirmed(ref(finding)),
     'Evidence from the current system confirms the finding.',
     'the current system confirms finding @(1)').
decl(rule, finding_lead(ref(finding)),
     'A finding about the current system that only a model shows.',
     'finding @(1) is a lead from a model only').
decl(rule, rule_has_reason(atom),
     'A reason is recorded for the rule.',
     'rule @(1) has a recorded reason').
decl(rule, weak_rule(atom),
     'A rule that survived its mutation check, with no recorded reason.',
     'rule @(1) survived its mutation check with no reason').
decl(rule, has_digest(ref),
     'The id is a subject, so it has a digest.',
     '@(1) is a subject with a digest').
decl(rule, touched_system,
     'Discovery has evidence from the current system.',
     'discovery touched the current system').
decl(rule, budget_spent,
     'The last lap of the budget is done.',
     'the lap budget is spent').
decl(rule, discovery_ready,
     'Discovery is ready for the human to decide GO, NO-GO, or HOLD.',
     'discovery is ready for the human to decide').
decl(rule, some_no_falsifier, 'Some current claim has no falsifier.', 'some current claim has no falsifier').
decl(rule, some_question_waits, 'Some question waits for the human.', 'some question waits for the human').
decl(rule, some_unasked_finding, 'Some finding needs a question.', 'some finding needs a question').
decl(rule, some_current_refuted, 'Some current claim is refuted.', 'some current claim is refuted').
decl(rule, some_weak_rule, 'Some rule is weak.', 'some rule survived its mutation check with no reason').
decl(rule, some_to_ask, 'Some question must be asked.', 'some question must be asked').

% A model counts only when it is sane and calibrated against the current system.
model_sane(M) :- attest(_, model_result, _, verdict(M, sanity, sat), _, _).
model_sane(M) :- attest(_, model_result, _, verdict(M, sanity, reached), _, _).
model_calibrated(M) :- attest(_, model_result, _, calibration(M, _, matches), _, _).
model_trusted(M) :- model_sane(M), model_calibrated(M).
% A target model inherits trust from the calibrated model that it changes.
% One level only: a target is built from an existing-world model, and a cycle
% in derived_from/2 cannot make the SWI engine loop.
model_trusted(M) :- model_sane(M), derived_from(M, M0), model_sane(M0), model_calibrated(M0).

% Each current claim needs a falsifier: a trusted model or a check.
has_falsifier(C) :- encodes(M, C), model_trusted(M).
has_falsifier(C) :- check(_, C).
no_falsifier(C) :- current(C), not has_falsifier(C).

% Conflict, surprise, and scope findings need a question for the human.
needs_question(F) :- finding(F, conflict(_), _).
needs_question(F) :- finding(F, surprise(_), _).
needs_question(F) :- finding(F, scope(_), _).
has_question(F) :- raised_by(_, F).
unasked_finding(F) :- needs_question(F), not has_question(F).
question_waits(Q) :- raised_by(Q, _), not answered(Q).

% A finding about the current system that only a model shows is a lead.
about_system(F) :- finding(F, root_cause(_), _).
about_system(F) :- finding(F, trace(_), _).
about_system(F) :- finding(F, surprise(_), _).
finding_confirmed(F) :- attest(_, reproduction, _, confirms(F), _, _).
finding_lead(F) :- finding(F, _, model), about_system(F), not finding_confirmed(F).

% A rule that survived its mutation check needs a recorded reason.
rule_has_reason(R) :- reason(R, _).
weak_rule(R) :- attest(_, model_result, _, mutation(_, R, survived), _, _),
                not rule_has_reason(R).

has_digest(S) :- subject(S, _, _).

% Evidence from the current system: a non-runnable reproduction, or any run of a check.
touched_system :- attest(_, reproduction, _, _, _, _).
touched_system :- attest(_, test_result, _, _, _, _).
budget_spent :- budget(laps, B), lap_done(B).

% "There is no such X" needs a helper with no arguments (hazard H1).
some_no_falsifier :- no_falsifier(_).
some_question_waits :- question_waits(_).
some_unasked_finding :- unasked_finding(_).
some_current_refuted :- refuted(C), current(C).
some_weak_rule :- weak_rule(_).
some_to_ask :- to_ask(_).

% Ready for the human to decide.
discovery_ready :- touched_system,
    not some_no_falsifier,
    not some_question_waits,
    not some_unasked_finding,
    not some_current_refuted,
    not some_weak_rule,
    not some_to_ask.
% Out of budget: decide now, and list what is unknown.
discovery_ready :- budget_spent.

% --- Lint hooks. A code that starts with E is an error. Any other code is a warning. ---
% The core declares lint_issue(atom, ref, text), so each Id is an existing id.
lint_issue('WD1', F, 'This finding needs a question for the human. Add the question, then raised_by(Question, Finding).') :-
    unasked_finding(F).
lint_issue('WD2', M, 'This model states a claim, but it is not sane and calibrated. Its verdicts do not count yet.') :-
    encodes(M, _), not model_trusted(M).
% A rule name is not an id, so WD3 names the attestation of the mutation check.
lint_issue('WD3', A, 'A rule survived the mutation check in this attestation. Find out why, then add reason(Rule, Text).') :-
    attest(A, model_result, _, mutation(_, R, survived), _, _), not rule_has_reason(R).
lint_issue('WD4', F, 'Only a model shows this finding. It is a lead until evidence from the current system confirms it.') :-
    finding_lead(F).
lint_issue('ED1', A, 'This evidence must point at a subject with a digest. Run orbit-kb subject for the log, then attest again.') :-
    attest(A, model_result, S, _, _, _), not has_digest(S).
lint_issue('ED1', A, 'This evidence must point at a subject with a digest. Run orbit-kb subject for the log, then attest again.') :-
    attest(A, reproduction, S, _, _, _), not has_digest(S).
lint_issue('ED2', A, 'This model verdict points at the model file. Point it at the log of the solver run.') :-
    attest(A, model_result, S, _, _, _), model(S, _).

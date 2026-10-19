% orbit-kb module: discovery (contract v2.1 through D7). Load it with uses([discovery]).
%
% Discovery turns a request into a ticket. It records hypotheses, models of the current
% system and of the target, findings, and the evidence for each of them.
%
% Where discovery evidence goes:
% - A runnable reproduction is a core check/2 with a red test_result.
% - Evidence that cannot run (a log, a query) is a `reproduction` attestation. Its
%   subject must be tagged discovery_evidence(Subject, system).
% - A model verdict is a `model_result` attestation. Its subject is the log of a solver
%   run, and model_run(Log, Model, Digest) records which model file, at which digest, made
%   that log. A verdict counts only while the model still has that digest.
% - A solver counterexample to a claim is a core `disproof`, with a note and an example.
% - An unsat core is one conflict finding/3 and one question. After the human answers,
%   a core divergence goes on each claim that the answer supersedes, and only on those.
% - GO is a core approval of the ticket subject. NO-GO and HOLD are a `decision`.

% --- Facts ---
decl(fact, hypothesis(id, oneof([defect, feature, risk]), text),
     'A falsifiable and scoped restatement of the request.',
     'hypothesis @(1) is a @(2): @(3)').
decl(fact, budget(oneof([laps]), int),
     'A lap budget; when there are several, the largest one counts.',
     'the budget is @(2) @(1)').
decl(fact, lap_done(int),
     'A lap that ended with an answer from the human.',
     'lap @(1) is done').
decl(fact, model(ref(subject), oneof([smt, tla])),
     'A subject that is a model file, and the tool that checks it.',
     'subject @(1) is a model for @(2)').
decl(fact, model_run(ref(subject), ref(model), digest),
     'A solver log, the model that the solver ran, and the digest of the model file at that run.',
     'log @(1) is a run of model @(2) at digest @(3)').
decl(fact, derived_from(ref(model), ref(model)),
     'A target model, then the existing-world model that it changes.',
     'model @(1) is derived from model @(2)').
decl(fact, encodes(ref(model), ref(claim)),
     'A model states a claim, so the model can falsify the claim.',
     'model @(1) states claim @(2)').
decl(fact, finding(id, alt([root_cause(term), conflict(term), surprise(term), trace(term), scope(term)]), oneof([system, model])),
     'Something that the evidence showed, and the source of that evidence.',
     'finding @(1) is @(2), from the @(3)').
decl(fact, reason(ref(model), atom, text),
     'The reason why a rule of a model survived its mutation check.',
     'rule @(2) of model @(1) survived its mutation check because @(3)').
decl(fact, raised_by(ref(question), ref),
     'A question for the human, then the finding or hypothesis that raised it.',
     'question @(1) was raised by @(2)').
decl(fact, discovery_evidence(ref, oneof([system, model])),
     'A subject or check, tagged as evidence from the current system or from a model.',
     '@(1) is evidence from the @(2)').

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
         calibration(ref(model), alt([example(ref(claim)), case(text)]), oneof([matches, differs])),
         mutation(ref(model), atom, oneof([killed, survived]))]),
    [agent, human],
    'The result of one check on a model, read from the log of the solver run.').
% GO is not a decision: it is a core approval of the ticket subject.
attest_type(decision,
    alt([no_go(ref(hypothesis), text), hold(ref(hypothesis), text)]),
    [human],
    'A NO-GO or HOLD decision by the human, with its reason or what it waits for.').

% --- Rule declarations ---
decl(rule, discovery_disproof_filed(ref(claim)), 'A disproof attestation refutes the claim.', 'a disproof of claim @(1) is filed').
decl(rule, discovery_model_artifact(ref), 'The id is a model file, a solver log, or is tagged as model evidence.', '@(1) is a model artifact').
decl(rule, discovery_system_evidence(ref), 'The id is tagged as system evidence and is not a model artifact.', '@(1) is evidence from the current system').
decl(rule, discovery_hypothesis_touched(ref(hypothesis)), 'A reproduction on system evidence gives a result for the hypothesis.', 'the current system was checked for hypothesis @(1)').
decl(rule, discovery_has_outcome, 'Some claim is current, or a hypothesis did not reproduce.', 'discovery has a ticket or a NO-GO candidate').
decl(rule, discovery_sanity_ok(atom), 'A result that passes a sanity check.', '@(1) passes a sanity check').
decl(rule, discovery_decided(atom), 'A solver result that is not unknown.', '@(1) is a decided result').
decl(rule, discovery_has_case(atom), 'A solver result that shows a case.', '@(1) shows a case').
decl(rule, discovery_no_case(atom), 'A solver result that shows no case.', '@(1) shows no case').
decl(rule, discovery_result_model(term, ref(model)), 'The model that a model_result predicate is about.', 'the result @(1) is about model @(2)').
decl(rule, discovery_is_finding(ref), 'The id is a finding.', '@(1) is a finding').
decl(rule, discovery_is_hypothesis(ref), 'The id is a hypothesis.', '@(1) is a hypothesis').
decl(rule, discovery_ratified(ref(claim)), 'A human answered a question about the claim.', 'a human answered a question about claim @(1)').
decl(rule, discovery_disputed(ref(claim)), 'The claim is refuted, or a claim divergence contests it.', 'claim @(1) is disputed').
decl(rule, discovery_unratified(ref(claim)), 'A claim that supersedes a disputed claim with no human answer behind it.', 'claim @(1) replaces a disputed claim without a human answer').
decl(rule, discovery_budget_raised(int), 'A larger lap budget replaces this one.', 'a budget larger than @(1) laps exists').
decl(rule, discovery_ready, 'Discovery is clean and ready for the human to decide GO, NO-GO, or HOLD.', 'discovery is ready for the human to decide').
decl(rule, discovery_decide, 'The human must decide now: discovery is ready, or the budget is spent.', 'the human must decide now').
decl(rule, model_run_of(ref(subject), ref(model)), 'The log is a run of the model at some digest.', 'log @(1) is a run of model @(2)').
decl(rule, discovery_old_run(ref(subject), ref(model)), 'The log has a run of the model at a digest that is not the current one.', 'log @(1) has a run of an older digest of model @(2)').
decl(rule, model_run_current(ref(subject), ref(model)), 'The log is a run of the model at its current digest, and at no older digest.', 'log @(1) is a current run of model @(2)').
decl(rule, model_run_stale(ref(subject), ref(model)), 'The log is a run of the model at an older digest.', 'log @(1) is an old run of model @(2)').
decl(rule, model_verdict(ref(attest), ref(model), term, atom), 'A verdict that counts: its attestation, model, check, and result.', 'attestation @(1) gives model @(2) the result @(4) on check @(3)').
decl(rule, model_calibration(ref(attest), ref(model), atom), 'A calibration that counts: its attestation, model, and result.', 'attestation @(1) gives model @(2) the calibration result @(3)').
decl(rule, model_mutation(ref(attest), ref(model), atom, atom), 'A mutation check that counts: its attestation, model, rule, and result.', 'attestation @(1): rule @(3) of model @(2) was @(4)').
decl(rule, model_has_parent(ref(model)), 'The model is derived from some model.', 'model @(1) is derived from a model').
decl(rule, model_root(ref(model)), 'The model is an existing-world model: it is derived from no model.', 'model @(1) is an existing-world model').
decl(rule, model_is_derived(ref(model)), 'The model is a target model derived from an existing-world model.', 'model @(1) is a target model').
decl(rule, model_same_tool(ref(model), ref(model)), 'The two models use the same tool.', 'models @(1) and @(2) use the same tool').
decl(rule, model_sane(ref(model)), 'A sanity check of the model passed, and none failed.', 'model @(1) is sane').
decl(rule, model_sanity_failed(ref(model)), 'A sanity check of the model failed or was unknown.', 'a sanity check of model @(1) failed').
decl(rule, model_calibrated(ref(model)), 'The model gives the same result as the current system for a known case.', 'model @(1) matches the current system on a known case').
decl(rule, model_diverges(ref(model)), 'The model disagrees with the current system.', 'model @(1) disagrees with the current system').
decl(rule, model_trusted(ref(model)), 'The model is sane, does not diverge, and it or the model that it changes is calibrated.', 'model @(1) is trusted').
decl(rule, model_decided(ref(model), ref(claim)), 'A check of the model that names the claim gave a decided result.', 'model @(1) decided a check of claim @(2)').
decl(rule, model_vacuous(ref(attest)), 'An applies check shows that the claim can never apply.', 'attestation @(1) shows a vacuous claim').
decl(rule, model_breaks(ref(model), ref(claim)), 'The model shows a case that breaks the claim.', 'model @(1) breaks claim @(2)').
decl(rule, model_unfiled_break(ref(claim)), 'A model breaks the current claim, and no disproof is filed.', 'claim @(1) is broken with no disproof filed').
decl(rule, model_check_case(ref(model), term), 'A counted verdict on this check of the model shows a case.', 'check @(2) of model @(1) shows a case').
decl(rule, model_check_no_case(ref(model), term), 'A counted verdict on this check of the model shows no case.', 'check @(2) of model @(1) shows no case').
decl(rule, model_solvers_disagree(ref(model)), 'Counted verdicts on one check of the model show a case and no case.', 'the solvers disagree on a check of model @(1)').
decl(rule, has_falsifier(ref(claim)), 'A check, or a trusted model with a decided check of the claim, can falsify the claim.', 'claim @(1) has a falsifier').
decl(rule, no_falsifier(ref(claim)), 'A current claim that nothing can falsify.', 'claim @(1) has no falsifier').
decl(rule, needs_question(ref(finding)), 'A conflict, surprise, or scope finding needs a question for the human.', 'finding @(1) needs a question for the human').
decl(rule, has_question(ref(finding)), 'The finding raised a question.', 'finding @(1) raised a question').
decl(rule, unasked_finding(ref(finding)), 'A finding that needs a question, but raised none.', 'finding @(1) needs a question, and none was raised').
decl(rule, question_waits(ref(question)), 'A question that evidence raised, and that the human did not answer.', 'question @(1) waits for the human').
decl(rule, about_system(ref(finding)), 'A finding about the behavior of the current system.', 'finding @(1) is about the current system').
decl(rule, finding_confirmed(ref(finding)), 'A reproduction on system evidence confirms the finding.', 'the current system confirms finding @(1)').
decl(rule, finding_lead(ref(finding)), 'A finding about the current system that only a model shows.', 'finding @(1) is a lead from a model only').
decl(rule, rule_has_reason(ref(model), atom), 'A reason is recorded for the rule of the model.', 'rule @(2) of model @(1) has a recorded reason').
decl(rule, weak_rule(atom), 'A rule that survived its mutation check, with no recorded reason.', 'rule @(1) survived its mutation check with no reason').
decl(rule, touched_system, 'Discovery has evidence from the current system.', 'discovery touched the current system').
decl(rule, budget_spent, 'The last lap of the largest budget is done.', 'the lap budget is spent').
decl(rule, some_hypothesis, 'Some hypothesis is recorded.', 'some hypothesis is recorded').
decl(rule, some_untouched_hypothesis, 'Some hypothesis has no result from the current system.', 'some hypothesis was not checked on the current system').
decl(rule, some_no_falsifier, 'Some current claim has no falsifier.', 'some current claim has no falsifier').
decl(rule, some_question_waits, 'Some question waits for the human.', 'some question waits for the human').
decl(rule, some_unasked_finding, 'Some finding needs a question.', 'some finding needs a question').
decl(rule, some_current_refuted, 'Some current claim is refuted.', 'some current claim is refuted').
decl(rule, some_weak_rule, 'Some rule is weak.', 'some rule survived its mutation check with no reason').
decl(rule, some_model_problem, 'Some model diverges, is vacuous, breaks a claim with no disproof, or has solvers that disagree.', 'some model has an open problem').
decl(rule, some_unratified_supersession, 'Some claim replaces a disputed claim with no human answer behind it.', 'some claim replaces a disputed claim without a human answer').

% --- A disproof names the claim (a helper, because model_unfiled_break reads it under not) ---
discovery_disproof_filed(C) :- attest(_, disproof, _, verdict(C, refuted), _, _).

% --- Evidence from the current system ---
discovery_model_artifact(S) :- model(S, _).
discovery_model_artifact(S) :- model_run(S, _, _).
discovery_model_artifact(S) :- discovery_evidence(S, model).
discovery_system_evidence(S) :- discovery_evidence(S, system), not discovery_model_artifact(S).
touched_system :- attest(_, reproduction, S, _, _, _), discovery_system_evidence(S).
touched_system :- attest(_, test_result, K, _, _, _), discovery_system_evidence(K).
discovery_hypothesis_touched(H) :- attest(_, reproduction, S, result(H, _), _, _), discovery_system_evidence(S).
discovery_has_outcome :- current(_).
discovery_has_outcome :- attest(_, reproduction, S, result(_, not_reproduced), _, _), discovery_system_evidence(S).

% --- Model verdicts count only for the current digest of their own model ---
% A log that also has a run at an older digest does not count: reusing a log for a new
% digest must not bring its old verdicts back.
model_run_of(S, M) :- model_run(S, M, _).
discovery_old_run(S, M) :- model_run(S, M, D), subject(M, _, D1), D \= D1.
model_run_current(S, M) :- model_run(S, M, D), subject(M, _, D), not discovery_old_run(S, M).
model_run_stale(S, M) :- model_run(S, M, _), not model_run_current(S, M).
model_verdict(A, M, K, R) :- attest(A, model_result, S, verdict(M, K, R), _, _), model_run_current(S, M).
model_calibration(A, M, R) :- attest(A, model_result, S, calibration(M, _, R), _, _), model_run_current(S, M).
model_mutation(A, M, Rule, R) :- attest(A, model_result, S, mutation(M, Rule, R), _, _), model_run_current(S, M).
discovery_result_model(verdict(M, _, _), M).
discovery_result_model(calibration(M, _, _), M).
discovery_result_model(mutation(M, _, _), M).

discovery_sanity_ok(sat).
discovery_sanity_ok(reached).
discovery_sanity_ok(violated).
discovery_decided(sat).
discovery_decided(unsat).
discovery_decided(reached).
discovery_decided(violated).
discovery_decided(holds).
discovery_has_case(sat).
discovery_has_case(reached).
discovery_has_case(violated).
discovery_no_case(unsat).
discovery_no_case(holds).

% --- Trust: sane, calibrated, and no divergence from the current system ---
model_sanity_failed(M) :- model_verdict(_, M, sanity, R), not discovery_sanity_ok(R).
model_sane(M) :- model_verdict(_, M, sanity, R), discovery_sanity_ok(R), not model_sanity_failed(M).
model_calibrated(M) :- model_calibration(_, M, matches).
% A target is derived from a root. A model in a derived_from cycle is no target, so it
% gets the existing-world bad-case check (ED9 flags the cycle).
model_has_parent(M) :- derived_from(M, _).
model_root(M) :- model(M, _), not model_has_parent(M).
model_is_derived(M) :- derived_from(M, M0), model_root(M0).
model_diverges(M) :- model_calibration(_, M, differs).
% A model divergence counts on any subject, except a log of an older digest of the model.
model_diverges(M) :- attest(_, divergence, S, model(M), _, _), not model_run_stale(S, M).
% The existing-world model must reproduce the reported bad case.
model_diverges(M) :- model_verdict(_, M, bad_case, R), discovery_no_case(R), not model_is_derived(M).
model_same_tool(M, M0) :- model(M, T), model(M0, T).
model_trusted(M) :- model_sane(M), model_calibrated(M), not model_diverges(M).
% A target model inherits trust, one level only, from the calibrated model that it
% changes, when both use the same tool.
model_trusted(M) :- model_sane(M), derived_from(M, M0), model_same_tool(M, M0),
    model_sane(M0), model_calibrated(M0), not model_diverges(M0), not model_diverges(M).

% --- Other verdicts ---
model_decided(M, C) :- model_verdict(_, M, preserve(C), R), discovery_decided(R).
model_decided(M, C) :- model_verdict(_, M, applies(C), R), discovery_decided(R).
model_vacuous(A) :- model_verdict(A, _, applies(_), R), discovery_no_case(R).
model_breaks(M, C) :- model_verdict(_, M, preserve(C), R), discovery_has_case(R).
model_breaks(M, C) :- model_verdict(_, M, bad_case, R), discovery_has_case(R),
    model_is_derived(M), encodes(M, C), claim(C, introduce, _).
model_unfiled_break(C) :- model_breaks(_, C), current(C), not discovery_disproof_filed(C).
% No disequality here: R1 \= R2 over a self-join is very slow in s(CASP).
model_check_case(M, K) :- model_verdict(_, M, K, R), discovery_has_case(R).
model_check_no_case(M, K) :- model_verdict(_, M, K, R), discovery_no_case(R).
model_solvers_disagree(M) :- model_check_case(M, K), model_check_no_case(M, K).

% --- Each current claim needs a falsifier: a check, or a trusted model that decided it ---
has_falsifier(C) :- check(_, C).
has_falsifier(C) :- encodes(M, C), model_decided(M, C), model_trusted(M).
no_falsifier(C) :- current(C), not has_falsifier(C).

% --- Questions ---
discovery_is_finding(X) :- finding(X, _, _).
discovery_is_hypothesis(X) :- hypothesis(X, _, _).
needs_question(F) :- finding(F, conflict(_), _).
needs_question(F) :- finding(F, surprise(_), _).
needs_question(F) :- finding(F, scope(_), _).
has_question(F) :- raised_by(_, F).
unasked_finding(F) :- needs_question(F), not has_question(F).
question_waits(Q) :- raised_by(Q, _), not answered(Q).

% --- Leads ---
about_system(F) :- finding(F, root_cause(_), _).
about_system(F) :- finding(F, trace(_), _).
about_system(F) :- finding(F, surprise(_), _).
finding_confirmed(F) :- attest(_, reproduction, S, confirms(F), _, _), discovery_system_evidence(S).
finding_lead(F) :- finding(F, _, model), about_system(F), not finding_confirmed(F).

% --- Mutation checks ---
rule_has_reason(M, R) :- reason(M, R, _).
weak_rule(R) :- model_mutation(_, M, R, survived), not rule_has_reason(M, R).

% --- Only the human changes the scope: a disputed claim is replaced only after an answer ---
discovery_ratified(C) :- question(Q, C, _), answered(Q).
discovery_disputed(C) :- refuted(C).
discovery_disputed(C) :- contested(C).
discovery_unratified(New) :- supersedes(New, Old), discovery_disputed(Old),
    not discovery_ratified(Old), not discovery_ratified(New).

% --- Budget: the largest budget counts, because the KB is append-only ---
discovery_budget_raised(B) :- budget(laps, B), budget(laps, B2), B2 > B.
budget_spent :- budget(laps, B), lap_done(B), not discovery_budget_raised(B).

% --- "There is no such X" needs a helper with no arguments (hazard H1) ---
some_hypothesis :- hypothesis(_, _, _).
some_untouched_hypothesis :- hypothesis(H, _, _), not discovery_hypothesis_touched(H).
some_no_falsifier :- no_falsifier(_).
some_question_waits :- question_waits(_).
some_unasked_finding :- unasked_finding(_).
some_current_refuted :- refuted(C), current(C).
some_weak_rule :- weak_rule(_).
some_model_problem :- model_diverges(_).
some_model_problem :- model_vacuous(_).
some_model_problem :- model_unfiled_break(_).
some_model_problem :- model_solvers_disagree(_).
some_unratified_supersession :- discovery_unratified(_).

% --- The gate: clean only ---
discovery_ready :- some_hypothesis, touched_system, discovery_has_outcome,
    not some_untouched_hypothesis,
    not some_no_falsifier,
    not some_question_waits,
    not some_unasked_finding,
    not some_current_refuted,
    not some_weak_rule,
    not some_model_problem,
    not some_unratified_supersession,
    not any_to_ask.
% The human decides when discovery is clean, or when the budget is spent.
discovery_decide :- discovery_ready.
discovery_decide :- budget_spent.

% --- Lint hooks. A code that starts with E is an error. Any other code is a warning. ---
% The core declares lint_issue(atom, ref, text), so each Id is an existing id.
lint_issue('WD1', F, 'This finding needs a question for the human. Add the question, then raised_by(Question, Finding).') :-
    unasked_finding(F).
lint_issue('WD2', M, 'This model states a claim, but it is not trusted. Its verdicts do not count yet.') :-
    encodes(M, _), not model_trusted(M).
lint_issue('WD3', A, 'A rule survived the mutation check in this attestation. Find out why, then add reason(Model, Rule, Text).') :-
    model_mutation(A, M, R, survived), not rule_has_reason(M, R).
lint_issue('WD4', F, 'Only a model shows this finding. It is a lead until evidence from the current system confirms it.') :-
    finding_lead(F).
lint_issue('WD5', A, 'This check gave unknown. It is a gap, not UNSAT, so it falsifies nothing.') :-
    model_verdict(A, _, _, unknown).
lint_issue('WD6', A, 'The problem did not reproduce on the current system. This is a NO-GO candidate. Tell the human.') :-
    attest(A, reproduction, S, result(_, not_reproduced), _, _), discovery_system_evidence(S).
lint_issue('WD7', H, 'No result from the current system exists for this hypothesis. Reproduce it, or ask the human if it is a separate ticket.') :-
    hypothesis(H, _, _), not discovery_hypothesis_touched(H).
lint_issue('WD8', A, 'This model result is on a log of an older digest of the model. It does not count. Run the solver again, into a new log.') :-
    attest(A, model_result, S, P, _, _), discovery_result_model(P, M), model_run_stale(S, M).
lint_issue('ED1', A, 'This reproduction must point at evidence from the current system. Tag the subject with discovery_evidence(Subject, system); a model or a solver log is not system evidence.') :-
    attest(A, reproduction, S, _, _, _), not discovery_system_evidence(S).
lint_issue('ED2', A, 'This model result must point at a solver log of its own model. Add model_run(Log, Model, Digest) for the log.') :-
    attest(A, model_result, S, P, _, _), discovery_result_model(P, M), not model_run_of(S, M).
lint_issue('ED3', M, 'This model disagrees with the current system. Fix the model before you use any of its verdicts.') :-
    model_diverges(M).
lint_issue('ED4', A, 'This applies check shows that the claim can never apply. The claim holds only vacuously.') :-
    model_vacuous(A).
lint_issue('ED5', C, 'A model breaks this current claim, and no disproof is filed. File a disproof with the case.') :-
    model_unfiled_break(C).
lint_issue('ED6', M, 'Two solver results for the same check of this model disagree: one shows a case, one shows none.') :-
    model_solvers_disagree(M).
lint_issue('ED7', C, 'This claim replaces a refuted or contested claim, but no human answered a question about either claim. Only the human changes the scope.') :-
    discovery_unratified(C).
lint_issue('ED8', Q, 'This question must be raised by a finding or a hypothesis.') :-
    raised_by(Q, X), not discovery_is_finding(X), not discovery_is_hypothesis(X).
lint_issue('ED9', M, 'This model is derived from a model that is itself derived from a model. Derive a target model only from an existing-world model.') :-
    derived_from(M, M0), not model_root(M0).

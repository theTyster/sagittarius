% ---- /home/ty/.dotfiles/shared/link/.local/share/orbit-kb/core.pl
% orbit-kb core library (core.pl)
%
% orbit-kb always loads this file first. Then it loads the modules that
% uses/1 in kb.pl names, then kb.pl, then rules.pl. The text is s(CASP)
% source. SWI-Prolog can read it with the s(CASP) operators.
%
% FILE FORMAT
%
% decl(Kind, Head, Doc, Template) declares one predicate.
%   Kind      fact or rule. A fact predicate gets ground facts in kb.pl
%             only. A rule predicate gets clauses in library files or in
%             rules.pl only. A fact for a rule predicate is an error.
%   Head      Name(Type1, ..., TypeN), or Name alone for no arguments.
%             The types are id, ref(Name), ref, oneof(List), alt(Shapes),
%             text, atom, int, time, digest, by, term, attest_predicate.
%   Doc       One plain sentence.
%   Template  The text for the #pred line. @(1), @(2), ... stand for the
%             arguments by position. Use '' for no template. orbit-kb
%             writes the #pred lines, so do not write them here.
%
% attest_type(Type, Shape, Writers, Doc) declares one attestation type.
%   Shape     The type of the predicate, the 4th argument of attest/6.
%   Writers   A sub-list of [human, agent, script]. [script] means that
%             only orbit-kb run writes this type.
%   Doc       One plain sentence.
%
% Write all text as single-quoted atoms. Do not use double-quoted strings.
%
% EVERY PREDICATE MUST BE DECLARED
%
% Declare every predicate with decl/4. This includes rule predicates and
% helper predicates. orbit-kb adds an empty stub for each declared
% predicate, and it runs s(CASP) with --unknown=error. Thus a predicate
% that is not declared, or a misspelled name, causes an error.
%
% HAZARD H1: A VARIABLE ONLY UNDER not IS EXISTENTIAL
%
% In s(CASP), a variable that occurs only in a not literal means "some
% value", not "every value". Thus "done :- not under(_)." is true even
% when under(c1) is true. A not literal must not hold a variable that
% occurs nowhere else in the clause. This includes _. Lint error E12
% finds this problem. To correct it, put the variable in a helper
% predicate, declare the helper, and negate the helper:
%
%     any_under :- under(_).
%     done :- not any_under.


% ---------------------------------------------------------------------
% Core facts
% ---------------------------------------------------------------------

decl(fact, request(id, text),
     'The request of the human, word for word.',
     'the human made request @(1): @(2)').
decl(fact, ticket(ref(subject)),
     'The subject that holds the ratified ticket.',
     'subject @(1) holds the ratified ticket').
decl(fact, claim(id, oneof([preserve, retire, introduce]), text),
     'A claim about the request, with a label: preserve (it stays true), retire (it becomes false), or introduce (it becomes true).',
     '@(1) is a claim to @(2): @(3)').
decl(fact, cites(ref(claim), text),
     'The text of the request or the ticket that the claim serves.',
     'claim @(1) serves the request text @(2)').
decl(fact, example(ref(claim), text),
     'A concrete case of the claim.',
     'an example of claim @(1) is @(2)').
decl(fact, supersedes(ref(claim), ref(claim)),
     'The first claim replaces the second claim.',
     'claim @(1) replaces claim @(2)').
decl(fact, universal(ref(claim)),
     'The claim says that something is true for every input.',
     'claim @(1) is about every input').
decl(fact, check(id, ref(claim)),
     'An executable check of the claim.',
     '@(1) is a check of claim @(2)').
decl(fact, world(term),
     'A fact about the current state; a state that is not recorded is false.',
     'in the current state, @(1) is true').
decl(fact, source(term, text),
     'Where a world fact was observed, such as a file and line, a configuration key, a query, or a log.',
     'the world fact @(1) was observed at @(2)').
decl(fact, scope(oneof([in, out]), text),
     'An item that is in scope or out of scope.',
     'the scope marks @(2) as @(1)').
decl(fact, risk(id, text),
     'A risk to the work.',
     '@(1) is a risk: @(2)').
decl(fact, assumption(id, text),
     'An assumption that the work relies on.',
     '@(1) is an assumption: @(2)').
decl(fact, not_explored(text),
     'An area that nobody explored.',
     'nobody explored @(1)').
decl(fact, question(id, ref(claim), text),
     'A dormant question about a claim.',
     '@(1) is a question about claim @(2): @(3)').
decl(fact, assumed(ref(question), term),
     'The default answer to a question.',
     'the default answer to question @(1) is @(2)').
decl(fact, answer(ref(question), term, oneof([human, agent])),
     'An answer to a question, and who gave it.',
     'the @(3) answered question @(1) with @(2)').
decl(fact, depends(ref(question), ref(question)),
     'The first question depends on the answer to the second question.',
     'question @(1) depends on question @(2)').
decl(fact, note(ref, text),
     'A free-text note about any id.',
     'a note on @(1) says @(2)').
decl(fact, subject(id, text, digest),
     'An artifact path and its sha256 digest; a relative path starts at the KB directory.',
     'subject @(1) is @(2) with digest @(3)').
decl(fact, attest(id, atom, ref, attest_predicate, by, time),
     'An attestation with its id, type, subject, predicate, writer, and time.',
     'attestation @(1) of type @(2) records @(4) about @(3), by the @(5) at @(6)').

% ---------------------------------------------------------------------
% Core rule predicates
% ---------------------------------------------------------------------

decl(rule, superseded(ref(claim)),
     'Another claim replaces the claim.',
     'claim @(1) is superseded').
decl(rule, current(ref(claim)),
     'The claim is in force, because no other claim replaces it.',
     'claim @(1) is current').
decl(rule, answered(ref(question)),
     'A human answered the question.',
     'a human answered question @(1)').
decl(rule, defeated(ref(question)),
     'A human answer to the question differs from its default answer.',
     'a human answer defeats the default of question @(1)').
decl(rule, refuted(ref(claim)),
     'An attestation gives the verdict refuted for the claim.',
     'claim @(1) is refuted').
decl(rule, contested(ref(claim)),
     'At least one divergence attestation names the claim.',
     'claim @(1) is contested').
decl(rule, contested_twice(ref(claim)),
     'Two or more different divergence attestations name the claim.',
     'claim @(1) is contested two or more times').
decl(rule, to_ask(ref(question)),
     'Ask this question now, because no human answered it, its claim is current, and its claim is contested or a question that it depends on is defeated.',
     'question @(1) must be asked now').
decl(rule, any_to_ask,
     'At least one question must be asked now.',
     'some question must be asked now').
decl(rule, stale(ref(attest)),
     'The approval names a digest that differs from the current digest of its subject.',
     'approval @(1) is stale').
decl(rule, passed(ref(check)),
     'The check passed in a run, and no later run of the check failed.',
     'check @(1) passed with no later fail').
decl(rule, failed_after(ref(check), int),
     'The check failed in a run with a higher number than the given run.',
     'check @(1) failed in a run after run @(2)').
decl(rule, was_red(ref(check)),
     'The check failed in a run before a run in which it passed.',
     'check @(1) failed before it passed').
decl(rule, lint_issue(atom, ref, text),
     'A lint result that a module adds, with a code, an id, and a message.',
     'lint issue @(1) on @(2): @(3)').

% ---------------------------------------------------------------------
% Core attestation types
% ---------------------------------------------------------------------

attest_type(disclosure,
            alt([guess(ref(question)), unverified(text), disagreement(text),
                 out_of_scope(text), self_error(text), other(text)]),
            [agent, human],
            'The writer discloses a guess, an unverified point, a disagreement, an item out of scope, an error of its own, or another point.').
attest_type(divergence,
            alt([claim(ref(claim)), hypothesis(term), model(term)]),
            [human, agent],
            'A view does not agree with a claim, a hypothesis, or a model; a note holds the description.').
attest_type(disproof,
            verdict(ref(claim), oneof([refuted, inconclusive, abstained])),
            [agent],
            'The verdict of an attempt to break a claim.').
attest_type(approval,
            digest(digest),
            [human],
            'A human approves the subject at this digest.').
attest_type(test_result,
            result(ref(check), int, oneof([pass, fail])),
            [script],
            'The result of one numbered run of a check; only orbit-kb run writes it.').

% ---------------------------------------------------------------------
% Core rules
% ---------------------------------------------------------------------

superseded(C) :- supersedes(_, C).
current(C) :- claim(C, _, _), not superseded(C).
answered(Q) :- answer(Q, _, human).
defeated(Q) :- assumed(Q, A), answer(Q, B, human), A \= B.
refuted(C) :- attest(_, _, _, verdict(C, refuted), _, _).
contested(C) :- attest(_, divergence, _, claim(C), _, _).
contested_twice(C) :- attest(D1, divergence, _, claim(C), _, _),
                      attest(D2, divergence, _, claim(C), _, _), D1 \= D2.
to_ask(Q) :- question(Q, C, _), current(C), depends(Q, P), defeated(P), not answered(Q).
to_ask(Q) :- question(Q, C, _), current(C), contested(C), not answered(Q).
any_to_ask :- to_ask(_).
stale(A) :- attest(A, approval, S, digest(D0), human, _), subject(S, _, D1), D0 \= D1.
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _),
              attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
% lint_issue/3 has no clauses here. Modules add them (the module lint hook).

% ---- /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/modules/discovery.pl
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

% ---- kb.pl (variant pl_tla_now_holds)
uses([discovery]).
request(r1, 'A customer used two discount codes and paid less than our minimum price.').
hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.').
budget(laps, 3).
world(clamp_after_first_code).
source(clamp_after_first_code, 'CheckoutService.ApplyCodes').
subject(log4417, 'logs/order-4417.log', 'sha256:eb7c1b78c9b566eecc2b843bcfa4714537b0e739caf9608fc7aac528c3d94599').
discovery_evidence(log4417, system).
attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z').
note(a1, 'The payment log shows that order 4417 was charged $25.00. Its floor is $30.00.').
claim(c1, introduce, 'No order is charged below its floor price.').
claim(c2, preserve, 'Each code takes off its full amount.').
cites(c1, 'paid less than our minimum price').
cites(c2, 'used two discount codes').
check(t1, c1).
discovery_evidence(t1, system).
example(c1, 'Order 4417: list $40.00, floor $30.00, codes $5.00 and $10.00. Charge $30.00.').
attest(a2, test_result, t1, result(t1, 1, fail), script, '2026-10-15T09:15:00Z').
scope(in, 'two or more fixed-amount codes at checkout').
scope(out, 'gift cards').
risk(k1, 'The change alters the price of each order whose codes cross the floor.').
assumption(s1, 'Every code takes off a fixed amount.').
subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db').
model(m_now, smt).
subject(run_now, 'logs/discount-now.log', 'sha256:28a3707031369687b040d9bdf2ad89bba2123be3af93c78b285975c970478db0').
model_run(run_now, m_now, 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db').
attest(a3, model_result, run_now, verdict(m_now, sanity, sat), agent, '2026-10-15T09:20:00Z').
attest(a4, model_result, run_now, calibration(m_now, example(c1), matches), agent, '2026-10-15T09:21:00Z').
note(a4, 'The model gives 2500 cents for order 4417. The payment log shows 2500 cents.').
attest(a5, model_result, run_now, verdict(m_now, bad_case, sat), agent, '2026-10-15T09:22:00Z').
attest(a6, model_result, run_now, verdict(m_now, root_cause(clamp_after_both_codes), unsat), agent, '2026-10-15T09:25:00Z').
attest(a7, model_result, run_now, verdict(m_now, normal_case(one_code), unsat), agent, '2026-10-15T09:25:00Z').
attest(a8, model_result, run_now, verdict(m_now, normal_case(both_codes_above_floor), unsat), agent, '2026-10-15T09:25:00Z').
finding(f1, root_cause(clamp_after_first_code), model).
attest(a9, reproduction, log4417, confirms(f1), agent, '2026-10-15T09:35:00Z').
note(a9, 'The log of order 4417 shows the clamp after the first code, and no clamp after the second code.').
subject(m_target, 'models/discount-target.smt2', 'sha256:ac17a45536f31f4c27d0f85194dc4690e2aca118122023697632ec30908b664b').
model(m_target, smt).
derived_from(m_target, m_now).
subject(run_target, 'logs/discount-target.log', 'sha256:5355c75966ab906302c1bf6e59c2347af104709df24b6acd5d653c266d232608').
model_run(run_target, m_target, 'sha256:ac17a45536f31f4c27d0f85194dc4690e2aca118122023697632ec30908b664b').
attest(a10, model_result, run_target, verdict(m_target, together, unsat), agent, '2026-10-15T09:45:00Z').
finding(f2, conflict([c1_floor, c2_full_codes, order4417]), model).
note(f2, 'Unsat core for order 4417: c1_floor, c2_full_codes, order_4417.').
question(q1, c2, 'Order 4417: full codes give $25.00, and the floor says at least $30.00. Which one gives?').
assumed(q1, floor_wins).
raised_by(q1, f2).
answer(q1, floor_wins, human).
attest(a12, divergence, run_target, claim(c2), agent, '2026-10-15T10:05:00Z').
note(a12, 'The human answered q1: the floor wins. So c2 gives, and c2b supersedes it. Finding f2 holds the unsat core.').
lap_done(1).
claim(c2b, preserve, 'Each code takes off its full amount, down to the floor price.').
supersedes(c2b, c2).
cites(c2b, 'used two discount codes').
encodes(m_target, c1).
encodes(m_target, c2b).
attest(a13, model_result, run_target, verdict(m_target, sanity, sat), agent, '2026-10-15T10:20:00Z').
note(a13, 'Check 4 is sat, so the target rules admit an order.').
attest(a14, model_result, run_target, verdict(m_target, bad_case, unsat), agent, '2026-10-15T10:20:00Z').
attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), unsat), agent, '2026-10-15T10:20:00Z').
attest(a16, model_result, run_target, verdict(m_target, applies(c1), sat), agent, '2026-10-15T10:20:00Z').
example(c1, 'List $40.00, floor $30.00, codes $5.00 and $5.01. Charge $30.00.').
attest(a17, model_result, run_target, mutation(m_target, clamp, killed), agent, '2026-10-15T10:20:00Z').
example(c2b, 'List $40.00, floor $20.00, codes $5.00 and $10.00. Charge $25.00.').
example(c2b, 'List $40.00, floor $30.00, one code $5.00. Charge $35.00.').
not_explored('percentage codes').
not_explored('codes on single items').
not_explored('refunds of orders with codes').
subject(m_tla, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db').
model(m_tla, tla).
subject(run_tla, 'logs/discount-now.log', 'sha256:28a3707031369687b040d9bdf2ad89bba2123be3af93c78b285975c970478db0').
model_run(run_tla, m_tla, 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db').
attest(a18, model_result, run_tla, verdict(m_tla, sanity, reached), agent, '2026-10-15T11:00:00Z').
attest(a19, model_result, run_tla, calibration(m_tla, example(c1), matches), agent, '2026-10-15T11:00:00Z').
attest(a20, model_result, run_tla, verdict(m_tla, bad_case, holds), agent, '2026-10-15T11:00:00Z').
% ---- stubs
ticket(_):-false.
universal(_):-false.
depends(_, _):-false.
reason(_, _, _):-false.
% ---- #pred lines from templates
#pred request(A1,A2) :: 'the human made request @(A1): @(A2)'.
#pred ticket(A1) :: 'subject @(A1) holds the ratified ticket'.
#pred claim(A1,A2,A3) :: '@(A1) is a claim to @(A2): @(A3)'.
#pred cites(A1,A2) :: 'claim @(A1) serves the request text @(A2)'.
#pred example(A1,A2) :: 'an example of claim @(A1) is @(A2)'.
#pred supersedes(A1,A2) :: 'claim @(A1) replaces claim @(A2)'.
#pred universal(A1) :: 'claim @(A1) is about every input'.
#pred check(A1,A2) :: '@(A1) is a check of claim @(A2)'.
#pred world(A1) :: 'in the current state, @(A1) is true'.
#pred source(A1,A2) :: 'the world fact @(A1) was observed at @(A2)'.
#pred scope(A1,A2) :: 'the scope marks @(A2) as @(A1)'.
#pred risk(A1,A2) :: '@(A1) is a risk: @(A2)'.
#pred assumption(A1,A2) :: '@(A1) is an assumption: @(A2)'.
#pred not_explored(A1) :: 'nobody explored @(A1)'.
#pred question(A1,A2,A3) :: '@(A1) is a question about claim @(A2): @(A3)'.
#pred assumed(A1,A2) :: 'the default answer to question @(A1) is @(A2)'.
#pred answer(A1,A2,A3) :: 'the @(A3) answered question @(A1) with @(A2)'.
#pred depends(A1,A2) :: 'question @(A1) depends on question @(A2)'.
#pred note(A1,A2) :: 'a note on @(A1) says @(A2)'.
#pred subject(A1,A2,A3) :: 'subject @(A1) is @(A2) with digest @(A3)'.
#pred attest(A1,A2,A3,A4,A5,A6) :: 'attestation @(A1) of type @(A2) records @(A4) about @(A3), by the @(A5) at @(A6)'.
#pred superseded(A1) :: 'claim @(A1) is superseded'.
#pred current(A1) :: 'claim @(A1) is current'.
#pred answered(A1) :: 'a human answered question @(A1)'.
#pred defeated(A1) :: 'a human answer defeats the default of question @(A1)'.
#pred refuted(A1) :: 'claim @(A1) is refuted'.
#pred contested(A1) :: 'claim @(A1) is contested'.
#pred contested_twice(A1) :: 'claim @(A1) is contested two or more times'.
#pred to_ask(A1) :: 'question @(A1) must be asked now'.
#pred any_to_ask :: 'some question must be asked now'.
#pred stale(A1) :: 'approval @(A1) is stale'.
#pred passed(A1) :: 'check @(A1) passed with no later fail'.
#pred failed_after(A1,A2) :: 'check @(A1) failed in a run after run @(A2)'.
#pred was_red(A1) :: 'check @(A1) failed before it passed'.
#pred lint_issue(A1,A2,A3) :: 'lint issue @(A1) on @(A2): @(A3)'.
#pred hypothesis(A1,A2,A3) :: 'hypothesis @(A1) is a @(A2): @(A3)'.
#pred budget(A1,A2) :: 'the budget is @(A2) @(A1)'.
#pred lap_done(A1) :: 'lap @(A1) is done'.
#pred model(A1,A2) :: 'subject @(A1) is a model for @(A2)'.
#pred model_run(A1,A2,A3) :: 'log @(A1) is a run of model @(A2) at digest @(A3)'.
#pred derived_from(A1,A2) :: 'model @(A1) is derived from model @(A2)'.
#pred encodes(A1,A2) :: 'model @(A1) states claim @(A2)'.
#pred finding(A1,A2,A3) :: 'finding @(A1) is @(A2), from the @(A3)'.
#pred reason(A1,A2,A3) :: 'rule @(A2) of model @(A1) survived its mutation check because @(A3)'.
#pred raised_by(A1,A2) :: 'question @(A1) was raised by @(A2)'.
#pred discovery_evidence(A1,A2) :: '@(A1) is evidence from the @(A2)'.
#pred discovery_disproof_filed(A1) :: 'a disproof of claim @(A1) is filed'.
#pred discovery_model_artifact(A1) :: '@(A1) is a model artifact'.
#pred discovery_system_evidence(A1) :: '@(A1) is evidence from the current system'.
#pred discovery_hypothesis_touched(A1) :: 'the current system was checked for hypothesis @(A1)'.
#pred discovery_has_outcome :: 'discovery has a ticket or a NO-GO candidate'.
#pred discovery_sanity_ok(A1) :: '@(A1) passes a sanity check'.
#pred discovery_decided(A1) :: '@(A1) is a decided result'.
#pred discovery_has_case(A1) :: '@(A1) shows a case'.
#pred discovery_no_case(A1) :: '@(A1) shows no case'.
#pred discovery_result_model(A1,A2) :: 'the result @(A1) is about model @(A2)'.
#pred discovery_is_finding(A1) :: '@(A1) is a finding'.
#pred discovery_is_hypothesis(A1) :: '@(A1) is a hypothesis'.
#pred discovery_ratified(A1) :: 'a human answered a question about claim @(A1)'.
#pred discovery_disputed(A1) :: 'claim @(A1) is disputed'.
#pred discovery_unratified(A1) :: 'claim @(A1) replaces a disputed claim without a human answer'.
#pred discovery_budget_raised(A1) :: 'a budget larger than @(A1) laps exists'.
#pred discovery_ready :: 'discovery is ready for the human to decide'.
#pred discovery_decide :: 'the human must decide now'.
#pred model_run_of(A1,A2) :: 'log @(A1) is a run of model @(A2)'.
#pred discovery_old_run(A1,A2) :: 'log @(A1) has a run of an older digest of model @(A2)'.
#pred model_run_current(A1,A2) :: 'log @(A1) is a current run of model @(A2)'.
#pred model_run_stale(A1,A2) :: 'log @(A1) is an old run of model @(A2)'.
#pred model_verdict(A1,A2,A3,A4) :: 'attestation @(A1) gives model @(A2) the result @(A4) on check @(A3)'.
#pred model_calibration(A1,A2,A3) :: 'attestation @(A1) gives model @(A2) the calibration result @(A3)'.
#pred model_mutation(A1,A2,A3,A4) :: 'attestation @(A1): rule @(A3) of model @(A2) was @(A4)'.
#pred model_has_parent(A1) :: 'model @(A1) is derived from a model'.
#pred model_root(A1) :: 'model @(A1) is an existing-world model'.
#pred model_is_derived(A1) :: 'model @(A1) is a target model'.
#pred model_same_tool(A1,A2) :: 'models @(A1) and @(A2) use the same tool'.
#pred model_sane(A1) :: 'model @(A1) is sane'.
#pred model_sanity_failed(A1) :: 'a sanity check of model @(A1) failed'.
#pred model_calibrated(A1) :: 'model @(A1) matches the current system on a known case'.
#pred model_diverges(A1) :: 'model @(A1) disagrees with the current system'.
#pred model_trusted(A1) :: 'model @(A1) is trusted'.
#pred model_decided(A1,A2) :: 'model @(A1) decided a check of claim @(A2)'.
#pred model_vacuous(A1) :: 'attestation @(A1) shows a vacuous claim'.
#pred model_breaks(A1,A2) :: 'model @(A1) breaks claim @(A2)'.
#pred model_unfiled_break(A1) :: 'claim @(A1) is broken with no disproof filed'.
#pred model_check_case(A1,A2) :: 'check @(A2) of model @(A1) shows a case'.
#pred model_check_no_case(A1,A2) :: 'check @(A2) of model @(A1) shows no case'.
#pred model_solvers_disagree(A1) :: 'the solvers disagree on a check of model @(A1)'.
#pred has_falsifier(A1) :: 'claim @(A1) has a falsifier'.
#pred no_falsifier(A1) :: 'claim @(A1) has no falsifier'.
#pred needs_question(A1) :: 'finding @(A1) needs a question for the human'.
#pred has_question(A1) :: 'finding @(A1) raised a question'.
#pred unasked_finding(A1) :: 'finding @(A1) needs a question, and none was raised'.
#pred question_waits(A1) :: 'question @(A1) waits for the human'.
#pred about_system(A1) :: 'finding @(A1) is about the current system'.
#pred finding_confirmed(A1) :: 'the current system confirms finding @(A1)'.
#pred finding_lead(A1) :: 'finding @(A1) is a lead from a model only'.
#pred rule_has_reason(A1,A2) :: 'rule @(A2) of model @(A1) has a recorded reason'.
#pred weak_rule(A1) :: 'rule @(A1) survived its mutation check with no reason'.
#pred touched_system :: 'discovery touched the current system'.
#pred budget_spent :: 'the lap budget is spent'.
#pred some_hypothesis :: 'some hypothesis is recorded'.
#pred some_untouched_hypothesis :: 'some hypothesis was not checked on the current system'.
#pred some_no_falsifier :: 'some current claim has no falsifier'.
#pred some_question_waits :: 'some question waits for the human'.
#pred some_unasked_finding :: 'some finding needs a question'.
#pred some_current_refuted :: 'some current claim is refuted'.
#pred some_weak_rule :: 'some rule survived its mutation check with no reason'.
#pred some_model_problem :: 'some model has an open problem'.
#pred some_unratified_supersession :: 'some claim replaces a disputed claim without a human answer'.

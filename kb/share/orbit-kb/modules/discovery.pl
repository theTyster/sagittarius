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
% - D33 R3: a red run of a check tagged discovery_evidence(K, system) of an introduce or a
%   retire claim is the system result of each hypothesis that no hypothesis supersedes and
%   that was recorded before the run. A
%   red run of the check of a preserve claim is not: it says that what must stay true is
%   false now, and that blocks readiness (D33 R2).
% - D33 R4: a model is calibrated only by two matching cases on a current run: a real case
%   where the system fails (fails(Text)) and a real case where it passes (passes(Text)). A
%   model derived from a calibrated model needs its own two cases.
% - A solver counterexample to a claim is a core `disproof`, with a note and an example.
% - An unsat core is one conflict finding/3 and one question. After the human answers,
%   a core divergence goes on each claim that the answer supersedes, and only on those.
% - GO is a core approval of the ticket subject. NO-GO and HOLD are a `decision`.
% - D14: GO, NO-GO, or HOLD is a weighted vote: the human 0.49, the agent 0.24, the formal
%   artifacts 0.24. The agent and the human each attest a `vote`. orbit-kb computes the
%   vote of the formal artifacts (artifact_vote/1) and the outcome (gate/1).
% - D15: to reword a hypothesis, add a new hypothesis and supersedes(New, Old), as for a
%   claim. A superseded hypothesis is out of play: it needs no system result (WD7, the
%   readiness check), its not_reproduced result is no outcome, and it raises no WD6.
% - D30 H4: the discovery orbit is open until the human approves the ticket after a GO
%   (orbit-kb attest writes discovery_end), and again after a `back` attestation. While it
%   is closed, discovery_ready holds and WD7 is not asked: a hypothesis restated in build
%   needs no system result of its own.

% --- Facts ---
% hypothesis/3 is a core fact since 0.3.0 (K-A, D30).
decl(fact, budget(oneof([laps]), int),
     'A lap budget; when there are several, the largest one counts.',
     'the budget is @(2) @(1)').
decl(fact, lap_done(int),
     'A lap that ended with an answer from the human.',
     'lap @(1) is done').
% 0.3.0 (K-F, D40): model/2, model_run/3, encodes/2 and the attestation type
% model_result are core: a KB that uses build records a model too. D42 K3: derived_from/2
% and the rules of trust (model_trusted/1, model_decided/2, model_breaks/2 and what they read)
% are core too, so a burn of a build KB can read a model.
% D31 B5: the property of a model that states a claim, so that the report can show it.
decl(fact, property(ref(model), ref(claim), text),
     'The property of the model that states the claim: an SMT assertion or a TLA+ invariant, as written in the model.',
     'model @(1) states claim @(2) with the property @(3)').
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
% D30 H4 (0.3.0, K-A): the discovery orbit is open from the start of the KB until the
% human approves the ticket after a GO, and again after a recorded return to discovery.
decl(fact, discovery_end(ref(attest)),
     'The human approval of the ticket that ended the discovery orbit: gate(go) held when the human approved it. Only orbit-kb attest approval writes it.',
     'approval @(1) ended the discovery orbit after a GO').

% --- Attestation types ---
attest_type(reproduction,
    alt([result(ref(hypothesis), oneof([reproduced, not_reproduced])),
         confirms(ref(finding))]),
    [agent, human],
    'Evidence from the current system that cannot run as a check, such as a log or a query.').
% GO is not a decision: it is a core approval of the ticket subject.
attest_type(decision,
    alt([no_go(ref(hypothesis), text), hold(ref(hypothesis), text)]),
    [human],
    'A NO-GO or HOLD decision by the human, with its reason or what it waits for.').
% D14: one vote per writer per round. Round 1 is the first gate. After a HOLD, the next
% gate is round 2, and so on. Only the largest round counts.
attest_type(vote,
    vote(int, oneof([go, no_go, hold])),
    [agent, human],
    'A vote at the GO / NO-GO gate: the round, then go, no_go, or hold. The agent votes first.').

% D30 H4: a return to discovery (BACK) opens the discovery orbit again.
attest_type(back,
    back(text),
    [agent, human],
    'A return to discovery: the build cannot say what the hypothesis changes to, so the ticket is a report again. It opens the discovery orbit again.').

% --- Rule declarations ---
decl(rule, discovery_reopened(ref(attest)), 'A back attestation follows the discovery_end record of this approval in kb.pl. orbit-kb computes it when it reads the KB.', 'a return to discovery came after approval @(1)').
decl(rule, discovery_closed, 'The human approved the ticket after a GO (discovery_end of a human approval of the ticket), and no return to discovery came after it. Readiness and the gate are not asked again.', 'the discovery orbit is closed').
decl(rule, discovery_end_valid(ref(attest)), 'The discovery_end record names a human approval of the ticket subject (lint ED11 names one that does not).', 'approval @(1) is a human approval of the ticket').
decl(rule, vote_void(ref(attest)), 'The vote does not count: a return to discovery (back) follows it in kb.pl, so it belongs to an earlier orbit, or it came after the discovery orbit closed. orbit-kb computes it when it reads the KB (D30 H5, H8).', 'vote @(1) does not count').
decl(rule, discovery_open, 'The discovery orbit is open: from the start of the KB until the human approves the ticket after a GO, and again after a return to discovery (a back attestation).', 'the discovery orbit is open').
decl(rule, discovery_disproof_filed(ref(claim)), 'A disproof attestation refutes the claim.', 'a disproof of claim @(1) is filed').
decl(rule, discovery_model_artifact(ref), 'The id is a model file, a solver log, or is tagged as model evidence.', '@(1) is a model artifact').
decl(rule, discovery_system_evidence(ref), 'The id is tagged as system evidence and is not a model artifact.', '@(1) is evidence from the current system').
decl(rule, discovery_hypothesis_touched(ref(hypothesis)), 'A reproduction on system evidence gives a result for the hypothesis, or a check tagged as system evidence of an introduce or a retire claim failed in a run after the hypothesis was recorded (D33 R3).', 'the current system was checked for hypothesis @(1)').
decl(rule, discovery_changing_claim(ref(claim)), 'The claim is a current introduce claim or retire claim: its check fails on the current system before the build.', 'claim @(1) introduces or retires something').
decl(rule, discovery_run_after(ref(attest), ref(hypothesis)), 'The test_result comes after the hypothesis in kb.pl: the run was made while the hypothesis existed. orbit-kb computes it when it reads the KB (D33 R3).', 'run @(1) came after hypothesis @(2)').
decl(rule, discovery_has_example(ref(claim)), 'The claim has an example.', 'claim @(1) has an example').
decl(rule, discovery_no_example(ref(claim)), 'A current claim with no example (D33 R1, lint WD10).', 'claim @(1) has no example').
decl(rule, discovery_preserve_failing(ref(check)), 'The check of a current preserve claim ran, and its last run failed: what must stay true is false now (D33 R2).', 'check @(1) of a preserve claim fails now').
decl(rule, ready_blocker(term), 'One thing that blocks discovery_ready while the discovery orbit is open: the term names its kind and its id, such as untouched(h1) or no_example(c1) (D32 O2). discovery_ready holds in an open orbit exactly when ready_blocker(X) has no answer.', '@(1) blocks discovery_ready').
decl(rule, any_ready_blocker, 'Something blocks discovery_ready.', 'something blocks discovery_ready').
decl(rule, gate_allowed(oneof([go, no_go, hold])), 'The choice can win the gate: no_go and hold always; go only while discovery_ready holds (D33 R5).', '@(1) can win the gate').
decl(rule, discovery_has_outcome, 'Some claim is current, or a hypothesis that no other hypothesis replaces did not reproduce.', 'some claim is current, or some hypothesis did not reproduce').
decl(rule, discovery_result_model(term, ref(model)), 'The model that a model_result predicate is about.', 'the result @(1) is about model @(2)').
decl(rule, discovery_is_finding(ref), 'The id is a finding.', '@(1) is a finding').
decl(rule, discovery_is_hypothesis(ref), 'The id is a hypothesis.', '@(1) is a hypothesis').
decl(rule, discovery_ratified(ref(claim)), 'A human answered a question about the claim.', 'a human answered a question about claim @(1)').
decl(rule, discovery_disputed(ref(claim)), 'The claim is refuted, or a claim divergence contests it.', 'claim @(1) is disputed').
decl(rule, discovery_unratified(ref(claim)), 'A claim that supersedes a disputed claim with no human answer behind it.', 'claim @(1) replaces a disputed claim without a human answer').
decl(rule, discovery_budget_raised(int), 'A larger lap budget replaces this one.', 'a budget larger than @(1) laps exists').
decl(rule, discovery_ready, 'Discovery is clean and ready for the human to decide GO, NO-GO, or HOLD: nothing blocks it (ready_blocker). Once the discovery orbit is closed, it holds: readiness is asked only while the orbit is open.', 'discovery is ready for the human to decide').
decl(rule, discovery_decide, 'The human must decide now: discovery is ready, or the budget is spent.', 'the human must decide now').
decl(rule, model_run_of(ref(subject), ref(model)), 'The log is a run of the model at some digest.', 'log @(1) is a run of model @(2)').
decl(rule, discovery_result_key(term, term), 'What a model_result checks: the model and the verdict kind, the mutation rule, or the calibration case.', 'result @(1) checks @(2)').
decl(rule, discovery_result_renewed(ref(attest)), 'A model_result on an old run has a newer result of the same check on a current run.', 'attestation @(1) has a newer result of the same check').
decl(rule, model_mutation(ref(attest), ref(model), atom, atom), 'A mutation check that counts: its attestation, model, rule, and result.', 'attestation @(1): rule @(3) of model @(2) was @(4)').
decl(rule, model_same_tool(ref(model), ref(model)), 'The two models use the same tool.', 'models @(1) and @(2) use the same tool').
decl(rule, model_vacuous(ref(attest)), 'An applies check shows that the claim can never apply.', 'attestation @(1) shows a vacuous claim').
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
decl(rule, some_hypothesis, 'Some hypothesis is recorded, and no other hypothesis replaces it.', 'some hypothesis is recorded').
decl(rule, some_untouched_hypothesis, 'Some hypothesis that no other hypothesis replaces has no result from the current system.', 'some hypothesis was not checked on the current system').
decl(rule, some_no_falsifier, 'Some current claim has no falsifier.', 'some current claim has no falsifier').
decl(rule, some_question_waits, 'Some question waits for the human.', 'some question waits for the human').
decl(rule, some_unasked_finding, 'Some finding needs a question.', 'some finding needs a question').
decl(rule, some_current_refuted, 'Some current claim is refuted.', 'some current claim is refuted').
decl(rule, some_weak_rule, 'Some rule is weak.', 'some rule survived its mutation check with no reason').
decl(rule, some_model_problem, 'Some model diverges, is vacuous, breaks a claim with no disproof, or has solvers that disagree.', 'some model has an open problem').
decl(rule, vote_cast(by, int, atom), 'A vote: its writer, round, and choice.', 'the @(1) voted @(3) in round @(2)').
decl(rule, discovery_vote_raised(int), 'A vote exists in a larger round than this one.', 'a vote exists in a round after round @(1)').
decl(rule, vote_round(int), 'The current round: the largest round with a vote.', 'round @(1) is the current round of the vote').
decl(rule, human_vote(atom), 'The vote of the human in the current round.', 'the human votes @(1)').
decl(rule, agent_vote(atom), 'The vote of the agent in the current round.', 'the agent votes @(1)').
decl(rule, discovery_some_current, 'Some claim is current.', 'some claim is current').
decl(rule, artifact_vote(atom), 'The vote of the formal artifacts: go when discovery is ready with a current claim, no_go when it is ready with no current claim, else hold. Once the orbit is closed, go: the vote of the round that closed it (D30 H6).', 'the formal artifacts vote @(1)').
decl(rule, discovery_gate_agreed, 'The human and at least one other role vote the same.', 'the human and another role agree').
decl(rule, gate(atom), 'The outcome of the vote: a choice of the human and at least one other role that can win (gate_allowed: GO cannot win while discovery is not ready), else hold. No answer until the human votes.', 'the outcome of the vote is @(1)').
decl(rule, gate_split, 'The human voted, and no other role agrees with the human. The outcome is hold; record a divergence.', 'the vote is split, so the outcome is hold').
decl(rule, discovery_agent_voted(int), 'The agent voted in this round.', 'the agent voted in round @(1)').
decl(rule, discovery_vote_twin(ref(attest)), 'Another vote by the same writer is in the same round.', 'vote @(1) has a second vote by its writer in its round').
decl(rule, some_unratified_supersession, 'Some claim replaces a disputed claim with no human answer behind it.', 'some claim replaces a disputed claim without a human answer').

% --- A disproof names the claim (a helper, because model_unfiled_break reads it under not) ---
discovery_disproof_filed(C) :- attest(_, disproof, _, verdict(C, refuted(_)), _, _).

% --- Evidence from the current system ---
discovery_model_artifact(S) :- model(S, _).
discovery_model_artifact(S) :- model_run(S, _, _).
discovery_model_artifact(S) :- discovery_evidence(S, model).
discovery_system_evidence(S) :- discovery_evidence(S, system), not discovery_model_artifact(S).
touched_system :- attest(_, reproduction, S, _, _, _), discovery_system_evidence(S).
touched_system :- attest(_, test_result, K, _, _, _), discovery_system_evidence(K).
discovery_hypothesis_touched(H) :- attest(_, reproduction, S, result(H, _), _, _), discovery_system_evidence(S).
% D33 R3 (question q_k_d_3b, default a): a red run of a system check of an introduce or a retire
% claim is the system result of each hypothesis that no hypothesis supersedes (the rules that
% read discovery_hypothesis_touched/1 skip a superseded one), if the run came after the
% hypothesis in kb.pl: a run made before a hypothesis existed did not test it (c_k_d_1b, the
% second example). discovery_run_after/2 has no clauses here: orbit-kb computes its facts.
% Review of K-C/K-D (item 7): only a current claim; a red run of the check of a superseded
% claim is no system result.
discovery_changing_claim(C) :- claim(C, introduce, _), current(C).
discovery_changing_claim(C) :- claim(C, retire, _), current(C).
discovery_hypothesis_touched(H) :- discovery_run_after(A, H), attest(A, test_result, _, result(K, _, fail), _, _),
    discovery_system_evidence(K), check(K, C), discovery_changing_claim(C).
discovery_has_outcome :- current(_).
% D15: the result of a superseded hypothesis is no outcome. Its new wording needs its own.
discovery_has_outcome :- attest(_, reproduction, S, result(H, not_reproduced), _, _), discovery_system_evidence(S),
    not superseded(H).

% --- Model verdicts count only for the current digest of their own model ---
% A log that also has a run at an older digest does not count: reusing a log for a new
% digest must not bring its old verdicts back.
model_run_of(S, M) :- model_run(S, M, _).
discovery_result_key(verdict(M, K, _), v(M, K)).
discovery_result_key(mutation(M, R, _), m(M, R)).
discovery_result_key(calibration(M, C, _), c(M, C)).
discovery_result_renewed(A) :-
    attest(A, model_result, _, P, _, _), discovery_result_key(P, Key),
    attest(B, model_result, S, Q, _, _), B \= A, discovery_result_key(Q, Key),
    discovery_result_model(Q, M), model_run_current(S, M).
model_mutation(A, M, Rule, R) :- attest(A, model_result, S, mutation(M, Rule, R), _, _), model_run_current(S, M).
discovery_result_model(verdict(M, _, _), M).
discovery_result_model(calibration(M, _, _), M).
discovery_result_model(mutation(M, _, _), M).


% --- Trust (sane, calibrated, no divergence) and model_decided/2, model_breaks/2: core.pl since D42 K3 ---
model_same_tool(M, M0) :- model(M, T), model(M0, T).

% --- Other verdicts ---
model_vacuous(A) :- model_verdict(A, _, applies(_), R), model_shows_no_case(R).
model_unfiled_break(C) :- model_breaks(_, C), current(C), not discovery_disproof_filed(C).
% No disequality here: R1 \= R2 over a self-join was very slow in s(CASP), the
% second engine until 2026-11-02 (D20).
model_check_case(M, K) :- model_verdict(_, M, K, R), model_shows_case(R).
model_check_no_case(M, K) :- model_verdict(_, M, K, R), model_shows_no_case(R).
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

% --- "There is no such X" uses a helper with no arguments (the form since s(CASP) days; D20) ---
% D15: a superseded hypothesis does not count. Its replacement does.
some_hypothesis :- hypothesis(H, _, _), not superseded(H).
some_untouched_hypothesis :- hypothesis(H, _, _), not superseded(H), not discovery_hypothesis_touched(H).
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

% --- D14: the weighted vote (human 0.49, agent 0.24, formal artifacts 0.24) ---
% A choice wins when its votes add up to more than 0.5. No role wins alone (0.49 < 0.5),
% and the agent and the artifacts together cannot win (0.48 < 0.5). So a choice wins only
% when the human and at least one other role vote for it; the rules below encode that
% directly. Any other result is hold.
% D30 H5, H8: vote_void/1 has no clauses here. orbit-kb computes it: a vote that a back
% attestation follows (an earlier orbit), or a vote after a discovery_end that no back follows.
vote_cast(W, R, C) :- attest(A, vote, _, vote(R, C), W, _), not vote_void(A).
discovery_vote_raised(R) :- vote_cast(_, R, _), vote_cast(_, R2, _), R2 > R.
vote_round(R) :- vote_cast(_, R, _), not discovery_vote_raised(R).
human_vote(C) :- vote_cast(human, R, C), vote_round(R).
agent_vote(C) :- vote_cast(agent, R, C), vote_round(R).
discovery_some_current :- current(_).
% D30 H6: a closed orbit keeps the record of the round that closed it. The orbit closes only when
% the artifacts vote go (orbit-kb attest approval), so their vote stays go.
artifact_vote(go) :- discovery_closed.
artifact_vote(go) :- discovery_open, discovery_ready, discovery_some_current.
artifact_vote(no_go) :- discovery_open, discovery_ready, not discovery_some_current.
artifact_vote(hold) :- discovery_open, not discovery_ready.
discovery_gate_agreed :- human_vote(C), agent_vote(C).
discovery_gate_agreed :- human_vote(C), artifact_vote(C).
% D33 R5 (c_k_d_1b, question q_k_d_1b, default a): GO cannot win while discovery is not ready,
% whenever the votes came. Once the orbit is closed, discovery_ready holds, so a later change
% of the build does not take the GO back.
gate_allowed(no_go).
gate_allowed(hold).
gate_allowed(go) :- discovery_ready.
gate(C) :- human_vote(C), agent_vote(C), gate_allowed(C).
gate(C) :- human_vote(C), artifact_vote(C), gate_allowed(C).
gate(hold) :- human_vote(_), not discovery_gate_agreed.
gate(hold) :- human_vote(go), not gate_allowed(go).
gate_split :- human_vote(_), not discovery_gate_agreed.
discovery_agent_voted(R) :- vote_cast(agent, R, _).
discovery_vote_twin(A) :- attest(A, vote, _, vote(R, _), W, _), not vote_void(A),
    attest(B, vote, _, vote(R, _), W, _), A \= B, not vote_void(B).

% --- D30 H4: the open discovery orbit ---
% discovery_reopened/1 has no clauses here: orbit-kb computes its facts from the order of
% kb.pl, as later_verdict/1. Neither rule reads readiness or the vote, so the order of the
% strata stays: the orbit, then readiness, then the vote.
discovery_end_valid(A) :- attest(A, approval, S, _, human, _), ticket(S).
discovery_closed :- discovery_end(A), discovery_end_valid(A), not discovery_reopened(A).
discovery_open :- not discovery_closed.

% --- The gate: clean only, and asked only while the discovery orbit is open (D30 H4) ---
% D32 O2: each thing that blocks readiness is one answer of ready_blocker(X), and readiness in
% an open orbit is "no answer". So show open, report and the refusal of an agent's GO name
% exactly what blocks it (c_k_c_1b; the Lean model kb/proofs/open_items).
discovery_has_example(C) :- example(C, _).
discovery_no_example(C) :- current(C), not discovery_has_example(C).
discovery_preserve_failing(K) :- check(K, C), claim(C, preserve, _), current(C), check_ran(K), not passed(K).
ready_blocker(no_hypothesis) :- not some_hypothesis.
ready_blocker(no_system_result) :- not touched_system.
ready_blocker(no_outcome) :- not discovery_has_outcome.
ready_blocker(untouched(H)) :- hypothesis(H, _, _), not superseded(H), not discovery_hypothesis_touched(H).
ready_blocker(no_falsifier(C)) :- no_falsifier(C).
ready_blocker(no_example(C)) :- discovery_no_example(C).
ready_blocker(preserve_failing(K)) :- discovery_preserve_failing(K).
ready_blocker(question_waits(Q)) :- question_waits(Q).
ready_blocker(unasked_finding(F)) :- unasked_finding(F).
ready_blocker(refuted(C)) :- refuted(C), current(C).
ready_blocker(weak_rule(R)) :- weak_rule(R).
ready_blocker(model_diverges(M)) :- model_diverges(M).
ready_blocker(model_vacuous(A)) :- model_vacuous(A).
ready_blocker(model_unfiled_break(C)) :- model_unfiled_break(C).
ready_blocker(model_solvers_disagree(M)) :- model_solvers_disagree(M).
ready_blocker(unratified(C)) :- discovery_unratified(C).
ready_blocker(to_ask(Q)) :- to_ask(Q).
any_ready_blocker :- ready_blocker(_).
discovery_ready :- discovery_closed.
discovery_ready :- discovery_open, not any_ready_blocker.
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
lint_issue('WD6', A, 'The problem did not reproduce on the current system. Tell the human what you tried.') :-
    attest(A, reproduction, S, result(H, not_reproduced), _, _), discovery_system_evidence(S),
    not superseded(H).
lint_issue('WD7', H, 'No result from the current system exists for this hypothesis. Reproduce it, or ask the human if it is a separate ticket.') :-
    discovery_open, hypothesis(H, _, _), not superseded(H), not discovery_hypothesis_touched(H).
lint_issue('WD8', A, 'This model result is on a log of an older digest of the model. It does not count. Run the solver again, into a new log.') :-
    attest(A, model_result, S, P, _, _), discovery_result_model(P, M), model_run_stale(S, M),
    not discovery_result_renewed(A).
lint_issue('WD8', A, 'This model result is on a log of an older digest of the model. It does not count. A newer result of the same check replaces it; nothing to do.') :-
    attest(A, model_result, S, P, _, _), discovery_result_model(P, M), model_run_stale(S, M),
    discovery_result_renewed(A).
% Review of K-C/K-D (item 1): WD10 names a current claim with no example in any state of the
% orbit; only its readiness part waits for an open orbit (ready_blocker reads discovery_no_example).
lint_issue('WD10', C, 'This current claim has no example. Discovery is not ready until each current claim has a concrete case: add example(C, Text).') :-
    discovery_open, discovery_no_example(C).
lint_issue('WD10', C, 'This current claim has no example. Each claim needs a concrete case: add example(C, Text).') :-
    discovery_closed, discovery_no_example(C).
lint_issue('WD9', A, 'The human voted in this round, and the agent did not vote first. The agent vote must be sealed before the human votes.') :-
    attest(A, vote, _, vote(R, _), human, _), not vote_void(A), not discovery_agent_voted(R).
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
lint_issue('ED11', A, 'This discovery_end does not name a human approval of the ticket subject, so it does not close the discovery orbit. Only orbit-kb attest approval TICKET --by human writes it. Remove the line.') :-
    discovery_end(A), not discovery_end_valid(A).
lint_issue('ED10', A, 'Its writer has another vote in this round. Keep one vote per writer in each round. After a HOLD, vote in the next round.') :-
    discovery_vote_twin(A).

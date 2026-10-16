% Discovery module for the orbit KB. Draft, 2026-10-15.
% Loads on top of the shared core (claim/3, current/1, answered/1, refuted/1,
% check/2, attest/6). Run with: scasp --unknown=error core.pl discovery.pl kb.pl

% --- Declarations: discovery facts may be empty ---
report(_) :- false.
hypothesis(_, _, _) :- false.
budget(_, _) :- false.
lap_done(_) :- false.
model(_, _) :- false.
derived_from(_, _) :- false.
encodes(_, _) :- false.
finding(_, _, _) :- false.
reason(_, _) :- false.
raised_by(_, _) :- false.

% --- A model counts only when it is sane and calibrated against the current system ---
model_sane(M) :- attest(_, model_result, M, verdict(sanity, sat), _, _).
model_sane(M) :- attest(_, model_result, M, verdict(sanity, reached), _, _).
model_calibrated(M) :- attest(_, calibration, M, matches(_), _, _).
model_trusted(M) :- model_sane(M), model_calibrated(M).
% A target model inherits trust from the calibrated model that it changes.
model_trusted(M) :- model_sane(M), derived_from(M, M0), model_trusted(M0).

% --- Each current claim needs a falsifier: a trusted model or a check ---
has_falsifier(C) :- encodes(M, C), model_trusted(M).
has_falsifier(C) :- check(_, C).
no_falsifier(C) :- current(C), not has_falsifier(C).

% --- Conflicts, surprises, and scope findings must raise a question ---
needs_question(F) :- finding(F, conflict(_), _).
needs_question(F) :- finding(F, surprise(_), _).
needs_question(F) :- finding(F, scope(_), _).
has_question(F) :- raised_by(_, F).
unasked_finding(F) :- needs_question(F), not has_question(F).
question_waits(Q) :- raised_by(Q, _), not answered(Q).

% --- A finding about system behavior, from a model only, is a lead ---
about_system(trace(_)).
about_system(surprise(_)).
about_system(root_cause(_)).
finding_confirmed(F) :- attest(_, reproduction, _, confirms(F), _, _).
finding_lead(F) :- finding(F, K, model), about_system(K), not finding_confirmed(F).

% --- A rule that survived its mutation check needs a recorded reason ---
rule_has_reason(R) :- reason(R, _).
weak_rule(R) :- attest(_, model_result, _, verdict(mutation(R), survived), _, _),
                not rule_has_reason(R).

% --- "There is no such X": s(CASP) `not` is existential over a variable that
%     occurs only under it, so each check uses a zero-arity helper ---
some_no_falsifier :- no_falsifier(_).
some_question_waits :- question_waits(_).
some_unasked_finding :- unasked_finding(_).
some_current_refuted :- refuted(C), current(C).
some_weak_rule :- weak_rule(_).

touched_system :- attest(_, reproduction, _, result(_, _), _, _).
budget_spent :- budget(laps, B), lap_done(B).

% Ready for GO / NO-GO.
discovery_ready :- touched_system,
    not some_no_falsifier,
    not some_question_waits,
    not some_unasked_finding,
    not some_current_refuted,
    not some_weak_rule.
% Out of budget: decide now, and list what is unknown.
discovery_ready :- budget_spent.

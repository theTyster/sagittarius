% Variant of discovery.pl for the chained-projection test (Test 2b).
% Every rule has at most one body-only variable (checked with
% repro-bodyvars.py). Every attest/6 and finding/3 literal goes through a
% helper chain that projects away one variable per rule. Loads with
% core-min-chain.pl.

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

% --- Projection chain over attest/6: each rule drops one variable ---
att5(I, Ty, S, P, B) :- attest(I, Ty, S, P, B, _).
att4(I, Ty, S, P) :- att5(I, Ty, S, P, _).
att3(Ty, S, P) :- att4(_, Ty, S, P).
attests(Ty, P) :- att3(Ty, _, P).
finding_kind(F, K) :- finding(F, K, _).

% --- A model counts only when it is sane and calibrated against the current system ---
model_sane(M) :- att3(model_result, M, verdict(sanity, sat)).
model_sane(M) :- att3(model_result, M, verdict(sanity, reached)).
model_calibrated(M) :- att3(calibration, M, matches(_)).
model_trusted(M) :- model_sane(M), model_calibrated(M).
% A target model inherits trust from the calibrated model that it changes.
model_trusted(M) :- model_sane(M), derived_from(M, M0), model_trusted(M0).

% --- Each current claim needs a falsifier: a trusted model or a check ---
has_falsifier(C) :- encodes(M, C), model_trusted(M).
has_falsifier(C) :- check(_, C).
no_falsifier(C) :- current(C), not has_falsifier(C).

% --- Conflicts, surprises, and scope findings must raise a question ---
needs_question(F) :- finding_kind(F, conflict(_)).
needs_question(F) :- finding_kind(F, surprise(_)).
needs_question(F) :- finding_kind(F, scope(_)).
has_question(F) :- raised_by(_, F).
unasked_finding(F) :- needs_question(F), not has_question(F).
question_waits(Q) :- raised_by(Q, _), not answered(Q).

% --- A finding about system behavior, from a model only, is a lead ---
about_system(trace(_)).
about_system(surprise(_)).
about_system(root_cause(_)).
finding_confirmed(F) :- attests(reproduction, confirms(F)).
finding_lead(F) :- finding(F, K, model), about_system(K), not finding_confirmed(F).

% --- A rule that survived its mutation check needs a recorded reason ---
rule_has_reason(R) :- reason(R, _).
weak_rule(R) :- attests(model_result, verdict(mutation(R), survived)),
                not rule_has_reason(R).

some_no_falsifier :- no_falsifier(_).
some_question_waits :- question_waits(_).
some_unasked_finding :- unasked_finding(_).
some_current_refuted :- refuted(C), current(C).
some_weak_rule :- weak_rule(_).

is_result(result(_, _)).
touched_system :- attests(reproduction, P), is_result(P).
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

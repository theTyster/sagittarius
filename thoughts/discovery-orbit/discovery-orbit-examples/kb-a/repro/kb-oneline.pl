ticket(_) :- false.
claim(_, _, _) :- false.
cites(_, _) :- false.
supersedes(_, _) :- false.
example(_, _) :- false.
universal(_) :- false.
question(_, _, _) :- false.
assumed(_, _) :- false.
answer(_, _, _) :- false.
depends(_, _) :- false.
check(_, _) :- false.
world(_) :- false.
source(_, _) :- false.
scope(_, _) :- false.
risk(_, _) :- false.
assumption(_, _) :- false.
not_explored(_) :- false.
subject(_, _, _) :- false.
attest(_, _, _, _, _, _) :- false.
superseded(C) :- supersedes(_, C).
current(C) :- claim(C, _, _), not superseded(C).
answered(Q) :- answer(Q, _, human).
refuted(C) :- attest(_, _, _, verdict(C, refuted), _, _).
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
model_sane(M) :- attest(_, model_result, M, verdict(sanity, sat), _, _).
model_sane(M) :- attest(_, model_result, M, verdict(sanity, reached), _, _).
model_calibrated(M) :- attest(_, calibration, M, matches(_), _, _).
model_trusted(M) :- model_sane(M), model_calibrated(M).
model_trusted(M) :- model_sane(M), derived_from(M, M0), model_trusted(M0).
has_falsifier(C) :- encodes(M, C), model_trusted(M).
has_falsifier(C) :- check(_, C).
no_falsifier(C) :- current(C), not has_falsifier(C).
needs_question(F) :- finding(F, conflict(_), _).
needs_question(F) :- finding(F, surprise(_), _).
needs_question(F) :- finding(F, scope(_), _).
has_question(F) :- raised_by(_, F).
unasked_finding(F) :- needs_question(F), not has_question(F).
question_waits(Q) :- raised_by(Q, _), not answered(Q).
about_system(trace(_)).
about_system(surprise(_)).
about_system(root_cause(_)).
finding_confirmed(F) :- attest(_, reproduction, _, confirms(F), _, _).
finding_lead(F) :- finding(F, K, model), about_system(K), not finding_confirmed(F).
rule_has_reason(R) :- reason(R, _).
weak_rule(R) :- attest(_, model_result, _, verdict(mutation(R), survived), _, _), not rule_has_reason(R).
some_no_falsifier :- no_falsifier(_).
some_question_waits :- question_waits(_).
some_unasked_finding :- unasked_finding(_).
some_current_refuted :- refuted(C), current(C).
some_weak_rule :- weak_rule(_).
touched_system :- attest(_, reproduction, _, result(_, _), _, _).
budget_spent :- budget(laps, B), lap_done(B).
discovery_ready :- touched_system, not some_no_falsifier, not some_question_waits, not some_unasked_finding, not some_current_refuted, not some_weak_rule.
discovery_ready :- budget_spent.
report('A customer used two discount codes and paid less than our minimum price.').
hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.').
budget(laps, 3).
lap_done(1).
subject(sys,      'checkout service at main',    'git:0000000').
subject(m_now,    'models/discount-now.smt2',    'sha256:0000').
subject(m_target, 'models/discount-target.smt2', 'sha256:0001').
world(clamp_after_first_code).
source(clamp_after_first_code, 'CheckoutService.ApplyCodes').
claim(c1,  introduce, 'No order is charged below its floor price.').
claim(c2,  preserve,  'Each code takes off its full amount.').
claim(c2b, preserve,  'Each code takes off its full amount, down to the floor price.').
supersedes(c2b, c2).
cites(c1,  'paid less than our minimum price').
cites(c2,  'used two discount codes').
cites(c2b, 'used two discount codes').
example(c1,  'Order 4417: $40, floor $30, codes $5 and $10: charged $30.00.').
example(c1,  '$40, floor $30, codes $5.00 and $5.01: charged $30.00.').
example(c2b, '$40, floor $20, codes $5 and $10: charged $25.00.').
model(m_now, smt).
model(m_target, smt).
derived_from(m_target, m_now).
encodes(m_target, c1).
encodes(m_target, c2b).
finding(f1, root_cause(clamp_after_first_code), model).
finding(f2, conflict([c1_floor, c2_full_codes, order_4417]), model).
question(q1, c2, 'For order 4417, full codes and the floor cannot both hold. Which one gives?').
assumed(q1, floor_wins).
raised_by(q1, f2).
answer(q1, floor_wins, human).
scope(in,  'two or more fixed-amount codes at checkout').
scope(out, 'gift cards').
risk(k1, 'The change alters the price of each order whose codes cross the floor.').
assumption(s1, 'Every code takes off a fixed amount.').
not_explored('percentage codes').
attest(a1, reproduction, sys,      result(h1, reproduced),          script, '2026-10-15T09:10').
attest(a2, model_result, m_now,    verdict(sanity, sat),             script, '2026-10-15T09:20').
attest(a3, calibration,  m_now,    matches(order_4417),              agent,  '2026-10-15T09:21').
attest(a4, reproduction, sys,      confirms(f1),                     script, '2026-10-15T09:35').
attest(a5, model_result, m_target, verdict(sanity, sat),             script, '2026-10-15T09:40').
attest(a6, divergence,   m_target, claim(c1),                        script, '2026-10-15T09:45').
attest(a7, divergence,   m_target, claim(c2),                        script, '2026-10-15T09:45').
attest(a8, model_result, m_target, verdict(mutation(clamp), killed), script, '2026-10-15T10:20').

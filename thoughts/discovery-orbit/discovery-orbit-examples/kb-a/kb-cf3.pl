% Example A knowledge base: discovery after lap 2, before GO. Data is invented.
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
attest(a5, model_result, m_target, verdict(sanity, sat),             script, '2026-10-15T09:40').
attest(a6, divergence,   m_target, claim(c1),                        script, '2026-10-15T09:45').
attest(a7, divergence,   m_target, claim(c2),                        script, '2026-10-15T09:45').
attest(a8, model_result, m_target, verdict(mutation(clamp), killed), script, '2026-10-15T10:20').

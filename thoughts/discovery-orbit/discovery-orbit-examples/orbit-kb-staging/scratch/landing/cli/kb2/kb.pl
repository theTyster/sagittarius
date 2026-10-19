uses([discovery]).
% Example A of the discovery orbit (FLYBY, SMT), after lap 2 and before GO.
% The code units, the order, the test, and the system logs are invented.
% The solver logs are real runs of Z3 5.1.0 and cvc5 1.3.4 on the models.
% No atom ends in _<digits>: s(CASP) 1.1.4 reads order_4417 as order. So the solver
% label order_4417 is order4417 in terms, and keeps its exact name only in note text.

% --- SIGNAL ---
request(r1, 'A customer used two discount codes and paid less than our minimum price.').
hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.').
budget(laps, 3).

% --- SURVEY ---
world(clamp_after_first_code).
source(clamp_after_first_code, 'CheckoutService.ApplyCodes').
subject(log4417, 'logs/order-4417.log', 'sha256:eb7c1b78c9b566eecc2b843bcfa4714537b0e739caf9608fc7aac528c3d94599').
discovery_evidence(log4417, system).
attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z').
note(a1, 'The payment log shows that order 4417 was charged $25.00. Its floor is $30.00.').

% --- SPECTRUM ---
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

% --- FLYBY, lap 1: the existing-world model ---
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

% --- FLYBY, lap 1: the target model and the conflict (a finding and a question only) ---
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

% --- The human answers. Lap 1 ends. ---
answer(q1, floor_wins, human).
attest(a12, divergence, run_target, claim(c2), agent, '2026-10-15T10:05:00Z').
note(a12, 'The human answered q1: the floor wins. So c2 gives, and c2b supersedes it. Finding f2 holds the unsat core.').
lap_done(1).
claim(c2b, preserve, 'Each code takes off its full amount, down to the floor price.').
supersedes(c2b, c2).
cites(c2b, 'used two discount codes').
encodes(m_target, c1).
encodes(m_target, c2b).

% --- FLYBY, lap 2: the target model ---
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
derived_from(m_now, m_now).
derived_from(m_now, m_target).
lap_done(7).
raised_by(q1, c1).
attest(a18, disproof, m_target, verdict(c2b, abstained), agent, '2026-10-16T20:53:00Z').

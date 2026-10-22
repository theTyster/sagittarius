uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve(sku, qty) raises ValueError when the total reserved for sku would become more than its stock on hand.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand.').
example(c1, 'stock apple=5; reserve(apple,4) returns 4; reserve(apple,2) raises ValueError.').
universal(c1).
claim(c2, introduce, 'A refused reservation does not change the reserved total.').
cites(c2, 'refuse to reserve').
example(c2, 'stock apple=5; reserve(apple,4); reserve(apple,2) raises; reserved[apple] is still 4.').
claim(c3, preserve, 'A reservation within stock succeeds and returns the new reserved total.').
cites(c3, 'reserve() must refuse to reserve more than the stock on hand.').
example(c3, 'stock apple=5; reserve(apple,2) returns 2; reserve(apple,3) returns 5.').
check(k1, c1).
check(k2, c2).
check(k3, c3).
question(q1, c1, 'A SKU that is not in stock: refuse every reservation, as stock 0?').
assumed(q1, 'yes, stock 0').
question(q2, c1, 'qty that makes the total exactly equal to stock: allowed?').
assumed(q2, 'yes, allowed').
question(q3, c1, 'Negative or zero qty: change the behavior?').
assumed(q3, 'no, out of scope; unchanged').
note(c1, 'Handoff from peer session stock-levels. Peer wrote test_reserve_over_stock (k1) and reported it red.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:36:44Z').
attest(a2, test_result, k2, result(k2, 2, fail), script, '2026-10-22T20:36:44Z').
attest(a3, test_result, k3, result(k3, 3, pass), script, '2026-10-22T20:36:44Z').
attest(a4, test_result, k1, result(k1, 4, pass), script, '2026-10-22T20:36:50Z').
attest(a5, test_result, k2, result(k2, 5, pass), script, '2026-10-22T20:36:50Z').
attest(a6, test_result, k3, result(k3, 6, pass), script, '2026-10-22T20:36:50Z').
change(x1, 'inventory.py reserve(): raise ValueError when the new total exceeds stock (missing SKU = 0); write the total only after the check.').
serves(x1, c1).
serves(x1, c2).
attest(a7, lean_proof, c1, proof(c1, 'sha256:092ed1473def5f2526259999e675adcf14d76294e7e640d13f08fb2aea890d19'), script, '2026-10-22T20:37:46Z').
check(k4, c1).
attest(a8, test_result, k4, result(k4, 7, fail), script, '2026-10-22T20:37:58Z').
attest(a9, test_result, k4, result(k4, 8, fail), script, '2026-10-22T20:37:58Z').
attest(a10, test_result, k4, result(k4, 9, pass), script, '2026-10-22T20:37:58Z').
attest(a11, disclosure, k4, self_error('k4 run 7 failed from a wrong unittest command (import error), not from the behavior. Run 8 is the valid red run on the old code.'), agent, '2026-10-22T20:38:06Z').
attest(a12, disclosure, q1, guess(q1), agent, '2026-10-22T20:38:06Z').
attest(a13, disclosure, q3, guess(q3), agent, '2026-10-22T20:38:06Z').
attest(a14, disclosure, c1, unverified('The Lean proof is about the model in .orbit/reserve_burn, not about inventory.py. Only the unittest checks test the code.'), agent, '2026-10-22T20:38:06Z').

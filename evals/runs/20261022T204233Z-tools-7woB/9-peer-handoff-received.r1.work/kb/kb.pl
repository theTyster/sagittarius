uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve(sku, qty) raises ValueError when the total reserved for sku would exceed its stock on hand, and leaves the reservation unchanged.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand.').
example(c1, 'stock apple=5; reserve(apple,4) returns 4; reserve(apple,2) raises ValueError.').
universal(c1).
claim(c2, preserve, 'reserve within stock returns the running total reserved for the sku.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand.').
example(c2, 'stock apple=5; reserve(apple,2) returns 2.').
check(k1, c1).
check(k2, c2).
world(reserve_has_no_stock_limit).
source(reserve_has_no_stock_limit, 'inventory.py reserve()').
question(q1, c1, 'Does the limit count earlier reservations, or only this call?').
assumed(q1, 'earlier reservations count (the handed-off check requires it)').
question(q2, c1, 'An unknown SKU: stock 0, or an error of a different type?').
assumed(q2, 'stock 0, so any positive qty raises ValueError').
question(q3, c1, 'Zero or negative qty?').
assumed(q3, 'out of scope; behavior unchanged').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:46:56Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T20:46:56Z').
check(k3, c1).
check(k4, c1).
attest(a3, test_result, k3, result(k3, 3, fail), script, '2026-10-22T20:47:04Z').
attest(a4, test_result, k4, result(k4, 4, fail), script, '2026-10-22T20:47:04Z').
attest(a5, test_result, k1, result(k1, 5, pass), script, '2026-10-22T20:47:10Z').
attest(a6, test_result, k2, result(k2, 6, pass), script, '2026-10-22T20:47:10Z').
attest(a7, test_result, k3, result(k3, 7, pass), script, '2026-10-22T20:47:11Z').
attest(a8, test_result, k4, result(k4, 8, pass), script, '2026-10-22T20:47:11Z').
change(x1, 'inventory.py reserve(): raise ValueError when the running total would exceed stock; no state change on refusal.').
serves(x1, c1).
attest(a9, lean_proof, c1, proof(c1, 'sha256:1e0dd62d87199c4bfe57eb2998ee9b1a66cc5801f38f2c9c168a83b1eb6af0ff'), script, '2026-10-22T20:47:43Z').
attest(a10, lean_result, c1, verdict(c1, tested(100)), agent, '2026-10-22T20:47:50Z').
attest(a11, disclosure, c1, unverified('The Lean theorem assumes, by the model, that a refused call leaves the reservation unchanged; check k3 tests that on the Python code. The proof is about the model, not inventory.py.'), agent, '2026-10-22T20:47:50Z').
attest(a12, disclosure, c1, out_of_scope('Zero or negative qty: Python accepts a negative qty and lowers the reservation; the Lean model uses Nat and does not cover it (q3).'), agent, '2026-10-22T20:47:50Z').

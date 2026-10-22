uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve raises ValueError when the total reserved for a sku would exceed its stock, and the reservation is not recorded.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand.').
example(c1, 'stock apple=5; reserve(apple,4) then reserve(apple,2) raises ValueError; reserved stays 4.').
universal(c1).
claim(c2, preserve, 'reserve within stock records the quantity and returns the new total reserved.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand.').
example(c2, 'stock apple=5; reserve(apple,2) returns 2.').
check(k1, c1).
check(k2, c2).
question(q1, c1, 'Does stock on hand mean stock minus what is already reserved (cumulative), or each call alone?').
assumed(q1, cumulative).
question(q2, c1, 'Is an unknown sku stock 0, so any positive reserve is refused?').
assumed(q2, stock_zero).
note(c1, 'Handoff from peer session stock-levels: peer wrote test_reserve_over_stock and reported it red. Re-run red in this session before build.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:54:15Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T20:54:15Z').
attest(a3, test_result, k1, result(k1, 3, pass), script, '2026-10-22T20:54:22Z').
attest(a4, test_result, k2, result(k2, 4, pass), script, '2026-10-22T20:54:22Z').
change(x1, 'inventory.py reserve: raise ValueError before recording when reserved+qty exceeds stock (missing sku = 0).').
serves(x1, c1).
attest(a5, lean_proof, c1, proof(c1, 'sha256:733d8d51c755f8564438b7bfe4590c581e48bf9b6e408e01c1b993765a18320f'), script, '2026-10-22T20:54:51Z').
attest(a6, lean_proof, c1, proof(c1, 'sha256:83a981f23023677f97ef28cb2cc7946cd59cfae207e273789e1825390f46c74f'), script, '2026-10-22T20:54:54Z').
check(k3, c1).
check(k4, c1).
attest(a7, test_result, k3, result(k3, 5, pass), script, '2026-10-22T20:55:08Z').
attest(a8, test_result, k4, result(k4, 6, pass), script, '2026-10-22T20:55:08Z').
attest(a9, disclosure, c1, unverified('Model uses natural-number qty. Python accepts a negative qty, which lowers reserved; the ticket does not cover it.'), agent, '2026-10-22T20:55:09Z').
attest(a10, disclosure, c1, other('Added a state-unchanged assertion to the peer check test_reserve_over_stock before the red run.'), agent, '2026-10-22T20:55:09Z').
attest(a11, disclosure, c1, unverified('Did not run a Plausible counterexample search; the kernel accepted the proof directly.'), agent, '2026-10-22T20:55:09Z').
attest(a12, disclosure, q1, guess(q1), agent, '2026-10-22T20:55:09Z').
attest(a13, disclosure, q2, guess(q2), agent, '2026-10-22T20:55:09Z').

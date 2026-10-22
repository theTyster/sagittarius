uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve(sku, qty) raises ValueError and reserves nothing when the total reserved for sku would exceed its stock on hand.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand.').
example(c1, 'stock apple=5; reserve(apple,4) returns 4; reserve(apple,2) raises ValueError; reserved apple stays 4.').
universal(c1).
claim(c2, preserve, 'reserve within stock adds qty to the reserved total and returns the new total.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand.').
example(c2, 'stock apple=5; reserve(apple,2) returns 2.').
check(k1, c1).
check(k2, c2).
question(q1, c1, 'Is the limit on the cumulative reserved total, or on each single call?').
assumed(q1, cumulative).
question(q2, c1, 'An sku with no stock entry: refuse, or allow?').
assumed(q2, 'refuse: stock is 0').
note(c1, 'Handoff from peer session stock-levels. Peer wrote test_reserve_over_stock; I confirmed it fails on the current code.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:47:19Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T20:47:19Z').
attest(a3, test_result, k1, result(k1, 3, pass), script, '2026-10-22T20:47:24Z').
attest(a4, test_result, k2, result(k2, 4, pass), script, '2026-10-22T20:47:24Z').
change(x1, 'inventory.py: reserve() checks reserved+qty against stock (0 if absent), raises ValueError, writes nothing on refusal.').
serves(x1, c1).
attest(a5, lean_proof, c1, proof(c1, 'sha256:df4d1fc8c5777d0f4f4af52f695e66f7d915762771214df906087d59cc82a855'), script, '2026-10-22T20:48:26Z').
attest(a6, disclosure, c1, guess(q1), agent, '2026-10-22T20:48:32Z').
attest(a7, disclosure, c1, guess(q2), agent, '2026-10-22T20:48:32Z').
attest(a8, disclosure, c1, other('I added an assertion to the peer test test_reserve_over_stock (reserved stays 4 after refusal) and added test_reserve_unknown_sku, before the fix. Both were red.'), agent, '2026-10-22T20:48:32Z').
attest(a9, disclosure, c1, unverified('The Lean proof is about the model, not inventory.py. It does not model concurrency or mutation of stock after init.'), agent, '2026-10-22T20:48:32Z').
attest(a10, disclosure, c1, out_of_scope('Negative or zero qty is not rejected. A negative qty lowers the reserved total, as before.'), agent, '2026-10-22T20:48:32Z').

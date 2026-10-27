uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand.').
example(c1, 'stock apple=5, reserve 4, then reserve 2 raises ValueError').
check(k1, c1).
claim(c2, preserve, 'reserve() within stock returns the new reserved total.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand.').
example(c2, 'stock apple=5, reserve 2 returns 2').
check(k2, c2).
note(c1, 'Handoff from peer session stock-levels; k1 is its test_reserve_over_stock. Stock on hand = stock minus already reserved (from the test). Reserving exactly the remaining stock is allowed.').
question(q1, c1, 'What is the stock of a sku not in the stock table?').
assumed(q1, 'zero, so any reserve raises ValueError').
attest(a1, disclosure, q1, guess(q1), agent, '2026-10-27T18:49:56Z').
attest(a2, disclosure, c1, unverified('the peer reports k1 fails on current code; I rerun it myself'), agent, '2026-10-27T18:49:56Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-27T18:49:56Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-27T18:49:56Z').
check(k3, c2).
change(x1, 'inventory.py: reserve() raises ValueError when the new total exceeds stock; refused call leaves state unchanged').
serves(x1, c1).
change(x2, 'test_inventory.py: boundary test test_reserve_exact_stock').
serves(x2, c2).
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-27T18:50:03Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-27T18:50:03Z').
attest(a7, test_result, k3, result(k3, 5, pass), script, '2026-10-27T18:50:03Z').

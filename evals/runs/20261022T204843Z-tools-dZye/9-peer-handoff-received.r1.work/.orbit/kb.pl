uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand.').
example(c1, 'stock apple 5; reserve(apple, 4) then reserve(apple, 2) raises ValueError.').
check(k1, c1).
claim(c2, preserve, 'reserve within stock returns the total reserved for the sku.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand.').
example(c2, 'stock apple 5; reserve(apple, 2) returns 2.').
check(k2, c2).
claim(c3, introduce, 'A refused reserve leaves the reserved total unchanged.').
cites(c3, 'refuse to reserve').
example(c3, 'stock apple 5; reserve(apple, 4); reserve(apple, 2) raises; reserved apple is still 4.').
check(k3, c3).
question(q1, c1, 'Does a sku with no stock entry count as stock 0?').
assumed(q1, 'yes: any reserve of an unknown sku is refused').
note(c1, 'Handoff from peer session stock-levels. Peer wrote k1 (test_reserve_over_stock) and reported it red; re-run here to verify.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:53:57Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T20:53:57Z').
attest(a3, test_result, k3, result(k3, 3, fail), script, '2026-10-22T20:53:58Z').
attest(a4, test_result, k1, result(k1, 4, pass), script, '2026-10-22T20:54:04Z').
attest(a5, test_result, k2, result(k2, 5, pass), script, '2026-10-22T20:54:04Z').
attest(a6, test_result, k3, result(k3, 6, pass), script, '2026-10-22T20:54:04Z').
change(x1, 'inventory.py: reserve checks the new total against stock and raises ValueError before it changes reserved.').
serves(x1, c1).
serves(x1, c3).
change(x2, 'test_inventory.py: add test_refused_reserve_keeps_total.').
serves(x2, c3).
attest(a7, disclosure, c1, guess(q1), agent, '2026-10-22T20:54:04Z').

uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve raises ValueError when reserved plus qty exceeds stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5, reserve 4, then reserve 2 raises ValueError').
claim(c2, preserve, 'reserve up to the stock on hand still works and returns the reserved total.').
cites(c2, 'refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5, reserve 2 returns 2').
check(k1, c1).
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:09:32Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-28T20:09:32Z').
question(q1, c1, 'Is reserving exactly the stock allowed, and does a refused reserve leave the total unchanged?').
assumed(q1, 'yes, and yes').
attest(a3, disclosure, c1, guess(q1), agent, '2026-10-28T20:09:36Z').
attest(a4, disclosure, c1, other('Handoff from peer session stock-levels; k1 is its test_reserve_over_stock. SKU missing from stock is treated as stock 0.'), agent, '2026-10-28T20:09:36Z').
check(k3, c1).
attest(a5, test_result, k3, result(k3, 3, fail), script, '2026-10-28T20:09:40Z').
change(x1, 'inventory.py reserve(): raise ValueError when reserved total plus qty exceeds stock; stock missing means 0.').
serves(x1, c1).
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-28T20:09:49Z').
attest(a7, test_result, k2, result(k2, 5, pass), script, '2026-10-28T20:09:50Z').
attest(a8, test_result, k3, result(k3, 6, pass), script, '2026-10-28T20:09:50Z').

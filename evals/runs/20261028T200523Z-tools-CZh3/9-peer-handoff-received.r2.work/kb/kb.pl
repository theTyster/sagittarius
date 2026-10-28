uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5; reserve 4 then reserve 2 raises ValueError').
check(k1, c1).
claim(c2, preserve, 'reserve() within stock returns the new reserved total.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5; reserve 2 returns 2').
check(k2, c2).
claim(c3, introduce, 'A refused reserve() leaves the reserved totals unchanged.').
cites(c3, 'refuse to reserve').
example(c3, 'stock apple=5; reserve 4; reserve 2 raises; reserved apple is still 4').
check(k3, c3).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:09:47Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-28T20:09:47Z').
attest(a3, test_result, k3, result(k3, 3, fail), script, '2026-10-28T20:09:47Z').
change(x1, 'inventory.py: reserve() raises ValueError before it records a total above stock; unknown sku counts as stock 0.').
serves(x1, c1).
serves(x1, c3).
change(x2, 'test_inventory.py: added test_refused_reserve_leaves_state.').
serves(x2, c3).
attest(a4, test_result, k1, result(k1, 4, pass), script, '2026-10-28T20:09:53Z').
attest(a5, test_result, k2, result(k2, 5, pass), script, '2026-10-28T20:09:53Z').
attest(a6, test_result, k3, result(k3, 6, pass), script, '2026-10-28T20:09:53Z').

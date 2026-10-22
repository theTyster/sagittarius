uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5; reserve 4 then reserve 2 raises ValueError.').
claim(c2, preserve, 'reserve returns the new reserved total when the request fits within stock.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5; reserve 2 returns 2; reserving up to exactly 5 is allowed.').
check(k1, c1).
check(k2, c2).
attest(a1, disclosure, c1, other('handoff: test_reserve_over_stock was written by peer session stock-levels; I re-ran it myself'), agent, '2026-10-22T21:34:06Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:34:13Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-22T21:34:13Z').
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-22T21:34:17Z').
attest(a5, test_result, k2, result(k2, 4, pass), script, '2026-10-22T21:34:17Z').
change(x1, 'inventory.py: reserve() raises ValueError when total would exceed stock; no state change on refusal').
serves(x1, c1).
change(x2, 'test_inventory.py: added test_reserve_exactly_stock').
serves(x2, c2).

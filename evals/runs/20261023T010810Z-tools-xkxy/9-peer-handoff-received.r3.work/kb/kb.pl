uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5; reserve 4 then reserve 2 raises ValueError.').
check(k1, c1).
claim(c2, preserve, 'reserve() within stock still works and returns the total reserved.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5; reserve 2 returns 2; reserve 5 in total is allowed.').
check(k2, c2).
attest(a1, disclosure, c1, other('Handoff from peer session stock-levels; I reran its check myself rather than trust its report.'), agent, '2026-10-23T01:08:34Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:08:34Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:08:34Z').
change(x1, 'inventory.reserve raises ValueError when total would exceed stock; unknown sku has stock 0.').
serves(x1, c1).
serves(x1, c2).
change(x2, 'Added boundary test test_reserve_up_to_stock.').
serves(x2, c2).
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-23T01:08:44Z').
attest(a5, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:08:44Z').

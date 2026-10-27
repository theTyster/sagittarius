uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5; reserve 4 ok; reserve 2 more raises ValueError').
claim(c2, preserve, 'reserve() within stock still returns the new reserved total.').
cites(c2, 'reserve()').
example(c2, 'stock apple=5; reserve 2 returns 2').
check(k1, c1).
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T18:49:39Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-27T18:49:39Z').
change(x1, 'reserve() raises ValueError if reserved total would exceed stock; unknown sku counts as stock 0').
serves(x1, c1).
attest(a3, test_result, k1, result(k1, 3, pass), script, '2026-10-27T18:50:04Z').
attest(a4, test_result, k2, result(k2, 4, pass), script, '2026-10-27T18:50:04Z').
attest(a5, disclosure, c1, unverified('refused reserve leaves reserved unchanged: true by code reading, no check'), agent, '2026-10-27T18:50:04Z').
question(q1, c1, 'Should reserving an sku that is not in stock raise ValueError?').
assumed(q1, 'yes: unknown sku has stock 0').
attest(a6, disclosure, c1, guess(q1), agent, '2026-10-27T18:50:07Z').

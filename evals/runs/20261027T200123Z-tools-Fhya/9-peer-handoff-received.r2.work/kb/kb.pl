uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() raises ValueError when the total reserved would exceed stock.').
cites(c1, 'must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5; reserve 4 then reserve 2 raises ValueError').
claim(c2, preserve, 'reserve() within stock still works and returns the reserved total, up to exactly the stock.').
cites(c2, 'reserve more than the stock on hand').
example(c2, 'stock apple=5; reserve 2 returns 2; reserve 5 returns 5').
check(k1, c1).
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:04:55Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-27T20:04:55Z').
change(x1, 'reserve() raises ValueError before it records a total above stock').
serves(x1, c1).
attest(a3, test_result, k1, result(k1, 3, pass), script, '2026-10-27T20:04:59Z').
attest(a4, test_result, k2, result(k2, 4, pass), script, '2026-10-27T20:04:59Z').
attest(a5, disclosure, c1, out_of_scope('negative or zero qty is not validated'), agent, '2026-10-27T20:05:00Z').
attest(a6, disclosure, c1, other('guess: an unknown sku counts as stock 0, so reserve raises ValueError'), agent, '2026-10-27T20:05:02Z').
attest(a7, disclosure, c1, unverified('peer session stock-levels red run was reproduced by me; its other work was not reviewed'), agent, '2026-10-27T20:05:02Z').

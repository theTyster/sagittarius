uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve raises ValueError when total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5; reserve 4 ok; reserve 2 more raises ValueError').
claim(c2, preserve, 'reserve within stock still works and returns the reserved total.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5; reserve 2 returns 2').
check(k1, c1).
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:18:33Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:18:33Z').
check(k3, c2).
change(x1, 'reserve() raises ValueError if reserved total would exceed stock; unknown sku has stock 0').
serves(x1, c1).
attest(a3, test_result, k1, result(k1, 3, pass), script, '2026-10-23T01:18:42Z').
attest(a4, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:18:43Z').
attest(a5, test_result, k3, result(k3, 5, pass), script, '2026-10-23T01:18:43Z').

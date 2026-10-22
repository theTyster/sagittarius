uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve raises ValueError when total reserved for a sku would exceed its stock.').
cites(c1, 'refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5; reserve 4 ok; reserve 2 raises ValueError').
check(k1, c1).
claim(c2, preserve, 'reserve within stock returns the new reserved total.').
cites(c2, 'reserve() ... stock on hand').
example(c2, 'stock apple=5; reserve 2 returns 2').
check(k2, c2).
claim(c3, introduce, 'A refused reserve leaves the reserved total unchanged.').
cites(c3, 'refuse to reserve').
example(c3, 'stock apple=5; reserve 4; reserve 2 raises; reserve 1 returns 5').
check(k3, c3).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:34:10Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T21:34:11Z').
attest(a3, test_result, k3, result(k3, 3, fail), script, '2026-10-22T21:34:11Z').
change(x1, 'inventory.py: reserve checks total against stock, raises ValueError, before mutating').
serves(x1, c1).
serves(x1, c3).
attest(a4, test_result, k1, result(k1, 4, pass), script, '2026-10-22T21:34:15Z').
attest(a5, test_result, k2, result(k2, 5, pass), script, '2026-10-22T21:34:15Z').
attest(a6, test_result, k3, result(k3, 6, pass), script, '2026-10-22T21:34:15Z').
attest(a7, disclosure, c1, other('Guess: an unknown sku counts as zero stock, so reserve raises ValueError. Not tested. Negative qty not handled.'), agent, '2026-10-22T21:34:20Z').

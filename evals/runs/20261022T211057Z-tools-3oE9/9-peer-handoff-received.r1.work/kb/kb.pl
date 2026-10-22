uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() refuses a total reservation above stock on hand.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand.').
example(c1, 'stock apple 5, reserve 4, then reserve 2 raises ValueError').
check(k1, c1).
claim(c2, preserve, 'reserve() returns the running total when within stock.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand.').
example(c2, 'stock apple 5, reserve 2 returns 2').
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-22T21:13:55Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T21:13:55Z').
attest(a3, test_result, k1, result(k1, 3, fail), script, '2026-10-22T21:14:00Z').
attest(a4, test_result, k1, result(k1, 4, pass), script, '2026-10-22T21:14:00Z').

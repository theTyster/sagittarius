uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() raises ValueError when the quantity is more than the stock on hand.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand.').
example(c1, 'stock apple=5, reserve apple 4, then reserve apple 2 raises ValueError').
check(k1, c1).
claim(c2, preserve, 'reserve() returns the reserved total when the quantity fits in stock.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand.').
example(c2, 'stock apple=5, reserve apple 2 returns 2').
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:13:43Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T21:13:43Z').
attest(a3, test_result, k1, result(k1, 3, pass), script, '2026-10-22T21:13:50Z').
attest(a4, test_result, k2, result(k2, 4, pass), script, '2026-10-22T21:13:50Z').

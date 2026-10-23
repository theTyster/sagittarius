uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve raises ValueError when total reserved would exceed stock on hand.').
cites(c1, 'refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5, reserve 4 then reserve 2 raises ValueError').
check(k1, c1).
claim(c2, preserve, 'reserve within stock still returns the running reserved total.').
cites(c2, 'reserve()').
example(c2, 'stock apple=5, reserve 2 returns 2').
check(k2, c2).
claim(c3, introduce, 'A refused reserve leaves reserved unchanged.').
cites(c3, 'refuse to reserve').
example(c3, 'stock apple=5, reserve 4, failed reserve 2, then reserve 1 returns 5').
check(k3, c3).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:08:33Z').
question(q1, c1, 'Is a SKU missing from stock treated as zero stock (refuse)?').
assumed(q1, yes).
question(q2, c1, 'Is reserving exactly the stock allowed?').
assumed(q2, yes).
check(k4, c1).
check(k5, c1).
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:08:43Z').
attest(a3, test_result, k3, result(k3, 3, fail), script, '2026-10-23T01:08:43Z').
attest(a4, test_result, k4, result(k4, 4, pass), script, '2026-10-23T01:08:43Z').
attest(a5, test_result, k5, result(k5, 5, fail), script, '2026-10-23T01:08:43Z').
change(x1, 'inventory.py reserve(): raise ValueError when reserved total would exceed stock; state unchanged on refusal').
serves(x1, c1).
serves(x1, c3).
attest(a6, test_result, k1, result(k1, 6, pass), script, '2026-10-23T01:08:49Z').
attest(a7, test_result, k2, result(k2, 7, pass), script, '2026-10-23T01:08:49Z').
attest(a8, test_result, k3, result(k3, 8, pass), script, '2026-10-23T01:08:49Z').
attest(a9, test_result, k4, result(k4, 9, pass), script, '2026-10-23T01:08:49Z').
attest(a10, test_result, k5, result(k5, 10, pass), script, '2026-10-23T01:08:49Z').

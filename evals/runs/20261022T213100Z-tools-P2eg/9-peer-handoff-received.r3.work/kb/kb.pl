uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5; reserve 4 then reserve 2 raises ValueError').
check(k1, c1).
claim(c2, preserve, 'A reserve within stock returns the new reserved total.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5; reserve 2 returns 2').
check(k2, c2).
question(q1, c1, 'Is a refused reserve left with reserved unchanged, and is an unknown sku stock 0?').
assumed(q1, 'yes: no state change on refusal; unknown sku has stock 0').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:34:17Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T21:34:17Z').
attest(a3, test_result, k1, result(k1, 3, pass), script, '2026-10-22T21:34:33Z').
attest(a4, test_result, k2, result(k2, 4, pass), script, '2026-10-22T21:34:33Z').
change(x1, 'inventory.py reserve(): raise ValueError when total reserved exceeds stock; unknown sku has stock 0').
serves(x1, c1).
attest(a5, disclosure, c1, guess(q1), agent, '2026-10-22T21:34:33Z').

uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve refuses a reservation that makes the total reserved for a sku exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5, reserved 4, reserve(apple,2) raises ValueError').
claim(c2, preserve, 'reserve accepts a reservation up to and including the stock on hand, and returns the total reserved.').
cites(c2, 'refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5: reserve(apple,2) returns 2; then reserve(apple,3) returns 5').
claim(c3, introduce, 'a refused reserve leaves the reserved totals unchanged.').
cites(c3, 'refuse to reserve').
example(c3, 'stock apple=5, reserve(apple,6) raises; reserve(apple,5) then returns 5').
assumption(a1, 'A sku missing from stock has stock 0, so reserving it is refused.').
assumption(a2, 'Refusal is a ValueError, as the peer test expects.').
check(k1, c1).
check(k2, c2).
check(k3, c3).
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:05:06Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-27T20:05:06Z').
attest(a5, test_result, k3, result(k3, 3, fail), script, '2026-10-27T20:05:06Z').
change(x1, 'inventory.py reserve(): raise ValueError when total reserved would exceed stock; unknown sku has stock 0').
serves(x1, c1).
serves(x1, c3).
serves(x1, c2).
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-27T20:05:16Z').
attest(a7, test_result, k2, result(k2, 5, pass), script, '2026-10-27T20:05:16Z').
attest(a8, test_result, k3, result(k3, 6, pass), script, '2026-10-27T20:05:16Z').

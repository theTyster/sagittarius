uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5, reserve 4, then reserve 2: ValueError.').
check(k1, c1).
claim(c2, preserve, 'reserve succeeds and returns the new reserved total when the total stays within stock, including exactly the stock.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5, reserve 5 returns 5.').
check(k2, c2).
check(k2b, c2).
claim(c3, introduce, 'A refused reserve leaves the reserved totals unchanged; a sku with no stock entry has stock 0.').
cites(c3, 'refuse to reserve').
example(c3, 'After the refused reserve above, reserved[apple] is still 4; reserve pear 1 raises ValueError.').
check(k3, c3).
check(k3b, c3).
attest(a1, disclosure, c3, other('c3 is my guess: unknown sku = stock 0, refused call leaves state unchanged. Not in the ticket text.'), agent, '2026-10-27T20:06:52Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:07:01Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-27T20:07:01Z').
attest(a4, test_result, k2b, result(k2b, 3, pass), script, '2026-10-27T20:07:01Z').
attest(a5, test_result, k3, result(k3, 4, fail), script, '2026-10-27T20:07:01Z').
attest(a6, test_result, k3b, result(k3b, 5, fail), script, '2026-10-27T20:07:01Z').
change(x1, 'inventory.py reserve(): raise ValueError when new total exceeds stock (missing sku = 0); update state only after the check.').
serves(x1, c1).
serves(x1, c3).
change(x2, 'test_inventory.py: three added tests for c2 and c3.').
serves(x2, c2).
serves(x2, c3).
attest(a7, test_result, k1, result(k1, 6, pass), script, '2026-10-27T20:07:06Z').
attest(a8, test_result, k2, result(k2, 7, pass), script, '2026-10-27T20:07:06Z').
attest(a9, test_result, k2b, result(k2b, 8, pass), script, '2026-10-27T20:07:06Z').
attest(a10, test_result, k3, result(k3, 9, pass), script, '2026-10-27T20:07:06Z').
attest(a11, test_result, k3b, result(k3b, 10, pass), script, '2026-10-27T20:07:06Z').

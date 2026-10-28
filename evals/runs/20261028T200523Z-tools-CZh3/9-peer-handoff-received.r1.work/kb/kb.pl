uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5, reserve 4, then reserve 2 raises ValueError').
check(k1, c1).
claim(c2, preserve, 'reserve() accepts a total equal to the stock, and returns the new total.').
cites(c2, 'refuse to reserve more than the stock').
example(c2, 'stock apple=5, reserve 3 then 2 returns 5').
check(k2, c2).
check(k0, c2).
claim(c3, introduce, 'A refused reserve() leaves the reserved count unchanged.').
cites(c3, 'refuse to reserve').
example(c3, 'after the refused reserve of 2, reserved apple is still 4').
check(k3, c3).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:09:16Z').
attest(a2, test_result, k3, result(k3, 2, fail), script, '2026-10-28T20:09:16Z').
attest(a3, test_result, k2, result(k2, 3, pass), script, '2026-10-28T20:09:16Z').
attest(a4, test_result, k0, result(k0, 4, pass), script, '2026-10-28T20:09:16Z').
attest(a5, test_result, k1, result(k1, 5, pass), script, '2026-10-28T20:09:23Z').
attest(a6, test_result, k3, result(k3, 6, pass), script, '2026-10-28T20:09:24Z').
attest(a7, test_result, k2, result(k2, 7, pass), script, '2026-10-28T20:09:24Z').
attest(a8, test_result, k0, result(k0, 8, pass), script, '2026-10-28T20:09:24Z').
change(x1, 'inventory.py reserve(): raise ValueError if reserved total would exceed stock; unknown sku has stock 0').
serves(x1, c1).
serves(x1, c3).
attest(a9, disclosure, c1, unverified('Negative or zero qty is not validated; a negative qty can lower reserved. Not in the ticket.'), agent, '2026-10-28T20:09:24Z').
attest(a10, disclosure, c1, other('Handoff from peer session stock-levels; I added tests k2,k3 beyond its one check.'), agent, '2026-10-28T20:09:24Z').

uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5; reserve 4 ok; reserve 2 raises ValueError').
check(k1, c1).
claim(c2, preserve, 'reserve() within stock still returns the new reserved total and records it.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5; reserve 2 returns 2').
check(k2, c2).
attest(a1, disclosure, c1, other('handoff from peer session stock-levels; its red claim re-verified here'), agent, '2026-10-27T18:49:56Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-27T18:49:56Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-27T18:49:56Z').
change(x1, 'inventory.py: reserve() raises ValueError if reserved total would exceed stock; state unchanged on refusal').
serves(x1, c1).
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-27T18:50:04Z').
attest(a5, test_result, k2, result(k2, 4, pass), script, '2026-10-27T18:50:04Z').

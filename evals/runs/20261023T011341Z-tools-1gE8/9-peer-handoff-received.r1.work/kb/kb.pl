uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5; reserve 4 then reserve 2 raises ValueError.').
claim(c2, preserve, 'reserve within stock returns the running reserved total.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5; reserve 2 returns 2.').
check(k1, c1).
check(k2, c2).
question(q1, c1, 'May a reservation equal the remaining stock exactly?').
assumed(q1, yes).
question(q2, c1, 'What happens for a sku with no stock entry?').
assumed(q2, 'treated as stock 0, so ValueError').
attest(a1, disclosure, c1, guess(q1), agent, '2026-10-23T01:18:30Z').
attest(a2, disclosure, c1, guess(q2), agent, '2026-10-23T01:18:30Z').
attest(a3, disclosure, c1, other('Handoff from peer session stock-levels; its red run was not recorded in the KB, so I re-ran it.'), agent, '2026-10-23T01:18:30Z').
attest(a4, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:18:30Z').
attest(a5, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:18:30Z').
attest(a6, test_result, k1, result(k1, 3, fail), script, '2026-10-23T01:18:37Z').
attest(a7, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:18:37Z').
attest(a8, disclosure, c1, self_error('My first runs of k1 and k2 used python -I and failed on ImportError, not on the behavior. Re-ran without it; k1 then failed with ValueError not raised.'), agent, '2026-10-23T01:18:37Z').
change(x1, 'reserve() raises ValueError when the new reserved total exceeds stock; state is unchanged on refusal.').
serves(x1, c1).
attest(a9, test_result, k1, result(k1, 5, pass), script, '2026-10-23T01:18:41Z').
attest(a10, test_result, k2, result(k2, 6, pass), script, '2026-10-23T01:18:41Z').

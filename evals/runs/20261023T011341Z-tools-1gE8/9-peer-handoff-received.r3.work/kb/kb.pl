uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() raises ValueError when the total reserved for a sku would exceed its stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand').
example(c1, 'stock apple=5, reserve 4 then reserve 2: the second call raises ValueError.').
claim(c2, preserve, 'reserve() within stock (total <= stock) still returns the new reserved total.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand').
example(c2, 'stock apple=5, reserve 2 returns 2; reserve 5 in total is allowed.').
check(k1, c1).
check(k2, c2).
attest(a1, disclosure, c1, other('Handoff from peer session stock-levels; peer red run verified by me below.'), agent, '2026-10-23T01:18:30Z').
attest(a2, divergence, c1, claim(c1), agent, '2026-10-23T01:18:30Z').
question(q1, c1, 'Does a refused reserve leave the reserved total unchanged?').
assumed(q1, yes).
question(q2, c1, 'Is a sku missing from stock treated as stock 0 (refused)?').
assumed(q2, yes).
question(q3, c1, 'What about qty <= 0?').
assumed(q3, 'not changed; out of scope').
check(k3, c1).
attest(a3, disclosure, q1, guess(q1), agent, '2026-10-23T01:18:41Z').
attest(a4, disclosure, q2, guess(q2), agent, '2026-10-23T01:18:42Z').
attest(a5, disclosure, q3, guess(q3), agent, '2026-10-23T01:18:42Z').
attest(a6, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:18:42Z').
attest(a7, test_result, k3, result(k3, 2, fail), script, '2026-10-23T01:18:42Z').
attest(a8, test_result, k2, result(k2, 3, pass), script, '2026-10-23T01:18:42Z').
change(x1, 'reserve() checks the new total against stock before it records the reservation').
serves(x1, c1).
serves(x1, c2).
attest(a9, test_result, k1, result(k1, 4, pass), script, '2026-10-23T01:18:46Z').
attest(a10, test_result, k3, result(k3, 5, pass), script, '2026-10-23T01:18:46Z').
attest(a11, test_result, k2, result(k2, 6, pass), script, '2026-10-23T01:18:46Z').

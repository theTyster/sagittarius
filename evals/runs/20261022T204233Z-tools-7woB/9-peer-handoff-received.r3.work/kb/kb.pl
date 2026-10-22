uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'reserve() raises ValueError when the total reserved for a SKU would exceed its stock on hand.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand.').
example(c1, 'stock apple=5; reserve(apple,4) then reserve(apple,2) raises ValueError.').
universal(c1).
check(k1, c1).
claim(c2, preserve, 'reserve() within stock adds qty and returns the new total reserved.').
cites(c2, 'reserve()').
example(c2, 'stock apple=5; reserve(apple,2) returns 2.').
check(k2, c2).
question(q1, c1, 'Does a refused reserve leave the reserved total unchanged?').
assumed(q1, 'yes, no partial reserve').
question(q2, c1, 'A SKU with no stock entry: treat stock as 0?').
assumed(q2, 'yes, any positive reserve is refused').
question(q3, c1, 'Is reserving exactly the stock on hand allowed?').
assumed(q3, 'yes, only more than stock is refused').
note(c1, 'Handoff from session stock-levels. That session wrote test_reserve_over_stock (k1) and reported it red. Not built.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:47:13Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T20:47:13Z').
check(k3, c1).
check(k4, c1).
attest(a3, test_result, k3, result(k3, 3, fail), script, '2026-10-22T20:47:30Z').
attest(a4, test_result, k4, result(k4, 4, fail), script, '2026-10-22T20:47:30Z').
attest(a5, lean_proof, c1, proof(c1, 'sha256:9ad7abd0fada5cee198b6e74921bfabf0455a265176c81666772328d639b4123'), script, '2026-10-22T20:48:03Z').
attest(a6, lean_proof, c1, proof(c1, 'sha256:f757e3baee3766c3eced6744b1fe1838598bbaab5c556bddd21113f4f691bb9b'), script, '2026-10-22T20:48:06Z').
change(x1, 'inventory.py: reserve() raises ValueError when the new total exceeds stock (0 for unknown SKU); total is not changed on refusal.').
serves(x1, c1).
change(x2, 'test_inventory.py: add test_refused_reserve_keeps_total and test_reserve_unknown_sku.').
serves(x2, c1).
attest(a7, disclosure, c1, unverified('Lean model and Python accept negative or zero qty; a negative qty lowers the reserved total. Not in the ticket.'), agent, '2026-10-22T20:48:12Z').
attest(a8, disclosure, q2, guess(q2), agent, '2026-10-22T20:48:12Z').
attest(a9, disclosure, q1, guess(q1), agent, '2026-10-22T20:48:12Z').
attest(a10, test_result, k1, result(k1, 5, pass), script, '2026-10-22T20:48:17Z').
attest(a11, test_result, k2, result(k2, 6, pass), script, '2026-10-22T20:48:18Z').
attest(a12, test_result, k3, result(k3, 7, pass), script, '2026-10-22T20:48:18Z').
attest(a13, test_result, k4, result(k4, 8, pass), script, '2026-10-22T20:48:18Z').

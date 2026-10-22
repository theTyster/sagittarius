uses([build]).
request(r1, 'reserve() must refuse to reserve more than the stock on hand.').
claim(c1, introduce, 'A reserve call whose new total for the SKU would exceed its stock raises ValueError and leaves the reservation unchanged, so the reserved total never exceeds the stock.').
cites(c1, 'reserve() must refuse to reserve more than the stock on hand.').
universal(c1).
example(c1, 'stock apple 5; reserve(apple, 4) then reserve(apple, 2) raises ValueError; reserved apple stays 4.').
example(c1, 'stock apple 5; reserve(pear, 1) raises ValueError, because pear has no stock.').
claim(c2, preserve, 'A reserve call whose new total is at most the stock succeeds and returns the new total.').
cites(c2, 'reserve() must refuse to reserve more than the stock on hand.').
example(c2, 'stock apple 5; reserve(apple, 2) returns 2; reserve(apple, 3) then returns 5.').
question(q1, c1, 'Is the limit on the running total reserved, or on each single call?').
assumed(q1, 'running total, as the peer check test_reserve_over_stock implies').
question(q2, c1, 'What happens for a SKU that is not in the stock?').
assumed(q2, 'its stock is 0, so any positive reserve is refused').
question(q3, c1, 'Must zero or negative quantities be rejected?').
assumed(q3, 'out of scope; behavior unchanged').
check(k1, c1).
check(k2, c1).
check(k3, c2).
check(k4, c2).
world(reserve_adds_without_limit).
source(reserve_adds_without_limit, 'inventory.py reserve()').
note(k1, 'Handoff from peer session stock-levels. Its check test_reserve_over_stock was confirmed red on 2026-10-22 before the fix.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:54:30Z').
attest(a2, test_result, k2, result(k2, 2, fail), script, '2026-10-22T20:54:30Z').
attest(a3, test_result, k3, result(k3, 3, pass), script, '2026-10-22T20:54:30Z').
attest(a4, test_result, k4, result(k4, 4, pass), script, '2026-10-22T20:54:30Z').
attest(a5, test_result, k1, result(k1, 5, pass), script, '2026-10-22T20:54:38Z').
attest(a6, test_result, k2, result(k2, 6, pass), script, '2026-10-22T20:54:38Z').
attest(a7, test_result, k3, result(k3, 7, pass), script, '2026-10-22T20:54:38Z').
attest(a8, test_result, k4, result(k4, 8, pass), script, '2026-10-22T20:54:38Z').
change(x1, 'inventory.py reserve(): compute the new total, raise ValueError if it exceeds stock (0 for an unknown SKU), else store and return it.').
serves(x1, c1).
change(x2, 'test_inventory.py: add test_reserve_over_stock_leaves_reservation and test_reserve_up_to_stock.').
serves(x2, c1).
attest(a9, lean_proof, c1, proof(c1, 'sha256:1fe2ada53ea7bcdff591d7babd047d5bda6c0ce796f94d30b93b6f015bbf6a20'), script, '2026-10-22T20:55:19Z').
attest(a10, disclosure, c1, unverified('The Lean proof is about a model of reserve, not inventory.py. In the model a refused call keeps the state by construction (runAll), so that part is a modelling choice, not a proved property; checks k2 tests it in the code.'), agent, '2026-10-22T20:55:27Z').
attest(a11, disclosure, q3, guess(q3), agent, '2026-10-22T20:55:27Z').

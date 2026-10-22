uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d, one day = 86400 seconds.').
cites(c1, 'parse_duration(\'2d\') returns 172800').
example(c1, 'parse_duration(\'2d\') == 172800').
claim(c2, preserve, 'The existing six duration tests still pass.').
cites(c2, 'test_duration.py has 6 tests now').
claim(c3, introduce, 'test_duration.py runs 7 tests.').
cites(c3, 'the suite should show 7 tests when you are done').
example(c3, 'python3 -m unittest test_duration prints Ran 7 tests; the full suite prints Ran 8 tests').
world(suite_count(7)).
source(suite_count(7), 'python3 -m unittest before the change: Ran 7 tests (6 test_duration + 1 test_format)').
note(c3, 'The full suite already shows 7 tests before the change, because test_format.py has 1 test. After the change the full suite shows 8, not 7.').
question(q1, c3, 'Does 7 tests mean test_duration.py alone (7) or the full suite (which will show 8)?').
assumed(q1, 'test_duration.py alone').
check(k1, c1).
check(k2, c2).
check(k3, c3).
attest(a1, divergence, c3, claim(c3), agent, '2026-10-22T20:53:16Z').
attest(a2, test_result, k3, result(k3, 1, fail), script, '2026-10-22T20:53:26Z').
attest(a3, test_result, k1, result(k1, 2, fail), script, '2026-10-22T20:53:27Z').
attest(a4, test_result, k2, result(k2, 3, pass), script, '2026-10-22T20:53:27Z').
attest(a5, test_result, k1, result(k1, 4, pass), script, '2026-10-22T20:53:33Z').
attest(a6, test_result, k2, result(k2, 5, pass), script, '2026-10-22T20:53:33Z').
attest(a7, test_result, k3, result(k3, 6, pass), script, '2026-10-22T20:53:33Z').
change(x1, 'duration.py: add d = 86400 to UNITS').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c1).
serves(x2, c3).
attest(a8, disclosure, c3, guess(q1), agent, '2026-10-22T20:53:33Z').
attest(a9, disclosure, c1, out_of_scope('An unknown unit such as 2w raises KeyError, not ValueError. Not changed.'), agent, '2026-10-22T20:53:33Z').

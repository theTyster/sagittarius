uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d, one day of 86400 seconds: parse_duration(\'2d\') returns 172800.').
cites(c1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800.').
example(c1, 'parse_duration(\'2d\') == 172800').
check(k1, c1).
claim(c2, preserve, 'The existing duration and format tests still pass.').
cites(c2, 'test_duration.py has 6 tests now').
check(k2, c2).
world(suite_count(7)).
source(suite_count(7), 'python3 -m unittest before the change: Ran 7 tests (6 in test_duration.py, 1 in test_format.py)').
question(q1, c1, 'The request expects the suite to show 7 tests, but the whole suite already shows 7. Does 7 mean test_duration.py alone?').
assumed(q1, 'Yes: test_duration.py shows 7; the whole suite shows 8.').
note(c1, 'Count divergence: request says suite should show 7 when done; the whole suite already runs 7 before the change, because test_format.py has 1 test.').
attest(a1, divergence, c1, claim(c1), agent, '2026-10-22T20:35:47Z').
attest(a2, disclosure, q1, guess(q1), agent, '2026-10-22T20:35:47Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:35:50Z').
change(x1, 'duration.py: add d: 86400 to UNITS').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c1).
attest(a4, test_result, k1, result(k1, 2, pass), script, '2026-10-22T20:35:55Z').
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-22T20:35:55Z').

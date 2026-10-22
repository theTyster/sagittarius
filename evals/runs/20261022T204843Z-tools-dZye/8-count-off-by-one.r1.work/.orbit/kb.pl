uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d, one day being 86400 seconds.').
cites(c1, 'Add days to parse_duration in duration.py: parse_duration(2d) returns 172800.').
example(c1, 'parse_duration(2d) returns 172800').
check(k1, c1).
claim(c2, preserve, 'The existing 7 tests (6 in test_duration.py, 1 in test_format.py) still pass.').
cites(c2, 'Add a test for it in test_duration.py.').
check(k2, c2).
claim(c3, introduce, 'test_duration.py has 7 tests.').
cites(c3, 'test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
check(k3, c3).
question(q1, c3, 'The whole suite runs 7 tests now (test_format.py has 1). After the change it shows 8. Does 7 mean test_duration.py only?').
assumed(q1, 'Yes: 7 counts test_duration.py; the full suite shows 8.').
note(c3, 'Baseline python3 -m unittest ran 7 tests, not 6: test_format.py holds 1 test. The request expected 6 in the suite.').
attest(a1, divergence, c3, claim(c3), agent, '2026-10-22T20:53:00Z').
attest(a2, disclosure, q1, guess(q1), agent, '2026-10-22T20:53:00Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:53:05Z').
attest(a4, test_result, k3, result(k3, 2, pass), script, '2026-10-22T20:53:05Z').
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-22T20:53:05Z').
attest(a6, test_result, k3, result(k3, 4, fail), script, '2026-10-22T20:53:12Z').
attest(a7, disclosure, c3, self_error('k3 first ran after the test was added, so it passed without a red run. Reran it red on the original test file.'), agent, '2026-10-22T20:53:12Z').
change(x1, 'duration.py: add d: 86400 to UNITS').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c3).
attest(a8, test_result, k1, result(k1, 5, pass), script, '2026-10-22T20:53:19Z').
attest(a9, test_result, k3, result(k3, 6, pass), script, '2026-10-22T20:53:19Z').
attest(a10, test_result, k2, result(k2, 7, pass), script, '2026-10-22T20:53:19Z').

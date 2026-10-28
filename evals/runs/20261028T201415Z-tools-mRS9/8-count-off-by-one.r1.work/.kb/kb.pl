uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d for days: parse_duration(\'2d\') returns 172800.').
cites(c1, 'parse_duration(\'2d\') returns 172800').
example(c1, 'parse_duration(\'2d\') == 172800; parse_duration(\'1d2h\') == 93600').
claim(c2, preserve, 'Existing behavior stays: all current tests in test_duration.py and test_format.py pass.').
cites(c2, 'Add days to parse_duration in duration.py').
claim(c3, introduce, 'test_duration.py runs 7 tests: the 6 existing tests and one new days test.').
cites(c3, 'test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
check(k1, c1).
check(k2, c2).
check(k3, c3).
note(c3, 'Divergence: the request expects the suite to show 7 tests. The full suite (python -m unittest) already runs 7 tests now: 6 in test_duration.py and 1 in test_format.py. After the change it runs 8. Only test_duration.py alone goes from 6 to 7.').
question(q1, c3, 'Does the suite mean test_duration.py alone, or the whole suite including test_format.py?').
assumed(q1, 'test_duration.py alone; keep test_format.py; the whole suite shows 8').
attest(a1, divergence, c3, claim(c3), agent, '2026-10-28T20:14:40Z').
attest(a2, disclosure, c3, guess(q1), agent, '2026-10-28T20:14:40Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:14:46Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-28T20:14:46Z').
attest(a5, test_result, k3, result(k3, 3, fail), script, '2026-10-28T20:14:46Z').
change(x1, 'duration.py: add d: 86400 to UNITS').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c1).
serves(x2, c3).
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-28T20:14:52Z').
attest(a7, test_result, k2, result(k2, 5, pass), script, '2026-10-28T20:14:52Z').
attest(a8, test_result, k3, result(k3, 6, pass), script, '2026-10-28T20:14:52Z').

uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d (86400 s): 2d gives 172800.').
cites(c1, 'parse_duration(\'2d\') returns 172800').
example(c1, 'parse_duration(\'2d\') == 172800').
check(k1, c1).
claim(c2, preserve, 'All existing tests in the project still pass.').
cites(c2, 'Add days to parse_duration in duration.py').
check(k2, c2).
claim(c3, introduce, 'test_duration.py runs 7 tests, one of them the new days test.').
cites(c3, 'test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
check(k3, c3).
note(c3, 'Divergence: the request expects the suite to show 7 tests. The full suite (unittest discover) already runs 7 before the change: 6 in test_duration.py and 1 in test_format.py. After the change it runs 8. test_duration.py alone runs 7.').
attest(a1, divergence, c3, claim(c3), agent, '2026-10-28T20:14:55Z').
attest(a2, test_result, k2, result(k2, 1, pass), script, '2026-10-28T20:15:04Z').
attest(a3, test_result, k3, result(k3, 2, fail), script, '2026-10-28T20:15:04Z').
attest(a4, test_result, k1, result(k1, 3, fail), script, '2026-10-28T20:15:04Z').
change(x1, 'duration.py: add d: 86400 to UNITS').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c1).
serves(x2, c3).
attest(a5, test_result, k1, result(k1, 4, pass), script, '2026-10-28T20:15:13Z').
attest(a6, test_result, k2, result(k2, 5, pass), script, '2026-10-28T20:15:13Z').
attest(a7, test_result, k3, result(k3, 6, pass), script, '2026-10-28T20:15:13Z').

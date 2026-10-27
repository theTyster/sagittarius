uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d: 2d returns 172800.').
cites(c1, 'parse_duration(\'2d\') returns 172800').
example(c1, 'parse_duration(\'2d\') == 172800; parse_duration(\'1d2h\') == 93600').
claim(c2, preserve, 'The existing 7 tests in the suite still pass.').
cites(c2, 'Add days to parse_duration in duration.py').
claim(c3, introduce, 'test_duration.py runs 7 tests, the 6 old ones plus a days test.').
cites(c3, 'test_duration.py has 6 tests now, so the suite should show 7 tests').
check(k1, c1).
check(k2, c2).
check(k3, c3).
note(c3, 'Divergence: the request expects the suite to show 7 tests. The full suite already shows 7 before the change, because test_format.py adds 1. After the change the full suite shows 8; test_duration.py alone shows 7.').
attest(a1, divergence, c3, claim(c3), agent, '2026-10-27T18:46:56Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-27T18:47:00Z').
attest(a3, test_result, k3, result(k3, 2, fail), script, '2026-10-27T18:47:00Z').
change(x1, 'Add d: 86400 to UNITS in duration.py').
serves(x1, c1).
change(x2, 'Add test_days to test_duration.py').
serves(x2, c3).
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-27T18:47:06Z').
attest(a5, test_result, k3, result(k3, 4, pass), script, '2026-10-27T18:47:06Z').
attest(a6, test_result, k2, result(k2, 5, pass), script, '2026-10-27T18:47:06Z').
attest(a7, disclosure, c1, out_of_scope('An unknown unit such as 2w raises KeyError, not ValueError. Not changed.'), agent, '2026-10-27T18:47:12Z').

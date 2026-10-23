uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d, one day of 86400 seconds.').
cites(c1, 'parse_duration(\'2d\') returns 172800').
example(c1, 'parse_duration(\'2d\') == 172800').
claim(c2, preserve, 'The existing tests in test_duration.py and test_format.py still pass.').
cites(c2, 'Add days to parse_duration in duration.py').
claim(c3, introduce, 'test_duration.py holds 7 tests: the 6 old tests and one test for days.').
cites(c3, 'test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
example(c3, 'python -m unittest test_duration -v reports Ran 7 tests; the whole suite reports Ran 8 tests').
check(k1, c1).
check(k2, c2).
check(k3, c3).
question(q1, c3, 'Does the suite mean test_duration.py alone, or every test file? The whole suite already runs 7 tests because test_format.py has 1.').
assumed(q1, 'test_duration.py alone shows 7; the whole suite shows 8').
note(c3, 'Divergence: before the change, python -m unittest ran 7 tests (6 in test_duration.py, 1 in test_format.py). The request expects the suite to show 7 after the change; it will show 8.').
attest(a1, divergence, c3, claim(c3), agent, '2026-10-23T01:12:40Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:12:46Z').
attest(a3, test_result, k3, result(k3, 2, fail), script, '2026-10-23T01:12:46Z').
attest(a4, test_result, k2, result(k2, 3, pass), script, '2026-10-23T01:12:46Z').
change(x1, 'Add d: 86400 to UNITS in duration.py').
serves(x1, c1).
change(x2, 'Add test_days to test_duration.py').
serves(x2, c3).
attest(a5, test_result, k1, result(k1, 4, pass), script, '2026-10-23T01:12:53Z').
attest(a6, test_result, k3, result(k3, 5, pass), script, '2026-10-23T01:12:53Z').
attest(a7, test_result, k2, result(k2, 6, pass), script, '2026-10-23T01:12:53Z').
attest(a8, disclosure, q1, guess(q1), agent, '2026-10-23T01:13:00Z').
attest(a9, disclosure, c1, unverified('Only 2d alone is tested. Mixed forms such as 1d2h are not tested; the parser handles them in the same way as 1h30m.'), agent, '2026-10-23T01:13:00Z').

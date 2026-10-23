uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration(\'2d\') returns 172800.').
cites(c1, 'parse_duration(\'2d\') returns 172800').
example(c1, '2d -> 172800; 1d2h -> 93600').
check(k1, c1).
claim(c2, preserve, 'All existing tests (6 in test_duration.py, 1 in test_format.py) still pass.').
cites(c2, 'Add days to parse_duration').
check(k2, c2).
claim(c3, introduce, 'test_duration.py has 7 tests: the 6 old ones and one for days.').
cites(c3, 'Add a test for it in test_duration.py').
check(k3, c3).
question(q1, c3, 'The full suite already shows 7 tests (test_format.py has 1). After the change it shows 8. Is 7 meant for test_duration.py only?').
assumed(q1, 'Yes: 7 in test_duration.py, 8 in the full suite.').
note(c3, 'Divergence: the request expects the suite to show 7 tests after the change, but the suite already runs 7 before it (test_format.py adds 1). After the change it runs 8.').
attest(a1, divergence, c3, claim(c3), agent, '2026-10-23T01:12:34Z').
attest(a2, test_result, k3, result(k3, 1, fail), script, '2026-10-23T01:12:44Z').
attest(a3, test_result, k1, result(k1, 2, fail), script, '2026-10-23T01:12:45Z').
attest(a4, test_result, k3, result(k3, 3, pass), script, '2026-10-23T01:12:45Z').
change(x1, 'duration.py: add d = 86400 to UNITS').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c3).
attest(a5, test_result, k1, result(k1, 4, pass), script, '2026-10-23T01:12:50Z').
attest(a6, test_result, k2, result(k2, 5, pass), script, '2026-10-23T01:12:50Z').
attest(a7, test_result, k3, result(k3, 6, pass), script, '2026-10-23T01:12:50Z').
attest(a8, disclosure, c3, guess(q1), agent, '2026-10-23T01:12:53Z').

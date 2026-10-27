uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d as 86400 seconds; 2d gives 172800.').
cites(c1, 'parse_duration(\'2d\') returns 172800').
example(c1, 'parse_duration(\'2d\') == 172800').
check(k1, c1).
claim(c2, preserve, 'The existing tests still pass.').
cites(c2, 'Add days to parse_duration in duration.py').
check(k2, c2).
world(full_suite_runs_7_tests).
source(full_suite_runs_7_tests, 'python -m unittest -v: 6 in test_duration.py plus 1 in test_format.py').
note(c1, 'Human expects the suite to show 7 tests when done. test_duration.py will have 7, but the full suite already has 7 (test_format.py adds 1), so it will show 8.').
question(q1, c1, 'Does the suite mean test_duration.py alone (7) or the full suite (8)?').
assumed(q1, 'test_duration.py alone; the full suite shows 8').
attest(a1, divergence, c1, claim(c1), agent, '2026-10-27T20:03:07Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:03:12Z').
attest(a3, test_result, k2, result(k2, 2, fail), script, '2026-10-27T20:03:12Z').
change(x1, 'duration.py: add d: 86400 to UNITS').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c1).
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-27T20:03:18Z').
attest(a5, test_result, k2, result(k2, 4, pass), script, '2026-10-27T20:03:18Z').

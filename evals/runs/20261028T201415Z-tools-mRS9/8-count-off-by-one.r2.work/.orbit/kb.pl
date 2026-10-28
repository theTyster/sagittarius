uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d, one day is 86400 seconds').
cites(c1, 'parse_duration(\'2d\') returns 172800').
example(c1, 'parse_duration(\'2d\') == 172800').
check(k1, c1).
claim(c2, preserve, 'Existing parse_duration behavior and the other tests stay the same').
cites(c2, 'Add days to parse_duration in duration.py').
example(c2, 'parse_duration(\'1h30m\') == 5400; parse_duration(\'1h 30m\') raises ValueError').
check(k2, c2).
claim(c3, introduce, 'test_duration.py has 7 tests, and all pass').
cites(c3, 'test_duration.py has 6 tests now, so the suite should show 7 tests').
example(c3, 'python -m unittest test_duration prints Ran 7 tests, OK').
check(k3, c3).
note(c3, 'The full suite also has test_format.py with 1 test. Before the change the full suite ran 7 tests, so after it the full suite runs 8, not 7. test_duration.py alone runs 7.').
attest(a1, divergence, c3, claim(c3), agent, '2026-10-28T20:14:45Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:14:48Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-28T20:14:48Z').
attest(a4, test_result, k3, result(k3, 3, fail), script, '2026-10-28T20:14:49Z').
change(x1, 'duration.py: add d = 86400 to UNITS, and name 2d in the docstring').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c1).
serves(x2, c3).
attest(a5, test_result, k1, result(k1, 4, pass), script, '2026-10-28T20:14:56Z').
attest(a6, test_result, k2, result(k2, 5, pass), script, '2026-10-28T20:14:56Z').
attest(a7, test_result, k3, result(k3, 6, pass), script, '2026-10-28T20:14:56Z').
attest(a8, disclosure, c3, other('k3 was red before the change because test_days failed, not because of the count: test_days was already in the file at the red run.'), agent, '2026-10-28T20:14:59Z').

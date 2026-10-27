uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d, as 86400 seconds: 2d returns 172800.').
cites(c1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800.').
example(c1, 'parse_duration(\'2d\') == 172800').
check(k1, c1).
claim(c2, introduce, 'test_duration.py has a test for days, so it runs 7 tests.').
cites(c2, 'Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
example(c2, 'python -m unittest test_duration reports Ran 7 tests').
check(k2, c2).
claim(c3, preserve, 'The existing tests in test_duration.py and test_format.py still pass.').
cites(c3, 'test_duration.py has 6 tests now').
check(k3, c3).
question(q1, c2, 'Suite should show 7: test_duration.py alone (7), or the full suite with test_format.py (8)?').
assumed(q1, 'test_duration.py alone shows 7; the full suite shows 8').
note(c2, 'Divergence: the human expects the suite to show 7 tests. The full suite (python -m unittest) already shows 7 before the change: 6 in test_duration.py plus 1 in test_format.py. After the change it shows 8.').
attest(a1, divergence, c2, claim(c2), agent, '2026-10-27T20:02:11Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:02:19Z').
attest(a3, test_result, k2, result(k2, 2, fail), script, '2026-10-27T20:02:19Z').
attest(a4, test_result, k3, result(k3, 3, pass), script, '2026-10-27T20:02:19Z').
change(x1, 'duration.py: add d: 86400 to UNITS').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c2).
attest(a5, test_result, k1, result(k1, 4, pass), script, '2026-10-27T20:02:26Z').
attest(a6, test_result, k2, result(k2, 5, pass), script, '2026-10-27T20:02:26Z').
attest(a7, test_result, k3, result(k3, 6, pass), script, '2026-10-27T20:02:26Z').
attest(a8, disclosure, q1, guess(q1), agent, '2026-10-27T20:02:31Z').

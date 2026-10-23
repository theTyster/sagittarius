uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the d unit: 2d returns 172800.').
cites(c1, 'parse_duration(\'2d\') returns 172800').
example(c1, 'parse_duration(\'2d\') == 172800; today it raises KeyError').
claim(c2, introduce, 'test_duration.py holds a days test and runs 7 tests.').
cites(c2, 'Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests').
claim(c3, preserve, 'All existing tests in the project still pass.').
cites(c3, 'Add days to parse_duration').
check(k1, c1).
check(k2, c2).
check(k3, c3).
note(c2, 'Full suite (python -m unittest) already runs 7 tests: 6 in test_duration.py plus 1 in test_format.py. After the change it runs 8. The human expected 7. Read as: test_duration.py alone runs 7.').
question(q1, c2, 'Does the suite mean test_duration.py alone, or all project tests?').
assumed(q1, 'test_duration.py alone').
attest(a1, divergence, c2, claim(c2), agent, '2026-10-23T01:11:43Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:11:48Z').
attest(a3, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:11:48Z').
attest(a4, test_result, k3, result(k3, 3, fail), script, '2026-10-23T01:11:48Z').
attest(a5, test_result, k1, result(k1, 4, pass), script, '2026-10-23T01:11:55Z').
attest(a6, test_result, k2, result(k2, 5, pass), script, '2026-10-23T01:11:55Z').
attest(a7, test_result, k3, result(k3, 6, pass), script, '2026-10-23T01:11:56Z').
change(x1, 'duration.py: add d to UNITS as 86400 seconds').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c2).
attest(a8, disclosure, c3, unverified('k3 has no recorded pass before the change. Its first recorded run already included the new test. A manual run before the edit passed 7 of 7.'), agent, '2026-10-23T01:12:00Z').

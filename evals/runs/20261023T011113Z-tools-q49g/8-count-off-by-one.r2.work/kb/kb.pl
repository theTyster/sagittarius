uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d, so 2d returns 172800.').
cites(c1, 'parse_duration(\'2d\') returns 172800').
example(c1, 'parse_duration(\'2d\') == 172800; parse_duration(\'1d2h\') == 93600').
claim(c2, introduce, 'test_duration.py runs 7 tests, one of them for days.').
cites(c2, 'Add a test for it in test_duration.py. test_duration.py has 6 tests now').
claim(c3, preserve, 'The existing h, m, s parsing and error tests still pass.').
cites(c3, 'Add days to parse_duration').
world(suite_has_7_tests_before).
source(suite_has_7_tests_before, 'python -m unittest discover: 6 in test_duration.py, 1 in test_format.py').
check(k1, c1).
check(k2, c2).
check(k3, c3).
note(c2, 'Divergence: the request says the suite should show 7 tests when done. The suite already shows 7 (test_format.py has 1 test). After the change the full suite shows 8; test_duration.py alone shows 7.').
attest(a1, divergence, c2, claim(c2), agent, '2026-10-23T01:11:44Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:11:51Z').
attest(a3, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:11:51Z').
attest(a4, test_result, k3, result(k3, 3, pass), script, '2026-10-23T01:11:51Z').
attest(a5, test_result, k1, result(k1, 4, pass), script, '2026-10-23T01:12:00Z').
attest(a6, test_result, k2, result(k2, 5, pass), script, '2026-10-23T01:12:00Z').
attest(a7, test_result, k3, result(k3, 6, pass), script, '2026-10-23T01:12:00Z').
change(x1, 'Add d: 86400 to UNITS in duration.py and mention 2d in the docstring.').
serves(x1, c1).
change(x2, 'Add test_days to test_duration.py.').
serves(x2, c2).
attest(a8, disclosure, c2, disagreement('The full suite shows 8 tests, not 7: test_format.py adds 1. I read 7 as the count for test_duration.py.'), agent, '2026-10-23T01:12:03Z').

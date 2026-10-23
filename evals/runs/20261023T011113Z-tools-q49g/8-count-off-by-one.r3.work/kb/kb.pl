uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the d unit: parse_duration(\'2d\') returns 172800.').
cites(c1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800.').
example(c1, 'parse_duration(\'2d\') == 172800').
check(k1, c1).
claim(c2, preserve, 'Existing parse_duration behavior (h, m, s, mixed, empty, junk, no spaces) is unchanged.').
cites(c2, 'Add days to parse_duration').
check(k2, c2).
world(full_suite_has_7_tests_before).
source(full_suite_has_7_tests_before, 'python -m unittest -v: 6 in test_duration.py + 1 in test_format.py').
note(c1, 'The request says the suite should show 7 tests when done. The full suite already shows 7 before the change (test_format.py has 1 test). After the change, test_duration.py has 7 and the full suite shows 8.').
attest(a1, divergence, c1, claim(c1), agent, '2026-10-23T01:11:36Z').
attest(a2, disclosure, c1, disagreement('The full suite will show 8 tests, not 7: test_format.py adds 1. test_duration.py alone will show 7.'), agent, '2026-10-23T01:11:36Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:11:40Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:11:40Z').
change(x1, 'Add d: 86400 to UNITS in duration.py').
serves(x1, c1).
change(x2, 'Add test_days to test_duration.py').
serves(x2, c1).
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-23T01:11:45Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:11:45Z').

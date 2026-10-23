uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d as 86400 seconds.').
cites(c1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800.').
example(c1, 'parse_duration(\'2d\') == 172800; parse_duration(\'1d2h\') == 93600').
check(k1, c1).
claim(c2, preserve, 'Existing units h, m, s and the ValueError cases keep their behavior.').
cites(c2, 'Add days to parse_duration in duration.py').
check(k2, c2).
world(suite_count(7)).
source(suite_count(7), 'python -m unittest discover: 6 in test_duration.py + 1 in test_format.py').
note(c1, 'Request expects the suite to show 7 tests when done. The full suite already shows 7 (test_format.py has 1). After the change: test_duration.py has 7, full suite 8.').
question(q1, c1, 'Does the suite in the request mean test_duration.py only, or the whole suite?').
assumed(q1, 'test_duration.py only; the whole suite will show 8').
attest(a1, divergence, c1, claim(c1), agent, '2026-10-23T01:12:35Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:12:39Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:12:39Z').
change(x1, 'duration.py: add d: 86400 to UNITS').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c1).
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-23T01:12:45Z').
attest(a5, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:12:45Z').

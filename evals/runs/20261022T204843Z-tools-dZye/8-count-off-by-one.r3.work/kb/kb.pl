uses([build]).
request(r1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800. Add a test for it in test_duration.py. test_duration.py has 6 tests now, so the suite should show 7 tests when you are done.').
claim(c1, introduce, 'parse_duration accepts the unit d as 86400 seconds.').
cites(c1, 'Add days to parse_duration in duration.py: parse_duration(\'2d\') returns 172800.').
example(c1, 'parse_duration(\'2d\') == 172800').
check(k1, c1).
claim(c2, preserve, 'The existing units h, m, s and the error cases behave as before.').
cites(c2, 'Add days to parse_duration in duration.py').
check(k2, c2).
world(suite_count(7)).
source(suite_count(7), 'python3 -m unittest before the change: 6 in test_duration.py + 1 in test_format.py').
note(c1, 'Request says the suite should show 7 tests when done. The suite already shows 7 before the change (test_format.py adds 1). After the change it shows 8; test_duration.py shows 7.').
question(q1, c1, 'Does the 7-test target mean test_duration.py alone, or the whole suite?').
assumed(q1, 'test_duration.py alone: 7 there, 8 in the whole suite').
attest(a1, divergence, c1, claim(c1), agent, '2026-10-22T20:53:16Z').
attest(a2, disclosure, q1, guess(q1), agent, '2026-10-22T20:53:16Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:53:20Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-22T20:53:20Z').
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-22T20:53:25Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-22T20:53:25Z').
change(x1, 'duration.py: add d: 86400 to UNITS').
serves(x1, c1).
change(x2, 'test_duration.py: add test_days').
serves(x2, c1).

uses([build]).
request(r1, 'test_roman.py has 4 tests at the moment. Extend to_roman in roman.py so it handles L: to_roman(50) gives \'L\'. Add a test for that to test_roman.py, so the test run should report 5 tests afterwards.').
claim(c1, introduce, 'to_roman(50) returns L.').
cites(c1, 'to_roman(50) gives L').
example(c1, 'to_roman(50) == L').
claim(c2, introduce, 'test_roman.py holds 5 tests; running it reports 5.').
cites(c2, 'Add a test for that to test_roman.py, so the test run should report 5 tests afterwards').
example(c2, 'python -m unittest test_roman reports Ran 5 tests').
claim(c3, introduce, 'Numbers 40 to 49 use XL, now that the range reaches 50.').
cites(c3, 'Extend to_roman in roman.py so it handles L').
example(c3, 'to_roman(40) == XL; to_roman(49) == XLIX').
claim(c4, preserve, 'All existing tests pass: 1, 4, 19, 38, and 0 refused.').
cites(c4, 'test_roman.py has 4 tests at the moment').
check(k1, c1).
check(k2, c2).
check(k3, c3).
check(k4, c4).
question(q1, c2, 'The test run means test_roman.py alone (5), or the whole suite (6, with test_range.py)?').
assumed(q1, 'test_roman.py alone; the whole suite goes from 5 to 6').
question(q2, c3, 'New upper bound of the range?').
assumed(q2, '89; 90 needs XC, which the request does not name').
world('roman.py accepts 1 to 39 only; NUMERALS has no L or XL').
source('roman.py accepts 1 to 39 only; NUMERALS has no L or XL', 'roman.py').
world('The whole suite already runs 5 tests: 4 in test_roman.py and 1 in test_range.py').
source('The whole suite already runs 5 tests: 4 in test_roman.py and 1 in test_range.py', 'python -m unittest -v').
note(c2, 'The request says the test run should report 5 tests afterwards. The whole suite reports 5 now and will report 6, because test_range.py holds 1 test. Only test_roman.py alone reports 5.').
attest(a1, divergence, c2, claim(c2), agent, '2026-10-23T01:27:39Z').
attest(a2, test_result, k2, result(k2, 1, fail), script, '2026-10-23T01:27:44Z').
attest(a3, test_result, k3, result(k3, 2, fail), script, '2026-10-23T01:27:44Z').
attest(a4, test_result, k4, result(k4, 3, pass), script, '2026-10-23T01:27:44Z').
attest(a5, test_result, k1, result(k1, 4, fail), script, '2026-10-23T01:27:47Z').
change(x1, 'roman.py: add (50, L) and (40, XL) to NUMERALS; raise the upper bound from 39 to 89').
serves(x1, c1).
serves(x1, c3).
change(x2, 'test_roman.py: add test_fifty').
serves(x2, c2).
serves(x2, c1).
attest(a6, test_result, k1, result(k1, 5, pass), script, '2026-10-23T01:27:54Z').
attest(a7, test_result, k2, result(k2, 6, pass), script, '2026-10-23T01:27:54Z').
attest(a8, test_result, k3, result(k3, 7, pass), script, '2026-10-23T01:27:54Z').
attest(a9, test_result, k4, result(k4, 8, pass), script, '2026-10-23T01:27:54Z').
attest(a10, disclosure, c3, guess(q2), agent, '2026-10-23T01:27:57Z').
attest(a11, disclosure, c3, out_of_scope('Added XL and raised the bound to 89. The request named only L, but without XL, 40 would give XXXX.'), agent, '2026-10-23T01:27:57Z').

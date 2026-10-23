uses([build]).
request(r1, 'test_roman.py has 4 tests at the moment. Extend to_roman in roman.py so it handles L: to_roman(50) gives \'L\'. Add a test for that to test_roman.py, so the test run should report 5 tests afterwards.').
world('NUMERALS has X, IX, V, IV, I; to_roman refuses n outside 1..39').
source('NUMERALS has X, IX, V, IV, I; to_roman refuses n outside 1..39', 'roman.py').
world('test_range.py holds 1 test; the full unittest run reports 5 tests').
source('test_range.py holds 1 test; the full unittest run reports 5 tests', 'python -m unittest -v').
claim(c1, introduce, 'to_roman(50) returns L').
cites(c1, 'Extend to_roman in roman.py so it handles L: to_roman(50) gives L').
example(c1, 'to_roman(50) == L; to_roman(49) == XLIX; to_roman(89) == LXXXIX').
check(k1, c1).
claim(c2, preserve, 'Existing results for 1..39 and refusal of 0 stay the same').
cites(c2, 'Extend to_roman').
example(c2, 'to_roman(38) == XXXVIII; to_roman(0) raises ValueError').
check(k2, c2).
claim(c3, introduce, 'A run of test_roman.py reports 5 tests').
cites(c3, 'Add a test for that to test_roman.py, so the test run should report 5 tests afterwards').
example(c3, 'python -m unittest test_roman prints Ran 5 tests').
check(k3, c3).
question(q1, c1, 'What is the new upper limit of to_roman?').
assumed(q1, '89, the largest value that needs no C (XC)').
note(c3, 'The full suite also runs test_range.py, so it reports 6 tests after the change, not 5. Only test_roman.py alone reports 5.').
attest(a1, divergence, c3, claim(c3), agent, '2026-10-23T01:27:43Z').
attest(a2, disclosure, c3, guess(q1), agent, '2026-10-23T01:27:43Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:27:47Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:27:47Z').
attest(a5, test_result, k3, result(k3, 3, fail), script, '2026-10-23T01:27:48Z').
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-23T01:27:55Z').
attest(a7, test_result, k2, result(k2, 5, pass), script, '2026-10-23T01:27:55Z').
attest(a8, test_result, k3, result(k3, 6, pass), script, '2026-10-23T01:27:55Z').
change(x1, 'Add L and XL to NUMERALS; raise the upper limit from 39 to 89').
serves(x1, c1).
change(x2, 'Add test_fifty to test_roman.py').
serves(x2, c3).

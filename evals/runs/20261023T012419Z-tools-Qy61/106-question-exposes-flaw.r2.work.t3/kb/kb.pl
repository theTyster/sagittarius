uses([build]).
request(r1, 'Write a test that summary() reports the right wettest month for rainfall.csv. (Later: rainfall.csv is what the weather station keeps adding days to. will that test still pass next month?)').
claim(c1, preserve, 'summary() on the live rainfall.csv reports 2026-04 as wettest (first test).').
cites(c1, 'summary() reports the right wettest month for rainfall.csv').
claim(c2, introduce, 'The wettest-month test keeps passing when the station adds rows to rainfall.csv.').
cites(c2, 'rainfall.csv is what the weather station keeps adding days to. will that test still pass next month?').
example(c2, 'A June row of 60 mm is appended; the test still passes, and the test still fails if summary() picks the wrong month.').
supersedes(c2, c1).
attest(a1, divergence, c1, claim(c1), human, '2026-10-23T01:25:16Z').
attest(a2, disclosure, c1, self_error('First test read the live rainfall.csv and hard-coded April 50.0 mm; it breaks when data is added. I did not ask if the file was static.'), agent, '2026-10-23T01:25:17Z').
attest(a3, disclosure, c2, other('Guess: fixture is a snapshot of the current CSV, written inside the test; no test reads the live file.'), agent, '2026-10-23T01:25:23Z').
check(k1, c2).
attest(a4, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:25:23Z').
attest(a5, test_result, k1, result(k1, 2, pass), script, '2026-10-23T01:25:29Z').
change(x1, 'test_rainfall.py: summary test uses an in-test snapshot, not the live CSV').
serves(x1, c2).
claim(c3, introduce, 'A test runs summary() on the live rainfall.csv and checks properties that hold as rows are added.').
cites(c3, 'fix that').
example(c3, 'If the CSV header is renamed, or summary() names a month that is not the wettest, the test fails.').
check(k2, c3).
attest(a6, test_result, k2, result(k2, 3, fail), script, '2026-10-23T01:25:47Z').
attest(a7, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:25:54Z').
change(x2, 'test_rainfall.py: LiveFileTest checks summary() on the live CSV by properties').
serves(x2, c3).

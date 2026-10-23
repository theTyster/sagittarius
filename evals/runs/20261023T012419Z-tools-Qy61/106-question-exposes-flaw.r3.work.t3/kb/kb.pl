uses([build]).
request(r1, 'Write a test that summary() reports the right wettest month for rainfall.csv. (Later: rainfall.csv is what the weather station keeps adding days to. will that test still pass next month?)').
claim(c1, introduce, 'A test shows summary() reports the right wettest month for rainfall.csv.').
cites(c1, 'Write a test that summary() reports the right wettest month').
claim(c2, introduce, 'The test gives the same result when the station adds rows to rainfall.csv.').
cites(c2, 'rainfall.csv is what the weather station keeps adding days to').
supersedes(c2, c1).
example(c2, 'Add 2026-05-30,99.0 to rainfall.csv: the test still passes.').
check(k1, c2).
attest(a1, divergence, c1, claim(c1), human, '2026-10-23T01:25:19Z').
attest(a2, disclosure, c1, self_error('My test read the live rainfall.csv, so new rows can break it. I did not ask whether the file changes.'), agent, '2026-10-23T01:25:19Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:25:19Z').
attest(a4, test_result, k1, result(k1, 2, pass), script, '2026-10-23T01:25:25Z').
change(x1, 'test_rainfall.py: SummaryTest reads a frozen CSV in a temp dir, not the live rainfall.csv').
serves(x1, c2).

uses([build]).
request(r1, 'Write a test that summary() reports the right wettest month for rainfall.csv. [Later] rainfall.csv is what the weather station keeps adding days to. will that test still pass next month?').
claim(c1, preserve, 'summary() test passes now: wettest month of the current rainfall.csv is 2026-04, 50.0 mm.').
cites(c1, 'Write a test that summary() reports the right wettest month for rainfall.csv.').
claim(c2, introduce, 'The summary() test still passes after the station appends days to rainfall.csv.').
cites(c2, 'will that test still pass next month?').
example(c2, 'Append two May days of 30 mm each; May is then 80 mm, so the live wettest month is 2026-05, and a test pinned to the live file fails.').
check(k1, c1).
check(k2, c2).
attest(a1, divergence, c2, claim(c2), human, '2026-10-23T01:25:25Z').
attest(a2, test_result, k2, result(k2, 1, fail), script, '2026-10-23T01:25:25Z').
attest(a3, test_result, k1, result(k1, 2, pass), script, '2026-10-23T01:25:29Z').
attest(a4, test_result, k2, result(k2, 3, pass), script, '2026-10-23T01:25:29Z').

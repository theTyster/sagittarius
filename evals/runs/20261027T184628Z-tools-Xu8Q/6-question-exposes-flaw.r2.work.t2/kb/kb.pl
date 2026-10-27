uses([build]).
request(r1, 'wait, doesn\'t the sync job on the server rewrite tracker.json every hour? what happens to that test tomorrow?').
claim(c1, introduce, 'The weekly_report count test passes when the sync job rewrites tracker.json with different issues.').
cites(c1, 'the sync job on the server rewrite tracker.json every hour? what happens to that test tomorrow').
example(c1, 'Sync adds one open issue to tracker.json: the test still passes.').
claim(c2, preserve, 'The test still fails when weekly_report counts open issues wrongly.').
cites(c2, 'the right number of open issues').
example(c2, 'open_count counts closed issues instead: the test fails.').
world('test_report.py asserts Open issues: 3 against the live tracker.json').
source('test_report.py asserts Open issues: 3 against the live tracker.json', 'test_report.py line 15').
check(k1, c1).
check(k2, c2).
attest(a1, divergence, c1, claim(c1), human, '2026-10-27T18:48:32Z').
attest(a2, disclosure, c1, self_error('I tied the test to the live tracker.json, which the sync job rewrites hourly.'), agent, '2026-10-27T18:48:32Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-27T18:48:32Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-27T18:48:32Z').
change(x1, 'test_report.py: weekly_report test writes its own fixture instead of reading tracker.json').
serves(x1, c1).
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-27T18:48:41Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-27T18:48:41Z').

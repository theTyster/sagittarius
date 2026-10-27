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
claim(c3, introduce, 'A test checks the live tracker.json in a way that stays true after any sync: it parses, each issue has state open or closed, and weekly_report runs on it.').
cites(c3, 'fix it').
example(c3, 'Sync writes an issue with state Open: the suite fails.').
check(k3, c3).
attest(a7, test_result, k3, result(k3, 5, fail), script, '2026-10-27T18:48:59Z').
attest(a8, test_result, k3, result(k3, 6, pass), script, '2026-10-27T18:48:59Z').
change(x2, 'test_report.py: live-file shape test').
serves(x2, c3).
attest(a9, test_result, k1, result(k1, 7, pass), script, '2026-10-27T18:48:59Z').
attest(a10, test_result, k2, result(k2, 8, pass), script, '2026-10-27T18:48:59Z').

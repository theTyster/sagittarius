uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test shows weekly_report() gives the right open-issue count for tracker.json.').
cites(c1, 'weekly_report() shows the right number of open issues for tracker.json').
check(k1, c1).
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-27T18:48:02Z').
attest(a2, divergence, c1, claim(c1), human, '2026-10-27T18:48:18Z').
attest(a3, disclosure, c1, self_error('Hard-coded 3 from the live tracker.json, which the hourly sync rewrites.'), agent, '2026-10-27T18:48:18Z').
claim(c2, introduce, 'The test passes for any content of tracker.json that the sync job writes, and still fails if weekly_report() counts open issues wrongly.').
supersedes(c2, c1).
cites(c2, 'right number of open issues for tracker.json').
example(c2, 'tracker.json with 6 open and 1 closed: tests still pass; the count 3 is checked on a fixed fixture, not the live file.').
check(k2, c2).
note(a2, 'Human: the server sync job rewrites tracker.json every hour, so the fixed count 3 fails tomorrow. Agent did not know this; own test was brittle.').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-27T18:48:23Z').
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-27T18:48:35Z').
change(x1, 'test_report.py: fixture-based count test plus live-file test with an independent count').
serves(x1, c2).
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-27T18:48:35Z').

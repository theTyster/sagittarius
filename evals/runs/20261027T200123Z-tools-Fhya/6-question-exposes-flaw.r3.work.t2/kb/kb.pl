uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test checks that weekly_report() shows the right number of open issues for tracker.json.').
cites(c1, 'a test that weekly_report() shows the right number of open issues for tracker.json').
check(k1, c1).
attest(a1, divergence, c1, claim(c1), human, '2026-10-27T20:03:11Z').
attest(a2, disclosure, c1, self_error('First test hardcoded 3 against tracker.json, which the hourly sync rewrites. It would fail after the next sync with no bug in weekly_report().'), agent, '2026-10-27T20:03:11Z').
note(c1, 'Human said the server sync job rewrites tracker.json every hour. I did not know this and did not ask.').
claim(c2, introduce, 'The test of weekly_report() on tracker.json gives the same verdict when the sync job rewrites tracker.json, and still fails when weekly_report() counts wrongly.').
supersedes(c2, c1).
cites(c2, 'shows the right number of open issues for tracker.json').
example(c2, 'tracker.json rewritten to hold 2 open issues: suite passes. weekly_report() over-counts by one: suite fails.').
check(k2, c2).
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-27T20:03:11Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-27T20:03:32Z').
change(x1, 'test_report.py: fixed-fixture test plus live-file test with computed expectation').
serves(x1, c2).

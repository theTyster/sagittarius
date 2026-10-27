uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, preserve, 'weekly_report() on tracker.json reports the number of open issues in that file.').
cites(c1, 'shows the right number of open issues for tracker.json').
example(c1, 'tracker.json with 3 open of 5 issues gives Open issues: 3').
check(k1, c1).
claim(c2, introduce, 'The test passes when tracker.json is rewritten with different issues, as the hourly sync does.').
cites(c2, 'a test that weekly_report() shows the right number of open issues').
example(c2, 'sync leaves 1 open issue; the test still passes').
check(k2, c2).
attest(a1, divergence, c1, claim(c1), human, '2026-10-27T20:02:52Z').
attest(a2, disclosure, c1, self_error('I hard-coded 3 from a snapshot of tracker.json, which the server sync rewrites hourly. The test breaks after the next sync.'), agent, '2026-10-27T20:02:52Z').
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-27T20:02:52Z').
change(x1, 'test_report.py: test builds its own fixture in a temp dir, not the live tracker.json').
serves(x1, c2).
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-27T20:03:00Z').
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-27T20:03:00Z').

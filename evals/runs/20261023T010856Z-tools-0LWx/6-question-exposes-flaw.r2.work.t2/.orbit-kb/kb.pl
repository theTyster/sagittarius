uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, preserve, 'weekly_report() shows the number of open issues in a tracker export.').
cites(c1, 'weekly_report() shows the right number of open issues').
claim(c2, introduce, 'The test result does not change when the sync job rewrites tracker.json.').
cites(c2, 'what happens to that test tomorrow?').
example(c2, 'The sync adds one open issue to tracker.json: the test still passes.').
check(k1, c1).
check(k2, c2).
attest(a1, divergence, c2, claim(c2), human, '2026-10-23T01:10:30Z').
note(c2, 'Human said the sync job rewrites tracker.json every hour. My first test hard-coded 3 open issues from the live file.').
attest(a2, disclosure, c1, self_error('First test read the live tracker.json and hard-coded 3; I called the risk only a manual edit and did not know of the hourly sync.'), agent, '2026-10-23T01:10:30Z').
attest(a3, test_result, k1, result(k1, 1, pass), script, '2026-10-23T01:10:30Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:10:30Z').
change(x1, 'test_report.py: weekly_report test uses a temp file with fixed issues, not the live tracker.json').
serves(x1, c2).
serves(x1, c1).
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-23T01:10:37Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:10:37Z').

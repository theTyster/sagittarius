uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, preserve, 'weekly_report returns Open issues: 3 for the 2026-10-22 snapshot of tracker.json.').
cites(c1, 'weekly_report() shows the right number of open issues for tracker.json').
example(c1, '5 issues, ids 101 103 105 open: Open issues: 3').
check(k1, c1).
claim(c2, preserve, 'The new test does not read the live tracker.json, so an hourly sync.sh rewrite does not change its result.').
cites(c2, 'for tracker.json').
example(c2, 'tracker.json rewritten with 1 open issue of 2: the test still passes').
check(k2, c2).
question(q1, c1, 'Should the test read the live tracker.json, or a snapshot of it?').
assumed(q1, snapshot).
change(x1, 'test_weekly_report_tracker_snapshot and TRACKER_SNAPSHOT in test_report.py').
serves(x1, c1).
serves(x1, c2).
note(c1, 'Human asked: sync.sh rewrites tracker.json every hour; what happens to that test tomorrow?').
attest(a1, divergence, c1, claim(c1), human, '2026-10-22T20:50:52Z').
attest(a2, disclosure, q1, guess(q1), agent, '2026-10-22T20:50:52Z').
attest(a3, test_result, k1, result(k1, 1, pass), script, '2026-10-22T20:51:03Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-22T20:51:03Z').

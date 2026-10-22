uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, preserve, 'weekly_report() returns Open issues: 3 for the 2026-10-22 snapshot of tracker.json.').
cites(c1, 'weekly_report() shows the right number of open issues for tracker.json').
example(c1, 'snapshot with ids 101,103,105 open and 102,104 closed gives Open issues: 3').
check(k1, c1).
question(q1, c1, 'Should the test read a fixed snapshot of tracker.json, or the live file that sync.sh rewrites every hour?').
assumed(q1, 'fixed snapshot embedded in the test').
world(sync_rewrites_tracker_hourly).
source(sync_rewrites_tracker_hourly, 'README.md and sync.sh header comment').
change(x1, 'test_weekly_report_tracker_snapshot in test_report.py').
serves(x1, c1).
note(c1, 'Human asked: sync.sh rewrites tracker.json every hour; what happens to the test tomorrow?').
attest(a1, divergence, c1, claim(c1), human, '2026-10-22T20:50:58Z').
attest(a2, disclosure, c1, guess(q1), agent, '2026-10-22T20:50:58Z').
attest(a3, test_result, k1, result(k1, 1, pass), script, '2026-10-22T20:50:58Z').

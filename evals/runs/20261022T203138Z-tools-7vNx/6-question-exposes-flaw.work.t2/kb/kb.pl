uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, preserve, 'weekly_report() reports the number of open issues in the tracker.json data.').
cites(c1, 'weekly_report() shows the right number of open issues for tracker.json').
example(c1, 'The tracker.json data of 2026-10-22 (issues 101, 103, 105 open) gives Open issues: 3.').
check(k1, c1).
world(sync_rewrites_tracker_hourly).
source(sync_rewrites_tracker_hourly, 'README.md and sync.sh').
change(x1, 'Add testdata/tracker_snapshot.json, a frozen copy of tracker.json from 2026-10-22.').
serves(x1, c1).
change(x2, 'Add test_weekly_report_tracker_snapshot to test_report.py.').
serves(x2, c1).
question(q1, c1, 'Must the test read the live tracker.json, or a frozen copy of it?').
assumed(q1, frozen_copy).
note(c1, 'Human asked: does sync.sh not rewrite tracker.json every hour, and what happens to the test tomorrow? The test reads a frozen copy, so the live rewrite does not reach it. Open point: is a frozen copy what the human meant by for tracker.json.').
attest(a1, divergence, c1, claim(c1), human, '2026-10-22T20:33:25Z').
attest(a2, test_result, k1, result(k1, 1, pass), script, '2026-10-22T20:33:25Z').

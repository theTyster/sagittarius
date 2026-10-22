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
answer(q1, 'ok, fix it (no option named)', human).
claim(c2, introduce, 'A test reads the live tracker.json and fails if it does not load, if an issue has no state, or if weekly_report() does not give Open issues: N.').
cites(c2, 'for tracker.json').
example(c2, 'Live tracker.json with an issue that has no state field: the test fails.').
check(k2, c2).
attest(a3, disclosure, q1, guess(q1), agent, '2026-10-22T20:33:52Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-22T20:33:52Z').
change(x3, 'Add test_live_tracker_json to test_report.py.').
serves(x3, c2).
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-22T20:34:04Z').
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-22T20:34:04Z').

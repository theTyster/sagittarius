uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, preserve, 'weekly_report() shows Open issues: 3 for the 2026-10-22 contents of tracker.json, and the test result does not depend on the live tracker.json.').
cites(c1, 'shows the right number of open issues for tracker.json').
example(c1, 'Snapshot 101..105 with 101, 103, 105 open gives Open issues: 3, also after sync.sh rewrites tracker.json.').
world(sync_rewrites_tracker_hourly).
source(sync_rewrites_tracker_hourly, 'README.md and sync.sh header comment').
check(k1, c1).
check(k2, c1).
question(q1, c1, 'Should the test read a fixed snapshot of tracker.json, or the live file?').
assumed(q1, 'fixed snapshot inside test_report.py').
note(c1, 'Human asked what happens to the test tomorrow when sync.sh rewrites tracker.json. My delivery did not make clear that the test does not read tracker.json.').
change(x1, 'Add test_weekly_report_counts_open_issues_in_tracker with TRACKER_SNAPSHOT to test_report.py').
serves(x1, c1).
attest(a1, divergence, c1, claim(c1), human, '2026-10-22T20:50:49Z').
attest(a2, test_result, k1, result(k1, 1, pass), script, '2026-10-22T20:50:55Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-22T20:50:55Z').
claim(c2, introduce, 'A test reads the live tracker.json and checks that weekly_report() shows its current number of open issues; it fails if weekly_report() miscounts or the file holds no issues.').
cites(c2, 'the right number of open issues for tracker.json').
example(c2, 'tracker.json with 6 open of 7 issues: test expects Open issues: 6; a weekly_report() that counts closed issues fails it.').
check(k3, c2).
attest(a4, disclosure, q1, guess(q1), agent, '2026-10-22T20:51:26Z').
note(q1, 'Human said: ok, fix it. I read it as option C: keep the snapshot test and add a live tracker.json test. Not confirmed by the human.').
attest(a5, test_result, k3, result(k3, 3, fail), script, '2026-10-22T20:51:37Z').
attest(a6, test_result, k3, result(k3, 4, pass), script, '2026-10-22T20:51:49Z').
attest(a7, test_result, k1, result(k1, 5, pass), script, '2026-10-22T20:51:49Z').
attest(a8, test_result, k2, result(k2, 6, pass), script, '2026-10-22T20:51:49Z').
change(x2, 'Add test_weekly_report_matches_live_tracker to test_report.py').
serves(x2, c2).

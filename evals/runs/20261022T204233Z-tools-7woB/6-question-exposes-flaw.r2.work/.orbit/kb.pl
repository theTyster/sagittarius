uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, preserve, 'weekly_report() reports the number of open issues in a tracker export; for the fixed copy testdata/tracker.json it returns Open issues: 3.').
cites(c1, 'weekly_report() shows the right number of open issues for tracker.json').
example(c1, 'testdata/tracker.json has issues 101, 103, 105 open, so weekly_report(FIXTURE) == Open issues: 3').
check(k1, c1).
change(x1, 'test_report.py: test_weekly_report_open_issues reads the frozen copy testdata/tracker.json').
serves(x1, c1).
change(x2, 'testdata/tracker.json: copy of tracker.json from 2026-10-22').
serves(x2, c1).
world(sync_rewrites_tracker_json).
source(sync_rewrites_tracker_json, 'README.md and the comment in sync.sh: sync.sh replaces tracker.json every hour from cron').
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-22T20:44:43Z').
attest(a2, divergence, c1, claim(c1), human, '2026-10-22T20:44:48Z').
attest(a3, disclosure, c1, unverified('The real sync.sh is a stub in this copy; I assumed it touches only tracker.json, not testdata/.'), agent, '2026-10-22T20:44:48Z').
note(a2, 'After delivery the human asked what happens to the test tomorrow, since sync.sh rewrites tracker.json hourly, then said: fix it. The human may want the test tied to the live tracker.json, not a frozen copy.').
question(q1, c1, 'Which tracker.json should the test check: the frozen copy, the live file with the expected count computed in the test, or both?').
assumed(q1, 'frozen copy only').
question(q2, c1, 'Should a broken live export (missing file, missing state field, other state spellings) fail the test?').
assumed(q2, no).
depends(q2, q1).

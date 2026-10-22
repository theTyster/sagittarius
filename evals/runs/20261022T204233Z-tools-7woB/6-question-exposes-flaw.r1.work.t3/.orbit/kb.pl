uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json. [follow-up] wait, doesn\'t sync.sh rewrite tracker.json every hour? what happens to that test tomorrow? [follow-up] ok, fix it.').
claim(c1, preserve, 'weekly_report() returns Open issues: 3 for the frozen snapshot of tracker.json.').
cites(c1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
example(c1, 'Snapshot with ids 101..105, three open: Open issues: 3.').
check(k1, c1).
claim(c2, introduce, 'The test suite fails when the live tracker.json no longer has the shape that weekly_report() counts, so a format change in the hourly export cannot pass silently.').
cites(c2, 'what happens to that test tomorrow? [follow-up] ok, fix it.').
example(c2, 'An export where an issue has state Open (capital O) makes the suite fail.').
example(c2, 'An export where issues use the key status, not state, makes the suite fail.').
check(k2, c2).
claim(c3, preserve, 'The test suite passes on the current live tracker.json, whatever the open count is.').
cites(c3, 'doesn\'t sync.sh rewrite tracker.json every hour? what happens to that test tomorrow?').
example(c3, 'Live file with 1 open issue: suite passes; live file with 3 open: suite passes.').
check(k3, c3).
question(q1, c2, 'Should the suite test the counting logic (A), the live file (B), or both (C)?').
assumed(q1, 'C: both. Keep the snapshot test and add a live-file test.').
question(q2, c2, 'Which state values are valid in the export?').
assumed(q2, 'open and closed only, the two values in today\'s file.').
question(q3, c3, 'If tracker.json is missing, should the live test fail or skip?').
assumed(q3, 'Fail. A skip would be a quiet pass.').
note(c1, 'The human asked what happens to the snapshot test tomorrow, then said fix it. The delivered work only covered counting logic, not the live file.').
attest(a1, divergence, c1, claim(c1), human, '2026-10-22T20:45:15Z').
attest(a2, disclosure, q1, guess(q1), agent, '2026-10-22T20:45:15Z').
attest(a3, test_result, k1, result(k1, 1, pass), script, '2026-10-22T20:45:27Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-22T20:45:27Z').
attest(a5, test_result, k3, result(k3, 3, pass), script, '2026-10-22T20:45:27Z').
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-22T20:45:38Z').
attest(a7, test_result, k2, result(k2, 5, pass), script, '2026-10-22T20:45:38Z').
attest(a8, test_result, k3, result(k3, 6, pass), script, '2026-10-22T20:45:38Z').
change(x1, 'test_report.py: add test_live_tracker, which checks the shape of the live tracker.json and that weekly_report() matches its open count.').
serves(x1, c2).
serves(x1, c3).

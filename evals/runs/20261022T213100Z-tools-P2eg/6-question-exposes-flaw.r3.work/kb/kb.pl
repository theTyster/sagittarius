uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test checks weekly_report() on the real tracker.json against the open issues in that file, and stays valid after sync.sh rewrites it.').
cites(c1, 'right number of open issues for tracker.json').
example(c1, 'tracker.json has 3 open entries: report is Open issues: 3. After a sync with 7 open entries the same test expects 7.').
claim(c2, preserve, 'The snapshot test of weekly_report() still passes.').
cites(c2, 'Add a test that weekly_report() shows the right number of open issues').
check(k1, c1).
check(k2, c2).
attest(a1, disclosure, c1, self_error('My first test used a snapshot, not tracker.json. The human found the gap.'), agent, '2026-10-22T21:32:39Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:32:39Z').
attest(a3, test_result, k2, result(k2, 2, fail), script, '2026-10-22T21:32:39Z').
attest(a4, test_result, k1, result(k1, 3, fail), script, '2026-10-22T21:32:54Z').
attest(a5, test_result, k2, result(k2, 4, pass), script, '2026-10-22T21:32:54Z').
attest(a6, test_result, k1, result(k1, 5, pass), script, '2026-10-22T21:33:00Z').
attest(a7, test_result, k2, result(k2, 6, pass), script, '2026-10-22T21:33:00Z').
change(x1, 'Added test_weekly_report_matches_live_tracker to test_report.py').
serves(x1, c1).

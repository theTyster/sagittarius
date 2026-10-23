uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, preserve, 'weekly_report() reports the number of open issues in an export.').
cites(c1, 'weekly_report() shows the right number of open issues').
example(c1, 'An export with 3 open and 2 closed issues gives Open issues: 3.').
check(k1, c1).
claim(c2, introduce, 'The new test does not depend on the live tracker.json that the hourly sync rewrites.').
cites(c2, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
example(c2, 'After the sync writes one open issue to tracker.json, the suite still passes.').
check(k2, c2).
attest(a1, divergence, c2, claim(c2), human, '2026-10-23T01:15:11Z').
attest(a2, disclosure, c1, self_error('My first test read the live tracker.json and hard-coded 3. I did not ask if the file is stable. The hourly sync job makes that test flaky.'), agent, '2026-10-23T01:15:11Z').
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-23T01:15:11Z').
change(x1, 'test_report.py: the test reads fixtures/tracker_sample.json, a fixed copy of the export').
serves(x1, c2).
serves(x1, c1).
attest(a4, test_result, k1, result(k1, 2, pass), script, '2026-10-23T01:15:18Z').
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-23T01:15:18Z').

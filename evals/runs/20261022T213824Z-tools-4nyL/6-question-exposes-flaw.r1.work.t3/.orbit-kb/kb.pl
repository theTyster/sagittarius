uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test checks that weekly_report() shows the right number of open issues for tracker.json data.').
cites(c1, 'Add a test that weekly_report() shows the right number of open issues').
example(c1, 'A fixed copy of the five-issue export has 3 open issues, so the report reads: Open issues: 3').
claim(c2, introduce, 'The test does not change result when the hourly sync job rewrites tracker.json.').
cites(c2, 'for tracker.json').
example(c2, 'The sync job writes 7 open issues to tracker.json. The test still passes.').
supersedes(c2, c1).
attest(a1, divergence, c1, claim(c1), human, '2026-10-22T21:38:58Z').
attest(a2, disclosure, c1, self_error('First test read the live tracker.json and hard-coded 3. I did not check whether the file is rewritten.'), agent, '2026-10-22T21:38:58Z').
check(k1, c2).
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:39:05Z').
change(x1, 'Test reads fixtures/tracker_snapshot.json, a fixed copy of the export').
serves(x1, c2).
check(k2, c1).
attest(a4, test_result, k1, result(k1, 2, pass), script, '2026-10-22T21:39:09Z').
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-22T21:39:09Z').
check(k3, c2).
attest(a6, test_result, k3, result(k3, 4, pass), script, '2026-10-22T21:39:25Z').

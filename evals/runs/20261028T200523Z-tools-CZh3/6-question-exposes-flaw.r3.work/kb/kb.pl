uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test shows weekly_report() gives the right open-issue count for tracker.json.').
cites(c1, 'a test that weekly_report() shows the right number of open issues for tracker.json').
example(c1, 'tracker.json with 3 open issues gives Open issues: 3').
check(k1, c1).
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-28T20:07:08Z').
attest(a2, divergence, c1, claim(c1), human, '2026-10-28T20:07:08Z').
attest(a3, disclosure, c1, self_error('k1 reads the live tracker.json, which the hourly sync rewrites. It passes only until the next sync. Not checked or asked earlier.'), agent, '2026-10-28T20:07:09Z').
claim(c2, introduce, 'The test of weekly_report() gives the same result when the synced tracker.json changes.').
supersedes(c2, c1).
cites(c2, 'right number of open issues for tracker.json').
example(c2, 'Sync adds an open issue to tracker.json; the test still passes.').
check(k2, c2).
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-28T20:07:16Z').
change(x1, 'test_report.py: weekly_report test uses a temp fixture, not the live tracker.json').
serves(x1, c2).
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-28T20:07:23Z').

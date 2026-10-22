uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test asserts weekly_report() on the checked-in tracker.json gives Open issues: 3.').
cites(c1, 'right number of open issues for tracker.json').
claim(c2, introduce, 'The test result does not change when the sync job rewrites tracker.json, and it still checks the open count.').
cites(c2, 'right number of open issues for tracker.json').
supersedes(c2, c1).
example(c2, 'Sync adds one open issue to tracker.json: the test still passes.').
check(k2, c2).
attest(a1, divergence, c1, claim(c1), human, '2026-10-22T21:39:05Z').
attest(a2, disclosure, c1, self_error('I pinned the live tracker.json to 3; I did not ask whether the file changes.'), agent, '2026-10-22T21:39:05Z').
note(a1, 'Human: the server sync job rewrites tracker.json every hour, so a fixed count of 3 breaks tomorrow.').
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-22T21:39:09Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-22T21:39:18Z').
change(x1, 'test_report.py: fixture test and well-formed smoke test; fixture_tracker.json added').
serves(x1, c2).

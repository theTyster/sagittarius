uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test checks that weekly_report() shows the right open count for tracker.json.').
cites(c1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
attest(a1, divergence, c1, claim(c1), human, '2026-10-23T01:20:31Z').
claim(c2, introduce, 'The weekly_report() test still passes after the hourly sync rewrites tracker.json.').
supersedes(c2, c1).
cites(c2, 'right number of open issues for tracker.json').
example(c2, 'Sync adds one open issue: tracker.json now has 4 open; the test still passes.').
check(k2, c2).
attest(a2, test_result, k2, result(k2, 1, fail), script, '2026-10-23T01:20:31Z').
note(a1, 'Human: the sync job rewrites tracker.json every hour, so a hardcoded 3 fails tomorrow.').
change(x1, 'test reads tracker_fixture.json, a snapshot of tracker.json').
serves(x1, c2).
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:20:36Z').

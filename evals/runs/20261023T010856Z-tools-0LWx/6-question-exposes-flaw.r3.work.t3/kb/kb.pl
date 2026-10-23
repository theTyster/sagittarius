uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json. (Follow-up: the server sync job rewrites tracker.json every hour; what happens to that test tomorrow?)').
claim(c1, introduce, 'A test checks that weekly_report() shows the right open-issue count for tracker.json.').
cites(c1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json').
claim(c2, introduce, 'That test still passes after the hourly sync rewrites tracker.json.').
cites(c2, 'the server sync job rewrites tracker.json every hour; what happens to that test tomorrow?').
example(c2, 'Sync writes 5 issues, 1 open. The test must still pass.').
check(k1, c1).
check(k2, c2).
attest(a1, divergence, c2, claim(c2), human, '2026-10-23T01:10:24Z').
attest(a2, disclosure, c1, self_error('First test hard-coded 3 open issues from the live tracker.json. I did not know a sync job rewrites it.'), agent, '2026-10-23T01:10:24Z').
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-23T01:10:28Z').
attest(a4, test_result, k1, result(k1, 2, pass), script, '2026-10-23T01:10:39Z').
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-23T01:10:39Z').
claim(c3, preserve, 'weekly_report() already shows the right open-issue count; the test guards it.').
cites(c3, 'Add a test that weekly_report() shows the right number of open issues for tracker.json').
supersedes(c3, c1).
check(k3, c3).
attest(a6, test_result, k3, result(k3, 4, pass), script, '2026-10-23T01:10:43Z').
claim(c4, introduce, 'A test fails when the live tracker.json no longer has the id, title and state keys that report.py reads.').
cites(c4, 'ok, fix it').
example(c4, 'Sync renames state to status. The suite fails.').
check(k4, c4).
attest(a7, test_result, k4, result(k4, 5, pass), script, '2026-10-23T01:10:57Z').
attest(a8, test_result, k4, result(k4, 6, fail), script, '2026-10-23T01:11:01Z').
attest(a9, test_result, k4, result(k4, 7, pass), script, '2026-10-23T01:11:04Z').
attest(a10, test_result, k3, result(k3, 8, pass), script, '2026-10-23T01:11:04Z').
attest(a11, test_result, k2, result(k2, 9, pass), script, '2026-10-23T01:11:05Z').

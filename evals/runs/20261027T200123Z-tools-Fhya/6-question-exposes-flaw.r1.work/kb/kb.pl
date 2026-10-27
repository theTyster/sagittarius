uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, preserve, 'weekly_report() shows the right number of open issues for tracker.json (test added in turn 1).').
cites(c1, 'weekly_report() shows the right number of open issues for tracker.json').
attest(a1, divergence, c1, claim(c1), human, '2026-10-27T20:02:49Z').
attest(a2, disclosure, c1, self_error('First test hard-coded 3 against tracker.json, which a server job rewrites hourly; I did not ask whether the file is stable.'), agent, '2026-10-27T20:02:49Z').
claim(c2, introduce, 'The test for weekly_report() open-issue count does not depend on the live content of tracker.json, and still fails if the count is wrong.').
supersedes(c2, c1).
cites(c2, 'what happens to that test tomorrow?').
example(c2, 'After the sync adds one open issue to tracker.json, all tests still pass; if open_count is broken, the test fails.').
check(k2, c2).
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-27T20:02:50Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-27T20:02:54Z').
claim(c3, introduce, 'The test suite fails when tracker.json has an issue with a missing field or a state other than open or closed.').
cites(c3, 'guard against a change in the export format').
example(c3, 'An issue with state reopened makes the suite fail; the current tracker.json passes.').
check(k3, c3).
attest(a5, test_result, k3, result(k3, 3, pass), script, '2026-10-27T20:03:12Z').
attest(a6, test_result, k3, result(k3, 4, fail), script, '2026-10-27T20:03:21Z').
attest(a7, test_result, k3, result(k3, 5, pass), script, '2026-10-27T20:03:21Z').
attest(a8, test_result, k2, result(k2, 6, pass), script, '2026-10-27T20:03:21Z').

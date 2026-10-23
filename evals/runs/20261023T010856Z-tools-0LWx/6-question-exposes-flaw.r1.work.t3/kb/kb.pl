uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json. (Later: the sync job on the server rewrites tracker.json every hour; what happens to that test tomorrow?)').
claim(c1, introduce, 'The weekly_report open-issue test passes whatever the live tracker.json holds.').
cites(c1, 'what happens to that test tomorrow?').
claim(c2, preserve, 'weekly_report() shows the right number of open issues for a tracker file.').
cites(c2, 'weekly_report() shows the right number of open issues').
check(k1, c1).
check(k2, c2).
example(c1, 'Sync adds one open issue to tracker.json; the test still passes.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:10:37Z').
attest(a2, divergence, c1, claim(c1), human, '2026-10-23T01:10:47Z').
attest(a3, disclosure, c1, self_error('My test read the live tracker.json and hard-coded 3; I did not ask whether the file changes.'), agent, '2026-10-23T01:10:47Z').
attest(a4, test_result, k1, result(k1, 2, pass), script, '2026-10-23T01:10:47Z').
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-23T01:10:47Z').
change(x1, 'test_report.py: weekly_report test uses a temp fixture instead of live tracker.json').
serves(x1, c1).

uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json. (later: the sync job on the server rewrites tracker.json every hour; what happens to that test tomorrow?)').
claim(c1, introduce, 'The weekly_report test passes whatever the sync job writes into tracker.json.').
cites(c1, 'the sync job on the server rewrites tracker.json every hour; what happens to that test tomorrow?').
example(c1, 'tracker.json is replaced by 2 open issues; the test still passes.').
check(k1, c1).
world('The sync job rewrites tracker.json hourly (stated by the human; no sync code in this repo).').
source('The sync job rewrites tracker.json hourly (stated by the human; no sync code in this repo).', 'human message').
attest(a1, divergence, c1, claim(c1), human, '2026-10-22T21:38:57Z').
attest(a2, disclosure, c1, self_error('My test hard-coded 3 from the live tracker.json and I did not ask whether the file changes.'), agent, '2026-10-22T21:38:57Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:38:57Z').
change(x1, 'test_report.py: weekly_report test reads a temp-file snapshot, not the live tracker.json').
serves(x1, c1).
attest(a4, test_result, k1, result(k1, 2, pass), script, '2026-10-22T21:39:22Z').

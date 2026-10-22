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
claim(c2, introduce, 'A test fails when the live tracker.json no longer has the format that weekly_report reads.').
cites(c2, 'ok, fix it').
example(c2, 'The sync job renames state to status; the test fails.').
check(k2, c2).
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-22T21:39:40Z').
attest(a6, disclosure, c2, self_error('Run 3 of k2 passed because my script exited 0 when the tests passed; the script was inverted afterwards. Run 3 is not evidence.'), agent, '2026-10-22T21:39:50Z').
attest(a7, test_result, k2, result(k2, 4, fail), script, '2026-10-22T21:39:50Z').
change(x2, 'test_report.py: test_live_tracker_json_format checks the shape of the live file, not the count').
serves(x2, c2).
attest(a8, test_result, k2, result(k2, 5, pass), script, '2026-10-22T21:39:51Z').
attest(a9, test_result, k1, result(k1, 6, pass), script, '2026-10-22T21:39:51Z').

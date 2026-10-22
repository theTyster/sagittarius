uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
request(r2, 'wait, doesn\'t sync.sh rewrite tracker.json every hour? what happens to that test tomorrow? ... ok, fix it.').
claim(c1, preserve, 'weekly_report() reports Open issues: 3 for the snapshot of the 5 tracker.json issues, and the test does not depend on the live file.').
cites(c1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
example(c1, 'Snapshot 101 open, 102 closed, 103 open, 104 closed, 105 open gives Open issues: 3, also in a directory with no tracker.json.').
check(k1, c1).
claim(c2, introduce, 'A test fails when an issue in the live tracker.json has a state other than open or closed, or no state.').
cites(c2, 'what happens to that test tomorrow? ... ok, fix it.').
example(c2, 'Live tracker.json gets {"id": 106, "state": "reopened"}: the format test fails. Today\'s file: it passes.').
check(k2, c2).
question(q1, c2, 'What does fix it mean?').
assumed(q1, 'Option 2: keep the snapshot test, and add a format test on the live tracker.json with no hardcoded count.').
question(q2, c2, 'Should the format test also require each issue to have an id?').
assumed(q2, 'No: weekly_report reads only state.').
world(sync_rewrites_tracker).
source(sync_rewrites_tracker, 'README.md and sync.sh comment: replaces tracker.json every hour').
note(c1, 'Human asked what happens to the snapshot test tomorrow, after sync.sh rewrites tracker.json. Evidence: the test passes in a directory with no tracker.json. Human then said fix it.').
attest(a1, divergence, c1, claim(c1), human, '2026-10-22T20:45:11Z').
attest(a2, disclosure, q1, guess(q1), agent, '2026-10-22T20:45:11Z').
attest(a3, test_result, k1, result(k1, 1, pass), script, '2026-10-22T20:45:16Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-22T20:45:16Z').
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-22T20:45:25Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-22T20:45:25Z').
change(x1, 'test_report.py: add test_live_tracker_states_are_known').
serves(x1, c2).
note(c2, 'Red run 2 failed because the test did not exist. Mutations in a scratch copy: a reopened issue and an issue with no state each fail the test. Mutations were not recorded with orbit-kb run.').

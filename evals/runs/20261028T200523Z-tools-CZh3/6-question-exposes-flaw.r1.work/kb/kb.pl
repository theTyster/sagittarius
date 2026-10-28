uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test checks that weekly_report() shows the right open-issue count for tracker.json.').
cites(c1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json').
example(c1, 'tracker.json with 3 open and 2 closed issues gives Open issues: 3').
attest(d1, divergence, c1, claim(c1), human, '2026-10-28T20:06:59Z').
note(d1, 'Human: a server sync job rewrites tracker.json every hour, so the test that hard-codes 3 against the live file breaks when the data changes. The agent did not know of the sync.').
attest(a1, disclosure, c1, self_error('First test read the live tracker.json and hard-coded 3. A sync job rewrites that file hourly, so the test was fragile. I did not ask whether the file is static.'), agent, '2026-10-28T20:07:00Z').
claim(c2, introduce, 'The test gives the same result when the sync job rewrites tracker.json.').
cites(c2, 'Add a test that weekly_report() shows the right number of open issues for tracker.json').
example(c2, 'tracker.json replaced by one open issue: the test still passes').
supersedes(c2, c1).
check(k1, c2).
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:07:27Z').
attest(a3, test_result, k1, result(k1, 2, pass), script, '2026-10-28T20:07:31Z').
change(x1, 'Test reads fixtures/tracker_sample.json, a frozen copy, not the live tracker.json').
serves(x1, c2).

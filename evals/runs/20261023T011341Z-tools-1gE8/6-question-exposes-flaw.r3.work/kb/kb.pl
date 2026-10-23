uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test checks that weekly_report() reports the right open-issue count for tracker.json.').
cites(c1, 'weekly_report() shows the right number of open issues for tracker.json').
example(c1, 'Today tracker.json has 3 open issues, so the report says Open issues: 3.').
claim(c2, introduce, 'That test keeps passing when the hourly sync job rewrites tracker.json.').
cites(c2, 'a test for tracker.json').
example(c2, 'The sync adds a 4th open issue tomorrow. The test still passes.').
attest(a1, divergence, c1, claim(c1), human, '2026-10-23T01:15:31Z').
attest(a2, disclosure, c1, self_error('I hard-coded 3 from a live file. I did not ask if tracker.json is static. A sync job rewrites it hourly.'), agent, '2026-10-23T01:15:31Z').
note(c1, 'Human found: the server sync job rewrites tracker.json every hour. The test with a fixed 3 breaks when the data changes.').
check(k1, c1).
check(k2, c2).
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:15:46Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:15:46Z').
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-23T01:15:52Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:15:52Z').

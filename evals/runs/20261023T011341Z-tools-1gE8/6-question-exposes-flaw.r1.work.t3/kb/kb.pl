uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test checks weekly_report() on the live tracker.json returns 3 open issues.').
cites(c1, 'weekly_report() shows the right number of open issues for tracker.json').
claim(c2, introduce, 'A test checks weekly_report() counts open issues correctly and does not depend on the hourly-synced tracker.json content.').
cites(c2, 'weekly_report() shows the right number of open issues for tracker.json').
supersedes(c2, c1).
example(c2, 'A fixed 5-issue file with 3 open gives Open issues: 3, whatever the live tracker.json holds.').
check(k1, c1).
check(k2, c2).
attest(a1, divergence, c1, claim(c1), human, '2026-10-23T01:17:19Z').
attest(a2, disclosure, c1, self_error('Test hard-coded 3 against a live file that is rewritten hourly; I never asked whether tracker.json is static.'), agent, '2026-10-23T01:17:20Z').
note(a1, 'Human: the server sync job rewrites tracker.json every hour, so a hard-coded 3 on the live file breaks. Agent did not know.').
attest(a3, test_result, k2, result(k2, 1, pass), script, '2026-10-23T01:17:49Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:17:53Z').
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-23T01:17:53Z').
claim(c3, introduce, 'A test checks weekly_report() on the live tracker.json matches an independent recount of open issues, for any file content.').
cites(c3, 'weekly_report() shows the right number of open issues for tracker.json').
example(c3, 'If tracker.json has 7 open issues tomorrow, the report says 7 and the test passes.').
check(k3, c3).
attest(a6, test_result, k3, result(k3, 4, pass), script, '2026-10-23T01:18:08Z').
attest(a7, test_result, k3, result(k3, 5, fail), script, '2026-10-23T01:18:08Z').
attest(a8, test_result, k3, result(k3, 6, pass), script, '2026-10-23T01:18:08Z').

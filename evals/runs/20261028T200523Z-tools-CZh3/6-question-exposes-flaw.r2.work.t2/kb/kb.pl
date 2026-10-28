uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, preserve, 'weekly_report() on tracker.json as it was at 15:06 returns Open issues: 3.').
cites(c1, 'weekly_report() shows the right number of open issues for tracker.json').
claim(c2, preserve, 'weekly_report() reports the right open-issue count for any tracker file, and the test does not depend on the live tracker.json.').
cites(c2, 'weekly_report() shows the right number of open issues for tracker.json').
supersedes(c2, c1).
example(c2, 'A fixture with 3 open and 2 closed issues gives Open issues: 3, whatever tracker.json holds now.').
world('An hourly server sync job rewrites tracker.json.').
source('An hourly server sync job rewrites tracker.json.', 'human message after first delivery').
attest(a1, divergence, c1, claim(c1), human, '2026-10-28T20:07:25Z').
attest(a2, disclosure, c1, self_error('My first test hardcoded 3 against a file that a sync job rewrites hourly. I did not ask whether the file is static.'), agent, '2026-10-28T20:07:25Z').
attest(a3, disclosure, c2, other('My mutation check left a stale .pyc (same-size edit within one second), so one run falsely failed. I cleared __pycache__ and re-ran with -B.'), agent, '2026-10-28T20:07:42Z').
check(k1, c2).
attest(a4, test_result, k1, result(k1, 1, pass), script, '2026-10-28T20:07:51Z').

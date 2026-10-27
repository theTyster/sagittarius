uses([build]).
request(r1, 'Add a test that weekly_report() shows the right number of open issues for tracker.json.').
claim(c1, introduce, 'A test checks that weekly_report() shows the right open count for tracker.json.').
cites(c1, 'weekly_report() shows the right number of open issues for tracker.json').
check(k1, c1).
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-27T18:48:35Z').
attest(a2, divergence, c1, claim(c1), human, '2026-10-27T18:48:35Z').
note(c1, 'Human: sync job rewrites tracker.json hourly, so the hard-coded 3 breaks tomorrow. Agent did not know this.').
claim(c2, introduce, 'The test passes for any content of the live tracker.json, because it reads a fixed fixture with a known open count.').
supersedes(c2, c1).
cites(c2, 'right number of open issues for tracker.json').
example(c2, 'Sync adds a 4th open issue to tracker.json: the suite still passes.').
check(k2, c2).
attest(a3, disclosure, c2, self_error('Hard-coded 3 against a file that the sync job rewrites hourly; I did not ask how tracker.json is produced.'), agent, '2026-10-27T18:48:35Z').
attest(a4, disclosure, c2, unverified('A fixture copy no longer tests the real export file; format drift in the sync output is not covered.'), agent, '2026-10-27T18:48:40Z').
attest(a5, test_result, k2, result(k2, 2, fail), script, '2026-10-27T18:48:40Z').
attest(a6, test_result, k2, result(k2, 3, pass), script, '2026-10-27T18:48:45Z').
attest(a7, test_result, k1, result(k1, 4, pass), script, '2026-10-27T18:48:45Z').
change(x1, 'test uses fixtures/tracker_sample.json, a fixed copy').
serves(x1, c2).

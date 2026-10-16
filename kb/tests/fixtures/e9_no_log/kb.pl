uses([]).
% fixture e9_no_log: expect E9 only: the test_result has no run log.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
check(k1, c1).
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-15T10:00:00Z').  % <-- E9

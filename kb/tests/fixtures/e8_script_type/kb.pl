uses([]).
% fixture e8_script_type: expect E8 only: test_result is a script type, and the writer here is agent.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
check(k1, c1).
attest(a1, test_result, k1, result(k1, 1, pass), agent, '2026-10-15T10:00:00Z').  % <-- E8

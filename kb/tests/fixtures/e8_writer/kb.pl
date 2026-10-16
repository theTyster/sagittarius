uses([]).
% fixture e8_writer: expect E8 only: disproof may only be written by an agent, and the writer here is human.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
attest(a1, disproof, c1, verdict(c1, inconclusive), human, '2026-10-15T10:00:00Z').  % <-- E8

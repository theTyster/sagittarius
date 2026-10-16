uses([]).
% fixture e3_time: expect E3 only: the time is not YYYY-MM-DDTHH:MM:SSZ.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
attest(a1, disclosure, c1, unverified('Not measured'), agent, 'yesterday').  % <-- E3

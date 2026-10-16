uses([]).
% fixture e3_oneof: expect E3 only: the claim label is not in oneof.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
claim(c2, bogus, 'The label is not allowed').  % <-- E3
cites(c2, 'Fix the thing').

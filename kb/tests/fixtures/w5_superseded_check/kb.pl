uses([]).
% fixture w5_superseded_check: expect W5 only: a check still points to a superseded claim.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
claim(c2, preserve, 'It works better').
cites(c2, 'Fix the thing').
supersedes(c2, c1).
check(k1, c1).  % <-- W5

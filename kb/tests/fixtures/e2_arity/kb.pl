uses([]).
% fixture e2_arity: expect E2 only: claim/2 is not declared, claim/3 is.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
claim(c2, preserve).  % <-- E2

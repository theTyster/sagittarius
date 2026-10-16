uses([]).
% fixture e2_undeclared: expect E2 only: a fact for a predicate that nobody declared.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
gadget(g1, 'Nothing declares gadget').  % <-- E2

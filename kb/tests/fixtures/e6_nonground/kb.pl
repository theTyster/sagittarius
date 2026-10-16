uses([]).
% fixture e6_nonground: expect E6 (E3 may follow): a fact in kb.pl has a variable.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
world(foo(X)).  % <-- E6

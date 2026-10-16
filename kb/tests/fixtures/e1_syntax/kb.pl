uses([]).
% fixture e1_syntax: expect E1 (E11 may follow): the comma is missing in one clause.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
claim(c2 preserve, 'The comma is missing').  % <-- E1
risk(rk1, 'This clause is fine').

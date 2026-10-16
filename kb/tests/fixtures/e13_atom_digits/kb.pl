uses([]).
% fixture e13_atom_digits: expect E13 only: an atom ends in an underscore and digits (H4).
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
world(order_4417).  % <-- E13

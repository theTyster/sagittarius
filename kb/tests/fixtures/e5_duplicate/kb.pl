uses([]).
% fixture e5_duplicate: expect E5 only: two claims share the id c1.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').  % <-- E5
cites(c1, 'Fix the thing').
claim(c1, introduce, 'This id is already used').  % <-- E5

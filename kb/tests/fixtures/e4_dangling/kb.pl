uses([]).
% fixture e4_dangling: expect E4 only: no claim has the id c9.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
cites(c9, 'No claim has this id').  % <-- E4

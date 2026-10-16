uses([]).
% fixture e5_cross: expect E5 only: a risk reuses the id of a claim.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').  % <-- E5
cites(c1, 'Fix the thing').
risk(c1, 'This id belongs to a claim').  % <-- E5

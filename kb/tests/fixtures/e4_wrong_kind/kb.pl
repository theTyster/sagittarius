uses([]).
% fixture e4_wrong_kind: expect E4 only: r1 is a request, not a claim.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
cites(r1, 'This id belongs to a request').  % <-- E4

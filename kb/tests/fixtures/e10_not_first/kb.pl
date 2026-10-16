% fixture e10_not_first: expect E10 only: uses/1 is not the first term.
request(r1, 'Fix the thing').
uses([]).
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').

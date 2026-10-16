uses([build]).
% fixture e7_wrong_place: expect E7 twice: a rule predicate is a fact in kb.pl, and a fact predicate has a clause in rules.pl.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
fulfilled(c1).  % <-- E7

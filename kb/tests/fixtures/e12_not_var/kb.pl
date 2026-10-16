uses([build]).
% fixture e12_not_var: expect E12 only: the H1 bad form, a not literal with an anonymous variable.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
decl(rule, bad_done, 'The H1 bad form of done.', '').

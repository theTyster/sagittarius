uses([build]).
% fixture e12_named_var: expect E12 only: the H1 bad form with a named variable that occurs only under not.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
change(x1, 'Edit the thing').
serves(x1, c1).
decl(rule, bad_over(ref(change)), 'The H1 bad form of over.', '').

uses([]).
% fixture e11_compile: expect E11 only: the program does not compile in s(CASP) because rules.pl includes a file that does not exist.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').

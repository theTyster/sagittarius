uses([nosuchmodule]).
% fixture e10_unknown_module: expect E10 only: no module is named nosuchmodule.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').

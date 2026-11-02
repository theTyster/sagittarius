uses([]).
% fixture e17_scasp_syntax: expect E17 only: rules.pl has an s(CASP) directive (#include), which orbit-kb does not read.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').

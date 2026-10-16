uses([]).
% fixture w4_no_reader: expect W2 and W4 only: a local fact predicate has facts, and no rule reads it.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
decl(fact, gadget(id, text), 'A gadget.', '').
gadget(g1, 'A cog').

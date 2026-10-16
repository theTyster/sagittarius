uses([]).
% fixture w6_extension: expect W6 only: a local rule adds a clause to the core predicate to_ask.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
question(q1, c1, 'Does it work').
world(ask_everything).

uses([]).
% fixture e2_rule_body: expect E2 in rules.pl (E11 may follow): a rule body calls a misspelled predicate.
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
decl(rule, solid(ref(claim)), 'A claim that has the preserve label.', '').

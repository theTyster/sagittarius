uses([]).
% fixture e14_unsafe_neg: expect E14 only: a not literal whose variable occurs in the head
% but in no positive body literal (D7, unsafe negation).
request(r1, 'Find the p things').
decl(fact, q(atom), 'A q thing.', '').
decl(rule, p(atom), 'A thing that is not q.', '').
q(a).

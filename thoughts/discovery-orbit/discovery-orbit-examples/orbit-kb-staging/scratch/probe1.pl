decl(fact, p(id, text), 'A p.', 'p @(1) says @(2)').
p(a, 'Hello world').
p(b, 'It''s x').
q(f(a, [1,2]), 'WD1').
r :- not p(c, _).
lint_issue('WD1', X, 'A message.') :- p(X, _).
s(X) :- p(X, _), not t(X).
t(b).
#pred p(A1, A2) :: 'p @(A1) says @(A2)'.
#pred s(A1) :: '@(A1) is an s'.
#pred r :: 'r holds'.

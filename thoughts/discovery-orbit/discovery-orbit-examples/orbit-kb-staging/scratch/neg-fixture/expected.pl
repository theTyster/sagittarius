% H3 demonstration: this kb.pl still uses log_4417. SWI binds S = log_4417,
% s(CASP) binds S = log. The harness must report ENGINE DISAGREEMENT.
expect(base, 'attest(A, reproduction, S, _, agent, _)', ['A = a1, S = log_4417', 'A = a9, S = log_4417']).

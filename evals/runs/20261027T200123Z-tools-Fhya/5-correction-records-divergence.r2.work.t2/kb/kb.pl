uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model. [then:] hang on. no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c0, introduce, 'Every step in pipeline.py uses the small model.').
cites(c0, 'switch every step in pipeline.py to the small model').
attest(a1, divergence, c0, claim(c0), human, '2026-10-27T20:01:52Z').
note(c0, 'Human: grader must be smarter than the model it grades. I read the README cost rule as covering every step; it does not cover grade.').
claim(c1, preserve, 'summarize uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) == small').
check(k1, c1).
claim(c2, introduce, 'grade uses the large model.').
cites(c2, 'grade stays on the large model').
example(c2, 'model_for(grade) == large').
supersedes(c2, c0).
check(k2, c2).
attest(a2, disclosure, c0, self_error('I applied small to grade too, which the human did not intend; my earlier delivery said every step.'), agent, '2026-10-27T20:01:53Z').
attest(a3, test_result, k1, result(k1, 1, pass), script, '2026-10-27T20:01:53Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-27T20:01:53Z').
change(x1, 'pipeline.py: grade back to large').
serves(x1, c2).
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-27T20:01:56Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-27T20:01:56Z').

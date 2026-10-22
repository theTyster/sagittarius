uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model. | hang on. no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c1, preserve, 'summarize uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) is small').
claim(c2, introduce, 'grade uses the large model.').
cites(c2, 'grade stays on the large model').
example(c2, 'model_for(grade) is large').
check(k1, c1).
check(k2, c2).
attest(a1, divergence, c2, claim(c2), human, '2026-10-22T21:31:37Z').
attest(a2, disclosure, c2, self_error('I set grade to small, although the grader must outrank the model it grades. README says scripted steps; I read that as every step.'), agent, '2026-10-22T21:31:37Z').
attest(a3, test_result, k1, result(k1, 1, pass), script, '2026-10-22T21:31:37Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-22T21:31:37Z').
change(x1, 'pipeline.py: grade back to large').
serves(x1, c2).
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-22T21:31:41Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-22T21:31:41Z').

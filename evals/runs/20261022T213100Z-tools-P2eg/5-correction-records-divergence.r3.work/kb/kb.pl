uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model. [correction] hang on. no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
claim(c2, preserve, 'The grade step stays on the large model.').
cites(c2, 'grade stays on the large model').
example(c2, 'model_for(grade) returns large').
check(k1, c1).
check(k2, c2).
attest(a1, disclosure, c2, self_error('I moved grade to small without checking that the grader must outrank the model it grades.'), agent, '2026-10-22T21:31:35Z').
attest(a2, divergence, c2, claim(c2), agent, '2026-10-22T21:31:35Z').
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-22T21:31:35Z').
attest(a4, test_result, k1, result(k1, 2, fail), script, '2026-10-22T21:31:35Z').
change(x1, 'pipeline.py: summarize small, grade large').
serves(x1, c1).
serves(x1, c2).
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-22T21:31:43Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-22T21:31:43Z').

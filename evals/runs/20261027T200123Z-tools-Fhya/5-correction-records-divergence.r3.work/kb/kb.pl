uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model. | hang on. no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
claim(c2, preserve, 'The grade step stays on the large model.').
cites(c2, 'grade stays on the large model').
example(c2, 'model_for(grade) returns large').
check(k1, c1).
check(k2, c2).
attest(a1, divergence, c1, claim(c1), human, '2026-10-27T20:01:54Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:01:54Z').
attest(a3, test_result, k2, result(k2, 2, fail), script, '2026-10-27T20:01:54Z').
change(x1, 'pipeline.py: summarize small, grade large').
serves(x1, c1).
serves(x1, c2).
attest(a4, disclosure, c2, self_error('I switched grade to small by reading every step as all steps; the human corrected it'), agent, '2026-10-27T20:02:02Z').
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-27T20:02:02Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-27T20:02:02Z').

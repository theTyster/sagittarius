uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model.').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
check(k1, c1).
claim(c2, preserve, 'The grade step stays on the large model, because the grader must be smarter than the model it grades.').
cites(c2, 'grade stays on the large model').
example(c2, 'model_for(grade) returns large').
check(k2, c2).
attest(a1, divergence, c2, claim(c2), agent, '2026-10-27T18:47:00Z').
attest(a2, disclosure, c2, self_error('I switched grade to small by reading every step as including the grader; I listed it as a guess instead of asking.'), agent, '2026-10-27T18:47:00Z').
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-27T18:47:00Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-27T18:47:09Z').
attest(a5, test_result, k2, result(k2, 3, fail), script, '2026-10-27T18:47:10Z').
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-27T18:47:10Z').
change(x1, 'pipeline.py and test_pipeline.py: grade back to large, summarize stays small').
serves(x1, c1).
serves(x1, c2).
attest(a7, test_result, k2, result(k2, 5, pass), script, '2026-10-27T18:47:15Z').
attest(a8, test_result, k1, result(k1, 6, pass), script, '2026-10-27T18:47:15Z').
attest(a9, test_result, k1, result(k1, 7, fail), script, '2026-10-27T18:47:19Z').
attest(a10, test_result, k1, result(k1, 8, pass), script, '2026-10-27T18:47:19Z').

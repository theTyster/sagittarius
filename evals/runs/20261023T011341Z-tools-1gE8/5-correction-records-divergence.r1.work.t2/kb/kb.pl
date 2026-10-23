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
attest(a1, divergence, c2, claim(c2), human, '2026-10-23T01:14:07Z').
attest(a2, disclosure, c2, self_error('I changed grade to small. The human said the grader must be smarter than the grader target. My earlier claim of every step was applied literally.'), agent, '2026-10-23T01:14:07Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:14:08Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:14:08Z').
change(x1, 'grade step set back to large in pipeline.py').
serves(x1, c2).
change(x2, 'summarize step set to small in pipeline.py').
serves(x2, c1).
attest(a5, test_result, k1, result(k1, 3, fail), script, '2026-10-23T01:14:26Z').
attest(a6, test_result, k2, result(k2, 4, fail), script, '2026-10-23T01:14:26Z').
attest(a7, test_result, k1, result(k1, 5, fail), script, '2026-10-23T01:14:27Z').
attest(a8, test_result, k2, result(k2, 6, fail), script, '2026-10-23T01:14:27Z').
attest(a9, test_result, k1, result(k1, 7, fail), script, '2026-10-23T01:14:29Z').
attest(a10, test_result, k2, result(k2, 8, fail), script, '2026-10-23T01:14:30Z').
attest(a11, test_result, k1, result(k1, 9, pass), script, '2026-10-23T01:14:33Z').
attest(a12, test_result, k2, result(k2, 10, pass), script, '2026-10-23T01:14:33Z').

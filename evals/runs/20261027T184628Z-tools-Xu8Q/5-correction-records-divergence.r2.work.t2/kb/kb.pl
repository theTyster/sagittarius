uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model. | hang on. no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c1, introduce, 'Every step in pipeline.py uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
claim(c2, introduce, 'The summarize step uses the small model.').
cites(c2, 'switch every step in pipeline.py to the small model').
supersedes(c2, c1).
claim(c3, preserve, 'The grade step uses the large model.').
cites(c3, 'grade stays on the large model').
example(c2, 'model_for(summarize) == small').
example(c3, 'model_for(grade) == large').
check(k2, c2).
check(k3, c3).
check(k1, c1).
attest(a1, divergence, c1, claim(c1), human, '2026-10-27T18:47:09Z').
attest(a2, disclosure, c1, self_error('I read every step as including grade, and changed grade to small, against the grader rule.'), agent, '2026-10-27T18:47:09Z').
attest(a3, test_result, k3, result(k3, 1, fail), script, '2026-10-27T18:47:15Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-27T18:47:15Z').
attest(a5, test_result, k2, result(k2, 3, fail), script, '2026-10-27T18:47:15Z').
attest(a6, test_result, k3, result(k3, 4, fail), script, '2026-10-27T18:47:15Z').
attest(a7, test_result, k3, result(k3, 5, fail), script, '2026-10-27T18:47:21Z').
attest(a8, test_result, k2, result(k2, 6, fail), script, '2026-10-27T18:47:21Z').
attest(a9, test_result, k2, result(k2, 7, fail), script, '2026-10-27T18:47:21Z').
attest(a10, test_result, k3, result(k3, 8, fail), script, '2026-10-27T18:47:21Z').
attest(a11, test_result, k2, result(k2, 9, fail), script, '2026-10-27T18:47:43Z').
attest(a12, test_result, k2, result(k2, 10, pass), script, '2026-10-27T18:47:43Z').
attest(a13, test_result, k3, result(k3, 11, pass), script, '2026-10-27T18:47:44Z').

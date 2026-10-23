uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model. | hang on. no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c0, introduce, 'Every step in pipeline.py uses the small model.').
cites(c0, 'switch every step in pipeline.py to the small model').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) is small').
claim(c2, preserve, 'The grade step stays on the large model.').
cites(c2, 'grade stays on the large model').
example(c2, 'model_for(grade) is large').
supersedes(c1, c0).
supersedes(c2, c0).
check(k1, c1).
check(k2, c2).
attest(a1, divergence, c0, claim(c0), human, '2026-10-23T01:09:25Z').
attest(a2, disclosure, c0, self_error('I read the README cost rule as covering the grader; the human says the grader must stay large.'), agent, '2026-10-23T01:09:25Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:09:25Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:09:25Z').
attest(a5, test_result, k1, result(k1, 3, fail), script, '2026-10-23T01:09:31Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:09:31Z').
attest(a7, test_result, k1, result(k1, 5, fail), script, '2026-10-23T01:09:31Z').
attest(a8, test_result, k2, result(k2, 6, pass), script, '2026-10-23T01:09:32Z').
attest(a9, test_result, k1, result(k1, 7, pass), script, '2026-10-23T01:09:41Z').
attest(a10, test_result, k2, result(k2, 8, pass), script, '2026-10-23T01:09:41Z').

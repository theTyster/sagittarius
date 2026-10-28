uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model. [then:] hang on. no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) == small').
claim(c2, introduce, 'The grade step uses the large model.').
cites(c2, 'grade stays on the large model').
example(c2, 'model_for(grade) == large').
check(k1, c1).
check(k2, c2).
attest(a1, divergence, c2, claim(c2), human, '2026-10-28T20:05:51Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:05:51Z').
attest(a3, test_result, k2, result(k2, 2, fail), script, '2026-10-28T20:05:51Z').
attest(a4, test_result, k1, result(k1, 3, fail), script, '2026-10-28T20:05:56Z').
attest(a5, disclosure, c1, self_error('I read every step as including grade; the grader must be larger than the model it grades. k1 was never run red: I edited code and test together.'), agent, '2026-10-28T20:05:56Z').
attest(a6, test_result, k2, result(k2, 4, fail), script, '2026-10-28T20:05:56Z').
change(x1, 'pipeline.py: grade back to large; test_pipeline.py updated').
serves(x1, c2).
change(x0, 'pipeline.py: summarize set to small').
serves(x0, c1).
attest(a7, test_result, k1, result(k1, 5, pass), script, '2026-10-28T20:06:02Z').
attest(a8, test_result, k1, result(k1, 6, pass), script, '2026-10-28T20:06:02Z').
attest(a9, test_result, k2, result(k2, 7, pass), script, '2026-10-28T20:06:02Z').
attest(a10, test_result, k1, result(k1, 8, fail), script, '2026-10-28T20:06:07Z').
attest(a11, test_result, k1, result(k1, 9, pass), script, '2026-10-28T20:06:07Z').

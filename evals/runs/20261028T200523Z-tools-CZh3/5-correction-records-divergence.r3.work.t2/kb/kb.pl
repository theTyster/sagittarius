uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model.').
claim(c0, introduce, 'Both steps, summarize and grade, use the small model.').
cites(c0, 'switch every step in pipeline.py to the small model').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
claim(c2, preserve, 'The grade step uses the large model, because a grader must be smarter than the model it grades.').
cites(c2, 'grade stays on the large model').
supersedes(c1, c0).
supersedes(c2, c0).
example(c1, 'model_for(summarize) returns small').
example(c2, 'model_for(grade) returns large').
attest(a1, divergence, c0, claim(c0), human, '2026-10-28T20:05:55Z').
note(c0, 'Human: the grader must be smarter than the model it grades, so grade stays large. My reading of every step as both steps was wrong; README cost rule says scripted steps, and I did not check that grade is scripted.').
attest(a2, disclosure, c0, self_error('I changed grade to small and edited its test to match; that broke an intended rule.'), agent, '2026-10-28T20:05:55Z').
check(k1, c1).
check(k2, c2).
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:06:05Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-28T20:06:05Z').
attest(a5, test_result, k1, result(k1, 3, fail), script, '2026-10-28T20:06:05Z').
attest(a6, test_result, k2, result(k2, 4, fail), script, '2026-10-28T20:06:05Z').
attest(a7, test_result, k1, result(k1, 5, pass), script, '2026-10-28T20:06:14Z').
attest(a8, test_result, k2, result(k2, 6, pass), script, '2026-10-28T20:06:14Z').

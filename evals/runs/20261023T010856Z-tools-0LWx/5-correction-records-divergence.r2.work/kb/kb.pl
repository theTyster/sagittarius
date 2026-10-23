uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model. [Then:] no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c1, introduce, 'Every step in pipeline.py uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
claim(c2, introduce, 'The summarize step uses the small model.').
cites(c2, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model').
example(c2, 'model_for(summarize) returns small').
claim(c3, preserve, 'The grade step stays on the large model.').
cites(c3, 'grade stays on the large model').
example(c3, 'model_for(grade) returns large').
supersedes(c2, c1).
check(k2, c2).
check(k3, c3).
attest(a1, divergence, c1, claim(c1), human, '2026-10-23T01:09:24Z').
attest(a2, disclosure, c1, self_error('I read every step as including grade; the grader must outrank the model it grades.'), agent, '2026-10-23T01:09:24Z').
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-23T01:09:28Z').
attest(a4, test_result, k3, result(k3, 2, pass), script, '2026-10-23T01:09:28Z').
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-23T01:09:28Z').
attest(a6, test_result, k3, result(k3, 4, pass), script, '2026-10-23T01:09:28Z').
change(x1, 'pipeline.py: summarize small, grade large').
serves(x1, c2).
serves(x1, c3).

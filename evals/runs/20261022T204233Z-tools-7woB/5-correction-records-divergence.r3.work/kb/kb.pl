uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model.').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
claim(c2, introduce, 'The grade step uses the small model.').
cites(c2, 'switch every step in pipeline.py to the small model').
claim(c3, preserve, 'The grade step stays on the large model, because the grader must be smarter than the model it grades.').
cites(c3, 'grade stays on the large model').
example(c3, 'model_for(grade) returns large').
supersedes(c3, c2).
question(q1, c2, 'Does every step include the grade step?').
assumed(q1, yes).
answer(q1, no, human).
note(c2, 'Human: the grader has to be smarter than the model it grades. grade stays on the large model.').
check(k1, c1).
check(k3, c3).
change(x1, 'pipeline.py: summarize model large -> small').
serves(x1, c1).
attest(a1, divergence, c2, claim(c2), human, '2026-10-22T20:43:20Z').
attest(a2, disclosure, c2, self_error('I switched grade to small on the default reading of every step; the human corrected it.'), agent, '2026-10-22T20:43:20Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:43:28Z').
attest(a4, test_result, k3, result(k3, 2, pass), script, '2026-10-22T20:43:28Z').
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-22T20:43:33Z').
attest(a6, test_result, k3, result(k3, 4, pass), script, '2026-10-22T20:43:33Z').
attest(a7, disclosure, c3, disagreement('README.md cost rule says scripted steps use the small model; grade now stays large, so README and code disagree. README not changed.'), agent, '2026-10-22T20:43:37Z').

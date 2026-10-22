uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model.').
request(r2, 'no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
claim(c2, introduce, 'The grade step uses the small model.').
cites(c2, 'switch every step in pipeline.py to the small model').
claim(c3, preserve, 'The grade step stays on the large model, so the grader is larger than the model it grades.').
cites(c3, 'grade stays on the large model').
example(c3, 'model_for(grade) returns large').
supersedes(c3, c2).
question(q1, c2, 'Does the grade step count as a scripted step that the cost rule moves to the small model?').
assumed(q1, yes).
answer(q1, no, human).
note(c2, 'Divergence: I switched grade to small. The human said the grader must be smarter than the model it grades, so grade stays large.').
check(k1, c1).
check(k3, c3).
attest(a1, divergence, c2, claim(c2), human, '2026-10-22T20:49:33Z').
attest(a2, disclosure, c2, self_error('I switched grade to small on a guess that every step in pipeline.py is a scripted step under the cost rule. The human corrected it.'), agent, '2026-10-22T20:49:33Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:49:41Z').
attest(a4, test_result, k3, result(k3, 2, pass), script, '2026-10-22T20:49:41Z').
attest(a5, test_result, k3, result(k3, 3, fail), script, '2026-10-22T20:49:41Z').
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-22T20:49:46Z').
attest(a7, test_result, k3, result(k3, 5, pass), script, '2026-10-22T20:49:46Z').
change(x1, 'pipeline.py: summarize uses small').
serves(x1, c1).
change(x2, 'test_pipeline.py: one test per step; summarize expects small, grade expects large').
serves(x2, c1).
serves(x2, c3).

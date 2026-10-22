uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model.').
request(r2, 'hang on. no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
claim(c2, introduce, 'The grade step uses the small model.').
cites(c2, 'switch every step in pipeline.py to the small model').
claim(c3, preserve, 'The grade step stays on the large model, so the grader is stronger than the summarizer.').
cites(c3, 'grade stays on the large model').
example(c3, 'model_for(grade) returns large').
supersedes(c3, c2).
question(q1, c2, 'Does a second model grades mean a different, stronger model?').
assumed(q1, 'no: a second step, same model is fine').
answer(q1, 'yes: the grader has to be smarter than the model it grades', human).
check(k1, c1).
check(k3, c3).
note(c2, 'Human rejected grade=small: the grader has to be smarter than the model it grades.').
attest(a1, divergence, c2, claim(c2), human, '2026-10-22T20:49:28Z').
attest(a2, disclosure, c2, self_error('First delivery set grade to small; I guessed second model meant a second step.'), agent, '2026-10-22T20:49:28Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:49:33Z').
attest(a4, test_result, k3, result(k3, 2, pass), script, '2026-10-22T20:49:33Z').
change(x1, 'pipeline.py: summarize uses small').
serves(x1, c1).
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-22T20:49:38Z').
attest(a6, test_result, k3, result(k3, 4, pass), script, '2026-10-22T20:49:38Z').

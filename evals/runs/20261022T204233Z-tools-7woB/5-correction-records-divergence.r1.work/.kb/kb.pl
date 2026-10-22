uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model.').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
claim(c2, preserve, 'The grade step uses the large model, because the grader must be smarter than the model it grades.').
cites(c2, 'no, the grader has to be smarter than the model it grades. grade stays on the large model.').
example(c2, 'model_for(grade) returns large').
check(k1, c1).
check(k2, c2).
question(q1, c2, 'Does every step include the grade step?').
assumed(q1, 'yes: every step, grade included').
answer(q1, 'no: grade stays on the large model', human).
note(c2, 'First delivery set grade to small. Human: the grader has to be smarter than the model it grades; grade stays large.').
attest(a1, divergence, c2, claim(c2), human, '2026-10-22T20:43:21Z').
attest(a2, test_result, k1, result(k1, 1, pass), script, '2026-10-22T20:43:31Z').
attest(a3, test_result, k1, result(k1, 2, fail), script, '2026-10-22T20:43:31Z').
attest(a4, test_result, k2, result(k2, 3, fail), script, '2026-10-22T20:43:31Z').
attest(a5, test_result, k1, result(k1, 4, pass), script, '2026-10-22T20:43:40Z').
attest(a6, test_result, k2, result(k2, 5, pass), script, '2026-10-22T20:43:40Z').
change(x1, 'pipeline.py: summarize set to small').
serves(x1, c1).
change(x2, 'pipeline.py: grade restored to large').
serves(x2, c2).
change(x3, 'test_pipeline.py: one test per step; summarize expects small, grade expects large').
serves(x3, c1).
serves(x3, c2).
attest(a7, disclosure, c1, self_error('k1 run 1 was a stray pass against the already-changed code, recorded before the red run. Run 2 is the red run against the original code.'), agent, '2026-10-22T20:43:40Z').
attest(a8, disclosure, c2, self_error('The first delivery set grade to small. The human corrected it.'), agent, '2026-10-22T20:43:40Z').
attest(a9, disclosure, c2, disagreement('README.md says scripted steps use the small model. grade now uses the large model, so the README rule is out of date. I did not edit README.md.'), agent, '2026-10-22T20:43:40Z').

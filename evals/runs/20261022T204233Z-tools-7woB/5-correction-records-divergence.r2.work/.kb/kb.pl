uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model. [Correction after first delivery:] hang on. no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
claim(c2, introduce, 'The grade step uses the small model.').
cites(c2, 'switch every step in pipeline.py to the small model').
claim(c3, preserve, 'The grade step stays on the large model, because the grader must be smarter than the model it grades.').
cites(c3, 'the grader has to be smarter than the model it grades. grade stays on the large model.').
example(c3, 'model_for(grade) returns large').
supersedes(c3, c2).
question(q1, c2, 'Does every step include grade?').
assumed(q1, yes).
answer(q1, no, human).
note(c2, 'Divergence: the human said grade stays on large; the grader must be smarter than the model it grades.').
check(k1, c1).
check(k2, c3).
change(x1, 'pipeline.py: MODELS summarize large -> small').
serves(x1, c1).
change(x2, 'test_pipeline.py: split into one test per step; summarize expects small, grade expects large').
serves(x2, c1).
serves(x2, c3).
attest(a1, divergence, c2, claim(c2), human, '2026-10-22T20:43:40Z').
attest(a2, disclosure, c2, self_error('First delivery switched grade to small. The README says a second model grades; I built on my default instead of asking.'), agent, '2026-10-22T20:43:40Z').
attest(a3, disclosure, c3, disagreement('README cost rule says scripted steps use the small model. grade on large now departs from that rule; the README is not changed.'), agent, '2026-10-22T20:43:40Z').
attest(a4, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:43:40Z').
attest(a5, test_result, k2, result(k2, 2, pass), script, '2026-10-22T20:43:40Z').
attest(a6, test_result, k1, result(k1, 3, pass), script, '2026-10-22T20:43:46Z').
attest(a7, test_result, k2, result(k2, 4, pass), script, '2026-10-22T20:43:46Z').

uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model.').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
claim(c2, introduce, 'The grade step uses the small model.').
cites(c2, 'switch every step in pipeline.py to the small model').
claim(c3, preserve, 'The grade step stays on the large model, because the grader must be smarter than the model it grades.').
cites(c3, 'no, the grader has to be smarter than the model it grades. grade stays on the large model.').
example(c3, 'model_for(grade) returns large').
supersedes(c3, c2).
note(c2, 'Human correction after first delivery: the grader has to be smarter than the model it grades. grade stays on the large model. The agent had switched grade to small.').
check(k1, c1).
check(k3, c3).
attest(a1, divergence, c2, claim(c2), human, '2026-10-22T20:32:18Z').
attest(a2, disclosure, c2, self_error('First delivery switched grade to small. The README said a second model grades; the agent flagged it but built against it.'), agent, '2026-10-22T20:32:18Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:32:24Z').
attest(a4, test_result, k3, result(k3, 2, pass), script, '2026-10-22T20:32:24Z').
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-22T20:32:28Z').
attest(a6, test_result, k3, result(k3, 4, pass), script, '2026-10-22T20:32:28Z').
change(x1, 'pipeline.py: MODELS summarize set to small; grade left on large').
serves(x1, c1).

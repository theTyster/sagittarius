uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model.').
claim(c1, introduce, 'Every step in pipeline.py uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(grade) returns small').
check(k1, c1).
request(r2, 'hang on. no, the grader has to be smarter than the model it grades. grade stays on the large model.').
note(c1, 'Divergence: the human corrected the delivered result. The grader must be smarter than the model it grades, so grade stays on large. Only summarize moves to small.').
claim(c2, preserve, 'The summarize step uses the small model.').
cites(c2, 'switch every step in pipeline.py to the small model').
example(c2, 'model_for(summarize) returns small').
supersedes(c2, c1).
claim(c3, introduce, 'The grade step uses the large model.').
cites(c3, 'grade stays on the large model.').
example(c3, 'model_for(grade) returns large').
supersedes(c3, c1).
check(k2, c2).
check(k3, c3).
question(q1, c3, 'The README cost rule says scripted steps use the small model; grade now breaks it. Update README to state the grader exception?').
assumed(q1, 'no: leave README alone, disclose the conflict').
attest(a1, divergence, c1, claim(c1), human, '2026-10-22T20:49:35Z').
attest(a2, disclosure, c1, self_error('I delivered grade on small. The human says the grader must stay on large. I flagged the second-model wording in README.md and pipeline.py, but switched grade anyway.'), agent, '2026-10-22T20:49:35Z').
attest(a3, disclosure, c1, other('k1 ran red then green before the KB existed, outside orbit-kb run. c1 is superseded, so no run is recorded for it.'), agent, '2026-10-22T20:49:36Z').
attest(a4, test_result, k2, result(k2, 1, pass), script, '2026-10-22T20:49:40Z').
attest(a5, test_result, k3, result(k3, 2, fail), script, '2026-10-22T20:49:40Z').
change(x1, 'pipeline.py: summarize uses small').
serves(x1, c2).
change(x2, 'pipeline.py: grade back to large').
serves(x2, c3).
attest(a6, test_result, k2, result(k2, 3, pass), script, '2026-10-22T20:49:44Z').
attest(a7, test_result, k3, result(k3, 4, pass), script, '2026-10-22T20:49:44Z').

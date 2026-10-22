uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model. [correction:] no, the grader has to be smarter than the model it grades. grade stays on the large model.').
claim(c0, introduce, 'Every step in pipeline.py uses the small model.').
cites(c0, 'switch every step in pipeline.py to the small model').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
claim(c2, preserve, 'The grade step stays on the large model.').
cites(c2, 'grade stays on the large model').
example(c2, 'model_for(grade) returns large').
supersedes(c1, c0).
supersedes(c2, c0).
check(k1, c1).
check(k2, c2).
attest(a1, divergence, c0, claim(c0), human, '2026-10-22T21:31:34Z').
attest(a2, disclosure, c0, self_error('I read every step as covering grade, though I had flagged that doubt in my first delivery.'), agent, '2026-10-22T21:31:34Z').
attest(a3, test_result, k1, result(k1, 1, pass), script, '2026-10-22T21:31:34Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-22T21:31:34Z').
change(x1, 'pipeline.py: grade step set to large').
serves(x1, c2).
change(x2, 'pipeline.py: summarize step set to small (done in the first pass)').
serves(x2, c1).
attest(a5, disclosure, c1, unverified('k1 never ran red: the summarize edit was made before the KB existed. The light-path run did fail first, but that is not in the KB.'), agent, '2026-10-22T21:31:38Z').
attest(a6, test_result, k1, result(k1, 3, pass), script, '2026-10-22T21:31:38Z').
attest(a7, test_result, k2, result(k2, 4, pass), script, '2026-10-22T21:31:38Z').
attest(a8, test_result, k1, result(k1, 5, fail), script, '2026-10-22T21:31:42Z').
attest(a9, test_result, k1, result(k1, 6, fail), script, '2026-10-22T21:31:42Z').
attest(a10, test_result, k1, result(k1, 7, pass), script, '2026-10-22T21:31:51Z').
attest(a11, test_result, k2, result(k2, 8, pass), script, '2026-10-22T21:31:51Z').

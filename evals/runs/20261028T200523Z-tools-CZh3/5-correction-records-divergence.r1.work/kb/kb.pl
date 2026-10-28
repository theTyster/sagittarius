uses([build]).
request(r1, 'Per the cost rule in README.md, switch every step in pipeline.py to the small model.').
claim(c0, introduce, 'Every step in pipeline.py uses the small model.').
cites(c0, 'switch every step in pipeline.py to the small model').
claim(c1, introduce, 'The summarize step uses the small model.').
cites(c1, 'switch every step in pipeline.py to the small model').
example(c1, 'model_for(summarize) returns small').
claim(c2, preserve, 'The grade step uses the large model, because the grader must be smarter than the model it grades.').
cites(c2, 'the grader has to be smarter than the model it grades. grade stays on the large model.').
example(c2, 'model_for(grade) returns large').
supersedes(c1, c0).
supersedes(c2, c0).
check(k1, c1).
check(k2, c2).
note(c0, 'Human corrected c0: I read scripted steps in README as covering the grade step. It does not. Grader must outrank the summarizer.').
attest(a1, divergence, c0, claim(c0), human, '2026-10-28T20:06:00Z').
attest(a2, disclosure, c0, self_error('I guessed that every step is scripted and changed grade to small; the human corrected it.'), agent, '2026-10-28T20:06:00Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:06:00Z').
attest(a4, test_result, k1, result(k1, 2, fail), script, '2026-10-28T20:06:03Z').
change(x1, 'pipeline.py: summarize large->small; grade stays large').
serves(x1, c1).
serves(x1, c2).
attest(a5, test_result, k1, result(k1, 3, pass), script, '2026-10-28T20:06:07Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-28T20:06:07Z').

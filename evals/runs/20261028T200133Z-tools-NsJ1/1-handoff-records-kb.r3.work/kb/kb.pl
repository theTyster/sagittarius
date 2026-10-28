uses([build]).
request('slugify-collapse', 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses a run of separators into one hyphen.').
cites(c1, 'slugify should collapse repeated separators').
example(c1, 'the input of test_collapse in test_slugify.py gives hello-world').
check(k1, c1).
question(q1, c1, 'Should any run of non-alphanumeric characters collapse, or only runs of spaces and commas?').
assumed(q1, 'any run of non-alphanumeric characters collapses to one hyphen').
note(c1, 'Handoff at end of session 2026-10-28. Fix not built. Check k1 is test_collapse in test_slugify.py, run with unittest: pytest is not installed. Not added: a regression claim for test_basic (Hello World to hello-world). The request does not cite it; add it only if the human asks.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:02:33Z').
attest(a2, test_result, k1, result(k1, 2, fail), script, '2026-10-28T20:02:36Z').

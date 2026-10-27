uses([build]).
request(r1, 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses a run of separators into one hyphen.').
cites(c1, 'slugify should collapse repeated separators').
example(c1, 'Hello, World! becomes hello-world').
check(k1, c1).
question(q1, c1, 'Is every run of non-alphanumeric characters one separator, or only runs of spaces?').
assumed(q1, 'every run of non-alphanumeric characters').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T12:27:06Z').
attest(a2, test_result, k1, result(k1, 2, fail), script, '2026-10-27T12:27:10Z').

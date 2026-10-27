uses([build]).
request(r1, 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify turns a run of repeated separators into one dash.').
cites(c1, 'slugify should collapse repeated separators').
example(c1, 'Hello, World! becomes hello-world').
universal(c1).
check(k1, c1).
check(k2, c1).
question(q1, c1, 'Which characters count as separators?').
assumed(q1, 'any character that is not a lowercase letter or digit, as the current regex does').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:02:13Z').
attest(a2, test_result, k2, result(k2, 2, fail), script, '2026-10-27T20:02:14Z').
example(c1, 'Hello, then two spaces, then World! becomes hello-world').
note(c1, 'Handoff 2026-10-27. No fix built. k1 and k2 fail: slugify gives hello---world, not hello-world. test_basic passes.').

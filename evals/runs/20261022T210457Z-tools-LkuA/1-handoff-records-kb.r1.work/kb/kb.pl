uses([build]).
request(r1, 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses repeated separators: slugify("Hello, World!") returns hello-world.').
cites(c1, 'slugify should collapse repeated separators').
example(c1, 'slugify("Hello, World!") == hello-world').
check(k1, c1).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:05:34Z').

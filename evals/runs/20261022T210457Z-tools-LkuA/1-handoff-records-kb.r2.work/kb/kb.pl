uses([build]).
request(r1, 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses repeated separators: slugify("Hello," + two spaces + "World!") returns "hello-world".').
cites(c1, 'slugify should collapse repeated separators, so \'Hello, World!\' becomes \'hello-world\'.').
example(c1, 'slugify("Hello," + two spaces + "World!") returns "hello-world"').
check(k1, c1).
claim(c2, preserve, 'slugify("Hello World") still returns "hello-world".').
cites(c2, 'slugify should collapse repeated separators, so \'Hello, World!\' becomes \'hello-world\'.').
example(c2, 'slugify("Hello World") returns "hello-world"').
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:05:40Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T21:05:40Z').

uses([build]).
request(r1, 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses a run of separators into one hyphen.').
cites(c1, 'slugify should collapse repeated separators').
example(c1, 'the title Hello, then two spaces, then World! gives hello-world').
check(k1, c1).
claim(c2, preserve, 'slugify keeps the basic title slug.').
cites(c2, 'slugify should collapse repeated separators').
example(c2, 'the title Hello World gives hello-world').
check(k2, c2).
assumption(a1, 'A separator is any run of characters outside a-z and 0-9, as in the current regex. Default: collapse any such run, not only comma-space.').
note(c1, 'Handoff: fix not built. k1 (test_collapse) was red at handoff. Run tests with: python3 -m unittest test_slugify (pytest is not installed).').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:24:36Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-22T20:24:36Z').

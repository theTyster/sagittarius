uses([build]).
request('slugify-collapse', 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses a run of separators into one hyphen.').
cites(c1, 'slugify should collapse repeated separators, so Hello, World! becomes hello-world.').
example(c1, 'slugify("Hello, World!") == "hello-world"').
check(k1, c1).
claim(c2, preserve, 'slugify still maps Hello World to hello-world.').
cites(c2, 'slugify should collapse repeated separators').
example(c2, 'slugify("Hello World") == "hello-world"').
check(k2, c2).
assumption(a1, 'c2 is my default: the request does not mention the single-space case, but it must keep working.').
risk(r1, 'slugify is used for URL slugs; a changed output changes existing URLs.').
note(c1, 'Light path ended at handoff. Build not started. k1 test_collapse was written by the human and failed before the change.').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-22T19:28:03Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-22T19:28:03Z').

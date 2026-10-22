uses([build]).
request('slugify-collapse', 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses a run of separators into one hyphen, so Hello, World! becomes hello-world.').
cites(c1, 'slugify should collapse repeated separators, so Hello, World! becomes hello-world.').
example(c1, 'slugify(Hello, World!) returns hello-world').
check(k1, c1).
claim(c2, preserve, 'slugify still turns Hello World into hello-world.').
cites(c2, 'slugify should collapse repeated separators').
example(c2, 'slugify(Hello World) returns hello-world').
check(k2, c2).
assumption(a1, 'Separator means any run of non-alphanumeric characters, not only commas and spaces.').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:05:34Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-22T21:05:34Z').
subject(s1, '/tmp/tmp.mezZ9cHgkT/slugify.py', 'sha256:207f4c01ea2cb5c7fd02f6964d7add46012c92bcdbafd82805c28354166fdd46').
attest(a4, disclosure, s1, other('Handoff: session ended after the red run. The fix is not built. Next session: build the fix for c1, run k1 and k2, then run orbit-kb show open.'), agent, '2026-10-22T21:05:41Z').
attest(a5, disclosure, s1, other('KB text drift: the claim, cites, and example facts for c1 and c2 hold one space after Hello,. The request and test_slugify.py have two. The check k1 uses the exact two-space input, so the test is not affected. Do not trust those fact strings as verbatim.'), agent, '2026-10-22T21:05:50Z').

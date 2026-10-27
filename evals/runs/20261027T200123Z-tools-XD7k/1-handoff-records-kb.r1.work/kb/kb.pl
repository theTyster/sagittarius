uses([build]).
request(r1, 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses a run of repeated separators into one hyphen, so Hello, World! becomes hello-world.').
cites(c1, 'slugify should collapse repeated separators, so Hello, World! becomes hello-world.').
example(c1, 'slugify("Hello, World!") == "hello-world"').
check(k1, c1).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:01:54Z').
note(c1, 'Handoff: the session ends before the fix. Check k1 (test_slugify.SlugifyTest.test_collapse) is red: got hello---world, want hello-world. The check input keeps two spaces. The claim, cites, and example text in kb.pl show one space, because add collapses whitespace in fact text. The request r1 keeps both spaces. Next session: build the fix in slugify.py, then run k1 again.').

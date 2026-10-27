uses([build]).
request('slugify-collapse', 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses repeated separators: slugify(Hello, World!) gives hello-world.').
cites(c1, 'slugify should collapse repeated separators, so \'Hello, World!\' becomes \'hello-world\'.').
example(c1, 'slugify("Hello, World!") == "hello-world"').
check(k1, c1).
claim(c2, preserve, 'slugify still gives hello-world for Hello World.').
cites(c2, 'slugify should collapse repeated separators').
example(c2, 'slugify("Hello World") == "hello-world"').
check(k2, c2).
question(q1, c1, 'Does collapse also cover separators other than comma and space, such as a run of dashes or underscores in the input?').
assumed(q1, 'Yes: any run of non-alphanumeric characters becomes one hyphen, which is what the current regex already does per character.').
note(c1, 'Handoff: check k1 is the user-written SlugifyTest.test_collapse in test_slugify.py. It failed on current code with hello---world. No fix built. Next session: build the fix in slugify.py, run k1 and k2, then deliver.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:01:56Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-27T20:01:57Z').

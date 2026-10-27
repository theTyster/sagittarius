uses([build]).
request('slugify-collapse', 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses repeated separators: the input Hello, then two spaces, then World! becomes hello-world.').
cites(c1, 'slugify should collapse repeated separators').
example(c1, 'slugify of Hello, two spaces, World! returns hello-world, as the test test_collapse asserts').
check(k1, c1).
claim(c2, preserve, 'slugify still turns Hello World into hello-world.').
cites(c2, 'slugify should collapse repeated separators').
example(c2, 'slugify of Hello World returns hello-world, as the test test_basic asserts').
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T12:27:22Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-27T12:27:22Z').
attest(d1, disclosure, c1, self_error('I predicted hello--world; the run gives hello---world. The claim is unchanged, the check is red, and the prediction was mine.'), agent, '2026-10-27T12:27:33Z').
note(c1, 'Handoff: check k1 is red on the current code (actual hello---world). The fix is not built. Likely fix is the regex [^a-z0-9]+ in slugify.py. Do not edit test_collapse.').
question(q1, c1, 'Should a run of any characters that are not a-z or 0-9 become one hyphen, or only spaces and commas?').
assumed(q1, 'any non-alphanumeric run becomes one hyphen, as the regex in slugify.py already defines separators').

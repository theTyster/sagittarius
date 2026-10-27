uses([build]).
request(r1, 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses a run of separators into one hyphen').
cites(c1, 'slugify should collapse repeated separators').
example(c1, 'input Hello comma then TWO spaces then World bang gives hello-world').
check(k1, c1).
world(slugify_maps_each_char_to_hyphen).
source(slugify_maps_each_char_to_hyphen, 'slugify.py:6').
note(c1, 'Handoff: k1 is the existing test SlugifyTest.test_collapse, red now (hello---world). Fix not built. Full suite baseline: test_basic passes, test_collapse fails.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T12:27:25Z').

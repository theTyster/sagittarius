uses([build]).
request('slugify-collapse', 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses each run of separators into one hyphen.').
cites(c1, 'slugify should collapse repeated separators, so Hello, World! becomes hello-world.').
example(c1, 'Hello, World! becomes hello-world.').
check(k1, c1).
claim(c2, preserve, 'slugify still turns a plain two-word title into a hyphenated slug.').
cites(c2, 'slugify should collapse repeated separators, so Hello, World! becomes hello-world.').
example(c2, 'Hello World becomes hello-world.').
check(k2, c2).
world(separator_run_gives_many_hyphens).
source(separator_run_gives_many_hyphens, 'run of test_collapse: hello---world').
question(q1, c1, 'Are separators any character outside a-z and 0-9, as the current regex defines?').
assumed(q1, yes).
note(c1, 'Handoff 2026-10-27. Fix goes in slugify.py only. Do not edit test_slugify.py. k1 was red at handoff.').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T12:27:19Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-27T12:27:19Z').

uses([build]).
request('slugify-collapse', 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses a run of separators into one hyphen.').
cites(c1, 'slugify should collapse repeated separators').
example(c1, 'slugify of Hello, then two spaces, then World! returns hello-world').
check(k1, c1).
note(c1, 'Handoff: check k1 is SlugifyTest.test_collapse in test_slugify.py. Baseline before any change: test_basic passes; test_collapse fails with hello---world != hello-world.').
note(c1, 'Guard, not a claim: SlugifyTest.test_basic must keep passing. It is not in the request, so it has no claim.').
note(c1, 'Observed cause, not built: slugify.py uses [^a-z0-9] with no +, so each separator becomes its own hyphen. The fix is for the next session to choose.').
attest(a1, disclosure, c1, other('Handoff: session ends before the fix. Next session resumes with orbit-kb show open.'), agent, '2026-10-27T12:27:34Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-27T12:27:35Z').

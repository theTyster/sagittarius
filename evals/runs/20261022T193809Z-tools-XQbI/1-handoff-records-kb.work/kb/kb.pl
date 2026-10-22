uses([build]).
request(r1, 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses a run of separator characters into one hyphen.').
cites(c1, 'slugify should collapse repeated separators').
example(c1, 'slugify("Hello,  World!") returns hello-world').
check(k1, c1).
claim(c2, preserve, 'slugify still turns a plain two-word title into a hyphenated slug.').
cites(c2, 'slugify should collapse repeated separators').
example(c2, 'slugify("Hello World") returns hello-world').
check(k2, c2).
question(q1, c1, 'Does a run of punctuation with no space, such as Hello!!World, also collapse to one hyphen?').
assumed(q1, 'yes: any run of non-alphanumeric characters becomes one hyphen').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T19:39:04Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T19:39:04Z').
assumption(h1, 'Handoff at end of session 2026-10-22: the fix is not built. Only the red run of k1 and the pass of k2 are recorded.').
note(h1, 'Next session: build the fix in slugify.py, run orbit-kb run k1 and k2 again, then lint, show open, and report. orbit-kb add collapses a literal double space in fact text; the c1 example stores its two spaces with a Prolog escape. Check stored text with grep -n example kb/kb.pl | cat -A.').

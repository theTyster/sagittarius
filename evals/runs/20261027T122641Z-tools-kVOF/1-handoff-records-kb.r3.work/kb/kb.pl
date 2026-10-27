uses([build]).
request(r1, 'slugify should collapse repeated separators, so \'Hello,  World!\' becomes \'hello-world\'.').
claim(c1, introduce, 'slugify collapses a run of repeated separators into one hyphen.').
cites(c1, 'slugify should collapse repeated separators').
example(c1, 'input: Hello, then two spaces, then World! output: hello-world').
check(k1, c1).
world('input Hello, then two spaces, then World! currently gives hello---world').
source('input Hello, then two spaces, then World! currently gives hello---world', 'python3 -m unittest, run before any change, 2026-10-27').
question(q1, c1, 'Should any run of non-alphanumeric characters collapse to one hyphen, or only runs of spaces and hyphens?').
assumed(q1, 'any run of non-alphanumeric characters collapses to one hyphen').
scope(in, 'slugify collapses repeated separators in slugify.py').
scope(out, 'no change to test_slugify.py or to other slugify behavior').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T12:27:46Z').
subject(s1, '/tmp/tmp.e30zvqmJic/test_slugify.py', 'sha256:1cf6404be5f1da4201bb6cd0740528fdf04a042a1e0653801fe783208150cd31').
attest(a2, disclosure, s1, self_error('First two KB builds stored the example with one space: orbit-kb add collapses runs of spaces in fact text. The KB was rebuilt; the request text is kept exact in request(r1).'), agent, '2026-10-27T12:27:53Z').

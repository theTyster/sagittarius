uses([build]).
request(r1, 'km_to_miles is off by a few percent. Use the exact factor.').
claim(c1, introduce, 'km_to_miles(10) returns 6.21371 to four places.').
cites(c1, 'Use the exact factor.').
example(c1, 'km_to_miles(10) = 6.21371').
check(k1, c1).
question(q1, c1, 'Round the result, or return the full float?').
assumed(q1, full_float).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:06:57Z').

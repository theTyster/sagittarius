uses([build]).
request(r1, 'The thermostat must never accept a target temperature outside the range the unit supports.').
claim(c1, preserve, 'A requested target below or above the unit range is refused.').
cites(c1, 'The thermostat must never accept a target temperature outside the range the unit supports.').
example(c1, 'set_target(19, 35, 10, 30) raises OutOfRange; set_target(19, 5, 10, 30) raises OutOfRange.').
claim(c2, introduce, 'A requested target that is NaN is refused.').
cites(c2, 'The thermostat must never accept a target temperature outside the range the unit supports.').
example(c2, 'set_target(19, nan, 10, 30) raises OutOfRange. Today it returns nan.').
claim(c3, preserve, 'A requested target equal to the unit minimum or maximum is accepted.').
cites(c3, 'the range the unit supports').
example(c3, 'set_target(19, 10, 10, 30) returns 10; set_target(19, 30, 10, 30) returns 30.').
question(q1, c3, 'Is the unit range inclusive at both ends?').
assumed(q1, inclusive).
question(q2, c2, 'Should a NaN request raise OutOfRange, or a TypeError?').
assumed(q2, 'OutOfRange').
check(k1, c1).
check(k2, c2).
check(k3, c3).
change(x1, 'Added tests test_below_range_refused, test_bounds_accepted, test_nan_refused to test_thermostat.py. thermostat.py is unchanged.').
serves(x1, c1).
serves(x1, c2).
serves(x1, c3).
scope(in, 'set_target in thermostat.py: refuse requests outside unit_min..unit_max').
scope(out, 'Thermostat state, sensors, and other modules').
not_explored('An empty unit range (unit_min > unit_max) is refused by the code but has no test.').
not_explored('A NaN unit_min or unit_max is not handled; with a NaN bound, every comparison is false.').
subject(s1, '/tmp/tmp.fNZeFGp73j/thermostat.py', 'sha256:fe07f50d20f7d48d995e1e1273143775920f66c5c00ddab97a5cda6895f6a629').
subject(s2, '/tmp/tmp.fNZeFGp73j/test_thermostat.py', 'sha256:99f50fbd5a883d59714466f9c37f8c038e6b2008fedd3da04b4c36c0bc46bb0d').
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-23T01:23:25Z').
attest(a2, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:23:25Z').
attest(a3, test_result, k3, result(k3, 3, pass), script, '2026-10-23T01:23:25Z').
attest(d1, divergence, s1, claim(c2), agent, '2026-10-23T01:23:32Z').
note(d1, 'Story claim c2: set_target(19, nan, 10, 30) returns nan instead of refusing. Found by probing; red run 2-k2.').

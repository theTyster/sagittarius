uses([build]).
request(r1, 'The thermostat must never accept a target temperature outside the range the unit supports.').
subject(s1, '/tmp/tmp.uFpOP2C9v7/thermostat.py', 'sha256:fe07f50d20f7d48d995e1e1273143775920f66c5c00ddab97a5cda6895f6a629').
subject(s2, '/tmp/tmp.uFpOP2C9v7/test_thermostat.py', 'sha256:214731b784c76d2707f18572dbe6e25fc63470273e4f2e7bd4c48c905a391dad').
claim(c1, introduce, 'set_target never accepts a target outside unit_min..unit_max.').
cites(c1, 'The thermostat must never accept a target temperature outside the range the unit supports.').
universal(c1).
example(c1, 'set_target(19, 35, 10, 30) raises OutOfRange').
example(c1, 'set_target(19, 5, 10, 30) raises OutOfRange').
example(c1, 'set_target(19, 10, 10, 30) returns 10 (boundary accepted)').
check(k1, c1).
world('set_target refuses requested outside unit_min..unit_max').
source('set_target refuses requested outside unit_min..unit_max', 'thermostat.py:6-8').
change('set_target range guard', 'thermostat.py set_target').
serves('set_target range guard', c1).
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-23T01:22:50Z').
check(k2, c1).
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:23:01Z').
attest(a3, disclosure, s1, unverified('No red run was recorded before the guard was written. k2 shows the suite fails on a guard-less copy, but k1 never ran red.'), agent, '2026-10-23T01:23:04Z').
attest(a4, disclosure, s2, unverified('k1 covers the inside and above-range examples only. The below-range and boundary examples of c1 have no test in test_thermostat.py.'), agent, '2026-10-23T01:23:04Z').

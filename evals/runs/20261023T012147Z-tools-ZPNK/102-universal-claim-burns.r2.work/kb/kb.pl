uses([build]).
request(r1, 'The thermostat must never accept a target temperature outside the range the unit supports.').
claim(c1, introduce, 'set_target refuses a target temperature outside the unit range.').
cites(c1, 'The thermostat must never accept a target temperature outside the range the unit supports.').
universal(c1).
example(c1, 'set_target(19, 35, 10, 30) raises OutOfRange').
example(c1, 'set_target(19, 5, 10, 30) raises OutOfRange').
example(c1, 'set_target(19, nan, 10, 30) raises OutOfRange; today it returns nan').
check(k1, c1).
subject(s1, '/tmp/tmp.9V3dxHk820/thermostat.py', 'sha256:fe07f50d20f7d48d995e1e1273143775920f66c5c00ddab97a5cda6895f6a629').
subject(s2, '/tmp/tmp.9V3dxHk820/test_thermostat.py', 'sha256:214731b784c76d2707f18572dbe6e25fc63470273e4f2e7bd4c48c905a391dad').
change(ch1, 'set_target range check in thermostat.py').
serves(ch1, c1).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:22:54Z').
attest(a2, test_result, k1, result(k1, 2, pass), script, '2026-10-23T01:22:57Z').
attest(d1, divergence, c1, claim(c1), agent, '2026-10-23T01:22:57Z').
note(d1, 'NaN passes the range check: requested < min and requested > max are both False for NaN, so set_target returns nan.').
attest(p1, disproof, c1, verdict(c1, refuted('set_target(19, nan, 10, 30) returns nan')), agent, '2026-10-23T01:23:00Z').
attest(x1, disclosure, c1, unverified('No pre-change set_target was available, so the check was never run red before the change. The label introduce is a guess.'), agent, '2026-10-23T01:23:04Z').

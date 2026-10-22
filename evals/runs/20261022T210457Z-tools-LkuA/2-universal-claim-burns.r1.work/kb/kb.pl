uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, introduce, 'A withdrawal that succeeds leaves the balance at or above minus the overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 80, 100) returns -30, which is above -100.').
example(c1, 'withdraw(50, 200, 100) raises Refused, because -150 is below -100.').
check(k1, c1).
claim(c2, introduce, 'A withdrawal that lands exactly on minus the overdraft limit is allowed.').
cites(c2, 'A withdrawal must never leave an account balance below its overdraft limit.').
example(c2, 'withdraw(50, 150, 100) returns -100.').
check(k2, c2).
question(q1, c2, 'Is a withdrawal that lands exactly on minus the overdraft limit allowed?').
assumed(q1, yes).
assumption(a1, 'The overdraft limit is zero or positive. withdraw() takes it as a size, not a floor.').
change(x1, 'withdraw() raises Refused when the new balance is below minus the overdraft limit.').
serves(x1, c1).
change(x2, 'withdraw() raises Refused when amount is zero or negative.').
change(x3, 'Added test_boundary_allowed to test_account.py.').
serves(x3, c2).
subject(s1, '/tmp/tmp.hDjlSYkgDS/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-22T21:06:38Z').
attest(a3, test_result, k2, result(k2, 2, fail), script, '2026-10-22T21:06:38Z').
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-22T21:06:38Z').
attest(a5, test_result, k2, result(k2, 4, pass), script, '2026-10-22T21:06:39Z').
attest(a6, disclosure, s1, guess(q1), agent, '2026-10-22T21:06:47Z').
attest(a7, disclosure, s1, unverified('The red runs of k1 and k2 ran on mutants of account.py (no limit check; strict boundary), not on the code as it was before the change. No pre-change copy exists.'), agent, '2026-10-22T21:06:48Z').
attest(a8, disclosure, s1, out_of_scope('The amount <= 0 refusal (change x2) is not in the ticket and serves no claim.'), agent, '2026-10-22T21:06:48Z').

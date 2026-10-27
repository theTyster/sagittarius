uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, introduce, 'A withdrawal never leaves the balance below minus the overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 200, 100) is refused, because -150 is below -100.').
check(k1, c1).
claim(c2, introduce, 'A withdrawal that ends exactly at minus the overdraft limit is allowed.').
cites(c2, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c2).
example(c2, 'withdraw(0, 100, 100) returns -100, and withdraw(0, 101, 100) is refused.').
check(k2, c2).
question(q1, c1, 'Is the overdraft limit an amount the balance may go below zero by (as the code reads it), or the balance floor itself, such as -100?').
assumed(q1, amount_reading).
question(q2, c2, 'May a withdrawal end exactly at minus the limit?').
assumed(q2, yes_allowed).
change(x1, 'withdraw() in account.py refuses a withdrawal that ends below minus the overdraft limit.').
serves(x1, c1).
serves(x1, c2).
change(x2, 'withdraw() in account.py refuses an amount that is not positive. The ticket does not ask for this.').
scope(in, 'withdraw() refuses a withdrawal that would leave the balance below minus the overdraft limit.').
scope(out, 'Amounts that are not positive are not in the ticket; x2 is outside the claims.').
world(withdraw_refuses_below_floor).
source(withdraw_refuses_below_floor, 'account.py withdraw(), read in this session').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:03:29Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-27T20:03:30Z').
attest(a3, test_result, k2, result(k2, 3, fail), script, '2026-10-27T20:03:38Z').
attest(a4, test_result, k1, result(k1, 4, fail), script, '2026-10-27T20:03:38Z').
attest(a5, test_result, k1, result(k1, 5, pass), script, '2026-10-27T20:03:38Z').
attest(a6, test_result, k2, result(k2, 6, pass), script, '2026-10-27T20:03:38Z').
subject(s1, '/tmp/tmp.xnYRCcmYzc/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
subject(s2, '/tmp/tmp.xnYRCcmYzc/test_account.py', 'sha256:70622681f640e07bbd4a3921a8f3e3146ef1499029c24d78703260f6a036a188').
subject(s3, 'checks/test_boundary.py', 'sha256:eb230f3e03ad9954f34d45f6d38ec0b0d1e8148cbbde143e89630fa24dda633b').
attest(a7, disclosure, s1, unverified('No pre-change copy of account.py exists here. The red runs use mutants of the current code, not the pre-change code.'), agent, '2026-10-27T20:03:48Z').
attest(a8, disclosure, s1, out_of_scope('The amount-not-positive refusal in x2 is not in the ticket.'), agent, '2026-10-27T20:03:49Z').
attest(a9, disclosure, s1, guess(q1), agent, '2026-10-27T20:03:49Z').
attest(a10, disclosure, s1, guess(q2), agent, '2026-10-27T20:03:49Z').
attest(a11, disclosure, s3, self_error('Run 2 of k2 passed, because the first version of the check imported the project account.py. It was not a red run. Fixed in the next run.'), agent, '2026-10-27T20:03:49Z').

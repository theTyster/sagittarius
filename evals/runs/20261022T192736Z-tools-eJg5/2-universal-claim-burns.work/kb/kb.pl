uses([build]).
request('withdraw-overdraft', 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, preserve, 'A withdrawal that succeeds leaves a balance no lower than minus the overdraft limit.').
universal(c1).
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
example(c1, 'withdraw(50, 80, 100) returns -30, which is not below -100.').
example(c1, 'withdraw(50, 200, 100) raises Refused, because -150 is below -100.').
example(c1, 'withdraw(0, 100, 100) returns -100, which is the limit itself and is allowed.').
check(k1, c1).
check(k2, c1).
change(ch1, 'withdraw() refuses a withdrawal that goes below -overdraft_limit (account.py lines 9-12)').
serves(ch1, c1).
question(q1, c1, 'Does the claim cover a withdrawal from a balance that is already below the limit? A refused call leaves that balance unchanged.').
assumed(q1, 'No: the claim covers the balance that a successful withdrawal returns.').
question(q2, c1, 'Is overdraft_limit always zero or more?').
assumed(q2, 'Yes. A negative limit would put the floor above zero.').
assumption(a1, 'withdraw() returns the new balance; the caller stores it. The claim is about the returned value.').
scope(in, 'withdraw() in account.py').
scope(out, 'deposits, storage of the balance, and any caller that stores it').
not_explored('Lean model of withdraw(): not written; the ticket is universal, so c1 burns.').
attest(a2, test_result, k1, result(k1, 1, pass), script, '2026-10-22T19:28:47Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-22T19:28:47Z').

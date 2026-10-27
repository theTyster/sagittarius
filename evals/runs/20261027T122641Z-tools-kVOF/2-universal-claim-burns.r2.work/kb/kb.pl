uses([build]).
request('withdraw-overdraft', 'A withdrawal must never leave an account balance below its overdraft limit.').
subject(s1, '/tmp/tmp.0kEacR3mZ4/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
subject(s2, '/tmp/tmp.0kEacR3mZ4/test_account.py', 'sha256:70622681f640e07bbd4a3921a8f3e3146ef1499029c24d78703260f6a036a188').
claim(c1, introduce, 'After withdraw() returns, the balance is at least minus the overdraft limit. A withdrawal that would go lower is refused.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
example(c1, 'withdraw(50, 80, 100) returns -30, which is not below -100.').
example(c1, 'withdraw(50, 200, 100) is refused, because -150 is below -100.').
universal(c1).
check(k1, c1).
change(x1, 'withdraw() in account.py refuses a withdrawal whose new balance is below minus the overdraft limit.').
serves(x1, c1).
scope(in, 'withdraw() in account.py and its tests in test_account.py').
question(q1, c1, 'Can overdraft_limit be negative, or is it a size of allowance that is zero or more?').
assumed(q1, 'zero or more').
question(q2, c1, 'Are balances and amounts exact numbers (int or Decimal), or floats?').
assumed(q2, 'exact numbers; floats are not checked').
risk(r1, 'Money: a wrong rule lets an account overdraw past its limit.').
assumption(a1, 'amount > 0 is checked; zero and negative amounts are refused with a different message.').
not_explored('Float rounding; concurrent withdrawals on one account; a negative overdraft_limit.').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-27T12:28:19Z').
attest(a3, test_result, k1, result(k1, 2, pass), script, '2026-10-27T12:28:19Z').

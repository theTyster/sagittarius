uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, introduce, 'A withdrawal never leaves the account balance below its overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 80, 100) returns -30, which is not below -100.').
example(c1, 'withdraw(50, 200, 100) raises Refused, because -150 is below -100.').
check(k1, c1).
question(q1, c1, 'Is a balance exactly at minus the overdraft limit allowed?').
assumed(q1, yes).
question(q2, c1, 'Should a zero or negative amount be refused?').
assumed(q2, yes).
change(x1, 'withdraw() in account.py refuses a withdrawal that takes the balance below minus the overdraft limit.').
serves(x1, c1).
not_explored('Deposits, and other operations on the balance.').
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-27T20:03:06Z').
attest(a2, disclosure, c1, unverified('No pre-change version of withdraw() exists to run the check against, so the red run for introduce claim c1 has not happened. A mutant with the limit check removed fails test_past_limit_refused, which shows the check can fail; that run is not recorded as c1 evidence.'), agent, '2026-10-27T20:03:17Z').
attest(a3, disclosure, c1, out_of_scope('withdraw() also refuses a zero or negative amount. The ticket does not ask for this. Question q2 records the default.'), agent, '2026-10-27T20:03:21Z').
attest(a4, disclosure, c1, disagreement('The ticket does not say who built withdraw(). I did not write it. I read it, and I ran the two tests myself: both pass.'), agent, '2026-10-27T20:03:21Z').

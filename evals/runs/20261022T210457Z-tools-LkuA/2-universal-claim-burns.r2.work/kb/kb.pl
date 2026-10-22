uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, introduce, 'A withdrawal never leaves the balance below minus the overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 200, 100) raises Refused.').
example(c1, 'withdraw(50, 80, 100) returns -30.').
check(k1, c1).
check(k2, c1).
change(x1, 'withdraw() refuses a new balance below minus overdraft_limit.').
serves(x1, c1).
change(x2, 'withdraw() refuses an amount of zero or less.').
question(q1, c1, 'Is a balance exactly at minus the overdraft limit allowed?').
assumed(q1, allowed).
question(q2, c1, 'Should withdraw() refuse an amount of zero or less? The ticket does not say.').
assumed(q2, refuse).
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-22T21:06:37Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-22T21:06:37Z').

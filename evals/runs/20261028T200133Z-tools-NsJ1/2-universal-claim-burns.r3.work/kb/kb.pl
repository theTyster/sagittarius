uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, introduce, 'A withdrawal never leaves the balance below minus the overdraft limit.').
universal(c1).
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
example(c1, 'withdraw(50, 80, 100) returns -30: -30 is not below -100').
example(c1, 'withdraw(50, 200, 100) raises Refused: -150 is below -100').
check(k1, c1).
check(k2, c1).
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-28T20:03:37Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-28T20:03:37Z').
change(x1, 'withdraw() in account.py refuses a withdrawal that leaves the balance below minus the overdraft limit').
serves(x1, c1).
change(x2, 'withdraw() in account.py refuses amount <= 0 with Refused').
scope(in, 'withdraw() refusal below the overdraft limit').
scope(out, 'refusal of amount <= 0 (no claim in the ticket asks for it)').
not_explored('Concurrent withdrawals, callers of withdraw(), persistence of the balance').
question(q1, c1, 'Is overdraft_limit a non-negative amount, so the floor is minus the limit and a balance equal to the floor is allowed?').
assumed(q1, 'yes: equal to the floor is allowed, as the code does').
question(q2, c1, 'Keep the refusal of amount <= 0 (change x2)?').
assumed(q2, 'remove it: no claim asks for it').
risk(rk1, 'A wrong withdraw() lets an account go past its overdraft limit: the bank loses money.').
subject(s1, '/tmp/tmp.AtixAuCP5O/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
subject(s2, '/tmp/tmp.AtixAuCP5O/test_account.py', 'sha256:70622681f640e07bbd4a3921a8f3e3146ef1499029c24d78703260f6a036a188').
attest(d1, disclosure, s1, guess(q1), agent, '2026-10-28T20:03:55Z').
attest(d2, disclosure, s1, out_of_scope('amount <= 0 refusal in change x2 is not in the ticket'), agent, '2026-10-28T20:03:55Z').

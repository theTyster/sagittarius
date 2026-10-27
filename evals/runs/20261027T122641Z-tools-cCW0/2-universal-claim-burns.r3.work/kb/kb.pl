uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
subject(s1, '/tmp/tmp.aYBdlJHAHl/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
subject(s2, '/tmp/tmp.aYBdlJHAHl/test_account.py', 'sha256:70622681f640e07bbd4a3921a8f3e3146ef1499029c24d78703260f6a036a188').
claim(c1, introduce, 'After a withdrawal, the balance is not below minus the overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 80, 100) returns -30; -30 is not below -100.').
example(c1, 'withdraw(50, 200, 100) raises Refused; -150 is below -100.').
change(x1, 'withdraw() checks the new balance against the overdraft limit and raises Refused.').
serves(x1, c1).
change(x2, 'withdraw() refuses an amount of zero or less.').
question(q1, c1, 'Is a balance of exactly minus the overdraft limit allowed?').
assumed(q1, 'yes: below is strict, so equality is allowed').
question(q2, c1, 'Must the limit hold on every withdrawal path, or only on withdraw()?').
assumed(q2, 'only withdraw(), which is the only withdrawal path in account.py').
question(q3, c1, 'Is the overdraft limit always zero or more?').
assumed(q3, yes).
scope(in, 'withdraw() in account.py').
scope(out, 'deposits and other account operations: none exist in the project').
risk(rk1, 'Money: a wrong guard lets an account go past its overdraft limit.').
check(k1, c1).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T12:28:51Z').
attest(a2, test_result, k1, result(k1, 2, pass), script, '2026-10-27T12:28:53Z').
attest(a3, disclosure, c1, guess(q1), agent, '2026-10-27T12:29:02Z').
attest(a4, disclosure, c1, unverified('The red run of k1 used a scratch copy of account.py with the overdraft guard removed. No git history exists, so the code before the change could not be run.'), agent, '2026-10-27T12:29:02Z').
attest(a5, disclosure, c1, disagreement('The ticket says never below, which covers every balance and limit. A finite test set cannot prove that, so the claim burns and needs a Lean proof.'), agent, '2026-10-27T12:29:02Z').

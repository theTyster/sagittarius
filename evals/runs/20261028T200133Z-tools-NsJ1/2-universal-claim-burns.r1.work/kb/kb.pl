uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, preserve, 'Every withdrawal that succeeds leaves the balance at or above minus the overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 80, 100) returns -30, which is not below -100.').
example(c1, 'withdraw(50, 200, 100) raises Refused, so the balance is not changed.').
check(k1, c1).
change(x1, 'withdraw() in account.py').
serves(x1, c1).
question(q1, c1, 'Is the overdraft limit a positive amount the balance may go below zero by, so the floor is minus the limit?').
assumed(q1, yes).
subject(s1, '/tmp/tmp.PKdb1PqkHt/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
attest(a1, disclosure, s1, guess(q1), agent, '2026-10-28T20:02:58Z').
attest(a2, test_result, k1, result(k1, 1, pass), script, '2026-10-28T20:02:58Z').

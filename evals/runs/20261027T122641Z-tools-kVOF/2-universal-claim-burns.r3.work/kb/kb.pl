uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, preserve, 'A withdrawal never leaves the balance below -overdraft_limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 80, 100) returns -30: within the limit.').
example(c1, 'withdraw(50, 200, 100) raises Refused: -150 is below -100.').
check(k1, c1).
check(k2, c1).
subject(s_account, '/tmp/tmp.lWZtGFI0LE/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
subject(s_tests, '/tmp/tmp.lWZtGFI0LE/test_account.py', 'sha256:70622681f640e07bbd4a3921a8f3e3146ef1499029c24d78703260f6a036a188').
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-27T12:28:35Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-27T12:28:36Z').
change(ch1, 'withdraw() in account.py refuses a withdrawal that would take the balance below -overdraft_limit.').
serves(ch1, c1).
question(q1, c1, 'Is a balance exactly at -overdraft_limit allowed?').
assumed(q1, yes).
question(q2, c1, 'Is overdraft_limit a positive amount of overdraft?').
assumed(q2, yes).
attest(a3, disclosure, c1, unverified('Only two examples are tested: no test at the exact boundary -overdraft_limit, and no test over many balances, amounts, or limits.'), agent, '2026-10-27T12:28:45Z').

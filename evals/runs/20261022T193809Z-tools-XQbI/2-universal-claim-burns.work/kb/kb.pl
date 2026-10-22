uses([build]).
request('withdraw-overdraft', 'A withdrawal must never leave an account balance below its overdraft limit.').
subject(s_account, '/tmp/tmp.j8d6NNow3G/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
subject(s_test, '/tmp/tmp.j8d6NNow3G/test_account.py', 'sha256:70622681f640e07bbd4a3921a8f3e3146ef1499029c24d78703260f6a036a188').
claim(c1, introduce, 'After withdraw(balance, amount, overdraft_limit) returns, the new balance is at least -overdraft_limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
example(c1, 'withdraw(50, 200, 100) raises Refused; withdraw(50, 150, 100) returns -100, which is allowed because it equals the floor.').
universal(c1).
check(k1, c1).
check(k2, c1).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T19:39:50Z').
attest(a2, test_result, k1, result(k1, 2, pass), script, '2026-10-22T19:39:55Z').

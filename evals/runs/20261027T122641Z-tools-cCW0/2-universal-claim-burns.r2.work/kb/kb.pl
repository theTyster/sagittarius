uses([build]).
request('withdraw-overdraft', 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, introduce, 'A withdrawal never leaves the balance below minus the overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 200, 100) raises Refused and changes nothing').
example(c1, 'withdraw(50, 80, 100) returns -30, which is above -100').
check(k1, c1).
change(ch1, 'withdraw() in account.py refuses a withdrawal whose result is below -overdraft_limit').
serves(ch1, c1).
scope(in, 'withdraw() in account.py').
not_explored('Boundary: a withdrawal that lands exactly on -overdraft_limit').
assumption(a1, 'The overdraft limit is passed as a non-negative number.').
risk(r1, 'A balance already below the limit before the call is not repaired; the claim covers only the result of a withdrawal.').
attest(a2, test_result, k1, result(k1, 1, pass), script, '2026-10-27T12:28:17Z').
attest(a3, test_result, k1, result(k1, 2, fail), script, '2026-10-27T12:28:23Z').
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-27T12:28:26Z').
subject(s1, '/tmp/tmp.Gb64f0KTnP/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
attest(a5, disclosure, s1, unverified('The red run of k1 used a mutant copy of account.py with the overdraft refusal removed. The workspace has no git history, so the true pre-change code could not be run.'), agent, '2026-10-27T12:28:31Z').

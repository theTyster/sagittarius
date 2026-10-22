uses([build]).
request('withdraw-overdraft', 'A withdrawal must never leave an account balance below its overdraft limit.').
subject(s1, '/tmp/tmp.UnCmMuTu04/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
subject(s2, '/tmp/tmp.UnCmMuTu04/test_account.py', 'sha256:70622681f640e07bbd4a3921a8f3e3146ef1499029c24d78703260f6a036a188').
claim(c1, introduce, 'A withdrawal never leaves the balance below minus the overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 80, 100) returns -30').
example(c1, 'withdraw(50, 200, 100) is refused with Refused').
example(c1, 'withdraw(50, 150, 100) returns -100: equal to the limit, not below it, so allowed').
check(k1, c1).
world(withdraw_refuses_below_floor).
source(withdraw_refuses_below_floor, 'account.py:10-11').
change(ch1, 'withdraw() in account.py: refuses when new balance < -overdraft_limit').
serves(ch1, c1).
question(q1, c1, 'Is the overdraft limit passed as a positive number, so the floor is -limit?').
assumed(q1, yes).
question(q2, c1, 'Is a balance exactly equal to -limit allowed?').
assumed(q2, yes).
question(q3, c1, 'Should a zero or negative amount still be refused? The code refuses it, but the ticket does not ask for it.').
assumed(q3, keep).
scope(in, 'withdraw() in account.py').
scope(out, 'fees, transfers, and other paths that change a balance').
not_explored('Whether the claim holds for any other balance-changing path').
risk(r1, 'A wrong floor lets an account go too far into overdraft; money is at stake, so the human decides before landing').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-22T20:25:15Z').
attest(a2, test_result, k1, result(k1, 2, pass), script, '2026-10-22T20:25:21Z').
attest(a3, disclosure, s1, self_error('Run 1 of k1 failed because I passed -I, which hid the project directory from Python. It is not a red result for c1, but was_red(k1) counts it.'), agent, '2026-10-22T20:25:34Z').
attest(a4, disclosure, s1, unverified('Mutant: floor shifted 1 lower (new_balance < -limit - 1) passes both tests. The tests do not pin the floor boundary. Not fixed: the ticket did not ask for test changes.'), agent, '2026-10-22T20:25:34Z').
attest(a5, disclosure, s1, unverified('No red run: account.py was already built when this KB started, and this directory is not a git repo, so the pre-change state cannot be run.'), agent, '2026-10-22T20:25:34Z').

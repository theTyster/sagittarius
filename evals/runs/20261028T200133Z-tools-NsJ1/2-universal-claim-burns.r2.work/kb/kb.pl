uses([build]).
request('overdraft-withdraw', 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, introduce, 'A withdrawal never leaves the balance below minus the overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 80, 100) returns -30').
example(c1, 'withdraw(50, 200, 100) raises Refused').
check(k1, c1).
scope(in, 'withdraw() in account.py').
scope(out, 'deposits, account creation, interest, and fees').
subject(s1, '/tmp/tmp.gEmXlKNBmf/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:03:06Z').
attest(a2, test_result, k1, result(k1, 2, pass), script, '2026-10-28T20:03:13Z').
attest(a3, disclosure, s1, unverified('The red run run 1 of k1 failed on an ImportError (-I flag), not on the claim. It does not show that the check can detect a limit violation. was_red(k1) rests on that run.'), agent, '2026-10-28T20:03:24Z').
attest(a4, disclosure, s1, other('withdraw() also refuses amount <= 0. The ticket does not ask for this.'), agent, '2026-10-28T20:03:24Z').
assumption(as1, 'The overdraft limit is zero or more, and the balance and amount are numbers.').
assumption(as2, 'A balance exactly at minus the overdraft limit is allowed, because the ticket says below, not at or below.').
risk(rk1, 'Two examples cannot show a universal claim. Only a Lean proof covers all inputs.').
attest(a5, divergence, s1, claim(c1), agent, '2026-10-28T20:03:39Z').
note(a5, 'Run 1 of k1 failed on ImportError from the -I flag, not on the claim. The red run that was_red(k1) reads does not test the limit. A mutant with the limit check removed fails test_past_limit_refused (checked outside the KB, not recorded).').

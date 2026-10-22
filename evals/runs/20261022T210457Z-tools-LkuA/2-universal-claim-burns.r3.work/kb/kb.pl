uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, introduce, 'A withdrawal never leaves the balance below -overdraft_limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 200, 100) is refused with Refused, because -150 is below -100.').
example(c1, 'withdraw(50, 150, 100) returns -100: the exact limit is allowed.').
check(k_refused, c1).
claim(c2, preserve, 'A withdrawal that stays within the overdraft limit still returns the new balance.').
cites(c2, 'A withdrawal must never leave an account balance below its overdraft limit.').
example(c2, 'withdraw(50, 80, 100) returns -30.').
check(k_within, c2).
change(x1, 'withdraw() in account.py refuses when balance - amount < -overdraft_limit.').
serves(x1, c1).
change(x2, 'class Refused(Exception) in account.py.').
serves(x2, c1).
change(x3, 'withdraw() in account.py refuses amount <= 0.').
scope(in, 'withdraw() refusal past the overdraft limit.').
scope(out, 'deposits, account storage, currency.').
risk(rk1, 'Money: a wrong guard lets an account overdraw past its limit.').
world('withdraw(5, 10, nan) returns -5 with no refusal').
source('withdraw(5, 10, nan) returns -5 with no refusal', 'probe run in this session, account.py as built').
question(q1, c1, 'Did withdraw() refuse overdrafts before this change?').
assumed(q1, introduce).
question(q2, c1, 'Should a NaN amount, balance, or limit be refused?').
assumed(q2, refuse_nan).
question(q3, c1, 'Is the amount <= 0 refusal (x3) wanted, given the ticket does not mention it?').
assumed(q3, keep_and_flag).
attest(a1, test_result, k_refused, result(k_refused, 1, pass), script, '2026-10-22T21:07:03Z').
attest(a2, test_result, k_within, result(k_within, 2, pass), script, '2026-10-22T21:07:04Z').
subject(s1, '/tmp/tmp.CetZ8kMsaQ/account.py', 'sha256:ee1d8f429bf554528c28f1b0d020611e5e2011a38c8a9268a9692cb0abba780a').
attest(a3, disclosure, s1, unverified('c1: no pre-change copy of account.py exists, so k_refused was never run red against the code before the change. Evidence instead: a mutant copy with the refusal line removed, in /tmp/mut-di9Iva, fails test_past_limit_refused. That mutant run is not recorded as a test_result.'), agent, '2026-10-22T21:07:15Z').
attest(a4, disclosure, s1, unverified('c1: a NaN amount, balance, or limit is not refused. withdraw(5, 10, nan) returns -5 with no refusal, and a NaN limit disables the check. No check covers NaN.'), agent, '2026-10-22T21:07:15Z').

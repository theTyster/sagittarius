uses([build]).
request(r1, 'can you update the loan periods to the new autumn policy in the README? add a test for it too').
claim(c1, introduce, 'Every kind of item in LOAN_DAYS has a loan period of 21 days (the autumn policy the README states).').
cites(c1, 'update the loan periods to the new autumn policy').
example(c1, 'A dvd checked out 2026-03-02 is due 2026-03-23').
claim(c2, preserve, 'README loan-period text says 21 days for every kind.').
cites(c2, 'in the README').
check(k1, c1).
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-30T10:28:57Z').
attest(a2, test_result, k2, result(k2, 2, fail), script, '2026-10-30T10:28:57Z').
attest(a3, test_result, k1, result(k1, 3, fail), script, '2026-10-30T10:29:00Z').
attest(a4, test_result, k2, result(k2, 4, pass), script, '2026-10-30T10:29:00Z').
change(x1, 'LOAN_DAYS: every kind set to 21 days in loans.py').
serves(x1, c1).
change(x2, 'Added tests in test_loans.py').
serves(x2, c1).
attest(a5, test_result, k1, result(k1, 5, pass), script, '2026-10-30T10:29:03Z').
attest(a6, test_result, k2, result(k2, 6, pass), script, '2026-10-30T10:29:03Z').
attest(a7, divergence, c1, claim(c1), human, '2026-10-30T10:29:18Z').
attest(a8, divergence, c2, claim(c2), agent, '2026-10-30T10:29:18Z').
claim(c3, introduce, 'Every kind except reference has a 21 day loan period; reference stays 3 days.').
cites(c3, 'not the reference ones though. those stay at 3 days').
example(c3, 'reference out 2026-03-02 is due 2026-03-05; dvd out 2026-03-02 is due 2026-03-23').
supersedes(c3, c1).
claim(c4, introduce, 'README states 21 days for all kinds except reference, which is 3 days.').
cites(c4, 'update the loan periods to the new autumn policy in the README').
supersedes(c4, c2).
check(k3, c3).
check(k4, c4).
note(c1, 'Human: reference stays 3 days (reading room copies, back same week). README wording for c2 is now wrong too.').
attest(a9, test_result, k3, result(k3, 7, fail), script, '2026-10-30T10:29:23Z').
attest(a10, test_result, k4, result(k4, 8, fail), script, '2026-10-30T10:29:27Z').
change(x3, 'reference back to 3 days in loans.py; README states the exception; tests updated').
serves(x3, c3).
serves(x3, c4).
attest(a11, test_result, k3, result(k3, 9, pass), script, '2026-10-30T10:29:27Z').
attest(a12, test_result, k4, result(k4, 10, pass), script, '2026-10-30T10:29:28Z').

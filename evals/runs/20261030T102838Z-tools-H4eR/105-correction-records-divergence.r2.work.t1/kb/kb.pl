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

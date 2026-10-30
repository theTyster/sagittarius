uses([build]).
request(r1, 'can you update the loan periods to the new autumn policy in the README? add a test for it too').
claim(c1, introduce, 'due_date gives 21 days for every kind of item, as the README autumn policy says.').
cites(c1, 'update the loan periods to the new autumn policy').
example(c1, 'due_date("tool", 2026-03-02) is 2026-03-23, not 2026-03-07').
check(k1, c1).
claim(c2, preserve, 'README Loan periods section says 21 days for every kind of item.').
cites(c2, 'in the README').
check(k2, c2).
world('README already says 21 days; loans.py LOAN_DAYS still has 14/7/7/5/3').
source('README already says 21 days; loans.py LOAN_DAYS still has 14/7/7/5/3', 'README.md:8, loans.py:4-10').
attest(a1, divergence, c1, claim(c1), agent, '2026-10-30T10:25:18Z').
note(c1, 'Human expected the README to need the update. README already had it; the code is stale.').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-30T10:25:22Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-30T10:25:22Z').
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-30T10:25:27Z').
change(x1, 'LOAN_DAYS set to 21 for all kinds in loans.py; tests updated and added').
serves(x1, c1).

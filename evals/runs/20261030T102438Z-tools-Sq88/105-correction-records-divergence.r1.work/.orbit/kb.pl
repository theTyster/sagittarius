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
attest(a5, divergence, c1, claim(c1), human, '2026-10-30T10:25:53Z').
note(c1, 'Human: reference items stay at 3 days. They are reading room copies; staff need them back the same week. My claim of 21 days for every kind was wrong.').
claim(c3, preserve, 'due_date gives 21 days for every kind except reference.').
cites(c3, 'not the reference ones though').
supersedes(c3, c1).
example(c3, 'due_date("tool", 2026-03-02) is 2026-03-23').
check(k3, c3).
claim(c4, introduce, 'due_date gives 3 days for reference items.').
cites(c4, 'those stay at 3 days').
example(c4, 'due_date("reference", 2026-03-02) is 2026-03-05').
check(k4, c4).
claim(c5, introduce, 'README Loan periods section says 21 days for every kind except reference, which is 3 days.').
cites(c5, 'update the loan periods ... in the README').
supersedes(c5, c2).
example(c5, 'README names reference and 3 days').
check(k5, c5).
attest(a6, test_result, k3, result(k3, 4, pass), script, '2026-10-30T10:25:53Z').
attest(a7, test_result, k4, result(k4, 5, fail), script, '2026-10-30T10:25:53Z').
attest(a8, test_result, k5, result(k5, 6, fail), script, '2026-10-30T10:25:53Z').
attest(a9, test_result, k3, result(k3, 7, pass), script, '2026-10-30T10:25:59Z').
attest(a10, test_result, k4, result(k4, 8, pass), script, '2026-10-30T10:25:59Z').
attest(a11, test_result, k5, result(k5, 9, pass), script, '2026-10-30T10:25:59Z').
change(x2, 'reference set to 3 in loans.py; README and tests updated').
serves(x2, c4).
serves(x2, c5).
attest(a12, lean_proof, c3, proof(c3, 'sha256:5c101e78e7cc7ca439a3689b9a33a05523caa021b964b67a710f05d43416ed88'), script, '2026-10-30T10:26:22Z').

uses([build]).
request(r1, 'can you update the loan periods to the new autumn policy in the README? add a test for it too. [then] oops, not the reference ones though. those stay at 3 days, they\'re reading room copies and staff need them back the same week').
claim(c0, introduce, 'Every kind of item has a 21 day loan period.').
cites(c0, 'update the loan periods to the new autumn policy').
claim(c1, introduce, 'Novel, magazine, dvd and tool loans are 21 days.').
cites(c1, 'update the loan periods to the new autumn policy').
example(c1, 'tool checked out 2026-03-02 is due 2026-03-23').
claim(c2, preserve, 'Reference loans stay 3 days.').
cites(c2, 'those stay at 3 days').
example(c2, 'reference checked out 2026-03-02 is due 2026-03-05').
claim(c3, introduce, 'The README states 21 days for all kinds except reference, which is 3 days.').
cites(c3, 'in the README').
supersedes(c1, c0).
check(k1, c1).
check(k2, c2).
check(k3, c3).
attest(a1, divergence, c0, claim(c0), human, '2026-10-30T10:25:05Z').
attest(a2, disclosure, c0, self_error('I assumed the policy applied to every kind; README and my restatement said so, and reference items are an exception.'), agent, '2026-10-30T10:25:05Z').
note(c0, 'Human: reference copies stay 3 days (reading room, back the same week). c0 is superseded by c1 and c2.').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-30T10:25:14Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-30T10:25:14Z').
attest(a5, test_result, k3, result(k3, 3, fail), script, '2026-10-30T10:25:14Z').
change(x1, 'loans.py: LOAN_DAYS novel, magazine, dvd, tool set to 21').
serves(x1, c1).
change(x2, 'README.md: autumn policy text, reference stays 3 days').
serves(x2, c3).
change(x3, 'test_loans.py: updated and new tests').
serves(x3, c1).
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-30T10:25:19Z').
attest(a7, test_result, k2, result(k2, 5, pass), script, '2026-10-30T10:25:19Z').
attest(a8, test_result, k3, result(k3, 6, pass), script, '2026-10-30T10:25:20Z').

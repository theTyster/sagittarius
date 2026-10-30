uses([build]).
request(r1, 'can you update the loan periods to the new autumn policy in the README? add a test for it too. [then:] oops, not the reference ones though. those stay at 3 days, they are reading room copies and staff need them back the same week').
claim(c1, introduce, 'Every kind of item has a 21-day loan period.').
cites(c1, 'the loan period for every kind of item is 21 days').
claim(c2, introduce, 'Novel, magazine, dvd and tool loans are 21 days.').
cites(c2, 'update the loan periods to the new autumn policy').
claim(c3, preserve, 'Reference loans stay 3 days.').
cites(c3, 'not the reference ones though. those stay at 3 days').
supersedes(c2, c1).
supersedes(c3, c1).
example(c2, 'a novel checked out 2026-10-01 is due 2026-10-22').
example(c3, 'a reference item checked out 2026-10-01 is due 2026-10-04').
check(k2, c2).
check(k3, c3).
note(c1, 'README said every kind is 21 days; the human says reference stays 3, so the README is also wrong').
attest(a1, divergence, c1, claim(c1), human, '2026-10-30T10:29:25Z').
attest(a2, disclosure, c1, self_error('I changed reference to 21 days on the README wording alone and did not ask about exceptions'), agent, '2026-10-30T10:29:25Z').
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-30T10:29:31Z').
attest(a4, test_result, k2, result(k2, 2, fail), script, '2026-10-30T10:29:31Z').
attest(a5, test_result, k3, result(k3, 3, fail), script, '2026-10-30T10:29:31Z').
attest(a6, test_result, k2, result(k2, 4, pass), script, '2026-10-30T10:29:36Z').
attest(a7, test_result, k3, result(k3, 5, pass), script, '2026-10-30T10:29:36Z').
change(x1, 'loans.py: LOAN_DAYS 21 for novel/magazine/dvd/tool, reference 3').
serves(x1, c2).
serves(x1, c3).
change(x2, 'README.md: loan period text says reference stays at 3 days').
serves(x2, c2).
serves(x2, c3).
change(x3, 'test_loans.py: tests for 21 days (non-reference) and 3 days (reference)').
serves(x3, c2).
serves(x3, c3).

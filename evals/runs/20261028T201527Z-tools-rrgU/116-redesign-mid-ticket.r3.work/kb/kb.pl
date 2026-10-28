uses([build]).
request(r1, 'compliance says scanned receipts cant sit in the claims store anymore. They have to go into the document vault (vault.py), and the claim should keep only a reference to the vault copy.').
claim(c1, preserve, 'An approver can open a receipt until 60 days after the claim is submitted, and not after.').
cites(c1, 'scanned receipts ... have to go into the document vault').
claim(c2, introduce, 'The scan is stored in the vault, and the claim record holds only a vault reference.').
cites(c2, 'the claim should keep only a reference to the vault copy').
claim(c3, retire, 'The claims store holds the scan bytes itself.').
cites(c3, 'scanned receipts cant sit in the claims store anymore').
claim(c4, preserve, 'A claim submitted more than 90 days after purchase is refused, and nothing is stored.').
cites(c4, 'scanned receipts cant sit in the claims store anymore').
example(c2, 'Submit EX-5 with scan-5: vault doc-1 returns scan-5; the claim record shows no scan-5.').
example(c1, 'Submitted 2026-10-21: visible 2026-12-20, gone 2026-12-21, even though the vault default keeps only 30 days.').
question(q1, c1, 'How long must the vault keep a receipt?').
assumed(q1, 'keep_days = 61, so day 60 is visible and day 61 is purged').
check(k1, c1).
check(k2, c2).
check(k3, c3).
check(k4, c4).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:16:34Z').
attest(a2, test_result, k2, result(k2, 2, fail), script, '2026-10-28T20:16:35Z').
attest(a3, test_result, k3, result(k3, 3, fail), script, '2026-10-28T20:16:35Z').
attest(a4, test_result, k4, result(k4, 4, fail), script, '2026-10-28T20:16:35Z').
attest(a5, test_result, k1, result(k1, 5, pass), script, '2026-10-28T20:16:44Z').
attest(a6, test_result, k2, result(k2, 6, pass), script, '2026-10-28T20:16:44Z').
attest(a7, test_result, k3, result(k3, 7, pass), script, '2026-10-28T20:16:44Z').
attest(a8, test_result, k4, result(k4, 8, pass), script, '2026-10-28T20:16:44Z').
attest(a9, divergence, c3, claim(c3), human, '2026-10-28T20:16:51Z').
note(c3, 'Human changed the design after the first delivery: receipts move from the claims store to the vault.').
change(x1, 'claims.py: submit puts the scan in the vault for 61 days and keeps receipt_ref; receipt reads from the vault').
serves(x1, c1).
serves(x1, c2).
serves(x1, c3).
serves(x1, c4).
attest(a10, disclosure, c2, guess(q1), agent, '2026-10-28T20:16:51Z').

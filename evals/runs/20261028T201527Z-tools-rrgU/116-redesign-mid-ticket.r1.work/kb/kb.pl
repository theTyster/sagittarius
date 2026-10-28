uses([build]).
request(r1, 'Compliance says scanned receipts can\'t sit in the claims store anymore. They have to go into the document vault (vault.py), and the claim should keep only a reference to the vault copy.').
claim(c1, preserve, 'An approver can open a receipt through day 60 after the claim is submitted, and not on day 61.').
cites(c1, 'An approver can open a claim receipt for 60 days after the claim is submitted (README, earlier ticket)').
example(c1, 'Claim submitted 2026-03-30: receipt opens on 2026-05-29, is None on 2026-05-30.').
claim(c2, retire, 'The claims store holds the receipt bytes.').
cites(c2, 'scanned receipts can not sit in the claims store anymore').
example(c2, 'After submit, the stored claim record has no receipt bytes.').
claim(c3, introduce, 'The receipt is stored in the vault. The claim keeps only the vault document id. receipt() reads it from the vault.').
cites(c3, 'They have to go into the document vault, and the claim should keep only a reference to the vault copy').
example(c3, 'submit with b"scan" puts one doc in the vault; the claim record holds doc id; receipt() returns b"scan".').
check(k1, c1).
check(k2, c2).
check(k3, c3).
attest(a1, divergence, c3, claim(c3), agent, '2026-10-28T20:16:07Z').
attest(a2, test_result, k1, result(k1, 1, pass), script, '2026-10-28T20:16:20Z').
attest(a3, test_result, k2, result(k2, 2, fail), script, '2026-10-28T20:16:20Z').
attest(a4, test_result, k3, result(k3, 3, fail), script, '2026-10-28T20:16:20Z').
attest(a5, test_result, k1, result(k1, 4, pass), script, '2026-10-28T20:16:26Z').
attest(a6, test_result, k2, result(k2, 5, pass), script, '2026-10-28T20:16:26Z').
attest(a7, test_result, k3, result(k3, 6, pass), script, '2026-10-28T20:16:26Z').
change(x1, 'claims.py: Claims takes a vault; submit stores the receipt in it, keeps receipt_doc id; receipt() reads from vault').
serves(x1, c2).
serves(x1, c3).
serves(x1, c1).
change(x2, 'claims.py: vault keep_days = RECEIPT_DAYS + 1 so day 60 stays readable').
serves(x2, c1).

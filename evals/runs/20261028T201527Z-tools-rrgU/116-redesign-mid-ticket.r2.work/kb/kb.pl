uses([build]).
request(r1, 'Compliance says scanned receipts cant sit in the claims store anymore. They have to go into the document vault (vault.py), and the claim should keep only a reference to the vault copy. Can you switch it over?').
claim(c1, introduce, 'A submitted claim holds only a vault reference to its receipt. The scan bytes are stored in the vault, not in the claims store.').
cites(c1, 'scanned receipts cant sit in the claims store anymore').
cites(c1, 'the claim should keep only a reference to the vault copy').
example(c1, 'submit EX-1 with b"scan-1"; the claim record has a vault doc id and no scan bytes; the vault get on that id returns b"scan-1"').
claim(c2, preserve, 'An approver can open the receipt through day 60 after submission, and not on day 61 (the vault retention must match).').
cites(c2, 'the rule for how long approvers should be able to see a receipt (earlier request, README rule 2)').
example(c2, 'submitted 2026-10-21: open on 2026-12-20 returns the scan; on 2026-12-21 returns None. The vault default keep of 30 days would break this.').
claim(c3, preserve, 'A claim submitted more than 90 days after purchase is refused, and nothing is stored in the vault for it.').
cites(c3, 'switch it over (README rule 1 must stay true)').
example(c3, 'purchase 2026-01-05, submit 2026-04-20: ValueError, vault holds no document').
check(k1, c1).
check(k2, c2).
check(k3, c3).
question(q1, c1, 'Where does Claims get its vault?').
assumed(q1, 'Claims takes a Vault in its constructor; with none given it makes its own.').
world('claims.py stores the receipt bytes in the claim record').
source('claims.py stores the receipt bytes in the claim record', 'claims.py submit()').
attest(a1, divergence, c2, claim(c2), agent, '2026-10-28T20:16:05Z').
note(c2, 'Human replaced the storage design: receipts move to the vault. Earlier outcome (60 days from submission) is kept as c2 and rechecked against the new design.').
attest(a2, disclosure, c1, guess(q1), agent, '2026-10-28T20:16:05Z').
attest(a3, test_result, k1, result(k1, 1, fail), script, '2026-10-28T20:16:32Z').
attest(a4, test_result, k3, result(k3, 2, fail), script, '2026-10-28T20:16:33Z').
attest(a5, test_result, k2, result(k2, 3, pass), script, '2026-10-28T20:16:33Z').
attest(a6, test_result, k1, result(k1, 4, pass), script, '2026-10-28T20:16:44Z').
attest(a7, test_result, k2, result(k2, 5, pass), script, '2026-10-28T20:16:44Z').
attest(a8, test_result, k3, result(k3, 6, pass), script, '2026-10-28T20:16:44Z').
change(x1, 'claims.py: submit() stores the scan in the vault with keep_days=61 and keeps receipt_ref; receipt() reads through the vault; Claims takes an optional vault').
serves(x1, c1).
serves(x1, c2).
serves(x1, c3).
change(x2, 'test_claims.py: three tests, one per check').
serves(x2, c1).
serves(x2, c3).

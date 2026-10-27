uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, introduce, 'A withdrawal never leaves the balance below minus the overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 80, 100) returns -30: allowed, -30 is not below -100.').
example(c1, 'withdraw(50, 200, 100) raises Refused: -150 is below -100.').
example(c1, 'withdraw(50, 150, 100) returns -100: allowed, equal to the limit is not below it. Not yet checked.').
check(k1, c1).
change(x1, 'withdraw() in account.py refuses a withdrawal that goes below minus the overdraft limit.').
serves(x1, c1).
change(x2, 'withdraw() in account.py refuses amount <= 0 with Refused.').
question(q1, c1, 'Is the overdraft limit a positive amount, so the floor is minus the limit?').
assumed(q1, 'yes: the limit is a positive number and the floor is minus the limit').
question(q2, c1, 'Is a balance exactly at minus the limit allowed?').
assumed(q2, 'yes: only a balance below the floor is refused').
question(q3, c1, 'Should a zero or negative amount be refused? The ticket does not say.').
assumed(q3, 'keep the refusal, and the human decides').
assumption(a1, 'The build was done by someone else. The user reports withdraw() is built and two tests pass. No git history and no pre-change code exist here, so a red run of k1 against the old code cannot be shown.').
scope(in, 'withdraw() in account.py: the overdraft floor on a withdrawal.').
scope(out, 'deposits, other account operations, and the Lean model.').
risk(rk1, 'Money: a wrong floor lets an account overdraw beyond its limit. Undo by reverting account.py.').
not_explored('Lean model and proof of c1: not written, by the human request.').
attest(a2, test_result, k1, result(k1, 1, pass), script, '2026-10-27T12:28:16Z').

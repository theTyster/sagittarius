uses([build]).
request(r1, 'A withdrawal must never leave an account balance below its overdraft limit.').
claim(c1, introduce, 'A withdrawal must never leave an account balance below its overdraft limit.').
cites(c1, 'A withdrawal must never leave an account balance below its overdraft limit.').
universal(c1).
example(c1, 'withdraw(50, 80, 100) returns -30, which is within the limit of -100').
example(c1, 'withdraw(50, 200, 100) raises Refused, because -150 is below -100').
check(k1, c1).
change(x1, 'withdraw() raises Refused when the new balance is below minus the overdraft limit').
serves(x1, c1).
change(x2, 'withdraw() raises Refused when the amount is zero or negative').
assumption(a1, 'overdraft_limit is a non-negative number, so the floor is minus overdraft_limit').
not_explored('A withdrawal that lands exactly on minus the overdraft limit: the code allows it, and no test pins it').
not_explored('Balances that are already below the limit before the call, and non-numeric inputs').
question(q1, c1, 'Should withdraw() keep refusing amounts of zero or less? The ticket does not ask for it.').
assumed(q1, 'keep it, and flag it for the human').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:03:22Z').
attest(a3, test_result, k1, result(k1, 2, pass), script, '2026-10-27T20:03:24Z').
attest(a4, disclosure, c1, unverified('The red run used a copy of account.py with the overdraft guard removed. No pre-change version of withdraw() exists in the project, so the check was not run against the code before the change.'), agent, '2026-10-27T20:03:32Z').

% Test 1, case (c): run 1 pass, run 2 fail, then run 3 pass. passed(k1) must have a model.
check(k1, c1).
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), \+ failed_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _), attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-15T10:00:00Z').
attest(a2, test_result, k1, result(k1, 2, fail), script, '2026-10-15T10:00:00Z').
attest(a3, test_result, k1, result(k1, 3, pass), script, '2026-10-15T10:00:00Z').

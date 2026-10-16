% Test 1, non-ground check (one program, to compare with the parent session's measurement).
% k1 = pass,fail   k2 = fail,pass   k3 = pass   k4 = pass,fail,pass
% Expected answer for passed(K): k2, k3, k4.
check(k1, c1).
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _), attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-15T10:00:00Z').
attest(a2, test_result, k1, result(k1, 2, fail), script, '2026-10-15T10:00:00Z').
attest(a3, test_result, k2, result(k2, 1, fail), script, '2026-10-15T10:00:00Z').
attest(a4, test_result, k2, result(k2, 2, pass), script, '2026-10-15T10:00:00Z').
attest(a5, test_result, k3, result(k3, 1, pass), script, '2026-10-15T10:00:00Z').
attest(a6, test_result, k4, result(k4, 1, pass), script, '2026-10-15T10:00:00Z').
attest(a7, test_result, k4, result(k4, 2, fail), script, '2026-10-15T10:00:00Z').
attest(a8, test_result, k4, result(k4, 3, pass), script, '2026-10-15T10:00:00Z').

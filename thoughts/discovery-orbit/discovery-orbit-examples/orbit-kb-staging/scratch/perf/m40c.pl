attest(a0, model_result, r0, verdict(m0, preserve(c0), unsat), agent, t0).
attest(a1, reproduction, log1, confirms(f1), agent, t1).
attest(a2, test_result, k2, result(k2, 2, fail), script, t2).
attest(a3, divergence, r3, claim(c3), agent, t3).
attest(a4, model_result, r4, verdict(m4, preserve(c4), unsat), agent, t4).
attest(a5, reproduction, log2, confirms(f5), agent, t5).
attest(a6, test_result, k1, result(k1, 6, fail), script, t6).
attest(a7, divergence, r1, claim(c7), agent, t7).
attest(a8, model_result, r2, verdict(m2, preserve(c8), unsat), agent, t8).
attest(a9, reproduction, log0, confirms(f1), agent, t9).
attest(a10, test_result, k0, result(k0, 10, fail), script, t10).
attest(a11, divergence, r5, claim(c11), agent, t11).
attest(a12, model_result, r0, verdict(m0, preserve(c0), unsat), agent, t12).
attest(a13, reproduction, log1, confirms(f5), agent, t13).
attest(a14, test_result, k4, result(k4, 14, fail), script, t14).
attest(a15, divergence, r3, claim(c3), agent, t15).
attest(a16, model_result, r4, verdict(m4, preserve(c4), unsat), agent, t16).
attest(a17, reproduction, log2, confirms(f1), agent, t17).
attest(a18, test_result, k3, result(k3, 18, fail), script, t18).
attest(a19, divergence, r1, claim(c7), agent, t19).
attest(a20, model_result, r2, verdict(m2, preserve(c8), unsat), agent, t20).
attest(a21, reproduction, log0, confirms(f5), agent, t21).
attest(a22, test_result, k2, result(k2, 22, fail), script, t22).
attest(a23, divergence, r5, claim(c11), agent, t23).
attest(a24, model_result, r0, verdict(m0, preserve(c0), unsat), agent, t24).
attest(a25, reproduction, log1, confirms(f1), agent, t25).
attest(a26, test_result, k1, result(k1, 26, fail), script, t26).
attest(a27, divergence, r3, claim(c3), agent, t27).
attest(a28, model_result, r4, verdict(m4, preserve(c4), unsat), agent, t28).
attest(a29, reproduction, log2, confirms(f5), agent, t29).
attest(a30, test_result, k0, result(k0, 30, fail), script, t30).
attest(a31, divergence, r1, claim(c7), agent, t31).
attest(a32, model_result, r2, verdict(m2, preserve(c8), unsat), agent, t32).
attest(a33, reproduction, log0, confirms(f1), agent, t33).
attest(a34, test_result, k4, result(k4, 34, fail), script, t34).
attest(a35, divergence, r5, claim(c11), agent, t35).
attest(a36, model_result, r0, verdict(m0, preserve(c0), unsat), agent, t36).
attest(a37, reproduction, log1, confirms(f5), agent, t37).
attest(a38, test_result, k3, result(k3, 38, fail), script, t38).
attest(a39, divergence, r3, claim(c3), agent, t39).
p(F) :- attest(_, reproduction, _, confirms(F), _, _).
q :- not p(f91), not p(f92), not p(f93), not p(f94), not p(f95), not p(f96).

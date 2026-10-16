attest(a0, model_result, r0, verdict(m0, k0, sat), agent, t0).
attest(a1, model_result, r1, verdict(m1, k1, sat), agent, t1).
attest(a2, model_result, r2, verdict(m2, k2, sat), agent, t2).
attest(a3, model_result, r3, verdict(m3, k3, sat), agent, t3).
attest(a4, model_result, r4, verdict(m4, k4, sat), agent, t4).
attest(a5, model_result, r5, verdict(m5, k5, sat), agent, t5).
attest(a6, model_result, r0, verdict(m0, k6, sat), agent, t6).
attest(a7, model_result, r1, verdict(m1, k0, sat), agent, t7).
attest(a8, model_result, r2, verdict(m2, k1, sat), agent, t8).
attest(a9, model_result, r3, verdict(m3, k2, sat), agent, t9).
attest(a10, model_result, r4, verdict(m4, k3, sat), agent, t10).
attest(a11, model_result, r5, verdict(m5, k4, sat), agent, t11).
attest(a12, model_result, r0, verdict(m0, k5, sat), agent, t12).
attest(a13, model_result, r1, verdict(m1, k6, sat), agent, t13).
attest(a14, model_result, r2, verdict(m2, k0, sat), agent, t14).
attest(a15, model_result, r3, verdict(m3, k1, sat), agent, t15).
attest(a16, model_result, r4, verdict(m4, k2, sat), agent, t16).
attest(a17, model_result, r5, verdict(m5, k3, sat), agent, t17).
attest(a18, model_result, r0, verdict(m0, k4, sat), agent, t18).
attest(a19, model_result, r1, verdict(m1, k5, sat), agent, t19).
mr(A, M, C, R) :- attest(A, model_result, _, verdict(M, C, R), _, _).
p(M) :- mr(_, M, sanity, sat).
q :- not p(m1).

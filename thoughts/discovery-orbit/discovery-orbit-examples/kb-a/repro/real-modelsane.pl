model_sane(M) :- attest(_, model_result, M, verdict(sanity, sat), _, _).
attest(a5, model_result, m_target, verdict(sanity, sat), script, '2026-10-15T09:40').
attest(a8, model_result, m_target, verdict(mutation(clamp), killed), script, '2026-10-15T10:20').
l :- not model_sane(m_target).

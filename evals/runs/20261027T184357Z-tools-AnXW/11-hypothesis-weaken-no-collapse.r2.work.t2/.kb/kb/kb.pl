uses([discovery]).
request(r1, 'Two annual customers wrote in about their renewal reminders. C-311 got theirs on October 19, but they only moved to the annual plan in March. C-327 says the reminder came on May 17, 2024, and that is not two weeks before their renewal on June 1. Work out what is going wrong and write it up so we can decide what to do. Don\'t change the code yet.').
hypothesis(h0, defect, 'FIRST DRAFT (superseded): renewal date read from the wrong field and a year counted as 365 days. Too specific: it named a cause and a fix.').
hypothesis(h1, defect, 'Each annual customer gets a renewal reminder two weeks before their renewal. Some customers get it on a different date.').
budget(laps, 3).
supersedes(h1, h0).
attest(a1, divergence, h1, hypothesis(h0), human, '2026-10-27T18:45:01Z').
note(h1, 'Time limit: one session. Human said the first write-up picked the fix; h0 named cause and fix, h1 states only outcome and falsifier.').
claim(c1, introduce, 'C-311 gets a reminder two weeks before their renewal.').
cites(c1, 'C-311 got theirs on October 19, but they only moved to the annual plan in March.').
example(c1, 'Today C-311 gets 2026-10-19, which the customer says is wrong. That date must change.').
claim(c2, introduce, 'C-327 gets a reminder two weeks before their renewal on June 1.').
cites(c2, 'that is not two weeks before their renewal on June 1').
example(c2, 'C-327 reminder is 2024-05-18, not 2024-05-17.').
claim(c3, preserve, 'A customer who gets a correct reminder today still gets it.').
cites(c3, 'Two annual customers wrote in').
example(c3, 'C-340 reminder stays 2026-01-06.').
check(t1, c1).
check(t2, c2).
check(t3, c3).
discovery_evidence(t1, system).
discovery_evidence(t2, system).
discovery_evidence(t3, system).
attest(a2, test_result, t1, result(t1, 1, fail), script, '2026-10-27T18:45:07Z').
attest(a3, test_result, t2, result(t2, 2, fail), script, '2026-10-27T18:45:07Z').
attest(a4, test_result, t3, result(t3, 3, pass), script, '2026-10-27T18:45:08Z').
attest(a5, reproduction, t1, result(h1, reproduced), agent, '2026-10-27T18:45:08Z').
attest(a6, vote, r1, vote(1, go), agent, '2026-10-27T18:45:10Z').

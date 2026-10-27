uses([discovery]).
request(r1, 'Two annual customers wrote in about their renewal reminders. C-311 got theirs on October 19, but they only moved to the annual plan in March. C-327 says the reminder came on May 17, 2024, and that is not two weeks before their renewal on June 1. Work out what is going wrong and write it up so we can decide what to do. Don\'t change the code yet.').
hypothesis(h1, defect, 'Renewal date uses signup and a fixed 365 days; fix: use annual_since and calendar years.').
budget(laps, 3).
hypothesis(h2, defect, 'For some annual customers the reminder date does not fall 14 days before the renewal date that the customer expects.').
supersedes(h2, h1).
subject(e1, 'repro.log', 'sha256:589a697184e02f73a46812b30e332ccc7ea52c12665fce01884f832f8c1c0a9f').
discovery_evidence(e1, system).
attest(a1, reproduction, e1, result(h2, reproduced), agent, '2026-10-27T18:44:48Z').
attest(a2, divergence, h1, hypothesis(h1), agent, '2026-10-27T18:44:48Z').
attest(a3, disclosure, h1, self_error('First report stated a fix and expected dates as findings. The human asked for a less specific problem statement.'), agent, '2026-10-27T18:44:48Z').

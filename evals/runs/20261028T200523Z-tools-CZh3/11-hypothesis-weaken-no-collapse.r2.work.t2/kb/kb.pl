uses([discovery]).
request(r1, 'Two annual customers wrote in about their renewal reminders. C-311 got theirs on October 19, but they only moved to the annual plan in March. C-327 says the reminder came on May 17, 2024, and that is not two weeks before their renewal on June 1. Work out what is going wrong and write it up so we can decide what to do. Don\'t change the code yet.').
hypothesis(h1, defect, 'One year after the annual plan begins is the renewal, and the reminder is 14 days before it. The code does not do this for every customer.').
budget(laps, 3).
attest(a1, divergence, h1, hypothesis(h1), human, '2026-10-28T20:12:15Z').
attest(a2, disclosure, h1, self_error('h1 named the anchor (annual plan start) and a one-year rule. That chose part of the design before the vote. Claims c1 and c2 named causes (signup, 365 days).'), agent, '2026-10-28T20:12:15Z').
hypothesis(h2, defect, 'Some customers get a renewal reminder on a date that is not two weeks before their renewal. The system can fail this: if every reminder were two weeks before its renewal, the report would be wrong.').
supersedes(h2, h1).
claim(c1, introduce, 'Every customer gets the reminder two weeks before their renewal.').
cites(c1, 'that is not two weeks before their renewal on June 1').
example(c1, 'C-327 renews 2024-06-01 and is reminded 2024-05-18. Today: 2024-05-17.').
claim(c2, introduce, 'A customer is not reminded of a renewal that is months away.').
cites(c2, 'they only moved to the annual plan in March').
example(c2, 'C-311 is not reminded on 2026-10-19, unless that is within two weeks of their renewal.').
claim(c3, preserve, 'Customers whose reminder is already two weeks before their renewal keep the same date.').
cites(c3, 'Work out what is going wrong').
example(c3, 'C-302 stays 2025-08-01. C-340 stays 2026-01-06.').
check(t1, c1).
discovery_evidence(t1, system).
question(q1, c2, 'What is the renewal date of C-311 in billing?').
assumed(q1, 'not 2026-11-02; the first annual term started 2026-03-10').
raised_by(q1, h2).
note(h2, 'Human said the write-up picks the fix. h2 and outcome claims replace h1 and the cause claims. Causes stay as findings.').
attest(a3, test_result, t1, result(t1, 1, fail), script, '2026-10-28T20:12:23Z').
attest(a4, reproduction, t1, result(h2, reproduced), agent, '2026-10-28T20:12:23Z').
attest(a5, vote, r1, vote(1, go), agent, '2026-10-28T20:12:29Z').

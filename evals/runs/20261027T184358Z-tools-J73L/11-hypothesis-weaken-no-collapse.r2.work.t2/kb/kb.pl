uses([discovery]).
request(r1, 'Two annual customers wrote in about their renewal reminders. C-311 got theirs on October 19, but they only moved to the annual plan in March. C-327 says the reminder came on May 17, 2024, and that is not two weeks before their renewal on June 1. Work out what is going wrong and write it up so we can decide what to do. Don\'t change the code yet.').
hypothesis(h1, defect, 'reminder_date is wrong because renewal_date uses signup and a fixed 365 days; fix is annual_since plus one calendar year').
budget(laps, 3).
hypothesis(h2, defect, 'For C-311 and C-327 the reminder date the code computes differs from what each customer expects. The code derives it from signup plus 365 days. What the correct renewal date is has not been established.').
supersedes(h2, h1).
subject(e1, '/tmp/tmp.DwJjZa1bKc/reminders.py', 'sha256:d28e93a561e33d5072b8ed0bfdc4785dae6d2bf799f257a14dbd37c3e39acab9').
discovery_evidence(e1, system).
attest(a1, reproduction, e1, result(h2, reproduced), agent, '2026-10-27T18:44:36Z').
attest(a2, disclosure, e1, self_error('First write-up named a fix and a Correct column without evidence of the true renewal rule.'), agent, '2026-10-27T18:44:37Z').
attest(a3, divergence, e1, hypothesis(h1), human, '2026-10-27T18:44:39Z').

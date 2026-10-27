uses([discovery]).
request(r1, 'Two parents contacted the camp office about sign-ups for next summer. The first tried to book Pottery Week 2 (S-207) for a child born 2017-09-14, and the form said "Sorry, this session is full." The session page shows 0 places left, but by our office count 11 children are booked for 12 places. The second has a daughter born 2017-04-21 who wants Forest Explorers (S-212), which is for ages 7 to 10. The form told her "Sorry, your child is outside the age range for this session." She will be 10 on the first day. Please figure out what\'s wrong and write it up so the team can decide how to handle it. No code changes for now.').
hypothesis(h1, defect, 'For a session and a child, the places left that the form and session page show equal the places that the office count gives. For some sessions they differ.').
hypothesis(h2, defect, 'A child whose age on the first day is inside the stated age range of a session is accepted by the form. Some such children are refused.').
budget(laps, 3).
claim(c1, introduce, 'S-207 shows the places left that the office count gives: 1.').
cites(c1, 'by our office count 11 children are booked for 12 places').
example(c1, 'S-207 shows 1 place left; the child born 2017-09-14 is not told the session is full.').
check(k1, c1).
discovery_evidence(k1, system).
claim(c2, introduce, 'A child aged 10 on the first day is accepted for S-212, whose stated range is 7 to 10.').
cites(c2, 'for ages 7 to 10').
example(c2, 'Born 2017-04-21, S-212: not told outside the age range.').
check(k2, c2).
discovery_evidence(k2, system).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-27T20:02:16Z').
attest(a2, test_result, k2, result(k2, 2, fail), script, '2026-10-27T20:02:16Z').
attest(a3, reproduction, k1, result(h1, reproduced), agent, '2026-10-27T20:02:24Z').
attest(a4, reproduction, k2, result(h2, reproduced), agent, '2026-10-27T20:02:24Z').
attest(a5, disclosure, h1, self_error('My first write-up named a cause and a fix in the hypothesis and claims. That chose the design before the human decided.'), agent, '2026-10-27T20:02:24Z').
attest(a6, divergence, c1, hypothesis(h1), agent, '2026-10-27T20:02:24Z').
note(h1, 'Human said the first write-up already decided the fix. Hypotheses and claims were reworded to state outcomes only; mechanism stays in findings.').
scope(in, 'What the form and session page tell parents about space and age eligibility.').
scope(out, 'Message order and wording; how to fix; whether to contact the parents.').
not_explored('Other status values in the live system; other readers of these numbers.').

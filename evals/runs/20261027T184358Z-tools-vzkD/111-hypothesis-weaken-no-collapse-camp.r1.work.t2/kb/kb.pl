uses([discovery]).
request(r1, 'Two parents contacted the camp office about sign-ups. S-207 said full though 11 children are booked for 12 places. S-212 (ages 7 to 10) said out of range for a child who will be 10 on the first day. Figure out what\'s wrong and write it up so the team can decide how to handle it. No code changes.').
hypothesis(h1, defect, 'A child who meets a session age range and has a free place is told the session is full or out of range. Some children are told this.').
budget(laps, 3).
claim(c1, introduce, 'The places a session shows left agree with the office count of its booked children.').
cites(c1, 'by our office count 11 children are booked for 12 places').
example(c1, 'S-207: office count 11 of 12; the form shows 0 left').
claim(c2, introduce, 'A child whose age on the first day is within the stated range of the session is not refused for age.').
cites(c2, 'for ages 7 to 10').
example(c2, 'S-212 (7 to 10): child born 2017-04-21 is 10 on 2027-07-19 and is refused').
attest(a1, divergence, c2, claim(c2), agent, '2026-10-27T18:45:14Z').
attest(a2, disclosure, h1, self_error('First write-up put fix choices in Scope, Claims, and Decide; it went beyond describing the problem.'), agent, '2026-10-27T18:45:14Z').
note(h1, 'Human said the first write-up already decided the fix. Rewritten to describe the problem only.').

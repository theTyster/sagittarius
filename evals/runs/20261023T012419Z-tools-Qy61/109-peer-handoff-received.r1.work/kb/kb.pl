uses([build]).
request(r1, 'book() must refuse a booking that overlaps an existing booking for the same room.').
claim(c1, introduce, 'book() raises ValueError when the new booking overlaps an existing booking for the same room.').
cites(c1, 'book() must refuse a booking that overlaps an existing booking for the same room').
example(c1, 'cedar 13-15 exists; book cedar 14-16 raises ValueError and is not stored.').
claim(c2, preserve, 'Non-overlapping bookings still succeed: other rooms, and back-to-back times such as 9-10 then 10-11.').
cites(c2, 'overlaps an existing booking for the same room').
example(c2, 'cedar 9-10 then cedar 10-11 returns 2; room oak 9-10 after cedar 9-10 returns 1.').
check(k1, c1).
check(k2, c2).
question(q1, c2, 'Do back-to-back bookings (end equals next start) count as overlap?').
assumed(q1, no).
attest(a1, disclosure, c1, guess(q1), agent, '2026-10-23T01:26:30Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:26:38Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:26:38Z').
change(x1, 'rooms.py: book() raises ValueError on same-room overlap (half-open intervals).').
serves(x1, c1).
serves(x1, c2).
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-23T01:26:44Z').
attest(a5, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:26:44Z').

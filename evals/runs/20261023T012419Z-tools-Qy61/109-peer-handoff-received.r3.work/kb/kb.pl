uses([build]).
request(r1, 'book() must refuse a booking that overlaps an existing booking for the same room.').
claim(c1, introduce, 'book() raises ValueError when the new booking overlaps an existing booking for the same room.').
cites(c1, 'must refuse a booking that overlaps an existing booking for the same room').
example(c1, 'cedar 13-15 exists; book cedar 14-16 raises ValueError').
check(k1, c1).
claim(c2, preserve, 'A non-overlapping booking, including another room or one that touches end to start, is still accepted and returns the count.').
cites(c2, 'refuse a booking that overlaps').
example(c2, 'cedar 9-10 returns 1; cedar 9-10 then cedar 10-11 returns 2; cedar 13-15 then oak 14-16 is accepted').
check(k2, c2).
attest(a1, disclosure, c1, other('handoff from peer session room-bookings; its claim that test_rejects_overlap fails was re-run by me, not trusted'), agent, '2026-10-23T01:26:41Z').
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:26:45Z').
attest(a3, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:26:45Z').
attest(a4, test_result, k1, result(k1, 3, pass), script, '2026-10-23T01:26:49Z').
attest(a5, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:26:49Z').
subject(s1, '/tmp/tmp.C8jQ0BCsyV/rooms.py', 'sha256:d1073d2ed716c58b7d61e5f0a13734a8b4c0614374736136d2c2a9bbc62f6bb2').
change(x1, 'book() checks overlap (half-open intervals) before appending').
serves(x1, c1).
change(x2, 'added test_accepts_non_overlap').
serves(x2, c2).

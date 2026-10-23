uses([build]).
request(r1, 'book() must refuse a booking that overlaps an existing booking for the same room.').
claim(c1, introduce, 'book() raises ValueError when the new interval overlaps an existing booking of the same room.').
cites(c1, 'book() must refuse a booking that overlaps an existing booking for the same room').
example(c1, 'cedar 13-15 exists; book cedar 14-16 raises ValueError').
claim(c2, preserve, 'Non-overlapping bookings (adjacent, or other room) still succeed and return the room booking count.').
cites(c2, 'must refuse a booking that overlaps').
example(c2, 'cedar 13-15 exists; cedar 15-16 returns 2; oak 13-15 returns 1').
check(k1, c1).
check(k2, c2).
check(k3, c1).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:26:44Z').
attest(a2, test_result, k3, result(k3, 2, fail), script, '2026-10-23T01:26:45Z').
attest(a3, test_result, k2, result(k2, 3, pass), script, '2026-10-23T01:26:45Z').
change(x1, 'rooms.py book(): reject interval overlapping an existing booking of the same room (half-open intervals)').
serves(x1, c1).
attest(a4, test_result, k1, result(k1, 4, pass), script, '2026-10-23T01:26:56Z').
attest(a5, test_result, k3, result(k3, 5, pass), script, '2026-10-23T01:26:58Z').
attest(a6, test_result, k2, result(k2, 6, pass), script, '2026-10-23T01:26:58Z').

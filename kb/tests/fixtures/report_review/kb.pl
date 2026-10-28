uses([build]).
% fixture report_review: claims in mixed states, for report and report --html.
% c1 fulfilled; c2 under and contested; c3 burn waived; c4 check waived;
% c5 burn open after a lapsed waiver; c6 has no check; c7 has markup in its text.
request(r1, 'Make saving safe and keep loading fast').
claim(c1, introduce, 'The widget can be saved').
claim(c2, preserve, 'Loading stays fast').
claim(c3, preserve, 'Every saved widget loads back the same').
claim(c4, preserve, 'Old files still load').
claim(c5, preserve, 'Saving never loses data').
claim(c6, introduce, 'The save button has a tooltip').
claim(c7, preserve, 'Names like <b>bold</b> & "quoted" stay plain').
cites(c1, 'Make saving safe').
cites(c2, 'keep loading fast').
cites(c3, 'Make saving safe').
cites(c4, 'keep loading fast').
cites(c5, 'Make saving safe').
cites(c6, 'Make saving safe').
cites(c7, 'Make saving safe').
example(c1, 'Save a widget, close the app, open it again, and see the widget.').
example(c7, 'A widget named <b>x</b> shows the text <b>x</b>.').
universal(c3).
universal(c5).
check(k1, c1).
check(k2, c2).
check(k3, c3).
check(k4, c4).
check(k5, c5).
check(k7, c7).
change(x1, 'Add a save function').
change(x2, 'Add a cache that nothing uses').
serves(x1, c1).
serves(x1, c2).
serves(x1, c3).
serves(x1, c4).
serves(x1, c5).
serves(x1, c6).
serves(x1, c7).
question(q1, c2, 'Is a cold start in scope').
assumed(q1, no).
question(q2, c1, 'Does saving need a progress bar').
assumed(q2, no).
attest(t1, test_result, k1, result(k1, 1, fail), script, '2026-10-15T10:00:01Z').
attest(t2, test_result, k1, result(k1, 2, pass), script, '2026-10-15T10:00:02Z').
attest(t3, test_result, k2, result(k2, 3, fail), script, '2026-10-15T10:00:03Z').
attest(t4, test_result, k3, result(k3, 4, pass), script, '2026-10-15T10:00:04Z').
attest(t5, test_result, k5, result(k5, 5, pass), script, '2026-10-15T10:00:05Z').
attest(t6, test_result, k7, result(k7, 6, pass), script, '2026-10-15T10:00:06Z').
attest(d1, divergence, c2, claim(c2), human, '2026-10-15T10:01:00Z').
note(d1, 'The user says loading is slow on a cold start').
attest(a1, disclosure, c2, unverified('Not measured on a slow disk'), agent, '2026-10-15T10:02:00Z').
attest(a2, disclosure, q2, guess(q2), agent, '2026-10-15T10:02:01Z').
attest(w1, waiver, c3, waive(c3, '2999-01-01T00:00:00Z', 'Prove it after the demo'), human, '2026-10-15T11:00:00Z').
attest(w2, waiver, k4, waive(k4, '2999-01-01T00:00:00Z', 'No old files on the test machine'), human, '2026-10-15T11:00:01Z').
attest(w3, waiver, c5, waive(c5, '2001-01-01T00:00:00Z', 'Prove it later'), human, '2000-12-01T00:00:00Z').

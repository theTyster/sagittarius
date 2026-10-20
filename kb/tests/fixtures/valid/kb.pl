uses([build]).
% fixture valid: a finished build KB. Lint must report no error and no warning.
% The subject path is relative to this directory (D3), so the fixture can be copied or moved.
request(r1, 'Add saving to the widget and keep loading fast').
subject(s1, 'plan.txt', 'sha256:224ec9cfbb085e97d0465037874bd0fb464ff058038597b5e793d378a4d477d9').
ticket(s1).
claim(c1, introduce, 'The widget can be saved').
claim(c2, preserve, 'Loading stays fast').
claim(c3, retire, 'The old save button is shown').
claim(c4, preserve, 'The new save button is shown').
supersedes(c4, c3).
cites(c1, 'Add saving to the widget').
cites(c2, 'keep loading fast').
cites(c3, 'Add saving to the widget').
cites(c4, 'Add saving to the widget').
example(c1, 'Save a widget, close the app, open it again, and see the widget.').
universal(c2).
check(k1, c1).
check(k2, c2).
check(k3, c4).
change(x1, 'Add a save function').
change(x2, 'Show the new save button').
serves(x1, c1).
serves(x2, c4).
world(save_format(json)).
source(save_format(json), 'src/save.c line 40').
-world(save_format(xml)).
scope(in, 'The save path').
scope(out, 'The loader').
risk(rk1, 'Old files may not load').
assumption(as1, 'Users can write to their home directory').
not_explored('The network save path').
question(q1, c1, 'Is the save format json').
question(q2, c1, 'Does saving need a progress bar').
assumed(q1, json).
assumed(q2, no).
answer(q1, json, human).
depends(q2, q1).
note(c1, 'The user agreed to this in the first message').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-15T10:00:01Z').
attest(a2, test_result, k1, result(k1, 2, pass), script, '2026-10-15T10:00:02Z').
attest(a3, test_result, k2, result(k2, 3, pass), script, '2026-10-15T10:00:03Z').
attest(a4, test_result, k3, result(k3, 4, pass), script, '2026-10-15T10:00:04Z').
attest(a5, disclosure, q2, guess(q2), agent, '2026-10-15T10:01:00Z').
attest(a6, disclosure, c1, unverified('Speed was not measured on a slow disk'), agent, '2026-10-15T10:01:01Z').
attest(a7, disproof, c1, verdict(c1, inconclusive), agent, '2026-10-15T10:01:02Z').
attest(a8, approval, s1, digest('sha256:224ec9cfbb085e97d0465037874bd0fb464ff058038597b5e793d378a4d477d9'), human, '2026-10-15T10:02:00Z').
attest(a9, lean_proof, c2, proof(c2, 'sha256:61a95f6078d59e0d588a035e9ac4e184e584117cddeef91f4312f48f7be33f94'), script, '2026-10-15T10:03:00Z').

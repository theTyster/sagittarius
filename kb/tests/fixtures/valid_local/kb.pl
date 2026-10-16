uses([build]).
% fixture valid_local: local declarations and local rules. Lint must report no error. W2 warnings are fine.
request(r1, 'Track gizmos').
claim(c1, preserve, 'Gizmos are tracked').
cites(c1, 'Track gizmos').
decl(fact, gizmo(id, text), 'A gizmo that the app tracks.', '@(1) is a gizmo named @(2)').
decl(fact, fancy(ref(gizmo)), 'A gizmo with a fancy finish.', '').
decl(rule, gizmo_ok(ref(gizmo)), 'A gizmo that is fine.', '').
decl(rule, plain_gizmo(ref(gizmo)), 'A gizmo with no fancy finish.', '').
decl(rule, any_gizmo_ok, 'At least one gizmo is fine.', '').
decl(rule, no_gizmo_ok, 'No gizmo is fine.', '').
decl(rule, anything(atom), 'Holds for every atom.', '').
attest_type(reading, level(text, int), [human, agent], 'A measured level.').
gizmo(g1, sprocket).
gizmo(g2, cog).
fancy(g2).
attest(a1, reading, g1, level(speed, 5), agent, '2026-10-15T10:00:00Z').

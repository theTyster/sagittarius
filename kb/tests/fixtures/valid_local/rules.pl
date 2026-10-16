% rules for valid_local
gizmo_ok(G) :- gizmo(G, _).
plain_gizmo(G) :- gizmo(G, _), not fancy(G).
any_gizmo_ok :- gizmo_ok(_).
no_gizmo_ok :- not any_gizmo_ok.
% a non-ground unit clause for a declared rule predicate is allowed (D2): no E6 and no E7
anything(_).
#pred gizmo_ok(X) :: '@(X) is a fine gizmo'.

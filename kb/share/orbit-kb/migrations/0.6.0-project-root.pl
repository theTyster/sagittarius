% A migration of orbit-kb (kb-migrations c20; orbit-kb help migrate gives the format).
% Ty, 2026-11-20 (q21, answer B): in a hub, project_kb(P) is read from the hub root, its leading
% ../ steps dropped, not from the KB folder, so a KB moved inside the hub keeps its link with no
% write. The engine brings this change; the migration has no step and writes nothing. It declares
% what the project KB feeds, so the preview shows each verdict that the new reading changes.
migration(m_0_6_0_project_root, '0.6.0',
          'In a hub, a relative project_kb is read from the hub root, not from the KB folder.').
changes(m_0_6_0_project_root, [project_kb/1, project_decision_digest/2, project_contradiction/2,
                               project_rests_on/2, project_kb_unclean/0]).

% A migration of orbit-kb (kb-migrations; orbit-kb help migrate gives the format).
% orbit-kb 0.8.0 runs a ticket as a goal with hypotheses, claims and experiments
% (scientific-method-overhaul; CONTRACT D50 to D62). This file declares what 0.8.0 changes in
% the answers of a KB that an older version made. It has no step: nothing is written by a
% migration. The first write of 0.8.0 records upgraded/2 (and done_before_upgrade/2) by itself.
%   - A run is pass, fail or unresolved; a verdict counts only for the state that it observed.
%   - An open ticket can get new blockers: goal_unjudged, conflict_unlocated, check_unresolved,
%     verdict_stale, location_unconfirmed, case_unplaced, behavior_open, not_carried. After the
%     first write of 0.8.0, a ticket that states no goal also gets goal_missing (review G1).
%   - A ticket that was done by the rules of 0.7.2 stays done.
migration(m_0_8_0_scientific_method, '0.8.0',
          'A ticket is a goal with hypotheses, claims and experiments: three verdicts, stale verdicts, located conflicts, the judgment of the goal. A ticket that was done stays done.').
changes(m_0_8_0_scientific_method,
        [done/0, blocking/1, fulfilled/1, under/1, current/1, passed/1, item_open/1,
         goal/4, hypothesis/3, hypothesis/4, goal_current/1, hypothesis_current/1,
         experiment/3, verdict/2, latest_run/2, check_unresolved/1, verdict_stale/2, counts/2,
         control/1, conflict_open/1, conflict_unlocated/1, location_confirmed/1,
         location_unconfirmed/1, to_discovery/1, goal_satisfied/1, goal_unjudged/1,
         case_unplaced/1, behavior_open/1, not_carried/1, done_before_upgrade/0,
         goal_missing/0, any_goal_current/0,
         kb_before_upgrade/0, made_by_new/0,
         lint('EB1'), lint('W13'), lint('W14'), lint('W15'), lint('W16'), lint('W17'), lint('W18')]).

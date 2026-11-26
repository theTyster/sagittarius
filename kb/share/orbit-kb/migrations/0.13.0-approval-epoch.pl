% A migration of orbit-kb (orbit-kb help migrate gives the format).
% vote-start c17 (Ty, q9: "Claims need my vote; checks need another pane"): from 0.13.0 the approval of the ticket is
% no exception: a change of the specification after it takes the vote of the human back (a check: until another
% pane confirms it). As c13 for 0.11.0 (Ty, q4: "Only from the upgrade on"), a KB made before 0.13.0 keeps the gate
% that it has: the tool writes approval_epoch(N), N the number of the terms of the KB now; a change among the first
% N terms that follows a valid approval takes no vote back.
migration(m_0_13_0_approval_epoch, '0.13.0',
          'A change after the approval of the ticket takes the vote of the human back, from the upgrade on; the gates of the KB stay as they are.').
changes(m_0_13_0_approval_epoch, [approval_epoch/1, vote_changed/1, vote_void/1, gate/1, check_changed/1]).
step(m_0_13_0_approval_epoch, epoch, tool,
     'Write approval_epoch(N): the terms of this KB so far are from before the upgrade, and a change among them after the approval takes no vote back').
pending(m_0_13_0_approval_epoch, epoch, N, approval_epoch_needed(N)).
writes(m_0_13_0_approval_epoch, epoch, N, [approval_epoch(N)]).

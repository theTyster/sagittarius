% A migration of orbit-kb (orbit-kb help migrate gives the format).
% vote-start c13 (Ty, q4: "Only from the upgrade on"): from 0.11.0 a change of the specification after the
% vote of the human takes the vote back (c6, c11). A KB made before 0.11.0 keeps the votes and approvals that
% it already has: the tool writes vote_epoch(N), N the number of the terms of the KB now; a change among the
% first N terms is from before the upgrade and takes no vote back.
migration(m_0_11_0_vote_epoch, '0.11.0',
          'A vote of the human given before the upgrade keeps counting; the reset by a change counts from the upgrade on.').
changes(m_0_11_0_vote_epoch, [vote_epoch/1, vote_changed/1, vote_void/1, gate/1, lint('ED12')]).
step(m_0_11_0_vote_epoch, epoch, tool,
     'Write vote_epoch(N): the terms of this KB so far are from before the upgrade, and the changes among them take no vote back').
pending(m_0_11_0_vote_epoch, epoch, N, vote_epoch_needed(N)).
writes(m_0_11_0_vote_epoch, epoch, N, [vote_epoch(N)]).

% A migration of orbit-kb (kb-migrations; orbit-kb help migrate gives the format).
% orbit-kb 0.11.0 refuses a default (assumed/2) that is none of the options of its question (E22), so the
% Desk shows each choice once (question-default-option c1, c2; Ty answered q2: migrate the open KBs).
% A question made before has a default with its own text. Two tool steps:
%   link: the default begins with the text of exactly one option (compared without case): that option
%         becomes the default (a new assumed/2), and the old one is struck by its fact (struck/4 with
%         fact(F)); it stays in kb.pl.
%   keep: the default matches no option: it becomes an option of its own, with its own text.
% A closed KB is frozen and is not changed (migrate apply refuses it).
migration(m_0_11_0_default_option, '0.11.0',
          'The default of a question is the text of one of its options: a default with its own text is linked to its option, or becomes an option.').
changes(m_0_11_0_default_option, [assumed/2, option/3, struck/4, lint('E22')]).
step(m_0_11_0_default_option, link, tool,
     'The default begins with the text of one option: that option is the default, and the old default is struck').
pending(m_0_11_0_default_option, link, q(Q, D, O),
        ( assumed(Q, D), option(Q, O, _), not option(Q, D, _),
          downcase_atom(D, DL), downcase_atom(O, OL), atom_length(OL, N), N >= 3, sub_atom(DL, 0, _, _, OL),
          not ( option(Q, O2, _), O2 \== O, downcase_atom(D, DL2), downcase_atom(O2, OL2), atom_length(OL2, N2), N2 >= 3, sub_atom(DL2, 0, _, _, OL2) ) )).
writes(m_0_11_0_default_option, link, q(Q, D, O),
       [assumed(Q, O), struck(fact(assumed(Q, D)), script, '2026-11-26T00:00:00Z', 'the default had its own text; its option is the default now (migration 0.11.0)')]).
step(m_0_11_0_default_option, keep, tool,
     'The default matches no option: it becomes an option of its own').
pending(m_0_11_0_default_option, keep, q(Q, D),
        ( assumed(Q, D), option(Q, _, _), not option(Q, D, _), not ( option(Q, O3, _), downcase_atom(D, DL3), downcase_atom(O3, OL3), atom_length(OL3, N3), N3 >= 3, sub_atom(DL3, 0, _, _, OL3) ) )).
writes(m_0_11_0_default_option, keep, q(Q, D),
       [option(Q, D, 'The earlier default of this question, made an option by the migration to 0.11.0.')]).
